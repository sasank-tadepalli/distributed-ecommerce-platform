# Postgres

Local PostgreSQL 17 for development. It runs from the root [`docker-compose.yml`](../../docker-compose.yml).

**Database per service:** each service gets its own database, owned by its own login role. A service role is not a superuser and can't create roles or databases.

| Database | Owner role | Used by | Password variable |
|---|---|---|---|
| `users_db` | `users_svc` | users-service | `USERS_DB_PASSWORD` |
| `products_db` | `products_svc` | products-service | `PRODUCTS_DB_PASSWORD` |
| `orders_db` | `orders_svc` | orders-service | `ORDERS_DB_PASSWORD` |

The admin superuser (`POSTGRES_USER`) is for admin work only. Services never connect with it.

Table schemas are **not** defined here. Each service owns its schema through Flyway migrations in its own folder.

## Contents

| File | Purpose |
|---|---|
| `init/01-create-service-databases.sql` | Creates the service roles and databases. Mounted read-only into `/docker-entrypoint-initdb.d/`. |

## How it's configured

1. All credentials live in the root `.env` (gitignored). Start from the template: `cp .env.example .env`
2. `docker-compose.yml` passes them into the container through `environment:`.
3. The init script reads the service passwords with `\getenv`, so no password is ever committed.

A variable's name has to match in all three places (`.env`, the left side of `environment:`, and `\getenv`). If one doesn't match, the init fails with `syntax error at or near ":"`.

## ⚠️ Init only runs once

Scripts in `init/` run **only when the data volume is empty**, i.e. on the very first start. The same applies to every password. After editing the init script or changing a password in `.env`, reset:

```bash
docker compose down -v    # ⚠️ deletes all local database data
docker compose up -d
```

If an init script fails partway, a plain restart skips init entirely, so reset the same way.

## Common commands

```bash
docker compose up -d                       # start
docker compose ps                          # wait for (healthy)
docker compose logs postgres               # check the init script ran without errors

# psql as admin (replace with your POSTGRES_USER / POSTGRES_DB values)
docker compose exec postgres psql -U <admin-user> -d <admin-db>
```

Inside `psql`: `\l` lists databases and owners, `\du` lists roles, `\c users_db` switches database, `\q` quits.

To connect from a GUI client (IntelliJ Database tool, DBeaver, TablePlus): host `localhost`, port `5432`, with a service role and its password from `.env`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `database files are incompatible with server … initialized by PostgreSQL version N` | An old volume from a different Postgres major version is being reused | `docker compose down -v` (or migrate the data with `pg_dump`/`pg_upgrade` if it matters) |
| `syntax error at or near ":"` during init | A `*_DB_PASSWORD` variable didn't reach the container | Check the names: `docker compose run --rm postgres env \| grep DB_PASSWORD \| cut -d= -f1` |
| Changed a password in `.env` and it doesn't work | Passwords are only applied on first init | `down -v`, or `ALTER ROLE … PASSWORD '…'` as admin |
| `Skipping initialization` in the logs | The volume already has data | Expected on every start after the first one |
