//

import SwiftUI

struct ContentView: View {
    static let log = PicItSelfLog<ContentView>.get()
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var cameraModel = CameraModel(CameraModel.Dependencies())
    
    var body: some View {
        CameraView(model: cameraModel)
            .onChange(of: scenePhase, perform: cameraModel.scenePhaseManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
