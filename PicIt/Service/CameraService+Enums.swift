// Source: [SwiftCamera](https://github.com/rorodriguez116/SwiftCamera)

import Foundation

// MARK: CameraService Enums
extension CameraService {
    enum LivePhotoMode {
        case on
        case off
    }
    
    enum DepthDataDeliveryMode {
        case on
        case off
    }
    
    enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    enum ActionState {
        case notReady
        case ready
        case inUse
    }
}
