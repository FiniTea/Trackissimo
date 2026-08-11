//
//  ButtonListEditView.swift
//  Tracker
//
//  Manage a single group's buttons: add, edit, delete, reorder.
//

import SwiftUI
import SwiftData

struct ButtonListEditView: View {
    @Environment(\.modelContext) private var modelContext

    let group: ActivityGroup

    @State private var editingButton: ActivityButton?
    @State private var isCreatingButton = false
    @State private var buttonPendingDelete: ActivityButton?

    private var buttons: [ActivityButton] { group.sortedButtons }

    var body: some View {
        List {
            ForEach(buttons) { button in
                Button {
                    editingButton = button
                } label: {
                    row(for: button)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        buttonPendingDelete = button
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: moveButtons)
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreatingButton = true
                } label: {
                    Label("Neuer Button", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $isCreatingButton) {
            ButtonEditSheet(group: group)
        }
        .sheet(item: $editingButton) { button in
            ButtonEditSheet(buttonToEdit: button)
        }
        .confirmationDialog(
            "Button \"\(buttonPendingDelete?.name ?? "")\" löschen?",
            isPresented: Binding(get: { buttonPendingDelete != nil }, set: { if !$0 { buttonPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                if let button = buttonPendingDelete {
                    modelContext.delete(button)
                    GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
                }
                buttonPendingDelete = nil
            }
            Button("Abbrechen", role: .cancel) { buttonPendingDelete = nil }
        } message: {
            Text("Alle Log-Einträge dieses Buttons werden ebenfalls gelöscht.")
        }
        .overlay {
            if buttons.isEmpty {
                ContentUnavailableView(
                    "Noch keine Buttons",
                    systemImage: "square.grid.2x2",
                    description: Text("Tippe auf + um einen Button anzulegen.")
                )
            }
        }
    }

    @ViewBuilder
    private func row(for button: ActivityButton) -> some View {
        HStack(spacing: 12) {
            Text(button.icon)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(button.name)
                    .foregroundStyle(.primary)
                Text(subtitle(for: button))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func subtitle(for button: ActivityButton) -> String {
        var parts = [button.loggingMode.label]
        if button.statKind != .none {
            parts.append(button.statKind.label)
        }
        return parts.joined(separator: " · ")
    }

    private func moveButtons(from source: IndexSet, to destination: Int) {
        var reordered = buttons
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, button) in reordered.enumerated() {
            button.sortOrder = index
        }
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        ButtonListEditView(group: ActivityGroup(name: "Preview"))
    }
    .modelContainer(for: ActivityGroup.self, inMemory: true)
}
