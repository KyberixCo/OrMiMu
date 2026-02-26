//
//  ActionComponents.swift
//  OrMiMu
//
//  Created by Kyberix on 2024-05-23.
//

import SwiftUI

struct KyberixFormRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .bold()
                .kerning(1.0)
                .foregroundStyle(Color.kyberixWhite)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.kyberixWhite)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.kyberixBlack)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.kyberixGrey),
            alignment: .bottom
        )
    }
}

struct KyberixBlockButton: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .kerning(1.0)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .overlay(
                Rectangle()
                    .stroke(Color.kyberixWhite, lineWidth: 1)
            )
            .onHover { isHovering = $0 }
            .contentShape(Rectangle())
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed || isHovering {
            return Color.kyberixWhite
        } else {
            return Color.kyberixBlack
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        if isPressed || isHovering {
            return Color.kyberixBlack
        } else {
            return Color.kyberixWhite
        }
    }
}

struct KyberixGeometricProgress: View {
    let value: Double // 0.0 to 1.0
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.kyberixBlack)
                    .overlay(Rectangle().stroke(Color.kyberixGrey, lineWidth: 1))

                // Fill
                Rectangle()
                    .fill(Color.kyberixWhite)
                    .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(value))))
            }
        }
        .frame(height: height)
    }
}
