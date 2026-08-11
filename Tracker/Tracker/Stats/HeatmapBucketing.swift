//
//  HeatmapBucketing.swift
//  Tracker
//
//  Maps a day's log count to one of a small number of shade buckets, relative
//  to the button's own configured `heatmapMaxFrequency` — so a button logged at
//  most ~5x/day gets a meaningfully different heatmap than one logged ~50x/day,
//  without any hardcoded per-button thresholds like the old HTML app had.
//

import SwiftUI

enum HeatmapBucketing {
    static let shadeBucketCount = 4

    /// Bucket 0 = no logs that day (rendered as an empty/neutral cell).
    /// Buckets 1...`shadeBucketCount` = increasingly saturated shades, scaled so
    /// `maxFrequency` (or more) logs in a day always lands in the darkest bucket.
    /// Example: maxFrequency=5 -> 1 log->bucket 1, 2->2, 3->3, 4 or 5+->bucket 4.
    static func bucket(for dayCount: Int, maxFrequency: Int, buckets: Int = shadeBucketCount) -> Int {
        guard dayCount > 0, maxFrequency > 0 else { return 0 }
        let raw = Double(dayCount) / Double(maxFrequency) * Double(buckets)
        return min(buckets, max(1, Int(raw.rounded(.up))))
    }

    /// The color to fill a heatmap cell with, given its shade bucket and the
    /// button's base color. Opacity interpolation (rather than brightness/
    /// saturation manipulation) is used because it stays legible for *any*
    /// user-chosen base color, including ones already close to white or black.
    static func shade(baseColor: Color, bucket: Int, buckets: Int = shadeBucketCount) -> Color {
        guard bucket > 0 else { return Color(.tertiarySystemFill) }
        let minOpacity = 0.28
        let maxOpacity = 1.0
        let step = (maxOpacity - minOpacity) / Double(buckets - 1)
        let opacity = minOpacity + step * Double(bucket - 1)
        return baseColor.opacity(opacity)
    }
}
