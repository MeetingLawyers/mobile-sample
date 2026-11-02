import Capacitor
import UIKit

/// Capacitor bridge to `MeetingLawyersIntegration`. Copy this file plus `MeetingLawyersIntegration.swift`
/// (and `src/plugins/meeting-lawyers/`) into your Capacitor app and register it in your bridge view controller.
@objc(MeetingLawyersPlugin)
public class MeetingLawyersPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MeetingLawyersPlugin"
    public let jsName = "MeetingLawyers"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "configureTheme", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authenticate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openProfessionalList", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openChat", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAuthenticated", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logout", returnType: CAPPluginReturnPromise)
    ]

    private let integration = MeetingLawyersIntegration.shared

    /// Configures the SDK.
    @objc func configure(_ call: CAPPluginCall) {
        guard let apiKey = call.getString("apiKey"), !apiKey.isEmpty else {
            call.reject("apiKey is required")
            return
        }
        let isProduction = call.getString("environment") != "DEV"
        run(call) { try await self.integration.configure(apiKey: apiKey, isProduction: isProduction) }
    }

    /// Applies the theme colors; every color is optional.
    @objc func configureTheme(_ call: CAPPluginCall) {
        let theme = MeetingLawyersIntegration.Theme(
            primaryColor: call.getString("primaryColor"),
            secondaryColor: call.getString("secondaryColor"),
            navigationBarColor: call.getString("navigationBarColor"),
            incomingMessageColor: call.getString("incomingMessageColor"),
            outgoingMessageColor: call.getString("outgoingMessageColor")
        )
        run(call) { try self.integration.configureTheme(theme) }
    }

    /// Signs the user in, asks for push permission and registers the push token.
    @objc func authenticate(_ call: CAPPluginCall) {
        guard let userId = call.getString("userId"), !userId.isEmpty else {
            call.reject("userId is required")
            return
        }
        run(call) { try await self.integration.authenticate(userId: userId) }
    }

    /// Pushes the professional list onto the app's navigation.
    @objc func openProfessionalList(_ call: CAPPluginCall) {
        run(call) { try self.integration.openProfessionalList(in: try self.navigationController()) }
    }

    /// Opens the chat with a professional.
    @objc func openChat(_ call: CAPPluginCall) {
        guard let hash = call.getString("professionalHash"), !hash.isEmpty else {
            call.reject("professionalHash is required")
            return
        }
        run(call) { try await self.integration.openChat(professionalHash: hash, from: try self.navigationController()) }
    }

    /// True while a user is signed in.
    @objc func isAuthenticated(_ call: CAPPluginCall) {
        call.resolve(["authenticated": integration.isAuthenticated])
    }

    /// Signs the user out.
    @objc func logout(_ call: CAPPluginCall) {
        run(call) { try await self.integration.logout() }
    }

    /// Runs an integration call on the main actor and resolves or rejects the plugin call.
    private func run(_ call: CAPPluginCall, _ operation: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            do {
                try await operation()
                call.resolve()
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    /// The navigation controller hosting the web view (see `MyViewController`).
    @MainActor
    private func navigationController() throws -> UINavigationController {
        guard let navigationController = bridge?.viewController?.navigationController else {
            throw MeetingLawyersPluginError.navigationUnavailable
        }
        return navigationController
    }
}

private enum MeetingLawyersPluginError: LocalizedError {
    case navigationUnavailable

    var errorDescription: String? { "The bridge view controller is not inside a UINavigationController" }
}
