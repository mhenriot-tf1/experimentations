import SwiftUI

// MARK: - CarouselView

struct CarouselView: View {
    let railIndex: Int
    let itemCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rail \(railIndex + 1)")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(0..<itemCount, id: \.self) { itemIndex in
                        CardView(railIndex: railIndex, itemIndex: itemIndex)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
