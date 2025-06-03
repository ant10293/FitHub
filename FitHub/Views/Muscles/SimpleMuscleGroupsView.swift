//
//  SimpleMuscleGroupsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI

struct SimpleMuscleGroupsView: View {
    var selectedSplit: [SplitCategory]
    @Binding var showFront: Bool
    
    var body: some View {
        ZStack {
            // Display the front or rear blank image as the base
            DirectImageView(imageName: showFront ? "Images/Male/Split_Images/Front_Blank/(M)Front_Simple_Blank" : "Images/Male/Split_Images/Rear_Blank/(M)Rear_Simple_Blank")
                .opacity(1.0)
            
            // Overlay the muscle images
            ForEach(selectedSplit, id: \.self) { split in
                let paths = split.splitGroupImages
                ForEach(paths.filter { $0.contains(showFront ? "Front" : "Rear") }, id: \.self) { path in
                    DirectImageView(imageName: path)
                }
            }
        }
    }
}
