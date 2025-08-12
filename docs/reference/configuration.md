# Configuration Reference

Complete reference for all Weather Station v2.0 configuration options, environment variables, and settings.

## Overview

Weather Station v2.0 uses environment-based configuration with sensible defaults. Configuration can be provided through:

1. **Environment variables** (highest priority)
2. **`.env` files** (medium priority)
3. **Default values** (lowest priority)

## Configuration Files

### Primary Configuration
- **`.env`** - Main environment file (development)
- **`/etc/weatherstation/config.env`** - System-wide configuration (production)
- **`docker-compose.yml`** - Docker environment variables

### Application Configuration
Configuration is handled by the `config.py` module with automatic validation and type conversion.

## Core Settings

### Server Configuration

#### WS_HOST
- **Type**: String
- **Default**: `0.0.0.0`
- **Description**: Host address to bind the server
- **Examples**:
  ```env
  WS_HOST=0.0.0.0          # Listen on all interfaces
  WS_HOST=127.0.0.1        # Localhost only
  WS_HOST=192.168.1.100    # Specific IP address
  ```

#### WS_PORT
- **Type**: Integer
- **Default**: `8110`
- **Range**: `1024-65535`
- **Description**: Port number for the web server
- **Examples**:
  ```env
  WS_PORT=8110             # Default port
  WS_PORT=8080             # Alternative port
  WS_PORT=443              # HTTPS port (requires root)
  ```

#### WS_DEBUG
- **Type**: Boolean
- **Default**: `false`
- **Description**: Enable debug mode with enhanced logging
- **Examples**:
  ```env
  WS_DEBUG=true             # Enable debug mode
  WS_DEBUG=false            # Production mode
  ```
- **Debug mode features**:
  - Detailed request/response logging
  - API key display endpoints
  - Enhanced error messages
  - Auto-reload on code changes
  - Access log endpoints

## Application Settings

### APP_NAME
- **Type**: String
- **Default**: `\"Weather Station v2.0\"`
- **Description**: Application name displayed in interface
- **Examples**:
  ```env
  APP_NAME=\"My Weather Station\"
  APP_NAME=\"School Weather Monitor\"
  ```

### APP_VERSION
- **Type**: String
- **Default**: `\"2.0.0\"`
- **Description**: Application version (auto-detected from code)
- **Note**: Usually set automatically, manual override not recommended

### APP_DESCRIPTION
- **Type**: String
- **Default**: `\"Modern weather data visualization platform\"`
- **Description**: Application description for API documentation

## Data Source Configuration

### WS_LIVE_DATA_ENABLED
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable live weather data fetching
- **Examples**:
  ```env
  WS_LIVE_DATA_ENABLED=true    # Use live API data
  WS_LIVE_DATA_ENABLED=false   # Use cached/mock data
  ```

### WS_USE_SELF_HOSTED
- **Type**: Boolean
- **Default**: `true`
- **Description**: Use self-hosted Open-Meteo API
- **Examples**:
  ```env
  WS_USE_SELF_HOSTED=true      # Use local Open-Meteo
  WS_USE_SELF_HOSTED=false     # Use public API
  ```

### WS_OPEN_METEO_URL
- **Type**: URL
- **Default**: `http://localhost:8080/v1` (self-hosted) or `https://api.open-meteo.com/v1` (public)
- **Description**: Open-Meteo API base URL
- **Examples**:
  ```env
  # Self-hosted (Docker)
  WS_OPEN_METEO_URL=http://openmeteo:8080/v1
  
  # Self-hosted (external)
  WS_OPEN_METEO_URL=http://weather-api.company.com:8080/v1
  
  # Public API
  WS_OPEN_METEO_URL=https://api.open-meteo.com/v1
  ```

### WS_DATA_UPDATE_INTERVAL
- **Type**: Integer (seconds)
- **Default**: `3600` (1 hour)
- **Description**: Automatic data update interval
- **Examples**:
  ```env
  WS_DATA_UPDATE_INTERVAL=1800    # 30 minutes
  WS_DATA_UPDATE_INTERVAL=3600    # 1 hour (default)
  WS_DATA_UPDATE_INTERVAL=7200    # 2 hours
  ```

### WS_CACHE_TTL
- **Type**: Integer (seconds)
- **Default**: `900` (15 minutes)
- **Description**: Cache time-to-live for weather data
- **Examples**:
  ```env
  WS_CACHE_TTL=300             # 5 minutes (frequent updates)
  WS_CACHE_TTL=900             # 15 minutes (default)
  WS_CACHE_TTL=1800            # 30 minutes (slower updates)
  ```

## Security Configuration

### WS_API_KEY
- **Type**: String (32+ characters)
- **Default**: Auto-generated
- **Description**: API key for administrative operations
- **Examples**:
  ```env
  WS_API_KEY=your-32-character-api-key-here
  ```
- **Generation**:
  ```bash
  # Generate secure API key
  openssl rand -hex 32
  
  # Or use Python
  python3 -c \"import secrets; print(secrets.token_hex(32))\"
  ```

### WS_CORS_ORIGINS
- **Type**: JSON Array
- **Default**: `[\"*\"]`
- **Description**: Allowed CORS origins for web applications
- **Examples**:
  ```env
  # Allow all origins (development only)
  WS_CORS_ORIGINS=[\"*\"]
  
  # Specific domains (production)
  WS_CORS_ORIGINS=[\"https://yourdomain.com\", \"https://app.yourdomain.com\"]
  
  # Local development
  WS_CORS_ORIGINS=[\"http://localhost:3000\", \"http://127.0.0.1:3000\"]
  ```

### WS_ALLOWED_HOSTS
- **Type**: JSON Array
- **Default**: `[\"*\"]`
- **Description**: Allowed host headers
- **Examples**:
  ```env
  WS_ALLOWED_HOSTS=[\"weather.yourdomain.com\", \"localhost\"]
  ```

## Logging Configuration

### WS_LOG_LEVEL
- **Type**: String
- **Default**: `INFO`
- **Options**: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`
- **Description**: Minimum logging level
- **Examples**:
  ```env
  WS_LOG_LEVEL=DEBUG           # Verbose logging
  WS_LOG_LEVEL=INFO            # Standard logging
  WS_LOG_LEVEL=WARNING         # Minimal logging
  ```

### WS_LOG_FORMAT
- **Type**: String
- **Default**: `\"%(asctime)s - %(name)s - %(levelname)s - %(message)s\"`
- **Description**: Python logging format string
- **Examples**:
  ```env
  # Default format
  WS_LOG_FORMAT=\"%(asctime)s - %(name)s - %(levelname)s - %(message)s\"
  
  # Simple format
  WS_LOG_FORMAT=\"%(levelname)s: %(message)s\"
  
  # JSON format (for log aggregation)
  WS_LOG_FORMAT='{\"time\":\"%(asctime)s\",\"level\":\"%(levelname)s\",\"msg\":\"%(message)s\"}'
  ```

### WS_ACCESS_LOG
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable HTTP access logging
- **Examples**:
  ```env
  WS_ACCESS_LOG=true           # Enable access logs
  WS_ACCESS_LOG=false          # Disable access logs
  ```

## Directory Configuration

### WS_ASSETS_DIR
- **Type**: Path
- **Default**: `WeatherStation/weather_station/assets`
- **Description**: Directory containing static assets
- **Examples**:
  ```env
  WS_ASSETS_DIR=/opt/weatherstation/assets
  WS_ASSETS_DIR=./custom-assets
  ```

### WS_DATA_DIR
- **Type**: Path
- **Default**: `./data`
- **Description**: Directory for data storage
- **Examples**:
  ```env
  WS_DATA_DIR=/var/lib/weatherstation
  WS_DATA_DIR=./data
  ```

### WS_LOG_DIR
- **Type**: Path
- **Default**: `./logs`
- **Description**: Directory for log files
- **Examples**:
  ```env
  WS_LOG_DIR=/var/log/weatherstation
  WS_LOG_DIR=./logs
  ```

## Performance Configuration

### WS_WORKERS
- **Type**: Integer
- **Default**: `1`
- **Description**: Number of worker processes (Gunicorn only)
- **Examples**:
  ```env
  WS_WORKERS=1                 # Single worker
  WS_WORKERS=4                 # Multiple workers
  ```
- **Calculation**: `(2 × CPU cores) + 1`

### WS_MAX_CONNECTIONS
- **Type**: Integer
- **Default**: `1000`
- **Description**: Maximum concurrent connections
- **Examples**:
  ```env
  WS_MAX_CONNECTIONS=100       # Low traffic
  WS_MAX_CONNECTIONS=1000      # Medium traffic
  WS_MAX_CONNECTIONS=5000      # High traffic
  ```

### WS_TIMEOUT
- **Type**: Integer (seconds)
- **Default**: `30`
- **Description**: Request timeout
- **Examples**:
  ```env
  WS_TIMEOUT=10                # Fast timeout
  WS_TIMEOUT=30                # Default timeout
  WS_TIMEOUT=60                # Slow timeout
  ```

### WS_KEEPALIVE
- **Type**: Integer (seconds)
- **Default**: `2`
- **Description**: Keep-alive timeout
- **Examples**:
  ```env
  WS_KEEPALIVE=2               # Default
  WS_KEEPALIVE=5               # Longer keep-alive
  ```

## Rate Limiting

### WS_RATE_LIMIT_ENABLED
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable API rate limiting
- **Examples**:
  ```env
  WS_RATE_LIMIT_ENABLED=true   # Enable rate limiting
  WS_RATE_LIMIT_ENABLED=false  # Disable rate limiting
  ```

### WS_RATE_LIMIT_PUBLIC
- **Type**: String
- **Default**: `\"100/minute\"`
- **Description**: Rate limit for public endpoints
- **Examples**:
  ```env
  WS_RATE_LIMIT_PUBLIC=\"100/minute\"      # 100 requests per minute
  WS_RATE_LIMIT_PUBLIC=\"1000/hour\"       # 1000 requests per hour
  WS_RATE_LIMIT_PUBLIC=\"10/second\"       # 10 requests per second
  ```

### WS_RATE_LIMIT_AUTHENTICATED
- **Type**: String
- **Default**: `\"1000/minute\"`
- **Description**: Rate limit for authenticated endpoints
- **Examples**:
  ```env
  WS_RATE_LIMIT_AUTHENTICATED=\"1000/minute\"
  WS_RATE_LIMIT_AUTHENTICATED=\"10000/hour\"
  ```

## Database Configuration (Future)

### WS_DATABASE_URL
- **Type**: URL
- **Default**: None (file-based storage)
- **Description**: Database connection URL (planned feature)
- **Examples**:
  ```env
  # PostgreSQL
  WS_DATABASE_URL=postgresql://user:pass@localhost/weatherstation
  
  # SQLite
  WS_DATABASE_URL=sqlite:///./weatherstation.db
  
  # MySQL
  WS_DATABASE_URL=mysql://user:pass@localhost/weatherstation
  ```

## Monitoring Configuration

### WS_METRICS_ENABLED
- **Type**: Boolean
- **Default**: `false`
- **Description**: Enable Prometheus metrics (planned feature)
- **Examples**:
  ```env
  WS_METRICS_ENABLED=true      # Enable metrics
  WS_METRICS_ENABLED=false     # Disable metrics
  ```

### WS_HEALTH_CHECK_INTERVAL
- **Type**: Integer (seconds)
- **Default**: `60`
- **Description**: Health check interval
- **Examples**:
  ```env
  WS_HEALTH_CHECK_INTERVAL=30  # Check every 30 seconds
  WS_HEALTH_CHECK_INTERVAL=60  # Check every minute
  ```

## Example Configurations

### Development Configuration
```env
# Development settings
WS_DEBUG=true
WS_LOG_LEVEL=DEBUG
WS_HOST=127.0.0.1
WS_PORT=8110

# Data source
WS_LIVE_DATA_ENABLED=false
WS_USE_SELF_HOSTED=false
WS_OPEN_METEO_URL=https://api.open-meteo.com/v1

# Security (relaxed for development)
WS_CORS_ORIGINS=[\"*\"]
WS_RATE_LIMIT_ENABLED=false

# Caching (short TTL for testing)
WS_CACHE_TTL=300
```

### Production Configuration
```env
# Production settings
WS_DEBUG=false
WS_LOG_LEVEL=INFO
WS_HOST=0.0.0.0
WS_PORT=8110

# Data source
WS_LIVE_DATA_ENABLED=true
WS_USE_SELF_HOSTED=true
WS_OPEN_METEO_URL=http://openmeteo:8080/v1

# Security
WS_API_KEY=your-secure-32-character-api-key-here
WS_CORS_ORIGINS=[\"https://weather.yourdomain.com\"]
WS_ALLOWED_HOSTS=[\"weather.yourdomain.com\"]

# Performance
WS_WORKERS=4
WS_MAX_CONNECTIONS=1000
WS_CACHE_TTL=900

# Rate limiting
WS_RATE_LIMIT_ENABLED=true
WS_RATE_LIMIT_PUBLIC=\"100/minute\"
WS_RATE_LIMIT_AUTHENTICATED=\"1000/minute\"

# Directories
WS_DATA_DIR=/var/lib/weatherstation
WS_LOG_DIR=/var/log/weatherstation
```

### Docker Configuration
```yaml
# docker-compose.yml
version: '3.8'

services:
  weatherstation:
    build: .
    ports:
      - \"8110:8110\"
    environment:
      - WS_HOST=0.0.0.0
      - WS_PORT=8110
      - WS_DEBUG=false
      - WS_LIVE_DATA_ENABLED=true
      - WS_USE_SELF_HOSTED=true
      - WS_OPEN_METEO_URL=http://openmeteo:8080/v1
      - WS_LOG_LEVEL=INFO
    env_file:
      - .env
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    depends_on:
      - openmeteo
    restart: unless-stopped

  openmeteo:
    image: ghcr.io/open-meteo/open-meteo:latest
    ports:
      - \"8080:8080\"
    volumes:
      - openmeteo-data:/app/data
    restart: unless-stopped

volumes:
  openmeteo-data:
```

### High Availability Configuration
```env
# High availability settings
WS_DEBUG=false
WS_LOG_LEVEL=WARNING
WS_WORKERS=8
WS_MAX_CONNECTIONS=5000
WS_TIMEOUT=60
WS_KEEPALIVE=5

# Aggressive caching
WS_CACHE_TTL=1800

# Rate limiting
WS_RATE_LIMIT_PUBLIC=\"500/minute\"
WS_RATE_LIMIT_AUTHENTICATED=\"5000/minute\"

# Monitoring
WS_METRICS_ENABLED=true
WS_HEALTH_CHECK_INTERVAL=30

# Database (when available)
WS_DATABASE_URL=postgresql://weather:password@db-cluster/weatherstation
```

## Configuration Validation

Weather Station automatically validates configuration on startup:

### Validation Rules
- **Required fields**: Must be present and non-empty
- **Type checking**: Values must match expected types
- **Range validation**: Numeric values within acceptable ranges
- **URL validation**: URLs must be properly formatted
- **JSON validation**: JSON arrays must be valid syntax

### Validation Errors
Common validation errors and solutions:

```bash
# Invalid port number
ERROR: WS_PORT must be between 1024 and 65535
# Solution: Use valid port number

# Invalid boolean value
ERROR: WS_DEBUG must be 'true' or 'false'
# Solution: Use lowercase boolean values

# Invalid JSON array
ERROR: WS_CORS_ORIGINS must be valid JSON array
# Solution: Use proper JSON syntax: [\"value1\", \"value2\"]

# Invalid URL
ERROR: WS_OPEN_METEO_URL must be a valid URL
# Solution: Include protocol: http://localhost:8080/v1
```

### Manual Validation
```bash
# Test configuration
python3 -c \"from WeatherStation.weather_station.config import get_config; print('Configuration valid:', get_config().validate())\"

# Show current configuration
python3 -c \"from WeatherStation.weather_station.config import get_config; import json; print(json.dumps(get_config().to_dict(), indent=2))\"
```

## Environment Variable Priority

Configuration values are resolved in this order (highest to lowest priority):

1. **Environment variables** (e.g., `export WS_DEBUG=true`)
2. **Docker environment** (docker-compose.yml environment section)
3. **`.env` file** (in current directory)
4. **System config** (`/etc/weatherstation/config.env`)
5. **Default values** (hardcoded in application)

### Example Priority Resolution
```bash
# Environment variable (highest priority)
export WS_PORT=8111

# Docker environment (medium-high priority)
# docker-compose.yml:
# environment:
#   - WS_PORT=8112

# .env file (medium priority)
# WS_PORT=8113

# Default value (lowest priority)
# WS_PORT=8110

# Result: WS_PORT=8111 (from environment variable)
```

## Configuration Best Practices

### Security
1. **Use strong API keys** (32+ characters, random)
2. **Restrict CORS origins** in production
3. **Enable rate limiting** for public deployments
4. **Use HTTPS** for public access
5. **Protect configuration files** (appropriate permissions)

### Performance
1. **Tune worker count** based on CPU cores
2. **Optimize cache TTL** for your use case
3. **Monitor resource usage** and adjust limits
4. **Use appropriate timeout values**
5. **Enable compression** in reverse proxy

### Reliability
1. **Use persistent storage** for data directory
2. **Configure proper logging** for debugging
3. **Set up health checks** and monitoring
4. **Use restart policies** in Docker
5. **Backup configuration** regularly

### Development
1. **Use debug mode** for development
2. **Disable rate limiting** for testing
3. **Use short cache TTL** for rapid iteration
4. **Enable verbose logging** for troubleshooting
5. **Use local APIs** when possible

## Troubleshooting Configuration

### Common Issues

#### Configuration Not Loading
```bash
# Check file permissions
ls -la .env

# Verify file encoding
file .env

# Check for syntax errors
cat .env | grep \"=\"
```

#### Environment Variables Not Working
```bash
# Verify environment variables are set
env | grep WS_

# Check variable precedence
echo $WS_PORT

# Test in Python
python3 -c \"import os; print(os.getenv('WS_PORT'))\"
```

#### Docker Environment Issues
```bash
# Check Docker environment
docker-compose config

# Verify container environment
docker exec weatherstation-app env | grep WS_
```

### Debug Configuration
```bash
# Enable configuration debugging
WS_DEBUG=true python3 -c \"from WeatherStation.weather_station.config import get_config; get_config()\"

# Show configuration source
WS_DEBUG=true WS_LOG_LEVEL=DEBUG python3 main.py
```

## Related Documentation

- [Installation Guide](../install/installation.md) - Setting up configuration during installation
- [Docker Installation](../install/docker-install.md) - Docker-specific configuration
- [Troubleshooting](../support/troubleshooting.md) - Configuration troubleshooting
- [Security Guide](../administration/security.md) - Security configuration
- [Performance Guide](../support/performance.md) - Performance tuning

---

**Need help with configuration?** Check our [FAQ](../support/faq.md) or [troubleshooting guide](../support/troubleshooting.md). 🔧