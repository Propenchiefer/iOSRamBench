//
//  BenchmarkResult.swift
//  RamBench
//
//  Created by Autumn on 8/3/25.
//

import SwiftUI

struct BenchmarkResult: Identifiable {
    let id = UUID()
    let data: [String: Any]
    let gradientColors: [Color]
}
