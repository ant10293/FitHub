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
    @State private var rpeLocal: Double = 1
    var exercise: Exercise
    var saveTemplate: () -> Void
    
    var isWarm: Bool {
        exercise.currentSet <= exercise.warmUpSets
    }
    
    init(setDetail: Binding<SetDetail>, shouldDisableNext: Binding<Bool>, exercise: Exercise, saveTemplate: @escaping () -> Void) {
        _setDetail = setDetail
        _shouldDisableNext = shouldDisableNext
        _weightInput = State(initialValue: setDetail.wrappedValue.weight > 0 ? String(Format.smartFormat(setDetail.wrappedValue.weight))  : "")
        _repsInput = State(initialValue: setDetail.wrappedValue.reps > 0 ? String(setDetail.wrappedValue.reps) : "")
        _repsLocal = State(initialValue: setDetail.wrappedValue.reps)
        _rpeLocal = State(initialValue: 1)
                
        self.exercise = exercise
        self.saveTemplate = saveTemplate
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
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
                
                if exercise.type.usesWeight {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8) // Background shape
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray4) : Color(UIColor.secondarySystemBackground))
                            .frame(width: calculateTextWidth(text: weightInput, minWidth: 60, maxWidth: 90), height: 35) // Adjust width/height as needed
                        
                        TextField("wt.", text: Binding<String>(
                            get: { weightInput },
                            set: { newValue in
                                let filtered = InputLimiter.filteredWeight(old: weightInput, new: newValue)
                                weightInput = filtered

                                if let w = Double(filtered), w > 0 {
                                    setDetail.weight = w
                                    shouldDisableNext = false
                                } else {
                                    shouldDisableNext = true
                                }
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
                            Text(weightInstruction.rawValue)
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
                            let filtered = InputLimiter.filteredReps(newValue)
                            repsInput = filtered
                            
                            if let r = Int(filtered), r > 0 {
                                setDetail.reps = r
                                repsLocal = r // new line instead of relying onChange(of: setDetail.reps)
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
                        Text(repsInstruction.rawValue)
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

                Stepper(value: $repsLocal, in: 0...(setDetail.reps * 5), step: 1) {
                    Text("\(repsLocal)")
                        .foregroundStyle(repsLocal < setDetail.reps ? .red : (repsLocal > setDetail.reps ? .green : .primary))
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, -15)
            // this should only be submitted before moving the next set or exercise. but it works fine as is
            .onChange(of: repsLocal) {
                setDetail.repsCompleted = repsLocal
                //print("updated repsCompleted with: \(repsLocal)")
            }
            
            // RPE read-out + slider
            if !isWarm {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("RPE:  ").fontWeight(.bold) + Text(String(format: "%.1f", rpeLocal))
                        
                        Slider(
                            value: Binding(
                                get: { Double(rpeLocal) },
                                set: { newValue in
                                    rpeLocal = newValue
                                    setDetail.rpe = newValue // new line instead of relying onChange(of: rpeLocal)
                                }
                            ),
                            in: 1...10,
                            step: 0.5
                        )
                        .padding(.horizontal)
                    }
                    .padding(.horizontal, -15)   // keeps your original edge-to-edge feel
                    
                    Text("(1 - 10)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, -10) // remove the space that came from adding the rpe range label
            }
        }
        .padding()
        .onChange(of: exercise) { oldValue, newValue in
            if oldValue.id != newValue.id || oldValue.currentSet != newValue.currentSet { // only if exercise or current set changes
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
        repsLocal = setDetail.reps
        rpeLocal = 1
    }
}

