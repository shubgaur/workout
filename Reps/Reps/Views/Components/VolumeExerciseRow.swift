import SwiftUI

/// Displays a single exercise's volume contribution with percentage bar
struct VolumeExerciseRow: View {
    let exerciseName: String
    let muscleGroup: String
    let totalVolume: Double
    let percentage: Double
    let workoutCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exerciseName)
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)
                        .lineLimit(1)

                    Text(muscleGroup)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatVolume(totalVolume))
                        .font(RepsTheme.Typography.mono)
                        .foregroundStyle(RepsTheme.Colors.accent)

                    Text("\(workoutCount) workout\(workoutCount == 1 ? "" : "s")")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
            }

            // Percentage bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RepsTheme.Colors.surfaceElevated)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RepsTheme.Colors.accent)
                        .frame(width: geo.size.width * (percentage / 100))
                }
            }
            .frame(height: 8)

            // Percentage label
            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM kg", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.1fK kg", volume / 1000)
        }
        return "\(Int(volume)) kg"
    }
}

#Preview {
    VStack(spacing: 12) {
        VolumeExerciseRow(
            exerciseName: "Barbell Bench Press",
            muscleGroup: "Chest",
            totalVolume: 45000,
            percentage: 25.5,
            workoutCount: 12
        )

        VolumeExerciseRow(
            exerciseName: "Barbell Back Squat",
            muscleGroup: "Quads",
            totalVolume: 62000,
            percentage: 35.2,
            workoutCount: 10
        )
    }
    .padding()
    .background(RepsTheme.Colors.background)
    .preferredColorScheme(.dark)
}
