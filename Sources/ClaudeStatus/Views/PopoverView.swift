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
                          color: store.trafficColor)
                metricRow(title: "7-Tage-Limit",
                          metric: snap.sevenDay,
                          color: .blue)
                if let opus = snap.sevenDayOpus, opus.utilization > 0 {
                    metricRow(title: "7-Tage-Opus",
                              metric: opus,
                              color: .purple)
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
    private func metricRow(title: String, metric: UsageMetric, color: Color) -> some View {
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
            if let reset = metric.resetsAt {
                Text("Reset \(formatReset(reset))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
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
