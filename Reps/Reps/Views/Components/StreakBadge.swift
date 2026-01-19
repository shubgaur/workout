import SwiftUI

/// Displays current workout streak with flame icon
struct StreakBadge: View {
    let streak: Int
    var isFrozen: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isFrozen ? "snowflake" : "flame.fill")
                .foregroundStyle(isFrozen ? .blue : streakColor)
            Text("\(streak)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .accessibilityLabel("\(streak) day streak\(isFrozen ? ", frozen" : "")")
    }

    private var streakColor: Color {
        switch streak {
        case 0..<7:
            return RepsTheme.Colors.accent
        case 7..<30:
            return .red
        default:
            return .purple
        }
    }

    private var backgroundColor: Color {
        if isFrozen {
            return Color.blue.opacity(0.15)
        }
        return streakColor.opacity(0.15)
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakBadge(streak: 3)
        StreakBadge(streak: 14)
        StreakBadge(streak: 45)
        StreakBadge(streak: 7, isFrozen: true)
    }
    .padding()
}
