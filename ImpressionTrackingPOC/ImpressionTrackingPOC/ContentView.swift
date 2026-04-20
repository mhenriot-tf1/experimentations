import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var store: ImpressionStore
    @StateObject private var perfMonitor = PerformanceMonitor()

    // Number of rails and items per approach/stress-test mode
    private var railCount: Int { store.isStressTest ? 15 : 6 }
    private var itemCount: Int { store.isStressTest ? 50 : 20 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            // Main scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    ForEach(0..<railCount, id: \.self) { railIndex in
                        CarouselView(railIndex: railIndex, itemCount: itemCount)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 200) // space for overlay panel
            }

            // Floating stats panel
            VStack(spacing: 0) {
                Spacer()
                StatsOverlayView(perfMonitor: perfMonitor)
                    .padding(.bottom, 4)
            }
        }
        // Apply coordinate space to the ZStack so card frames are in screen coordinates
        .coordinateSpace(name: "screen")
        .navigationTitle("Impression Tracking POC")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Approach", selection: Binding(
                    get: { store.currentApproach },
                    set: { newVal in
                        store.currentApproach = newVal
                        store.reset()
                    }
                )) {
                    ForEach(TrackingApproach.allCases, id: \.self) { approach in
                        Text(approach.rawValue).tag(approach)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Toggle(isOn: Binding(
                    get: { store.isStressTest },
                    set: { newVal in
                        store.isStressTest = newVal
                        store.reset()
                    }
                )) {
                    Label("Stress Test", systemImage: "bolt.fill")
                }
                .toggleStyle(.button)
                .tint(store.isStressTest ? .yellow : .gray)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            perfMonitor.start()
        }
        .onDisappear {
            perfMonitor.stop()
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(ImpressionStore())
    }
}
