import UIKit

/// Home screen with the same flow as the Capacitor sample: sign in, open the list or a chat, log out.
final class ViewController: UIViewController {
    private enum Status: String {
        case missingCredentials = "Missing credentials"
        case configuring = "Configuring…"
        case configured = "Configured"
        case authenticated = "Authenticated"
    }

    private static let brandHex = "#2E7D6B"
    private static let brandColor = UIColor(red: 0x2E / 255, green: 0x7D / 255, blue: 0x6B / 255, alpha: 1)

    private let integration = MeetingLawyersIntegration.shared
    private let statusLabel = UILabel()
    private let messageLabel = UILabel()
    private let hashField = UITextField()
    private lazy var signInButton = makeButton("Sign in", action: #selector(signIn))
    private lazy var listButton = makeButton("Open professional list", action: #selector(openProfessionalList))
    private lazy var chatButton = makeButton("Open chat", action: #selector(openChat))
    private lazy var logoutButton = makeButton("Log out", action: #selector(logOut))

    private var status = Status.configuring {
        didSet { render() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MeetingLawyers Sample"
        view.backgroundColor = .systemBackground
        layout()
        render()
        Task { await configure() }
    }

    /// Configures the SDK once, unless the `.env` credentials are missing.
    private func configure() async {
        guard !Constants.apiKey.isEmpty, !Constants.userId.isEmpty else {
            status = .missingCredentials
            show("Fill in ML_API_KEY and ML_USER_ID in the repo-root .env, then rebuild.")
            return
        }
        do {
            try await integration.configure(apiKey: Constants.apiKey, isProduction: Constants.isProduction)
            let theme = MeetingLawyersIntegration.Theme(primaryColor: Self.brandHex, secondaryColor: Self.brandHex,
                                                        navigationBarColor: Self.brandHex, outgoingMessageColor: Self.brandHex)
            try integration.configureTheme(theme, logo: UIImage(named: "ml_logo"))
            status = integration.isAuthenticated ? .authenticated : .configured
        } catch {
            status = .missingCredentials
            show(error)
        }
    }

    @objc private func signIn() {
        run {
            try await self.integration.authenticate(userId: Constants.userId)
            self.status = .authenticated
        }
    }

    @objc private func openProfessionalList() {
        guard let navigationController else { return }
        run { try self.integration.openProfessionalList(in: navigationController) }
    }

    @objc private func openChat() {
        let hash = hashField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !hash.isEmpty else {
            show("Type a professional hash first.")
            return
        }
        run { try await self.integration.openChat(professionalHash: hash, from: self) }
    }

    @objc private func logOut() {
        run {
            try await self.integration.logout()
            self.status = .configured
        }
    }

    /// Runs an SDK call and shows its error, if any.
    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        show(nil)
        Task {
            do {
                try await operation()
            } catch {
                show(error)
            }
        }
    }
}

// MARK: - UI

private extension ViewController {
    func layout() {
        statusLabel.font = .preferredFont(forTextStyle: .headline)
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .systemRed
        hashField.placeholder = "Professional hash"
        hashField.borderStyle = .roundedRect
        hashField.autocapitalizationType = .none
        hashField.autocorrectionType = .no

        let stack = UIStackView(arrangedSubviews: [statusLabel, messageLabel, signInButton, listButton,
                                                   hashField, chatButton, logoutButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    func makeButton(_ title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = Self.brandColor
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func render() {
        statusLabel.text = "Status: \(status.rawValue) (\(Constants.isProduction ? "PROD" : "DEV"))"
        let authenticated = status == .authenticated
        signInButton.isEnabled = status == .configured
        listButton.isEnabled = authenticated
        chatButton.isEnabled = authenticated
        hashField.isEnabled = authenticated
        logoutButton.isEnabled = authenticated
    }

    func show(_ message: String?) {
        messageLabel.text = message
        messageLabel.isHidden = message == nil
    }

    func show(_ error: Error) {
        show(error.localizedDescription)
    }
}
