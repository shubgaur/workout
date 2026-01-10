import SwiftUI
import SwiftData

/// Shows total volume per exercise breakdown
struct VolumeBreakdownView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endTime != nil })
    private var completedWorkouts: [WorkoutSession]

    private var exerciseVolumes: [ExerciseVolumeData] {
        calculateExerciseVolumes()
    }

    private var totalVolume: Double {
        exerciseVolumes.reduce(0) { $0 + $1.totalVolume }
    }

    var body: some View {
        Group {
            if exerciseVolumes.isEmpty {
                emptyState
            } else {
                volumeList
            }
        }
        .navigationTitle("Volume Breakdown")
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigation()
    }

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "scalemass.fill")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.accent.opacity(0.5))

            Text("No Volume Data")
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)

            Text("Complete workouts to see your volume breakdown")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(RepsTheme.Spacing.xl)
    }

    private var volumeList: some View {
        ScrollView {
            VStack(spacing: RepsTheme.Spacing.md) {
                // Summary header
                VStack(spacing: RepsTheme.Spacing.xs) {
                    Text("TOTAL VOLUME")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    Text(formatVolume(totalVolume))
                        .font(RepsTheme.Typography.monoLarge)
                        .foregroundStyle(RepsTheme.Colors.accent)

                    Text("\(exerciseVolumes.count) exercises • \(completedWorkouts.count) workouts")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
                .padding(RepsTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))

                // Exercise breakdown
                ForEach(exerciseVolumes) { item in
                    VolumeExerciseRow(
                        exerciseName: item.exerciseName,
                        muscleGroup: item.muscleGroup,
                        totalVolume: item.totalVolume,
                        percentage: item.percentage,
                        workoutCount: item.workoutCount
                    )
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
    }

    // MARK: - Volume Calculation

    private func calculateExerciseVolumes() -> [ExerciseVolumeData] {
        var volumeMap: [UUID: ExerciseVolumeData] = [:]

        for workout in completedWorkouts {
            for group in workout.exerciseGroups {
                for workoutExercise in group.exercises {
                    guard let exercise = workoutExercise.exercise else { continue }

                    let exerciseVolume = workoutExercise.loggedSets
                        .filter { $0.isCompleted }
                        .reduce(0.0) { total, set in
                            let weight = set.weight ?? 0
                            let reps = Double(set.reps ?? 0)
                            return total + (weight * reps)
                        }

                    if exerciseVolume > 0 {
                        if var existing = volumeMap[exercise.id] {
                            existing.totalVolume += exerciseVolume
                            existing.workoutCount += 1
                            volumeMap[exercise.id] = existing
                        } else {
                            volumeMap[exercise.id] = ExerciseVolumeData(
                                exerciseId: exercise.id,
                                exerciseName: exercise.name,
                                muscleGroup: exercise.displayMuscle,
                                totalVolume: exerciseVolume,
                                percentage: 0,
                                workoutCount: 1
                            )
                        }
                    }
                }
            }
        }

        let total = volumeMap.values.reduce(0) { $0 + $1.totalVolume }

        return volumeMap.values
            .map { item in
                var updated = item
                updated.percentage = total > 0 ? (item.totalVolume / total) * 100 : 0
                return updated
            }
            .sorted { $0.totalVolume > $1.totalVolume }
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

// MARK: - Data Model

struct ExerciseVolumeData: Identifiable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let muscleGroup: String
    var totalVolume: Double
    var percentage: Double
    var workoutCount: Int
}

#Preview {
    NavigationStack {
        VolumeBreakdownView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
    .preferredColorScheme(.dark)
}
