import SwiftUI

// MARK: - Holographic Text

/// Alias to use new holographic shader for all gradient titles
typealias GradientTitle = HolographicText

/// Premium title text with subtle iridescent effect, parallax, and dynamic shadows
/// Uses theme-aware colors from PaletteManager
/// Responds to unified light source from MotionManager
struct HolographicText: View {
    let text: String
    var fontSize: CGFloat = 38
    var parallaxIntensity: CGFloat = 4   // Degrees of rotation (increased for visibility)
    var shadowIntensity: CGFloat = 0.4

    @ObservedObject private var motion = MotionManager.shared
    @ObservedObject private var paletteManager = PaletteManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Extract hue from active palette's accent color
    private var accentHue: CGFloat {
        let uiColor = UIColor(paletteManager.activePalette.accent)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return h
    }

    // Subtle gradient based on theme accent color
    private var subtleGradient: LinearGradient {
        let h = accentHue
        let angle = motion.lightAngle

        // Subtle hue variation: ±0.04 around theme accent (lighter/pastel colors)
        let colors: [Color] = [
            Color(hue: max(0, h - 0.04), saturation: 0.6, brightness: 0.98),
            Color(hue: h, saturation: 0.5, brightness: 1.0),  // Pure accent brightness
            Color(hue: min(1, h + 0.04), saturation: 0.6, brightness: 0.98),
        ]

        // Gradient angle shifts with device tilt (reduced multiplier for slower color shift)
        let gradientAngle = Angle(degrees: angle + motion.roll * 8)

        return LinearGradient(
            colors: colors,
            startPoint: UnitPoint(
                x: 0.5 + cos(gradientAngle.radians) * 0.5,
                y: 0.5 + sin(gradientAngle.radians) * 0.5
            ),
            endPoint: UnitPoint(
                x: 0.5 - cos(gradientAngle.radians) * 0.5,
                y: 0.5 - sin(gradientAngle.radians) * 0.5
            )
        )
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .foregroundStyle(subtleGradient)
        // Subtle drop shadow for depth
        .shadow(
            color: .black.opacity(0.3),
            radius: 4,
            x: 0,
            y: 4
        )
        // Extra padding to prevent clipping when offset moves text
        .padding(24)
        // PARALLAX: Position offset based on tilt (very pronounced movement)
        .offset(
            x: reduceMotion ? 0 : CGFloat(motion.roll * 12),
            y: reduceMotion ? 0 : CGFloat(motion.pitch * 8)
        )
        // PARALLAX: 3D rotation based on tilt (16 degrees on both axes)
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : motion.pitch * 16),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : motion.roll * 16),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        // CRITICAL: Flatten to single layer - prevents letter jiggling
        .drawingGroup()
        // Remove the extra padding after flattening (keeps layout correct)
        .padding(-24)
        // Snappy spring animations
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: motion.pitch)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: motion.roll)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: motion.lightAngle)
        .onAppear { motion.startUpdates() }
        .onDisappear { motion.stopUpdates() }
    }
}

// MARK: - View Modifier

struct HolographicModifier: ViewModifier {
    var intensity: CGFloat = 0.8

    @ObservedObject private var motion = MotionManager.shared
    @ObservedObject private var paletteManager = PaletteManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Extract hue from active palette's accent color
    private var accentHue: CGFloat {
        let uiColor = UIColor(paletteManager.activePalette.accent)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return h
    }

    private var subtleGradient: LinearGradient {
        let h = accentHue
        let angle = motion.lightAngle

        let colors: [Color] = [
            Color(hue: max(0, h - 0.04), saturation: 0.75 * intensity, brightness: 0.92),
            Color(hue: h, saturation: 0.65 * intensity, brightness: 1.0),
            Color(hue: min(1, h + 0.04), saturation: 0.75 * intensity, brightness: 0.92),
        ]

        let gradientAngle = Angle(degrees: angle)

        return LinearGradient(
            colors: colors,
            startPoint: UnitPoint(
                x: 0.5 + cos(gradientAngle.radians) * 0.5,
                y: 0.5 + sin(gradientAngle.radians) * 0.5
            ),
            endPoint: UnitPoint(
                x: 0.5 - cos(gradientAngle.radians) * 0.5,
                y: 0.5 - sin(gradientAngle.radians) * 0.5
            )
        )
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(subtleGradient)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: motion.lightAngle)
            .onAppear { motion.startUpdates() }
            .onDisappear { motion.stopUpdates() }
    }
}

// MARK: - View Extension

extension View {
    /// Apply holographic effect to any view (text works best)
    func holographic(intensity: CGFloat = 0.8) -> some View {
        modifier(HolographicModifier(intensity: intensity))
    }
}

// MARK: - Preview

#Preview("Holographic Text") {
    VStack(spacing: 32) {
        HolographicText(text: "Workout")
            .padding()

        HolographicText(text: "Premium", fontSize: 28)

        Text("Modifier")
            .font(.system(size: 24, weight: .bold))
            .holographic()

        // Side-by-side comparison
        HStack(spacing: 24) {
            VStack {
                Text("Holo")
                    .font(.title.bold())
                    .holographic()
                Text("With gradient")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack {
                Text("Plain")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("No effect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
