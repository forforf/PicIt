//

import SwiftUI

struct CameraOverlayActionView: View {
    let countdownState: CountdownState
    let doPause: NoArgClosure<Void>
    let doRestart: NoArgClosure<Void>
        
    var timer: some View {
        Image(systemName: "timer")
            .font(.system(size: 50, weight: .medium, design: .default))
            .opacity(0.4)
    }
    
    var pauseImage: some View {
        ZStack {
            timer
            Image(systemName: "pause.fill")
                .font(.system(size: 120, weight: .medium, design: .default))
                .opacity(0.3)
        }

    }
    
    var playImage: some View {
        ZStack {
            timer
            Image(systemName: "play.fill")
                .font(.system(size: 120, weight: .medium, design: .default))
                .opacity(0.3)
        }

    }
    
    var pauseButton: some View {
        Button(action: {
            doPause()
        }, label: {pauseImage})
        .accentColor(.white)
    }
    
    var playButton: some View {
        Button(action: {
            doRestart()
        }, label: {playImage})
        .accentColor(.white)
    }
    
    @ViewBuilder
    var body: some View {
        switch countdownState {
        case .undefined:
            EmptyView()
        case .inProgress:
            pauseButton
        case .stopped, .complete, .ready:
            playButton
        default:
            EmptyView()
        }
    }
}

struct CameraOverlayActionView_Previews: PreviewProvider {
    static let countdownStates: [CountdownState] = [.inProgress, .ready, .undefined]
    
    static var previews: some View {
        Group {
                ZStack {
                    Color(.gray)
                    VStack {
                        Divider()
                        ForEach(countdownStates, id: \.self) { countdownState in
                            CameraOverlayActionView(countdownState: countdownState, doPause: {}, doRestart: {})
                            Rectangle().fill(.white).frame(height: 5)
                        }

                    }
                    
                }
        }
    }
}
