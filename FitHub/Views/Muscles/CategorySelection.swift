import SwiftUI

struct CategorySelection: View {
    @EnvironmentObject var userData: UserData
    @Binding var selectedCategories: [SplitCategory]
    @State private var donePressed: Bool = false
    @State private var showFrontView: Bool = true
    @State private var showSaveChangesAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    var onSave: ([SplitCategory]) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 3) {
                    ForEach(0..<3) { column in
                        HStack(spacing: 6) {
                            ForEach(SplitCategory.columnGroups[column], id: \.self) { muscleGroup in
                                MuscleGroupButton(muscleGroup: muscleGroup, selections: $selectedCategories, disabled: shouldDisable(muscleGroup))
                            }
                        }
                    }
                }
                .padding(.horizontal, -10)
                
                Text("Select Categories for Template")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                GeometryReader { geometry in
                    ZStack {
                        SimpleMuscleGroupsView(selectedSplit: selectedCategories, showFront: $showFrontView)
                            .frame(width: geometry.size.width, height: 600)
                            .padding(.top, -25)
                            .centerHorizontally()
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showFrontView.toggle()
                                }) {
                                    Image(systemName: "arrow.2.circlepath")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 20)
                                .padding(.top, -100)
                            }
                        }
                    }
                }
                .frame(height: 550)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Customize Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave(selectedCategories)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func MuscleGroupButton(muscleGroup: SplitCategory, selections: Binding<[SplitCategory]>, disabled: Bool) -> some View {
        let isLegFocused = selections.wrappedValue.contains(.legs) && muscleGroup.isLegCategory()
        let shouldShow = !(isLegFocused && selections.wrappedValue.contains(muscleGroup))
        
        if shouldShow {
            Button(action: {
                toggleSelection(for: muscleGroup, in: selections)
            }) {
                Text(displayName(for: muscleGroup, with: selections.wrappedValue))
                    .padding(5)
                    .frame(minWidth: 50, minHeight: 35)
                    .minimumScaleFactor(0.5)
                    .background(disabled ? Color.gray : (selections.wrappedValue.contains(muscleGroup) ? Color.blue : Color.secondary))
                    .foregroundColor(disabled ? Color.white.opacity(0.5) : Color.white)
                    .cornerRadius(8)
            }
            .disabled(disabled)
        }
    }
    
    private func shouldDisable(_ category: SplitCategory) -> Bool {
        let legCategories: Set<SplitCategory> = [.quads, .glutes, .hamstrings, .calves]
        let selectedLegCategories = selectedCategories.filter { legCategories.contains($0) }
        
        if selectedCategories.contains(.all) && category != .all {
            return true
        }
        if selectedCategories.contains(.arms) && [.biceps, .triceps, .forearms].contains(category) {
            return true
        }
        // Disable all other leg categories if two are selected but allow the currently selected ones
        if selectedLegCategories.count > 1 && category.isLegCategory() && !selectedCategories.contains(category) {
            return true
        }
        
        return false
    }
    
    private func toggleSelection(for muscleGroup: SplitCategory, in selections: Binding<[SplitCategory]>) {
        if selections.wrappedValue.contains(muscleGroup) {
            // When deselecting, check if it's 'Legs'
            if muscleGroup == .legs {
                // Remove all leg-related categories
                selections.wrappedValue.removeAll { $0.isLegCategory() }
                // Remove 'Legs'
                selections.wrappedValue.removeAll { $0 == muscleGroup }
            } else {
                // Remove just the specific muscle group if it's not 'Legs'
                selections.wrappedValue.removeAll { $0 == muscleGroup }
            }
        } else {
            // Adding selection logic remains the same
            selections.wrappedValue.append(muscleGroup)
        }
    }
    
    private func displayName(for category: SplitCategory, with selectedCategories: [SplitCategory]) -> String {
        if category == .legs {
            // Filter to identify if any specific leg categories are actively selected
            let focusCategories = selectedCategories.filter { $0.isLegCategory() }
            if focusCategories.isEmpty {
                // If no specific leg categories are selected, return "Legs"
                return "Legs"
            } else {
                // If specific leg categories are selected, show them as a focused label
                if selectedCategories.contains(.legs) {
                    return SplitCategory.concatenateCategories(for: selectedCategories)
                }
            }
        }
        return category.rawValue
    }
}



extension SplitCategory {
    func isLegCategory() -> Bool {
        return self == .quads || self == .glutes || self == .hamstrings || self == .calves
    }
}

