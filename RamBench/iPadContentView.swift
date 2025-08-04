import SwiftUI

struct iPadContentView: View {
    @StateObject private var benchmark = MemoryBenchmark()
    @State private var memoryInfo: MemoryInfo = getMemoryInfo()
    @State private var showInfoSheet = false
    @State private var showResultsSheet = false
    @State private var showDetailSheet = false
    @State private var selectedDetailResult: [String: Any]? = nil
    @State private var memoryUpdateTimer: Timer?
    @State private var benchmarkHistory: [BenchmarkDataPoint] = []
    
    let gradientColors = [
        Color.blue, Color.blue.opacity(0.7),
        Color.purple, Color.purple.opacity(0.8), Color.blue,
    ]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    // Landscape Layout
                    HStack(spacing: 32) {
                        // Left Column - Controls and Status
                        VStack(spacing: 24) {
                            AppTitleView(gradientColors: gradientColors)
                            MemoryStatusView(memoryInfo: memoryInfo)
                            BenchmarkControlsView(benchmark: benchmark, runBenchmark: runBenchmark)
                            
                            if !benchmark.previousResults.isEmpty {
                                LatestResultCompactView(
                                    benchmark: benchmark,
                                    gradientColors: gradientColors,
                                    showDetailsSheet: { result in
                                        selectedDetailResult = result
                                        showDetailSheet = true
                                    }
                                )
                            }
                            
                            Spacer()
                        }
                        .frame(width: geometry.size.width * 0.45)
                        
                        // Right Column - Real-time Visualization
                        VStack(spacing: 20) {
                            RealTimeBenchmarkVisualization(
                                benchmark: benchmark,
                                memoryInfo: memoryInfo,
                                gradientColors: gradientColors,
                                benchmarkHistory: benchmarkHistory
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                } else {
                    // Portrait Layout
                    ScrollView {
                        VStack(spacing: 32) {
                            AppTitleView(gradientColors: gradientColors)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20)
                            ], spacing: 24) {
                                MemoryStatusView(memoryInfo: memoryInfo)
                                BenchmarkControlsView(benchmark: benchmark, runBenchmark: runBenchmark)
                            }
                            
                            RealTimeBenchmarkVisualization(
                                benchmark: benchmark,
                                memoryInfo: memoryInfo,
                                gradientColors: gradientColors,
                                benchmarkHistory: benchmarkHistory
                            )
                            
                            if !benchmark.previousResults.isEmpty {
                                LatestResultView(
                                    benchmark: benchmark,
                                    gradientColors: gradientColors,
                                    showDetailsSheet: { result in
                                        selectedDetailResult = result
                                        showDetailSheet = true
                                    }
                                )
                            }
                        }
                        .padding(32)
                    }
                }
            }
            .background(
                ZStack {
                    Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                    
                    // Subtle animated background elements
                    GeometryReader { geo in
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [gradientColors[i].opacity(0.03), .clear],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 300
                                    )
                                )
                                .frame(width: 400, height: 400)
                                .position(
                                    x: geo.size.width * (0.2 + 0.3 * Double(i)),
                                    y: geo.size.height * (0.3 + 0.2 * Double(i))
                                )
                                .animation(
                                    Animation.easeInOut(duration: 8 + Double(i) * 2)
                                        .repeatForever(autoreverses: true),
                                    value: benchmark.isRunning
                                )
                        }
                    }
                }
            )
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if !benchmark.previousResults.isEmpty {
                            Button("Results") { showResultsSheet = true }
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Button("Info") { showInfoSheet = true }
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showInfoSheet) {
                InfoSheetView()
            }
            .sheet(isPresented: $showResultsSheet) {
                ResultsSheetView(benchmark: benchmark, gradientColors: gradientColors)
            }
            .sheet(isPresented: $showDetailSheet) {
                if let result = selectedDetailResult {
                    BenchmarkDetailView(result: result, gradientColors: gradientColors)
                }
            }
            .onAppear {
                startMemoryMonitoring()
            }
            .onDisappear {
                memoryUpdateTimer?.invalidate()
                memoryUpdateTimer = nil
            }
        }
    }
    
    private func startMemoryMonitoring() {
        memoryUpdateTimer?.invalidate()
        
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if !benchmark.isRunning {
                DispatchQueue.main.async {
                    memoryInfo = getMemoryInfo()
                }
            } else {
                // Update benchmark history during benchmark
                DispatchQueue.main.async {
                    let currentMemory = getMemoryInfo()
                    let dataPoint = BenchmarkDataPoint(
                        timestamp: Date(),
                        allocatedGB: Double(benchmark.totalAllocated) / (1024 * 1024 * 1024),
                        usedMemoryGB: Double(currentMemory.used) / (1024 * 1024 * 1024),
                        freeMemoryGB: Double(currentMemory.free) / (1024 * 1024 * 1024)
                    )
                    
                    benchmarkHistory.append(dataPoint)
                    
                    // Keep only last 100 points for performance
                    if benchmarkHistory.count > 100 {
                        benchmarkHistory.removeFirst()
                    }
                    
                    memoryInfo = currentMemory
                }
            }
        }
    }
    
    private func runBenchmark() {
        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = nil
        
        // Clear previous benchmark history
        benchmarkHistory.removeAll()
        
        benchmark.clearMemory()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Restart monitoring with higher frequency during benchmark
            self.startMemoryMonitoring()
            
            self.benchmark.startBenchmark { finalResult in
                DispatchQueue.main.async {
                    self.memoryInfo = getMemoryInfo()
                    // Add final data point
                    let finalDataPoint = BenchmarkDataPoint(
                        timestamp: Date(),
                        allocatedGB: Double(finalResult),
                        usedMemoryGB: Double(self.memoryInfo.used) / (1024 * 1024 * 1024),
                        freeMemoryGB: Double(self.memoryInfo.free) / (1024 * 1024 * 1024)
                    )
                    self.benchmarkHistory.append(finalDataPoint)
                }
            }
        }
    }
}

struct RealTimeBenchmarkVisualization: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let memoryInfo: MemoryInfo
    let gradientColors: [Color]
    let benchmarkHistory: [BenchmarkDataPoint]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Real-Time Benchmark Visualization")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                
                if benchmark.isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Running...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if benchmark.isRunning || !benchmarkHistory.isEmpty {
                // Real-time Chart
                RealTimeMemoryChart(
                    benchmarkHistory: benchmarkHistory,
                    gradientColors: gradientColors,
                    totalRAM: Double(memoryInfo.total) / (1024 * 1024 * 1024)
                )
                .frame(height: 320)
                
                // Current Stats Row
                if benchmark.isRunning {
                    CurrentBenchmarkStats(
                        benchmark: benchmark,
                        memoryInfo: memoryInfo,
                        gradientColors: gradientColors
                    )
                }
            } else {
                // Placeholder when no benchmark is running
                BenchmarkPlaceholder(gradientColors: gradientColors)
                    .frame(height: 320)
            }
        }
        .padding(28)
        .background(
            ZStack {
                Color(.secondarySystemBackground)
                
                // Subtle grid pattern
                Canvas { context, size in
                    let gridSpacing: CGFloat = 20
                    context.stroke(
                        Path { path in
                            for x in stride(from: 0, to: size.width, by: gridSpacing) {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            }
                            for y in stride(from: 0, to: size.height, by: gridSpacing) {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            }
                        },
                        with: .color(.gray.opacity(0.05)),
                        lineWidth: 0.5
                    )
                }
            }
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

struct RealTimeMemoryChart: View {
    let benchmarkHistory: [BenchmarkDataPoint]
    let gradientColors: [Color]
    let totalRAM: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<6) { i in
                        HStack {
                            Text(String(format: "%.1f GB", totalRAM * (1.0 - Double(i) / 5.0)))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 0.5)
                        }
                        if i < 5 {
                            Spacer()
                        }
                    }
                }
                
                if !benchmarkHistory.isEmpty {
                    // Allocated memory line
                    Path { path in
                        let stepX = (geometry.size.width - 60) / max(Double(benchmarkHistory.count - 1), 1.0)
                        
                        for (index, point) in benchmarkHistory.enumerated() {
                            let x = 60 + stepX * Double(index)
                            let y = geometry.size.height * (1.0 - point.allocatedGB / totalRAM)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Fill area under allocated memory
                    Path { path in
                        let stepX = (geometry.size.width - 60) / max(Double(benchmarkHistory.count - 1), 1.0)
                        path.move(to: CGPoint(x: 60, y: geometry.size.height))
                        
                        for (index, point) in benchmarkHistory.enumerated() {
                            let x = 60 + stepX * Double(index)
                            let y = geometry.size.height * (1.0 - point.allocatedGB / totalRAM)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Used memory line (system + apps)
                    Path { path in
                        let stepX = (geometry.size.width - 60) / max(Double(benchmarkHistory.count - 1), 1.0)
                        
                        for (index, point) in benchmarkHistory.enumerated() {
                            let x = 60 + stepX * Double(index)
                            let y = geometry.size.height * (1.0 - point.usedMemoryGB / totalRAM)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    
                    // Current point indicator
                    if let lastPoint = benchmarkHistory.last {
                        let stepX = (geometry.size.width - 60) / max(Double(benchmarkHistory.count - 1), 1.0)
                        let x = 60 + stepX * Double(benchmarkHistory.count - 1)
                        let y = geometry.size.height * (1.0 - lastPoint.allocatedGB / totalRAM)
                        
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                            .scaleEffect(1.5)
                            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: benchmarkHistory.count)
                    }
                }
                
                // Legend
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 10, height: 10)
                            Text("Allocated")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 10, height: 10)
                            Text("System Used")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, 60)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

struct CurrentBenchmarkStats: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let memoryInfo: MemoryInfo
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 24) {
            StatCard(
                title: "Allocated",
                value: String(format: "%.2f GB", Double(benchmark.totalAllocated) / (1024 * 1024 * 1024)),
                color: .blue,
                icon: "memorychip.fill"
            )
            
            StatCard(
                title: "Memory Used",
                value: formatBytes(memoryInfo.used),
                color: .orange,
                icon: "gauge.high"
            )
            
            StatCard(
                title: "Available",
                value: formatBytes(memoryInfo.free),
                color: .green,
                icon: "checkmark.circle.fill"
            )
            
            StatCard(
                title: "Efficiency",
                value: String(format: "%.1f%%", (Double(benchmark.totalAllocated) / Double(memoryInfo.total)) * 100),
                color: .purple,
                icon: "chart.bar.fill"
            )
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct BenchmarkPlaceholder: View {
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.clear)
                    .background(
                        FluidGradient(colors: gradientColors)
                        .mask(Image(systemName: "chart.line.uptrend.xyaxis.circle").font(.system(size: 80, weight: .light)))
                    )
            }
            
            VStack(spacing: 8) {
                Text("Real-Time Visualization")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Start a benchmark to see live memory allocation data")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct LatestResultCompactView: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let gradientColors: [Color]
    let showDetailsSheet: ([String: Any]) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Latest Result")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                
                if let last = benchmark.previousResults.last {
                    Button("Details") {
                        showDetailsSheet(last)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            
            if let last = benchmark.previousResults.last,
               let gb = last["gb"] as? Double,
               let deviceRAM = last["deviceRAM"] as? Double {
                
                VStack(spacing: 8) {
                    ZStack {
                        Text(String(format: "%.2f GB", gb))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.clear)
                            .background(
                                FluidGradient(colors: gradientColors)
                                .mask(Text(String(format: "%.2f GB", gb)).font(.system(size: 28, weight: .bold)))
                            )
                    }
                    
                    Text(String(format: "%.1f%% efficiency", (gb / deviceRAM) * 100))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct BenchmarkDataPoint {
    let timestamp: Date
    let allocatedGB: Double
    let usedMemoryGB: Double
    let freeMemoryGB: Double
}