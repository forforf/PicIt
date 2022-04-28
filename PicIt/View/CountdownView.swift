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

struct CountdownView: View {
    
    let countdownTimer: TimeInterval
    let countdownState: CountdownState
    
    @State var countdownText: String = ""
    @State var buttonColor: Color = .gray

    let readyColor: Color = .green
    let recordingColor: Color = .red
    
    func formatCountdownTimer(countdownTimer: TimeInterval) -> String {
        return countdownTimer > 0 ? String(format: "%.0f", countdownTimer) : "0"
    }
    
    var body: some View {
 
        let countdownText = formatCountdownTimer(countdownTimer: countdownTimer)
        
        HStack {
            ZStack {
                Circle()
                    .foregroundColor(countdownState.cameraButtonColor())
                    .frame(width: 80, height: 80, alignment: .center)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.8), lineWidth: 2)
                            .frame(width: 65, height: 65, alignment: .center)
                    )

                Text(countdownText)
            }
        }
    }
}

struct CountdownView_Previews: PreviewProvider {
    static let countdown = Countdown()
    static var previews: some View {
        ForEach(CountdownState.allCases, id: \.self) { countdownState in
            VStack {
                CountdownView(countdownTimer: 3, countdownState: countdownState)
                Text(String(describing: countdownState))
            }

        }
        VStack {
            CountdownView(countdownTimer: 0, countdownState: .complete)
            Text("Complete with timer at 0")
        }
        
    }
}
