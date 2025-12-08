import SwiftUI

/// Main content view with LED-style UI matching Android widget
struct ContentView: View {
    @StateObject private var api = OasthAPI()
    @State private var stopCode = "1029"  // Default: Kamara
    @State private var lineFilter = ""
    
    // LED Colors matching Android widget
    private let ledOrange = Color(red: 1.0, green: 0.58, blue: 0.0)   // #FF9500
    private let ledAmber = Color(red: 1.0, green: 0.67, blue: 0.0)    // #FFAA00
    private let background = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
    
    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // App title
                    HStack {
                        Text("OASTH LIVE")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(ledOrange)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Session status
                    sessionStatusView
                    
                    // Stop configuration
                    stopConfigView
                    
                    // Arrivals list (LED style)
                    arrivalsListView
                    
                    Spacer()
                    
                    // Credits
                    creditsView
                }
                .padding(.top)
            }
        }
        .task {
            await api.acquireSession()
        }
    }
    
    private var sessionStatusView: some View {
        HStack {
            Text(api.sessionStatus)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(api.sessionStatus.contains("✓") ? .green : 
                               api.sessionStatus.contains("✗") ? .red : ledAmber)
            
            Spacer()
            
            Button("Connect") {
                Task { await api.acquireSession() }
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ledOrange)
            .cornerRadius(6)
        }
        .padding(.horizontal)
    }
    
    private var stopConfigView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Stop code input
                TextField("Stop Code", text: $stopCode)
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(ledAmber)
                    .padding(10)
                    .background(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ledOrange, lineWidth: 1))
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                
                // Line filter input
                TextField("Filter (e.g. 01,31)", text: $lineFilter)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(ledAmber)
                    .padding(10)
                    .background(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ledOrange, lineWidth: 1))
                
                // Fetch button
                Button(action: {
                    Task { await api.getArrivals(stopCode: stopCode) }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(ledOrange)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var arrivalsListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LINE")
                    .frame(width: 50, alignment: .leading)
                Text("DESTINATION")
                Spacer()
                Text("MIN")
                    .frame(width: 50, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(ledOrange)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider().background(ledOrange.opacity(0.3))
            
            // Content
            if api.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ledOrange))
                    .padding(40)
            } else if let error = api.error {
                Text("Error: \(error)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.red)
                    .padding()
            } else if filteredArrivals.isEmpty {
                Text(api.arrivals.isEmpty ? "Enter stop code → tap refresh" : "No matching buses")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(ledAmber)
                    .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredArrivals) { arrival in
                            arrivalRow(arrival)
                            Divider().background(ledOrange.opacity(0.1))
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ledOrange.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }
    
    private func arrivalRow(_ arrival: BusArrival) -> some View {
        HStack {
            // Line number
            Text(arrival.displayLine)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(ledAmber)
                .frame(width: 50, alignment: .leading)
            
            // Destination
            Text(arrival.lineDescr)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ledAmber)
                .lineLimit(1)
            
            Spacer()
            
            // Time with urgency color
            Text(arrival.estimatedMinutes == 0 ? "NOW" : "\(arrival.estimatedMinutes)'")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(arrival.isUrgent ? .red : .green)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var creditsView: some View {
        VStack(spacing: 2) {
            Text("Made with ❤️ in Thessaloniki")
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.4))
            Text("Built with xtool • No Mac required")
                .font(.system(size: 10))
                .foregroundColor(Color(white: 0.3))
        }
        .padding(.bottom, 8)
    }
    
    /// Filter arrivals based on line filter
    private var filteredArrivals: [BusArrival] {
        guard !lineFilter.trimmingCharacters(in: .whitespaces).isEmpty else {
            return api.arrivals
        }
        
        let allowed = Set(lineFilter.split(separator: ",").map { 
            $0.trimmingCharacters(in: .whitespaces).uppercased() 
        })
        
        return api.arrivals.filter { allowed.contains($0.displayLine.uppercased()) }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
