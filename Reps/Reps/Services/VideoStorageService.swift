import Foundation
import AVFoundation
import os.log

private let logger = Logger(subsystem: "com.reps.app", category: "VideoStorageService")

/// Service for storing and managing local video files
enum VideoStorageService {

    /// Directory where videos are stored
    static var videosDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosPath = documentsPath.appendingPathComponent("Videos", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: videosPath.path) {
            try? FileManager.default.createDirectory(at: videosPath, withIntermediateDirectories: true)
            logger.info("Created videos directory at \(videosPath.path)")
        }

        return videosPath
    }

    /// Directory where images are stored
    static var imagesDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("Images", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: imagesPath.path) {
            try? FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
            logger.info("Created images directory at \(imagesPath.path)")
        }

        return imagesPath
    }

    /// Saves a video file and returns the filename
    /// - Parameter sourceURL: The source URL of the video to save
    /// - Returns: The filename of the saved video
    static func saveVideo(from sourceURL: URL) throws -> String {
        let filename = "\(UUID().uuidString).\(sourceURL.pathExtension)"
        let destinationURL = videosDirectory.appendingPathComponent(filename)

        // Start accessing security-scoped resource if needed
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        logger.info("Saved video: \(filename)")

        return filename
    }

    /// Deletes a video file
    /// - Parameter filename: The filename of the video to delete
    static func deleteVideo(filename: String) {
        let fileURL = videosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
        logger.info("Deleted video: \(filename)")
    }

    /// Gets the URL for a stored video
    /// - Parameter filename: The filename of the video
    /// - Returns: The full URL to the video file
    static func videoURL(for filename: String) -> URL {
        videosDirectory.appendingPathComponent(filename)
    }

    /// Checks if a video file exists
    /// - Parameter filename: The filename to check
    /// - Returns: True if the file exists
    static func videoExists(filename: String) -> Bool {
        let fileURL = videosDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Gets the total size of all stored videos
    static var totalStorageUsed: Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: videosDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    /// Formatted string of storage used
    static var formattedStorageUsed: String {
        let bytes = totalStorageUsed
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Image Storage

    /// Saves an image file and returns the filename
    /// - Parameter sourceURL: The source URL of the image to save
    /// - Returns: The filename of the saved image
    static func saveImage(from sourceURL: URL) throws -> String {
        let filename = "\(UUID().uuidString).\(sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension)"
        let destinationURL = imagesDirectory.appendingPathComponent(filename)

        // Start accessing security-scoped resource if needed
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        logger.info("Saved image: \(filename)")

        return filename
    }

    /// Deletes an image file
    /// - Parameter filename: The filename of the image to delete
    static func deleteImage(filename: String) {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
        logger.info("Deleted image: \(filename)")
    }

    /// Gets the URL for a stored image
    /// - Parameter filename: The filename of the image
    /// - Returns: The full URL to the image file
    static func imageURL(for filename: String) -> URL {
        imagesDirectory.appendingPathComponent(filename)
    }

    /// Checks if an image file exists
    /// - Parameter filename: The filename to check
    /// - Returns: True if the file exists
    static func imageExists(filename: String) -> Bool {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
