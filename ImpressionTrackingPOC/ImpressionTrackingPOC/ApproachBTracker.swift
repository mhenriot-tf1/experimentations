import SwiftUI

// MARK: - Approach B Tracker (GeometryReader + 50% visibility)

/// Overlays a hidden GeometryReader on a card and checks if ≥50% is visible in the named
/// coordinate space "screen". Calls store.trackItemApproachB when threshold is met.
struct ApproachBTracker: ViewModifier {
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
                            key: FramePreferenceKey.self,
                            value: geo.frame(in: .named("screen"))
                        )
                }
            )
            .onPreferenceChange(FramePreferenceKey.self) { frame in
                store.incrementGeometryCallbacks()
                guard isAtLeastHalfVisible(frame: frame, cardSize: cardSize) else { return }
                store.trackItemApproachB(railIndex: railIndex, itemIndex: itemIndex)
            }
    }
}

/// Returns true if at least 50% of the card (by area) is within the screen-coordinate viewport.
/// Uses UIScreen.main.bounds as the reference for the "screen" named coordinate space.
func isAtLeastHalfVisible(frame: CGRect, cardSize: CGSize) -> Bool {
    // The "screen" coordinate space is anchored to the ZStack which fills the view area.
    // We compare against the screen's full bounds for a conservative approximation.
    let screenBounds = UIScreen.main.bounds
    let intersection = frame.intersection(screenBounds)
    guard !intersection.isNull else { return false }
    let visibleArea = intersection.width * intersection.height
    let totalArea = cardSize.width * cardSize.height
    return totalArea > 0 && visibleArea / totalArea >= 0.5
}

extension View {
    func trackWithApproachB(railIndex: Int, itemIndex: Int, cardSize: CGSize) -> some View {
        modifier(ApproachBTracker(railIndex: railIndex, itemIndex: itemIndex, cardSize: cardSize))
    }
}

// MARK: - Shared preference key

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
