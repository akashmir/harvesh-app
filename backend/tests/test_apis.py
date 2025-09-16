import requests

print("Testing APIs...")
apis = [
    ('Crop', '8080'),
    ('Weather', '5005'), 
    ('Market', '5004'),
    ('Soil', '5006'),
    ('Multilingual', '5007'),
    ('Disease', '5008'),
    ('Sustainability', '5009'),
    ('Rotation', '5010'),
    ('Offline', '5011'),
    ('Integrated', '5012')
]

for name, port in apis:
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=2)
        print(f"{name}: {response.status_code}")
    except:
        print(f"{name}: Not running")
