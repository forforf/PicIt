//

import SwiftUI

struct CameraOverlayView: View {
    
    let countdownTimer: TimeInterval
    var countdownState: CountdownState
    var doPause: NoArgClosure<Void>
    var doRestart: NoArgClosure<Void>
        
    func formatCountdownTimer(_ countdownTimer: TimeInterval) -> String {
        return countdownTimer > 0 ? String(format: "%.0f", countdownTimer) : ""
    }
    
    var body: some View {
        VStack {
            Text(formatCountdownTimer(countdownTimer))
                .opacity(0.4)
                .foregroundColor(.white)
                .font(.system(size: 120, weight: .medium, design: .default))
            CameraOverlayActionView(
                countdownState: countdownState,
                doPause: doPause,
                doRestart: doRestart
            )
        }.contrast(2)
    }
}

struct CameraOverlayView_Previews: PreviewProvider {
    static let bgColors: [UIColor] = [.gray, .white, .black, .red, .green, .blue]
    static var previews: some View {
        Group {
            ForEach(bgColors, id: \.self) { bgColor in
                ZStack {
                    Color(bgColor)
                    CameraOverlayView(countdownTimer: 3.0, countdownState: .ready, doPause: {}, doRestart: {})
                }
            }
        }
    }
}
