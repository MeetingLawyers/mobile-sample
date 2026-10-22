import Flutter
import UIKit

/// Flutter bridge to `MeetingProsIntegration`: the `meeting_pros` method channel used by
/// `lib/meeting_pros/meeting_pros.dart`. Copy it with `MeetingProsIntegration.swift`.
final class MeetingProsChannel: NSObject, FlutterPlugin {
    private typealias Integration = MeetingProsIntegration
    private let integration = MeetingProsIntegration.shared

    private static let listTypes: [String: Integration.ProfessionalType] = ["lawyers": .lawyers, "doctors": .doctors, "vets": .vets]
    private static let features: [String: Integration.DoctorsFeature] = [
        "videoCall": .videoCall, "medicalHistory": .medicalHistory, "myHealth": .myHealth,
        "booking": .booking, "appointments": .appointments
    ]

    /// Registers the channel; call it from `didInitializeImplicitFlutterEngine`.
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "meeting_pros", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(MeetingProsChannel(), channel: channel)
    }

    /// Routes each Dart call to the integration.
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        Task { @MainActor in
            do {
                result(try await perform(call.method, arguments))
            } catch {
                result(FlutterError(code: call.method, message: error.localizedDescription, details: nil))
            }
        }
    }

    @MainActor
    private func perform(_ method: String, _ arguments: [String: Any]) async throws -> Any? {
        switch method {
        case "configure":
            try await integration.configure(lawyersApiKey: arguments["lawyersApiKey"] as? String ?? "",
                                            doctorsApiKey: arguments["doctorsApiKey"] as? String ?? "",
                                            isProduction: arguments["isProduction"] as? Bool ?? true)
        case "configureTheme":
            integration.configureTheme(color: Self.color(arguments["color"] as? Int ?? 0), logo: nil)
        case "authenticate":
            try await integration.authenticate(userId: arguments["userId"] as? String ?? "")
        case "openProfessionalList":
            guard let type = Self.listTypes[arguments["type"] as? String ?? ""] else { throw ChannelError.invalidArgument("type") }
            try integration.openProfessionalList(type, in: try navigationController())
        case "openLawyerChat":
            let hash = arguments["professionalHash"] as? String ?? ""
            guard !hash.isEmpty else { throw ChannelError.invalidArgument("professionalHash") }
            try await integration.openLawyerChat(professionalHash: hash, from: try navigationController())
        case "availableFeatures":
            let available = await integration.availableFeatures()
            return Self.features.filter { available.contains($0.value) }.map(\.key).sorted()
        case "openFeature":
            guard let feature = Self.features[arguments["feature"] as? String ?? ""] else { throw ChannelError.invalidArgument("feature") }
            try await integration.open(feature, in: try navigationController())
        case "isAuthenticated":
            return integration.isAuthenticated
        case "logout":
            try await integration.logout()
        default:
            return FlutterMethodNotImplemented
        }
        return nil
    }

    /// The navigation controller hosting the Flutter view (see `Main.storyboard`).
    @MainActor
    private func navigationController() throws -> UINavigationController {
        let root = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        guard let navigationController = root as? UINavigationController else { throw ChannelError.navigationUnavailable }
        return navigationController
    }

    /// Converts a Dart 0xAARRGGBB color.
    private static func color(_ argb: Int) -> UIColor {
        UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255, green: CGFloat((argb >> 8) & 0xFF) / 255,
                blue: CGFloat(argb & 0xFF) / 255, alpha: CGFloat((argb >> 24) & 0xFF) / 255)
    }
}

/// Hides the navigation bar over the Flutter view and shows it on the native SDK screens.
final class FlutterNavigationController: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.setNavigationBarHidden(viewController is FlutterViewController, animated: animated)
    }
}

private enum ChannelError: LocalizedError {
    case invalidArgument(String)
    case navigationUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidArgument(let name): "\(name) is required"
        case .navigationUnavailable: "The Flutter view is not inside a UINavigationController"
        }
    }
}
