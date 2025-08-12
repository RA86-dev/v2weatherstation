"""
Simple Weather Station Configuration
"""

import os

class Config:
    # Server settings
    HOST = os.getenv('WEATHER_STATION_HOST', '0.0.0.0')
    PORT = int(os.getenv('WEATHER_STATION_PORT', '8110'))
    DEBUG = os.getenv('DEBUG', 'false').lower() == 'true'
    
    # API settings - SELF-HOSTED ONLY
    OPEN_METEO_API_URL = os.getenv('OPEN_METEO_API_URL', 'http://open-meteo:8080')
    
    # Paths
    ASSETS_DIR = os.path.join(os.path.dirname(__file__), 'assets')
    UPDATERS_DIR = os.path.join(os.path.dirname(__file__), 'updaters')
    LOCATIONS_FILE = os.path.join(UPDATERS_DIR, 'geolocations.json')

# Global config instance
config = Config()

# Legacy function for backward compatibility
def get_config():
    return config