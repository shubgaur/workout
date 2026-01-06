import SwiftUI

struct ExerciseCell: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Exercise image/icon
            exerciseImage

            // Exercise info
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(exercise.name)
                    .font(RepsTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(RepsTheme.Colors.text)
                    .lineLimit(1)

                // Muscle groups
                Text(exercise.muscleGroups.map { $0.displayName }.joined(separator: ", "))
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .lineLimit(1)

                // Equipment badges
                if !exercise.equipment.isEmpty {
                    HStack(spacing: RepsTheme.Spacing.xxs) {
                        if let first = exercise.equipment.first {
                            Image(systemName: first.iconName)
                                .font(.system(size: 10))
                        }
                        Text(exercise.equipment.map { $0.displayName }.joined(separator: ", "))
                            .font(RepsTheme.Typography.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            Spacer()

            // Custom indicator
            if exercise.isCustom {
                Text("CUSTOM")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(RepsTheme.Colors.accent, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, RepsTheme.Spacing.xs)
    }

    private var exerciseImage: some View {
        Group {
            if let filename = exercise.localImageFilename, let uiImage = loadLocalImage(filename: filename) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RepsTheme.Colors.surfaceElevated)
            } else if let imageURL = exercise.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderImage
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(RepsTheme.Colors.surfaceElevated)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }

    private func loadLocalImage(filename: String) -> UIImage? {
        let url = VideoStorageService.imageURL(for: filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private var placeholderImage: some View {
        ZStack {
            RepsTheme.Colors.surfaceElevated

            Image(systemName: muscleGroupIcon)
                .font(.system(size: 24))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
    }

    private var muscleGroupIcon: String {
        guard let primaryMuscle = exercise.muscleGroups.first else {
            return "figure.strengthtraining.traditional"
        }

        switch primaryMuscle {
        case .chest:
            return "figure.arms.open"
        case .back, .lats, .traps:
            return "figure.strengthtraining.traditional"
        case .shoulders:
            return "figure.arms.open"
        case .biceps, .triceps, .forearms:
            return "figure.mixed.cardio"
        case .quads, .hamstrings, .glutes, .calves, .hipFlexors, .adductors, .abductors:
            return "figure.run"
        case .abdominals, .obliques, .lowerBack:
            return "figure.core.training"
        case .fullBody:
            return "figure.strengthtraining.functional"
        case .cardio:
            return "figure.run"
        case .neck:
            return "person.fill"
        }
    }
}

// MARK: - Equipment Icon Extension

extension Equipment {
    var iconName: String {
        switch self {
        case .barbell:
            return "figure.strengthtraining.traditional"
        case .dumbbell:
            return "dumbbell.fill"
        case .kettlebell:
            return "figure.strengthtraining.functional"
        case .cable:
            return "arrow.up.and.down"
        case .machine:
            return "gearshape.fill"
        case .bodyweight:
            return "figure.stand"
        case .bands:
            return "arrow.left.arrow.right"
        case .pullupBar:
            return "arrow.up"
        case .dipStation:
            return "arrow.down"
        case .box:
            return "cube.fill"
        case .bench:
            return "rectangle.fill"
        case .smith:
            return "figure.strengthtraining.traditional"
        case .ezBar, .trapBar:
            return "figure.strengthtraining.traditional"
        case .medicineBall:
            return "circle.fill"
        case .treadmill, .bike, .rower, .elliptical, .stairmaster:
            return "figure.run"
        case .none:
            return "questionmark.circle"
        }
    }
}

#Preview {
    List {
        ExerciseCell(exercise: Exercise(
            name: "Barbell Back Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: [.barbell],
            instructions: "Lower your body by bending your knees",
            isCustom: false
        ))

        ExerciseCell(exercise: Exercise(
            name: "Custom Push-up",
            muscleGroups: [.chest, .triceps],
            equipment: [.bodyweight],
            isCustom: true
        ))
    }
    .listStyle(.plain)
    .background(RepsTheme.Colors.background)
    .preferredColorScheme(.dark)
}
