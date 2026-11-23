.PHONY: help up down ps logs reset psql psql-users psql-products psql-orders verify-isolation

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

up: ## Start everything in the background
	docker compose up -d

down: ## Stop everything, keeping the data
	docker compose down

ps: ## Show the status of the containers
	docker compose ps

logs: ## Show the logs of Postgres
	docker compose logs -f postgres

reset: ## Delete ALL local data and start fresh (asks first)
	@read -p "Delete ALL local data? [y/N] " answer; \
	[ "$$answer" = "y" ] || { echo "Reset cancelled."; exit 1; }
	docker compose down -v
	docker compose up -d

psql: ## Connect to the Postgres database as admin user
	docker compose exec postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

psql-users: ## Connect to the postgres users database using users_svc role
	docker compose exec postgres psql -U users_svc -d users_db

psql-products: ## Connect to the postgres products database using products_svc role
	docker compose exec postgres psql -U products_svc -d products_db

psql-orders: ## Connect to the postgres orders database using orders_svc role
	docker compose exec postgres psql -U orders_svc -d orders_db

verify-isolation: ## Prove each service role can reach only its own database
	@echo "Verifying isolation between service roles and databases..."; \
	for role in users_svc products_svc orders_svc; do \
		for db in users_db products_db orders_db; do \
			if [ "$$role" != "$${db%_db}_svc" ]; then \
				docker compose exec -T postgres psql -U $$role -d $$db -tAc 'SELECT 1' > /dev/null 2>&1 && { echo "Isolation test failed: $$role can access $$db"; exit 1; } || echo "Isolation test passed: $$role cannot access $$db"; \
			else \
				docker compose exec -T postgres psql -U $$role -d $$db -tAc 'SELECT 1' > /dev/null 2>&1 && echo "Isolation test passed: $$role can access $$db" || { echo "Isolation test failed: $$role cannot access $$db"; exit 1; }; \
			fi; \
		done; \
	done
