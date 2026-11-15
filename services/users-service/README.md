# Users Service

Identity, authentication and authorization for the platform.

**Owns:** `users_db` (users, roles, permissions, refresh tokens, addresses, audit log)

**Responsibilities**
- Registration, login, refresh-token rotation, `/me`
- Issues RS256-signed JWTs and publishes its public key at a JWKS endpoint, so other services can verify tokens without calling this service
- Role and permission management (RBAC), with every grant and revoke audited

**Status:** ⬜ Not started (planned for Weeks 2–5)
