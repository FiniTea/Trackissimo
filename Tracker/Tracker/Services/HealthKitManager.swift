//
//  HealthKitManager.swift
//  Tracker
//
//  Thin wrapper around HKHealthStore: writes mood entries as HKStateOfMind
//  samples, and reads sleep-analysis samples to compute per-night duration,
//  bedtime and wake time.
//
//  Requires the HealthKit capability/entitlement (Tracker.entitlements, wired
//  via CODE_SIGN_ENTITLEMENTS) and a signing team selected in Xcode's Signing &
//  Capabilities tab — the entitlement alone isn't enough without a team.
//

import Foundation
import HealthKit
import SwiftData

/// One night's sleep, already merged/derived from possibly-overlapping raw
/// HealthKit samples (see `HealthKitManager.nights(from:)`).
struct SleepNight: Identifiable {
    let id = UUID()
    /// The calendar day the night "belongs to" (the evening it started, per the
    /// 18:00 cutoff rule) — used as the x-axis date for bucketing.
    let night: Date
    let duration: TimeInterval
    let bedTime: Date
    let wakeTime: Date
    /// True if this night had no `.asleep*` sub-stage samples and we fell back
    /// to treating `.inBed` as the sleep signal (older data / basic sources).
    let usedInBedFallback: Bool
}

enum HealthKitError: Error {
    case unavailable
}

@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Current authorization status for the mood *write* permission — the only
    /// one HealthKit lets an app introspect directly (read-permission status is
    /// intentionally not exposed by the framework, to avoid leaking whether the
    /// user has read data at all; a read query simply returns nothing if denied).
    var moodShareStatus: HKAuthorizationStatus {
        store.authorizationStatus(for: HKSampleType.stateOfMindType())
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else { throw HealthKitError.unavailable }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let shareTypes: Set<HKSampleType> = [HKSampleType.stateOfMindType()]
        let readTypes: Set<HKObjectType> = [sleepType]
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    // MARK: - Mood write (HKStateOfMind)

    /// Mirrors a WellbeingEntry to Apple Health. `kind: .dailyMood` fits the
    /// gate's "how are you overall" semantics better than `.momentaryEmotion`,
    /// which is meant for a feeling tied to a specific tagged context we don't
    /// have here — this is a judgment call, not a hard API requirement.
    /// Valence mapping: HealthKit's range is continuous -1...1 with 0 = neutral;
    /// the 1-5 score's midpoint (3) should map to neutral, so
    /// `valence = (score - 3) / 2` gives 1->-1, 3->0, 5->+1, a clean linear fit.
    func writeStateOfMind(for entry: WellbeingEntry, modelContext: ModelContext) async {
        guard isHealthDataAvailable else { return }
        let valence = (Double(entry.score) - 3.0) / 2.0
        let sample = HKStateOfMind(
            date: entry.timestamp,
            kind: .dailyMood,
            valence: valence,
            labels: [],
            associations: []
        )
        do {
            try await store.save(sample)
            entry.healthKitSynced = true
        } catch {
            entry.healthKitSynced = false
        }
    }

    /// Retries every WellbeingEntry whose Health mirror previously failed.
    /// Surfaced as a manual action in Settings rather than run automatically on
    /// every launch, since failures should be rare and don't need to block startup.
    func retryFailedWellbeingSyncs(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<WellbeingEntry>(predicate: #Predicate { $0.healthKitSynced == false })
        guard let pending = try? modelContext.fetch(descriptor) else { return }
        for entry in pending {
            await writeStateOfMind(for: entry, modelContext: modelContext)
        }
    }

    // MARK: - Sleep read

    /// Fetches raw sleep-analysis samples from the last `monthsBack` months and
    /// reduces them into per-night summaries.
    func fetchSleepNights(monthsBack: Int = 12) async throws -> [SleepNight] {
        guard isHealthDataAvailable, let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        let start = Calendar.current.date(byAdding: .month, value: -monthsBack, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await descriptor.result(for: store)
        return Self.nights(from: samples)
    }

    /// Groups raw samples into "nights" and computes duration/bedtime/waketime
    /// for each. Exposed as a static, HealthKit-type-free function so it can be
    /// unit-tested without a real HKHealthStore.
    static func nights(from samples: [HKCategorySample]) -> [SleepNight] {
        let calendar = Calendar.current

        // A sample belongs to "last night" if it ends before 18:00 local time —
        // the standard heuristic for grouping sleep sessions that cross midnight.
        func nightKey(for date: Date) -> Date {
            let day = calendar.startOfDay(for: date)
            let hour = calendar.component(.hour, from: date)
            return hour < 18 ? calendar.date(byAdding: .day, value: -1, to: day) ?? day : day
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        let inBedValue = HKCategoryValueSleepAnalysis.inBed.rawValue

        let grouped = Dictionary(grouping: samples) { nightKey(for: $0.endDate) }

        return grouped.compactMap { night, nightSamples -> SleepNight? in
            var relevant = nightSamples.filter { asleepValues.contains($0.value) }
            var usedFallback = false
            if relevant.isEmpty {
                relevant = nightSamples.filter { $0.value == inBedValue }
                usedFallback = true
            }
            guard !relevant.isEmpty else { return nil }

            // Merge overlapping/adjacent intervals so multi-source or
            // multi-stage samples don't double-count overlapping sleep time.
            let sorted = relevant.map { ($0.startDate, $0.endDate) }.sorted { $0.0 < $1.0 }
            var merged: [(start: Date, end: Date)] = []
            for interval in sorted {
                if let last = merged.last, interval.0 <= last.end {
                    merged[merged.count - 1].end = max(last.end, interval.1)
                } else {
                    merged.append((interval.0, interval.1))
                }
            }

            let duration = merged.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
            guard let bedTime = merged.map(\.start).min(), let wakeTime = merged.map(\.end).max() else { return nil }
            return SleepNight(night: night, duration: duration, bedTime: bedTime, wakeTime: wakeTime, usedInBedFallback: usedFallback)
        }
        .sorted { $0.night < $1.night }
    }

    /// Averages a set of dates as times-of-day (ignoring which calendar day
    /// they fall on), avoiding the naive-mean wraparound bug around midnight:
    /// each time is expressed as minutes-since-noon (so both typical bedtimes,
    /// ~22:00-02:00, and wake times, ~06:00-09:00, stay on a single monotonic
    /// scale without crossing the 0/1440 boundary) before averaging.
    static func averageTimeOfDay(_ dates: [Date], calendar: Calendar = .current) -> Date? {
        guard !dates.isEmpty else { return nil }
        let minutesSinceNoon: [Double] = dates.map { date in
            let comps = calendar.dateComponents([.hour, .minute], from: date)
            let totalMinutes = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
            return (totalMinutes - 720 + 1440).truncatingRemainder(dividingBy: 1440)
        }
        let averageSinceNoon = minutesSinceNoon.reduce(0, +) / Double(minutesSinceNoon.count)
        let averageMinutesOfDay = (averageSinceNoon + 720).truncatingRemainder(dividingBy: 1440)
        let today = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .minute, value: Int(averageMinutesOfDay.rounded()), to: today)
    }
}
