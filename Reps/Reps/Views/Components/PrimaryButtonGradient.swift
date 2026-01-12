import SwiftUI

/// Animated gradient background for primary action buttons
/// Uses Metal shader with high brightness for vibrant button appearance
struct PrimaryButtonGradient: View {
    var palette: Palette { PaletteManager.shared.activePalette }

    var body: some View {
        MetalGradientView(
            palette: palette,
            speed: 0.6,       // Slightly slower for buttons
            brightness: 0.85  // Higher brightness for vibrant buttons
        )
    }
}

/// Button style that uses the animated gradient background
struct GradientButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Animated gradient background
            PrimaryButtonGradient()
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))

            // Dark overlay for better text contrast
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .fill(Color.black.opacity(0.2))

            // Button label
            configuration.label
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, RepsTheme.Spacing.lg)
                .padding(.vertical, RepsTheme.Spacing.md)
        }
        .frame(height: 50)
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Pill-shaped button style with gradient background
/// Perfect for FAB buttons and CTAs
struct GradientPillButtonStyle: ButtonStyle {
    var height: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.vertical, RepsTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(RepsTheme.Colors.accent)
            )
            .frame(minHeight: height)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Button with dark gradient fill and liquid metal animated border
/// Use for premium CTAs like "Start Early" button
struct LiquidMetalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Dark/black gradient fill
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.08),  // Near black
                            Color(white: 0.18)   // Dark gray
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            // Liquid metal border overlay (thicker)
            LiquidMetalBorder(
                cornerRadius: RepsTheme.Radius.md,
                lineWidth: 3.5
            )

            // Button label
            configuration.label
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, RepsTheme.Spacing.lg)
                .padding(.vertical, RepsTheme.Spacing.md)
        }
        .frame(height: 50)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(RepsTheme.Animations.buttonPress, value: configuration.isPressed)
        .drawingGroup()  // GPU-accelerate the composite
    }
}

#Preview {
    VStack(spacing: 24) {
        // Standalone gradient preview
        PrimaryButtonGradient()
            .frame(height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        // Button with gradient style
        Button("Start Workout") {}
            .buttonStyle(GradientButtonStyle())

        Button("Finish") {}
            .buttonStyle(GradientButtonStyle())

        Button("Create Superset") {}
            .buttonStyle(GradientButtonStyle())

        // Pill buttons
        HStack(spacing: 16) {
            Button {
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("New Exercise")
                }
            }
            .buttonStyle(GradientPillButtonStyle())

            Button {
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Begin Workout")
                }
            }
            .buttonStyle(GradientPillButtonStyle())
        }
    }
    .padding()
    .background(Color.black)
}
