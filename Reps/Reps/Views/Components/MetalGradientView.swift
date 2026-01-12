import SwiftUI
import MetalKit
import UIKit

/// GPU-accelerated animated gradient view using Metal shader
/// Displays dynamic, organic fluid motion using palette-based color schemes
struct MetalGradientView: UIViewRepresentable {
    var palette: Palette?
    var speed: Float = 0.75
    var brightness: Float = 0.5  // 0.0-1.0: default subtle for background use
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()

        // Setup Metal device and command queue
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal: Unable to create system default device")
            return mtkView
        }

        mtkView.device = device
        mtkView.isPaused = false  // Start running, updateUIView will pause if needed
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        NSLog("Metal: makeUIView called, reduceMotion=%d", reduceMotion ? 1 : 0)

        // Opaque Metal view renders animated gradient
        mtkView.isOpaque = true
        mtkView.layer.isOpaque = true
        mtkView.backgroundColor = .black
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Setup delegate
        let delegate = MetalGradientDelegate(device: device, palette: palette, speed: speed, brightness: brightness)
        mtkView.delegate = delegate

        // Store delegate and mtkView reference in coordinator
        context.coordinator.delegate = delegate
        context.coordinator.mtkView = mtkView

        NSLog("Metal: makeUIView done, initial bounds=%.0fx%.0f drawableSize=%.0fx%.0f",
              mtkView.bounds.width, mtkView.bounds.height,
              mtkView.drawableSize.width, mtkView.drawableSize.height)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update palette, speed, and brightness if needed
        context.coordinator.delegate?.palette = palette
        context.coordinator.delegate?.speed = speed
        context.coordinator.delegate?.brightness = brightness

        // Respect Reduce Motion accessibility setting
        uiView.isPaused = reduceMotion
    }

    static func dismantleUIView(_ uiView: MTKView, coordinator: Coordinator) {
        uiView.isPaused = true
        uiView.delegate = nil
        coordinator.cleanup()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        fileprivate var delegate: MetalGradientDelegate?
        weak var mtkView: MTKView?
        private var observers: [NSObjectProtocol] = []

        init() {
            // Pause when app enters background to save battery
            observers.append(NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.mtkView?.isPaused = true
            })

            // Resume when app enters foreground
            observers.append(NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.mtkView?.isPaused = false
            })

            // Throttle to 30fps in Low Power Mode for battery savings
            observers.append(NotificationCenter.default.addObserver(
                forName: .NSProcessInfoPowerStateDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.mtkView?.preferredFramesPerSecond =
                    ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
            })
        }

        func cleanup() {
            delegate = nil
        }

        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }
}

// MARK: - Metal Rendering Delegate

fileprivate class MetalGradientDelegate: NSObject, MTKViewDelegate {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var samplerState: MTLSamplerState?
    var startTime = Date()
    var palette: Palette?
    var speed: Float = 1.0
    var brightness: Float = 0.5
    var hasLoggedFirstDraw = false

    struct Uniforms {
        var time: Float = 0
        var page: Int32 = 0  // 0-3 based on palette
        var brightness: Float = 0.5  // Must match Metal shader layout
        var _padding: Float = 0  // Align float3 to 16-byte boundary
        var accentColor: simd_float3 = simd_float3(1, 0.33, 0)
        var backgroundColor: simd_float3 = simd_float3(0, 0, 0)
        var secondaryColor: simd_float3 = simd_float3(0.5, 0.5, 0.5)
    }

    /// Map palette to gradient page (0-3)
    /// - Page 0: Orange/Red (Dark, Sunset, Ember)
    /// - Page 1: Blue/Cyan (Ocean, Midnight)
    /// - Page 2: Teal/Green (Forest)
    /// - Page 3: Vibrant multi (Custom/Magic palettes)
    private var gradientPage: Int32 {
        guard let palette = palette ?? PaletteManager.shared.activePalette as Palette? else {
            return 0
        }

        switch palette.name {
        case "Dark", "Sunset", "Ember":
            return 0  // Orange/red
        case "Ocean", "Midnight":
            return 1  // Blue/cyan
        case "Forest":
            return 2  // Teal/green
        default:
            // For custom/magic palettes, detect based on accent hue
            let uiColor = UIColor(palette.accent)
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

            // Map hue to page
            if h < 0.1 || h > 0.9 {
                return 0  // Red/orange hue
            } else if h >= 0.1 && h < 0.45 {
                return 2  // Green/teal hue
            } else if h >= 0.45 && h < 0.75 {
                return 1  // Blue/cyan hue
            } else {
                return 3  // Pink/purple → vibrant multi
            }
        }
    }

    init(device: MTLDevice, palette: Palette?, speed: Float, brightness: Float) {
        self.device = device
        self.palette = palette
        self.speed = speed
        self.brightness = brightness

        super.init()

        self.commandQueue = device.makeCommandQueue()
        setupRenderPipeline()
    }

    private func setupRenderPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            print("Metal: Failed to create library - ensure animated-gradient.metal is in Xcode project build")
            return
        }

        guard let vertexFn = library.makeFunction(name: "gradient_animation_vertex") else {
            print("Metal: Vertex shader 'gradient_animation_vertex' not found in library")
            return
        }

        guard let fragmentFn = library.makeFunction(name: "gradient_animation_fragment") else {
            print("Metal: Fragment shader 'gradient_animation_fragment' not found in library")
            return
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFn
        pipelineDescriptor.fragmentFunction = fragmentFn
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            NSLog("Metal: Pipeline state created successfully")
        } catch {
            NSLog("Metal: Failed to create render pipeline state: %@", error.localizedDescription)
        }

        // Setup sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        NSLog("Metal: drawableSizeWillChange to %.0fx%.0f", size.width, size.height)
    }

    func draw(in view: MTKView) {
        // Get drawable once to avoid race condition
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let pipelineState = pipelineState else {
            return
        }

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // Debug: log first successful draw
        if !hasLoggedFirstDraw {
            hasLoggedFirstDraw = true
            NSLog("Metal: First successful draw! drawableSize=%.0fx%.0f page=%d",
                  view.drawableSize.width, view.drawableSize.height, gradientPage)
        }

        // Calculate elapsed time
        let elapsed = Float(Date().timeIntervalSince(startTime)) * speed

        // Setup render encoder
        renderEncoder.setRenderPipelineState(pipelineState)

        // Create and upload uniforms
        var uniforms = Uniforms(time: elapsed, page: gradientPage, brightness: brightness)

        // Extract colors from palette (for fallback/reference)
        if let palette = palette ?? PaletteManager.shared.activePalette as Palette? {
            let accentUIColor = UIColor(palette.accent)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            accentUIColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            uniforms.accentColor = simd_float3(Float(r), Float(g), Float(b))

            let bgUIColor = UIColor(palette.background)
            bgUIColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            uniforms.backgroundColor = simd_float3(Float(r), Float(g), Float(b))

            let secUIColor = UIColor(palette.secondary)
            secUIColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            uniforms.secondaryColor = simd_float3(Float(r), Float(g), Float(b))
        }

        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)

        // Draw fullscreen quad using packed float3 (12 bytes each, matches Metal's packed_float3)
        // Note: simd_float3 is 16 bytes due to alignment, but Metal packed_float3 is 12 bytes
        struct PackedFloat3 {
            var x: Float
            var y: Float
            var z: Float
        }
        let positions: [PackedFloat3] = [
            PackedFloat3(x: -1, y: -1, z: 0),
            PackedFloat3(x: 1, y: -1, z: 0),
            PackedFloat3(x: -1, y: 1, z: 0),
            PackedFloat3(x: 1, y: 1, z: 0)
        ]

        renderEncoder.setVertexBytes(positions, length: positions.count * MemoryLayout<PackedFloat3>.stride, index: 0)
        renderEncoder.setVertexBytes([elapsed], length: MemoryLayout<Float>.size, index: 1)

        // Use drawableSize (actual pixel dimensions) not bounds (points)
        let viewSize = simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        renderEncoder.setVertexBytes([viewSize], length: MemoryLayout<simd_float2>.size, index: 2)

        var page = gradientPage
        renderEncoder.setVertexBytes(&page, length: MemoryLayout<Int32>.size, index: 3)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

#Preview {
    VStack(spacing: 20) {
        MetalGradientView(palette: Palette.dark)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        MetalGradientView(palette: Palette.ocean)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        MetalGradientView(palette: Palette.forest)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color.black)
}
