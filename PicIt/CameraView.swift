//
//  PicIt
//

import SwiftUI

// TODO: Fix the issue where re-running the app has extremely slow behavior. This has something to do with "model.capturePhoto()", as it works fine if that is commented out.
// it also works fine if the app is discarded and then re-opened.

struct CameraView: View {
    var timer: PicItTimer
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var model = CameraModel()
    
    @State var currentZoomFactor: CGFloat = 1.0
    
    @State private var buttonColor: Color = .white
    
    @State private var timerInc = 0.0
    
    private var buttonText: String {
        get {
            let t = timer.timeRemaining(timerInc)
            let displayTime = t < 0.0 ? "" : String(format:"%.2f", t)
            return displayTime
        }
    }
    
    var captureButton: some View {
        Button(action: {
            model.capturePhoto()
        }, label: {
            ZStack {
                Circle()
                    .foregroundColor(buttonColor)
                    .frame(width: 80, height: 80, alignment: .center)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.8), lineWidth: 2)
                            .frame(width: 65, height: 65, alignment: .center)
                    )
                Text("\(buttonText)")
            }
        })

            .onReceive(timer.publisher, perform: { time in
                if timer.timeRemaining(timerInc) > 0 {
                    print(timerInc)
                    buttonColor = .yellow
                    timerInc += timer.interval
                    if timer.timeRemaining(timerInc) <= 0 {
                        // Take Picture
                        model.capturePhoto()
                        buttonColor = .green
                    }
                } else {
                    print("else \(timerInc)")
                    buttonColor = .white
                }

            })
            .onChange(of: scenePhase) { newPhase in
                  switch newPhase {
                  case .background:
                      timer.stopTimer()
                  case .active:
                      timerInc = 0
                      if timer.state == .stopped {
                          timer.restartTimer()
                      }
                  case .inactive:
                      timer.stopTimer()
                  @unknown default:
                      timer.stopTimer()
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

//TODO: Do a View_Preview
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView()
//    }
//}
