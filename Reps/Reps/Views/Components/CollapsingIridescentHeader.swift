import SwiftUI

// MARK: - Collapsing Iridescent Header

/// A scroll-aware header with iridescent title that collapses on scroll down
/// and reappears on scroll up. Uses blur/glass background for readability.
///
/// Usage:
/// ```swift
/// @State private var headerState = CollapsingHeaderState()
///
/// ScrollView {
///     content
/// }
/// .onScrollGeometryChange(for: CGFloat.self) { geo in
///     geo.contentOffset.y + geo.contentInsets.top
/// } action: { old, new in
///     headerState.handleScroll(oldOffset: old, newOffset: new)
/// }
/// .safeAreaInset(edge: .top, spacing: 0) {
///     CollapsingIridescentHeader(title: "Title", isVisible: $headerState.isVisible)
/// }
/// ```
struct CollapsingIridescentHeader<TrailingContent: View>: View {
    let title: String
    @Binding var isVisible: Bool
    @ViewBuilder let trailingContent: () -> TrailingContent

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HolographicText(text: title)
                Spacer()
                trailingContent()
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.top, RepsTheme.Spacing.xl)
            .padding(.bottom, RepsTheme.Spacing.sm)
            .frame(maxWidth: .infinity)  // Ensure HStack doesn't collapse
        }
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85),
            value: isVisible
        )
    }
}

// MARK: - Convenience Initializer

extension CollapsingIridescentHeader where TrailingContent == EmptyView {
    init(title: String, isVisible: Binding<Bool>) {
        self.title = title
        self._isVisible = isVisible
        self.trailingContent = { EmptyView() }
    }
}

// MARK: - Collapsing Header State

/// Manages scroll-aware visibility state for collapsing headers.
/// Use with `onScrollGeometryChange` to track scroll position.
@Observable
final class CollapsingHeaderState {
    var isVisible: Bool = true

    private var lastScrollOffset: CGFloat = 0
    private var accumulatedScrollUp: CGFloat = 0

    // Configuration
    private let scrollUpThreshold: CGFloat = 50
    private let hideThreshold: CGFloat = 0  // Hide immediately when scrolling starts

    /// Call this from `onScrollGeometryChange` action closure
    func handleScroll(oldOffset: CGFloat, newOffset: CGFloat) {
        let delta = newOffset - oldOffset

        // At or near top - always show
        if newOffset <= 10 {
            if !isVisible {
                isVisible = true
            }
            accumulatedScrollUp = 0
            lastScrollOffset = newOffset
            return
        }

        // Scrolling up
        if delta < 0 {
            accumulatedScrollUp += abs(delta)
            if accumulatedScrollUp >= scrollUpThreshold && !isVisible {
                isVisible = true
            }
        }
        // Scrolling down
        else if delta > 0 {
            accumulatedScrollUp = 0
            if newOffset > hideThreshold && isVisible {
                isVisible = false
            }
        }

        lastScrollOffset = newOffset
    }

    /// Reset state (e.g., when tab changes)
    func reset() {
        isVisible = true
        lastScrollOffset = 0
        accumulatedScrollUp = 0
    }
}

// MARK: - Binding Extension for @Observable

extension CollapsingHeaderState {
    var isVisibleBinding: Binding<Bool> {
        Binding(
            get: { self.isVisible },
            set: { self.isVisible = $0 }
        )
    }
}

// MARK: - Preview

#Preview("Collapsing Header") {
    struct PreviewWrapper: View {
        @State private var headerState = CollapsingHeaderState()

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<50) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 80)
                                .overlay(Text("Item \(index)").foregroundStyle(.white))
                        }
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { old, new in
                    headerState.handleScroll(oldOffset: old, newOffset: new)
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    CollapsingIridescentHeader(
                        title: "Workouts",
                        isVisible: headerState.isVisibleBinding
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("With Trailing Content") {
    struct PreviewWrapper: View {
        @State private var headerState = CollapsingHeaderState()
        @State private var showFilters = false

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<50) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 80)
                        }
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { old, new in
                    headerState.handleScroll(oldOffset: old, newOffset: new)
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    CollapsingIridescentHeader(
                        title: "Exercises",
                        isVisible: headerState.isVisibleBinding
                    ) {
                        Button {
                            showFilters.toggle()
                        } label: {
                            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(RepsTheme.Colors.accent)
                        }
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
