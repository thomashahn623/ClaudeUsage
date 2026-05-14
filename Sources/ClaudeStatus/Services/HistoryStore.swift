import Foundation
import Combine
import os

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var samples: [HistorySample] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var saveTask: Task<Void, Never>?
    private let saveDebounce: TimeInterval = 5
    private let log = Logger(subsystem: "ClaudeStatus", category: "HistoryStore")

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let fm = FileManager.default
            let base = (try? fm.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true))
                ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
            let dir = base.appendingPathComponent("ClaudeStatus", isDirectory: true)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("history.json")
        }

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        load()
    }

    func append(_ snapshot: UsageSnapshot) {
        let sample = HistorySample(snapshot: snapshot)
        if let last = samples.last, last == sample { return }
        samples.append(sample)
        scheduleSave()
    }

    func samples(for metric: MetricKind, cycleEndingAt resetsAt: Date) -> [HistorySample] {
        samples.filter { sample in
            guard sample.utilization(for: metric) != nil,
                  let r = sample.resetsAt(for: metric) else { return false }
            return abs(r.timeIntervalSince(resetsAt)) < 1
        }
    }

    func cycles(for metric: MetricKind) -> [CycleSummary] {
        let relevant = samples.filter { $0.utilization(for: metric) != nil && $0.resetsAt(for: metric) != nil }
        let grouped = Dictionary(grouping: relevant) { sample -> Date in
            sample.resetsAt(for: metric)!
        }
        return grouped.map { (resetsAt, items) -> CycleSummary in
            let sorted = items.sorted { $0.timestamp < $1.timestamp }
            let utilizations = sorted.compactMap { $0.utilization(for: metric) }
            let peak = utilizations.max() ?? 0
            let velocity = Self.averageVelocity(samples: sorted, metric: metric)
            return CycleSummary(
                id: resetsAt,
                resetsAt: resetsAt,
                metric: metric,
                peak: peak,
                averageVelocityPerHour: velocity,
                sampleCount: sorted.count,
                firstSampleAt: sorted.first?.timestamp ?? resetsAt,
                lastSampleAt: sorted.last?.timestamp ?? resetsAt
            )
        }.sorted { $0.resetsAt > $1.resetsAt }
    }

    private static func averageVelocity(samples: [HistorySample], metric: MetricKind) -> Double? {
        guard let first = samples.first,
              let last = samples.last,
              first.timestamp != last.timestamp,
              let firstU = first.utilization(for: metric),
              let lastU = last.utilization(for: metric) else { return nil }
        let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600
        guard hours > 0 else { return nil }
        return (lastU - firstU) / hours
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            samples = try decoder.decode([HistorySample].self, from: data)
        } catch {
            log.error("History laden fehlgeschlagen, starte leer: \(error.localizedDescription, privacy: .public)")
            samples = []
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = samples
        let url = fileURL
        let encoder = encoder
        let log = log
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.saveDebounce ?? 5) * 1_000_000_000)
            if Task.isCancelled { return }
            do {
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                log.error("History speichern fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func flushNow() {
        saveTask?.cancel()
        do {
            let data = try encoder.encode(samples)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            log.error("History flush fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
        }
    }
}
