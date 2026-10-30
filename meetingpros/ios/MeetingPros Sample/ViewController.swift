import UIKit

/// Home screen: sign in, open the lawyers, doctors or vets list, a lawyer chat or a doctors feature, log out.
final class ViewController: UIViewController {
    private typealias Integration = MeetingProsIntegration

    private enum Status: String {
        case missingCredentials = "Missing credentials"
        case configuring = "Configuring…"
        case configured = "Configured"
        case authenticated = "Authenticated"
    }

    private static let brandHex = "#2E7D6B"
    private static let brandColor = UIColor(red: 0x2E / 255, green: 0x7D / 255, blue: 0x6B / 255, alpha: 1)

    private let integration = Integration.shared
    private let statusLabel = UILabel()
    private let messageLabel = UILabel()
    private let hashField = UITextField()
    private lazy var signInButton = makeButton("Sign in") { [unowned self] in signIn() }
    private lazy var listButtons = Integration.ProfessionalType.allCases.map { type in
        makeButton("Open \(type) list") { [unowned self] in openList(type) }
    }
    private lazy var chatButton = makeButton("Open lawyer chat") { [unowned self] in openChat() }
    private lazy var featureButtons = Dictionary(uniqueKeysWithValues: Integration.DoctorsFeature.allCases.map { feature in
        (feature, makeButton("Open \(feature)") { [unowned self] in open(feature) })
    })
    private lazy var logoutButton = makeButton("Log out") { [unowned self] in logOut() }

    private var features = Set<Integration.DoctorsFeature>()
    private var status = Status.configuring {
        didSet { render() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MeetingPros Sample"
        view.backgroundColor = .systemBackground
        layout()
        render()
        Task { await configure() }
    }

    /// Configures both SDKs once, unless the `.env` credentials are missing.
    private func configure() async {
        guard !Constants.lawyersApiKey.isEmpty, !Constants.doctorsApiKey.isEmpty, !Constants.userId.isEmpty else {
            status = .missingCredentials
            show("Fill in ML_API_KEY, MD_API_KEY and ML_USER_ID in the repo-root .env, then rebuild.")
            return
        }
        do {
            try await integration.configure(lawyersApiKey: Constants.lawyersApiKey,
                                            doctorsApiKey: Constants.doctorsApiKey,
                                            isProduction: Constants.isProduction)
            try integration.configureTheme(primaryColor: Self.brandHex, logo: UIImage(named: "ml_logo"))
            if integration.isAuthenticated {
                await signedIn()
            } else {
                status = .configured
            }
        } catch {
            status = .missingCredentials
            show(error)
        }
    }

    private func signIn() {
        run {
            try await self.integration.authenticate(userId: Constants.userId)
            await self.signedIn()
        }
    }

    private func signedIn() async {
        features = await integration.availableFeatures()
        status = .authenticated
    }

    private func openList(_ type: Integration.ProfessionalType) {
        guard let navigationController else { return }
        run { try self.integration.openProfessionalList(type, in: navigationController) }
    }

    private func openChat() {
        let hash = hashField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !hash.isEmpty else {
            show("Type a lawyer's professional hash first.")
            return
        }
        run { try await self.integration.openLawyerChat(professionalHash: hash, from: self) }
    }

    private func open(_ feature: Integration.DoctorsFeature) {
        guard let navigationController else { return }
        run { try await self.integration.open(feature, in: navigationController) }
    }

    private func logOut() {
        run {
            try await self.integration.logout()
            self.features = []
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
        hashField.placeholder = "Lawyer's professional hash"
        hashField.borderStyle = .roundedRect
        hashField.autocapitalizationType = .none
        hashField.autocorrectionType = .no

        let featureViews = Integration.DoctorsFeature.allCases.compactMap { featureButtons[$0] }
        let stack = UIStackView(arrangedSubviews: [statusLabel, messageLabel, signInButton] + listButtons
                                + [hashField, chatButton] + featureViews + [logoutButton])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = Self.brandColor
        return UIButton(configuration: configuration, primaryAction: UIAction { _ in action() })
    }

    func render() {
        statusLabel.text = "Status: \(status.rawValue) (\(Constants.isProduction ? "PROD" : "DEV"))"
        let authenticated = status == .authenticated
        signInButton.isEnabled = status == .configured
        listButtons.forEach { $0.isEnabled = authenticated }
        hashField.isEnabled = authenticated
        chatButton.isEnabled = authenticated
        featureButtons.forEach { feature, button in button.isEnabled = authenticated && features.contains(feature) }
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
