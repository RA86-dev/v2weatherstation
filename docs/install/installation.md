# Installation Guide

This comprehensive guide covers all installation methods for Weather Station v2.0, from quick Docker deployment to manual installation and production setup.

## Quick Start

For most users, the Docker installation is the fastest way to get started:

```bash
# Clone and install
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation
./install-global.sh
```

## Installation Methods

### 🐳 Docker Installation (Recommended)
- **Best for**: Most users, production deployments
- **Time**: 5-10 minutes
- **Difficulty**: Easy
- **Guide**: [Docker Installation](docker-install.md)

### 🔧 Manual Installation
- **Best for**: Development, custom setups
- **Time**: 15-30 minutes
- **Difficulty**: Intermediate
- **Guide**: [Manual Installation](#manual-installation)

### 🚀 Global Installation Script
- **Best for**: System-wide installation
- **Time**: 5-15 minutes
- **Difficulty**: Easy
- **Guide**: [Global Installation](#global-installation)

### ☁️ Cloud Deployment
- **Best for**: Production, scalability
- **Time**: 10-20 minutes
- **Difficulty**: Intermediate
- **Guide**: [Cloud Deployment](../administration/deployment.md)

## System Requirements

### Minimum Requirements
| Component | Requirement |
|-----------|-------------|
| **OS** | Linux, macOS, Windows (WSL2) |
| **Memory** | 2GB RAM |
| **Storage** | 5GB available space |
| **CPU** | 1 core, 1GHz |
| **Network** | Internet connection |

### Recommended Requirements
| Component | Recommendation |
|-----------|----------------|
| **OS** | Ubuntu 20.04+ LTS |
| **Memory** | 4GB+ RAM |
| **Storage** | 20GB+ SSD |
| **CPU** | 2+ cores, 2GHz+ |
| **Network** | Broadband connection |

### Software Dependencies
| Software | Version | Required |
|----------|---------|----------|
| **Docker** | 20.10.0+ | Yes (Docker method) |
| **Docker Compose** | 2.0.0+ | Yes (Docker method) |
| **Python** | 3.8+ | Yes (Manual method) |
| **Git** | 2.20.0+ | Yes |
| **Node.js** | 16.0+ | Optional (development) |

## Global Installation

The global installation script provides the easiest way to install Weather Station system-wide.

### Quick Install
```bash
# Download and run installer
curl -sSL https://raw.githubusercontent.com/RA86-dev/v2weatherstation/main/install-global.sh | bash
```

### Manual Download
```bash
# Download installer
wget https://raw.githubusercontent.com/RA86-dev/v2weatherstation/main/install-global.sh
chmod +x install-global.sh

# Run installer
./install-global.sh
```

### Installation Options
```bash
# Install to custom directory
./install-global.sh --dir /opt/weather

# Auto-install dependencies (Linux only)
./install-global.sh --auto-install

# Force reinstall
./install-global.sh --force

# Install specific branch
./install-global.sh --branch develop

# Setup only (don't start services)
./install-global.sh --no-start
```

### Post-Installation
After installation:

1. **Access the dashboard**: http://localhost:8110
2. **Check API status**: http://localhost:8110/api/status
3. **View logs**: `sudo journalctl -u weatherstation -f`
4. **Manage service**: `sudo systemctl status weatherstation`

## Manual Installation

For development or custom setups, install manually:

### Step 1: Install Dependencies

#### Ubuntu/Debian
```bash
# Update package list
sudo apt update

# Install Python and pip
sudo apt install python3 python3-pip python3-venv git curl

# Install Docker (optional)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### CentOS/RHEL/Fedora
```bash
# Install Python and tools
sudo dnf install python3 python3-pip git curl

# Install Docker (optional)
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### macOS
```bash
# Install Homebrew if not installed
/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"

# Install dependencies
brew install python3 git
brew install --cask docker  # For Docker support
```

### Step 2: Clone Repository
```bash
# Clone the repository
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation
```

### Step 3: Setup Python Environment
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
# or
venv\\Scripts\\activate.bat  # Windows

# Install dependencies
pip install -r requirements.txt
```

### Step 4: Configuration
```bash
# Copy example configuration
cp .env.example .env

# Edit configuration
nano .env
```

Example `.env` file:
```env
WS_HOST=0.0.0.0
WS_PORT=8110
WS_DEBUG=true
WS_LIVE_DATA_ENABLED=true
WS_USE_SELF_HOSTED=false
WS_OPEN_METEO_URL=https://api.open-meteo.com/v1
WS_LOG_LEVEL=INFO
```

### Step 5: Initialize Database (if needed)
```bash
# Create data directories
mkdir -p data/weather data/logs

# Initialize configuration
python3 -c \"from WeatherStation.weather_station.config import get_config; get_config().validate()\"
```

### Step 6: Start Application
```bash
# Start the application
python3 main.py
```

### Step 7: Verify Installation
```bash
# Test in another terminal
curl http://localhost:8110/health
```

## Development Installation

For developers working on Weather Station:

### Additional Dependencies
```bash
# Install development dependencies
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install

# Install Node.js dependencies (for frontend)
npm install
```

### Development Tools
```bash
# Run tests
pytest

# Run linting
flake8 .
black .

# Run type checking
mypy .

# Start development server with hot reload
uvicorn WeatherStation.weather_station.index:app --reload --host 0.0.0.0 --port 8110
```

## Production Installation

For production deployments, additional considerations:

### Security Hardening
```bash
# Generate secure API key
WS_API_KEY=$(openssl rand -hex 32)

# Set restrictive CORS origins
WS_CORS_ORIGINS=[\"https://yourdomain.com\"]

# Disable debug mode
WS_DEBUG=false
```

### Process Management

#### Systemd Service
```ini
# /etc/systemd/system/weatherstation.service
[Unit]
Description=Weather Station v2.0
After=network.target

[Service]
Type=simple
User=weatherstation
WorkingDirectory=/opt/weatherstation
EnvironmentFile=/etc/weatherstation/config.env
ExecStart=/opt/weatherstation/venv/bin/python main.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

#### Start Service
```bash
# Enable and start service
sudo systemctl enable weatherstation
sudo systemctl start weatherstation

# Check status
sudo systemctl status weatherstation
```

### Reverse Proxy Setup

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name weather.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name weather.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:8110;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }
    
    # Static files
    location /assets/ {
        alias /opt/weatherstation/WeatherStation/weather_station/assets/;
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }
}
```

### Database Setup (Optional)

For persistent data storage:

```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Create database and user
sudo -u postgres createuser weatherstation
sudo -u postgres createdb weatherstation_db -O weatherstation

# Configure connection
echo \"DATABASE_URL=postgresql://weatherstation:password@localhost/weatherstation_db\" >> .env
```

## Verification

After installation, verify everything is working:

### Health Checks
```bash
# Basic health check
curl http://localhost:8110/health

# API status
curl http://localhost:8110/api/status

# Weather data
curl \"http://localhost:8110/api/data/weather?limit=5\"
```

### Web Interface
1. Open http://localhost:8110 in your browser
2. Check that weather data loads
3. Test different pages (comparison, maps, statistics)
4. Verify responsive design on mobile

### Performance Test
```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test API performance
ab -n 100 -c 10 http://localhost:8110/api/data/weather
```

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Fix file permissions
chmod +x *.sh
chown -R $USER:$USER .
```

#### Port Already in Use
```bash
# Find process using port
sudo lsof -i :8110

# Kill process or change port
WS_PORT=8111 python3 main.py
```

#### Module Not Found
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### Docker Issues
```bash
# Restart Docker
sudo systemctl restart docker

# Clean up
docker system prune -a
```

### Log Analysis
```bash
# Application logs
tail -f data/logs/weatherstation.log

# System logs
sudo journalctl -u weatherstation -f

# Docker logs
docker-compose logs -f
```

## Uninstallation

### Docker Installation
```bash
# Stop and remove containers
docker-compose down -v

# Remove images
docker rmi v2weatherstation:latest
```

### Manual Installation
```bash
# Stop service
sudo systemctl stop weatherstation
sudo systemctl disable weatherstation

# Remove files
rm -rf /opt/weatherstation
sudo rm /etc/systemd/system/weatherstation.service
```

### Global Installation
```bash
# Use uninstall option
./install-global.sh --uninstall
```

## Next Steps

- [Configuration Guide](../reference/configuration.md)
- [User Guide](../guides/user-guide.md)
- [API Documentation](../api/overview.md)
- [Deployment Guide](../administration/deployment.md)

## Support

If you need help:

1. Check [Troubleshooting Guide](../support/troubleshooting.md)
2. Review [FAQ](../support/faq.md)
3. Search [GitHub Issues](https://github.com/RA86-dev/v2weatherstation/issues)
4. Join our [Community Forum](https://github.com/RA86-dev/v2weatherstation/discussions)