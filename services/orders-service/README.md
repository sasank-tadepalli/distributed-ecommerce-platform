# Orders Service

Cart, checkout and the order lifecycle.

**Owns:** `orders_db` (orders, order items, status history, idempotency keys, outbox events, audit log)

**Responsibilities**
- Cart (Redis, with a TTL) and checkout
- Order state machine: PENDING → RESERVED → PAID → SHIPPED → DELIVERED / CANCELLED
- Reserves stock in products-service (with retries and a circuit breaker)
- Idempotent order creation, and reliable event publishing through the transactional outbox

**Status:** ⬜ Not started (planned for Weeks 9–11)
