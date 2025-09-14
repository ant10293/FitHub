    private func filterEligibleExercises(
        from indices: [Int],
        usedNames: Set<String>,
        rAndS: RepsAndSets,
        dayLabel: String
    ) -> [Exercise] {
        
        var filteredCount = 0
        var dislikedCount = 0
        var cantPerformCount = 0
        var resistanceCount = 0
        var effortOKCount = 0
        var strengthFilteredCount = 0
        var strengthFallbackCount = 0
        
        var result: [Exercise] = []
        var fallbackResult: [Exercise] = []
        
        for idx in indices {
            let ex = self.idx.exercises[idx]
            
            // Basic filters - skip this exercise if any condition fails
            if disliked.contains(ex.id) { 
                dislikedCount += 1
                continue
            }
            
            if !self.idx.canPerform[idx] {
                cantPerformCount += 1
                continue
            }
            if !ex.resistanceOK(resistance) { 
                resistanceCount += 1
                continue
            }
            
            // CRITICAL: Only include exercises that have sets configured AND positive distribution
            if !ex.effortOK(rAndS) { 
                effortOKCount += 1
                continue
            }
            
            // Strength ceiling filtering
            let exerciseDifficulty = ex.difficulty.strengthValue
            let userStrengthCeiling = strengthCeiling.strengthValue
            
            if exerciseDifficulty <= userStrengthCeiling {
                // Exercise is within user's strength level
                filteredCount += 1
                result.append(ex)
            } else if exerciseDifficulty == userStrengthCeiling + 1 {
                // Exercise is one level above - add to fallback pool
                strengthFallbackCount += 1
                fallbackResult.append(ex)
            } else {
                // Exercise is too difficult (more than one level above)
                strengthFilteredCount += 1
            }
        }
        
        // If we don't have enough exercises within the strength ceiling, add from fallback
        if result.count < 3 && !fallbackResult.isEmpty {
            logger?.add("[\(dayLabel)] Not enough exercises within strength ceiling (\(result.count)), adding from fallback pool (\(fallbackResult.count) available)")
            result.append(contentsOf: fallbackResult)
        }
        
        // Log filtering results
        logger?.add("[\(dayLabel)] Strength filtering: \(filteredCount) within ceiling, \(strengthFallbackCount) too difficult, \(strengthFallbackCount) in fallback pool")
        logger?.add("[\(dayLabel)] Other filters: \(dislikedCount) disliked, \(cantPerformCount) can't perform, \(resistanceCount) wrong resistance, \(effortOKCount) effort issues")
        
        return result
    }
