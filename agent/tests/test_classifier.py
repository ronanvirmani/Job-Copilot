import pytest

from inbox_triage_agent.classifier import ClassificationEngine, extract_first_json_object
from inbox_triage_agent.models import Message


class StubOllamaClient:
    def __init__(self, responses):
        self._responses = responses

    async def generate(self, prompt: str, *, options: dict | None = None) -> str:  # noqa: D401
        return self._responses.pop(0)


@pytest.mark.asyncio
async def test_extracts_json_payload():
    payload = "Some preamble {\"label\":\"offer\",\"confidence\":0.9}\n"""
    assert extract_first_json_object(payload) == '{"label":"offer","confidence":0.9}'


@pytest.mark.asyncio
async def test_llm_result_used():
    message = Message(id=1, subject="Congrats!", snippet="We'd like to extend an offer.")
    client = StubOllamaClient([
        '{"label":"offer","confidence":0.94,"reason":"explicit offer"}'
    ])
    engine = ClassificationEngine(client, min_confidence=0.5)

    payload = await engine.classify_message(message)

    assert payload.classification == "offer"
    assert payload.classified_by == "llm"
    assert payload.confidence == pytest.approx(0.94)


@pytest.mark.asyncio
async def test_falls_back_when_confidence_low():
    message = Message(id=2, subject="Following up", snippet="Let's schedule a chat.")
    client = StubOllamaClient([
        '{"label":"recruiter_reply","confidence":0.2,"reason":"unsure"}'
    ])
    engine = ClassificationEngine(client, min_confidence=0.6)

    payload = await engine.classify_message(message)

    assert payload.classification == "recruiter_reply"
    assert payload.classified_by == "rules"
    assert payload.confidence is None


@pytest.mark.asyncio
async def test_falls_back_on_invalid_json():
    message = Message(id=3, subject="Hello", snippet="No keywords here")
    client = StubOllamaClient(["Not JSON at all"])
    engine = ClassificationEngine(client, min_confidence=0.5)

    payload = await engine.classify_message(message)

    assert payload.classified_by == "rules"
    assert payload.classification == "other"
