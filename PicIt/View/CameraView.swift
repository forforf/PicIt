//
//  PicIt
//

import SwiftUI
import Combine

struct CameraView: View {
    static let log = PicItSelfLog<CameraView>.get()
        
    @State var currentZoomFactor: CGFloat = 1.0
    @State var showSettings: Bool = false
    @ObservedObject var model: CameraModel
        
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
                model.countdownStop()
            }
        }, label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .medium, design: .default))
        })
            .accentColor(.white)
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: model.settings)
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
                                guard let media = model.mediaType else {
                                    Self.log.warning("Unable to read media type settings (i.e., photo or video")
                                    return
                                }
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
                            countdownState: model.countdownState,
                            doPause: model.countdownStop,
                            doRestart: model.countdownRestart
                        )

                    }
                    
                    HStack {
                        ThumbnailView(
                            thumbnailImage: model.thumbnail,
                            shareItem: model.shareItem,
                            localId: model.mediaLocalId,
                                      shareAction: {
                            Self.log.debug("called shareAction in ThumbnailView closure")

                        }, deleteAction: {
                            AvoidStateChange.returningFromSystemDeletePrompt = true
                            Self.log.debug("Thumbnail: deleteAction. deferCountdownFlag: \(AvoidStateChange.returningFromSystemDeletePrompt)")
                            
                        })
                        
                        Spacer()
                        
                        VStack {
                            CameraCaptureButton(
                                countdownTime: model.countdownTime,
                                countdownState: model.countdownState,
                                mediaMode: model.mediaMode,
                                cameraAction: model.cameraAction)
                            // Note that countdown can be in a disabled state.
                            // In which case nothing is ever published, so onReceive never fires
                            // TODO: This logic belongs somewhere else
                                .onReceive(model.$countdownState, perform: { countdownState in
                                    Self.log.info("Received Countdown state change: \(String(describing: countdownState))")
                                    // Here is where we should do any actions when the countdown is reached
                                    if countdownState == .triggering {
                                        Self.log.debug("Camera Action after countdown")
                                        model.cameraAction()
                                    }
                                })
                        }

                        Spacer()
                        
                        flipCameraButton
                        
                    }
                    .padding(.horizontal, 20)
                }
                
            }
            .onDisappear {
                print("Camera View Disappeared")
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static let dependencies = CameraModel.Dependencies()
        
    static var previews: some View {
        CameraView(model: CameraModel(dependencies))
    }
}
