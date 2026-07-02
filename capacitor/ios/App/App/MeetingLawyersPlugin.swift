import Capacitor
import MeetingLawyers
import UIKit
import UserNotifications
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

/// Capacitor bridge to the MeetingLawyers iOS SDK.
/// Self-contained: copy this file (plus `src/plugins/meeting-lawyers/`) into your
/// own Capacitor project and register it in your bridge view controller.
@objc(MeetingLawyersPlugin)
public class MeetingLawyersPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MeetingLawyersPlugin"
    public let jsName = "MeetingLawyers"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "configureTheme", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authenticate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openProfessionalList", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openChatWithProfessional", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "registerForPushNotifications", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAuthenticated", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logout", returnType: CAPPluginReturnPromise)
    ]

    /// Initializes the SDK with the company API key and target environment.
    @objc func configure(_ call: CAPPluginCall) {
        guard let apiKey = call.getString("apiKey"), !apiKey.isEmpty else {
            call.reject("apiKey is required")
            return
        }
        let isDevelopment = call.getString("environment") == "DEV"
        let configuration = MeetingLawyersConfiguration(
            apiKey: apiKey,
            environment: isDevelopment ? .development : .production,
            logType: isDevelopment ? .debug : .none
        )
        Task {
            do {
                try await MeetingLawyersApp.configure(configuration)
                call.resolve()
            } catch {
                call.reject("Configure failed: \(error.localizedDescription)")
            }
        }
    }

    /// Applies the theme colors supported on iOS; unsupported keys are ignored.
    @objc func configureTheme(_ call: CAPPluginCall) {
        Task { @MainActor in
            if let color = Self.color(call.getString("primaryColor")) { MeetingLawyersApp.setStyle(primaryColor: color) }
            if let color = Self.color(call.getString("secondaryColor")) { MeetingLawyersApp.setStyle(secondaryColor: color) }
            if let color = Self.color(call.getString("navigationBarColor")) { MeetingLawyersApp.setStyle(navigationColor: color) }
            if let color = Self.color(call.getString("incomingMessageColor")) { MeetingLawyersApp.setStyle(incomingBubbleColor: color) }
            if let color = Self.color(call.getString("outgoingMessageColor")) { MeetingLawyersApp.setStyle(outgoingBubbleColor: color) }
            if let color = Self.color(call.getString("dividerColor")) { MeetingLawyersApp.setStyle(dividerColor: color) }
            if let color = Self.color(call.getString("videoCallColor")) { MeetingLawyersApp.setStyle(videoCallColor: color) }
            call.resolve()
        }
    }

    /// Parses a "#RRGGBB" or "#RRGGBBAA" hex string into a UIColor.
    private static func color(_ hex: String?) -> UIColor? {
        guard let hex = hex else { return nil }
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard value.count == 6 || value.count == 8, let rgba = UInt64(value, radix: 16) else { return nil }
        let hasAlpha = value.count == 8
        let red = CGFloat((rgba >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = CGFloat((rgba >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = CGFloat((rgba >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? CGFloat(rgba & 0xFF) / 255 : 1
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Authenticates the user in the SDK.
    @objc func authenticate(_ call: CAPPluginCall) {
        guard let userId = call.getString("userId"), !userId.isEmpty else {
            call.reject("userId is required")
            return
        }
        Task {
            do {
                try await MeetingLawyersApp.authenticate(userId: userId)
                call.resolve()
            } catch {
                call.reject("Authentication failed: \(error.localizedDescription)")
            }
        }
    }

    /// Opens the SDK professional list; tapping a professional opens its chat.
    /// Pushes into an existing navigation controller when one is found; presents modally otherwise.
    @objc func openProfessionalList(_ call: CAPPluginCall) {
        Task { @MainActor in
            guard let listNavigationController = MeetingLawyersApp.professionalListViewController(
                delegate: nil,
                filter: ProfessionalListFilter.none
            ) else {
                call.reject("Could not create the professional list. Call configure() and authenticate() first.")
                return
            }
            guard let viewController = self.bridge?.viewController else {
                call.reject("No view controller available to present from")
                return
            }
            if let navigationController = Self.findNavigationController(from: viewController),
               let listViewController = listNavigationController.viewControllers.first {
                navigationController.pushViewController(listViewController, animated: true)
            } else {
                viewController.present(listNavigationController, animated: true)
            }
            call.resolve()
        }
    }

    /// Finds the closest navigation controller in the view hierarchy, if any.
    @MainActor
    private static func findNavigationController(from viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        if let navigationController = viewController.navigationController {
            return navigationController
        }
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return findNavigationController(from: selectedViewController)
        }
        if let presentedViewController = viewController.presentedViewController {
            return findNavigationController(from: presentedViewController)
        }
        return nil
    }

    /// Opens the chat with a specific professional by hash.
    @objc func openChatWithProfessional(_ call: CAPPluginCall) {
        guard let professionalHash = call.getString("professionalHash"), !professionalHash.isEmpty else {
            call.reject("professionalHash is required")
            return
        }
        Task { @MainActor in
            do {
                let action = MeetingLawyersAction.chat(filter: .professionalHash(hash: professionalHash))
                try await MeetingLawyersApp.execute(action: action, origin: self.bridge?.viewController)
                call.resolve()
            } catch {
                call.reject("Could not open the chat: \(error.localizedDescription)")
            }
        }
    }

    /// Asks for notification permission and registers the FCM token with the SDK.
    @objc func registerForPushNotifications(_ call: CAPPluginCall) {
        #if canImport(FirebaseCore) && canImport(FirebaseMessaging)
        Task { @MainActor in
            guard FirebaseApp.app() != nil
                    || Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
                call.reject("Firebase is not configured. Add GoogleService-Info.plist to the iOS app.")
                return
            }
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: options)
            UIApplication.shared.registerForRemoteNotifications()
            call.resolve()
        }
        #else
        call.reject("FirebaseMessaging is not linked. Add the firebase-ios-sdk package to enable push.")
        #endif
    }

    /// Returns whether a user is currently authenticated in the SDK.
    @objc func isAuthenticated(_ call: CAPPluginCall) {
        call.resolve(["authenticated": MeetingLawyersApp.isAuthenticated()])
    }

    /// Logs the user out of the SDK.
    @objc func logout(_ call: CAPPluginCall) {
        Task {
            do {
                try await MeetingLawyersApp.logout()
                call.resolve()
            } catch {
                call.reject("Logout failed: \(error.localizedDescription)")
            }
        }
    }
}

#if canImport(FirebaseMessaging)
extension MeetingLawyersPlugin: MessagingDelegate {
    /// Forwards every FCM token refresh to the SDK.
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task {
            try? await MeetingLawyersApp.setFirebaseMessagingToken(token: fcmToken)
        }
    }
}
#endif

extension MeetingLawyersPlugin: UNUserNotificationCenterDelegate {
    /// Lets the SDK handle its own pushes in foreground; shows the rest normally.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if MeetingLawyersApp.isMeetingLawyersPush(userInfo: notification.request.content.userInfo) {
            _ = MeetingLawyersApp.userNotificationCenter(willPresent: notification.request, completionHandler: completionHandler)
            return
        }
        completionHandler([.banner, .badge, .sound])
    }

    /// Lets the SDK react to taps on its own pushes (e.g. open the chat).
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        if MeetingLawyersApp.isMeetingLawyersPush(userInfo: response.notification.request.content.userInfo) {
            _ = MeetingLawyersApp.userNotificationCenter(didReceive: response.notification.request) { _ in
                completionHandler()
            }
            return
        }
        completionHandler()
    }
}
