"""Async client for the local Ollama server."""

from __future__ import annotations

import json
import logging

import httpx
from tenacity import AsyncRetrying, RetryError, retry_if_exception_type, stop_after_attempt, wait_exponential

logger = logging.getLogger(__name__)


class OllamaError(RuntimeError):
    """Raised when the Ollama request ultimately fails."""


class OllamaClient:
    def __init__(
        self,
        base_url: str,
        model: str,
        timeout: float,
        max_retries: int,
    ) -> None:
        self.model = model
        self._client = httpx.AsyncClient(base_url=base_url, timeout=timeout)
        self._retry = AsyncRetrying(
            reraise=True,
            stop=stop_after_attempt(max(1, max_retries)),
            wait=wait_exponential(multiplier=1, min=1, max=timeout),
            retry=retry_if_exception_type(httpx.RequestError),
        )

    async def close(self) -> None:
        await self._client.aclose()

    async def __aenter__(self) -> "OllamaClient":
        return self

    async def __aexit__(self, exc_type, exc, tb) -> None:  # type: ignore[override]
        await self.close()

    async def generate(self, prompt: str, *, options: dict | None = None) -> str:
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
        }
        if options:
            payload["options"] = options

        try:
            async for attempt in self._retry:
                with attempt:
                    response = await self._client.post("/api/generate", json=payload)
                    response.raise_for_status()
                    data = response.json()
                    text = data.get("response")
                    if not isinstance(text, str):
                        raise OllamaError("Ollama response missing 'response' field")
                    return text
        except RetryError as exc:
            raise OllamaError(str(exc.last_attempt.exception())) from exc
        except json.JSONDecodeError as exc:
            raise OllamaError(f"Invalid JSON from Ollama: {exc}") from exc

        raise OllamaError("Ollama request failed without raising an exception")
