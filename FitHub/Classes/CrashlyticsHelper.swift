//
//  CrashlyticsHelper.swift
//  FitHub
//
//  Helper class for Firebase Crashlytics integration
//

import Foundation
import FirebaseCrashlytics

/// Helper class for consistent Crashlytics logging and error reporting
final class CrashlyticsHelper {
    
    // MARK: - User Identification
    
    /// Sets the current user ID for crash reports
    /// Call this after successful authentication
    static func setUserID(_ userID: String?) {
        guard let userID = userID else {
            Crashlytics.crashlytics().setUserID("anonymous")
            return
        }
        Crashlytics.crashlytics().setUserID(userID)
    }
    
    /// Sets user email (non-sensitive identifier)
    static func setUserEmail(_ email: String?) {
        Crashlytics.crashlytics().setCustomValue(email ?? "no-email", forKey: "user_email")
    }
    
    // MARK: - Custom Logging
    
    /// Logs an informational message
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    /// Logs an error with context
    static func logError(_ error: Error, context: String) {
        Crashlytics.crashlytics().log("\(context): \(error.localizedDescription)")
    }
    
    // MARK: - Custom Keys (Context)
    
    /// Sets membership type for crash context
    static func setMembershipType(_ type: String) {
        Crashlytics.crashlytics().setCustomValue(type, forKey: "membership_type")
    }
    
    /// Sets setup state for crash context
    static func setSetupState(_ state: String) {
        Crashlytics.crashlytics().setCustomValue(state, forKey: "setup_state")
    }
    
    /// Sets whether user is working out
    static func setWorkingOut(_ isWorkingOut: Bool) {
        Crashlytics.crashlytics().setCustomValue(isWorkingOut, forKey: "is_working_out")
    }
    
    /// Sets subscription validation state
    static func setSubscriptionValidationState(_ state: String) {
        Crashlytics.crashlytics().setCustomValue(state, forKey: "subscription_validation_state")
    }
    
    // MARK: - Non-Fatal Error Recording
    
    /// Records a non-fatal error (doesn't crash the app)
    static func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        let nsError = error as NSError
        var errorUserInfo = nsError.userInfo
        
        if let userInfo = userInfo {
            errorUserInfo.merge(userInfo) { (_, new) in new }
        }
        
        let customError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: errorUserInfo
        )
        
        Crashlytics.crashlytics().record(error: customError)
    }
    
    /// Records a non-fatal error with a custom message
    static func recordError(message: String, domain: String = "FitHub", code: Int = -1, userInfo: [String: Any]? = nil) {
        var errorInfo: [String: Any] = [
            NSLocalizedDescriptionKey: message
        ]
        
        if let userInfo = userInfo {
            errorInfo.merge(userInfo) { (_, new) in new }
        }
        
        let error = NSError(domain: domain, code: code, userInfo: errorInfo)
        Crashlytics.crashlytics().record(error: error)
    }
}

























































