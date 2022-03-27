// Source: [SwiftCamera](https://github.com/rorodriguez116/SwiftCamera)

import SwiftUI
import Combine
import AVFoundation
import PhotosUI // Used for deleting photos from the Library

// typealias PhotoHandler = (_ sharePic: Photo) -> Void
// TODO: Look into using "Result" type in callbacks
typealias PhotoChangeCompletion = (Bool, Error?) -> Void

final class CameraModel: ObservableObject {
    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var photoLocalId: String!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = false
    
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
    
    func configure() {
        service.checkForPermissions()
        service.configure()
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
