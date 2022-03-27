//

import SwiftUI

struct CountdownView: View {
    @ObservedObject var countdown: Countdown
    
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
        
        .onReceive(countdown.$state, perform: { countdownState in
            switch countdownState {
            case .stopped:
                buttonColor = .gray
            case .inProgress:
                buttonColor = .yellow
            case .triggering:
                buttonColor = .green
            case .complete:
                buttonColor = .mint
            case .undefined:
                buttonColor = .black
            case .ready:
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
