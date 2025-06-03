import SwiftUI
import Firebase
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      
    return true
    }
}

/*import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOpts: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Google OAuth callback
        return GIDSignIn.sharedInstance.handle(url)
    }
}*/


@main
struct FitHubApp: App {
    let persistenceController = PersistenceController.shared
    //@StateObject private var notifier = NotificationManager.shared
    @StateObject var userData: UserData = {
        if let loadedUserData = UserData.loadFromFile() {
            // If userData is loaded from file, use it
            return loadedUserData
        } else {
            // Otherwise, use a new instance
            return UserData()
        }
    }()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var exerciseData = ExerciseData()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var toastManager = ToastManager()
    @StateObject private var equipmentData = EquipmentData()
    @StateObject var adjustmentsViewModel: AdjustmentsViewModel = {
        if let loadedAdjustments = AdjustmentsViewModel.loadAdjustmentsFromFile() {
            return loadedAdjustments
        } else {
            // Otherwise, use a new instance
            return AdjustmentsViewModel()
        }
    }()
    @StateObject private var csvLoader = CSVLoader()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if let root = Bundle.main.resourceURL {
                        let fm = FileManager.default
                        print("🔍 Top-level bundle folders:")
                        if let contents = try? fm.contentsOfDirectory(atPath: root.path) {
                            contents.forEach { print("• \($0)") }
                        }
                        
                        print("\n🔍 Show first 20 PNGs anywhere in bundle:")
                        let pngs = Bundle.main.paths(forResourcesOfType: "png", inDirectory: nil)
                        pngs.prefix(20).forEach { print("• \($0)") }
                    }
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                //.environmentObject(notifier)
                .environmentObject(userData)
                /*.task {
                                    // ① Discover current OS status
                                    await notifier.refreshAuthorizationStatus()

                                    // ② Reconcile with stored preference
                                    if userData.allowedNotifications {
                                        // User *wants* them → make sure OS is authorised
                                        if !notifier.isAuthorized {
                                            await notifier.requestAuthorization()
                                            if !notifier.isAuthorized {          // user denied dialog
                                                userData.allowedNotifications = false
                                            }
                                        }
                                    } else {
                                        // User *doesn’t* want them → clean slate
                                        await notifier.cancelAll()
                                    }
                                }*/
                .environmentObject(healthKitManager)
                .environmentObject(exerciseData)
                .environmentObject(timerManager)
                .environmentObject(toastManager)
                .environmentObject(equipmentData)  
                .environmentObject(adjustmentsViewModel)
                .environmentObject(csvLoader)
        }
    }
}

var dismissKeyboardButton: some View {
    Button(action: {
        // Move any potential non-UI related work off the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Perform I/O or any non-UI operations here if needed in the future

            // UI work should remain on the main thread
            DispatchQueue.main.async {
                // Dismiss the keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }) {
        Image(systemName: "keyboard.chevron.compact.down")
            .resizable()
            .frame(width: 24, height: 24)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .clipShape(Circle())
            .shadow(radius: 10)
            .padding()
    }
    .transition(.scale) // Add a transition effect when the button appears/disappears
}

func smartFormat(_ value: Double) -> String {
    let roundedValue = round(value * 100) / 100 // Round to two decimal places
    if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
        // It's effectively an integer
        return String(format: "%.0f", roundedValue)
    } else {
        // Keep the two decimal precision
        return String(format: "%.2f", roundedValue).trimmingCharacters(in: CharacterSet(charactersIn: "0").union(.punctuationCharacters))
    }
}

func formatDate(_ date: Date,
                dateStyle: DateFormatter.Style = .medium,
                timeStyle: DateFormatter.Style = .short,
                timeZone: TimeZone = .current) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    formatter.timeZone = timeZone
    return formatter.string(from: date)
}

func timeString(from totalSeconds: Int) -> String {
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = (totalSeconds % 3600) % 60
    return "\(hours > 0 ? "\(hours):" : "")\(String(format: "%02d:%02d", minutes, seconds))"
}

func formatTime(_ seconds: Int) -> String {
     let minutes = seconds / 60
     let remainderSeconds = seconds % 60
     return "\(minutes) min \(remainderSeconds) sec"
 }

func formatTimeShort(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainderSeconds = seconds % 60
    
    if remainderSeconds == 0 && minutes != 0 {
        return "\(minutes) min"
    } else if remainderSeconds != 0 && minutes != 0 {
        return "\(minutes) min \(remainderSeconds) sec"
    } else {
        return "\(remainderSeconds) sec"
    }
 }

func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if hours > 0 {
        return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours) hour\(hours > 1 ? "s" : "")"
    } else {
        return "\(remainingMinutes) minute\(remainingMinutes > 1 ? "s" : "")"
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension String {
    func removingCharacters(in set: CharacterSet) -> String {
        self.components(separatedBy: set).joined()
    }
}

// Helper extension for averaging an array
extension Array where Element: Numeric {
    var average: Double? {
        guard !isEmpty else { return nil }
        let sum = reduce(0, +)
        return Double(truncating: sum as! NSNumber) / Double(count)
    }
}
// Extension for safe array indexing
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
// Splits an array into chunks of a given size.
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
// A safe subscript to prevent out of range errors.
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension View {
    func centerHorizontally() -> some View {
        self.frame(maxWidth: .infinity, alignment: .center)
    }
}

struct CenterVerticallyModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            content
                .padding(.top, 1)
                .padding(.bottom, 1)
        }
    }
}

extension View {
    func centerVertically() -> some View {
        self.modifier(CenterVerticallyModifier())
    }
}

extension Color {
    static let darkGreen = Color(UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0))
    static let darkBlue = Color(UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0))
}

