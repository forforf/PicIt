//

import SwiftUI

struct InUseIndicatorView: View {
    let systemImage: String

    @State private var animationValue = 1.0

    var body: some View {
        BaseIndicatorView(systemImage: systemImage, color: IndicatorColor.inUse)
            .scaleEffect(animationValue)
            .animation(.easeInOut(duration: 1).repeatForever(), value: animationValue)
            .onAppear {
                animationValue = 2.0
            }
    }
}

struct InUseIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        InUseIndicatorView(systemImage: "photo.fill")
    }
}
