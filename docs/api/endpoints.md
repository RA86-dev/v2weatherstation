# API Endpoints

Complete reference for all Weather Station v2.0 API endpoints.

## Health & Status Endpoints

### Health Check
Check if the service is running and healthy.

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "timestamp": "2025-01-01T00:00:00Z",
  "data_status": {
    "live_data_enabled": true,
    "api_accessible": true,
    "last_update": "2025-01-01T00:00:00Z"
  }
}
```

**Status Codes:**
- `200` - Service is healthy
- `503` - Service is unhealthy

### API Status
Get comprehensive API and system status information.

```http
GET /api/status
```

**Response:**
```json
{
  "api_status": {
    "accessible": true,
    "response_time_ms": 45,
    "last_check": "2025-01-01T00:00:00Z"
  },
  "data_manager_status": {
    "running": true,
    "last_update": "2025-01-01T00:00:00Z",
    "cache_size": 240,
    "update_interval": 3600
  },
  "live_data_enabled": true,
  "self_hosted": true,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

### Configuration
Get public configuration information.

```http
GET /config
```

**Response:**
```json
{
  "app_name": "Weather Station v2.0",
  "app_version": "2.0.0",
  "api_url": "http://localhost:8080/v1",
  "self_hosted": true
}
```

## Weather Data Endpoints

### Get Weather Data
Retrieve weather data for multiple locations.

```http
GET /api/data/weather?limit={limit}
```

**Parameters:**
- `limit` (optional): Number of locations to return (1-300, default: 300)

**Example:**
```bash
curl "http://localhost:8110/api/data/weather?limit=50"
```

**Response:**
```json
{
  "data": {
    "New York": {
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "current_conditions": {
        "temperature": 22.5,
        "humidity": 65,
        "pressure": 1013.25,
        "wind_speed": 15.2,
        "wind_direction": 180,
        "precipitation": 0.0
      },
      "forecast": {
        "hourly": [...],
        "daily": [...]
      },
      "last_updated": "2025-01-01T00:00:00Z"
    }
  },
  "locations": ["New York", "Los Angeles", ...],
  "total_available": 240,
  "requested": 50,
  "fetched": 50,
  "live_data": true,
  "fetch_time_seconds": 0.45,
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

**Status Codes:**
- `200` - Success
- `400` - Invalid limit parameter
- `503` - Weather service unavailable

### Get Live City Weather
Get real-time weather data for a specific city.

```http
GET /api/data/live/{city}
```

**Parameters:**
- `city` (required): City name (URL encoded)

**Example:**
```bash
curl "http://localhost:8110/api/data/live/New%20York"
```

**Response:**
```json
{
  "city": "New York",
  "data": {
    "coordinates": {
      "latitude": 40.7128,
      "longitude": -74.0060
    },
    "current_conditions": {
      "temperature": 22.5,
      "humidity": 65,
      "pressure": 1013.25,
      "wind_speed": 15.2,
      "wind_direction": 180,
      "precipitation": 0.0,
      "conditions": "partly_cloudy"
    },
    "forecast": {
      "next_24h": [...],
      "next_7d": [...]
    }
  },
  "live_data": true,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

**Status Codes:**
- `200` - Success
- `404` - City not found
- `503` - Live data not enabled

### Get Current Conditions
Get current weather conditions for a specific city.

```http
GET /api/data/current/{city}
```

**Parameters:**
- `city` (required): City name (URL encoded)

**Example:**
```bash
curl "http://localhost:8110/api/data/current/Los%20Angeles"
```

**Response:**
```json
{
  "city": "Los Angeles",
  "current_conditions": {
    "temperature": 24.8,
    "feels_like": 26.2,
    "humidity": 68,
    "pressure": 1015.2,
    "wind_speed": 12.5,
    "wind_direction": 225,
    "wind_gust": 18.3,
    "precipitation": 0.0,
    "visibility": 16.0,
    "uv_index": 6,
    "conditions": "sunny",
    "description": "Clear sky"
  },
  "live_data": true,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

### Get Available Locations
Get list of all available weather locations.

```http
GET /api/data/locations
```

**Response:**
```json
{
  "locations": [
    "New York",
    "Los Angeles",
    "Chicago",
    "Houston",
    "Phoenix"
  ],
  "coordinates": {
    "New York": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "timezone": "America/New_York",
      "country": "US",
      "state": "NY"
    }
  },
  "total": 240,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

## Administrative Endpoints

### Force Data Update
Manually trigger a weather data update (requires authentication).

```http
POST /api/data/force-update
```

**Headers:**
```http
X-API-Key: your-api-key-here
```

**Example:**
```bash
curl -X POST http://localhost:8110/api/data/force-update \
  -H "X-API-Key: your-api-key"
```

**Response:**
```json
{
  "success": true,
  "message": "Data update completed successfully",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

**Status Codes:**
- `200` - Update successful
- `401` - Unauthorized (invalid API key)
- `500` - Update failed

### Get Data Status
Get detailed data manager status information.

```http
GET /api/data/status
```

**Response:**
```json
{
  "running": true,
  "last_update": "2025-01-01T00:00:00Z",
  "next_update": "2025-01-01T01:00:00Z",
  "update_interval": 3600,
  "cache_status": {
    "size": 240,
    "last_refresh": "2025-01-01T00:00:00Z",
    "hit_rate": 0.95
  },
  "debug_info": {
    "cache_exists": true,
    "cache_size": 240,
    "cache_timestamp": "2025-01-01T00:00:00Z",
    "last_update_check": "2025-01-01T00:00:00Z"
  }
}
```

## Debug Endpoints (Development Only)

These endpoints are only available when `WS_DEBUG=true`.

### Get API Key
Get the API key for administrative operations.

```http
GET /admin/api-key
```

**Response:**
```json
{
  "api_key": "your-32-character-api-key",
  "usage": "Use with X-API-Key header or Authorization: Bearer <key>",
  "example": "curl -X POST http://localhost:8110/api/data/force-update -H 'X-API-Key: your-api-key'"
}
```

### Get Access Logs
Get recent access logs.

```http
GET /logs?limit={limit}
```

**Parameters:**
- `limit` (optional): Number of log entries to return (default: 100)

**Response:**
```json
{
  "logs": [
    {
      "timestamp": "2025-01-01T00:00:00Z",
      "iso_timestamp": "2025-01-01T00:00:00Z",
      "client_host": "192.168.1.100",
      "client_port": 54321,
      "page": "home",
      "method": "GET",
      "user_agent": "Mozilla/5.0...",
      "referer": "",
      "query_params": {}
    }
  ],
  "total": 150
}
```

## Web Interface Endpoints

### Dashboard
Main weather dashboard.

```http
GET /
```

Returns the main HTML dashboard page.

### Weather Comparison
Weather data comparison page.

```http
GET /comparison
```

Returns the weather comparison HTML page.

### Interactive Map
Interactive pressure map page.

```http
GET /intmap
```

Returns the interactive map HTML page.

### Weather Statistics
Weather statistics page.

```http
GET /weatherstat
```

Returns the weather statistics HTML page.

### License Information
License information page.

```http
GET /license
```

Returns the license information page.

## Static Asset Endpoints

### Serve Assets
Serve static assets (CSS, JS, images).

```http
GET /assets/{filename}
```

**Example:**
```http
GET /assets/style.css
GET /assets/script.js
GET /assets/favicon.ico
```

### Favicon
Serve the site favicon.

```http
GET /favicon.ico
```

## Error Responses

All endpoints may return these common error responses:

### Bad Request (400)
```json
{
  "error": "bad_request",
  "message": "Invalid parameter: limit must be between 1 and 300",
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

### Unauthorized (401)
```json
{
  "error": "unauthorized",
  "message": "Valid API key required",
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

### Not Found (404)
```json
{
  "error": "not_found",
  "message": "City not found: InvalidCity",
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

### Service Unavailable (503)
```json
{
  "error": "service_unavailable",
  "message": "Weather service temporarily unavailable",
  "api_status": {
    "accessible": false,
    "error": "Connection timeout"
  },
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

### Internal Server Error (500)
```json
{
  "error": "internal_error",
  "message": "An unexpected error occurred",
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

## Rate Limiting Headers

All API responses include rate limiting headers:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
X-RateLimit-Window: 60
```

When rate limit is exceeded (429):
```json
{
  "error": "rate_limit_exceeded",
  "message": "API rate limit exceeded. Try again in 30 seconds.",
  "retry_after": 30,
  "timestamp": "2025-01-01T00:00:00Z"
}
```

## Next Steps

- [Authentication Guide](authentication.md)
- [Code Examples](examples.md)
- [Error Handling Best Practices](../guides/error-handling.md)
- [API Testing Guide](../development/testing.md)