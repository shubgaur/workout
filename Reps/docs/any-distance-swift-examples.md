# Any Distance - Swift Code Examples Reference

> Source: [Any Distance Goes Open Source](https://www.spottedinprod.com/p/any-distance-goes-open-source) by Dan Kuntz
> Open Source Repository: [GitHub](https://github.com/AnyDistance/any-distance)

These are excellent examples of well-executed Swift code from Any Distance, a fitness tracker app. Use these as reference for high-quality iOS implementations.

---

## Table of Contents

1. [Gradient Animation (Metal)](#gradient-animation-metal)
2. [3D Routes (SceneKit)](#3d-routes)
3. [3-2-1 Go Animation](#3-2-1-go-animation)
4. [Goal Picker](#goal-picker)
5. [3D Medals](#3d-medals)
6. [3D Sneakers](#3d-sneakers)
7. [Tap & Hold To Stop Animation](#tap--hold-to-stop-animation)
8. [Access Code Field](#access-code-field)
9. [Custom MapKit Overlay Renderer](#custom-mapkit-overlay-renderer)
10. [Fake UIAlertView](#fake-uialertview)
11. [Health Connect Animation (2021)](#health-connect-animation-2021)
12. [Nice Confetti](#nice-confetti)
13. [Recent Photo Picker](#recent-photo-picker)
14. [Vertical Picker](#vertical-picker)
15. [Share Asset Generation](#share-asset-generation)
16. [Header With Progressive Blur](#header-with-progressive-blur)
17. [Custom Refresh Control](#custom-refresh-control)
18. [Onboarding Carousel (2022)](#onboarding-carousel-2022)
19. [Scrubbable Line Graph](#scrubbable-line-graph)
20. [Made With Soul In Atlanta](#made-with-soul-in-atlanta)

---

## Gradient Animation (Metal)

**Key Technique:** GPU-accelerated animated gradient using Metal shaders with organic blob motion.

```metal
#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

struct VertexIn {
    float2 position;
};

struct VertexOut {
    float4 position [[position]];
    float time;
    float2 viewSize;
    int page;
};

struct Uniforms {
    int page;
};

/// Passthrough vertex shader
vertex VertexOut gradient_animation_vertex(const device packed_float3* in [[ buffer(0) ]],
                                           constant float &time [[buffer(1)]],
                                           const device packed_float2* viewSize [[buffer(2)]],
                                           constant int &page [[buffer(3)]],
                                           unsigned int vid [[ vertex_id ]]) {
    VertexOut out;
    out.position = float4(in[vid], 1);
    out.time = time + (float)page * 10.;
    out.viewSize = float2(viewSize->x, viewSize->y);
    out.page = page;
    return out;
}

float noise1(float seed1, float seed2){
    return(
           fract(seed1+12.34567*
                 fract(100.*(abs(seed1*0.91)+seed2+94.68)*
                       fract((abs(seed2*0.41)+45.46)*
                             fract((abs(seed2)+757.21)*
                                   fract(seed1*0.0171))))))
    * 1.0038 - 0.00185;
}

float noise2(float seed1, float seed2, float seed3){
    float buff1 = abs(seed1+100.81) + 1000.3;
    float buff2 = abs(seed2+100.45) + 1000.2;
    float buff3 = abs(noise1(seed1, seed2)+seed3) + 1000.1;
    buff1 = (buff3*fract(buff2*fract(buff1*fract(buff2*0.146))));
    buff2 = (buff2*fract(buff2*fract(buff1+buff2*fract(buff3*0.52))));
    buff1 = noise1(buff1, buff2);
    return(buff1);
}

float noise3(float seed1, float seed2, float seed3) {
    float buff1 = abs(seed1+100.813) + 1000.314;
    float buff2 = abs(seed2+100.453) + 1000.213;
    float buff3 = abs(noise1(buff2, buff1)+seed3) + 1000.17;
    buff1 = (buff3*fract(buff2*fract(buff1*fract(buff2*0.14619))));
    buff2 = (buff2*fract(buff2*fract(buff1+buff2*fract(buff3*0.5215))));
    buff1 = noise2(noise1(seed2,buff1), noise1(seed1,buff2), noise1(seed3,buff3));
    return(buff1);
}

/// Fragment shader for gradient animation
fragment float4 gradient_animation_fragment(VertexOut in [[stage_in]]) {
    float2 st = in.position.xy/in.viewSize.xy;
    st = float2(tan(st.x), sin(st.y));

    st.x += (sin(in.time/2.1)+2.0)*0.12*sin(sin(st.y*st.x+in.time/6.0)*8.2);
    st.y -= (cos(in.time/1.73)+2.0)*0.12*cos(st.x*st.y*5.1-in.time/4.0);

    float3 bg = float3(0.0);

    float3 color1;
    float3 color2;
    float3 color3;
    float3 color4;
    float3 color5;

    if (in.page == 0) {
        color1 = float3(252.0/255.0, 60.0/255.0, 0.0/255.0);
        color2 = float3(253.0/255.0, 0.0/255.0, 12.0/255.0);
        color3 = float3(26.0/255.0, 0.5/255.0, 6.0/255.0);
        color4 = float3(128.0/255.0, 0.0/255.0, 17.0/255.0);
        color5 = float3(255.0/255.0, 15.0/255.0, 8.0/255.0);
    } else if (in.page == 1) {
        color1 = float3(183.0/255.0, 246.0/255.0, 254.0/255.0);
        color2 = float3(50.0/255.0, 160.0/255.0, 251.0/255.0);
        color3 = float3(3.0/255.0, 79.0/255.0, 231.0/255.0);
        color4 = float3(1.0/255.0, 49.0/255.0, 161.0/255.0);
        color5 = float3(3.0/255.0, 12.0/255.0, 47.0/255.0);
    } else if (in.page == 2) {
        color1 = float3(102.0/255.0, 231.0/255.0, 255.0/255.0);
        color2 = float3(4.0/255.0, 207.0/255.0, 213.0/255.0);
        color3 = float3(0.0/255.0, 160.0/255.0, 119.0/255.0);
        color4 = float3(0.0/255.0, 175.0/255.0, 139.0/255.0);
        color5 = float3(2.0/255.0, 37.0/255.0, 27.0/255.0);
    } else {
        color1 = float3(255.0/255.0, 50.0/255.0, 134.0/255.0);
        color2 = float3(236.0/255.0, 18.0/255.0, 60.0/255.0);
        color3 = float3(178.0/255.0, 254.0/255.0, 0.0/255.0);
        color4 = float3(0.0/255.0, 248.0/255.0, 209.0/255.0);
        color5 = float3(0.0/255.0, 186.0/255.0, 255.0/255.0);
    }

    float mixValue = smoothstep(0.0, 0.8, distance(st,float2(sin(in.time/5.0)+0.5,sin(in.time/6.1)+0.5)));
    float3 outColor = mix(color1,bg,mixValue);

    mixValue = smoothstep(0.1, 0.9, distance(st,float2(sin(in.time/3.94)+0.7,sin(in.time/4.2)-0.1)));
    outColor = mix(color2,outColor,mixValue);

    mixValue = smoothstep(0.1, 0.8, distance(st,float2(sin(in.time/3.43)+0.2,sin(in.time/3.2)+0.45)));
    outColor = mix(color3,outColor,mixValue);

    mixValue = smoothstep(0.14, 0.89, distance(st,float2(sin(in.time/5.4)-0.3,sin(in.time/5.7)+0.7)));
    outColor = mix(color4,outColor,mixValue);

    mixValue = smoothstep(0.01, 0.89, distance(st,float2(sin(in.time/9.5)+0.23,sin(in.time/3.95)+0.23)));
    outColor = mix(color5,outColor,mixValue);

    /// ----

    mixValue = smoothstep(0.01, 0.89, distance(st,float2(cos(in.time/8.5)/2.+0.13,sin(in.time/4.95)-0.23)));
    outColor = mix(color1,outColor,mixValue);

    mixValue = smoothstep(0.1, 0.9, distance(st,float2(cos(in.time/6.94)/2.+0.7,sin(in.time/4.112)+0.66)));
    outColor = mix(color2,outColor,mixValue);

    mixValue = smoothstep(0.1, 0.8, distance(st,float2(cos(in.time/4.43)/2.+0.2,sin(in.time/6.2)+0.85)));
    outColor = mix(color3,outColor,mixValue);

    mixValue = smoothstep(0.14, 0.89, distance(st,float2(cos(in.time/10.4)/2.-0.3,sin(in.time/5.7)+0.8)));
    outColor = mix(color4,outColor,mixValue);

    mixValue = smoothstep(0.01, 0.89, distance(st,float2(cos(in.time/4.5)/2.+0.63,sin(in.time/4.95)+0.93)));
    outColor = mix(color5,outColor,mixValue);

    float2 st_unwarped = in.position.xy/in.viewSize.xy;
    float3 noise = float3(noise3(st_unwarped.x*0.000001, st_unwarped.y*0.000001, in.time * 1e-15));
    outColor = (outColor * 0.85) - (noise * 0.1);

    return float4(outColor, 1.0);
}
```

**Notes:**
- Uses 10 Gaussian blobs (5 sin-based + 5 cos-based) that move over time
- Page-based color scheme selection (0-3) for different palettes
- Domain warping for organic motion using sin/cos transformations
- Procedural noise overlay for texture
- `smoothstep()` distance-based blending for smooth color blobs

---

## 3D Routes

**Key Technique:** SceneKit 3D route visualization with animated elevation planes.

```swift
import Foundation
import SceneKit
import SCNLine
import CoreLocation

struct RouteScene {
    let scene: SCNScene
    let camera: SCNCamera
    let lineNode: SCNLineNode
    let centerNode: SCNNode
    let dotNode: SCNNode
    let dotAnimationNode: SCNNode
    let planeNodes: [SCNNode]
    let animationDuration: TimeInterval
    let elevationMinNode: SCNNode?
    let elevationMinLineNode: SCNNode?
    let elevationMaxNode: SCNNode?
    let elevationMaxLineNode: SCNNode?
    private let forExport: Bool
    private let elevationMinTextAction: SCNAction?
    private let elevationMaxTextAction: SCNAction?

    fileprivate static let dotRadius: CGFloat = 3.0
    fileprivate static let initialFocalLength: CGFloat = 42.0
    fileprivate static let initialZoom: CGFloat = 1.0
    fileprivate var minElevation: CLLocationDistance = 0.0
    fileprivate var maxElevation: CLLocationDistance = 0.0
    fileprivate var minElevationPoint = SCNVector3(0, 1000, 0)
    fileprivate var maxElevationPoint = SCNVector3(0, -1000, 0)

    var zoom: CGFloat = 1.0 {
        didSet {
            camera.focalLength = Self.initialFocalLength * zoom
        }
    }

    var palette: Palette {
        didSet {
            lineNode.geometry?.firstMaterial?.diffuse.contents = palette.foregroundColor

            let darkeningPercentage: CGFloat = forExport ? 0.0 : 35.0
            let alpha = (palette.foregroundColor.isReallyDark ? 0.8 : 0.5) + (forExport ? 0.2 : 0.0)
            let color = palette.foregroundColor.darker(by: darkeningPercentage)?.withAlphaComponent(alpha)
            for plane in planeNodes {
                plane.geometry?.firstMaterial?.diffuse.contents = color
            }

            dotNode.geometry?.firstMaterial?.diffuse.contents = palette.accentColor
            dotAnimationNode.geometry?.firstMaterial?.diffuse.contents = palette.accentColor

            elevationMinNode?.geometry?.firstMaterial?.diffuse.contents = palette.foregroundColor.lighter(by: 15.0)
            elevationMinLineNode?.geometry?.firstMaterial?.diffuse.contents = palette.foregroundColor.lighter(by: 15.0)
            elevationMaxNode?.geometry?.firstMaterial?.diffuse.contents = palette.foregroundColor.lighter(by: 15.0)
            elevationMaxLineNode?.geometry?.firstMaterial?.diffuse.contents = palette.foregroundColor.lighter(by: 15.0)
        }
    }
}
```

**Notes:**
- Uses SCNLineNode (low poly cylinders) for route lines
- Elevation planes use constant lighting model with replace blend mode
- SCNAction sequences for animated elevation labels
- Custom text counting animation using SCNAction.customAction
- Keyframe animation for dot movement along path

---

## 3-2-1 Go Animation

**Key Technique:** SwiftUI countdown with stacked modifiers for complex animations.

```swift
import SwiftUI

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct CountdownView: View {
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let startGenerator = UINotificationFeedbackGenerator()

    @State private var animationStep: CGFloat = 4
    @State private var animationTimer: Timer?
    @State private var isFinished: Bool = false
    @Binding var skip: Bool
    var finishedAction: () -> Void

    func hStackXOffset() -> CGFloat {
        let clampedStep = animationStep.clamped(to: 0...3)
        if clampedStep > 0 {
            return 60 * (clampedStep - 1) - 10
        } else {
            return -90
        }
    }

    func startTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true, block: { _ in
            if animationStep == 0 {
                withAnimation(.easeIn(duration: 0.15)) {
                    isFinished = true
                }
                finishedAction()
                animationTimer?.invalidate()
            }

            withAnimation(.easeInOut(duration: animationStep == 4 ? 0.3 : 0.4)) {
                animationStep -= 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if animationStep < 4 && animationStep > 0 {
                    impactGenerator.impactOccurred()
                } else if animationStep == 0 {
                    startGenerator.notificationOccurred(.success)
                }
            }
        })
    }

    var body: some View {
        VStack {
            ZStack {
                DarkBlurView()

                HStack(alignment: .center, spacing: 0) {
                    Text("3")
                        .font(.system(size: 89, weight: .semibold, design: .default))
                        .frame(width: 60)
                        .opacity(animationStep >= 3 ? 1 : 0.6)
                        .scaleEffect(animationStep >= 3 ? 1 : 0.6)
                    Text("2")
                        .font(.system(size: 89, weight: .semibold, design: .default))
                        .frame(width: 60)
                        .opacity(animationStep == 2 ? 1 : 0.6)
                        .scaleEffect(animationStep == 2 ? 1 : 0.6)
                    Text("1")
                        .font(.system(size: 89, weight: .semibold, design: .default))
                        .frame(width: 60)
                        .opacity(animationStep == 1 ? 1 : 0.6)
                        .scaleEffect(animationStep == 1 ? 1 : 0.6)
                    Text("GO")
                        .font(.system(size: 65, weight: .bold, design: .default))
                        .frame(width: 100)
                        .opacity(animationStep == 0 ? 1 : 0.6)
                        .scaleEffect(animationStep == 0 ? 1 : 0.6)
                }
                .foregroundStyle(Color.white)
                .offset(x: hStackXOffset())
            }
            .mask {
                RoundedRectangle(cornerRadius: 65)
                    .frame(width: 130, height: 200)
            }
            .opacity(isFinished ? 0 : 1)
            .scaleEffect(isFinished ? 1.2 : 1)
            .blur(radius: isFinished ? 6.0 : 0.0)
            .opacity(animationStep < 4 ? 1 : 0)
            .scaleEffect(animationStep < 4 ? 1 : 0.8)
        }
        .onChange(of: skip) { newValue in
            if newValue == true {
                animationTimer?.invalidate()
                withAnimation(.easeIn(duration: 0.15)) {
                    isFinished = true
                }
                finishedAction()
            }
        }
        .onAppear {
            guard animationStep == 4 else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.startTimer()
            }
        }
    }
}
```

**Notes:**
- Timer-driven animation state changes
- Haptic feedback coordination with visual state
- Stacked modifiers (scaleEffect, opacity, blur) for complex effects
- Masked HStack for spotlight-style reveal

---

## Nice Confetti

**Key Technique:** SpriteKit CAEmitterLayer with extensive randomization.

```swift
import UIKit
import QuartzCore

public final class ConfettiView: UIView {
    public var colors = GoalProgressIndicator().trackGradientColors
    public var intensity: Float = 0.8
    public var style: ConfettiViewStyle = .large

    private(set) var emitter: CAEmitterLayer?
    private var active = false
    private var image = UIImage(named: "confetti")?.cgImage

    public func startConfetti(beginAtTimeZero: Bool = true) {
        emitter?.removeFromSuperlayer()
        emitter = CAEmitterLayer()

        if beginAtTimeZero {
            emitter?.beginTime = CACurrentMediaTime()
        }

        emitter?.emitterPosition = CGPoint(x: frame.size.width / 2.0, y: -10)
        emitter?.emitterShape = .line
        emitter?.emitterSize = CGSize(width: frame.size.width, height: 1)

        var cells = [CAEmitterCell]()
        for color in colors {
            cells.append(confettiWithColor(color: color))
        }

        emitter?.emitterCells = cells

        switch style {
        case .large:
            emitter?.birthRate = 4
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.emitter?.birthRate = 0.6
            }
        case .small:
            emitter?.birthRate = 0.35
        }

        layer.addSublayer(emitter!)
        active = true
    }

    func confettiWithColor(color: UIColor) -> CAEmitterCell {
        let confetti = CAEmitterCell()
        confetti.birthRate = 12.0 * intensity
        confetti.lifetime = 14.0 * intensity
        confetti.lifetimeRange = 0
        confetti.color = color.cgColor
        confetti.velocity = CGFloat(350.0 * intensity)
        confetti.velocityRange = CGFloat(80.0 * intensity)
        confetti.emissionLongitude = CGFloat(Double.pi)
        confetti.emissionRange = CGFloat(Double.pi)
        confetti.spin = CGFloat(3.5 * intensity)
        confetti.spinRange = CGFloat(4.0 * intensity)
        confetti.scaleRange = CGFloat(intensity)
        confetti.scaleSpeed = CGFloat(-0.1 * intensity)
        confetti.contents = image
        confetti.contentsScale = 1.5
        confetti.setValue("plane", forKey: "particleType")
        confetti.setValue(Double.pi, forKey: "orientationRange")
        confetti.setValue(Double.pi / 2, forKey: "orientationLongitude")
        confetti.setValue(Double.pi / 2, forKey: "orientationLatitude")

        if style == .small {
            confetti.contentsScale = 3.0
            confetti.velocity = CGFloat(70.0 * intensity)
            confetti.velocityRange = CGFloat(20.0 * intensity)
        }

        return confetti
    }
}
```

**Notes:**
- Uses CAEmitterCell's randomization properties extensively
- Orientation transforms make confetti look natural
- Dynamic birthRate adjustment for burst-then-settle effect
- Intensity parameter scales all physics values proportionally

---

## Header With Progressive Blur

**Key Technique:** Private CAFilter API for variable blur effect.

```swift
import SwiftUI
import UIKit

public enum VariableBlurDirection {
    case blurredTopClearBottom
    case blurredBottomClearTop
}

open class VariableBlurUIView: UIVisualEffectView {
    public init(maxBlurRadius: CGFloat = 20,
                direction: VariableBlurDirection = .blurredTopClearBottom,
                startOffset: CGFloat = 0) {
        super.init(effect: UIBlurEffect(style: .regular))

        // Same but no need for `CAFilter.h`.
        let CAFilter = NSClassFromString("CAFilter")! as! NSObject.Type
        let variableBlur = CAFilter.self.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur").takeUnretainedValue() as! NSObject

        // The blur radius at each pixel depends on the alpha value of the corresponding pixel in the gradient mask.
        // An alpha of 1 results in the max blur radius, while an alpha of 0 is completely unblurred.
        let gradientImage = direction == .blurredTopClearBottom ? UIImage(named: "layout_top_gradient")?.cgImage : UIImage(named: "layout_gradient")?.cgImage

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImage, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // We use a `UIVisualEffectView` here purely to get access to its `CABackdropLayer`,
        // which is able to apply various, real-time CAFilters onto the views underneath.
        let backdropLayer = subviews.first?.layer

        // Replace the standard filters (i.e. `gaussianBlur`, `colorSaturate`, etc.) with only the variableBlur.
        backdropLayer?.filters = [variableBlur]

        // Get rid of the visual effect view's dimming/tint view, so we don't see a hard line.
        for subview in subviews.dropFirst() {
            subview.alpha = 0
        }
    }
}
```

**Notes:**
- Uses private CAFilter API for variable blur
- Gradient mask controls blur intensity per-pixel
- CABackdropLayer applies real-time filters to underlying views
- Removes dimming view to avoid hard edges

---

## SwiftUI Gradient Animation

**Key Technique:** SwiftUI animated blurred ellipses for organic motion.

```swift
fileprivate struct GradientAnimation: View {
    @Binding var animate: Bool

    private func rand18(_ idx: Int) -> [Float] {
        let idxf = Float(idx)
        return [sin(idxf * 6.3),
                cos(idxf * 1.3 + 48),
                sin(idxf + 31.2),
                cos(idxf * 44.1),
                sin(idxf * 3333.2),
                cos(idxf + 1.12 * pow(idxf, 3)),
                sin(idxf * 22),
                cos(idxf * 34)]
    }

    var body: some View {
        ZStack {
            ForEach(Array(0...50), id: \.self) { idx in
                let rands = rand18(idx)
                let fill = Color(hue: sin(Double(idx) * 5.12) + 1.1, saturation: 1, brightness: 1)

                Ellipse()
                    .fill(fill)
                    .frame(width: CGFloat(rands[1] + 2.0) * 50.0, height: CGFloat(rands[2] + 2.0) * 40.0)
                    .blur(radius: 25.0 + CGFloat(rands[1] + rands[2]) / 2)
                    .opacity(0.8)
                    .offset(x: CGFloat(animate ? rands[3] * 150.0 : rands[4] * 150.0),
                            y: CGFloat(animate ? rands[5] * 50.0 : rands[6] * 50.0))
                    .animation(.easeInOut(duration: TimeInterval(rands[7] + 3.0) * 1.3).repeatForever(autoreverses: true),
                               value: animate)
            }
        }
        .offset(y: 0)
        .onAppear {
            animate = true
        }
    }
}
```

**Notes:**
- Deterministic randomization using sin/cos with index
- Varying size, blur, position, and animation duration
- `.repeatForever(autoreverses: true)` for continuous motion
- 50+ ellipses create soupy rainbow effect

---

## Custom MapKit Overlay Renderer

**Key Technique:** CADisplayLink-driven polyline stroke animation.

```swift
@objc func displayLinkFire() {
    if polylineProgress <= 1 {
        for overlay in mkView!.overlays {
            if !overlay.boundingMapRect.intersects(mkView?.visibleMapRect ?? MKMapRect()) {
                continue
            }

            if let polylineRenderer = mkView!.renderer(for: overlay) as? MKPolylineRenderer {
                polylineRenderer.strokeEnd = RouteScene.easeOutQuad(x: polylineProgress).clamped(to: 0...1)
                polylineRenderer.strokeColor = polylineProgress <= 0.01 ? .clear : lineColor
                polylineRenderer.blendMode = .destinationAtop
                polylineRenderer.setNeedsDisplay()
            }
        }

        polylineProgress += 0.01
    }
}
```

**Notes:**
- CADisplayLink forces redraw every frame
- Updates strokeEnd property for animation
- Easing function for natural motion
- Visibility check skips off-screen overlays

---

## Health Connect Animation (2021)

**Key Technique:** CADisplayLink procedural UI drawing.

```swift
@objc private func update() {
    t += 1
    incrementDots()
    spawnNewDots()
    spawnNewVerticalDots()
    setNeedsDisplay()

    if animatingTranslate {
        animProgress += 1 / translateAnimationDuration / 60
        let easedProgress = easeInOutQuart(x: animProgress)
        translateY = easedProgress * finalTranslateY
        if easedProgress >= 1 {
            animatingTranslate = false
        }
    }
}

override func draw(_ rect: CGRect) {
    let ctx = UIGraphicsGetCurrentContext()
    ctx?.translateBy(x: 0, y: headerHeight)
    ctx?.translateBy(x: 0, y: translateY)

    // Draw all elements manually at calculated positions...
}
```

**Notes:**
- 100% procedural drawing - no Auto Layout
- CADisplayLink at 60fps for smooth animation
- Manual position calculation similar to generative art
- Dots spawn and flow along curved paths

---

## Vertical Picker

**Key Technique:** UIKit gesture handling for precise touch control.

```swift
@objc func panGestureHandler(_ recognizer: UIPanGestureRecognizer) {
    if recognizer.state == .ended ||
       recognizer.state == .cancelled ||
       recognizer.state == .failed {
        contract()
        return
    }

    let location = recognizer.location(in: backgroundView)

    let closestButton = buttons.min { button1, button2 in
        let distance1 = location.distance(to: button1.center)
        let distance2 = location.distance(to: button2.center)
        return distance1 < distance2
    }

    guard let closestButton = closestButton,
              closestButton.tag != selectedIdx else {
        return
    }

    selectedIdx = closestButton.tag
    tapHandler?(closestButton.tag)
    generator.impactOccurred()
    updateButtonSelection()
}
```

**Notes:**
- Immediate engagement on touch down
- Finds closest button during drag
- Haptic feedback on selection change
- Expand/contract animations with spring physics

---

## Key Patterns & Techniques

### Animation
- **Timer-driven state changes** for choreographed sequences
- **CADisplayLink** for frame-by-frame control
- **Spring animations** for natural physics
- **Stacked modifiers** (opacity, scale, blur) for complex effects

### Graphics
- **Metal shaders** for GPU-accelerated effects
- **CoreGraphics** for runtime texture generation
- **CAEmitterLayer** for particle systems
- **SceneKit** for 3D rendering

### Interaction
- **UIPanGestureRecognizer** for precise touch handling
- **UIImpactFeedbackGenerator** synchronized with visuals
- **Custom hit testing** for out-of-bounds touch handling

### Architecture
- **UIViewRepresentable** for UIKit in SwiftUI
- **Coordinator pattern** for delegate handling
- **Protocol extensions** for shared behavior
