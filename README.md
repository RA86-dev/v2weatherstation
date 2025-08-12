# Weather Station v2.0 - SELF-HOSTED

A completely self-hosted weather data visualization platform with local Open-Meteo API.
**NO external dependencies or API calls** - everything runs locally!

## ⚡ Quick Install

**One-line installation:**
```bash
curl -sSL https://raw.githubusercontent.com/RA86-dev/v2weatherstation/main/install.sh | bash
```

**Or manual:**
```bash
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation/WeatherStation/weather_station
./start.sh
```

## 📋 Requirements

- Docker (running)
- Git

That's it!

## 🌐 Access

After installation, wait 2-3 minutes for Open-Meteo to initialize, then open:
- **Weather Station**: http://localhost:8110
- **Self-hosted Open-Meteo API**: http://localhost:8080
- **API Status**: http://localhost:8110/api/status
- **Weather Data**: http://localhost:8110/api/data/weather

## 🛠️ Management

```bash
# View logs
docker-compose logs -f

# Stop the service
docker-compose down

# Restart
docker-compose restart

# Update to latest version
git pull && docker-compose up --build -d
```

## 📊 API Endpoints

- `GET /health` - Health check
- `GET /api/status` - API status
- `GET /api/data/weather?limit=50` - Weather data for multiple cities
- `GET /api/data/live/{city}` - Live data for specific city
- `GET /api/data/locations` - All available locations

## 🏙️ Available Cities

240+ US cities including:
- New York, Los Angeles, Chicago, Houston
- All state capitals
- Major metropolitan areas

## ⚙️ Configuration

The system is configured for self-hosting only in `docker-compose.yml`:

```yaml
environment:
  - OPEN_METEO_API_URL=http://open-meteo:8080  # Internal container network
  - DEBUG=false
```

**Note**: The system ONLY works with the self-hosted Open-Meteo container.

## 🐛 Troubleshooting

**Service not starting?**
```bash
docker-compose logs
```

**Data not loading?**
```bash
# Check if Open-Meteo is ready
curl http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0

# Check weather station status
curl http://localhost:8110/api/status
```

**Port conflicts?**
```bash
# Change port in docker-compose.yml
ports:
  - "8111:8110"  # Use port 8111 instead
```

## 📄 License

MIT License

---

**Made with ❤️ for SELF-HOSTED weather monitoring**  
**100% local - NO external API dependencies!**