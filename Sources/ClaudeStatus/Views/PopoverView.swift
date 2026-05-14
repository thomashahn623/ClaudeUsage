import SwiftUI
import AppKit

struct PopoverView: View {
    @EnvironmentObject var store: UsageStore
    @Environment(\.openWindow) private var openWindow
    @State private var now = Date()
    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Claude Usage").font(.headline)
                Spacer()
                if store.isLoading { ProgressView().controlSize(.small) }
            }

            if let err = store.lastError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let snap = store.snapshot {
                metricRow(title: "5-Stunden-Session",
                          metric: snap.fiveHour,
                          windowDuration: 5 * 3600,
                          color: store.trafficColor,
                          forecast: store.forecast(for: .fiveHour, now: now))
                metricRow(title: "7-Tage-Limit",
                          metric: snap.sevenDay,
                          windowDuration: 7 * 24 * 3600,
                          color: .blue,
                          forecast: store.forecast(for: .sevenDay, now: now))
                if let opus = snap.sevenDayOpus, opus.utilization > 0 {
                    metricRow(title: "7-Tage-Opus",
                              metric: opus,
                              windowDuration: 7 * 24 * 3600,
                              color: .purple,
                              forecast: store.forecast(for: .sevenDayOpus, now: now))
                }

                Text("Aktualisiert: \(snap.fetchedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if store.lastError == nil {
                Text("Lade Daten…").foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Aktualisieren", systemImage: "arrow.clockwise")
                }
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "history")
                } label: {
                    Label("Verlauf", systemImage: "chart.xyaxis.line")
                }
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                } label: {
                    Label("Einstellungen", systemImage: "gearshape")
                }
                Spacer()
                Button("Beenden") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(16)
        .frame(width: 320)
        .onReceive(ticker) { now = $0 }
    }

    @ViewBuilder
    private func metricRow(title: String, metric: UsageMetric, windowDuration: TimeInterval, color: Color, forecast: ForecastResult?) -> some View {
        let timeProgress = timeProgress(for: metric, windowDuration: windowDuration)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(metric.utilization.rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            ProgressView(value: min(metric.utilization, 100) / 100)
                .tint(color)
            if let timeProgress {
                HStack {
                    Text("Zeitfenster")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((timeProgress * 100).rounded()))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                ProgressView(value: timeProgress)
                    .tint(.secondary)
            }
            if let reset = metric.resetsAt {
                Text("Reset \(formatReset(reset))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let forecast {
                forecastLine(forecast)
            }
        }
    }

    @ViewBuilder
    private func forecastLine(_ forecast: ForecastResult) -> some View {
        let arrow: String = {
            if forecast.velocityPerHour > 1 { return "arrow.up.right" }
            if forecast.velocityPerHour < -1 { return "arrow.down.right" }
            return "arrow.right"
        }()
        let projected = Int(forecast.projectedAtReset.rounded())
        let velocityText: String = {
            let sign = forecast.velocityPerHour >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.0f", forecast.velocityPerHour)) %/h"
        }()
        let suffix = forecast.confidence == .low ? " · wenig Daten" : ""
        let color: Color = {
            if forecast.confidence == .low { return .secondary }
            if forecast.projectedAtReset >= 100 { return .red }
            if forecast.projectedAtReset >= 85 { return .orange }
            return .secondary
        }()
        HStack(spacing: 4) {
            Image(systemName: arrow)
            Text("Forecast: \(projected) % bei Reset · \(velocityText)\(suffix)")
                .monospacedDigit()
        }
        .font(.caption2)
        .foregroundStyle(color)
    }

    private func timeProgress(for metric: UsageMetric, windowDuration: TimeInterval) -> Double? {
        guard let reset = metric.resetsAt, windowDuration > 0 else { return nil }
        let start = reset.addingTimeInterval(-windowDuration)
        let elapsed = now.timeIntervalSince(start)
        return min(max(elapsed / windowDuration, 0), 1)
    }

    private func formatReset(_ date: Date) -> String {
        let interval = date.timeIntervalSince(now)
        if interval <= 0 { return "jetzt" }
        let f = DateComponentsFormatter()
        f.unitsStyle = .abbreviated
        f.allowedUnits = interval < 3600 ? [.minute] :
                         interval < 86400 ? [.hour, .minute] : [.day, .hour]
        f.maximumUnitCount = 2
        let rel = f.string(from: interval) ?? ""
        let abs = date.formatted(date: .abbreviated, time: .shortened)
        return "in \(rel) (\(abs))"
    }
}
