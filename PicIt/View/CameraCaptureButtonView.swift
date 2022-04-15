//

import SwiftUI

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
        HStack {
            CountdownView(countdownTimer: countdownTime, countdownState: countdownState)
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
