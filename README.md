# Job Copilot

Job Copilot is a full-stack productivity assistant for job seekers. It connects to Gmail and Google Calendar via Supabase Auth, keeps an always-on sync of messages, classifies every incoming email with a local Ollama model, and surfaces the current state of each application in a React dashboard.

---

## Architecture at a glance

| Component | Stack | Responsibilities |
| --- | --- | --- |
| Backend API | Ruby on Rails 8, Postgres (Supabase), Sidekiq, Redis | Google OAuth token storage, Gmail/Calendar sync jobs, application + message CRUD, Supabase JWT auth |
| Inbox Triage Agent | Python 3.13, httpx, Pydantic, Ollama | Polls the API for unclassified messages, runs LLM + rule-based classification, posts confidence metadata back |
| Frontend | Vite + React 18, Tailwind v4, daisyUI, React Query | Supabase Google login, dashboards, message triage workflow, manual sync triggers |

For deeper architectural notes see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Prerequisites

| Tool | Version (tested) | Notes |
| --- | --- | --- |
| Ruby | 3.3.6 | Managed with `rbenv`; required for the Rails backend + Sidekiq |
| Bundler | 2.5+ | Install dependencies in `backend/` |
| Node.js | 20.x | Vite dev server + frontend build |
| npm | 10.x | Package manager for the frontend |
| Python | 3.11+ (3.13 used) | Runs the inbox triage agent |
| Redis | 7.x | Sidekiq job queue and caching |
| Ollama | 0.2+ | Local LLM inference (`OLLAMA_MODEL` defaults to `llama3.1`) |
| Supabase project | Postgres + Auth | Stores data and issues Google OAuth tokens |
| Google Cloud project | OAuth consent + Gmail/Calendar APIs | Needed for user data access |

---

## Environment configuration

Create secure values for the Rails Active Record encryption keys (each must be 32-byte Base64 strings) and store every secret using your preferred secret manager. The tables below list the minimum environment variables required.

### Backend (`backend/.env` or service config)

| Variable | Description |
| --- | --- |
| `RAILS_ENV` | Use `development` locally, `production` when deployed |
| `DATABASE_URL` | Supabase Postgres connection string (include `sslmode=require`) |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY` | Used for Supabase Auth + admin calls |
| `SUPABASE_JWT_SECRET` | HS256 key matching your Supabase project |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI` | OAuth credentials for Gmail/Calendar sync |
| `GOOGLE_CAL_CLIENT_ID`, `GOOGLE_CAL_CLIENT_SECRET`, `GOOGLE_CAL_REDIRECT_URI` | Only if using a separate OAuth app for Calendar |
| `REDIS_URL` | Redis connection string for Sidekiq |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | 32-byte Base64 string |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | 32-byte Base64 string |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | 32-byte Base64 string |
| `FRONTEND_URL` | (Optional) Used in mailers + CORS |
| `OLLAMA_BASE_URL`, `OLLAMA_MODEL` | Needed if backend initiates classification or previews |

### Frontend (`frontend/.env.local`)

```
VITE_API_URL=http://localhost:3000
VITE_SUPABASE_URL=https://<your-project>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-key>
VITE_GOOGLE_CLIENT_ID=<oauth-client-id>
```

The Google OAuth client must include `http://localhost:5173` (dev) and your deployed Vercel domains as authorized redirect URIs.

### Inbox Triage Agent (`agent/.env`)

| Variable | Default | Description |
| --- | --- | --- |
| `JOB_COPILOT_API_URL` | `http://localhost:3000/api/v1` | Base URL for the Rails API |
| `JOB_COPILOT_API_TOKEN` | _required_ | Supabase JWT or service token used for API calls |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Local Ollama instance |
| `OLLAMA_MODEL` | `llama3.1` | Model passed to Ollama |
| `POLL_INTERVAL_SECONDS` | `15` | Sleep between polling cycles when no work is available |

Refer to [`agent/README.md`](agent/README.md) for the full list of optional toggles.

---

## Running the stack locally

### 1. Prepare shared services

```sh
# Start Redis
redis-server

# Start Ollama (model download may take time)
ollama run llama3.1
```

Ensure your Supabase project has Gmail + Calendar APIs enabled and that the redirect URIs match the environment variables above.

### 2. Backend API

```sh
cd backend
bundle install

# Apply database schema to Supabase (runs migrations against DATABASE_URL)
bundle exec rails db:migrate

# Run the Rails server on http://localhost:3000
bundle exec rails server

# In a second terminal, run Sidekiq
bundle exec sidekiq
```

Key dev endpoints (all under `http://localhost:3000/api/v1`):
- `GET /messages` – list messages for the authenticated Supabase user
- `PATCH /messages/:id/claim` – mark a message as triage-in-progress
- `PATCH /messages/:id` – update classification + metadata
- `POST /sync/gmail` – enqueue a Gmail sync job

### 3. Inbox triage agent

```sh
cd agent
python -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'

# With backend + Ollama running
inbox-triage-agent
```

The agent polls the API for messages classified as `other`, optionally claims them, and writes back the LLM or rule-based result.

### 4. Frontend dashboard

```sh
cd frontend
npm install
npm run dev
```

Visit `http://localhost:5173` and complete the Supabase Google sign-in. Once authenticated, you can trigger manual syncs, review classifications, and manage application statuses.

---

## Testing

Run focused suites before committing:

- **Backend**
	```sh
	cd backend
	bundle exec rails test
	bundle exec ruby -Itest test/controllers/messages_controller_test.rb
	bundle exec ruby -Itest test/controllers/classifications_controller_test.rb
	bundle exec ruby -Itest test/services/email_classifier_test.rb
	```

- **Inbox agent**
	```sh
	cd agent
	source .venv/bin/activate
	python -m pytest
	```

- **Frontend**
	```sh
	cd frontend
	npm run lint
	npm run build
	```

---

## Deployment overview

1. Deploy the Rails API + Sidekiq worker to a host that supports Ruby (Render, Fly.io, Heroku). Provide Supabase, Redis, Google, and encryption secrets. Run `rails db:migrate` on release.
2. Deploy the inbox triage agent as a long-lived worker (Render background worker, Fly.io machine, etc.) with access to the API, Redis/Ollama, and the same secrets.
3. Deploy the Vite frontend to Vercel. Set `VITE_*` environment variables in the Vercel dashboard and add the production domain to Google OAuth.
4. Update DNS (optional) and monitor Supabase, Sidekiq, and agent logs for initial traffic.

For a fuller deployment checklist, see the guidance in the project history or adapt the steps above to your target platform.

---

## Additional resources

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/ENDPOINTS.md`](docs/ENDPOINTS.md)
- [`agent/README.md`](agent/README.md)
- [`backend/README.md`](backend/README.md) (fill in platform specifics for your environment)

Happy shipping!
