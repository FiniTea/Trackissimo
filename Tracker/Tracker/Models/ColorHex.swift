//
//  ColorHex.swift
//  Tracker
//
//  SwiftData can't natively persist `Color`, so every model stores a hex string
//  instead. This file centralizes the Color <-> "#RRGGBB" conversion so the
//  conversion logic (and its rounding/edge-case behavior) lives in exactly one place.
//

import SwiftUI

extension Color {
    /// Creates a Color from a "#RRGGBB" or "RRGGBB" hex string. Falls back to gray
    /// if the string is malformed, since a broken color should never crash the app.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized.removeAll { $0 == "#" }

        var rgbValue: UInt64 = 0
        guard sanitized.count == 6, Scanner(string: sanitized).scanHexInt64(&rgbValue) else {
            self = .gray
            return
        }

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255
        let blue = Double(rgbValue & 0x0000FF) / 255
        self = Color(red: red, green: green, blue: blue)
    }

    /// Renders this color as "#RRGGBB" via UIKit's RGB resolution, which SwiftData
    /// models then persist as a plain String.
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}

/// A small curated palette offered when creating a group/button, so users aren't
/// forced through the full color picker for the common case.
enum PalettePresets {
    static let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown,
    ]
}
