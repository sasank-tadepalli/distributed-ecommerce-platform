# Project Journal: Distributed E-Commerce Platform

> **Purpose:** My learning log, interview prep notebook, and source for the weekly LinkedIn posts.
> **Plan:** [Roadmap](roadmap/learning-and-build-plan.md) · **Architecture:** [docs/architecture](architecture/)

## How to use this journal

| When | What to write | Time |
|---|---|---|
| After every session | One row in that week's **Session log** + the day's interview answer | 5 min |
| When something breaks | A row in the **Problems & solutions** log (the best LinkedIn material) | 2 min |
| When I choose between options | A row in the **Decisions** log (and an ADR if it's significant) | 2 min |
| Sunday | Week summary + LinkedIn post draft, then update the milestone tracker | 15 min |

**Rule:** Write answers in my own words **before** looking anything up. Then correct them. The gap between the two is what I actually learned.

---

## Project overview

| Field | Detail |
|---|---|
| Start date | 2026-11-15 |
| Target MVP date | ~2027-03-07 (16 weeks; expect it to slip a little, and that's fine) |
| Repo | _(add GitHub link)_ |
| Stack | Java 21, Spring Boot, Gradle (Kotlin DSL), PostgreSQL, Flyway, Redis, Kafka, Docker Compose, Testcontainers, Prometheus, Grafana, OpenTelemetry |
| Weekly time | ~6 h (weekdays 30–60 min, weekends 60–90 min) |

---

## Milestone tracker

| Phase | Weeks | Milestone | Status | Done on |
|---|---|---|---|---|
| 0 | 1 | Foundations: Java 21, repo skeleton, Gradle, Postgres in compose | 🟡 In progress | |
| 1 | 2–5 | Users & Auth service: REST, JPA, Flyway, JWT, RBAC, auditing, tests | ⬜ | |
| 2 | 6–8 | Products & Inventory: catalog, Redis cache, oversell protection | ⬜ | |
| 3 | 9–11 | Orders: cart, state machine, resilience, idempotency, outbox | ⬜ | |
| 4 | 12–13 | API Gateway + Kafka events + notification service | ⬜ | |
| 5 | 14–16 | CI, observability, load test → 🎯 **MVP** | ⬜ | |
| E1–E8 | after MVP | Payments, search, cloud, Kubernetes, more features | ⬜ | |

Status key: ⬜ Not started · 🟡 In progress · ✅ Done · 🔴 Blocked

---

## Session log

### Week 1: Foundations

| Day | Date | What I did | What I learned (my own words) | Time |
|---|---|---|---|---|
| 1 | 2026-11-15 | Installed SDKMAN + Java 21 (fixed a missing `~/.zshrc` setup). Wrote `.gitignore`. Set up the monorepo skeleton (services, infra, docs). Wrote architecture docs as Mermaid diagrams (C4 model). Started this journal. First commit. | Companies use LTS Java versions only, which is why 21 and not 19. A command like `sdk` can be a shell function that only exists once a startup script has run. In `.gitignore`, the last matching rule wins, so `!.env.example` must come after `.env.*`. Git doesn't track empty folders. Good architecture docs answer one question per diagram. | 2.5 h |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |

**Week summary:** _(Sunday: 3–5 sentences. What's working, what was hard, what's next.)_

<!-- Copy this block for each new week:

### Week N: <Phase / topic>

| Day | Date | What I did | What I learned (my own words) | Time |
|---|---|---|---|---|
| 1 | | | | |

**Week summary:**
-->

---

## Interview questions (answered in my own words)

One question per session. Write the first answer without looking anything up, then add a corrected version after review.

### Day 1: Why does each microservice get its own database, and what do you give up by doing that?

**My first answer:** _(Day 1 is a worked example written with Claude. From Day 2, write this part yourself before asking for review.)_

**After review:**

*Why:* If services shared one database, they would be coupled through the schema. Renaming a column in `users` could break orders-service without anyone noticing until production. With a database per service, each team can change its schema, pick its own storage, and scale or deploy independently. Other services can only get the data through the owning service's API or events. That API becomes a contract, and the internals stay private.

*What I give up:*
1. **No cross-service joins.** "Orders with the customer's name" needs an API call, or a copy of the name kept in orders (which is why order lines store a snapshot of the product name and price).
2. **No single ACID transaction across services.** Placing an order touches orders and inventory, so I need patterns like the outbox and sagas instead of one `BEGIN … COMMIT`.
3. **Eventual consistency.** Copies of data in other services can be briefly out of date.
4. **More to operate:** more databases to back up, migrate and monitor.

*In this project:* one Postgres server with three databases, and each service gets its own DB user, so one service *can't* read another's tables even by accident.

*Follow-up an interviewer might ask:* "Isn't one Postgres server with 3 databases still a shared database?" → It's a shared **server**, not a shared **schema**. That's fine for local dev and small scale. The isolation is logical (separate databases and users). In production, each database could move to its own server without code changes.

<!-- Template:
### Day N: <question>
**My first answer:**
**After review:**
-->

---

## Problems & solutions

Every bug, confusing error and "why doesn't this work" moment goes here.

| Date | Problem | Root cause | Fix | Lesson |
|---|---|---|---|---|
| 2026-11-15 | `zsh: command not found: sdk` after installing SDKMAN | The installer didn't add its init lines to `~/.zshrc`, so new shells never loaded the `sdk` function | Added `SDKMAN_DIR` and `source …/sdkman-init.sh` to the end of `~/.zshrc` | `sdk` is a shell **function**, not a program on disk. It only exists if a startup script defines it. `source` runs a script inside the current shell; `./script` runs it in a separate one. |
| | | | | |

---

## Decisions log

Significant decisions also get a full ADR in [docs/adr](adr/).

| Date | Decision | Why | Alternatives considered | ADR |
|---|---|---|---|---|
| 2026-11-15 | Build one service deeply first (users), then add the others | Learn Spring, JPA, security and testing before adding network complexity | All services in parallel; modular monolith first | _to write_ |
| 2026-11-15 | Java 21 + Gradle (Kotlin DSL) | 21 is the most widely used LTS; Gradle is common at large tech companies | Java 25; Maven | _to write_ |
| 2026-11-15 | Backend only, demoed through Swagger UI + Postman | Focus on backend skills; a frontend can be added later | React storefront from the start | |
| 2026-11-15 | Architecture diagrams in Mermaid, organized with the C4 model | Renders on GitHub, diffable, no extra tooling | Python `diagrams` library (PNG output) | |
| | | | | |

---

## Concepts glossary

Add each concept the day I learn it. Definitions in my own words.

| Concept | My definition | Where it shows up in this project | Week |
|---|---|---|---|
| JDK / JRE / JVM | JVM runs compiled bytecode (like V8 runs JS). JRE = JVM + standard library, enough to run Java. JDK = JRE + tools like the `javac` compiler, needed to build Java. | Building and running every service | 1 |
| LTS release | A Java version that gets security fixes for years (17, 21, 25). Non-LTS versions (like 19) stop getting fixes after 6 months, so companies avoid them. | Why Java 21 and not 19 | 1 |
| SDKMAN | A version manager for the JDK, like `nvm` for Node. `sdk` is a shell function loaded by `~/.zshrc`. | Installing and switching Java versions | 1 |
| `source` vs `./script` | `source` runs a script inside my current shell, so its variables and functions stay. `./script` runs it in a new process that disappears afterwards. | SDKMAN setup; `.env` files later | 1 |
| `.gitignore` rules | No `/` → matches at any depth. Trailing `/` → directories only. `*` → wildcard. `!` → un-ignore. Last matching rule wins. `!` can't rescue a file inside an ignored folder. | Keeping secrets and build output out of git | 1 |
| C4 model | Architecture docs at zoom levels: system context → containers → components. One diagram answers one question. | `docs/architecture/` | 1 |
| Database per service | Each service owns its data and nobody else touches it. Others go through its API or events. Costs: no cross-service joins or transactions. | Each service owns one Postgres database | 1 |
| | | | |

Coming up: dependency injection, JPA/Hibernate, Flyway migrations, JWT/JWKS, RBAC, optimistic locking, cache-aside, idempotency, transactional outbox, circuit breaker, consumer groups, DLQ, RED metrics, distributed tracing, saga, CQRS.

---

## LinkedIn

### Post archive

| Week | Topic | Link | Reactions | Comments | What resonated |
|---|---|---|---|---|---|
| 1 | | | | | |

### Post formula
1. **Hook:** one surprising line or problem ("I wrote zero lines of Java on Day 1 of my Java project. Here's why.")
2. **What I built or broke** this week, in 2–3 sentences
3. **One concept** explained simply, ideally with a diagram or 5-line code snippet
4. **One lesson** I'd tell someone starting out
5. **What's next** + 3–5 hashtags

Keep it to 150–250 words. Write it from this week's session log and problems table.

### Week 1 draft
_(Write on Sunday.)_

---

## Interview story bank

After each milestone, write one STAR story (Situation, Task, Action, Result). Use real numbers from tests and dashboards; never invent them.

| Milestone | Story topic | Status |
|---|---|---|
| Users & Auth | How services verify JWTs without calling the auth service | ⬜ |
| Products | How I proved no overselling under concurrent checkouts | ⬜ |
| Orders | Handling a reserved-stock-but-failed-order partial failure | ⬜ |
| Kafka | Taking a consumer down without losing events | ⬜ |
| Observability | Finding a latency bottleneck with traces | ⬜ |

### Questions this project prepares me for

| Question | Where I'll learn the answer |
|---|---|
| How would you prevent overselling the last item when 1,000 users buy at once? | Week 7: optimistic locking |
| How do you stop a retried request from creating two orders? | Week 10: idempotency keys |
| How do you guarantee an event is published if the DB commit succeeds? | Week 11: transactional outbox |
| What happens when the notification service is down? | Week 13: consumer groups, offsets, DLQ |
| How would you debug a slow request that crosses 4 services? | Week 15: distributed tracing |
| How do you handle a payment that succeeds but the order fails? | E1: saga + compensation |
| How would you scale this to 10x traffic? | E3/E4: horizontal scaling, partitions, caching |

---

## Reading list

Read alongside the week that uses it, not all up front.

- [ ] [The Twelve-Factor App](https://12factor.net/) (Week 1, 30 min)
- [ ] [Spring Boot reference docs](https://docs.spring.io/spring-boot/) and the [Spring guides](https://spring.io/guides) (Weeks 2+)
- [ ] [Baeldung](https://www.baeldung.com/): practical Spring how-tos (whenever stuck)
- [ ] [Vlad Mihalcea's blog](https://vladmihalcea.com/): JPA, Hibernate and locking in depth (Weeks 3, 7)
- [ ] [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) (Week 4)
- [ ] [microservices.io patterns](https://microservices.io/patterns/) (Weeks 9–13)
- [ ] *Designing Data-Intensive Applications*, Martin Kleppmann: chapters 5, 7, 9 and 11 alongside Phases 3–4
- [ ] [Google SRE book](https://sre.google/sre-book/), chapters 6, 21 and 22 (Week 15)

---

*Last updated: 2026-11-15 · Current: Week 1, Day 1 done → next: Day 2 (Java for Node developers)*
