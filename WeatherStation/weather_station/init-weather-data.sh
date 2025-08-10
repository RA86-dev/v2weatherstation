#!/bin/bash

echo "🌤️  Initializing Open-Meteo with weather data..."
echo "==============================================="

# Wait for Open-Meteo container to be ready
echo "⏳ Waiting for Open-Meteo container to start..."
sleep 10

# Check if Open-Meteo is running
if ! docker ps | grep -q weather_station_openmeteo; then
    echo "❌ Open-Meteo container is not running!"
    exit 1
fi

echo "✅ Open-Meteo container is running"

# Download essential weather models with core variables for US weather
echo "📡 Downloading weather data models..."

# Download ECMWF IFS model (European Centre for Medium-Range Weather Forecasts)
# This provides good global coverage including the US
echo "⬇️  Downloading ECMWF IFS model data..."
docker run -it --rm \
    -v weather_station_open-meteo-data:/app/data \
    ghcr.io/open-meteo/open-meteo \
    sync ecmwf_ifs025 \
    temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,pressure_msl,surface_pressure,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,rain,showers,snowfall

if [ $? -eq 0 ]; then
    echo "✅ ECMWF IFS model data downloaded successfully"
else
    echo "⚠️  ECMWF download failed, trying alternative..."
fi

# Download GFS model (US National Weather Service) as backup
echo "⬇️  Downloading GFS model data..."
docker run -it --rm \
    -v weather_station_open-meteo-data:/app/data \
    ghcr.io/open-meteo/open-meteo \
    sync gfs_seamless \
    temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,pressure_msl,surface_pressure,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,rain,showers,snowfall

if [ $? -eq 0 ]; then
    echo "✅ GFS model data downloaded successfully"
else
    echo "⚠️  GFS download failed"
fi

echo ""
echo "🎉 Weather data initialization complete!"
echo "🌐 Open-Meteo API is ready at: http://localhost:8080"
echo ""
echo "Test with:"
echo "curl 'http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&hourly=temperature_2m'"