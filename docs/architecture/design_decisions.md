# PocketLedger — Design Decisions

This document outlines key technical decisions made during the architecture design of the **PocketLedger** application, explaining the trade-offs and rationale behind each choice.

---

## 1. Compile-Time URL Injection vs. Remote Configuration
**Decision:** Inject the backend URL at build time using Flutter's compile-time environment variables (`--dart-define`) instead of fetching it dynamically on app startup.

### Trade-off Analysis:
| Criteria | Compile-Time Injection (Chosen) | Remote Configuration |
|---|---|---|
| **Performance** | **Instant (Zero Latency):** App starts up and can connect directly. | **Delayed:** Adds a 1–2 second startup delay to query the DB first. |
| **Security** | **High:** URL is baked into code. Cannot be hijacked remotely. | **Low:** If DB is compromised, users can be redirected to a fake server. |
| **Robustness** | **High:** App functions normally even if Supabase is offline. | **Low:** If Supabase goes down, the backend URL cannot be resolved. |
| **Flexibility** | **Low:** Requires an app update/build to change domains. | **High:** Change domains instantly via database row update. |

### Rationale:
For PocketLedger, the production backend domain (hosted on Render/Vercel) is highly stable and expected to remain unchanged. Since we have automated CI/CD pipelines via GitHub Actions to compile release APKs instantly, the operational cost of releasing a new build if the domain *does* change is trivial. The performance (fast launch time) and security benefits far outweigh the flexibility of remote lookup.

---

## 2. Monorepo (Sibling Folders) vs. Multi-Repo Split
**Decision:** Maintain both projects in a single Git repository separated into `pocketledger-frontend/` and `pocketledger-backend/` directories, instead of split Git repositories.

### Rationale:
*   **Solo Development Velocity:** As a solo developer, making features that span both frontend and backend is vastly easier to track in a single pull request/commit. You don't have to keep branches in sync across different repositories.
*   **Decoupled CI/CD:** By using path filters in GitHub Actions and configuring independent build directories, we retain the ability to deploy the backend independently of the mobile app compilation steps.
*   **Explicit Boundaries:** Placing code in strict folders prevents leakage of backend code into the client, maintaining structural decoupling.

---

## 3. Delegation of Row Level Security (RLS) to Supabase
**Decision:** Use the FastAPI backend as a validation and proxy layer that forwards client authentication tokens (`Authorization: Bearer <JWT>`) directly to Supabase REST endpoints, rather than managing DB connections and query authorization directly in Python.

### Rationale:
*   **Single Source of Truth:** By forwarding the user's JWT token, we leverage Supabase's native PostgreSQL Row Level Security (RLS) policies. Security checks are executed at the database engine level.
*   **Dry Principles:** We don't have to write and duplicate authorization policies in Python code (FastAPI) and SQL. The backend client simply passes the `Authorization` and `X-Company-ID` headers along to Supabase, which enforces membership rules natively.

---

## 4. Offline-First Synchronization (Nuclear Sync)
**Decision:** Write immediately to Hive (local cache) for all user actions (create, edit, delete) to eliminate UI latency, then push changes asynchronously to the FastAPI backend.

### Rationale:
*   **User Experience:** Regular expense tracking apps feel sluggish if the app blocks interaction while waiting for a remote API to respond. Storing data locally first guarantees a 60FPS, zero-lag log interface.
*   **Automatic Reconciliation:** The "Nuclear Sync" process wipes and rebuilds Hive using the remote API as the single source of truth, ensuring that updates made on other devices are properly fetched while retaining any pending offline modifications.
