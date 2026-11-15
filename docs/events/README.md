# Event Contracts

The Kafka event schemas that services agree on. Events are **versioned contracts** (for example `order.created.v1`): consumers depend on them, so breaking changes need a new version.

For each event, document: topic, partition key, producer, consumers, payload schema and an example.

**Status:** ⬜ Defined from Week 11 onward
