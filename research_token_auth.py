"""
OASTH Token Authentication Test
================================
Tests using the JavaScript-generated token for getStopArrivals
"""

from playwright.sync_api import sync_playwright
import requests
import hashlib

def test_token_auth():
    """Get the JavaScript token and use it for API calls"""
    
    print("="*70)
    print("OASTH TOKEN-BASED AUTHENTICATION TEST")
    print("="*70)
    
    with sync_playwright() as p:
        browser = p.firefox.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        
        # Load page
        print("\n📡 Loading page...")
        page.goto("https://telematics.oasth.gr/en/")
        page.wait_for_timeout(2000)
        
        # Get all JavaScript tokens and variables
        print("\n🔑 Extracting tokens and session data...")
        
        js_data = page.evaluate("""
            () => {
                let result = {
                    token: window.token || null,
                    csrf: window.csrf_token || null,
                    phpsessid: null,
                    all_tokens: {}
                };
                
                // Check document.cookie
                result.cookies = document.cookie;
                
                // Find anything that looks like a token
                for (let key in window) {
                    if (typeof window[key] === 'string' && 
                        (key.toLowerCase().includes('token') || 
                         key.toLowerCase().includes('csrf') ||
                         key.toLowerCase().includes('key') ||
                         key.toLowerCase().includes('secret'))) {
                        result.all_tokens[key] = window[key];
                    }
                }
                
                return result;
            }
        """)
        
        print(f"Token: {js_data.get('token')}")
        print(f"CSRF: {js_data.get('csrf')}")
        print(f"Cookies: {js_data.get('cookies')}")
        print(f"All tokens found: {js_data.get('all_tokens')}")
        
        # Get browser cookies
        cookies = context.cookies()
        cookies_dict = {c['name']: c['value'] for c in cookies}
        phpsessid = cookies_dict.get('PHPSESSID', '')
        print(f"\nPHPSESSID: {phpsessid}")
        
        # Calculate SHA256
        if phpsessid:
            sha256 = hashlib.sha256(phpsessid.encode()).hexdigest()
            print(f"SHA256(PHPSESSID): {sha256}")
            print(f"Token matches SHA256: {sha256 == js_data.get('token')}")
        
        # Now try to make an API call using intercepted auth
        print("\n" + "="*70)
        print("TESTING API WITH CAPTURED CREDENTIALS")
        print("="*70)
        
        session = requests.Session()
        session.headers.update({
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest',
            'Origin': 'https://telematics.oasth.gr',
            'Referer': 'https://telematics.oasth.gr/en/',
        })
        
        # Set captured cookies
        session.cookies.set('PHPSESSID', phpsessid, domain='telematics.oasth.gr')
        
        token = js_data.get('token')
        
        # Test 1: Without token header
        print("\n📡 Test 1: API call without token header...")
        resp = session.get("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344")
        print(f"Result: {resp.status_code} - {resp.text[:100]}")
        
        # Test 2: With X-CSRF-Token header
        print("\n📡 Test 2: API call with X-CSRF-Token header...")
        session.headers['X-CSRF-Token'] = token
        resp = session.get("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344")
        print(f"Result: {resp.status_code} - {resp.text[:100]}")
        
        # Test 3: With X-Token header
        print("\n📡 Test 3: API call with X-Token header...")
        session.headers['X-Token'] = token
        resp = session.get("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344")
        print(f"Result: {resp.status_code} - {resp.text[:100]}")
        
        # Test 4: With Authorization header
        print("\n📡 Test 4: API call with Authorization header...")
        session.headers['Authorization'] = f"Bearer {token}"
        resp = session.get("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344")
        print(f"Result: {resp.status_code} - {resp.text[:100]}")
        
        # Test 5: POST with token in body
        print("\n📡 Test 5: POST with token in body...")
        resp = session.post("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344",
                           data={'_token': token, 'csrf_token': token})
        print(f"Result: {resp.status_code} - {resp.text[:100]}")
        
        # Test 6: Let's try making the SAME call that the browser makes
        print("\n📡 Test 6: Replicating exact browser call from within page...")
        
        api_response = page.evaluate("""
            async () => {
                const resp = await fetch('/api/?act=getStopArrivals&p1=3344', {
                    method: 'GET',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                });
                return {
                    status: resp.status,
                    body: await resp.text()
                };
            }
        """)
        print(f"Result from browser context: {api_response}")
        
        # Test 7: Look for how the actual site makes the call
        print("\n📡 Test 7: Triggering search and observing actual API call...")
        
        # Capture requests when we search
        api_request_made = []
        
        def capture_request(request):
            if 'getStopArrivals' in request.url or 'arrivals' in request.url.lower():
                api_request_made.append({
                    'url': request.url,
                    'method': request.method,
                    'headers': dict(request.headers)
                })
        
        page.on('request', capture_request)
        
        # Do a search
        try:
            search_input = page.locator("#stopSearch")
            search_input.fill("3344")
            page.locator(".toSearchForStop").click()
            page.wait_for_timeout(5000)
        except Exception as e:
            print(f"Search error: {e}")
        
        print(f"\nAPI requests captured during search: {len(api_request_made)}")
        for req in api_request_made:
            print(f"\n  URL: {req['url']}")
            print(f"  Method: {req['method']}")
            for h in req['headers']:
                if any(k in h.lower() for k in ['token', 'auth', 'csrf', 'x-']):
                    print(f"  {h}: {req['headers'][h]}")
        
        browser.close()
        return js_data

if __name__ == "__main__":
    test_token_auth()
