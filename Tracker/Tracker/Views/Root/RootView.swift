//
//  RootView.swift
//  Tracker
//
//  App shell: hosts the four main tabs and overlays the blocking mood gate on
//  top whenever it should be shown.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @State private var showMoodGate = false
    /// Tracks whether the app has actually reached `.background` since the
    /// process started. Combined with `isFirstLaunch`, this drives the "gate on
    /// every real app-open" rule — see `handleScenePhaseChange` for the exact logic.
    @State private var wasBackgrounded = false
    @State private var isFirstLaunch = true

    var body: some View {
        ZStack {
            RootTabView()

            if showMoodGate {
                MoodGateView {
                    showMoodGate = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showMoodGate)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    /// The user explicitly asked for the mood gate on *every* app open, not just
    /// once a day. Taken completely literally that would also refire on trivial
    /// `.inactive` blips (Control Center, an incoming call banner, the app
    /// switcher preview) which merely pass through `.inactive` without ever
    /// reaching `.background` — regating on those would make the gate appear
    /// mid-interaction, which can't be what "every app open" is meant to cover.
    /// So: regate on `.active` only if the app actually reached `.background`
    /// first, or if this is the very first `.active` transition of the process
    /// (the cold-launch case, which never passes through `.background` at all).
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            wasBackgrounded = true
        case .active:
            if isFirstLaunch || wasBackgrounded {
                showMoodGate = true
                isFirstLaunch = false
                wasBackgrounded = false
            }
        default:
            break
        }
    }
}

/// The four main sections of the app, mirroring Daylio's tab layout.
private struct RootTabView: View {
    var body: some View {
        TabView {
            LogTabView()
                .tabItem { Label("Log", systemImage: "checkmark.circle") }

            StatsTabView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            HealthTabView()
                .tabItem { Label("Gesundheit", systemImage: "heart") }

            SettingsView()
                .tabItem { Label("Einstellungen", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [ActivityGroup.self, ActivityButton.self, LogEntry.self, WellbeingEntry.self], inMemory: true)
}
