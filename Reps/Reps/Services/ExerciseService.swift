import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.reps.app", category: "ExerciseService")

// MARK: - Exercise DTO for JSON Parsing

struct ExerciseDTO: Codable {
    let id: String
    let name: String
    let muscleGroups: [String]
    let equipment: String?
    let instructions: String?
    let videoURL: String?
    let imageURL: String?
}

// MARK: - Exercise Service

@MainActor
final class ExerciseService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Seeding

    func seedExercisesIfNeeded() async throws {
        let descriptor = FetchDescriptor<Exercise>()
        let count = try modelContext.fetchCount(descriptor)

        guard count == 0 else {
            logger.debug("Exercises already seeded: \(count) exercises in database")
            return
        }

        logger.info("Seeding exercises from bundled JSON...")
        try await seedFromBundle()
    }

    private func seedFromBundle() async throws {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            logger.warning("exercises.json not found in bundle")
            return
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let dtos = try decoder.decode([ExerciseDTO].self, from: data)

        logger.debug("Parsing \(dtos.count) exercises...")

        for dto in dtos {
            let exercise = Exercise(
                id: UUID(uuidString: dto.id) ?? UUID(),
                name: dto.name,
                muscleGroups: dto.muscleGroups.compactMap { MuscleGroup(rawValue: $0) },
                equipment: dto.equipment.flatMap { Equipment(rawValue: $0) }.map { [$0] } ?? [],
                instructions: dto.instructions,
                videoURL: dto.videoURL,
                imageURL: dto.imageURL,
                isCustom: false
            )
            modelContext.insert(exercise)
        }

        try modelContext.save()
        logger.info("Successfully seeded \(dtos.count) exercises")
    }

    // MARK: - CRUD Operations

    func fetchAllExercises() throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchExercises(
        searchText: String = "",
        muscleGroup: MuscleGroup? = nil,
        equipment: Equipment? = nil
    ) throws -> [Exercise] {
        var predicates: [Predicate<Exercise>] = []

        if !searchText.isEmpty {
            predicates.append(#Predicate<Exercise> { exercise in
                exercise.name.localizedStandardContains(searchText)
            })
        }

        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )

        var exercises = try modelContext.fetch(descriptor)

        // Filter by muscle group (can't do array contains in predicate easily)
        if let muscleGroup = muscleGroup {
            exercises = exercises.filter { $0.muscleGroups.contains(muscleGroup) }
        }

        // Filter by equipment
        if let equipment = equipment {
            exercises = exercises.filter { $0.equipment.contains(equipment) }
        }

        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return exercises
    }

    func findExercise(byName name: String) throws -> Exercise? {
        let exercises = try fetchAllExercises()

        // Exact match first
        if let exact = exercises.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return exact
        }

        // Fuzzy match - contains
        if let fuzzy = exercises.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) {
            return fuzzy
        }

        return nil
    }

    func createExercise(
        name: String,
        muscleGroups: [MuscleGroup],
        equipment: [Equipment] = [],
        instructions: String?,
        videoURL: String?
    ) throws -> Exercise {
        let exercise = Exercise(
            name: name,
            muscleGroups: muscleGroups,
            equipment: equipment,
            instructions: instructions,
            videoURL: videoURL,
            isCustom: true
        )
        modelContext.insert(exercise)
        try modelContext.save()
        return exercise
    }

    func deleteExercise(_ exercise: Exercise) throws {
        modelContext.delete(exercise)
        try modelContext.save()
    }
}
