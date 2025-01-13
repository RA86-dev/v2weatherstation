print('DataProcessing.')
import requests
import json
import time
from urllib.parse import quote
output = {}
def fetch_weather_and_pressure_information(city,location):
    URL = f"https://api.open-meteo.com/v1/forecast?latitude={quote(str(location[0]))}&longitude={quote(str(location[1]))}&hourly=temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,precipitation_probability,precipitation,rain,showers,snowfall,snow_depth,pressure_msl,surface_pressure,cloud_cover,cloud_cover_low,vapour_pressure_deficit,wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_speed_180m,wind_direction_10m,wind_direction_80m,wind_direction_120m,wind_gusts_10m,temperature_180m,soil_temperature_0cm,soil_moisture_0_to_1cm,soil_moisture_9_to_27cm&past_days=92"
    response = requests.get(URL)
    if not response.ok:
        print('Could not fetch information for this city')
        print(f'{response.text}')
        time.sleep(60)
        return {}
    return response.json()
p = open('geolocations.json','r')
data = json.load(p)
for city, location in data.items():
    c =fetch_weather_and_pressure_information(city,location)
    output[city] = c
with open('output_data.json','w') as write:
    json.dump(fp=write,obj=output)