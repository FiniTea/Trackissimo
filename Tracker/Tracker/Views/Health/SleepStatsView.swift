//
//  SleepStatsView.swift
//  Tracker
//
//  Reads sleep-analysis data from HealthKit and shows duration in the same
//  3-panel bar format used for activity buttons, plus average bedtime/wake time.
//

import SwiftUI

struct SleepStatsView: View {
    @State private var nights: [SleepNight] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var isAuthorizing = false
    @State private var authError: String?

    private let sleepColor = Color.indigo

    private var durationPoints: [(date: Date, value: Double)] {
        nights.map { (date: $0.night, value: $0.duration / 3600) }
    }

    private var averageBedTime: Date? {
        HealthKitManager.averageTimeOfDay(nights.map(\.bedTime))
    }

    private var averageWakeTime: Date? {
        HealthKitManager.averageTimeOfDay(nights.map(\.wakeTime))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !HealthKitManager.shared.isHealthDataAvailable {
                    ContentUnavailableView(
                        "Health nicht verfügbar",
                        systemImage: "heart.slash",
                        description: Text("Auf diesem Gerät ist Apple Health nicht verfügbar.")
                    )
                } else if isLoading {
                    ProgressView("Lade Schlafdaten…").padding(.top, 60)
                } else if nights.isEmpty {
                    ContentUnavailableView(
                        "Keine Schlafdaten",
                        systemImage: "bed.double",
                        description: Text(loadError ?? "Es wurden noch keine Schlafdaten in Apple Health gefunden. Stelle sicher, dass dein iPhone/deine Apple Watch Schlaf erfasst.")
                    )
                    connectButton
                    if let authError {
                        Text(authError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    HStack(spacing: 24) {
                        timeCard(label: "Ø Einschlafzeit", date: averageBedTime)
                        timeCard(label: "Ø Aufwachzeit", date: averageWakeTime)
                    }
                    .frame(maxWidth: .infinity)
                    .card()

                    BarChartPanel(
                        color: sleepColor,
                        dailyPoints: StatsEngine.dailyBuckets(durationPoints),
                        weeklyPoints: StatsEngine.weeklyBuckets(durationPoints),
                        monthlyPoints: StatsEngine.monthlyBuckets(durationPoints),
                        unit: "h"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Schlaf")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var connectButton: some View {
        Button {
            Task { await requestAndLoad() }
        } label: {
            Label("Health verbinden", systemImage: "heart")
        }
        .buttonStyle(.borderedProminent)
        .disabled(isAuthorizing)
    }

    private func timeCard(label: String, date: Date?) -> some View {
        VStack(spacing: 4) {
            Text(date.map { $0.formatted(date: .omitted, time: .shortened) } ?? "–")
                .font(.title3.bold())
                .foregroundStyle(sleepColor)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        guard HealthKitManager.shared.isHealthDataAvailable else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            nights = try await HealthKitManager.shared.fetchSleepNights()
        } catch {
            loadError = "Schlafdaten konnten nicht geladen werden."
        }
    }

    private func requestAndLoad() async {
        isAuthorizing = true
        defer { isAuthorizing = false }
        do {
            try await HealthKitManager.shared.requestAuthorization()
            authError = nil
        } catch {
            authError = "Verbinden fehlgeschlagen: \(error.localizedDescription)"
        }
        await load()
    }
}

#Preview {
    NavigationStack { SleepStatsView() }
}
