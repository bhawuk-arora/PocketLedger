# PocketLedger — Frontend Architecture Documentation

This document describes the structure, design patterns, and systems powering the **Flutter Mobile Application**.

---

## 🏗️ Folder Structure

The frontend code resides under `/pocketledger-frontend` and is organized using **Feature-First Architecture**:

```
lib/
├── core/
│   ├── api/
│   │   └── backend_client.dart    # Central HTTP API wrapper
│   ├── constants.dart             # Global keys, urls and defaults
│   ├── notification_service.dart  # Local notification scheduler
│   └── widget_service.dart        # Android/iOS native widget updates
│
├── features/
│   ├── auth/                      # Login, signup and session state
│   │   └── presentation/
│   │       ├── auth_notifier.dart
│   │       └── screens/
│   │           └── auth_screen.dart
│   │
│   ├── expenses/                  # Main ledger UI and local database
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── expense_model.dart  # Hive model adapters
│   │   │   └── repositories/
│   │   │       └── expense_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── dashboard_screen.dart
│   │       │   ├── all_transactions_screen.dart
│   │       │   └── monthly_analysis_screen.dart
│   │       └── widgets/
│   │           └── add_expense_sheet.dart
│   │
│   └── workspaces/                # Shared multi-user accounts
│       └── presentation/
│           └── workspace_provider.dart  # Active workspace state
│
└── main.dart                      # Flutter app setup & Hive initialization
```

---

## ⚡ State Management (Riverpod)

The application uses **Riverpod** for declarative dependency injection and UI state observation:

1.  **`workspaceProvider` (`StateNotifierProvider`):**
    *   Tracks the selected `company_id` UUID of the active workspace.
    *   Intercepts and injects this workspace ID into `backendClient.activeCompanyId` to automatically scope every network query.
2.  **`userCompaniesProvider` (`FutureProvider`):**
    *   Loads available shared workspaces that the authenticated user belongs to.
3.  **`expenseRepositoryProvider` (`Provider`):**
    *   Gives widgets access to the transaction data layer (`ExpenseRepository`).
4.  **`refreshSignalProvider` (`StateProvider`):**
    *   Acts as a quick refresh counter to force-reload transaction feeds.

---

## ⚛️ Offline-First & Sync Strategy

The app utilizes a hybrid offline-first strategy combining **Hive** (local key-value database) and the **FastAPI Backend** (single source of truth):

```
[Local Screen Interaction]
         │
         ▼
  [ExpenseRepository]
         │
         ├──► Write immediately to Hive Database (Instant UI Update)
         │
         └──► Try HTTP POST/PUT/DELETE to FastAPI Backend
                   │
                   ├─── Success ───► Set synced = true
                   │
                   └─── Failure ───► Leave synced = false (Retry on next Sync)
```

### 1. The Repository Layer (`ExpenseRepository`)
*   **Reads:** Streams data out of Hive (`watchExpenses()`), yielding cached entries instantly so the UI feels fast.
*   **Writes:** Saves transactions locally to Hive first (zero-lag), then pushes to the API asynchronously.

### 2. Nuclear Sync (`nuclearSync()`)
*   Triggers when the app starts, or when manual refresh is hit:
    1.  Iterates through local Hive entries to find un-synced expenses (`synced = false`) and pushes them to the FastAPI backend.
    2.  Fetches all records from `/api/transactions` for the active workspace.
    3.  Nukes the local Hive database and rebuilds it using backend data (ensuring cross-device updates reflect properly).
    4.  Re-appends any failed unsynced local entries.

---

## 🏢 Workspace Context Interceptor (`BackendClient`)

Located in `lib/core/api/backend_client.dart`, this HTTP helper acts as a wrapper around the `http` package:
*   Automatically fetches the active Supabase authentication JWT from `Supabase.instance.client.auth.currentSession`.
*   Appends the `Authorization: Bearer <TOKEN>` header dynamically.
*   Injects the `X-Company-ID` header if `activeCompanyId` is configured in `workspaceProvider`.
