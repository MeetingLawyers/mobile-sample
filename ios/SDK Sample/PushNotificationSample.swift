import FirebaseMessaging
import MeetingLawyers
import UIKit
import FirebaseCore
import Foundation

class PushNotificationSample: NSObject {

    public func configurePush(application: UIApplication) {

        // Enable firebase push notification
        registerFirebasePushNotification()

        // Enable Push notification
        registerForPushNotifications(application: application)

    }
}

extension PushNotificationSample {
    internal func registerFirebasePushNotification() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    internal func registerForPushNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications()

    }
}

// MARK: Firebase Implementation
extension PushNotificationSample: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            Task {
                print("[ApplicationDelegate] Firebase registration token: \(fcmToken)")
                do {
                    try await MeetingLawyersApp.setFirebaseMessagingToken(token: fcmToken)
                    print("[ApplicationDelegate] Token registered correctly")
                } catch {
                    print("[ApplicationDelegate] Error registering token: \(error)")
                }

            }
        }
    }
}

// MARK: Push notification Implementation
extension PushNotificationSample: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ userNotificationCenter: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        _ = MeetingLawyersApp.userNotificationCenter(willPresent: notification.request, completionHandler: completionHandler)
    }

    func userNotificationCenter(_ userNotificationCenter: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        _ = MeetingLawyersApp.userNotificationCenter(didReceive: response.notification.request) { error in
            print("ERROR \(error.debugDescription)")
            completionHandler()
        }

    }
}
