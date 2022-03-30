//

import SwiftUI

struct ContentView: View {
    
    // StateObject because this is the view that creates the Observable Countdown()
    // Consider changing to EnvironmentObject if many or deep views need access to it.
    @StateObject var countdown = Countdown()
    @StateObject var cameraModel = CameraModel()
    
    var body: some View {
        CameraView(model: cameraModel, countdown: countdown).environmentObject(SettingsStore())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
