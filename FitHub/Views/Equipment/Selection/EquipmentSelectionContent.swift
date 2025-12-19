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
    let isSelected: (GymEquipment) -> Bool
    let onToggle: (GymEquipment) -> Void
    let onViewDetail: (UUID) -> Void
    var onViewImplements: (UUID) -> Void = { _ in }
    
    /// Which subtitle type to display in the row
    let subtitleType: RowSubtitle

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
                                subtitle: subtitleType,
                                viewDetail: { onViewDetail(ge.id) },
                                viewImplements: { onViewImplements(ge.id) },
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

private struct EquipmentRow: View {
    let gymEquip: GymEquipment
    let equipmentSelected: Bool
    let subtitle: RowSubtitle
    let viewDetail: () -> Void
    let viewImplements: () -> Void
    let toggleSelection: () -> Void

    var body: some View {
        HStack {
            ExEquipImage(
                image: gymEquip.fullImage,
                size: 0.2,
                button: .info,
                onTap: { viewDetail() }
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(gymEquip.name)
                        .foregroundStyle(.primary)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                    
                    subtitleView
                }

                Spacer()

                Image(systemName: equipmentSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(equipmentSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: toggleSelection)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var subtitleView: some View {
        switch subtitle {
        case .category:
            categoryLine

        case .implements:
            implementsLine

        case .both:
            categoryLine
            implementsLine
        }
    }

    var categoryLine: some View {
        Text(gymEquip.equCategory.rawValue)
            .lineLimit(1)
            .font(.subheadline)
            .foregroundStyle(.gray)
    }

    @ViewBuilder
    var implementsLine: some View {
        if let impl = gymEquip.availableImplements?.subtitle {
            Button(action: viewImplements) {
                HStack(spacing: 6) {
                    Text(impl)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Edit")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .contentShape(Rectangle())
                }
                .font(.caption)
                .lineLimit(1)
                .padding(.trailing)
            }
            .buttonStyle(.plain)
        }
    }
}

enum RowSubtitle: String {
    case category, implements, both
}
