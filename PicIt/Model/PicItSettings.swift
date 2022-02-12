//

// TODO: I think this should be simplified.

// Constants are not modifiable by user
private struct PicItConstant {
    static let interval = 1.0
    static let toleranceFactor = 0.25
}

// Defaults may be modified (usually via app settings)
private struct PicItDefault {
    static let delay = 5.0

}

// Convenience Struct for associating a setting key to its assigned value.
struct PicItSettingItem<T> {
    let key: String
    var value: T
}

// Keys are used to map to Settings.bundle configurations
struct PicItSetting {
    static let delay = PicItSettingItem<Double>(key: "PICIT_DELAY", value: PicItDefault.delay)
    static var interval = PicItConstant.interval
    // Note: It seems that an interval/tolerance ~<0.9 will not be met upon running the app again after putting it in the background AND photo capturing has occurred.
    // interval/tolerance of ~0.1 DO work on initial opening of the app (still not found exaclty why returns from background cause issues
    static var tolerance: Double { return Self.interval * PicItConstant.toleranceFactor }
}

