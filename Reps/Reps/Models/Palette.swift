import SwiftUI
import UIKit

// MARK: - Palette Model

/// Dynamic color palette for Magic Palettes feature
/// Extracted from user photos or preset themes
struct Palette: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var backgroundColor: CodableColor
    var foregroundColor: CodableColor
    var accentColor: CodableColor
    var secondaryColor: CodableColor

    // Computed SwiftUI colors
    var background: Color { backgroundColor.color }
    var foreground: Color { foregroundColor.color }
    var accent: Color { accentColor.color }
    var secondary: Color { secondaryColor.color }

    // MARK: - Preset Palettes

    static let dark = Palette(
        name: "Dark",
        backgroundColor: CodableColor(.black),
        foregroundColor: CodableColor(.white),
        accentColor: CodableColor(Color(hex: "FF5500")),
        secondaryColor: CodableColor(Color(hex: "7B7B7B"))
    )

    static let midnight = Palette(
        name: "Midnight",
        backgroundColor: CodableColor(Color(hex: "0A0A0F")),
        foregroundColor: CodableColor(.white),
        accentColor: CodableColor(Color(hex: "6366F1")),
        secondaryColor: CodableColor(Color(hex: "818CF8"))
    )

    static let forest = Palette(
        name: "Forest",
        backgroundColor: CodableColor(Color(hex: "0D1F0D")),
        foregroundColor: CodableColor(.white),
        accentColor: CodableColor(Color(hex: "30D158")),
        secondaryColor: CodableColor(Color(hex: "4ADE80"))
    )

    static let ocean = Palette(
        name: "Ocean",
        backgroundColor: CodableColor(Color(hex: "0A1628")),
        foregroundColor: CodableColor(.white),
        accentColor: CodableColor(Color(hex: "0EA5E9")),
        secondaryColor: CodableColor(Color(hex: "38BDF8"))
    )

    static let sunset = Palette(
        name: "Sunset",
        backgroundColor: CodableColor(Color(hex: "1A0A0A")),
        foregroundColor: CodableColor(.white),
        accentColor: CodableColor(Color(hex: "F97316")),
        secondaryColor: CodableColor(Color(hex: "FB923C"))
    )

    static let ember = Palette(
        name: "Ember",
        backgroundColor: CodableColor(Color(hex: "1C0A00")),
        foregroundColor: CodableColor(.white),
        accentColor: CodableColor(Color(hex: "EF4444")),
        secondaryColor: CodableColor(Color(hex: "F87171"))
    )

    static let allPresets: [Palette] = [.dark, .midnight, .forest, .ocean, .sunset, .ember]
}

// MARK: - Codable Color Wrapper

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - Color Extraction

extension Palette {
    /// Generate palettes from an image using dominant colors
    static func generatePalettes(from image: UIImage) async -> [Palette] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let colors = extractDominantColors(from: image, count: 8)
                var palettes: [Palette] = []

                for (index, color) in colors.enumerated() {
                    // Ensure minimum brightness for background
                    let darkened = darkenColor(color, factor: 0.15)
                    let accent = adjustSaturation(color, factor: 1.2)

                    let palette = Palette(
                        name: "Magic \(index + 1)",
                        backgroundColor: CodableColor(Color(uiColor: darkened)),
                        foregroundColor: CodableColor(.white),
                        accentColor: CodableColor(Color(uiColor: accent)),
                        secondaryColor: CodableColor(Color(uiColor: color).opacity(0.7))
                    )
                    palettes.append(palette)
                }

                continuation.resume(returning: palettes)
            }
        }
    }

    /// Extract dominant colors from image
    private static func extractDominantColors(from image: UIImage, count: Int) -> [UIColor] {
        guard let cgImage = image.cgImage else { return [] }

        let width = 50  // Sample at low resolution
        let height = 50
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var colorCounts: [UInt32: Int] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = pointer[offset]
                let g = pointer[offset + 1]
                let b = pointer[offset + 2]

                // Quantize colors to reduce palette
                let qr = (r / 32) * 32
                let qg = (g / 32) * 32
                let qb = (b / 32) * 32

                let key = (UInt32(qr) << 16) | (UInt32(qg) << 8) | UInt32(qb)
                colorCounts[key, default: 0] += 1
            }
        }

        // Sort by frequency and take top colors
        let sorted = colorCounts.sorted { $0.value > $1.value }
        let topColors = sorted.prefix(count).map { key, _ -> UIColor in
            let r = CGFloat((key >> 16) & 0xFF) / 255.0
            let g = CGFloat((key >> 8) & 0xFF) / 255.0
            let b = CGFloat(key & 0xFF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }

        return Array(topColors)
    }

    /// Darken a color by factor (0-1)
    private static func darkenColor(_ color: UIColor, factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * factor, alpha: a)
    }

    /// Adjust saturation
    private static func adjustSaturation(_ color: UIColor, factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(s * factor, 1.0), brightness: b, alpha: a)
    }
}

// Note: Color.init(hex:) is defined in RepsTheme.swift
