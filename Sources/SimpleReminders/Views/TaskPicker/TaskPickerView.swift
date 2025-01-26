import SwiftUI
import EventKit
import AppKit

struct TaskPickerView: View {
    @ObservedObject var viewModel: TaskPickerViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Button(action: {
                        viewModel.isShowingListPicker.toggle()
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.primary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $viewModel.isShowingListPicker) {
                        ListSelectionView(viewModel: viewModel, isShowingListPicker: $viewModel.isShowingListPicker)
                    }
                    
                    CustomTextField(
                        text: $viewModel.searchText,
                        font: .systemFont(ofSize: 24, weight: .regular),
                        onEditingChanged: { isEditing in
                            isSearchFocused = isEditing
                        },
                        onEnterKey: {
                            handleTaskCreation()
                            return true
                        },
                        onArrowUp: {
                            viewModel.moveSelectionUp()
                        },
                        onArrowDown: {
                            viewModel.moveSelectionDown()
                        },
                        viewModel: viewModel
                    )
                    .focused($isSearchFocused)
                    .onChange(of: viewModel.clickedLinkId) { _ in
                        dismiss()
                    }
                    
                    Button(action: {
                        handleTaskCreation()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(viewModel.searchText.isEmpty ? .gray.opacity(0.5) : .white)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.searchText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if viewModel.searchText.hasPrefix("#") {
                    let searchTerm = String(viewModel.searchText.dropFirst()).trimmingCharacters(in: .whitespaces)
                    let filteredLists = viewModel.availableLists.filter {
                        searchTerm.isEmpty || $0.title.localizedCaseInsensitiveContains(searchTerm)
                    }
                    if !filteredLists.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filteredLists, id: \.calendarIdentifier) { calendar in
                                    HStack {
                                        Circle()
                                            .fill(Color(nsColor: calendar.color))
                                            .frame(width: 8, height: 8)
                                        Text(calendar.title)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.2))
                                    )
                                    .onTapGesture {
                                        viewModel.selectList(calendar)
                                        viewModel.searchText = ""
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                    }
                }
                
                if let selectedListTitle = viewModel.selectedListTitle {
                    HStack {
                        Text("List: \(selectedListTitle)")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            viewModel.clearListFilter()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            ReminderListView(viewModel: viewModel) {
                dismiss()
            }
        }
        .frame(width: 600, height: 400)
        .onAppear {
            isSearchFocused = true
            viewModel.validateAndUpdateSelection()
        }
        .onSubmit {
            handleTaskCreation()
        }
    }
    
    private func handleTaskCreation() {
        Task {
            if await TaskCreationService.shared.createAndPasteTask(withText: viewModel.searchText, in: viewModel) {
                dismiss()
            }
        }
    }
}
