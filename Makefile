.PHONY: help install dev dev-docker build test lint clean docker-build docker-push deploy

help:
	@echo "Expodia - Available Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make install              Install dependencies"
	@echo "  make setup               Setup project with initial configuration"
	@echo ""
	@echo "Development:"
	@echo "  make dev                 Start development server (local)"
	@echo "  make dev-docker          Start development with Docker"
	@echo "  make dev-docker-build    Build and start with Docker"
	@echo ""
	@echo "Building & Testing:"
	@echo "  make build               Build for production"
	@echo "  make test                Run tests"
	@echo "  make lint                Run linter"
	@echo ""
	@echo "Database:"
	@echo "  make migrate             Run database migrations"
	@echo "  make migrate-undo        Undo last migration"
	@echo "  make seed                Seed initial data"
	@echo "  make db-reset            Reset database (development only)"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build        Build Docker image"
	@echo "  make docker-push         Push Docker image to registry"
	@echo "  make docker-clean        Remove Docker containers and images"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean               Clean build artifacts and node_modules"
	@echo "  make clean-logs          Clean log files"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy              Deploy to staging"
	@echo "  make deploy-prod         Deploy to production"

install:
	npm install

setup: install
	@cp .env.example .env.local
	@echo "✓ Copied .env.example to .env.local"
	@echo "⚠️  Please edit .env.local with your configuration"

dev:
	npm run dev

dev-docker:
	docker-compose up

dev-docker-build:
	docker-compose up -d --build

build:
	npm run build

test:
	npm test

lint:
	npm run lint

migrate:
	npm run migrate

migrate-undo:
	npm run migrate:undo

seed:
	npm run seed

db-reset: migrate-undo migrate seed
	@echo "✓ Database reset complete"

docker-build:
	docker build -t expodia:latest .

docker-push: docker-build
	@read -p "Enter Docker registry (e.g., your-username): " registry; \
	docker tag expodia:latest $$registry/expodia:latest; \
	docker push $$registry/expodia:latest

docker-clean:
	docker-compose down -v
	docker rmi expodia:latest

clean:
	rm -rf node_modules dist build
	npm cache clean --force

clean-logs:
	rm -rf logs/*.log

deploy:
	@echo "Deploying to staging..."
	git push origin main
	@echo "✓ Pushed to main branch"
	@echo "Staging deployment should trigger automatically"

deploy-prod:
	@echo "⚠️  WARNING: About to deploy to PRODUCTION"
	@read -p "Are you sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		git push origin main && git tag production-$$(date +%Y%m%d-%H%M%S) && git push --tags; \
		echo "✓ Pushed to main and created production tag"; \
		echo "Production deployment should trigger automatically"; \
	else \
		echo "Deployment cancelled"; \
	fi

# Utility commands
logs:
	docker-compose logs -f app

ps:
	docker-compose ps

shell:
	docker-compose exec app sh

db-shell:
	docker-compose exec postgres psql -U expodia -d expodia_dev

redis-cli:
	docker-compose exec redis redis-cli

health:
	@curl -s http://localhost:3000/health | jq .

# Development helpers
format:
	npm run format

format-check:
	npm run format:check

analyze:
	npm run analyze

performance:
	npm run performance
