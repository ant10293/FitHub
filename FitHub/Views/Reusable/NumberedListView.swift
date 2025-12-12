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
        spacing: CGFloat = 6
    ) {
        self.items = items.filter { !$0.isEmptyAfterTrim }
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
                    spacing: spacing
                )
            }
        }
    }
}

private struct NumberedItemView: View {
    let text: String
    let index: Int
    let prefix: String
    let numberingStyle: NumberingStyle
    let spacing: CGFloat
    
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
            VStack(alignment: .leading, spacing: spacing) {
                // First line with number
                row(numberLabel: numberLabel, line: firstLine, isFirst: true)
                
                // Continuation lines with indentation
                if !continuationLines.isEmpty {
                    ForEach(continuationLines, id: \.self) { line in
                        row(numberLabel: numberLabel, line: line, isFirst: false)
                        
                    }
                }
            }
        )
    }
    
    private func row(numberLabel: String, line: String, isFirst: Bool) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(prefix)\(numberLabel)")
                .monospacedDigit()
                .bold(numberingStyle == .bullet)
                .foregroundStyle(isFirst ? Color.secondary : .clear)

            Text(line)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
