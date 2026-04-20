import Foundation
import QuartzCore
import Darwin

// MARK: - PerformanceMonitor

class PerformanceMonitor: NSObject, ObservableObject {
    @Published var fps: Int = 60
    @Published var cpuUsage: Double = 0.0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var cpuTimer: Timer?

    // Moving average buffer for CPU smoothing
    private var cpuSamples: [Double] = []
    private let cpuSampleCount = 5

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        displayLink?.add(to: .main, forMode: .common)

        cpuTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCPU()
        }
        updateCPU()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        cpuTimer?.invalidate()
        cpuTimer = nil
    }

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            frameCount = 0
            return
        }
        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            let measuredFPS = Double(frameCount) / elapsed
            DispatchQueue.main.async {
                self.fps = Int(measuredFPS.rounded())
            }
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }

    private func updateCPU() {
        let sample = Self.processCPUUsage()
        cpuSamples.append(sample)
        if cpuSamples.count > cpuSampleCount { cpuSamples.removeFirst() }
        let averaged = cpuSamples.reduce(0, +) / Double(cpuSamples.count)
        DispatchQueue.main.async {
            self.cpuUsage = averaged
        }
    }

    /// Returns approximate CPU usage % for the current process using mach thread info.
    private static func processCPUUsage() -> Double {
        var threads: thread_act_array_t?
        var threadCount = mach_msg_type_number_t(0)
        let kr = task_threads(mach_task_self_, &threads, &threadCount)
        guard kr == KERN_SUCCESS, let threads = threads else { return 0 }
        defer {
            vm_deallocate(mach_task_self_,
                          vm_address_t(bitPattern: threads),
                          vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.size))
        }
        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            if result == KERN_SUCCESS && (info.flags & TH_FLAGS_IDLE) == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }
        return totalUsage
    }
}
