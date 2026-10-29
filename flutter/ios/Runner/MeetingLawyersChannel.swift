import Flutter
import UIKit

/// Flutter bridge to `MeetingLawyersIntegration`: the `meeting_lawyers` method channel used by
/// `lib/meeting_lawyers/meeting_lawyers.dart`. Copy it with `MeetingLawyersIntegration.swift`.
final class MeetingLawyersChannel: NSObject, FlutterPlugin {
    private let integration = MeetingLawyersIntegration.shared

    /// Registers the channel; call it from `didInitializeImplicitFlutterEngine`.
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "meeting_lawyers", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(MeetingLawyersChannel(), channel: channel)
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
            try await integration.configure(apiKey: try Self.required("apiKey", in: arguments),
                                            isProduction: arguments["isProduction"] as? Bool ?? true)
        case "configureTheme":
            integration.configureTheme(MeetingLawyersIntegration.Theme(
                primaryColor: Self.color(arguments["primaryColor"]),
                secondaryColor: Self.color(arguments["secondaryColor"]),
                navigationBarColor: Self.color(arguments["navigationBarColor"]),
                incomingMessageColor: Self.color(arguments["incomingMessageColor"]),
                outgoingMessageColor: Self.color(arguments["outgoingMessageColor"])
            ))
        case "authenticate":
            try await integration.authenticate(userId: try Self.required("userId", in: arguments))
        case "openProfessionalList":
            try integration.openProfessionalList(in: try navigationController())
        case "openChat":
            try await integration.openChat(professionalHash: try Self.required("professionalHash", in: arguments),
                                           from: try navigationController())
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

    /// A non-empty string argument.
    private static func required(_ name: String, in arguments: [String: Any]) throws -> String {
        guard let value = arguments[name] as? String, !value.isEmpty else { throw ChannelError.invalidArgument(name) }
        return value
    }

    /// Converts a Dart 0xAARRGGBB color; nil when the argument is missing.
    private static func color(_ value: Any?) -> UIColor? {
        guard let argb = value as? Int else { return nil }
        return UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255, green: CGFloat((argb >> 8) & 0xFF) / 255,
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
