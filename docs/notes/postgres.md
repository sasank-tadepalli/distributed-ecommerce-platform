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

## `PUBLIC` and default privileges (the gap I found)
- **`PUBLIC`** is a pseudo-role meaning **every role, including future ones**.
- By default, every new database grants **`PUBLIC` CONNECT + TEMPORARY**. So separate users + separate databases were **not** isolated: `users_svc` could connect to `products_db`.
- The defaults are **invisible**: `\l` shows an empty Access privileges value, which means "built-in defaults apply".

Fix (in the init script, once per database):
```sql
REVOKE ALL ON DATABASE products_db FROM PUBLIC;   -- ALL on a database = CONNECT + TEMPORARY + CREATE
```
The owner keeps access without any `GRANT`, because owners implicitly hold every privilege. Result: `FATAL: permission denied for database "products_db" — User does not have CONNECT privilege.`

What `users_svc` could do in `products_db` **before** the fix:

| Action | Allowed? | Why |
|---|---|---|
| Connect | ✅ | PUBLIC had CONNECT |
| `CREATE TEMP TABLE` | ✅ | PUBLIC had TEMPORARY |
| List table/column names (`information_schema`, `pg_catalog`) | ✅ | Catalog metadata is readable once connected |
| Use up connection slots (`max_connections`) | ✅ | Any connection counts |
| Read rows of `products_svc`'s tables | ❌ | No SELECT granted on tables it doesn't own |
| `CREATE TABLE` in schema `public` | ❌ (Postgres 15+) | Postgres 15 removed CREATE on `public` from PUBLIC. Before 15, **anyone could create objects there**, a long-standing security weakness. |

> 🎯 **Interview:** "Least privilege isn't only about what you grant; it's about what the **defaults already grant**." Separate users looked isolated, but weren't. The only way to know is to **test the negative case**: prove that access is *denied*, not just that it works.

## Reading access privileges (ACLs)
```
products_svc=CTc/products_svc
  grantee   privs   grantor
```
- **grantee:** the role receiving the privileges. An **empty** grantee (`=Tc/owner`) means **PUBLIC**.
- **privileges** on a database: `C` = CREATE (schemas), `T` = TEMPORARY, `c` = CONNECT.
- **grantor:** **who granted** it. Often the owner, but not necessarily.
- **Empty/NULL value:** built-in defaults (owner: everything, PUBLIC: CONNECT + TEMPORARY).

**Why my grantor is `products_svc`, not the admin who ran the script:**
1. Grants or revokes run by a **superuser** are recorded **as if the object's owner issued them**, so privileges always trace back to someone with real authority over the object.
2. `REVOKE … FROM PUBLIC` on an empty ACL first **materializes the defaults**, `{=Tc/products_svc, products_svc=CTc/products_svc}`, then removes the PUBLIC entry. What's left is the owner's implicit self-grant, written out.

Quick query: `SELECT datname, datacl FROM pg_database;`

## GRANT and REVOKE
```sql
GRANT  <privileges> ON <object> TO   <role> [WITH GRANT OPTION];
REVOKE [GRANT OPTION FOR] <privileges> ON <object> FROM <role> [CASCADE | RESTRICT];
```
| Object | Privileges |
|---|---|
| `DATABASE` | `CONNECT`, `CREATE` (schemas), `TEMPORARY` |
| `SCHEMA` | `USAGE` (needed before touching anything inside), `CREATE` |
| `TABLE` | `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES` (FKs to it), `TRIGGER` |
| Columns | `SELECT (col, …)`, `UPDATE (col, …)` |
| `SEQUENCE` | `USAGE`, `SELECT`, `UPDATE` |
| `FUNCTION` | `EXECUTE` |

Access is **layered**: reading a table needs `CONNECT` on the database **and** `USAGE` on the schema **and** `SELECT` on the table. Missing any one layer blocks you. That's why `users_svc` couldn't read `products_svc`'s tables even when it could still connect to `products_db`.

`ALL` = every privilege that applies to that object type (on a database: CONNECT + CREATE + TEMPORARY).

### Useful forms
```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting;      -- existing tables only
ALTER DEFAULT PRIVILEGES IN SCHEMA public
      GRANT SELECT ON TABLES TO reporting;                     -- tables created in the FUTURE
GRANT reporting TO alice;                                      -- role membership = groups
GRANT SELECT ON orders TO support WITH GRANT OPTION;           -- support may pass it on
REVOKE GRANT OPTION FOR SELECT ON orders FROM support;         -- remove only the right to pass it on
REVOKE SELECT ON orders FROM support CASCADE;                  -- also revoke from those support granted it to
```

**`ON ALL TABLES IN SCHEMA`**: grants on every table in the schema **that exists right now**. It's a one-time action, not a rule.

**`ALTER DEFAULT PRIVILEGES`**: sets up a rule for objects created **in the future**. A plain `GRANT … ON ALL TABLES` misses tables created later, so a new migration's table silently gets no grants. This is the one people forget. Note it applies to objects created **by the role running the `ALTER DEFAULT PRIVILEGES`** (or the role named with `FOR ROLE …`), so run it as the role that creates the tables (e.g. the migration role).

**`GRANT role TO role`** (role membership): how groups work. Grant privileges once to a group role such as `reporting`, then add people or services to it. `alice` inherits `reporting`'s privileges. To remove her: `REVOKE reporting FROM alice;`. Changing what `reporting` can do updates every member at once.

**`WITH GRANT OPTION`**: the recipient can grant the same privilege to **other** roles. It's rarely a good idea, because control spreads beyond the owner and becomes hard to audit.

**`REVOKE GRANT OPTION FOR …`**: takes away only the right to **pass the privilege on**. The role keeps the privilege itself.

**`CASCADE` vs `RESTRICT`** (on `REVOKE`): if the role already passed the privilege on to others (via `WITH GRANT OPTION`):
- **`RESTRICT`** (the default) **refuses** the revoke, so you don't accidentally break other roles' access.
- **`CASCADE`** revokes it from the role **and from everyone in the chain** it granted it to.
- ⚠️ **An owner implicitly holds every privilege on its objects.** Revoking `UPDATE`/`DELETE` from the owner doesn't make a table append-only. Real pattern: a **migration role** (owner, used by Flyway) and a separate **app role** (not the owner, minimal grants). Planned for `audit_log` in Week 5.

## Temporary tables
`CREATE TEMP TABLE t (…)`: visible **only to the creating session**, dropped automatically when the session ends (or at commit with `ON COMMIT DROP`), not written to the WAL. Used for staging bulk imports and intermediate results.
The `TEMPORARY` privilege matters because temp tables use memory/disk, and `pg_temp` can **shadow** real tables in name resolution. That's why security-sensitive functions pin `search_path`.

## Authentication (`pg_hba.conf`) vs authorization (GRANT)
`pg_hba.conf` decides **how a connection must authenticate**. Rules are checked **top to bottom, first match wins**. See them with `SELECT * FROM pg_hba_file_rules;`. In the official Docker image:

| Connection | Rule | Password? |
|---|---|---|
| Unix socket inside the container (`docker compose exec … psql`) | `local all all trust` | No |
| TCP to `127.0.0.1` / `::1` **inside** the container | `host … 127.0.0.1 trust` | No |
| Anything else: my Mac via the port mapping, other containers (the Spring services) | `host all all all scram-sha-256` | **Yes** |

So `make psql-users` needs no password. **Passwords are checked for connections from outside the container**, not "for all TCP" (verified: a wrong password from inside the container over `localhost` connected, but via the container's network IP it failed).

**Not a real hole:** to use those `trust` rules you must already be able to run commands inside the container, and then you could read the data files directly anyway. **The security boundary is access to Docker/the container.**

> 🎯 **Interview:** authentication ("who are you?", `pg_hba.conf`) and authorization ("what may you do?", GRANT/REVOKE) are **separate layers**. `trust` skipped authentication, but `REVOKE` still blocked `users_svc` from `products_db`. That's defense in depth.

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
