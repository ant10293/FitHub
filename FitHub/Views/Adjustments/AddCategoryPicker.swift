//
//  AddCategoryPicker.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct AddCategoryPicker: View {
    var exercise: Exercise
    var existingCategories: Set<AdjustmentCategories>
    var onAddCategory: (AdjustmentCategories) -> Void
    var availableCategories: [AdjustmentCategories] {
        AdjustmentCategories.allCases.filter { !existingCategories.contains($0) }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
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
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                            // .foregroundColor(.blue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Adjustment Category").navigationBarTitleDisplayMode(.inline)
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
