# Development Setup

This guide covers setting up a development environment for Weather Station v2.0, including tools, dependencies, and best practices for contributing to the project.

## Prerequisites

### System Requirements
- **OS**: Linux, macOS, or Windows (with WSL2)
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 10GB available space
- **CPU**: 2+ cores recommended

### Required Software
- **Python**: 3.8+ (3.11+ recommended)
- **Git**: 2.20.0+
- **Docker**: 20.10.0+ (for testing)
- **Node.js**: 16.0+ (for frontend development)

### Recommended Tools
- **IDE**: VS Code, PyCharm, or similar
- **Terminal**: iTerm2 (macOS), Windows Terminal (Windows)
- **Git GUI**: GitKraken, Sourcetree, or GitHub Desktop
- **API Testing**: Postman, Insomnia, or HTTPie

## Environment Setup

### 1. Clone Repository
```bash
# Clone the main repository
git clone https://github.com/RA86-dev/v2weatherstation.git
cd v2weatherstation

# Add upstream remote for syncing
git remote add upstream https://github.com/RA86-dev/v2weatherstation.git
```

### 2. Python Environment
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# Linux/macOS:
source venv/bin/activate
# Windows:
venv\\Scripts\\activate

# Upgrade pip
pip install --upgrade pip

# Install development dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### 3. Development Dependencies

Create `requirements-dev.txt`:
```txt
# Testing
pytest>=7.0.0
pytest-asyncio>=0.21.0
pytest-cov>=4.0.0
pytest-mock>=3.10.0
httpx>=0.24.0

# Code Quality
flake8>=6.0.0
black>=23.0.0
isort>=5.12.0
mypy>=1.0.0
pre-commit>=3.0.0

# Documentation
sphinx>=6.0.0
sphinx-rtd-theme>=1.2.0
mkdocs>=1.4.0
mkdocs-material>=9.0.0

# Development Tools
ipython>=8.0.0
jupyter>=1.0.0
watchdog>=3.0.0

# API Development
fastapi-cli>=0.0.2
uvicorn[standard]>=0.20.0
```

### 4. IDE Configuration

#### VS Code Setup
Create `.vscode/settings.json`:
```json
{
    \"python.defaultInterpreterPath\": \"./venv/bin/python\",
    \"python.linting.enabled\": true,
    \"python.linting.flake8Enabled\": true,
    \"python.linting.mypyEnabled\": true,
    \"python.formatting.provider\": \"black\",
    \"python.formatting.blackArgs\": [\"--line-length=88\"],
    \"python.sortImports.args\": [\"--profile\", \"black\"],
    \"editor.formatOnSave\": true,
    \"editor.codeActionsOnSave\": {
        \"source.organizeImports\": true
    },
    \"files.exclude\": {
        \"**/__pycache__\": true,
        \"**/*.pyc\": true,
        \".mypy_cache\": true,
        \".pytest_cache\": true
    }
}
```

Create `.vscode/extensions.json`:
```json
{
    \"recommendations\": [
        \"ms-python.python\",
        \"ms-python.flake8\",
        \"ms-python.black-formatter\",
        \"ms-python.isort\",
        \"ms-python.mypy-type-checker\",
        \"ms-vscode.vscode-json\",
        \"redhat.vscode-yaml\",
        \"ms-vscode.test-adapter-converter\"
    ]
}
```

### 5. Pre-commit Hooks
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
```

Create `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-json
      - id: check-merge-conflict

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: [\"--profile\", \"black\"]

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        args: [\"--max-line-length=88\", \"--extend-ignore=E203,W503\"]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
```

## Development Workflow

### 1. Branch Strategy
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Create bugfix branch
git checkout -b bugfix/issue-description

# Create documentation branch
git checkout -b docs/section-name
```

### 2. Development Environment
```bash
# Start development server with hot reload
uvicorn WeatherStation.weather_station.index:app --reload --host 0.0.0.0 --port 8110

# Or use the development script
python scripts/dev-server.py
```

Create `scripts/dev-server.py`:
```python
#!/usr/bin/env python3
\"\"\"
Development server with hot reload and enhanced logging.
\"\"\"

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Set development environment
os.environ[\"WS_DEBUG\"] = \"true\"
os.environ[\"WS_LOG_LEVEL\"] = \"DEBUG\"
os.environ[\"WS_LIVE_DATA_ENABLED\"] = \"false\"  # Use mock data for development

if __name__ == \"__main__\":
    import uvicorn
    
    uvicorn.run(
        \"WeatherStation.weather_station.index:app\",
        host=\"0.0.0.0\",
        port=8110,
        reload=True,
        log_level=\"debug\",
        access_log=True
    )
```

### 3. Code Quality
```bash
# Format code
black .
isort .

# Check code quality
flake8 .
mypy .

# Run all checks
pre-commit run --all-files
```

### 4. Testing
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=WeatherStation --cov-report=html

# Run specific test file
pytest tests/test_api.py

# Run with verbose output
pytest -v

# Run and watch for changes
ptw
```

## Testing Framework

### Test Structure
```
tests/
├── __init__.py
├── conftest.py           # Shared fixtures
├── test_api/
│   ├── __init__.py
│   ├── test_endpoints.py
│   ├── test_auth.py
│   └── test_data.py
├── test_core/
│   ├── __init__.py
│   ├── test_config.py
│   ├── test_data_manager.py
│   └── test_live_data.py
├── test_integration/
│   ├── __init__.py
│   ├── test_full_stack.py
│   └── test_docker.py
└── fixtures/
    ├── weather_data.json
    └── test_config.env
```

### Writing Tests

Create `tests/conftest.py`:
```python
\"\"\"
Shared test fixtures.
\"\"\"

import pytest
from fastapi.testclient import TestClient
from WeatherStation.weather_station.index import create_app
from WeatherStation.weather_station.config import get_config


@pytest.fixture
def test_config():
    \"\"\"Test configuration.\"\"\"
    import os
    # Set test environment variables
    os.environ[\"WS_DEBUG\"] = \"true\"
    os.environ[\"WS_LIVE_DATA_ENABLED\"] = \"false\"
    os.environ[\"WS_USE_SELF_HOSTED\"] = \"false\"
    
    config = get_config()
    yield config
    
    # Cleanup
    for key in [\"WS_DEBUG\", \"WS_LIVE_DATA_ENABLED\", \"WS_USE_SELF_HOSTED\"]:
        os.environ.pop(key, None)


@pytest.fixture
def test_client(test_config):
    \"\"\"Test client fixture.\"\"\"
    app = create_app()
    with TestClient(app) as client:
        yield client


@pytest.fixture
def sample_weather_data():
    \"\"\"Sample weather data for testing.\"\"\"
    return {
        \"New York\": {
            \"coordinates\": {\"latitude\": 40.7128, \"longitude\": -74.0060},
            \"current_conditions\": {
                \"temperature\": 22.5,
                \"humidity\": 65,
                \"pressure\": 1013.25,
                \"wind_speed\": 15.2,
                \"wind_direction\": 180
            }
        }
    }
```

Example test file `tests/test_api/test_endpoints.py`:
```python
\"\"\"
API endpoint tests.
\"\"\"

import pytest
from fastapi import status


class TestHealthEndpoints:
    \"\"\"Test health and status endpoints.\"\"\"
    
    def test_health_check(self, test_client):
        \"\"\"Test health check endpoint.\"\"\"
        response = test_client.get(\"/health\")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert data[\"status\"] == \"healthy\"
        assert \"version\" in data
        assert \"timestamp\" in data
    
    def test_api_status(self, test_client):
        \"\"\"Test API status endpoint.\"\"\"
        response = test_client.get(\"/api/status\")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert \"live_data_enabled\" in data
        assert \"timestamp\" in data


class TestWeatherEndpoints:
    \"\"\"Test weather data endpoints.\"\"\"
    
    def test_get_weather_data(self, test_client):
        \"\"\"Test weather data endpoint.\"\"\"
        response = test_client.get(\"/api/data/weather?limit=5\")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert \"data\" in data
        assert \"timestamp\" in data
        assert len(data.get(\"locations\", [])) <= 5
    
    def test_get_weather_invalid_limit(self, test_client):
        \"\"\"Test weather data endpoint with invalid limit.\"\"\"
        response = test_client.get(\"/api/data/weather?limit=999\")
        assert response.status_code == status.HTTP_200_OK
        
        # Should be capped at maximum
        data = response.json()
        assert len(data.get(\"locations\", [])) <= 300
    
    def test_get_locations(self, test_client):
        \"\"\"Test locations endpoint.\"\"\"
        response = test_client.get(\"/api/data/locations\")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert \"locations\" in data
        assert \"coordinates\" in data
        assert \"total\" in data
```

### Mock Data for Development

Create `tests/mocks/weather_service.py`:
```python
\"\"\"
Mock weather service for development and testing.
\"\"\"

import json
import random
from datetime import datetime
from pathlib import Path
from typing import Dict, Any


class MockWeatherService:
    \"\"\"Mock weather service that generates realistic test data.\"\"\"
    
    def __init__(self):
        self.cities = self._load_cities()
    
    def _load_cities(self) -> Dict[str, Dict[str, float]]:
        \"\"\"Load city coordinates from test data.\"\"\"
        cities_file = Path(__file__).parent / \"cities.json\"
        if cities_file.exists():
            with open(cities_file) as f:
                return json.load(f)
        
        # Fallback test cities
        return {
            \"New York\": {\"latitude\": 40.7128, \"longitude\": -74.0060},
            \"Los Angeles\": {\"latitude\": 34.0522, \"longitude\": -118.2437},
            \"Chicago\": {\"latitude\": 41.8781, \"longitude\": -87.6298},
            \"Houston\": {\"latitude\": 29.7604, \"longitude\": -95.3698},
            \"Phoenix\": {\"latitude\": 33.4484, \"longitude\": -112.0740}
        }
    
    def get_weather_data(self, limit: int = 300) -> Dict[str, Any]:
        \"\"\"Generate mock weather data.\"\"\"
        cities = list(self.cities.items())[:limit]
        data = {}
        
        for city_name, coords in cities:
            data[city_name] = {
                \"coordinates\": coords,
                \"current_conditions\": self._generate_conditions(),
                \"last_updated\": datetime.utcnow().isoformat() + \"Z\"
            }
        
        return {
            \"data\": data,
            \"locations\": list(data.keys()),
            \"total_available\": len(self.cities),
            \"requested\": len(cities),
            \"fetched\": len(data),
            \"live_data\": False,
            \"mock_data\": True,
            \"timestamp\": datetime.utcnow().isoformat() + \"Z\"
        }
    
    def _generate_conditions(self) -> Dict[str, Any]:
        \"\"\"Generate realistic weather conditions.\"\"\"
        return {
            \"temperature\": round(random.uniform(-10, 35), 1),
            \"humidity\": random.randint(30, 95),
            \"pressure\": round(random.uniform(995, 1025), 1),
            \"wind_speed\": round(random.uniform(0, 25), 1),
            \"wind_direction\": random.randint(0, 359),
            \"precipitation\": round(random.uniform(0, 5), 1) if random.random() < 0.3 else 0.0,
            \"conditions\": random.choice([\"sunny\", \"cloudy\", \"partly_cloudy\", \"rainy\", \"snow\"])
        }
```

## Docker Development

### Development Compose
Create `docker-compose.dev.yml`:
```yaml
version: '3.8'

services:
  weatherstation-dev:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: weatherstation-dev
    ports:
      - \"8110:8110\"
    environment:
      - WS_DEBUG=true
      - WS_LOG_LEVEL=DEBUG
      - WS_LIVE_DATA_ENABLED=false
    volumes:
      - .:/app
      - /app/venv  # Exclude venv from mount
    command: uvicorn WeatherStation.weather_station.index:app --host 0.0.0.0 --port 8110 --reload
    
  redis-dev:
    image: redis:alpine
    container_name: weatherstation-redis-dev
    ports:
      - \"6379:6379\"
    
  postgres-dev:
    image: postgres:15-alpine
    container_name: weatherstation-postgres-dev
    environment:
      POSTGRES_DB: weatherstation_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev123
    ports:
      - \"5432:5432\"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data

volumes:
  postgres_dev_data:
```

Create `Dockerfile.dev`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

# Copy source code
COPY . .

# Development command (overridden in docker-compose)
CMD [\"python\", \"main.py\"]
```

### Development Commands
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f weatherstation-dev

# Execute commands in container
docker-compose -f docker-compose.dev.yml exec weatherstation-dev bash

# Run tests in container
docker-compose -f docker-compose.dev.yml exec weatherstation-dev pytest
```

## Debugging

### VS Code Debugging
Create `.vscode/launch.json`:
```json
{
    \"version\": \"0.2.0\",
    \"configurations\": [
        {
            \"name\": \"Weather Station Debug\",
            \"type\": \"python\",
            \"request\": \"launch\",
            \"program\": \"main.py\",
            \"console\": \"integratedTerminal\",
            \"env\": {
                \"WS_DEBUG\": \"true\",
                \"WS_LOG_LEVEL\": \"DEBUG\"
            }
        },
        {
            \"name\": \"FastAPI Debug\",
            \"type\": \"python\",
            \"request\": \"launch\",
            \"module\": \"uvicorn\",
            \"args\": [
                \"WeatherStation.weather_station.index:app\",
                \"--host\", \"0.0.0.0\",
                \"--port\", \"8110\",
                \"--reload\"
            ],
            \"env\": {
                \"WS_DEBUG\": \"true\",
                \"WS_LOG_LEVEL\": \"DEBUG\"
            }
        },
        {
            \"name\": \"pytest\",
            \"type\": \"python\",
            \"request\": \"launch\",
            \"module\": \"pytest\",
            \"args\": [\"-v\"]
        }
    ]
}
```

### Remote Debugging
```python
# Add to development code for remote debugging
import debugpy

if os.getenv(\"WS_DEBUG\") == \"true\":
    debugpy.listen((\"0.0.0.0\", 5678))
    print(\"Waiting for debugger attach on port 5678...\")
    debugpy.wait_for_client()
```

## Performance Profiling

### Memory Profiling
```bash
# Install memory profiler
pip install memory-profiler

# Profile memory usage
python -m memory_profiler main.py
```

### CPU Profiling
```python
import cProfile
import pstats
from pstats import SortKey

# Profile function
def profile_function():
    pr = cProfile.Profile()
    pr.enable()
    
    # Your code here
    
    pr.disable()
    stats = pstats.Stats(pr)
    stats.sort_stats(SortKey.TIME)
    stats.print_stats()
```

### API Performance Testing
```bash
# Install load testing tools
pip install locust

# Create load test
# locustfile.py
from locust import HttpUser, task, between

class WeatherStationUser(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def get_weather_data(self):
        self.client.get(\"/api/data/weather?limit=10\")
    
    @task(1)
    def get_health(self):
        self.client.get(\"/health\")
    
    @task(1)
    def get_locations(self):
        self.client.get(\"/api/data/locations\")

# Run load test
locust -f locustfile.py --host=http://localhost:8110
```

## Documentation Development

### Live Documentation Server
```bash
# Install MkDocs
pip install mkdocs mkdocs-material

# Start live server
mkdocs serve

# Build documentation
mkdocs build
```

Create `mkdocs.yml`:
```yaml
site_name: Weather Station v2.0 Documentation
site_description: Modern weather data visualization platform
site_author: Weather Station Team
repo_url: https://github.com/RA86-dev/v2weatherstation

theme:
  name: material
  palette:
    - scheme: default
      primary: blue
      accent: light-blue
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate
    - search.suggest
    - search.highlight

markdown_extensions:
  - codehilite
  - admonition
  - toc:
      permalink: true

nav:
  - Home: index.md
  - Installation:
    - Overview: install/installation.md
    - Docker: install/docker-install.md
  - Guides:
    - Quick Start: guides/quick-start.md
    - User Guide: guides/user-guide.md
  - API:
    - Overview: api/overview.md
    - Endpoints: api/endpoints.md
  - Development:
    - Setup: development/setup.md
    - Architecture: development/architecture.md
    - Contributing: development/contributing.md
```

## Contributing Workflow

### 1. Set Up Development
```bash
# Fork repository on GitHub
# Clone your fork
git clone https://github.com/yourusername/v2weatherstation.git
cd v2weatherstation

# Add upstream remote
git remote add upstream https://github.com/RA86-dev/v2weatherstation.git

# Set up development environment
./scripts/setup-dev.sh
```

### 2. Make Changes
```bash
# Create feature branch
git checkout -b feature/awesome-feature

# Make your changes
# ...

# Test your changes
pytest
pre-commit run --all-files

# Commit changes
git add .
git commit -m \"Add awesome feature\"
```

### 3. Submit Pull Request
```bash
# Push to your fork
git push origin feature/awesome-feature

# Create pull request on GitHub
# Include:
# - Clear description of changes
# - Test results
# - Screenshots if UI changes
# - Breaking changes noted
```

## Development Scripts

Create `scripts/setup-dev.sh`:
```bash
#!/bin/bash
set -e

echo \"Setting up Weather Station development environment...\"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install

# Create development configuration
cp .env.example .env.dev

echo \"Development environment setup complete!\"
echo \"Activate with: source venv/bin/activate\"
echo \"Start dev server: python scripts/dev-server.py\"
```

Create `scripts/test.sh`:
```bash
#!/bin/bash
set -e

echo \"Running Weather Station tests...\"

# Code formatting
echo \"Checking code formatting...\"
black --check .
isort --check-only .

# Linting
echo \"Running linting...\"
flake8 .
mypy .

# Tests
echo \"Running tests...\"
pytest --cov=WeatherStation --cov-report=term-missing

echo \"All tests passed!\"
```

## Next Steps

- [Architecture Overview](architecture.md) - Understand the system design
- [Contributing Guidelines](contributing.md) - Learn how to contribute
- [Testing Guide](testing.md) - Write effective tests
- [API Development](../api/overview.md) - Extend the API

## Getting Help

- **Documentation**: Check existing docs first
- **Discussions**: [GitHub Discussions](https://github.com/RA86-dev/v2weatherstation/discussions)
- **Issues**: [GitHub Issues](https://github.com/RA86-dev/v2weatherstation/issues)
- **Discord**: Join our development community

---

**Happy coding!** 🚀