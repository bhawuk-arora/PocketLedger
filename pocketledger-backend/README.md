# PocketLedger-Backend

FastAPI backend for PocketLedger — handles all business logic, Supabase queries, email reports, and multi-tenant workspace access.

> This folder lives inside the main PocketLedger repo but is **deployed independently** as its own service.

## Architecture

```
pocketledger-backend/
├── requirements.txt
├── .env.example
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI entry point
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py        # Environment settings
│   │   └── security.py      # JWT verification via Supabase
│   ├── api/
│   │   ├── __init__.py
│   │   ├── companies.py     # Workspace CRUD
│   │   ├── transactions.py  # Expense CRUD + pagination
│   │   └── reports.py       # Monthly analysis + email
│   └── models/
│       ├── __init__.py
│       └── schemas.py       # Pydantic models
```

## Setup

```bash
cd pocketledger-backend
python -m venv venv
venv\Scripts\activate       # Windows
pip install -r requirements.txt
cp .env.example .env        # Fill in your keys
uvicorn app.main:app --reload
```

## Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon/public key |
| `SUPABASE_SERVICE_KEY` | Supabase service role key (for admin ops) |
| `RESEND_API_KEY` | Resend API key for email reports |

## Deployment

Deploy to **Render** or **Vercel** as a Python web service pointing at `app.main:app`.
