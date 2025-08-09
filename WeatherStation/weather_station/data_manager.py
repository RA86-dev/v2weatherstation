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
from typing import Dict, Optional, Tuple
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
            logger.info("Data needs updating on startup")
            self._perform_update()
        
        while not self.should_stop.is_set():
            try:
                if self.should_update_data():
                    logger.info("Performing scheduled data update")
                    self._perform_update()
                
                # Sleep for 1 hour between checks (more frequent than update interval)
                self.should_stop.wait(3600)  # Check every hour
                
            except Exception as e:
                logger.error(f"Error in update loop: {e}")
                self.should_stop.wait(300)  # Wait 5 minutes on error
    
    def should_update_data(self) -> bool:
        """Check if data needs updating based on age and retention policy"""
        try:
            data_info = self.get_data_info()
            if not data_info['exists']:
                logger.info("No data file found - update needed")
                return True
            
            age_seconds = data_info['age_seconds']
            max_age = self.config.DATA_RETENTION_DAYS * 24 * 3600  # Convert days to seconds
            
            # Update if data is older than retention policy OR older than update interval
            needs_update = (age_seconds > max_age) or (age_seconds > self.config.DATA_UPDATE_INTERVAL)
            
            if needs_update:
                logger.info(f"Data update needed - age: {age_seconds/3600:.1f}h, max_age: {max_age/3600:.1f}h")
            
            return needs_update
            
        except Exception as e:
            logger.error(f"Error checking if update needed: {e}")
            return True  # Update on error to be safe
    
    def get_data_info(self) -> Dict:
        """Get information about current data file"""
        data_file = Path(self.config.OUTPUT_DATA_FILE)
        
        if not data_file.exists():
            return {
                'exists': False,
                'size': 0,
                'modified': None,
                'age_seconds': float('inf'),
                'age_days': float('inf'),
                'is_valid': False,
                'record_count': 0
            }
        
        try:
            stat = data_file.stat()
            modified_time = datetime.fromtimestamp(stat.st_mtime)
            age_seconds = (datetime.now() - modified_time).total_seconds()
            age_days = age_seconds / (24 * 3600)
            
            # Try to load and validate data
            is_valid, record_count = self._validate_data_file(data_file)
            
            return {
                'exists': True,
                'size': stat.st_size,
                'modified': modified_time.isoformat(),
                'age_seconds': age_seconds,
                'age_days': age_days,
                'is_valid': is_valid,
                'record_count': record_count
            }
            
        except Exception as e:
            logger.error(f"Error getting data info: {e}")
            return {
                'exists': True,
                'size': 0,
                'modified': None,
                'age_seconds': float('inf'),
                'age_days': float('inf'),
                'is_valid': False,
                'record_count': 0
            }
    
    def _validate_data_file(self, data_file: Path) -> Tuple[bool, int]:
        """Validate data file structure and content"""
        try:
            with open(data_file, 'r') as f:
                data = json.load(f)
            
            if not isinstance(data, dict):
                return False, 0
            
            record_count = len(data)
            if record_count == 0:
                return False, 0
            
            # Check if at least one location has valid data structure
            for location, location_data in data.items():
                if not isinstance(location_data, dict):
                    continue
                    
                if 'hourly' not in location_data:
                    continue
                    
                hourly = location_data['hourly']
                if 'time' not in hourly or not hourly['time']:
                    continue
                    
                # Check if data is within retention period
                try:
                    latest_time = max(hourly['time'])
                    latest_datetime = datetime.fromisoformat(latest_time.replace('T', ' ').replace('Z', ''))
                    data_age_days = (datetime.now() - latest_datetime).days
                    
                    if data_age_days > self.config.DATA_RETENTION_DAYS:
                        logger.warning(f"Data is {data_age_days} days old, exceeds retention policy")
                        return False, record_count
                        
                except Exception as e:
                    logger.warning(f"Error parsing date from data: {e}")
                    continue
                
                # If we get here, at least one location has valid recent data
                return True, record_count
            
            return False, record_count
            
        except Exception as e:
            logger.error(f"Error validating data file: {e}")
            return False, 0
    
    def _perform_update(self):
        """Perform the actual data update"""
        try:
            logger.info("Starting weather data update...")
            
            updater_script = Path(self.config.UPDATERS_DIR) / "update_weather_information.py"
            if not updater_script.exists():
                logger.error(f"Update script not found: {updater_script}")
                return False
            
            # Build command with proper arguments
            cmd = [
                "python3",
                str(updater_script),
                "--past-days", str(self.config.PAST_DAYS),
                "--output", str(self.config.OUTPUT_DATA_FILE),
                "--retries", str(self.config.MAX_RETRIES),
                "--retry-delay", str(self.config.RETRY_DELAY)
            ]
            
            if self.config.USE_SELF_HOSTED:
                cmd.append("--self-hosted")
            else:
                cmd.extend(["--api-url", self.config.OPEN_METEO_BASE_URL])
            
            # Run the update script
            result = subprocess.run(
                cmd,
                cwd=self.config.UPDATERS_DIR,
                capture_output=True,
                text=True,
                timeout=1800  # 30 minutes timeout
            )
            
            if result.returncode == 0:
                logger.info("✓ Data update completed successfully")
                # Clear cache to force reload
                self._data_cache = None
                self._cache_timestamp = 0
                return True
            else:
                logger.error(f"Data update failed with code {result.returncode}")
                logger.error(f"STDOUT: {result.stdout}")
                logger.error(f"STDERR: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("Data update timed out after 30 minutes")
            return False
        except Exception as e:
            logger.error(f"Error performing data update: {e}")
            return False
    
    def force_update(self) -> bool:
        """Force an immediate data update"""
        logger.info("Forcing immediate data update")
        return self._perform_update()
    
    def load_weather_data(self) -> Optional[Dict]:
        """Load weather data with caching and validation"""
        # Check cache first (cache for 5 minutes)
        current_time = time.time()
        if (self._data_cache is not None and 
            current_time - self._cache_timestamp < 300):
            return self._data_cache
        
        try:
            data_file = Path(self.config.OUTPUT_DATA_FILE)
            if not data_file.exists():
                logger.warning("Weather data file not found")
                return None
            
            # Check if data is too old
            data_info = self.get_data_info()
            if data_info['age_days'] > self.config.DATA_RETENTION_DAYS:
                logger.warning(f"Weather data is {data_info['age_days']:.1f} days old, exceeds retention policy")
                # Try to update data automatically
                if self.config.AUTO_UPDATE_ENABLED:
                    logger.info("Attempting automatic data refresh")
                    if self._perform_update():
                        # Reload after update
                        data_file = Path(self.config.OUTPUT_DATA_FILE)
                    else:
                        return None
                else:
                    return None
            
            with open(data_file, 'r') as f:
                data = json.load(f)
            
            # Validate data structure
            if not isinstance(data, dict) or len(data) == 0:
                logger.error("Invalid weather data structure")
                return None
            
            # Filter data to only include recent entries within retention period
            filtered_data = self._filter_old_data(data)
            
            # Update cache
            self._data_cache = filtered_data
            self._cache_timestamp = current_time
            
            logger.info(f"Loaded weather data for {len(filtered_data)} locations")
            return filtered_data
            
        except Exception as e:
            logger.error(f"Error loading weather data: {e}")
            return None
    
    def _filter_old_data(self, data: Dict) -> Dict:
        """Filter out data older than retention policy"""
        filtered_data = {}
        cutoff_date = datetime.now() - timedelta(days=self.config.DATA_RETENTION_DAYS)
        
        for location, location_data in data.items():
            try:
                if 'hourly' not in location_data or 'time' not in location_data['hourly']:
                    continue
                
                hourly_data = location_data['hourly']
                time_list = hourly_data['time']
                
                if not time_list:
                    continue
                
                # Find indices of data within retention period
                valid_indices = []
                for i, time_str in enumerate(time_list):
                    try:
                        # Parse ISO format time string
                        dt = datetime.fromisoformat(time_str.replace('T', ' ').replace('Z', ''))
                        if dt >= cutoff_date:
                            valid_indices.append(i)
                    except Exception:
                        continue
                
                if not valid_indices:
                    logger.warning(f"No recent data for {location}")
                    continue
                
                # Filter all hourly data arrays
                filtered_hourly = {}
                for key, values in hourly_data.items():
                    if isinstance(values, list) and len(values) > max(valid_indices):
                        filtered_hourly[key] = [values[i] for i in valid_indices]
                    else:
                        filtered_hourly[key] = values
                
                # Copy location data with filtered hourly data
                filtered_location_data = location_data.copy()
                filtered_location_data['hourly'] = filtered_hourly
                filtered_data[location] = filtered_location_data
                
            except Exception as e:
                logger.warning(f"Error filtering data for {location}: {e}")
                continue
        
        return filtered_data
    
    def get_status(self) -> Dict:
        """Get current status of data manager"""
        data_info = self.get_data_info()
        
        return {
            'auto_update_enabled': self.config.AUTO_UPDATE_ENABLED,
            'update_interval_hours': self.config.DATA_UPDATE_INTERVAL / 3600,
            'retention_days': self.config.DATA_RETENTION_DAYS,
            'background_thread_running': self.update_thread and self.update_thread.is_alive(),
            'data_info': data_info,
            'needs_update': self.should_update_data(),
            'cache_active': self._data_cache is not None
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