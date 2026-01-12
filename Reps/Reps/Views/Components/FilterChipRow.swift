import SwiftUI

// MARK: - Filter Chip Row (AnyDistance-style horizontal scrolling)

/// Horizontal scrolling row of selectable filter chips
struct FilterChipRow: View {
    @Binding var selected: String
    var options: [String]
    var showAllOption: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                if showAllOption {
                    ADFilterChip(
                        label: "All",
                        isSelected: selected == "All",
                        action: {
                            withAnimation(RepsTheme.Animations.selection) {
                                selected = "All"
                            }
                            HapticManager.filterSelected()
                        }
                    )
                }

                ForEach(options, id: \.self) { option in
                    ADFilterChip(
                        label: option,
                        isSelected: selected == option,
                        action: {
                            withAnimation(RepsTheme.Animations.selection) {
                                selected = option
                            }
                            HapticManager.filterSelected()
                        }
                    )
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
        }
    }
}

// MARK: - AD Filter Chip (AnyDistance-inspired)

struct ADFilterChip: View {
    var label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(label)
                .font(RepsTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : RepsTheme.Colors.text)
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.vertical, RepsTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : RepsTheme.Colors.surface)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(.isStaticText)
    }
}

// MARK: - Multi-Select Filter Chips

struct MultiSelectFilterChipRow: View {
    @Binding var selected: Set<String>
    var options: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    ADFilterChip(
                        label: option,
                        isSelected: selected.contains(option),
                        action: {
                            withAnimation(RepsTheme.Animations.selection) {
                                if selected.contains(option) {
                                    selected.remove(option)
                                } else {
                                    selected.insert(option)
                                }
                            }
                            HapticManager.filterSelected()
                        }
                    )
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
        }
    }
}

// MARK: - Icon Filter Chip

struct IconFilterChip: View {
    var icon: String
    var label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: RepsTheme.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(label)
                    .font(RepsTheme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .black : RepsTheme.Colors.text)
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.vertical, RepsTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white : RepsTheme.Colors.surface)
            )
        }
        .buttonStyle(ScalingPressButtonStyle(scale: 0.97, opacity: 0.9))
    }
}

// MARK: - Segmented Control Style

struct SegmentedFilterRow: View {
    @Binding var selected: Int
    var options: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    withAnimation(RepsTheme.Animations.segment) {
                        selected = index
                    }
                    HapticManager.filterSelected()
                } label: {
                    Text(option)
                        .font(RepsTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selected == index ? .black : RepsTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RepsTheme.Spacing.xs)
                        .background(
                            selected == index ?
                            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                                .fill(Color.white)
                            : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(RepsTheme.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm + RepsTheme.Spacing.xxs)
                .fill(RepsTheme.Colors.surface)
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        FilterChipRow(
            selected: .constant("Chest"),
            options: ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core"]
        )

        SegmentedFilterRow(
            selected: .constant(1),
            options: ["Week", "Month", "Year"]
        )
        .padding(.horizontal)

        MultiSelectFilterChipRow(
            selected: .constant(["Bench Press", "Squat"]),
            options: ["Bench Press", "Squat", "Deadlift", "OHP"]
        )
    }
    .padding(.vertical)
    .background(RepsTheme.Colors.background)
}
