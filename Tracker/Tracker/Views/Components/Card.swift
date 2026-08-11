//
//  Card.swift
//  Tracker
//
//  Shared "box" container used throughout the app for the card-based look the
//  user asked for (rounded corners, subtle shadow/material, consistent spacing).
//

import SwiftUI

struct CardBackground: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint?.opacity(0.12) ?? Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint?.opacity(0.25) ?? Color.clear, lineWidth: tint == nil ? 0 : 1)
            )
    }
}

extension View {
    /// Wraps this view in the app's standard rounded-rect card container.
    /// Pass `tint` to give a card a subtle colored background matching a
    /// button/group's own color (e.g. on the Stats screens).
    func card(tint: Color? = nil) -> some View {
        modifier(CardBackground(tint: tint))
    }
}
