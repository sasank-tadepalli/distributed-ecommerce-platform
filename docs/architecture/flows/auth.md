# Flow: Authentication

**Question:** How do login, token refresh and token verification work?

**Status:** 🟡 Target design, built in Week 4

## Login, then calling another service

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant GW as API Gateway
    participant U as Users Service
    participant P as Products Service

    Note over GW,P: At startup, the gateway and each service fetch users-service's<br/>public keys from /.well-known/jwks.json and cache them

    C->>GW: POST /auth/login (email, password)
    GW->>U: forward
    U->>U: verify password hash, check account status
    U->>U: sign access token (RS256, 15 min) with private key
    U-->>GW: 200 access token + refresh token
    GW-->>C: 200

    C->>GW: GET /products (Authorization: Bearer access token)
    GW->>GW: verify signature and expiry with cached public key
    GW->>P: forward
    P->>P: verify token again, check permission (e.g. product:read)
    P-->>GW: 200 products
    GW-->>C: 200
```

## Refresh with rotation

```mermaid
sequenceDiagram
    autonumber
    actor C as Client
    participant GW as API Gateway
    participant U as Users Service
    participant DB as users_db

    C->>GW: POST /auth/refresh (refresh token)
    GW->>U: forward
    U->>DB: look up token by hash
    alt token valid and not used before
        U->>DB: revoke old token, store new one (same family)
        U-->>C: 200 new access token + new refresh token
    else token was already used (possible theft)
        U->>DB: revoke the whole token family
        U-->>C: 401 log in again
    end
```

## Key decisions (fill in as you build)

- Why RS256 (asymmetric) rather than HS256 (shared secret)? → _ADR to write in Week 4_
- Why verify at both the gateway and the service? → _your answer here_
- Where does the client keep the refresh token? → _your answer here_
