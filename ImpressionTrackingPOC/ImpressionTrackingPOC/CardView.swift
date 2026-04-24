import SwiftUI

// MARK: - Card dimensions

let cardWidth: CGFloat = 160
let cardHeight: CGFloat = 220
let cardSize = CGSize(width: cardWidth, height: cardHeight)

// MARK: - SF Symbols used as thumbnails

private let thumbnailSymbols = ["tv", "film", "play.rectangle", "play.tv", "play.square"]

// MARK: - Card gradient colours (dark streaming-app look)

private func cardGradient(for index: Int) -> LinearGradient {
    let palette: [(Color, Color)] = [
        (Color(white: 0.15), Color(white: 0.22)),
        (Color(red: 0.10, green: 0.12, blue: 0.20), Color(red: 0.15, green: 0.18, blue: 0.30)),
        (Color(red: 0.12, green: 0.10, blue: 0.18), Color(red: 0.20, green: 0.15, blue: 0.25)),
        (Color(red: 0.10, green: 0.15, blue: 0.12), Color(red: 0.15, green: 0.22, blue: 0.18)),
    ]
    let pair = palette[index % palette.count]
    return LinearGradient(colors: [pair.0, pair.1],
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
}

// MARK: - CardView

struct CardView: View {
    let railIndex: Int
    let itemIndex: Int

    @EnvironmentObject var store: ImpressionStore
    @State private var pulseScale: CGFloat = 1.0

    private var key: ItemKey { ItemKey(railIndex: railIndex, itemIndex: itemIndex) }
    private var isTracked: Bool { store.trackedItems.contains(key) }

    private var borderColor: Color {
        guard isTracked else { return Color.clear }
        return store.currentApproach == .approachA ? .green : .orange
    }

    private var dotColor: Color {
        store.currentApproach == .approachA ? .green : .orange
    }

    private var symbol: String {
        thumbnailSymbols[(railIndex * 7 + itemIndex) % thumbnailSymbols.count]
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card background
            RoundedRectangle(cornerRadius: 10)
                .fill(cardGradient(for: railIndex + itemIndex))
                .frame(width: cardWidth, height: cardHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 2.5)
                )

            // Card content
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(height: 60)

                Text("Programme \(itemIndex + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("Rail \(railIndex + 1) / Pos \(itemIndex + 1)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: cardWidth, height: cardHeight)

            // Tracked dot indicator
            if isTracked {
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
                    .padding(6)
                    .transition(.scale)
            }
        }
        .scaleEffect(pulseScale)
        .onChange(of: isTracked) { tracked in
            if tracked {
                withAnimation(.easeOut(duration: 0.15)) {
                    pulseScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeIn(duration: 0.15)) {
                        pulseScale = 1.0
                    }
                }
            }
        }
        // Approach A: onAppear tracking
        .trackWithApproachA(railIndex: railIndex, itemIndex: itemIndex)
        // Approach B: GeometryReader tracking
        .trackWithApproachB(railIndex: railIndex, itemIndex: itemIndex, cardSize: cardSize)
        // Ground truth (always active, silent)
        .trackGroundTruth(railIndex: railIndex, itemIndex: itemIndex, cardSize: cardSize)
    }
}
