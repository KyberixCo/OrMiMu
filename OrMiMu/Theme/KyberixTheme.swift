//
//  KyberixTheme.swift
//  OrMiMu
//
//  Created by Kyberix on 2024-05-23.
//

import SwiftUI

struct KyberixTheme {
    static let black = Color(red: 0, green: 0, blue: 0)
    static let white = Color(red: 1, green: 1, blue: 1)
    static let grey = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
}

extension Color {
    static let kyberixBlack = KyberixTheme.black
    static let kyberixWhite = KyberixTheme.white
    static let kyberixGrey = KyberixTheme.grey
}

struct KyberixHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.caption, design: .default).weight(.bold))
            .textCase(.uppercase)
            .kerning(1.5)
            .foregroundStyle(Color.kyberixWhite)
    }
}

struct KyberixBody: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.kyberixWhite)
    }
}

extension View {
    func kyberixHeader() -> some View {
        modifier(KyberixHeader())
    }

    func kyberixBody() -> some View {
        modifier(KyberixBody())
    }
}
