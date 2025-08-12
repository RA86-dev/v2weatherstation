# Troubleshooting Guide

This comprehensive guide covers common issues, solutions, and debugging techniques for Weather Station v2.0.

## Quick Diagnostics

### Health Check Commands
```bash
# Basic health check
curl http://localhost:8110/health

# Detailed system status
curl http://localhost:8110/api/status

# Check Docker containers
docker-compose ps

# View application logs
docker-compose logs weatherstation
```

### Expected Healthy Responses

**Health Endpoint** (`/health`):
```json
{
  \"status\": \"healthy\",
  \"version\": \"2.0.0\",
  \"timestamp\": \"2025-01-01T00:00:00Z\",
  \"data_status\": {
    \"live_data_enabled\": true,
    \"api_accessible\": true,
    \"last_update\": \"2025-01-01T00:00:00Z\"
  }
}
```

**System Status** (`/api/status`):
```json
{
  \"api_status\": {
    \"accessible\": true,
    \"response_time_ms\": 45
  },
  \"live_data_enabled\": true,
  \"self_hosted\": true
}
```

## Installation Issues

### Docker Installation Problems

#### Docker Not Running
**Symptoms**: \"Cannot connect to the Docker daemon\"

**Solutions**:
```bash
# Start Docker service (Linux)
sudo systemctl start docker

# Start Docker Desktop (macOS/Windows)
# Open Docker Desktop application

# Check Docker status
docker info
```

#### Permission Denied
**Symptoms**: \"permission denied while trying to connect to the Docker daemon socket\"

**Solutions**:
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo (not recommended)
sudo docker-compose up -d
```

#### Port Already in Use
**Symptoms**: \"Port 8110 is already in use\"

**Solutions**:
```bash
# Find process using port
sudo lsof -i :8110

# Kill the process
sudo kill -9 <PID>

# Or use different port
WS_PORT=8111 docker-compose up -d
```

#### Out of Disk Space
**Symptoms**: \"No space left on device\"

**Solutions**:
```bash
# Clean Docker system
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
df -h
du -sh ~/.docker
```

### Manual Installation Problems

#### Python Version Issues
**Symptoms**: \"Python 3.8+ required\"

**Solutions**:
```bash
# Check Python version
python3 --version

# Install Python 3.11 (Ubuntu)
sudo apt update
sudo apt install python3.11 python3.11-venv

# Use specific Python version
python3.11 -m venv venv
```

#### Module Not Found
**Symptoms**: \"ModuleNotFoundError: No module named 'fastapi'\"

**Solutions**:
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt

# Check installed packages
pip list
```

#### Virtual Environment Issues
**Symptoms**: Virtual environment not working properly

**Solutions**:
```bash
# Remove and recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Service Issues

### Application Won't Start

#### Configuration Errors
**Symptoms**: Application exits immediately with configuration error

**Debug Steps**:
```bash
# Check configuration
python3 -c \"from WeatherStation.weather_station.config import get_config; print(get_config().to_dict())\"

# Validate environment variables
env | grep WS_

# Check syntax of .env file
cat .env
```

**Common Fixes**:
```env
# Fix malformed environment variables
WS_CORS_ORIGINS=[\"*\"]  # Correct
# WS_CORS_ORIGINS=*    # Incorrect

# Ensure boolean values are lowercase
WS_DEBUG=true          # Correct
# WS_DEBUG=True        # Incorrect
```

#### Import Errors
**Symptoms**: \"ImportError\" or \"ModuleNotFoundError\"

**Debug Steps**:
```bash
# Check Python path
python3 -c \"import sys; print(sys.path)\"

# Test imports manually
python3 -c \"from WeatherStation.weather_station import index\"

# Check file structure
ls -la WeatherStation/weather_station/
```

### API Connection Issues

#### Open-Meteo API Not Accessible
**Symptoms**: \"Weather service temporarily unavailable\"

**Debug Steps**:
```bash
# Test Open-Meteo API directly
curl \"http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&current=temperature_2m\"

# Check Open-Meteo container
docker logs openmeteo-api

# Verify network connectivity
docker exec weatherstation-app curl http://openmeteo:8080/v1/forecast?latitude=0&longitude=0&current=temperature_2m
```

**Solutions**:
```bash
# Restart Open-Meteo container
docker-compose restart openmeteo

# Re-initialize weather data
./init-weather-data.sh

# Check if using external API
WS_USE_SELF_HOSTED=false
WS_OPEN_METEO_URL=https://api.open-meteo.com/v1
```

#### Slow API Responses
**Symptoms**: API calls take >30 seconds

**Debug Steps**:
```bash
# Test API response time
time curl \"http://localhost:8110/api/data/weather?limit=10\"

# Check resource usage
docker stats

# Monitor database queries (if applicable)
docker-compose logs -f
```

**Solutions**:
```bash
# Reduce data load
curl \"http://localhost:8110/api/data/weather?limit=5\"

# Check Open-Meteo data availability
./init-weather-data.sh

# Restart services
docker-compose restart
```

### Data Issues

#### No Weather Data Available
**Symptoms**: Empty data responses or \"Weather data not available\"

**Debug Steps**:
```bash
# Check data manager status
curl http://localhost:8110/api/data/status

# Verify weather data initialization
docker volume ls | grep openmeteo
docker run --rm -v openmeteo-api:/data alpine ls -la /data

# Test data fetching
curl \"http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&hourly=temperature_2m\" -v
```

**Solutions**:
```bash
# Re-initialize weather data
./init-weather-data.sh

# Force data update (requires API key)
curl -X POST http://localhost:8110/api/data/force-update \\
  -H \"X-API-Key: your-api-key\"

# Switch to external API temporarily
WS_USE_SELF_HOSTED=false docker-compose restart
```

#### Outdated Weather Data
**Symptoms**: Data timestamps are hours old

**Debug Steps**:
```bash
# Check last update time
curl http://localhost:8110/api/data/status | jq '.last_update'

# Verify automatic updates
docker-compose logs weatherstation | grep \"update\"

# Check system time
date
docker exec weatherstation-app date
```

**Solutions**:
```bash
# Manual data update
curl -X POST http://localhost:8110/api/data/force-update \\
  -H \"X-API-Key: $(grep WS_API_KEY .env | cut -d= -f2)\"

# Check update schedule
# Updates should happen every hour automatically

# Restart data manager
docker-compose restart weatherstation
```

## Performance Issues

### High Memory Usage

**Symptoms**: System becomes slow, Docker containers using excessive memory

**Debug Steps**:
```bash
# Check memory usage
docker stats --no-stream
free -h

# Check application memory
docker exec weatherstation-app ps aux

# Monitor memory over time
watch \"docker stats --no-stream\"
```

**Solutions**:
```bash
# Set memory limits in docker-compose.yml
services:
  weatherstation:
    deploy:
      resources:
        limits:
          memory: 1G

# Reduce data cache size
WS_CACHE_SIZE=100 docker-compose restart

# Clear Docker system cache
docker system prune
```

### High CPU Usage

**Symptoms**: System becomes slow, high CPU usage by Docker containers

**Debug Steps**:
```bash
# Check CPU usage
top
htop
docker stats --no-stream

# Check for infinite loops in logs
docker-compose logs weatherstation | tail -100
```

**Solutions**:
```bash
# Set CPU limits
services:
  weatherstation:
    deploy:
      resources:
        limits:
          cpus: '0.5'

# Reduce API request frequency
# Check for client polling too frequently

# Restart services
docker-compose restart
```

### Slow Response Times

**Symptoms**: Web interface loads slowly, API calls take >5 seconds

**Debug Steps**:
```bash
# Test API response times
time curl \"http://localhost:8110/api/data/weather?limit=5\"

# Check database query performance
docker-compose logs weatherstation | grep \"slow\"

# Monitor resource usage
docker stats
```

**Solutions**:
```bash
# Enable caching
WS_ENABLE_CACHE=true

# Reduce data fetching
curl \"http://localhost:8110/api/data/weather?limit=10\"

# Optimize database queries
# Check for missing indexes

# Use CDN for static assets
# Configure reverse proxy caching
```

## Network Issues

### Cannot Access Web Interface

**Symptoms**: Browser shows \"This site can't be reached\"

**Debug Steps**:
```bash
# Check if service is listening
sudo netstat -tlnp | grep 8110

# Test local access
curl http://localhost:8110/health

# Check firewall
sudo ufw status
sudo iptables -L

# Check Docker networking
docker network ls
docker inspect bridge
```

**Solutions**:
```bash
# Allow port through firewall
sudo ufw allow 8110/tcp

# Check binding address
# Ensure WS_HOST=0.0.0.0 not 127.0.0.1

# Restart networking
sudo systemctl restart docker
docker-compose down && docker-compose up -d
```

### CORS Errors

**Symptoms**: \"Access to fetch at ... has been blocked by CORS policy\"

**Debug Steps**:
```bash
# Check CORS configuration
grep CORS .env

# Test with curl (should work)
curl -H \"Origin: http://example.com\" \\
     -H \"Access-Control-Request-Method: GET\" \\
     http://localhost:8110/api/data/weather
```

**Solutions**:
```env
# Allow all origins (development only)
WS_CORS_ORIGINS=[\"*\"]

# Allow specific origins (production)
WS_CORS_ORIGINS=[\"https://yourdomain.com\", \"https://app.yourdomain.com\"]
```

### SSL/TLS Issues

**Symptoms**: \"SSL certificate error\" or \"ERR_CERT_AUTHORITY_INVALID\"

**Debug Steps**:
```bash
# Check certificate validity
openssl s_client -connect yourdomain.com:443

# Check reverse proxy configuration
sudo nginx -t
sudo apache2ctl configtest
```

**Solutions**:
```bash
# Renew Let's Encrypt certificate
sudo certbot renew

# Check certificate paths in nginx/apache config
# Ensure certificate files exist and are readable
ls -la /etc/ssl/certs/
```

## Authentication Issues

### API Key Problems

**Symptoms**: \"Unauthorized\" or \"Valid API key required\"

**Debug Steps**:
```bash
# Check API key in configuration
grep WS_API_KEY .env

# Get API key (debug mode only)
curl http://localhost:8110/admin/api-key

# Test API key
curl -X POST http://localhost:8110/api/data/force-update \\
  -H \"X-API-Key: your-key-here\" -v
```

**Solutions**:
```bash
# Generate new API key
WS_API_KEY=$(openssl rand -hex 32)
echo \"WS_API_KEY=$WS_API_KEY\" >> .env
docker-compose restart

# Use correct header format
# X-API-Key: key (not Authorization: key)
```

## Data Quality Issues

### Inaccurate Weather Data

**Symptoms**: Weather data doesn't match other sources

**Debug Steps**:
```bash
# Compare with external source
curl \"https://api.open-meteo.com/v1/current?latitude=40.7&longitude=-74.0&current=temperature_2m\"

# Check data timestamp
curl http://localhost:8110/api/data/live/New%20York | jq '.timestamp'

# Verify coordinates
curl http://localhost:8110/api/data/locations | jq '.coordinates[\"New York\"]'
```

**Solutions**:
```bash
# Update location coordinates
# Edit WeatherStation/weather_station/updaters/geolocations.json

# Force fresh data fetch
./init-weather-data.sh

# Check Open-Meteo model availability
docker run --rm -v openmeteo-api:/data alpine ls -la /data
```

### Missing Locations

**Symptoms**: Expected cities not showing in location list

**Debug Steps**:
```bash
# Check available locations
curl http://localhost:8110/api/data/locations | jq '.total'

# Verify geolocations file
cat WeatherStation/weather_station/updaters/geolocations.json | jq keys

# Check for filtering
curl \"http://localhost:8110/api/data/weather?limit=300\" | jq '.fetched'
```

**Solutions**:
```bash
# Add missing cities to geolocations.json
{
  \"Your City\": {
    \"latitude\": 40.7128,
    \"longitude\": -74.0060
  }
}

# Restart to reload configuration
docker-compose restart
```

## Log Analysis

### Enable Debug Logging
```bash
# Enable debug mode
WS_DEBUG=true
WS_LOG_LEVEL=DEBUG
docker-compose restart

# View detailed logs
docker-compose logs -f weatherstation
```

### Common Log Patterns

**Successful API Call**:
```
INFO: 192.168.1.100:54321 - \"GET /api/data/weather?limit=10 HTTP/1.1\" 200 OK
DEBUG: Fetching live data for 10 cities
DEBUG: Successfully fetched 10/10 cities in 0.45s
```

**API Error**:
```
ERROR: Error getting weather data after 2.34s: Connection timeout
WARNING: API not accessible: Connection timeout
```

**Configuration Error**:
```
ERROR: Invalid configuration. Exiting.
ERROR: WS_PORT must be a valid integer
```

### Log Locations

| Log Type | Location |
|----------|----------|
| Application | `docker-compose logs weatherstation` |
| Open-Meteo | `docker-compose logs openmeteo` |
| System (Linux) | `sudo journalctl -u weatherstation` |
| Nginx | `/var/log/nginx/access.log` |
| Docker | `docker logs <container-id>` |

## Recovery Procedures

### Complete Reset

If all else fails, perform a complete reset:

```bash
# Stop all services
docker-compose down -v

# Remove all data
docker volume prune -f
sudo rm -rf data/

# Remove Docker images
docker rmi $(docker images 'v2weatherstation*' -q)

# Fresh installation
git pull
docker-compose build --no-cache
docker-compose up -d

# Re-initialize data
./init-weather-data.sh
```

### Backup and Restore

**Create Backup**:
```bash
# Create backup directory
mkdir -p backups/$(date +%Y%m%d)

# Backup configuration
cp .env backups/$(date +%Y%m%d)/
cp docker-compose.yml backups/$(date +%Y%m%d)/

# Backup Docker volumes
docker run --rm -v openmeteo-api:/data -v $(pwd)/backups/$(date +%Y%m%d):/backup alpine tar czf /backup/openmeteo-data.tar.gz -C /data .
```

**Restore from Backup**:
```bash
# Stop services
docker-compose down

# Restore configuration
cp backups/20231201/.env .
cp backups/20231201/docker-compose.yml .

# Restore data
docker volume create openmeteo-api
docker run --rm -v openmeteo-api:/data -v $(pwd)/backups/20231201:/backup alpine tar xzf /backup/openmeteo-data.tar.gz -C /data

# Start services
docker-compose up -d
```

## Getting Help

### Self-Service Resources
1. **Check this troubleshooting guide** thoroughly
2. **Search documentation**: [docs/](../main.md)
3. **Review FAQ**: [FAQ](faq.md)
4. **Check GitHub issues**: [Issues](https://github.com/RA86-dev/v2weatherstation/issues)

### Community Support
1. **GitHub Discussions**: [Discussions](https://github.com/RA86-dev/v2weatherstation/discussions)
2. **Discord Server**: Join our community chat
3. **Stack Overflow**: Tag questions with `weather-station-v2`

### Professional Support
1. **Enterprise Support**: Available for business users
2. **Custom Development**: Feature development services
3. **Consulting**: Architecture and optimization consulting

### Reporting Issues

When reporting issues, include:

1. **System Information**:
   ```bash
   uname -a
   docker --version
   docker-compose --version
   ```

2. **Configuration**:
   ```bash
   grep -v API_KEY .env  # Remove sensitive data
   ```

3. **Logs**:
   ```bash
   docker-compose logs --tail=50 weatherstation
   ```

4. **Steps to Reproduce**:
   - What you did
   - What you expected
   - What actually happened

5. **Error Messages**:
   - Complete error messages
   - Screenshots if applicable

---

**Remember**: Most issues can be resolved by checking logs, verifying configuration, and restarting services. Don't hesitate to reach out if you need help! 🛠️