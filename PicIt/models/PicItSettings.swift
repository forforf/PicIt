//

// These will be overridden by values in Settings.bundle
struct PicItDefault {
    static let delay = 5.0
    static let interval = 1.0
    // Note: It seems that an interval/tolerance ~<0.9 will not be met upon running the app again after putting it in the background AND photo capturing has occurred.
    // interval/tolerance of ~0.1 DO work on initial opening of the app (still not found exaclty why returns from background cause issues
    static let tolerance = 1.0
}

struct PicItSettingItem<T> {
    let key: String
    var value: T
}

// Keys are used to map to Settings.bundle configurations
struct PicItSetting {
    static let delay = PicItSettingItem<Double>(key: "PICIT_DELAY", value: PicItDefault.delay)
}
