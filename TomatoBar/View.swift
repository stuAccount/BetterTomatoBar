import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
}

private struct IntervalsView: View {
    @EnvironmentObject var timer: TBTimer
    private var minStr = NSLocalizedString("IntervalsView.min", comment: "min")

    // Number formatters for each field
    private let intervalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.minimum = 1
        f.maximum = 90
        return f
    }()
    private let setFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.minimum = 1
        f.maximum = 10
        return f
    }()

    var body: some View {
        VStack {
            // Preset Picker
            HStack {
                Spacer()
                Picker("", selection: $timer.currentPreset) {
                    ForEach(PresetType.allCases) { preset in
                        Text(preset.label).tag(preset.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: timer.currentPreset) { _ in
                    timer.selectPreset(PresetType(rawValue: timer.currentPreset) ?? .morning)
                }
                Spacer()
            }
            // Work Interval
            HStack {
                Text(
                    NSLocalizedString(
                        "IntervalsView.workIntervalLength.label",
                        comment: "Work interval label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    TextField(
                        "",
                        value: $timer.workIntervalLength,
                        formatter: intervalFormatter
                    )
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
                    .onChange(of: timer.workIntervalLength) { _ in
                        timer.updateCustomPresetFromFields()
                    }

                    Text("min")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }

                Stepper("", value: $timer.workIntervalLength, in: 1...90)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
            }

            // Short Rest Interval
            HStack {
                Text(
                    NSLocalizedString(
                        "IntervalsView.shortRestIntervalLength.label",
                        comment: "Short rest interval label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    TextField(
                        "",
                        value: $timer.shortRestIntervalLength,
                        formatter: intervalFormatter
                    )
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
                    .onChange(of: timer.shortRestIntervalLength) { _ in
                        timer.updateCustomPresetFromFields()
                    }

                    Text("min")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }

                Stepper("", value: $timer.shortRestIntervalLength, in: 1...90)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
            }

            // Long Rest Interval
            HStack {
                Text(
                    NSLocalizedString(
                        "IntervalsView.longRestIntervalLength.label",
                        comment: "Long rest interval label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    TextField(
                        "",
                        value: $timer.longRestIntervalLength,
                        formatter: intervalFormatter
                    )
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
                    .onChange(of: timer.longRestIntervalLength) { _ in
                        timer.updateCustomPresetFromFields()
                    }

                    Text("min")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }

                Stepper("", value: $timer.longRestIntervalLength, in: 1...90)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
            }
            .help(
                NSLocalizedString(
                    "IntervalsView.longRestIntervalLength.help",
                    comment: "Long rest interval hint"))

            // Work Intervals In Set
            HStack {
                Text(
                    NSLocalizedString(
                        "IntervalsView.workIntervalsInSet.label",
                        comment: "Work intervals in a set label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField(
                    "",
                    value: $timer.workIntervalsInSet,
                    formatter: setFormatter
                )
                .frame(width: 40)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .disabled(timer.currentPreset != PresetType.custom.rawValue)
                .onChange(of: timer.workIntervalsInSet) { _ in
                    timer.updateCustomPresetFromFields()
                }

                Stepper("", value: $timer.workIntervalsInSet, in: 1...10)
                    .disabled(timer.currentPreset != PresetType.custom.rawValue)
            }
            .help(
                NSLocalizedString(
                    "IntervalsView.workIntervalsInSet.help",
                    comment: "Work intervals in set hint"))

            Spacer().frame(minHeight: 0)
        }
        .padding(4)
        .onAppear {
            timer.loadPresets()
            timer.loadPresetToFields()
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject var timer: TBTimer
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

    var body: some View {
        VStack {
            KeyboardShortcuts.Recorder(for: .startStopTimer) {
                Text(
                    NSLocalizedString(
                        "SettingsView.shortcut.label",
                        comment: "Shortcut label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Toggle(isOn: $timer.stopAfterBreak) {
                Text(
                    NSLocalizedString(
                        "SettingsView.stopAfterBreak.label",
                        comment: "Stop after break label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Toggle(isOn: $timer.showTimerInMenuBar) {
                Text(
                    NSLocalizedString(
                        "SettingsView.showTimerInMenuBar.label",
                        comment: "Show timer in menu bar label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
                .onChange(of: timer.showTimerInMenuBar) { _ in
                    timer.updateTimeLeft()
                }
            Toggle(isOn: $launchAtLogin.isEnabled) {
                Text(
                    NSLocalizedString(
                        "SettingsView.launchAtLogin.label",
                        comment: "Launch at login label")
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.switch)
            Spacer().frame(minHeight: 0)
        }
        .padding(4)
    }
}

private struct VolumeSlider: View {
    @Binding var volume: Double

    var body: some View {
        Slider(value: $volume, in: 0...2) {
            Text(String(format: "%.1f", volume))
        }.gesture(
            TapGesture(count: 2).onEnded({
                volume = 1.0
            }))
    }
}

private struct SoundsView: View {
    @EnvironmentObject var player: TBPlayer

    private var columns = [
        GridItem(.flexible()),
        GridItem(.fixed(110)),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            Text(
                NSLocalizedString(
                    "SoundsView.isWindupEnabled.label",
                    comment: "Windup label"))
            VolumeSlider(volume: $player.windupVolume)
            Text(
                NSLocalizedString(
                    "SoundsView.isDingEnabled.label",
                    comment: "Ding label"))
            VolumeSlider(volume: $player.dingVolume)
            Text(
                NSLocalizedString(
                    "SoundsView.isTickingEnabled.label",
                    comment: "Ticking label"))
            VolumeSlider(volume: $player.tickingVolume)
            Text(
                NSLocalizedString(
                    "SoundsView.isRainyEnabled.label",
                    comment: "Rainy label"))
            VolumeSlider(volume: $player.rainyVolume)
            Text(
                NSLocalizedString(
                    "SoundsView.isDarkEnabled.label",
                    comment: "Dark label"))
            VolumeSlider(volume: $player.darkVolume)
        }.padding(4)
        Spacer().frame(minHeight: 0)
    }
}

private enum ChildView {
    case intervals, settings, sounds
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @State private var buttonHovered = false
    @State private var activeChildView = ChildView.intervals

    private var startLabel = NSLocalizedString("TBPopoverView.start.label", comment: "Start label")
    private var stopLabel = NSLocalizedString("TBPopoverView.stop.label", comment: "Stop label")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                timer.startStop()
                TBStatusItem.shared.closePopover(nil)
            } label: {
                Text(
                    timer.timer != nil
                        ? (buttonHovered ? stopLabel : timer.timeLeftString) : startLabel
                )
                /*
                  When appearance is set to "Dark" and accent color is set to "Graphite"
                  "defaultAction" button label's color is set to the same color as the
                  button, making the button look blank. #24
                 */
                .foregroundColor(Color.white)
                .font(.system(.body).monospacedDigit())
                .frame(maxWidth: .infinity)
            }
            .onHover { over in
                buttonHovered = over
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Picker("", selection: $activeChildView) {
                Text(
                    NSLocalizedString(
                        "TBPopoverView.intervals.label",
                        comment: "Intervals label")
                ).tag(ChildView.intervals)
                Text(
                    NSLocalizedString(
                        "TBPopoverView.settings.label",
                        comment: "Settings label")
                ).tag(ChildView.settings)
                Text(
                    NSLocalizedString(
                        "TBPopoverView.sounds.label",
                        comment: "Sounds label")
                ).tag(ChildView.sounds)
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .pickerStyle(.segmented)

            GroupBox {
                switch activeChildView {
                case .intervals:
                    IntervalsView().environmentObject(timer)
                case .settings:
                    SettingsView().environmentObject(timer)
                case .sounds:
                    SoundsView().environmentObject(timer.player)
                }
            }

            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text(
                        NSLocalizedString(
                            "TBPopoverView.about.label",
                            comment: "About label"))
                    Spacer()
                    Text("⌘ A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text(
                        NSLocalizedString(
                            "TBPopoverView.quit.label",
                            comment: "Quit label"))
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        #if DEBUG
            /*
             After several hours of Googling and trying various StackOverflow
             recipes I still haven't figured a reliable way to auto resize
             popover to fit all it's contents (pull requests are welcome!).
             The following code block is used to determine the optimal
             geometry of the popover.
             */
            .overlay(
                GeometryReader { proxy in
                    debugSize(proxy: proxy)
                }
            )
        #endif
        /* Use values from GeometryReader */
        //            .frame(width: 230, height: 276)
        .padding(12)
    }
}

#if DEBUG
    func debugSize(proxy: GeometryProxy) -> some View {
        print("Optimal popover size:", proxy.size)
        return Color.clear
    }
#endif
