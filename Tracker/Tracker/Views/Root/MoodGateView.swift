//
//  MoodGateView.swift
//  Tracker
//
//  Full-screen blocking modal shown on every app open (see RootView's scenePhase
//  logic). The user must pick one of 5 mood emojis before anything else in the
//  app becomes reachable.
//

import SwiftUI
import SwiftData

/// One mood option shown in the gate. `score` also drives the color used
/// elsewhere for wellbeing stats (see `ColorInterpolation.wellbeingColor`).
private struct MoodOption: Identifiable {
    let score: Int
    let emoji: String
    var id: Int { score }
}

private let moodOptions: [MoodOption] = [
    MoodOption(score: 1, emoji: "😞"),
    MoodOption(score: 2, emoji: "🙁"),
    MoodOption(score: 3, emoji: "😐"),
    MoodOption(score: 4, emoji: "🙂"),
    MoodOption(score: 5, emoji: "😄"),
]

struct MoodGateView: View {
    @Environment(\.modelContext) private var modelContext
    /// Called once the user has picked a mood and the entry has been recorded.
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Opaque background: this is a hard gate, nothing behind it should
            // be visible or reachable while it's up.
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Wie geht's dir gerade?")
                        .font(.title2.bold())
                    Text("Wähle eine Stimmung, um fortzufahren")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    ForEach(moodOptions) { option in
                        Button {
                            record(option)
                        } label: {
                            Text(option.emoji)
                                .font(.system(size: 40))
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
    }

    private func record(_ option: MoodOption) {
        Haptics.selected()
        let entry = WellbeingEntry(score: option.score)
        modelContext.insert(entry)

        // Fire-and-forget mirrors: neither should block dismissing the gate.
        Task {
            await HealthKitManager.shared.writeStateOfMind(for: entry, modelContext: modelContext)
        }
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)

        onComplete()
    }
}

#Preview {
    MoodGateView(onComplete: {})
        .modelContainer(for: WellbeingEntry.self, inMemory: true)
}
