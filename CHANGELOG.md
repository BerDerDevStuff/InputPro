# Changelog

## 1.1.0 — 2026-04-07

### **Re-install the runtime** to get mouse button icon support!

### Added
- Mouse button icons for `GetInputImage` and `CreatePromptHint` — custom glyph assets for MouseLeftButton, MouseRightButton, MouseMiddleButton
- Toast hint when entering keyboard listen mode — reminds users that left click must be added via Browse mode

### Fixed
- Insert Code popup couldn't be opened without a script selected — popup now opens freely, selection is checked only on insert
- Explorer selection cleared on widget focus — now only clears during input listen mode, preserving selection for Insert Code
- `GetInputImage` crashed on mouse button bindings — fixed with instance name lookup

### Changed
- Mouse button display names unified to `MouseLeftButton` / `MouseRightButton` / `MouseMiddleButton` across plugin UI, export, and runtime
- Add Action button moved outside scroll area — always visible regardless of widget size

---

## 1.0.0 — 2026-04-04

Initial public release.

### Features
- `Init(configName)` — load exported plugin configs
- `InitManual()` — code-only initialization (no plugin needed)
- `BindPressed` / `BindReleased` / `BindStateChanged` — action event binding
- `SetContext` / `DisableContext` — context switching (exclusive and additive)
- `ContextChanged` signal
- `GetActiveDevice` / `ActiveDeviceChanged` — automatic device detection (Keyboard, Gamepad, Touch)
- `GetInputImage` — retrieve key glyph images and display names
- `CreatePromptHint` — auto-updating key badge UI (keyboard text, gamepad glyphs, hidden on touch)
- Manual creation API: `CreateContext`, `CreateAction`, `CreateBinding`
- Analog trigger threshold support (R2/L2 with configurable pressed/released thresholds)
- Touch binding support via `TouchButtonPath` attributes
- Auto-enable default context on init
