//

import SwiftUI

struct ReadyIndicatorView: View {
    let systemImage: String

    var body: some View {
        BaseIndicatorView(systemImage: systemImage, color: IndicatorColor.ready)
    }
}

struct ReadyIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyIndicatorView(systemImage: "photo.fill")
    }
}
