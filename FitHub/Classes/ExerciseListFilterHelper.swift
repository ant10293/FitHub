//
//  ExerciseListFilterHelper.swift
//  FitHub
//
//  Created by Anthony Cantu on 1/15/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ExerciseListFilterHelper: ObservableObject {
    @Published var filteredExercises: [Exercise] = []
    @Published var isInitialLoad: Bool = true
    
    private var lastParamsHash: Int = 0
    private var debounceTask: Task<Void, Never>?
    
    struct FilterParams {
        let searchText: String
        let selectedCategory: CategorySelections
        let showingFavorites: Bool
        let dislikedOnly: Bool
        let templateCategories: [SplitCategory]?
        let templateFilter: Bool
        
        var hashValue: Int {
            var hasher = Hasher()
            hasher.combine(searchText)
            hasher.combine(selectedCategory)
            hasher.combine(showingFavorites)
            hasher.combine(dislikedOnly)
            hasher.combine(templateCategories?.map { $0.rawValue })
            hasher.combine(templateFilter)
            return hasher.finalize()
        }
    }
    
    func updateFilter(
        exercises: ExerciseData,
        params: FilterParams,
        userData: UserData,
        equipment: EquipmentData,
        debounceMs: Int = 150,
        mode: FilterMode = .standard
    ) {
        let paramsHash = params.hashValue
        
        // If params haven't changed, don't recompute
        if paramsHash == lastParamsHash && !filteredExercises.isEmpty {
            return
        }
        
        // Cancel previous debounce task
        debounceTask?.cancel()
        
        // Debounce the actual computation
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(debounceMs) * 1_000_000)
            
            guard !Task.isCancelled else { return }
            
            let base = exercises.filteredExercises(
                searchText: params.searchText,
                selectedCategory: params.selectedCategory,
                templateCategories: params.templateCategories,
                templateFilter: params.templateFilter,
                favoritesOnly: params.showingFavorites,
                dislikedOnly: params.dislikedOnly,
                userData: userData,
                equipmentData: equipment
            )
            
            let results: [Exercise]
            switch mode {
            case .standard:
                results = base
            case .performanceView:
                // Dedupe by ID, preserve order
                var seen = Set<Exercise.ID>()
                let uniqueBase = base.filter { seen.insert($0.id).inserted }
                
                // Filter: must have a peak and its actualValue > 0
                let filtered = uniqueBase.filter { ex in
                    guard let peak = exercises.peakMetric(for: ex.id) else { return false }
                    return peak.actualValue > 0
                }
                
                // Sort: newest max first
                results = filtered.sorted { a, b in
                    let da = exercises.getMax(for: a.id)?.date ?? .distantPast
                    let db = exercises.getMax(for: b.id)?.date ?? .distantPast
                    return da > db
                }
            }
            
            self.filteredExercises = results
            self.lastParamsHash = paramsHash
            self.isInitialLoad = false
        }
    }
    
    func invalidate() {
        filteredExercises = []
        lastParamsHash = 0
        isInitialLoad = true
        debounceTask?.cancel()
    }
    
    enum FilterMode {
        case standard
        case performanceView
    }
}

