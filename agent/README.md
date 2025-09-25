# Inbox Triage Agent

Async Python worker that pulls unclassified email messages from the Job Copilot Rails API, classifies them with a local Ollama model, and writes the results back with confidence metadata.

## Quick start

1. Install dependencies (Python 3.11+):
   ```bash
   cd agent
   python -m venv .venv
   source .venv/bin/activate
   pip install -e .[dev]
   ```
2. Ensure the Rails API and Ollama are running locally. The agent expects:
   - `JOB_COPILOT_API_URL` (default `http://localhost:3000/api/v1`)
   - `JOB_COPILOT_API_TOKEN` – Supabase JWT or service token with API access
   - `OLLAMA_URL` (default `http://localhost:11434`)
   - `OLLAMA_MODEL` (default `llama3.1`)
3. Run the worker:
   ```bash
   inbox-triage-agent
   ```

## Configuration

Environment variables (all optional unless noted):

| Variable | Default | Description |
| --- | --- | --- |
| `JOB_COPILOT_API_URL` | `http://localhost:3000/api/v1` | Base URL for the Rails API |
| `JOB_COPILOT_API_TOKEN` | _required_ | Bearer token used for API requests |
| `OLLAMA_URL` | `http://localhost:11434` | Base URL for the local Ollama instance |
| `OLLAMA_MODEL` | `llama3.1` | Model name passed to Ollama |
| `POLL_INTERVAL_SECONDS` | `15` | Sleep between polling cycles when no work is available |
| `BATCH_SIZE` | `10` | Number of messages fetched per poll |
| `CLAIM_MESSAGES` | `true` | Whether to call the optional claim endpoint before classifying |
| `LLM_MIN_CONFIDENCE` | `0.5` | Threshold under which the rule-based fallback is used |
| `HTTP_TIMEOUT_SECONDS` | `30` | Timeout for API and Ollama requests |
| `MAX_RETRIES` | `3` | Tenacity retry attempts for network calls |
## API interactions

- Fetch work items: `GET /api/v1/messages?classification=other&limit={BATCH_SIZE}`
- (Optional) claim: `PATCH /api/v1/messages/:id/claim` – the agent treats 404/409 as a no-op.
- Update classification: `PATCH /api/v1/messages/:id` with body `{ "classification": "...", "classified_by": "llm"|"rules", "confidence": 0.xx }`. Confidence is omitted when a rule-based fallback is used.

Adjust the endpoints in `api_client.py` if your API differs.

## Development

- Run the formatting & tests:
  ```bash
  pytest
  ```
- The code favors resilience: HTTP requests are retried, and JSON responses are validated with Pydantic before updates are sent.
