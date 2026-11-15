# Flow: Checkout

**Question:** What happens when a customer places an order, including when things fail?

**Status:** 🟡 Target design, built in Weeks 9–11

## Place order

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer
    participant GW as API Gateway
    participant O as Orders Service
    participant ODB as orders_db
    participant P as Products Service
    participant K as Kafka
    participant N as Notification Service

    C->>GW: POST /orders (Idempotency-Key header)
    GW->>GW: verify JWT, apply rate limit
    GW->>O: forward

    O->>ODB: idempotency key seen before?
    alt key already used
        O-->>C: return the saved response, create nothing new
    else new request
        O->>P: POST /reservations (SKUs, quantities, orderId)
        alt stock available
            P-->>O: 201 reserved
            O->>ODB: in ONE transaction, insert order + items + outbox event
            O-->>GW: 201 Created
            GW-->>C: 201 Created
        else insufficient stock
            P-->>O: 409 Conflict
            O-->>GW: 409 Conflict
            GW-->>C: 409 Conflict
        end
    end

    Note over O,K: Asynchronously, after the transaction commits
    O->>K: outbox relay publishes order.created.v1
    K->>N: deliver event
    N->>N: skip if already processed, otherwise notify the customer
```

## Failure cases to design for

| What fails | What happens | Pattern |
|---|---|---|
| Client retries after a timeout | The same order is returned, no duplicate created | Idempotency key |
| Products service is slow or down | Fail fast after a timeout, return 503 | Timeout + retry with backoff + circuit breaker |
| Stock reserved, but the order insert fails | Reservation released (compensation), or it expires on its own | Compensating action + reservation TTL |
| Kafka is down when the order commits | Event waits in the outbox table and is published later | Transactional outbox |
| Notification service gets the same event twice | Second copy is ignored | Idempotent consumer |
| Event keeps failing to process | Moved aside after N retries for inspection | Retry topic + dead-letter queue |

## Order lifecycle

```mermaid
stateDiagram-v2
    [*] --> PENDING
    PENDING --> RESERVED: stock reserved
    PENDING --> CANCELLED: reservation failed
    RESERVED --> PAID: payment captured
    RESERVED --> CANCELLED: customer cancels or reservation expires
    PAID --> SHIPPED
    PAID --> CANCELLED: refund
    SHIPPED --> DELIVERED
    DELIVERED --> [*]
    CANCELLED --> [*]
```

## Key decisions (fill in as you build)

- Why reserve stock synchronously instead of through an event? → _your answer here_
- Why store a price snapshot on each order line? → _your answer here_
- What's the reservation TTL, and why that value? → _your answer here_
