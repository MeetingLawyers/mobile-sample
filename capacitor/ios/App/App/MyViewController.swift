import Capacitor
import UIKit

/// Bridge view controller that registers the MeetingLawyers plugin with Capacitor.
class MyViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(MeetingLawyersPlugin())
    }
}
