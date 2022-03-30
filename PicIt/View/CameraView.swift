//
//  PicIt
//

import SwiftUI
import Combine

/* Let's think about all the states that should affect the view
 - Preparing (countdown not started) [Does it matter if video or photo?]
 - CountingDown  [Does it matter if video or photo?]
     - Countdown increment (currently comes from countdown.$time)
 - Countdown.$state (InProgress, Ready, Triggering, etc)
 - Video vs Photo mode
 
  TODO: Indicate whether video is recording or not.
    Think about whether countdown should be a separate state or combined
 */
class AvoidStateChange {
    // The system delete user prompt takes our app out of foreground
    // but from the user point of view the app never left foreground
    // so we should skip any state changes related to moving from
    // background to foreground.
    static var returningFromSystemDeletePrompt: Bool = false
}

struct CameraView: View {
    static let log = PicItSelfLog<CameraView>.get()

    @Environment(\.scenePhase) var scenePhase
    
    // TODO: Need to inspect this view to ensure correct form is being used: Observable vs static getter
    @EnvironmentObject var settings: SettingsStore
        
    @State var currentZoomFactor: CGFloat = 1.0
    @State var showSettings: Bool = false

    
    @ObservedObject var model: CameraModel
    @ObservedObject var countdown: Countdown
    
    // TODO: Move this logic into a model
    // TODO: Is it ok to use .wrappedValue?
    func cameraAction() {
        let media = $settings.mediaType.wrappedValue
        let mediaState = $settings.mediaState
        print("Media type (photo or video?): \(media)")
        print("starting media state: \(settings.mediaState)")
        switch mediaState.wrappedValue {
        case .photoReady:
            model.capture(media: media)
        case .videoReady:
            // TODO: guard that media == .video
            settings.mediaState = .videoRecording(media)
            model.capture(media: media)
        case .videoRecording:
            print("TODO: Stop Video Recording")
            // TODO: guard that media == .video
            settings.mediaState = .videoReady(media)
        }
        print("new media state: \(settings.mediaState)")
        
    }
    
    var flipCameraButton: some View {
        Button(action: {
            model.flipCamera()
        }, label: {
            Circle()
                .foregroundColor(Color.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(
                    Image(systemName: "camera.rotate.fill")
                        .foregroundColor(.white))
        })
    }
    
    var settingsButton: some View {
        Button(action: {
            showSettings.toggle()
            if showSettings {
                countdown.stop()
            }
        }, label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .medium, design: .default))
        })
            .accentColor(.white)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }

    var body: some View {
        GeometryReader { reader in
            ZStack {
                
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Button(action: {
                            model.switchFlash()
                        }, label: {
                            Image(systemName: model.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 20, weight: .medium, design: .default))
                        })
                            .accentColor(model.isFlashOn ? .yellow : .white)
                        
                        Spacer()

                        settingsButton
                            
                    }
                    
                    ZStack {
                        CameraPreview(session: model.session)
                            .gesture(
                                DragGesture().onChanged({ (val) in
                                    //  Only accept vertical drag
                                    if abs(val.translation.height) > abs(val.translation.width) {
                                        //  Get the percentage of vertical screen space covered by drag
                                        let percentage: CGFloat = -(val.translation.height / reader.size.height)
                                        //  Calculate new zoom factor
                                        let calc = currentZoomFactor + percentage
                                        //  Limit zoom factor to a maximum of 5x and a minimum of 1x
                                        let zoomFactor: CGFloat = min(max(calc, 1), 5)
                                        //  Store the newly calculated zoom factor
                                        currentZoomFactor = zoomFactor
                                        //  Sets the zoom factor to the capture device session
                                        model.zoom(with: zoomFactor)
                                    }
                                })
                            )
                            .onAppear {
                                let media = settings.mediaType
                                CameraView.log.debug("Configure after appear using media: \(String(describing: media))")
                                model.configure(media: media)
                            }
                            .alert(isPresented: $model.showAlertError, content: {
                                Alert(title: Text(model.alertError.title), message: Text(model.alertError.message), dismissButton: .default(Text(model.alertError.primaryButtonTitle), action: {
                                    model.alertError.primaryAction?()
                                }))
                            })
                            .overlay(
                                Group {
                                    if model.willCapturePhoto {
                                        Color.black
                                    }
                                }
                            )
                        // .animation(.easeInOut)
                        
                        CameraOverlayView(
                            countdownState: countdown.state,
                            doPause: countdown.stop,
                            doRestart: countdown.restart
                        )

                    }
                    
                    HStack {
                        ThumbnailView(photo: model.photo, localId: model.photoLocalId,
                                      shareAction: {
                            Self.log.debug("called shareAction in ThumbnailView closure")

                        }, deleteAction: {
                            AvoidStateChange.returningFromSystemDeletePrompt = true
                            Self.log.debug("Thumbnail: deleteAction. deferCountdownFlag: \(AvoidStateChange.returningFromSystemDeletePrompt)")
                            
                        })
                        
                        Spacer()
                        
                        CameraCaptureButton(countdown: countdown, mediaState: settings.mediaState, cameraAction: cameraAction)
                             
                        Spacer()
                        
                        flipCameraButton
                        
                    }
                    .padding(.horizontal, 20)
                }
                
            }
            .onDisappear {
                print("Camera View Disappeared")
            }
            .onChange(of: scenePhase) { newPhase in
                Self.log.info("newPhase: \(String(describing: newPhase))")
                switch newPhase {
                case .background, .inactive:
                    countdown.stop()
                case .active:
                    if AvoidStateChange.returningFromSystemDeletePrompt == false {
                        Self.log.info("Countdown started")
                        countdown.start()
                    } else {
                        Self.log.debug("Returning from System Delete, Keep current countdown, should work next try")
                        // remove the old photo from the model so we don't have the old preview lying around.
                        self.model.photo = nil
                        AvoidStateChange.returningFromSystemDeletePrompt = false
                    }
                    
                @unknown default:
                    countdown.stop()
                }
                
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(model: CameraModel(), countdown: Countdown())
    }
}
