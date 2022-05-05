//

import SwiftUI

extension CameraModel.MediaMode {

    // TODO: Decouple CameraService, should live somewhere else
    private func indicatorState(_ state: CameraService.ActionState, systemImage: String) -> AnyView {
        switch state {
        case .ready:
            return AnyView(ReadyIndicatorView(systemImage: systemImage))
        case .notReady:
            return AnyView(NotReadyIndicatorView(systemImage: systemImage))
        case .inUse:
            return AnyView(InUseIndicatorView(systemImage: systemImage))
        }
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
