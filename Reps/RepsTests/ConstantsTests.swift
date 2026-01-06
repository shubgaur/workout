import XCTest
@testable import Reps

final class ConstantsTests: XCTestCase {

    // MARK: - Rest Timer Constants

    func testRestTimerDefaults() {
        XCTAssertEqual(Constants.RestTimer.defaultSeconds, 90)
        XCTAssertEqual(Constants.RestTimer.shortAdjustment, 15)
        XCTAssertEqual(Constants.RestTimer.mediumAdjustment, 30)
    }

    func testHapticWarnings() {
        XCTAssertEqual(Constants.RestTimer.HapticWarnings.medium, 10)
        XCTAssertEqual(Constants.RestTimer.HapticWarnings.light, 5)
        XCTAssertEqual(Constants.RestTimer.HapticWarnings.countdown, 3)
    }

    // MARK: - Workout Defaults

    func testWorkoutDefaults() {
        XCTAssertEqual(Constants.Workout.defaultSets, 3)
        XCTAssertEqual(Constants.Workout.defaultReps, 10)
    }

    // MARK: - Contribution Graph

    func testContributionGraph() {
        XCTAssertEqual(Constants.ContributionGraph.weeksToShow, 17)
    }

    // MARK: - Formulas

    func testEpleyDivisor() {
        XCTAssertEqual(Constants.Formulas.epleyDivisor, 30.0)
    }

    // MARK: - Volume Display

    func testVolumeThresholds() {
        XCTAssertEqual(Constants.VolumeDisplay.millionThreshold, 1_000_000.0)
        XCTAssertEqual(Constants.VolumeDisplay.thousandThreshold, 1_000.0)
    }

    // MARK: - Layout

    func testLayoutConstants() {
        XCTAssertEqual(Constants.Layout.setColumnWidth, 50)
        XCTAssertEqual(Constants.Layout.previousColumnWidth, 80)
        XCTAssertEqual(Constants.Layout.checkButtonSize, 50)
    }

    // MARK: - Time Constants

    func testTimeConstants() {
        XCTAssertEqual(Constants.Time.secondsPerHour, 3600)
        XCTAssertEqual(Constants.Time.secondsPerMinute, 60)
    }

    // MARK: - Array Extension

    func testArraySortedByKeyPath() {
        struct Item {
            let order: Int
            let name: String
        }

        let items = [
            Item(order: 3, name: "C"),
            Item(order: 1, name: "A"),
            Item(order: 2, name: "B")
        ]

        let sorted = items.sorted(by: \.order)

        XCTAssertEqual(sorted[0].order, 1)
        XCTAssertEqual(sorted[1].order, 2)
        XCTAssertEqual(sorted[2].order, 3)
    }

    func testArraySortedByKeyPath_Strings() {
        struct Person {
            let name: String
        }

        let people = [
            Person(name: "Zoe"),
            Person(name: "Alice"),
            Person(name: "Mike")
        ]

        let sorted = people.sorted(by: \.name)

        XCTAssertEqual(sorted[0].name, "Alice")
        XCTAssertEqual(sorted[1].name, "Mike")
        XCTAssertEqual(sorted[2].name, "Zoe")
    }
}
