import Capacitor
import MeetingLawyers
import UIKit

/// Capacitor bridge to the MeetingLawyers iOS SDK.
/// Self-contained: copy this file (plus `src/plugins/meeting-lawyers/`) into your
/// own Capacitor project and register it in your bridge view controller.
@objc(MeetingLawyersPlugin)
public class MeetingLawyersPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MeetingLawyersPlugin"
    public let jsName = "MeetingLawyers"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authenticate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openProfessionalList", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openChatWithProfessional", returnType: CAPPluginReturnPromise),
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

    /// Presents the SDK professional list; tapping a professional opens its chat.
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
            viewController.present(listNavigationController, animated: true)
            call.resolve()
        }
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
