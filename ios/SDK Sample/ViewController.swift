import UIKit
import MeetingLawyers

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onClickButton(_ sender: Any) {
        self.launchSdk()
    }
}

extension ViewController {
    private func configStyle() {
        MeetingLawyersApp.setStyle(primaryColor: .blue)
        MeetingLawyersApp.setStyle(secondaryColor: .systemBlue)
        MeetingLawyersApp.setStyle(navigationTitleView: getNavigationLogoView())
        MeetingLawyersApp.setStyle(navigationLeftBarButtons: getNavigationLeftBarButtons())
    }

    @objc private func onClickNavigation() {
        print("onClickNavigation topButtonBar")
    }

    private func launchSdk() {
        Task {
            do {
                let configuration = MeetingLawyersConfiguration(apiKey: Constants.apiKey, environment: RemoteEnvironment.development, logType: .debug)
                try await MeetingLawyersApp.configure(configuration)
                self.configStyle()
                try await MeetingLawyersApp.authenticate(userId: Constants.userId)
                self.launchProfessionalList()
            } catch {
                showAlert(errorMessage: error.localizedDescription)
                print("Error: \(error.localizedDescription)")
            }

        }
    }
    
    private func launchProfessionalList() {
        DispatchQueue.main.async {
            if let result = MeetingLawyersApp.professionalListViewController() {
                self.present(result, animated: true)
            }
        }
    }
}

extension ViewController {

    private func getNavigationLogoView() -> UIView {
        let titleView = UIView(frame: CGRect.zero)
        titleView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "ml_logo")
        imageView.contentMode = .scaleAspectFit

        titleView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 50),
            imageView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor)
        ])
        return titleView
    }

    private func getNavigationLeftBarButtons() -> [UIBarButtonItem] {
        // Add top button bar
        let rightButton = UIBarButtonItem(image: UIImage(systemName: "heart.fill"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(self.onClickNavigationRightButton))
        return [rightButton]
    }
    @objc func onClickNavigationRightButton() {
        print("onClickNavigationRightButton")
    }

    private func showAlert(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: "\(errorMessage)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
