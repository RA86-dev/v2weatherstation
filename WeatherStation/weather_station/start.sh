#!/bin/bash

echo "🌤️  Starting Weather Station v2.0 - SELF-HOSTED"
echo "=============================================="

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Create data directory
mkdir -p data/open-meteo
echo "✅ Created data directories"

# Start the application
echo "🚀 Building and starting self-hosted Weather Station..."
echo "   • Open-Meteo API will start at: http://localhost:8080"
echo "   • Weather Station will start at: http://localhost:8110"
docker-compose up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Self-hosted Weather Station is starting!"
    echo ""
    echo "⏳ IMPORTANT: Open-Meteo needs 2-3 minutes to initialize"
    echo "   Please wait before accessing the weather station"
    echo ""
    echo "🌐 Access URLs:"
    echo "   • Weather Station: http://localhost:8110"
    echo "   • Open-Meteo API: http://localhost:8080"
    echo "   • API Status: http://localhost:8110/api/status"
    echo ""
    echo "🛠️  Management:"
    echo "   • View logs: docker-compose logs -f"
    echo "   • Stop: docker-compose down"
    echo "   • Check Open-Meteo: curl http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0"
    echo ""
    echo "📥 Optional: Initialize weather data for better performance"
    echo "   ./init-weather-data.sh"
else
    echo "❌ Failed to start services. Check logs:"
    echo "   docker-compose logs"
fi