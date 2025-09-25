"""Classification orchestration between Ollama and rule-based fallbacks."""

from __future__ import annotations

import json
import logging

from .models import ClassificationError, LLMClassification, Message, UpdatePayload
from .ollama_client import OllamaClient, OllamaError
from .rules import classify_with_rules
from pydantic import ValidationError

logger = logging.getLogger(__name__)


class ClassificationEngine:
    def __init__(self, llm_client: OllamaClient, *, min_confidence: float) -> None:
        self._llm_client = llm_client
        self._min_confidence = max(0.0, min(1.0, min_confidence))

    async def classify_message(self, message: Message) -> UpdatePayload:
        text = message.combined_text()
        fallback_label = classify_with_rules(text)

        raw_response: str | None = None
        reason: str | None = None

        try:
            prompt = build_prompt(message)
            raw_response = await self._llm_client.generate(
                prompt,
                options={"temperature": 0.0, "num_predict": 256},
            )
            json_payload = extract_first_json_object(raw_response)
            llm_result = parse_llm(json_payload)
            reason = llm_result.reason

            if llm_result.confidence is None:
                logger.info("LLM did not return confidence for message %s; using rules", message.id)
                raise ClassificationError("missing confidence")

            if llm_result.confidence < self._min_confidence:
                logger.info(
                    "LLM confidence %.2f below threshold %.2f for message %s; using rules",
                    llm_result.confidence,
                    self._min_confidence,
                    message.id,
                )
                raise ClassificationError("confidence below threshold")
            return UpdatePayload(
                classification=llm_result.label,
                classified_by="llm",
                confidence=llm_result.confidence,
                reason=reason,
                raw_response=json_payload,
            )
        except (OllamaError, ClassificationError, json.JSONDecodeError) as exc:
            logger.warning("Falling back to rules for message %s: %s", message.id, exc)
            return UpdatePayload(
                classification=fallback_label,
                classified_by="rules",
                confidence=None,
                reason=reason,
                raw_response=raw_response,
            )


def build_prompt(message: Message) -> str:
    headers = message.raw_headers or {}
    headers_block = "\n".join(f"{k}: {v}" for k, v in headers.items())
    snippet = message.snippet or "(no snippet)"
    subject = message.subject or "(no subject)"

    categories = ", ".join(
        [
            "offer",
            "interview_invite",
            "oa",
            "recruiter_reply",
            "rejection",
            "auto_ack",
            "not_job_related",
            "other",
        ]
    )

    return (
        "You are a JSON-only classifier for job search emails.\n"
        "Return a single-line JSON object with keys 'label', 'confidence', and 'reason'.\n"
        "Label MUST be one of ["
        + categories
        + "]. Confidence must be between 0 and 1.\n"
        "Do not include any extra text or Markdown.\n"
        "Example: {\"label\":\"interview_invite\",\"confidence\":0.82,\"reason\":\"mentions scheduling\"}.\n"
        "Email to classify:\n"
        f"Subject: {subject}\n"
        f"Snippet: {snippet}\n"
        "Headers:\n"
        f"{headers_block if headers_block else '(none)'}\n"
    )


def parse_llm(raw_json: str) -> LLMClassification:
    try:
        return LLMClassification.model_validate_json(raw_json)
    except ValidationError as exc:
        raise ClassificationError(str(exc)) from exc


def extract_first_json_object(text: str) -> str:
    """Extract the first top-level JSON object from ``text``."""

    start_index = text.find("{")
    if start_index == -1:
        raise ClassificationError("No JSON object found in response")

    depth = 0
    for index in range(start_index, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start_index : index + 1]
    raise ClassificationError("Unterminated JSON object in response")
