import SwiftUI

// MARK: - Toast View (AnyDistance-inspired floating notifications)

struct ToastView: View {
    var message: String
    var icon: String
    var style: ToastStyle = .info

    enum ToastStyle {
        case info, success, warning, error, pr

        var iconColor: Color {
            switch self {
            case .info: return RepsTheme.Colors.text
            case .success: return RepsTheme.Colors.chartGreen
            case .warning: return RepsTheme.Colors.warning
            case .error: return RepsTheme.Colors.error
            case .pr: return RepsTheme.Colors.accent
            }
        }
    }

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(style.iconColor)

            Text(message)
                .font(RepsTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(RepsTheme.Colors.text)
        }
        .padding(.horizontal, RepsTheme.Spacing.lg)
        .padding(.vertical, RepsTheme.Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - PR Achievement Toast

struct PRAchievementToast: View {
    var exerciseName: String
    var newRecord: String
    var unit: String

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.sm) {
            // Trophy icon with glow
            ZStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RepsTheme.Colors.accent)
                    .shadow(color: RepsTheme.Colors.accent.opacity(0.5), radius: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("NEW PR!")
                    .font(RepsTheme.Typography.label)
                    .foregroundColor(RepsTheme.Colors.accent)

                HStack(spacing: 4) {
                    Text(exerciseName)
                        .font(RepsTheme.Typography.subheadline)
                        .fontWeight(.semibold)

                    Text("•")
                        .foregroundColor(RepsTheme.Colors.textSecondary)

                    Text("\(newRecord) \(unit)")
                        .font(RepsTheme.Typography.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundColor(RepsTheme.Colors.text)
            }
        }
        .padding(.horizontal, RepsTheme.Spacing.lg)
        .padding(.vertical, RepsTheme.Spacing.md)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [RepsTheme.Colors.accent.opacity(0.5), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Toast Presenter

struct ToastPresenter<Content: View>: View {
    @Binding var isPresented: Bool
    var message: String
    var icon: String
    var style: ToastView.ToastStyle = .info
    var duration: Double = 2.5
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()

            VStack {
                if isPresented {
                    ToastView(message: message, icon: icon, style: style)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(RepsTheme.Animations.toast) {
                                    isPresented = false
                                }
                            }
                        }

                    Spacer()
                }
            }
            .padding(.top, RepsTheme.Spacing.xl)
            .animation(RepsTheme.Animations.overlay, value: isPresented)
        }
    }
}

// MARK: - View Extension

extension View {
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        icon: String,
        style: ToastView.ToastStyle = .info,
        duration: Double = 2.5
    ) -> some View {
        ToastPresenter(
            isPresented: isPresented,
            message: message,
            icon: icon,
            style: style,
            duration: duration
        ) {
            self
        }
    }
}

// MARK: - Toast Manager (Observable)

@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var isPresented = false
    @Published var message = ""
    @Published var icon = ""
    @Published var style: ToastView.ToastStyle = .info

    private init() {}

    func show(_ message: String, icon: String, style: ToastView.ToastStyle = .info) {
        self.message = message
        self.icon = icon
        self.style = style

        withAnimation(RepsTheme.Animations.overlay) {
            isPresented = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            withAnimation(RepsTheme.Animations.toast) {
                self?.isPresented = false
            }
        }
    }

    func success(_ message: String) {
        show(message, icon: "checkmark.circle.fill", style: .success)
        HapticManager.success()
    }

    func error(_ message: String) {
        show(message, icon: "xmark.circle.fill", style: .error)
        HapticManager.error()
    }

    func pr(_ exerciseName: String, record: String) {
        show("New PR: \(exerciseName) - \(record)", icon: "trophy.fill", style: .pr)
        HapticManager.prAchieved()
    }
}

#Preview {
    VStack(spacing: 24) {
        ToastView(message: "Set completed", icon: "checkmark.circle.fill", style: .success)

        ToastView(message: "Rest timer active", icon: "timer", style: .info)

        ToastView(message: "Connection lost", icon: "wifi.slash", style: .error)

        PRAchievementToast(exerciseName: "Bench Press", newRecord: "225", unit: "lbs")
    }
    .padding()
    .background(RepsTheme.Colors.background)
}
