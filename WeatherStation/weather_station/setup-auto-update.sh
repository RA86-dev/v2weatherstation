#!/bin/bash
#
# Setup Automatic Weather Data Updates
# ===================================
# Sets up weekly cron job to update Open-Meteo weather data
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
    echo_info "Setting up automatic weather data updates"
    echo_info "========================================"
    echo
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    UPDATE_SCRIPT="$SCRIPT_DIR/update-openmeteo-data.sh"
    
    # Check if update script exists
    if [[ ! -f "$UPDATE_SCRIPT" ]]; then
        echo_error "Update script not found at: $UPDATE_SCRIPT"
        exit 1
    fi
    
    echo_success "Found update script at: $UPDATE_SCRIPT"
    
    # Create cron job entry (runs every Sunday at 2 AM)
    CRON_ENTRY="0 2 * * 0 $UPDATE_SCRIPT >> $SCRIPT_DIR/update.log 2>&1"
    
    echo_info "Setting up weekly cron job..."
    echo_info "Schedule: Every Sunday at 2:00 AM"
    echo_info "Log file: $SCRIPT_DIR/update.log"
    echo
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
        echo_warning "Cron job already exists for this script"
        echo
        read -p "Replace existing cron job? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Skipping cron job setup"
            exit 0
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
    echo "  Command: $UPDATE_SCRIPT"
    echo "  Schedule: Every Sunday at 2:00 AM"
    echo "  Log file: $SCRIPT_DIR/update.log"
    echo
    echo_info "You can view current cron jobs with: crontab -l"
    echo_info "You can view update logs with: tail -f $SCRIPT_DIR/update.log"
    echo
    
    # Test the update script once to make sure it works
    read -p "Test the update script now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Running test update..."
        if "$UPDATE_SCRIPT"; then
            echo_success "Test update completed successfully!"
        else
            echo_error "Test update failed. Check the script and try again."
            exit 1
        fi
    fi
    
    echo
    echo_success "Automatic weather data updates are now configured!"
    echo_info "Weather data will update every Sunday at 2:00 AM"
}

# Run main function
main "$@"