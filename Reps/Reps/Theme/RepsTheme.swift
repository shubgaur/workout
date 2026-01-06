import SwiftUI

// MARK: - Teenage Engineering Inspired Theme

enum RepsTheme {
    // MARK: Colors (Adaptive Light/Dark)
    enum Colors {
        // Background colors - adapts to light/dark mode
        static let background = Color("Background", bundle: nil)
        static let surface = Color("Surface", bundle: nil)
        static let surfaceElevated = Color("SurfaceElevated", bundle: nil)
        static let surfacePressed = Color("SurfacePressed", bundle: nil)

        static let accent = Color(hex: "FF5500") // Teenage Engineering Orange - stays same
        static let accentLight = Color(hex: "FF7733")
        static let accentDark = Color(hex: "CC4400")

        // Text colors - adapts to light/dark mode
        static let text = Color("Text", bundle: nil)
        static let textSecondary = Color("TextSecondary", bundle: nil)
        static let textTertiary = Color("TextTertiary", bundle: nil)

        static let success = Color(hex: "4CAF50")
        static let successBackground = Color("SuccessBackground", bundle: nil)
        static let warning = Color(hex: "FFC107")
        static let error = Color(hex: "F44336")

        static let border = Color("Border", bundle: nil)
        static let divider = Color("Divider", bundle: nil)

        // Fallback colors for when asset catalog isn't set up
        enum Dark {
            static let background = Color(hex: "0A0A0A")
            static let surface = Color(hex: "141414")
            static let surfaceElevated = Color(hex: "1C1C1C")
            static let surfacePressed = Color(hex: "0F0F0F")
            static let text = Color(hex: "F5F5F5")
            static let textSecondary = Color(hex: "8A8A8A")
            static let textTertiary = Color(hex: "5A5A5A")
            static let border = Color(hex: "2A2A2A")
            static let divider = Color(hex: "1E1E1E")
            static let successBackground = Color(hex: "1B3D1C")
        }

        enum Light {
            static let background = Color(hex: "F8F8F8")
            static let surface = Color(hex: "FFFFFF")
            static let surfaceElevated = Color(hex: "F0F0F0")
            static let surfacePressed = Color(hex: "E8E8E8")
            static let text = Color(hex: "1A1A1A")
            static let textSecondary = Color(hex: "6B6B6B")
            static let textTertiary = Color(hex: "9A9A9A")
            static let border = Color(hex: "E0E0E0")
            static let divider = Color(hex: "EBEBEB")
            static let successBackground = Color(hex: "E8F5E9")
        }
    }

    // MARK: Typography
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)

        // Monospace for numbers (industrial feel)
        static let mono = Font.system(size: 17, weight: .medium, design: .monospaced)
        static let monoLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
        static let monoSmall = Font.system(size: 14, weight: .medium, design: .monospaced)
    }

    // MARK: Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Corner Radius
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 9999
    }

    // MARK: Shadows (subtle depth for skeuomorphism)
    enum Shadow {
        static let sm = ShadowStyle(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        static let md = ShadowStyle(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
        static let lg = ShadowStyle(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        static let inner = ShadowStyle(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct RepsCardStyle: ViewModifier {
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .fill(isPressed ? RepsTheme.Colors.surfacePressed : RepsTheme.Colors.surface)
                    .shadow(
                        color: RepsTheme.Shadow.md.color,
                        radius: RepsTheme.Shadow.md.radius,
                        x: RepsTheme.Shadow.md.x,
                        y: RepsTheme.Shadow.md.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )
    }
}

struct RepsButtonStyle: ButtonStyle {
    var style: ButtonStyleType = .primary

    enum ButtonStyleType {
        case primary, secondary, ghost
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RepsTheme.Typography.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, RepsTheme.Spacing.lg)
            .padding(.vertical, RepsTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(configuration.isPressed ? pressedBackground : background)
                    .shadow(
                        color: configuration.isPressed ? .clear : RepsTheme.Shadow.sm.color,
                        radius: RepsTheme.Shadow.sm.radius,
                        x: RepsTheme.Shadow.sm.x,
                        y: RepsTheme.Shadow.sm.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .stroke(borderColor, lineWidth: style == .secondary ? 2 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return RepsTheme.Colors.accent
        case .ghost: return RepsTheme.Colors.text
        }
    }

    private var background: Color {
        switch style {
        case .primary: return RepsTheme.Colors.accent
        case .secondary: return .clear
        case .ghost: return .clear
        }
    }

    private var pressedBackground: Color {
        switch style {
        case .primary: return RepsTheme.Colors.accentDark
        case .secondary: return RepsTheme.Colors.accent.opacity(0.1)
        case .ghost: return RepsTheme.Colors.surface
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return RepsTheme.Colors.accent
        case .ghost: return .clear
        }
    }
}

// MARK: - View Extensions

extension View {
    func repsCard(isPressed: Bool = false) -> some View {
        modifier(RepsCardStyle(isPressed: isPressed))
    }

    func repsShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
