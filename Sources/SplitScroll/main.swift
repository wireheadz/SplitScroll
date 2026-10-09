import AppKit
import SwiftUI
import ServiceManagement
import ScrollCore

final class AppModel: ObservableObject {
    let scrolling = ScrollController()
    @Published var revision = 0
    @Published var loginMessage = ""
    @Published var showingIntro = !UserDefaults.standard.bool(forKey: "completedIntro")
    @Published var selectedDeviceID = "fallback"
    var onMenuBarVisibilityChange: (() -> Void)?

    init() {
        UserDefaults.standard.register(defaults: ["showInMenuBar": true])
    }

    var showInMenuBar: Bool {
        get { UserDefaults.standard.bool(forKey: "showInMenuBar") }
        set {
            UserDefaults.standard.set(newValue, forKey: "showInMenuBar")
            onMenuBarVisibilityChange?()
            revision += 1
        }
    }

    var launchAtLogin: Bool { SMAppService.mainApp.status == .enabled }

    var selectedDevice: ScrollDevice? {
        scrolling.catalog.devices.first { $0.id == selectedDeviceID }
    }

    var selectedProfile: DeviceProfile {
        if let device = selectedDevice { return scrolling.profile(for: device) }
        return DeviceProfile(vertical: scrolling.vertical, horizontal: scrolling.horizontal)
    }

    func setAxis(vertical: Bool, reversed: Bool) {
        var profile = selectedProfile
        if vertical { profile.vertical = reversed } else { profile.horizontal = reversed }
        if let device = selectedDevice { scrolling.setProfile(profile, for: device) }
        else {
            if vertical { scrolling.vertical = reversed } else { scrolling.horizontal = reversed }
        }
        revision += 1
    }

    func finishIntro() {
        UserDefaults.standard.set(true, forKey: "completedIntro")
        selectedDeviceID = scrolling.catalog.devices.first?.id ?? "fallback"
        showingIntro = false
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginMessage = SMAppService.mainApp.status == .requiresApproval
                ? "Allow SplitScroll in System Settings → General → Login Items." : ""
        } catch { loginMessage = "Login item: \(error.localizedDescription)" }
        revision += 1
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    private var scrolling: ScrollController { model.scrolling }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "computermouse.fill")
                    .font(.system(size: 26)).foregroundStyle(.blue)
                    .frame(width: 50, height: 50)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 7) {
                    Text("SplitScroll")
                        .font(.system(size: 26, weight: .semibold))
                        .padding(.trailing, 88)
                    Text("Separate scrolling for mouse and trackpad.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(QuitButtonStyle())
                    .keyboardShortcut("q", modifiers: .command)
                    .help("Quit SplitScroll")
                    .accessibilityLabel("Quit SplitScroll")
                    .offset(y: -4)
            }

            HStack {
                Circle().fill(scrolling.active ? Color.green : Color.orange).frame(width: 9, height: 9)
                Text(scrolling.status).font(.callout.weight(.medium))
                Spacer()
                Toggle("Enable", isOn: Binding(get: { scrolling.enabled }, set: { scrolling.enabled = $0 }))
                    .toggleStyle(.switch).labelsHidden().accessibilityLabel("Enable mouse scroll reversal")
            }.padding(14).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            if !scrolling.trusted {
                VStack(alignment: .leading, spacing: 10) {
                    Label("One-time permission", systemImage: "hand.raised.fill").font(.headline)
                    Text("Allow SplitScroll in Privacy & Security → Accessibility to enable mouse scrolling controls.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Allow Accessibility") { scrolling.requestPermission() }.buttonStyle(.borderedProminent)
                        Button("Open Settings") { openSettings("Privacy_Accessibility") }
                    }
                    Text("If the app is missing, add it with the + button.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 14) {
                Label("Devices", systemImage: "computermouse").font(.headline)
                Picker("Configure", selection: $model.selectedDeviceID) {
                    ForEach(scrolling.catalog.devices) { device in
                        Text(device.name).tag(device.id)
                    }
                    Text("Other mouse wheels").tag("fallback")
                }
                if let device = model.selectedDevice {
                    Text(device.detail).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Default for mouse wheels whose device cannot be identified.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Reverse vertical scrolling")
                    Spacer()
                    Toggle("Reverse vertical scrolling", isOn: Binding(get: { model.selectedProfile.vertical }, set: { model.setAxis(vertical: true, reversed: $0) }))
                        .toggleStyle(.switch).labelsHidden()
                }
                HStack {
                    Text("Reverse horizontal scrolling")
                    Spacer()
                    Toggle("Reverse horizontal scrolling", isOn: Binding(get: { model.selectedProfile.horizontal }, set: { model.setAxis(vertical: false, reversed: $0) }))
                        .toggleStyle(.switch).labelsHidden()
                }
                Divider()
                Label("A direction for each device", systemImage: "arrow.up.arrow.down").font(.callout.weight(.medium))
                Text("Keep Natural scrolling on in macOS. Select a device above to adjust its direction. Trackpads start unchanged; mice start reversed.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("Open Trackpad Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Trackpad-Settings.extension")!)
                }
                if !scrolling.catalog.lookupAvailable {
                    Text("Device identification is unavailable on this macOS version. Only the Other mouse wheels defaults can be applied.")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Text("Show in menu bar")
                Spacer()
                Toggle("Show in menu bar", isOn: Binding(get: { model.showInMenuBar }, set: { model.showInMenuBar = $0 }))
                    .toggleStyle(.switch).labelsHidden()
            }
            if !model.showInMenuBar {
                Text("The icon hides when this panel closes. Open SplitScroll again to return to settings.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("Launch at login")
                Spacer()
                Toggle("Launch at login", isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                    .toggleStyle(.switch).labelsHidden()
            }
            if !model.loginMessage.isEmpty { Text(model.loginMessage).font(.caption).foregroundStyle(.orange) }
        }
        .padding(24).frame(width: 490)
        .onChange(of: scrolling.catalog.devices) { devices in
            if model.selectedDeviceID != "fallback", !devices.contains(where: { $0.id == model.selectedDeviceID }) {
                model.selectedDeviceID = devices.first?.id ?? "fallback"
            }
        }
    }

    private func openSettings(_ anchor: String) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)")!)
    }
}

private struct QuitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 72, height: 32, alignment: .center)
            .background(Color.blue.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let model = AppModel()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let reopenNotification = Notification.Name("com.tomo.SplitScroll.showSettings")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A second copy asks the existing process to open its anchored panel.
        if let identifier = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            DistributedNotificationCenter.default().postNotificationName(reopenNotification, object: nil)
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "SplitScroll")
            button.target = self
            button.action = #selector(togglePopover)
        }
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverContentView(model: model))
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(showSettings),
                                                           name: reopenNotification, object: nil)
        model.onMenuBarVisibilityChange = { [weak self] in
            guard let self else { return }
            // Retain the anchor until the open panel closes, then apply hiding.
            self.statusItem.isVisible = self.model.showInMenuBar || self.popover.isShown
        }
        statusItem.isVisible = model.showInMenuBar
        model.scrolling.onChange = { [weak self] in
            guard let self else { return }
            self.model.revision += 1
            self.updateStatus()
        }
        model.scrolling.start()
        updateStatus()
        if model.showingIntro || !UserDefaults.standard.bool(forKey: "hasLaunched") || !model.scrolling.trusted {
            DispatchQueue.main.async { [weak self] in self?.showSettings() }
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
    }

    private func updateStatus() {
        statusItem.button?.toolTip = "SplitScroll — \(model.scrolling.status)"
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil) }
        else { showSettings() }
    }

    @objc func showSettings() {
        statusItem.isVisible = true
        guard let button = statusItem.button else { return }
        model.scrolling.refresh()
        model.revision += 1
        NSApp.activate(ignoringOtherApps: true)
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverShouldDetach(_ popover: NSPopover) -> Bool { false }
    func popoverDidClose(_ notification: Notification) {
        statusItem.isVisible = model.showInMenuBar
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
        model.scrolling.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
