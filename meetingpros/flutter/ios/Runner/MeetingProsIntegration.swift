import FirebaseMessaging
import MeetingDoctorsSDK
import MeetingLawyers
import UIKit
import UserNotifications

/// Lawyers (MeetingLawyers SDK) plus doctors and vets (MeetingDoctors SDK) behind one file you can copy
/// into your app: it is the only place that imports either SDK.
final class MeetingProsIntegration: NSObject {
    static let shared = MeetingProsIntegration()

    enum ProfessionalType: CaseIterable {
        case lawyers, doctors, vets
    }

    enum DoctorsFeature: CaseIterable {
        case videoCall, medicalHistory, myHealth, booking, appointments
    }

    enum IntegrationError: LocalizedError {
        case doctorsApiKeyRequired
        case lawyersListUnavailable
        case featureUnavailable(DoctorsFeature)

        var errorDescription: String? {
            switch self {
            case .doctorsApiKeyRequired: "doctorsApiKey is required"
            case .lawyersListUnavailable: "Could not create the lawyers list. Configure and authenticate first."
            case .featureUnavailable(let feature): "\(feature) is not available"
            }
        }
    }

    /// MeetingDoctors speciality ids of the vets list; doctors gets every other speciality.
    private static let vetSpecialities = ["62", "63", "71", "77", "80", "83", "84", "87", "101", "108", "111", "112"]

    private var isConfigured = false

    /// Configures MeetingLawyers, then MeetingDoctors: production, or demo (lawyers) and staging (doctors).
    /// Later calls do nothing.
    func configure(lawyersApiKey: String, doctorsApiKey: String, isProduction: Bool) async throws {
        guard !doctorsApiKey.isEmpty else { throw IntegrationError.doctorsApiKeyRequired }
        guard !isConfigured else { return }
        try await MeetingLawyersApp.configure(MeetingLawyersConfiguration(
            apiKey: lawyersApiKey,
            environment: isProduction ? .production : .development,
            logType: isProduction ? .none : .debug
        ))
        // Leaves crash reporting to your app.
        MeetingDoctors.style.flags.common.sentryEnabled = false
        _ = try await MeetingDoctors.initialize(configuration: MeetingDoctors.Configuration(
            apikey: doctorsApiKey,
            environment: isProduction ? .production : .staging
        ))
        isConfigured = true
    }

    /// Applies the brand color to both SDKs and shows the logo in the lawyers navigation bar.
    @MainActor
    func configureTheme(color: UIColor, logo: UIImage?) {
        MeetingLawyersApp.setStyle(primaryColor: color)
        MeetingLawyersApp.setStyle(secondaryColor: color)
        MeetingLawyersApp.setStyle(navigationColor: color)
        MeetingLawyersApp.setStyle(outgoingBubbleColor: color)
        let logoView = UIImageView(image: logo)
        logoView.contentMode = .scaleAspectFit
        logoView.frame = CGRect(x: 0, y: 0, width: 150, height: 32)
        MeetingLawyersApp.setStyle(navigationTitleView: logoView)

        MeetingDoctors.style.colors.common.primary = color
        MeetingDoctors.style.colors.chat.bubbleBackgroundOutgoing = color
        MeetingDoctors.style.inboxCellStyle = MeetingDoctorsInboxCellStyle.meetingDoctors(
            overlay: .clear, badge: color, speciality: color, hideSchedule: false
        )
        // The app asks for the notification permission itself.
        MeetingDoctors.style.flags.common.showNotificationPermission = false
        MeetingDoctors.updateStyle()
    }

    /// Signs the same user into both SDKs, then asks for push permission and registers the token.
    func authenticate(userId: String) async throws {
        try await MeetingLawyersApp.authenticate(userId: userId)
        try await MeetingDoctors.authenticate(token: userId)
        Task { await registerForPushNotifications() }
    }

    /// True only while the user is signed into both SDKs.
    var isAuthenticated: Bool {
        MeetingLawyersApp.isAuthenticated() && MeetingDoctors.isAuthenticated
    }

    /// Signs the user out of both SDKs, even when one fails, and rethrows the first error.
    func logout() async throws {
        var firstError: Error?
        do { try await MeetingLawyersApp.logout() } catch { firstError = error }
        if MeetingDoctors.isAuthenticated {
            do { try await MeetingDoctors.logout() } catch { firstError = firstError ?? error }
        }
        if let firstError { throw firstError }
    }

    /// Pushes the list of the given type onto the app's navigation; tapping a professional opens its chat.
    @MainActor
    func openProfessionalList(_ type: ProfessionalType, in navigationController: UINavigationController) throws {
        let list: UIViewController
        switch type {
        case .lawyers:
            guard let lawyers = MeetingLawyersApp.professionalListViewController()?.viewControllers.first else {
                throw IntegrationError.lawyersListUnavailable
            }
            list = lawyers
        case .doctors:
            list = try MeetingDoctors.consultationViewController(
                filter: MeetingDoctorsFilter(specialities: Self.vetSpecialities, excludeRoles: true)
            )
        case .vets:
            list = try MeetingDoctors.consultationViewController(
                filter: MeetingDoctorsFilter(specialities: Self.vetSpecialities, excludeRoles: false)
            )
        }
        navigationController.pushViewController(list, animated: true)
    }

    /// Opens the chat with the lawyer identified by `professionalHash`.
    @MainActor
    func openLawyerChat(professionalHash: String, from viewController: UIViewController) async throws {
        let action = MeetingLawyersAction.chat(filter: .professionalHash(hash: professionalHash))
        try await MeetingLawyersApp.execute(action: action, origin: viewController)
    }

    /// The MeetingDoctors features the company has. Call it after authenticating.
    @MainActor
    func availableFeatures() async -> Set<DoctorsFeature> {
        var features = Set<DoctorsFeature>()
        if MeetingDoctors.hasVideoCall() { features.insert(.videoCall) }
        if MeetingDoctors.hasMedicalHistory() { features.insert(.medicalHistory) }
        if MeetingDoctors.isAppointmentsEnabled() { features.insert(.appointments) }
        if (try? await MeetingDoctors.myHealthViewController()) != nil { features.insert(.myHealth) }
        if (try? await MeetingDoctors.bookingWebviewController()) != nil { features.insert(.booking) }
        return features
    }

    /// Opens a MeetingDoctors feature on the app's navigation, or fails when the company does not have it.
    @MainActor
    func open(_ feature: DoctorsFeature, in navigationController: UINavigationController) async throws {
        guard await availableFeatures().contains(feature) else { throw IntegrationError.featureUnavailable(feature) }
        let screen: UIViewController
        switch feature {
        case .videoCall:
            try await MeetingDoctors.startVideocall(origin: navigationController)
            return
        case .medicalHistory: screen = try await MeetingDoctors.medicalHistoryViewController()
        case .myHealth: screen = try await MeetingDoctors.myHealthViewController()
        case .booking: screen = try await MeetingDoctors.bookingWebviewController()
        case .appointments: screen = try await MeetingDoctors.appointmentsViewController()
        }
        navigationController.pushViewController(screen, animated: true)
    }
}

// MARK: - Push notifications

extension MeetingProsIntegration: MessagingDelegate, UNUserNotificationCenterDelegate {
    /// Takes over push delivery; call it on launch, after `FirebaseApp.configure()`.
    func startHandlingPushNotifications() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    /// Asks for permission and sends the current FCM token to both SDKs. Call it after authenticating.
    func registerForPushNotifications() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        if let token = try? await Messaging.messaging().token() {
            await register(token: token)
        }
    }

    /// Forwards token refreshes once a user is signed in.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, isAuthenticated else { return }
        Task { await register(token: fcmToken) }
    }

    /// Lets the SDK that owns a push present it in foreground; shows the rest normally.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if MeetingLawyersApp.isMeetingLawyersPush(notification: notification) {
            _ = MeetingLawyersApp.userNotificationCenter(willPresent: notification.request, completionHandler: completionHandler)
            return
        }
        Task { @MainActor in
            MeetingDoctors.userNotificationCenter(center, willPresent: notification) { result in
                completionHandler((try? result.get()) ?? [.banner, .badge, .sound])
            }
        }
    }

    /// Lets the SDK that owns a tapped push open its chat; ignores the rest.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if MeetingLawyersApp.isMeetingLawyersPush(notification: response.notification) {
            _ = MeetingLawyersApp.userNotificationCenter(didReceive: response.notification.request) { _ in
                completionHandler()
            }
            return
        }
        Task { @MainActor in
            MeetingDoctors.userNotificationCenter(center, didReceive: response) { _ in
                completionHandler()
            }
        }
    }

    /// Sends the FCM token to both SDKs.
    private func register(token: String) async {
        try? await MeetingLawyersApp.setFirebaseMessagingToken(token: token)
        try? await MeetingDoctors.registerFirebaseForNotifications(token: token)
    }
}
