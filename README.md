# PocketLedger Monorepo

Welcome to the **PocketLedger** repository. This is a monorepo containing both the Flutter mobile application and the FastAPI backend service.

## 🏗️ Repository Structure

```
PocketLedger/
├── pocketledger-frontend/  # Flutter Mobile App
├── pocketledger-backend/   # FastAPI Backend Service
├── docs/                   # Architecture diagrams & SQL Migrations
└── .github/                # GitHub Actions CI/CD workflows
```

---

### 📱 1. pocketledger-frontend (Flutter)
The mobile application built with Flutter and Riverpod. 
- **Tech:** Flutter, Riverpod, Supabase SDK
- **Features:** Expense tracking, monthly analysis, workspace switching, offline-first syncing.
- **Config:** Dynamic backend URL injection via `--dart-define=BACKEND_URL=...`
- **Docs:** Read the [Frontend README](./pocketledger-frontend/README.md) for setup and build instructions.

### ⚙️ 2. pocketledger-backend (FastAPI)
The backend service that handles business logic separated from the client.
- **Tech:** Python, FastAPI, Supabase REST API, Resend
- **Features:** Full CRUD API for transactions (GET, POST, PUT, DELETE), secure email reports, multi-tenant workspace enforcement, automated summaries.
- **Docs:** Read the [Backend README](./pocketledger-backend/README.md) for setup and deployment instructions.

### 🗄️ 3. docs (Architecture & Database)
Contains the single source of truth for our database architecture.
- **SQL Migrations:** Strict, versioned SQL migrations in [`docs/migrations/`](./docs/migrations/). Never edit old migrations, always create new ones.
- **Architecture:** ERD diagrams and RLS policies in [`docs/architecture/`](./docs/architecture/).
- **Design Decisions:** Trade-off analysis on architectural patterns in [`docs/architecture/design_decisions.md`](./docs/architecture/design_decisions.md).

---

## 🚀 CI/CD Pipelines
This repository uses GitHub Actions for automated builds.
- **Semantic Release & APK Build:** Triggers automatically on pushes to main/master. It uses semantic-release to analyze Conventional Commits, auto-generate changelogs, bump the version, build the Flutter APKs from pocketledger-frontend, and attach them to a new GitHub Release.
