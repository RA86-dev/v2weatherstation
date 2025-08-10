#!/bin/bash

echo "🌤️  Weather Station Self-Hosted Setup"
echo "====================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose not found. Please install docker-compose."
    exit 1
fi

echo "✅ docker-compose found"

# Create data directory for Open-Meteo
mkdir -p data/open-meteo
echo "✅ Created data directories"

# Build and start the services
echo "🚀 Starting self-hosted Open-Meteo and Weather Station..."
echo "   - Open-Meteo API will be available at: http://localhost:8081"
echo "   - Weather Station will be available at: http://localhost:8110"

docker-compose up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Services started successfully!"
    echo ""
    echo "📥 Initializing weather data (this may take a few minutes)..."
    echo "   You can skip this step and the API will work with live requests"
    echo "   but having local data improves performance significantly."
    echo ""
    read -p "Initialize weather data now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./init-weather-data.sh
    else
        echo "⚠️  Skipping data initialization. API will fetch data on-demand."
    fi
    echo ""
    echo "🌐 Access your weather station at: http://localhost:8110"
    echo "🔧 API endpoints:"
    echo "   - Health check: http://localhost:8110/health"
    echo "   - API status: http://localhost:8110/api/status"
    echo "   - Live data: http://localhost:8110/api/data/live/{city}"
    echo "   - All locations: http://localhost:8110/api/data/locations"
    echo ""
    echo "📊 You can monitor the services with:"
    echo "   docker-compose logs -f"
    echo ""
    echo "🛑 To stop the services:"
    echo "   docker-compose down"
else
    echo "❌ Failed to start services. Check the logs with:"
    echo "   docker-compose logs"
fi