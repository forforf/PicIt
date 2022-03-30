//

import SwiftUI

struct CameraOverlayView: View {
    
    var countdownState: CountdownState
    var doPause: NoArgClosure<Void>
    var doRestart: NoArgClosure<Void>
    
    var body: some View {
        VStack {
            CameraOverlayActionView(
                countdownState: countdownState,
                doPause: doPause,
                doRestart: doRestart
            )
        }
    }
}

struct CameraOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.gray)
            CameraOverlayView(countdownState: .ready, doPause: {}, doRestart: {})
        }
    }
}
