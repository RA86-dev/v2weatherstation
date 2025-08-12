# Frequently Asked Questions (FAQ)

Common questions and answers about Weather Station v2.0.

## General Questions

### What is Weather Station v2.0?

Weather Station v2.0 is a modern, self-hosted weather data visualization platform that provides real-time weather information through a web interface and REST API. It's designed for schools, organizations, and weather enthusiasts who need reliable, accessible weather data.

### What's new in version 2.0?

- **Real-time data fetching** from self-hosted Open-Meteo API
- **Instant startup** (no more 4+ minute initial downloads)
- **240+ locations** available immediately
- **Docker-based deployment** for easy installation
- **Enhanced API** with comprehensive endpoints
- **Responsive web interface** optimized for all devices

### Is it free to use?

Yes, Weather Station v2.0 is open source and free to use. You can install it on your own infrastructure without any licensing fees.

### What are the system requirements?

**Minimum:**
- 2GB RAM
- 5GB storage
- Internet connection
- Docker 20.10.0+

**Recommended:**
- 4GB+ RAM
- 20GB+ SSD storage
- Broadband connection
- Linux server (Ubuntu 20.04+)

## Installation & Setup

### How do I install Weather Station v2.0?

The fastest way is using our global installation script:

```bash
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation
./install-global.sh
```

See our [Installation Guide](../install/installation.md) for detailed instructions.

### Can I install it without Docker?

Yes, you can install manually using Python. See the [Manual Installation](../install/installation.md#manual-installation) section for instructions.

### What ports does it use?

- **8110**: Weather Station web interface and API
- **8080**: Open-Meteo API (if using self-hosted)

### How do I change the default port?

Set the `WS_PORT` environment variable:

```bash
WS_PORT=8111 docker-compose up -d
```

Or edit your `.env` file:
```env
WS_PORT=8111
```

### Can I run multiple instances?

Yes, but each instance needs different ports:

```bash
# Instance 1
WS_PORT=8110 docker-compose up -d

# Instance 2
WS_PORT=8111 docker-compose -p weatherstation2 up -d
```

## Usage & Features

### How many locations are supported?

Weather Station v2.0 supports 240+ locations worldwide, primarily focused on major cities in the United States, with expanding international coverage.

### How often is weather data updated?

- **Live data**: Updates every 10-15 minutes
- **Forecast data**: Updates hourly
- **Historical data**: Processed daily

### Can I add custom locations?

Yes, edit the `geolocations.json` file:

```json
{
  "Your City": {
    "latitude": 40.7128,
    "longitude": -74.0060
  }
}
```

Then restart the service.

### How accurate is the weather data?

Data accuracy depends on the source:
- **Self-hosted Open-Meteo**: Uses multiple weather models (ECMWF, NOAA GFS, etc.)
- **Public APIs**: Varies by provider
- **Typical accuracy**: Temperature ±1-2°C, Pressure ±2-5 hPa

### Can I export weather data?

Yes, several ways:
- **API**: JSON format via REST endpoints
- **Web interface**: CSV/PDF export from comparison page
- **Direct database**: Access raw data (advanced users)

### Does it work on mobile devices?

Yes, the web interface is fully responsive and optimized for mobile devices. There's no separate mobile app needed.

## API & Integration

### How do I access the API?

The REST API is available at:
```
http://localhost:8110/api/
```

Example endpoints:
- `/api/data/weather` - All weather data
- `/api/data/live/{city}` - Specific city data
- `/api/data/locations` - Available locations

### Do I need an API key?

- **Public endpoints**: No authentication required
- **Administrative endpoints**: API key required

Generate an API key automatically during installation or get it via:
```bash
curl http://localhost:8110/admin/api-key  # Debug mode only
```

### What data formats are supported?

All API responses use JSON format with consistent structure:

```json
{
  \"data\": { ... },
  \"timestamp\": \"2025-01-01T00:00:00Z\",
  \"request_id\": \"req_1234567890\"
}
```

### Are there rate limits?

- **Public endpoints**: 100 requests/minute per IP
- **Authenticated endpoints**: 1000 requests/minute per API key

### Can I integrate with other applications?

Yes, the REST API makes integration straightforward:

```javascript
// JavaScript example
fetch('http://localhost:8110/api/data/weather')
  .then(response => response.json())
  .then(data => console.log(data));
```

```python
# Python example
import requests
response = requests.get('http://localhost:8110/api/data/weather')
weather_data = response.json()
```

## Configuration & Customization

### How do I configure Weather Station?

Configuration is done through environment variables in a `.env` file:

```env
WS_HOST=0.0.0.0
WS_PORT=8110
WS_DEBUG=false
WS_LIVE_DATA_ENABLED=true
WS_OPEN_METEO_URL=http://localhost:8080/v1
```

See [Configuration Reference](../reference/configuration.md) for all options.

### Can I customize the web interface?

Yes, several ways:
- **CSS**: Modify `assets/style.css`
- **HTML**: Edit template files
- **JavaScript**: Extend `assets/script.js`
- **Themes**: Dark/light mode toggle available

### How do I enable debug mode?

Set the debug environment variable:

```env
WS_DEBUG=true
WS_LOG_LEVEL=DEBUG
```

This enables:
- Detailed logging
- API key display
- Access logs endpoint
- Development features

### Can I use external weather APIs?

Yes, configure to use public Open-Meteo API:

```env
WS_USE_SELF_HOSTED=false
WS_OPEN_METEO_URL=https://api.open-meteo.com/v1
```

## Troubleshooting

### Weather Station won't start

1. **Check Docker is running**: `docker info`
2. **Check port availability**: `sudo lsof -i :8110`
3. **Check logs**: `docker-compose logs weatherstation`
4. **Verify configuration**: Check `.env` file syntax

### No weather data showing

1. **Check API status**: `curl http://localhost:8110/api/status`
2. **Initialize data**: `./init-weather-data.sh`
3. **Check Open-Meteo**: `curl http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&current=temperature_2m`
4. **Force update**: Use admin API to trigger manual update

### Slow performance

1. **Reduce data load**: Use `?limit=10` parameter
2. **Check resources**: `docker stats`
3. **Optimize configuration**: Enable caching
4. **Update data**: `./init-weather-data.sh`

### Can't access from other computers

1. **Check host binding**: Ensure `WS_HOST=0.0.0.0`
2. **Check firewall**: `sudo ufw allow 8110/tcp`
3. **Test locally first**: `curl http://localhost:8110/health`
4. **Check network**: Verify IP address and routing

### CORS errors in browser

Configure CORS origins:

```env
# Development (allow all)
WS_CORS_ORIGINS=[\"*\"]

# Production (specific domains)
WS_CORS_ORIGINS=[\"https://yourdomain.com\"]
```

## Performance & Scaling

### How many concurrent users can it handle?

Typical performance:
- **Small setup** (2GB RAM): 50-100 concurrent users
- **Medium setup** (4GB RAM): 200-500 concurrent users
- **Large setup** (8GB+ RAM): 1000+ concurrent users

Actual performance depends on usage patterns and data complexity.

### Can I use a database for better performance?

Currently, Weather Station uses file-based caching. Database support is planned for future versions. You can implement custom data persistence by extending the data managers.

### How do I monitor performance?

```bash
# Resource usage
docker stats

# Response times
time curl \"http://localhost:8110/api/data/weather?limit=10\"

# Application logs
docker-compose logs -f weatherstation

# System monitoring
htop
iotop
```

### Can I use a CDN?

Yes, for static assets. Configure your reverse proxy to serve static files:

```nginx
location /assets/ {
    alias /path/to/weatherstation/assets/;
    expires 1y;
    add_header Cache-Control \"public\";
}
```

## Security

### Is Weather Station secure?

Weather Station follows security best practices:
- **No default passwords**
- **API key authentication** for admin functions
- **Input validation** on all endpoints
- **CORS protection** configurable
- **No sensitive data logging**

### How do I secure it for production?

1. **Use HTTPS**: Configure reverse proxy with SSL
2. **Firewall**: Only allow necessary ports
3. **API keys**: Use strong, unique API keys
4. **Updates**: Keep system and dependencies updated
5. **Monitoring**: Set up log monitoring

### Should I expose it to the internet?

For internal use, keep it behind a VPN or firewall. For public access:
- Use HTTPS
- Configure rate limiting
- Monitor access logs
- Consider authentication

### How do I update Weather Station?

```bash
# Pull latest changes
git pull

# Rebuild containers
docker-compose build --no-cache

# Restart services
docker-compose up -d

# Update weather data
./init-weather-data.sh
```

## Development & Contribution

### Can I contribute to the project?

Yes! Weather Station v2.0 is open source. See our [Contributing Guide](../development/contributing.md) for details.

### How do I set up a development environment?

See our [Development Setup Guide](../development/setup.md) for complete instructions.

### What technologies are used?

- **Backend**: Python 3.11+, FastAPI, Uvicorn
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Data**: Open-Meteo API, JSON caching
- **Deployment**: Docker, Docker Compose
- **Testing**: pytest, GitHub Actions

### How do I report bugs or request features?

1. **Search existing issues**: [GitHub Issues](https://github.com/RA86-dev/v2weatherstation/issues)
2. **Create new issue**: Use appropriate template
3. **Provide details**: Steps to reproduce, expected behavior
4. **Include logs**: Relevant error messages

### Is there a roadmap?

Yes, check our [GitHub Project Board](https://github.com/RA86-dev/v2weatherstation/projects) for planned features and improvements.

## Licensing & Legal

### What license is Weather Station under?

Weather Station v2.0 is released under [LICENSE](https://github.com/RA86-dev/v2weatherstation/blob/main/LICENSE). Check the repository for current license terms.

### Can I use it commercially?

Check the license file for commercial use permissions. Generally, open source licenses allow commercial use with certain requirements.

### What about weather data licensing?

Weather data from Open-Meteo is available under their terms. Public weather data is generally freely available, but check specific sources for any restrictions.

### Do you provide support?

- **Community support**: Free via GitHub, Discord
- **Documentation**: Comprehensive guides included
- **Enterprise support**: Available for business users
- **Custom development**: Professional services available

## Migration & Compatibility

### Can I migrate from Weather Station v1.x?

Weather Station v2.0 is a complete rewrite. Migration tools are not provided, but you can:
- Export data from v1.x
- Configure v2.0 with similar settings
- Use API to import historical data (if needed)

### Is it compatible with existing weather APIs?

Weather Station v2.0 uses Open-Meteo API format. To use other APIs, you'd need to:
- Create custom data adapters
- Implement API connectors
- Follow contribution guidelines

### Can I run it alongside other weather software?

Yes, but ensure:
- Different ports are used
- No resource conflicts
- Separate data directories
- Different Docker networks if needed

## Still Need Help?

If your question isn't answered here:

1. **Check documentation**: [Full documentation](../main.md)
2. **Search issues**: [GitHub Issues](https://github.com/RA86-dev/v2weatherstation/issues)
3. **Ask community**: [GitHub Discussions](https://github.com/RA86-dev/v2weatherstation/discussions)
4. **Join Discord**: Community chat and support
5. **Contact support**: For enterprise users

---

**Have a question not covered here?** [Let us know!](https://github.com/RA86-dev/v2weatherstation/discussions) We'll add it to the FAQ. 🤔