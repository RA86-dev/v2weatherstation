# Docker Installation Guide

This guide covers installing Weather Station v2.0 using Docker, which is the recommended deployment method for most users.

## Prerequisites

### System Requirements
- **OS**: Linux, macOS, or Windows (with WSL2)
- **Memory**: 2GB RAM minimum, 4GB recommended
- **Storage**: 5GB available space minimum
- **Network**: Internet connection for initial setup

### Required Software
- **Docker**: Version 20.10.0 or later
- **Docker Compose**: Version 2.0.0 or later
- **Git**: For cloning the repository

## Installation Steps

### Step 1: Install Docker

#### Ubuntu/Debian
```bash
# Update package index
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose-plugin
```

#### CentOS/RHEL/Fedora
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### macOS
1. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop)
2. Install and start Docker Desktop
3. Ensure Docker Compose is included (it comes with Docker Desktop)

#### Windows
1. Install WSL2 if not already installed
2. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop)
3. Install Docker Desktop with WSL2 backend
4. Ensure Docker Compose is included

### Step 2: Clone Repository

```bash
# Clone the Weather Station repository
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation
```

### Step 3: Quick Start with Docker

#### Option A: Simple Docker Run
```bash
# Build the Docker image
docker build -t v2weatherstation:latest .

# Run the container
docker run -d \
  --name weatherstation \
  -p 8110:8110 \
  -p 8080:8080 \
  v2weatherstation:latest
```

#### Option B: Docker Compose (Recommended)
```bash
# Navigate to the weather station directory
cd WeatherStation/weather_station

# Start services with Docker Compose
docker-compose up -d
```

### Step 4: Initialize Weather Data

```bash
# Wait for containers to start (30 seconds)
sleep 30

# Initialize weather data
./init-weather-data.sh
```

### Step 5: Verify Installation

```bash
# Check if containers are running
docker-compose ps

# Test the Weather Station API
curl http://localhost:8110/health

# Test the Open-Meteo API
curl http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&current=temperature_2m
```

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Server Configuration
WS_HOST=0.0.0.0
WS_PORT=8110
WS_DEBUG=false

# Data Source Configuration
WS_LIVE_DATA_ENABLED=true
WS_USE_SELF_HOSTED=true
WS_OPEN_METEO_URL=http://localhost:8080/v1

# Security
WS_API_KEY=your-32-character-api-key-here

# Logging
WS_LOG_LEVEL=INFO

# CORS (for web applications)
WS_CORS_ORIGINS=["*"]
```

### Docker Compose Configuration

Example `docker-compose.yml`:

```yaml
version: '3.8'

services:
  weatherstation:
    build: .
    container_name: weatherstation-app
    ports:
      - "8110:8110"
    environment:
      - WS_HOST=0.0.0.0
      - WS_PORT=8110
      - WS_LIVE_DATA_ENABLED=true
      - WS_OPEN_METEO_URL=http://openmeteo:8080/v1
    depends_on:
      - openmeteo
    restart: unless-stopped
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs

  openmeteo:
    image: ghcr.io/open-meteo/open-meteo:latest
    container_name: openmeteo-api
    ports:
      - "8080:8080"
    environment:
      - OPEN_METEO_PORT=8080
    volumes:
      - openmeteo-data:/app/data
    restart: unless-stopped

volumes:
  openmeteo-data:
```

## Management Commands

### Start Services
```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d weatherstation
```

### Stop Services
```bash
# Stop all services
docker-compose down

# Stop but keep volumes
docker-compose stop
```

### View Logs
```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs for specific service
docker-compose logs weatherstation
```

### Update Services
```bash
# Pull latest changes
git pull

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Restart Services
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart weatherstation
```

## Data Persistence

### Volumes
The Docker setup uses volumes to persist data:

- `openmeteo-data`: Weather model data
- `./data`: Application data and cache
- `./logs`: Application logs

### Backup
```bash
# Create backup of all data
docker run --rm -v $(pwd):/backup \
  -v openmeteo-data:/data \
  alpine tar czf /backup/weatherstation-backup.tar.gz /data
```

### Restore
```bash
# Restore from backup
docker run --rm -v $(pwd):/backup \
  -v openmeteo-data:/data \
  alpine tar xzf /backup/weatherstation-backup.tar.gz -C /
```

## Networking

### Port Configuration

| Port | Service | Description |
|------|---------|-------------|
| 8110 | Weather Station | Main application API and web interface |
| 8080 | Open-Meteo API | Weather data API |

### Custom Networks

For advanced setups, create a custom network:

```yaml
networks:
  weatherstation:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Security

### Firewall Configuration
```bash
# Allow Weather Station port
sudo ufw allow 8110/tcp

# Allow Open-Meteo port (if external access needed)
sudo ufw allow 8080/tcp
```

### SSL/TLS with Reverse Proxy

For production, use a reverse proxy with SSL:

```nginx
server {
    listen 443 ssl;
    server_name weather.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8110;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check container status
docker-compose ps

# Check logs for errors
docker-compose logs weatherstation
```

#### Port Already in Use
```bash
# Check what's using the port
sudo lsof -i :8110

# Kill the process or change port in docker-compose.yml
```

#### Out of Disk Space
```bash
# Clean up Docker
docker system prune -a

# Remove unused volumes
docker volume prune
```

#### API Not Accessible
```bash
# Test internal connectivity
docker exec weatherstation-app curl http://localhost:8110/health

# Check firewall
sudo ufw status
```

### Health Checks

```bash
# Check Weather Station health
curl http://localhost:8110/health

# Check Open-Meteo health
curl http://localhost:8080/v1/forecast?latitude=0&longitude=0&current=temperature_2m

# Check Docker container health
docker exec weatherstation-app python -c "import requests; print(requests.get('http://localhost:8110/health').status_code)"
```

## Performance Optimization

### Resource Limits

```yaml
services:
  weatherstation:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

### Caching

Enable Redis for better performance:

```yaml
services:
  redis:
    image: redis:alpine
    container_name: weatherstation-redis
    restart: unless-stopped
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

## Next Steps

- [Configuration Reference](../reference/configuration.md)
- [API Documentation](../api/overview.md)
- [User Guide](../guides/user-guide.md)
- [Troubleshooting](../support/troubleshooting.md)

## Support

If you encounter issues:

1. Check the [Troubleshooting Guide](../support/troubleshooting.md)
2. Review the [FAQ](../support/faq.md)
3. Search [GitHub Issues](https://github.com/RA86-dev/v2weatherstation/issues)
4. Create a new issue with detailed information