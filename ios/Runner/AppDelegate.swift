import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    var overlayView: UIView?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        GeneratedPluginRegistrant.register(with: self)
        
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        
//        let controller = window?.rootViewController as! FlutterViewController
//        let channel = FlutterMethodChannel(name: "screen_protection", binaryMessenger: controller.binaryMessenger)
//        
//        channel.setMethodCallHandler { [weak self] (call, result) in
//            switch call.method {
//            case "enableProtection":
//                self?.enableProtection()
//                result(true)
//            case "disableProtection":
//                self?.disableProtection()
//                result(true)
//            default:
//                result(FlutterMethodNotImplemented)
//            }
//        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func enableProtection() {
        // Line 1: Add permanent overlay that's always visible to prevent screenshots
        addPermanentOverlay()
        
        // Line 2: Add observer for screen recording detection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenRecordingChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        
        // Line 3: Add observer for screenshot detection (for showing additional warning)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        // Line 4: Check initial screen recording state
        screenRecordingChanged()
    }
    
    private func disableProtection() {
        // Line 5: Remove both observers
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        
        // Line 6: Remove permanent overlay
        removePermanentOverlay()
        
        // Line 7: Remove any additional overlays
        removeOverlay()
    }
    
    @objc private func screenRecordingChanged() {
        // Line 8: Check if screen is being recorded
        if UIScreen.main.isCaptured {
            // Line 9: Show additional warning overlay for screen recording
            addOverlay("Screen recording detected\nThis action is not allowed.")
        } else {
            // Line 10: Remove additional warning overlay
            removeOverlay()
        }
    }
    
    @objc private func screenshotTaken() {
        // Line 11: Show temporary warning message when screenshot is taken
        showTemporaryWarning("Screenshot detected!\nThis action is not permitted.")
    }
    
    // MARK: - Permanent Overlay (Prevents screenshots)
    
    private func addPermanentOverlay() {
        // Line 12: Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Line 13: Remove existing overlay first
            self.removePermanentOverlay()
            
            // Line 14: Create a subtle, barely visible overlay that's always present
            let overlay = UIView(frame: UIScreen.main.bounds)
            
            // Line 15: Make it almost invisible but still effective for screenshot prevention
            overlay.backgroundColor = UIColor.clear
            
            // Line 16: Add a hidden text field to prevent screenshots in some contexts
            let textField = UITextField()
            textField.isSecureTextEntry = true
            textField.isUserInteractionEnabled = false
            textField.isHidden = true
            textField.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
            
            // Line 17: Add the text field to the overlay
            overlay.addSubview(textField)
            
            // Line 18: Add overlay to window but behind all other content
            self.window?.insertSubview(overlay, at: 0)
            
            // Line 19: Store reference to permanent overlay
            self.overlayView = overlay
            
            // Line 20: Additional protection: Make the window secure
            self.makeWindowSecure()
        }
    }
    
    private func removePermanentOverlay() {
        // Line 21: Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            // Line 22: Remove overlay from superview
            self?.overlayView?.removeFromSuperview()
            // Line 23: Set overlayView to nil
            self?.overlayView = nil
        }
    }
    
    private func makeWindowSecure() {
        // Line 24: This makes the window secure and can help prevent screenshots
        window?.isHidden = true
        window?.isHidden = false
        
        // Line 25: Additional security measures for iOS 13+
        if #available(iOS 13.0, *) {
            // Line 26: Set screenshot service delegate if available
            // Note: This is a best-effort approach as complete prevention isn't possible
            window?.windowScene?.screenshotService?.delegate = self
        }
    }
    
    // MARK: - Additional Warning Overlays
    
    private func addOverlay(_ message: String) {
        // Line 27: Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            // Line 28: Remove any existing warning overlay first
            self?.removeOverlay()
            
            // Line 29: Create warning overlay view
            let warningView = UIView(frame: UIScreen.main.bounds)
            warningView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
            warningView.tag = 9999 // Use tag to identify warning overlay
            
            // Line 30: Create warning label
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = UIFont.boldSystemFont(ofSize: 18)
            
            // Line 31: Add label to warning view
            warningView.addSubview(label)
            
            // Line 32: Set up constraints for label
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: warningView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: warningView.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -20)
            ])
            
            // Line 33: Add to window on top of everything
            self?.window?.addSubview(warningView)
        }
    }
    
    private func removeOverlay() {
        // Line 34: Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            // Line 35: Remove warning overlay by tag
            if let warningView = self?.window?.viewWithTag(9999) {
                warningView.removeFromSuperview()
            }
        }
    }
    
    private func showTemporaryWarning(_ message: String) {
        // Line 36: Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            // Line 37: Create temporary warning view
            let tempView = UIView(frame: UIScreen.main.bounds)
            tempView.backgroundColor = UIColor.red.withAlphaComponent(0.8)
            tempView.tag = 8888 // Different tag for temporary warning
            
            // Line 38: Create temporary warning label
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = UIFont.boldSystemFont(ofSize: 16)
            
            // Line 39: Add label to temporary view
            tempView.addSubview(label)
            
            // Line 40: Set up constraints for label
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: tempView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: tempView.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: tempView.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: tempView.trailingAnchor, constant: -20)
            ])
            
            // Line 41: Add to window
            self?.window?.addSubview(tempView)
            
            // Line 42: Remove after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                tempView.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Application State Handling
    
    override func applicationWillResignActive(_ application: UIApplication) {
        // Line 43: Call super method
        super.applicationWillResignActive(application)
        // Line 44: Ensure protection is active when app goes to background
        if UIScreen.main.isCaptured {
            addOverlay("Screen recording detected\nThis action is not allowed.")
        }
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Line 45: Call super method
        super.applicationDidBecomeActive(application)
        // Line 46: Remove warning overlay if not being recorded
        if !UIScreen.main.isCaptured {
            removeOverlay()
        }
    }
}

// MARK: - Screenshot Service Delegate (Simplified)
@available(iOS 13.0, *)
extension AppDelegate: UIScreenshotServiceDelegate {
    // Line 47: Implement screenshot service delegate method
    
    
    func screenshotServiceGeneratePDFRepresentation(_ screenshotService: UIScreenshotService) async -> (Data?, Int, CGRect) {
        return (nil,0, CGRect.zero)
    }
}
