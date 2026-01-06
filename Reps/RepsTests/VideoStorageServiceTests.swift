import XCTest
@testable import Reps

final class VideoStorageServiceTests: XCTestCase {

    // MARK: - Directory Tests

    func testVideosDirectoryPath() {
        let url = VideoStorageService.videosDirectory
        XCTAssertTrue(url.path.contains("Documents"))
        XCTAssertTrue(url.lastPathComponent == "Videos")
    }

    func testVideoURLConstruction() {
        let filename = "test_video.mp4"
        let url = VideoStorageService.videoURL(for: filename)
        XCTAssertTrue(url.lastPathComponent == filename)
        XCTAssertTrue(url.path.contains("Videos"))
    }

    // MARK: - Storage Calculation

    func testFormattedStorageUsed_Empty() {
        // When no videos, should show reasonable format
        let formatted = VideoStorageService.formattedStorageUsed
        XCTAssertTrue(formatted.contains("MB") || formatted.contains("GB") || formatted.contains("KB") || formatted == "0 bytes")
    }

    // MARK: - Video Exists Check

    func testVideoExists_NonExistent() {
        let exists = VideoStorageService.videoExists(filename: "definitely_not_a_real_video_12345.mp4")
        XCTAssertFalse(exists)
    }
}
