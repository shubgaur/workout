import SwiftUI
import SwiftData
import AVKit
import UniformTypeIdentifiers
import ImageIO

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise

    @State private var showingVideo = false
    @State private var isEditing = false
    @State private var showingVideoURLInput = false
    @State private var headerScale: CGFloat = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
                // Header with image/video
                headerSection

                // Info cards
                VStack(spacing: RepsTheme.Spacing.md) {
                    // Video card - tappable to add/play
                    videoCard
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))

                    // Muscle groups
                    infoCard(
                        title: "TARGET MUSCLES",
                        icon: "figure.strengthtraining.traditional"
                    ) {
                        FlowLayout(spacing: RepsTheme.Spacing.xs) {
                            ForEach(exercise.muscleGroups, id: \.self) { muscle in
                                MuscleTag(muscle: muscle)
                            }
                        }
                    }

                    // Equipment
                    if !exercise.equipment.isEmpty {
                        infoCard(
                            title: "EQUIPMENT",
                            icon: exercise.equipment.first?.iconName ?? "dumbbell.fill"
                        ) {
                            Text(exercise.equipment.map { $0.displayName }.joined(separator: ", "))
                                .font(RepsTheme.Typography.body)
                                .foregroundStyle(RepsTheme.Colors.text)
                        }
                    }

                    // Instructions
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        infoCard(
                            title: "INSTRUCTIONS",
                            icon: "list.number"
                        ) {
                            MarkdownText(instructions)
                                .font(RepsTheme.Typography.body)
                                .foregroundStyle(RepsTheme.Colors.text)
                        }
                    }

                    // History placeholder
                    infoCard(
                        title: "HISTORY",
                        icon: "chart.line.uptrend.xyaxis"
                    ) {
                        VStack(spacing: RepsTheme.Spacing.sm) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(RepsTheme.Colors.textTertiary)

                            Text("No history yet")
                                .font(RepsTheme.Typography.footnote)
                                .foregroundStyle(RepsTheme.Colors.textSecondary)

                            Text("Complete a workout with this exercise to see your progress")
                                .font(RepsTheme.Typography.caption)
                                .foregroundStyle(RepsTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RepsTheme.Spacing.lg)
                    }
                }
                .padding(.horizontal, RepsTheme.Spacing.md)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: exercise.videoURL)
            }
        }
        .background(RepsTheme.Colors.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
                .foregroundStyle(RepsTheme.Colors.accent)
            }
        }
        .sheet(isPresented: $isEditing) {
            ExerciseEditSheet(exercise: exercise)
        }
        .sheet(isPresented: $showingVideoURLInput) {
            VideoURLInputSheet(exercise: exercise)
        }
    }

    // MARK: - Video Card

    private var videoCard: some View {
        Button {
            if exercise.hasVideo {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingVideo = true
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingVideoURLInput = true
            }
        } label: {
            HStack(spacing: RepsTheme.Spacing.md) {
                // Video icon with animation
                ZStack {
                    Circle()
                        .fill(exercise.hasVideo ? RepsTheme.Colors.accent : RepsTheme.Colors.surfaceElevated)
                        .frame(width: 48, height: 48)

                    Image(systemName: exercise.hasVideo ? "play.fill" : "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(exercise.hasVideo ? RepsTheme.Colors.background : RepsTheme.Colors.accent)
                }
                .scaleEffect(headerScale)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: headerScale)

                VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                    Text(exercise.hasVideo ? "WATCH VIDEO" : "ADD VIDEO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    Text(videoCardSubtitle)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RepsTheme.Colors.textTertiary)
            }
            .padding(RepsTheme.Spacing.md)
            .background(RepsTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(exercise.hasVideo ? RepsTheme.Colors.accent.opacity(0.3) : RepsTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var videoCardSubtitle: String {
        if exercise.localVideoFilename != nil {
            return "Local video • Tap to play"
        } else if exercise.videoURL != nil {
            return "Tap to play exercise tutorial"
        } else {
            return "Tap to add a video URL or file"
        }
    }

    private var headerSection: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    RepsTheme.Colors.accent.opacity(0.3),
                    RepsTheme.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: RepsTheme.Spacing.md) {
                // Image or placeholder
                if let imageURL = exercise.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        default:
                            exercisePlaceholder
                        }
                    }
                    .frame(height: 200)
                } else {
                    exercisePlaceholder
                        .frame(height: 200)
                }
            }
            .padding(.vertical, RepsTheme.Spacing.lg)
        }
        .sheet(isPresented: $showingVideo) {
            VideoPlayerSheet(
                videoURL: exercise.videoURL,
                localVideoURL: exercise.localVideoURL,
                exerciseName: exercise.name
            )
        }
    }

    private var exercisePlaceholder: some View {
        VStack(spacing: RepsTheme.Spacing.sm) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.accent.opacity(0.5))

            if exercise.isCustom {
                Text("Custom Exercise")
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
    }

    private func infoCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(RepsTheme.Colors.accent)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Muscle Tag

struct MuscleTag: View {
    let muscle: MuscleGroup

    var body: some View {
        Text(muscle.displayName)
            .font(RepsTheme.Typography.caption)
            .fontWeight(.medium)
            .foregroundStyle(RepsTheme.Colors.text)
            .padding(.horizontal, RepsTheme.Spacing.sm)
            .padding(.vertical, RepsTheme.Spacing.xxs)
            .background(RepsTheme.Colors.surfaceElevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            height = y + lineHeight
        }
    }
}

// MARK: - Video Player Sheet

struct VideoPlayerSheet: View {
    let videoURL: String?
    let localVideoURL: URL?
    let exerciseName: String

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    private enum ContentType {
        case localVideo
        case localGIF
        case youTube
        case directVideo
        case remoteGIF
        case unavailable
    }

    private var contentType: ContentType {
        // Check local file first
        if let localURL = localVideoURL, FileManager.default.fileExists(atPath: localURL.path) {
            if isGIF(url: localURL) {
                return .localGIF
            }
            return .localVideo
        }

        // Check remote URL
        if let urlString = videoURL {
            if isYouTubeURL(urlString) {
                return .youTube
            }
            if isGIFURL(urlString) {
                return .remoteGIF
            }
            if isDirectVideoURL(urlString) {
                return .directVideo
            }
        }

        return .unavailable
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RepsTheme.Colors.background.ignoresSafeArea()

                switch contentType {
                case .localVideo:
                    if let localURL = localVideoURL {
                        LocalVideoPlayerView(url: localURL, player: $player)
                            .ignoresSafeArea()
                    }

                case .localGIF:
                    if let localURL = localVideoURL {
                        GIFPlayerView(url: localURL)
                    }

                case .youTube:
                    if let urlString = videoURL {
                        YouTubePlayerView(videoURL: urlString, autoplay: true)
                    }

                case .directVideo:
                    if let urlString = videoURL, let url = URL(string: urlString) {
                        LocalVideoPlayerView(url: url, player: $player)
                            .ignoresSafeArea()
                    }

                case .remoteGIF:
                    if let urlString = videoURL, let url = URL(string: urlString) {
                        RemoteGIFPlayerView(url: url)
                    }

                case .unavailable:
                    VStack(spacing: RepsTheme.Spacing.md) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(RepsTheme.Colors.textTertiary)

                        Text("Video unavailable")
                            .font(RepsTheme.Typography.body)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        player?.pause()
                        dismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func isYouTubeURL(_ url: String) -> Bool {
        url.contains("youtube.com") || url.contains("youtu.be")
    }

    private func isGIF(url: URL) -> Bool {
        url.pathExtension.lowercased() == "gif"
    }

    private func isGIFURL(_ url: String) -> Bool {
        url.lowercased().hasSuffix(".gif")
    }

    private func isDirectVideoURL(_ url: String) -> Bool {
        let videoExtensions = ["mp4", "m4v", "mov", "m4a", "webm", "avi"]
        let lowercased = url.lowercased()
        return videoExtensions.contains { lowercased.contains(".\($0)") }
    }
}

// MARK: - Local Video Player

struct LocalVideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    @Binding var player: AVPlayer?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let avPlayer = AVPlayer(url: url)
        controller.player = avPlayer
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = UIColor(RepsTheme.Colors.background)

        // Autoplay
        DispatchQueue.main.async {
            self.player = avPlayer
            avPlayer.play()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - YouTube Player View

import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String
    var autoplay: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = UIColor(RepsTheme.Colors.background)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let videoID = extractVideoID(from: videoURL) else { return }

        let autoplayParam = autoplay ? "&autoplay=1" : ""
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { margin: 0; background: #0A0A0A; display: flex; justify-content: center; align-items: center; height: 100vh; }
                iframe { width: 100%; aspect-ratio: 16/9; border: none; }
            </style>
        </head>
        <body>
            <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1&rel=0\(autoplayParam)" allowfullscreen></iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(embedHTML, baseURL: nil)
    }

    private func extractVideoID(from url: String) -> String? {
        if url.contains("youtu.be/") {
            return url.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        } else if url.contains("youtube.com/watch") {
            return URLComponents(string: url)?.queryItems?.first(where: { $0.name == "v" })?.value
        } else if url.contains("youtube.com/embed/") {
            return url.components(separatedBy: "embed/").last?.components(separatedBy: "?").first
        }
        return nil
    }
}

// MARK: - GIF Player View (Local)

struct GIFPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(RepsTheme.Colors.background)

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(RepsTheme.Colors.background)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Load animated GIF
        if let data = try? Data(contentsOf: url),
           let source = CGImageSourceCreateWithData(data as CFData, nil) {
            let frameCount = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var duration: Double = 0

            for i in 0..<frameCount {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))

                    // Get frame duration
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                       let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                        duration += frameDuration
                    } else {
                        duration += 0.1 // Default frame duration
                    }
                }
            }

            imageView.animationImages = images
            imageView.animationDuration = duration
            imageView.startAnimating()
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Remote GIF Player View

struct RemoteGIFPlayerView: View {
    let url: URL
    @State private var gifData: Data?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            RepsTheme.Colors.background

            if let data = gifData {
                GIFDataView(data: data)
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(RepsTheme.Colors.accent)
            } else {
                VStack(spacing: RepsTheme.Spacing.md) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(RepsTheme.Colors.textTertiary)

                    Text("Failed to load GIF")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
        }
        .task {
            await loadGIF()
        }
    }

    private func loadGIF() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run {
                self.gifData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - GIF Data View

struct GIFDataView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(RepsTheme.Colors.background)

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(RepsTheme.Colors.background)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        loadAnimatedGIF(into: imageView)
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func loadAnimatedGIF(into imageView: UIImageView) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }

        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: Double = 0

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))

                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += frameDuration
                } else {
                    duration += 0.1
                }
            }
        }

        imageView.animationImages = images
        imageView.animationDuration = duration
        imageView.startAnimating()
    }
}

// MARK: - Video URL Input Sheet

struct VideoURLInputSheet: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    @State private var urlText = ""
    @State private var showingFilePicker = false
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: RepsTheme.Spacing.xl) {
                // Header
                VStack(spacing: RepsTheme.Spacing.sm) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(RepsTheme.Colors.accent)
                        .padding(.top, RepsTheme.Spacing.xl)

                    Text("Add Video")
                        .font(RepsTheme.Typography.title)
                        .foregroundStyle(RepsTheme.Colors.text)

                    Text("Add a YouTube URL or import a local video file")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: RepsTheme.Spacing.md) {
                    // URL Input
                    VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
                        Text("VIDEO URL")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(RepsTheme.Colors.textSecondary)

                        TextField("https://youtube.com/watch?v=...", text: $urlText)
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(RepsTheme.Spacing.md)
                            .background(RepsTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
                            )
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        saveURL()
                    } label: {
                        Text("Save URL")
                            .font(RepsTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(RepsTheme.Colors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RepsTheme.Spacing.md)
                            .background(urlText.isEmpty ? RepsTheme.Colors.textTertiary : RepsTheme.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
                    }
                    .disabled(urlText.isEmpty)
                    .buttonStyle(ScaleButtonStyle())

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(RepsTheme.Colors.border)
                            .frame(height: 1)
                        Text("OR")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                        Rectangle()
                            .fill(RepsTheme.Colors.border)
                            .frame(height: 1)
                    }
                    .padding(.vertical, RepsTheme.Spacing.sm)

                    // File picker button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showingFilePicker = true
                    } label: {
                        HStack(spacing: RepsTheme.Spacing.sm) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18))
                            Text("Choose from Files")
                                .font(RepsTheme.Typography.body)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(RepsTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RepsTheme.Spacing.md)
                        .background(RepsTheme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                                .stroke(RepsTheme.Colors.accent.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(RepsTheme.Typography.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Current video info
                    if exercise.hasVideo {
                        VStack(spacing: RepsTheme.Spacing.xs) {
                            Divider()
                                .padding(.vertical, RepsTheme.Spacing.sm)

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(exercise.localVideoFilename != nil ? "Local video saved" : "Video URL set")
                                    .font(RepsTheme.Typography.caption)
                                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                                Spacer()

                                Button("Remove") {
                                    removeVideo()
                                }
                                .font(RepsTheme.Typography.caption)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, RepsTheme.Spacing.lg)

                Spacer()
            }
            .background(RepsTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie, .gif, .mpeg4Audio],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .overlay {
                if isImporting {
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(spacing: RepsTheme.Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(RepsTheme.Colors.accent)
                            Text("Importing video...")
                                .font(RepsTheme.Typography.caption)
                                .foregroundStyle(RepsTheme.Colors.text)
                        }
                        .padding(RepsTheme.Spacing.xl)
                        .background(RepsTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }

    private func saveURL() {
        guard !urlText.isEmpty else { return }

        // Clear local video if setting URL
        if let filename = exercise.localVideoFilename {
            VideoStorageService.deleteVideo(filename: filename)
            exercise.localVideoFilename = nil
        }

        exercise.videoURL = urlText
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else { return }

            isImporting = true
            errorMessage = nil

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let filename = try VideoStorageService.saveVideo(from: sourceURL)

                    DispatchQueue.main.async {
                        // Clear URL if setting local video
                        exercise.videoURL = nil
                        exercise.localVideoFilename = filename
                        isImporting = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                } catch {
                    DispatchQueue.main.async {
                        isImporting = false
                        errorMessage = "Failed to import video: \(error.localizedDescription)"
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func removeVideo() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if let filename = exercise.localVideoFilename {
            VideoStorageService.deleteVideo(filename: filename)
            exercise.localVideoFilename = nil
        }
        exercise.videoURL = nil
    }
}

// MARK: - Exercise Edit Sheet

struct ExerciseEditSheet: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var instructions: String = ""
    @State private var imageURL: String = ""
    @State private var localImageFilename: String?
    @State private var showingImagePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }

                Section("Target Muscles") {
                    MuscleGroupPicker(selectedMuscles: $selectedMuscles)
                }

                Section("Equipment") {
                    EquipmentPicker(selectedEquipment: $selectedEquipment)
                }

                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }

                Section("Image") {
                    // Show current image preview
                    if let filename = localImageFilename {
                        HStack {
                            Image(uiImage: loadLocalImage(filename: filename) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))

                            Spacer()

                            Button(role: .destructive) {
                                // Delete old image file
                                if let old = localImageFilename {
                                    VideoStorageService.deleteImage(filename: old)
                                }
                                localImageFilename = nil
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(RepsTheme.Colors.error)
                            }
                        }
                    } else if !imageURL.isEmpty, let url = URL(string: imageURL) {
                        HStack {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))

                            Spacer()

                            Button(role: .destructive) {
                                imageURL = ""
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(RepsTheme.Colors.error)
                            }
                        }
                    }

                    // Upload button
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label(localImageFilename != nil || !imageURL.isEmpty ? "Change Image" : "Choose Image", systemImage: "photo")
                    }

                    // URL fallback
                    TextField("Or paste image URL...", text: $imageURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .onChange(of: imageURL) { _, newValue in
                            if !newValue.isEmpty {
                                // Clear local image when URL is entered
                                if let old = localImageFilename {
                                    VideoStorageService.deleteImage(filename: old)
                                }
                                localImageFilename = nil
                            }
                        }
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = exercise.name
                selectedMuscles = Set(exercise.muscleGroups)
                selectedEquipment = Set(exercise.equipment)
                instructions = exercise.instructions ?? ""
                imageURL = exercise.imageURL ?? ""
                localImageFilename = exercise.localImageFilename
            }
            .fileImporter(
                isPresented: $showingImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                handleImageSelection(result)
            }
        }
    }

    private func loadLocalImage(filename: String) -> UIImage? {
        let url = VideoStorageService.imageURL(for: filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else { return }

            do {
                // Delete old image if exists
                if let old = localImageFilename {
                    VideoStorageService.deleteImage(filename: old)
                }

                // Save new image
                let filename = try VideoStorageService.saveImage(from: sourceURL)
                localImageFilename = filename
                imageURL = "" // Clear URL when local image is selected
            } catch {
                print("Failed to save image: \(error)")
            }
        case .failure(let error):
            print("Image selection failed: \(error)")
        }
    }

    private func saveChanges() {
        exercise.name = name
        exercise.muscleGroups = Array(selectedMuscles)
        exercise.equipment = Array(selectedEquipment)
        exercise.instructions = instructions.isEmpty ? nil : instructions
        exercise.imageURL = imageURL.isEmpty ? nil : imageURL
        exercise.localImageFilename = localImageFilename
    }
}

// MARK: - Equipment Picker

struct EquipmentPicker: View {
    @Binding var selectedEquipment: Set<Equipment>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: RepsTheme.Spacing.sm) {
            ForEach(Equipment.allCases, id: \.self) { equipment in
                Button {
                    if selectedEquipment.contains(equipment) {
                        selectedEquipment.remove(equipment)
                    } else {
                        selectedEquipment.insert(equipment)
                    }
                } label: {
                    HStack(spacing: RepsTheme.Spacing.xxs) {
                        Image(systemName: equipment.iconName)
                            .font(.system(size: 12))
                        Text(equipment.displayName)
                            .font(RepsTheme.Typography.caption)
                            .fontWeight(selectedEquipment.contains(equipment) ? .semibold : .regular)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selectedEquipment.contains(equipment) ? RepsTheme.Colors.background : RepsTheme.Colors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RepsTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                            .fill(selectedEquipment.contains(equipment) ? RepsTheme.Colors.accent : RepsTheme.Colors.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                            .stroke(selectedEquipment.contains(equipment) ? Color.clear : RepsTheme.Colors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, RepsTheme.Spacing.xs)
    }
}

// MARK: - Muscle Group Picker

struct MuscleGroupPicker: View {
    @Binding var selectedMuscles: Set<MuscleGroup>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: RepsTheme.Spacing.sm) {
            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                Button {
                    if selectedMuscles.contains(muscle) {
                        selectedMuscles.remove(muscle)
                    } else {
                        selectedMuscles.insert(muscle)
                    }
                } label: {
                    Text(muscle.displayName)
                        .font(RepsTheme.Typography.caption)
                        .fontWeight(selectedMuscles.contains(muscle) ? .semibold : .regular)
                        .foregroundStyle(selectedMuscles.contains(muscle) ? RepsTheme.Colors.background : RepsTheme.Colors.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RepsTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                                .fill(selectedMuscles.contains(muscle) ? RepsTheme.Colors.accent : RepsTheme.Colors.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                                .stroke(selectedMuscles.contains(muscle) ? Color.clear : RepsTheme.Colors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, RepsTheme.Spacing.xs)
    }
}

// MARK: - Markdown Text View

struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        if let attributedString = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributedString)
                .lineSpacing(4)
        } else {
            Text(text)
                .lineSpacing(4)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(
            name: "Barbell Back Squat",
            muscleGroups: [.quads, .glutes, .hamstrings],
            equipment: [.barbell],
            instructions: "**Setup**: Position the barbell on your upper back\n\n1. Stand with feet *shoulder-width* apart\n2. Descend by pushing hips back and bending knees\n3. Lower until thighs are parallel to floor\n4. Drive through heels to return to standing",
            videoURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            isCustom: false
        ))
    }
    .preferredColorScheme(.dark)
}
