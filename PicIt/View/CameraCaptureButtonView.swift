//

import SwiftUI

struct CameraCaptureButton: View {
    static let log = PicItSelfLog<CameraCaptureButton>.get()
    
    let countdown: Countdown
    let mediaState: PicItMediaState
    var cameraAction: NoArgClosure<Void>
    
    // TODO: CameraCapture(Button?)Model
    //   cameraAction -> calls CameraModel#capture (capture varies based on media)
    //    ok for CameraCaptureModel([weak]? cameraAction, countdown?)
    
    var buttonView: some View {
        HStack {
            CountdownView(countdownTimer: countdown.time, countdownState: countdown.state)
            mediaState.indicatorView()
        }
    }
    
    var body: some View {

        Button(action: cameraAction, label: {
            buttonView
        })
        
        // Note that countdown can be in a disabled state.
        // In which case nothing is ever published, so onReceive never fires
        // TODO: This logic belongs somewhere else
            .onReceive(countdown.$state, perform: { countdownState in
                Self.log.info("Received Countdown state change: \(String(describing: countdownState))")
                // Here is where we should do any actions when the countdown is reached
                if countdownState == .triggering {
                    Self.log.debug("Capture after countdown using mediaState: \(String(describing: mediaState))")
                    cameraAction()
                }
            })
    }
}

struct CameraCaptureButton_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PicItMediaState.allCases, id: \.self) { mediaState in
            VStack {
                CameraCaptureButton(countdown: Countdown(), mediaState: mediaState, cameraAction: {})
                Text(String(describing: mediaState))
            }

        }
    }
}
