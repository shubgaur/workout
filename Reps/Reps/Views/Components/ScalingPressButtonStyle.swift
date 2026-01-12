import SwiftUI

// MARK: - Scaling Press Button Style (AnyDistance-inspired)

/// Premium button style with scale + opacity animation on press
struct ScalingPressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var opacity: CGFloat = 0.8

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(RepsTheme.Animations.press, value: configuration.isPressed)
    }
}

/// Subtle version for smaller interactive elements
struct SubtleScalingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(RepsTheme.Animations.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - View Extension

extension View {
    func scalingPressStyle(scale: CGFloat = 0.95, opacity: CGFloat = 0.8) -> some View {
        self.buttonStyle(ScalingPressButtonStyle(scale: scale, opacity: opacity))
    }

    func subtleScalingStyle() -> some View {
        self.buttonStyle(SubtleScalingButtonStyle())
    }
}
