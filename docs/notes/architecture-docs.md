# Architecture Documentation

## C4 model
A way to organize architecture diagrams at increasing **zoom levels**, like a map:

| Level | Shows | In this repo |
|---|---|---|
| 1. System context | The system as one box, its users, external systems | `architecture/01-system-context.md` |
| 2. Containers | Separately deployable pieces: services, databases, brokers | `architecture/02-containers.md` |
| 3. Components | The insides of one container (controllers, services, repositories) | Added if needed |
| 4. Code | Classes. Usually left to the IDE | Not drawn |

"Container" in C4 means *deployable unit*, not specifically a Docker container.

**Rule: one diagram answers one question.** A diagram that tries to show everything communicates nothing.

## Mermaid
Diagrams written as text inside Markdown. GitHub renders them automatically.
- **Why:** they're diffable and reviewable, there's nothing to install, and you update them in the same commit as the code they describe.
- **Trade-off:** less polished than drawn diagrams. For LinkedIn or README "hero" images, a tool with real icons looks better.

| Mermaid type | Use it for |
|---|---|
| `flowchart` | Service maps, containers |
| `sequenceDiagram` | Request flows across services (`alt`/`else` for failure branches) |
| `erDiagram` | Database schemas |
| `stateDiagram-v2` | Lifecycles (e.g. order states) |

Preview in VS Code with the "Markdown Preview Mermaid Support" extension.

## ADRs (Architecture Decision Records)
A short markdown file per significant decision: **context → decision → alternatives considered → consequences**. Numbered, and never edited after acceptance. If a decision changes, a new ADR supersedes the old one. Template: [docs/adr/README.md](../adr/README.md).

> 🎯 **Interview:** "Why did you choose X?" is one of the most common follow-ups. ADRs mean you have a written, reasoned answer, including what you gave up.
