//
//  SplitCategoryPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct SplitCategoryPicker: View {
    let enableSortPicker: Bool // disable ExerciseSortOptions picker
    let saveSelectedSort: Bool // save selections as new exerciseSortOption
    let sortByTemplateCategories: Bool // sort by template categories when editing a template with categories
    
    @State var sortOption: ExerciseSortOption
    @Binding var selectedCategory: CategorySelections // One binding to cover whatever category-type is in use
 
    var templateCategories: [SplitCategory]?
    var onChange: (ExerciseSortOption) -> Void
    
    private let templateSortingEnabled: Bool

    
    init(
        enableSortPicker: Bool,
        saveSelectedSort: Bool,
        sortByTemplateCategories: Bool = false,
        sortOption: ExerciseSortOption,
        templateCategories: [SplitCategory]? = nil,
        selectedCategory: Binding<CategorySelections>,
        onChange: @escaping (ExerciseSortOption) -> Void
    ) {
        self.enableSortPicker = enableSortPicker
        self.saveSelectedSort = saveSelectedSort
        self.sortByTemplateCategories = sortByTemplateCategories
        self.templateCategories = templateCategories
        
        let enabled = sortByTemplateCategories && !(templateCategories?.isEmpty ?? true)
        self.templateSortingEnabled = enabled

        if enabled { _sortOption = State(initialValue: .templateCategories) }
        else { _sortOption = State(initialValue: sortOption) }
        
        _selectedCategory = selectedCategory
        
        self.onChange = onChange
    }
    
    var body: some View {
        HStack(spacing: 7.5) {
            if enableSortPicker {
                SortMenu // Filter button to open full category menu
            }
            
            CategoryScroller
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var SortMenu: some View {
        Menu {
            Text("-- Sort Category Options --")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)   // greyed-out look
                .disabled(true)                // makes it non-interactive
            
            // Direct list of categories, no nested Picker
            ForEach(ExerciseSortOption.allCases.filter { $0 != .templateCategories || templateSortingEnabled }, id: \.self) { category in
                Button(action: {
                    // update selected category to the first option
                    sortOption = category
                    if saveSelectedSort && sortOption != .templateCategories { onChange(sortOption) }
                }) {
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        if sortOption == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.horizontal.3.decrease")
                .imageScale(.large)
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var CategoryScroller: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 7.5) {
                switch sortOption {
                    case .simple:
                        ForEach(SplitCategory.allCases.filter { ![.forearms, .quads, .calves, .hamstrings, .glutes].contains($0) }, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                selectedCategory = .split(category)
                            })
                        }.onAppear { selectedCategory = .split(.all) }
                    case .moderate:
                        ForEach(SplitCategory.allCases.filter { ![.arms, .legs].contains($0) }, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                selectedCategory = .split(category)
                            })
                        }.onAppear { selectedCategory = .split(.all) }
                    case .complex:
                        ForEach(Muscle.allCases, id: \.self) { category in
                            PillButton(text: category.simpleName, isSelected: selectedCategory == .muscle(category), action: {
                                selectedCategory = .muscle(category)
                            })
                        }.onAppear { selectedCategory = .muscle(.all) }
                    case .upperLower:
                        ForEach(UpperLower.allCases, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .upperLower(category), action: {
                                selectedCategory = .upperLower(category)
                            })
                        }.onAppear { selectedCategory = .upperLower(.upperBody) }
                    case .pushPull:
                        ForEach(PushPull.allCases, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .pushPull(category), action: {
                                selectedCategory = .pushPull(category)
                            })
                        }.onAppear { selectedCategory = .pushPull(.push) }
                    case .templateCategories:
                        if let categories = templateCategories {
                            ForEach(categories, id: \.self) { category in
                                PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                    selectedCategory = .split(category)
                                })
                            }.onAppear { if let firstCat = categories.first { selectedCategory = .split(firstCat) } }
                        } else {
                            ForEach(SplitCategory.allCases.filter { ![.arms, .legs].contains($0) }, id: \.self) { category in
                                PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                    selectedCategory = .split(category)
                                })
                            }.onAppear { selectedCategory = .split(.all) }
                        }
                    case .difficulty:
                        ForEach(StrengthLevel.allCases, id: \.self) { lvl in
                            PillButton(text: lvl.fullName, isSelected: selectedCategory == .difficulty(lvl), action: {
                                selectedCategory = .difficulty(lvl)
                            })
                        }.onAppear { selectedCategory = .difficulty(.beginner) }
                    case .resistanceType:
                        ForEach(ResistanceType.allCases, id: \.self) { type in
                            PillButton(text: type.rawValue, isSelected: selectedCategory == .resistanceType(type), action: {
                                selectedCategory = .resistanceType(type)
                            })
                        }.onAppear { selectedCategory = .resistanceType(.any) }
                    case .effortType:
                        ForEach(EffortType.allCases, id: \.self) { type in
                            PillButton(text: type.rawValue, isSelected: selectedCategory == .effortType(type), action: {
                                selectedCategory = .effortType(type)
                            })
                        }.onAppear { selectedCategory = .effortType(.compound) }
                }
            }
        }
    }
    
    struct PillButton: View {
        let text: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Text(text)
                .padding(10)
                .frame(minWidth: 60)
                .background(isSelected ? Color.blue : Color(UIColor.lightGray))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture(perform: action)
        }
    }
}
