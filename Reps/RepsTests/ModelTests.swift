import XCTest
@testable import Reps

final class ModelTests: XCTestCase {

    // MARK: - MuscleGroup Tests

    func testMuscleGroupDisplayNames() {
        XCTAssertEqual(MuscleGroup.chest.displayName, "Chest")
        XCTAssertEqual(MuscleGroup.back.displayName, "Back")
        XCTAssertEqual(MuscleGroup.shoulders.displayName, "Shoulders")
        XCTAssertEqual(MuscleGroup.biceps.displayName, "Biceps")
        XCTAssertEqual(MuscleGroup.triceps.displayName, "Triceps")
        XCTAssertEqual(MuscleGroup.forearms.displayName, "Forearms")
        XCTAssertEqual(MuscleGroup.quads.displayName, "Quadriceps")
        XCTAssertEqual(MuscleGroup.hamstrings.displayName, "Hamstrings")
        XCTAssertEqual(MuscleGroup.glutes.displayName, "Glutes")
        XCTAssertEqual(MuscleGroup.calves.displayName, "Calves")
        XCTAssertEqual(MuscleGroup.abdominals.displayName, "Abdominals")
        XCTAssertEqual(MuscleGroup.obliques.displayName, "Obliques")
        XCTAssertEqual(MuscleGroup.lowerBack.displayName, "Lower Back")
        XCTAssertEqual(MuscleGroup.traps.displayName, "Traps")
        XCTAssertEqual(MuscleGroup.lats.displayName, "Lats")
        XCTAssertEqual(MuscleGroup.cardio.displayName, "Cardio")
    }

    // MARK: - Equipment Tests

    func testEquipmentDisplayNames() {
        XCTAssertEqual(Equipment.barbell.displayName, "Barbell")
        XCTAssertEqual(Equipment.dumbbell.displayName, "Dumbbell")
        XCTAssertEqual(Equipment.machine.displayName, "Machine")
        XCTAssertEqual(Equipment.cable.displayName, "Cable")
        XCTAssertEqual(Equipment.bodyweight.displayName, "Bodyweight")
        XCTAssertEqual(Equipment.kettlebell.displayName, "Kettlebell")
        XCTAssertEqual(Equipment.resistanceBand.displayName, "Resistance Band")
        XCTAssertEqual(Equipment.smithMachine.displayName, "Smith Machine")
        XCTAssertEqual(Equipment.ezBar.displayName, "EZ Bar")
        XCTAssertEqual(Equipment.trapBar.displayName, "Trap Bar")
    }

    // MARK: - SetType Tests

    func testSetTypeDisplayNames() {
        XCTAssertEqual(SetType.warmup.displayName, "Warmup")
        XCTAssertEqual(SetType.working.displayName, "Working")
        XCTAssertEqual(SetType.dropset.displayName, "Drop Set")
        XCTAssertEqual(SetType.failure.displayName, "To Failure")
        XCTAssertEqual(SetType.amrap.displayName, "AMRAP")
        XCTAssertEqual(SetType.restPause.displayName, "Rest-Pause")
    }

    // MARK: - RestTimerState Tests

    func testRestTimerStateRemainingSeconds() {
        let state = RestTimerState(totalSeconds: 90)
        XCTAssertEqual(state.remainingSeconds, 90)
    }

    func testRestTimerStateWithStartDate() {
        let startDate = Date().addingTimeInterval(-30)
        let state = RestTimerState(totalSeconds: 90, startDate: startDate)
        // Should be around 60 seconds remaining
        XCTAssertTrue(state.remainingSeconds >= 59 && state.remainingSeconds <= 61)
    }

    func testRestTimerStateExpired() {
        let startDate = Date().addingTimeInterval(-100)
        let state = RestTimerState(totalSeconds: 90, startDate: startDate)
        XCTAssertEqual(state.remainingSeconds, 0)
    }

    // MARK: - Exercise Tests

    func testExerciseHasVideo_WithURL() {
        let exercise = Exercise(name: "Test", muscleGroups: [.chest])
        exercise.videoURL = "https://youtube.com/watch?v=test"
        XCTAssertTrue(exercise.hasVideo)
    }

    func testExerciseHasVideo_WithLocalFile() {
        let exercise = Exercise(name: "Test", muscleGroups: [.chest])
        exercise.localVideoFilename = "test.mp4"
        XCTAssertTrue(exercise.hasVideo)
    }

    func testExerciseHasVideo_NoVideo() {
        let exercise = Exercise(name: "Test", muscleGroups: [.chest])
        XCTAssertFalse(exercise.hasVideo)
    }
}
