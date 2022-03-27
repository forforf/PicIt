//

enum PicItMedia: String, CaseIterable {
    case photo = "PHOTO"
    case media = "MEDIA"
}

// Convenience Struct for associating a setting key to its assigned value.
// Keys are used to map to Settings.bundle configurations
struct PicItSettingItem<T> {
    let key: String
    var value: T
}

struct PicItSetting {
    static let delay = PicItSettingItem<Double>(key: "PICIT_DELAY", value: 5.0)
    static var interval = 1.0
    // Note: It seems that an interval/tolerance ~<0.9 will not be met upon running the app again after putting it in the background AND photo capturing has occurred.
    // interval/tolerance of ~0.1 DO work on initial opening of the app (still not found exaclty why returns from background cause issues
    static var tolerance: Double { return Self.interval * 0.25 }
//    static var enableCountdown: Bool = true
}

import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    // Static properties are not observable but are useful when we need static access to the Defaults.
    // For example, non-views (like the Countdown model) that should use the stored defaults.
    static var countdownStart: Int {
        // Disable setter as we should only be using the static property to get the stored default
        // set { UserDefaults.standard.set(newValue, forKey: Keys.delay) }
        get { UserDefaults.standard.integer(forKey: Keys.delay) }
    }
    
    private enum Keys {
        static let delay = "PICIT_DELAY"
        static let media = "PICIT_MEDIA"
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    let objectWillChange = PassthroughSubject<Void, Never>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.delay: 5,
            Keys.media: PicItMedia.photo.rawValue
            ])

        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(objectWillChange)
    }

    var mediaType: PicItMedia {
        get {
            return defaults.string(forKey: Keys.media)
                .flatMap { PicItMedia(rawValue: $0) } ?? .photo
        }

        set {
            defaults.set(newValue.rawValue, forKey: Keys.media)
        }
    }
    
    var countdownStart: Int {
        get { Self.countdownStart }
        set { defaults.set(newValue, forKey: Keys.delay) }
    }
}
