//
//  SimpleMuscleGroupsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct SimpleMuscleGroupsView: View {
    @Binding var showFront: Bool
    var gender: Gender
    var selectedSplit: [SplitCategory]


    var body: some View {
        ZStack {
            // Display the front or rear blank image as the base
            DirectImageView(imageName: AssetPath.getImagePath(for: .split, isfront: showFront, isBlank: true, gender: gender))
                .opacity(1.0)

            let legTargets = SplitCategory.legFocusCategories(selectedSplit)

            // Overlay the muscle images
            ForEach(selectedSplit, id: \.self) { split in
                let paths = AssetPath.getSplitImages(category: split, isTarget: legTargets.contains(split), gender: gender)
                ForEach(paths.filter { $0.contains(showFront ? "Front" : "Rear") }, id: \.self) { path in
                    DirectImageView(imageName: path)
                        .zIndex(split == .legs ? 0 : 1) // legs always underneath to ensure target images are properly displayed
                }
            }
        }
    }
}
