# Changelog

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
