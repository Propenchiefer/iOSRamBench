import Foundation
import UIKit
import Darwin.Mach
import Metal

class MemoryBenchmark: ObservableObject {
    @Published var totalAllocated: Int = 0
    @Published var previousResults: [[String: Any]] = []
    @Published var currentMemoryInfo: MemoryInfo?
    
    private var allocatedPointers: [(pointer: UnsafeMutableRawPointer?, size: Int)] = []
    private var mallocPointers: [UnsafeMutableRawPointer?] = []
    private var metalBuffers: [MTLBuffer] = []
    private var metalTextures: [MTLTexture] = []
    private let storageKey = "benchmarks_data"
    private var isRunning = false
    private let GB = 1024 * 1024 * 1024
    private let MB = 1024 * 1024
    private let KB = 1024
    private var metalDevice: MTLDevice?
    
    private var deviceProfile: (ramGB: Double, isM1OrLater: Bool, deviceFamily: String)
    
    init() {
        deviceProfile = getDeviceMemoryProfile()
        metalDevice = MTLCreateSystemDefaultDevice()
        loadPreviousResults()
        currentMemoryInfo = getMemoryInfo()
    }
    
    func updateMemoryInfo() {
        currentMemoryInfo = getMemoryInfo()
    }
    
    func startBenchmark(completion: @escaping (Double) -> Void) {
        guard !isRunning else { return }
        isRunning = true
        totalAllocated = 0
        allocatedPointers.removeAll()
        mallocPointers.removeAll()
        metalBuffers.removeAll()
        metalTextures.removeAll()
        
        updateMemoryInfo()
        let iosVersion = UIDevice.current.systemVersion
        let deviceRAM = deviceProfile.ramGB
        let deviceType = deviceProfile.deviceFamily
        
        var saved = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
        saved.append([
            "gb": 0.0,
            "iosVersion": iosVersion,
            "deviceRAM": deviceRAM,
            "deviceType": deviceType
        ])
        UserDefaults.standard.set(saved, forKey: storageKey)
        DispatchQueue.main.async { self.previousResults = saved }
        
        allocateNext(completion: completion)
    }
    
    private func calculateChunkSize(totalAllocatedSoFar: Int, ramGB: Double) -> Int {
        let allocatedGB = Double(totalAllocatedSoFar) / Double(GB)
        let allocatedPercentage = allocatedGB / ramGB
        let isIPad = deviceProfile.deviceFamily == "iPad"
        let isM1OrLater = deviceProfile.isM1OrLater
        
        let baseMultiplier = isM1OrLater ? 1.5 : 1.0
        let deviceMultiplier = isIPad ? 2.0 : 1.0
        
        if allocatedPercentage >= 0.98 {
            return max(64 * KB, Int(Double(64 * KB) * baseMultiplier))
        } else if allocatedPercentage >= 0.96 {
            return max(128 * KB, Int(Double(128 * KB) * baseMultiplier))
        } else if allocatedPercentage >= 0.94 {
            return max(256 * KB, Int(Double(256 * KB) * baseMultiplier))
        } else if allocatedPercentage >= 0.92 {
            return max(512 * KB, Int(Double(512 * KB) * baseMultiplier))
        } else if allocatedPercentage >= 0.90 {
            return max(1 * MB, Int(Double(1 * MB) * baseMultiplier))
        } else if allocatedPercentage >= 0.85 {
            return max(2 * MB, Int(Double(2 * MB) * baseMultiplier))
        } else if allocatedPercentage >= 0.80 {
            return max(4 * MB, Int(Double(4 * MB) * baseMultiplier))
        } else if allocatedPercentage >= 0.75 {
            return max(8 * MB, Int(Double(8 * MB) * baseMultiplier))
        } else if allocatedPercentage >= 0.70 {
            return max(12 * MB, Int(Double(12 * MB) * baseMultiplier * deviceMultiplier))
        } else if allocatedPercentage >= 0.60 {
            return max(16 * MB, Int(Double(16 * MB) * baseMultiplier * deviceMultiplier))
        } else if allocatedPercentage >= 0.50 {
            return max(24 * MB, Int(Double(24 * MB) * baseMultiplier * deviceMultiplier))
        } else if allocatedPercentage >= 0.40 {
            return max(32 * MB, Int(Double(32 * MB) * baseMultiplier * deviceMultiplier))
        } else if allocatedPercentage >= 0.30 {
            return max(48 * MB, Int(Double(48 * MB) * baseMultiplier * deviceMultiplier))
        } else if allocatedPercentage >= 0.20 {
            return max(64 * MB, Int(Double(64 * MB) * baseMultiplier * deviceMultiplier))
        } else {
            let baseSize = isIPad ? (128 * MB) : (64 * MB)
            return max(baseSize, Int(Double(baseSize) * baseMultiplier * deviceMultiplier))
        }
    }
    
    private func allocateNext(completion: @escaping (Double) -> Void) {
        let delayMultiplier = deviceProfile.ramGB > 8.0 ? 0.02 : 0.05
        let delay = max(0.01, delayMultiplier)
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let memInfo = self.currentMemoryInfo ?? getMemoryInfo()
            let ramSizeGB = memInfo.ramSizeGB
            
            let chunk = self.calculateChunkSize(
                totalAllocatedSoFar: self.totalAllocated,
                ramGB: ramSizeGB
            )
            
            let allocationType = self.chooseAllocationType(allocatedPercentage: Double(self.totalAllocated) / Double(self.GB) / ramSizeGB)
            let success = self.allocateMemory(size: chunk, type: allocationType)
            
            if success {
                DispatchQueue.main.async {
                    self.totalAllocated += chunk
                    let totalGB = max(
                        Double(self.totalAllocated) / Double(self.GB),
                        Double(self.getPhysicalMemoryFootprint()) / Double(self.GB)
                    )
                    self.saveIntermediate(totalGB)
                    
                    self.allocateNext(completion: completion)
                }
            } else {
                self.tryWithSmallerChunk(currentChunk: chunk, completion: completion)
            }
        }
    }
    
    private func chooseAllocationType(allocatedPercentage: Double) -> AllocationType {
        if allocatedPercentage < 0.3 {
            return .vmAllocate
        } else if allocatedPercentage < 0.6 {
            return [.vmAllocate, .malloc, .metalBuffer].randomElement() ?? .vmAllocate
        } else if allocatedPercentage < 0.8 {
            return [.malloc, .metalBuffer, .metalTexture].randomElement() ?? .malloc
        } else {
            return [.metalBuffer, .metalTexture].randomElement() ?? .metalBuffer
        }
    }
    
    private enum AllocationType {
        case vmAllocate, malloc, metalBuffer, metalTexture
    }
    
    private func allocateMemory(size: Int, type: AllocationType) -> Bool {
        switch type {
        case .vmAllocate:
            return allocateVM(size: size)
        case .malloc:
            return allocateMalloc(size: size)
        case .metalBuffer:
            return allocateMetalBuffer(size: size)
        case .metalTexture:
            return allocateMetalTexture(size: size)
        }
    }
    
    private func allocateVM(size: Int) -> Bool {
        var address: vm_address_t = 0
        let kr = vm_allocate(mach_task_self_, &address, vm_size_t(size), VM_FLAGS_ANYWHERE)
        if kr == KERN_SUCCESS {
            let ptr = UnsafeMutableRawPointer(bitPattern: address)
            if let ptr = ptr {
                memset(ptr, 1, size)
                allocatedPointers.append((ptr, size))
                return true
            }
        }
        return false
    }
    
    private func allocateMalloc(size: Int) -> Bool {
        let ptr = malloc(size)
        if let ptr = ptr {
            memset(ptr, 1, size)
            mallocPointers.append(ptr)
            return true
        }
        return false
    }
    
    private func allocateMetalBuffer(size: Int) -> Bool {
        guard let device = metalDevice else { return false }
        guard let buffer = device.makeBuffer(length: size, options: [.storageModeShared]) else { return false }
        
        let contents = buffer.contents()
        memset(contents, 1, size)
        metalBuffers.append(buffer)
        return true
    }
    
    private func allocateMetalTexture(size: Int) -> Bool {
        guard let device = metalDevice else { return false }
        
        let dimension = Int(sqrt(Double(size / 4)))
        guard dimension > 0 else { return false }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: dimension,
            height: dimension,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        
        guard let texture = device.makeTexture(descriptor: descriptor) else { return false }
        
        let region = MTLRegionMake2D(0, 0, dimension, dimension)
        let data = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 1)
        memset(data, 1, size)
        texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: dimension * 4)
        data.deallocate()
        
        metalTextures.append(texture)
        return true
    }
    
    private func tryWithSmallerChunk(currentChunk: Int, completion: @escaping (Double) -> Void) {
        let isIPad = deviceProfile.deviceFamily == "iPad"
        let minimumChunkSize = isIPad ? (512 * KB) : (64 * KB)
        
        if currentChunk <= minimumChunkSize {
            self.isRunning = false
            let totalGB = max(
                Double(self.totalAllocated) / Double(self.GB),
                Double(self.getPhysicalMemoryFootprint()) / Double(self.GB)
            )
            self.saveIntermediate(totalGB)
            completion(totalGB)
            return
        }
        
        let reductionFactor = isIPad ? 2.0 : 1.5
        let smallerChunk = max(minimumChunkSize, Int(Double(currentChunk) / reductionFactor))
        
        let allocationType = self.chooseAllocationType(allocatedPercentage: Double(self.totalAllocated) / Double(self.GB) / self.deviceProfile.ramGB)
        let success = self.allocateMemory(size: smallerChunk, type: allocationType)
        
        if success {
            DispatchQueue.main.async {
                self.totalAllocated += smallerChunk
                let totalGB = max(
                    Double(self.totalAllocated) / Double(self.GB),
                    Double(self.getPhysicalMemoryFootprint()) / Double(self.GB)
                )
                self.saveIntermediate(totalGB)
                self.allocateNext(completion: completion)
            }
        } else {
            self.tryWithSmallerChunk(currentChunk: smallerChunk, completion: completion)
        }
    }
    
    private func getPhysicalMemoryFootprint() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<Int32>.size)
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, UInt32(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? UInt64(taskInfo.phys_footprint) : UInt64(getAppMemoryUsage())
    }
    
    func clearMemory() {
        for (ptr, size) in allocatedPointers {
            if let validPtr = ptr {
                let address = vm_address_t(bitPattern: validPtr)
                vm_deallocate(mach_task_self_, address, vm_size_t(size))
            }
        }
        allocatedPointers.removeAll()
        
        for ptr in mallocPointers {
            if let validPtr = ptr {
                free(validPtr)
            }
        }
        mallocPointers.removeAll()
        
        metalBuffers.removeAll()
        metalTextures.removeAll()
        
        totalAllocated = 0
        isRunning = false
        updateMemoryInfo()
    }
    
    func clearSavedResults() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        previousResults = []
    }
    
    private func saveIntermediate(_ totalGB: Double) {
        var all = previousResults
        if all.isEmpty {
            let memInfo = currentMemoryInfo ?? getMemoryInfo()
            all.append([
                "gb": totalGB,
                "iosVersion": UIDevice.current.systemVersion,
                "deviceRAM": memInfo.ramSizeGB,
                "deviceType": deviceProfile.deviceFamily
            ])
        } else {
            all[all.count - 1]["gb"] = totalGB
        }
        UserDefaults.standard.set(all, forKey: storageKey)
        DispatchQueue.main.async { self.previousResults = all }
    }
    
    private func loadPreviousResults() {
        previousResults = UserDefaults.standard.array(forKey: storageKey) as? [[String: Any]] ?? []
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
