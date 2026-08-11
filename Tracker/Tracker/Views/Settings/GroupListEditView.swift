//
//  GroupListEditView.swift
//  Tracker
//
//  Manage groups: add, rename/recolor, reorder, delete. Tapping a group drills
//  into its button list (ButtonListEditView).
//

import SwiftUI
import SwiftData

struct GroupListEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityGroup.sortOrder) private var groups: [ActivityGroup]

    @State private var editingGroup: ActivityGroup?
    @State private var isCreatingGroup = false
    @State private var groupPendingDelete: ActivityGroup?

    var body: some View {
        List {
            ForEach(groups) { group in
                NavigationLink {
                    ButtonListEditView(group: group)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: group.colorHex ?? "#3B82F6"))
                            .frame(width: 14, height: 14)
                        Text(group.name)
                        Spacer()
                        Text("\(group.sortedButtons.count)")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        groupPendingDelete = group
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                    Button {
                        editingGroup = group
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onMove(perform: moveGroups)
        }
        .navigationTitle("Gruppen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreatingGroup = true
                } label: {
                    Label("Neue Gruppe", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $isCreatingGroup) {
            GroupEditSheet()
        }
        .sheet(item: $editingGroup) { group in
            GroupEditSheet(groupToEdit: group)
        }
        .confirmationDialog(
            "Gruppe \"\(groupPendingDelete?.name ?? "")\" löschen?",
            isPresented: Binding(get: { groupPendingDelete != nil }, set: { if !$0 { groupPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                if let group = groupPendingDelete {
                    modelContext.delete(group)
                    GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
                }
                groupPendingDelete = nil
            }
            Button("Abbrechen", role: .cancel) { groupPendingDelete = nil }
        } message: {
            Text("Alle Buttons und Einträge dieser Gruppe werden ebenfalls gelöscht. Das kann nicht rückgängig gemacht werden.")
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView(
                    "Noch keine Gruppen",
                    systemImage: "square.grid.2x2",
                    description: Text("Tippe auf + um deine erste Gruppe anzulegen.")
                )
            }
        }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var reordered = groups
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, group) in reordered.enumerated() {
            group.sortOrder = index
        }
        GitHubBackupService.shared.scheduleSync(modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        GroupListEditView()
    }
    .modelContainer(for: ActivityGroup.self, inMemory: true)
}
