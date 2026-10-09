import Foundation

public struct DeviceProfile: Codable, Equatable {
    public var vertical: Bool
    public var horizontal: Bool

    public init(vertical: Bool, horizontal: Bool) {
        self.vertical = vertical
        self.horizontal = horizontal
    }
}

/// Each profile uses a hardware fingerprint, never a transient registry ID.
public final class DeviceProfileStore {
    private let defaults: UserDefaults
    private var profiles: [String: DeviceProfile]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        profiles = defaults.data(forKey: "deviceProfiles")
            .flatMap { try? JSONDecoder().decode([String: DeviceProfile].self, from: $0) } ?? [:]
    }

    public func profile(for key: String, default fallback: DeviceProfile) -> DeviceProfile {
        profiles[key] ?? fallback
    }

    public func set(_ profile: DeviceProfile, for key: String) {
        profiles[key] = profile
        if let data = try? JSONEncoder().encode(profiles) { defaults.set(data, forKey: "deviceProfiles") }
    }

    public func register(_ profile: DeviceProfile, for key: String) {
        guard profiles[key] == nil else { return }
        set(profile, for: key)
    }
}
