import WidgetKit
import SwiftUI

// MARK: - Minimal Widget Entry
struct MinimalWidgetEntry: TimelineEntry {
    let date: Date
    let stopCode: String
    let arrivals: [MinimalArrivalData]
    let error: String?
    
    static var placeholder: MinimalWidgetEntry {
        MinimalWidgetEntry(
            date: Date(),
            stopCode: "1029",
            arrivals: [
                MinimalArrivalData(lineId: "01", minutes: 3),
                MinimalArrivalData(lineId: "31", minutes: 7),
                MinimalArrivalData(lineId: "52", minutes: 12),
            ],
            error: nil
        )
    }
}

struct MinimalArrivalData {
    let lineId: String
    let minutes: Int
    
    init(lineId: String, minutes: Int) {
        self.lineId = lineId
        self.minutes = minutes
    }
    
    init(from json: [String: Any]) {
        self.lineId = json["bline_id"] as? String ?? json["route_code"] as? String ?? ""
        let rawTime = json["btime2"] as? String ?? "0"
        self.minutes = Int(rawTime) ?? 0
    }
    
    /// Urgency color based on time - from Panos's idea
    /// Red: < 5 minutes (urgent), Green: >= 5 minutes (safe)
    var urgencyColor: Color {
        if minutes < 5 {
            return Color(red: 1.0, green: 0.33, blue: 0.33)  // Neon Red
        } else {
            return Color(red: 0.33, green: 1.0, blue: 0.33)  // Neon Green
        }
    }
}

// MARK: - Minimal Timeline Provider
struct MinimalWidgetProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.oasth.widget")
    
    func placeholder(in context: Context) -> MinimalWidgetEntry {
        return .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MinimalWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MinimalWidgetEntry>) -> Void) {
        let entry = loadEntry()
        
        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadEntry() -> MinimalWidgetEntry {
        let stopCode = sharedDefaults?.string(forKey: "stopCode") ?? ""
        let arrivalsJson = sharedDefaults?.string(forKey: "arrivals") ?? "[]"
        let error = sharedDefaults?.string(forKey: "error")
        
        var arrivals: [MinimalArrivalData] = []
        if let data = arrivalsJson.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            arrivals = jsonArray.map { MinimalArrivalData(from: $0) }
        }
        
        return MinimalWidgetEntry(
            date: Date(),
            stopCode: stopCode,
            arrivals: arrivals,
            error: error?.isEmpty == false ? error : nil
        )
    }
}

// MARK: - Minimal Widget View (Compact with Urgency Colors)
struct MinimalWidgetView: View {
    var entry: MinimalWidgetEntry
    
    @Environment(\.widgetFamily) var family
    
    private let ledAmber = Color(red: 1.0, green: 0.67, blue: 0.0)  // #FFAA00
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header with stop code
            HStack {
                Text(entry.stopCode)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(ledAmber)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ledAmber, lineWidth: 1)
                    )
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundColor(ledAmber.opacity(0.7))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            
            // Separator
            Rectangle()
                .fill(ledAmber.opacity(0.3))
                .frame(height: 1)
            
            // Content
            if entry.arrivals.isEmpty {
                Spacer()
                Text(entry.error ?? "No buses")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ledAmber)
                Spacer()
            } else {
                VStack(spacing: 2) {
                    ForEach(entry.arrivals.prefix(maxRows), id: \.lineId) { arrival in
                        minimalRow(arrival)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
            }
        }
        .background(Color.black)
        .font(.system(.body, design: .monospaced))
    }
    
    private func minimalRow(_ arrival: MinimalArrivalData) -> some View {
        HStack {
            // Line number in amber
            Text(arrival.lineId)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(ledAmber)
                .frame(width: 30, alignment: .leading)
            
            Spacer()
            
            // Time with URGENCY COLOR (Panos's idea!)
            Text(arrival.minutes == 0 ? "NOW" : "\(arrival.minutes)'")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(arrival.urgencyColor)
        }
    }
    
    private var maxRows: Int {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 3
        default: return 4
        }
    }
}

// MARK: - Minimal Widget Configuration
struct MinimalBusWidget: Widget {
    let kind: String = "MinimalBusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MinimalWidgetProvider()) { entry in
            MinimalWidgetView(entry: entry)
        }
        .configurationDisplayName("OASTH Compact")
        .description("Compact view with urgency colors")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview
struct MinimalBusWidget_Previews: PreviewProvider {
    static var previews: some View {
        MinimalWidgetView(entry: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
