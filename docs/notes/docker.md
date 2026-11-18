# Docker & Docker Compose

## Image vs container vs volume
| Term | What it is | Node analogy |
|---|---|---|
| **Image** | Read-only template (OS + app binaries) | A published npm package |
| **Container** | A running instance of an image. Disposable. | A running `node` process |
| **Volume** | Storage managed by Docker that **outlives** containers | Database files on disk |

You can delete a container at any time and lose nothing, as long as the data lives in a volume.

- **One image → many containers.** The image is never modified by running it.
- Each container gets its own thin **writable layer**. Anything written inside the container but *not* to a volume is lost when the container is removed. That's why database files must go to a volume.

- `docker compose down` removes containers and networks. **Volumes survive**, so the data is still there next time.
- `docker compose down -v` also deletes the volumes. **The data is gone.**

## Declarative, not step-by-step
A compose file describes the **desired state**, not commands to run. `docker compose up` compares the file with what's actually running and only changes the difference. Running it twice with no edits does nothing. Edit one service and only that container is recreated. Kubernetes and Terraform work the same way.

### What `docker compose up -d` does
1. Loads `.env`, substitutes `${…}`, turns `$$` into `$`
2. Creates the network `<project>_default` (always, even if not written in the file)
3. Creates the named volumes, or **reuses existing ones with their data**
4. Pulls the image if it isn't downloaded yet
5. Creates and starts the container (env vars, ports, mounts)
6. Runs the image's entrypoint (for Postgres: init on an empty volume, otherwise "Skipping initialization")
7. Runs the healthcheck repeatedly: `starting` → `healthy` / `unhealthy`

`-d` = detached (runs in the background). Without it, logs stream in your terminal and Ctrl+C stops everything.

### Networking
- Containers on the same Compose network reach each other by **service name**: users-service will connect to `postgres:5432`, not `localhost`. Compose runs a small DNS server for this.
- `ports:` is only for reaching a container **from the host**. Container-to-container traffic doesn't need it.
- `"127.0.0.1:5432:5432"` = `HOST_IP:HOST_PORT:CONTAINER_PORT`. If 5432 is taken on the host, change the **left** port.
- `127.0.0.1` binds to the **loopback interface** (this machine only). Without an IP, Docker binds to `0.0.0.0`, which is **every** interface, i.e. anyone on the network. On Linux, Docker's published ports even **bypass the host firewall** (ufw), a well-known way databases end up exposed to the internet.

### `container_name`
Gives a fixed name (otherwise it's `<project>-<service>-1`). Convenient, but it prevents running more than one copy of the service. Fine for a local DB, but avoid it for app services you might scale.

## Anatomy of a Compose service
```yaml
services:
  postgres:                          # service name = DNS name on the Compose network
    image: postgres:17-alpine        # pin versions; `latest` changes underneath you
    environment:                     # config as env vars (Twelve-Factor III)
      POSTGRES_USER: ${POSTGRES_USER}
    ports:
      - "127.0.0.1:5432:5432"        # host:container. 127.0.0.1 = only this machine can reach it
    volumes:
      - postgres-data:/var/lib/postgresql/data     # named volume (persistent data)
      - ./infra/postgres/init:/docker-entrypoint-initdb.d:ro   # bind mount (a host folder), read-only
    healthcheck: ...
volumes:
  postgres-data:
```
- **Named volume** (`postgres-data:`): Docker manages where it's stored. Use it for data.
- **Bind mount** (`./path:`): a folder from your machine. Use it for config and scripts you edit.
- The top-level `version:` key is obsolete; don't add it.

## `.env`: two separate mechanisms
1. **Substitution:** Compose automatically reads `.env` from the project root and replaces `${VAR}` *in the YAML file* before anything starts.
2. **Container environment:** only variables listed under `environment:` (or loaded with `env_file:`) exist *inside* the container.

Commit a `.env.example` with placeholders, and keep the real `.env` gitignored.

`docker compose config` prints the fully substituted YAML, so you can check for blank values. ⚠️ It prints **real secrets**, so never paste its output publicly.

## Healthchecks
"Container started" ≠ "service ready". Postgres takes a few seconds to accept connections.
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
  interval: 5s
  timeout: 5s
  retries: 10
```
The file is read twice, by two different programs:
1. **Compose, on my Mac, at `docker compose up`:** replaces `${VAR}` with the value from `.env`.
2. **The shell inside the container, every healthcheck:** also understands `${VAR}`, but reads the **container's** environment.

`$$` means "Compose, leave this `$` alone". Compose turns `$$` into `$`, and the container's shell does the substitution. It's like `\${name}` in a JS template literal.
```
pg_isready -U ${POSTGRES_USER}    → Compose writes in "platform_admin"
pg_isready -U $${POSTGRES_USER}   → Compose leaves "${POSTGRES_USER}" → container's shell fills it in
```
In this project both produce the same result. `$$` is the more robust habit: the healthcheck always matches what the container was actually started with.

⚠️ **The real gotcha:** a literal `$` in a value. `POSTGRES_PASSWORD: pa$word` written in the YAML silently becomes `pa`, because Compose tries to substitute `$word`. Write `pa$$word` instead. `.env` files are substituted too. There, wrap the value in **single quotes** to keep it literal: `POSTGRES_PASSWORD='pa$word'`. The easiest fix is to avoid `$` in local passwords.

Check it yourself: `docker compose config | grep -A2 healthcheck`.

Later, other services will use `depends_on: { postgres: { condition: service_healthy } }` so they wait until Postgres is actually ready.

## What the Postgres image does on first start
When the data volume is **empty**, the image's entrypoint runs these steps:
1. `initdb` creates the cluster, with **`POSTGRES_USER` as superuser** and `POSTGRES_PASSWORD` as its password
2. starts a temporary server
3. creates `POSTGRES_DB`
4. runs `/docker-entrypoint-initdb.d/*` **connected as `POSTGRES_USER`**
5. stops the temporary server, then starts the real one

So: **never create the admin role in an init script.** It already exists, and the script would fail with "role already exists". Also, the init script can only create roles and databases *because* it runs as that superuser.

`POSTGRES_USER`/`PASSWORD`/`DB` are **settings the image reads** (see its Docker Hub page). Variables like `USERS_DB_PASSWORD` are my own; only my script uses them.

⚠️ Passwords are **bootstrap configuration**: they're only applied on first init. Changing them in `.env` later does nothing. Either `docker compose down -v` (wipes the data) or `ALTER ROLE … PASSWORD '…'` inside Postgres.

> 🎯 **Interview:** bootstrap config vs runtime config. Once state exists, it takes priority over the config that created it.

## Init scripts (`/docker-entrypoint-initdb.d`)
The Postgres image runs any `.sql` or `.sh` file in this folder, in alphabetical order (hence the `01-` prefix).

⚠️ **They only run when the data volume is empty**, i.e. on the very first start. Editing the script and restarting does nothing. To re-run: `docker compose down -v && docker compose up -d`, which wipes the data.

## Volume names and stale volumes
- Compose names volumes **`<project>_<volume>`**. The project name defaults to the **folder name**: `postgres_data` → `distributed-ecommerce-platform_postgres_data`.
- Deleting or rewriting `docker-compose.yml` **doesn't delete its volumes**. A new compose file in the same folder with the same volume name **silently reuses the old data**.
- `docker volume ls` shows every volume; `docker volume rm <name>` deletes one.

Bug I hit: an old `postgres:15` setup left a volume behind. The new `postgres:17` container reused it, skipped init ("Database directory appears to contain a database; Skipping initialization"), then crashed with *"database files are incompatible with server … initialized by PostgreSQL version 15"*. Fix: `docker compose down -v`, since there was no data worth keeping.

**Postgres major versions (15 → 17) change the on-disk format.** Upgrading real data needs `pg_upgrade` or `pg_dump` + restore. Minor versions (17.11 → 17.12) are always compatible.

> 🎯 **Interview:** "How do you upgrade a production database's major version?" Plan it: test on a copy, `pg_upgrade` or dump/restore (or logical replication for near-zero downtime), with a rollback plan.

## Useful commands
```bash
docker compose up -d                 # start in the background
docker compose ps                    # status, including (healthy)
docker compose logs -f postgres      # follow logs
docker compose exec postgres psql -U <user> -d <db>   # run a command inside the container
docker compose down                  # stop, keep data
docker compose down -v               # stop and DELETE data
```
