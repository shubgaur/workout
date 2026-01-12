import SwiftUI
#if canImport(CoreMotion)
import CoreMotion
#endif

// MARK: - Motion Manager

/// Shared manager for device motion (accelerometer) data
/// Provides unified light angle for coordinated glint effects across all views
@MainActor
final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    // MARK: - Published Properties

    /// Device pitch (forward/back tilt), normalized -1 to 1
    @Published private(set) var pitch: Double = 0

    /// Device roll (left/right tilt), normalized -1 to 1
    @Published private(set) var roll: Double = 0

    /// Unified light angle (0-360°) computed from pitch/roll
    /// All glint effects should use this for coordinated lighting
    @Published private(set) var lightAngle: Double = 0

    /// Raw pitch value scaled for parallax effects (matches legacy behavior)
    @Published private(set) var pitchScaled: Double = 0

    /// Raw roll value scaled for parallax effects (matches legacy behavior)
    @Published private(set) var rollScaled: Double = 0

    // MARK: - Private Properties

    #if canImport(CoreMotion)
    private let motionManager = CMMotionManager()
    #endif
    private var referenceCount = 0
    private var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    // MARK: - Initialization

    private init() {
        #if os(iOS)
        // Listen for Low Power Mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerModeChanged),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
        #endif
    }

    deinit {
        #if canImport(CoreMotion)
        motionManager.stopDeviceMotionUpdates()
        #endif
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    /// Start receiving motion updates (reference counted)
    /// Call this in onAppear of views that need motion data
    func startUpdates() {
        referenceCount += 1
        guard referenceCount == 1 else { return }

        #if canImport(CoreMotion)
        guard motionManager.isDeviceMotionAvailable else { return }

        let interval = isLowPowerMode ? 1.0 / 30.0 : 1.0 / 60.0
        motionManager.deviceMotionUpdateInterval = interval

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.updateMotion(motion)
        }
        #endif
    }

    /// Stop receiving motion updates (reference counted)
    /// Call this in onDisappear of views that need motion data
    func stopUpdates() {
        referenceCount -= 1
        guard referenceCount <= 0 else { return }
        referenceCount = 0

        #if canImport(CoreMotion)
        motionManager.stopDeviceMotionUpdates()
        #endif

        // Don't reset values - keep last known state for smooth resume
        // This prevents jarring resets when views temporarily disappear
    }

    // MARK: - Private Methods

    #if canImport(CoreMotion)
    private func updateMotion(_ motion: CMDeviceMotion) {
        let rawPitch = motion.attitude.pitch
        let rawRoll = motion.attitude.roll

        // Normalized values (-1 to 1)
        pitch = max(-1, min(1, rawPitch / (.pi / 2)))
        roll = max(-1, min(1, rawRoll / (.pi / 2)))

        // Scaled values for parallax (legacy compatibility)
        pitchScaled = rawPitch * 30
        rollScaled = rawRoll * 30

        // Unified light angle (0-360°)
        // atan2 gives angle in radians, convert to degrees
        let angle = atan2(rawRoll, rawPitch) * 180 / .pi
        let normalizedAngle = angle < 0 ? angle + 360 : angle
        // Invert here so shaders don't need to (fixes double-inversion bug)
        // Tilting device right should move glint right (natural feel)
        let invertedAngle = (360 - normalizedAngle).truncatingRemainder(dividingBy: 360)

        // Sensitivity multiplier - amplifies rotation for same tilt amount
        // 1.8x means small tilts cause bigger glint movement
        let sensitivity: Double = 1.8
        let targetAngle = (invertedAngle * sensitivity).truncatingRemainder(dividingBy: 360)

        // Exponential smoothing for synchronized movement across all views
        // Higher factor = snappier response, lower = smoother/slower
        // 0.15 gives ~200ms effective response time at 60Hz
        let smoothingFactor: Double = 0.15

        // Handle angle wrap-around (359° → 1° should go through 0°, not 358°)
        var delta = targetAngle - lightAngle
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        // Apply smoothing - all subscribers get identical pre-smoothed value
        lightAngle = (lightAngle + delta * smoothingFactor).truncatingRemainder(dividingBy: 360)
        if lightAngle < 0 { lightAngle += 360 }
    }
    #endif

    #if os(iOS)
    @objc private func powerModeChanged() {
        // Adjust update interval if motion is active
        guard referenceCount > 0, motionManager.isDeviceMotionActive else { return }

        let interval = isLowPowerMode ? 1.0 / 30.0 : 1.0 / 60.0
        motionManager.deviceMotionUpdateInterval = interval
    }
    #endif
}

// MARK: - View Extension

extension View {
    /// Automatically manage motion updates for this view's lifecycle
    func trackingMotion() -> some View {
        self.onAppear {
            MotionManager.shared.startUpdates()
        }
        .onDisappear {
            MotionManager.shared.stopUpdates()
        }
    }
}
