#!/bin/bash

# Weather Station Installer v2.0
# Enhanced installer with Open-Meteo self-hosting support
# =======================================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_PORT=8110
DEFAULT_OPEN_METEO_PORT=8080
WEATHER_STATION_DIR="weather_station"
SELF_HOST_OPTION="n"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}Weather Station Installer v2.0 [Linux/macOS]${NC}"
echo -e "${BLUE}Enhanced with Open-Meteo self-hosting support${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install system dependencies
install_system_deps() {
    echo -e "${YELLOW}Installing system dependencies...${NC}"
    
    if command_exists apt-get; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv tmux curl
        if [[ "$SELF_HOST_OPTION" == "y" ]]; then
            # Install Docker for Open-Meteo
            if ! command_exists docker; then
                echo -e "${YELLOW}Installing Docker for Open-Meteo...${NC}"
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
                echo -e "${GREEN}Docker installed! Please log out and back in to use Docker without sudo.${NC}"
            fi
        fi
    elif command_exists yum; then
        # CentOS/RHEL
        sudo yum update -y
        sudo yum install -y python3 python3-pip tmux curl
    elif command_exists brew; then
        # macOS
        brew install python3 tmux
        if [[ "$SELF_HOST_OPTION" == "y" ]] && ! command_exists docker; then
            brew install --cask docker
        fi
    else
        echo -e "${RED}Unsupported package manager. Please install Python 3, pip, and tmux manually.${NC}"
        exit 1
    fi
}

# Function to setup Python environment
setup_python_env() {
    echo -e "${YELLOW}Setting up Python virtual environment...${NC}"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Python dependencies
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip install -r requirements.txt
    
    echo -e "${GREEN}✓ Python environment setup complete${NC}"
}

# Function to setup Open-Meteo self-hosting
setup_open_meteo() {
    if [[ "$SELF_HOST_OPTION" != "y" ]]; then
        return
    fi
    
    echo -e "${YELLOW}Setting up Open-Meteo self-hosting...${NC}"
    
    # Make item.sh executable
    chmod +x ${WEATHER_STATION_DIR}/item.sh
    
    # Create Open-Meteo setup script
    cat > "setup_open_meteo.sh" << 'EOF'
#!/bin/bash
echo "Setting up Open-Meteo self-hosted instance..."
echo "This will download weather data and start the Open-Meteo API server."
echo ""

cd weather_station
./item.sh

echo ""
echo "Starting Open-Meteo API server..."
docker run -d --name open-meteo-api \
    -v open-meteo-data:/app/data \
    -p 8080:8080 \
    --restart unless-stopped \
    ghcr.io/open-meteo/open-meteo

echo "Open-Meteo API is now running on http://localhost:8080"
echo "You can test it with: curl \"http://localhost:8080/v1/forecast?latitude=40.7&longitude=-74.0&hourly=temperature_2m\""
EOF
    
    chmod +x setup_open_meteo.sh
    echo -e "${GREEN}✓ Open-Meteo setup script created${NC}"
}

# Function to update weather data
update_weather_data() {
    echo -e "${YELLOW}Updating weather data...${NC}"
    
    cd ${WEATHER_STATION_DIR}/updaters
    
    # Run the weather data update script
    python3 update_weather_information.py
    
    # Move the output to the assets directory
    if [ -f "output_data.json" ]; then
        mv output_data.json ../assets/
        echo -e "${GREEN}✓ Weather data updated successfully${NC}"
    else
        echo -e "${RED}Warning: output_data.json not found. Please run the update manually.${NC}"
    fi
    
    cd ../..
}

# Function to create run scripts
create_run_scripts() {
    echo -e "${YELLOW}Creating run scripts...${NC}"
    
    # Create main run script
    cat > "run_weather_station.sh" << EOF
#!/bin/bash
echo "Starting Weather Station v2.0..."
echo "=================================="

# Activate virtual environment
source venv/bin/activate

# Start the Weather Station
echo "Weather Station running on http://localhost:${DEFAULT_PORT}"
echo "Press Ctrl+C to stop"
echo ""

cd ${WEATHER_STATION_DIR}
python3 index.py
EOF
    
    # Create development script with tmux
    cat > "run_dev.sh" << EOF
#!/bin/bash
echo "Starting Weather Station in development mode..."

# Create new tmux session
tmux new-session -d -s weather-station

# Split window for weather station
tmux send-keys -t weather-station 'source venv/bin/activate && cd ${WEATHER_STATION_DIR} && python3 index.py' Enter

# Split window for logs if self-hosting
if [[ "$SELF_HOST_OPTION" == "y" ]]; then
    tmux split-window -h -t weather-station
    tmux send-keys -t weather-station 'docker logs -f open-meteo-api' Enter
fi

# Attach to session
tmux attach-session -t weather-station
EOF
    
    # Create update script
    cat > "update_data.sh" << 'EOF'
#!/bin/bash
echo "Updating weather data..."
source venv/bin/activate
cd weather_station/updaters
python3 update_weather_information.py
if [ -f "output_data.json" ]; then
    mv output_data.json ../assets/
    echo "✓ Data updated successfully"
else
    echo "✗ Update failed"
fi
EOF
    
    # Make scripts executable
    chmod +x run_weather_station.sh run_dev.sh update_data.sh
    
    echo -e "${GREEN}✓ Run scripts created${NC}"
}

# Function to show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo ""
    echo -e "${BLUE}Available commands:${NC}"
    echo -e "  ${GREEN}./run_weather_station.sh${NC}  - Start the Weather Station"
    echo -e "  ${GREEN}./run_dev.sh${NC}              - Start in development mode (tmux)"
    echo -e "  ${GREEN}./update_data.sh${NC}          - Update weather data"
    
    if [[ "$SELF_HOST_OPTION" == "y" ]]; then
        echo -e "  ${GREEN}./setup_open_meteo.sh${NC}      - Setup Open-Meteo self-hosting"
        echo ""
        echo -e "${BLUE}Open-Meteo Integration:${NC}"
        echo -e "  Run ./setup_open_meteo.sh to download weather data and start the API"
        echo -e "  Open-Meteo API will be available at: http://localhost:${DEFAULT_OPEN_METEO_PORT}"
    fi
    
    echo ""
    echo -e "${BLUE}Weather Station will be available at: http://localhost:${DEFAULT_PORT}${NC}"
    echo ""
    echo -e "${YELLOW}To get started:${NC}"
    echo -e "  1. ${GREEN}./update_data.sh${NC}           # Update weather data"
    if [[ "$SELF_HOST_OPTION" == "y" ]]; then
        echo -e "  2. ${GREEN}./setup_open_meteo.sh${NC}      # Setup Open-Meteo (optional)"
    fi
    echo -e "  $(if [[ "$SELF_HOST_OPTION" == "y" ]]; then echo "3"; else echo "2"; fi). ${GREEN}./run_weather_station.sh${NC}     # Start the application"
    echo ""
}

# Main installation flow
main() {
    echo -e "${BLUE}Installation Options:${NC}"
    echo -e "  Port for Weather Station: ${GREEN}${DEFAULT_PORT}${NC}"
    
    # Ask about Open-Meteo self-hosting
    echo ""
    read -p "Do you want to enable Open-Meteo self-hosting? (y/N): " SELF_HOST_OPTION
    SELF_HOST_OPTION=$(echo "$SELF_HOST_OPTION" | tr '[:upper:]' '[:lower:]') # lowercase
    
    if [[ "$SELF_HOST_OPTION" == "y" ]]; then
        echo -e "  Open-Meteo API Port: ${GREEN}${DEFAULT_OPEN_METEO_PORT}${NC}"
        echo -e "  ${YELLOW}Note: Docker will be installed for Open-Meteo${NC}"
    fi
    
    echo ""
    read -p "Proceed with installation? (Y/n): " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$confirm" == "n" ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Install system dependencies
    install_system_deps
    
    # Setup Python environment
    setup_python_env
    
    # Setup Open-Meteo if requested
    setup_open_meteo
    
    # Update weather data
    update_weather_data
    
    # Create run scripts
    create_run_scripts
    
    # Show completion message
    show_completion
}

# Run main function
main "$@"
