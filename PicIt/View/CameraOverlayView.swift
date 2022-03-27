//

import SwiftUI

struct CameraOverlayView: View {
    
    @ObservedObject var countdown: Countdown
    
    @State var countdownState: CountdownState = .undefined
    
    var doPause: NoArgClosure<Void>
    var doRestart: NoArgClosure<Void>
    
    var body: some View {
        VStack {
            CameraOverlayActionView(
                countdownState: $countdownState,
                doPause: doPause,
                doRestart: doRestart
            )
            
        }.onReceive(countdown.$state, perform: { cdState in
                countdownState = cdState
        })
    }
}

struct CameraOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.gray)
            CameraOverlayView(countdown: Countdown(), doPause: {}, doRestart: {})
        }
    }
}
