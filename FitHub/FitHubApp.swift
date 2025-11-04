import SwiftUI
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle universal links and URL schemes
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Handle universal links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            ReferralURLHandler.handleIncoming(url)
            return true
        }
        return false
    }
    
    // Handle custom URL schemes
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ReferralURLHandler.handleIncoming(url)
        return true
    }
}

@main
struct FitHubApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var ctx = AppContext()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ctx)
                .onOpenURL { url in
                    // Handle URL when app is opened from URL
                    ReferralURLHandler.handleIncoming(url)
                }
        }
    }
}
