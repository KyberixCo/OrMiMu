//
//  KyberixTheme.swift
//  OrMiMu
//
//  Created by Jules on 2024-05-22.
//

import SwiftUI

struct KyberixTheme {
    static let black = Color(red: 0, green: 0, blue: 0)
    static let white = Color(red: 1, green: 1, blue: 1)
    static let divider = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333 is roughly 0.2

    struct Font {
        static func header() -> SwiftUI.Font {
            return .system(size: 13, weight: .bold, design: .default)
        }

        static func body() -> SwiftUI.Font {
            return .system(size: 13, weight: .regular, design: .default)
        }

        static func caption() -> SwiftUI.Font {
            return .system(size: 11, weight: .regular, design: .default)
        }
    }
}

extension View {
    func kyberixTracking() -> some View {
        self.kerning(1.0)
    }
}
