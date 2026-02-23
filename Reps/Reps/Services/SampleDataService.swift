import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.reps.app", category: "SampleDataService")

/// Service for generating sample/fake data for visualization and testing
@MainActor
final class SampleDataService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Seeds sample workout history and records for visualization
    func seedSampleData() async throws {
        logger.info("Seeding sample data for visualization...")

        // Check if we already have workout history
        let sessionDescriptor = FetchDescriptor<WorkoutSession>()
        let existingCount = try modelContext.fetchCount(sessionDescriptor)

        guard existingCount == 0 else {
            logger.debug("Sample data already exists: \(existingCount) sessions")
            return
        }

        // Fetch exercises for use in workouts
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseDescriptor)

        guard !exercises.isEmpty else {
            logger.warning("No exercises found - cannot seed sample workouts")
            return
        }

        // Create sample workout sessions over the past 60 days
        try await createSampleWorkoutHistory(using: exercises)

        // Create personal records
        try await createSamplePersonalRecords(using: exercises)

        try modelContext.save()
        logger.info("Successfully seeded sample data")
    }

    private func createSampleWorkoutHistory(using exercises: [Exercise]) async throws {
        let calendar = Calendar.current
        let today = Date()

        // Common exercises for workouts
        let chestExercises = exercises.filter { $0.muscleGroups.contains(.chest) }.prefix(4)
        let backExercises = exercises.filter { $0.muscleGroups.contains(.back) || $0.muscleGroups.contains(.lats) }.prefix(4)
        let legExercises = exercises.filter { $0.muscleGroups.contains(.quads) || $0.muscleGroups.contains(.hamstrings) }.prefix(4)
        let shoulderExercises = exercises.filter { $0.muscleGroups.contains(.shoulders) }.prefix(3)
        let armExercises = exercises.filter { $0.muscleGroups.contains(.biceps) || $0.muscleGroups.contains(.triceps) }.prefix(4)

        // Create workouts over the past 60 days (roughly 4-5 per week)
        var workoutDates: [Date] = []

        for weeksAgo in 0..<9 {
            // 4-5 workouts per week
            let workoutsThisWeek = Int.random(in: 4...5)
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today)!

            for dayOffset in [0, 1, 2, 4, 5, 6].shuffled().prefix(workoutsThisWeek) {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                    if date <= today {
                        workoutDates.append(date)
                    }
                }
            }
        }

        // Create workout sessions
        for (index, date) in workoutDates.sorted().enumerated() {
            let workoutType = index % 4

            let exercisesForWorkout: [Exercise]
            let workoutName: String

            switch workoutType {
            case 0:
                exercisesForWorkout = Array(chestExercises) + Array(shoulderExercises.prefix(1))
                workoutName = "Push Day"
            case 1:
                exercisesForWorkout = Array(backExercises)
                workoutName = "Pull Day"
            case 2:
                exercisesForWorkout = Array(legExercises)
                workoutName = "Leg Day"
            default:
                exercisesForWorkout = Array(armExercises)
                workoutName = "Arms"
            }

            try createWorkoutSession(
                name: workoutName,
                date: date,
                exercises: exercisesForWorkout,
                weekNumber: 9 - (workoutDates.sorted().firstIndex(of: date)! / 5)
            )
        }
    }

    private func createWorkoutSession(
        name: String,
        date: Date,
        exercises: [Exercise],
        weekNumber: Int
    ) throws {
        let calendar = Calendar.current

        // Random workout duration 45-90 minutes
        let durationMinutes = Int.random(in: 45...90)
        let startTime = calendar.date(bySettingHour: Int.random(in: 6...19), minute: 0, second: 0, of: date)!
        let endTime = calendar.date(byAdding: .minute, value: durationMinutes, to: startTime)!

        let session = WorkoutSession(template: nil, programDay: nil)
        session.name = name
        session.startTime = startTime
        session.endTime = endTime
        session.status = .completed
        session.rating = Int.random(in: 4...9)  // 1-10 perceived difficulty scale
        session.notes = generateWorkoutNote()

        modelContext.insert(session)

        // Create exercise group
        let group = ExerciseGroup(groupType: .single, order: 0)
        group.workoutSession = session
        modelContext.insert(group)

        // Add exercises with logged sets
        for (exerciseIndex, exercise) in exercises.enumerated() {
            let workoutExercise = WorkoutExercise(
                order: exerciseIndex,
                restSeconds: 90
            )
            workoutExercise.exercise = exercise
            workoutExercise.exerciseGroup = group
            modelContext.insert(workoutExercise)

            // Progressive overload - weights increase slightly over weeks
            let baseWeight = getBaseWeight(for: exercise)
            let progressMultiplier = 1.0 + (Double(weekNumber) * 0.02) // 2% increase per week

            // 3-4 sets per exercise
            let setCount = Int.random(in: 3...4)
            for setNum in 1...setCount {
                let loggedSet = LoggedSet(
                    setNumber: setNum,
                    setType: setNum == 1 ? .warmup : .working
                )

                // Slightly vary weight and reps
                let weight = Int(Double(baseWeight) * progressMultiplier) + Int.random(in: -5...5)
                let reps = setNum == 1 ? Int.random(in: 10...12) : Int.random(in: 6...10)

                loggedSet.weight = Double(max(0, weight))
                loggedSet.reps = reps
                loggedSet.isCompleted = true
                loggedSet.workoutExercise = workoutExercise
                modelContext.insert(loggedSet)
            }
        }
    }

    private func createSamplePersonalRecords(using exercises: [Exercise]) async throws {
        // Create PRs for common compound lifts
        let prExercises = exercises.filter { exercise in
            let name = exercise.name.lowercased()
            return name.contains("bench press") ||
                   name.contains("squat") ||
                   name.contains("deadlift") ||
                   name.contains("overhead press") ||
                   name.contains("barbell row")
        }.prefix(5)

        for exercise in prExercises {
            let baseWeight = getBaseWeight(for: exercise)
            let prWeight = Double(baseWeight + Int.random(in: 10...30))

            let pr = PersonalRecord(
                recordType: .maxWeight,
                value: prWeight,
                exercise: exercise
            )
            modelContext.insert(pr)
        }
    }

    private func getBaseWeight(for exercise: Exercise) -> Int {
        let name = exercise.name.lowercased()

        // Realistic base weights for common exercises (in lbs)
        if name.contains("squat") || name.contains("deadlift") {
            return Int.random(in: 185...275)
        } else if name.contains("bench press") {
            return Int.random(in: 135...205)
        } else if name.contains("overhead press") || name.contains("shoulder press") {
            return Int.random(in: 85...135)
        } else if name.contains("row") {
            return Int.random(in: 115...175)
        } else if name.contains("curl") {
            return Int.random(in: 25...45)
        } else if name.contains("tricep") || name.contains("extension") {
            return Int.random(in: 30...60)
        } else if name.contains("lateral raise") || name.contains("fly") {
            return Int.random(in: 15...30)
        } else if name.contains("leg press") {
            return Int.random(in: 270...450)
        } else if name.contains("pulldown") || name.contains("pull-down") {
            return Int.random(in: 100...160)
        } else {
            return Int.random(in: 40...100)
        }
    }

    private func generateWorkoutNote() -> String? {
        let notes = [
            nil, nil, nil, // 60% chance of no note
            "Felt strong today!",
            "Good pump",
            "Increased weight on main lift",
            "Quick session, time crunched",
            "Great energy",
            "Focused on form",
            "PR attempt next week"
        ]
        return notes.randomElement() ?? nil
    }

    // MARK: - Sample Program

    /// Seeds a sample "Push Pull Legs" program for testing
    func seedSampleProgram() async throws {
        logger.info("Seeding sample program...")

        // Check if PPL program already exists by name so other programs can coexist
        let pplName = "Push Pull Legs"
        let programDescriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.name == pplName }
        )
        let existingCount = try modelContext.fetchCount(programDescriptor)

        guard existingCount == 0 else {
            logger.debug("Push Pull Legs program already exists")
            return
        }

        // Fetch exercises for use in templates
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseDescriptor)

        guard !exercises.isEmpty else {
            logger.warning("No exercises found - cannot seed sample program")
            return
        }

        // Create Push Pull Legs program
        let program = Program(
            name: "Push Pull Legs",
            programDescription: "A classic 6-day split focusing on pushing movements, pulling movements, and leg exercises. Each muscle group is trained twice per week for optimal growth.",
            isActive: true
        )
        modelContext.insert(program)

        // Phase 1: Foundation (2 weeks)
        let phase1 = Phase(name: "Foundation", order: 0, phaseDescription: "Build a base with moderate volume")
        phase1.program = program
        modelContext.insert(phase1)

        for weekNum in 1...2 {
            let week = Week(weekNumber: weekNum)
            week.phase = phase1
            modelContext.insert(week)

            // 6 training days + 1 rest
            let dayNames = ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B", "Rest"]
            for (dayIndex, dayName) in dayNames.enumerated() {
                let isRest = dayName == "Rest"
                let day = ProgramDay(
                    dayNumber: dayIndex + 1,
                    name: dayName,
                    dayType: isRest ? .rest : .training
                )
                day.week = week
                modelContext.insert(day)

                if !isRest {
                    createWorkoutTemplate(
                        for: day,
                        name: dayName,
                        type: dayName.hasPrefix("Push") ? "push" : (dayName.hasPrefix("Pull") ? "pull" : "legs"),
                        exercises: exercises
                    )
                }
            }
        }

        // Phase 2: Intensification (2 weeks)
        let phase2 = Phase(name: "Intensification", order: 1, phaseDescription: "Increase intensity with progressive overload")
        phase2.program = program
        modelContext.insert(phase2)

        for weekNum in 3...4 {
            let week = Week(weekNumber: weekNum, notes: weekNum == 4 ? "Deload if needed" : nil)
            week.phase = phase2
            modelContext.insert(week)

            let dayNames = ["Push A", "Pull A", "Legs A", "Push B", "Pull B", "Legs B", "Rest"]
            for (dayIndex, dayName) in dayNames.enumerated() {
                let isRest = dayName == "Rest"
                let day = ProgramDay(
                    dayNumber: dayIndex + 1,
                    name: dayName,
                    dayType: isRest ? .rest : .training
                )
                day.week = week
                modelContext.insert(day)

                if !isRest {
                    createWorkoutTemplate(
                        for: day,
                        name: dayName,
                        type: dayName.hasPrefix("Push") ? "push" : (dayName.hasPrefix("Pull") ? "pull" : "legs"),
                        exercises: exercises,
                        intensified: true
                    )
                }
            }
        }

        try modelContext.save()
        logger.info("Successfully seeded sample program")
    }

    private func createWorkoutTemplate(for day: ProgramDay, name: String, type: String, exercises: [Exercise], intensified: Bool = false) {
        let template = WorkoutTemplate(
            name: name,
            templateDescription: "\(type.capitalized) workout",
            estimatedDuration: 60
        )
        template.programDay = day
        modelContext.insert(template)

        var groupOrder = 0

        switch type {
        case "push":
            // Push exercises: chest, shoulders, triceps
            let pushExercises = [
                exercises.first { $0.name.lowercased().contains("bench press") },
                exercises.first { $0.name.lowercased().contains("overhead press") || $0.name.lowercased().contains("shoulder press") },
                exercises.first { $0.name.lowercased().contains("incline") && $0.name.lowercased().contains("dumbbell") },
                exercises.first { $0.name.lowercased().contains("lateral raise") },
                exercises.first { $0.name.lowercased().contains("tricep") || $0.name.lowercased().contains("pushdown") }
            ].compactMap { $0 }

            for exercise in pushExercises {
                let group = ExerciseGroup(groupType: .single, order: groupOrder)
                modelContext.insert(group)
                group.workoutTemplate = template

                let workoutExercise = WorkoutExercise(order: 0, restSeconds: 90)
                workoutExercise.exercise = exercise
                workoutExercise.exerciseGroup = group
                modelContext.insert(workoutExercise)

                // Add 3-4 sets
                let setCount = intensified ? 4 : 3
                for setNum in 1...setCount {
                    let setTemplate = SetTemplate(
                        setNumber: setNum,
                        setType: setNum == 1 ? .warmup : .working,
                        targetReps: intensified ? 8 : 10
                    )
                    setTemplate.workoutExercise = workoutExercise
                    modelContext.insert(setTemplate)
                }

                groupOrder += 1
            }

        case "pull":
            // Pull exercises: back, biceps
            let pullExercises = [
                exercises.first { $0.name.lowercased().contains("row") && $0.name.lowercased().contains("barbell") },
                exercises.first { $0.name.lowercased().contains("pulldown") || $0.name.lowercased().contains("lat") },
                exercises.first { $0.name.lowercased().contains("row") && $0.name.lowercased().contains("cable") },
                exercises.first { $0.name.lowercased().contains("face pull") },
                exercises.first { $0.name.lowercased().contains("curl") && $0.name.lowercased().contains("dumbbell") }
            ].compactMap { $0 }

            for exercise in pullExercises {
                let group = ExerciseGroup(groupType: .single, order: groupOrder)
                modelContext.insert(group)
                group.workoutTemplate = template

                let workoutExercise = WorkoutExercise(order: 0, restSeconds: 90)
                workoutExercise.exercise = exercise
                workoutExercise.exerciseGroup = group
                modelContext.insert(workoutExercise)

                let setCount = intensified ? 4 : 3
                for setNum in 1...setCount {
                    let setTemplate = SetTemplate(
                        setNumber: setNum,
                        setType: setNum == 1 ? .warmup : .working,
                        targetReps: intensified ? 8 : 10
                    )
                    setTemplate.workoutExercise = workoutExercise
                    modelContext.insert(setTemplate)
                }

                groupOrder += 1
            }

        case "legs":
            // Leg exercises: quads, hamstrings, glutes, calves
            let legExercises = [
                exercises.first { $0.name.lowercased().contains("squat") && $0.name.lowercased().contains("barbell") },
                exercises.first { $0.name.lowercased().contains("romanian") || $0.name.lowercased().contains("rdl") },
                exercises.first { $0.name.lowercased().contains("leg press") },
                exercises.first { $0.name.lowercased().contains("leg curl") },
                exercises.first { $0.name.lowercased().contains("calf") }
            ].compactMap { $0 }

            for exercise in legExercises {
                let group = ExerciseGroup(groupType: .single, order: groupOrder)
                modelContext.insert(group)
                group.workoutTemplate = template

                let workoutExercise = WorkoutExercise(order: 0, restSeconds: 120)
                workoutExercise.exercise = exercise
                workoutExercise.exerciseGroup = group
                modelContext.insert(workoutExercise)

                let setCount = intensified ? 4 : 3
                for setNum in 1...setCount {
                    let setTemplate = SetTemplate(
                        setNumber: setNum,
                        setType: setNum == 1 ? .warmup : .working,
                        targetReps: intensified ? 6 : 8
                    )
                    setTemplate.workoutExercise = workoutExercise
                    modelContext.insert(setTemplate)
                }

                groupOrder += 1
            }

        default:
            break
        }
    }

    // MARK: - Beginner Body Restoration Program

    /// Seeds the "Beginner Body Restoration" corrective exercise program from JSON
    func seedBeginnerBodyRestoration() async throws {
        logger.info("Seeding Beginner Body Restoration program...")

        let bbrName = "Beginner Body Restoration"
        let descriptor = FetchDescriptor<Program>(
            predicate: #Predicate { $0.name == bbrName }
        )
        let existing = try modelContext.fetch(descriptor)

        // Delete and re-seed to pick up structural changes
        if !existing.isEmpty {
            for program in existing {
                modelContext.delete(program)
            }
            try modelContext.save()
            logger.info("Deleted existing BBR program for re-seed")
        }

        // Import from bundled JSON
        guard let url = Bundle.main.url(forResource: "bbr-program", withExtension: "json") else {
            logger.error("bbr-program.json not found in bundle")
            return
        }

        let importService = ImportService(modelContext: modelContext)
        _ = try await importService.importProgram(from: url)

        logger.info("Successfully seeded Beginner Body Restoration program from JSON")
    }

    /// Clears all sample data (for reset)
    func clearSampleData() throws {
        // Delete all workout sessions
        let sessionDescriptor = FetchDescriptor<WorkoutSession>()
        let sessions = try modelContext.fetch(sessionDescriptor)
        for session in sessions {
            modelContext.delete(session)
        }

        // Delete all personal records
        let prDescriptor = FetchDescriptor<PersonalRecord>()
        let records = try modelContext.fetch(prDescriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
        logger.info("Cleared all sample data")
    }
}
