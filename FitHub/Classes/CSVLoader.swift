//
//  CSVLoader.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

enum CSVKey: String { case age = "Age"; case bodyweight = "BW" }


final class CSVLoader {
    static let shared = CSVLoader()      // <– universal entry point

    private init() {}   
    
    static func loadCSV(fileName: String) -> [[String: String]] {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            print("CSV file not found: \(fileName).csv")
            return []
        }
        
        do {
            let content = try String(contentsOfFile: filePath)
            var rows = content.components(separatedBy: "\n").map { $0.components(separatedBy: ",") }
            let headers = rows.removeFirst()
            var csvData: [[String: String]] = []
            
            for row in rows {
                if row.count == headers.count {
                    var rowData: [String: String] = [:]
                    for (index, header) in headers.enumerated() {
                        rowData[header] = row[index]
                    }
                    csvData.append(rowData)
                }
            }
            return csvData
        } catch {
            print("Error reading CSV file: \(error)")
            return []
        }
    }
        
    static func getBasePaths(gender: Gender) -> (basePathAge: String, basePathBW: String) {
        var basePath: String = "FitHubAssets/Datasets/"
        if gender == .male {
            basePath += "Male/"
            return ("\(basePath)Age/", "\(basePath)Bodyweight/")
        } else {
            basePath += "Female/"
            return ("\(basePath)Age/", "\(basePath)Bodyweight/")
        }
    }
    
    static func getExercisePaths(exercise: String, gender: Gender) -> (agePath: String, pathBW: String) {
        let (basePathAge, basePathBW) = getBasePaths(gender: gender)
        let pathAge = "\(basePathAge)\(exercise)"
        let pathBW = "\(basePathBW)\(exercise)"
        return (pathAge, pathBW)
    }
    
    static func getExerciseData(exercise: String, gender: Gender) -> (dataAge: [[String: String]], dataBW: [[String: String]]) {
        let (pathAge, pathBW) = getExercisePaths(exercise: exercise, gender: gender)
        let dataAge = loadCSV(fileName: pathAge)
        let dataBW = loadCSV(fileName: pathBW)
        return (dataAge, dataBW)
    }
    
    struct ExCat {
        var exerciseName: String
        var maxValue: Double?
        var bwPath: String = ""
        var agePath: String = ""
        var fitnessCategory: StrengthLevel?
        var percentile: Int?
    }
}


extension CSVLoader {
    static func getMaxValues(for exercise: Exercise, key: CSVKey, value: Double, userData: UserData) -> [String: PeakMetric] {
        guard let url = exercise.url else { return [:] }

        let (pathAge, pathBW) = getExercisePaths(exercise: url, gender: userData.physical.gender)
        let fileName = key == .age ? pathAge : pathBW
        let rows = loadCSV(fileName: fileName)
        let roundedValue = value.rounded()

        let sortedRows: [(Double, [String: Double])] = rows.compactMap { row in
            guard let keyString = row[key.rawValue], let keyValue = Double(keyString) else {
                return nil // malformed row
            }

            // Convert every other column that can be parsed to Double.
            var dict: [String: Double] = [:]
            for (column, string) in row where column != key.rawValue {
                if let doubleVal = (string.contains("< 1") ? Double(0) : Double(string)) { dict[column] = doubleVal }
            }
            return (keyValue, dict)

        }.sorted { $0.0 < $1.0 }

        guard !sortedRows.isEmpty else { return [:] }

        // Pick the user's bracket row
                let chosen: [String: Double] = {
                    for i in 0..<(sortedRows.count - 1) {
                        let a = sortedRows[i].0
                        let b = sortedRows[i + 1].0
                        if roundedValue >= a && roundedValue < b {
                            return sortedRows[i].1
                        }
                    }
                    return sortedRows.last?.1 ?? [:]
                }()

                // Wrap doubles into PeakMetric using exercise.getPeakMetric(for:)
                var out: [String: PeakMetric] = [:]
                for (k, v) in chosen {
                    out[k] = exercise.getPeakMetric(metricValue: v)
                }
                return out
    }

    static func predict1RM(using data: [[String: String]], key: CSVKey, value: Double, fitnessLevel: StrengthLevel) -> Double {
        let fitnessLevel = fitnessLevel.rawValue
        
        let filteredData = data.compactMap { row -> (Double, Double)? in
            if let keyValue = Double(row[key.rawValue] ?? ""), let fitnessValue = Double(row[fitnessLevel] ?? "") {
                return (keyValue, fitnessValue)
            }
            return nil
        }.sorted(by: { $0.0 < $1.0 })
        
        guard !filteredData.isEmpty else { return 0.0 }
        
        if let exactMatch = filteredData.first(where: { $0.0 == value }) {
            return exactMatch.1
        } else {
            for i in 0..<filteredData.count - 1 {
                if filteredData[i].0 < value && filteredData[i + 1].0 > value {
                    let x0 = filteredData[i].0
                    let y0 = filteredData[i].1
                    let x1 = filteredData[i + 1].0
                    let y1 = filteredData[i + 1].1
                    let interpolatedValue = y0 + (value - x0) * (y1 - y0) / (x1 - x0)
                    return interpolatedValue
                }
            }
        }
        return filteredData.last?.1 ?? 0.0
    }

    static func predictRepsForExercise(using data: [[String: String]], key: CSVKey, value: Double, fitnessLevel: StrengthLevel) -> Int {
        let fitnessLevel = fitnessLevel.rawValue
        
        // First, filter and transform the data to match expected types
        let filteredData = data.compactMap { row -> (Double, Int)? in
            if let keyValue = Double(row[key.rawValue] ?? ""), let reps = Int(row[fitnessLevel] ?? "") {
                return (keyValue, reps)
            }
            return nil
        }.sorted(by: { $0.0 < $1.0 })
        
        guard !filteredData.isEmpty else { return 0 }
        
        // Handle the case where an exact match is found
        if let exactMatch = filteredData.first(where: { $0.0 == value }) {
            return exactMatch.1
        } else {
            // Interpolation for values between known data points
            for i in 0..<filteredData.count - 1 {
                if filteredData[i].0 < value && filteredData[i + 1].0 > value {
                    let x0 = filteredData[i].0
                    let y0 = Double(filteredData[i].1)
                    let x1 = filteredData[i + 1].0
                    let y1 = Double(filteredData[i + 1].1)
                    let interpolatedValue = y0 + (value - x0) * (y1 - y0) / (x1 - x0)
                    return Int(round(interpolatedValue))
                }
            }
        }
        // Return the last known value if the input is greater than any data point
        return filteredData.last?.1 ?? 0
    }
    // TODO: tweak these to better accomodate older people
    static func calculateFinal1RM(userData: UserData, exercise: String) -> PeakMetric {
        let (dataAge, dataBW) = getExerciseData(exercise: exercise, gender: userData.physical.gender)
        
        let predicted1RM_BW = predict1RM(using: dataBW, key: .bodyweight, value: userData.currentMeasurementValue(for: .weight).actualValue, fitnessLevel: userData.evaluation.strengthLevel)
        let predicted1RM_Age = predict1RM(using: dataAge, key: .age, value: Double(userData.profile.age), fitnessLevel: userData.evaluation.strengthLevel)
        
        let predictedCombined = predicted1RM_BW + predicted1RM_Age
        guard predictedCombined > 0 else { return .oneRepMax(Mass(kg: 0)) }
        
        let final1RM = predictedCombined / 2
        //print("Predicted 1RM for \(exercise) - BW: \(predicted1RM_BW), Age: \(predicted1RM_Age), Final: \(final1RM)")
        return .oneRepMax(Mass(kg: final1RM))
    }
    
    static func calculateFinalReps(userData: UserData, exercise: String) -> PeakMetric {
        let (dataAge, dataBW) = getExerciseData(exercise: exercise, gender: userData.physical.gender)
        
        let predictedReps_BW = predictRepsForExercise(using: dataBW, key: .bodyweight, value: userData.currentMeasurementValue(for: .weight).actualValue, fitnessLevel: userData.evaluation.strengthLevel)
        let predictedReps_Age = predictRepsForExercise(using: dataAge, key: .age, value: Double(userData.profile.age), fitnessLevel: userData.evaluation.strengthLevel)
        
        let predictedCombined = predictedReps_BW + predictedReps_Age
        guard predictedCombined > 0 else { return .maxReps(0) }
        
        let finalReps = predictedCombined / 2
        //print("Predicted Reps for \(exercise) - BW: \(predictedReps_BW), Age: \(predictedReps_Age), Final: \(finalReps)")
        return .maxReps(finalReps)
    }
    
    static func calculateMaxValue(for exercise: Exercise, userData: UserData) -> PeakMetric? {
        guard let url = exercise.url else { return nil }
        
        switch exercise.getPeakMetric(metricValue: 0) {
        case .oneRepMax:
            return calculateFinal1RM(userData: userData, exercise: url)
        case .maxReps:
            return calculateFinalReps(userData: userData, exercise: url)
        default:
            return nil
        }
    }
    
    static func calculateExercisePercentile(for exercise: Exercise, maxValue: Double, userData: UserData) -> Int? {
        guard let url = exercise.url else { return nil }

        let (dataAge, dataBW) = getExerciseData(exercise: url, gender: userData.physical.gender)
        
        let percentile = derivePercentile(userData: userData, maxValue: maxValue, dataAge: dataAge, dataBW: dataBW)
        return percentile
    }
    
    private static func derivePercentile(userData: UserData, maxValue: Double, dataAge: [[String: String]], dataBW: [[String: String]]) -> Int {
        let agePercentile = findPercentile(data: dataAge, key: .age, value: Double(userData.profile.age), maxValue: maxValue)
        let bwPercentile = findPercentile(data: dataBW, key: .bodyweight, value: userData.currentMeasurementValue(for: .weight).actualValue, maxValue: maxValue)
        
        print("Percentiles determined: Age - \(agePercentile), BW - \(bwPercentile)")
        
        return (agePercentile + bwPercentile) / 2
    }
    
    static func estimateStrengthCategories(userData: UserData, exerciseData: ExerciseData) -> StrengthLevel {
        let (basePathAge, basePathBW) = getBasePaths(gender: userData.physical.gender)
        var categories = [StrengthLevel]()
        let exerciseNames: [String] = ["Bench Press", "Back Squat", "Deadlift", "Push-Up", "Sit-Up", "Bodyweight Squat"]
        var exercises: [ExCat] = []
        
        for name in exerciseNames {
            if let exercise = exerciseData.exercise(named: name),
                let maxValue = exerciseData.peakMetric(for: exercise.id)?.actualValue,
                let url = exercise.url {
                let bwPath = "\(basePathBW)\(url)"
                let agePath = "\(basePathAge)\(url)"
                exercises.append(ExCat(exerciseName: name, maxValue: maxValue, bwPath: bwPath, agePath: agePath))
            }
        }
        
        for i in 0..<exercises.count {
            if let max = exercises[i].maxValue {
                let category = calculateFitnessCategory(
                    userData: userData,
                    basePathAge: exercises[i].agePath,
                    basePathBW: exercises[i].bwPath,
                    maxValue: max
                )
                exercises[i].fitnessCategory = category
                categories.append(category)
            }
        }
        // Dictionary to count occurrences
        var categoryCounts = [StrengthLevel.RawValue: Int]()
        categories.forEach { categoryCounts[$0.rawValue, default: 0] += 1 }
        //print("Category counts: \(categoryCounts)")
        
        // Determine the most frequent category
        let maxCount = categoryCounts.values.max() ?? 1
        let mostFrequentCategories = categoryCounts.filter { $1 == maxCount }.map { $0.key }
        
        let selectedCategory: String
        if mostFrequentCategories.count == 1 {
            selectedCategory = mostFrequentCategories.first ?? "beginner" // Return the most frequent category
        } else {
            // If there is a tie or all different, sort and choose the middle
            let sortedCategories = mostFrequentCategories.sorted()
            let middleIndex = sortedCategories.count / 2
            selectedCategory = sortedCategories[safe: middleIndex] ?? "beginner"
        }
        print("Selected fitness category: \(selectedCategory)")
        
        return StrengthLevel(rawValue: selectedCategory) ?? .beginner
        
    }
    
    static func calculateFitnessCategory(userData: UserData, basePathAge: String, basePathBW: String, maxValue: Double) -> StrengthLevel {
        print("Calculating fitness category for \(basePathAge) and \(basePathBW)")
        let dataAge = loadCSV(fileName: basePathAge)
        let dataBW = loadCSV(fileName: basePathBW)
        
        let fitnessLevelAge = findFitnessLevel(data: dataAge, key: .age, value: Double(userData.profile.age), maxValue: maxValue)
        let fitnessLevelBW = findFitnessLevel(data: dataBW, key: .bodyweight, value: userData.currentMeasurementValue(for: .weight).actualValue, maxValue: maxValue)
        
        print("Fitness levels determined: Age - \(fitnessLevelAge), BW - \(fitnessLevelBW)")
        return decideFinalFitnessLevel(fitnessLevelAge, fitnessLevelBW)
    }
    
    // FIXME: this is not good for accomodating older users
    static private func decideFinalFitnessLevel(_ ageLevel: StrengthLevel, _ bwLevel: StrengthLevel) -> StrengthLevel {
        let ageWeight = 0.3  // 30% weight to the age level
        let bwWeight = 0.7   // 70% weight to the bodyweight level
        
        let ageScore = Double(ageLevel.strengthValue) * ageWeight
        let bwScore = Double(bwLevel.strengthValue) * bwWeight
        
        let finalScore = ageScore + bwScore
        let roundedScore = round(finalScore)  // Round to the nearest whole number
        
        print("Age score: \(ageScore), BW score: \(bwScore), Combined score: \(finalScore), Rounded score: \(roundedScore)")
        
        for lvl in StrengthLevel.allCases {
            if lvl.strengthValue == Int(roundedScore) {
                return lvl
            }
        }
        
        return .beginner
    }
    
    private static func makeFilteredData(from data: [[String: String]], key: CSVKey) -> [(Double, [String: Double])] {
        data.compactMap { row -> (Double, [String: Double])? in
            // Parse the key column as Double
            guard let x = Double(row[key.rawValue] ?? "") else { return nil }

            // Collect every column that parses as Double
            var numeric: [String: Double] = [:]
            for (col, str) in row {
                if let d = Double(str) {
                    numeric[col] = d
                }
            }
            return (x, numeric)
        }
        .sorted(by: { $0.0 < $1.0 })
    }

    static func findPercentile(data: [[String: String]], key: CSVKey, value: Double, maxValue: Double) -> Int {
        let maxValue = round(maxValue)
        let filteredData = makeFilteredData(from: data, key: key)
                
        // Ensure there are at least two elements in filteredData
        guard filteredData.count > 1 else {
            print("Insufficient data for percentile calculation.")
            return 0
        }
        
        for i in 0..<filteredData.count-1 {
            let current = filteredData[i]
            let next = filteredData[i+1]
            if value >= current.0 && value < next.0 {
                print("User value falls between \(current.0) and \(next.0)")
                return calculateCategoryPercentile(current: current, next: next, maxValue: maxValue)
            }
        }
        
        print("No appropriate bracket found; using last record.")
        if let lastRecord = filteredData.last {
            return calculateCategoryPercentile(current: lastRecord, next: lastRecord, maxValue: maxValue)
        }
        return 0
    }
    
    static private func findFitnessLevel(data: [[String: String]], key: CSVKey, value: Double, maxValue: Double) -> StrengthLevel {
        let maxValue = round(maxValue)
        let filteredData = makeFilteredData(from: data, key: key)
        
        guard filteredData.count > 1 else {
            print("Insufficient data to determine fitness category.")
            return .beginner
        }
                
        for i in 0..<filteredData.count-1 {
            let current = filteredData[i]
            let next = filteredData[i+1]
            if value >= current.0 && value < next.0 {
                print("User value falls between \(current.0) and \(next.0)")
                // Compare oneRepMax to the fitness levels in 'current' row
                return compareMaxValueToLevels(row: current.1, maxValue: maxValue)
            }
        }
        // Handle values greater than the last range
        if let last = filteredData.last, maxValue >= last.0 {
            print("Rounded oneRepMax \(maxValue) exceeds last range starting at \(last.0).")
            return compareMaxValueToLevels(row: last.1, maxValue: maxValue)
        }
        
        print("No appropriate bracket found; using last record.")
        return .beginner
    }
    
    static private func compareMaxValueToLevels(row: [String: Double], maxValue: Double) -> StrengthLevel {
        for category in StrengthLevel.categories.reversed() {
            if let level = row[category], maxValue >= level {
                print("User's max of \(maxValue) qualifies for \(category)")
                if let selectedCategory = StrengthLevel(rawValue: category) {
                    return selectedCategory
                }
            }
        }
        print("User's max of \(maxValue) does not meet the minimum for 'Beg.'")
        return .beginner
    }
    
    static private func calculateCategoryPercentile(current: (Double, [String: Double]), next: (Double, [String: Double]), maxValue: Double) -> Int {
        var category: String = "Beg."
        
        for cat in StrengthLevel.categories.reversed() {
            if let currentLevel = current.1[cat], maxValue >= currentLevel {
                category = cat
                break
            }
        }
        
        print("Determined category: \(category)")
        
        guard let index = StrengthLevel.categories.firstIndex(of: category) else {
            print("Error: Category \(category) not found in predefined categories.")
            return 0
        }
        
        var maxForCategory: Double = 0.0
        var minForCategory: Double = 0.0
        
        if category == "Beg." {
            print("Beg")
            let nextCategory = index < StrengthLevel.categories.count - 1 ? StrengthLevel.categories[index + 1] : nil
            
            minForCategory = 0
            maxForCategory = nextCategory != nil ? (current.1[nextCategory ?? ""] ?? 0) - 1 : (current.1[category] ?? 0)
        } else if category == "Elite" {
            print("Elite")
            let nextCategory = index < StrengthLevel.categories.count - 1 ? StrengthLevel.categories[index + 1] : nil
            let currentCategory = index > 0 ? StrengthLevel.categories[index - 1] : nil
            
            minForCategory = currentCategory != nil ? (current.1[currentCategory ?? ""] ?? 0) : (current.1[category] ?? 0)
            maxForCategory = nextCategory != nil ? (current.1[currentCategory ?? ""] ?? 0) * 1.25 : (current.1[category] ?? 0)
        } else {
            print("Normal")
            // normal case
            let nextCategory = index < StrengthLevel.categories.count - 1 ? StrengthLevel.categories[index + 1] : nil
            let currentCategory = index > 0 ? StrengthLevel.categories[index - 1] : nil
            
            minForCategory = currentCategory != nil ? (current.1[currentCategory ?? ""] ?? 0) : (current.1[category] ?? 0)
            maxForCategory = nextCategory != nil ? (current.1[nextCategory ?? ""] ?? 0) - 1 : (current.1[category] ?? 0)
        }
        print("Max for category \(category): \(maxForCategory), Min for category: \(minForCategory)")
        
        let effectiveMax = max(maxForCategory, minForCategory)
        guard effectiveMax > 0 else { return 0 }
        
        let proportion = maxValue / effectiveMax
        
        let enumCategory = StrengthLevel(rawValue: category)
        let percentile = proportion * (enumCategory?.percentile ?? 0)
        
        print("User's max of \(maxValue) in category \(category) with effective max \(effectiveMax) gives proportion \(proportion) and percentile \(percentile)")
        
        return max(0, min(100, Int(round(percentile * 100))))
    }
}
