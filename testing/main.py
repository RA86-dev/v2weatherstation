_d = {}
import json

data = json.loads(open("cities.json","r").read())
for chunk in data[:250]:
    _d[chunk.get('city')] = [chunk.get('latitude'),chunk.get('longitude')]

with open('result.json','w') as write:
    json.dump(_d,write)