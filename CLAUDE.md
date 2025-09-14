# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Agent Notices

- Use Transitional Chinese response.

## Architecture Overview

This repository contains a collection of Docker Compose configurations for various DevOps services designed for local development environments. The architecture uses Traefik as a reverse proxy to route traffic to different services through custom domains (*.docker.internal).

### Core Components

- **Network Architecture**: All services use a shared external Docker network named `devops` for inter-service communication
- **Reverse Proxy**: Traefik (v3.2.1) handles routing, SSL termination, and service discovery
- **Service Discovery**: Services are automatically discovered via Docker labels and exposed through custom domains
- **SSL/TLS**: Self-signed certificates using mkcert for HTTPS in local development

### Key Files

- `docker-compose.network.yaml`: Defines the shared external network configuration
- `makefile`: Primary service management interface
- `taskfile.yml`: Alternative task runner with Go Task
- `.env` (gitignored): Contains environment variables for domain and network settings

## Common Commands

### Service Management

Using Make (primary method):
```bash
# Start a service
make start service=<folder-name>

# Stop a service
make stop service=<folder-name>

# Restart a service
make restart service=<folder-name>

# View service configuration
make config service=<folder-name>
```

Using Task (alternative):
```bash
# Start traefik specifically
task traefik

# Start any service
task start <service-name>

# Stop any service
task stop <service-name>

# Completely remove service
task down <service-name>
```

### Network Setup

Before starting any services, create the shared network:
```bash
docker network create devops
```

### Required Environment Variables

Create a `.env` file with:
```
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops
BASE_NETWORK_YAML="docker-compose.network.yaml"
```

### Service Structure

Each service directory contains:
- `docker-compose.yml`: Service-specific configuration
- Optional `README.md`: Service-specific documentation
- Configuration files and volumes as needed

### Traefik Labels Pattern

Services typically use these Traefik labels for HTTP services:
```yaml
labels:
  - 'traefik.http.routers.{service}.tls=true'
  - 'traefik.http.routers.{service}.rule=Host(`{service}.$MY_DOMAIN`)'
  - 'traefik.http.routers.{service}.entrypoints=websecure'
  - 'traefik.http.services.{service}.loadbalancer.server.port={port}'
```

For TCP services (databases):
```yaml
labels:
  - 'traefik.tcp.routers.{service}.rule=HostSNI(`{service}.$MY_DOMAIN`)'
  - 'traefik.tcp.routers.{service}.entrypoints={service}'
  - 'traefik.tcp.services.{service}.loadBalancer.server.port={port}'
```

## Development Notes

- Services are designed to be started individually, not as a monolithic stack
- All HTTP services are accessible via https://{service-name}.docker.internal
- Database services use TCP routing through Traefik
- SSL certificates should be generated using mkcert (see traefik/certs/SSL.md)
- DNS resolution requires dnsmasq configuration for *.docker.internal domains