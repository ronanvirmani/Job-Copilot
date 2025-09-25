"""Lightweight keyword-based fallback classifier."""

from __future__ import annotations

import re
from typing import Pattern

from .models import LABELS

_RULES: dict[str, Pattern[str]] = {
    "offer": re.compile(r"\boffer\b|compensation|package", re.I),
    "interview_invite": re.compile(r"\b(interview|invite|phone screen|onsite|loop)\b", re.I),
    "oa": re.compile(r"(hacker ?rank|codility|codesignal|karat|online assessment|challenge|take-?home)", re.I),
    "recruiter_reply": re.compile(r"(connect|schedule|chat|next steps|availability)", re.I),
    "rejection": re.compile(r"(regret to inform|unfortunately|not moving forward)", re.I),
    "auto_ack": re.compile(r"(thank you for applying|we received your application|application received)", re.I),
    "not_job_related": re.compile(r"unsubscribe|newsletter|promo", re.I),
}

_PRIORITY: tuple[str, ...] = (
    "offer",
    "interview_invite",
    "oa",
    "recruiter_reply",
    "rejection",
    "auto_ack",
    "not_job_related",
)


def classify_with_rules(text: str) -> str:
    haystack = text or ""
    for label in _PRIORITY:
        if _RULES[label].search(haystack):
            return label
    return "other"
