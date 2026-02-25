//
//  KyberixComponents.swift
//  OrMiMu
//
//  Created by Jules on 2024-05-22.
//

import SwiftUI

// MARK: - Buttons

struct KyberixButtonStyle: ButtonStyle {
    var isFilled: Bool = false
    var color: Color = KyberixTheme.white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .kerning(1.0)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFilled ? (configuration.isPressed ? color.opacity(0.8) : color) : Color.clear)
            .foregroundColor(isFilled ? KyberixTheme.black : color)
            .border(color, width: 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - TextFields

struct KyberixTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(KyberixTheme.black)
            .overlay(
                Rectangle()
                    .stroke(KyberixTheme.divider, lineWidth: 1)
            )
            .font(.system(size: 13, design: .monospaced)) // Monospaced fits the "technical" look
            .foregroundColor(KyberixTheme.white)
    }
}

// MARK: - Progress

struct KyberixProgressView: View {
    var value: Double
    var total: Double = 1.0
    var color: Color = KyberixTheme.white
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(KyberixTheme.divider)
                    .frame(height: height)

                Rectangle()
                    .fill(color)
                    .frame(width: max(0, min(CGFloat(self.value / self.total) * geometry.size.width, geometry.size.width)), height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Slider

struct KyberixSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track Background
                Rectangle()
                    .fill(KyberixTheme.divider)
                    .frame(height: 2)
                    .offset(y: 0)

                // Track Fill
                Rectangle()
                    .fill(KyberixTheme.white)
                    .frame(width: calculateWidth(geometry: geometry), height: 2)
                    .offset(y: 0)

                // Thumb (Square)
                Rectangle()
                    .fill(KyberixTheme.white)
                    .frame(width: 8, height: 8)
                    .position(x: calculateThumbX(geometry: geometry), y: geometry.size.height / 2)
            }
            .contentShape(Rectangle()) // Make entire area draggable
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        updateValue(with: gesture, geometry: geometry)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 16) // Enough height for hit target
    }

    private func calculateWidth(geometry: GeometryProxy) -> CGFloat {
        let ratio = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return max(0, min(geometry.size.width, CGFloat(ratio) * geometry.size.width))
    }

    private func calculateThumbX(geometry: GeometryProxy) -> CGFloat {
        let ratio = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return max(0, min(geometry.size.width, CGFloat(ratio) * geometry.size.width))
    }

    private func updateValue(with gesture: DragGesture.Value, geometry: GeometryProxy) {
        let width = geometry.size.width
        let percent = min(max(0, gesture.location.x / width), 1)
        let newValue = range.lowerBound + percent * (range.upperBound - range.lowerBound)
        value = newValue
    }
}
