//
//  RAMBenchApp.swift
//  RamBench
//
//  Created by Autumn on 5/16/25.
//

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

struct AppTitleView: View {
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Text("RAMBench")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.clear)
                    .background(
                        FluidGradient(colors: gradientColors)
                        .mask(Text("RAMBench").font(.system(size: 36, weight: .bold, design: .rounded)))
                    )
                Text("RAMBench")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.clear)
                    .shadow(color: Color.purple.opacity(0.5), radius: 2, x: 1, y: 1)
            }
            
            Text("Memory Allocation Analyzer")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
    }
}

struct MemoryStatusView: View {
    let memoryInfo: MemoryInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Memory Status")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Device RAM: \(formatBytes(memoryInfo.total))")
                    .font(.system(size: 15, weight: .medium))
                
                MemoryUsageBarView(memoryInfo: memoryInfo)
                MemoryDetailsList(memoryInfo: memoryInfo)
                
                Text("These monitors are rough estimations, results may vary")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryUsageBarView: View {
    let memoryInfo: MemoryInfo
    
    var body: some View {
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
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryDetailsList: View {
    let memoryInfo: MemoryInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MemoryDetailRow(icon: "app.badge", title: "App Usage:", value: formatBytes(memoryInfo.appUsed))
            MemoryDetailRow(icon: "apps.iphone", title: "Other Apps:", value: formatBytes(memoryInfo.activeAndInactive))
            MemoryDetailRow(icon: "gear", title: "System:", value: formatBytes(memoryInfo.systemUsed))
            
            if memoryInfo.compressed > 0 {
                MemoryDetailRow(icon: "archivebox", title: "Compressed:", value: formatBytes(memoryInfo.compressed))
            }
            
            MemoryDetailRow(icon: "plus.square.dashed", title: "Available:", value: formatBytes(memoryInfo.free))
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
                .foregroundColor(.blue)
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

struct BenchmarkControlsView: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let runBenchmark: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if benchmark.isRunning {
                BenchmarkProgressView(benchmark: benchmark)
            } else {
                BenchmarkButtonsView(benchmark: benchmark, runBenchmark: runBenchmark)
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
    }
}

struct BenchmarkProgressView: View {
    @ObservedObject var benchmark: MemoryBenchmark
    
    var body: some View {
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
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct BenchmarkButtonsView: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let runBenchmark: () -> Void
    
    var body: some View {
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
            .disabled(benchmark.isRunning)
            
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
}

struct LatestResultView: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let gradientColors: [Color]
    let showDetailsSheet: (BenchmarkResult) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Latest Result")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                
                if let last = benchmark.previousResults.last {
                    Button("Details") {
                        let result = BenchmarkResult(data: last, gradientColors: gradientColors)
                        showDetailsSheet(result)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            
            if let last = benchmark.previousResults.last,
               let gb = last["gb"] as? Double,
               let iosVersion = last["iosVersion"] as? String,
               let deviceType = last["deviceType"] as? String,
               let deviceRAM = last["deviceRAM"] as? Double {
                
                ResultDisplayView(
                    gb: gb,
                    iosVersion: iosVersion,
                    deviceType: deviceType,
                    deviceRAM: deviceRAM,
                    gradientColors: gradientColors
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ResultDisplayView: View {
    let gb: Double
    let iosVersion: String
    let deviceType: String
    let deviceRAM: Double
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Text(String(format: "%.2f GB", gb))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.clear)
                    .background(
                        FluidGradient(colors: gradientColors)
                        .mask(Text(String(format: "%.2f GB", gb)).font(.system(size: 36, weight: .bold)))
                    )
                Text(String(format: "%.2f GB", gb))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.clear)
                    .shadow(color: Color.purple.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
            }
            
            Text("Maximum Allocatable Memory")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Divider().padding(.vertical, 8)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Device")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(deviceType)
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
    
    private func formatDate() -> String {
        return DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .none
        )
    }
}

extension UIDevice {
    var isIPad: Bool {
        return userInterfaceIdiom == .pad
    }
}

struct ContentView: View {
    var body: some View {
        Group {
            if UIDevice.current.isIPad {
                iPadContentView()
            } else {
                iPhoneContentView()
            }
        }
    }
}

struct iPhoneContentView: View {
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
            ScrollView {
                VStack(spacing: 24) {
                    AppTitleView(gradientColors: gradientColors)
                    MemoryStatusView(memoryInfo: memoryInfo)
                    BenchmarkControlsView(benchmark: benchmark, runBenchmark: runBenchmark)
                    
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
        
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !benchmark.isRunning {
                DispatchQueue.main.async {
                    memoryInfo = getMemoryInfo()
                }
            }
        }
    }
    
    private func runBenchmark() {
        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = nil
        
        benchmark.clearMemory()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.benchmark.startBenchmark { finalResult in
                DispatchQueue.main.async {
                    self.memoryInfo = getMemoryInfo()
                    self.startMemoryMonitoring()
                }
            }
        }
    }
}

struct ResultsSheetView: View {
    @ObservedObject var benchmark: MemoryBenchmark
    let gradientColors: [Color]
    @Environment(\.dismiss) private var dismiss
    @State private var detailResult: BenchmarkResult? = nil
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(benchmark.previousResults.enumerated().reversed()), id: \.offset) { _, result in
                    if let gb = result["gb"] as? Double,
                       let iosVersion = result["iosVersion"] as? String,
                       let deviceType = result["deviceType"] as? String,
                       let deviceRAM = result["deviceRAM"] as? Double {
                        listItemView(gb: gb, iosVersion: iosVersion, deviceType: deviceType, deviceRAM: deviceRAM, result: result)
                    }
                }
            }
            .navigationTitle("Benchmark History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
            .sheet(item: $detailResult) { benchmarkResult in
                BenchmarkDetailView(result: benchmarkResult.data, gradientColors: benchmarkResult.gradientColors)
            }
        }
    }
    
    private func listItemView(gb: Double, iosVersion: String, deviceType: String, deviceRAM: Double, result: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.2f GB", gb))
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text("\(deviceType) • OS \(iosVersion)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    let percentage = (gb / deviceRAM) * 100
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("of device RAM")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            if deviceRAM > 0 {
                let normalizedValue = min(gb / deviceRAM, 1.0)
                ProgressView(value: normalizedValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 0.7)
            }
            
            if gb > 0 {
                Button("Details") {
                    let benchmarkResult = BenchmarkResult(data: result, gradientColors: gradientColors)
                    detailResult = benchmarkResult
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
