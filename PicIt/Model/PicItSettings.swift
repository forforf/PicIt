//
import SwiftUI
import Combine

public enum PicItMedia: String, CaseIterable {
    case photo = "PHOTO"
    case video = "VIDEO"
}

// PicItMediaType is sort of like a backing variable to PicItMediaState.
// the type influences what states are valid
public enum PicItMediaState: Hashable {
    case photoReady(_ mediaType: PicItMedia)
    case videoReady(_ mediaType: PicItMedia)
    case videoRecording(_ mediaType: PicItMedia)
}


// One use case for CaseIterable is for generating the View_preview for all valid media states.
// Be aware that this might not cover every possible case
extension PicItMediaState: CaseIterable {
    public static var allCases: [PicItMediaState] = [.photoReady(.photo), .videoReady(.video), .videoRecording(.video)]
}

extension PicItMediaState {
    
    // Convenience to initialize mediaState based on the underlying media type
    init(mediaType: PicItMedia) {
        switch mediaType {
        case .photo:
            self = .photoReady(mediaType)
        case .video:
            self = .videoReady(mediaType)
        }
    }
    
    // Mechanism to update the enum to prevent invalid states
    // TODO: Is there a way to enforce? For example PicItMediaState.videoReady(.photo) works. It'd be nice to prevent (ideally compile time if possible)
    // TODO: Would inverting the relationship help (i.e. PicItMediaType.photo(.ready) or PicItMediaType.video(.recording))?
    func update(mediaType: PicItMedia) -> PicItMediaState {
        var newState = self
        switch self {
        case .photoReady:
            if mediaType == .video {
                newState = .videoReady(mediaType)
            }
        case .videoReady, .videoRecording:
            if mediaType == .photo {
                newState = .photoReady(mediaType)
            }
        }
        return newState
    }
}

// Convenience Struct for associating a setting key to its assigned value.
// Keys are used to map to Settings.bundle configurations
struct PicItSettingItem<T> {
    let key: String
    var value: T
}

// TODO: Migrate interval and tolerance into SettingsStore (and UserDefaults)
struct PicItSetting {
    static var interval = 1.0
    static var tolerance: Double { return Self.interval * 0.25 }
}

final class SettingsStore: ObservableObject {
    static let log = PicItSelfLog<CameraModel>.get()
    
    @Published var mediaState: PicItMediaState = PicItMediaState(mediaType: SettingsStore.mediaType)
    
    private enum Keys {
        static let delay = "PICIT_DELAY"
        static let media = "PICIT_MEDIA"
    }
    
    // Static properties are not observable but are useful when we need static access to the Defaults.
    // For example, non-views (like the Countdown model) that should use the stored defaults.
    static var countdownStart: Int {
        // Disable setter as we should only be using the static property to get the stored default
        // set { UserDefaults.standard.set(newValue, forKey: Keys.delay) }
        get { UserDefaults.standard.integer(forKey: Keys.delay) }
    }
    
    static var mediaType: PicItMedia {
        get {
            let mediaSetting = UserDefaults.standard.string(forKey: Keys.media) ?? PicItMedia.photo.rawValue
            return PicItMedia(rawValue: mediaSetting) ?? PicItMedia.photo
        }
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
            Self.mediaType
        }
        set {
            Self.log.debug("Changing Media: old type: \(Self.mediaType) old state: \(mediaState)")// so we make sure they stay consistent here.
            defaults.set(newValue.rawValue, forKey: Keys.media)
            // The media state has a dependency on mediaType
            mediaState = mediaState.update(mediaType: newValue)
            objectWillChange.send()
            Self.log.debug("Changed Media: new type: \(newValue) updated to \(Self.mediaType) new state: \(mediaState)")
        }
    }
    
    var countdownStart: Int {
        get { Self.countdownStart }
        set { defaults.set(newValue, forKey: Keys.delay) }
    }
}
