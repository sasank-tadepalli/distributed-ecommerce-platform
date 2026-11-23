-- Creates one database + one owning role per service.
-- Runs ONLY when the postgres volume is empty (first start). To re-run: docker compose down -v
-- Passwords come from the container environment (see docker-compose.yml / .env).

\getenv users_db_pwd USERS_DB_PASSWORD
\getenv products_db_pwd PRODUCTS_DB_PASSWORD
\getenv orders_db_pwd ORDERS_DB_PASSWORD

CREATE ROLE users_svc LOGIN PASSWORD :'users_db_pwd';
CREATE ROLE products_svc LOGIN PASSWORD :'products_db_pwd';
CREATE ROLE orders_svc LOGIN PASSWORD :'orders_db_pwd';

CREATE DATABASE users_db OWNER users_svc;
CREATE DATABASE products_db OWNER products_svc;
CREATE DATABASE orders_db OWNER orders_svc;

REVOKE ALL ON DATABASE users_db FROM PUBLIC;
REVOKE ALL ON DATABASE products_db FROM PUBLIC;
REVOKE ALL ON DATABASE orders_db FROM PUBLIC;
