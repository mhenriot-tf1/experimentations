import SwiftUI

// MARK: - Approach A Tracker (onAppear-based)

/// Provides `.onAppear` modifier that logs impressions to the store.
/// Used when approach is .approachA.
struct ApproachATracker: ViewModifier {
    let railIndex: Int
    let itemIndex: Int
    @EnvironmentObject var store: ImpressionStore

    func body(content: Content) -> some View {
        content
            .onAppear {
                store.trackItemApproachA(railIndex: railIndex, itemIndex: itemIndex)
            }
    }
}

extension View {
    func trackWithApproachA(railIndex: Int, itemIndex: Int) -> some View {
        modifier(ApproachATracker(railIndex: railIndex, itemIndex: itemIndex))
    }
}
