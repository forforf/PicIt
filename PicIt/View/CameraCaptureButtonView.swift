//

import SwiftUI

extension CountdownState {
    
    func cameraButtonColor() -> Color {
        switch self {
        case .stopped:
            return .gray
        case .inProgress:
            return .yellow
        case .triggering:
            return .green
        case .complete:
            return .mint
        case .undefined:
            return .black
        case .ready:
            return .white
        }
    }
    
}

struct CameraCaptureButton: View {
    static let log = PicItSelfLog<CameraCaptureButton>.get()
    
    let countdownTime: Double
    let countdownState: CountdownState
    let mediaMode: CameraModel.MediaMode
    var cameraAction: NoArgClosure<Void>

    // TODO: CameraCapture(Button?)Model
    //   cameraAction -> calls CameraModel#capture (capture varies based on media)
    //    ok for CameraCaptureModel([weak]? cameraAction, countdown?)
    
    var buttonView: some View {
        ZStack {
            Circle()
                .foregroundColor(countdownState.cameraButtonColor())
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )

            mediaMode.indicatorView()
        }
    }
    
    var body: some View {

        Button(action: cameraAction, label: {
            buttonView
        })
    }
}

struct CameraCaptureButton_Previews: PreviewProvider {
    static let mediaMode = CameraModel.MediaMode.photo(.ready)
    static var previews: some View {
        ForEach(CameraModel.MediaMode.allCases, id: \.self) { mediaMode in
            VStack {
                CameraCaptureButton(
                    countdownTime: 3.0,
                    countdownState: CountdownState.inProgress,
                    mediaMode: mediaMode,
                    cameraAction: {})
                Text(String(describing: mediaMode)) // Helper for preview
            }

        }
    }
}
