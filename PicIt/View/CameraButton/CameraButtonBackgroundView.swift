//

import SwiftUI

struct CameraButtonBackgroundView: View {
    
    let color: Color
    @Binding var scaleAmount: Double
    
    var body: some View {
        Circle()
            .foregroundColor(color)
            .frame(width: 80, height: 80, alignment: .center)
            .scaleEffect(scaleAmount)
            .animation(.easeInOut(duration: 1), value: scaleAmount)
    }
}

struct CameraButtonBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        CameraButtonBackgroundView(color: .green, scaleAmount: .constant(1.5))
    }
}
