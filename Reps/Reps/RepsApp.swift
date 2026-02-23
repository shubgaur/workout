import SwiftUI
import SwiftData

@main
struct RepsApp: App {
    let container: ModelContainer

    init() {
        // Pre-warm MotionManager so all cards see same initial state
        // This ensures synchronized glint movement across all views
        MotionManager.shared.startUpdates()

        do {
            let schema = Schema([
                Exercise.self,
                Program.self,
                Phase.self,
                Week.self,
                ProgramDay.self,
                WorkoutTemplate.self,
                ExerciseGroup.self,
                WorkoutExercise.self,
                SetTemplate.self,
                WorkoutSession.self,
                LoggedSet.self,
                PersonalRecord.self,
                UserSettings.self,
                UserStats.self
            ])

            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await seedDataIfNeeded()
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func seedDataIfNeeded() async {
        let context = container.mainContext
        let exerciseService = ExerciseService(modelContext: context)
        let sampleDataService = SampleDataService(modelContext: context)

        do {
            try await exerciseService.seedExercisesIfNeeded()
            // Seed sample workout history for visualization
            try await sampleDataService.seedSampleData()
            // Seed sample program for testing Programs tab
            try await sampleDataService.seedSampleProgram()
            // Seed Beginner Body Restoration corrective exercise program
            try await sampleDataService.seedBeginnerBodyRestoration()
        } catch {
            print("Failed to seed data: \(error)")
        }
    }
}
