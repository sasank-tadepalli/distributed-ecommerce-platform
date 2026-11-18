# PostgreSQL

## Roles
- In Postgres, a **role** is both a "user" and a "group". There's no separate user concept (`CREATE USER` is just `CREATE ROLE … LOGIN`).
- `LOGIN` means the role can connect.
- A **superuser** bypasses every permission check. Use it only for admin work, never from an application.

## Database ownership
The **owner** of a database can do anything inside it, including creating tables. Flyway migrations need that, so each service role owns its own database:
```sql
CREATE DATABASE users_db OWNER users_svc;
```

## Least privilege in this project
| Role | Can do | Used by |
|---|---|---|
| Admin (superuser, from `.env`) | Everything | Me, for admin work only |
| `users_svc` | Owns `users_db` | users-service |
| `products_svc` | Owns `products_db` | products-service |
| `orders_svc` | Owns `orders_db` | orders-service |

**Why:** if one service is compromised or buggy, the damage stays inside its own database. This is what makes "database per service" real rather than just a naming convention.

## Keeping passwords out of SQL files
Init scripts are committed, so they can't contain passwords. `psql` can read environment variables:
```sql
\getenv users_pw USERS_DB_PASSWORD                   -- env var → psql variable (psql 15+)
CREATE ROLE users_svc LOGIN PASSWORD :'users_pw';    -- :'var' inserts it as a quoted literal
```
`:var` inserts the raw value, and `:'var'` inserts it as a safely quoted string literal.

⚠️ **Two silent failures combine here:**
1. `\getenv` does **nothing** if the environment variable doesn't exist. There's no error.
2. If a psql variable isn't set, `:'users_pw'` is left as **literal text**, and Postgres reports `syntax error at or near ":"`.

So that syntax error really means "the env var never reached the container". Bug I hit: compose had `USER_DB_PASSWORD:` (missing `S`) on the left side of `environment:`, so the container never got `USERS_DB_PASSWORD`. Check what a container actually received, printing names only:
```bash
docker compose run --rm postgres env | grep DB_PASSWORD | cut -d= -f1
```
⚠️ After a **failed** init, `initdb` has already run, so a plain restart skips init forever. Reset with `docker compose down -v`.

## Useful `psql` meta-commands
| Command | Shows |
|---|---|
| `\l` | Databases, with owners and access privileges |
| `\du` | Roles and their attributes |
| `\c users_db` | Connect to another database |
| `\dt` | Tables in the current database |
| `\q` | Quit |

_To be continued in Week 1, Day 3: testing the isolation._
