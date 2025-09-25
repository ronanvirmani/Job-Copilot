"""HTTP client for interacting with the Job Copilot Rails API."""

from __future__ import annotations

import logging
import httpx
from tenacity import AsyncRetrying, RetryError, retry_if_exception_type, stop_after_attempt, wait_exponential

from .models import ClaimResponse, Message, UpdatePayload

logger = logging.getLogger(__name__)


class ApiError(RuntimeError):
    """Raised when the API request ultimately fails."""


class ApiClient:
    def __init__(
        self,
        base_url: str,
        token: str,
        timeout: float,
        max_retries: int,
    ) -> None:
        self._client = httpx.AsyncClient(
            base_url=base_url,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            timeout=timeout,
        )
        self._retry = AsyncRetrying(
            reraise=True,
            stop=stop_after_attempt(max(1, max_retries)),
            wait=wait_exponential(multiplier=1, min=1, max=timeout),
            retry=retry_if_exception_type((httpx.RequestError, httpx.HTTPStatusError)),
        )

    async def close(self) -> None:
        await self._client.aclose()

    async def __aenter__(self) -> "ApiClient":
        return self

    async def __aexit__(self, exc_type, exc, tb) -> None:  # type: ignore[override]
        await self.close()

    async def fetch_messages(self, *, classification: str, limit: int) -> list[Message]:
        response = await self._request(
            "GET",
            "/messages",
            params={"classification": classification, "limit": str(limit)},
        )
        data = response.json()
        if not isinstance(data, list):
            raise ApiError("API did not return a list of messages")
        return [Message.model_validate(item) for item in data]

    async def claim_message(self, message_id: int) -> bool:
        try:
            response = await self._request(
                "PATCH",
                f"/messages/{message_id}/claim",
                raise_for_status=False,
            )
        except httpx.HTTPStatusError as exc:
            if exc.response.status_code == 404:
                logger.info("Message %s not claimable (404)", message_id)
                return False
            raise

        if response.status_code == 409:
            logger.info("Message %s already claimed", message_id)
            return False

        if response.status_code >= 400:
            logger.warning(
                "Unexpected status when claiming %s: %s %s",
                message_id,
                response.status_code,
                response.text,
            )
            return False

        try:
            payload = ClaimResponse.model_validate_json(response.text)
        except Exception:  # noqa: BLE001
            return True
        return bool(payload.triage_in_progress)

    async def update_message(self, message_id: int, payload: UpdatePayload) -> None:
        await self._request(
            "PATCH",
            f"/messages/{message_id}",
            json=payload.model_dump(exclude_none=True),
        )

    async def _request(
        self,
        method: str,
        url: str,
        *,
        params: dict[str, str] | None = None,
        json: dict | None = None,
        raise_for_status: bool = True,
    ) -> httpx.Response:
        try:
            async for attempt in self._retry:
                with attempt:
                    response = await self._client.request(method, url, params=params, json=json)
                    if raise_for_status:
                        response.raise_for_status()
                    elif response.status_code >= 500:
                        response.raise_for_status()
                    return response
        except RetryError as exc:
            raise ApiError(str(exc.last_attempt.exception())) from exc

        raise ApiError("Request failed without raising an exception")
