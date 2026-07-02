import Capacitor
import UIKit

/// Bridge view controller that registers the MeetingLawyers plugin with Capacitor.
/// It lives inside a navigation controller (see Main.storyboard) so native SDK
/// screens can be pushed instead of presented; the bar stays hidden over the web view.
class MyViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(MeetingLawyersPlugin())
        navigationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

extension MyViewController: UINavigationControllerDelegate {
    /// Hides the navigation bar over the web view and shows it for pushed native screens.
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        navigationController.setNavigationBarHidden(viewController is CAPBridgeViewController, animated: animated)
    }
}
