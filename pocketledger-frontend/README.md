# PocketLedger Frontend 📱

A modern, professional, and responsive personal finance tracker built with Flutter.

---

## ✨ Features (Sleek & Powerful)

*   **Zero-Lag Logger ⚡:** Tap "Save Expense" and the screen updates instantly with local-first Hive caching. No waiting for the database to reply while you stand awkwardly at the cashier.
*   **Double-Tap Shield 🛡️:** Buttons disable instantly to prevent duplicate transaction entries.
*   **Vibrant Categories 🏷️:**
    *   🛒 *Food & Groceries*
    *   🚌 *Commute*
    *   🚂 *Travel*
    *   🛍️ *Shopping*
    *   📨 *Bills*
    *   🎬 *Entertainment*
    *   💊 *Health*
    *   ⚽ *Sports*
    *   📈 *Investments*
    *   🏷️ *Miscellaneous*
*   **Dynamic Insight Cards 📊:** Flexible pie charts and bar graphs that automatically expand and scale to perfectly fit your category breakdowns without pixel overflow.
*   **Smart Sync ⚛️:** Automatically syncs with the FastAPI backend database when online. Offline? Hive stores it locally and pushes it later.
*   **Smart Notifications 🔔:** Provides contextual, scheduled reminders to log daily transactions.

---

## 🛠️ Run & Build Instructions

### Running in Development
For local development targeting a local FastAPI backend running on your emulator:
```bash
flutter run
```

### Targeting a Live Production Backend
Inject your production backend URL dynamically using the `BACKEND_URL` compile-time constant:
```bash
flutter run --dart-define=BACKEND_URL=https://your-backend-service.render.com
```

### Building the Release APK
Build the release bundle with the production backend URL defined:
```bash
flutter build apk --release --dart-define=BACKEND_URL=https://your-backend-service.render.com
```
