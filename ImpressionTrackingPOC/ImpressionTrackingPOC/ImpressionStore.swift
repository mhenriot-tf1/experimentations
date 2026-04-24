import SwiftUI
import Combine

// MARK: - Data Models

enum TrackingApproach: String, CaseIterable {
    case approachA = "Approach A (onAppear)"
    case approachB = "Approach B (GeometryReader)"
}

struct ImpressionEvent: Identifiable {
    let id = UUID()
    let railIndex: Int
    let itemIndex: Int
    let timestamp: Date
    let approach: TrackingApproach
}

struct ItemKey: Hashable {
    let railIndex: Int
    let itemIndex: Int
}

// MARK: - ImpressionStore

class ImpressionStore: ObservableObject {
    @Published var currentApproach: TrackingApproach = .approachA
    @Published var isStressTest: Bool = false

    // Tracked impressions for A or B
    @Published private(set) var trackedItems: Set<ItemKey> = []
    @Published private(set) var impressionEvents: [ImpressionEvent] = []

    // Ground truth: items truly visible (always tracked silently)
    @Published private(set) var groundTruthVisible: Set<ItemKey> = []
    // When an item first became truly visible
    private var groundTruthFirstVisible: [ItemKey: Date] = [:]

    // For Approach A: when onAppear fired
    private var approachAFireTimes: [ItemKey: Date] = [:]

    // Count of GeometryReader preference-change callbacks (proxy for layout overhead)
    @Published private(set) var geometryCallbackCount: Int = 0

    // Session start time (for impressions/s rate)
    private var sessionStart: Date = Date()

    // Computed stats
    var totalItems: Int {
        isStressTest ? 15 * 50 : 6 * 20
    }

    var trackedCount: Int {
        trackedItems.count
    }

    var falsePositiveCount: Int {
        guard currentApproach == .approachA else { return 0 }
        // Items tracked by A that were never truly visible
        return trackedItems.filter { key in
            groundTruthFirstVisible[key] == nil
        }.count
    }

    var avgTrackingDelay: Double {
        guard currentApproach == .approachA else { return 0.0 }
        // Average time between onAppear firing and item becoming truly visible
        var delays: [Double] = []
        for key in trackedItems {
            guard let appearTime = approachAFireTimes[key],
                  let visibleTime = groundTruthFirstVisible[key] else { continue }
            let delay = visibleTime.timeIntervalSince(appearTime)
            // Only count positive delays (visible after appear)
            if delay > 0 { delays.append(delay) }
        }
        guard !delays.isEmpty else { return 0.0 }
        return delays.reduce(0, +) / Double(delays.count)
    }

    /// Largest observed delay between onAppear and true visibility (Approach A only).
    var maxTrackingDelay: Double {
        guard currentApproach == .approachA else { return 0.0 }
        return trackedItems.compactMap { key -> Double? in
            guard let appearTime = approachAFireTimes[key],
                  let visibleTime = groundTruthFirstVisible[key] else { return nil }
            let d = visibleTime.timeIntervalSince(appearTime)
            return d > 0 ? d : nil
        }.max() ?? 0.0
    }

    /// Percentage of tracked items that were actually visible (100% for B, <100% for A if FPs exist).
    var precisionPercent: Double {
        guard trackedCount > 0 else { return 100.0 }
        let correct = trackedCount - falsePositiveCount
        return Double(max(correct, 0)) / Double(trackedCount) * 100.0
    }

    /// False-positive rate as a percentage of tracked items.
    var falsePositivePercent: Double {
        guard trackedCount > 0 else { return 0.0 }
        return Double(falsePositiveCount) / Double(trackedCount) * 100.0
    }

    /// Impressions tracked per second since session start.
    var impressionsPerSecond: Double {
        let elapsed = Date().timeIntervalSince(sessionStart)
        guard elapsed > 0 else { return 0 }
        return Double(trackedCount) / elapsed
    }

    // MARK: - Geometry callback counter (proxy for layout overhead)

    func incrementGeometryCallbacks() {
        geometryCallbackCount += 1
    }

    // MARK: - Approach A tracking

    func trackItemApproachA(railIndex: Int, itemIndex: Int) {
        guard currentApproach == .approachA else { return }
        let key = ItemKey(railIndex: railIndex, itemIndex: itemIndex)
        guard !trackedItems.contains(key) else { return }
        let now = Date()
        trackedItems.insert(key)
        approachAFireTimes[key] = now
        impressionEvents.append(ImpressionEvent(
            railIndex: railIndex,
            itemIndex: itemIndex,
            timestamp: now,
            approach: .approachA
        ))
    }

    // MARK: - Approach B tracking

    func trackItemApproachB(railIndex: Int, itemIndex: Int) {
        guard currentApproach == .approachB else { return }
        let key = ItemKey(railIndex: railIndex, itemIndex: itemIndex)
        guard !trackedItems.contains(key) else { return }
        trackedItems.insert(key)
        impressionEvents.append(ImpressionEvent(
            railIndex: railIndex,
            itemIndex: itemIndex,
            timestamp: Date(),
            approach: .approachB
        ))
    }

    // MARK: - Ground truth tracking (always active)

    func updateGroundTruth(railIndex: Int, itemIndex: Int, isVisible: Bool) {
        let key = ItemKey(railIndex: railIndex, itemIndex: itemIndex)
        if isVisible {
            if groundTruthFirstVisible[key] == nil {
                groundTruthFirstVisible[key] = Date()
            }
            groundTruthVisible.insert(key)
        } else {
            groundTruthVisible.remove(key)
        }
    }

    // MARK: - Reset

    func reset() {
        trackedItems = []
        impressionEvents = []
        groundTruthVisible = []
        groundTruthFirstVisible = [:]
        approachAFireTimes = [:]
        geometryCallbackCount = 0
        sessionStart = Date()
    }
}
