# Ireland Visa Checker — Android App

Native Android app (Flutter) + FastAPI backend for checking Irish visa application decisions across five embassies (New Delhi, Beijing, Abuja, Abu Dhabi, Ankara).

---

## Architecture

```
┌─────────────────────┐        REST API        ┌───────────────────────────┐
│   Flutter Android   │ ─────────────────────▶ │   FastAPI Backend         │
│   (Play Store app)  │                         │   (HuggingFace / Render)  │
└─────────────────────┘                         └───────────┬───────────────┘
                                                            │  scrapes
                                                            ▼
                                                      ireland.ie
                                               (ODS spreadsheets + PDFs)
```

---

## Repo structure

```
ireland-visa-checker-android/
├── backend/
│   ├── main.py          # FastAPI app — all API endpoints
│   ├── fetchers.py      # HTTP fetch, ODS/PDF parsing, 3-tier cache logic
│   ├── cache.py         # Disk cache with ETag/Last-Modified support
│   ├── embassies.py     # Embassy registry (add new embassies here)
│   ├── requirements.txt
│   └── Dockerfile
└── flutter_app/
    ├── pubspec.yaml
    ├── android/
    │   └── app/src/main/AndroidManifest.xml
    └── lib/
        ├── main.dart
        ├── models/
        │   ├── visa_result.dart
        │   └── embassy_info.dart
        ├── services/
        │   └── api_service.dart
        ├── providers/
        │   └── visa_provider.dart
        ├── screens/
        │   └── home_screen.dart
        └── widgets/
            ├── check_tab.dart
            ├── embassies_tab.dart
            ├── embassy_card.dart
            ├── decision_badge.dart
            └── stats_row.dart
```

---

## 1 — Backend setup

### Run locally

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

API docs available at `http://localhost:8000/docs`.

### Deploy to HuggingFace Spaces (free)

1. Create a new Space → SDK: **Docker**
2. Upload the `backend/` folder contents
3. The `Dockerfile` is already configured — HuggingFace will build and serve it
4. Note your Space URL (e.g. `https://your-username-ireland-visa-api.hf.space`)

### Deploy to Render (free tier)

1. Push `backend/` to a GitHub repo
2. New Web Service → Docker → set port 8000
3. Copy the public URL

---

## 2 — Flutter app setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.22
- Android Studio + Android SDK (API 21+)

### First-time project initialisation

Flutter needs its boilerplate generated once:

```bash
cd flutter_app
flutter create . --org com.yourname --project-name ireland_visa_checker
# This generates android/, ios/, test/ scaffolding without overwriting lib/ or pubspec.yaml
```

### Point the app at your backend

Edit [`flutter_app/lib/services/api_service.dart`](flutter_app/lib/services/api_service.dart):

```dart
static const String baseUrl = 'https://your-backend-url.hf.space';
// For local testing with Android emulator use: http://10.0.2.2:8000
```

### Run on emulator / device

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 3 — Build release APK / AAB

```bash
cd flutter_app

# Generate a signing key (one-time)
keytool -genkey -v -keystore android/key.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload

# Create android/key.properties
cat > android/key.properties <<EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../key.jks
EOF

# Build App Bundle (required for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 4 — Play Store submission checklist

- [ ] Google Play Developer account ($25 one-time fee at play.google.com/console)
- [ ] App icon (512×512 PNG)
- [ ] Feature graphic (1024×500 PNG)
- [ ] At least 2 screenshots (phone)
- [ ] Short description (≤80 chars) and full description
- [ ] Privacy Policy URL (required — even for a simple data-lookup app)
- [ ] Target API level ≥ 34 (current Play Store requirement)
- [ ] Upload `app-release.aab` to a new app in Play Console → Production track

---

## API reference

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/embassies` | All embassy statuses + record counts |
| GET | `/api/stats` | Aggregate totals (total / approved / refused) |
| POST | `/api/check` | Check an application number |
| POST | `/api/refresh` | Force-refresh all embassy data |

### POST `/api/check` example

```json
// Request
{ "application_number": "63690452" }

// Found
{
  "application_number": "63690452",
  "found": true,
  "results": [
    { "embassy": "New Delhi", "decision": "APPROVED", "source": "Oct 2024" }
  ],
  "nearest": null
}

// Not found
{
  "application_number": "63690452",
  "found": false,
  "results": [],
  "nearest": {
    "before": { "number": "63690451", "embassy": "New Delhi", "decision": "APPROVED" },
    "after":  { "number": "63690453", "embassy": "New Delhi", "decision": "REFUSED" }
  }
}
```
