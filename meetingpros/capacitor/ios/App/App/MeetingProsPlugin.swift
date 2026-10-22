import Capacitor
import UIKit

/// Capacitor bridge to `MeetingProsIntegration`. Copy this file plus `MeetingProsIntegration.swift`
/// (and `src/plugins/meeting-pros/`) into your Capacitor app and register it in your bridge view controller.
@objc(MeetingProsPlugin)
public class MeetingProsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MeetingProsPlugin"
    public let jsName = "MeetingPros"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "configureTheme", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authenticate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openProfessionalList", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openLawyerChat", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "availableFeatures", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openFeature", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAuthenticated", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logout", returnType: CAPPluginReturnPromise)
    ]

    private typealias Integration = MeetingProsIntegration
    private let integration = MeetingProsIntegration.shared

    private static let listTypes: [String: Integration.ProfessionalType] = ["lawyers": .lawyers, "doctors": .doctors, "vets": .vets]
    private static let features: [String: Integration.DoctorsFeature] = [
        "videoCall": .videoCall, "medicalHistory": .medicalHistory, "myHealth": .myHealth,
        "booking": .booking, "appointments": .appointments
    ]

    /// Configures both SDKs.
    @objc func configure(_ call: CAPPluginCall) {
        guard let lawyersApiKey = call.getString("lawyersApiKey"), !lawyersApiKey.isEmpty else {
            call.reject("lawyersApiKey is required")
            return
        }
        let doctorsApiKey = call.getString("doctorsApiKey") ?? ""
        let isProduction = call.getString("environment") != "DEV"
        run(call) {
            try await self.integration.configure(lawyersApiKey: lawyersApiKey, doctorsApiKey: doctorsApiKey, isProduction: isProduction)
        }
    }

    /// Applies the brand color to both SDKs.
    @objc func configureTheme(_ call: CAPPluginCall) {
        guard let color = Self.color(call.getString("primaryColor")) else {
            call.reject("primaryColor must be #RRGGBB or #RRGGBBAA")
            return
        }
        run(call) { self.integration.configureTheme(color: color, logo: nil) }
    }

    /// Signs the user into both SDKs.
    @objc func authenticate(_ call: CAPPluginCall) {
        guard let userId = call.getString("userId"), !userId.isEmpty else {
            call.reject("userId is required")
            return
        }
        run(call) { try await self.integration.authenticate(userId: userId) }
    }

    /// Pushes the lawyers, doctors or vets list onto the app's navigation.
    @objc func openProfessionalList(_ call: CAPPluginCall) {
        guard let type = Self.listTypes[call.getString("type") ?? ""] else {
            call.reject("type must be lawyers, doctors or vets")
            return
        }
        run(call) { try self.integration.openProfessionalList(type, in: try self.navigationController()) }
    }

    /// Opens the chat with a lawyer.
    @objc func openLawyerChat(_ call: CAPPluginCall) {
        guard let hash = call.getString("professionalHash"), !hash.isEmpty else {
            call.reject("professionalHash is required")
            return
        }
        run(call) { try await self.integration.openLawyerChat(professionalHash: hash, from: try self.navigationController()) }
    }

    /// Returns the MeetingDoctors features the company has.
    @objc func availableFeatures(_ call: CAPPluginCall) {
        Task { @MainActor in
            let available = await integration.availableFeatures()
            let names = Self.features.filter { available.contains($0.value) }.map(\.key).sorted()
            call.resolve(["features": names])
        }
    }

    /// Opens a MeetingDoctors feature.
    @objc func openFeature(_ call: CAPPluginCall) {
        guard let feature = Self.features[call.getString("feature") ?? ""] else {
            call.reject("Unknown feature")
            return
        }
        run(call) { try await self.integration.open(feature, in: try self.navigationController()) }
    }

    /// True only while the user is signed into both SDKs.
    @objc func isAuthenticated(_ call: CAPPluginCall) {
        call.resolve(["authenticated": integration.isAuthenticated])
    }

    /// Signs the user out of both SDKs.
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
            throw CAPPluginError.navigationUnavailable
        }
        return navigationController
    }

    /// Parses a "#RRGGBB" or "#RRGGBBAA" hex string into a UIColor.
    private static func color(_ hex: String?) -> UIColor? {
        guard let hex else { return nil }
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard value.count == 6 || value.count == 8, let rgba = UInt64(value, radix: 16) else { return nil }
        let hasAlpha = value.count == 8
        let red = CGFloat((rgba >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = CGFloat((rgba >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = CGFloat((rgba >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? CGFloat(rgba & 0xFF) / 255 : 1
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private enum CAPPluginError: LocalizedError {
    case navigationUnavailable

    var errorDescription: String? { "The bridge view controller is not inside a UINavigationController" }
}
