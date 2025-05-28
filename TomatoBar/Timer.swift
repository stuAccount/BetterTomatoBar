import AppKit
import KeyboardShortcuts
import SwiftState
import SwiftUI

struct TimerPreset: Codable, Equatable {
    var workIntervalLength: Int
    var shortRestIntervalLength: Int
    var longRestIntervalLength: Int
    var workIntervalsInSet: Int
}

enum PresetType: Int, CaseIterable, Identifiable {
    case morning = 0
    case afternoon, night, custom
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .morning: return "morning"
        case .afternoon: return "afternoon"
        case .night: return "night"
        case .custom: return "custom"
        }
    }
}

class TBTimer: ObservableObject {
    @AppStorage("stopAfterBreak") var stopAfterBreak = false
    @AppStorage("showTimerInMenuBar") var showTimerInMenuBar = true
    @AppStorage("workIntervalLength") var workIntervalLength = 25
    @AppStorage("shortRestIntervalLength") var shortRestIntervalLength = 5
    @AppStorage("longRestIntervalLength") var longRestIntervalLength = 15
    @AppStorage("workIntervalsInSet") var workIntervalsInSet = 4
    // This preference is "hidden"
    @AppStorage("overrunTimeLimit") var overrunTimeLimit = -60.0

    @AppStorage("currentPreset") var currentPreset: Int = 0
    @AppStorage("timerPresets") var presetsData: Data = Data()
    @Published var presets: [TimerPreset] = [
        TimerPreset(
            workIntervalLength: 40, shortRestIntervalLength: 10, longRestIntervalLength: 20,
            workIntervalsInSet: 2),  // morning
        TimerPreset(
            workIntervalLength: 25, shortRestIntervalLength: 5, longRestIntervalLength: 30,
            workIntervalsInSet: 3),  // afternoon
        TimerPreset(
            workIntervalLength: 30, shortRestIntervalLength: 5, longRestIntervalLength: 20,
            workIntervalsInSet: 2),  // night
        TimerPreset(
            workIntervalLength: 25, shortRestIntervalLength: 5, longRestIntervalLength: 15,
            workIntervalsInSet: 4),  // custom
    ]

    private var stateMachine = TBStateMachine(state: .idle)
    public let player = TBPlayer()
    private var consecutiveWorkIntervals: Int = 0
    private var notificationCenter = TBNotificationCenter()
    private var finishTime: Date!
    private var timerFormatter = DateComponentsFormatter()
    @Published var timeLeftString: String = ""
    @Published var timer: DispatchSourceTimer?

    init() {
        /*
         * State diagram
         *
         *                 start/stop
         *       +--------------+-------------+
         *       |              |             |
         *       |  start/stop  |  timerFired |
         *       V    |         |    |        |
         * +--------+ |  +--------+  | +--------+
         * | idle   |--->| work   |--->| rest   |
         * +--------+    +--------+    +--------+
         *   A                  A        |    |
         *   |                  |        |    |
         *   |                  +--------+    |
         *   |  timerFired (!stopAfterBreak)  |
         *   |             skipRest           |
         *   |                                |
         *   +--------------------------------+
         *      timerFired (stopAfterBreak)
         *
         */
        stateMachine.addRoutes(
            event: .startStop,
            transitions: [
                .idle => .work, .work => .idle, .rest => .idle,
            ])
        stateMachine.addRoutes(event: .timerFired, transitions: [.work => .rest])
        stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .idle]) { _ in
            self.stopAfterBreak
        }
        stateMachine.addRoutes(event: .timerFired, transitions: [.rest => .work]) { _ in
            !self.stopAfterBreak
        }
        stateMachine.addRoutes(event: .skipRest, transitions: [.rest => .work])

        /*
         * "Finish" handlers are called when time interval ended
         * "End"    handlers are called when time interval ended or was cancelled
         */
        stateMachine.addAnyHandler(.any => .work, handler: onWorkStart)
        stateMachine.addAnyHandler(.work => .rest, order: 0, handler: onWorkFinish)
        stateMachine.addAnyHandler(.work => .any, order: 1, handler: onWorkEnd)
        stateMachine.addAnyHandler(.any => .rest, handler: onRestStart)
        stateMachine.addAnyHandler(.rest => .work, handler: onRestFinish)
        stateMachine.addAnyHandler(.any => .idle, handler: onIdleStart)
        stateMachine.addAnyHandler(
            .any => .any,
            handler: { ctx in
                logger.append(event: TBLogEventTransition(fromContext: ctx))
            })

        stateMachine.addErrorHandler { ctx in fatalError("state machine context: <\(ctx)>") }

        timerFormatter.unitsStyle = .positional
        timerFormatter.allowedUnits = [.minute, .second]
        timerFormatter.zeroFormattingBehavior = .pad

        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)
        notificationCenter.setActionHandler(handler: onNotificationAction)

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURLEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent: NSAppleEventDescriptor
    ) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue else {
            print("url handling error: cannot get url")
            return
        }
        let url = URL(string: urlString)
        guard url != nil,
            let scheme = url!.scheme,
            let host = url!.host
        else {
            print("url handling error: cannot parse url")
            return
        }
        guard scheme.caseInsensitiveCompare("tomatobar") == .orderedSame else {
            print("url handling error: unknown scheme \(scheme)")
            return
        }
        switch host.lowercased() {
        case "startstop":
            startStop()
        default:
            print("url handling error: unknown command \(host)")
            return
        }
    }

    func startStop() {
        stateMachine <-! .startStop
    }

    func skipRest() {
        stateMachine <-! .skipRest
    }

    func updateTimeLeft() {
        timeLeftString = timerFormatter.string(from: Date(), to: finishTime)!
        if timer != nil, showTimerInMenuBar {
            TBStatusItem.shared.setTitle(title: timeLeftString)
        } else {
            TBStatusItem.shared.setTitle(title: nil)
        }
    }

    private func startTimer(seconds: Int) {
        finishTime = Date().addingTimeInterval(TimeInterval(seconds))

        let queue = DispatchQueue(label: "Timer")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        timer!.setEventHandler(handler: onTimerTick)
        timer!.setCancelHandler(handler: onTimerCancel)
        timer!.resume()
    }

    private func stopTimer() {
        timer!.cancel()
        timer = nil
    }

    private func onTimerTick() {
        /* Cannot publish updates from background thread */
        DispatchQueue.main.async { [self] in
            updateTimeLeft()
            let timeLeft = finishTime.timeIntervalSince(Date())
            if timeLeft <= 0 {
                /*
                 Ticks can be missed during the machine sleep.
                 Stop the timer if it goes beyond an overrun time limit.
                 */
                if timeLeft < overrunTimeLimit {
                    stateMachine <-! .startStop
                } else {
                    stateMachine <-! .timerFired
                }
            }
        }
    }

    private func onTimerCancel() {
        DispatchQueue.main.async { [self] in
            updateTimeLeft()
        }
    }

    private func onNotificationAction(action: TBNotification.Action) {
        if action == .skipRest, stateMachine.state == .rest {
            skipRest()
        }
    }

    private func onWorkStart(context _: TBStateMachine.Context) {
        TBStatusItem.shared.setIcon(name: .work)
        player.playWindup()
        player.startDark()
        player.startRainy()
        player.startTicking()
        startTimer(seconds: workIntervalLength * 60)
    }

    //
    private func showSessionEndPopup(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Pomodoro Session complete!"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .informational
            if let window = NSApplication.shared.mainWindow {
                alert.beginSheetModal(for: window, completionHandler: nil)
            } else {
                alert.runModal()
            }
        }
    }
    //
    private func onWorkFinish(context _: TBStateMachine.Context) {
        consecutiveWorkIntervals += 1
        player.playDing()
        showSessionEndPopup(message: "Time for a break!")
    }

    private func onWorkEnd(context _: TBStateMachine.Context) {
        player.stopTicking()
        player.stopDark()
        player.stopRainy()
    }

    private func onRestStart(context _: TBStateMachine.Context) {
        var body = NSLocalizedString("TBTimer.onRestStart.short.body", comment: "Short break body")
        var length = shortRestIntervalLength
        var imgName = NSImage.Name.shortRest
        if consecutiveWorkIntervals >= workIntervalsInSet {
            body = NSLocalizedString("TBTimer.onRestStart.long.body", comment: "Long break body")
            length = longRestIntervalLength
            imgName = .longRest
            consecutiveWorkIntervals = 0
        }
        notificationCenter.send(
            title: NSLocalizedString("TBTimer.onRestStart.title", comment: "Time's up title"),
            body: body,
            category: .restStarted
        )
        TBStatusItem.shared.setIcon(name: imgName)
        startTimer(seconds: length * 60)
    }

    private func onRestFinish(context ctx: TBStateMachine.Context) {
        if ctx.event == .skipRest {
            return
        }
        notificationCenter.send(
            title: NSLocalizedString("TBTimer.onRestFinish.title", comment: "Break is over title"),
            body: NSLocalizedString("TBTimer.onRestFinish.body", comment: "Break is over body"),
            category: .restFinished
        )
        showSessionEndPopup(message: "Break is over! Get up boy!")
    }

    private func onIdleStart(context _: TBStateMachine.Context) {
        stopTimer()
        TBStatusItem.shared.setIcon(name: .idle)
        consecutiveWorkIntervals = 0
    }
}

extension TBTimer {
    var currentPresetType: PresetType {
        PresetType(rawValue: currentPreset) ?? .morning
    }

    var currentPresetInstance: TimerPreset {
        get { presets[currentPreset] }
        set {
            if currentPreset == PresetType.custom.rawValue {
                presets[currentPreset] = newValue
                savePresets()
            }
        }
    }

    func selectPreset(_ preset: PresetType) {
        // Stop the timer if running
        if timer != nil {
            stopTimer()
        }
        consecutiveWorkIntervals = 0
        currentPreset = preset.rawValue
        loadPresetToFields()
    }

    func loadPresetToFields() {
        let preset = presets[currentPreset]
        workIntervalLength = preset.workIntervalLength
        shortRestIntervalLength = preset.shortRestIntervalLength
        longRestIntervalLength = preset.longRestIntervalLength
        workIntervalsInSet = preset.workIntervalsInSet
    }

    func updateCustomPresetFromFields() {
        if currentPreset == PresetType.custom.rawValue {
            presets[currentPreset] = TimerPreset(
                workIntervalLength: workIntervalLength,
                shortRestIntervalLength: shortRestIntervalLength,
                longRestIntervalLength: longRestIntervalLength,
                workIntervalsInSet: workIntervalsInSet
            )
            savePresets()
        }
    }

    func savePresets() {
        if let data = try? JSONEncoder().encode(presets) {
            presetsData = data
        }
    }

    func loadPresets() {
        if let loaded = try? JSONDecoder().decode([TimerPreset].self, from: presetsData),
            loaded.count == 4
        {
            presets = loaded
        }
    }
}
