struct BenchmarkResult: Identifiable {
    let id = UUID()
    let data: [String: Any]
    let gradientColors: [Color]
}
