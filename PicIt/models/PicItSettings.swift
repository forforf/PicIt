//

// These will be overridden by values in Settings.bundle
struct PicItDefault {
    static let delay = 2.5
    static let interval = 0.25
    static let tolerance = 0.1
}

struct PicItSettingItem<T> {
    let key: String
    var value: T
}

// Keys are used to map to Settings.bundle configurations
struct PicItSetting {
    static let delay = PicItSettingItem<Double>(key: "PICIT_DELAY", value: PicItDefault.delay)
}
