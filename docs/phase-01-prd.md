# FuelIQ — Product Requirements Document
**Version**: 1.0.0 | **Status**: Approved | **Date**: 2026-06-01

---

## 1. Vision

> **FuelIQ transforms every vehicle owner into an informed driver.**
>
> We believe that your vehicle is one of the largest investments you make — yet most people have no idea how much it truly costs them, when it needs attention, or how efficiently it's running. FuelIQ eliminates that blind spot.

FuelIQ is a Vehicle Intelligence Platform that gives individuals and fleet operators complete visibility into their vehicle's health, fuel consumption, expenses, and performance — delivered through a beautiful, intelligent mobile experience.

---

## 2. Mission

To democratize vehicle data intelligence by providing every vehicle owner — from a daily commuter to a small fleet operator — with the tools previously available only to enterprise automotive companies.

**We will achieve this by:**
- Making fuel and expense tracking frictionless (< 30 seconds per fill)
- Using AI-assisted OCR to eliminate manual data entry
- Delivering actionable insights that drive real-world savings
- Building a platform that scales from 1 vehicle to 10,000 vehicles

---

## 3. Problem Statement

### Current Pain Points
| Pain Point | Impact |
|---|---|
| Fuel tracking is manual and forgotten | Users lose visibility into consumption trends |
| No centralized vehicle expense record | Tax time and resale value suffer |
| Service reminders are scattered | Missed maintenance leads to breakdowns |
| No data-driven driving insights | Inefficient behavior persists |
| Multiple vehicles = multiple spreadsheets | Cognitive overload for owners |

### Market Context
- 1.4 billion vehicles on the road globally
- Average household owns 2+ vehicles
- 60% of vehicle owners don't track maintenance schedules
- $200B+ in preventable vehicle damage annually due to missed maintenance

---

## 4. User Personas

### Persona 1 — Arjun, The Daily Commuter
- **Age**: 28 | **Occupation**: Software Engineer | **Location**: Bangalore
- **Vehicles**: 1 car (Maruti Swift)
- **Pain Points**: No idea of monthly fuel cost, forgets oil changes, receipts pile up
- **Goals**: Know exactly what his car costs per month, never miss a service
- **Tech Comfort**: High — uses 8+ apps daily
- **Key Feature**: Quick fuel log (< 30s), smart reminders

### Persona 2 — Priya, The Working Parent
- **Age**: 35 | **Occupation**: Doctor | **Location**: Mumbai
- **Vehicles**: 2 (SUV + Scooter)
- **Pain Points**: Manages two vehicles, wants one place for everything
- **Goals**: Track both vehicles, understand total transport cost, service history for resale
- **Tech Comfort**: Medium — prefers simplicity
- **Key Feature**: Multi-vehicle garage, expense summaries, OCR receipts

### Persona 3 — Rajan, The Small Fleet Operator
- **Age**: 45 | **Occupation**: Transport Business Owner | **Location**: Delhi
- **Vehicles**: 8–15 commercial vehicles
- **Pain Points**: Manual ledgers, no analytics, drivers inflate fuel reports
- **Goals**: Per-vehicle fuel efficiency, anomaly detection, cost reports
- **Tech Comfort**: Low-Medium — needs simple UI, powerful data
- **Key Feature**: Analytics dashboard, anomaly detection, export reports

### Persona 4 — Meera, The Eco-Conscious Driver
- **Age**: 24 | **Occupation**: Marketing Manager | **Location**: Pune
- **Vehicles**: 1 Electric Vehicle (EV + old petrol bike)
- **Pain Points**: Wants to track charging costs alongside petrol
- **Goals**: Carbon footprint tracking, efficiency improvement, savings tips
- **Tech Comfort**: High
- **Key Feature**: Fuel efficiency trends, eco-scoring, insights

---

## 5. Functional Requirements

### 5.1 Authentication & Identity
| ID | Requirement | Priority |
|---|---|---|
| FR-AUTH-01 | Users can register via email + password | P0 |
| FR-AUTH-02 | Users can login via email + password | P0 |
| FR-AUTH-03 | Users can login via Google OAuth | P0 |
| FR-AUTH-04 | Users can login via Apple OAuth | P1 |
| FR-AUTH-05 | Multi-factor authentication (TOTP/SMS) | P1 |
| FR-AUTH-06 | Password reset via email | P0 |
| FR-AUTH-07 | JWT-based session management | P0 |
| FR-AUTH-08 | Automatic token refresh | P0 |
| FR-AUTH-09 | Logout from all devices | P1 |

### 5.2 User Profile Management
| ID | Requirement | Priority |
|---|---|---|
| FR-USER-01 | View and edit profile (name, photo, preferences) | P0 |
| FR-USER-02 | Set distance unit preference (km/miles) | P0 |
| FR-USER-03 | Set fuel volume unit preference (L/gallon) | P0 |
| FR-USER-04 | Set currency preference | P0 |
| FR-USER-05 | Delete account with data export | P1 |
| FR-USER-06 | Notification preferences management | P1 |

### 5.3 Vehicle Management (Garage)
| ID | Requirement | Priority |
|---|---|---|
| FR-VEH-01 | Add vehicle with make, model, year, fuel type, license plate | P0 |
| FR-VEH-02 | Upload vehicle photo | P1 |
| FR-VEH-03 | Edit vehicle details | P0 |
| FR-VEH-04 | Archive/delete vehicle | P0 |
| FR-VEH-05 | Set primary vehicle | P0 |
| FR-VEH-06 | Support multiple vehicle types (car, bike, truck, EV) | P0 |
| FR-VEH-07 | Set odometer at vehicle creation | P0 |
| FR-VEH-08 | View vehicle summary (total cost, fills, efficiency) | P0 |
| FR-VEH-09 | Vehicle service history timeline | P1 |

### 5.4 Fuel Logging
| ID | Requirement | Priority |
|---|---|---|
| FR-FUEL-01 | Log fuel fill (date, odometer, liters, cost, station) | P0 |
| FR-FUEL-02 | Mark fill as full tank or partial | P0 |
| FR-FUEL-03 | Auto-calculate fuel efficiency (L/100km or km/L or MPG) | P0 |
| FR-FUEL-04 | View fuel log history with pagination | P0 |
| FR-FUEL-05 | Edit/delete fuel log entry | P0 |
| FR-FUEL-06 | OCR receipt scanning to auto-populate fuel log | P1 |
| FR-FUEL-07 | Manual fuel price entry | P0 |
| FR-FUEL-08 | Attach photo to fuel log | P1 |
| FR-FUEL-09 | Location tagging (GPS) for fuel station | P2 |
| FR-FUEL-10 | Fuel log export (CSV/PDF) | P1 |

### 5.5 Expense Tracking
| ID | Requirement | Priority |
|---|---|---|
| FR-EXP-01 | Log expense (category, amount, date, description) | P0 |
| FR-EXP-02 | Expense categories: fuel, maintenance, insurance, taxes, toll, parking, accessories | P0 |
| FR-EXP-03 | Attach receipt photo to expense | P1 |
| FR-EXP-04 | View expense history with filters | P0 |
| FR-EXP-05 | Edit/delete expense | P0 |
| FR-EXP-06 | Monthly expense breakdown by category | P0 |
| FR-EXP-07 | Total lifetime cost per vehicle | P0 |
| FR-EXP-08 | Expense export (CSV/PDF) | P1 |

### 5.6 Service & Maintenance
| ID | Requirement | Priority |
|---|---|---|
| FR-SVC-01 | Log service event (type, date, odometer, cost, shop, notes) | P0 |
| FR-SVC-02 | Service types: oil change, tire rotation, brake service, filter, general | P0 |
| FR-SVC-03 | View service history timeline | P0 |
| FR-SVC-04 | Edit/delete service record | P0 |
| FR-SVC-05 | Set service reminders (date-based or odometer-based) | P0 |
| FR-SVC-06 | Receive push notification for due reminders | P0 |
| FR-SVC-07 | Attach service receipt/invoice | P1 |
| FR-SVC-08 | Service cost tracking | P0 |

### 5.7 Analytics & Insights
| ID | Requirement | Priority |
|---|---|---|
| FR-ANA-01 | Fuel efficiency trend over time (per vehicle) | P0 |
| FR-ANA-02 | Monthly fuel cost trend | P0 |
| FR-ANA-03 | Cost per kilometer calculation | P0 |
| FR-ANA-04 | Expense breakdown by category (pie/bar chart) | P0 |
| FR-ANA-05 | Total spend by month (line chart) | P0 |
| FR-ANA-06 | Fuel fill frequency analysis | P1 |
| FR-ANA-07 | Best/worst fuel economy sessions | P1 |
| FR-ANA-08 | Service cost timeline | P1 |
| FR-ANA-09 | Predict next service due date | P2 |
| FR-ANA-10 | Compare efficiency between vehicles | P1 |

### 5.8 OCR Module
| ID | Requirement | Priority |
|---|---|---|
| FR-OCR-01 | Capture fuel receipt photo via camera | P1 |
| FR-OCR-02 | Extract: fuel volume, price per unit, total cost, date | P1 |
| FR-OCR-03 | Display extracted data for user confirmation | P1 |
| FR-OCR-04 | Allow user to correct extracted values | P1 |
| FR-OCR-05 | Upload receipt image to storage | P1 |

### 5.9 Notifications
| ID | Requirement | Priority |
|---|---|---|
| FR-NOT-01 | Push notification for upcoming service reminders | P0 |
| FR-NOT-02 | Push notification for overdue service | P0 |
| FR-NOT-03 | Weekly fuel summary notification | P1 |
| FR-NOT-04 | Monthly expense report notification | P2 |
| FR-NOT-05 | In-app notification center | P1 |
| FR-NOT-06 | Notification read/unread state | P1 |

---

## 6. Non-Functional Requirements

### 6.1 Performance
| ID | Requirement | Target |
|---|---|---|
| NFR-PERF-01 | API P95 response time | < 200ms |
| NFR-PERF-02 | API P99 response time | < 500ms |
| NFR-PERF-03 | App cold start time | < 2 seconds |
| NFR-PERF-04 | App screen transition | < 300ms |
| NFR-PERF-05 | OCR processing time | < 3 seconds |
| NFR-PERF-06 | Dashboard load time | < 1 second |

### 6.2 Scalability
| ID | Requirement | Target |
|---|---|---|
| NFR-SCALE-01 | Concurrent users (MVP) | 1,000 |
| NFR-SCALE-02 | Concurrent users (Growth) | 100,000 |
| NFR-SCALE-03 | Database read throughput | 10,000 RPS |
| NFR-SCALE-04 | API horizontal scaling | Stateless, infinitely scalable |
| NFR-SCALE-05 | Storage | Petabyte-scale via S3/MinIO |

### 6.3 Reliability
| ID | Requirement | Target |
|---|---|---|
| NFR-REL-01 | Service uptime | 99.9% (8.7 hrs/year downtime) |
| NFR-REL-02 | Data backup frequency | Daily |
| NFR-REL-03 | RTO (Recovery Time Objective) | < 1 hour |
| NFR-REL-04 | RPO (Recovery Point Objective) | < 24 hours |
| NFR-REL-05 | Zero-downtime deployments | Required |

### 6.4 Security
| ID | Requirement | Standard |
|---|---|---|
| NFR-SEC-01 | Authentication | Firebase (OIDC compliant) |
| NFR-SEC-02 | Data encryption at rest | AES-256 |
| NFR-SEC-03 | Data encryption in transit | TLS 1.3 |
| NFR-SEC-04 | API rate limiting | Per-user, per-IP |
| NFR-SEC-05 | Input validation | Server-side always |
| NFR-SEC-06 | OWASP Top 10 compliance | Required |
| NFR-SEC-07 | PII data handling | GDPR/PDPB compliant |

### 6.5 Usability
| ID | Requirement | Target |
|---|---|---|
| NFR-UX-01 | Fuel log time | < 30 seconds |
| NFR-UX-02 | Accessibility | WCAG 2.1 AA |
| NFR-UX-03 | Offline support | Core features work offline |
| NFR-UX-04 | Language support | English (MVP), multi-lang (v2) |

---

## 7. User Stories

### Epic 1: Onboarding
```
US-001 As a new user, I want to register with my email so that I can create a FuelIQ account.
  Acceptance: Registration creates a verified account, sends welcome email, redirects to vehicle setup.

US-002 As a returning user, I want to log in with Google so that I don't need to remember a password.
  Acceptance: Google OAuth completes in < 3 taps, creates account if first time.

US-003 As a new user, I want to be guided through adding my first vehicle so that I can start tracking immediately.
  Acceptance: Onboarding flow prompts for vehicle details after signup, cannot be skipped.
```

### Epic 2: Garage
```
US-010 As a vehicle owner, I want to see all my vehicles in a garage view so that I can quickly switch between them.
  Acceptance: Shows vehicle card with name, photo, last odometer, and quick stats.

US-011 As a vehicle owner, I want to add a new vehicle with its details so that I can track it separately.
  Acceptance: Required: make, model, year, fuel type. Optional: photo, plate number.

US-012 As a vehicle owner, I want to archive a vehicle I no longer own while retaining its history.
  Acceptance: Archived vehicles don't appear in primary list but history is retained and accessible.
```

### Epic 3: Fuel Logging
```
US-020 As a vehicle owner, I want to quickly log a fuel fill after visiting a station.
  Acceptance: Log accessible in ≤ 2 taps. Required fields: odometer, liters, price. Auto-date.

US-021 As a vehicle owner, I want the app to calculate my fuel efficiency automatically.
  Acceptance: Efficiency shown immediately after logging. Based on previous full-tank fill.

US-022 As a vehicle owner, I want to scan my fuel receipt to automatically fill in the log.
  Acceptance: OCR extracts volume, price, total. Shows preview. Allows correction.
```

### Epic 4: Analytics
```
US-030 As a vehicle owner, I want to see my fuel efficiency trend over the past 6 months.
  Acceptance: Line chart with monthly averages. Highlight best and worst months.

US-031 As a vehicle owner, I want to know my exact cost per kilometer for each vehicle.
  Acceptance: Calculated from total fuel + maintenance costs divided by total distance.

US-032 As a vehicle owner, I want a monthly expense breakdown by category.
  Acceptance: Pie chart + itemized list. Filter by date range.
```

### Epic 5: Service & Reminders
```
US-040 As a vehicle owner, I want to log service records so I have complete maintenance history.
  Acceptance: Record: service type, date, odometer, cost, shop name, notes.

US-041 As a vehicle owner, I want service reminders so I never miss maintenance.
  Acceptance: Reminder by date OR odometer. Push notification 7 days before due.

US-042 As a vehicle owner, I want overdue service alerts on my home screen.
  Acceptance: Banner shown on home screen for overdue items. Dismissible after logging service.
```

---

## 8. Acceptance Criteria (Summary)

| User Story | Primary AC | Secondary AC |
|---|---|---|
| Registration | Account created, email verified | Profile created in DB, Clerk user synced |
| Login | Token issued, dashboard loaded | Refresh token stored securely |
| Add Vehicle | Vehicle visible in Garage | Odometer history initialized |
| Log Fuel | Log saved, efficiency calculated | Analytics updated, cache invalidated |
| OCR Scan | Data extracted, form pre-filled | Receipt image stored in MinIO |
| View Analytics | Charts render with real data | Empty state shown if insufficient data |
| Service Reminder | Notification delivered on time | Reminder marked "sent" to prevent duplication |

---

## 9. MVP Scope (Phase 1 Launch)

### ✅ MVP Includes
- Email/Google authentication via Firebase
- Profile management (name, photo, unit preferences)
- Garage — add, view, edit up to 10 vehicles
- Fuel logging — manual entry with efficiency calculation
- Basic expense tracking with categories
- Service log entry and history
- Date-based service reminders with push notifications
- Home dashboard with key stats
- Basic analytics: fuel efficiency trend, monthly costs, expense breakdown
- OCR receipt scanning (fuel fills)
- Settings screen

### ❌ MVP Excludes
- Apple Sign In (P1 — post-MVP)
- GPS location tagging for stations (P2)
- Odometer-based reminders (P1)
- Multi-language support (P2)
- Fleet management / team accounts (P2)
- Data export (P1)
- EV charging tracking (P1)
- Predictive analytics/ML (P3)
- Admin dashboard (P2)
- Subscription/billing (P2)

---

## 10. Future Scope

### Version 2.0 — Intelligence Layer
- **Predictive Maintenance**: ML model predicts component failure based on vehicle age, mileage, and logs
- **Fuel Price Intelligence**: Integrate fuel price APIs, suggest optimal stations nearby
- **Driver Behavior Scoring**: Analyze fill frequency and efficiency changes to score driving habits
- **Smart Anomaly Detection**: Flag unusual fuel consumption spikes (potential theft or leak)

### Version 3.0 — Fleet & Social Layer
- **Fleet Management**: Multi-user organizations with driver assignments and vehicle pools
- **Expense Approval Workflows**: Managers approve driver expense submissions
- **API Ecosystem**: Public REST API for third-party integrations (insurance, resale platforms)
- **Social Benchmarking**: Anonymous comparison against similar vehicles in the user's city

### Version 4.0 — Platform Layer
- **EV Intelligence**: Charging logs, battery health tracking, range prediction
- **OBD-II Integration**: Bluetooth OBD-II scanner data ingestion for real-time diagnostics
- **Insurance Integration**: Partner with insurers for usage-based insurance pricing
- **Resale Intelligence**: Estimate vehicle resale value based on maintenance and usage history

### Monetization Roadmap
| Tier | Features | Price |
|---|---|---|
| Free | 1 vehicle, basic logs, 3-month history | $0 |
| Pro | 5 vehicles, unlimited history, analytics, OCR | $4.99/mo |
| Fleet | Unlimited vehicles, team accounts, API access, reports | $29.99/mo |

---

## 11. Success Metrics (KPIs)

| Metric | Target (Month 3) | Target (Month 12) |
|---|---|---|
| Registered Users | 500 | 10,000 |
| DAU | 50 | 2,000 |
| Fuel Logs / Day | 100 | 5,000 |
| 30-day Retention | 40% | 55% |
| Avg Session Duration | 2 min | 3 min |
| OCR Accuracy | > 85% | > 92% |
| API P95 Latency | < 200ms | < 150ms |
| Crash-Free Sessions | > 99% | > 99.5% |

---

*Document Owner: Principal Product Architect*
*Review Cycle: Quarterly*
