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
    let bundledVideoFilename: String?
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

        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            logger.warning("exercises.json not found in bundle")
            return
        }

        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([ExerciseDTO].self, from: data)

        if count == 0 {
            logger.info("Seeding exercises from bundled JSON...")
            try await seedFromBundle(dtos: dtos)
        } else if count < dtos.count {
            logger.info("Seeding \(dtos.count - count) missing exercises...")
            try await seedMissingExercises(from: dtos)
            try await syncBundledVideoFilenames(from: dtos)
        } else {
            // Always sync bundled video filenames in case JSON was updated
            try await syncBundledVideoFilenames(from: dtos)
        }
    }

    private func seedFromBundle(dtos: [ExerciseDTO]? = nil) async throws {
        let exerciseDTOs: [ExerciseDTO]
        if let dtos = dtos {
            exerciseDTOs = dtos
        } else {
            guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
                logger.warning("exercises.json not found in bundle")
                return
            }
            let data = try Data(contentsOf: url)
            exerciseDTOs = try JSONDecoder().decode([ExerciseDTO].self, from: data)
        }

        logger.debug("Parsing \(exerciseDTOs.count) exercises...")

        for dto in exerciseDTOs {
            let exercise = Exercise(
                id: UUID(uuidString: dto.id) ?? UUID(),
                name: dto.name,
                muscleGroups: dto.muscleGroups.compactMap { MuscleGroup(rawValue: $0) },
                equipment: dto.equipment.flatMap { Equipment(rawValue: $0) }.map { [$0] } ?? [],
                instructions: dto.instructions,
                videoURL: dto.videoURL,
                bundledVideoFilename: dto.bundledVideoFilename,
                imageURL: dto.imageURL,
                isCustom: false
            )
            modelContext.insert(exercise)
        }

        try modelContext.save()
        logger.info("Successfully seeded \(exerciseDTOs.count) exercises")
    }

    private func seedMissingExercises(from dtos: [ExerciseDTO]) async throws {
        let existing = try fetchAllExercises()
        let existingNames = Set(existing.map { $0.name.lowercased() })

        var added = 0
        for dto in dtos {
            if !existingNames.contains(dto.name.lowercased()) {
                let exercise = Exercise(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    name: dto.name,
                    muscleGroups: dto.muscleGroups.compactMap { MuscleGroup(rawValue: $0) },
                    equipment: dto.equipment.flatMap { Equipment(rawValue: $0) }.map { [$0] } ?? [],
                    instructions: dto.instructions,
                    videoURL: dto.videoURL,
                    bundledVideoFilename: dto.bundledVideoFilename,
                    imageURL: dto.imageURL,
                    isCustom: false
                )
                modelContext.insert(exercise)
                added += 1
            }
        }

        try modelContext.save()
        logger.info("Seeded \(added) missing exercises")
    }

    /// Update existing exercises with bundled video filenames from JSON
    private func syncBundledVideoFilenames(from dtos: [ExerciseDTO]) async throws {
        let existing = try fetchAllExercises()
        let nameMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.name.lowercased(), $0) })

        var updated = 0
        for dto in dtos {
            guard let bundledFilename = dto.bundledVideoFilename else { continue }
            if let exercise = nameMap[dto.name.lowercased()],
               exercise.bundledVideoFilename != bundledFilename {
                exercise.bundledVideoFilename = bundledFilename
                updated += 1
            }
        }

        if updated > 0 {
            try modelContext.save()
            logger.info("Updated bundled video filenames for \(updated) exercises")
        }
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
