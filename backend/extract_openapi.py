import json
import codecs

with codecs.open('openapi.json', 'r', 'utf-16') as f:
    spec = json.load(f)

endpoints = [
    ('/api/v1/auth/sync-user', 'post'),
    ('/api/v1/vehicles', 'get'),
    ('/api/v1/vehicles', 'post'),
    ('/api/v1/vehicles/{vehicle_id}', 'put'),
    ('/api/v1/vehicles/{vehicle_id}', 'delete'),
    ('/api/v1/notifications', 'get'),
    ('/api/v1/users/me', 'get'),
    ('/api/v1/vehicles/{vehicle_id}/fuel-logs', 'get'),
    ('/api/v1/vehicles/{vehicle_id}/fuel-logs', 'post'),
]

for path, method_dict in spec['paths'].items():
    if 'analytics' in path:
        for m in method_dict.keys():
            endpoints.append((path, m))

for path, method in endpoints:
    if path in spec['paths'] and method in spec['paths'][path]:
        op = spec['paths'][path][method]
        print(f"\\n--- {method.upper()} {path} ---")
        if 'requestBody' in op:
            try:
                ref = op['requestBody']['content']['application/json']['schema'].get('$ref')
                print(f"Request: {ref}")
            except:
                print("Request: Inline/Unknown")
        else:
            print("Request: None")
            
        try:
            resp = op['responses']['200']['content']['application/json']['schema']
            if '$ref' in resp:
                print(f"Response: {resp['$ref']}")
            elif 'items' in resp and '$ref' in resp['items']:
                print(f"Response: Array of {resp['items']['$ref']}")
            else:
                print(f"Response: {resp}")
        except:
            print("Response: Unknown or not 200")
    else:
        print(f"\\n--- MISSING: {method.upper()} {path} ---")
