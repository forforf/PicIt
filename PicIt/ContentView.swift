//

import SwiftUI


struct ContentView: View {
    /*
     We don't want to alter the value stored by AppStorage, so we should not access it directly, but only through the computed property. We could have used  "UserDefaults" instead of "AppStorage" to do this, but I prefer the conciseness of AppStorage.
     Note: The default value (.delay.value) is only used if the setting doesn't exist (or at least I think so)
     */
    @AppStorage(PicItSetting.delay.key) private var _picitDelay: String = "\(PicItSetting.delay.value)"
    private var picitDelay: Double {
        return Double(_picitDelay) ?? 0.0
    }
    
    var timer: PicItTimer {
        let myTimer = PicItTimer(delay: picitDelay, interval: PicItDefault.interval, tolerance: PicItDefault.tolerance)
        print("CREATED timer with: \(myTimer.delay), \(myTimer.interval), \(myTimer.tolerance)")
        return myTimer
    }
    
    var body: some View {
        CameraView(timer: timer)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
