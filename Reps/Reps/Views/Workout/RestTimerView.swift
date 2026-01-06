import SwiftUI

struct RestTimerView: View {
    let state: RestTimerState
    var onSkip: () -> Void

    @State private var remainingSeconds: Int
    @State private var timer: Timer?

    init(state: RestTimerState, onSkip: @escaping () -> Void) {
        self.state = state
        self.onSkip = onSkip
        self._remainingSeconds = State(initialValue: state.remainingSeconds)
    }

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.sm) {
            HStack {
                Text("REST")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                Button("Skip") {
                    stopTimer()
                    onSkip()
                }
                .font(RepsTheme.Typography.subheadline)
                .foregroundStyle(RepsTheme.Colors.accent)
            }

            // Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(RepsTheme.Colors.surfaceElevated, lineWidth: 8)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        RepsTheme.Colors.accent,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time display
                VStack(spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(RepsTheme.Colors.text)

                    Text("remaining")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
            }
            .frame(height: 160)
            .padding(.vertical, RepsTheme.Spacing.sm)

            // Quick adjust buttons
            HStack(spacing: RepsTheme.Spacing.md) {
                QuickTimeButton(label: "-\(Constants.RestTimer.shortAdjustment)s") {
                    remainingSeconds = max(0, remainingSeconds - Constants.RestTimer.shortAdjustment)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                QuickTimeButton(label: "+\(Constants.RestTimer.shortAdjustment)s") {
                    remainingSeconds += Constants.RestTimer.shortAdjustment
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                QuickTimeButton(label: "+\(Constants.RestTimer.mediumAdjustment)s") {
                    remainingSeconds += Constants.RestTimer.mediumAdjustment
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }

    private var progress: Double {
        guard state.totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(state.totalSeconds)
    }

    private var timeString: String {
        TimeFormatter.formatRestTimer(remainingSeconds)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1

                // Haptic warnings
                if remainingSeconds == Constants.RestTimer.HapticWarnings.medium ||
                   remainingSeconds == Constants.RestTimer.HapticWarnings.light {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } else if remainingSeconds <= Constants.RestTimer.HapticWarnings.countdown && remainingSeconds > 0 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } else if remainingSeconds == 0 {
                    // Timer complete
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    stopTimer()
                    onSkip()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Quick Time Button

struct QuickTimeButton: View {
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.text)
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.vertical, RepsTheme.Spacing.sm)
                .background(RepsTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
        }
        .buttonStyle(TimerButtonStyle())
    }
}

// MARK: - Timer Button Style

struct TimerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    RestTimerView(state: RestTimerState(totalSeconds: 90)) {}
        .padding()
        .background(RepsTheme.Colors.background)
        .preferredColorScheme(.dark)
}
