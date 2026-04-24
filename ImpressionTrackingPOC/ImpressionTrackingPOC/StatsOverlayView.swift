import SwiftUI

// MARK: - FPS Sparkline

/// Mini bar chart of the last N FPS readings.
struct FPSSparklineView: View {
    let history: [Int]
    let targetFPS: Int = 60

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard !history.isEmpty else { return }
                let barWidth = size.width / CGFloat(history.count)
                let maxVal = CGFloat(max(history.max() ?? targetFPS, targetFPS))

                for (i, value) in history.enumerated() {
                    let frac = CGFloat(value) / maxVal
                    let barH = frac * size.height
                    let rect = CGRect(x: CGFloat(i) * barWidth + 1,
                                     y: size.height - barH,
                                     width: max(barWidth - 2, 1),
                                     height: barH)
                    let color: Color = value >= 55 ? .green : value >= 30 ? .yellow : .red
                    ctx.fill(Path(rect), with: .color(color.opacity(0.85)))
                }

                // 60fps target line
                let targetY = size.height * (1 - CGFloat(targetFPS) / maxVal)
                var linePath = Path()
                linePath.move(to: CGPoint(x: 0, y: targetY))
                linePath.addLine(to: CGPoint(x: size.width, y: targetY))
                ctx.stroke(linePath, with: .color(.white.opacity(0.25)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Metric Row helpers

private struct StatRow: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(valueColor)
                .monospacedDigit()
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.uppercaseSmallCaps())
            .foregroundColor(.secondary)
    }
}

// MARK: - StatsOverlayView

struct StatsOverlayView: View {
    @EnvironmentObject var store: ImpressionStore
    @ObservedObject var perfMonitor: PerformanceMonitor

    private var approachColor: Color {
        store.currentApproach == .approachA ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Header ──────────────────────────────────────────────────
            HStack(spacing: 6) {
                Circle()
                    .fill(approachColor)
                    .frame(width: 8, height: 8)
                Text(store.currentApproach == .approachA ? "Approach A — onAppear" : "Approach B — GeometryReader")
                    .bold()
                    .foregroundColor(approachColor)
                Spacer()
                if store.isStressTest {
                    Label("STRESS", systemImage: "bolt.fill")
                        .font(.caption2.bold())
                        .foregroundColor(.yellow)
                }
            }

            Divider().background(Color.white.opacity(0.2))

            // ── Tracking precision ───────────────────────────────────────
            SectionHeader(title: "Précision du tracking", systemImage: "checkmark.shield")

            HStack(spacing: 12) {
                // Precision gauge
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", store.precisionPercent))
                        .font(.title2.bold())
                        .foregroundColor(store.precisionPercent >= 95 ? .green :
                                         store.precisionPercent >= 80 ? .yellow : .red)
                        .monospacedDigit()
                    Text("Précision")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 64)

                Divider().frame(height: 36).background(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 4) {
                    StatRow(
                        label: "Trackés",
                        value: "\(store.trackedCount) / \(store.totalItems)",
                        valueColor: .white
                    )
                    StatRow(
                        label: "Faux positifs",
                        value: store.currentApproach == .approachA
                            ? "\(store.falsePositiveCount) (\(String(format: "%.0f%%", store.falsePositivePercent)))"
                            : "0 (0%)",
                        valueColor: store.falsePositiveCount > 0 ? .red : .green
                    )
                }
            }

            Divider().background(Color.white.opacity(0.2))

            // ── Timing ──────────────────────────────────────────────────
            SectionHeader(title: "Délai de détection", systemImage: "timer")

            if store.currentApproach == .approachA {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        let delay = store.avgTrackingDelay
                        Text(delay > 0 ? String(format: "+%.0fms", delay * 1000) : "~0ms")
                            .font(.title2.bold())
                            .foregroundColor(delay > 0.2 ? .red : delay > 0.05 ? .yellow : .green)
                            .monospacedDigit()
                        Text("Moy. délai")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 64)

                    Divider().frame(height: 36).background(Color.white.opacity(0.2))

                    VStack(alignment: .leading, spacing: 4) {
                        let maxDelay = store.maxTrackingDelay
                        StatRow(
                            label: "Délai max",
                            value: maxDelay > 0 ? String(format: "+%.0fms", maxDelay * 1000) : "~0ms",
                            valueColor: maxDelay > 0.5 ? .red : .white
                        )
                        StatRow(
                            label: "Impressions/s",
                            value: String(format: "%.1f", store.impressionsPerSecond),
                            valueColor: .white
                        )
                    }
                }
            } else {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("~0ms")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                            .monospacedDigit()
                        Text("Délai exact")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 64)

                    Divider().frame(height: 36).background(Color.white.opacity(0.2))

                    VStack(alignment: .leading, spacing: 4) {
                        StatRow(
                            label: "GR callbacks",
                            value: "\(store.geometryCallbackCount)",
                            valueColor: store.geometryCallbackCount > 5000 ? .red :
                                        store.geometryCallbackCount > 1000 ? .yellow : .white
                        )
                        StatRow(
                            label: "Impressions/s",
                            value: String(format: "%.1f", store.impressionsPerSecond),
                            valueColor: .white
                        )
                    }
                }
            }

            Divider().background(Color.white.opacity(0.2))

            // ── Performance ─────────────────────────────────────────────
            SectionHeader(title: "Performance", systemImage: "gauge.high")

            HStack(spacing: 12) {
                // FPS gauge
                VStack(spacing: 2) {
                    Text("\(perfMonitor.fps)")
                        .font(.title2.bold())
                        .foregroundColor(perfMonitor.fps >= 55 ? .green :
                                         perfMonitor.fps >= 30 ? .yellow : .red)
                        .monospacedDigit()
                    Text("FPS")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 40)

                // Sparkline
                FPSSparklineView(history: perfMonitor.fpsHistory)
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)

                Divider().frame(height: 36).background(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 4) {
                    StatRow(
                        label: "Tps/frame",
                        value: String(format: "%.1fms", perfMonitor.frameTimeMs),
                        valueColor: perfMonitor.frameTimeMs > 33 ? .red :
                                    perfMonitor.frameTimeMs > 20 ? .yellow : .white
                    )
                    StatRow(
                        label: "FPS min",
                        value: "\(perfMonitor.minFPS)",
                        valueColor: perfMonitor.minFPS < 30 ? .red :
                                    perfMonitor.minFPS < 50 ? .yellow : .white
                    )
                    StatRow(
                        label: "Dropped frames",
                        value: "\(perfMonitor.droppedFrameCount)",
                        valueColor: perfMonitor.droppedFrameCount > 10 ? .red :
                                    perfMonitor.droppedFrameCount > 3 ? .yellow : .white
                    )
                    StatRow(
                        label: "CPU",
                        value: String(format: "%.0f%%", perfMonitor.cpuUsage),
                        valueColor: perfMonitor.cpuUsage > 60 ? .red :
                                    perfMonitor.cpuUsage > 30 ? .yellow : .white
                    )
                }
            }
        }
        .font(.caption)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.default, value: store.trackedCount)
        .animation(.default, value: store.falsePositiveCount)
        .animation(.default, value: perfMonitor.fps)
        .animation(.default, value: perfMonitor.droppedFrameCount)
    }
}
