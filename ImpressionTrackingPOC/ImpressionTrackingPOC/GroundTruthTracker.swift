import SwiftUI

// MARK: - Ground Truth Tracker (always silent, used for false positive detection)

/// Silently measures true visibility using GeometryReader + 50% threshold.
/// Always runs regardless of the active approach — used to compute false positives for Approach A.
struct GroundTruthTracker: ViewModifier {
    let railIndex: Int
    let itemIndex: Int
    let cardSize: CGSize
    @EnvironmentObject var store: ImpressionStore

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: GroundTruthFrameKey.self,
                            value: geo.frame(in: .named("screen"))
                        )
                }
            )
            .onPreferenceChange(GroundTruthFrameKey.self) { frame in
                let isVisible = isAtLeastHalfVisible(frame: frame, cardSize: cardSize)
                store.updateGroundTruth(railIndex: railIndex, itemIndex: itemIndex, isVisible: isVisible)
            }
    }
}

extension View {
    func trackGroundTruth(railIndex: Int, itemIndex: Int, cardSize: CGSize) -> some View {
        modifier(GroundTruthTracker(railIndex: railIndex, itemIndex: itemIndex, cardSize: cardSize))
    }
}

// MARK: - Preference key (separate from ApproachB to avoid conflicts)

struct GroundTruthFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
