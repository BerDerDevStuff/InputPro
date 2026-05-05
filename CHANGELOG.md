# Changelog

## 1.2.0 — 2026-05-05

### **Re-install the runtime** to get touch gestures!

### Added
- **Touch gestures** — Tap, LongPress, and Swipe as first-class bindings, no GuiButton required. Bind via the plugin's Touch tab and react in code with the same `BindPressed` / `BindReleased` / `BindStateChanged` API
- **Gesture payloads** — gesture-driven `BindPressed` / `BindReleased` callbacks now receive an optional `GestureEventData` table with `Gesture`, `StartPosition`, `EndPosition`, `Position`, `Duration` fields. Native bindings still pass `nil`, so existing callbacks are unchanged
- **`SwipeTolerance` per Swipe binding** — minimum pixel distance the finger must move before Swipe events fire (default 10 px). Sub-tolerance touches are silently discarded
- **Force-release on context disable** — in-progress Swipes whose context becomes disabled mid-gesture now fire `Released` immediately with the last known position, preventing stuck-pressed state
- New `Signal` sibling module (`InputProService.Signal`) — bundled automatically when installing the runtime

### Changed
- `BindPressed` / `BindReleased` / `BindStateChanged` now route through internal Signals (one per action) so native input and gestures can both feed the same subscription list. Public API and behaviour unchanged for existing keyboard / gamepad / touch-button code
- Mouse-button bindings now set `Enum.KeyCode.MouseLeftButton` / `MouseRightButton` / `MouseMiddleButton` on the exported `InputBinding` instead of leaving `KeyCode` as `Unknown`

### Fixed
- **Mouse Right button bindings now actually fire.** Previously the exported `InputBinding` had `KeyCode = Unknown`, so the native `InputAction` never dispatched for Mouse Right (Mouse Left / Middle happened to work via a different path). Mouse Right now behaves identically to Mouse Left and Middle

### Notes
- Tap is intentionally pressed-only — no Released, no StateChanged. Use LongPress if you need a press/release pair on touch
- Gestures are only allowed on Bool actions. The plugin UI hides the **+ Gesture** button on non-Bool actions; the runtime defensively skips any stray gesture binding on a non-Bool action with a `warn`

---

## 1.1.1 — 2026-04-07

### Fixed
- Mouse button bindings lost after closing and reopening the plugin — session now saves immediately after export
- Importing a config dropped mouse button bindings — import now recognizes `Keyboard_MouseLeftButton/Right/Middle` instances

---

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
