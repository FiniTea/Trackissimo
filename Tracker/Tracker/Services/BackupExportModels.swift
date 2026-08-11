//
//  BackupExportModels.swift
//  Tracker
//
//  Codable snapshot of the whole SwiftData store, pushed to GitHub as
//  `backups/tracker.json`. Deliberately denormalized (button/group names are
//  duplicated onto every log entry) so the exported JSON is analyzable on its
//  own — e.g. for correlation studies — without needing to join back against
//  the in-app database. This is the one place denormalization is intentional;
//  the SwiftData models themselves stay normalized (see LogEntry.swift).
//

import Foundation

struct BackupExport: Codable {
    var exportedAt: Date
    /// Bump and document a migration note here if this shape ever changes.
    var schemaVersion: Int
    var groups: [GroupExport]
    var buttons: [ButtonExport]
    var logEntries: [LogEntryExport]
    var wellbeingEntries: [WellbeingExport]
}

struct GroupExport: Codable {
    var id: UUID
    var name: String
    var showsPieChart: Bool
    var sortOrder: Int
}

struct ButtonExport: Codable {
    var id: UUID
    var name: String
    var groupId: UUID?
    var groupName: String?
    var icon: String
    var colorHex: String
    var loggingMode: String
    var statKind: String
    var heatmapMaxFrequency: Int?
}

struct LogEntryExport: Codable {
    var id: UUID
    var buttonId: UUID?
    var buttonName: String
    var groupName: String?
    var startDate: Date
    var endDate: Date?
}

struct WellbeingExport: Codable {
    var id: UUID
    var score: Int
    var timestamp: Date
}

enum BackupCoding {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
