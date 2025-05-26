import Darwin
import Darwin.Mach
import Foundation
import UIKit

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
    let result = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, UInt32(TASK_BASIC_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? UInt64(taskInfo.resident_size) : 0
}

func getMemoryPressure() -> Float {
    var pressureLevel: DispatchSource.MemoryPressureEvent = .normal
    let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: nil)
    source.setEventHandler {
        pressureLevel = source.mask
    }
    
    switch pressureLevel {
    case .normal:
        return 0.0
    case .warning:
        return 0.5
    case .critical:
        return 1.0
    default:
        return 0.0
    }
}

func getDetailedMemoryUsage() -> (free: UInt64, active: UInt64, inactive: UInt64, wired: UInt64, compressed: UInt64, speculative: UInt64) {
    var pageSize: vm_size_t = 0
    let pageSizeResult = host_page_size(mach_host_self(), &pageSize)
    if pageSizeResult != KERN_SUCCESS {
        return (0, 0, 0, 0, 0, 0)
    }
    
    var stats = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    
    let statsResult = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    
    if statsResult != KERN_SUCCESS {
        var oldStats = vm_statistics_data_t()
        var oldCount = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size)
        
        let oldResult = withUnsafeMutablePointer(to: &oldStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(oldCount)) {
                host_statistics(mach_host_self(), HOST_VM_INFO, $0, &oldCount)
            }
        }
        
        if oldResult != KERN_SUCCESS {
            return (0, 0, 0, 0, 0, 0)
        }
        
        let free = UInt64(oldStats.free_count) * UInt64(pageSize)
        let active = UInt64(oldStats.active_count) * UInt64(pageSize)
        let inactive = UInt64(oldStats.inactive_count) * UInt64(pageSize)
        let wired = UInt64(oldStats.wire_count) * UInt64(pageSize)
        
        return (free, active, inactive, wired, 0, 0)
    }
    
    let free = UInt64(stats.free_count) * UInt64(pageSize)
    let active = UInt64(stats.active_count) * UInt64(pageSize)
    let inactive = UInt64(stats.inactive_count) * UInt64(pageSize)
    let wired = UInt64(stats.wire_count) * UInt64(pageSize)
    let compressed = UInt64(stats.compressor_page_count) * UInt64(pageSize)
    let speculative = UInt64(stats.speculative_count) * UInt64(pageSize)
    
    return (free, active, inactive, wired, compressed, speculative)
}

func getDeviceMemoryProfile() -> (ramGB: Double, isM1OrLater: Bool, deviceFamily: String) {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        let scalar = UnicodeScalar(UInt8(value))
        return identifier + String(scalar)
    }
    
    let totalRAM = Double(getTotalMemory()) / (1024.0 * 1024.0 * 1024.0)
    let isM1OrLater = identifier.contains("arm64") || identifier.hasPrefix("iPhone14") || identifier.hasPrefix("iPhone15") || identifier.hasPrefix("iPhone16") || identifier.hasPrefix("iPad13") || identifier.hasPrefix("iPad14") || identifier.hasPrefix("iPad15")
    
    let deviceFamily: String
    if identifier.hasPrefix("iPad") {
        deviceFamily = "iPad"
    } else if identifier.hasPrefix("iPhone") {
        deviceFamily = "iPhone"
    } else {
        deviceFamily = "Unknown"
    }
    
    return (totalRAM, isM1OrLater, deviceFamily)
}

struct MemoryInfo {
    let total: UInt64
    let used: UInt64
    let activeAndInactive: UInt64
    let free: UInt64
    let systemUsed: UInt64
    let appUsed: UInt64
    let compressed: UInt64
    let ramSizeGB: Double
    let memoryPressure: Float
    
    var description: String {
        let gb = 1024.0 * 1024.0 * 1024.0
        let mb = 1024.0 * 1024.0
        return """
        Device RAM: \(String(format: "%.1f", Double(total) / gb)) GB
        Free: \(String(format: "%.2f", Double(free) / gb)) GB
        App Usage: \(String(format: "%.1f", Double(appUsed) / mb)) MB
        System Usage: \(String(format: "%.2f", Double(systemUsed) / gb)) GB
        Other Apps: \(String(format: "%.2f", Double(activeAndInactive) / gb)) GB
        Compressed: \(String(format: "%.2f", Double(compressed) / gb)) GB
        """
    }
}

func getMemoryInfo() -> MemoryInfo {
    let total = getRoundedTotalMemory()
    let (free, active, inactive, wired, compressed, speculative) = getDetailedMemoryUsage()
    let appMemory = getAppMemoryUsage()
    let memoryPressure = getMemoryPressure()
    
    let activeAndInactive = (active + inactive + speculative) > appMemory ? (active + inactive + speculative) - appMemory : 0
    let used = total - free
    let ramSizeGB = Double(total) / (1024.0 * 1024.0 * 1024.0)
    
    return MemoryInfo(
        total: total,
        used: used,
        activeAndInactive: activeAndInactive,
        free: free,
        systemUsed: wired,
        appUsed: appMemory,
        compressed: compressed,
        ramSizeGB: ramSizeGB,
        memoryPressure: memoryPressure
    )
}
