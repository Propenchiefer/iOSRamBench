//
//  RAMBenchApp.swift
//  RamBench
//
//  Created by Autumn on 5/16/25.
//

import Foundation
import UIKit
import Darwin.Mach

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let data = Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN))
        let identifier = String(data: data, encoding: .ascii)?
            .trimmingCharacters(in: .controlCharacters) ?? "Unknown"
        
        switch identifier {
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE (1st generation)"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,5": return "iPhone 16e"
        
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad (3rd generation)"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad (4th generation)"
        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad6,11", "iPad6,12": return "iPad (5th generation)"
        case "iPad7,5", "iPad7,6": return "iPad (6th generation)"
        case "iPad7,11", "iPad7,12": return "iPad (7th generation)"
        case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
        case "iPad12,1", "iPad12,2": return "iPad (9th generation)"
        case "iPad13,18", "iPad13,19": return "iPad (10th generation)"
        case "iPad15,7", "iPad15,8": return "iPad (11th generation)"
        
        case "iPad11,3", "iPad11,4": return "iPad Air (3rd generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,8", "iPad14,9": return "iPad Air 11-inch (M2)"
        case "iPad14,10", "iPad14,11": return "iPad Air 13-inch (M2)"
        case "iPad15,3", "iPad15,4": return "iPad Air 11-inch (M3)"
        case "iPad15,5", "iPad15,6": return "iPad Air 13-inch (M3)"
        
        case "iPad6,3", "iPad6,4": return "iPad Pro 9.7-inch"
        case "iPad6,7", "iPad6,8": return "iPad Pro 12.9-inch (1st generation)"
        case "iPad7,1", "iPad7,2": return "iPad Pro 12.9-inch (2nd generation)"
        case "iPad7,3", "iPad7,4": return "iPad Pro 10.5-inch"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro 11-inch (1st generation)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro 12.9-inch (3rd generation)"
        case "iPad8,9", "iPad8,10": return "iPad Pro 11-inch (2nd generation)"
        case "iPad8,11", "iPad8,12": return "iPad Pro 12.9-inch (4th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (M1)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (M1)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (M2)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (M2)"
        case "iPad16,3", "iPad16,4": return "iPad Pro 11-inch (M4)"
        case "iPad16,5", "iPad16,6": return "iPad Pro 13-inch (M4)"
        
        case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad mini"
        case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad mini 3"
        case "iPad5,1", "iPad5,2": return "iPad mini 4"
        case "iPad11,1", "iPad11,2": return "iPad mini (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        
        default:
            return identifier
        }
    }
}
enum AllocationType {
    case vmAlloc, malloc
}

class MemoryBenchmark: ObservableObject {
    @Published var totalAllocated: Int = 0
    @Published var actualAllocatedMemory: UInt64 = 0
    @Published var previousResults: [[String: Any]] = []
    @Published var isRunning = false
    
    private var allocatedPointers: [(UnsafeMutableRawPointer?, Int)] = []
    private var mallocPointers: [(UnsafeMutableRawPointer?, Int)] = []
    private let storageKey = "benchmarks_data"
    
    private let GB = 1024 * 1024 * 1024
    private let MB = 1024 * 1024
    private let KB = 1024
    
    let deviceRAM: Double
    private let isModernDevice: Bool
    private let isiPad: Bool
    
    init() {
        let totalRAM = Double(getRoundedTotalMemory()) / (1024.0 * 1024.0 * 1024.0)
        deviceRAM = totalRAM
        
        let model = UIDevice.current.modelName
        isModernDevice = model.contains("M1") || model.contains("M2") || model.contains("M3") ||
                        model.contains("M4") || model.contains("iPhone 12") || model.contains("iPhone 13") ||
                        model.contains("iPhone 14") || model.contains("iPhone 15") || model.contains("iPhone 16")
        isiPad = model.contains("iPad")
        
        loadResults()
    }
    
    func startBenchmark(completion: @escaping (Double) -> Void) {
        guard !isRunning else { return }
        
        isRunning = true
        totalAllocated = 0
        actualAllocatedMemory = 0
        allocatedPointers.removeAll()
        mallocPointers.removeAll()
        
        saveInitialResult()
        performAllocation(completion: completion)
    }
    private func captureMemorySnapshot() -> MemoryInfo {
        let total = getRoundedTotalMemory()
        let (free, active, inactive, wired, compressed, speculative, purgeable) = getDetailedMemoryUsage()
        let baseAppMemory = getAppMemoryUsage()
        
        let availableMemory = free + speculative + purgeable
        let systemMemory = wired
        let totalActiveInactive = active + inactive
        let otherAppsMemory = totalActiveInactive > baseAppMemory ?
                             totalActiveInactive - baseAppMemory : 0
        let totalUsedMemory = total - availableMemory
        let ramSizeGB = Double(total) / (1024.0 * 1024.0 * 1024.0)
        
        return MemoryInfo(
            total: total,
            used: totalUsedMemory,
            activeAndInactive: otherAppsMemory,
            free: availableMemory,
            systemUsed: systemMemory,
            appUsed: baseAppMemory,
            compressed: compressed,
            ramSizeGB: ramSizeGB
        )
    }
    private func saveMemorySnapshot(_ memorySnapshot: MemoryInfo) {
        var results = previousResults
        if !results.isEmpty {
            let lastIndex = results.count - 1
            results[lastIndex]["memorySnapshot"] = [
                "total": memorySnapshot.total,
                "used": memorySnapshot.used,
                "activeAndInactive": memorySnapshot.activeAndInactive,
                "free": memorySnapshot.free,
                "systemUsed": memorySnapshot.systemUsed,
                "appUsed": memorySnapshot.appUsed,
                "compressed": memorySnapshot.compressed
            ]
            
            UserDefaults.standard.set(results, forKey: storageKey)
            
            DispatchQueue.main.async {
                self.previousResults = results
            }
            
            print("DEBUG: Saved memory snapshot - system: \(memorySnapshot.systemUsed), other apps: \(memorySnapshot.activeAndInactive), available: \(memorySnapshot.free)")
        }
    }
    
    private func saveInitialResult() {
        var saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        let timestamp = Date()
        
        let newResult: [String: Any] = [
            "gb": 0.0,
            "iosVersion": UIDevice.current.systemVersion,
            "deviceRAM": deviceRAM,
            "deviceType": UIDevice.current.modelName,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        
        saved.append(newResult)
        UserDefaults.standard.set(saved, forKey: storageKey)
        
        DispatchQueue.main.async {
            self.previousResults = saved
        }
    }
    
    private func performAllocation(completion: @escaping (Double) -> Void) {
        let delay = deviceRAM > 8.0 ? 0.02 : 0.04
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let chunkSize = self.calculateChunkSize()
            let allocType = self.selectAllocationType()
            
            let success = self.allocateMemory(size: chunkSize, type: allocType)
            
            if success {
                let currentMemorySnapshot = self.captureMemorySnapshot()
                self.saveMemorySnapshot(currentMemorySnapshot)
                
                DispatchQueue.main.async {
                    self.totalAllocated = Int(self.actualAllocatedMemory)
                    self.updateProgress()
                }
                self.performAllocation(completion: completion)
            } else {
                self.attemptSmallerAllocation(originalSize: chunkSize, completion: completion)
            }
        }
    }
    
    private func calculateChunkSize() -> Int {
        let allocatedGB = Double(actualAllocatedMemory) / Double(GB)
        let percentage = allocatedGB / deviceRAM
        
        var multiplier = isModernDevice ? 1.2 : 1.0
        if isiPad { multiplier *= 1.3 }
        
        let baseSize = determineBaseSize(for: percentage)
        return max(baseSize, Int(Double(baseSize) * multiplier))
    }
    
    private func determineBaseSize(for percentage: Double) -> Int {
        switch percentage {
        case 0.95...:
            return deviceRAM >= 16.0 ? 2 * MB :
                   deviceRAM >= 12.0 ? 1 * MB :
                   deviceRAM >= 8.0 ? 512 * KB : 32 * KB
        case 0.90..<0.95:
            return deviceRAM >= 16.0 ? 4 * MB :
                   deviceRAM >= 12.0 ? 2 * MB :
                   deviceRAM >= 8.0 ? 1 * MB : 128 * KB
        case 0.85..<0.90:
            return deviceRAM >= 16.0 ? 8 * MB :
                   deviceRAM >= 12.0 ? 4 * MB :
                   deviceRAM >= 8.0 ? 2 * MB : 512 * KB
        case 0.80..<0.85:
            return deviceRAM >= 12.0 ? 4 * MB : 1 * MB
        case 0.75..<0.80:
            return deviceRAM >= 12.0 ? 8 * MB : 2 * MB
        case 0.70..<0.75:
            return deviceRAM >= 12.0 ? 12 * MB : 4 * MB
        case 0.60..<0.70:
            return deviceRAM >= 12.0 ? 16 * MB : 8 * MB
        case 0.50..<0.60:
            return deviceRAM >= 12.0 ? 24 * MB : 12 * MB
        case 0.40..<0.50:
            return deviceRAM >= 12.0 ? 32 * MB : 16 * MB
        case 0.30..<0.40:
            return deviceRAM >= 12.0 ? 48 * MB : 24 * MB
        case 0.20..<0.30:
            return deviceRAM >= 12.0 ? 64 * MB : 32 * MB
        default:
            return isiPad ? (deviceRAM >= 12.0 ? 96 * MB : 48 * MB) :
                           (deviceRAM >= 12.0 ? 64 * MB : 32 * MB)
        }
    }
    
    private func selectAllocationType() -> AllocationType {
        let percentage = Double(actualAllocatedMemory) / Double(GB) / deviceRAM
        return percentage < 0.6 ? .vmAlloc : .malloc
    }
    
    private func allocateMemory(size: Int, type: AllocationType) -> Bool {
        switch type {
        case .vmAlloc:
            return allocateWithVM(size: size)
        case .malloc:
            return allocateWithMalloc(size: size)
        }
    }
    
    private func allocateWithVM(size: Int) -> Bool {
        var address: vm_address_t = 0
        let result = vm_allocate(mach_task_self_, &address, vm_size_t(size), VM_FLAGS_ANYWHERE)
        
        guard result == KERN_SUCCESS else { return false }
        
        let ptr = UnsafeMutableRawPointer(bitPattern: address)
        guard let validPtr = ptr, verifyVMAllocation(ptr: validPtr, size: size) else {
            if let p = ptr {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: p), vm_size_t(size))
            }
            return false
        }
        
        allocatedPointers.append((validPtr, size))
        touchVMMemory(ptr: validPtr, size: size)
        actualAllocatedMemory += UInt64(size)
        return true
    }
    
    private func allocateWithMalloc(size: Int) -> Bool {
        guard let ptr = malloc(size), verifyMallocAllocation(ptr: ptr, size: size) else {
            return false
        }
        
        mallocPointers.append((ptr, size))
        memset(ptr, 1, size)
        actualAllocatedMemory += UInt64(size)
        return true
    }
    
    private func verifyVMAllocation(ptr: UnsafeMutableRawPointer, size: Int) -> Bool {
        let pageSize = 4096
        let testPoints = min(5, size / pageSize)
        
        for i in 0..<testPoints {
            let offset = i * pageSize
            let testValue = UInt8.random(in: 1...255)
            ptr.storeBytes(of: testValue, toByteOffset: offset, as: UInt8.self)
            guard ptr.load(fromByteOffset: offset, as: UInt8.self) == testValue else {
                return false
            }
        }
        return testPoints > 0
    }
    
    private func verifyMallocAllocation(ptr: UnsafeMutableRawPointer, size: Int) -> Bool {
        let testPoints = [0, size/4, size/2, 3*size/4, size-1]
        
        for point in testPoints where point < size {
            let testValue = UInt8.random(in: 1...255)
            ptr.storeBytes(of: testValue, toByteOffset: point, as: UInt8.self)
            guard ptr.load(fromByteOffset: point, as: UInt8.self) == testValue else {
                return false
            }
        }
        return true
    }
    
    private func touchVMMemory(ptr: UnsafeMutableRawPointer, size: Int) {
        let pageSize = 4096
        var offset = 0
        while offset < size {
            ptr.storeBytes(of: UInt8(1), toByteOffset: offset, as: UInt8.self)
            _ = ptr.load(fromByteOffset: offset, as: UInt8.self)
            offset += pageSize
        }
    }
    
    private func attemptSmallerAllocation(originalSize: Int, completion: @escaping (Double) -> Void) {
        let reduction = isiPad ? 2.0 : 1.6
        let smallerSize = max(1024, Int(Double(originalSize) / reduction)) // min 1KB
        let allocType = selectAllocationType()
        
        let success = allocateMemory(size: smallerSize, type: allocType)
        
        if success {
            let currentMemorySnapshot = captureMemorySnapshot()
            saveMemorySnapshot(currentMemorySnapshot)
            
            DispatchQueue.main.async {
                self.totalAllocated = Int(self.actualAllocatedMemory)
                self.updateProgress()
            }
            self.performAllocation(completion: completion)
        } else {
            attemptSmallerAllocation(originalSize: smallerSize, completion: completion)
        }
    }
    
    private func finalizeBenchmark(completion: @escaping (Double) -> Void) {
        isRunning = false
        let totalGB = Double(actualAllocatedMemory) / Double(GB)
        completion(totalGB)
    }
    
    private func updateProgress(finalResult: Double? = nil, memoryInfo: MemoryInfo? = nil) {
        let gb = finalResult ?? (Double(actualAllocatedMemory) / Double(GB))
        saveProgress(gb, memoryInfo: memoryInfo)
    }
    
    func clearMemory() {
        allocatedPointers.forEach { ptr, size in
            if let p = ptr {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: p), vm_size_t(size))
            }
        }
        allocatedPointers.removeAll()
        
        mallocPointers.forEach { ptr, _ in
            if let p = ptr {
                free(p)
            }
        }
        mallocPointers.removeAll()
        
        totalAllocated = 0
        actualAllocatedMemory = 0
        isRunning = false
    }
    
    func clearSavedResults() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        previousResults = []
    }
    
    private func saveProgress(_ totalGB: Double, memoryInfo: MemoryInfo? = nil) {
        var results = previousResults
        if results.isEmpty {
            var newResult: [String: Any] = [
                "gb": totalGB,
                "iosVersion": UIDevice.current.systemVersion,
                "deviceRAM": deviceRAM,
                "deviceType": UIDevice.current.modelName,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            if let memInfo = memoryInfo {
                newResult["memoryInfo"] = [
                    "total": memInfo.total,
                    "used": memInfo.used,
                    "activeAndInactive": memInfo.activeAndInactive,
                    "free": memInfo.free,
                    "systemUsed": memInfo.systemUsed,
                    "appUsed": memInfo.appUsed,
                    "compressed": memInfo.compressed
                ]
            }
            
            results.append(newResult)
        } else {
            results[results.count - 1]["gb"] = totalGB
            
            if let memInfo = memoryInfo {
                results[results.count - 1]["memoryInfo"] = [
                    "total": memInfo.total,
                    "used": memInfo.used,
                    "activeAndInactive": memInfo.activeAndInactive,
                    "free": memInfo.free,
                    "systemUsed": memInfo.systemUsed,
                    "appUsed": memInfo.appUsed,
                    "compressed": memInfo.compressed
                ]
            }
        }
        
        UserDefaults.standard.set(results, forKey: storageKey)
        
        DispatchQueue.main.async {
            self.previousResults = results
        }
    }
    
    private func loadResults() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] {
            previousResults = saved
        }
    }
}
