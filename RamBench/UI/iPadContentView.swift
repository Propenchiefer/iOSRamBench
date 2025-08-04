//
//  InfoSheetView.swift
//  RamBench
//
//  Created by Autumn on 7/9/25.
//

import SwiftUI

struct iPadContentView: View {
    @StateObject private var benchmark = MemoryBenchmark()
    @State private var memoryInfo: MemoryInfo = getMemoryInfo()
    @State private var showInfoSheet = false
    @State private var showResultsSheet = false
    @State private var detailResult: BenchmarkResult? = nil
    @State private var memoryUpdateTimer: Timer?
    
    let gradientColors = [
        Color.blue, Color.blue.opacity(0.7),
        Color.purple, Color.purple.opacity(0.8), Color.blue,
    ]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    VStack(spacing: 24) {
                        AppTitleView(gradientColors: gradientColors)
                        
                        HStack(spacing: 32) {
                            ScrollView {
                                VStack(spacing: 24) {
                                    MemoryStatusView(memoryInfo: memoryInfo)
                                    BenchmarkControlsView(benchmark: benchmark, runBenchmark: runBenchmark)
                                }
                                .padding(.vertical, 24)
                            }
                            .frame(width: geometry.size.width * 0.35)
                            .scrollDisabled(benchmark.isRunning) // disable scrolling during benchmarks cause it destroys the allocation tracking for some God awful reason
                            .scrollIndicators(.hidden)
                            
                            ScrollView {
                                VStack(spacing: 24) {
                                    MemoryUtilizationVisualization(
                                        benchmark: benchmark,
                                        memoryInfo: memoryInfo,
                                        gradientColors: gradientColors
                                    )
                                    
                                    if !benchmark.previousResults.isEmpty {
                                        LatestResultView(
                                            benchmark: benchmark,
                                               gradientColors: gradientColors,
                                               showDetailsSheet: { result in
                                                   detailResult = result
                                               }
                                           )
                                    }
                                }
                                .padding(.vertical, 24)
                            }
                            .frame(maxWidth: .infinity)
                            .scrollDisabled(benchmark.isRunning)
                            .scrollIndicators(.hidden)
                        }
                    }
                    .padding(.horizontal, 32)
                } else {
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
                            
                            MemoryUtilizationVisualization(
                                benchmark: benchmark,
                                memoryInfo: memoryInfo,
                                gradientColors: gradientColors
                            )
                            
                            if !benchmark.previousResults.isEmpty {
                                LatestResultView(
                                    benchmark: benchmark,
                                       gradientColors: gradientColors,
                                       showDetailsSheet: { result in
                                           detailResult = result
                                       }
                                   )
                            }
                        }
                        .padding(32)
                    }
                    .scrollDisabled(benchmark.isRunning)
                    .scrollIndicators(.hidden)
                }
            }
            .background(
                ZStack {
                    Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
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
            .sheet(item: $detailResult) { benchmarkResult in
                BenchmarkDetailView(result: benchmarkResult.data, gradientColors: benchmarkResult.gradientColors)
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
        
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if !self.benchmark.isRunning {
                    self.memoryInfo = getMemoryInfo()
                }
            }
        }
    }
    
    private func runBenchmark() {
        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = nil
        benchmark.clearMemory()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startMemoryMonitoring()
            
            self.benchmark.startBenchmark { finalResult in
                DispatchQueue.main.async {
                    self.memoryInfo = getMemoryInfo()
                    if finalResult > 0 && finalResult <= 20 {
                        let steps = 10
                        
                        for i in 0...steps {
                            let progress = Double(i) / Double(steps)
                            let value = finalResult * progress
                            let point = ChartDataPoint(index: i, value: value) // doesnt get used but if i remove it xcode fucks itself, classic appel
                        }
                    }
                }
            }
        }
    }
}

struct MemoryUtilizationVisualization: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let memoryInfo: MemoryInfo
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Allocation Chart")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                
                if benchmark.isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)}
                }
            }
            
            if benchmark.isRunning {
                VStack(spacing: 16) {
                    Text("Benchmark Running")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 60)
                }
                .frame(minHeight: 280, maxHeight: 400)
            } else if !benchmark.previousResults.isEmpty {
                if let lastResult = benchmark.previousResults.last,
                   let allocatedGB = lastResult["gb"] as? Double,
                   let deviceRAM = lastResult["deviceRAM"] as? Double {
                    
                    MemoryUtilizationChart(
                        allocatedGB: allocatedGB,
                        deviceRAM: deviceRAM
                    )
                    .frame(minHeight: 280, maxHeight: 400)
                }
            } else {
                BenchmarkPlaceholder(gradientColors: gradientColors)
                    .frame(minHeight: 280, maxHeight: 400)
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color(.secondarySystemBackground)
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
struct MemoryUtilizationChart: View {
    let allocatedGB: Double
    let deviceRAM: Double
    
    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let data = generateChartData()
                let maxValue = data.map { $0.value }.max() ?? 1.0
                
                ZStack {
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
            .frame(height: 280)
            HStack {
                Spacer().frame(width: 50)
                Text("Start")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
               
                Spacer()
                Text("Crash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func generateChartData() -> [iPadChartDataPoint] {
        let points = 25
        var data: [iPadChartDataPoint] = []
        
        for i in 0..<points {
            let progress = Double(i) / Double(points - 1)
            let value: Double
            
            if progress < 0.3 {
                let curveProgress = progress / 0.3
                value = allocatedGB * 0.4 * (curveProgress * curveProgress)
            } else if progress < 0.7 {
                let linearProgress = (progress - 0.3) / 0.4
                value = allocatedGB * (0.4 + 0.4 * linearProgress)
            } else if progress < 0.95 {
                let slowProgress = (progress - 0.7) / 0.25
                let easedProgress = 1.0 - pow(1.0 - slowProgress, 3)
                value = allocatedGB * (0.8 + 0.15 * easedProgress)
            } else {
                let finalProgress = (progress - 0.95) / 0.05
                value = allocatedGB * (0.95 + 0.05 * finalProgress)
            }
            
            data.append(iPadChartDataPoint(index: i, value: value))
        }
        
        return data
    }
}

struct ChartDataPoint {
    let index: Int
    let value: Double
}

struct iPadChartDataPoint {
    let index: Int
    let value: Double
} // i dont wanna do the work to fix this dont judge me :(

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
                Text("Allocation Chart")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Run a benchmark to see the memory allocation progression")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
