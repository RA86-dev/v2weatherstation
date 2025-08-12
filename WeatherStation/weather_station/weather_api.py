"""
Simple Weather API Client
"""

import json
import requests
import logging
from typing import Dict, List, Optional
from config import config

logger = logging.getLogger(__name__)

class WeatherAPI:
    def __init__(self):
        self.api_url = config.OPEN_METEO_API_URL
        self.session = requests.Session()
        self.session.timeout = 10

    def load_locations(self) -> Dict:
        """Load city locations from JSON file"""
        try:
            with open(config.LOCATIONS_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load locations: {e}")
            return {}

    def get_weather_for_city(self, city: str, lat: float, lon: float) -> Optional[Dict]:
        """Get weather data for a single city"""
        try:
            params = {
                'latitude': lat,
                'longitude': lon,
                'hourly': 'temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m',
                'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum',
                'current_weather': 'true',
                'timezone': 'auto'
            }
            
            url = f"{self.api_url}/v1/forecast"
            response = self.session.get(url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            # Extract current weather
            current = data.get('current_weather', {})
            
            # Extract daily data (first day)
            daily = data.get('daily', {})
            today_max = daily.get('temperature_2m_max', [None])[0]
            today_min = daily.get('temperature_2m_min', [None])[0]
            today_precipitation = daily.get('precipitation_sum', [None])[0]
            
            return {
                'city': city,
                'temperature': current.get('temperature'),
                'humidity': None,  # Not available in current_weather
                'precipitation': today_precipitation,
                'wind_speed': current.get('windspeed'),
                'wind_direction': current.get('winddirection'),
                'weather_code': current.get('weathercode'),
                'temperature_max': today_max,
                'temperature_min': today_min,
                'timestamp': current.get('time'),
                'latitude': lat,
                'longitude': lon
            }
            
        except Exception as e:
            logger.error(f"Failed to get weather for {city}: {e}")
            return None

    def get_weather_for_multiple_cities(self, limit: int = 50) -> List[Dict]:
        """Get weather data for multiple cities"""
        locations = self.load_locations()
        if not locations:
            return []
        
        results = []
        count = 0
        
        for city, coords in locations.items():
            if count >= limit:
                break
            
            # Handle both array format [lat, lon] and dict format
            if isinstance(coords, list) and len(coords) >= 2:
                lat, lon = coords[0], coords[1]
            elif isinstance(coords, dict):
                lat = coords.get('latitude')
                lon = coords.get('longitude')
            else:
                logger.warning(f"Invalid coordinates format for {city}: {coords}")
                continue
                
            weather_data = self.get_weather_for_city(city, lat, lon)
            
            if weather_data:
                results.append(weather_data)
                
            count += 1
        
        return results

    def get_all_locations(self) -> List[Dict]:
        """Get list of all available locations"""
        locations = self.load_locations()
        result = []
        
        for city, coords in locations.items():
            # Handle both array format [lat, lon] and dict format
            if isinstance(coords, list) and len(coords) >= 2:
                lat, lon = coords[0], coords[1]
                state, country = '', 'US'
            elif isinstance(coords, dict):
                lat = coords.get('latitude')
                lon = coords.get('longitude') 
                state = coords.get('state', '')
                country = coords.get('country', 'US')
            else:
                continue
                
            result.append({
                'city': city,
                'latitude': lat,
                'longitude': lon,
                'state': state,
                'country': country
            })
        
        return result

# Global instance
weather_api = WeatherAPI()