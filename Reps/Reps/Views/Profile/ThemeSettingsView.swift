import SwiftUI
import PhotosUI

struct ThemeSettingsView: View {
    @ObservedObject private var paletteManager = PaletteManager.shared
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: RepsTheme.Spacing.xl) {
                // Preview
                themePreview

                // Photo picker
                photoPickerSection

                // Palette grid
                paletteGridSection
            }
            .padding(RepsTheme.Spacing.md)
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigation()
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await paletteManager.generatePalettesFromPhoto(image)
                }
            }
        }
    }

    // MARK: - Theme Preview

    private var themePreview: some View {
        VStack(spacing: RepsTheme.Spacing.sm) {
            Text("PREVIEW")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: RepsTheme.Spacing.md) {
                // Mock stat cards
                HStack(spacing: RepsTheme.Spacing.sm) {
                    previewStatCard(value: "12", label: "Workouts")
                    previewStatCard(value: "45K", label: "Volume", accent: true)
                }

                // Mock progress bar
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
                    Text("Progress")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(paletteManager.activePalette.foreground)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(paletteManager.activePalette.secondary.opacity(0.3))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(paletteManager.activePalette.accent)
                                .frame(width: geo.size.width * 0.7)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(RepsTheme.Spacing.md)
                .background(paletteManager.activePalette.background.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            }
            .padding(RepsTheme.Spacing.md)
            .background(paletteManager.activePalette.background)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.lg)
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    private func previewStatCard(value: String, label: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(accent ? paletteManager.activePalette.accent : paletteManager.activePalette.foreground)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(paletteManager.activePalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .background(paletteManager.activePalette.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    // MARK: - Photo Picker Section

    private var photoPickerSection: some View {
        VStack(spacing: RepsTheme.Spacing.sm) {
            Text("MAGIC PALETTES")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: RepsTheme.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generate from Photo")
                            .font(.system(size: 15, weight: .medium))

                        Text("Extract colors from your gym photos")
                            .font(.system(size: 12))
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                    }

                    Spacer()

                    if paletteManager.isGenerating {
                        ProgressView()
                            .tint(RepsTheme.Colors.accent)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                    }
                }
                .foregroundStyle(RepsTheme.Colors.text)
                .padding(RepsTheme.Spacing.md)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            }
            .buttonStyle(ScalingPressButtonStyle())
            .disabled(paletteManager.isGenerating)
        }
    }

    // MARK: - Palette Grid Section

    private var paletteGridSection: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            // Preset palettes
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                Text("PRESETS")
                    .font(RepsTheme.Typography.label)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: RepsTheme.Spacing.sm)
                ], spacing: RepsTheme.Spacing.sm) {
                    ForEach(Palette.allPresets) { palette in
                        PaletteCell(
                            palette: palette,
                            isSelected: paletteManager.activePalette.id == palette.id
                        ) {
                            paletteManager.selectPalette(palette)
                        }
                    }
                }
            }

            // Custom palettes
            if !paletteManager.customPalettes.isEmpty {
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                    HStack {
                        Text("GENERATED")
                            .font(RepsTheme.Typography.label)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)

                        Spacer()

                        Button {
                            paletteManager.clearCustomPalettes()
                        } label: {
                            Text("Clear All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RepsTheme.Colors.textTertiary)
                        }
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
                        GridItem(.flexible(), spacing: RepsTheme.Spacing.sm),
                        GridItem(.flexible(), spacing: RepsTheme.Spacing.sm)
                    ], spacing: RepsTheme.Spacing.sm) {
                        ForEach(paletteManager.customPalettes) { palette in
                            PaletteCell(
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
}

// MARK: - Palette Cell

private struct PaletteCell: View {
    let palette: Palette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: RepsTheme.Spacing.xs) {
                // Color bars
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(palette.background)
                    Rectangle()
                        .fill(palette.accent)
                    Rectangle()
                        .fill(palette.secondary)
                }
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                        .stroke(isSelected ? Color.white : RepsTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
                )

                // Name
                Text(palette.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? RepsTheme.Colors.text : RepsTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(ScalingPressButtonStyle())
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
}
