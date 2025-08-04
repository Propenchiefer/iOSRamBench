//
//  RAMBenchApp.swift
//  RamBench
//
//  Created by Autumn on 5/16/25.
//

import Darwin
import Darwin.Mach
import Foundation
import UIKit

struct MemoryInfo {
    let total: UInt64
    let used: UInt64
    let activeAndInactive: UInt64
    let free: UInt64
    let systemUsed: UInt64
    let appUsed: UInt64
    let compressed: UInt64
    let ramSizeGB: Double
}

func getTotalMemory() -> UInt64 {
    var size: size_t = MemoryLayout<UInt64>.size
    var totalMemory: UInt64 = 0
    sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)
    return totalMemory
}

func getRoundedTotalMemory() -> UInt64 {
    let totalBytes = getTotalMemory()
    let totalGB = Double(totalBytes) / (1024.0 * 1024.0 * 1024.0)
    let standardSizes = [1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0, 64.0, 128.0]
    let closestSize = standardSizes.min { abs($0 - totalGB) < abs($1 - totalGB) } ?? 8.0
    return UInt64(closestSize * 1024.0 * 1024.0 * 1024.0)
}

func getAppMemoryUsage() -> UInt64 {
    var taskInfo = task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<Int32>.size)
    
    let basicResult = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, UInt32(TASK_BASIC_INFO), $0, &count)
        }
    }
    
    var residentSize: UInt64 = 0
    if basicResult == KERN_SUCCESS {
        residentSize = UInt64(taskInfo.resident_size)
    }
    
    var vmInfo = task_vm_info()
    var vmCount = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<Int32>.size)
    
    let vmResult = withUnsafeMutablePointer(to: &vmInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
            task_info(mach_task_self_, UInt32(TASK_VM_INFO), $0, &vmCount)
        }
    }
    
    if vmResult == KERN_SUCCESS {
        let footprint = UInt64(vmInfo.phys_footprint)
        return max(footprint, residentSize)
    }
    
    return residentSize
}

func getDetailedMemoryUsage() -> (free: UInt64, active: UInt64, inactive: UInt64, wired: UInt64, compressed: UInt64, speculative: UInt64, purgeable: UInt64) {
    var pageSize: vm_size_t = 0
    guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else {
        return (0, 0, 0, 0, 0, 0, 0)
    }
    
    var stats = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    
    let statsResult = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    
    if statsResult == KERN_SUCCESS {
        let free = UInt64(stats.free_count) * UInt64(pageSize)
        let active = UInt64(stats.active_count) * UInt64(pageSize)
        let inactive = UInt64(stats.inactive_count) * UInt64(pageSize)
        let wired = UInt64(stats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(stats.compressor_page_count) * UInt64(pageSize)
        let speculative = UInt64(stats.speculative_count) * UInt64(pageSize)
        let purgeable = UInt64(stats.purgeable_count) * UInt64(pageSize)
        
        return (free, active, inactive, wired, compressed, speculative, purgeable)
    }
    
    // fallback to old method
    var oldStats = vm_statistics_data_t()
    var oldCount = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size)
    
    let oldResult = withUnsafeMutablePointer(to: &oldStats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(oldCount)) {
            host_statistics(mach_host_self(), HOST_VM_INFO, $0, &oldCount)
        }
    }
    
    guard oldResult == KERN_SUCCESS else {
        return (0, 0, 0, 0, 0, 0, 0)
    }
    
    let free = UInt64(oldStats.free_count) * UInt64(pageSize)
    let active = UInt64(oldStats.active_count) * UInt64(pageSize)
    let inactive = UInt64(oldStats.inactive_count) * UInt64(pageSize)
    let wired = UInt64(oldStats.wire_count) * UInt64(pageSize)
    
    return (free, active, inactive, wired, 0, 0, 0)
}

func getMemoryInfo(benchmarkAllocatedMemory: UInt64 = 0) -> MemoryInfo {
    let total = getRoundedTotalMemory()
    let (free, active, inactive, wired, compressed, speculative, purgeable) = getDetailedMemoryUsage()
    let actualAppMemory = getAppMemoryUsage()
    let availableMemory = free + speculative + purgeable
    let systemMemory = wired
    let totalActiveInactive = active + inactive
    let otherAppsMemory = totalActiveInactive > actualAppMemory ? totalActiveInactive - actualAppMemory : 0
    let totalUsedMemory = total - availableMemory
    let ramSizeGB = Double(total) / (1024.0 * 1024.0 * 1024.0)
    
    return MemoryInfo(
        total: total,
        used: totalUsedMemory,
        activeAndInactive: otherAppsMemory,
        free: availableMemory,
        systemUsed: systemMemory,
        appUsed: actualAppMemory,
        compressed: compressed,
        ramSizeGB: ramSizeGB
    )
}

func getMemoryInfoForBenchmark() -> MemoryInfo {
    let total = getRoundedTotalMemory()
    let (free, active, inactive, wired, compressed, speculative, purgeable) = getDetailedMemoryUsage()
    let actualAppMemory = getAppMemoryUsage()
    
    let availableMemory = free + speculative + purgeable
    let systemMemory = wired
    let totalActiveInactive = active + inactive
    let otherAppsMemory = totalActiveInactive > actualAppMemory ?
                         totalActiveInactive - actualAppMemory : 0
    let totalUsedMemory = total - availableMemory
    let ramSizeGB = Double(total) / (1024.0 * 1024.0 * 1024.0)
    
    return MemoryInfo(
        total: total,
        used: totalUsedMemory,
        activeAndInactive: otherAppsMemory,
        free: availableMemory,
        systemUsed: systemMemory,
        appUsed: actualAppMemory,
        compressed: compressed,
        ramSizeGB: ramSizeGB
    )
}
