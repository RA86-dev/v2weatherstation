"""
Simple Weather Station FastAPI App
"""

import time
import logging
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import config
from weather_api import weather_api

# Setup logging
logging.basicConfig(
    level=logging.DEBUG if config.DEBUG else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Weather Station v2.0",
    description="Simple weather data visualization platform",
    version="2.0.0"
)

# Add CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Mount static files
if Path(config.ASSETS_DIR).exists():
    app.mount("/assets", StaticFiles(directory=config.ASSETS_DIR), name="assets")

# Routes
@app.get("/")
async def home():
    """Serve the main dashboard"""
    index_path = Path(config.ASSETS_DIR) / "index.html"
    if index_path.exists():
        return FileResponse(index_path)
    return {"message": "Weather Station v2.0", "status": "running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        "version": "2.0.0",
        "api_url": config.OPEN_METEO_API_URL
    }

@app.get("/api/status")
async def api_status():
    """API status endpoint"""
    try:
        # Test API connection
        locations = weather_api.load_locations()
        total_locations = len(locations)
        
        return {
            "status": "operational",
            "api_url": config.OPEN_METEO_API_URL,
            "total_locations": total_locations,
            "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        }
    except Exception as e:
        logger.error(f"API status check failed: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error", 
                "message": str(e),
                "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            }
        )

@app.get("/api/data/weather")
async def get_weather_data(limit: int = 50):
    """Get weather data for multiple cities"""
    try:
        # Validate limit
        limit = max(1, min(limit, 100))  # Between 1 and 100
        
        logger.info(f"Fetching weather data for {limit} cities")
        
        # Check if locations load properly
        locations = weather_api.load_locations()
        if not locations:
            raise HTTPException(status_code=500, detail="No locations available - check geolocations.json")
        
        logger.info(f"Loaded {len(locations)} locations")
        weather_data = weather_api.get_weather_for_multiple_cities(limit)
        
        return {
            "data": weather_data,
            "count": len(weather_data),
            "limit": limit,
            "total_locations": len(locations),
            "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get weather data: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/api/data/live/{city}")
async def get_live_city_data(city: str):
    """Get live weather data for a specific city"""
    try:
        locations = weather_api.load_locations()
        
        if city not in locations:
            raise HTTPException(status_code=404, detail=f"City '{city}' not found")
        
        coords = locations[city]
        
        # Handle both array format [lat, lon] and dict format
        if isinstance(coords, list) and len(coords) >= 2:
            lat, lon = coords[0], coords[1]
        elif isinstance(coords, dict):
            lat = coords.get('latitude')
            lon = coords.get('longitude')
        else:
            raise HTTPException(status_code=500, detail=f"Invalid coordinates format for {city}")
        
        weather_data = weather_api.get_weather_for_city(city, lat, lon)
        
        if not weather_data:
            raise HTTPException(status_code=500, detail="Failed to fetch weather data")
        
        return weather_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get live data for {city}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/data/locations")
async def get_locations():
    """Get all available locations"""
    try:
        locations = weather_api.get_all_locations()
        return {
            "locations": locations,
            "count": len(locations),
            "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        }
    except Exception as e:
        logger.error(f"Failed to get locations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Additional page routes
@app.get("/comparison")
async def comparison_page():
    """Weather comparison page"""
    comparison_path = Path(config.ASSETS_DIR) / "comparison_quick.html"
    if comparison_path.exists():
        return FileResponse(comparison_path)
    return {"message": "Comparison page not found"}

@app.get("/intmap")
async def interactive_map():
    """Interactive pressure map"""
    map_path = Path(config.ASSETS_DIR) / "interactive_pressure_map.html"
    if map_path.exists():
        return FileResponse(map_path)
    return {"message": "Interactive map not found"}

@app.get("/weatherstat")
async def weather_statistics():
    """Weather statistics page"""
    stats_path = Path(config.ASSETS_DIR) / "weather_statistics.html"
    if stats_path.exists():
        return FileResponse(stats_path)
    return {"message": "Weather statistics page not found"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=config.HOST, port=config.PORT, log_level="info")