//
//  Name.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/14/25.
//

import Foundation

enum Name {
    static func getDisplayName(firstName: String?, lastName: String?) -> String? {
        let formattedFirst = firstName?.formatName() ?? ""
        let formattedLast = lastName?.formatName() ?? ""
        let displayName = [formattedFirst, formattedLast]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return displayName.isEmpty ? nil : displayName
    }
    
    static func parseName(
        preferredFirstName: String?,
        preferredLastName: String?,
        fallbackDisplayName: String?,
        firebaseDisplayName: String?
    ) -> (userName: String, firstName: String, lastName: String) {
        let trimmedFirst = (preferredFirstName?.trimmed ?? "")
        let trimmedLast = (preferredLastName?.trimmed ?? "")
        
        if !trimmedFirst.isEmpty || !trimmedLast.isEmpty {
            let first = trimmedFirst.formatName()
            let last = trimmedLast.formatName()
            let userName = last.isEmpty ? first : "\(first) \(last)"
            return (userName, first, last)
        }
        
        let bestDisplay = [fallbackDisplayName, firebaseDisplayName]
            .compactMap { $0?.trimmed }
            .first(where: { !$0.isEmpty }) ?? ""
        let parts = bestDisplay.split(separator: " ")
        let first = parts.first.map(String.init)?.formatName() ?? ""
        let last = parts.dropFirst().joined(separator: " ").formatName()
        let userName = last.isEmpty ? first : "\(first) \(last)"
        return (userName, first, last)
    }
}
