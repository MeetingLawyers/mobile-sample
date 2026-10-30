import FirebaseMessaging
import MeetingLawyers
import UIKit
import UserNotifications

/// Every MeetingLawyers SDK call the sample makes, in one file you can copy into your app.
final class MeetingLawyersIntegration: NSObject {
    static let shared = MeetingLawyersIntegration()

    enum IntegrationError: LocalizedError {
        case professionalListUnavailable
        case invalidColor(String)

        var errorDescription: String? {
            switch self {
            case .professionalListUnavailable: "Could not create the professional list. Configure and authenticate first."
            case .invalidColor(let name): "\(name) must be #RRGGBB or #RRGGBBAA"
            }
        }
    }

    /// Initializes the SDK: production, or the demo environment with debug logs.
    func configure(apiKey: String, isProduction: Bool) async throws {
        let configuration = MeetingLawyersConfiguration(
            apiKey: apiKey,
            environment: isProduction ? .production : .development,
            logType: isProduction ? .none : .debug
        )
        try await MeetingLawyersApp.configure(configuration)
    }

    /// Colors of the SDK screens shared by iOS and Android, as "#RRGGBB" or "#RRGGBBAA"; a nil color keeps the SDK default.
    struct Theme {
        var primaryColor: String?
        var secondaryColor: String?
        var navigationBarColor: String?
        var incomingMessageColor: String?
        var outgoingMessageColor: String?
    }

    /// Applies the theme colors and, if given, shows the logo in the navigation bar; throws on an invalid color.
    @MainActor
    func configureTheme(_ theme: Theme, logo: UIImage? = nil) throws {
        let primary = try Self.color("primaryColor", theme.primaryColor)
        let secondary = try Self.color("secondaryColor", theme.secondaryColor)
        let navigationBar = try Self.color("navigationBarColor", theme.navigationBarColor)
        let incomingMessage = try Self.color("incomingMessageColor", theme.incomingMessageColor)
        let outgoingMessage = try Self.color("outgoingMessageColor", theme.outgoingMessageColor)
        if let primary { MeetingLawyersApp.setStyle(primaryColor: primary) }
        if let secondary { MeetingLawyersApp.setStyle(secondaryColor: secondary) }
        if let navigationBar { MeetingLawyersApp.setStyle(navigationColor: navigationBar) }
        if let incomingMessage { MeetingLawyersApp.setStyle(incomingBubbleColor: incomingMessage) }
        if let outgoingMessage { MeetingLawyersApp.setStyle(outgoingBubbleColor: outgoingMessage) }
        guard let logo else { return }
        let logoView = UIImageView(image: logo)
        logoView.contentMode = .scaleAspectFit
        logoView.frame = CGRect(x: 0, y: 0, width: 150, height: 32)
        MeetingLawyersApp.setStyle(navigationTitleView: logoView)
    }

    /// Parses a "#RRGGBB" or "#RRGGBBAA" color; nil when not given.
    private static func color(_ name: String, _ hex: String?) throws -> UIColor? {
        guard let hex else { return nil }
        let value = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard value.count == 6 || value.count == 8, value.allSatisfy(\.isHexDigit), let parsed = UInt64(value, radix: 16) else {
            throw IntegrationError.invalidColor(name)
        }
        let rgba = value.count == 6 ? (parsed << 8) | 0xFF : parsed
        return UIColor(red: CGFloat((rgba >> 24) & 0xFF) / 255, green: CGFloat((rgba >> 16) & 0xFF) / 255,
                       blue: CGFloat((rgba >> 8) & 0xFF) / 255, alpha: CGFloat(rgba & 0xFF) / 255)
    }

    /// Signs the user in, then asks for push permission and links this device's token to them.
    func authenticate(userId: String) async throws {
        try await MeetingLawyersApp.authenticate(userId: userId)
        Task { await registerForPushNotifications() }
    }

    var isAuthenticated: Bool {
        MeetingLawyersApp.isAuthenticated()
    }

    /// Signs the user out of the SDK.
    func logout() async throws {
        try await MeetingLawyersApp.logout()
    }

    /// Pushes the professional list onto the app's navigation; tapping a professional opens its chat.
    @MainActor
    func openProfessionalList(in navigationController: UINavigationController) throws {
        guard let list = MeetingLawyersApp.professionalListViewController()?.viewControllers.first else {
            throw IntegrationError.professionalListUnavailable
        }
        navigationController.pushViewController(list, animated: true)
    }

    /// Opens the chat with the professional identified by `professionalHash`.
    @MainActor
    func openChat(professionalHash: String, from viewController: UIViewController) async throws {
        let action = MeetingLawyersAction.chat(filter: .professionalHash(hash: professionalHash))
        try await MeetingLawyersApp.execute(action: action, origin: viewController)
    }
}

// MARK: - Push notifications

extension MeetingLawyersIntegration: MessagingDelegate, UNUserNotificationCenterDelegate {
    /// Takes over push delivery; call it on launch, after `FirebaseApp.configure()`.
    func startHandlingPushNotifications() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    /// Asks for permission and sends the current FCM token to the SDK. Call it after authenticating.
    func registerForPushNotifications() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        if let token = try? await Messaging.messaging().token() {
            try? await MeetingLawyersApp.setFirebaseMessagingToken(token: token)
        }
    }

    /// Forwards token refreshes once a user is signed in.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, MeetingLawyersApp.isAuthenticated() else { return }
        Task { try? await MeetingLawyersApp.setFirebaseMessagingToken(token: fcmToken) }
    }

    /// Lets the SDK present its own pushes in foreground; shows the rest normally.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard MeetingLawyersApp.isMeetingLawyersPush(notification: notification) else {
            completionHandler([.banner, .badge, .sound])
            return
        }
        _ = MeetingLawyersApp.userNotificationCenter(willPresent: notification.request, completionHandler: completionHandler)
    }

    /// Lets the SDK open the chat of a tapped push; ignores the rest.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        guard MeetingLawyersApp.isMeetingLawyersPush(notification: response.notification) else {
            completionHandler()
            return
        }
        _ = MeetingLawyersApp.userNotificationCenter(didReceive: response.notification.request) { _ in
            completionHandler()
        }
    }
}
