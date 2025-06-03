# RAMBench: iOS RAM Benchmarking Tool

## Overview
RAMBench is a iOS app designed to benchmark the RAM limits of your iOS device. With recent iOS updates (18.2–18.5) introducing changes to memory management that have caused confusion (specifically for emulation and power-users of the platform), RAMBench provides a clear way to test memory allocation limits specific to your device and iOS version.

The app allocates memory incrementally until it reaches the system’s limit, records the maximum allocated amount alongside the iOS version.

## Features
### These are not 100% accurate, definitely take with a grain of salt
Memory Benchmarking: Allocates memory in chunks until the process is killed.
iOS Version Tracking: Saves benchmark results with the iOS version (e.g., 18.5), allowing comparison across updates.
Real-Time Memory Stats: Updates every second to show:
Total Device RAM
Total Used RAM
This App’s RAM
Free RAM


## How It Works (for nerds)
Benchmarking:

The MemoryBenchmark class allocates memory using malloc in chunks, starting higher and reducing each chunk to up to 16 KB as it nears the system limit.
It tracks the total allocated memory (totalAllocated) and stops when malloc or vm_allocate fails, indicating the RAM limit.
Results are saved in UserDefaults with the model and iOS version and displayed in a list.


Memory Monitoring (WHICH IS NOT ACCURATE):

The MemoryInfo struct retrieves:
Total RAM: From sysctlbyname("hw.memsize"), rounded to standard sizes.
Free RAM: From host_statistics (free page count × page size).
Used RAM: Calculated as total - free, including all non-free memory.
App’s RAM: From task_info(mach_task_self_(), TASK_BASIC_INFO), reporting RAMBench’s own memory.



## Limitations
iOS Restrictions: Mach APIs provide limited per-process memory details due to sandboxing, so metrics are system-wide or app-specific.
Memory Compression: iOS compresses memory, so the app’s reported RAM (e.g., 6 GB allocated) may use less physical RAM (e.g., 5.8 GB).
Rounding: Total RAM is rounded (e.g., 7.98 GB to 8 GB) for simplicity, which may slightly skew calculations.

## Installation
For best result's sideload or build with xcode with the increased memory entitlement (free), the extended virtual addressing entitlement, and the increased debugging memory limit entitlement (both paid). 
IF you only have a free account, I suggest simply downloading it from the app store to save app id's https://apps.apple.com/us/app/rambench/id6745537329

## Contributing
Contributions are welcome! Please submit issues or pull requests for bug fixes, or feature enhancements.

## License
This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0). You are free to share and adapt the material, provided you give appropriate credit and do not use it for commercial purposes.
