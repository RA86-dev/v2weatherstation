#!/bin/bash

#
# Open-Meteo Manager v2.0
# =======================
# Complete Open-Meteo container and cron management script
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONTAINER_NAME="weather_station_openmeteo"
IMAGE_NAME="ghcr.io/open-meteo/open-meteo:latest"
DATA_VOLUME="open-meteo-data"
LOG_FILE="$SCRIPT_DIR/openmeteo_manager.log"

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

echo_header() {
    echo
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE} $1 ${NC}"
    echo -e "${PURPLE}============================================${NC}"
    echo
}

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    log "INFO: $1"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
    log "ERROR: $1"
}

echo_step() {
    echo -e "${CYAN}🔧 $1${NC}"
    log "STEP: $1"
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    echo_success "Docker is available and running"
}

# Check if container exists
container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Check if container is running
container_running() {
    docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Create Open-Meteo container
create_container() {
    echo_step "Creating Open-Meteo container..."
    
    # Create data volume if it doesn't exist
    if ! docker volume ls | grep -q "$DATA_VOLUME"; then
        docker volume create "$DATA_VOLUME"
        echo_success "Created data volume: $DATA_VOLUME"
    fi
    
    # Remove existing container if it exists
    if container_exists; then
        echo_warning "Removing existing container..."
        docker rm -f "$CONTAINER_NAME" || true
    fi
    
    # Create and start the container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 8080:8080 \
        -v "${DATA_VOLUME}:/app/data" \
        -e RUST_LOG=info \
        --health-cmd="curl -f http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0 || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=5 \
        --health-start-period=120s \
        "$IMAGE_NAME"
    
    echo_success "Open-Meteo container created and started"
    echo_info "Container name: $CONTAINER_NAME"
    echo_info "API URL: http://localhost:8080"
    echo_info "Data volume: $DATA_VOLUME"
}

# Start container
start_container() {
    if container_running; then
        echo_warning "Container is already running"
        return 0
    fi
    
    if container_exists; then
        echo_step "Starting existing container..."
        docker start "$CONTAINER_NAME"
    else
        echo_step "Container doesn't exist, creating new one..."
        create_container
        return 0
    fi
    
    echo_success "Container started successfully"
}

# Stop container
stop_container() {
    if ! container_running; then
        echo_warning "Container is not running"
        return 0
    fi
    
    echo_step "Stopping Open-Meteo container..."
    docker stop "$CONTAINER_NAME"
    echo_success "Container stopped"
}

# Remove container and volume
remove_container() {
    echo_step "Removing Open-Meteo container and data..."
    
    # Stop and remove container
    if container_exists; then
        docker rm -f "$CONTAINER_NAME" || true
        echo_success "Container removed"
    fi
    
    # Remove volume
    if docker volume ls | grep -q "$DATA_VOLUME"; then
        read -p "Remove data volume (all weather data will be lost)? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker volume rm "$DATA_VOLUME"
            echo_success "Data volume removed"
        else
            echo_info "Data volume preserved"
        fi
    fi
}

# Check container status
status_container() {
    echo_header "Open-Meteo Container Status"
    
    if container_running; then
        echo_success "Container is RUNNING"
        
        # Show container details
        echo
        echo_info "Container Details:"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Check health
        echo
        echo_info "Health Status:"
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
        case $HEALTH in
            "healthy")
                echo_success "Container is healthy"
                ;;
            "unhealthy")
                echo_error "Container is unhealthy"
                ;;
            "starting")
                echo_warning "Container is starting (health check pending)"
                ;;
            *)
                echo_warning "Health status: $HEALTH"
                ;;
        esac
        
        # Test API
        echo
        echo_info "API Test:"
        if curl -s -f "http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0" > /dev/null; then
            echo_success "API is responding"
        else
            echo_error "API is not responding"
        fi
        
    elif container_exists; then
        echo_warning "Container exists but is NOT RUNNING"
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
    else
        echo_error "Container does NOT EXIST"
    fi
    
    # Show volume info
    echo
    echo_info "Data Volume:"
    if docker volume ls | grep -q "$DATA_VOLUME"; then
        VOLUME_SIZE=$(docker system df -v | grep "$DATA_VOLUME" | awk '{print $3}' || echo "unknown")
        echo_success "Volume exists: $DATA_VOLUME (Size: $VOLUME_SIZE)"
    else
        echo_warning "Data volume does not exist"
    fi
}

# Initialize weather data
init_data() {
    echo_header "Initializing Weather Data"
    
    if ! container_running; then
        echo_error "Container is not running. Start it first with: $0 start"
        exit 1
    fi
    
    # Wait for container to be healthy
    echo_step "Waiting for Open-Meteo to be ready..."
    for i in {1..30}; do
        if curl -s -f "http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0" > /dev/null; then
            echo_success "Open-Meteo is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo_error "Open-Meteo did not become ready in time"
            exit 1
        fi
        echo_info "Waiting... ($i/30)"
        sleep 10
    done
    
    echo_step "Downloading weather model data..."
    echo_info "This will download several GB of weather data and may take 30+ minutes"
    echo
    
    # Download essential weather models
    MODELS=(
        "ecmwf_ifs025:ECMWF IFS Global (best accuracy)"
        "ncep_gfs025:NOAA GFS Global (reliable)"
        "meteofrance_arpege_world025:MeteoFrance ARPEGE World"
    )
    
    VARIABLES="temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,pressure_msl,surface_pressure,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,rain,showers,snowfall"
    
    for model_info in "${MODELS[@]}"; do
        IFS=':' read -r model_name model_desc <<< "$model_info"
        
        echo_step "Downloading $model_desc..."
        if docker run --rm \
            -v "${DATA_VOLUME}:/app/data" \
            "$IMAGE_NAME" \
            sync "$model_name" "$VARIABLES"; then
            echo_success "Downloaded $model_desc"
        else
            echo_warning "Failed to download $model_desc (continuing...)"
        fi
        echo
    done
    
    echo_success "Weather data initialization complete!"
    echo_info "Open-Meteo is now ready with local weather data"
}

# Setup cron job for data updates
setup_cron() {
    echo_header "Setting Up Automatic Data Updates"
    
    UPDATE_SCRIPT="$SCRIPT_DIR/$(basename "$0")"
    CRON_ENTRY="0 2 * * 0 $UPDATE_SCRIPT update >> $LOG_FILE 2>&1"
    
    echo_info "Setting up weekly cron job..."
    echo_info "Schedule: Every Sunday at 2:00 AM"
    echo_info "Command: $UPDATE_SCRIPT update"
    echo_info "Log file: $LOG_FILE"
    echo
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
        echo_warning "Cron job already exists for this script"
        echo
        read -p "Replace existing cron job? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Skipping cron job setup"
            return 0
        fi
        
        # Remove existing cron job
        crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab -
        echo_info "Removed existing cron job"
    fi
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    
    echo_success "Cron job added successfully!"
    echo
    echo_info "Cron job details:"
    echo "  Command: $UPDATE_SCRIPT update"
    echo "  Schedule: Every Sunday at 2:00 AM"
    echo "  Log file: $LOG_FILE"
    echo
    echo_info "You can view current cron jobs with: crontab -l"
    echo_info "You can view update logs with: tail -f $LOG_FILE"
}

# Remove cron job
remove_cron() {
    echo_header "Removing Automatic Data Updates"
    
    UPDATE_SCRIPT="$SCRIPT_DIR/$(basename "$0")"
    
    if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
        crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab -
        echo_success "Cron job removed"
    else
        echo_warning "No cron job found for this script"
    fi
}

# Update weather data (for cron job)
update_data() {
    echo_header "Updating Weather Data"
    log "Starting scheduled weather data update"
    
    if ! container_running; then
        echo_error "Container is not running. Cannot update data."
        log "ERROR: Container not running during scheduled update"
        exit 1
    fi
    
    # Simple update - just restart container to refresh data
    echo_step "Restarting container to refresh data..."
    docker restart "$CONTAINER_NAME"
    
    # Wait for it to be healthy again
    echo_step "Waiting for container to be ready..."
    sleep 60
    
    for i in {1..10}; do
        if curl -s -f "http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0" > /dev/null; then
            echo_success "Container is ready after restart"
            log "SUCCESS: Scheduled update completed"
            return 0
        fi
        sleep 30
    done
    
    echo_error "Container did not become ready after restart"
    log "ERROR: Container failed to become ready after scheduled update"
    exit 1
}

# Show logs
show_logs() {
    if container_exists; then
        echo_header "Open-Meteo Container Logs"
        docker logs --tail 50 -f "$CONTAINER_NAME"
    else
        echo_error "Container does not exist"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo_header "Open-Meteo Manager v2.0"
    echo "Complete Open-Meteo container and cron management"
    echo
    echo "Usage: $0 {command}"
    echo
    echo "Container Management:"
    echo "  start         - Start Open-Meteo container (create if needed)"
    echo "  stop          - Stop Open-Meteo container"
    echo "  restart       - Restart Open-Meteo container"
    echo "  remove        - Remove container and optionally data volume"
    echo "  status        - Show container status and health"
    echo "  logs          - Show container logs (follow mode)"
    echo
    echo "Data Management:"
    echo "  init          - Initialize weather data (download models)"
    echo "  update        - Update weather data (for cron)"
    echo
    echo "Cron Management:"
    echo "  setup-cron    - Setup automatic weekly data updates"
    echo "  remove-cron   - Remove automatic data updates"
    echo "  show-cron     - Show current cron jobs"
    echo
    echo "Information:"
    echo "  help          - Show this help"
    echo
    echo "Examples:"
    echo "  $0 start                    # Start Open-Meteo"
    echo "  $0 init                     # Download weather data"
    echo "  $0 setup-cron               # Setup weekly updates"
    echo "  $0 status                   # Check status"
    echo
}

# Main function
main() {
    case "${1:-help}" in
        "start")
            echo_header "Starting Open-Meteo"
            check_docker
            start_container
            echo
            echo_success "Open-Meteo is starting!"
            echo_info "Wait 2-3 minutes for initialization"
            echo_info "API will be available at: http://localhost:8080"
            echo_info "Check status with: $0 status"
            echo_info "Initialize data with: $0 init"
            ;;
        "stop")
            echo_header "Stopping Open-Meteo"
            check_docker
            stop_container
            ;;
        "restart")
            echo_header "Restarting Open-Meteo"
            check_docker
            stop_container
            sleep 5
            start_container
            ;;
        "remove")
            echo_header "Removing Open-Meteo"
            check_docker
            remove_container
            ;;
        "status")
            check_docker
            status_container
            ;;
        "logs")
            echo_header "Open-Meteo Logs"
            check_docker
            show_logs
            ;;
        "init")
            check_docker
            init_data
            ;;
        "update")
            check_docker
            update_data
            ;;
        "setup-cron")
            setup_cron
            ;;
        "remove-cron")
            remove_cron
            ;;
        "show-cron")
            echo_header "Current Cron Jobs"
            crontab -l 2>/dev/null | grep -E "($(basename "$0")|open.?meteo)" || echo "No cron jobs found"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            echo_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"