"""
OASTH Pure HTTP Authentication Test
====================================
Based on network capture findings:
1. PHPSESSID is set via Set-Cookie on first API call
2. Subsequent calls just need the cookie
3. X-Requested-With: XMLHttpRequest may be needed

This tests if we can replicate authentication WITHOUT a browser.
"""

import requests
import json
import hashlib

def test_pure_http_api():
    """Test pure HTTP API access without browser"""
    
    print("="*70)
    print("OASTH PURE HTTP API TEST")
    print("="*70)
    
    session = requests.Session()
    
    # Set up browser-like headers
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'X-Requested-With': 'XMLHttpRequest',
        'Origin': 'https://telematics.oasth.gr',
        'Referer': 'https://telematics.oasth.gr/en/',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-origin',
        'Connection': 'keep-alive'
    })
    
    # ============================================================
    # TEST 1: Initial GET to establish session
    # ============================================================
    print("\n📡 TEST 1: Initial page load...")
    resp = session.get("https://telematics.oasth.gr/en/")
    print(f"Status: {resp.status_code}")
    print(f"Cookies after GET: {session.cookies.get_dict()}")
    
    # ============================================================
    # TEST 2: Call isProduction API (first API call that sets cookie)
    # ============================================================
    print("\n📡 TEST 2: isProduction API call...")
    resp = session.get("https://telematics.oasth.gr/api/?act=isProduction")
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text}")
    print(f"Cookies after API: {session.cookies.get_dict()}")
    
    # ============================================================
    # TEST 3: Try webGetLangs
    # ============================================================
    print("\n📡 TEST 3: webGetLangs API call...")
    resp = session.post("https://telematics.oasth.gr/api/?act=webGetLangs")
    print(f"Status: {resp.status_code}")
    print(f"Response (first 200 chars): {resp.text[:200]}")
    
    # ============================================================
    # TEST 4: Try getStopArrivals (the main endpoint we need)
    # ============================================================
    print("\n📡 TEST 4: getStopArrivals for stop 3344...")
    resp = session.get("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344")
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text[:500]}")
    
    # ============================================================
    # TEST 5: Try POST version of getStopArrivals
    # ============================================================
    print("\n📡 TEST 5: getStopArrivals POST version...")
    resp = session.post("https://telematics.oasth.gr/api/?act=getStopArrivals&p1=3344")
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text[:500]}")
    
    # ============================================================
    # TEST 6: Try getStopBySIP (what the actual site uses)
    # ============================================================
    print("\n📡 TEST 6: getStopBySIP (site's actual endpoint)...")
    resp = session.post("https://telematics.oasth.gr/api/?act=getStopBySIP&sip=3344")
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text[:500]}")
    
    # ============================================================
    # TEST 7: List all available API endpoints
    # ============================================================
    print("\n📡 TEST 7: Trying various API endpoints...")
    endpoints = [
        "getStopArrivals",
        "webGetStopArrivals",
        "getStationArrivals",
        "getArrivalsByStop",
        "webGetStations",
        "webGetStops",
        "getRoutes",
        "webGetRoutes",
        "webGetLines",
    ]
    
    for endpoint in endpoints:
        resp = session.post(f"https://telematics.oasth.gr/api/?act={endpoint}")
        status = "✅" if resp.status_code == 200 and "error" not in resp.text.lower() else "❌"
        preview = resp.text[:80].replace('\n', ' ')
        print(f"  {status} {endpoint}: {resp.status_code} - {preview}")
    
    # ============================================================
    # TEST 8: Try webGetRoutes with stopCode
    # ============================================================
    print("\n📡 TEST 8: Testing endpoint discovery with stop code 3344...")
    test_endpoints = [
        ("webGetLines", {}),
        ("webGetStopArrivals", {"stopCode": "3344"}),
        ("getStopArrivals", {"stopCode": "3344"}),
        ("webGetStopArrivals", {"p1": "3344"}),
    ]
    
    for endpoint, data in test_endpoints:
        if data:
            resp = session.post(f"https://telematics.oasth.gr/api/?act={endpoint}", data=data)
        else:
            resp = session.post(f"https://telematics.oasth.gr/api/?act={endpoint}")
        status = "✅" if resp.status_code == 200 and len(resp.text) > 10 else "❌"
        print(f"  {status} {endpoint} {data}: {resp.status_code} - {resp.text[:100]}")
    
    print("\n" + "="*70)
    print("SESSION STATE")
    print("="*70)
    print(f"Final cookies: {session.cookies.get_dict()}")
    
    return session

if __name__ == "__main__":
    session = test_pure_http_api()
