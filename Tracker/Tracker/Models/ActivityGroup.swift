//
//  ActivityGroup.swift
//  Tracker
//
//  A user-defined category that holds a set of ActivityButtons, e.g. "Badezimmer"
//  containing Pinkeln/Duschen/Scheißen. Named `ActivityGroup` rather than `Group`
//  to avoid colliding with SwiftUI's own `Group` view type.
//

import Foundation
import SwiftData

@Model
final class ActivityGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    /// User-controlled display order on the Log/Stats tabs (lower = earlier).
    var sortOrder: Int
    /// Optional accent color for the group's section header; individual buttons
    /// still own their own color for their button/stat rendering.
    var colorHex: String?
    /// Whether this group shows an additional pie chart (share of each button's
    /// logs within the group) on the Stats tab.
    var showsPieChart: Bool
    /// Whether the group's button grid is currently collapsed on the Log tab
    /// (and its Stats section collapsed too — both screens share this one flag
    /// so collapsing a group in either place stays in sync). Persisted rather
    /// than kept as transient view state so it survives app relaunches, which
    /// matters once someone has enough groups that re-expanding everything on
    /// every launch would defeat the point.
    var isCollapsed: Bool
    var createdAt: Date

    /// Deleting a group deletes everything inside it — a group is a "folder" for
    /// its buttons, so an empty group left behind after its only contents vanish
    /// serves no purpose. The UI must confirm this destructive action with the
    /// user before calling `modelContext.delete(group)`.
    @Relationship(deleteRule: .cascade, inverse: \ActivityButton.group)
    var buttons: [ActivityButton] = []

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0,
        colorHex: String? = nil,
        showsPieChart: Bool = false,
        isCollapsed: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.colorHex = colorHex
        self.showsPieChart = showsPieChart
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
    }

    var sortedButtons: [ActivityButton] {
        buttons.sorted { $0.sortOrder < $1.sortOrder }
    }
}
