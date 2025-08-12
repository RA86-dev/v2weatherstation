# API Overview

The Weather Station v2.0 provides a comprehensive RESTful API for accessing weather data, managing the system, and integrating with external applications.

## Base URL

```
http://localhost:8110/api
```

For production deployments, replace `localhost:8110` with your server's domain and port.

## API Versioning

The API uses URL-based versioning. The current version is embedded in the base path:

```
GET /api/data/weather    # Current version
```

## Authentication

### Public Endpoints
Most data endpoints are publicly accessible and don't require authentication:
- `/api/data/weather`
- `/api/data/locations`
- `/api/data/live/{city}`
- `/api/status`
- `/health`

### Protected Endpoints
Administrative endpoints require API key authentication:
- `/api/data/force-update`
- `/admin/*` (debug mode only)

### API Key Authentication

Include your API key in requests using one of these methods:

**Header (Recommended):**
```http
X-API-Key: your-api-key-here
```

**Bearer Token:**
```http
Authorization: Bearer your-api-key-here
```

**Example:**
```bash
curl -X POST http://localhost:8110/api/data/force-update \
  -H "X-API-Key: your-api-key-here"
```

## Response Format

All API responses use JSON format with consistent structure:

### Success Response
```json
{
  "data": { ... },
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

### Error Response
```json
{
  "error": "Error type",
  "message": "Detailed error description",
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

## HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Access denied |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

## Rate Limiting

The API implements rate limiting to ensure fair usage:

- **Public endpoints**: 100 requests per minute per IP
- **Authenticated endpoints**: 1000 requests per minute per API key

Rate limit headers are included in responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Data Models

### Weather Data
```json
{
  "city_name": {
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
      "conditions": "partly_cloudy"
    },
    "forecast": {
      "hourly": [...],
      "daily": [...]
    },
    "last_updated": "2025-01-01T00:00:00Z"
  }
}
```

### Location Data
```json
{
  "city_name": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "timezone": "America/New_York",
    "country": "US",
    "state": "NY"
  }
}
```

### Status Data
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "uptime": 86400,
  "data_sources": {
    "live_data": true,
    "self_hosted": true,
    "api_url": "http://localhost:8080/v1"
  },
  "statistics": {
    "total_requests": 1234,
    "cache_hits": 567,
    "error_count": 0
  }
}
```

## Error Handling

### Error Types

| Error Type | Description | Resolution |
|------------|-------------|------------|
| `validation_error` | Invalid request parameters | Check parameter format and values |
| `authentication_error` | Invalid or missing API key | Verify API key |
| `rate_limit_error` | Too many requests | Wait and retry |
| `service_unavailable` | Weather service down | Check service status |
| `internal_error` | Server error | Contact support |

### Error Details
```json
{
  "error": "validation_error",
  "message": "Invalid city name format",
  "details": {
    "field": "city",
    "value": "invalid-city-123",
    "expected": "Valid city name (letters, spaces, hyphens)"
  },
  "timestamp": "2025-01-01T00:00:00Z",
  "request_id": "req_1234567890"
}
```

## CORS Support

The API supports Cross-Origin Resource Sharing (CORS) for web applications:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Key
```

For production, configure specific origins in the `WS_CORS_ORIGINS` environment variable.

## SDK and Libraries

### JavaScript/TypeScript
```bash
npm install @weatherstation/api-client
```

```javascript
import WeatherStationAPI from '@weatherstation/api-client';

const api = new WeatherStationAPI({
  baseURL: 'http://localhost:8110',
  apiKey: 'your-api-key'
});

const weather = await api.getWeatherData();
```

### Python
```bash
pip install weatherstation-api
```

```python
from weatherstation_api import WeatherStationClient

client = WeatherStationClient(
    base_url='http://localhost:8110',
    api_key='your-api-key'
)

weather_data = client.get_weather_data()
```

### cURL Examples
```bash
# Get all weather data
curl http://localhost:8110/api/data/weather

# Get specific city weather
curl http://localhost:8110/api/data/live/New%20York

# Get API status
curl http://localhost:8110/api/status

# Force data update (requires API key)
curl -X POST http://localhost:8110/api/data/force-update \
  -H "X-API-Key: your-api-key"
```

## OpenAPI Specification

The complete API specification is available in OpenAPI 3.0 format:

- **Swagger UI**: http://localhost:8110/docs (when available)
- **OpenAPI JSON**: http://localhost:8110/openapi.json
- **ReDoc**: http://localhost:8110/redoc

## Webhooks

Weather Station supports webhooks for real-time notifications:

### Webhook Events
- `weather.updated` - Weather data updated
- `weather.alert` - Weather alert issued
- `system.health` - System health change

### Webhook Configuration
```json
{
  "url": "https://your-app.com/webhooks/weather",
  "events": ["weather.updated"],
  "secret": "webhook-secret",
  "active": true
}
```

## Next Steps

- [Explore API Endpoints](endpoints.md)
- [Authentication Setup](authentication.md)
- [Code Examples](examples.md)
- [Rate Limiting Details](rate-limiting.md)