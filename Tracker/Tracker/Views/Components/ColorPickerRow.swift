//
//  ColorPickerRow.swift
//  Tracker
//
//  Color selection for groups/buttons: a row of curated preset swatches plus a
//  fallback to the full system ColorPicker for anything more specific. Bridges
//  to/from the hex-string storage SwiftData models actually persist.
//

import SwiftUI

struct ColorPickerRow: View {
    /// Bound as a hex string since that's what the model stores directly.
    @Binding var colorHex: String

    private var selectedColor: Color {
        get { Color(hex: colorHex) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Farbe")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(Array(PalettePresets.colors.enumerated()), id: \.offset) { _, presetColor in
                    swatch(presetColor)
                }

                ColorPicker("", selection: Binding(
                    get: { selectedColor },
                    set: { colorHex = $0.toHex() }
                ))
                .labelsHidden()
            }
        }
    }

    private func swatch(_ color: Color) -> some View {
        let isSelected = color.toHex() == selectedColor.toHex()
        return Button {
            colorHex = color.toHex()
        } label: {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: isSelected ? 2 : 0)
                        .padding(-2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var hex = "#3B82F6"
    return ColorPickerRow(colorHex: $hex).padding()
}
