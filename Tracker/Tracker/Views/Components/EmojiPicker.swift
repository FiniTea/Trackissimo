//
//  EmojiPicker.swift
//  Tracker
//
//  Icon selection for group/button creation. Icons are stored as a single
//  emoji character rather than a curated SF Symbol name, so the free-text
//  field below — which just opens the system's native emoji keyboard — gives
//  access to every emoji iOS supports, not a hand-picked subset. The grid is
//  purely a one-tap shortcut for the most common everyday choices.
//

import SwiftUI

struct EmojiPicker: View {
    @Binding var icon: String
    @FocusState private var isTextFieldFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible()), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symbol")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text(icon.isEmpty ? "❓" : icon)
                    .font(.system(size: 36))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color(.secondarySystemBackground)))

                TextField("Eigenes Emoji eingeben…", text: $icon)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onChange(of: icon) { _, newValue in
                        // Keep only the most recently typed character, so the
                        // field always represents exactly one icon even if
                        // someone types or pastes more than one emoji.
                        if let last = newValue.last, String(last) != icon {
                            icon = String(last)
                        }
                    }
            }

            Text("Tippe im Textfeld auf die Emoji-Taste (🌐 oder 😀) auf der Tastatur, um aus allen Emojis zu wählen — oder nimm unten eins der häufigsten.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(curatedEmojis, id: \.self) { emoji in
                    Button {
                        icon = emoji
                        isTextFieldFocused = false
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(emoji == icon ? Color.accentColor.opacity(0.25) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// A cross-section of everyday activities, grouped loosely by theme, offered
/// as one-tap shortcuts. Not exhaustive by design — the text field above is
/// the escape hatch to literally any emoji, so this list only needs to cover
/// common cases well, not completely.
private let curatedEmojis: [String] = [
    // Bathroom / hygiene
    "🚽", "🚿", "🛁", "🧴", "🧼", "🪥",
    // Food / drink
    "🍽️", "☕️", "🍵", "🍺", "🥗", "🍕",
    // Sport / health
    "🏃", "🚴", "🧘", "💪", "⚽️", "💊",
    // People / social
    "👥", "❤️", "💬", "📞", "🎉", "👋",
    // Gaming / entertainment
    "🎮", "📺", "🎬", "🎧", "📚", "🎨",
    // Sleep / rest
    "🛌", "😴", "🌙", "☀️", "⏰", "😌",
    // Work / chores
    "💼", "💻", "📄", "🛒", "🏠", "🚗",
    // Misc
    "⭐️", "🚩", "✅", "🔥", "🎁", "🐾",
]

#Preview {
    @Previewable @State var icon = "🚿"
    return EmojiPicker(icon: $icon).padding()
}
