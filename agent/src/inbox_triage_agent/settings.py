"""Application configuration loaded from environment variables."""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import AnyHttpUrl, Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    job_copilot_api_url: AnyHttpUrl = Field(
        "http://localhost:3000/api/v1",
        alias="JOB_COPILOT_API_URL",
        description="Base URL of the Job Copilot API (should include /api/v1)",
    )
    job_copilot_api_token: str = Field(..., alias="JOB_COPILOT_API_TOKEN")
    ollama_url: AnyHttpUrl = Field(
        "http://localhost:11434",
        alias="OLLAMA_URL",
        description="Base URL of the local Ollama instance",
    )
    ollama_model: str = Field("llama3.1", alias="OLLAMA_MODEL")

    poll_interval_seconds: float = Field(15.0, alias="POLL_INTERVAL_SECONDS")
    batch_size: int = Field(10, alias="BATCH_SIZE")
    claim_messages: bool = Field(True, alias="CLAIM_MESSAGES")
    llm_min_confidence: float = Field(0.5, alias="LLM_MIN_CONFIDENCE")

    http_timeout_seconds: float = Field(30.0, alias="HTTP_TIMEOUT_SECONDS")
    max_retries: int = Field(3, alias="MAX_RETRIES")

    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = Field(
        "INFO", alias="LOG_LEVEL"
    )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Load the application settings once per process."""

    return Settings()
