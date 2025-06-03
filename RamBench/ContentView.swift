import SwiftUI
import UIKit

struct FluidGradient: View {
    let colors: [Color]
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AngularGradient(
                    gradient: Gradient(colors: colors),
                    center: .center,
                    angle: .degrees(rotation)
                )
                .blur(radius: 15)
                AngularGradient(
                    gradient: Gradient(colors: colors.reversed()),
                    center: .center,
                    angle: .degrees(-rotation * 0.7)
                )
                .blur(radius: 10)
                .opacity(0.7)
            }
            .frame(width: geometry.size.width * 2, height: geometry.size.height * 3)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
                withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var benchmark = MemoryBenchmark()
    @State private var isRunning = false
    @State private var memoryInfo: MemoryInfo = getMemoryInfo()
    @State private var showInfoSheet = false
    @State private var showResultsSheet = false
    @State private var memoryUpdateTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // title
                    VStack(spacing: 6) {
                        ZStack {
                            Text("RAMBench")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.clear)
                                .background(
                                    FluidGradient(colors: [
                                        Color.blue, Color.blue.opacity(0.7),
                                        Color.purple, Color.purple.opacity(0.8), Color.blue,
                                    ])
                                    .mask(Text("RAMBench").font(.system(size: 36, weight: .bold, design: .rounded)))
                                )
                            Text("RAMBench")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.clear)
                                .shadow(color: Color.purple.opacity(0.5), radius: 2, x: 1, y: 1)
                        }
                        
                        Text("Memory Performance Analyzer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Image(systemName: "memorychip")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("Memory Status")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Spacer()
                            
                            if memoryInfo.memoryPressure > 0 {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(memoryInfo.memoryPressure >= 1.0 ? .red : .orange)
                                        .frame(width: 8, height: 8)
                                    Text(memoryInfo.memoryPressure >= 1.0 ? "Critical" : "Warning")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Device RAM: \(formatBytes(memoryInfo.total))")
                                .font(.system(size: 15, weight: .medium))
                            
                            // Memory usage
                            VStack(spacing: 4) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 12)
                                        
                                        let usagePercent = min(CGFloat(memoryInfo.used) / CGFloat(memoryInfo.total), 1.0)
                                        Capsule()
                                            .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: max(0, geometry.size.width * usagePercent), height: 12)
                                    }
                                }
                                .frame(height: 12)
                                
                                HStack {
                                    Text(formatBytes(memoryInfo.used))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(Double(memoryInfo.used) / Double(memoryInfo.total) * 100))% used")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatBytes(memoryInfo.total))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Memory infos row
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    Image(systemName: "app.badge")
                                        .font(.system(size: 12))
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.blue)
                                    Text("App Usage:")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Text(formatBytes(memoryInfo.appUsed))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                
                                HStack(spacing: 10) {
                                    Image(systemName: "apps.iphone")
                                        .font(.system(size: 12))
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.blue)
                                    Text("Other Apps:")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Text(formatBytes(memoryInfo.activeAndInactive))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                
                                HStack(spacing: 10) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 12))
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.blue)
                                    Text("System (Wired):")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Text(formatBytes(memoryInfo.systemUsed))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                
                                if memoryInfo.compressed > 0 {
                                    HStack(spacing: 10) {
                                        Image(systemName: "archivebox")
                                            .font(.system(size: 12))
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(.blue)
                                        Text("Compressed:")
                                            .font(.system(size: 14, weight: .medium))
                                        Spacer()
                                        Text(formatBytes(memoryInfo.compressed))
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.square.dashed")
                                        .font(.system(size: 12))
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.blue)
                                    Text("Available:")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Text(formatBytes(memoryInfo.free))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Benchmark buttons
                    VStack(spacing: 20) {
                        if isRunning {
                            HStack(spacing: 12) {
                                ProgressView().scaleEffect(1.2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Benchmarking in progress...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    if benchmark.totalAllocated > 0 {
                                        Text("Allocated: \(formatBytes(UInt64(benchmark.totalAllocated)))")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                        } else {
                            HStack(spacing: 15) {
                                Button(action: runBenchmark) {
                                    HStack {
                                        Image(systemName: "gauge.with.needle")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Start Benchmark")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isRunning)
                                
                                if !benchmark.previousResults.isEmpty {
                                    Button(action: { benchmark.clearSavedResults() }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 16, weight: .medium))
                                            .padding(12)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        Text("Benchmarking will allocate memory until the system limit is reached. Your device may become unresponsive during this process.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Latest result if available
                    if !benchmark.previousResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text("Latest Result")
                                    .font(.system(size: 20, weight: .semibold))
                                Spacer()
                                Button("View All") { showResultsSheet = true }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            if let last = benchmark.previousResults.last,
                               let gb = last["gb"] as? Double,
                               let iosVersion = last["iosVersion"] as? String,
                               let deviceType = last["deviceType"] as? String,
                               let deviceRAM = last["deviceRAM"] as? Double {
                                
                                VStack(spacing: 8) {
                                    let displayGB = min(gb, deviceRAM * 0.95)
                                    
                                    Text(String(format: "%.2f GB", displayGB))
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(displayGB > deviceRAM * 0.8 ? .red : .blue)
                                    
                                    Text("Maximum Allocatable Memory")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    if gb > deviceRAM * 0.95 {
                                        Text("Results might be wonky due to system stuff")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    
                                    Divider().padding(.vertical, 8)
                                    
                                    HStack(spacing: 20) {
                                        VStack(spacing: 4) {
                                            Text("Device")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                            Text(deviceType == "iPhone" || deviceType == "iPad" ? deviceType : deviceType)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text("OS Version")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                            Text(iosVersion)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text("Test Date")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                            Text(formatDate())
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Info") { showInfoSheet = true }
                        .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if !benchmark.previousResults.isEmpty {
                        Button("Results") { showResultsSheet = true }
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showInfoSheet) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("About RAMBench")
                                .font(.system(size: 22, weight: .bold))
                            
                            Text("RAMBench tests your device's RAM limits by allocating memory until it hits the system limit. Uses both virtual memory and malloc.")
                                .font(.body)
                            
                            Text("Thanks to:")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.top, 16)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Button("Autumn") {
                                        if let url = URL(string: "https://github.com/Propenchiefer") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    Text("Creator")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Button("Stossy11") {
                                        if let url = URL(string: "https://github.com/Stossy11") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    Text("Memory allocation help & device detection")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Button("CycloKid") {
                                        if let url = URL(string: "https://github.com/CycloKid") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    Text("App icon & graphics")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("About RAMBench")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showInfoSheet = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showResultsSheet) {
                NavigationStack {
                    List {
                        ForEach(Array(benchmark.previousResults.enumerated().reversed()), id: \.offset) { _, result in
                            if let gb = result["gb"] as? Double,
                               let iosVersion = result["iosVersion"] as? String,
                               let deviceType = result["deviceType"] as? String,
                               let deviceRAM = result["deviceRAM"] as? Double {
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(String(format: "%.2f GB", gb))
                                                    .font(.system(size: 17, weight: .semibold))
                                                
                                                if gb > deviceRAM * 0.95 {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            
                                            Text("\(deviceType) • iOS \(iosVersion)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            let percentage = (gb / deviceRAM) * 100
                                            Text(String(format: "%.1f%%", percentage))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(percentage > 95 ? .orange : .blue)
                                            
                                            Text("of device RAM")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if deviceRAM > 0 {
                                        let normalizedValue = min(gb / deviceRAM, 1.0)
                                        ProgressView(value: normalizedValue)
                                            .progressViewStyle(LinearProgressViewStyle(
                                                tint: normalizedValue > 0.95 ? .orange : .blue
                                            ))
                                            .scaleEffect(x: 1, y: 0.7)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .navigationTitle("Benchmark History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showResultsSheet = false }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            if !benchmark.previousResults.isEmpty {
                                Button(action: { benchmark.clearSavedResults() }) {
                                    Image(systemName: "trash")
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .onAppear { startMemoryMonitoring() }
            .onDisappear { stopMemoryMonitoring() }
        }
    }
    
    func startMemoryMonitoring() {
        stopMemoryMonitoring()
        let interval = isRunning ? 2.0 : 1.0
        
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if !isRunning {
                DispatchQueue.main.async {
                    memoryInfo = getMemoryInfo()
                }
            }
        }
    }
    
    func stopMemoryMonitoring() {
        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = nil
    }
    
    func runBenchmark() {
        isRunning = true
        stopMemoryMonitoring()
        
        benchmark.clearMemory()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.benchmark.startBenchmark { finalResult in
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.memoryInfo = getMemoryInfo()
                    self.startMemoryMonitoring()
                }
            }
        }
    }
    
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func formatDate() -> String {
        return DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .none
        )
    }
}

#Preview {
    ContentView()
}
