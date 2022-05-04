//

import SwiftUI

struct NotReadyIndicatorView: View {
    let systemImage: String

    @State private var animationValue = 1.0

    var body: some View {
        BaseIndicatorView(systemImage: systemImage, color: IndicatorColor.notReady)
            .scaleEffect(animationValue)
            .animation(.easeInOut(duration: 1), value: animationValue)
            .onAppear {
                animationValue = 0.5
            }
    }
}

struct NotReadyIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        NotReadyIndicatorView(systemImage: "photo.fill")
    }
}
