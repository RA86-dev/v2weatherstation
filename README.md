# Weather Station v2.0 - Self-Hosted Live Data Edition

![Weather Station](https://img.shields.io/badge/Weather-Station-blue?style=for-the-badge)
![Python](https://img.shields.io/badge/Python-3.11+-green?style=for-the-badge&logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-red?style=for-the-badge&logo=fastapi)
![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)

A modern, self-hosted weather data visualization platform with real-time data fetching from Open-Meteo API. Designed for schools and organizations to provide unified weather information access.

## 🌟 Features

### ✨ New in v2.0
- **🔴 Live Data Fetching**: Real-time weather data from self-hosted Open-Meteo API
- **🚀 Instant Startup**: No more 4+ minute initial data downloads
- **🌍 240+ Locations**: All US cities available immediately
- **📊 Multiple Data Sources**: Historical, current, and forecast data
- **🐳 Dockerized**: One-command deployment with Docker Compose
- **⚡ Fast Response**: Sub-second data retrieval
- **🔧 Configurable**: Environment-based configuration

### 🎯 Core Features
- Beautiful, responsive web interface
- Interactive weather maps and charts
- Weather statistics and comparisons
- Multiple visualization modes
- RESTful API for data access
- Health monitoring and status endpoints
- CORS support for web applications

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/RA86-dev/v2weatherstation.git
   cd v2weatherstation/WeatherStation/weather_station
   ```

2. **Start the services**:
   ```bash
   ./start.sh
   ```
   The script will:
   - Start Open-Meteo API server (port 8080)
   - Start Weather Station app (port 8110)
   - Optionally download weather data for better performance

3. **Access the application**:
   - 🌐 Weather Station: http://localhost:8110
   - 🔧 Open-Meteo API: http://localhost:8080

**Note**: Initial weather data download improves performance but isn't required. The API works with on-demand requests.

### Option 2: Manual Setup

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment** (optional):
   ```bash
   export LIVE_DATA_ENABLED=true
   export USE_SELF_HOSTED=true
   export OPEN_METEO_API_URL=http://localhost:8080
   ```

3. **Run the application**:
   ```bash
   python index.py
   ```

## 🏗️ Architecture

### Live Data Architecture
```
User Request → Weather Station → Self-Hosted Open-Meteo → Live Weather Data
     ↓              ↓                       ↓                    ↓
Web Interface → FastAPI Server → Open-Meteo API → Real-time Response
```

### Previous Architecture (v1.x)
```
Scheduled Update → Download All Data → Store in Files → Serve from Cache
       ↓                 ↓                  ↓              ↓
   Every 7 days     240+ API calls     output_data.json  Static data
```

## 📡 API Endpoints

### Core Data Endpoints
- `GET /api/data/weather?limit=50` - Get live weather data for multiple cities
- `GET /api/data/live/{city}` - Get live weather data for specific city
- `GET /api/data/current/{city}` - Get current conditions for specific city
- `GET /api/data/locations` - Get all available locations

### Status & Health
- `GET /health` - Application health check
- `GET /api/status` - API and Open-Meteo status
- `GET /api/data/status` - Data manager status
- `GET /config` - Public configuration

### Web Pages
- `GET /` - Main dashboard
- `GET /comparison` - Weather comparison tool
- `GET /intmap` - Interactive pressure map
- `GET /weatherstat` - Weather statistics

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WEATHER_STATION_HOST` | `0.0.0.0` | Server host |
| `WEATHER_STATION_PORT` | `8110` | Server port |
| `OPEN_METEO_API_URL` | `http://localhost:8080` | Open-Meteo API URL |
| `USE_SELF_HOSTED` | `true` | Use self-hosted Open-Meteo |
| `LIVE_DATA_ENABLED` | `true` | Enable live data fetching |
| `DEBUG` | `false` | Debug mode |

### Configuration File

The system uses `config.py` for centralized configuration management:

```python
from config import get_config

config = get_config()
print(f"API URL: {config.effective_open_meteo_url}")
print(f"Live data: {config.LIVE_DATA_ENABLED}")
```

## 🌍 Available Locations

The system supports **240+ US cities** including:

- **Major Cities**: New York, Los Angeles, Chicago, Houston, Philadelphia
- **State Capitals**: Austin, Sacramento, Atlanta, Denver, Boston
- **Regional Centers**: Seattle, Miami, Las Vegas, Portland, Nashville
- **And many more...**

Full list available via `/api/data/locations` endpoint.

## 🐳 Docker Configuration

### Services

1. **open-meteo**: Self-hosted Open-Meteo API server
   - Port: 8080
   - Health checks enabled
   - Data persistence

2. **weather-station**: Main application server
   - Port: 8110
   - Depends on open-meteo service
   - Auto-restart enabled

### Docker Compose Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up --build -d

# View service status
docker-compose ps
```

## 🔍 Monitoring & Debugging

### Health Checks

```bash
# Application health
curl http://localhost:8110/health

# API status
curl http://localhost:8110/api/status

# Open-Meteo health (direct)
curl http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0
```

### Log Monitoring

```bash
# Follow all logs
docker-compose logs -f

# Weather station logs only
docker-compose logs -f weather-station

# Open-Meteo logs only
docker-compose logs -f open-meteo
```

## 🛠️ Development

### Local Development Setup

1. **Clone and install**:
   ```bash
   git clone https://github.com/RA86-dev/v2weatherstation.git
   cd v2weatherstation/WeatherStation/weather_station
   pip install -r requirements.txt
   ```

2. **Run in development mode**:
   ```bash
   export DEBUG=true
   python index.py
   ```

3. **Access development server**:
   - Auto-reload enabled
   - Debug logging active
   - Access logs available at `/logs`

### Code Structure

```
weather_station/
├── index.py              # FastAPI application & routes
├── config.py             # Configuration management
├── data_manager.py       # Legacy file-based data manager
├── live_data_manager.py  # New live data fetching
├── docker-compose.yml    # Docker services
├── Dockerfile           # Application container
├── requirements.txt     # Python dependencies
├── start.sh            # Quick start script
├── assets/             # Static files & HTML
└── updaters/           # Location data
    └── geolocations.json  # 240+ US cities
```

## 📊 Performance

### Response Times
- **Live data request**: ~100-500ms per city
- **Batch requests (50 cities)**: ~30-60 seconds
- **Current conditions**: ~100-200ms
- **Location list**: ~1-5ms (cached)

### Rate Limiting
- 1 request per second to Open-Meteo API
- 5-minute caching for location data
- Built-in timeout handling (5s per request)

## 🔄 Migration from v1.x

### What Changed
- ✅ **No more pre-downloading**: Data fetched on-demand
- ✅ **All locations available**: No 49-location limit
- ✅ **Faster startup**: Instant application start
- ✅ **Real-time data**: Always fresh weather information
- ✅ **Better error handling**: Graceful API failure handling

### Backward Compatibility
- All original web pages still work
- Original `/api/data/weather` endpoint maintained
- File-based mode still available (set `LIVE_DATA_ENABLED=false`)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Open-Meteo](https://open-meteo.com/) for providing excellent weather data API
- [FastAPI](https://fastapi.tiangolo.com/) for the modern web framework
- [Docker](https://docker.com/) for containerization support

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/RA86-dev/v2weatherstation/issues)
- 📚 **Documentation**: This README and inline code comments
- 💬 **Discussions**: GitHub Discussions

---

**Made with ❤️ by RA86-dev**  
*Providing unified weather information for educational institutions*