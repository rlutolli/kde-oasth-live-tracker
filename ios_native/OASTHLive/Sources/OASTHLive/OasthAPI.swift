import Foundation

/// OASTH API client
class OasthAPI: ObservableObject {
    private let baseURL = "https://telematics.oasth.gr"
    
    @Published var arrivals: [BusArrival] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var sessionStatus: String = "Not connected"
    
    private var session: URLSession
    private var phpSessionId: String?
    private var csrfToken: String?
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        self.session = URLSession(configuration: config)
    }
    
    /// Acquire session by loading the OASTH website
    func acquireSession() async {
        DispatchQueue.main.async {
            self.sessionStatus = "Connecting..."
            self.isLoading = true
        }
        
        do {
            // First, load the main page to get cookies
            let mainURL = URL(string: "\(baseURL)/en/")!
            var request = URLRequest(url: mainURL)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await session.data(for: request)
            
            // Extract CSRF token from HTML
            if let html = String(data: data, encoding: .utf8) {
                // Look for window.token = "..." in the HTML
                if let tokenMatch = html.range(of: "window\\.token\\s*=\\s*['\"]([^'\"]+)['\"]", options: .regularExpression) {
                    let fullMatch = String(html[tokenMatch])
                    if let tokenStart = fullMatch.firstIndex(of: "\"") ?? fullMatch.firstIndex(of: "'"),
                       let tokenEnd = fullMatch.lastIndex(of: "\"") ?? fullMatch.lastIndex(of: "'") {
                        let startIndex = fullMatch.index(after: tokenStart)
                        csrfToken = String(fullMatch[startIndex..<tokenEnd])
                        print("[OasthAPI] Found token: \(csrfToken?.prefix(10) ?? "nil")...")
                    }
                }
            }
            
            // Get PHPSESSID from cookies
            if let httpResponse = response as? HTTPURLResponse,
               let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String {
                if let sessMatch = setCookie.range(of: "PHPSESSID=([^;]+)", options: .regularExpression) {
                    phpSessionId = String(setCookie[sessMatch]).replacingOccurrences(of: "PHPSESSID=", with: "")
                    print("[OasthAPI] Got PHPSESSID: \(phpSessionId?.prefix(10) ?? "nil")...")
                }
            }
            
            // Also check cookie storage
            if let cookies = HTTPCookieStorage.shared.cookies(for: mainURL) {
                for cookie in cookies {
                    if cookie.name == "PHPSESSID" {
                        phpSessionId = cookie.value
                        print("[OasthAPI] Got PHPSESSID from storage: \(phpSessionId?.prefix(10) ?? "nil")...")
                    }
                }
            }
            
            DispatchQueue.main.async {
                if self.phpSessionId != nil && self.csrfToken != nil {
                    self.sessionStatus = "✓ Connected"
                } else {
                    self.sessionStatus = "⚠ Partial session"
                }
                self.isLoading = false
            }
            
        } catch {
            print("[OasthAPI] Session error: \(error)")
            DispatchQueue.main.async {
                self.sessionStatus = "✗ Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Fetch arrivals for a stop
    func getArrivals(stopCode: String) async {
        guard let token = csrfToken, let sessId = phpSessionId else {
            DispatchQueue.main.async {
                self.error = "No session - tap Connect first"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/?act=getStopArrivals&p1=\(stopCode)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
            request.setValue(token, forHTTPHeaderField: "X-CSRF-Token")
            request.setValue("PHPSESSID=\(sessId)", forHTTPHeaderField: "Cookie")
            request.setValue(baseURL, forHTTPHeaderField: "Origin")
            
            print("[OasthAPI] Fetching arrivals for stop: \(stopCode)")
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[OasthAPI] Response status: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let arrivals = try decoder.decode([BusArrival].self, from: data)
            let sorted = arrivals.sorted { $0.estimatedMinutes < $1.estimatedMinutes }
            
            print("[OasthAPI] Got \(sorted.count) arrivals")
            
            DispatchQueue.main.async {
                self.arrivals = sorted
                self.isLoading = false
            }
            
        } catch {
            print("[OasthAPI] Error: \(error)")
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
