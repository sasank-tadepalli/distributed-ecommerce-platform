# Notes

Concepts I've learned while building this project, organized by **topic** (not by day) so they work as a reference. Each note explains *why* something exists, not just how to use it, and includes the gotchas I hit.

The [journal](../distributed-ecommerce-journal.md) records *when* I learned things and what happened. These notes record *what* I learned, in full.

| Note | Covers | First learned |
|---|---|---|
| [dev-environment.md](dev-environment.md) | JDK/JRE/JVM, LTS releases, SDKMAN, shell startup files, `source` | Week 1, Day 1 |
| [git.md](git.md) | `.gitignore` rules, commit messages, staging | Week 1, Day 1 |
| [architecture-docs.md](architecture-docs.md) | C4 model, Mermaid, ADRs | Week 1, Day 1 |
| [java.md](java.md) | Records, interfaces, generics, `Optional`, streams, equality, nested classes, immutability, money | Week 1, Day 2 |
| [docker.md](docker.md) | Images, containers, volumes, Compose, `.env`, healthchecks, init scripts | Week 1, Day 2 |
| [postgres.md](postgres.md) | Roles, database ownership, least privilege, `psql` variables | Week 1, Day 2 |

## How to add a note
- Add to the existing topic file if one fits. Start a new file only for a genuinely new area (e.g. `spring.md`, `jpa.md`, `kafka.md`).
- Structure each concept as: **what it is → why it exists → how it's used here → gotchas**.
- Put interview-worthy points in a **🎯 Interview** callout.
- Add new files to the table above.
