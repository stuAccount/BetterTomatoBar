## ⏱️ Hybrid Pomodoro Schedule

This is a hybrid productivity structure combining **custom deep work Pomodoros** and the **textbook Pomodoro Technique** for different energy levels throughout the day.

| Time of Day | Style               | Work Interval | Short Rest | Long Rest | Work Intervals a set  |Total Time |
|-------------|---------------------|---------------|-------------|------------|------------------|-------------|
| ☀️ Morning   | Custom (Deep Focus) | 40 min        | 10 min      | 20 min     | 2        | 3h 20m      |
| 🌤️ Afternoon | Textbook Pomodoro   | 25 min        | 5 min       | 30 min     | 3       | 3h 20m      |
| 🌙 Night     | Light Pomodoro      | 30 min        | 5 min       | 20 min     | 2       | 2h 30m      |

---

### 📌 An Ideal Pomodoro for Reference

The **textbook Pomodoro Technique** consists of:

- **25 minutes** of focused work  
- **5 minutes** short break  
- After **4 work sessions**, take a **15–30 minute long break**  
- One full cycle ≈ 2 hours

This structure is great for maintaining stamina, while the custom version above supports longer deep work sessions.

---

<p align="center">
<img src="https://raw.githubusercontent.com/ivoronin/TomatoBar/main/TomatoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png" width="128" height="128"/>
<p>


<img
  src="https://github.com/stuAccount/BetterTomatoBar/raw/main/screenshot.png?raw=true"
  alt="Screenshot"
  width="50%"
  align="left"
/><img
  src="https://github.com/stuAccount/BetterTomatoBar/raw/main/screenshot2.png?raw=true"
  alt="Screenshot"
  width="50%"
  align="right"
/>

## Overview
Have you ever heard of Pomodoro? It’s a great technique to help you keep track of time and stay on task during your studies or work. Read more about it on <a href="https://en.wikipedia.org/wiki/Pomodoro_Technique">Wikipedia</a>.

TomatoBar is world's neatest Pomodoro timer for the macOS menu bar. All the essential features are here - configurable
work and rest intervals, optional sounds, discreet actionable notifications, global hotkey.

TomatoBar is fully sandboxed with no entitlements.

Download the latest release <a href="https://github.com/ivoronin/TomatoBar/releases/latest/">here</a> or install using Homebrew:
```
$ brew install --cask tomatobar
```

If the app doesn't start, install using the `--no-quarantine` flag:
```
$ brew install --cask --no-quarantine tomatobar
```

## Integration with other tools
### Event log
TomatoBar logs state transitions in JSON format to `~/Library/Containers/com.github.ivoronin.TomatoBar/Data/Library/Caches/TomatoBar.log`. Use this data to analyze your productivity and enrich other data sources.
### Starting and stopping the timer
TomatoBar can be controlled using `tomatobar://` URLs. To start or stop the timer from the command line, use `open tomatobar://startStop`.

## Older versions
Touch bar integration and older macOS versions (earlier than Big Sur) are supported by TomatoBar versions prior to 3.0

## Licenses
 - Timer sounds are licensed from buddhabeats
