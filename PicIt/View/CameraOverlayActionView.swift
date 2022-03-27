//

import SwiftUI

struct CameraOverlayActionView: View {
    @Binding var countdownState: CountdownState
    var doPause: NoArgClosure<Void>
    var doRestart: NoArgClosure<Void>
        
    var timer: some View {
        Image(systemName: "timer")
            .font(.system(size: 50, weight: .medium, design: .default))
            .opacity(0.2)
    }
    
    var pauseImage: some View {
        VStack {
            timer
            Image(systemName: "pause.fill")
                .font(.system(size: 100, weight: .medium, design: .default))
                .opacity(0.1)
        }

    }
    
    var playImage: some View {
        VStack {
            timer
            Image(systemName: "play.fill")
                .font(.system(size: 100, weight: .medium, design: .default))
                .opacity(0.1)
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
    @State static var inProgress: CountdownState = .inProgress
    @State static var ready: CountdownState = .ready
    @State static var other: CountdownState = .undefined
    
    static var previews: some View {
        Group {
            ZStack {
                Color(.gray)
                CameraOverlayActionView(countdownState: $inProgress, doPause: {}, doRestart: {})
            }
        
            ZStack {
                Color(.gray)
                CameraOverlayActionView(countdownState: $ready, doPause: {}, doRestart: {})
            }
            
            ZStack {
                Color(.gray)
                CameraOverlayActionView(countdownState: $other, doPause: {}, doRestart: {})
            }
        }
    }
}
