# Distributed E-Commerce Platform

A production-style, distributed e-commerce backend built with **Java 21** and **Spring Boot**, to learn distributed-systems patterns hands-on: microservices, event-driven communication, RBAC and auditing, resilience, and observability.

> 🚧 Work in progress. See the [roadmap](docs/roadmap/learning-and-build-plan.md) for the plan and the [journal](docs/distributed-ecommerce-journal.md) for progress.

## Architecture (target)

| Service | Responsibility | Database |
|---|---|---|
| [api-gateway](services/api-gateway) | Single entry point, JWT validation, rate limiting | none |
| [users-service](services/users-service) | Auth, JWT issuing, RBAC | `users_db` |
| [products-service](services/products-service) | Catalog, inventory | `products_db` |
| [orders-service](services/orders-service) | Cart, checkout, order lifecycle | `orders_db` |
| [notification-service](services/notification-service) | Event-driven notifications | own store |

**Infrastructure:** PostgreSQL, Redis, Kafka, Prometheus, Grafana, OpenTelemetry

## Repository layout

```
├── services/        # one folder per microservice
├── infra/           # local infrastructure config (postgres, redis, kafka, prometheus, grafana)
└── docs/
    ├── roadmap/     # learning and build plan
    ├── notes/       # concept notes by topic (Java, Docker, Postgres, …)
    ├── adr/         # architecture decision records
    ├── architecture/# system diagrams
    ├── db/          # database conventions and schemas
    ├── events/      # Kafka event contracts
    └── api/         # API collections
```

## Running locally

_Coming soon._
