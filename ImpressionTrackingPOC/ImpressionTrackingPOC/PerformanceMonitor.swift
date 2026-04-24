import Foundation
import QuartzCore
import Darwin

// MARK: - PerformanceMonitor

class PerformanceMonitor: NSObject, ObservableObject {
    // Current FPS (updated every second)
    @Published var fps: Int = 60
    // Frame time in milliseconds (1000 / fps)
    @Published var frameTimeMs: Double = 16.67
    // Worst FPS seen since last reset
    @Published var minFPS: Int = 60
    // Number of frames that took longer than 16.67ms (dropped below 60fps)
    @Published var droppedFrameCount: Int = 0
    // Last 20 FPS readings for sparkline chart
    @Published var fpsHistory: [Int] = []
    // Smoothed CPU usage
    @Published var cpuUsage: Double = 0.0

    private static let targetFrameInterval: CFTimeInterval = 1.0 / 60.0
    private static let maxExpectedFPS: Int = 120
    private static let historyCapacity = 20

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var previousFrameTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var droppedAccumulator: Int = 0
    private var cpuTimer: Timer?

    // Moving average buffer for CPU smoothing
    private var cpuSamples: [Double] = []
    private let cpuSampleCount = 5

    func start() {
        resetPerfStats()
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

    /// Reset accumulated perf counters (called on approach/stress-test switch).
    func resetPerfStats() {
        fps = 60
        frameTimeMs = 16.67
        minFPS = 60
        droppedFrameCount = 0
        droppedAccumulator = 0
        fpsHistory = []
        lastTimestamp = 0
        previousFrameTimestamp = 0
        frameCount = 0
    }

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        // Detect dropped frame using consecutive frame timestamps
        if previousFrameTimestamp != 0 {
            let frameDuration = link.timestamp - previousFrameTimestamp
            if frameDuration > Self.targetFrameInterval * 1.5 {
                droppedAccumulator += 1
            }
        }
        previousFrameTimestamp = link.timestamp

        guard lastTimestamp != 0 else {
            lastTimestamp = link.timestamp
            frameCount = 0
            return
        }

        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp
        if elapsed >= 1.0 {
            let measuredFPS = min(Int((Double(frameCount) / elapsed).rounded()), Self.maxExpectedFPS)
            let dropped = droppedAccumulator

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.fps = measuredFPS
                self.frameTimeMs = measuredFPS > 0 ? 1000.0 / Double(measuredFPS) : 0
                if measuredFPS < self.minFPS { self.minFPS = measuredFPS }
                self.droppedFrameCount += dropped
                self.fpsHistory.append(measuredFPS)
                if self.fpsHistory.count > Self.historyCapacity {
                    self.fpsHistory.removeFirst()
                }
            }

            frameCount = 0
            droppedAccumulator = 0
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
            var infoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
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
