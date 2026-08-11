//
//  Enums.swift
//  Tracker
//
//  Shared enums used by the SwiftData models. Stored on models as raw `String`
//  values (not native SwiftData enum storage) so the underlying store stays
//  stable and human-readable even if cases are ever renamed/reordered.
//

import Foundation

/// How a button records time when tapped.
enum LoggingMode: String, Codable, CaseIterable, Identifiable {
    /// A single tap immediately logs "now" — no further input needed (e.g. "Pinkeln").
    case instant
    /// A tap opens a sheet asking for a start/end time range (e.g. "Sofie", 10:00–13:00).
    case timed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .instant: return "Einmalig"
        case .timed: return "Zeitspanne"
        }
    }
}

/// Which statistic view a button renders, chosen when the button is created.
///
/// Pie charts are intentionally not a case here — per product decision, pie charts
/// summarize a whole *group* (share of each button within it), not a single button.
enum StatKind: String, Codable, CaseIterable, Identifiable {
    /// No dedicated stats screen.
    case none
    case bar
    case heatmap

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Keine"
        case .bar: return "Balkendiagramm"
        case .heatmap: return "Heatmap"
        }
    }
}
