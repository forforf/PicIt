//

import SwiftUI

// Perhaps have the colors come from settings, or a theme environment in the future
struct PicItIndicatorColor {
    static let ready = Color.green
    static let notReady = Color.gray
    static let inUse = Color.red
}

extension CameraModel.MediaMode {

    // TODO: Decouple CameraService, should live somewhere else
    private func indicatorState(_ state: CameraService.ActionState, systemImage: String) -> some View {
        switch state {
        case .ready:
            return buildIndicatorView(systemImage: systemImage, color: PicItIndicatorColor.ready)
        case .notReady:
            return buildIndicatorView(systemImage: systemImage, color: PicItIndicatorColor.notReady)
        case .inUse:
            return buildIndicatorView(systemImage: systemImage, color: PicItIndicatorColor.inUse)
        }
    }
    
    private func buildIndicatorView(systemImage: String, color: Color) -> some View {
        return Image(systemName: systemImage)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40, alignment: .center)
            .foregroundColor(color)
    }
    
    func indicatorView() -> some View {
        switch self {
        case .photo(let state):
            return indicatorState(state, systemImage: "photo.fill")
        case .video(let state):
            return indicatorState(state, systemImage: "video.fill")
        }
    }
}

struct MediaIndicatorView: View {
    let mediaMode: CameraModel.MediaMode
    
    // TODO: Where should colors come from? Maybe from a theme provider?
    let readyColor: Color = .green
    let recordingColor: Color = .red
    
    var body: some View {
        mediaMode.indicatorView()
    }
}

struct MediaIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(CameraModel.MediaMode.allCases, id: \.self) { mediaMode in
            VStack {
                mediaMode.indicatorView()
                Text(String(describing: mediaMode))
            }
        }
    }
}
