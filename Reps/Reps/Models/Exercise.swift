import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroups: [MuscleGroup]
    var equipment: [Equipment]
    var instructions: String?
    var videoURL: String?
    var localVideoFilename: String? // Stored in app's documents/videos directory
    var bundledVideoFilename: String? // Filename in app bundle's "Videos" folder
    var imageURL: String?
    var localImageFilename: String? // Stored in app's documents/images directory
    var isCustom: Bool
    var createdAt: Date

    @Relationship(inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise] = []

    @Relationship(inverse: \PersonalRecord.exercise)
    var personalRecords: [PersonalRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroups: [MuscleGroup] = [],
        equipment: [Equipment] = [],
        instructions: String? = nil,
        videoURL: String? = nil,
        localVideoFilename: String? = nil,
        bundledVideoFilename: String? = nil,
        imageURL: String? = nil,
        localImageFilename: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
        self.videoURL = videoURL
        self.localVideoFilename = localVideoFilename
        self.bundledVideoFilename = bundledVideoFilename
        self.imageURL = imageURL
        self.localImageFilename = localImageFilename
        self.isCustom = isCustom
        self.createdAt = Date()
    }

    /// Primary equipment for display
    var primaryEquipment: Equipment? {
        equipment.first
    }

    var primaryMuscle: MuscleGroup? {
        muscleGroups.first
    }

    var displayMuscle: String {
        primaryMuscle?.displayName ?? "General"
    }

    /// Returns true if the exercise has any video (URL, local, or bundled)
    var hasVideo: Bool {
        videoURL != nil || localVideoFilename != nil || bundledVideoFilename != nil
    }

    /// Returns the local video URL if it exists
    var localVideoURL: URL? {
        guard let filename = localVideoFilename else { return nil }
        return VideoStorageService.videosDirectory.appendingPathComponent(filename)
    }

    /// Returns the bundled video URL if it exists in the app bundle
    var bundledVideoURL: URL? {
        guard let filename = bundledVideoFilename else { return nil }
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Videos")
    }

    /// Effective video URL for inline playback: local file > bundled > nil
    var effectiveVideoURL: URL? {
        if let localURL = localVideoURL,
           FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        if let bundledURL = bundledVideoURL {
            return bundledURL
        }
        return nil
    }

    /// Returns true if the exercise has any image (URL or local)
    var hasImage: Bool {
        imageURL != nil || localImageFilename != nil
    }

    /// Returns the local image URL if it exists
    var localImageURL: URL? {
        guard let filename = localImageFilename else { return nil }
        return VideoStorageService.imagesDirectory.appendingPathComponent(filename)
    }
}
