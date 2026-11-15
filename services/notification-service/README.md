# Notification Service

Reacts to domain events and notifies users. To start with, "sending" just means logging the email.

**Owns:** its own small store of processed event IDs (for idempotency)

**Responsibilities**
- Consumes `order.created`, `order.cancelled` and other events from Kafka
- Idempotent consumer: processing the same event twice has no extra effect
- Retry topics and a dead-letter queue (DLQ) for events that keep failing

**Status:** ⬜ Not started (planned for Week 13)
