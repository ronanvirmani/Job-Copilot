"""Background worker loop for classifying messages."""

from __future__ import annotations

import asyncio
import logging
import signal
from dataclasses import dataclass

from .api_client import ApiClient, ApiError
from .classifier import ClassificationEngine
from .models import Message
from .ollama_client import OllamaClient
from .settings import get_settings

logger = logging.getLogger(__name__)


@dataclass
class Metrics:
    processed: int = 0
    classified_via_llm: int = 0
    classified_via_rules: int = 0
    failed: int = 0
    last_error: str | None = None

    def log_summary(self) -> None:
        logger.info(
            "Processed=%s success_llm=%s success_rules=%s failed=%s",
            self.processed,
            self.classified_via_llm,
            self.classified_via_rules,
            self.failed,
        )


async def worker_loop(stop_event: asyncio.Event) -> None:
    settings = get_settings()
    logger.info(
        "Starting inbox triage agent with batch_size=%s poll_interval=%s",
        settings.batch_size,
        settings.poll_interval_seconds,
    )

    metrics = Metrics()

    async with ApiClient(
        base_url=str(settings.job_copilot_api_url),
        token=settings.job_copilot_api_token,
        timeout=settings.http_timeout_seconds,
        max_retries=settings.max_retries,
    ) as api_client, OllamaClient(
        base_url=str(settings.ollama_url),
        model=settings.ollama_model,
        timeout=settings.http_timeout_seconds,
        max_retries=settings.max_retries,
    ) as ollama_client:
        engine = ClassificationEngine(ollama_client, min_confidence=settings.llm_min_confidence)

        while not stop_event.is_set():
            try:
                messages = await api_client.fetch_messages(classification="other", limit=settings.batch_size)
            except ApiError as exc:
                metrics.failed += 1
                metrics.last_error = str(exc)
                logger.error("Failed fetching messages: %s", exc)
                await asyncio.sleep(settings.poll_interval_seconds)
                continue

            if not messages:
                await asyncio.sleep(settings.poll_interval_seconds)
                continue

            for message in messages:
                if stop_event.is_set():
                    break

                if settings.claim_messages:
                    try:
                        claimed = await api_client.claim_message(message.id)
                    except ApiError as exc:
                        metrics.failed += 1
                        metrics.last_error = str(exc)
                        logger.warning("Unable to claim message %s: %s", message.id, exc)
                        continue

                    if not claimed:
                        logger.debug("Message %s skipped (not claimed)", message.id)
                        continue

                await _classify_and_update(message, engine, api_client, metrics)

        metrics.log_summary()


async def _classify_and_update(message: Message, engine: ClassificationEngine, api_client: ApiClient, metrics: Metrics) -> None:
    try:
        payload = await engine.classify_message(message)
        await api_client.update_message(message.id, payload)
        metrics.processed += 1
        if payload.classified_by == "llm":
            metrics.classified_via_llm += 1
        else:
            metrics.classified_via_rules += 1
        logger.info(
            "Message %s classified as %s via %s", message.id, payload.classification, payload.classified_by
        )
    except ApiError as exc:
        metrics.failed += 1
        metrics.last_error = str(exc)
        logger.error("Failed to update message %s: %s", message.id, exc)
    except Exception as exc:  # noqa: BLE001
        metrics.failed += 1
        metrics.last_error = str(exc)
        logger.exception("Unexpected error processing message %s", message.id)


async def _main_async() -> None:
    stop_event = asyncio.Event()

    loop = asyncio.get_running_loop()
    for sig in (getattr(signal, "SIGINT", None), getattr(signal, "SIGTERM", None)):
        if sig is not None:
            loop.add_signal_handler(sig, stop_event.set)

    await worker_loop(stop_event)


def run() -> None:
    """Entry point used by the console script."""

    logging.basicConfig(
        level=get_settings().log_level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )

    try:
        asyncio.run(_main_async())
    except KeyboardInterrupt:
        logger.info("Shutdown requested by user")
