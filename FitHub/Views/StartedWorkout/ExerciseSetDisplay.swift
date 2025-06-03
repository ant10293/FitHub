//
//  ExerciseSetDisplay.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/3/25.
//

import SwiftUI


struct ExerciseSetDisplay: View {
    @Environment(\.colorScheme) var colorScheme // Environment value for color scheme
    @Binding var setDetail: SetDetail
    @Binding var shouldDisableNext: Bool
    @State private var weightInput: String
    @State private var repsInput: String
    @State private var repsLocal: Int
    var exercise: Exercise
    var saveTemplate: () -> Void
    
    
    // Initialize the inputs similar to how it is done in `ExerciseSetDetailView`
    init(setDetail: Binding<SetDetail>, shouldDisableNext: Binding<Bool>, exercise: Exercise, saveTemplate: @escaping () -> Void) {
        _setDetail = setDetail
        _shouldDisableNext = shouldDisableNext
        
        // Initialize weight and reps inputs based on the set details
        _weightInput = State(initialValue: setDetail.wrappedValue.weight > 0 ? (setDetail.wrappedValue.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", setDetail.wrappedValue.weight) : String(setDetail.wrappedValue.weight)) : "")
        _repsInput = State(initialValue: setDetail.wrappedValue.reps > 0 ? String(setDetail.wrappedValue.reps) : "")
        
        _repsLocal = State(initialValue: setDetail.wrappedValue.repsCompleted ?? setDetail.wrappedValue.reps)
        self.exercise = exercise
        self.saveTemplate = saveTemplate
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                let warmCount = exercise.warmUpSets
                let isWarm = exercise.currentSet <= warmCount

                if isWarm {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("warmup")
                            .font(.caption2)                // smaller font
                            .foregroundColor(.secondary)    // grayed out
                        Text("Set \(setDetail.setNumber):")
                            .fontWeight(.bold)
                    }
                } else {
                    Text("Set \(setDetail.setNumber):")
                        .fontWeight(.bold)
                }
                
                if exercise.usesWeight {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8) // Background shape
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray4) : Color(UIColor.secondarySystemBackground))
                            .frame(width: calculateTextWidth(text: weightInput, minWidth: 60, maxWidth: 90), height: 35) // Adjust width/height as needed
                        
                        TextField("wt.", text: Binding<String>(
                            get: { weightInput },
                            set: { newValue in
                                // 1️⃣ Only allow digits and “.”
                                let filtered = newValue.filter { "0123456789.".contains($0) }

                                // 2️⃣ Test the entire string against our pattern
                                let pattern = #"^(\d{0,4})(\.\d{0,2})?$"#
                                if filtered.range(of: pattern, options: .regularExpression) != nil {
                                    // it matches → we accept
                                    weightInput = filtered

                                    // update your model
                                    if let w = Double(filtered), w > 0 {
                                        setDetail.weight = w
                                        shouldDisableNext = false
                                    } else {
                                        shouldDisableNext = true
                                    }
                                }
                            // else: it doesn’t match → drop that keystroke
                            }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .foregroundColor(weightInput == "0" ? .red : .primary)
                        .frame(width: calculateTextWidth(text: weightInput, minWidth: 60, maxWidth: 90), alignment: .center) // Ensure proper width
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("lbs").bold()
                        
                        if let weightInstruction = exercise.weightInstruction {
                            Text(weightInstruction)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.trailing, 2.5)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8) // Background shape
                        .fill(colorScheme == .dark ? Color(UIColor.systemGray4) : Color(UIColor.secondarySystemBackground))
                        .frame(width: calculateTextWidth(text: repsInput, minWidth: 45, maxWidth: 70), height: 35) // Adjust width/height as needed
                    
                    // Reps input with dynamic width
                    TextField("reps", text: Binding<String>(
                        get: { repsInput },
                        set: { newValue in
                            
                            let capped = String(newValue.prefix(3))
                            repsInput = capped

                            if let r = Int(capped), r > 0 {
                                setDetail.reps = r
                                shouldDisableNext = false
                            } else {
                                shouldDisableNext = true
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .foregroundColor(repsInput == "0" ? .red : .primary)
                    .frame(width: calculateTextWidth(text: repsInput, minWidth: 45, maxWidth: 70), alignment: .center)
                }
                
                VStack(alignment: .leading) {
                    Text("Reps").bold()
                    
                    if let repsInstruction = exercise.repsInstruction {
                        Text(repsInstruction)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, -20)
            .padding(.bottom)
                              
            HStack {
                Text("Reps Completed:")
                    .fontWeight(.bold)
                    .padding(.trailing, 10)

                Stepper(value: $repsLocal,in: 0...(setDetail.reps * 5),step: 1) {
                    Text("\(repsLocal)")
                }
            }
            .padding(.horizontal, -15)
            .onChange(of: repsLocal) { oldValue, newValue in
                setDetail.repsCompleted = newValue
            }
        }
        .padding()
        .onChange(of: setDetail.reps) { oldValue, newValue in
            // if user is changing reps or new set or new exercise
            if oldValue != newValue {
                repsLocal = newValue
            }
        }
        .onChange(of: exercise) { oldValue, newValue in
            // only if exercise or current set changes
            if oldValue.id != newValue.id || oldValue.currentSet != newValue.currentSet {
                saveTemplate()
                resetInputs()
            }
        }
    }
    // Function to dynamically calculate text width
    private func calculateTextWidth(text: String, minWidth: CGFloat, maxWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let measured = (text as NSString).size(withAttributes: attributes).width + 20   // 20 pt padding

        // clamp:  not smaller than minWidth, not larger than maxWidth
        return min(max(measured, minWidth), maxWidth)
    }
    
    private func resetInputs() {
        weightInput = setDetail.weight > 0 ? (setDetail.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", setDetail.weight) : String(setDetail.weight)) : ""
        repsInput = setDetail.reps > 0 ? String(setDetail.reps) : ""
        //repsLocal = setDetail.repsCompleted ?? setDetail.reps
    }
}
