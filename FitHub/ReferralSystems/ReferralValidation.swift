//
//  ReferralValidation.swift
//  FitHub
//
//  Created by Anthony Cantu on 11/5/25.
//

import Foundation

// MARK: - Email Validation

/// Validates email format: must match pattern _@_._
/// - Parameter email: The email string to validate
/// - Returns: `true` if email matches pattern something@something.something, `false` otherwise
func isValidEmail(_ email: String) -> Bool {
    let trimmed = email.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return false }
    
    // Basic email validation: something@something.something
    // Pattern: at least one character before @, at least one character after @, then a dot, then at least one character
    let emailRegex = "^[^@]+@[^@]+\\.[^@]+$"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: trimmed)
}

/// Validates and trims an email address
/// - Parameter email: The email string to validate and trim
/// - Returns: A tuple containing the trimmed email (if valid) and an optional error
func validateAndTrimEmail(_ email: String) -> (email: String?, error: ReferralError?) {
    let trimmed = email.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, isValidEmail(trimmed) else {
        return (nil, ReferralError.invalidEmailFormat)
    }
    return (trimmed, nil)
}

/// Gets email validation error message for display (returns nil if email is empty or valid)
/// - Parameter email: The email string to validate
/// - Returns: Error message if email is invalid, `nil` if email is empty or valid
func emailValidationError(_ email: String) -> String? {
    guard !email.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
    let emailResult = validateAndTrimEmail(email)
    return emailResult.error?.localizedDescription
}

/// Checks if email is valid for form submission (non-empty and valid format)
/// - Parameter email: The email string to validate
/// - Returns: `true` if email is non-empty and valid, `false` otherwise
func isEmailValidForSubmission(_ email: String) -> Bool {
    let trimmed = email.trimmingCharacters(in: .whitespaces)
    return !trimmed.isEmpty && isValidEmail(trimmed)
}

// MARK: - Custom Code Validation

/// Gets custom code validation error message for display (returns nil if code is empty or valid)
/// - Parameter code: The custom code string to validate
/// - Returns: Error message if code is invalid, `nil` if code is empty or valid
func customCodeValidationError(_ code: String) -> String? {
    let trimmed = code.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }
    guard ReferralCodeGenerator.isValidCode(trimmed) else {
        return ReferralError.invalidCodeFormat.localizedDescription
    }
    return nil
}

// MARK: - Error Handling

enum ReferralError: Error {
    case invalidEmailFormat
    case invalidCodeFormat
    case codeAlreadyTaken
    case emailHasCodeAlready
    case uidHasCodeAlready
    case unableToGenerateUniqueCode
    case unknownError(String)
    
    var forCustomCode: Bool {
        switch self {
        case .codeAlreadyTaken, .invalidCodeFormat: return true
        default: return false
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .invalidEmailFormat:
            return "Invalid email format. Must be (name@domain.com)"
        case .invalidCodeFormat:
            return "Invalid code format. Code must be 4-10 alphanumeric characters."
        case .codeAlreadyTaken:
            return "This referral code is already taken. Please choose a different code."
        case .emailHasCodeAlready:
            return "This email is already registered with another referral code. Please use a different email or contact support."
        case .uidHasCodeAlready:
            return "You already have a referral code associated with your account. Please contact support."
        case .unableToGenerateUniqueCode:
            return "Unable to generate unique code. Please try again."
        case .unknownError(let e):
            return "Unknown error: \(e)"
        }
    }
}

/// Converts any error to a ReferralError for consistent error handling
/// - Parameter error: The error that occurred
/// - Returns: A ReferralError enum case
func referralError(from error: Error) -> ReferralError {
    if let referralError = error as? ReferralError {
        return referralError
    }
    
    // Backwards compatibility: handle old NSError codes
    if let nsError = error as NSError? {
        switch nsError.code {
        case -1:
            return .invalidCodeFormat
        case -2:
            return .codeAlreadyTaken
        case -3:
            return .unableToGenerateUniqueCode
        case -4:
            return .emailHasCodeAlready
        case -5:
            return .uidHasCodeAlready
        default:
            return .unknownError(nsError.localizedDescription)
        }
    }
    
    // For any other error type, use unknownError
    return .unknownError(error.localizedDescription)
}

enum ReferralAdminError: Error {
    case codeNotFound, malformedDocument, databaseUnavailable
}
