//

import SwiftUI

extension CountdownState {
    
    func cameraButtonColor() -> Color {
        switch self {
        case .stopped:
            return .picit.gray
        case .inProgress:
            return .picit.yellow
        case .triggering:
            return .picit.lightGreen
        case .complete:
            return .white
        case .undefined:
            return .black
        case .ready:
            return .picit.darkgreen
        }
    }
}

struct CameraCaptureButton: View {
    static let log = PicItSelfLog<CameraCaptureButton>.get()
    static let rotationStartAngle = 270.0
    
    let model: CameraModel
    
    @State var animationAmount = rotationStartAngle
    @State var scaleAmount = 1.0
    @State var showCountdownAnimation = true
    @State var countdownIsRunning = false
    @State var timer = 0.0
    
    @State var mediaModeView: AnyView = AnyView(EmptyView())

    var buttonView: some View {
        ZStack {
            CameraButtonBackgroundView(color: model.countdownState.cameraButtonColor(), scaleAmount: $scaleAmount)
                .overlay(
                    CountdownSweeperView(
                        show: $showCountdownAnimation,
                        isRunning: $countdownIsRunning,
                        timer: $timer)
                    
                        .onReceive(model.$countdownTime) { timer = $0 ?? 0.0 }
                        .onReceive(model.$countdownState) { state in
                            mediaModeView = AnyView(model.mediaMode.indicatorView())
                            switch state {
                            case .inProgress:
                                scaleAmount = 1.0
                                showCountdownAnimation = true
                                countdownIsRunning = true
                            case .stopped:
                                scaleAmount = 1.0
                                showCountdownAnimation = true
                                countdownIsRunning = false
                            case .triggering:
                                scaleAmount = 2.0
                            case .ready, .complete:
                                scaleAmount = 1.0
                                showCountdownAnimation = false
                                countdownIsRunning = false
                            case .undefined, .none:
                                // TODO: Gray out
                                scaleAmount = 0.5
                                showCountdownAnimation = false
                                countdownIsRunning = false
                            }
                        }
                )
            model.mediaMode.indicatorView()
        }
    }
    
    var body: some View {

        Button(action: {
            model.cameraAction()
        }, label: {
            buttonView
        })
    }
}

struct CameraCaptureButton_Previews: PreviewProvider {
    static let dependencies = CameraModel.Dependencies()
    
    static var previews: some View {
        ForEach(CameraModel.MediaMode.allCases, id: \.self) { mediaMode in
            VStack {
                ZStack {
                    Color.gray
                    CameraCaptureButton(model: CameraModel(dependencies))
                }
                Text(String(describing: mediaMode)) // Helper for preview
            }

        }
    }
}
