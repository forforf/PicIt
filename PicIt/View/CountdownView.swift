//

import SwiftUI

struct CountdownView: View {
    @ObservedObject var countdown: CountdownBase
    
    //TODO: Is there a way to make these immutable rather than @State?
    @State var countdownText: String = ""
    @State var buttonColor: Color = .gray
    
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(buttonColor)
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )
            Text(countdownText)
        }
        .onReceive(countdown.$time, perform: { countdown in
            countdownText = countdown > 0 ? String(format: "%.0f", countdown) : "0"
        })
        
        // countdown can be an "empty", which really should be called disabled.
        // In which case nothing is ever published, so the on Receive never fires.
        .onReceive(countdown.$countdownState, perform: { countdownState in
            switch countdownState {
            case .notStarted:
                buttonColor = .gray
            case .inProgress:
                buttonColor = .yellow
            case .triggering:
                buttonColor = .green
            case .complete:
                buttonColor = .white
            }
        })
    }
}

struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView(countdown: Countdown())
    }
}
