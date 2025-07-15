//
//  AddCategoryPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AddCategoryPicker: View {
    @Environment(\.presentationMode) var presentationMode
    var exercise: Exercise
    var existingCategories: Set<AdjustmentCategory>
    var onAddCategory: (AdjustmentCategory) -> Void
    var availableCategories: [AdjustmentCategory] {
        AdjustmentCategory.allCases.filter { !existingCategories.contains($0) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCategories, id: \.self) { category in
                    Button(action: {
                        onAddCategory(category)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(category.rawValue)
                                    .foregroundColor(.primary)
                                
                                // Adjustment image
                                Image(category.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIScreen.main.bounds.height * 0.1)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationBarTitle("Add Adjustment Category", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
