# FuelIQ — Vehicle Intelligence Platform

> **Production-grade SaaS** | Flutter + FastAPI + PostgreSQL + Redis + MinIO + Firebase

[![CI/CD](https://github.com/AxArjun/dummy/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/AxArjun/dummy/actions)

---

## What is FuelIQ?

FuelIQ is a Vehicle Intelligence Platform that gives vehicle owners complete visibility into fuel consumption, expenses, service history, and vehicle health — delivered through a premium Android app.

### Features
- 🚗 **Multi-vehicle garage** — manage all your vehicles in one place
- ⛽ **Smart fuel logging** — automatic efficiency calculation (L/100km, km/L, MPG)
- 📷 **OCR receipt scanning** — scan fuel receipts with Google ML Kit (on-device)
- 📊 **Analytics engine** — cost per km, monthly trends, efficiency tracking
- 🔔 **Service reminders** — date-based and odometer-based push notifications
- 💸 **Expense tracking** — full cost-of-ownership across 10 categories
- 🔒 **Enterprise security** — Clerk auth, JWT, rate limiting, OWASP controls

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter + Dart + Material 3 + Riverpod + Go Router + Freezed |
| Auth | Clerk |
| Backend | FastAPI + Python 3.13 |
| Database | PostgreSQL 16 (partitioned tables, materialized views) |
| Cache | Redis 7 |
| Storage | MinIO / AWS S3 |
| Notifications | Firebase Cloud Messaging |
| OCR | Google ML Kit (on-device) |
| Deployment | Docker + Docker Compose (Kubernetes-ready) |
| CI/CD | GitHub Actions |

---

## Project Structure

```
fueliq/
├── backend/           # FastAPI application
│   ├── app/
│   │   ├── api/v1/    # REST routers (9 modules)
│   │   ├── core/      # Auth, DB, Cache, Storage
│   │   ├── models/    # SQLAlchemy ORM
│   │   ├── modules/   # Business logic services
│   │   ├── repositories/ # Data access layer
│   │   ├── schemas/   # Pydantic v2 request/response
│   │   ├── middleware/ # Security, rate limiting
│   │   └── tasks/     # Celery background tasks
│   ├── Dockerfile
│   └── requirements.txt
├── mobile/            # Flutter Android app
│   ├── lib/
│   │   ├── core/      # Network, Router, Auth
│   │   ├── features/  # Feature-first modules
│   │   └── shared/    # Theme, Models, Widgets
│   └── pubspec.yaml
├── docs/              # Architecture & PRD documents
│   ├── phase-01-prd.md
│   ├── phase-02-architecture.md
│   ├── phase-03-database.md
│   └── phase-16-future-scale.md
├── docker-compose.yml # Full stack orchestration
├── .env.example       # Environment template
└── .github/workflows/ # CI/CD pipeline
```

---

## Quick Start

### Prerequisites
- Docker + Docker Compose
- Flutter SDK 3.19+
- Python 3.13+ (for local dev)

### 1. Setup Environment
```bash
cp .env.example .env
# Edit .env with your Clerk, Firebase, and database credentials
```

### 2. Start Backend
```bash
docker compose up -d
docker compose run --rm migrate     # Run DB migrations
curl http://localhost:8000/health   # Verify
```

### 3. View API Docs (dev mode)
```
http://localhost:8000/docs
```

### 4. Run Flutter App
```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Architecture

See [phase-02-architecture.md](docs/phase-02-architecture.md) for full PlantUML diagrams including:
- High-Level Architecture
- Component Diagram  
- Authentication Flow
- Fuel Logging Flow
- OCR Flow
- Notification Flow

---

## Documentation

| Phase | Document |
|---|---|
| Phase 1 | [Product Requirements Document](docs/phase-01-prd.md) |
| Phase 2 | [System Architecture](docs/phase-02-architecture.md) |
| Phase 3 | [Database Design](docs/phase-03-database.md) |
| Phase 16 | [Future Scale (100K–10M users)](docs/phase-16-future-scale.md) |

---

## License

Private — All rights reserved. FuelIQ © 2026
