---
title: Ireland Visa API
emoji: 🌍
colorFrom: green
colorTo: green
sdk: docker
app_port: 8000
pinned: false
---

# Ireland Visa Checker — API Backend

FastAPI backend that scrapes Irish visa decisions from ireland.ie and exposes them via REST API.

## Endpoints

- `GET /api/health` — health check
- `GET /api/embassies` — all embassy statuses
- `GET /api/stats` — total / approved / refused counts
- `POST /api/check` — check an application number
- `POST /api/refresh` — force refresh all data
