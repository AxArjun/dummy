# FuelIQ — System Architecture
**Phase 2 | Version 1.0.0**

---

## 1. High-Level Architecture Overview

FuelIQ follows a **Cloud-Native Microservices-Ready Monolith** pattern for MVP — a structured monolith that can be decomposed into microservices as load demands. This is the pragmatic choice for a startup: move fast, maintain quality, defer complexity.

### Architecture Principles
1. **Stateless API Layer** — All state in DB/Redis, enabling horizontal scaling
2. **Repository Pattern** — DB access abstracted behind repositories
3. **Event-Driven Notifications** — Async notification delivery via Redis queues
4. **Defense in Depth** — Auth at gateway + per-route + per-resource level
5. **12-Factor App** — Config via env vars, logs to stdout, disposable processes

---

## 2. PlantUML Diagrams

### 2.1 High-Level Architecture

```plantuml
@startuml FuelIQ_High_Level_Architecture
!define ICONURL https://raw.githubusercontent.com/tupadr3/plantuml-icon-font-sprites/v2.4.0
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam defaultFontName "Inter"
skinparam ArrowColor #58A6FF
skinparam BorderColor #30363D
skinparam RectangleBorderColor #30363D
skinparam RectangleBackgroundColor #161B22

title FuelIQ — High-Level Architecture

actor "Mobile User\n(Flutter App)" as User

rectangle "Edge Layer" #1C2128 {
  component "Cloudflare CDN\n+ WAF" as CDN
  component "Load Balancer\n(Nginx)" as LB
}

rectangle "Application Layer" #1C2128 {
  component "FastAPI\nService\n(Python 3.13)" as API
  component "FastAPI\nService\n(Replica 2)" as API2
  component "Background\nWorker\n(Celery)" as Worker
}

rectangle "Auth Layer" #1C2128 {
  component "Clerk\nAuth Service" as Clerk
}

rectangle "Data Layer" #1C2128 {
  database "PostgreSQL\n(Primary)" as PGPrimary
  database "PostgreSQL\n(Read Replica)" as PGReplica
  database "Redis\nCluster" as Redis
}

rectangle "Storage Layer" #1C2128 {
  storage "MinIO / S3\n(Object Storage)" as S3
}

rectangle "External Services" #1C2128 {
  component "Firebase\nCloud Messaging" as FCM
  component "Google\nML Kit" as MLKit
}

rectangle "Observability" #1C2128 {
  component "Prometheus\n+ Grafana" as Monitor
  component "Sentry\n(Error Tracking)" as Sentry
}

User --> CDN : HTTPS
CDN --> LB : Forward
LB --> API : Route
LB --> API2 : Route (load balanced)
API --> Clerk : Verify JWT
API --> PGPrimary : Writes
API --> PGReplica : Reads
API --> Redis : Cache / Sessions
API --> S3 : Receipt Storage
API --> Worker : Async Tasks (Redis Queue)
Worker --> FCM : Push Notifications
Worker --> PGPrimary : Reminder Processing
API --> Monitor : Metrics
API --> Sentry : Errors
User -[#58A6FF]-> MLKit : OCR (on-device)

@enduml
```

---

### 2.2 Component Diagram

```plantuml
@startuml FuelIQ_Component_Diagram
skinparam componentStyle rectangle
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam ArrowColor #58A6FF
skinparam componentBorderColor #30363D
skinparam componentBackgroundColor #161B22
skinparam packageBorderColor #30363D
skinparam packageBackgroundColor #1C2128

title FuelIQ — Component Diagram

package "Flutter Mobile App" {
  [Presentation Layer\n(Screens + Widgets)] as UI
  [State Management\n(Riverpod Providers)] as SM
  [Domain Layer\n(Use Cases)] as Domain
  [Data Layer\n(Repositories)] as DataLayer
  [Network\n(Retrofit + Dio)] as Network
  [Local Storage\n(Hive + SharedPrefs)] as Local
  [OCR Engine\n(Google ML Kit)] as OCR

  UI --> SM
  SM --> Domain
  Domain --> DataLayer
  DataLayer --> Network
  DataLayer --> Local
}

package "FastAPI Backend" {
  [API Gateway\n(Route Registration)] as Gateway
  [Auth Middleware\n(Clerk JWT Verify)] as AuthMW
  [Rate Limiter\n(Redis Sliding Window)] as RateLimit
  
  package "Modules" {
    [Auth Router] as AuthR
    [Users Router] as UsersR
    [Vehicles Router] as VehiclesR
    [Fuel Router] as FuelR
    [Expenses Router] as ExpR
    [Services Router] as SvcR
    [Analytics Router] as AnaR
    [Notifications Router] as NotR
    [OCR Router] as OCRR
  }
  
  package "Services" {
    [Auth Service] as AuthSvc
    [Fuel Service] as FuelSvc
    [Analytics Service] as AnaSvc
    [Notification Service] as NotSvc
    [OCR Service] as OCRSvc
    [Storage Service] as StorSvc
  }
  
  package "Repositories" {
    [User Repository] as UserRepo
    [Vehicle Repository] as VehRepo
    [Fuel Repository] as FuelRepo
    [Analytics Repository] as AnaRepo
  }
  
  Gateway --> AuthMW
  AuthMW --> RateLimit
  RateLimit --> AuthR
  RateLimit --> UsersR
  RateLimit --> VehiclesR
  RateLimit --> FuelR
  RateLimit --> ExpR
  RateLimit --> SvcR
  RateLimit --> AnaR
  RateLimit --> NotR
  RateLimit --> OCRR
  
  FuelR --> FuelSvc
  AnaR --> AnaSvc
  NotR --> NotSvc
  
  FuelSvc --> FuelRepo
  AnaSvc --> AnaRepo
}

package "Infrastructure" {
  database "PostgreSQL" as PG
  database "Redis" as Redis
  storage "MinIO" as Minio
  [Celery Worker] as Celery
  [Firebase FCM] as FCM
}

Network --> Gateway : REST/HTTPS
FuelRepo --> PG
UserRepo --> PG
AnaRepo --> PG
AuthSvc --> Redis : Token Blacklist
FuelSvc --> Redis : Cache
StorSvc --> Minio
Celery --> FCM : Push
NotSvc --> Celery : Queue Task

@enduml
```

---

### 2.3 Deployment Diagram

```plantuml
@startuml FuelIQ_Deployment_Diagram
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam ArrowColor #58A6FF
skinparam nodeBorderColor #30363D
skinparam nodeBackgroundColor #1C2128
skinparam artifactBorderColor #388BFD
skinparam artifactBackgroundColor #161B22

title FuelIQ — Deployment Diagram (Docker Compose / K8s Ready)

node "User Device\n(Android)" as Device {
  artifact "FuelIQ Flutter App\n(Release APK)" as App
}

node "Cloudflare" as CF {
  artifact "WAF + DDoS\nProtection" as WAF
  artifact "CDN Edge\nCache" as CDNEdge
}

node "VPS / Cloud VM\n(Docker Host)" as Host {
  node "Docker Network: fueliq_net" as DockerNet {
    
    node "nginx:alpine" as Nginx {
      artifact "Reverse Proxy\nSSL Termination\nLoad Balancer" as NginxArt
    }
    
    node "fueliq-api:latest" as APIContainer {
      artifact "FastAPI App\n(Uvicorn + Gunicorn)\nPort 8000" as APIC
    }
    
    node "fueliq-worker:latest" as WorkerContainer {
      artifact "Celery Worker\n(Reminder Engine)\n4 Concurrency" as WorkerArt
    }
    
    node "fueliq-beat:latest" as BeatContainer {
      artifact "Celery Beat\n(Scheduler)\nCron Jobs" as BeatArt
    }
    
    node "postgres:15" as PGNode {
      artifact "PostgreSQL\nPort 5432\nVolume: pg_data" as PGArt
    }
    
    node "redis:7" as RedisNode {
      artifact "Redis\nPort 6379\nVolume: redis_data" as RedisArt
    }
    
    node "minio:latest" as MinioNode {
      artifact "MinIO\nPort 9000/9001\nVolume: minio_data" as MinioArt
    }
  }
}

node "External Cloud" as External {
  artifact "Clerk\nAuth SaaS" as ClerkExt
  artifact "Firebase\nFCM" as FCMExt
  artifact "Sentry\nError Tracking" as SentryExt
  artifact "Google\nML Kit (SDK)" as MLKitExt
}

Device --> CF : HTTPS 443
CF --> Nginx : Proxy
Nginx --> APIContainer : /api/* → :8000
APIContainer --> PGNode : :5432
APIContainer --> RedisNode : :6379
APIContainer --> MinioNode : :9000
APIContainer --> ClerkExt : JWKS Verification
WorkerContainer --> RedisNode : Task Queue
WorkerContainer --> FCMExt : Push Notifications
WorkerContainer --> PGNode : Read/Write
BeatContainer --> RedisNode : Schedule Tasks
APIContainer --> SentryExt : Error Reports
App --> MLKitExt : On-Device OCR

@enduml
```

---

### 2.4 Authentication Flow

```plantuml
@startuml FuelIQ_Auth_Flow
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam ArrowColor #58A6FF
skinparam sequenceLifeLineBorderColor #58A6FF
skinparam sequenceBoxBorderColor #30363D
skinparam sequenceBoxBackgroundColor #1C2128
skinparam participantBorderColor #388BFD
skinparam participantBackgroundColor #161B22

title FuelIQ — Authentication Flow (Clerk + FastAPI)

participant "Flutter App" as App
participant "Clerk SDK" as Clerk
participant "Clerk Backend" as ClerkBE
participant "FastAPI" as API
participant "PostgreSQL" as DB
participant "Redis" as Cache

== Registration Flow ==
App -> Clerk: signUp(email, password)
Clerk -> ClerkBE: Create User Account
ClerkBE --> Clerk: User Created + Session Token
Clerk --> App: SessionToken + JWT
App -> API: POST /v1/auth/sync-user\nBearer: JWT
API -> ClerkBE: GET /jwks (verify JWT)
ClerkBE --> API: Public Key
API -> API: Verify JWT Signature
API -> DB: INSERT INTO users (clerk_id, email, ...)
DB --> API: User Record Created
API -> Cache: SET user:{id} ttl=3600
API --> App: 201 { user, profile }

== Login Flow ==
App -> Clerk: signIn(email, password)
Clerk -> ClerkBE: Authenticate
ClerkBE --> Clerk: Session + JWT (short-lived, 60s)
Clerk --> App: access_token + refresh context
App -> API: Any protected request\nAuthorization: Bearer {access_token}

== JWT Verification (Every Request) ==
API -> API: Extract Bearer token
API -> Cache: GET jwks_cache
alt Cache Hit
  Cache --> API: Cached JWKS
else Cache Miss
  API -> ClerkBE: GET /.well-known/jwks.json
  ClerkBE --> API: JWKS
  API -> Cache: SET jwks_cache ttl=86400
end
API -> API: Verify signature, expiry, issuer
alt Token Valid
  API -> API: Extract user_id (sub claim)
  API -> Cache: GET user:{user_id}
  alt User Cache Hit
    Cache --> API: User object
  else Cache Miss
    API -> DB: SELECT * FROM users WHERE clerk_id = ?
    DB --> API: User record
    API -> Cache: SET user:{user_id} ttl=3600
  end
  API --> App: 200 Response
else Token Invalid/Expired
  API --> App: 401 Unauthorized
  App -> Clerk: Refresh session
  Clerk -> ClerkBE: Refresh tokens
  ClerkBE --> App: New access_token
  App -> API: Retry request
end

== Logout Flow ==
App -> Clerk: signOut()
Clerk -> ClerkBE: Invalidate session
App -> API: POST /v1/auth/logout\nBearer: JWT
API -> Cache: DEL user:{user_id}
API --> App: 200 OK

@enduml
```

---

### 2.5 Fuel Logging Flow

```plantuml
@startuml FuelIQ_Fuel_Logging_Flow
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam ArrowColor #58A6FF
skinparam sequenceLifeLineBorderColor #58A6FF
skinparam participantBorderColor #388BFD
skinparam participantBackgroundColor #161B22

title FuelIQ — Fuel Logging Flow

participant "Flutter App" as App
participant "FastAPI" as API
participant "Fuel Service" as FuelSvc
participant "Analytics Service" as AnaSvc
participant "PostgreSQL" as DB
participant "Redis Cache" as Cache

== Manual Fuel Log Entry ==
App -> App: User fills: odometer, liters, price_per_liter
App -> API: POST /v1/vehicles/{id}/fuel-logs\n{ odometer, volume_liters, price_per_liter,\n  is_full_tank, station_name, notes }
API -> API: Validate JWT + ownership
API -> FuelSvc: create_fuel_log(vehicle_id, user_id, dto)

FuelSvc -> DB: SELECT last_full_tank_log\nWHERE vehicle_id = ? AND is_full_tank = true\nORDER BY odometer DESC LIMIT 1
DB --> FuelSvc: Previous log

alt Full tank fill available
  FuelSvc -> FuelSvc: efficiency = (odometer - prev_odometer) / prev_volume
  FuelSvc -> FuelSvc: total_cost = volume * price_per_liter
else No previous full tank
  FuelSvc -> FuelSvc: efficiency = null (insufficient data)
end

FuelSvc -> DB: INSERT INTO fuel_logs\n(vehicle_id, odometer, volume_liters,\n price_per_liter, total_cost, efficiency_lper100km,\n is_full_tank, logged_at)
DB --> FuelSvc: fuel_log record

FuelSvc -> DB: UPDATE vehicles\nSET current_odometer = ?\nWHERE id = ?
DB --> FuelSvc: Updated

FuelSvc -> Cache: INVALIDATE vehicle:{id}:stats
FuelSvc -> Cache: INVALIDATE user:{uid}:dashboard

FuelSvc -> AnaSvc: async compute_analytics(vehicle_id)
AnaSvc -> DB: Recalculate rolling averages
AnaSvc -> Cache: SET vehicle:{id}:analytics ttl=3600

FuelSvc --> API: FuelLogResponse
API --> App: 201 { fuel_log, efficiency, total_cost }

App -> App: Show efficiency badge\n"42.3 km/L — Best ever! 🎉"

@enduml
```

---

### 2.6 OCR Flow

```plantuml
@startuml FuelIQ_OCR_Flow
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam ArrowColor #58A6FF
skinparam sequenceLifeLineBorderColor #58A6FF
skinparam participantBorderColor #388BFD
skinparam participantBackgroundColor #161B22

title FuelIQ — OCR Receipt Scanning Flow

participant "Flutter App" as App
participant "Camera" as Cam
participant "ML Kit OCR\n(On-Device)" as MLKit
participant "OCR Parser\n(Dart)" as Parser
participant "FastAPI" as API
participant "MinIO Storage" as Storage
participant "PostgreSQL" as DB

== Receipt Capture ==
App -> Cam: Open camera (portrait mode)
Cam --> App: Image frame stream
App -> App: Show real-time edge detection
App -> Cam: Capture image (JPEG, max 2MB)

== On-Device OCR Processing ==
App -> MLKit: processImage(InputImage)
MLKit -> MLKit: Text block detection\nLine segmentation\nWord recognition
MLKit --> App: List<TextBlock>\n(raw text elements with bounding boxes)

== Intelligent Parsing ==
App -> Parser: parse(textBlocks)
Parser -> Parser: Pattern match: fuel_volume\n(regex: \d+\.?\d*\s*(L|litre|liter|लीटर))
Parser -> Parser: Pattern match: price_per_unit\n(regex: ₹|Rs\.?\s*\d+\.\d{2}/L)
Parser -> Parser: Pattern match: total_amount\n(regex: Total\s*:?\s*₹?\s*\d+\.\d{2})
Parser -> Parser: Pattern match: date\n(regex: \d{1,2}[/-]\d{1,2}[/-]\d{2,4})
Parser -> Parser: Confidence scoring per field
Parser --> App: ParsedReceiptData\n{ volume, price_per_unit, total, date, confidence }

== User Confirmation ==
App -> App: Show pre-filled form\nwith confidence indicators
App -> App: User reviews + corrects if needed
App -> App: User taps "Log Fuel"

== Upload & Save ==
App -> API: POST /v1/ocr/upload-receipt\nMultipart: { image_file, vehicle_id }
API -> Storage: PUT receipts/{user_id}/{uuid}.jpg
Storage --> API: Receipt URL
API --> App: { receipt_url }

App -> API: POST /v1/vehicles/{id}/fuel-logs\n{ ...parsed_data, receipt_url }
API -> DB: INSERT fuel_log with receipt_url
DB --> API: Created
API --> App: 201 FuelLog

@enduml
```

---

### 2.7 Notification Flow

```plantuml
@startuml FuelIQ_Notification_Flow
skinparam backgroundColor #0D1117
skinparam defaultFontColor #E6EDF3
skinparam ArrowColor #58A6FF
skinparam sequenceLifeLineBorderColor #58A6FF
skinparam participantBorderColor #388BFD
skinparam participantBackgroundColor #161B22

title FuelIQ — Notification Flow (Service Reminders)

participant "Celery Beat\n(Scheduler)" as Beat
participant "Celery Worker" as Worker
participant "PostgreSQL" as DB
participant "Redis" as Queue
participant "Notification Service" as NotSvc
participant "Firebase FCM" as FCM
participant "Flutter App" as App

== Scheduled Trigger (Daily at 08:00 UTC) ==
Beat -> Queue: ENQUEUE check_reminders_task
Queue --> Worker: Dequeue task

Worker -> DB: SELECT r.*, u.fcm_token\nFROM reminders r\nJOIN vehicles v ON r.vehicle_id = v.id\nJOIN users u ON v.user_id = u.id\nWHERE r.remind_at <= NOW() + INTERVAL '7 days'\n  AND r.is_completed = false\n  AND r.notification_sent = false
DB --> Worker: List<ReminderWithUser>

loop For each reminder
  Worker -> NotSvc: send_push_notification(user, reminder)
  NotSvc -> DB: INSERT INTO notifications\n(user_id, type, title, body, metadata)
  DB --> NotSvc: notification_id
  NotSvc -> FCM: POST /v1/projects/{id}/messages:send\n{ token, notification, data }
  FCM --> NotSvc: message_id
  NotSvc -> DB: UPDATE reminders\nSET notification_sent = true\n    notification_sent_at = NOW()
  DB --> NotSvc: OK
end

== App Receives Notification ==
FCM -> App: FCM Push (background)
App -> App: Show system notification
App -> App: User taps notification
App -> App: Navigate to service reminder screen

== In-App Notification Center ==
App -> "FastAPI" as API: GET /v1/notifications?page=1
API -> DB: SELECT * FROM notifications\nWHERE user_id = ? ORDER BY created_at DESC
DB --> API: List<Notification>
API --> App: Paginated notifications
App -> App: Show notification list\nwith unread badges

@enduml
```

---

## 3. Architecture Decision Records (ADRs)

### ADR-001: Structured Monolith over Microservices
**Decision**: Start with a structured monolith (FastAPI with module boundaries)
**Rationale**: At MVP scale, microservices add deployment complexity without benefits. Module boundaries are enforced through code structure, enabling extraction later.
**Tradeoff**: Single deploy unit; all modules scale together. Acceptable at < 100K users.
**Exit criteria**: Extract as independent services when any module requires independent scaling or different deployment cadence.

### ADR-002: Clerk for Authentication
**Decision**: Use Clerk as the auth provider
**Rationale**: Clerk handles all auth complexity (JWKS rotation, OAuth, MFA, session management) with a Flutter-compatible SDK. Eliminates 2-3 weeks of auth implementation risk.
**Tradeoff**: Vendor dependency, pricing at scale. Migration path: implement own OIDC server using Hydra if Clerk becomes cost-prohibitive.
**Security**: JWT verification uses Clerk's JWKS endpoint with 24h caching. Token never touches our DB — only the `sub` claim (Clerk user ID) is stored.

### ADR-003: Redis for Caching + Queue
**Decision**: Use Redis for both cache and Celery broker
**Rationale**: Reduces infrastructure components at MVP. Redis 7+ supports persistence and clustering.
**Tradeoff**: Single point of failure without Redis Cluster. Mitigated with Redis Sentinel (single AZ) at MVP, Cluster at scale.

### ADR-004: PostgreSQL with Read Replica
**Decision**: Primary + Read Replica from day one
**Rationale**: Analytics queries are read-heavy. Separating read traffic protects write performance.
**Implementation**: Writes always go to primary. Analytics/reporting queries routed to replica via SQLAlchemy connection pool.

### ADR-005: On-Device OCR (ML Kit)
**Decision**: Process OCR on-device, not via API
**Rationale**: Eliminates round-trip latency, reduces backend costs, works offline, and avoids sending raw receipt images to the server (privacy).
**Tradeoff**: OCR quality varies by device capability. Mitigation: confidence scoring, user correction flow.

---

## 4. Scalability Analysis

| Load | Strategy | Components |
|---|---|---|
| 0–1K users | Single host, Docker Compose | API × 1, PG × 1, Redis × 1 |
| 1K–10K users | Add read replica, Redis sentinel | API × 2, PG primary+replica, Redis sentinel |
| 10K–100K users | Horizontal API scaling, CDN | API × N behind LB, PG with connection pooling (PgBouncer), Redis Cluster |
| 100K–1M users | K8s, service extraction | Separate analytics service, event-driven architecture, Kafka |
| 1M+ users | Full microservices, global | Multi-region, CQRS, separate read/write models |

---

*Document Owner: Principal Architect + Senior Backend Engineer*
