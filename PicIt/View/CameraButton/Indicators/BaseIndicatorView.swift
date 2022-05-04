//

import SwiftUI

struct IndicatorColor {
    static let ready = Color.picit.darkgreen
    static let notReady = Color.picit.gray
    static let inUse = Color.picit.yellow
}

struct BaseIndicatorView: View {
    let systemImage: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemImage)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40, alignment: .center)
            .foregroundColor(color)
    }
}

struct BaseIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        BaseIndicatorView(systemImage: "photo.fill", color: IndicatorColor.ready)
    }
}
