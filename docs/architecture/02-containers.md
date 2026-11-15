# 02. Containers

**Question:** Which services, databases and brokers exist, and how do they connect?

"Container" in C4 means a separately deployable thing (a service, a database, a broker), not specifically a Docker container. In this project, each one does also run as a Docker container.

```mermaid
flowchart LR
    client["Client<br/>Swagger UI / Postman"]

    subgraph platform["E-Commerce Platform"]
        gw["API Gateway<br/>Spring Cloud Gateway"]

        users["Users Service<br/>auth, JWT, RBAC"]
        products["Products Service<br/>catalog, inventory"]
        orders["Orders Service<br/>cart, checkout, orders"]
        notif["Notification Service<br/>event consumer"]

        usersdb[("users_db<br/>PostgreSQL")]
        productsdb[("products_db<br/>PostgreSQL")]
        ordersdb[("orders_db<br/>PostgreSQL")]

        redis[("Redis<br/>cache, carts, rate limits")]
        kafka{{"Kafka<br/>event bus"}}
    end

    client -->|HTTPS + JWT| gw
    gw -->|REST| users
    gw -->|REST| products
    gw -->|REST| orders
    gw -.->|rate limit counters| redis

    users --> usersdb
    products --> productsdb
    orders --> ordersdb

    products -.->|product cache| redis
    orders -.->|carts| redis

    orders -->|reserve stock - REST| products
    products -.->|fetch public keys - JWKS| users
    orders -.->|fetch public keys - JWKS| users

    orders -->|order events via outbox| kafka
    kafka -->|consume| notif
```

## Containers

| Container | Tech | Owns | Built in |
|---|---|---|---|
| API Gateway | Spring Cloud Gateway | none | Week 12 |
| Users Service | Spring Boot | `users_db` | Weeks 2–5 |
| Products Service | Spring Boot | `products_db` | Weeks 6–8 |
| Orders Service | Spring Boot | `orders_db` | Weeks 9–11 |
| Notification Service | Spring Boot + Spring Kafka | processed-event store | Week 13 |
| PostgreSQL | PostgreSQL | one database per service | Week 1 |
| Redis | Redis | cache, carts, rate-limit counters | Week 6 |
| Kafka | Kafka (KRaft mode) | topics | Week 13 |

## Rules this diagram enforces

1. **Database per service.** An arrow into a database only ever comes from its owning service.
2. **No synchronous call chains longer than one hop.** Orders calls products; products never calls orders back.
3. **Facts are shared through events, not shared tables.** Anything that only needs to *know* something happened subscribes to Kafka.
4. **Auth is verified locally.** Services fetch users-service's public key once and cache it; there's no per-request call to users-service.

## Not shown yet

Observability (Prometheus, Grafana, OpenTelemetry), search (Elasticsearch) and payments get added to this diagram when they're built.
