// Modified from: [SwiftCamera](https://github.com/rorodriguez116/SwiftCamera)

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit

enum CameraSessionOutputMedia {
    case photo
    case video
    
    func mediaHasChanged(_ mediaMode: PicItMedia) -> Bool {
        switch self {
        case .photo:
            return mediaMode != .photo
        case .video:
            return mediaMode != .video
        }
    }
}

// MARK: Class Camera Service, handles setup of AVFoundation needed for a basic camera app.
public class CameraService: NSObject {
    static let log = PicItSelfLog<CameraService>.get()
    
    typealias PhotoCaptureSessionID = String
    
// MARK: Observed Properties UI must react to
    
//    1.
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
//    2.
    @Published public var shouldShowAlertView = false
//    3.
    @Published public var shouldShowSpinner = false
//    4.
    @Published public var willCapturePhoto = false
//    5.
    @Published public var isCameraButtonDisabled = true
//    6.
    @Published public var isCameraUnavailable = true
//    8.
    @Published public var photo: Photo?
    
    @Published public var shareItem: Any?
    
    // thumbnail can come from a photo or video
    @Published public var thumbnail: UIImage?
    
    // TODO: Rename as it handles video too (assuming it works)
    @Published public var mediaLocalId: String?
    
// MARK: Alert properties
    public var alertError: AlertError = AlertError()
    
// MARK: Session Management Properties
    
//    9
    public let session = AVCaptureSession()
//    10
    var isSessionRunning = false
//    12
    var isConfigured = false
//    13
    var setupResult: SessionSetupResult = .success
//    14
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    // MARK: Device Configuration Properties
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    // MARK: Capturing Photos
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    // MARK: KVO and Notifications Properties
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    private var movieFileOutput: AVCaptureMovieFileOutput?
    
    private var cameraSessionOutputMedia: CameraSessionOutputMedia?
    
    public func configure(media: PicItMedia, didConfigure: NoArgClosure<Void>? = nil) {

        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.session.beginConfiguration()
            self.configureSession(media)
            self.session.commitConfiguration()
            if self.setupResult == .success {
                self.isConfigured = true
                Self.log.info("Session configured")
                self.start()
                Self.log.info("Session started")
                didConfigure?()
            } else {
                self.configurationFailed("Setup result was: \(self.setupResult)")
            }
        }
    }
    
    // TODO: Only clear config if it's invalid (basically if setup for video, but now photo)
    public func clearConfig() {
        clearCaptureOutputs()
        clearCaptureInputs()
    }
    
    // MARK: Checks for user's permisions
    public func checkForPermissions() {
        // Check for permission to take photos
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
            
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Access", message: "PicIt doesn't have access to use your camera, please update your privacy settings.", primaryButtonTitle: "Settings", secondaryButtonTitle: nil, primaryAction: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                  options: [:], completionHandler: nil)
                    
                }, secondaryAction: nil)
                self.shouldShowAlertView = true
                self.isCameraUnavailable = true
                self.isCameraButtonDisabled = true
            }
        }
        
        // Check for permissions to save photos
        // TODO: DRY up the repeated actions (identical to actions on Camera authorization
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            PHPhotoLibrary.requestAuthorization({ authStatus in
                if authStatus != .authorized {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
            
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Access", message: "PicIt doesn't have access to use your camera, please update your privacy settings.", primaryButtonTitle: "Settings", secondaryButtonTitle: nil, primaryAction: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                  options: [:], completionHandler: nil)
                    
                }, secondaryAction: nil)
                self.shouldShowAlertView = true
                self.isCameraUnavailable = true
                self.isCameraButtonDisabled = true
            }
        }

    }
    
    // MARK: Session Management
    
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    
    private func validateSetup() -> Bool {
        let setupSuccess = setupResult == .success
        if !setupSuccess {
            Self.log.warning("Setup was not successful.")
        }
        return setupSuccess
    }
    
    private func configurationFailed(_ message: String) {
        Self.log.error("Configuration Failed: \(message)")
        setupResult = .configurationFailed
        session.commitConfiguration()
    }
    
    // TODO: Move addInput/Output to enum(?) so we can call a commone method for adding I/Os
    private func tryAddInput(_ device: AVCaptureDeviceInput) -> Bool {
        if session.canAddInput(device) {
            session.addInput(device)
            return true
        }
        return false
    }
    
    private func retryAddInput(_ device: AVCaptureDeviceInput) -> Bool {
        
        var addInputResult = tryAddInput(device)
        if !addInputResult {
            Self.log.warning("Failed to add input, retrying after clearing. This is expected if the media type has changed")
            clearCaptureInputs()
            addInputResult = tryAddInput(device)
        }
        
        return addInputResult
    }
    
    private func tryAddOutput(_ device: AVCaptureOutput) -> Bool {
        if session.canAddOutput(device) {
            session.addOutput(device)
            return true
        }
        return false
    }
    
    private func retryAddOutput(_ device: AVCaptureOutput) -> Bool {
        var addOutputResult = tryAddOutput(device)
        if !addOutputResult {
            Self.log.warning("Failed to add output, retrying after clearing. This is expected if the media type has changed")
            clearCaptureOutputs()
            addOutputResult = tryAddOutput(device)
        }
        return addOutputResult
    }
    
    private func addAudioInputToSession() {
        // Add an audio input device.
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                Self.log.warning("Default Audio Device not found")
                return
            }
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if !retryAddInput(audioDeviceInput) {
                configurationFailed("Could not add audio device input to the session")
                return
            }
        } catch {
            configurationFailed("Could not create audio device input: \(error)")
        }
        
        Self.log.debug("Added audio input to session")
    }
    
    private func addVideoInputToSession() {
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                configurationFailed("Default video device is unavailable.")
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if !retryAddInput(videoDeviceInput) {
                configurationFailed("Could not add video device input to the session")
                return
            }
            self.videoDeviceInput = videoDeviceInput
        } catch {
            configurationFailed("Couldn't create video device input: \(error)")
            return
        }
        
        Self.log.debug("Added video input to session")
    }
    
    private func updateSessionPresets(_ media: PicItMedia) {
        switch media {
        case .photo:
            session.sessionPreset = .photo
        case .video:
            session.sessionPreset = .high
        }
    }
    
    private func addPhotoOutputToSession() {
        // Add the photo output.
        if !retryAddOutput(photoOutput) {
            configurationFailed("Could not add photo output to the session")
        }
        
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
    }
    
    private func addVideoOutputToSession() {
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if !retryAddOutput(movieFileOutput) {
            configurationFailed("Could not add movie output to the session")
            return
        }
        
        if let connection = movieFileOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        
        self.movieFileOutput = movieFileOutput
    }
    
    // TODO: If wrong media, remove existing output
    private func updateSessionOutput(_ media: PicItMedia) {
        // If cameraSessionOutputMedia exists AND it is different than current media mode
        // then we need to remove the existing output.
        if (cameraSessionOutputMedia?.mediaHasChanged(media)) != nil {
            clearCaptureOutputs()
        }
        switch media {
        case .photo:
            addPhotoOutputToSession()
        case .video:
            addVideoOutputToSession()
        }
    }
    
    private func configureSession(_ media: PicItMedia) {
        updateSessionPresets(media)
        
        addVideoInputToSession()
        addAudioInputToSession()
        
        updateSessionOutput(media)
    }
    
    private func clearCaptureOutputs() {
        for output in session.outputs {
                session.removeOutput(output)
            }
    }
    
    private func clearCaptureInputs() {
        for input in session.inputs {
                session.removeInput(input)
            }
    }
    
    // MARK: Device Configuration
    
    /// - Tag: ChangeCamera
    public func changeCamera() {
        // MARK: Here disable all camera operation related buttons due to configuration is due upon and must not be interrupted
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
        }
        //
        
        // TODO: Evaluate to make sure it will work with video as well as photo configuration
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice?
            
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    if let connection = self.photoOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
            // MARK: EnableCaptureButton Here enable capture button due to successfull setup
                self.isCameraButtonDisabled = false
            }
        }
    }
    
    public func focus(at focusPoint: CGPoint) {
//        let focusPoint = self.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)

        let device = self.videoDeviceInput.device
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .continuousAutoExposure
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// - Tag: Stop capture session
    
    public func stop(completion: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.isSessionRunning {
                if self.setupResult == .success {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if !self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = true
                            self.isCameraUnavailable = true
                            completion?()
                        }
                    }
                }
            }
        }
    }
    
    /// - Tag: Start capture session
    
    public func start() {
//        We use our capture session queue to ensure our UI runs smoothly on the main thread.
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = false
                            self.isCameraUnavailable = false
                        }
                    }
                    
                case .configurationFailed, .notAuthorized:
                    print("Application not authorized to use camera")

                    DispatchQueue.main.async {
                        self.alertError = AlertError(title: "Camera Error", message: "Camera configuration failed. Either your device camera is not available or its missing permissions", primaryButtonTitle: "Accept", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
                        self.shouldShowAlertView = true
                        self.isCameraButtonDisabled = true
                        self.isCameraUnavailable = true
                    }
                }
            }
        }
    }
    
    public func set(zoom: CGFloat) {
        let factor = zoom < 1 ? 1 : zoom
        let device = self.videoDeviceInput.device
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: Capture Photo
    
    /// - Tag: CapturePhoto
    public func capturePhoto() {
        if self.setupResult != .configurationFailed {
            self.isCameraButtonDisabled = true
            
            sessionQueue.async {
                if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = .portrait
                }
                var photoSettings = AVCapturePhotoSettings()
                
                // Capture HEIF photos when supported. Enable according to user settings and high-resolution photos.
                if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                
                // Sets the flash option for this capture.
                if self.videoDeviceInput.device.isFlashAvailable {
                    photoSettings.flashMode = self.flashMode
                }
                
                photoSettings.isHighResolutionPhotoEnabled = true
                
                // Sets the preview thumbnail pixel format
                if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                }
                
                photoSettings.photoQualityPrioritization = .quality
                
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: { [weak self] in
                    // Tells the UI to flash the screen to signal that PicIt took a photo.
                    DispatchQueue.main.async {
                        self?.willCapturePhoto = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self?.willCapturePhoto = false
                    }
                    
                }, completionHandler: { [weak self] (photoCaptureProcessor) in
                    
                    // Reference to photo
                    if let localId = photoCaptureProcessor.photoLocalId {
                        self?.mediaLocalId = localId
                        print("Found photo Id: \(localId)")
                    } else {
                        print("No photo id found")
                    }
                    
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    if let data = photoCaptureProcessor.photoData {
                        self?.photo = Photo(originalData: data) // TODO: After refactor for shareItem, see what else Photo is used for
                        self?.thumbnail = self?.photo?.thumbnailImage
                        self?.shareItem = self?.photo?.image
                        print("passing photo and thumbnail")
                    } else {
                        print("No photo data")
                    }
                    
                    self?.isCameraButtonDisabled = false
                    
                    self?.sessionQueue.async {
                        self?.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }, photoProcessingHandler: { [weak self] animate in
                    // Animates a spinner while photo is processing
                    if animate {
                        self?.shouldShowSpinner = true
                    } else {
                        self?.shouldShowSpinner = false
                    }
                })
                
                // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        } else {
            // TODO: Replace with proper error handling
            print("Setup Failed configuration")
        }
    }
}

// TODO: Add protocol for generating thumbnail.
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    public func startVideoRecording() {
        guard let output = movieFileOutput else {
            Self.log.warning("Tried to start video recoring without any output")
            return
        }
        if output.isRecording {
            Self.log.warning("Tried to start video recoring when already recording")
        } else {
            // Start Recording!

            let movieFileOutputConnection = output.connection(with: .video)
//            // Update the orientation on the movie file output video connection before recording.
//            movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
            
            let availableVideoCodecTypes = output.availableVideoCodecTypes
            
            if availableVideoCodecTypes.contains(.hevc) {
                output.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
            }
            
            // Start recording video to a temporary file.
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            output.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
        }
        Self.log.debug("Starting video recording")
    }
    
    public func stopVideoRecording() {
        movieFileOutput?.stopRecording()
        Self.log.debug("Stopping video recording")
    }

    /// - Tag: DidStartRecording
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        Self.log.warning("Started vidoe recording .... not sure if anything needs to be done here")
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
        }

        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            // TODO: DRY with PhotoCaputreProcesor.saveToPhotoLibrary
            //       Perhaps using enum to distinguish photo/video handling
            // Check the authorization status.
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library and cleanup.
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                        
                        // ID used for deleting (common to video and photos)
                        self.mediaLocalId = creationRequest.placeholderForCreatedAsset?.localIdentifier

                    }, completionHandler: { success, error in
                        if !success {
                            print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        cleanup()
                    }
                    )
                } else {
                    cleanup()
                }
            }
            
            // TODO: Is thumbnail appropriately sized?
            let thumbnail = generateThumbnail(url: outputFileURL)
            self.thumbnail = thumbnail
            self.shareItem = outputFileURL
            Self.log.debug("didFinishRecording saved mov to library and generated thumbnail url: \(String(describing: outputFileURL))")
        } else {
            cleanup()
        }
    }
    
    private func generateThumbnail(url: URL?) -> UIImage? {
        guard let url = url else { return  nil }
        do {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Swift 5.3
            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)

            return UIImage(cgImage: cgImage)
             
        } catch {
            Self.log.error("Unable to generate thumbnail from url: \(url)")
            return nil
        }
    }
}
