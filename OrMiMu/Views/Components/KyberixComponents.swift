//
//  KyberixComponents.swift
//  OrMiMu
//
//  Created by Jules on 2024-05-23.
//

import SwiftUI

// KyberixButton Style
struct KyberixButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.kyberixBlack)
            .overlay(
                Rectangle()
                    .stroke(Color.kyberixWhite, lineWidth: 1)
            )
            .foregroundStyle(Color.kyberixWhite)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .font(.system(.body).bold())
            .textCase(.uppercase)
            .contentShape(Rectangle()) // Ensure tap target is rectangular
    }
}

// KyberixTextField Style
struct KyberixTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(Color.kyberixBlack)
            .overlay(
                Rectangle()
                    .stroke(Color.kyberixGrey, lineWidth: 1)
            )
            .foregroundStyle(Color.kyberixWhite)
            .font(.system(.body))
            .accentColor(Color.kyberixWhite) // Cursor color
    }
}

struct KyberixButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(KyberixButtonStyle())
    }
}

struct KyberixTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .textFieldStyle(KyberixTextFieldStyle())
    }
}

struct KyberixProgressView: View {
    let value: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.kyberixGrey)
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.kyberixWhite)
                    .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(value))), height: 4)
            }
        }
        .frame(height: 4)
    }
}

struct KyberixSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let rangeSpan = range.upperBound - range.lowerBound
            let progress = rangeSpan > 0 ? (value - range.lowerBound) / rangeSpan : 0
            let thumbWidth: CGFloat = 8
            // Center thumb
            let xOffset = width * CGFloat(progress) - (thumbWidth / 2)

            ZStack(alignment: .leading) {
                // Hit Area
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())

                // Track
                Rectangle()
                    .fill(Color.kyberixGrey)
                    .frame(height: 4)

                // Active Track
                Rectangle()
                    .fill(Color.kyberixWhite)
                    .frame(width: max(0, min(width, width * CGFloat(progress))), height: 4)

                // Thumb
                Rectangle()
                    .fill(Color.kyberixWhite)
                    .frame(width: thumbWidth, height: 16)
                    .offset(x: xOffset)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * rangeSpan
                        value = min(max(range.lowerBound, newValue), range.upperBound)
                    }
            )
        }
        .frame(height: 16)
    }
}

struct KyberixIcon: View {
    let name: String
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .light))
            .foregroundStyle(Color.kyberixWhite)
            .symbolRenderingMode(.monochrome)
    }
}
