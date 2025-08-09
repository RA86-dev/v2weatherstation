"""
Weather Data Manager
====================
Handles automatic data updates, validation, and retention policies.
"""

import json
import os
import time
import asyncio
import threading
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Optional, Tuple, List
import logging
import subprocess

from config import get_config

logger = logging.getLogger(__name__)


class WeatherDataManager:
    """Manages weather data updates, validation, and retention"""
    
    def __init__(self):
        self.config = get_config()
        self.update_thread: Optional[threading.Thread] = None
        self.should_stop = threading.Event()
        self._last_update_check = 0
        self._data_cache = None
        self._cache_timestamp = 0
        
    def start_background_updates(self):
        """Start background thread for automatic data updates"""
        if not self.config.AUTO_UPDATE_ENABLED:
            logger.info("Automatic data updates disabled")
            return
            
        if self.update_thread and self.update_thread.is_alive():
            logger.warning("Background update thread already running")
            return
            
        logger.info(f"Starting automatic data updates every {self.config.DATA_UPDATE_INTERVAL} seconds")
        self.should_stop.clear()
        self.update_thread = threading.Thread(target=self._update_loop, daemon=True)
        self.update_thread.start()
    
    def stop_background_updates(self):
        """Stop background data updates"""
        if self.update_thread:
            logger.info("Stopping background data updates")
            self.should_stop.set()
            self.update_thread.join(timeout=10)
    
    def _update_loop(self):
        """Background update loop"""
        # Check immediately on startup if data needs updating
        if self.should_update_data():
            logger.info("Open-Meteo instance needs updating on startup")
            self._perform_update()
        
        while not self.should_stop.is_set():
            try:
                # Check for Open-Meteo instance updates (weekly)
                if self.should_update_data():
                    logger.info("Performing scheduled Open-Meteo instance update")
                    self._perform_update()
                
                # Refresh data cache if it's getting stale (every 10 minutes)
                current_time = time.time()
                if (self._data_cache is not None and 
                    current_time - self._cache_timestamp > 600):  # 10 minutes
                    logger.info("Refreshing data cache in background")
                    try:
                        locations = self._load_locations()
                        if locations:
                            fresh_data = self._fetch_data_in_batches(locations)
                            if fresh_data:
                                self._data_cache = fresh_data
                                self._cache_timestamp = current_time
                                logger.info(f"✓ Background cache refresh completed ({len(fresh_data)} locations)")
                    except Exception as e:
                        logger.warning(f"Background cache refresh failed: {e}")
                
                # Sleep for 10 minutes between checks
                self.should_stop.wait(600)  # Check every 10 minutes
                
            except Exception as e:
                logger.error(f"Error in update loop: {e}")
                self.should_stop.wait(300)  # Wait 5 minutes on error
    
    def should_update_data(self) -> bool:
        """Check if Open-Meteo instance needs updating"""
        try:
            # Always return True for weekly updates (controlled by _update_loop timing)
            # We only update the Open-Meteo instance, not local data files
            current_time = time.time()
            time_since_last_check = current_time - self._last_update_check
            
            # Update every week (604800 seconds)
            needs_update = time_since_last_check >= self.config.DATA_UPDATE_INTERVAL
            
            if needs_update:
                logger.info(f"Open-Meteo instance update needed - {time_since_last_check/3600:.1f}h since last update")
                self._last_update_check = current_time
            
            return needs_update
            
        except Exception as e:
            logger.error(f"Error checking if update needed: {e}")
            return True  # Update on error to be safe
    
    def get_data_info(self) -> Dict:
        """Get information about live data system"""
        try:
            # Check if Open-Meteo instance is accessible
            import requests
            response = requests.get(f"{self.config.effective_open_meteo_url}/v1/forecast?latitude=0&longitude=0", timeout=5)
            is_api_accessible = response.status_code == 200
            
            # Load location count
            locations = self._load_locations()
            location_count = len(locations)
            
            return {
                'exists': True,
                'live_fetch': True,
                'api_accessible': is_api_accessible,
                'api_url': self.config.effective_open_meteo_url,
                'location_count': location_count,
                'last_update_check': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(self._last_update_check)),
                'is_valid': is_api_accessible and location_count > 0,
                'record_count': location_count
            }
            
        except Exception as e:
            logger.error(f"Error getting data info: {e}")
            return {
                'exists': False,
                'live_fetch': True,
                'api_accessible': False,
                'api_url': self.config.effective_open_meteo_url,
                'location_count': 0,
                'last_update_check': 'Never',
                'is_valid': False,
                'record_count': 0
            }
    
    
    def _perform_update(self):
        """Perform Open-Meteo instance update (item.sh only)"""
        try:
            logger.info("Starting Open-Meteo instance update...")
            
            # Run item.sh to update the self-hosted Open-Meteo instance
            logger.info("Running item.sh to update Open-Meteo Docker container...")
            item_script = Path(self.config.UPDATERS_DIR).parent / "item.sh"
            if not item_script.exists():
                logger.error(f"item.sh script not found: {item_script}")
                return False
            
            # Run item.sh script
            item_result = subprocess.run(
                ["bash", str(item_script)],
                cwd=str(item_script.parent),
                capture_output=True,
                text=True,
                timeout=1800  # 30 minutes timeout
            )
            
            if item_result.returncode != 0:
                logger.error(f"item.sh failed with code {item_result.returncode}")
                logger.error(f"STDOUT: {item_result.stdout}")
                logger.error(f"STDERR: {item_result.stderr}")
                return False
            else:
                logger.info("✓ Open-Meteo instance update completed successfully")
                return True
                
        except subprocess.TimeoutExpired:
            logger.error("Open-Meteo update timed out after 30 minutes")
            return False
        except Exception as e:
            logger.error(f"Error updating Open-Meteo instance: {e}")
            return False
    
    def force_update(self) -> bool:
        """Force an immediate Open-Meteo instance update"""
        logger.info("Forcing immediate Open-Meteo instance update")
        return self._perform_update()
    
    def refresh_cache(self) -> bool:
        """Force immediate cache refresh"""
        try:
            logger.info("Forcing immediate cache refresh")
            locations = self._load_locations()
            if not locations:
                return False
                
            fresh_data = self._fetch_data_in_batches(locations)
            if fresh_data:
                self._data_cache = fresh_data
                self._cache_timestamp = time.time()
                logger.info(f"✓ Cache refresh completed ({len(fresh_data)} locations)")
                return True
            return False
        except Exception as e:
            logger.error(f"Cache refresh failed: {e}")
            return False
    
    def load_weather_data(self) -> Optional[Dict]:
        """Load weather data with smart caching for performance"""
        try:
            # Check if we have fresh cached data (cache for 15 minutes)
            current_time = time.time()
            if (self._data_cache is not None and 
                current_time - self._cache_timestamp < 900):  # 15 minutes cache
                logger.info(f"Returning cached data ({len(self._data_cache)} locations)")
                return self._data_cache
            
            logger.info("Fetching fresh data from Open-Meteo instance")
            
            # Load locations
            locations = self._load_locations()
            if not locations:
                logger.error("No locations to fetch data for")
                return None
            
            # Fetch data in parallel batches for performance
            live_data = self._fetch_data_in_batches(locations)
            
            if live_data:
                # Update cache
                self._data_cache = live_data
                self._cache_timestamp = current_time
                logger.info(f"✓ Cached fresh data for {len(live_data)} locations")
                return live_data
            else:
                logger.error("Failed to fetch any data")
                return None
            
        except Exception as e:
            logger.error(f"Error loading weather data: {e}")
            return None
    
    def _fetch_data_in_batches(self, locations: Dict) -> Dict:
        """Fetch data in parallel batches for better performance"""
        import concurrent.futures
        import threading
        
        live_data = {}
        data_lock = threading.Lock()
        
        def fetch_location_data(city_coords_pair):
            city, coordinates = city_coords_pair
            try:
                data = self._fetch_live_weather_data(city, coordinates)
                if data:
                    with data_lock:
                        live_data[city] = data
                    return True
                return False
            except Exception as e:
                logger.warning(f"Failed to fetch data for {city}: {e}")
                return False
        
        # Use ThreadPoolExecutor for concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(fetch_location_data, item) for item in locations.items()]
            
            # Wait for completion with progress tracking
            completed = 0
            for future in concurrent.futures.as_completed(futures):
                completed += 1
                if completed % 50 == 0:  # Log progress every 50 locations
                    logger.info(f"Progress: {completed}/{len(locations)} locations fetched")
        
        return live_data
    
    def _load_locations(self) -> Dict:
        """Load locations from geolocations.json"""
        try:
            with open(self.config.LOCATIONS_FILE, 'r') as f:
                locations = json.load(f)
            logger.info(f"Loaded {len(locations)} locations")
            return locations
        except Exception as e:
            logger.error(f"Error loading locations: {e}")
            return {}
    
    def _fetch_live_weather_data(self, city: str, coordinates: List[float]) -> Optional[Dict]:
        """Fetch live weather data for a specific city"""
        try:
            import requests
            
            latitude, longitude = coordinates
            
            # Weather parameters to fetch (using parameters available in ecmwf_ifs025 model)
            if self.config.USE_SELF_HOSTED:
                weather_params = [
                    'temperature_2m', 'relative_humidity_2m', 'apparent_temperature',
                    'rain', 'showers', 'snowfall', 'pressure_msl', 
                    'cloud_cover', 'wind_speed_180m', 'wind_direction_180m',
                    'visibility', 'uv_index'
                ]
            else:
                weather_params = [
                    'temperature_2m', 'relative_humidity_2m', 'dew_point_2m', 
                    'apparent_temperature', 'precipitation_probability', 'precipitation',
                    'rain', 'showers', 'snowfall', 'snow_depth', 'pressure_msl',
                    'surface_pressure', 'cloud_cover', 'vapour_pressure_deficit',
                    'wind_speed_10m', 'wind_direction_10m', 'soil_temperature_0cm',
                    'soil_moisture_0_to_1cm'
                ]
            
            # Build API URL for self-hosted instance
            params = {
                'latitude': latitude,
                'longitude': longitude,
                'hourly': ','.join(weather_params),
                'past_days': self.config.PAST_DAYS,
                'timezone': 'auto'
            }
            
            # Add model parameter for self-hosted instance
            if self.config.USE_SELF_HOSTED:
                params['models'] = 'ecmwf_ifs025'
            
            api_url = f"{self.config.effective_open_meteo_url}/v1/forecast"
            
            response = requests.get(api_url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Clean null values from the data
            if 'hourly' in data:
                cleaned_hourly = {}
                for param, values in data['hourly'].items():
                    if isinstance(values, list):
                        # Replace None/null with a reasonable default or remove
                        cleaned_values = []
                        for value in values:
                            if value is None:
                                cleaned_values.append(None)  # Keep None for proper array indexing
                            else:
                                cleaned_values.append(value)
                        cleaned_hourly[param] = cleaned_values
                    else:
                        cleaned_hourly[param] = values
                data['hourly'] = cleaned_hourly
            
            return data
            
        except Exception as e:
            logger.warning(f"Failed to fetch live data for {city}: {e}")
            return None
    
    
    def get_status(self) -> Dict:
        """Get current status of data manager"""
        data_info = self.get_data_info()
        
        # Cache status
        cache_age_minutes = 0
        cached_locations = 0
        if self._data_cache and self._cache_timestamp > 0:
            cache_age_minutes = (time.time() - self._cache_timestamp) / 60
            cached_locations = len(self._data_cache)
        
        return {
            'live_fetch_enabled': True,
            'auto_update_enabled': self.config.AUTO_UPDATE_ENABLED,
            'update_interval_hours': self.config.DATA_UPDATE_INTERVAL / 3600,
            'background_thread_running': self.update_thread and self.update_thread.is_alive(),
            'data_info': data_info,
            'needs_update': self.should_update_data(),
            'api_accessible': data_info.get('api_accessible', False),
            'location_count': data_info.get('location_count', 0),
            'cache_status': {
                'has_cache': self._data_cache is not None,
                'cached_locations': cached_locations,
                'cache_age_minutes': round(cache_age_minutes, 1),
                'cache_fresh': cache_age_minutes < 15
            }
        }


# Global instance
_data_manager: Optional[WeatherDataManager] = None


def get_data_manager() -> WeatherDataManager:
    """Get global data manager instance"""
    global _data_manager
    if _data_manager is None:
        _data_manager = WeatherDataManager()
    return _data_manager


def start_data_manager():
    """Start the global data manager"""
    manager = get_data_manager()
    manager.start_background_updates()
    return manager


def stop_data_manager():
    """Stop the global data manager"""
    global _data_manager
    if _data_manager:
        _data_manager.stop_background_updates()
        _data_manager = None