import XCTest
@testable import Reps

final class TimeFormatterTests: XCTestCase {

    // MARK: - formatDuration Tests

    func testFormatDuration_Zero() {
        XCTAssertEqual(TimeFormatter.formatDuration(0), "0s")
    }

    func testFormatDuration_SecondsOnly() {
        XCTAssertEqual(TimeFormatter.formatDuration(45), "45s")
    }

    func testFormatDuration_MinutesOnly() {
        XCTAssertEqual(TimeFormatter.formatDuration(120), "2m")
    }

    func testFormatDuration_MinutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.formatDuration(90), "1m 30s")
    }

    func testFormatDuration_HoursMinutesSeconds() {
        XCTAssertEqual(TimeFormatter.formatDuration(3661), "1h 1m")
    }

    func testFormatDuration_HoursOnly() {
        XCTAssertEqual(TimeFormatter.formatDuration(7200), "2h")
    }

    // MARK: - formatRestTimer Tests

    func testFormatRestTimer_LessThanMinute() {
        XCTAssertEqual(TimeFormatter.formatRestTimer(45), "0:45")
    }

    func testFormatRestTimer_ExactMinute() {
        XCTAssertEqual(TimeFormatter.formatRestTimer(60), "1:00")
    }

    func testFormatRestTimer_MinutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.formatRestTimer(90), "1:30")
    }

    func testFormatRestTimer_SingleDigitSeconds() {
        XCTAssertEqual(TimeFormatter.formatRestTimer(65), "1:05")
    }

    func testFormatRestTimer_Zero() {
        XCTAssertEqual(TimeFormatter.formatRestTimer(0), "0:00")
    }

    func testFormatRestTimer_LargeValue() {
        XCTAssertEqual(TimeFormatter.formatRestTimer(180), "3:00")
    }
}
