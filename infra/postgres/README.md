# Postgres

Local PostgreSQL configuration: one database per service, each with its own least-privilege role (`users_svc`, `products_svc`, `orders_svc`).

Planned contents:
- `init.sql`: creates the databases and roles (Week 1, Thursday)

Table schemas are **not** defined here. Each service owns its schema through Flyway migrations in its own folder.
