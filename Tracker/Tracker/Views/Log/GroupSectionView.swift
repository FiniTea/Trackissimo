//
//  GroupSectionView.swift
//  Tracker
//
//  One group's section on the Log tab: a tappable header (name + collapse
//  chevron) followed by the grid of its buttons, hidden when collapsed so
//  someone with many groups can fold away the ones they don't need right now.
//

import SwiftUI

struct GroupSectionView: View {
    let group: ActivityGroup

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    group.isCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: group.colorHex ?? "#3B82F6"))
                        .frame(width: 10, height: 10)
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(group.isCollapsed ? -90 : 0))
                }
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !group.isCollapsed {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(group.sortedButtons) { button in
                        ActivityButtonCell(button: button)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
