"""
OASTH Authentication Deep Dive - Network Capture & Analysis
============================================================
This script captures ALL network traffic to reverse-engineer the authentication flow.
"""

from playwright.sync_api import sync_playwright
import json
import hashlib
import re
from datetime import datetime

class NetworkCapture:
    def __init__(self):
        self.requests = []
        self.responses = []
        self.cookies = {}
        self.headers_seen = {}
        self.api_calls = []
        
    def capture(self, stop_code="3344"):
        """Capture all network traffic when accessing a stop"""
        
        print("="*70)
        print("OASTH AUTHENTICATION REVERSE-ENGINEERING")
        print("="*70)
        print(f"Start Time: {datetime.now()}")
        print(f"Target Stop: {stop_code}\n")
        
        with sync_playwright() as p:
            # Launch with full capabilities
            browser = p.firefox.launch(
                headless=True,
                args=["--no-sandbox"]
            )
            
            context = browser.new_context(
                viewport={"width": 1280, "height": 720}
            )
            
            page = context.new_page()
            
            # ============================================================
            # CAPTURE ALL REQUESTS
            # ============================================================
            def on_request(request):
                req_data = {
                    'url': request.url,
                    'method': request.method,
                    'headers': dict(request.headers),
                    'post_data': request.post_data,
                    'resource_type': request.resource_type,
                    'timestamp': str(datetime.now())
                }
                self.requests.append(req_data)
                
                # Track interesting headers
                for key, value in request.headers.items():
                    if key.lower() not in ['user-agent', 'accept', 'accept-language', 'accept-encoding']:
                        if key not in self.headers_seen:
                            self.headers_seen[key] = []
                        self.headers_seen[key].append(value)
                
                # Log API calls specifically
                if '/api/' in request.url or 'csrf' in request.url.lower():
                    self.api_calls.append(req_data)
                    print(f"📤 API REQUEST: {request.method} {request.url}")
                    if request.post_data:
                        print(f"   POST: {request.post_data[:200]}")
                    for h in ['x-csrf-token', 'x-requested-with', 'cookie', 'authorization']:
                        if h in [k.lower() for k in request.headers.keys()]:
                            print(f"   {h}: {request.headers.get(h, request.headers.get(h.title(), 'N/A'))[:100]}")
            
            # ============================================================
            # CAPTURE ALL RESPONSES
            # ============================================================
            def on_response(response):
                resp_data = {
                    'url': response.url,
                    'status': response.status,
                    'headers': dict(response.headers),
                    'timestamp': str(datetime.now())
                }
                
                # Capture cookies from Set-Cookie
                if 'set-cookie' in response.headers:
                    cookie_str = response.headers['set-cookie']
                    print(f"🍪 COOKIE SET: {cookie_str[:100]}")
                    # Parse cookie
                    if 'PHPSESSID' in cookie_str:
                        match = re.search(r'PHPSESSID=([^;]+)', cookie_str)
                        if match:
                            self.cookies['PHPSESSID'] = match.group(1)
                            print(f"   ✅ PHPSESSID captured: {match.group(1)}")
                
                # Capture API response bodies
                if '/api/' in response.url:
                    try:
                        body = response.text()
                        resp_data['body'] = body
                        print(f"📥 API RESPONSE: {response.status} {response.url}")
                        print(f"   Body: {body[:200]}")
                    except:
                        pass
                
                self.responses.append(resp_data)
            
            page.on('request', on_request)
            page.on('response', on_response)
            
            # ============================================================
            # STEP 1: Load the main page
            # ============================================================
            print("\n" + "-"*70)
            print("STEP 1: Loading main page to establish session...")
            print("-"*70)
            
            page.goto("https://telematics.oasth.gr/en/", timeout=30000)
            page.wait_for_timeout(3000)
            
            # Get cookies from browser context
            browser_cookies = context.cookies()
            print(f"\n🍪 Browser cookies after page load:")
            for c in browser_cookies:
                print(f"   {c['name']}: {c['value'][:50]}...")
                self.cookies[c['name']] = c['value']
            
            # ============================================================
            # STEP 2: Analyze JavaScript for CSRF token generation
            # ============================================================
            print("\n" + "-"*70)
            print("STEP 2: Extracting JavaScript-based tokens...")
            print("-"*70)
            
            # Try to execute JavaScript to find token generation
            try:
                # Check if there's a csrf token function or variable
                csrf_check = page.evaluate("""
                    () => {
                        let result = {};
                        
                        // Check common CSRF storage locations
                        if (window.csrf_token) result.csrf_token = window.csrf_token;
                        if (window.csrfToken) result.csrfToken = window.csrfToken;
                        if (document.querySelector('meta[name="csrf-token"]')) {
                            result.meta_csrf = document.querySelector('meta[name="csrf-token"]').content;
                        }
                        
                        // Check for any token in window
                        for (let key in window) {
                            if (key.toLowerCase().includes('token') || key.toLowerCase().includes('csrf')) {
                                try {
                                    result[key] = JSON.stringify(window[key]).substring(0, 100);
                                } catch(e) {}
                            }
                        }
                        
                        // Check localStorage
                        result.localStorage = {};
                        for (let i = 0; i < localStorage.length; i++) {
                            let key = localStorage.key(i);
                            result.localStorage[key] = localStorage.getItem(key);
                        }
                        
                        // Check sessionStorage
                        result.sessionStorage = {};
                        for (let i = 0; i < sessionStorage.length; i++) {
                            let key = sessionStorage.key(i);
                            result.sessionStorage[key] = sessionStorage.getItem(key);
                        }
                        
                        return result;
                    }
                """)
                print(f"JavaScript token analysis: {json.dumps(csrf_check, indent=2)}")
            except Exception as e:
                print(f"JS analysis error: {e}")
            
            # ============================================================
            # STEP 3: Trigger a search to capture API call
            # ============================================================
            print("\n" + "-"*70)
            print(f"STEP 3: Searching for stop {stop_code} to trigger API call...")
            print("-"*70)
            
            try:
                # Fill and submit search
                search_input = page.locator("#stopSearch")
                search_input.fill(stop_code)
                page.locator(".toSearchForStop").click()
                
                print("Search triggered, waiting for API call...")
                page.wait_for_timeout(5000)
                
            except Exception as e:
                print(f"Search error: {e}")
            
            # ============================================================
            # STEP 4: Capture final state
            # ============================================================
            print("\n" + "-"*70)
            print("STEP 4: Final state capture...")
            print("-"*70)
            
            # Get updated cookies
            browser_cookies = context.cookies()
            print(f"\n🍪 Final browser cookies:")
            for c in browser_cookies:
                print(f"   {c['name']}: {c['value']}")
                self.cookies[c['name']] = c['value']
            
            browser.close()
        
        # ============================================================
        # ANALYSIS
        # ============================================================
        self.analyze()
        
        return self
    
    def analyze(self):
        """Analyze captured data"""
        
        print("\n" + "="*70)
        print("ANALYSIS RESULTS")
        print("="*70)
        
        print(f"\n📊 Total requests: {len(self.requests)}")
        print(f"📊 API calls captured: {len(self.api_calls)}")
        print(f"📊 Unique headers seen: {len(self.headers_seen)}")
        
        print(f"\n🍪 COOKIES:")
        for name, value in self.cookies.items():
            print(f"   {name}: {value}")
            
            # Try SHA-256 hash
            if name == 'PHPSESSID':
                sha256_hash = hashlib.sha256(value.encode()).hexdigest()
                print(f"   SHA256(PHPSESSID): {sha256_hash}")
        
        print(f"\n📝 INTERESTING HEADERS:")
        for header, values in self.headers_seen.items():
            unique_values = list(set(values))[:3]
            print(f"   {header}: {unique_values}")
        
        print(f"\n🔌 API CALLS DETAILS:")
        for call in self.api_calls:
            print(f"\n   URL: {call['url']}")
            print(f"   Method: {call['method']}")
            if call['post_data']:
                print(f"   POST: {call['post_data'][:200]}")
            
            # Show auth-related headers
            for h in call['headers']:
                if any(k in h.lower() for k in ['csrf', 'token', 'auth', 'cookie', 'x-']):
                    print(f"   {h}: {call['headers'][h][:100]}")
        
        # Save full capture to file
        output = {
            'cookies': self.cookies,
            'headers_seen': {k: list(set(v))[:5] for k, v in self.headers_seen.items()},
            'api_calls': self.api_calls,
            'request_count': len(self.requests),
            'response_count': len(self.responses)
        }
        
        with open('/home/rlutolli/oasth_widget/capture_results.json', 'w') as f:
            json.dump(output, f, indent=2)
        
        print(f"\n💾 Full results saved to: capture_results.json")


if __name__ == "__main__":
    capture = NetworkCapture()
    capture.capture("3344")
