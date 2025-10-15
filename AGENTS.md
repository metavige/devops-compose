# DevOps Compose - AI Agent Guide

A layered Docker Compose architecture for local DevOps development environments.

## Agent Instructions

- **Language**: Use Traditional Chinese (繁體中文) for responses
- **Environment**: This is a local development environment - simple passwords are acceptable
- **Focus**: Prioritize modularity, clear layer separation, and ease of development

## Project Overview

This repository provides a comprehensive DevOps stack organized into logical layers:

- **Infrastructure Layer**: Core services (networking, storage, security, monitoring)
- **Platform Layer**: Container management and messaging services  
- **Development Layer**: SCM, CI/CD, quality assurance, and collaboration tools
- **Application Layer**: Business applications and specialized tools

## Dev Environment Setup

### Prerequisites
```bash
# Create shared Docker network
docker network create devops

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your preferred settings
```

### Quick Start
```bash
# Start infrastructure layer (must run first)
./scripts/start-infrastructure.sh

# Start specific services using Task
task start development/scm/gitlab
task start platform/containers/harbor2

# Or use Make (legacy support)
make start service=development/scm/gitlab
```

### Environment Variables
Create `.env` file with:
```env
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops
BASE_NETWORK_YAML="docker-compose.network.yaml"
```

## Build and Test Commands

### Service Management
```bash
# Infrastructure layer (required first)
./scripts/start-infrastructure.sh
./scripts/stop-infrastructure.sh  
./scripts/restart-infrastructure.sh

# Individual services
docker-compose -f infrastructure/network/docker-compose.yml up -d
docker-compose -f development/scm/gitlab/docker-compose.yml up -d

# Using Task runner
task start <layer>/<category>/<service>
task stop <layer>/<category>/<service>
```

### Service Discovery
```bash
# List available services
task search services

# Search by keyword
task search postgres
make search keyword=postgres
```

### Health Checks
Most services include health checks and are accessible via:
- HTTP services: `https://{service-name}.docker.internal`
- Database services: TCP routing through Traefik

## Architecture Guidelines

### Layer Dependencies
1. **Infrastructure Layer** - Start first (networking, storage, security)
2. **Platform Layer** - Depends on Infrastructure
3. **Development Layer** - Can run independently after Infrastructure
4. **Application Layer** - May depend on services from other layers

### Service Structure
Each service directory contains:
- `docker-compose.yml` - Service configuration
- `README.md` (optional) - Service-specific docs
- Configuration files and persistent volumes

### Network Access Patterns
- All HTTP services use Traefik reverse proxy
- HTTPS with self-signed certificates
- Database services use TCP routing
- Internal service communication via `devops` network

## Code Style and Conventions

### Docker Compose Standards
```yaml
# HTTP Service Traefik labels
labels:
  - 'traefik.http.routers.{service}.tls=true'
  - 'traefik.http.routers.{service}.rule=Host(`{service}.$MY_DOMAIN`)'
  - 'traefik.http.routers.{service}.entrypoints=websecure'
  - 'traefik.http.services.{service}.loadbalancer.server.port={port}'

# TCP Service Traefik labels  
labels:
  - 'traefik.tcp.routers.{service}.rule=HostSNI(`{service}.$MY_DOMAIN`)'
  - 'traefik.tcp.routers.{service}.entrypoints={service}'
  - 'traefik.tcp.services.{service}.loadBalancer.server.port={port}'
```

### File Organization
- Use consistent directory structure: `layer/category/service/`
- Keep secrets in dedicated `secrets/` directories
- Use Docker Secrets for sensitive data where possible
- Maintain backward compatibility with Make commands

## Security Considerations

### Development Environment
- Simple passwords are acceptable for local development
- Focus on container privilege escalation risks (`privileged: true`)
- Ensure proper volume mounting permissions
- Use Docker Secrets for production-ready configurations

### Best Practices
- Store secrets in `secrets/` directories
- Implement health checks for critical services
- Configure resource limits to prevent exhaustion
- Use security middleware in Traefik configurations

## Testing Instructions

### Service Validation
```bash
# Check service health
docker-compose ps
curl -k https://{service}.docker.internal/health

# Validate network connectivity
docker network inspect devops

# Test database connections
# PostgreSQL: https://pgadmin.docker.internal
# Redis: https://redis-ui.docker.internal
```

### Integration Testing
- Services should start in dependency order
- Infrastructure layer provides foundation for all other layers
- Verify Traefik routing for new services
- Test backup/restore procedures for data services

## Common Issues and Solutions

### Port Conflicts
- All external access goes through Traefik (ports 80/443)
- Database services use custom Traefik entrypoints
- Check for conflicting local services

### DNS Resolution
- Services use `{service-name}.docker.internal` format
- DNSMasq or CoreDNS handles internal resolution
- Add entries to hosts file if needed

### Service Dependencies
- Always start Infrastructure layer first
- Check Docker network connectivity
- Verify environment variables are set correctly

## Key Management Interfaces

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Traefik Dashboard | `https://traefik.docker.internal` | N/A |
| pgAdmin | `https://pgadmin.docker.internal` | admin@example.com |
| Redis Commander | `https://redis-ui.docker.internal` | N/A |
| Keycloak | `https://keycloak.docker.internal` | admin/admin |
| Portainer | `https://portainer.docker.internal` | admin/admin |
| GitLab | `https://gitlab.docker.internal` | root/password |

## Development Workflow

### Adding New Services
1. Create service directory following layer structure
2. Add `docker-compose.yml` with appropriate Traefik labels
3. Update relevant layer's main `docker-compose.yml`
4. Add service to `taskfile.yml` and `makefile`
5. Test service startup and connectivity
6. Document service-specific configuration

### Modifying Existing Services
1. Test changes in isolated environment
2. Verify backward compatibility
3. Update documentation if needed
4. Test startup/shutdown procedures
5. Validate integration with dependent services

This environment is designed for local development and testing. For production deployment, review security configurations and replace development passwords with secure alternatives.