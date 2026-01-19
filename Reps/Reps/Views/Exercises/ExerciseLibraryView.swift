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
    @State private var showingCreateExercise = false
    @State private var headerState = CollapsingHeaderState()

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
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                Group {
                    if filteredExercises.isEmpty {
                        emptyStateView
                    } else {
                        exerciseListWithFilters
                    }
                }
                .transparentNavigation()
                .searchable(text: $searchText, prompt: "Search exercises")
                .safeAreaInset(edge: .top, spacing: 0) {
                    CollapsingIridescentHeader(
                        title: "Exercises",
                        isVisible: headerState.isVisibleBinding
                    ) {
                        Button {
                            showingFilters.toggle()
                        } label: {
                            Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(hasActiveFilters ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
                        }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .sheet(isPresented: $showingCreateExercise) {
                    CreateExerciseView()
                }
            }

            // Floating button - completely outside NavigationStack
            LiquidMetalPillButton(icon: "plus", title: "New Exercise") {
                showingCreateExercise = true
            }
            .padding(.trailing, RepsTheme.Spacing.md)
            .padding(.bottom, 20)
        }
    }

    private var exerciseListWithFilters: some View {
        ScrollView {
            VStack(spacing: 0) {
                filterChipsSection
                exerciseListContent
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .onScrollGeometryChange(for: CGFloat.self) { geo in
            geo.contentOffset.y + geo.contentInsets.top
        } action: { old, new in
            headerState.handleScroll(oldOffset: old, newOffset: new)
        }
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

    private var exerciseListContent: some View {
        LazyVStack(spacing: RepsTheme.Spacing.sm) {
            ForEach(filteredExercises) { exercise in
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    ExerciseCell(exercise: exercise)
                        .padding(RepsTheme.Spacing.md)
                        .repsCard()
                }
                .buttonStyle(ScalingPressButtonStyle())
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
        .padding(.horizontal, RepsTheme.Spacing.md)
        .padding(.bottom, RepsTheme.Spacing.tabBarSafeArea)
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
                // Capture horizontal drags to prevent tab swipe interference
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { _ in }
                )

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
                // Capture horizontal drags to prevent tab swipe interference
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { _ in }
                )
            }
            .padding(.vertical, RepsTheme.Spacing.sm)
            .background(Color.clear)
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
        .background(Color.clear)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.filterSelected()
            withAnimation(RepsTheme.Animations.segment) {
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .black : RepsTheme.Colors.text)
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.vertical, RepsTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : RepsTheme.Colors.surface)
                )
        }
        .buttonStyle(ScalingPressButtonStyle())
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
        .preferredColorScheme(.dark)
}
