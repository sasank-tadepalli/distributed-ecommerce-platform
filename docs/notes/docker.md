# Docker & Docker Compose

## Image vs container vs volume
| Term | What it is | Node analogy |
|---|---|---|
| **Image** | Read-only template (OS + app binaries) | A published npm package |
| **Container** | A running instance of an image. Disposable. | A running `node` process |
| **Volume** | Storage managed by Docker that **outlives** containers | Database files on disk |

You can delete a container at any time and lose nothing, as long as the data lives in a volume.

- `docker compose down` removes containers and networks. **Volumes survive**, so the data is still there next time.
- `docker compose down -v` also deletes the volumes. **The data is gone.**

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
- `${VAR}` is replaced by **Compose** when it reads the file.
- `$${VAR}` is an escaped `$`. It's passed through literally, and the shell **inside the container** evaluates it.

Later, other services will use `depends_on: { postgres: { condition: service_healthy } }` so they wait until Postgres is actually ready.

## Init scripts (`/docker-entrypoint-initdb.d`)
The Postgres image runs any `.sql` or `.sh` file in this folder, in alphabetical order (hence the `01-` prefix).

⚠️ **They only run when the data volume is empty**, i.e. on the very first start. Editing the script and restarting does nothing. To re-run: `docker compose down -v && docker compose up -d`, which wipes the data.

## Useful commands
```bash
docker compose up -d                 # start in the background
docker compose ps                    # status, including (healthy)
docker compose logs -f postgres      # follow logs
docker compose exec postgres psql -U <user> -d <db>   # run a command inside the container
docker compose down                  # stop, keep data
docker compose down -v               # stop and DELETE data
```
