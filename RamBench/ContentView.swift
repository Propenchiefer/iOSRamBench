import SwiftUI

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
                withAnimation(
                    Animation
                        .linear(duration: 5)
                        .repeatForever(autoreverses: false)
                ) {
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
 
    private let accentColor = Color.blue
    private let cardBackgroundColor = Color(.secondarySystemBackground)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    memoryUsageCard
                    benchmarkControlsCard
                    if !benchmark.previousResults.isEmpty {
                        latestResultCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if !benchmark.previousResults.isEmpty {
                        Button(action: { showResultsSheet = true }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showInfoSheet) {
                infoSheetView
            }
            .sheet(isPresented: $showResultsSheet) {
                resultsSheetView
            }
            .onAppear {
                setupMemoryMonitoring()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 6) {
            ZStack {
                Text("RAMBench")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.clear)
                    .background(
                        FluidGradient(colors: [
                            Color.blue,
                            Color.blue.opacity(0.7),
                            Color.purple,
                            Color.purple.opacity(0.8),
                            Color.blue,
                        ])
                        .mask(
                            Text("RAMBench")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                        )
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
        .frame(maxWidth: .infinity)
    }
    
    private var memoryUsageCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
                
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
                
                memoryMeterView
                    .padding(.vertical, 8)
                
                memoryInfoRowsView
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var memoryMeterView: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                0,
                                geometry.size.width * min(
                                    CGFloat(memoryInfo.used) / CGFloat(memoryInfo.total),
                                    1.0
                                )
                            ),
                            height: 12
                        )
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
    }
    
    private var memoryInfoRowsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            memoryInfoRow(icon: "app.badge", title: "App Usage:", value: formatBytes(memoryInfo.appUsed))
            memoryInfoRow(icon: "apps.iphone", title: "Other Apps:", value: formatBytes(memoryInfo.activeAndInactive))
            memoryInfoRow(icon: "gear", title: "System (Wired):", value: formatBytes(memoryInfo.systemUsed))
            if memoryInfo.compressed > 0 {
                memoryInfoRow(icon: "archivebox", title: "Compressed:", value: formatBytes(memoryInfo.compressed))
            }
            memoryInfoRow(icon: "plus.square.dashed", title: "Available:", value: formatBytes(memoryInfo.free))
        }
    }
    
    private func memoryInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    private var benchmarkControlsCard: some View {
        VStack(spacing: 20) {
            if isRunning {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
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
                        .background(accentColor)
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
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var latestResultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Text("Latest Result")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button(action: { showResultsSheet = true }) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            
            if let last = benchmark.previousResults.last,
               let gb = last["gb"] as? Double,
               let iosVersion = last["iosVersion"] as? String,
               let deviceType = last["deviceType"] as? String {
                
                VStack(spacing: 8) {
                    Text(String(format: "%.2f GB", gb))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(accentColor)
                    
                    Text("Maximum Allocatable Memory")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack(spacing: 20) {
                        resultDetailItem(title: "Device", value: deviceType)
                        resultDetailItem(title: "iOS Version", value: iosVersion)
                        resultDetailItem(title: "Test Date", value: formatDate())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func resultDetailItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }
    
    private var infoSheetView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("About RAMBench")
                            .font(.system(size: 22, weight: .bold))
                        
                        Text("RAMBench is a memory performance analyzer that tests your device's RAM limits by incrementally allocating memory until the system threshold is reached using multiple allocation strategies including virtual memory, heap allocation, and Metal GPU resources.")
                            .font(.body)
                        
                        Text("Key Features")
                            .font(.system(size: 18, weight: .semibold))
                        
                        featureItem(icon: "chart.bar", text: "Precise measurement of available app memory")
                        featureItem(icon: "bell", text: "Detection of iOS memory management changes")
                        featureItem(icon: "device.phone", text: "Device-optimized allocation strategies")
                        featureItem(icon: "arrow.triangle.2.circlepath", text: "Benchmark history tracking")
                        featureItem(icon: "speedometer", text: "Adaptive speed for different device types")
                        featureItem(icon: "cpu", text: "Multiple memory allocation types including Metal GPU resources")
                    }
                    
                    Group {
                        Text("Important Notes")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 8)
                        
                        warningItem(text: "Benchmarking will push your device to its memory limits and may cause temporary system unresponsiveness")
                        warningItem(text: "Memory information displayed is based on system APIs and provides accurate real-time data")
                        warningItem(text: "Results may vary between runs due to system conditions and background processes")
                        warningItem(text: "For optimal results, close other apps before running a benchmark")
                        warningItem(text: "The app uses multiple allocation strategies to simulate real-world memory usage patterns")
                    }
                }
                .padding()
            }
            .navigationTitle("About RAMBench")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showInfoSheet = false
                    }
                }
            }
        }
    }
    
    private var resultsSheetView: some View {
        NavigationStack {
            List {
                ForEach(Array(benchmark.previousResults.enumerated().reversed()), id: \.offset) { index, result in
                    if let gb = result["gb"] as? Double,
                       let iosVersion = result["iosVersion"] as? String,
                       let deviceType = result["deviceType"] as? String,
                       let deviceRAM = result["deviceRAM"] as? Double {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: "%.2f GB", gb))
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    Text("\(deviceType) • iOS \(iosVersion)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.1f%%", (gb / deviceRAM) * 100))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(accentColor)
                                    
                                    Text("of device RAM")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if deviceRAM > 0 {
                                ProgressView(value: gb / deviceRAM)
                                    .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
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
                    Button("Done") {
                        showResultsSheet = false
                    }
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
    
    private func featureItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(accentColor)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 15))
        }
    }
    
    private func warningItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 15))
        }
    }
    
    private func setupMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                memoryInfo = getMemoryInfo()
            }
        }
    }
    
    private func runBenchmark() {
        isRunning = true
        benchmark.clearMemory()
        benchmark.startBenchmark { _ in
            DispatchQueue.main.async {
                isRunning = false
                memoryInfo = getMemoryInfo()
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatDate() -> String {
        return DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .none
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
