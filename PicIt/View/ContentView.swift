//

import SwiftUI


struct ContentView: View {
//    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var countdown = Countdown()
    
    var body: some View {
        CameraView(countdown: countdown)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
