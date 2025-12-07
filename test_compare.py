"""
Compare browser API response with Python requests
"""

from playwright.sync_api import sync_playwright
import requests
import json

STOP_CODES = ["1029", "1052", "1049", "1051"]

def compare_responses():
    """Compare what browser gets vs what Python requests gets"""
    
    print("="*70)
    print("COMPARING BROWSER VS PYTHON REQUESTS")
    print("="*70)
    
    with sync_playwright() as p:
        browser = p.firefox.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        
        # Load page
        page.goto("https://telematics.oasth.gr/en/")
        page.wait_for_timeout(2000)
        
        # Get credentials
        token = page.evaluate("() => window.token")
        cookies = context.cookies()
        phpsessid = next((c['value'] for c in cookies if c['name'] == 'PHPSESSID'), None)
        
        print(f"\n🔑 Credentials:")
        print(f"  Token: {token[:30]}...")
        print(f"  PHPSESSID: {phpsessid}")
        
        # Test each stop code
        for stop_code in STOP_CODES:
            print(f"\n{'='*70}")
            print(f"TESTING STOP: {stop_code}")
            print(f"{'='*70}")
            
            # Method 1: Browser fetch
            print("\n📡 Method 1: Browser fetch API...")
            browser_result = page.evaluate(f"""
                async () => {{
                    try {{
                        const resp = await fetch('/api/?act=getStopArrivals&p1={stop_code}', {{
                            method: 'GET',
                            headers: {{
                                'X-Requested-With': 'XMLHttpRequest',
                                'X-CSRF-Token': window.token
                            }}
                        }});
                        const data = await resp.json();
                        return {{ status: resp.status, data: data }};
                    }} catch(e) {{
                        return {{ error: e.message }};
                    }}
                }}
            """)
            print(f"  Browser result: {browser_result}")
            
            # Method 2: Python requests with same credentials
            print("\n📡 Method 2: Python requests...")
            session = requests.Session()
            session.headers.update({
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
                'Accept': 'application/json, text/javascript, */*; q=0.01',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-Token': token,
                'Origin': 'https://telematics.oasth.gr',
                'Referer': 'https://telematics.oasth.gr/en/',
            })
            session.cookies.set('PHPSESSID', phpsessid, domain='telematics.oasth.gr')
            
            resp = session.get(f"https://telematics.oasth.gr/api/?act=getStopArrivals&p1={stop_code}")
            print(f"  Python result: {resp.status_code} - {resp.text[:100]}")
            
            # Method 3: Try stopCode parameter name
            print("\n📡 Method 3: Try with stopCode parameter...")
            resp2 = session.get(f"https://telematics.oasth.gr/api/?act=getStopArrivals&stopCode={stop_code}")
            print(f"  Result: {resp2.status_code} - {resp2.text[:100]}")
        
        browser.close()

if __name__ == "__main__":
    compare_responses()
