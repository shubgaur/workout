import SwiftUI

/// Multi-select day of week picker with chip-style buttons
struct DayOfWeekPicker: View {
    @Binding var selectedDays: [Int]  // 0=Sun, 1=Mon, ... 6=Sat

    private let days = [
        (0, "S", "Sun"),
        (1, "M", "Mon"),
        (2, "T", "Tue"),
        (3, "W", "Wed"),
        (4, "T", "Thu"),
        (5, "F", "Fri"),
        (6, "S", "Sat")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.0) { day in
                DayChip(
                    letter: day.1,
                    fullName: day.2,
                    isSelected: selectedDays.contains(day.0)
                )
                .onTapGesture {
                    toggleDay(day.0)
                }
            }
        }
    }

    private func toggleDay(_ day: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedDays.contains(day) {
                selectedDays.removeAll { $0 == day }
            } else {
                selectedDays.append(day)
                selectedDays.sort()
            }
        }
    }
}

struct DayChip: View {
    let letter: String
    let fullName: String
    let isSelected: Bool

    var body: some View {
        Text(letter)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .white : .secondary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .accessibilityLabel("\(fullName), \(isSelected ? "selected" : "not selected")")
    }
}

#Preview {
    @Previewable @State var days: [Int] = [1, 3, 5]  // Mon, Wed, Fri
    VStack(spacing: 20) {
        Text("Training Days")
            .font(.headline)
        DayOfWeekPicker(selectedDays: $days)
        Text("Selected: \(ScheduleService.formatScheduledDays(days))")
            .font(.caption)
    }
    .padding()
}
