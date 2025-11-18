//
//  ScrollRow.swift
//  FitHub
//
//  Created by Anthony Cantu on 9/7/25.
//

import SwiftUI

struct HorizontalScrollRow<Data, ID, ImageContent: View>: View where Data: RandomAccessCollection, ID: Hashable {
    let title: String
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let size: CGFloat
    let image: (Data.Element) -> ImageContent
    let label: (Data.Element) -> String

    init(
        title: String,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        size: CGFloat = UIScreen.main.bounds.height * 0.1,
        @ViewBuilder image: @escaping (Data.Element) -> ImageContent,
        label: @escaping (Data.Element) -> String
    ) {
        self.title = title
        self.data = data
        self.id = id
        self.size = size
        self.image = image
        self.label = label
    }

    var body: some View {
        if data.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(title): ")
                    .bold()

                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(data, id: id) { item in
                            VStack {
                                image(item)
                                    .frame(width: size, height: size)

                                Text(label(item))
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .frame(maxWidth: size * 1.1)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
    }
}

struct EquipmentScrollRow: View {
    let equipment: [GymEquipment]
    let title: String

    var body: some View {
        HorizontalScrollRow(
            title: title,
            data: equipment,
            id: \.self,
            image: { eq in
                eq.fullImageView   // compiler infers ImageContent from this
            },
            label: { eq in
                eq.name
            }
        )
    }
}

struct ExerciseScrollRow: View {
    let userData: UserData
    let exercises: [Exercise]
    let title: String

    var body: some View {
        HorizontalScrollRow(
            title: title,
            data: exercises,
            id: \.id,
            image: { exercise in
                exercise.fullImageView(
                    favState: FavoriteState.getState(for: exercise, userData: userData)
                )
            },
            label: { exercise in
                exercise.name
            }
        )
    }
}
