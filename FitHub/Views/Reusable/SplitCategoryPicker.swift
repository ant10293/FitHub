//
//  SplitCategoryPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct SplitCategoryPicker: View {
    @State var sortOption: ExerciseSortOption
    @Binding var selectedCategory: CategorySelections // One binding to cover whatever category-type is in use
    var templateCategories: [SplitCategory]?
    var onChange: (ExerciseSortOption) -> Void
    
    var body: some View {
        HStack(spacing: 7.5) {
            // Filter button to open full category menu
            Menu {
                // Direct list of categories, no nested Picker
                ForEach(ExerciseSortOption.allCases.filter { $0 != .templateCategories || templateCategories != nil }, id: \.self) { category in
                    Button(action: {
                        // update selected category to the first option
                        sortOption = category
                        onChange(sortOption)
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
                    .cornerRadius(8)
            }
            CategoryScroller
        }
        .padding(.horizontal)
        .padding(.bottom)
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
                    }.onAppear {
                        selectedCategory = .split(.all)
                    }
                case .moderate:
                    ForEach(SplitCategory.allCases.filter { ![.arms, .legs].contains($0) }, id: \.self) { category in
                        PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                            selectedCategory = .split(category)
                        })
                    }.onAppear {
                        selectedCategory = .split(.all)
                    }
                case .complex:
                    ForEach(Muscle.allCases, id: \.self) { category in
                        PillButton(text: category.simpleName, isSelected: selectedCategory == .muscle(category), action: {
                            selectedCategory = .muscle(category)
                        })
                    }.onAppear {
                        selectedCategory = .muscle(.all)
                    }
                case .upperLower:
                    ForEach(UpperLower.allCases, id: \.self) { category in
                        PillButton(text: category.rawValue, isSelected: selectedCategory == .upperLower(category), action: {
                            selectedCategory = .upperLower(category)
                        })
                    }.onAppear {
                        selectedCategory = .upperLower(.upperBody)
                    }
                case .pushPull:
                    ForEach(PushPull.allCases, id: \.self) { category in
                        PillButton(text: category.rawValue, isSelected: selectedCategory == .pushPull(category), action: {
                            selectedCategory = .pushPull(category)
                        })
                    }.onAppear {
                        selectedCategory = .pushPull(.push)
                    }
                case .templateCategories:
                    if let categories = templateCategories {
                        ForEach(categories, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                selectedCategory = .split(category)
                            })
                        }.onAppear {
                            if let firstCat = categories.first {
                                selectedCategory = .split(firstCat)
                            }
                        }
                    } else {
                        ForEach(SplitCategory.allCases.filter { ![.arms, .legs].contains($0) }, id: \.self) { category in
                            PillButton(text: category.rawValue, isSelected: selectedCategory == .split(category), action: {
                                selectedCategory = .split(category)
                            })
                        }.onAppear {
                            selectedCategory = .split(.all)
                        }
                    }
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

