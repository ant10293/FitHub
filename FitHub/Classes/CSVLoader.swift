//
//  CSVLoader.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/1/25.
//

import Foundation

/*
struct CSVEntry: Codable {
    var id: UUID = UUID()
    let exerciseName: String
    let ageTable: [CSVTable]
    let bwTable: [CSVTable]
}

struct CSVTable: Codable {
    let key: String // "Age" or "BW"
    let rows: [CSVRow]
}

struct CSVRow: Codable {
    let keyValue: Int
    let beg: Double // "Beg."
    let nov: Double // "Nov."
    let int: Double // "Int."
    let adv: Double // "Adv."
    let elite: Double // "Elite"
}
*/

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
    
    static func get1RMValues(for exercise: String, key: String, value: Double, userData: UserData) -> [String: Double] {
        let (basePathAge, basePathBW) = getBasePaths(userData: userData)
        let fileName = key == "Age" ? "\(basePathAge)\(exercise)" : "\(basePathBW)\(exercise)"
        let rows = loadCSV(fileName: fileName)
        let roundedValue = value.rounded()

        let sortedRows: [(Double, [String: Double])] = rows.compactMap { row in
            guard let keyString = row[key], let keyValue = Double(keyString) else {
                return nil // malformed row
            }

            // Convert every other column that can be parsed to Double.
            var dict: [String: Double] = [:]
            for (column, string) in row where column != key {
                if let doubleVal = (string.contains("< 1") ? Double(0) : Double(string)) { dict[column] = doubleVal }
            }
            return (keyValue, dict)

        }.sorted { $0.0 < $1.0 }

        guard !sortedRows.isEmpty else { return [:] }

        for i in 0..<(sortedRows.count - 1) {
            let current = sortedRows[i]
            let next    = sortedRows[i + 1]

            if roundedValue >= current.0 && roundedValue < next.0 {
                return current.1
            }
        }

        return sortedRows.last!.1
    }

    static func predict1RM(using data: [[String: String]], key: String, value: Double, fitnessLevel: StrengthLevel) -> Double {
        let fitnessLevel = fitnessLevel.rawValue
        
        let filteredData = data.compactMap { row -> (Double, Double)? in
            if let keyValue = Double(row[key] ?? ""), let fitnessValue = Double(row[fitnessLevel] ?? "") {
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
                    return y0 + (value - x0) * (y1 - y0) / (x1 - x0)
                }
            }
        }
        return filteredData.last?.1 ?? 0.0
    }
    
    static func getBasePaths(userData: UserData) -> (basePathAge: String, basePathBW: String) {
        var basePath: String = "FitHubAssets/Datasets/"
        if userData.physical.gender == .male {
            basePath += "Male/"
            return ("\(basePath)Age/", "\(basePath)Bodyweight/")
        } else {
            basePath += "Female/"
            return ("\(basePath)Age/", "\(basePath)Bodyweight/")
        }
    }
    
    static func calculateFinal1RM(userData: UserData, exercise: String) -> Double {
        let (basePathAge, basePathBW) = getBasePaths(userData: userData)
        let pathAge = "\(basePathAge)\(exercise)"
        let pathBW = "\(basePathBW)\(exercise)"
        
        let dataAge = loadCSV(fileName: pathAge)
        let dataBW = loadCSV(fileName: pathBW)
        
        let predicted1RM_BW = predict1RM(using: dataBW, key: "BW", value: userData.currentMeasurementValue(for: .weight), fitnessLevel: userData.evaluation.strengthLevel)
        let predicted1RM_Age = predict1RM(using: dataAge, key: "Age", value: Double(userData.profile.age), fitnessLevel: userData.evaluation.strengthLevel)
        
        let final1RM = (2 * predicted1RM_BW + predicted1RM_Age) / 3.0
        //print("Predicted 1RM for \(exercise) - BW: \(predicted1RM_BW), Age: \(predicted1RM_Age), Final: \(final1RM)")
        return final1RM
    }
    
    static func predictRepsForExercise(using data: [[String: String]], key: String, value: Double, fitnessLevel: StrengthLevel) -> Int {
        let fitnessLevel = fitnessLevel.rawValue
        
        // First, filter and transform the data to match expected types
        let filteredData = data.compactMap { row -> (Double, Int)? in
            if let keyValue = Double(row[key] ?? ""), let reps = Int(row[fitnessLevel] ?? "") {
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
    
    static func calculateFinalReps(userData: UserData, exercise: String) -> Int {
        let (basePathAge, basePathBW) = getBasePaths(userData: userData)
        let pathAge = "\(basePathAge)\(exercise)"
        let pathBW = "\(basePathBW)\(exercise)"
        
        let dataAge = loadCSV(fileName: pathAge)
        let dataBW = loadCSV(fileName: pathBW)
        
        let predictedReps_BW = predictRepsForExercise(using: dataBW, key: "BW", value: userData.currentMeasurementValue(for: .weight), fitnessLevel: userData.evaluation.strengthLevel)
        let predictedReps_Age = predictRepsForExercise(using: dataAge, key: "Age", value: Double(userData.profile.age), fitnessLevel: userData.evaluation.strengthLevel)
        
        let finalReps = (2 * predictedReps_BW + predictedReps_Age) / 3
        //print("Predicted Reps for \(exercise) - BW: \(predictedReps_BW), Age: \(predictedReps_Age), Final: \(finalReps)")
        return finalReps
    }
    
    static func calculateExercisePercentile(userData: UserData, exercise: Exercise, maxValue: Double) -> Int {
        let (basePathAge, basePathBW) = getBasePaths(userData: userData)
        let pathAge = "\(basePathAge)\(exercise.url)"
        let pathBW = "\(basePathBW)\(exercise.url)"
        
        let dataAge = loadCSV(fileName: pathAge)
        let dataBW = loadCSV(fileName: pathBW)
        
        let agePercentile = findPercentile(data: dataAge, key: "Age", value: Double(userData.profile.age), maxValue: maxValue)
        let bwPercentile = findPercentile(data: dataBW, key: "BW", value: userData.currentMeasurementValue(for: .weight), maxValue: maxValue)
        
        print("Percentiles determined: Age - \(agePercentile), BW - \(bwPercentile)")
        
        return (agePercentile + bwPercentile) / 2
    }
    
    struct ExCat {
        var exerciseName: String
        var maxValue: Double?
        var bwPath: String = ""
        var agePath: String = ""
        var fitnessCategory: StrengthLevel?
        var percentile: Int?
    }
    
    static func estimateStrengthCategories(userData: UserData, exerciseData: ExerciseData) {
        let (basePathAge, basePathBW) = getBasePaths(userData: userData)
        var categories = [StrengthLevel]()
        let exerciseNames: [String] = ["Bench Press", "Back Squat", "Deadlift", "Push-Up", "Sit-Up", "Bodyweight Squat"]
        var exercises: [ExCat] = []
        
        for name in exerciseNames {
            if let exercise = exerciseData.exercise(named: name), let maxValue = exerciseData.getMax(for: exercise.id) {
                let bwPath = "\(basePathBW)\(exercise.url)"
                let agePath = "\(basePathAge)\(exercise.url)"
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
        
        // Calculate strength percentile
        let strengthPercentile = calculateStrengthPercentile(userData: userData, exercises: &exercises)
        print("Strength percentile: \(strengthPercentile)")
        
        // Dictionary to count occurrences
        var categoryCounts = [StrengthLevel.RawValue: Int]()
        categories.forEach { categoryCounts[$0.rawValue, default: 0] += 1 }
        //print("Category counts: \(categoryCounts)")
        
        // Determine the most frequent category
        let maxCount = categoryCounts.values.max() ?? 1
        let mostFrequentCategories = categoryCounts.filter { $1 == maxCount }.map { $0.key }
        
        let selectedCategory: String
        if mostFrequentCategories.count == 1 {
            selectedCategory = mostFrequentCategories.first! // Return the most frequent category
        } else {
            // If there is a tie or all different, sort and choose the middle
            let sortedCategories = mostFrequentCategories.sorted()
            selectedCategory = sortedCategories[sortedCategories.count / 2]
        }
        print("Selected fitness category: \(selectedCategory)")
        
        if let selectedCategory = StrengthLevel(rawValue: selectedCategory) {
            userData.evaluation.strengthLevel = selectedCategory
        }
        
        userData.evaluation.strengthPercentile = strengthPercentile // Save the strength percentile
    }
    
    static func calculateFitnessCategory(userData: UserData, basePathAge: String, basePathBW: String, maxValue: Double) -> StrengthLevel {
        print("Calculating fitness category for \(basePathAge) and \(basePathBW)")
        let dataAge = loadCSV(fileName: basePathAge)
        let dataBW = loadCSV(fileName: basePathBW)
        
        let fitnessLevelAge = findFitnessLevel(data: dataAge, key: "Age", value: Double(userData.profile.age), maxValue: maxValue)
        let fitnessLevelBW = findFitnessLevel(data: dataBW, key: "BW", value: userData.currentMeasurementValue(for: .weight), maxValue: maxValue)
        
        print("Fitness levels determined: Age - \(fitnessLevelAge), BW - \(fitnessLevelBW)")
        return decideFinalFitnessLevel(fitnessLevelAge, fitnessLevelBW)
    }
    
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
    
    static private func calculateStrengthPercentile(userData: UserData, exercises: inout [ExCat]) -> Int {
        var percentiles: [Int] = []

        for i in 0..<exercises.count {
            if let maxValue = exercises[i].maxValue {
                let percentile = calculatePercentile(
                    userData: userData,
                    basePathAge: exercises[i].agePath,
                    basePathBW: exercises[i].bwPath,
                    maxValue: maxValue
                )
                exercises[i].percentile = percentile
                percentiles.append(percentile)
            }
        }

        guard !percentiles.isEmpty else {
            print("No valid percentiles found.")
            return 0
        }

        let average = percentiles.reduce(0, +) / percentiles.count
        print("Strength percentiles: \(percentiles), Average: \(average)")
        return average
    }
    
    static private func calculatePercentile(userData: UserData, basePathAge: String, basePathBW: String, maxValue: Double) -> Int {
        let dataAge = loadCSV(fileName: basePathAge)
        let dataBW = loadCSV(fileName: basePathBW)
        
        let agePercentile = findPercentile(data: dataAge, key: "Age", value: Double(userData.profile.age), maxValue: maxValue)
        let bwPercentile = findPercentile(data: dataBW, key: "BW", value: userData.currentMeasurementValue(for: .weight), maxValue: maxValue)
        
        print("Percentiles determined: Age - \(agePercentile), BW - \(bwPercentile)")
        
        return (agePercentile + bwPercentile) / 2
    }
    
    static func findPercentile(data: [[String: String]], key: String, value: Double, maxValue: Double) -> Int {
        let maxValue = round(maxValue)
        let filteredData = data.compactMap { row -> (Double, [String: Double])? in
            if let keyValue = Double(row[key] ?? "") {
                var maxValues: [String: Double] = [:]
                for (category, stringValue) in row {
                    if let doubleValue = Double(stringValue) {
                        maxValues[category] = doubleValue
                    }
                }
                return (keyValue, maxValues)
            }
            return nil
        }.sorted(by: { $0.0 < $1.0 })
                
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
        return calculateCategoryPercentile(current: filteredData.last!, next: filteredData.last!, maxValue: maxValue)
    }
    
    static private func findFitnessLevel(data: [[String: String]], key: String, value: Double, maxValue: Double) -> StrengthLevel{
        let maxValue = round(maxValue)
        let filteredData = data.compactMap { row -> (Double, [String: Double])? in
            if let keyValue = Double(row[key] ?? "") {
                var maxValues: [String: Double] = [:]
                for (category, stringValue) in row {
                    if let doubleValue = Double(stringValue) {
                        maxValues[category] = doubleValue
                    }
                }
                return (keyValue, maxValues)
            }
            return nil
        }.sorted(by: { $0.0 < $1.0 })
                
        for i in 0..<filteredData.count-1 {
            let current = filteredData[i]
            let next = filteredData[i+1]
            if value >= current.0 && value < next.0 {
                print("User value falls between \(current.0) and \(next.0)")
                // Compare oneRepMax to the fitness levels in 'current' row
                return compareOneRepMaxToLevels(row: current.1, maxValue: maxValue)
            }
        }
        // Handle values greater than the last range
        if let last = filteredData.last, maxValue >= last.0 {
            print("Rounded oneRepMax \(maxValue) exceeds last range starting at \(last.0).")
            return compareOneRepMaxToLevels(row: last.1, maxValue: maxValue)
        }
        
        print("No appropriate bracket found; using last record.")
        return .beginner
    }
    
    static private func compareOneRepMaxToLevels(row: [String: Double], maxValue: Double) -> StrengthLevel {
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
            maxForCategory = nextCategory != nil ? (current.1[nextCategory!] ?? 0) - 1 : (current.1[category] ?? 0)
        }
        else if category == "Elite" {
            print("Elite")
            let nextCategory = index < StrengthLevel.categories.count - 1 ? StrengthLevel.categories[index + 1] : nil
            let currentCategory = index > 0 ? StrengthLevel.categories[index - 1] : nil
            
            minForCategory = currentCategory != nil ? (current.1[currentCategory!] ?? 0) : (current.1[category] ?? 0)
            maxForCategory = nextCategory != nil ? (current.1[currentCategory!] ?? 0) * 1.25 : (current.1[category] ?? 0)
        }
        else {
            print("Normal")
            // normal case
            let nextCategory = index < StrengthLevel.categories.count - 1 ? StrengthLevel.categories[index + 1] : nil
            let currentCategory = index > 0 ? StrengthLevel.categories[index - 1] : nil
            
            minForCategory = currentCategory != nil ? (current.1[currentCategory!] ?? 0) : (current.1[category] ?? 0)
            maxForCategory = nextCategory != nil ? (current.1[nextCategory!] ?? 0) - 1 : (current.1[category] ?? 0)
        }
        print("Max for category \(category): \(maxForCategory), Min for category: \(minForCategory)")
        
        let effectiveMax = max(maxForCategory, minForCategory)
        let proportion = maxValue / effectiveMax
        
        let enumCategory = StrengthLevel(rawValue: category)
        let percentile = proportion * (enumCategory?.percentile ?? 0)
        
        print("User's max of \(maxValue) in category \(category) with effective max \(effectiveMax) gives proportion \(proportion) and percentile \(percentile)")
        
        return max(0, min(100, Int(round(percentile * 100))))
    }
}
