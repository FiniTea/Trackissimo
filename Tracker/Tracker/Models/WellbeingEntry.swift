//
//  WellbeingEntry.swift
//  Tracker
//
//  One mood pick from the app-open gate (1 = worst, 5 = best). App-global, not
//  tied to any group/button. Since the gate fires on every app open (not once a
//  day), multiple entries per day are expected and normal.
//

import Foundation
import SwiftData

@Model
final class WellbeingEntry {
    @Attribute(.unique) var id: UUID
    /// 1 (worst) ... 5 (best).
    var score: Int
    var timestamp: Date
    /// Whether the mirrored `HKStateOfMind` write to Apple Health succeeded.
    /// HealthKit writes can fail (permission revoked, HealthKit unavailable, no
    /// network needed but store errors do happen) — this flag lets Settings offer
    /// a "retry failed syncs" action instead of silently losing the Health mirror.
    var healthKitSynced: Bool

    init(id: UUID = UUID(), score: Int, timestamp: Date = .now, healthKitSynced: Bool = false) {
        self.id = id
        self.score = score
        self.timestamp = timestamp
        self.healthKitSynced = healthKitSynced
    }
}
