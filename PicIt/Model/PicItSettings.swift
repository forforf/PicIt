
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
}
