#!/bin/bash
#
# Open-Meteo Data Update Script
# ============================
# Updates weather model data weekly for self-hosted Open-Meteo
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

main() {
    echo_info "Open-Meteo Data Update - $(date)"
    echo_info "================================="
    echo
    
    # Check if Open-Meteo container is running
    if ! docker ps | grep -q open-meteo-api; then
        echo_error "Open-Meteo container is not running!"
        exit 1
    fi
    
    echo_success "Open-Meteo container is running"
    
    # Download fresh weather model data
    echo_info "Downloading fresh weather model data..."
    
    # Download global weather models for worldwide coverage
    echo_info "Updating global weather models (5-7 days forecast)..."
    
    # 1. ECMWF IFS 0.25° Global (best global coverage)
    echo_info "Updating ECMWF IFS Global model..."
    if docker run --rm -v open-meteo-data:/app/data ghcr.io/open-meteo/open-meteo \
        sync ecmwf_ifs025 temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m,wind_direction_10m,precipitation; then
        echo_success "ECMWF IFS Global model updated successfully"
    else
        echo_warning "ECMWF update failed, continuing with other models..."
    fi
    
    # 2. NOAA GFS 0.25° (worldwide coverage)
    echo_info "Updating NOAA GFS 0.25° model..."
    if docker run --rm -v open-meteo-data:/app/data ghcr.io/open-meteo/open-meteo \
        sync ncep_gfs025 temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m,wind_direction_10m,precipitation; then
        echo_success "NOAA GFS 0.25° model updated successfully"
    else
        echo_warning "NOAA GFS 0.25° update failed"
    fi
    
    # 3. MeteoFrance ARPEGE World 0.25°
    echo_info "Updating MeteoFrance ARPEGE World model..."
    if docker run --rm -v open-meteo-data:/app/data ghcr.io/open-meteo/open-meteo \
        sync meteofrance_arpege_world025 temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m,wind_direction_10m,precipitation; then
        echo_success "MeteoFrance ARPEGE World updated successfully"
    else
        echo_warning "MeteoFrance ARPEGE World update failed"
    fi
    
    # 4. JMA GSM (Asia/Pacific)
    echo_info "Updating JMA GSM model..."
    if docker run --rm -v open-meteo-data:/app/data ghcr.io/open-meteo/open-meteo \
        sync jma_gsm temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m,wind_direction_10m,precipitation; then
        echo_success "JMA GSM model updated successfully"
    else
        echo_warning "JMA GSM update failed"
    fi
    
    # 5. CMA GRAPES Global
    echo_info "Updating CMA GRAPES Global model..."
    if docker run --rm -v open-meteo-data:/app/data ghcr.io/open-meteo/open-meteo \
        sync cma_grapes_global temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m,wind_direction_10m,precipitation; then
        echo_success "CMA GRAPES Global model updated successfully"
    else
        echo_warning "CMA GRAPES Global update failed"
    fi
    
    # Restart Open-Meteo API to load new data
    echo_info "Restarting Open-Meteo API to load fresh data..."
    docker restart open-meteo-api
    
    # Wait for restart
    sleep 10
    
    # Test API
    echo_info "Testing API with fresh data..."
    if curl -s "http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&hourly=pressure_msl" > /dev/null; then
        echo_success "API is responding after update"
    else
        echo_error "API test failed after update"
        exit 1
    fi
    
    echo
    echo_success "Weather data update completed successfully!"
    echo_info "Next update should run in 7 days"
}

# Run main function
main "$@"