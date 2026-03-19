// PerformanceMonitor.swift
// MacOS-Dino – CPU/GPU/RAM Performans İzleme
// Hedef: CPU ≤ %0.4, RAM ≤ 135MB, Energy Impact ≤ 8

import Foundation
import IOKit
import Darwin
import QuartzCore

final class PerformanceMonitor {

    // MARK: - Callback

    var onUpdate: ((Double, Double, Double) -> Void)? // (cpu, memory, fps)

    // MARK: - State

    private var timer: Timer?
    private var previousCPUInfo: host_cpu_load_info?
    private var frameCount: Int = 0
    private var lastFPSCheck: CFTimeInterval = 0

    // MARK: - Thresholds

    static let maxCPUPercent: Double = 0.5
    static let maxMemoryMB: Double = 135.0
    static let maxEnergyImpact: Double = 8.0

    // MARK: - Monitoring

    func startMonitoring(interval: TimeInterval = 2.0) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            let cpu = self.getCPUUsage()
            let memory = self.getMemoryUsage()
            let fps = self.getCurrentFPS()
            self.onUpdate?(cpu, memory, fps)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func incrementFrame() {
        frameCount += 1
    }

    // MARK: - CPU Usage

    func getCPUUsage() -> Double {
        var cpuInfo: host_cpu_load_info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &cpuInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0.0 }

        let user = Double(cpuInfo.cpu_ticks.0)
        let system = Double(cpuInfo.cpu_ticks.1)
        let idle = Double(cpuInfo.cpu_ticks.2)
        let nice = Double(cpuInfo.cpu_ticks.3)

        let total = user + system + idle + nice

        if let prev = previousCPUInfo {
            let prevTotal = Double(prev.cpu_ticks.0 + prev.cpu_ticks.1 + prev.cpu_ticks.2 + prev.cpu_ticks.3)
            let prevIdle = Double(prev.cpu_ticks.2)

            let totalDiff = total - prevTotal
            let idleDiff = idle - prevIdle

            previousCPUInfo = cpuInfo

            guard totalDiff > 0 else { return 0.0 }
            return ((totalDiff - idleDiff) / totalDiff) * 100.0
        }

        previousCPUInfo = cpuInfo
        return 0.0
    }

    // MARK: - Memory Usage

    func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0.0 }

        // Byte → MB
        return Double(info.resident_size) / (1024.0 * 1024.0)
    }

    // MARK: - FPS Tracking

    func getCurrentFPS() -> Double {
        let now = CACurrentMediaTime()
        let elapsed = now - lastFPSCheck

        guard elapsed > 0 else { return 0 }

        let fps = Double(frameCount) / elapsed
        frameCount = 0
        lastFPSCheck = now

        return fps
    }

    // MARK: - Performance Warnings

    func checkPerformance() -> [PerformanceWarning] {
        var warnings: [PerformanceWarning] = []

        let cpu = getCPUUsage()
        if cpu > Self.maxCPUPercent {
            warnings.append(.highCPU(current: cpu, max: Self.maxCPUPercent))
        }

        let memory = getMemoryUsage()
        if memory > Self.maxMemoryMB {
            warnings.append(.highMemory(current: memory, max: Self.maxMemoryMB))
        }

        return warnings
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - Performance Warning Types

enum PerformanceWarning {
    case highCPU(current: Double, max: Double)
    case highMemory(current: Double, max: Double)
    case highEnergy(current: Double, max: Double)
    case lowFPS(current: Double, target: Double)

    var message: String {
        switch self {
        case .highCPU(let current, let max):
            return "⚠️ CPU kullanımı yüksek: %\(String(format: "%.1f", current)) (hedef: ≤%\(String(format: "%.1f", max)))"
        case .highMemory(let current, let max):
            return "⚠️ RAM kullanımı yüksek: \(String(format: "%.0f", current))MB (hedef: ≤\(String(format: "%.0f", max))MB)"
        case .highEnergy(let current, let max):
            return "⚠️ Enerji etkisi yüksek: \(String(format: "%.1f", current)) (hedef: ≤\(String(format: "%.1f", max)))"
        case .lowFPS(let current, let target):
            return "⚠️ FPS düşük: \(String(format: "%.0f", current)) (hedef: \(String(format: "%.0f", target)))"
        }
    }
}
