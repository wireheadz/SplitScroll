import Foundation
import IOKit
import CoreGraphics
import SenderBridge

struct ScrollDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let transport: String
    let isTrackpad: Bool
    var detail: String { "\(isTrackpad ? "Trackpad" : "Mouse") · \(transport)" }
}

final class DeviceCatalog {
    private(set) var devices: [ScrollDevice] = []
    private var senderKeys: [UInt64: String] = [:]
    private var unknownSenders: Set<UInt64> = []
    var lookupAvailable: Bool { SSSenderLookupAvailable() }

    @discardableResult
    func refresh() -> Bool {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDDevice"), &iterator) == KERN_SUCCESS else { return false }
        defer { IOObjectRelease(iterator) }
        var discovered: [String: ScrollDevice] = [:]
        var keys: [UInt64: String] = [:]
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard let device = describe(service) else { continue }
            discovered[device.id] = device
            var registryID: UInt64 = 0
            if IORegistryEntryGetRegistryEntryID(service, &registryID) == KERN_SUCCESS {
                keys[registryID] = device.id
            }
        }
        // Preserve validated aliases while their physical device is still connected.
        for (sender, key) in senderKeys where discovered[key] != nil { keys[sender] = key }
        senderKeys = keys
        unknownSenders.removeAll()
        let updated = discovered.values.sorted { ($0.isTrackpad ? 1 : 0, $0.name, $0.id) < ($1.isTrackpad ? 1 : 0, $1.name, $1.id) }
        let changed = updated != devices
        devices = updated
        return changed
    }

    func device(for event: CGEvent) -> ScrollDevice? {
        let sender = SSScrollSenderID(event)
        guard sender != 0 else { return nil }
        if let key = senderKeys[sender] { return devices.first { $0.id == key } }
        // Resolve a sender's own registry properties, rather than guessing from the
        // last mouse moved. One-time resolution is deferred out of the event tap.
        if unknownSenders.insert(sender).inserted {
            DispatchQueue.main.async { [weak self] in self?.resolve(sender) }
        }
        return nil
    }

    private func resolve(_ sender: UInt64) {
        var service = IOServiceGetMatchingService(kIOMainPortDefault, IORegistryEntryIDMatching(sender))
        for _ in 0..<6 {
            guard service != 0 else { return }
            if let description = describe(service), devices.contains(where: { $0.id == description.id }) {
                senderKeys[sender] = description.id
                IOObjectRelease(service)
                return
            }
            var parent: io_registry_entry_t = 0
            let result = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent)
            IOObjectRelease(service)
            service = result == KERN_SUCCESS ? parent : 0
        }
        if service != 0 { IOObjectRelease(service) }
    }

    private func describe(_ service: io_registry_entry_t) -> ScrollDevice? {
        func property(_ name: String) -> Any? {
            IORegistryEntryCreateCFProperty(service, name as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        guard let name = property("Product") as? String else { return nil }
        let page = (property("PrimaryUsagePage") as? NSNumber)?.intValue ?? 0
        let usage = (property("PrimaryUsage") as? NSNumber)?.intValue ?? 0
        let isTrackpad = name.localizedCaseInsensitiveContains("trackpad") || (page == 13 && usage == 5)
        guard (page == 1 && [1, 2].contains(usage)) || isTrackpad else { return nil }
        let vendor = (property("VendorID") as? NSNumber)?.intValue ?? 0
        let product = (property("ProductID") as? NSNumber)?.intValue ?? 0
        let transport = property("Transport") as? String ?? "HID"
        let serial = property("SerialNumber") as? String ?? ""
        let location = (property("LocationID") as? NSNumber)?.uint64Value ?? 0
        var registryID: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(service, &registryID)
        // Location distinguishes identical devices without serial numbers. A device
        // with neither serial nor location gets a session identity to avoid collisions.
        let address = serial.isEmpty ? (location == 0 ? "session:\(registryID)" : "port:\(location)") : "serial:\(serial)"
        let key = "\(vendor):\(product):\(transport):\(address):\(name)"
        return ScrollDevice(id: key, name: isTrackpad && transport == "SPI" ? "Built-in Trackpad" : name,
                            transport: transport == "SPI" ? "Built-in" : transport, isTrackpad: isTrackpad)
    }
}
