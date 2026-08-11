//
//  ButtonEditSheet.swift
//  Tracker
//
//  Create or edit a single ActivityButton: name, icon, color, group membership
//  (implicit from context), logging mode, and stat type.
//

import SwiftUI
import SwiftData

struct ButtonEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Set when creating a new button in a group.
    var group: ActivityGroup?
    /// Set when editing an existing button — overrides `group` above.
    var buttonToEdit: ActivityButton?

    @State private var name: String = ""
    @State private var icon: String = "⭐️"
    @State private var colorHex: String = "#3B82F6"
    @State private var loggingMode: LoggingMode = .instant
    @State private var statKind: StatKind = .bar
    @State private var heatmapMaxFrequency: Int = 5

    private var isEditing: Bool { buttonToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z.B. Pinkeln", text: $name)
                }

                Section {
                    EmojiPicker(icon: $icon)
                }

                Section {
                    ColorPickerRow(colorHex: $colorHex)
                }

                Section {
                    Picker("Modus", selection: $loggingMode) {
                        ForEach(LoggingMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                } header: {
                    Text("Protokollierung")
                } footer: {
                    Text("Einmalig: ein Tipp loggt sofort. Zeitspanne: fragt Start- und Endzeit ab (z.B. für Besuche).")
                }

                Section {
                    Picker("Typ", selection: $statKind) {
                        ForEach(StatKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    if statKind == .heatmap {
                        Stepper("Max. Häufigkeit/Tag: \(heatmapMaxFrequency)", value: $heatmapMaxFrequency, in: 1...50)
                    }
                } header: {
                    Text("Statistik")
                } footer: {
                    Text("Kreisdiagramme werden auf Gruppenebene aktiviert (siehe Gruppen-Einstellungen).")
                }
            }
            .navigationTitle(isEditing ? "Button bearbeiten" : "Neuer Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let button = buttonToEdit else { return }
        name = button.name
        icon = button.icon
        colorHex = button.colorHex
        loggingMode = button.loggingMode
        statKind = button.statKind
        heatmapMaxFrequency = button.heatmapMaxFrequency ?? 5
    }

    private func save() {
        let resolvedHeatmapMax: Int? = statKind == .heatmap ? heatmapMaxFrequency : nil

        if let button = buttonToEdit {
            button.name = name
            button.icon = icon
            button.colorHex = colorHex
            button.loggingMode = loggingMode
            button.statKind = statKind
            button.heatmapMaxFrequency = resolvedHeatmapMax
        } else {
            let siblingCount = group?.sortedButtons.count ?? 0
            let newButton = ActivityButton(
                name: name,
                icon: icon,
                colorHex: colorHex,
                sortOrder: siblingCount,
                loggingMode: loggingMode,
                statKind: statKind,
                heatmapMaxFrequency: resolvedHeatmapMax,
                group: group
            )
            modelContext.insert(newButton)
        }
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
        dismiss()
    }
}

#Preview {
    ButtonEditSheet(group: ActivityGroup(name: "Preview"))
        .modelContainer(for: ActivityGroup.self, inMemory: true)
}
