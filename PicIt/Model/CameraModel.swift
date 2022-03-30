// Source: [SwiftCamera](https://github.com/rorodriguez116/SwiftCamera)

import SwiftUI
import Combine
import AVFoundation
import PhotosUI // Used for deleting photos from the Library

// typealias PhotoHandler = (_ sharePic: Photo) -> Void
// TODO: Look into using "Result" type in callbacks
typealias PhotoChangeCompletion = (Bool, Error?) -> Void

//    @State var mediaState: PicItMediaState = {
//        switch SettingsStore.mediaType {
//        case .photo:
//            return .photoReady
//        case .video:
//            return .videoReady
//        }
//    }()

final class CameraModel: ObservableObject {
    static let log = PicItSelfLog<CameraModel>.get()

    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var photoLocalId: String!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = false
    
    // TODO: should mediaState be in view or model?
//    // TODO: This is not dynamically synced with Settings Store, so it's possible for things to get out of sync.
//    @Published var mediaState: PicItMediaState = {
//        switch SettingsStore.mediaType {
//        case .photo:
//            return .photoReady
//        case .video:
//            return .videoReady
//        }
//    }()
    
    /* Context
     Need to update UI to show recording vs non-recording
     Need to implemnt a saner model (or view model)
     */
    // TODO: Figure out how to handle camera action
//    func cameraAction() {
//        let media = SettingsStore.mediaType
//        print("starting state: \(self.mediaState)")
//        switch self.mediaState {
//        case .photoReady:
//            self.capture(media: media)
//        case .videoReady:
//            self.mediaState = .videoRecording
//            self.capture(media: media)
//        case .videoRecording:
//            print("TODO: Stop Video Recording")
//            self.mediaState = .videoReady
//        }
//        print("new state: \(self.mediaState)")
//
//    }
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photoLocalId.sink { [weak self] (localId) in
            guard let id = localId else { return }
            self?.photoLocalId = id
        }
        .store(in: &self.subscriptions)
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
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
    }
    
    func configure(media: PicItMedia) {
        service.checkForPermissions()
        service.configure(media: media)
    }
    
    func capture(media: PicItMedia) {
        switch media {
        case .photo:
            service.capturePhoto()
        case .video:
            print("TODO: Capture Movie")
        }
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
    
    func photoTimer() {

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
    
//    func withPhoto(completion: PhotoHandler) {
//        service.withPhoto(completion: completion)
//    }
}
