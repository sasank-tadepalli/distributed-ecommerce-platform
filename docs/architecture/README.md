# Architecture

How the platform is structured and how requests flow through it. The docs follow the [C4 model](https://c4model.com/): each level zooms in further, and each diagram answers one question.

All diagrams are [Mermaid](https://mermaid.js.org/) code inside Markdown, so GitHub renders them automatically. Update a diagram **in the same commit** as the change it describes.

## Overview

The platform is a set of Spring Boot microservices behind an API gateway. Each service owns its own PostgreSQL database; no service reads another service's database. Services talk to each other in two ways:
- **synchronous REST**, when the caller needs an answer right away (for example, reserving stock at checkout)
- **asynchronous Kafka events**, published through a transactional outbox, when others just need to know something happened (for example, `order.created`)

Authentication uses RS256-signed JWTs issued by users-service. Every other service verifies tokens locally with users-service's public key (JWKS), so it never has to call users-service on each request.

## Contents

| Doc | Question it answers | Status |
|---|---|---|
| [01-system-context.md](01-system-context.md) | Who uses the platform, and which external systems does it depend on? | 🟡 Draft |
| [02-containers.md](02-containers.md) | Which services, databases and brokers exist, and how do they connect? | 🟡 Draft (target design) |
| [flows/auth.md](flows/auth.md) | How do login, token refresh and token verification work? | 🟡 Draft (built in Week 4) |
| [flows/checkout.md](flows/checkout.md) | What happens when a customer places an order, including failures? | 🟡 Draft (built in Weeks 9–11) |

Related: [database design](../db/), [event contracts](../events/), [decision records](../adr/)

> **Draft** means this is the target design from the [roadmap](../roadmap/learning-and-build-plan.md). Change it to ✅ once the implementation matches the diagram.
