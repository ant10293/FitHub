//
//  ComplexitySettings.swift
//  FitHub
//
//  Created by Anthony Cantu on 5/19/25.
//

import SwiftUI

// option to disable ExerciseSortOptions picker
// option to save new selections as default
// option to sort by template categories by default when editing a template with categories

struct ComplexitySettings: View {
    @State private var disableSortPicker: Bool = false
    @
    
    var body: some View {
        List {
            Section(header: Text("")) {
                VStack {
                    Toggle("", isOn: )
                        .onChange(of: ) {
                  
                        }
      
                }
                
                VStack {
                    // should be workout reminders?
                    Toggle("", isOn:)
                        .onChange(of: ) {
                        }
                    
  
                }
            }
        }
    }
}

