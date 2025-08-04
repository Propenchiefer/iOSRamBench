# RAMBench: iOS RAM Benchmarking Tool

## Overview
RAMBench is a iOS app designed to benchmark the RAM limits of your iOS device. With recent iOS updates (18.2–26) introducing changes to memory management that have caused confusion (specifically for emulation and power-users of the platform), RAMBench provides a clear way to test memory allocation limits specific to your device and iOS version.

The app allocates memory incrementally until it reaches the system’s limit, records the maximum allocated amount alongside the iOS version.

## Features
### These are not 100% accurate, definitely take with a grain of salt
- Memory Benchmarking: Allocates memory in chunks until the process is killed.
- iOS Version Tracking: Saves benchmark results with the iOS version (e.g., 18.5), allowing comparison across updates.
- Detailed Benchmark results
### - Memory Stats, Updates every second to show:
- Total Device RAM
- Total Used RAM
- This App’s RAM
- Free RAM

## Limitations
iOS Restrictions: Mach APIs provide limited per-process memory details due to sandboxing, so metrics are system-wide or app-specific.
Memory Compression: iOS compresses memory, so the app’s reported RAM (e.g., 6 GB allocated) may use less physical RAM (e.g., 5.8 GB).
Rounding: Total RAM is rounded (e.g., 7.98 GB to 8 GB) for simplicity, which may slightly skew calculations.

## Installation
For best result's sideload or build with xcode with the increased memory entitlement (free), the extended virtual addressing entitlement, and the increased debugging memory limit entitlement (both paid). 
If you only have a free account, I suggest simply downloading it from the app store to save app id's https://apps.apple.com/us/app/rambench/id6745537329 

### Why the two paid entitlements?
Throughout my testing i've found both of them slightly increase your per app ram limit, using these along with RamBench (assuming you also use them on a memory heavy application) will yield more accurate result's to your personal limit.

## Contributing
Contributions are welcome! Please submit issues or pull requests for bug fixes, or feature enhancements.

## License
This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0). You are free to share and adapt the material, provided you give appropriate credit and do not use it for commercial purposes.
