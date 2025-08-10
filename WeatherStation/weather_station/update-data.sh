#!/bin/bash
#
# Weather Station Data Update Script
# ==================================
# Triggers a secure manual data update using the API key
#

set -e

# Configuration
API_KEY="${API_KEY:-wx_admin_2025_secure_key_v1_abc123}"
WEATHER_STATION_URL="${WEATHER_STATION_URL:-http://localhost:8110}"
TIMEOUT="${TIMEOUT:-300}"  # 5 minutes

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

# Function to check if weather station is healthy
check_health() {
    echo_info "Checking weather station health..."
    
    if ! curl -s -f "$WEATHER_STATION_URL/health" > /dev/null 2>&1; then
        echo_error "Weather station is not accessible at $WEATHER_STATION_URL"
        exit 1
    fi
    
    echo_success "Weather station is healthy"
}

# Function to get current status
get_current_status() {
    echo_info "Getting current data status..."
    
    STATUS=$(curl -s "$WEATHER_STATION_URL/api/data/status" | jq -r '.location_count, .data_info.data_age, .data_info.file_size_mb')
    
    if [ $? -eq 0 ] && [ "$STATUS" != "null" ]; then
        LOCATIONS=$(echo "$STATUS" | head -n 1)
        AGE=$(echo "$STATUS" | head -n 2 | tail -n 1)
        SIZE=$(echo "$STATUS" | tail -n 1)
        
        echo_info "Current status:"
        echo "  📍 Locations: $LOCATIONS"
        echo "  📅 Data age: $AGE"
        echo "  📦 File size: ${SIZE} MB"
    else
        echo_warning "Could not get current status"
    fi
}

# Function to trigger update
trigger_update() {
    echo_info "Triggering secure data update..."
    echo_info "This may take several minutes to fetch data for 240+ locations..."
    
    # Show spinner while updating
    {
        curl -X POST "$WEATHER_STATION_URL/api/data/force-update" \
             -H "X-API-Key: $API_KEY" \
             -H "Content-Type: application/json" \
             --max-time $TIMEOUT \
             -s > /tmp/update_response.json 2>&1
    } &
    
    UPDATE_PID=$!
    
    # Show spinner
    spin='-\|/'
    i=0
    while kill -0 $UPDATE_PID 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${BLUE}⏳ Updating data... ${spin:$i:1}${NC}"
        sleep 0.5
    done
    
    wait $UPDATE_PID
    UPDATE_EXIT_CODE=$?
    
    printf "\r                              \r"  # Clear spinner
    
    if [ $UPDATE_EXIT_CODE -eq 0 ]; then
        if [ -f /tmp/update_response.json ]; then
            SUCCESS=$(jq -r '.success' /tmp/update_response.json 2>/dev/null || echo "false")
            MESSAGE=$(jq -r '.message' /tmp/update_response.json 2>/dev/null || echo "Unknown response")
            
            if [ "$SUCCESS" = "true" ]; then
                echo_success "Data update completed successfully!"
                echo_info "Message: $MESSAGE"
            else
                echo_error "Update failed: $MESSAGE"
                exit 1
            fi
        else
            echo_success "Update completed (no response file)"
        fi
    else
        echo_error "Update request failed (exit code: $UPDATE_EXIT_CODE)"
        if [ -f /tmp/update_response.json ]; then
            echo_warning "Response: $(cat /tmp/update_response.json)"
        fi
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/update_response.json
}

# Function to show new status
show_new_status() {
    echo_info "Checking updated status..."
    sleep 2  # Wait for status to update
    
    get_current_status
}

# Main execution
main() {
    echo_info "Weather Station Data Update Script"
    echo_info "=================================="
    echo
    
    # Validate API key
    if [ -z "$API_KEY" ]; then
        echo_error "API_KEY environment variable is not set"
        exit 1
    fi
    
    # Check prerequisites
    if ! command -v curl >/dev/null 2>&1; then
        echo_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        echo_warning "jq is recommended for better output formatting"
    fi
    
    # Execute update sequence
    check_health
    get_current_status
    echo
    trigger_update
    echo
    show_new_status
    
    echo
    echo_success "Update process completed!"
    echo_info "You can check the web interface at: $WEATHER_STATION_URL"
}

# Run main function
main "$@"