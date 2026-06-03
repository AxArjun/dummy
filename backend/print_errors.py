import json
import re

with open("verification_output.txt", "rb") as f:
    text = f.read().decode("utf-16le")
    
match = re.search(r"Status: 422\r?\nResponse: (\{.*?\})", text, re.DOTALL)
if match:
    data = json.loads(match.group(1))
    print(json.dumps(data, indent=2))
else:
    print("No 422 found")
