//
//  PicIt
//

import SwiftUI
import Combine

class AvoidStateChange {
    // The system delete user prompt takes our app out of foreground
    // but from the user point of view the app never left foreground
    // so we should skip any state changes related to moving from
    // background to foreground.
    static var returningFromSystemDeletePrompt: Bool = false
}

extension CameraModel {
    func viewToModelMedia(_ viewMedia: PicItMedia) -> CameraModel.Media {
        return {
            switch viewMedia {
            case .photo:
                return CameraModel.Media.photo
            case .video:
                return CameraModel.Media.video
            }
        }()
    }
}

struct CameraView: View {
    static let log = PicItSelfLog<CameraView>.get()

    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var model = CameraModel()
    
    @State var currentZoomFactor: CGFloat = 1.0
    @State var showSettings: Bool = false
    
    @ObservedObject var countdown: Countdown
    
    @ViewBuilder
    var captureButton: some View {
        // modelMedia is enum of .photo or .video
        let modelMedia = model.viewToModelMedia(SettingsStore.mediaType)
        Button(action: {
            model.capture(media: modelMedia)
        }, label: {
            CountdownView(countdown: countdown)
        })
        
        // Note that countdown can be in a disabled state.
        // In which case nothing is ever published, so onReceive never fires
            .onReceive(countdown.$state, perform: { countdownState in
                Self.log.info("Received Countdown state change: \(String(describing: countdownState))")
                // Here is where we should do any actions when the countdown is reached
                if countdownState == .triggering {
                    // Start media capture (photo or video)
                    let modelMedia = model.viewToModelMedia(SettingsStore.mediaType)
                    CameraView.log.debug("Capture after countdown using media: \(String(describing: modelMedia))")
                    model.capture(media: modelMedia)
                }
            })
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
                                let modelMedia = model.viewToModelMedia(SettingsStore.mediaType)
                                CameraView.log.debug("Configure after appear using media: \(String(describing: modelMedia))")
                                model.configure(media: modelMedia)
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
                            countdown: countdown,
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
                        
                        captureButton
                        
                        Spacer()
                        
                        flipCameraButton
                        
                    }
                    .padding(.horizontal, 20)
                }
                
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
        CameraView(countdown: Countdown())
    }
}
