import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var scrubProgress: CGFloat?

    // Scrub state
    @State private var isScrubbing = false
    @State private var scrubLocation: CGFloat? = nil
    @State private var currentHoverTab: Tab? = nil
    @State private var hasConfirmedHorizontal = false
    @GestureState private var pressLocation: CGPoint? = nil

    // Magnification constants
    private let maxScale: CGFloat = 1.3
    private let maxYOffset: CGFloat = -10
    private let magnificationRadius: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(Tab.allCases.enumerated()), id: \.element) { index, tab in
                    tabButton(for: tab, index: index, tabBarWidth: geo.size.width)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($pressLocation) { value, state, _ in
                        state = value.location
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onEnded { _ in
                        let x = pressLocation?.x ?? geo.size.width / 2
                        enterScrubMode(at: x, tabBarWidth: geo.size.width)
                    }
            )
            .simultaneousGesture(
                scrubDragGesture(tabBarWidth: geo.size.width)
            )
            .coordinateSpace(name: "tabBar")
        }
        .frame(height: 56)
        .padding(.top, 4)
        .background(
            ZStack {
                // Animated gradient background
                MetalGradientView(
                    palette: PaletteManager.shared.activePalette,
                    speed: 0.4,
                    brightness: 0.6
                )

                // Subtle dark overlay for text contrast
                RepsTheme.Colors.surface.opacity(0.3)
            }
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(for tab: Tab, index: Int, tabBarWidth: CGFloat) -> some View {
        let isSelected = selectedTab == tab

        Button {
            guard !isScrubbing else { return }
            HapticManager.tabChanged()
            withAnimation(RepsTheme.Animations.tabTransition) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(magnificationScale(for: index, tabBarWidth: tabBarWidth))
                    .offset(y: magnificationYOffset(for: index, tabBarWidth: tabBarWidth))
                    .animation(.spring(response: 0.15, dampingFraction: 0.7), value: scrubLocation)

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(tabColor(for: tab, index: index))
            .frame(maxWidth: .infinity)
            .padding(.vertical, RepsTheme.Spacing.xs)
            .background(
                // Static glint indicator for active tab only
                Group {
                    if isSelected {
                        Capsule()
                            .fill(RepsTheme.Colors.accent.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                RepsTheme.Colors.accent.opacity(0.6),
                                                RepsTheme.Colors.accent.opacity(0.2),
                                                .clear,
                                                .clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
        .accessibilityAdjustableAction { direction in
            let allTabs = Tab.allCases
            guard let currentIndex = allTabs.firstIndex(of: tab) else { return }

            switch direction {
            case .increment:
                if currentIndex < allTabs.count - 1 {
                    HapticManager.tabChanged()
                    withAnimation(RepsTheme.Animations.tabTransition) {
                        selectedTab = allTabs[currentIndex + 1]
                    }
                }
            case .decrement:
                if currentIndex > 0 {
                    HapticManager.tabChanged()
                    withAnimation(RepsTheme.Animations.tabTransition) {
                        selectedTab = allTabs[currentIndex - 1]
                    }
                }
            @unknown default:
                break
            }
        }
    }

    // MARK: - Tab Color

    private func tabColor(for tab: Tab, index: Int) -> Color {
        if isScrubbing, let hoverTab = currentHoverTab {
            return tab == hoverTab ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary
        }
        return selectedTab == tab ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary
    }

    // MARK: - Magnification

    private func magnificationScale(for tabIndex: Int, tabBarWidth: CGFloat) -> CGFloat {
        guard let scrubX = scrubLocation else { return 1.0 }
        let tabWidth = tabBarWidth / CGFloat(Tab.allCases.count)
        let tabCenterX = tabWidth * (CGFloat(tabIndex) + 0.5)
        let distance = abs(scrubX - tabCenterX)
        let normalizedDist = min(distance / magnificationRadius, 1.0)
        let factor = max(0, 1 - pow(normalizedDist, 2))
        return 1.0 + (maxScale - 1.0) * factor
    }

    private func magnificationYOffset(for tabIndex: Int, tabBarWidth: CGFloat) -> CGFloat {
        guard let scrubX = scrubLocation else { return 0 }
        let tabWidth = tabBarWidth / CGFloat(Tab.allCases.count)
        let tabCenterX = tabWidth * (CGFloat(tabIndex) + 0.5)
        let distance = abs(scrubX - tabCenterX)
        let normalizedDist = min(distance / magnificationRadius, 1.0)
        let factor = max(0, 1 - pow(normalizedDist, 2))
        return maxYOffset * factor
    }

    // MARK: - Gesture

    private func scrubDragGesture(tabBarWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("tabBar"))
            .onChanged { value in
                guard isScrubbing else { return }

                // Directional filter - only process horizontal
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                if !hasConfirmedHorizontal && (horizontal > 5 || vertical > 5) {
                    hasConfirmedHorizontal = horizontal >= vertical
                }

                guard hasConfirmedHorizontal else { return }

                handleScrubDrag(at: value.location.x, tabBarWidth: tabBarWidth)
            }
            .onEnded { value in
                hasConfirmedHorizontal = false
                handleScrubEnd(finalX: value.location.x, tabBarWidth: tabBarWidth)
            }
    }

    // MARK: - Scrub Handlers

    private func enterScrubMode(at x: CGFloat, tabBarWidth: CGFloat) {
        guard !isScrubbing else { return }
        isScrubbing = true
        scrubLocation = x  // Set initial position for magnification

        let tabWidth = tabBarWidth / CGFloat(Tab.allCases.count)
        let tabIndex = min(max(0, Int(x / tabWidth)), Tab.allCases.count - 1)
        currentHoverTab = Tab.allCases[tabIndex]
        HapticManager.medium()
    }

    private func handleScrubDrag(at x: CGFloat, tabBarWidth: CGFloat) {
        let clampedX = max(0, min(tabBarWidth, x))
        scrubLocation = clampedX

        let tabWidth = tabBarWidth / CGFloat(Tab.allCases.count)
        let progress = max(0, min(CGFloat(Tab.allCases.count - 1), (clampedX / tabWidth) - 0.5))
        scrubProgress = progress

        // Haptic on tab zone crossing
        let hoverIndex = min(max(0, Int(round(progress))), Tab.allCases.count - 1)
        let newHoverTab = Tab.allCases[hoverIndex]
        if newHoverTab != currentHoverTab {
            currentHoverTab = newHoverTab
            HapticManager.selection()
        }
    }

    private func handleScrubEnd(finalX: CGFloat, tabBarWidth: CGFloat) {
        guard isScrubbing else { return }

        // Use actual final finger position, not stored scrubProgress
        let clampedX = max(0, min(tabBarWidth, finalX))
        let tabWidth = tabBarWidth / CGFloat(Tab.allCases.count)
        let progress = max(0, min(CGFloat(Tab.allCases.count - 1), (clampedX / tabWidth) - 0.5))
        let nearestIndex = Int(round(progress))
        let clampedIndex = max(0, min(Tab.allCases.count - 1, nearestIndex))
        let nearestTab = Tab.allCases[clampedIndex]

        HapticManager.tabChanged()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            selectedTab = nearestTab
            scrubProgress = nil
            isScrubbing = false
            scrubLocation = nil
            currentHoverTab = nil
        }
    }
}

// MARK: - Tab Extension

extension Tab {
    var icon: String {
        switch self {
        case .home: return "house"
        case .programs: return "calendar"
        case .exercises: return "dumbbell"
        case .history: return "clock"
        case .profile: return "person"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .programs: return "Programs"
        case .exercises: return "Exercises"
        case .history: return "History"
        case .profile: return "Profile"
        }
    }
}
