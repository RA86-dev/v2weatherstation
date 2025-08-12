# Quick Start Guide

Get Weather Station v2.0 up and running in just 5 minutes! This guide covers the fastest path to a working weather station.

## 🚀 5-Minute Setup

### Prerequisites Check
Before starting, ensure you have:
- A computer with internet connection
- Git installed (`git --version`)
- Docker installed (`docker --version`)

### Step 1: Clone and Install (2 minutes)
```bash
# Clone the repository
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation

# Run the global installer
./install-global.sh
```

### Step 2: Wait for Setup (2 minutes)
The installer will:
- ✅ Check system requirements
- ✅ Download and build Docker containers
- ✅ Initialize weather data
- ✅ Start all services

### Step 3: Access Your Weather Station (30 seconds)
Open your browser and visit: **http://localhost:8110**

You should see the Weather Station dashboard with live weather data!

## ✅ Verification

### Quick Health Check
```bash
# Check if services are running
curl http://localhost:8110/health

# Test API
curl http://localhost:8110/api/data/weather?limit=5
```

Expected response:
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

### Web Interface Test
1. **Dashboard**: Should show weather cards for multiple cities
2. **Live data**: Weather information should be current (check timestamps)
3. **Navigation**: Click through different pages (Comparison, Maps, Statistics)

## 🎯 What You Get

### Immediately Available
- ✅ **Real-time weather data** for 240+ locations
- ✅ **Interactive dashboard** with responsive design
- ✅ **REST API** for programmatic access
- ✅ **Self-hosted** Open-Meteo weather service
- ✅ **Mobile-friendly** interface

### Services Running
| Service | URL | Description |
|---------|-----|-------------|
| Weather Station | http://localhost:8110 | Main application |
| Open-Meteo API | http://localhost:8080 | Weather data API |
| Health Check | http://localhost:8110/health | System status |

## 🔧 Essential Commands

### Service Management
```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d
```

### Data Management
```bash
# Force weather data update
curl -X POST http://localhost:8110/api/data/force-update \
  -H "X-API-Key: $(cat ~/.weatherstation/api-key)"

# Check data status
curl http://localhost:8110/api/data/status
```

## 📱 Quick Tour

### 1. Dashboard
**URL**: http://localhost:8110/
- View current weather for multiple cities
- Search for specific locations
- Responsive design works on mobile

### 2. Weather Comparison
**URL**: http://localhost:8110/comparison
- Compare weather between different cities
- Side-by-side temperature, humidity, pressure
- Export comparison data

### 3. Interactive Maps
**URL**: http://localhost:8110/intmap
- Interactive pressure maps
- Real-time weather visualization
- Zoom and pan functionality

### 4. Statistics
**URL**: http://localhost:8110/weatherstat
- Historical weather trends
- Statistical analysis
- Data visualization charts

## 🛠️ Basic Configuration

### Environment Variables
Edit the configuration file:
```bash
# For global installation
sudo nano /etc/weatherstation/config.env

# For local installation
nano .env
```

Common settings:
```env
# Change port (default: 8110)
WS_PORT=8111

# Enable debug mode
WS_DEBUG=true

# Set custom API URL
WS_OPEN_METEO_URL=https://api.open-meteo.com/v1
```

### Apply Changes
```bash
# Restart services to apply changes
docker-compose restart

# Or if using systemd (global installation)
sudo systemctl restart weatherstation
```

## 📊 API Quick Examples

### Get Weather Data
```bash
# All weather data (up to 300 cities)
curl http://localhost:8110/api/data/weather

# Limited to 10 cities
curl "http://localhost:8110/api/data/weather?limit=10"

# Specific city
curl "http://localhost:8110/api/data/live/New%20York"
```

### JavaScript Integration
```javascript
// Fetch weather data
fetch('http://localhost:8110/api/data/weather?limit=5')
  .then(response => response.json())
  .then(data => console.log(data));
```

### Python Integration
```python
import requests

# Get weather data
response = requests.get('http://localhost:8110/api/data/weather')
weather_data = response.json()
print(f"Weather data for {len(weather_data['data'])} cities")
```

## 🚨 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using port 8110
sudo lsof -i :8110

# Use different port
WS_PORT=8111 docker-compose up -d
```

#### Services Won't Start
```bash
# Check Docker is running
docker info

# Restart Docker
sudo systemctl restart docker

# Check logs for errors
docker-compose logs
```

#### No Weather Data
```bash
# Check API connectivity
curl http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&current=temperature_2m

# Initialize weather data manually
./init-weather-data.sh
```

#### Can't Access Web Interface
```bash
# Check if service is running
curl http://localhost:8110/health

# Check firewall
sudo ufw status

# Test locally
docker exec -it weatherstation-app curl http://localhost:8110/health
```

### Get Help
- **Check logs**: `docker-compose logs weatherstation`
- **System status**: `curl http://localhost:8110/api/status`
- **Full troubleshooting**: [Troubleshooting Guide](../support/troubleshooting.md)

## ⚡ Performance Tips

### Optimize for Speed
```bash
# Limit locations to improve performance
curl "http://localhost:8110/api/data/weather?limit=50"

# Use caching
# (already enabled by default)

# Monitor resource usage
docker stats
```

### Resource Management
```yaml
# Add to docker-compose.yml for resource limits
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

## 🔒 Security Quick Setup

### Basic Security
```bash
# Generate secure API key
WS_API_KEY=$(openssl rand -hex 32)

# Set in configuration
echo "WS_API_KEY=$WS_API_KEY" >> .env

# Restart to apply
docker-compose restart
```

### Firewall Setup
```bash
# Allow only necessary ports
sudo ufw allow 8110/tcp
sudo ufw enable
```

## 📈 Next Steps

### Beginner
- [User Guide](user-guide.md) - Learn all features
- [Web Interface Guide](web-interface.md) - Master the dashboard
- [Configuration Reference](../reference/configuration.md) - Customize settings

### Intermediate
- [API Usage Guide](api-usage.md) - Integrate with applications
- [Mobile Guide](mobile.md) - Optimize for mobile
- [Performance Guide](../support/performance.md) - Optimize performance

### Advanced
- [Development Setup](../development/setup.md) - Contribute to project
- [Deployment Guide](../administration/deployment.md) - Production deployment
- [Architecture Overview](../development/architecture.md) - Understand the system

### Production
- [Security Guide](../administration/security.md) - Secure your installation
- [Monitoring Guide](../administration/monitoring.md) - Monitor system health
- [Backup Guide](../administration/backup.md) - Backup and restore

## 🎉 Success!

Congratulations! You now have a fully functional Weather Station v2.0 installation. 

### What's Working
- ✅ Weather data from 240+ locations
- ✅ Interactive web interface
- ✅ REST API for integration
- ✅ Self-hosted weather service
- ✅ Automatic data updates

### Explore More
- **Dashboard**: Real-time weather overview
- **API**: Programmatic data access
- **Maps**: Interactive weather visualization
- **Statistics**: Historical data analysis

### Get Support
- [Full Documentation](../main.md)
- [Community Forum](https://github.com/RA86-dev/v2weatherstation/discussions)
- [Report Issues](https://github.com/RA86-dev/v2weatherstation/issues)

---

**Enjoy your new Weather Station!** 🌤️