// TODO: Is ViewController an appropriate home for this code?

import UIKit

// Extension to find the key window.
// Primary use is to find the underlying videwcontroller in order to add
// dynamic content (like the share sheet)
extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
}

struct ShareViewController {
    static let log = PicItSelfLog<ShareViewController>.get()
    // I'm not sure a static func is the right thing to do here.
    // TODO: Is a Boolean the right return type?
    static func share(sharePic: UIImage) -> Bool {

        let excludedActivityTypes: [UIActivity.ActivityType] = [
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.markupAsPDF,
            UIActivity.ActivityType.openInIBooks
        ]

        guard let source = UIApplication.shared.keyWindow?.rootViewController else {
            return false
        }
        let vc = UIActivityViewController(
            activityItems: [sharePic],
            applicationActivities: nil
        )
        vc.excludedActivityTypes = excludedActivityTypes
        vc.popoverPresentationController?.sourceView = source.view
        source.present(vc, animated: true)
        return true
    
    }
    
    // A convenient handler for sharing a UIImage, suitable for handling the general case
    static func shareCompletion(_ image: UIImage) {
        if ShareViewController.share(sharePic: image) {
            Self.log.debug("Called share sheet")
        } else {
            Self.log.debug("Failed to call share sheet")
        }
    }
}
