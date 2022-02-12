//
//  PicIt
//

import SwiftUI
import Combine

struct CameraView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var model = CameraModel()
    
    @State var currentZoomFactor: CGFloat = 1.0
    @State var countdown: CountdownBase
    
    var captureButton: some View {
        Button(action: {
            model.capturePhoto()
        }, label: {
            CountdownView(countdown: countdown)
        })
        
        // countdown can be an "empty", which really should be called disabled.
        // In which case nothing is ever published, so the on Receive never fires.
        // TODO: Change "EmptyCountdown" to "CountdownDisabled"
            .onReceive(countdown.$countdownState, perform: { countdownState in
                print("Countdown STATE: \(countdownState)")
                if countdownState == .triggering {
                    print("TAKING PICTURE")
                    model.capturePhoto()
                }
            })
        
            .onChange(of: scenePhase) { newPhase in
                print("scenePHase changed to \(newPhase)")
                switch newPhase {
                case .background, .inactive:
                    countdown = EmptyCountdown()
                case .active:
                    countdown = countdown.isEmpty() ? Countdown() : countdown
                @unknown default:
                    countdown = EmptyCountdown()
                }
            }
    }
    
    var capturedPhotoThumbnail: some View {
        Group {
            if model.photo != nil {
                Image(uiImage: model.photo.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                // .animation(.spring())
                
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundColor(.black)
            }
        }
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
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Button(action: {
                        model.switchFlash()
                    }, label: {
                        Image(systemName: model.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .medium, design: .default))
                    })
                        .accentColor(model.isFlashOn ? .yellow : .white)
                    
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
                            model.configure()
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
                    
                    
                    HStack {
                        capturedPhotoThumbnail
                        
                        Spacer()
                        
                        captureButton
                        
                        Spacer()
                        
                        flipCameraButton
                        
                    }
                    .padding(.horizontal, 20)
                }
                
            }
        }
    }
}

// TODO: Do a View_Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(countdown: Countdown())
    }
}