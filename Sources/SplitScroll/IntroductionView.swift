import SwiftUI
import AppKit


struct PopoverContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            if model.showingIntro {
                IntroductionView(model: model)
            } else {
                ScrollView {
                    SettingsView(model: model)
                }
                .frame(width: 490, height: min(model.scrolling.trusted ? 590 : 720,
                                              (NSScreen.main?.visibleFrame.height ?? 800) - 60))
            }
        }
    }
}

struct IntroductionView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0

    private let titles = ["Two devices. Two directions.", "Make each device yours.", "One permission, then you're ready."]
    private let descriptions = [
        "Natural on your trackpad. Traditional on your mouse. SplitScroll gives each device its own scrolling direction.",
        "Choose a connected mouse or trackpad and set its vertical and horizontal direction independently.",
        "Allow Accessibility so SplitScroll can apply your choices. Keep Natural scrolling on in macOS as your starting point."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Welcome to SplitScroll", systemImage: "computermouse.fill")
                    .font(.callout.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Text("\(step + 1) of 3").font(.caption).foregroundStyle(.secondary)
            }

            Group {
                if step == 0 {
                    HStack(spacing: 16) {
                        ScrollPreview(symbol: "hand.draw.fill", name: "Trackpad", caption: "Natural scrolling", reverse: false)
                        ScrollPreview(symbol: "computermouse.fill", name: "Mouse", caption: "Traditional scrolling", reverse: true)
                    }
                } else if step == 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Connected devices", systemImage: "cable.connector").font(.headline)
                        if model.scrolling.catalog.devices.isEmpty {
                            Text("Connect a mouse or trackpad to add its settings.")
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(model.scrolling.catalog.devices) { device in
                                        HStack(spacing: 12) {
                                            Image(systemName: device.isTrackpad ? "hand.draw" : "computermouse")
                                                .font(.title2).foregroundStyle(.blue).frame(width: 30)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(device.name).font(.callout.weight(.medium))
                                                Text(device.detail).font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(device.isTrackpad ? "Natural" : "Traditional")
                                                .font(.caption).foregroundStyle(.blue)
                                        }.padding(12)
                                            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        Text("Each device remembers its own choices.").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(18).background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: model.scrolling.trusted ? "checkmark.shield.fill" : "hand.raised.fill")
                            .font(.system(size: 48)).foregroundStyle(.blue)
                        Text(model.scrolling.trusted ? "Accessibility is ready" : "Enable Accessibility")
                            .font(.headline)
                        Text("System Settings → Privacy & Security → Accessibility")
                            .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        if !model.scrolling.trusted {
                            Button("Allow Accessibility") { model.scrolling.requestPermission() }
                                .buttonStyle(.borderedProminent)
                        }
                        Text("You can also enable it later in settings.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity).padding(20)
                        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                }
            }.frame(height: 236)
                .id(step).transition(.opacity)

            VStack(alignment: .leading, spacing: 10) {
                Text(titles[step]).font(.system(size: 25, weight: .semibold))
                Text(descriptions[step]).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(height: 100, alignment: .topLeading)

            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Capsule().fill(index == step ? Color.blue : Color.secondary.opacity(0.25))
                            .frame(width: index == step ? 20 : 6, height: 6)
                    }
                }.accessibilityLabel("Introduction step \(step + 1) of 3")
                Spacer()
                if step > 0 { Button("Back") { changeStep(step - 1) } }
                Button(step == 2 ? "Open device settings" : "Continue") {
                    if step == 2 { model.finishIntro() }
                    else { changeStep(step + 1) }
                }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }
        }.padding(28).frame(width: 490)
    }

    private func changeStep(_ next: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { step = next }
    }
}

private struct ScrollPreview: View {
    let symbol: String
    let name: String
    let caption: String
    let reverse: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moving = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor)).frame(height: 102)
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == 2 ? Color.blue.opacity(0.7) : Color.secondary.opacity(0.18))
                            .frame(width: index % 2 == 0 ? 98 : 72, height: 7)
                    }
                }.offset(y: moving ? (reverse ? 13 : -13) : (reverse ? -13 : 13))
                    .frame(height: 88).clipped()
                Image(systemName: reverse ? "arrow.down" : "arrow.up")
                    .font(.callout.bold()).foregroundStyle(.blue).offset(x: 66)
            }
            Image(systemName: symbol).font(.system(size: 29)).foregroundStyle(.blue)
                .offset(y: moving ? -3 : 3)
            VStack(spacing: 4) {
                Text(name).font(.headline)
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16).frame(maxWidth: .infinity)
        .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { moving = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name): \(caption)")
    }
}
