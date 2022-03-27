//

import SwiftUI

struct ContentView: View {
    
    // StateObject because this is the view that creates the Observable Countdown()
    // Consider changing to EnvironmentObject if many or deep views need access to it.
    @StateObject var countdown = Countdown()
    
    var body: some View {
        CameraView(countdown: countdown).environmentObject(SettingsStore())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
