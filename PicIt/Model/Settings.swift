//
import SwiftUI
import Combine

public enum PicItMedia: String, CaseIterable {
    case photo = "PHOTO"
    case video = "VIDEO"
}

// TODO: Migrate interval and tolerance into SettingsStore (and UserDefaults)
struct PicItSetting {
    static var interval = 1.0
    static var tolerance: Double { return Self.interval * 0.25 }
}

enum PicItUserDefaults: String {
    case mediaTypeKey = "PICIT_MEDIA"
    case countdownFromKey = "PICIT_DELAY"  // TODO: Change the UserDefaults Key
    
    func getString() -> String? {
        return UserDefaults.standard.string(forKey: self.rawValue)
    }
    
    func getInteger() -> Int {
        return UserDefaults.standard.integer(forKey: self.rawValue)
    }
    
    func set(_ val: Int) {
        UserDefaults.standard.set(val, forKey: self.rawValue)
    }
    
    func set(_ val: String) {
        UserDefaults.standard.set(val, forKey: self.rawValue)
    }
}

// Note: This approach only polls UserDefaults at initialization and is not notified if UserDefaults changes.
//       This should be ok, but if we need to react to changes in UserDefaults,
//       see: https://swiftwithmajid.com/2019/06/19/building-forms-with-swiftui/ for an example
//       where NotificationCenter and UserDefaults.didChangeNotification are used to publish changes.
//       An example of where it might be needed is if we have multiple apps sharing the same configuration settings.
class Settings: ObservableObject {
    
    static var mediaType: PicItMedia {
        get {
            let mediaSetting = PicItUserDefaults.mediaTypeKey.getString() ?? PicItMedia.photo.rawValue
            return PicItMedia(rawValue: mediaSetting) ?? PicItMedia.photo
        }
    }
    
    static var countdownStart: Int {
        get {
            return PicItUserDefaults.countdownFromKey.getInteger()
        }
    }
    
    @Published var mediaType: PicItMedia = .photo {
        didSet {
            PicItUserDefaults.mediaTypeKey.set(mediaType.rawValue)
        }
    }
    
    @Published var countdownStart: Int {
        didSet {
            PicItUserDefaults.countdownFromKey.set(countdownStart)
        }
    }
    
    init() {
        self.mediaType = Self.mediaType // instance prop initialized from static prop
        self.countdownStart = Self.countdownStart
    }
}
