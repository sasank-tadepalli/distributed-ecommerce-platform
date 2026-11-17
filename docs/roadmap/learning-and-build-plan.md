# Distributed E-Commerce Platform: Learning and Build Plan

> Living document: update the phase status and dates as the project moves forward. Day-to-day progress lives in [the journal](../distributed-ecommerce-journal.md).

## Context
I'm learning backend engineering and distributed systems by building a production-style e-commerce backend in **Spring Boot**, starting from a Node.js background. The goal is to understand every piece well enough to explain and defend it, not just to get it working. I share progress weekly on LinkedIn.

Time budget: about **6 hours/week** (weekdays 30–60 min, weekends 60–90 min).

Decisions made:
- Build **one service properly first** (users/auth), then products, then orders, then make it distributed.
- **I write the code myself**, with an AI mentor (Claude) explaining concepts, setting small tasks and reviewing the code.
- **Backend only**, demoed through Swagger UI and Postman. A frontend can be an extension later.
- **Java 21 + Gradle (Kotlin DSL)**, using the latest stable Spring Boot from start.spring.io.

Realistic timeline: **MVP in about 16 weeks** (mid-March 2027), with extensions after that. Missed days are expected. Each week has a buffer slot on Sunday.

---

## 1. Foundation principles

These rules are set up in Week 1 and apply from then on:

| # | Principle | Why it matters | How |
|---|---|---|---|
| 1 | Use an LTS Java version | Companies run LTS versions only; non-LTS versions stop getting fixes after 6 months | Temurin 21 via SDKMAN |
| 2 | Real database-per-service isolation | Separate databases mean nothing if one user can read all of them | `users_svc`, `products_svc` and `orders_svc` Postgres roles, each allowed only into its own DB |
| 3 | No secrets in git | Credentials in git leak forever (Twelve-Factor III) | A gitignored `.env` file plus a committed `.env.example` |
| 4 | Clean commits | No OS junk, build output or local settings in history | `.gitignore` from the first commit |
| 5 | Add infrastructure only when it's needed | Unused containers are just noise | Redis arrives in Week 6, Kafka in Week 13 |
| 6 | Record design decisions | Interviewers ask "why X over Y?" | `docs/adr/` (Architecture Decision Records, one short markdown file per decision) |
| 7 | Public history from day one | Recruiters can see steady progress | Public GitHub repo, small commits with clear messages |

Target repo layout after Week 1:
```
distributed-ecommerce-platform/
├── settings.gradle.kts          # Gradle multi-project root (includes services/*)
├── build.gradle.kts             # shared plugin/version config
├── gradle/libs.versions.toml    # version catalog: one place for dependency versions
├── services/
│   ├── users-service/           # Week 2+
│   ├── products-service/        # Week 6+
│   ├── orders-service/          # Week 9+
│   ├── api-gateway/             # Week 12
│   └── notification-service/    # Week 13
├── infra/ (postgres/, redis/, kafka/, prometheus/, grafana/)
├── docs/ (adr/, architecture/, db/, journal)
├── docker-compose.yml, .env.example, Makefile, README.md
└── .github/workflows/           # Week 14
```
There is deliberately **no shared "common" library for domain code**. Services share only contracts (the JWT format, event schemas, the error-response shape). Sharing domain classes couples services together, which is a classic microservices mistake and a good interview talking point.

---

## 2. Daily rhythm (repeats every week)

| Day | Time | What |
|---|---|---|
| Mon–Fri | 30–60 min | **10 min** read the concept I explain → **30–40 min** you build the task → **5 min** commit + one line in the journal session log |
| Sat | 60–90 min | Bigger piece: integration tests, a design session, or a refactor |
| Sun | 60 min | **30 min** buffer and catch-up → **15 min** weekly review with me (I review the week's diff) → **15 min** write the LinkedIn post from the journal |

How each session runs: concept first (why it exists and what problem it solves), then a small task with acceptance criteria, then I write the code, then a code review (correctness, Spring idioms, what a senior reviewer would flag). Each session ends with **one interview-style question**, answered in my own words in the journal.

### Java concepts, taught when needed
There are no standalone Java lessons. Each concept is explained the first time the service code needs it, with a short explanation and a JavaScript comparison when that helps:

| Java concept | First needed for | Week |
|---|---|---|
| Annotations, classes, packages | First controller, Spring beans | 1–2 |
| Interfaces, dependency injection | Service and repository layers | 2 |
| Records | Request/response DTOs | 2 |
| Exceptions (checked vs unchecked) | Global error handling | 2 |
| Generics, collections | Repositories, `List<T>`, `Page<T>` | 2–3 |
| `Optional` | `findById` and "not found" handling | 3 |
| `equals`/`hashCode` | JPA entities | 3 |
| Lambdas, streams | Mapping entities to DTOs, filtering permissions | 3–4 |
| Enums | User status, roles, order states | 3–4 |
| Concurrency, threads, `volatile`, atomic types | Optimistic locking test, executors | 7 |
| `CompletableFuture`, virtual threads | Parallel calls, load testing | 10+ |

---

## 3. Phases and milestones

### Phase 0: Foundations (Week 1)
| Day | Task | Concept you learn |
|---|---|---|
| Mon | Install JDK 21 (SDKMAN), `.gitignore`, monorepo skeleton, architecture docs, first commit, GitHub repo | JDK vs JRE, LTS, git hygiene, C4 model |
| Tue | Create `docker-compose.yml` with Postgres, `.env`/`.env.example`, and an `init.sql` with per-service DB roles | Least privilege, Twelve-Factor config, container networking, healthchecks |
| Wed | Add a Makefile, then prove isolation: connect as `users_svc` and confirm it **can't** open `products_db` | Make targets, Postgres roles and privileges |
| Thu | Gradle basics: create the root multi-project build and version catalog, plus the Gradle wrapper | Build tools, dependency management, multi-project builds |
| Fri | Generate users-service from start.spring.io (Web, JPA, Postgres, Flyway, Validation, Actuator). Connect it to `users_db` and hit `/actuator/health` | What Spring Boot auto-configuration does |
| Sat | Head start on Week 2: first REST endpoint and a first look at dependency injection | Annotations, beans, the request lifecycle |
| Sun | ADR-001 (service split), ADR-002 (Java 21 + Gradle). **LinkedIn post #1** | Writing decision records |

Java itself has no dedicated sessions; see [Java concepts, taught when needed](#java-concepts-taught-when-needed).

### Phase 1: Users & Auth Service, done properly (Weeks 2–5)
- **Week 2: Spring core + REST.** IoC/DI and beans (compared to Node's `require`), controller → service → repository layers, DTOs vs entities, Bean Validation, global error handling with `@RestControllerAdvice` returning RFC 7807 `ProblemDetail`, profiles (`application-local.yml`).
- **Week 3: Database design + JPA + Flyway.** Design the users schema on paper first (I review it), then Flyway `V1__init.sql`, JPA entities, relationships, the N+1 problem, transactions (`@Transactional`, propagation), UUID primary keys. Integration tests with **Testcontainers** against real Postgres.
- **Week 4: Security + RBAC.** Spring Security filter chain, BCrypt/Argon2 password hashing, JWT **signed with RS256** (a private key in users-service; other services verify with the public key from a **JWKS endpoint**, so they never need to call users-service), access and refresh tokens with refresh rotation, roles and permissions, `@PreAuthorize`, ownership checks.
- **Week 5: Auditing + polish.** JPA auditing (`created_by/at`, `updated_by/at`), an `audit_log` table written in the same transaction, correlation IDs in logs, OpenAPI/Swagger, Dockerfile (multi-stage, non-root user), and running users-service inside compose.
- ✅ Milestone: register/login/refresh/me/admin endpoints, RBAC enforced, every change audited, tests green.

### Phase 2: Products & Inventory Service (Weeks 6–8)
- Week 6: Catalog schema (categories, products, SKUs/variants, prices, images), pagination and sorting, filtering, ETags. Add Redis and a **cache-aside** pattern for product reads.
- Week 7: Inventory as a separate table with a `version` column. **Optimistic locking** (`@Version`) vs pessimistic locking (`SELECT … FOR UPDATE`). Write a concurrency test where 100 threads buy the last item and nothing oversells.
- Week 8: Validate JWTs from users-service through JWKS (the first cross-service trust). `CATALOG_MANAGER` permissions. Auditing reused here.
- ✅ Milestone: catalog + inventory with oversell protection proven by a test.

### Phase 3: Orders Service, where it becomes distributed (Weeks 9–11)
- Week 9: Cart (kept in Redis, with a TTL), the order schema, a **price snapshot** on order lines, and the order **state machine** (PENDING → RESERVED → PAID → SHIPPED → DELIVERED / CANCELLED).
- Week 10: Synchronous call to products-service to reserve stock (Spring `RestClient`), timeouts, **Resilience4j** retry with backoff and jitter plus a circuit breaker, and **idempotency keys** on `POST /orders`.
- Week 11: **Transactional outbox** table (`outbox_events`) and what to do when stock is reserved but the order fails, using compensation.
- ✅ Milestone: checkout works end to end across 3 services, survives a service restart, and creates no duplicate orders.

### Phase 4: Gateway + events (Weeks 12–13)
- Week 12: **Spring Cloud Gateway** as the single entry point: JWT checked at the edge, a Redis **token-bucket rate limiter**, routing, CORS.
- Week 13: **Kafka** (KRaft mode) in compose. An outbox relay publishes `order.created`, `order.cancelled` and `inventory.reserved`. notification-service consumes them (logging the "email" is enough). Covers consumer groups, partition keys (orderId), at-least-once delivery, **idempotent consumers**, retry topics, and a **DLQ**.
- ✅ Milestone: event-driven flow; take notification-service down and bring it back, and it catches up with no lost events.

### Phase 5: MVP hardening (Weeks 14–16)
- Week 14: **GitHub Actions CI** (build, test, Testcontainers, Docker image build), status badge in the README.
- Week 15: **Observability basics**: Micrometer → Prometheus → Grafana RED dashboard, structured JSON logs, **OpenTelemetry** traces across gateway → orders → products → Kafka → notifications, viewed in Jaeger/Tempo.
- Week 16: **k6 load test** (p95/p99 latency, finding the bottleneck), README with an architecture diagram, a 2-minute demo video, and the resume bullet.
- 🎯 **MVP complete.**

### Extensions after the MVP (each about 2–4 weeks, in any order)
| Extension | What you learn |
|---|---|
| E1 Payments (Stripe test mode) | **Saga** (orchestration vs choreography), webhooks, exactly-once-ish semantics, reconciliation |
| E2 Search (Elasticsearch/OpenSearch) | **CQRS**, Kafka-fed read model, eventual consistency, relevance and facets |
| E3 Cloud deploy (AWS: ECS Fargate or EKS, RDS, ElastiCache, MSK, with Terraform) | VPC, IAM least privilege, IaC, managed vs self-hosted, cost control |
| E4 Kubernetes | Deployments, HPA, probes, ConfigMaps/Secrets, Helm |
| E5 Reviews/ratings, wishlist, coupons/promotions | Adding features without touching other services, because the design is extensible |
| E6 Shipping/fulfillment service | Another saga participant, external API simulation |
| E7 Minimal React storefront | Demo polish for LinkedIn |
| E8 Debezium CDC instead of polling the outbox | Log-based change data capture |

---

## 4. Database design (to be refined together in Week 3; this is the starting point)

Shared conventions (written down in `docs/db/conventions.md`):
- UUID primary keys (UUIDv7, so new keys are time-ordered and index-friendly). Never expose sequential IDs.
- Every table gets `created_at`, `created_by`, `updated_at`, `updated_by`, and `version` (used for optimistic locking).
- **Money is stored as `BIGINT` minor units (cents) plus a `currency CHAR(3)`.** Never use a float.
- Soft delete (`deleted_at`) for business entities. Hard delete only for tokens.
- All schema changes go through **Flyway** migrations. Nothing is edited by hand, ever.
- Names are snake_case and plural. Every foreign key has an index. Business rules are also enforced with CHECK constraints.

**users_db**
- `users` (id, email UNIQUE citext, password_hash, full_name, phone, status [ACTIVE/LOCKED/DISABLED], email_verified_at, failed_login_count, last_login_at, audit cols)
- `roles` (id, name UNIQUE: CUSTOMER, SUPPORT_AGENT, CATALOG_MANAGER, ORDER_MANAGER, ADMIN)
- `permissions` (id, code UNIQUE, e.g. `product:write`, `order:read:any`, `user:manage`)
- `role_permissions` (role_id, permission_id): many-to-many
- `user_roles` (user_id, role_id, granted_by, granted_at): many-to-many, and the grant itself is audited
- `refresh_tokens` (id, user_id, token_hash, family_id, expires_at, revoked_at, replaced_by): supports rotation and reuse detection
- `addresses` (id, user_id, type, line1…, is_default)

**products_db**
- `categories` (id, parent_id self-FK, slug, name): a tree
- `products` (id, category_id, slug, name, description, brand, status [DRAFT/ACTIVE/ARCHIVED])
- `product_variants` / SKUs (id, product_id, sku UNIQUE, attributes JSONB, price_minor, currency)
- `inventory` (sku_id PK, on_hand, reserved, version, CHECK reserved <= on_hand)
- `inventory_reservations` (id, sku_id, order_id, qty, status, expires_at): the record of which order holds which stock
- `product_images` (id, product_id, url, sort_order)

**orders_db**
- `orders` (id, user_id, status, total_minor, currency, shipping_address JSONB snapshot, placed_at)
- `order_items` (id, order_id, sku_id, product_name snapshot, unit_price_minor snapshot, qty)
- `order_status_history` (order_id, from_status, to_status, changed_by, reason, at)
- `idempotency_keys` (key, user_id, request_hash, response JSONB, created_at)
- `outbox_events` (id, aggregate_type, aggregate_id, event_type, payload JSONB, created_at, published_at)
- (E1) `payments`, `refunds`

**RBAC model**
- The JWT carries `sub`, `roles` and `permissions` (flattened). Services check **permissions, not roles**, e.g. `@PreAuthorize("hasAuthority('product:write')")`. That way adding a new role never requires a code change.
- **Ownership** is checked separately: a CUSTOMER with `order:read:own` can read an order only if `order.user_id == jwt.sub`.
- Admin endpoints exist to grant and revoke roles, and every grant or revoke is audited.

**Auditing (two layers)**
1. **Row-level columns** filled automatically by Spring Data JPA auditing (`@CreatedBy` etc., with `AuditorAware` reading the JWT subject).
2. **An `audit_log` table in each service DB** (id, actor_id, actor_roles, action, entity_type, entity_id, before JSONB, after JSONB, ip, user_agent, trace_id, at). It is written **in the same transaction** as the change, so an audit entry can never be lost. It is append-only: the DB role is granted INSERT/SELECT only, with no UPDATE or DELETE.
3. Later (E3+), stream the audit logs to a central store through Kafka.

---

## 5. How the design stays extensible
- Each service owns its own DB and its own API. A new feature means a new service or module subscribed to existing events, not changes to old code.
- **Events are versioned contracts** (`order.created.v1`) documented in `docs/events/`.
- Integration points are left open on purpose: the outbox (feeds search, analytics and CDC), a JWKS-based auth that any new service can verify, and the gateway routing table.
- Config is entirely environment-driven, so the same images run locally, in CI and in the cloud.

---

## 6. LinkedIn + resume
- **Weekly post** (Sunday): one problem, one concept, one lesson, written from the journal's session log. Include a diagram or code snippet. ~150–250 words.
- Strong post topics: "How I stopped overselling with 3 lines of code", "Why my services never call the auth service", "The outbox pattern explained with my bug", "My first Grafana dashboard caught a p99 spike".
- **Target resume bullet (after the MVP):** *Built a distributed e-commerce backend (Java 21, Spring Boot, PostgreSQL, Kafka, Redis) across 5 microservices behind an API gateway; implemented JWT/RBAC auth, transactional outbox and idempotent consumers for reliable events, optimistic locking for zero overselling under 500 concurrent checkouts, and end-to-end OpenTelemetry tracing; CI with GitHub Actions and Testcontainers.* Every claim in it will be backed by a test or a dashboard screenshot.

---

## 7. Verification (how each milestone gets proven, not just claimed)
- `make up` → whole stack healthy (`docker compose ps` shows everything healthy).
- `./gradlew test` → unit tests plus Testcontainers integration tests pass for every service.
- A Postman/Bruno collection in `docs/api/` exercises every endpoint, including RBAC negative cases (403s).
- Concurrency test for inventory (Week 7), an idempotency replay test (Week 10), and a consumer-down-then-recovers test (Week 13).
- CI green on every push (from Week 14). Grafana dashboard plus a Jaeger trace screenshot (Week 15). k6 report (Week 16).

---

## First session (Day 1, about 40 min)
1. Install SDKMAN + Temurin 21 and set `JAVA_HOME`. Install IntelliJ IDEA Community.
2. Add a `.gitignore`, then set up the monorepo skeleton (services, infra, docs) and the architecture docs.
3. `git add` + first commit. Create a public GitHub repo and push.
4. Journal: fill in the start date (2026-11-15) and the repo link.
5. Interview question to answer in the journal: *"Why does each microservice get its own database, and what do you lose by doing that?"*
