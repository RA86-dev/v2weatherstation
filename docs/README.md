# Weather Station v2.0 Documentation

![Weather Station](https://img.shields.io/badge/Weather-Station-blue?style=for-the-badge)
![Python](https://img.shields.io/badge/Python-3.11+-green?style=for-the-badge&logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-red?style=for-the-badge&logo=fastapi)
![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)

A modern, self-hosted weather data visualization platform with real-time data fetching from Open-Meteo API. Designed for schools and organizations to provide unified weather information access.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Usage Examples](#usage-examples)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Features

### ✨ Core Features
- **🔴 Live Data Fetching**: Real-time weather data from self-hosted Open-Meteo API
- **🚀 Instant Startup**: No more 4+ minute initial data downloads
- **🌍 240+ Locations**: All US cities available immediately
- **📊 Multiple Data Sources**: Historical, current, and forecast data
- **🐳 Dockerized**: One-command deployment with Docker Compose
- **⚡ Fast Response**: Sub-second data retrieval
- **🔧 Configurable**: Environment-based configuration

### 🎯 Web Interface Features
- Beautiful, responsive web interface
- Interactive weather maps and charts
- Weather statistics and comparisons
- Multiple visualization modes
- Real-time data updates
- Mobile-friendly design

### 🔌 API Features
- RESTful API for data access
- Health monitoring and status endpoints
- CORS support for web applications
- Authentication for administrative operations
- JSON responses with comprehensive metadata

## Architecture

```
Weather Station v2.0
├── FastAPI Backend (main.py)
│   ├── Weather Station Core (WeatherStation/)
│   │   ├── Configuration Management (config.py)
│   │   ├── Data Manager (data_manager.py)
│   │   ├── Live Data Manager (live_data_manager.py)
│   │   └── Web Server (index.py)
│   └── Assets & Frontend (assets/)
├── Docker Support
│   ├── Dockerfile
│   └── Docker Compose
└── Installation Scripts
    ├── install-weatherstation.sh
    └── init-weather-data.sh
```

### Key Components

1. **FastAPI Application**: High-performance async web framework
2. **Data Managers**: Handle both live API data and cached file data
3. **Configuration System**: Environment-based configuration with validation
4. **Web Interface**: Responsive HTML/CSS/JS frontend
5. **API Layer**: RESTful endpoints for data access

## Installation

### Quick Start with Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/RA86-dev/v2weatherstation
cd v2weatherstation

# Build and run with Docker
docker build -t v2weatherstation:latest .
docker run -p 8110:8110 v2weatherstation:latest
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/RA86-dev/v2weatherstation
cd v2weatherstation

# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py
```

### Global Installation Script

Use our enhanced installation script for system-wide installation:

```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/RA86-dev/v2weatherstation/main/install-global.sh | bash

# Or manually download and run
wget https://raw.githubusercontent.com/RA86-dev/v2weatherstation/main/install-global.sh
chmod +x install-global.sh
./install-global.sh
```

## Configuration

### Environment Variables

The application supports configuration through environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `WS_HOST` | `0.0.0.0` | Server host address |
| `WS_PORT` | `8110` | Server port |
| `WS_DEBUG` | `False` | Enable debug mode |
| `WS_LIVE_DATA_ENABLED` | `True` | Enable live data fetching |
| `WS_USE_SELF_HOSTED` | `True` | Use self-hosted Open-Meteo API |
| `WS_OPEN_METEO_URL` | `http://localhost:8080/v1` | Open-Meteo API URL |
| `WS_API_KEY` | Auto-generated | API key for admin operations |
| `WS_LOG_LEVEL` | `INFO` | Logging level |
| `WS_CORS_ORIGINS` | `["*"]` | Allowed CORS origins |

### Configuration File

Create a `.env` file in the project root:

```env
WS_HOST=0.0.0.0
WS_PORT=8110
WS_DEBUG=False
WS_LIVE_DATA_ENABLED=True
WS_USE_SELF_HOSTED=True
WS_OPEN_METEO_URL=http://localhost:8080/v1
WS_LOG_LEVEL=INFO
```

## API Documentation

### Health & Status Endpoints

#### GET /health
Health check endpoint
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "timestamp": "2025-01-01T00:00:00Z",
  "data_status": {...}
}
```

#### GET /api/status
Comprehensive API status
```json
{
  "api_status": {...},
  "data_manager_status": {...},
  "live_data_enabled": true,
  "self_hosted": true,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

### Weather Data Endpoints

#### GET /api/data/weather?limit=300
Get weather data for multiple locations
- **Parameters**: `limit` (1-300, default: 300)
- **Returns**: Weather data for requested number of locations

#### GET /api/data/live/{city}
Get live weather data for specific city
- **Parameters**: `city` (string)
- **Returns**: Real-time weather data for the city

#### GET /api/data/current/{city}
Get current conditions for specific city
- **Parameters**: `city` (string)
- **Returns**: Current weather conditions

#### GET /api/data/locations
Get list of available locations
```json
{
  "locations": ["New York", "Los Angeles", ...],
  "coordinates": {...},
  "total": 240,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

### Administrative Endpoints

#### POST /api/data/force-update
Manually trigger data update (requires API key)
- **Headers**: `X-API-Key: your-api-key`
- **Returns**: Update status

#### GET /admin/api-key (Debug mode only)
Get API key for administrative operations

#### GET /logs?limit=100 (Debug mode only)
Get recent access logs

### Web Interface Endpoints

- **GET /**: Main dashboard
- **GET /comparison**: Weather comparison page
- **GET /intmap**: Interactive pressure map
- **GET /weatherstat**: Weather statistics
- **GET /license**: License information

## Usage Examples

### Fetching Weather Data

```bash
# Get weather data for all locations
curl http://localhost:8110/api/data/weather

# Get weather data for specific number of cities
curl "http://localhost:8110/api/data/weather?limit=50"

# Get live data for New York
curl http://localhost:8110/api/data/live/New%20York

# Get current conditions for Los Angeles
curl http://localhost:8110/api/data/current/Los%20Angeles
```

### Administrative Operations

```bash
# Get API key (debug mode only)
curl http://localhost:8110/admin/api-key

# Force data update
curl -X POST http://localhost:8110/api/data/force-update \
  -H "X-API-Key: your-api-key-here"

# Check API status
curl http://localhost:8110/api/status
```

### Web Interface

- **Dashboard**: http://localhost:8110/
- **Weather Comparison**: http://localhost:8110/comparison
- **Interactive Map**: http://localhost:8110/intmap
- **Statistics**: http://localhost:8110/weatherstat

## Development

### Project Structure

```
v2weatherstation/
├── main.py                 # Application entry point
├── WeatherStation/         # Core application
│   └── weather_station/
│       ├── index.py        # FastAPI application
│       ├── config.py       # Configuration management
│       ├── data_manager.py # File-based data handling
│       ├── live_data_manager.py # Live API data handling
│       └── assets/         # Static web assets
├── docs/                   # Documentation
├── testing/               # Test files
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
└── install-*.sh          # Installation scripts
```

### Running in Development Mode

```bash
# Install development dependencies
pip install -r requirements.txt

# Run with debug mode
export WS_DEBUG=True
python main.py

# Or use uvicorn directly
uvicorn WeatherStation.weather_station.index:app --reload --host 0.0.0.0 --port 8110
```

### Adding New Features

1. **Study existing patterns** in the codebase
2. **Write tests first** when possible
3. **Follow the configuration system** for new settings
4. **Use the existing data managers** for data access
5. **Maintain API consistency** with existing endpoints

### Code Quality

- Follow PEP 8 style guidelines
- Use type hints where appropriate
- Write descriptive commit messages
- Test your changes thoroughly
- Update documentation for new features

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using port 8110
lsof -i :8110

# Kill the process
kill -9 <PID>
```

#### API Not Accessible
1. Check if Open-Meteo API is running
2. Verify `WS_OPEN_METEO_URL` configuration
3. Check network connectivity
4. Review application logs

#### Data Not Loading
1. Check `WS_LIVE_DATA_ENABLED` setting
2. Verify API key for manual updates
3. Check file permissions for data directory
4. Review data manager logs

#### Docker Issues
```bash
# Rebuild the container
docker build --no-cache -t v2weatherstation:latest .

# Check container logs
docker logs <container-id>

# Access container shell
docker exec -it <container-id> /bin/bash
```

### Debug Mode

Enable debug mode for detailed logging:

```bash
export WS_DEBUG=True
python main.py
```

Debug mode provides:
- Detailed request/response logging
- API key display
- Access log endpoint
- Enhanced error messages

### Log Files

Application logs are written to stdout. In production, redirect to files:

```bash
python main.py > weatherstation.log 2>&1
```

## Contributing

### Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

### Development Guidelines

- Follow the existing code style
- Write tests for new features
- Update documentation
- Use descriptive commit messages
- Keep changes focused and atomic

### Reporting Issues

When reporting issues, include:
- Weather Station version
- Operating system
- Python version
- Error messages
- Steps to reproduce
- Expected vs actual behavior

## License

This project is licensed under the terms specified in the LICENSE file.

## Support

For support and questions:
- Check the [troubleshooting section](#troubleshooting)
- Review existing GitHub issues
- Create a new issue with detailed information

---

**Weather Station v2.0** - Modern weather data visualization for everyone.