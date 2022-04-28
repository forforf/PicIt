//

import SwiftUI

struct SettingRowView: View {
    var title: String
    var systemImageName: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: systemImageName)
            Text(title)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var settings: Settings
    
    var body: some View {
        
        NavigationView {
            
            Form {
                
                Section(header: Text("Capture Settings")) {
                    
                    Picker(
                        selection: $settings.mediaType,
                        label: Text("Capture media as ...")
                    ) {
                        ForEach(PicItMedia.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                }
                                
                Section(header: Text("Timer Settings")) {
                    Stepper(value: $settings.countdownStart, in: 1...30) {
                        Text("Timer Countdown: \(settings.countdownStart) secs")
                    }
                }
                            
                Button("Press to dismiss") {
                    dismiss()
                }
            }
            .navigationBarTitle(Text("Settings"))
        }
        //        Text("ok")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: Settings())
        
    }
}
