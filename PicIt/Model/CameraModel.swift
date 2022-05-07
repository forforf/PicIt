// Extensively modified from: [SwiftCamera](https://github.com/rorodriguez116/SwiftCamera)

import SwiftUI
import Combine
import AVFoundation
import PhotosUI // Used for deleting photos from the Library

// TODO: Figure out a better strategy (perhaps enum?)
//       See implementation in scenePhaseManager for more info
class AvoidStateChange {
    // The system delete user prompt takes our app out of foreground
    // but from the user point of view the app never left foreground
    // so we should skip any state changes related to moving from
    // background to foreground.
    // Note: This is actually a bit tricky. We want to distinguish between
    //   user is mainly in PicIt, but PicIt goes into background
    // vs
    //   user leaves PicIt intentionally (sending PicIt to the background)
    // Example: User swipes on a notification, or does some other task
    //   related to PicIt, but leaves PicIt briefly. This will trigger
    //   a countdown restart
    static var returningFromSystemDeletePrompt: Bool = false
}

// typealias PhotoHandler = (_ sharePic: Photo) -> Void
// TODO: Look into using "Result" type in callbacks
typealias PhotoChangeCompletion = (Bool, Error?) -> Void

protocol CameraModelDependenciesProtocol {
    var countdownDefaults: CountdownDependenciesProtocol { get }
    var countdown: Countdown { get }
    var settings: Settings { get }
    var service: CameraService { get }
}

extension CameraModel {
    
    struct Dependencies: CameraModelDependenciesProtocol {
        
        // Providers generates a new instance of the dependency
        // We can use this as a way to "reset" those dependencies while keeping the model state
        public static func serviceProvider() -> CameraService { CameraService() }
        public static func settingsProvider() -> Settings { Settings() }
        public let countdownDefaults: CountdownDependenciesProtocol = Self.CountdownDefaults()
        public let countdown = Countdown()
        public let settings = Self.settingsProvider()
        public let service = Self.serviceProvider()
        
        // Although it's a deeply nested type, keeping it here has two advantages.
        // 1. Allows the usage of Self
        // 2. Avoids polluting the CameraModel (or higher) namespace with a very specific use case.
        // swiftlint:disable:next nesting
        struct CountdownDefaults: CountdownDependenciesProtocol {
            let referenceTimeProvider = { Date().timeIntervalSince1970 }
            let countdownFrom = Double(Settings.countdownStart)
            let interval = PicItSetting.interval
            let countdownPublisher = TimerPublishers().countdownPublisher
        }
    }
}

final class CameraModel: ObservableObject {
        
    // TODO: Too much inside the model class, maybe move outside the model?
    enum MediaMode: Hashable, CaseIterable {
        case photo(_ state: CameraService.ActionState)
        case video(_ state: CameraService.ActionState)
        
        init(mediaType: PicItMedia) {
            switch mediaType {
            // TODO: Probably a way to dry this up, maybe iterate over the cases?
            case .photo:
                self = .photo(.notReady)
            case .video:
                self = .video(.notReady)
            }
        }
        
        public static var allCases: [MediaMode] = [
            .photo(.ready),
            .photo(.notReady),
            .photo(.inUse),
            .video(.ready),
            .video(.notReady),
            .video(.inUse)
        ]
        
        // Mechanism to update the enum to prevent invalid states
        // TODO: Is there a way to enforce? For example PicItMediaState.videoReady(.photo) works. It'd be nice to prevent (ideally compile time if possible)
        static func updateMedia(currentMode: MediaMode, mediaType: PicItMedia) -> MediaMode {
            var newMode = currentMode // default is no change to mode
            switch currentMode {
            case .photo:
                if mediaType == .video {
                    newMode = .video(.notReady)
                    // TODO: Make ready (perhaps a completion closure)
                }
            case .video:
                if mediaType == .photo {
                    newMode = .photo(.notReady)
                    // TODO: Make ready (perhaps a completion closure)
                }
            }
            return newMode
        }
        
        // TODO: Can this be more DRY?
        static func updateActionState(currentMode: MediaMode, actionState: CameraService.ActionState) -> MediaMode {
            var newMode = currentMode // default is no change to mode
            switch currentMode {
            case .photo:
                newMode = .photo(actionState)
            case .video:
                newMode = .video(actionState)
            }
            return newMode
        }
        
        func getActionState() -> CameraService.ActionState {
            switch self {
            case .photo(let state):
                return state
            case .video(let state):
                return state
            }
        }
    }
    
    static let log = PicItSelfLog<CameraModel>.get()

    private var service: CameraService
    private let countdown: Countdown
    
    // We allow clients access to settings.
    // Mainly so we can pass all the settings to the settings view in a single argument
    var settings: Settings
    
    @Published var countdownTime: Double!
    
    @Published var mediaType: PicItMedia!
    
    @Published var mediaMode: MediaMode = MediaMode(mediaType: Settings.mediaType)
    
    @Published var startCountdownAt: Int!
    
    // TODO: countdownState should be internal, not published
    @Published var countdownState: CountdownState!
    
    @Published var photo: Photo!
    
    // thumbnail can come from a photo or video
    @Published var thumbnail: UIImage!
    
    @Published var shareItem: Any!
    
    @Published var mediaLocalId: String!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = false
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(_ dependencies: CameraModelDependenciesProtocol) {
        // using self explicitly for assignemnt clarity
        self.service = dependencies.service
        self.session = self.service.session
        self.countdown = dependencies.countdown
        self.settings = dependencies.settings
        
        addSubscriptions()
        self.mediaMode = MediaMode.updateActionState(currentMode: self.mediaMode, actionState: .ready)
     }
    
    func resetMode() {
        countdown.reset()
        configure(media: mediaType, didConfigure: {
            DispatchQueue.main.async {
                self.mediaMode = MediaMode.updateActionState(currentMode: self.mediaMode, actionState: .ready)
            }
        })
        
    }
        
    func configure(media: PicItMedia, didConfigure: NoArgClosure<Void>? = nil) {
        service.checkForPermissions()
        service.configure(media: media, didConfigure: didConfigure)
    }

    func startVideoRecording() {
        self.mediaMode = MediaMode.updateActionState(currentMode: self.mediaMode, actionState: .inUse)
        service.startVideoRecording()
    }
    
    func stopVideoRecording() {
        service.stopVideoRecording()
        self.mediaMode = MediaMode.updateActionState(currentMode: self.mediaMode, actionState: .ready)
    }
    
    func capturePhoto() {
        service.capturePhoto()
    }
    
    func flipCamera() {
        service.changeCamera()
    }
    
    func zoom(with factor: CGFloat) {
        service.set(zoom: factor)
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
    
    func countdownStart() {
        countdown.start(Double(settings.countdownStart))
    }
    
    func countdownRestart() {
        countdown.restart()
    }
    
    func countdownStop() {
        countdown.stop()
    }

    func cameraAction() {
        Self.log.debug("Entered camera action with media mode: \(mediaMode)")
        switch mediaMode {
        case .photo(let state):
            if state == .ready {
                capturePhoto()
            } else {
                Self.log.warning("State: \(state) was not ready, no photo taken")
            }
        case .video(let state):
            switch state {
            case .ready:
                mediaMode = .video(.inUse)
                startVideoRecording()
            case .inUse:
                stopVideoRecording()
                mediaMode = .video(.ready)
            default:
                Self.log.warning("State: \(state) was not ready, no video action taken")
            }
        }
        Self.log.debug("Exited camera action with media mode: \(mediaMode)")
    }
    
    // TODO: Is this even being used? old todo: Not sure if this belongs in the "Camera" model, but it's better than being in the view.
    func deletePhoto(localId: String, completion: @escaping PhotoChangeCompletion) {
        DispatchQueue.main.async {
            
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
            print(assets)
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets)
            }, completionHandler: completion)
        }
    }
    
    func scenePhaseManager(_ newPhase: ScenePhase) {
        Self.log.info("newPhase: \(String(describing: newPhase))")
        switch newPhase {
        case .background, .inactive:
            Self.log.debug("App Sent to background")
            // We call reset here so we don't have to call it inline while moving to active state
            // (a bit better performance this way)
            resetMode()
        case .active:
            if AvoidStateChange.returningFromSystemDeletePrompt == false {
                countdownStart()
            } else {
                // TODO: Violates SRP ... handling the model changes should not be here, maybe in AvoidStateChange?
                Self.log.debug("Returning from System Delete, Keep current countdown, should work next try")
                // remove the old photo from the model so we don't have the old preview lying around.
                photo = nil
                thumbnail = nil
                // remove video too
                AvoidStateChange.returningFromSystemDeletePrompt = false
            }

        @unknown default:
            Self.log.warning("Unknown scene phase: \(String(describing: newPhase)). Resetting model")
            resetMode()
        }
    }
    
    private func addSubscriptions() {
        service.$mediaLocalId.sink { [weak self] (localId) in
            guard let id = localId else { return }
            self?.mediaLocalId = id
        }
        .store(in: &self.subscriptions)
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$thumbnail.sink { [weak self] (val) in
            guard let thumb = val else { return }
            self?.thumbnail = thumb
        }
        .store(in: &self.subscriptions)
        
        service.$shareItem.sink { [weak self] (val) in
            guard let shareItem = val else { return }
            self?.shareItem = shareItem
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
        
        self.countdown.$time.sink { [weak self] time in
            self?.countdownTime = time
        }
        .store(in: &self.subscriptions)
        
        self.countdown.$state.sink { [weak self] state in
            self?.countdownState = state
        }
        .store(in: &self.subscriptions)
        
        self.settings.$mediaType.sink { [weak self] media in
            // TODO: Does this result in unnecessary renders if newMode == currentMode?
            let currentMode = self?.mediaMode
            
            // If we have a new mode (i.e. changed from photo to video, it will be initialized in the .notReady state
            let newMode = MediaMode.updateMedia(currentMode: currentMode!, mediaType: media)
            self?.mediaMode = newMode
            self?.mediaType = media
            
            // If the new mode is in the .notReady state, reset it to get it in the .ready state.
            if let actionState = self?.mediaMode.getActionState() {
                switch actionState {
                case .notReady:
                    self?.resetMode()
                default:
                    break
                }
            }
   
        }
        .store(in: &self.subscriptions)
        
        self.settings.$countdownStart.sink { [weak self] start in
            self?.startCountdownAt = start
        }
        .store(in: &self.subscriptions)
    }
}
