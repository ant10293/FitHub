//
//  NumberedListView.swift
//  FitHub
//
//  Created by Anthony Cantu.
//

import SwiftUI

enum NumberingStyle {
    case oneDot        // "1."
    case oneParen      // "1)"
    case stepWord      // "Step 1:"
    case bullet        // "•" (no number)
    
    func label(for n: Int) -> String {
        switch self {
        case .oneDot:   return "\(n)."
        case .oneParen: return "\(n))"
        case .stepWord: return "Step \(n):"
        case .bullet:   return "•"
        }
    }
}

struct NumberedListView: View {
    let items: [String]
    let prefix: String
    let numberingStyle: NumberingStyle
    let spacing: CGFloat
    
    init(
        items: [String],
        prefix: String = "",
        numberingStyle: NumberingStyle = .oneDot,
        spacing: CGFloat = 4
    ) {
        self.items = items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        self.prefix = prefix
        self.numberingStyle = numberingStyle
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, text in
                NumberedItemView(
                    text: text,
                    index: idx + 1,
                    prefix: prefix,
                    numberingStyle: numberingStyle,
                    maxNumberWidth: maxNumberWidth
                )
            }
        }
    }
    
    private var maxNumberWidth: CGFloat {
        let maxNumber = items.count
        let maxLabel = numberingStyle.label(for: maxNumber)
        let maxPrefix = "\(prefix)\(maxLabel) "
        // Estimate width: roughly 8 points per character for system font
        return CGFloat(maxPrefix.count) * 8
    }
}

private struct NumberedItemView: View {
    let text: String
    let index: Int
    let prefix: String
    let numberingStyle: NumberingStyle
    let maxNumberWidth: CGFloat
    
    var body: some View {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard let firstLine = lines.first else {
            return AnyView(EmptyView())
        }
        
        let continuationLines = Array(lines.dropFirst())
        let numberLabel = numberingStyle.label(for: index)
        
        return AnyView(
            VStack(alignment: .leading, spacing: 2) {
                // First line with number
                HStack(alignment: .top, spacing: 4) {
                    Text("\(prefix)\(numberLabel)")
                        .foregroundStyle(.secondary)
                        .frame(width: maxNumberWidth, alignment: .leading)
                    
                    Text(firstLine)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Continuation lines with indentation
                if !continuationLines.isEmpty {
                    ForEach(continuationLines, id: \.self) { line in
                        HStack(alignment: .top, spacing: 4) {
                            // Spacer to match the width of the number prefix
                            Spacer()
                                .frame(width: maxNumberWidth)
                            
                            Text(line)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        )
    }
}
