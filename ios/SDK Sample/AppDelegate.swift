import FirebaseCore
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    /// Configures Firebase and takes over push delivery before any notification can arrive.
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        MeetingLawyersIntegration.shared.startHandlingPushNotifications()
        return true
    }

    /// Uses the scene configuration declared in Info.plist.
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
