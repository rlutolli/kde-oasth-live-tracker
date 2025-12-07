"""
OASTH Final Authentication Test
================================
Test if same session with extracted token works.
The token must be used with the SAME PHPSESSID that generated it.
"""

from playwright.sync_api import sync_playwright
import requests

def test_session_bound_token():
    """Test using session + token together from same context"""
    
    print("="*70)
    print("OASTH SESSION-BOUND TOKEN TEST")
    print("="*70)
    
    with sync_playwright() as p:
        browser = p.firefox.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        
        print("\n📡 Step 1: Load page...")
        page.goto("https://telematics.oasth.gr/en/")
        page.wait_for_timeout(2000)
        
        # Get token and session
        print("\n📡 Step 2: Extract token and PHPSESSID...")
        
        token = page.evaluate("() => window.token")
        cookies = context.cookies()
        phpsessid = next((c['value'] for c in cookies if c['name'] == 'PHPSESSID'), None)
        
        print(f"  Token: {token}")
        print(f"  PHPSESSID: {phpsessid}")
        
        # Now use this EXACT combination with requests
        print("\n📡 Step 3: Testing with requests library (same session)...")
        
        session = requests.Session()
        session.headers.update({
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest',
            'Origin': 'https://telematics.oasth.gr',
            'Referer': 'https://telematics.oasth.gr/en/',
            'X-CSRF-Token': token,
        })
        session.cookies.set('PHPSESSID', phpsessid, domain='telematics.oasth.gr')
        
        # Test various stops
        print("\n📡 Step 4: Testing getStopArrivals...")
        
        test_stops = ["100", "200", "1000", "2000", "3000", "3005", "3344"]
        
        for stop in test_stops:
            resp = session.get(f"https://telematics.oasth.gr/api/?act=getStopArrivals&p1={stop}")
            preview = resp.text[:80]
            status = "✅" if resp.status_code == 200 and "error" not in resp.text.lower() else "❌"
            print(f"  {status} Stop {stop}: {resp.status_code} - {preview}")
        
        # Try alternative endpoints that might give us arrivals
        print("\n📡 Step 5: Testing alternative arrival endpoints...")
        
        alt_endpoints = [
            ("getStopArrivals", "p1=100"),
            ("webGetStopArrivals", "stop_code=100"),
            ("getArrivalsBySIPStopId", "stop_id=100"),
            ("getArrivalsForStop", "stop=100"),
        ]
        
        for endpoint, params in alt_endpoints:
            resp = session.get(f"https://telematics.oasth.gr/api/?act={endpoint}&{params}")
            status = "✅" if resp.status_code == 200 and "error" not in resp.text.lower() else "❌"
            print(f"  {status} {endpoint}: {resp.status_code} - {resp.text[:60]}")
        
        # Try making the actual call from browser and comparing
        print("\n📡 Step 6: API call from browser context for comparison...")
        
        browser_result = page.evaluate("""
            async (stopCode) => {
                const resp = await $.ajax({
                    url: '/api/',
                    type: 'GET',
                    data: { act: 'getStopArrivals', p1: stopCode }
                });
                return resp;
            }
        """, "100")
        
        print(f"  Browser result for stop 100: {browser_result}")
        
        # Check what endpoints actually work from browser
        print("\n📡 Step 7: Browser API capability test...")
        
        endpoints_to_test = [
            "getStopArrivals",
            "webGetStopArrivals", 
            "getRouteArrivals",
        ]
        
        for endpoint in endpoints_to_test:
            try:
                result = page.evaluate(f"""
                    async () => {{
                        try {{
                            const resp = await $.ajax({{
                                url: '/api/',
                                type: 'GET',
                                data: {{ act: '{endpoint}', p1: '100' }}
                            }});
                            return {{ success: true, data: JSON.stringify(resp).substring(0, 100) }};
                        }} catch(e) {{
                            return {{ success: false, error: e.statusText || e.message }};
                        }}
                    }}
                """)
                print(f"  {endpoint}: {result}")
            except Exception as e:
                print(f"  {endpoint}: Error - {str(e)[:50]}")
        
        browser.close()

if __name__ == "__main__":
    test_session_bound_token()
