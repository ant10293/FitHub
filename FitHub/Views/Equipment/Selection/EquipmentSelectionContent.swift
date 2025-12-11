//
//  EquipmentSelectionContent.swift
//  FitHub
//
//  Created by Anthony Cantu on 8/22/25.
//

import SwiftUI

// MARK: - BASE CONTENT (Shared UI)
struct EquipmentSelectionContent: View {
    @EnvironmentObject private var ctx: AppContext
    @Binding var selectedCategory: EquipmentCategory
    @Binding var searchText: String

    /// Injected behaviors so the base view stays dumb and reusable.
    var isSelected: (GymEquipment) -> Bool
    var onToggle: (GymEquipment) -> Void
    var onViewDetail: (UUID) -> Void

    /// Optional banner trigger (shown only in normal view)
    var showSaveBanner: Bool = false

    var body: some View {
        VStack {
            categoryBar
                .padding(.bottom, -5)

            SearchBar(text: $searchText, placeholder: "Search Equipment")
                .padding(.horizontal)

            if showSaveBanner {
                InfoBanner(title: "Equipment Saved Successfully!").zIndex(1)
            }

            List {
                if filtered.isEmpty {
                    Text("No equipment found.")
                        .foregroundStyle(.gray)
                        .padding()
                } else {
                    Section {
                        ForEach(filtered, id: \.self) { ge in
                            EquipmentRow(
                                gymEquip: ge,
                                equipmentSelected: isSelected(ge),
                                viewDetail: { onViewDetail(ge.id) },
                                toggleSelection: { onToggle(ge) }
                            )
                        }
                    } footer: {
                        Text("\(selectedInFiltered)/\(filtered.count) equipment selected")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 10) {
                ForEach(EquipmentCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .padding(.all, 10)
                        .background(self.selectedCategory == category ? Color.blue : Color(UIColor.lightGray))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture { self.selectedCategory = category }
                }
            }
            .contentShape(Rectangle())
            .padding([.horizontal, .bottom])
        }
    }
    
    
    private var filtered: [GymEquipment] {
        let cat: EquipmentCategory? = (selectedCategory == .all ? nil : selectedCategory)
        return ctx.equipment.filteredEquipment(searchText: searchText, category: cat)
    }

    private var selectedInFiltered: Int {
        filtered.reduce(0) { $0 + (isSelected($1) ? 1 : 0) }
    }
}
