//
//  SplitCategoryPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct SplitCategoryPicker: View {
    @ObservedObject var userData: UserData
    @State private var showSortSheet: Bool = false
    @State private var sortOption: ExerciseSortOption          // editable
    @Binding var selectedCategory: CategorySelections          // editable

    // ── flags copied once from Settings – not edited inside this View ──
    let enableSortPicker: Bool
    let saveSelectedSort: Bool
    let templateCategories: [SplitCategory]?
    let onChange: (ExerciseSortOption) -> Void
    
    let sortByTemplateCategories: Bool

    private let templateSortingEnabled: Bool

    init(
        userData: UserData,
        selectedCategory: Binding<CategorySelections>,
        templateCategories: [SplitCategory]? = nil,
        onChange: @escaping (ExerciseSortOption) -> Void = { _ in }
    ) {
        self.userData                = userData
        _selectedCategory            = selectedCategory
        self.templateCategories      = templateCategories

        // copy the three flags from Settings exactly once
        self.enableSortPicker        = userData.settings.enableSortPicker
        self.saveSelectedSort        = userData.settings.saveSelectedSort
        self.sortByTemplateCategories = userData.settings.sortByTemplateCategories

        // decide the initial sort-option
        let tplSortEnabled = sortByTemplateCategories && !(templateCategories?.isEmpty ?? true)
        self.templateSortingEnabled = tplSortEnabled
        if tplSortEnabled {
            _sortOption = State(initialValue: .templateCategories)
        } else {
            _sortOption = State(initialValue: userData.sessionTracking.exerciseSortOption)
        }
        self.onChange = onChange
    }
    
    var body: some View {
        HStack(spacing: 7.5) {
            if enableSortPicker {
                SortButton // Filter button to open full category menu
            }
            
            CategoryScroller
        }
        .padding(.horizontal)
        .padding(.bottom)
        .sheet(isPresented: $showSortSheet) {
            SortOptionSheet(
                current: sortOption,
                options: ExerciseSortOption.allCases.filter { $0 != .templateCategories || templateSortingEnabled }
            ) { picked in
                sortOption = picked

                if saveSelectedSort && userData.sessionTracking.exerciseSortOption != picked {
                    userData.sessionTracking.exerciseSortOption = picked
                }

                // keep your existing default selection behavior
                selectedCategory = picked.getDefaultSelection(templateCategories: templateCategories)

                onChange(picked)
                showSortSheet = false
            }
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var SortButton: some View {
        Button {
            showSortSheet = true
        } label: {
            Image(systemName: "line.horizontal.3.decrease")
                .imageScale(.large)
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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
                    }
                case .moderate:
                    ForEach(SplitCategory.allCases.filter { ![.arms, .legs].contains($0) }, id: \.self) { category in
                        PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                            selectedCategory = .split(category)
                        })
                    }
                case .complex:
                    ForEach(Muscle.allCases, id: \.self) { category in
                        PillButton(text: category.simpleName, isSelected: selectedCategory == .muscle(category), action: {
                            selectedCategory = .muscle(category)
                        })
                    }
                case .upperLower:
                    ForEach(UpperLower.allCases, id: \.self) { category in
                        PillButton(text: category.rawValue, isSelected: selectedCategory == .upperLower(category), action: {
                            selectedCategory = .upperLower(category)
                        })
                    }
                case .pushPull:
                    ForEach(PushPull.allCases, id: \.self) { category in
                        PillButton(text: category.rawValue, isSelected: selectedCategory == .pushPull(category), action: {
                            selectedCategory = .pushPull(category)
                        })
                    }
                case .templateCategories:
                    if let categories = templateCategories {
                        ForEach(categories, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                selectedCategory = .split(category)
                            })
                        }
                    } else {
                        ForEach(SplitCategory.allCases.filter { ![.arms, .legs].contains($0) }, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                selectedCategory = .split(category)
                            })
                        }
                    }
                case .difficulty:
                    ForEach(StrengthLevel.allCases, id: \.self) { lvl in
                        PillButton(text: lvl.fullName, isSelected: selectedCategory == .difficulty(lvl), action: {
                            selectedCategory = .difficulty(lvl)
                        })
                    }
                case .resistanceType:
                    ForEach(ResistanceType.allCases, id: \.self) { type in
                        PillButton(text: type.rawValue, isSelected: selectedCategory == .resistanceType(type), action: {
                            selectedCategory = .resistanceType(type)
                        })
                    }
                case .effortType:
                    ForEach(EffortType.allCases, id: \.self) { type in
                        PillButton(text: type.rawValue, isSelected: selectedCategory == .effortType(type), action: {
                            selectedCategory = .effortType(type)
                        })
                    }
                case .limbMovement:
                    ForEach(LimbMovementType.allCases, id: \.self) { type in
                        PillButton(text: type.rawValue, isSelected: selectedCategory == .limbMovement(type), action: {
                            selectedCategory = .limbMovement(type)
                        })
                    }
                }
            }
            
            .onChange(of: sortOption) { selectedCategory = sortOption.getDefaultSelection(templateCategories: templateCategories) }
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
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture(perform: action)
        }
    }
}
