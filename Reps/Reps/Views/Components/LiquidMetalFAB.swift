// Licensed under the Reps Source License
//
//  LiquidMetalFAB.swift
//  Reps
//
//  Floating action button with liquid metal border effect

import SwiftUI

/// Floating action button with liquid metal border
struct LiquidMetalFAB: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            ZStack {
                // Dark fill
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.08),
                                Color(white: 0.18)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                // Liquid metal border
                LiquidMetalBorder(
                    cornerRadius: size / 2,
                    lineWidth: 3
                )

                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(ScalingPressButtonStyle())
        .drawingGroup()
    }
}

/// Liquid metal icon button for headers (smaller, inline)
struct LiquidMetalIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            ZStack {
                // Dark fill
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.08),
                                Color(white: 0.18)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                // Liquid metal border
                LiquidMetalBorder(
                    cornerRadius: size / 2,
                    lineWidth: 2.5
                )

                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(ScalingPressButtonStyle())
        .drawingGroup()
    }
}

/// Liquid metal pill button with icon and text
struct LiquidMetalPillButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var height: CGFloat = 48

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            HStack(spacing: RepsTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, RepsTheme.Spacing.lg)
            .frame(height: height)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.08),
                                Color(white: 0.18)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            )
            .overlay(
                LiquidMetalBorder(
                    cornerRadius: height / 2,
                    lineWidth: 2.5
                )
            )
        }
        .buttonStyle(ScalingPressButtonStyle())
        .drawingGroup()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 32) {
            LiquidMetalFAB(icon: "plus", action: {
                print("FAB tapped")
            })

            LiquidMetalIconButton(icon: "plus", action: {
                print("Icon button tapped")
            }, size: 36)

            LiquidMetalPillButton(icon: "plus", title: "New Exercise", action: {
                print("Pill button tapped")
            })
        }
    }
}
