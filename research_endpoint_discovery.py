"""
OASTH Deep Endpoint Discovery
==============================
The getStopArrivals endpoint specifically requires authorization.
Let's discover what makes it different and find alternative endpoints.
"""

import requests
import json

def deep_endpoint_discovery():
    """Discover all available API endpoints and their parameters"""
    
    print("="*70)
    print("OASTH DEEP API ENDPOINT DISCOVERY")
    print("="*70)
    
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'X-Requested-With': 'XMLHttpRequest',
        'Origin': 'https://telematics.oasth.gr',
        'Referer': 'https://telematics.oasth.gr/en/',
    })
    
    # Initialize session
    session.get("https://telematics.oasth.gr/en/")
    session.get("https://telematics.oasth.gr/api/?act=isProduction")
    
    print(f"\n🍪 Session established: {session.cookies.get_dict()}")
    
    # ============================================================
    # Comprehensive endpoint testing
    # ============================================================
    
    endpoints_to_test = [
        # Web endpoints (likely public)
        ("webGetLines", None),
        ("webGetRoutes", None),
        ("webGetStops", None),
        ("webGetLangs", None),
        ("webGetLinesWithMLInfo", None),
        
        # Route-related
        ("webGetRoutesForLine", {"line_code": "434"}),
        ("webGetStopsForRoute", {"route_code": "1"}),
        
        # Stop-related (our target)
        ("getStopBySIP", {"sip": "3344"}),
        ("getStopBySIP", {"p1": "3344"}),
        ("webGetStopArrivals", {"stop_code": "3344"}),
        ("webGetStopArrivals", {"stopCode": "3344"}),
        ("getStopArrivals", {"stop_code": "3344"}),
        ("getStopArrivals", {"stopCode": "3344"}),
        
        # Try with different parameter names
        ("getStopArrivals", None),  # URL params only
        ("webGetArrivalsByStop", {"stop_code": "3344"}),
        ("getArrivals", {"stop": "3344"}),
        
        # Real-time data
        ("getBusLocation", {"route_code": "1"}),
        ("getRoutePoints", {"route_code": "1"}),
        ("getVehicleLocations", None),
        
        # Other possibilities
        ("isProduction", None),
        ("getStopInfo", {"stop_code": "3344"}),
        ("webGetStopInfo", {"stop_code": "3344"}),
    ]
    
    print("\n" + "="*70)
    print("TESTING ALL ENDPOINTS")
    print("="*70)
    
    working_endpoints = []
    
    for endpoint, data in endpoints_to_test:
        # Build URL
        url = f"https://telematics.oasth.gr/api/?act={endpoint}"
        
        # Also test URL params
        if data:
            url_params = "&".join([f"{k}={v}" for k, v in data.items()])
            url_with_params = f"{url}&{url_params}"
        else:
            url_with_params = url
        
        # POST with body
        if data:
            resp_post_body = session.post(url, data=data)
        else:
            resp_post_body = session.post(url)
        
        # POST with URL params
        resp_post_url = session.post(url_with_params)
        
        # GET with URL params
        resp_get = session.get(url_with_params)
        
        # Analyze responses
        for method, resp in [("POST+body", resp_post_body), ("POST+url", resp_post_url), ("GET", resp_get)]:
            is_success = resp.status_code == 200 and "error" not in resp.text.lower()
            has_data = len(resp.text) > 10 and resp.text not in ["[]", "false", "true", "null"]
            
            if is_success and has_data:
                working_endpoints.append({
                    'endpoint': endpoint,
                    'method': method,
                    'data': data,
                    'response_preview': resp.text[:150]
                })
                print(f"✅ {method} {endpoint} {data}: {resp.text[:80]}")
            elif is_success:
                print(f"⬜ {method} {endpoint} {data}: {resp.status_code} - {resp.text[:50]}")
    
    print("\n" + "="*70)
    print("WORKING ENDPOINTS SUMMARY")
    print("="*70)
    
    for ep in working_endpoints:
        print(f"\n  Endpoint: {ep['endpoint']}")
        print(f"  Method: {ep['method']}")
        print(f"  Data: {ep['data']}")
        print(f"  Response: {ep['response_preview']}")
    
    # ============================================================
    # Try to find stop arrivals via alternative flow
    # ============================================================
    print("\n" + "="*70)
    print("TESTING ALTERNATIVE FLOW FOR STOP ARRIVALS")
    print("="*70)
    
    # Get lines first
    lines_resp = session.post("https://telematics.oasth.gr/api/?act=webGetLines")
    lines = lines_resp.json()
    print(f"\n📊 Found {len(lines)} bus lines")
    
    # Try to find routes for a common line (e.g., line 01)
    print("\n🔍 Getting routes for line 434 (01 Evkarpia-Sklaveniths)...")
    routes_resp = session.post("https://telematics.oasth.gr/api/?act=webGetRoutesForLine", 
                               data={"line_code": "434"})
    print(f"Response: {routes_resp.text[:300]}")
    
    # Try different line
    print("\n🔍 Getting routes for line with URL param...")
    routes_resp2 = session.post("https://telematics.oasth.gr/api/?act=webGetRoutesForLine&line_code=434")
    print(f"Response: {routes_resp2.text[:300]}")
    
    # Try stops for a route
    print("\n🔍 Getting stops for route...")
    if routes_resp.status_code == 200:
        try:
            routes = routes_resp.json()
            if routes and len(routes) > 0:
                route_code = routes[0].get('RouteCode', routes[0].get('route_code', ''))
                print(f"   Testing with route_code: {route_code}")
                stops_resp = session.post("https://telematics.oasth.gr/api/?act=webGetStopsForRoute",
                                         data={"route_code": route_code})
                print(f"   Stops response: {stops_resp.text[:300]}")
        except:
            pass
    
    # ============================================================
    # Try webGetStopArrivals with route context
    # ============================================================
    print("\n" + "="*70)
    print("TESTING STOP ARRIVALS WITH ROUTE CONTEXT")
    print("="*70)
    
    test_params = [
        {"stop_code": "3344"},
        {"stopCode": "3344"},
        {"stop_id": "3344"},
        {"stopId": "3344"},
        {"sip": "3344"},
        {"code": "3344"},
        {"p1": "3344"},
    ]
    
    for params in test_params:
        resp = session.post("https://telematics.oasth.gr/api/?act=webGetStopArrivals", data=params)
        print(f"  webGetStopArrivals {params}: {resp.status_code} - {resp.text[:80]}")

    # ============================================================
    # Check if mobile/app endpoints exist
    # ============================================================
    print("\n" + "="*70)
    print("TESTING MOBILE/APP ENDPOINTS")
    print("="*70)
    
    mobile_endpoints = [
        "/api/v1/stops/3344/arrivals",
        "/api/v2/arrivals",
        "/mobile/api/arrivals",
        "/app/arrivals",
    ]
    
    for endpoint in mobile_endpoints:
        url = f"https://telematics.oasth.gr{endpoint}"
        resp = session.get(url)
        print(f"  GET {endpoint}: {resp.status_code}")

    return working_endpoints

if __name__ == "__main__":
    working = deep_endpoint_discovery()
    print(f"\n\n📊 Total working endpoints found: {len(working)}")
