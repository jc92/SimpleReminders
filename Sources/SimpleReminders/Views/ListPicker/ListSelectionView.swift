import SwiftUI
import EventKit

struct ListSelectionView: View {
    @ObservedObject var viewModel: TaskPickerViewModel
    @Binding var isShowingListPicker: Bool
    
    var body: some View {
        VStack {
            TextField("Search lists...", text: $viewModel.listSearchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            List(viewModel.filteredLists, id: \.calendarIdentifier, selection: .constant(viewModel.selectedIndex)) { calendar in
                HStack {
                    Circle()
                        .fill(Color(nsColor: calendar.color))
                        .frame(width: 12, height: 12)
                    Text(calendar.title)
                    Spacer()
                    if calendar.calendarIdentifier == viewModel.selectedListId {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectList(calendar)
                    isShowingListPicker = false
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 300, height: 400)
    }
}
