import SwiftUI

// MARK: - StatsOverlayView

struct StatsOverlayView: View {
    @EnvironmentObject var store: ImpressionStore
    @ObservedObject var perfMonitor: PerformanceMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Approach:")
                    .foregroundColor(.secondary)
                Text(store.currentApproach == .approachA ? "A (onAppear)" : "B (GeometryReader)")
                    .bold()
                    .foregroundColor(store.currentApproach == .approachA ? .green : .orange)
            }

            HStack {
                Text("Items tracked:")
                    .foregroundColor(.secondary)
                Text("\(store.trackedCount) / \(store.totalItems)")
                    .bold()
                    .foregroundColor(.white)
            }

            if store.currentApproach == .approachA {
                HStack {
                    Text("False positives:")
                        .foregroundColor(.secondary)
                    Text("\(store.falsePositiveCount)")
                        .bold()
                        .foregroundColor(store.falsePositiveCount > 0 ? .red : .white)
                    Text("(tracked but never on screen)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Avg tracking delay:")
                        .foregroundColor(.secondary)
                    let delay = store.avgTrackingDelay
                    Text(delay > 0 ? String(format: "+%.2fs before visible", delay) : "~0s")
                        .bold()
                        .foregroundColor(.white)
                }
            } else {
                HStack {
                    Text("Avg tracking delay:")
                        .foregroundColor(.secondary)
                    Text("~0s (exact visibility)")
                        .bold()
                        .foregroundColor(.white)
                }
            }

            Divider().background(Color.white.opacity(0.3))

            HStack(spacing: 20) {
                Label("\(perfMonitor.fps) FPS", systemImage: "gauge.high")
                    .foregroundColor(perfMonitor.fps < 30 ? .red : perfMonitor.fps < 50 ? .yellow : .green)
                    .bold()

                Label(String(format: "CPU %.0f%%", perfMonitor.cpuUsage), systemImage: "cpu")
                    .foregroundColor(.white)
            }
            .font(.callout)
        }
        .font(.callout)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.default, value: store.trackedCount)
        .animation(.default, value: store.falsePositiveCount)
        .animation(.default, value: perfMonitor.fps)
    }
}
