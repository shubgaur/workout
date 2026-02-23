import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            "dumbbell.fill",
            "Welcome to Reps",
            "Your personal workout companion.\nTrack exercises, follow programs,\nand crush your fitness goals."
        ),
        (
            "list.bullet.clipboard.fill",
            "Follow Programs",
            "Load structured training programs\nwith phases, weeks, and daily workouts.\nStay on track with scheduled sessions."
        ),
        (
            "chart.line.uptrend.xyaxis",
            "Track Progress",
            "Log every set and rep.\nWatch your personal records grow\nand review your workout history."
        ),
        (
            "trophy.fill",
            "Set Records",
            "Automatic PR detection tracks\nyour best lifts, highest volume,\nand fastest times."
        ),
    ]

    var body: some View {
        ZStack {
            // Background
            RepsTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            hasSeenOnboarding = true
                        }
                        .font(RepsTheme.Typography.subheadline)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .padding(.trailing, RepsTheme.Spacing.md)
                    }
                }
                .frame(height: 44)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: RepsTheme.Spacing.xl) {
                            ZStack {
                                Circle()
                                    .fill(RepsTheme.Colors.accent.opacity(0.1))
                                    .frame(width: 140, height: 140)

                                Image(systemName: page.icon)
                                    .font(.system(size: 56))
                                    .foregroundStyle(RepsTheme.Colors.accent)
                            }

                            Text(page.title)
                                .font(RepsTheme.Typography.largeTitle)
                                .foregroundStyle(RepsTheme.Colors.text)

                            Text(page.description)
                                .font(RepsTheme.Typography.body)
                                .foregroundStyle(RepsTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Page indicator
                HStack(spacing: RepsTheme.Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? RepsTheme.Colors.accent : RepsTheme.Colors.textTertiary)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, RepsTheme.Spacing.lg)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(RepsTheme.Typography.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RepsButtonStyle(style: .primary))
                .padding(.horizontal, RepsTheme.Spacing.xl)
                .padding(.bottom, RepsTheme.Spacing.xl)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OnboardingView()
}
