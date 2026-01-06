import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedEquipment: Equipment?
    @State private var showingFilters = true
    @State private var exerciseToEdit: Exercise?
    @State private var showingDeleteConfirmation = false
    @State private var exerciseToDelete: Exercise?

    var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)

            let matchesMuscle = selectedMuscleGroup == nil ||
                exercise.muscleGroups.contains(selectedMuscleGroup!)

            let matchesEquipment = selectedEquipment == nil ||
                exercise.equipment.contains(selectedEquipment!)

            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterChipsSection

                // Exercise list
                if filteredExercises.isEmpty {
                    emptyStateView
                } else {
                    exerciseList
                }
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        selectedMuscleGroup != nil || selectedEquipment != nil
    }

    @ViewBuilder
    private var filterChipsSection: some View {
        if showingFilters {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                // Muscle group filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RepsTheme.Spacing.xs) {
                        FilterChip(
                            title: "All Muscles",
                            isSelected: selectedMuscleGroup == nil,
                            action: { selectedMuscleGroup = nil }
                        )

                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            FilterChip(
                                title: muscle.displayName,
                                isSelected: selectedMuscleGroup == muscle,
                                action: {
                                    selectedMuscleGroup = selectedMuscleGroup == muscle ? nil : muscle
                                }
                            )
                        }
                    }
                    .padding(.horizontal, RepsTheme.Spacing.md)
                }

                // Equipment filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RepsTheme.Spacing.xs) {
                        FilterChip(
                            title: "All Equipment",
                            isSelected: selectedEquipment == nil,
                            action: { selectedEquipment = nil }
                        )

                        ForEach(Equipment.allCases, id: \.self) { equipment in
                            FilterChip(
                                title: equipment.displayName,
                                isSelected: selectedEquipment == equipment,
                                action: {
                                    selectedEquipment = selectedEquipment == equipment ? nil : equipment
                                }
                            )
                        }
                    }
                    .padding(.horizontal, RepsTheme.Spacing.md)
                }
            }
            .padding(.vertical, RepsTheme.Spacing.sm)
            .background(RepsTheme.Colors.surfaceElevated)
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(filteredExercises) { exercise in
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    ExerciseCell(exercise: exercise)
                }
                .listRowBackground(RepsTheme.Colors.surface)
                .listRowSeparatorTint(RepsTheme.Colors.border)
                .contextMenu {
                    Button {
                        exerciseToEdit = exercise
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        duplicateExercise(exercise)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    if exercise.isCustom {
                        Button(role: .destructive) {
                            exerciseToDelete = exercise
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sheet(item: $exerciseToEdit) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .alert("Delete Exercise?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete {
                    deleteExercise(exercise)
                }
            }
        } message: {
            Text("This will permanently delete \"\(exerciseToDelete?.name ?? "")\".")
        }
    }

    private func duplicateExercise(_ exercise: Exercise) {
        let copy = Exercise(
            name: "Copy of \(exercise.name)",
            muscleGroups: exercise.muscleGroups,
            equipment: exercise.equipment,
            instructions: exercise.instructions,
            videoURL: exercise.videoURL,
            localVideoFilename: nil,  // Don't copy video file
            imageURL: exercise.imageURL,
            isCustom: true
        )
        modelContext.insert(copy)
    }

    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        exerciseToDelete = nil
    }

    private var emptyStateView: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No exercises found")
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            if hasActiveFilters || !searchText.isEmpty {
                Button("Clear Filters") {
                    searchText = ""
                    selectedMuscleGroup = nil
                    selectedEquipment = nil
                }
                .font(RepsTheme.Typography.footnote)
                .foregroundStyle(RepsTheme.Colors.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RepsTheme.Colors.background)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RepsTheme.Typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? RepsTheme.Colors.background : RepsTheme.Colors.text)
                .padding(.horizontal, RepsTheme.Spacing.sm)
                .padding(.vertical, RepsTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : RepsTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
        .preferredColorScheme(.dark)
}
