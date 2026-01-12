import SwiftUI
import UIKit

// MARK: - Dark Blur View (AnyDistance-inspired)

/// Ultra-thin dark material blur for overlays, toasts, modals
struct DarkBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// Light blur variant for contrast situations
struct LightBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialLight

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Blur Background Modifier

struct BlurBackgroundModifier: ViewModifier {
    var cornerRadius: CGFloat = RepsTheme.Radius.md
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func body(content: Content) -> some View {
        content
            .background(
                DarkBlurView(style: style)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
    }
}

extension View {
    func blurBackground(
        cornerRadius: CGFloat = RepsTheme.Radius.md,
        style: UIBlurEffect.Style = .systemUltraThinMaterialDark
    ) -> some View {
        modifier(BlurBackgroundModifier(cornerRadius: cornerRadius, style: style))
    }
}

// MARK: - Blur + Fade Transition

struct BlurFadeModifier: ViewModifier {
    var blur: CGFloat
    var opacity: Double
    var scale: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
            .scaleEffect(scale)
    }
}

extension AnyTransition {
    static var blurFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 8, opacity: 0, scale: 0.9),
            identity: BlurFadeModifier(blur: 0, opacity: 1, scale: 1.0)
        )
    }

    static var subtleBlurFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 4, opacity: 0, scale: 0.95),
            identity: BlurFadeModifier(blur: 0, opacity: 1, scale: 1.0)
        )
    }
}

// MARK: - BlurOpacityTransition (AnyDistance-style)

/// Configurable blur + opacity + scale transition with timing control
struct BlurOpacityTransitionModifier: ViewModifier {
    var isVisible: Bool
    var blur: CGFloat = 8
    var speed: Double = 0.3
    var delay: Double = 0
    var anchor: UnitPoint = .center

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .blur(radius: isVisible || reduceMotion ? 0 : blur)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.95, anchor: anchor)
            .animation(
                reduceMotion ? .none : .easeOut(duration: speed).delay(delay),
                value: isVisible
            )
    }
}

extension View {
    /// Apply AnyDistance-style blur opacity transition
    func blurOpacityTransition(
        isVisible: Bool,
        blur: CGFloat = 8,
        speed: Double = 0.3,
        delay: Double = 0,
        anchor: UnitPoint = .center
    ) -> some View {
        modifier(BlurOpacityTransitionModifier(
            isVisible: isVisible,
            blur: blur,
            speed: speed,
            delay: delay,
            anchor: anchor
        ))
    }

    /// Staggered appearance with index-based delay
    func staggeredAppearance(
        isVisible: Bool,
        index: Int,
        staggerDelay: Double = 0.05,
        blur: CGFloat = 6
    ) -> some View {
        blurOpacityTransition(
            isVisible: isVisible,
            blur: blur,
            speed: 0.35,
            delay: Double(index) * staggerDelay
        )
    }
}
