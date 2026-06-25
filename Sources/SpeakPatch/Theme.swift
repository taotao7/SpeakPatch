import SwiftUI

enum Theme {
    static let panelSize = CGSize(width: 480, height: 380)

    static let background = Color(hex: "#f5f0e8ff")
    static let surface = Color(hex: "#ede8e0ff")
    static let elevatedSurface = Color(hex: "#faf8f4ff")
    static let border = Color(hex: "#c4b8a8ff")
    static let text = Color(hex: "#2d2a27ff")
    static let textMuted = Color(hex: "#6b6560ff")
    static let textPlaceholder = Color(hex: "#928374ff")
    static let accent = Color(hex: "#d65d0eff")
    static let success = Color(hex: "#458588ff")
    static let error = Color(hex: "#9d0006ff")
    static let errorBackground = Color(hex: "#9d00061a")
    static let hover = Color(hex: "#e8e0d6ff")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (r, g, b, a) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            assertionFailure("Invalid hex color: \(hex)")
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
