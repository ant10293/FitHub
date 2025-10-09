//
//  AddCategoryPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AddCategoryPicker: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    let existingCategories: Set<AdjustmentCategory>
    let onAddCategory: (AdjustmentCategory) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableCategories, id: \.self) { category in
                    Button(action: {
                        onAddCategory(category)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(category.rawValue)
                                    .foregroundStyle(Color.primary)
                                
                                // Adjustment image
                                Image(category.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: UIScreen.main.bounds.height * 0.1)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .navigationBarTitle("Add Adjustment Category", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var availableCategories: [AdjustmentCategory] {
        AdjustmentCategory.allCases.filter { !existingCategories.contains($0) }
    }
}
