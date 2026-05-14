import SwiftUI
import AppKit

struct HistorySheetView: View {
    @EnvironmentObject var store: UsageStore
    @State private var selectedMetric: MetricKind = .fiveHour

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Verlauf").font(.headline)
                Spacer()
                Button("Schließen") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }

            Picker("Metrik", selection: $selectedMetric) {
                ForEach(MetricKind.allCases) { metric in
                    Text(shortName(metric)).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            let cycles = store.history.cycles(for: selectedMetric)
            if cycles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Noch keine Daten für diese Metrik")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("Zyklen erscheinen, sobald die App ein paar Snapshots gesammelt hat.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(cycles) { cycle in
                            cycleRow(cycle)
                            Divider()
                        }
                    }
                }
            }

            HStack {
                Text("\(store.history.samples.count) Samples insgesamt")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(16)
        .frame(width: 460, height: 420)
    }

    @ViewBuilder
    private func cycleRow(_ cycle: CycleSummary) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(cycle.resetsAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                Text("\(cycle.sampleCount) Samples · \(cycle.firstSampleAt.formatted(date: .omitted, time: .shortened)) – \(cycle.lastSampleAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Peak \(Int(cycle.peak.rounded())) %")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                if let v = cycle.averageVelocityPerHour {
                    let sign = v >= 0 ? "+" : ""
                    Text("Ø \(sign)\(String(format: "%.1f", v)) %/h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func shortName(_ metric: MetricKind) -> String {
        switch metric {
        case .fiveHour: return "5h"
        case .sevenDay: return "7d"
        case .sevenDayOpus: return "Opus"
        }
    }
}
