//
//  ActivityButton.swift
//  Tracker
//
//  A single loggable activity (e.g. "Pinkeln", "Sofie"). Buttons are fully
//  user-configured — nothing is hardcoded.
//

import Foundation
import SwiftData

@Model
final class ActivityButton {
    @Attribute(.unique) var id: UUID
    var name: String
    /// The button's icon, stored as a single emoji character (e.g. "🚿") rather
    /// than an SF Symbol name — this gives access to the full native emoji
    /// keyboard (thousands of options) instead of a hand-curated symbol list.
    var icon: String
    /// Hex color string; drives both the button's own appearance and its stats
    /// (heatmap shading, pie chart slice color).
    var colorHex: String
    var sortOrder: Int

    /// Raw storage for `LoggingMode`; use `loggingMode` for the typed value.
    var loggingModeRaw: String
    /// Raw storage for `StatKind`; use `statKind` for the typed value.
    var statKindRaw: String
    /// Only meaningful when `statKind == .heatmap`: the daily count that maps to
    /// the darkest shade. Nil for non-heatmap buttons.
    var heatmapMaxFrequency: Int?

    var createdAt: Date

    /// The group this button belongs to. Optional only to satisfy SwiftData's
    /// relationship macro requirements — the create/edit UI must always assign a
    /// group before saving a button.
    var group: ActivityGroup?

    /// Deleting a button deletes its own log history — an orphaned LogEntry
    /// pointing at a vanished button is meaningless in-app (the durable historical
    /// record instead lives in the GitHub export, which denormalizes names).
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.button)
    var logEntries: [LogEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "⭐️",
        colorHex: String = "#3B82F6",
        sortOrder: Int = 0,
        loggingMode: LoggingMode = .instant,
        statKind: StatKind = .bar,
        heatmapMaxFrequency: Int? = nil,
        group: ActivityGroup? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.loggingModeRaw = loggingMode.rawValue
        self.statKindRaw = statKind.rawValue
        self.heatmapMaxFrequency = heatmapMaxFrequency
        self.group = group
        self.createdAt = createdAt
    }

    var loggingMode: LoggingMode {
        get { LoggingMode(rawValue: loggingModeRaw) ?? .instant }
        set { loggingModeRaw = newValue.rawValue }
    }

    var statKind: StatKind {
        get { StatKind(rawValue: statKindRaw) ?? .none }
        set { statKindRaw = newValue.rawValue }
    }
}
