"""
OASTH Direct API Testing
Tests various potential API endpoints and URL patterns
DO NOT USE IN PRODUCTION - FOR RESEARCH ONLY
"""

import requests
from bs4 import BeautifulSoup
import json

def test_direct_urls(stop_code="3344"):
    """Test various URL patterns to find direct access methods"""
    
    print(f"🔍 Testing direct URL access for stop code: {stop_code}\n")
    
    # Test various potential URL patterns
    url_patterns = [
        f"https://telematics.oasth.gr/api/station/{stop_code}",
        f"https://telematics.oasth.gr/api/arrivals/{stop_code}",
        f"https://telematics.oasth.gr/api/stop/{stop_code}",
        f"https://telematics.oasth.gr/en/station/{stop_code}",
        f"https://telematics.oasth.gr/en/#stationInfo_{stop_code}",
        f"https://telematics.oasth.gr/ajax/getStationArrivals.php?code={stop_code}",
        f"https://telematics.oasth.gr/getStationArrivals.php?code={stop_code}",
    ]
    
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
    })
    
    for url in url_patterns:
        print(f"\n{'='*60}")
        print(f"Testing: {url}")
        print(f"{'='*60}")
        
        try:
            response = session.get(url, timeout=10)
            print(f"Status Code: {response.status_code}")
            print(f"Content-Type: {response.headers.get('content-type', 'unknown')}")
            print(f"Content Length: {len(response.content)} bytes")
            
            # Show preview
            content_preview = response.text[:300]
            print(f"\nContent Preview:\n{content_preview}...")
            
            # Try to parse as JSON
            if 'json' in response.headers.get('content-type', ''):
                try:
                    data = response.json()
                    print(f"\n✅ Valid JSON response!")
                    print(json.dumps(data, indent=2)[:500])
                except:
                    print("\n❌ Not valid JSON despite content-type")
            
        except requests.exceptions.Timeout:
            print("⏱️  Request timed out")
        except requests.exceptions.ConnectionError:
            print("❌ Connection error")
        except Exception as e:
            print(f"❌ Error: {str(e)}")

def test_session_requirements():
    """Test if the site requires session/cookies"""
    
    print("\n\n" + "="*60)
    print("TESTING SESSION REQUIREMENTS")
    print("="*60 + "\n")
    
    # First visit the main page to get session
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
    })
    
    print("Step 1: Visiting main page to establish session...")
    resp1 = session.get("https://telematics.oasth.gr/en/")
    print(f"Status: {resp1.status_code}")
    print(f"Cookies received: {session.cookies.get_dict()}")
    print(f"Session ID: {session.cookies.get('PHPSESSID', 'None')}")
    
    # Look for any CSRF tokens or hidden fields
    soup = BeautifulSoup(resp1.text, 'html.parser')
    csrf_tokens = soup.find_all('input', {'type': 'hidden'})
    print(f"\nHidden input fields found: {len(csrf_tokens)}")
    for token in csrf_tokens:
        print(f"  - {token.get('name')}: {token.get('value', '')[:50]}")
    
    return session

if __name__ == "__main__":
    print("OASTH Direct API Testing\n")
    
    # Test various URL patterns
    test_direct_urls("3344")
    
    # Test session requirements
    session = test_session_requirements()
    
    print("\n\n✅ Testing complete! Check output above for findings.")
