import SwiftUI
import EventKit

struct TaskPickerView: View {
    @ObservedObject var viewModel: TaskPickerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search reminders...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24))
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: viewModel.clickedLinkId) { _ in
                        dismiss()
                    }
                
                if viewModel.selectedListTitle != nil {
                    HStack {
                        Text(viewModel.selectedListTitle!)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                        
                        Button(action: {
                            viewModel.clearListFilter()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing)
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            if viewModel.isShowingLists {
                listSelectionView
            } else {
                reminderListView
            }
        }
        .frame(width: 600, height: 400)
    }
    
    private var listSelectionView: some View {
        List(viewModel.filteredLists, id: \.calendarIdentifier, selection: .constant(viewModel.selectedIndex)) { calendar in
            HStack {
                Circle()
                    .fill(Color(nsColor: calendar.color))
                    .frame(width: 12, height: 12)
                Text(calendar.title)
            }
            .listRowBackground(
                viewModel.filteredLists.firstIndex(where: { $0.calendarIdentifier == calendar.calendarIdentifier }) == viewModel.selectedIndex
                ? Color.accentColor.opacity(0.2)
                : Color.clear
            )
        }
        .listStyle(.plain)
    }
    
    private var reminderListView: some View {
        List(viewModel.filteredReminders, id: \.calendarItemIdentifier, selection: .constant(viewModel.selectedIndex)) { reminder in
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
        }
        .listStyle(.plain)
    }
}
