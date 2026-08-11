//
//  Haptics.swift
//  Tracker
//
//  Tiny shared helper so every "I just logged something" moment gets the same
//  tactile confirmation, without importing UIKit's feedback generators all over the view layer.
//

import UIKit

enum Haptics {
    static func logged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selected() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
