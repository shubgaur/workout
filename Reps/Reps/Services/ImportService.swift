import Foundation
import SwiftData

// MARK: - Exercise Import DTOs

struct ExerciseImportWrapper: Codable {
    let exercises: [ImportableExercise]
}

struct ImportableExercise: Codable {
    let name: String
    let muscleGroups: [String]?
    let equipment: [String]?
    let instructions: String?
    let videoURL: String?
    let imageURL: String?
}

// MARK: - Program Import DTOs

struct ProgramDTO: Codable {
    let name: String
    let description: String?
    let programDetails: String?
    let phases: [PhaseDTO]
}

struct PhaseDTO: Codable {
    let name: String
    let description: String?
    let weeks: [WeekDTO]
}

struct WeekDTO: Codable {
    let weekNumber: Int
    let notes: String?
    let days: [DayDTO]
}

struct DayDTO: Codable {
    let dayNumber: Int
    let name: String?
    let dayType: String?
    let workout: WorkoutDTO?
}

struct WorkoutDTO: Codable {
    let name: String?
    let exerciseGroups: [ExerciseGroupDTO]
}

struct ExerciseGroupDTO: Codable {
    let type: String?
    let name: String?
    let exercises: [WorkoutExerciseDTO]
}

struct WorkoutExerciseDTO: Codable {
    let exerciseRef: String
    let notes: String?
    let restSeconds: Int?
    let isOptional: Bool?
    let sets: [SetDTO]
}

struct SetDTO: Codable {
    let setNumber: Int
    let setType: String?
    let targetReps: Int?
    let targetWeight: Double?
    let targetTime: Int?
    let targetRPE: Int?
    let side: String?
    let notes: String?
}

// MARK: - Import Service

@MainActor
final class ImportService {
    private let modelContext: ModelContext
    private let exerciseService: ExerciseService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.exerciseService = ExerciseService(modelContext: modelContext)
    }

    // MARK: - Exercise Import

    func importExercises(from data: Data) async throws -> Int {
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ExerciseImportWrapper.self, from: data)

        var importedCount = 0

        for importable in wrapper.exercises {
            // Parse muscle groups
            let muscleGroups = (importable.muscleGroups ?? []).compactMap { MuscleGroup(rawValue: $0) }

            // Parse equipment
            let equipment = (importable.equipment ?? []).compactMap { Equipment(rawValue: $0) }

            // Check if exercise already exists
            let name = importable.name
            let existingDescriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { exercise in
                    exercise.name == name
                }
            )

            if let existing = try? modelContext.fetch(existingDescriptor).first {
                // Update existing exercise
                existing.muscleGroups = muscleGroups.isEmpty ? existing.muscleGroups : muscleGroups
                existing.equipment = equipment.isEmpty ? existing.equipment : equipment
                if let instructions = importable.instructions {
                    existing.instructions = instructions
                }
                if let videoURL = importable.videoURL {
                    existing.videoURL = videoURL
                }
                if let imageURL = importable.imageURL {
                    existing.imageURL = imageURL
                }
            } else {
                // Create new exercise
                let exercise = Exercise(
                    name: importable.name,
                    muscleGroups: muscleGroups,
                    equipment: equipment,
                    instructions: importable.instructions,
                    videoURL: importable.videoURL,
                    imageURL: importable.imageURL,
                    isCustom: true
                )
                modelContext.insert(exercise)
            }

            importedCount += 1
        }

        try modelContext.save()
        return importedCount
    }

    // MARK: - Program Import

    func importProgram(from url: URL) async throws -> Program {
        let data = try Data(contentsOf: url)
        return try await importProgram(from: data)
    }

    func importProgram(from data: Data) async throws -> Program {
        let decoder = JSONDecoder()
        let dto = try decoder.decode(ProgramDTO.self, from: data)

        return try await createProgram(from: dto)
    }

    func createProgram(from dto: ProgramDTO) async throws -> Program {
        let program = Program(
            name: dto.name,
            programDescription: dto.description,
            programDetails: dto.programDetails
        )
        modelContext.insert(program)

        for (phaseIndex, phaseDTO) in dto.phases.enumerated() {
            let phase = try await createPhase(from: phaseDTO, order: phaseIndex)
            phase.program = program
            program.phases.append(phase)
        }

        try modelContext.save()
        return program
    }

    func createPhase(from dto: PhaseDTO, order: Int) async throws -> Phase {
        let phase = Phase(
            name: dto.name,
            order: order,
            phaseDescription: dto.description
        )

        for weekDTO in dto.weeks {
            let week = try await createWeek(from: weekDTO)
            week.phase = phase
            phase.weeks.append(week)
        }

        return phase
    }

    func createWeek(from dto: WeekDTO) async throws -> Week {
        let week = Week(
            weekNumber: dto.weekNumber,
            notes: dto.notes
        )

        for dayDTO in dto.days {
            let day = try await createDay(from: dayDTO)
            day.week = week
            week.days.append(day)
        }

        return week
    }

    func createDay(from dto: DayDTO) async throws -> ProgramDay {
        let dayType = dto.dayType.flatMap { DayType(rawValue: $0) } ?? .training

        let day = ProgramDay(
            dayNumber: dto.dayNumber,
            name: dto.name ?? "Day \(dto.dayNumber)",
            dayType: dayType
        )

        if let workoutDTO = dto.workout {
            let template = try await createWorkoutTemplate(from: workoutDTO, dayName: dto.name)
            template.programDay = day
            day.workoutTemplate = template
        }

        return day
    }

    func createWorkoutTemplate(from dto: WorkoutDTO, dayName: String?) async throws -> WorkoutTemplate {
        let template = WorkoutTemplate(
            name: dto.name ?? dayName ?? "Workout"
        )

        for (groupIndex, groupDTO) in dto.exerciseGroups.enumerated() {
            let group = try await createExerciseGroup(from: groupDTO, order: groupIndex)
            group.workoutTemplate = template
            template.exerciseGroups.append(group)
        }

        return template
    }

    func createExerciseGroup(from dto: ExerciseGroupDTO, order: Int) async throws -> ExerciseGroup {
        let groupType = dto.type.flatMap { ExerciseGroupType(rawValue: $0) } ?? .single

        let group = ExerciseGroup(
            groupType: groupType,
            order: order,
            name: dto.name
        )

        for (exerciseIndex, exerciseDTO) in dto.exercises.enumerated() {
            let workoutExercise = try await createWorkoutExercise(from: exerciseDTO, order: exerciseIndex)
            workoutExercise.exerciseGroup = group
            group.exercises.append(workoutExercise)
        }

        return group
    }

    func createWorkoutExercise(from dto: WorkoutExerciseDTO, order: Int) async throws -> WorkoutExercise {
        // Find exercise by name (fuzzy match)
        guard let exercise = try exerciseService.findExercise(byName: dto.exerciseRef) else {
            // Create a custom exercise if not found
            let customExercise = try exerciseService.createExercise(
                name: dto.exerciseRef,
                muscleGroups: [],
                equipment: [],
                instructions: nil,
                videoURL: nil
            )

            let workoutExercise = WorkoutExercise(
                order: order,
                isOptional: dto.isOptional ?? false,
                notes: dto.notes,
                restSeconds: dto.restSeconds ?? 90
            )
            workoutExercise.exercise = customExercise

            for setDTO in dto.sets {
                let setTemplate = createSetTemplate(from: setDTO)
                setTemplate.workoutExercise = workoutExercise
                workoutExercise.setTemplates.append(setTemplate)
            }

            return workoutExercise
        }

        let workoutExercise = WorkoutExercise(
            order: order,
            isOptional: dto.isOptional ?? false,
            notes: dto.notes,
            restSeconds: dto.restSeconds ?? 90
        )
        workoutExercise.exercise = exercise

        for setDTO in dto.sets {
            let setTemplate = createSetTemplate(from: setDTO)
            setTemplate.workoutExercise = workoutExercise
            workoutExercise.setTemplates.append(setTemplate)
        }

        return workoutExercise
    }

    func createSetTemplate(from dto: SetDTO) -> SetTemplate {
        let setType = dto.setType.flatMap { SetType(rawValue: $0) } ?? .working
        let side = dto.side.flatMap { SetSide(rawValue: $0) }

        return SetTemplate(
            setNumber: dto.setNumber,
            setType: setType,
            targetReps: dto.targetReps,
            targetWeight: dto.targetWeight,
            targetTime: dto.targetTime,
            targetRPE: dto.targetRPE,
            side: side,
            notes: dto.notes
        )
    }
}
