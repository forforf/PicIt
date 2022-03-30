//

import SwiftUI

// Perhaps have the colors come from settings, or a theme environment in the future
struct PicItIndicatorColor {
    static let ready = Color.green
    static let recording = Color.red
}

extension PicItMediaState {

    private func buildIndicatorView(systemImage: String, color: Color) -> some View {
        return Image(systemName: systemImage)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40, alignment: .center)
            .foregroundColor(color)
    }
    
    func indicatorView() -> some View {
        switch self {
        case .photoReady:
            return buildIndicatorView(systemImage: "photo.fill", color: PicItIndicatorColor.ready)
        case .videoReady:
            return buildIndicatorView(systemImage: "video.fill", color: PicItIndicatorColor.ready)
        case .videoRecording:
            return buildIndicatorView(systemImage: "video.fill", color: PicItIndicatorColor.recording)
        }
    }
}

struct MediaIndicatorView: View {
    let mediaState: PicItMediaState
    
    // TODO: Where should colors come from? Maybe from a theme provider?
    let readyColor: Color = .green
    let recordingColor: Color = .red
    
    var body: some View {
        mediaState.indicatorView()
    }
}

struct MediaIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PicItMediaState.allCases, id: \.self) { mediaState in
            VStack {
                mediaState.indicatorView()
                Text(String(describing: mediaState))
            }
        }
    }
}
