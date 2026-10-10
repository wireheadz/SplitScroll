import AppKit
import SwiftUI
import ServiceManagement
import ScrollCore

final class AppModel: ObservableObject {
    let scrolling = ScrollController()
    @Published var revision = 0
    private let languagePreferences = LanguagePreferences()
    @Published var language: AppLanguage = .english {
        didSet {
            languagePreferences.save(language)
            onLanguageChange?()
        }
    }
    var onLanguageChange: (() -> Void)?
    @Published var loginError = ""

    func text(_ english: String) -> String { language.text(english) }

    var loginMessage: String {
        if !loginError.isEmpty { return "\(text("Login item")): \(loginError)" }
        return SMAppService.mainApp.status == .requiresApproval
            ? text("Allow SplitScroll in System Settings → General → Login Items.") : ""
    }
    @Published var showingIntro = !UserDefaults.standard.bool(forKey: "completedIntro")
    @Published var selectedDeviceID = "fallback"
    var onMenuBarVisibilityChange: (() -> Void)?
    var onIntroCompleted: (() -> Void)?

    init() {
        UserDefaults.standard.register(defaults: ["showInMenuBar": true])
        language = languagePreferences.load()
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
        onIntroCompleted?()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginError = ""
        } catch { loginError = error.localizedDescription }
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
                    Text(model.text("Separate scrolling for mouse and trackpad."))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                Button(model.text("Quit")) { NSApp.terminate(nil) }
                    .buttonStyle(QuitButtonStyle())
                    .keyboardShortcut("q", modifiers: .command)
                    .help(model.text("Quit SplitScroll"))
                    .accessibilityLabel(model.text("Quit SplitScroll"))
                    .offset(y: -4)
            }

            HStack {
                Circle().fill(scrolling.active ? Color.green : Color.orange).frame(width: 9, height: 9)
                Text(model.text(scrolling.status)).font(.callout.weight(.medium))
                Spacer()
                Toggle(model.text("Enable"), isOn: Binding(get: { scrolling.enabled }, set: { scrolling.enabled = $0 }))
                    .toggleStyle(.switch).labelsHidden().accessibilityLabel(model.text("Enable mouse scroll reversal"))
            }.padding(14).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            if !scrolling.trusted {
                VStack(alignment: .leading, spacing: 10) {
                    Label(model.text("One-time permission"), systemImage: "hand.raised.fill").font(.headline)
                    Text(model.text("Allow SplitScroll in Privacy & Security → Accessibility to enable mouse scrolling controls."))
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(model.text("Allow Accessibility")) { scrolling.requestPermission() }.buttonStyle(.borderedProminent)
                        Button(model.text("Open Settings")) { openSettings("Privacy_Accessibility") }
                    }
                    Text(model.text("If the app is missing, add it with the + button."))
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 14) {
                Label(model.text("Devices"), systemImage: "computermouse").font(.headline)
                Picker(model.text("Configure"), selection: $model.selectedDeviceID) {
                    ForEach(scrolling.catalog.devices) { device in
                        Text(model.text(device.name)).tag(device.id)
                    }
                    Text(model.text("Other mouse wheels")).tag("fallback")
                }
                if let device = model.selectedDevice {
                    Text(device.localizedDetail(language: model.language)).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(model.text("Default for mouse wheels whose device cannot be identified."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text(model.text("Reverse vertical scrolling"))
                    Spacer()
                    Toggle(model.text("Reverse vertical scrolling"), isOn: Binding(get: { model.selectedProfile.vertical }, set: { model.setAxis(vertical: true, reversed: $0) }))
                        .toggleStyle(.switch).labelsHidden()
                }
                HStack {
                    Text(model.text("Reverse horizontal scrolling"))
                    Spacer()
                    Toggle(model.text("Reverse horizontal scrolling"), isOn: Binding(get: { model.selectedProfile.horizontal }, set: { model.setAxis(vertical: false, reversed: $0) }))
                        .toggleStyle(.switch).labelsHidden()
                }
                Divider()
                Label(model.text("A direction for each device"), systemImage: "arrow.up.arrow.down").font(.callout.weight(.medium))
                Text(model.text("Keep Natural scrolling on in macOS. Select a device above to adjust its direction. Trackpads start unchanged; mice start reversed."))
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button(model.text("Open Trackpad Settings")) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Trackpad-Settings.extension")!)
                }
                if !scrolling.catalog.lookupAvailable {
                    Text(model.text("Device identification is unavailable on this macOS version. Only the Other mouse wheels defaults can be applied."))
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Text(model.text("Show in menu bar"))
                Spacer()
                Toggle(model.text("Show in menu bar"), isOn: Binding(get: { model.showInMenuBar }, set: { model.showInMenuBar = $0 }))
                    .toggleStyle(.switch).labelsHidden()
            }
            if !model.showInMenuBar {
                Text(model.text("The icon hides when this panel closes. Open SplitScroll again to return to settings."))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text(model.text("Launch at login"))
                Spacer()
                Toggle(model.text("Launch at login"), isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                    .toggleStyle(.switch).labelsHidden()
            }
            LanguagePicker(model: model)

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

struct LanguagePicker: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Language / 语言").font(.caption).foregroundStyle(.secondary)
            Picker("Language / 语言", selection: $model.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
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

private final class IntroductionWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let model = AppModel()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var introductionWindow: NSWindow?
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
        model.onIntroCompleted = { [weak self] in
            guard let self else { return }
            self.introductionWindow?.close()
            self.introductionWindow = nil
            self.showSettings()
        }
        model.onLanguageChange = { [weak self] in self?.updateStatus() }
        model.scrolling.start()
        updateStatus()
        if model.showingIntro {
            DispatchQueue.main.async { [weak self] in self?.showIntroduction() }
        }
    }

    private func updateStatus() {
        statusItem.button?.toolTip = "SplitScroll — \(model.text(model.scrolling.status))"
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil) }
        else { showSettings() }
    }

    private func showIntroduction() {
        model.scrolling.refresh()
        model.revision += 1
        if introductionWindow == nil {
            let height = min(640, (NSScreen.main?.visibleFrame.height ?? 800) - 100)
            let window = IntroductionWindow(
                contentRect: NSRect(x: 0, y: 0, width: 490, height: height),
                styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.title = "SplitScroll"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.tabbingMode = .disallowed
            window.isMovableByWindowBackground = true
            for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                window.standardWindowButton(button)?.isHidden = true
            }
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.contentViewController = NSHostingController(
                rootView: IntroductionWindowContentView(model: model)
                    .frame(width: 490, height: height))
            window.contentView?.layoutSubtreeIfNeeded()
            let screenFrame = (window.screen ?? NSScreen.main)?.visibleFrame
            if let screenFrame {
                window.setFrameOrigin(NSPoint(
                    x: screenFrame.midX - window.frame.width / 2,
                    y: screenFrame.midY - window.frame.height / 2))
            }
            introductionWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        introductionWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if model.showingIntro {
            showIntroduction()
            return
        }
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
