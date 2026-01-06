import SwiftUI
import SwiftData

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?

    var onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    TextField("Search exercises", text: $searchText)
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.text)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(RepsTheme.Colors.textTertiary)
                        }
                    }
                }
                .padding(RepsTheme.Spacing.sm)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.top, RepsTheme.Spacing.sm)

                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RepsTheme.Spacing.sm) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedMuscleGroup == nil
                        ) {
                            selectedMuscleGroup = nil
                        }

                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            FilterChip(
                                title: muscle.displayName,
                                isSelected: selectedMuscleGroup == muscle
                            ) {
                                selectedMuscleGroup = muscle
                            }
                        }
                    }
                    .padding(.horizontal, RepsTheme.Spacing.md)
                }
                .padding(.vertical, RepsTheme.Spacing.sm)

                // Exercise list
                List {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            ExercisePickerRow(exercise: exercise)
                        }
                        .listRowBackground(RepsTheme.Colors.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        var results = exercises

        if !searchText.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let muscle = selectedMuscleGroup {
            results = results.filter {
                $0.muscleGroups.contains(muscle)
            }
        }

        return results
    }
}

// MARK: - Exercise Picker Row

struct ExercisePickerRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Exercise icon/image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(RepsTheme.Colors.surfaceElevated)
                    .frame(width: 48, height: 48)

                Image(systemName: equipmentIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(RepsTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(exercise.name)
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.text)
                    .lineLimit(1)

                Text(exercise.muscleGroups.map { $0.displayName }.joined(separator: ", "))
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "plus.circle")
                .font(.system(size: 22))
                .foregroundStyle(RepsTheme.Colors.accent)
        }
        .padding(.vertical, RepsTheme.Spacing.xs)
    }

    private var equipmentIcon: String {
        exercise.equipment.first?.iconName ?? "questionmark.circle"
    }
}
