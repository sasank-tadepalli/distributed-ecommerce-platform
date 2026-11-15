# API Gateway

The single entry point for all external traffic (Spring Cloud Gateway).

**Owns:** no database

**Responsibilities**
- Routing to the backend services
- JWT validation at the edge
- Rate limiting (Redis token bucket)
- CORS

**Status:** ⬜ Not started (planned for Week 12)
