//
//  LogEntry.swift
//  Tracker
//
//  One recorded occurrence of an ActivityButton being logged.
//

import Foundation
import SwiftData

@Model
final class LogEntry {
    @Attribute(.unique) var id: UUID
    /// For `.instant` buttons this IS the log timestamp. For `.timed` buttons this
    /// is the start of the recorded range.
    var startDate: Date
    /// Populated only for `.timed` buttons. `endDate` may be earlier in
    /// "clock time" than `startDate` when a range crosses midnight (e.g. 22:00 ->
    /// 02:00) — the edit UI is responsible for rolling it onto the next calendar
    /// day before saving, so `endDate` is always the true, absolute instant here.
    var endDate: Date?
    var button: ActivityButton?

    // Deliberately NOT denormalized with button/group name: every in-app screen
    // already reaches the live name through `button`, and duplicating it here
    // would just be state that can drift if a button is renamed. Denormalization
    // only happens at the GitHub export boundary (see BackupExportModels.swift),
    // where a standalone, human-readable JSON snapshot is the actual goal.

    init(id: UUID = UUID(), startDate: Date = .now, endDate: Date? = nil, button: ActivityButton?) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.button = button
    }

    var isTimed: Bool { endDate != nil }

    /// Duration for timed entries, nil for instant ones.
    var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
}
