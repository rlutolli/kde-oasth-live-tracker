import Foundation

/// Bus arrival data from OASTH API
struct BusArrival: Codable, Identifiable {
    let lineId: String
    let lineDescr: String
    let routeCode: String
    let vehicleCode: String
    let rawTime: String
    
    var id: String { "\(lineId)-\(vehicleCode)-\(rawTime)" }
    
    /// Estimated minutes as Int
    var estimatedMinutes: Int {
        Int(rawTime) ?? 0
    }
    
    /// Display name - prefer lineId if available
    var displayLine: String {
        lineId.isEmpty ? routeCode : lineId
    }
    
    /// Urgency color - red for <5min, green for >=5min
    var isUrgent: Bool {
        estimatedMinutes < 5
    }
    
    enum CodingKeys: String, CodingKey {
        case lineId = "bline_id"
        case lineDescr = "bline_descr"
        case routeCode = "route_code"
        case vehicleCode = "veh_code"
        case rawTime = "btime2"
    }
}

/// Session credentials for API access
struct SessionData: Codable {
    let phpSessionId: String
    let token: String
    let createdAt: Date
    
    var isValid: Bool {
        // Valid for 1 hour
        Date().timeIntervalSince(createdAt) < 3600
    }
}

/// Widget configuration
struct WidgetConfig: Codable {
    let stopCode: String
    let stopName: String
    let lineFilter: String  // Comma-separated line IDs
    
    /// Parse line filter into a set
    func getAllowedLines() -> Set<String>? {
        guard !lineFilter.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return Set(lineFilter.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).uppercased() })
    }
}
