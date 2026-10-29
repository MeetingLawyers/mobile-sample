import FirebaseMessaging
import MeetingLawyers
import UIKit
import UserNotifications

/// Every MeetingLawyers SDK call the sample makes, in one file you can copy into your app.
final class MeetingLawyersIntegration: NSObject {
    static let shared = MeetingLawyersIntegration()

    enum IntegrationError: LocalizedError {
        case professionalListUnavailable

        var errorDescription: String? {
            "Could not create the professional list. Configure and authenticate first."
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

    /// Colors of the SDK screens shared by iOS and Android; a nil color keeps the SDK default.
    struct Theme {
        var primaryColor: UIColor?
        var secondaryColor: UIColor?
        var navigationBarColor: UIColor?
        var incomingMessageColor: UIColor?
        var outgoingMessageColor: UIColor?
    }

    /// Applies the theme colors and, if given, shows the logo in the navigation bar.
    @MainActor
    func configureTheme(_ theme: Theme, logo: UIImage? = nil) {
        if let color = theme.primaryColor { MeetingLawyersApp.setStyle(primaryColor: color) }
        if let color = theme.secondaryColor { MeetingLawyersApp.setStyle(secondaryColor: color) }
        if let color = theme.navigationBarColor { MeetingLawyersApp.setStyle(navigationColor: color) }
        if let color = theme.incomingMessageColor { MeetingLawyersApp.setStyle(incomingBubbleColor: color) }
        if let color = theme.outgoingMessageColor { MeetingLawyersApp.setStyle(outgoingBubbleColor: color) }
        guard let logo else { return }
        let logoView = UIImageView(image: logo)
        logoView.contentMode = .scaleAspectFit
        logoView.frame = CGRect(x: 0, y: 0, width: 150, height: 32)
        MeetingLawyersApp.setStyle(navigationTitleView: logoView)
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
