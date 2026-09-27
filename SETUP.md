# Expodia Setup & Deployment Guide

This guide helps you set up the Expodia project across different environments (local, staging, production).

## Prerequisites

- **Node.js**: v18+ ([Download](https://nodejs.org/))
- **npm** or **yarn**: Latest version
- **Docker**: v20.10+ ([Download](https://www.docker.com/))
- **Docker Compose**: v1.29+ (usually included with Docker Desktop)
- **Git**: v2.30+

## Quick Start

### Option 1: Local Development (Without Docker)

1. **Extract the project files**
   ```bash
   unzip expodia-flight-main.zip
   cd expodia-flight-main
   ```

2. **Install dependencies**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration
   nano .env.local
   ```

4. **Initialize database** (if applicable)
   ```bash
   npm run migrate
   # or
   npm run db:setup
   ```

5. **Start the application**
   ```bash
   npm run dev
   # or for production build
   npm run build
   npm start
   ```

6. **Access the application**
   - Open http://localhost:3000 in your browser

### Option 2: Docker Development (Recommended)

1. **Extract the project files**
   ```bash
   unzip expodia-flight-main.zip
   cd expodia-flight-main
   ```

2. **Set up environment file**
   ```bash
   cp .env.example .env.local
   # Edit if needed
   ```

3. **Build and start services**
   ```bash
   docker-compose up -d
   ```

   This starts:
   - **App**: http://localhost:3000
   - **PostgreSQL**: localhost:5432
   - **Redis**: localhost:6379

4. **View logs**
   ```bash
   docker-compose logs -f app
   ```

5. **Stop services**
   ```bash
   docker-compose down
   ```

### Option 3: Kubernetes/Production Deployment

1. **Build Docker image**
   ```bash
   docker build -t expodia:latest .
   docker tag expodia:latest your-registry/expodia:latest
   docker push your-registry/expodia:latest
   ```

2. **Create namespace** (if needed)
   ```bash
   kubectl create namespace expodia
   ```

3. **Deploy using Helm or kubectl manifests**
   ```bash
   kubectl apply -f k8s/
   ```

## Environment Configuration

### Development (.env.local)
- Use `.env.example` as template
- LocalHost databases are fine
- Debug logging enabled
- Relaxed CORS settings

### Staging (.env.staging)
- Use external staging database
- All credentials via environment variables
- Moderate logging level
- Staging API endpoints

### Production (.env.production)
- Use external production database with SSL
- All secrets from secure vault
- Minimal logging (warn level)
- Production API endpoints
- Sentry error tracking enabled

## Database Setup

### PostgreSQL Initialization

```bash
# Using Docker
docker exec expodia-postgres psql -U expodia -d expodia_dev -c "CREATE EXTENSION IF NOT EXISTS uuid-ossp;"

# Or manually
psql -h localhost -U expodia -d expodia_dev < scripts/init.sql
```

### Run Migrations

```bash
npm run migrate
# or
npm run migrate:prod  # for production
```

## Available Scripts

```bash
# Development
npm run dev              # Start dev server with hot-reload
npm run dev:docker      # Start with Docker Compose

# Building
npm run build           # Build for production
npm run build:docker    # Build Docker image

# Database
npm run migrate         # Run migrations
npm run migrate:undo    # Rollback migrations
npm run seed           # Seed initial data

# Testing
npm run test           # Run tests
npm run test:coverage  # Run with coverage report
npm run lint           # Run linter

# Deployment
npm run deploy         # Deploy to staging
npm run deploy:prod    # Deploy to production
```

## Docker Cheat Sheet

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Execute command in container
docker-compose exec app npm run migrate

# Rebuild services
docker-compose up -d --build

# Clean up everything
docker-compose down -v  # includes removing volumes

# Scale services
docker-compose up -d --scale app=3
```

## Troubleshooting

### Port Already in Use
```bash
# Find process using port
lsof -i :3000
# Kill process
kill -9 <PID>

# Or use Docker with different port
docker-compose down
# Edit docker-compose.yml port mapping
docker-compose up -d
```

### Database Connection Issues
```bash
# Test connection
docker-compose exec postgres psql -U expodia -d expodia_dev -c "SELECT 1"

# Check credentials in .env file
cat .env.local | grep DB_
```

### Out of Memory
```bash
# Increase Docker memory allocation
# Docker Desktop → Preferences → Resources → Memory: 4GB+

# Or limit container memory in docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 2G
```

### Redis Connection Issues
```bash
# Test Redis
docker-compose exec redis redis-cli ping

# Flush Redis cache (development only)
docker-compose exec redis redis-cli FLUSHALL
```

## Monitoring & Logs

### Application Logs
```bash
# Docker
docker-compose logs -f app --tail=100

# Local
npm run dev 2>&1 | tee app.log
```

### Health Check
```bash
curl http://localhost:3000/health
# Expected: {"status": "ok"}
```

## Security Checklist

- [ ] All credentials stored in `.env` files (never commit)
- [ ] Use strong JWT secrets in production
- [ ] Enable HTTPS in production
- [ ] Restrict CORS to known origins
- [ ] Use SSL for database connections
- [ ] Enable authentication/authorization
- [ ] Set up rate limiting
- [ ] Configure firewall rules
- [ ] Enable logging and monitoring
- [ ] Regular security updates

## Support & Documentation

- **Bug Reports**: [GitHub Issues](https://github.com/theoraclearc-a11y/Expodia/issues)
- **Documentation**: See `docs/` folder
- **API Documentation**: See `docs/API.md`

## Contributing

1. Create a feature branch: `git checkout -b feature/amazing-feature`
2. Commit changes: `git commit -m 'Add amazing feature'`
3. Push to branch: `git push origin feature/amazing-feature`
4. Open a Pull Request

## License

See LICENSE file for details.
