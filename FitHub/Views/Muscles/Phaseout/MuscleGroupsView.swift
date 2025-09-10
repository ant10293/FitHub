//
//  MuscleGroupsView.swift
//  FitHub
//
//  Created by Anthony Cantu on 6/29/24.
//
/*
import SwiftUI
import UIKit


struct MuscleGroupsView: View {
    @Binding var showFront: Bool
    var gender: Gender
    var selectedMuscles: [Muscle]
    var restPercentages: [Muscle: Int] = [:]  // State to hold the rest percentages
    
    var body: some View {
        ZStack {
            // Display the front or rear blank image as the base
            DirectImageView(imageName: AssetPath.getImagePath(for: .muscle, isfront: showFront, isBlank: true, gender: gender))
                .opacity(1.0)
            
            // Filter and overlay the muscle images
            ForEach(selectedMuscles, id: \.self) { muscle in
                let paths = AssetPath.getMuscleImages(category: muscle, gender: gender)
                ForEach(paths.filter { $0.contains(showFront ? "Front" : "Rear") }, id: \.self) { path in
                    DirectImageView(imageName: path)
                        .opacity(opacity(for: muscle))
                }
            }
        }
    }
    
    private func opacity(for muscle: Muscle) -> Double {
        return 1.0 - Double(restPercentages[muscle] ?? 0) / 100.0
    }
}
*/
