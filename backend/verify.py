import asyncio
import httpx
import json
import uuid

API_URL = "http://127.0.0.1:8000/api/v1"
FIREBASE_API_KEY = "AIzaSyCaOqblFA5yX0AEKZ8XWlEwQbnpemYrqAc"

async def run_verification():
    print("=== FUELIQ VERIFICATION SCRIPT ===")
    
    async with httpx.AsyncClient() as client:
        # 1. Create a Firebase User via REST
        print("\n--- 1. FIREBASE AUTH ---")
        email = f"test_{uuid.uuid4().hex[:8]}@example.com"
        password = "Password123!"
        print(f"Registering user: {email}")
        
        signup_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_API_KEY}"
        resp = await client.post(signup_url, json={"email": email, "password": password, "returnSecureToken": True})
        if resp.status_code != 200:
            print(f"FAILED TO CREATE FIREBASE USER: {resp.text}")
            return
            
        data = resp.json()
        uid = data['localId']
        token = f"mock_{uid}"
        print(f"Success! UID: {uid}")
        
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Sync User
        print("\n--- 2. SYNC USER ---")
        sync_payload = {
            "firebase_uid": uid,
            "email": email,
            "display_name": "Test User",
            "avatar_url": None
        }
        print(f"POST /auth/sync-user payload: {json.dumps(sync_payload)}")
        resp = await client.post(f"{API_URL}/auth/sync-user", json=sync_payload, headers=headers)
        print(f"Status: {resp.status_code}")
        print(f"Response: {json.dumps(resp.json(), indent=2)}")
        
        # 3. Create Vehicle
        print("\n--- 3. CREATE VEHICLE ---")
        vehicle_payload = {
            "make": "Toyota",
            "model": "Camry",
            "year": 2024,
            "fuel_type": "petrol",
            "tank_capacity_liters": 60.0,
            "vehicle_type": "car",
            "initial_odometer": 0
        }
        print(f"POST /vehicles payload: {json.dumps(vehicle_payload)}")
        resp = await client.post(f"{API_URL}/vehicles", json=vehicle_payload, headers=headers)
        print(f"Status: {resp.status_code}")
        v_data = resp.json()
        print(f"Response: {json.dumps(v_data, indent=2)}")
        vehicle_id = v_data['data']['id']
        
        # 4. Get Vehicles
        print("\n--- 4. GET VEHICLES (Garage Screen) ---")
        resp = await client.get(f"{API_URL}/vehicles", headers=headers)
        print(f"Status: {resp.status_code}")
        print(f"Response: {json.dumps(resp.json(), indent=2)}")
        
        # 5. Get Analytics
        print("\n--- 5. GET ANALYTICS ---")
        resp = await client.get(f"{API_URL}/vehicles/{vehicle_id}/analytics", headers=headers)
        print(f"Status: {resp.status_code}")
        print(f"Response: {json.dumps(resp.json(), indent=2)}")
        
        # 6. Get Notifications
        print("\n--- 6. GET NOTIFICATIONS ---")
        resp = await client.get(f"{API_URL}/notifications", headers=headers)
        print(f"Status: {resp.status_code}")
        print(f"Response: {json.dumps(resp.json(), indent=2)}")
        
        # 7. Logout
        print("\n--- 7. LOGOUT ---")
        resp = await client.post(f"{API_URL}/auth/logout", headers=headers)
        print(f"Status: {resp.status_code}")
        
if __name__ == "__main__":
    asyncio.run(run_verification())
