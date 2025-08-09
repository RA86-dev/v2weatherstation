"""
Weather Station Configuration
============================
Centralized configuration management for the weather station application.
"""

import os
from typing import Optional, Dict, Any


class WeatherStationConfig:
    """Configuration class for Weather Station application"""
    
    def __init__(self):
        # Server configuration
        self.HOST = os.getenv('WEATHER_STATION_HOST', '0.0.0.0')
        self.PORT = int(os.getenv('WEATHER_STATION_PORT', '8110'))
        self.DEBUG = os.getenv('DEBUG', 'false').lower() == 'true'
        
        # API configuration
        self.OPEN_METEO_BASE_URL = os.getenv(
            'OPEN_METEO_API_URL', 
            'https://api.open-meteo.com'
        )
        self.USE_SELF_HOSTED = True  # Always use self-hosted Open-Meteo instance
        self.SELF_HOSTED_PORT = int(os.getenv('SELF_HOSTED_PORT', '8080'))
        
        # Data configuration
        self.DATA_UPDATE_INTERVAL = int(os.getenv('DATA_UPDATE_INTERVAL', '604800'))  # 7 days in seconds
        self.DATA_RETENTION_DAYS = int(os.getenv('DATA_RETENTION_DAYS', '16'))  # Maximum 16 days of data
        self.PAST_DAYS = int(os.getenv('PAST_DAYS', '16'))  # Fetch last 16 days
        self.MAX_RETRIES = int(os.getenv('MAX_RETRIES', '3'))
        self.RETRY_DELAY = int(os.getenv('RETRY_DELAY', '5'))
        self.AUTO_UPDATE_ENABLED = os.getenv('AUTO_UPDATE_ENABLED', 'true').lower() == 'true'
        
        # File paths
        self.ASSETS_DIR = os.path.join(os.path.dirname(__file__), 'assets')
        self.UPDATERS_DIR = os.path.join(os.path.dirname(__file__), 'updaters')
        self.LOCATIONS_FILE = os.path.join(self.UPDATERS_DIR, 'geolocations.json')
        self.OUTPUT_DATA_FILE = os.path.join(self.ASSETS_DIR, 'output_data.json')
        
        # Logging configuration
        self.LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO').upper()
        self.LOG_FORMAT = os.getenv(
            'LOG_FORMAT', 
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # Security settings
        self.ALLOWED_HOSTS = self._parse_list(os.getenv('ALLOWED_HOSTS', '*'))
        self.CORS_ORIGINS = self._parse_list(os.getenv('CORS_ORIGINS', '*'))
        
        # Application metadata
        self.APP_NAME = "Weather Station"
        self.APP_VERSION = "2.0.0"
        self.APP_DESCRIPTION = "Modern weather data visualization and analytics platform"
        
    def _parse_list(self, value: str) -> list:
        """Parse comma-separated string into list"""
        if not value or value == '*':
            return ['*']
        return [item.strip() for item in value.split(',') if item.strip()]
    
    @property
    def effective_open_meteo_url(self) -> str:
        """Get the effective Open-Meteo API URL based on configuration"""
        if self.USE_SELF_HOSTED:
            return "https://backend.weatherbox.org"
        return self.OPEN_METEO_BASE_URL
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary for logging/debugging"""
        return {
            'server': {
                'host': self.HOST,
                'port': self.PORT,
                'debug': self.DEBUG
            },
            'api': {
                'open_meteo_url': self.effective_open_meteo_url,
                'use_self_hosted': self.USE_SELF_HOSTED,
                'self_hosted_port': self.SELF_HOSTED_PORT
            },
            'data': {
                'update_interval': self.DATA_UPDATE_INTERVAL,
                'past_days': self.PAST_DAYS,
                'max_retries': self.MAX_RETRIES,
                'retry_delay': self.RETRY_DELAY
            },
            'app': {
                'name': self.APP_NAME,
                'version': self.APP_VERSION,
                'description': self.APP_DESCRIPTION
            }
        }
    
    def validate(self) -> bool:
        """Validate configuration settings"""
        errors = []
        
        # Validate port ranges
        if not (1 <= self.PORT <= 65535):
            errors.append(f"Invalid port: {self.PORT}")
        
        if not (1 <= self.SELF_HOSTED_PORT <= 65535):
            errors.append(f"Invalid self-hosted port: {self.SELF_HOSTED_PORT}")
        
        # Validate data settings
        if self.PAST_DAYS < 1 or self.PAST_DAYS > 365:
            errors.append(f"Invalid past_days: {self.PAST_DAYS} (must be 1-365)")
        
        if self.MAX_RETRIES < 0:
            errors.append(f"Invalid max_retries: {self.MAX_RETRIES}")
        
        if self.RETRY_DELAY < 0:
            errors.append(f"Invalid retry_delay: {self.RETRY_DELAY}")
        
        # Validate directories exist or can be created
        try:
            os.makedirs(self.ASSETS_DIR, exist_ok=True)
            os.makedirs(self.UPDATERS_DIR, exist_ok=True)
        except Exception as e:
            errors.append(f"Cannot create directories: {e}")
        
        if errors:
            print("Configuration validation errors:")
            for error in errors:
                print(f"  - {error}")
            return False
        
        return True


# Global configuration instance
config = WeatherStationConfig()


def get_config() -> WeatherStationConfig:
    """Get the global configuration instance"""
    return config


def load_config_from_env() -> WeatherStationConfig:
    """Load configuration from environment variables"""
    return WeatherStationConfig()


def print_config_summary(cfg: Optional[WeatherStationConfig] = None) -> None:
    """Print a summary of the current configuration"""
    if cfg is None:
        cfg = config
    
    print(f"Weather Station Configuration Summary")
    print(f"====================================")
    print(f"Application: {cfg.APP_NAME} v{cfg.APP_VERSION}")
    print(f"Server: {cfg.HOST}:{cfg.PORT} (Debug: {cfg.DEBUG})")
    print(f"Open-Meteo API: {cfg.effective_open_meteo_url}")
    print(f"Self-hosted: {cfg.USE_SELF_HOSTED}")
    print(f"Data update interval: {cfg.DATA_UPDATE_INTERVAL}s")
    print(f"Historical data: {cfg.PAST_DAYS} days")
    print(f"Assets directory: {cfg.ASSETS_DIR}")
    print(f"Updaters directory: {cfg.UPDATERS_DIR}")
    print()


if __name__ == "__main__":
    # Print configuration when run directly
    print_config_summary()
    
    # Validate configuration
    if config.validate():
        print("✓ Configuration is valid")
    else:
        print("✗ Configuration has errors")
        exit(1)