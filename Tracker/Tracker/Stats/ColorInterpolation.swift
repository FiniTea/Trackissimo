//
//  ColorInterpolation.swift
//  Tracker
//
//  Maps a wellbeing average (1.0...5.0, continuous) to a color by linearly
//  interpolating between 5 fixed stops. Interpolating rather than snapping to
//  the nearest stop is deliberate: an average is inherently fractional (e.g.
//  3.4), and a smooth blend communicates that better than a hard snap, at no
//  extra implementation cost.
//

import SwiftUI

enum ColorInterpolation {
    private static let stops: [(value: Double, color: Color)] = [
        (1, .red),
        (2, .orange),
        (3, .blue),
        (4, Color(red: 0.56, green: 0.93, blue: 0.56)), // light green
        (5, Color(red: 0.0, green: 0.39, blue: 0.0)),   // dark green
    ]

    static func wellbeingColor(for average: Double) -> Color {
        let clamped = min(5, max(1, average))
        guard let upperIndex = stops.firstIndex(where: { $0.value >= clamped }), upperIndex > 0 else {
            return stops.first!.color
        }
        let lower = stops[upperIndex - 1]
        let upper = stops[upperIndex]
        guard upper.value != lower.value else { return upper.color }
        let fraction = (clamped - lower.value) / (upper.value - lower.value)
        return lerp(lower.color, upper.color, fraction: fraction)
    }

    private static func lerp(_ a: Color, _ b: Color, fraction: Double) -> Color {
        let uiA = UIColor(a)
        let uiB = UIColor(b)
        var rA: CGFloat = 0, gA: CGFloat = 0, bA: CGFloat = 0, aA: CGFloat = 0
        var rB: CGFloat = 0, gB: CGFloat = 0, bB: CGFloat = 0, aB: CGFloat = 0
        uiA.getRed(&rA, green: &gA, blue: &bA, alpha: &aA)
        uiB.getRed(&rB, green: &gB, blue: &bB, alpha: &aB)
        let t = CGFloat(fraction)
        return Color(
            red: Double(rA + (rB - rA) * t),
            green: Double(gA + (gB - gA) * t),
            blue: Double(bA + (bB - bA) * t)
        )
    }
}
