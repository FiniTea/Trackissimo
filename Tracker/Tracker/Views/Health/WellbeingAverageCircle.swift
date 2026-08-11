//
//  WellbeingAverageCircle.swift
//  Tracker
//
//  A colored circle summarizing a wellbeing average for some period. Tapping
//  it reveals the exact value to 2 decimal places.
//

import SwiftUI

struct WellbeingAverageCircle: View {
    let label: String
    let average: Double?
    var size: CGFloat = 64

    @State private var showExact = false

    var body: some View {
        VStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showExact.toggle() }
            } label: {
                Circle()
                    .fill(average.map { ColorInterpolation.wellbeingColor(for: $0) } ?? Color(.systemGray5))
                    .frame(width: size, height: size)
                    .overlay {
                        if showExact, let average {
                            Text(String(format: "%.2f", average))
                                .font(.system(size: size * 0.24, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(average == nil)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
