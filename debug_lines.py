import requests
import json

STATIC_TOKEN = "e2287129f7a2bbae422f3673c4944d703b84a1cf71e189f869de7da527d01137"

def debug_lines():
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': STATIC_TOKEN,
        'Referer': 'https://telematics.oasth.gr/'
    })
    
    # 1. Get Lines
    print("Fetching Lines...")
    resp = session.post("https://telematics.oasth.gr/api/?act=webGetLines")
    if resp.status_code != 200:
        print(f"Failed to get lines: {resp.status_code}")
        return

    lines = resp.json()
    print(f"Found {len(lines)} lines. Sample:")
    print(json.dumps(lines[0], indent=2, ensure_ascii=False))
    
    # 2. Get Routes for the first line
    line_id = lines[0].get('LineID')
    print(f"\nFetching Routes for LineID {line_id}...")
    resp = session.post(f"https://telematics.oasth.gr/api/?act=webGetRoutes&p1={line_id}")
    
    if resp.status_code == 200:
        routes = resp.json()
        print(f"Found {len(routes)} routes. Sample:")
        print(json.dumps(routes[0], indent=2, ensure_ascii=False))
    else:
        print(f"Failed to get routes: {resp.status_code}")

if __name__ == "__main__":
    debug_lines()
