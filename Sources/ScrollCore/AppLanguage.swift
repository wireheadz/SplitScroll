import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    public var id: String { rawValue }
    public var displayName: String { self == .english ? "English" : "简体中文" }

    public static func resolve(savedValue: String?, preferredLanguages: [String]) -> AppLanguage {
        if let savedValue, let saved = AppLanguage(rawValue: savedValue) { return saved }
        for identifier in preferredLanguages {
            let code = identifier.lowercased().split(separator: "-").first
            if code == "zh" { return .simplifiedChinese }
            if code == "en" { return .english }
        }
        return .english
    }

    public func text(_ english: String) -> String {
        self == .simplifiedChinese ? Self.chinese[english] ?? english : english
    }

    private static let chinese: [String: String] = [
        "Separate scrolling for mouse and trackpad.": "为鼠标和触控板分别设置滚动方向。",
        "Quit": "退出",
        "Quit SplitScroll": "退出 SplitScroll",
        "Enable": "启用",
        "Enable mouse scroll reversal": "启用滚动方向调整",
        "One-time permission": "首次授权",
        "Allow SplitScroll in Privacy & Security → Accessibility to enable mouse scrolling controls.": "请在“隐私与安全性 → 辅助功能”中允许 SplitScroll，以启用滚动控制。",
        "Allow Accessibility": "授权辅助功能",
        "Open Settings": "打开系统设置",
        "If the app is missing, add it with the + button.": "如果列表中没有该应用，请点击 + 添加。",
        "Devices": "设备",
        "Configure": "选择设备",
        "Other mouse wheels": "其他鼠标滚轮",
        "Default for mouse wheels whose device cannot be identified.": "用于无法识别设备的鼠标滚轮的默认设置。",
        "Reverse vertical scrolling": "反转垂直滚动",
        "Reverse horizontal scrolling": "反转水平滚动",
        "A direction for each device": "每个设备，独立方向",
        "Keep Natural scrolling on in macOS. Select a device above to adjust its direction. Trackpads start unchanged; mice start reversed.": "请保持 macOS 的“自然滚动”开启。在上方选择设备并调整方向。默认反转鼠标方向，触控板保持不变。",
        "Open Trackpad Settings": "打开触控板设置",
        "Device identification is unavailable on this macOS version. Only the Other mouse wheels defaults can be applied.": "此 macOS 版本无法识别设备，只能使用“其他鼠标滚轮”的默认设置。",
        "Show in menu bar": "显示菜单栏图标",
        "The icon hides when this panel closes. Open SplitScroll again to return to settings.": "关闭面板后图标将隐藏。重新打开 SplitScroll 即可返回设置。",
        "Launch at login": "登录时启动",
        "Allow SplitScroll in System Settings → General → Login Items.": "请在“系统设置 → 通用 → 登录项”中允许 SplitScroll。",
        "Login item": "登录项",
        "Two devices. Two directions.": "两种设备，两种方向。",
        "Make each device yours.": "为每个设备设置合适的方向。",
        "One permission, then you're ready.": "一次授权，即可开始。",
        "Natural on your trackpad. Traditional on your mouse. SplitScroll gives each device its own scrolling direction.": "触控板自然滚动，鼠标传统滚动。SplitScroll 让每个设备拥有独立的滚动方向。",
        "Choose a connected mouse or trackpad and set its vertical and horizontal direction independently.": "选择已连接的鼠标或触控板，分别设置垂直和水平滚动方向。",
        "Allow Accessibility so SplitScroll can apply your choices. Keep Natural scrolling on in macOS as your starting point.": "授予辅助功能权限，让 SplitScroll 应用你的设置。请保持 macOS 的“自然滚动”开启。",
        "Welcome to SplitScroll": "欢迎使用 SplitScroll",
        "Trackpad": "触控板",
        "Mouse": "鼠标",
        "Natural scrolling": "自然滚动",
        "Traditional scrolling": "传统滚动",
        "Connected devices": "已连接的设备",
        "Connect a mouse or trackpad to add its settings.": "连接鼠标或触控板后即可设置。",
        "Natural": "自然",
        "Traditional": "传统",
        "Each device remembers its own choices.": "每个设备都会保存自己的设置。",
        "Accessibility is ready": "辅助功能已授权",
        "Enable Accessibility": "启用辅助功能",
        "System Settings → Privacy & Security → Accessibility": "系统设置 → 隐私与安全性 → 辅助功能",
        "You can also enable it later in settings.": "你也可以稍后在设置中授权。",
        "Back": "上一步",
        "Open device settings": "打开设备设置",
        "Continue": "继续",
        "Accessibility permission needed": "需要辅助功能权限",
        "Paused — macOS scrolling unchanged": "已暂停 — 保持 macOS 原有滚动方向",
        "Active — device settings applied": "已启用 — 已应用设备设置",
        "Event tap unavailable — retrying": "滚动控制暂不可用 — 正在重试",
        "Could not start — check permission or relaunch": "无法启动 — 请检查权限或重新打开应用",
        "Built-in Trackpad": "内置触控板",
        "Built-in": "内置",
    ]
}

public final class LanguagePreferences {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        AppLanguage.resolve(savedValue: defaults.string(forKey: "appLanguage"),
                            preferredLanguages: preferredLanguages)
    }

    public func save(_ language: AppLanguage) { defaults.set(language.rawValue, forKey: "appLanguage") }
}
