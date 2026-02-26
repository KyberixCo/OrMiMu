//
//  SidebarButton.swift
//  OrMiMu
//
//  Created by Kyberix on 2024-05-23.
//

import SwiftUI

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(isSelected ? Color.kyberixBlack : Color.kyberixWhite)
                    .frame(width: 20, alignment: .center)

                // Text
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.kyberixBlack : Color.kyberixWhite)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.kyberixWhite : (isHovering ? Color.kyberixGrey : Color.kyberixBlack))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
