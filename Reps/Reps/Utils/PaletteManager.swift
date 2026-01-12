import SwiftUI
import PhotosUI

// MARK: - Palette Manager

/// Manages active color palette and user preferences
/// Note: Thread-safe for UI access via @Published; only accessed from main thread in practice
final class PaletteManager: ObservableObject {
    static let shared = PaletteManager()

    @Published private(set) var activePalette: Palette = .dark
    @Published private(set) var customPalettes: [Palette] = []
    @Published var isGenerating: Bool = false

    private let userDefaultsKey = "activePaletteId"
    private let customPalettesKey = "customPalettes"

    private init() {
        loadSavedPalette()
        loadCustomPalettes()
    }

    // MARK: - Palette Selection

    func selectPalette(_ palette: Palette) {
        activePalette = palette
        savePalette(palette)
        HapticManager.filterSelected()
    }

    func selectPreset(_ preset: Palette) {
        selectPalette(preset)
    }

    // MARK: - Photo Import

    func generatePalettesFromPhoto(_ image: UIImage) async {
        isGenerating = true
        defer { isGenerating = false }

        let newPalettes = await Palette.generatePalettes(from: image)

        // Add to custom palettes (limit to 24)
        for palette in newPalettes {
            if !customPalettes.contains(where: { $0.id == palette.id }) {
                customPalettes.append(palette)
            }
        }

        // Trim to max
        if customPalettes.count > 24 {
            customPalettes = Array(customPalettes.suffix(24))
        }

        saveCustomPalettes()

        // Auto-select first generated palette
        if let first = newPalettes.first {
            selectPalette(first)
        }
    }

    // MARK: - Persistence

    private func savePalette(_ palette: Palette) {
        if let data = try? JSONEncoder().encode(palette) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadSavedPalette() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let palette = try? JSONDecoder().decode(Palette.self, from: data) else {
            return
        }
        activePalette = palette
    }

    private func saveCustomPalettes() {
        if let data = try? JSONEncoder().encode(customPalettes) {
            UserDefaults.standard.set(data, forKey: customPalettesKey)
        }
    }

    private func loadCustomPalettes() {
        guard let data = UserDefaults.standard.data(forKey: customPalettesKey),
              let palettes = try? JSONDecoder().decode([Palette].self, from: data) else {
            return
        }
        customPalettes = palettes
    }

    // MARK: - Clear Custom

    func clearCustomPalettes() {
        customPalettes = []
        saveCustomPalettes()

        // Reset to default if active was custom
        if !Palette.allPresets.contains(where: { $0.id == activePalette.id }) {
            selectPalette(.dark)
        }
    }
}

// MARK: - Photo Picker Helper

struct PhotoPalettePickerView: View {
    @ObservedObject var paletteManager: PaletteManager = .shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            // Photo picker button
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: RepsTheme.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 16))

                    Text("Generate from Photo")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(RepsTheme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, RepsTheme.Spacing.md)
                .background(RepsTheme.Colors.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await paletteManager.generatePalettesFromPhoto(image)
                    }
                }
            }

            // Loading indicator
            if paletteManager.isGenerating {
                HStack(spacing: RepsTheme.Spacing.sm) {
                    ProgressView()
                        .tint(RepsTheme.Colors.accent)

                    Text("Extracting colors...")
                        .font(.system(size: 13))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Palette Selection Grid

struct PaletteSelectionGrid: View {
    @ObservedObject var paletteManager: PaletteManager = .shared
    let columns = [
        GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
        GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
        GridItem(.flexible(), spacing: RepsTheme.Spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            // Preset palettes
            Text("PRESETS")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            LazyVGrid(columns: columns, spacing: RepsTheme.Spacing.sm) {
                ForEach(Palette.allPresets) { palette in
                    PalettePreviewCell(
                        palette: palette,
                        isSelected: paletteManager.activePalette.id == palette.id
                    ) {
                        paletteManager.selectPalette(palette)
                    }
                }
            }

            // Custom palettes
            if !paletteManager.customPalettes.isEmpty {
                HStack {
                    Text("MAGIC PALETTES")
                        .font(RepsTheme.Typography.label)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    Spacer()

                    Button("Clear") {
                        paletteManager.clearCustomPalettes()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RepsTheme.Colors.textTertiary)
                }

                LazyVGrid(columns: columns, spacing: RepsTheme.Spacing.sm) {
                    ForEach(paletteManager.customPalettes) { palette in
                        PalettePreviewCell(
                            palette: palette,
                            isSelected: paletteManager.activePalette.id == palette.id
                        ) {
                            paletteManager.selectPalette(palette)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Palette Preview Cell

struct PalettePreviewCell: View {
    let palette: Palette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: RepsTheme.Spacing.xs) {
                // Color preview
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(palette.background)
                    Rectangle()
                        .fill(palette.accent)
                    Rectangle()
                        .fill(palette.secondary)
                }
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )

                // Name
                Text(palette.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? RepsTheme.Colors.text : RepsTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ScalingPressButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        PhotoPalettePickerView()
        PaletteSelectionGrid()
    }
    .padding()
    .background(RepsTheme.Colors.background)
}
