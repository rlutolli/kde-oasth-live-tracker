import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct BusWidgetEntry: TimelineEntry {
    let date: Date
    let stopCode: String
    let stopName: String
    let arrivals: [BusArrivalData]
    let error: String?
    
    static var placeholder: BusWidgetEntry {
        BusWidgetEntry(
            date: Date(),
            stopCode: "1029",
            stopName: "KAMARA",
            arrivals: [
                BusArrivalData(lineId: "01", lineDescr: "PLATEIA → KALAMARIA", minutes: 3),
                BusArrivalData(lineId: "31", lineDescr: "NEA EGNATIA", minutes: 7),
                BusArrivalData(lineId: "52", lineDescr: "AERODROMIO", minutes: 12),
            ],
            error: nil
        )
    }
}

struct BusArrivalData: Codable {
    let lineId: String
    let lineDescr: String
    let minutes: Int
    
    init(lineId: String, lineDescr: String, minutes: Int) {
        self.lineId = lineId
        self.lineDescr = lineDescr
        self.minutes = minutes
    }
    
    init(from json: [String: Any]) {
        self.lineId = json["bline_id"] as? String ?? ""
        self.lineDescr = json["bline_descr"] as? String ?? ""
        let rawTime = json["btime2"] as? String ?? "0"
        self.minutes = Int(rawTime) ?? 0
    }
}

// MARK: - Timeline Provider
struct BusWidgetProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.oasth.widget")
    
    func placeholder(in context: Context) -> BusWidgetEntry {
        return .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BusWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BusWidgetEntry>) -> Void) {
        let entry = loadEntry()
        
        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadEntry() -> BusWidgetEntry {
        let stopCode = sharedDefaults?.string(forKey: "stopCode") ?? ""
        let stopName = sharedDefaults?.string(forKey: "stopName") ?? ""
        let arrivalsJson = sharedDefaults?.string(forKey: "arrivals") ?? "[]"
        let error = sharedDefaults?.string(forKey: "error")
        
        var arrivals: [BusArrivalData] = []
        if let data = arrivalsJson.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            arrivals = jsonArray.map { BusArrivalData(from: $0) }
        }
        
        return BusWidgetEntry(
            date: Date(),
            stopCode: stopCode,
            stopName: stopName,
            arrivals: arrivals,
            error: error
        )
    }
}

// MARK: - Widget View (LED Style)
struct BusWidgetView: View {
    var entry: BusWidgetEntry
    
    @Environment(\.widgetFamily) var family
    
    private let ledOrange = Color(red: 1.0, green: 0.58, blue: 0.0)      // #FF9500
    private let ledAmber = Color(red: 1.0, green: 0.67, blue: 0.0)       // #FFAA00
    private let ledDim = Color(red: 1.0, green: 0.67, blue: 0.0).opacity(0.3)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Separator
            Rectangle()
                .fill(ledDim)
                .frame(height: 1)
            
            // Content
            if entry.arrivals.isEmpty {
                emptyView
            } else {
                arrivalsListView
            }
            
            // Footer
            footerView
        }
        .background(Color.black)
        .font(.system(.body, design: .monospaced))
    }
    
    private var headerView: some View {
        HStack {
            Text("LINE | DESTINATION")
                .font(.system(size: family == .systemSmall ? 10 : 14, weight: .bold, design: .monospaced))
                .foregroundColor(ledOrange)
            
            Spacer()
            
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12))
                .foregroundColor(ledOrange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var emptyView: some View {
        VStack {
            Spacer()
            Text(entry.error ?? "No arrivals")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ledAmber)
            Spacer()
        }
    }
    
    private var arrivalsListView: some View {
        VStack(spacing: 2) {
            ForEach(entry.arrivals.prefix(maxRows), id: \.lineId) { arrival in
                arrivalRow(arrival)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func arrivalRow(_ arrival: BusArrivalData) -> some View {
        HStack {
            Text(arrival.lineId)
                .font(.system(size: family == .systemSmall ? 12 : 14, weight: .bold, design: .monospaced))
                .foregroundColor(ledAmber)
                .frame(width: 35, alignment: .leading)
            
            Text(arrival.lineDescr)
                .font(.system(size: family == .systemSmall ? 10 : 12, design: .monospaced))
                .foregroundColor(ledAmber)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(arrival.minutes)'")
                .font(.system(size: family == .systemSmall ? 12 : 14, weight: .bold, design: .monospaced))
                .foregroundColor(ledAmber)
        }
    }
    
    private var footerView: some View {
        HStack {
            // Stop code box
            Text(entry.stopCode)
                .font(.system(size: family == .systemSmall ? 16 : 20, weight: .bold, design: .monospaced))
                .foregroundColor(ledOrange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(ledOrange, lineWidth: 1)
                )
            
            // Stop name
            if !entry.stopName.isEmpty {
                Text(entry.stopName)
                    .font(.system(size: family == .systemSmall ? 14 : 18, weight: .bold, design: .monospaced))
                    .foregroundColor(ledAmber)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var maxRows: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        case .systemLarge: return 8
        default: return 4
        }
    }
}

// MARK: - Widget Configuration
struct BusWidget: Widget {
    let kind: String = "BusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BusWidgetProvider()) { entry in
            BusWidgetView(entry: entry)
        }
        .configurationDisplayName("OASTH Live")
        .description("Real-time bus arrivals for Thessaloniki")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle (Both Standard and Minimal widgets)
@main
struct OasthWidgetBundle: WidgetBundle {
    var body: some Widget {
        BusWidget()
        MinimalBusWidget()
    }
}

// MARK: - Preview
struct BusWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BusWidgetView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            BusWidgetView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
