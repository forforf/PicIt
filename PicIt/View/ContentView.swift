//

import SwiftUI


struct ContentView: View {
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
