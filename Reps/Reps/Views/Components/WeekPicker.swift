import SwiftUI

/// Horizontal scrolling week picker with numbered pills
struct WeekPicker: View {
    let totalWeeks: Int
    @Binding var selectedWeek: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<totalWeeks, id: \.self) { week in
                        WeekPill(
                            weekNumber: week + 1,
                            isSelected: selectedWeek == week
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedWeek = week
                            }
                        }
                        .id(week)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                proxy.scrollTo(selectedWeek, anchor: .center)
            }
            .onChange(of: selectedWeek) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

struct WeekPill: View {
    let weekNumber: Int
    let isSelected: Bool

    var body: some View {
        Text("\(weekNumber)")
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
    }
}

#Preview {
    @Previewable @State var selected = 2
    VStack {
        Text("Select Week")
            .font(.headline)
        WeekPicker(totalWeeks: 12, selectedWeek: $selected)
        Text("Selected: Week \(selected + 1)")
    }
}
