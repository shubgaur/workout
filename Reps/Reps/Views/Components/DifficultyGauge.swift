import SwiftUI

/// Circular gauge displaying perceived difficulty (1-10 scale)
struct DifficultyGauge: View {
    let value: Int
    let size: CGFloat

    private var progress: Double {
        Double(value) / 10.0
    }

    private var color: Color {
        switch value {
        case 1...3: return RepsTheme.Colors.success
        case 4...6: return RepsTheme.Colors.warning
        case 7...10: return RepsTheme.Colors.accent
        default: return RepsTheme.Colors.textTertiary
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    RepsTheme.Colors.surfaceElevated,
                    lineWidth: size * 0.15
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: size * 0.15,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Value text
            Text("\(value)")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundColor(RepsTheme.Colors.text)
        }
        .frame(width: size, height: size)
    }
}

/// Compact version for list rows
struct DifficultyGaugeCompact: View {
    let value: Int

    var body: some View {
        DifficultyGauge(value: value, size: 28)
    }
}

/// Large version for detail views
struct DifficultyGaugeLarge: View {
    let value: Int

    var body: some View {
        DifficultyGauge(value: value, size: 60)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            ForEach([2, 5, 7, 10], id: \.self) { val in
                DifficultyGauge(value: val, size: 40)
            }
        }

        DifficultyGaugeLarge(value: 8)

        HStack {
            Text("Compact:")
            DifficultyGaugeCompact(value: 6)
        }
    }
    .padding()
}
