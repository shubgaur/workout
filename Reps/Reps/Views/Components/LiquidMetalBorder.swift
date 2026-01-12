// Licensed under the Reps Source License
//
//  LiquidMetalBorder.swift
//  Reps
//
//  Animated liquid metal chromatic border that responds to device tilt
//  Uses unified lightAngle from MotionManager for coordinated effects

import SwiftUI

/// Animated liquid metal chromatic border
/// Responds to device tilt via MotionManager
/// Colors adapt to current theme accent
struct LiquidMetalBorder: View {
    var cornerRadius: CGFloat = RepsTheme.Radius.md
    var lineWidth: CGFloat = 2.5

    @ObservedObject private var motion = MotionManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var startDate = Date.now

    private var accentColor: Color {
        PaletteManager.shared.activePalette.accent
    }

    var body: some View {
        if reduceMotion {
            // Accessibility: Solid accent border instead of frozen animation
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(accentColor, lineWidth: lineWidth)
        } else {
            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
                    let time = Float(timeline.date.timeIntervalSince(startDate))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white, lineWidth: lineWidth)
                        .colorEffect(
                            ShaderLibrary.liquidMetalBorder(
                                .float2(geo.size),
                                .float(time),
                                .float(Float(motion.lightAngle)),
                                .color(accentColor)
                            )
                        )
                }
            }
            .trackingMotion()
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        // Preview the border effect
        LiquidMetalBorder(cornerRadius: 12, lineWidth: 3)
            .frame(width: 200, height: 50)

        // Stacked on a button-like shape
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.6), Color.orange],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            LiquidMetalBorder(cornerRadius: 12, lineWidth: 2.5)

            Text("Start Early")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(width: 200, height: 50)
    }
    .padding()
    .background(Color.black)
}
