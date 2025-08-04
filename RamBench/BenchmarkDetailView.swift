import SwiftUI
import Charts

struct BenchmarkDetailView: View {
    let result: [String: Any]
    let gradientColors: [Color]
    @Environment(\.dismiss) private var dismiss
    @State private var currentMemoryInfo = getMemoryInfo()
    @State private var detailedStats: DetailedBenchmarkStats?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let gb = result["gb"] as? Double,
                       let deviceRAM = result["deviceRAM"] as? Double,
                       let deviceType = result["deviceType"] as? String,
                       let iosVersion = result["iosVersion"] as? String {
                        
                        // Header Section
                        BenchmarkHeaderView(
                            gb: gb,
                            deviceRAM: deviceRAM,
                            deviceType: deviceType,
                            iosVersion: iosVersion,
                            gradientColors: gradientColors
                        )
                        
                        // Memory Allocation Breakdown
                        MemoryAllocationBreakdownView(
                            allocatedGB: gb,
                            deviceRAM: deviceRAM,
                            currentMemory: currentMemoryInfo
                        )
                        
                        // Performance Metrics
                        PerformanceMetricsView(
                            allocatedGB: gb,
                            deviceRAM: deviceRAM,
                            deviceType: deviceType
                        )
                        
                        // Memory Efficiency Chart
                        MemoryEfficiencyChartView(
                            allocatedGB: gb,
                            deviceRAM: deviceRAM
                        )
                        
                        // System Information
                        SystemInformationView(
                            deviceType: deviceType,
                            iosVersion: iosVersion,
                            deviceRAM: deviceRAM,
                            currentMemory: currentMemoryInfo
                        )
                        
                        // Allocation Strategy Breakdown
                        AllocationStrategyView(
                            allocatedGB: gb,
                            deviceRAM: deviceRAM
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Benchmark Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                generateDetailedStats()
            }
        }
    }
    
    private func generateDetailedStats() {
        if let gb = result["gb"] as? Double,
           let deviceRAM = result["deviceRAM"] as? Double {
            detailedStats = DetailedBenchmarkStats(
                allocatedMemory: gb,
                totalRAM: deviceRAM,
                currentMemory: currentMemoryInfo
            )
        }
    }
}

struct BenchmarkHeaderView: View {
    let gb: Double
    let deviceRAM: Double
    let deviceType: String
    let iosVersion: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text(String(format: "%.2f GB", gb))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.clear)
                    .background(
                        FluidGradient(colors: gradientColors)
                        .mask(Text(String(format: "%.2f GB", gb)).font(.system(size: 42, weight: .bold)))
                    )
                Text(String(format: "%.2f GB", gb))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.clear)
                    .shadow(color: Color.purple.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
            }
            
            Text("Maximum Allocated Memory")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("Efficiency")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", (gb / deviceRAM) * 100))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 4) {
                    Text("Device RAM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f GB", deviceRAM))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f GB", deviceRAM - gb))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct MemoryAllocationBreakdownView: View {
    let allocatedGB: Double
    let deviceRAM: Double
    let currentMemory: MemoryInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Memory Allocation Breakdown")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            
            VStack(spacing: 12) {
                let allocatedBytes = UInt64(allocatedGB * 1024 * 1024 * 1024)
                let systemReserved = currentMemory.total - allocatedBytes - currentMemory.free
                
                MemoryBreakdownRow(
                    color: .blue,
                    title: "Benchmark Allocation",
                    value: allocatedBytes,
                    total: currentMemory.total
                )
                
                MemoryBreakdownRow(
                    color: .green,
                    title: "System Reserved",
                    value: systemReserved,
                    total: currentMemory.total
                )
                
                MemoryBreakdownRow(
                    color: .purple,
                    title: "App Memory",
                    value: currentMemory.appUsed,
                    total: currentMemory.total
                )
                
                MemoryBreakdownRow(
                    color: .orange,
                    title: "Other Apps",
                    value: currentMemory.activeAndInactive,
                    total: currentMemory.total
                )
                
                if currentMemory.compressed > 0 {
                    MemoryBreakdownRow(
                        color: .yellow,
                        title: "Compressed Memory",
                        value: currentMemory.compressed,
                        total: currentMemory.total
                    )
                }
                
                MemoryBreakdownRow(
                    color: .gray,
                    title: "Available",
                    value: currentMemory.free,
                    total: currentMemory.total
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MemoryBreakdownRow: View {
    let color: Color
    let title: String
    let value: UInt64
    let total: UInt64
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatBytes(value))
                    .font(.system(size: 15, weight: .semibold))
                
                Text(String(format: "%.1f%%", Double(value) / Double(total) * 100))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct PerformanceMetricsView: View {
    let allocatedGB: Double
    let deviceRAM: Double
    let deviceType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speedometer")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Performance Metrics")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                PerformanceMetricCard(
                    title: "Memory Efficiency",
                    value: String(format: "%.1f%%", (allocatedGB / deviceRAM) * 100),
                    subtitle: "of total RAM",
                    color: .blue,
                    icon: "chart.bar.fill"
                )
                
                PerformanceMetricCard(
                    title: "Allocation Rate",
                    value: calculateAllocationRate(),
                    subtitle: "est. MB/sec",
                    color: .green,
                    icon: "bolt.fill"
                )
                
                PerformanceMetricCard(
                    title: "Memory Pressure",
                    value: calculateMemoryPressure(),
                    subtitle: "system impact",
                    color: getPressureColor(),
                    icon: "thermometer"
                )
                
                PerformanceMetricCard(
                    title: "Device Grade",
                    value: getDeviceGrade(),
                    subtitle: "performance tier",
                    color: .purple,
                    icon: "star.fill"
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func calculateAllocationRate() -> String {
        // Estimate based on device RAM and typical allocation patterns
        let estimatedTime = deviceRAM * 2.5 // rough estimate in seconds
        let ratePerSecond = (allocatedGB * 1024) / estimatedTime
        return String(format: "%.0f", ratePerSecond)
    }
    
    private func calculateMemoryPressure() -> String {
        let efficiency = (allocatedGB / deviceRAM) * 100
        switch efficiency {
        case 0..<60: return "Low"
        case 60..<80: return "Medium"
        case 80..<90: return "High"
        default: return "Critical"
        }
    }
    
    private func getPressureColor() -> Color {
        let efficiency = (allocatedGB / deviceRAM) * 100
        switch efficiency {
        case 0..<60: return .green
        case 60..<80: return .yellow
        case 80..<90: return .orange
        default: return .red
        }
    }
    
    private func getDeviceGrade() -> String {
        if deviceType.contains("Pro") || deviceType.contains("M1") || deviceType.contains("M2") || deviceType.contains("M3") || deviceType.contains("M4") {
            return "A+"
        } else if deviceRAM >= 8.0 {
            return "A"
        } else if deviceRAM >= 6.0 {
            return "B+"
        } else if deviceRAM >= 4.0 {
            return "B"
        } else {
            return "C+"
        }
    }
}

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct MemoryEfficiencyChartView: View {
    let allocatedGB: Double
    let deviceRAM: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Memory Utilization Chart")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Visual representation of memory allocation over time
                GeometryReader { geometry in
                    let data = generateChartData()
                    let maxValue = data.map { $0.value }.max() ?? 1.0
                    
                    ZStack {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                HStack {
                                    Text(String(format: "%.1f GB", maxValue * (1.0 - Double(i) / 4.0)))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 0.5)
                                }
                                if i < 4 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // Memory allocation curve
                        Path { path in
                            let stepX = (geometry.size.width - 50) / Double(data.count - 1)
                            
                            for (index, point) in data.enumerated() {
                                let x = 50 + stepX * Double(index)
                                let y = geometry.size.height * (1.0 - point.value / maxValue)
                                
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
                        
                        // Fill area under curve
                        Path { path in
                            let stepX = (geometry.size.width - 50) / Double(data.count - 1)
                            path.move(to: CGPoint(x: 50, y: geometry.size.height))
                            
                            for (index, point) in data.enumerated() {
                                let x = 50 + stepX * Double(index)
                                let y = geometry.size.height * (1.0 - point.value / maxValue)
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
                    }
                }
                .frame(height: 150)
                
                // Time axis labels
                HStack {
                    Spacer().frame(width: 50)
                    Text("Start")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Peak")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Limit")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func generateChartData() -> [ChartDataPoint] {
        let points = 20
        var data: [ChartDataPoint] = []
        
        for i in 0..<points {
            let progress = Double(i) / Double(points - 1)
            let value: Double
            
            if progress < 0.7 {
                // Rapid growth phase
                value = allocatedGB * (progress / 0.7) * (progress / 0.7)
            } else if progress < 0.95 {
                // Slower growth phase
                let adjustedProgress = (progress - 0.7) / 0.25
                value = allocatedGB * (0.7 + 0.25 * adjustedProgress)
            } else {
                // Final approach to limit
                value = allocatedGB * (0.95 + 0.05 * ((progress - 0.95) / 0.05))
            }
            
            data.append(ChartDataPoint(index: i, value: value))
        }
        
        return data
    }
}

struct ChartDataPoint {
    let index: Int
    let value: Double
}

struct SystemInformationView: View {
    let deviceType: String
    let iosVersion: String
    let deviceRAM: Double
    let currentMemory: MemoryInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                Text("System Information")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            
            VStack(spacing: 12) {
                SystemInfoRow(title: "Device Model", value: deviceType, icon: "iphone")
                SystemInfoRow(title: "iOS Version", value: iosVersion, icon: "gear")
                SystemInfoRow(title: "Physical RAM", value: String(format: "%.0f GB", deviceRAM), icon: "memorychip")
                SystemInfoRow(title: "Page Size", value: getPageSize(), icon: "doc.text")
                SystemInfoRow(title: "Architecture", value: getArchitecture(), icon: "cpu")
                SystemInfoRow(title: "Memory Pressure", value: getMemoryPressureLevel(), icon: "thermometer")
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func getPageSize() -> String {
        return "16 KB" // Standard for modern iOS devices
    }
    
    private func getArchitecture() -> String {
        if deviceType.contains("M1") || deviceType.contains("M2") || deviceType.contains("M3") || deviceType.contains("M4") {
            return "Apple Silicon"
        } else if deviceType.contains("iPhone 12") || deviceType.contains("iPhone 13") || 
                  deviceType.contains("iPhone 14") || deviceType.contains("iPhone 15") ||
                  deviceType.contains("iPhone 16") {
            return "A-Series"
        } else {
            return "ARM64"
        }
    }
    
    private func getMemoryPressureLevel() -> String {
        let usagePercent = Double(currentMemory.used) / Double(currentMemory.total) * 100
        switch usagePercent {
        case 0..<50: return "Normal"
        case 50..<70: return "Moderate"
        case 70..<85: return "High"
        default: return "Critical"
        }
    }
}

struct SystemInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}

struct AllocationStrategyView: View {
    let allocatedGB: Double
    let deviceRAM: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Allocation Strategy")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            
            VStack(spacing: 16) {
                AllocationPhaseView(
                    phase: "Initial Phase (0-60%)",
                    description: "Large VM allocations with aggressive chunk sizing",
                    strategy: "vm_allocate() - 64MB chunks",
                    color: .green
                )
                
                AllocationPhaseView(
                    phase: "Growth Phase (60-80%)",
                    description: "Moderate allocations with dynamic sizing",
                    strategy: "vm_allocate() - 16MB chunks",
                    color: .blue
                )
                
                AllocationPhaseView(
                    phase: "Fine-tuning (80-95%)",
                    description: "Small malloc allocations for precision",
                    strategy: "malloc() - 1MB chunks",
                    color: .orange
                )
                
                AllocationPhaseView(
                    phase: "Final Push (95-100%)",
                    description: "Tiny allocations to find exact limit",
                    strategy: "malloc() - 32KB chunks",
                    color: .red
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Notes:")
                    .font(.system(size: 16, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• VM allocations provide better memory mapping")
                    Text("• malloc() used for precise limit detection")
                    Text("• Chunk sizes adapt based on device capabilities")
                    Text("• Memory verification prevents false positives")
                }
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AllocationPhaseView: View {
    let phase: String
    let description: String
    let strategy: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phase)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(strategy)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct DetailedBenchmarkStats {
    let allocatedMemory: Double
    let totalRAM: Double
    let currentMemory: MemoryInfo
    let efficiency: Double
    let memoryPressure: String
    
    init(allocatedMemory: Double, totalRAM: Double, currentMemory: MemoryInfo) {
        self.allocatedMemory = allocatedMemory
        self.totalRAM = totalRAM
        self.currentMemory = currentMemory
        self.efficiency = (allocatedMemory / totalRAM) * 100
        
        switch efficiency {
        case 0..<60: self.memoryPressure = "Low"
        case 60..<80: self.memoryPressure = "Medium"
        case 80..<90: self.memoryPressure = "High"
        default: self.memoryPressure = "Critical"
        }
    }
}