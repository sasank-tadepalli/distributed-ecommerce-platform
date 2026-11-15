# Products Service

Product catalog and inventory.

**Owns:** `products_db` (categories, products, SKUs/variants, inventory, reservations, audit log)

**Responsibilities**
- Catalog browsing with pagination and filtering (cached in Redis)
- Inventory with oversell protection (optimistic locking)
- Stock reservations for orders

**Status:** ⬜ Not started (planned for Weeks 6–8)
