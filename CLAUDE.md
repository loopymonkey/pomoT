# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Mr. T themed Pomodoro timer — macOS-only Flutter desktop app. Two modes: a full-size launch screen and a compact always-on-top floating widget while the timer is active.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run -d macos     # Run the app
flutter analyze          # Lint / static analysis (run before considering work done)
```

## Architecture

macOS-only (`macos/` runner only — no iOS/Android targets).

### File structure

- `lib/main.dart` — App entry point; initializes `window_manager`, routes between screens via `ListenableBuilder` on `TimerState`
- `lib/timer_state.dart` — All business logic: task list (up to 4), cycle tracking, audio playback via `pomot/sound` method channel, `shared_preferences` persistence
- `lib/ui/launch_screen.dart` — Full-size screen: `mrt_large.png`, 4 task fields, Start button, daily/all-time tally
- `lib/ui/active_timer_screen.dart` — Compact 200×80 frameless always-on-top widget: image, countdown, pause/stop, task strip
- `macos/Runner/MainFlutterWindow.swift` — Registers `window_manager` and the `pomot/sound` AVAudioPlayer method channel

### Key packages

- `window_manager` ^0.5.1 — window resize, always-on-top, frameless (`TitleBarStyle.hidden`)
- `shared_preferences` ^2.5.4 — persists daily/all-time pomodoro counts

### Audio (critical — read before changing)

Sound is played via a native `AVAudioPlayer` method channel (`pomot/sound`) in `MainFlutterWindow.swift`. Two non-obvious facts:

1. **Flutter assets on macOS are in `App.framework`, not `Bundle.main`**. The correct path:
   ```swift
   Bundle.main.bundleURL
     .appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets/<assetPath>")
   ```
   Using `Bundle.main.resourceURL` gives the wrong directory and causes `OSStatus error 2003334207`.

2. **Audio files must be AAC M4A**, not MPEG-2 Layer III MP3. The original `.mp3` files (22.05 kHz mono MPEG-2) are rejected by `AVAudioPlayer` on macOS sandbox with `OSStatus error 2003334207`. They were converted using:
   ```bash
   afconvert -f m4af -d aac input.mp3 output.m4a
   ```

### Audio cues

- Timer start / break ends → random from `sounds/start/` (3 files)
- Short break starts → random from `sounds/break/` (2 files)
- Long break starts (after 4 work cycles) → `sounds/done/done.m4a`

### Window behavior

- Launch screen: normal macOS window, 400×680
- Active timer: frameless `TitleBarStyle.hidden`, 200×80, always-on-top, draggable via `DragToMoveArea`
- Stopping timer restores normal window

### Pomodoro cycle

Work 25m → Short Break 5m (×3) → Work 25m → Long Break 15m, then repeats. After 4 work sessions the long break shows `mr_pause.png` and plays `done.m4a`.

### Assets

```yaml
flutter:
  assets:
    - images/mrt_large.png    # launch screen
    - images/mrt_small.png    # active timer (working)
    - images/mr_pause.png     # active timer (paused or long break)
    - sounds/start/*.m4a
    - sounds/break/*.m4a
    - sounds/done/done.m4a
```
