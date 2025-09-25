"""Typed models for API payloads and classifier responses."""

from __future__ import annotations

from typing import ClassVar, Literal

from pydantic import BaseModel, Field, ValidationError, field_validator

LABELS: tuple[str, ...] = (
    "offer",
    "interview_invite",
    "oa",
    "recruiter_reply",
    "rejection",
    "auto_ack",
    "not_job_related",
    "other",
)

ClassificationLabel = Literal[
    "offer",
    "interview_invite",
    "oa",
    "recruiter_reply",
    "rejection",
    "auto_ack",
    "not_job_related",
    "other",
]


class Message(BaseModel):
    id: int
    subject: str = ""
    snippet: str = ""
    raw_headers: dict | None = None
    gmail_message_id: str | None = None
    gmail_thread_id: str | None = None

    def combined_text(self) -> str:
        parts = [self.subject or "", self.snippet or ""]
        return "\n".join(part.strip() for part in parts if part and part.strip())


class ClaimResponse(BaseModel):
    triage_in_progress: bool | None = None


class UpdatePayload(BaseModel):
    classification: ClassificationLabel
    classified_by: Literal["llm", "rules"]
    confidence: float | None = Field(default=None, ge=0.0, le=1.0)
    reason: str | None = None
    raw_response: str | None = None


class LLMClassification(BaseModel):
    label: str
    confidence: float | None = Field(default=None, ge=0.0, le=1.0)
    reason: str | None = None

    normalized_label: ClassVar[tuple[str, ...]] = LABELS

    @field_validator("label")
    @classmethod
    def _normalize_label(cls, value: str) -> str:
        if not isinstance(value, str):
            raise TypeError("label must be a string")
        normalized = value.strip().lower()
        if normalized not in cls.normalized_label:
            raise ValueError(f"label must be one of {cls.normalized_label}")
        return normalized


class ClassificationError(RuntimeError):
    """Raised when we cannot classify a message."""


def parse_llm_response(raw_json: str) -> LLMClassification:
    """Try to parse the model output into an ``LLMClassification`` instance.

    Raises ``ClassificationError`` if the payload cannot be parsed.
    """

    try:
        return LLMClassification.model_validate_json(raw_json)
    except ValidationError as exc:
        raise ClassificationError(str(exc)) from exc
