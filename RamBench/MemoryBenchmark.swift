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
        
        if identifier.contains("iPhone") {
            return "iPhone"
        } else if identifier.contains("iPad") {
            return "iPad"
        } else {
            return identifier
        }
    }
}

class MemoryBenchmark: ObservableObject {
    @Published var totalAllocated: Int = 0
    @Published var previousResults: [[String: Any]] = []
    @Published var currentMemoryInfo: MemoryInfo?
    
    var allocatedPointers: [(UnsafeMutableRawPointer?, Int)] = []
    var mallocPointers: [(UnsafeMutableRawPointer?, Int)] = []
    let storageKey = "benchmarks_data"
    var isRunning = false
    let GB = 1024 * 1024 * 1024
    let MB = 1024 * 1024
    let KB = 1024
    var consecutiveFailures: Int = 0
    let maxFailures = 5
    
    var deviceRAM: Double
    var isNewDevice: Bool
    
    init() {
        // figure out device specs thanks to Stossy11 :3
        let totalRAM = Double(getTotalMemory()) / (1024.0 * 1024.0 * 1024.0)
        deviceRAM = totalRAM
        
        let model = UIDevice.current.modelName
        isNewDevice = model.contains("M1") || model.contains("M2") || model.contains("M3") ||
                     model.contains("M4") || model.contains("iPhone 12") || model.contains("iPhone 13") ||
                     model.contains("iPhone 14") || model.contains("iPhone 15") || model.contains("iPhone 16")
        
        loadResults()
        currentMemoryInfo = getMemoryInfo()
    }
    
    func updateMemoryInfo() {
        currentMemoryInfo = getMemoryInfo()
    }
    
    func startBenchmark(completion: @escaping (Double) -> Void) {
        if isRunning { return }
        
        isRunning = true
        totalAllocated = 0
        consecutiveFailures = 0
        allocatedPointers.removeAll()
        mallocPointers.removeAll()
        updateMemoryInfo()
        
        var saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        saved.append([
            "gb": 0.0,
            "iosVersion": UIDevice.current.systemVersion,
            "deviceRAM": deviceRAM,
            "deviceType": UIDevice.current.modelName
        ])
        UserDefaults.standard.set(saved, forKey: storageKey)
        
        DispatchQueue.main.async {
            self.previousResults = saved
        }
        
        doNextAllocation(completion: completion)
    }
    
    func getChunkSize(totalSoFar: Int) -> Int {
        let allocatedGB = Double(totalSoFar) / Double(GB)
        let percentage = allocatedGB / deviceRAM
        let model = UIDevice.current.modelName
        let isiPad = model.contains("iPad")
        
        var multiplier = 1.0
        if isNewDevice { multiplier = 1.4 }
        if isiPad { multiplier *= 1.8 }
        
        var baseSize: Int
        
        if percentage >= 0.95 {
            baseSize = 64 * KB
        } else if percentage >= 0.90 {
            baseSize = 256 * KB
        } else if percentage >= 0.85 {
            baseSize = 1 * MB
        } else if percentage >= 0.80 {
            baseSize = 2 * MB
        } else if percentage >= 0.75 {
            baseSize = 4 * MB
        } else if percentage >= 0.70 {
            baseSize = 8 * MB
        } else if percentage >= 0.60 {
            baseSize = 16 * MB
        } else if percentage >= 0.50 {
            baseSize = 24 * MB
        } else if percentage >= 0.40 {
            baseSize = 32 * MB
        } else if percentage >= 0.30 {
            baseSize = 48 * MB
        } else if percentage >= 0.20 {
            baseSize = 64 * MB
        } else {
            baseSize = isiPad ? (96 * MB) : (64 * MB)
        }
        
        return max(baseSize, Int(Double(baseSize) * multiplier))
    }
    
    func doNextAllocation(completion: @escaping (Double) -> Void) {
        let delay = deviceRAM > 8.0 ? 0.02 : 0.04
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let currentUsage = self.getRealMemoryUsage()
            let memInfo = getMemoryInfo()
            
            let chunkSize = self.getChunkSize(totalSoFar: Int(currentUsage))
            let allocType = self.pickAllocationType(percentage: Double(currentUsage) / Double(self.GB) / memInfo.ramSizeGB)
            
            if self.tryAllocate(size: chunkSize, type: allocType) {
                DispatchQueue.main.async {
                    let usage = self.getRealMemoryUsage()
                    self.totalAllocated = Int(usage)
                    let gb = Double(usage) / Double(self.GB)
                    self.saveProgress(gb)
                    self.consecutiveFailures = 0
                    self.doNextAllocation(completion: completion)
                }
            } else {
                self.consecutiveFailures += 1
                if self.consecutiveFailures >= self.maxFailures {
                    self.isRunning = false
                    let finalUsage = self.getRealMemoryUsage()
                    let totalGB = Double(finalUsage) / Double(self.GB)
                    self.saveProgress(totalGB)
                    completion(totalGB)
                } else {
                    self.trySmallerSize(originalSize: chunkSize, completion: completion)
                }
            }
        }
    }
    
    func getRealMemoryUsage() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<Int32>.size)
        
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, UInt32(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return UInt64(taskInfo.phys_footprint)
        }
        // Fallback method that doens;t really work
        return getAppMemoryUsage()
    }
    
    func pickAllocationType(percentage: Double) -> AllocType {
        if percentage < 0.6 {
            return .vmAlloc
        } else {
            return .malloc
        }
    }
    
    enum AllocType {
        case vmAlloc, malloc
    }
    
    func tryAllocate(size: Int, type: AllocType) -> Bool {
        var success = false
        
        switch type {
        case .vmAlloc:
            success = allocateWithVM(size: size)
        case .malloc:
            success = allocateWithMalloc(size: size)
        }
        
        if success {
            touchMemory(type: type, size: size)
        }
        
        return success
    }
    
    func touchMemory(type: AllocType, size: Int) {
        switch type {
        case .vmAlloc:
            if let ptr = allocatedPointers.last?.0 {
                let pageSize = 4096
                var offset = 0
                while offset < size {
                    ptr.storeBytes(of: UInt8(1), toByteOffset: offset, as: UInt8.self)
                    offset += pageSize
                }
            }
        case .malloc:
            if let ptr = mallocPointers.last?.0 {
                memset(ptr, 1, size)
            }
        }
    }
    
    func allocateWithVM(size: Int) -> Bool {
        var address: vm_address_t = 0
        let result = vm_allocate(mach_task_self_, &address, vm_size_t(size), VM_FLAGS_ANYWHERE)
        
        if result == KERN_SUCCESS {
            let ptr = UnsafeMutableRawPointer(bitPattern: address)
            allocatedPointers.append((ptr, size))
            return true
        }
        return false
    }
    
    func allocateWithMalloc(size: Int) -> Bool {
        let ptr = malloc(size)
        if ptr != nil {
            mallocPointers.append((ptr, size))
            return true
        }
        return false
    }
    
    func trySmallerSize(originalSize: Int, completion: @escaping (Double) -> Void) {
        let model = UIDevice.current.modelName
        let isiPad = model.contains("iPad")
        let minSize = isiPad ? (256 * KB) : (64 * KB)
        
        if originalSize <= minSize {
            isRunning = false
            let finalUsage = getRealMemoryUsage()
            let totalGB = Double(finalUsage) / Double(GB)
            saveProgress(totalGB)
            completion(totalGB)
            return
        }
        
        let reduction = isiPad ? 2.0 : 1.6
        let smallerSize = max(minSize, Int(Double(originalSize) / reduction))
        
        let usage = getRealMemoryUsage()
        let allocType = pickAllocationType(percentage: Double(usage) / Double(GB) / deviceRAM)
        
        if tryAllocate(size: smallerSize, type: allocType) {
            DispatchQueue.main.async {
                let realUsage = self.getRealMemoryUsage()
                self.totalAllocated = Int(realUsage)
                let totalGB = Double(realUsage) / Double(self.GB)
                self.saveProgress(totalGB)
                self.doNextAllocation(completion: completion)
            }
        } else {
            trySmallerSize(originalSize: smallerSize, completion: completion)
        }
    }
    
    func clearMemory() {
        for (ptr, size) in allocatedPointers {
            if let p = ptr {
                let addr = vm_address_t(bitPattern: p)
                vm_deallocate(mach_task_self_, addr, vm_size_t(size))
            }
        }
        allocatedPointers.removeAll()
        for (ptr, _) in mallocPointers {
            if let p = ptr {
                free(p)
            }
        }
        mallocPointers.removeAll()
        
        totalAllocated = 0
        consecutiveFailures = 0
        isRunning = false
        
        updateMemoryInfo()
    }
    
    func clearSavedResults() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        previousResults = []
    }
    
    func saveProgress(_ totalGB: Double) {
        var results = previousResults
        if results.isEmpty {
            let memInfo = currentMemoryInfo ?? getMemoryInfo()
            results.append([
                "gb": totalGB,
                "iosVersion": UIDevice.current.systemVersion,
                "deviceRAM": memInfo.ramSizeGB,
                "deviceType": UIDevice.current.modelName
            ])
        } else {
            results[results.count - 1]["gb"] = totalGB
        }
        UserDefaults.standard.set(results, forKey: storageKey)
        
        DispatchQueue.main.async {
            self.previousResults = results
        }
    }
    
    func loadResults() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] {
            previousResults = saved
        }
    }
    
    func formatMemorySize(_ bytes: UInt64) -> String {
        if bytes >= UInt64(GB) {
            return String(format: "%.2f GB", Double(bytes) / Double(GB))
        } else if bytes >= UInt64(MB) {
            return String(format: "%.2f MB", Double(bytes) / Double(MB))
        } else if bytes >= UInt64(KB) {
            return String(format: "%.2f KB", Double(bytes) / Double(KB))
        } else {
            return "\(bytes) bytes"
        }
    }
}
