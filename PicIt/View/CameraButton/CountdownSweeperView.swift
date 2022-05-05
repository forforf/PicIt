//

import SwiftUI

struct CountdownSweeperVM {
    // Constants
    static let startAngle = 270.0
    private static let gradientStartAngle = 0.0
    private static let gradientEndAngle = 360.0
    private static let degreesInCircle = 360.0
    
    let gradient = AngularGradient(
        gradient: Gradient(colors: [.black.opacity(1.0), .black.opacity(0.0)]),
        center: .center,
        startAngle: .degrees(Self.gradientStartAngle),
        endAngle: .degrees(Self.gradientEndAngle))
    
    func animationCalc(isRunning: Bool, timer: Double, initialAnimationAmount: Double) -> Double {
        if isRunning {
            let timerFraction = timer - Double(Int(timer))
            return initialAnimationAmount + (timerFraction * Self.degreesInCircle)
        } else {
            let currentAngle = initialAnimationAmount.truncatingRemainder(dividingBy: Self.degreesInCircle)
            let adjustAngle = Self.startAngle - currentAngle
            return initialAnimationAmount + adjustAngle
        }
    }
}

struct CountdownSweeperView: View {
    
    @State var animationAmount = CountdownSweeperVM.startAngle
    @Binding var show: Bool
    @Binding var isRunning: Bool
    @Binding var timer: Double
    
    private let viewModel = CountdownSweeperVM()

    var body: some View {
        Circle()
            .stroke(viewModel.gradient, style: StrokeStyle(lineWidth: 30, lineCap: .round))
            .frame(width: 30, height: 30, alignment: .center)
            .opacity(show ? 1.0 : 0.0)
            .rotationEffect(Angle.degrees(animationAmount))
            .animation(.linear(duration: 0.5), value: animationAmount)
            .onChange(of: timer) { timer in
                animationAmount = viewModel.animationCalc(isRunning: isRunning, timer: timer, initialAnimationAmount: animationAmount)
            }
        Spacer().padding(.bottom, 30)
    }
}

struct CountdownSweeperView_Previews: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            Color.yellow
            VStack {
                Spacer().padding(20)
                CountdownSweeperView(show: .constant(true), isRunning: .constant(true), timer: .constant(2.5))
            }
        }
    }
}
