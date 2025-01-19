import SwiftUI
import EventKit

struct ReminderListView: View {
    @ObservedObject var viewModel: TaskPickerViewModel
    var onReminderSelected: () -> Void
    
    var body: some View {
        List(viewModel.filteredReminders, id: \.calendarItemIdentifier, selection: $viewModel.selectedIndex) { reminder in
            HStack {
                Circle()
                    .fill(Color(nsColor: reminder.calendar.color))
                    .frame(width: 12, height: 12)
                Text(reminder.title ?? "")
                Spacer()
                if let date = reminder.dueDateComponents?.date {
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(
                viewModel.filteredReminders.firstIndex(where: { $0.calendarItemIdentifier == reminder.calendarItemIdentifier }) == viewModel.selectedIndex
                ? Color.accentColor.opacity(0.2)
                : Color.clear
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if let index = viewModel.filteredReminders.firstIndex(where: { $0.calendarItemIdentifier == reminder.calendarItemIdentifier }) {
                    viewModel.selectedIndex = index
                    viewModel.confirmSelection()
                    onReminderSelected()
                }
            }
        }
        .listStyle(.plain)
    }
}
