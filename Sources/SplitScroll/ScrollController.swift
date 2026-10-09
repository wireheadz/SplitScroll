import AppKit
import ApplicationServices
import ScrollCore

final class ScrollController {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var timer: Timer?
    var onChange: (() -> Void)?
    private(set) var status = "Accessibility permission needed"
    private var previousSnapshot = ""
    private let defaults = UserDefaults.standard
    let catalog = DeviceCatalog()
    let profiles = DeviceProfileStore()

    func profile(for device: ScrollDevice) -> DeviceProfile {
        profiles.profile(for: device.id, default: DeviceProfile(
            vertical: device.isTrackpad ? false : vertical,
            horizontal: device.isTrackpad ? false : horizontal))
    }

    func setProfile(_ profile: DeviceProfile, for device: ScrollDevice) {
        profiles.set(profile, for: device.id)
        refresh()
        onChange?()
    }

    var enabled: Bool {
        get { defaults.bool(forKey: "enabled") }
        set { defaults.set(newValue, forKey: "enabled"); refresh() }
    }
    var vertical: Bool {
        get { defaults.bool(forKey: "vertical") }
        set { defaults.set(newValue, forKey: "vertical"); onChange?() }
    }
    var horizontal: Bool {
        get { defaults.bool(forKey: "horizontal") }
        set { defaults.set(newValue, forKey: "horizontal"); onChange?() }
    }
    var trusted: Bool { AXIsProcessTrusted() }
    var active: Bool { enabled && trusted && tap.map { CGEvent.tapIsEnabled(tap: $0) } == true }

    init() {
        defaults.register(defaults: ["enabled": true, "vertical": true, "horizontal": true])
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refresh()
    }

    func refresh() {
        let devicesChanged = catalog.refresh()
        if devicesChanged {
            for device in catalog.devices {
                profiles.register(DeviceProfile(vertical: device.isTrackpad ? false : vertical,
                                                horizontal: device.isTrackpad ? false : horizontal), for: device.id)
            }
        }
        if !enabled {
            removeTap()
            status = "Paused — macOS scrolling unchanged"
        } else if !trusted {
            removeTap()
            status = "Accessibility permission needed"
        } else {
            if tap == nil { installTap() }
            if let tap {
                if !CGEvent.tapIsEnabled(tap: tap) { CGEvent.tapEnable(tap: tap, enable: true) }
                status = CGEvent.tapIsEnabled(tap: tap) ? "Active — device settings applied" : "Event tap unavailable — retrying"
            } else {
                status = "Could not start — check permission or relaunch"
            }
        }
        let snapshot = status
        if snapshot != previousSnapshot || devicesChanged {
            previousSnapshot = snapshot
            onChange?()
        }
    }

    private func installTap() {
        let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, pointer in
                guard let pointer else { return Unmanaged.passUnretained(event) }
                let owner = Unmanaged<ScrollController>.fromOpaque(pointer).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if owner.enabled, let tap = owner.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }
                if let device = owner.catalog.device(for: event) {
                    let profile = owner.profile(for: device)
                    ScrollTransform.apply(to: event, enabled: owner.enabled,
                                          vertical: profile.vertical, horizontal: profile.horizontal,
                                          identifiedDevice: true)
                } else {
                    ScrollTransform.apply(to: event, enabled: owner.enabled,
                                          vertical: owner.vertical, horizontal: owner.horizontal)
                }
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }
        guard let newSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            return
        }
        tap = newTap
        source = newSource
        // Common modes keep the filter alive while a menu is tracking.
        CFRunLoopAddSource(CFRunLoopGetMain(), newSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
    }

    private func removeTap() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        removeTap()
    }
}
