#Med6
import time
####
# WIP 
####
import json
import fastapi
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse
from fastapi.templating import Jinja2Templates
import os

logs = []

# prepare presets
print('Preparing Presets')
def generate_log(requests: fastapi.requests.Request, page: str):
    client_host = requests.client.host
    client_port = requests.client.port
    cookies = requests.cookies
    query_parameters = requests.query_params
    return {
        'text':f'{client_host}:{client_port} visited {page} with cookies {cookies} and query parameters {query_parameters} at {time.asctime()}'
    }
app = fastapi.FastAPI()
templates = Jinja2Templates(directory="templates")
# Route for serving files directly
@app.get("/assets/{filename}")
async def get_file(filename: str):
    file_path = os.path.join("assets", filename)
    if os.path.exists(file_path):
        return FileResponse(file_path)
    return {"error": "File not found"}
@app.get('/')
async def main(requests: fastapi.requests.Request):
    return fastapi.responses.FileResponse('assets/index.html')
@app.get('/comparison')
async def comparison_quick(requests: fastapi.requests.Request):
    return fastapi.responses.FileResponse('assets/comparison_quick.html')
@app.get('/intmap')
async def interactive_map(requests: fastapi.requests.Request):
    return fastapi.responses.FileResponse('assets/interactive_pressure_map.html')
@app.get('/license')
async def license(requests: fastapi.requests.Request):
    return fastapi.responses.FileResponse('assets/LICENSE.html')
@app.get('/favicon.ico')
async def favicon_item(requests: fastapi.requests.Request):
    return fastapi.responses.FileResponse('assets/favicon.ico')
@app.get('/weatherstat')
async def weatherstat(requests: fastapi.requests.Request):
    return fastapi.responses.FileResponse('assets/weather_statistics.html')
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app=app,host='0.0.0.0',port=8110)
