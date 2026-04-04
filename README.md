# InputPro Runtime

Client-side runtime for the [InputPro](https://create.roblox.com/store/asset/70499943911585/InputPro) input binding system for Roblox.

Provides a clean API for input handling: bind actions to keys, switch contexts, detect devices, and show auto-updating prompt hints.

## Installation

### Option 1: Download
1. Download [`InputProService.luau`](https://github.com/BerDerDevStuff/InputPro/blob/main/runtime/InputProService.luau) from this repository
2. Place it in `ReplicatedStorage/InputProRuntime/InputProService`

### Option 2: Wally
```toml
[dependencies]
InputPro = "BerDerDevStuff/inputpro@1.0.0"
```

### Option 3: InputPro Plugin (automatic)
If you use the [InputPro Studio Plugin](https://create.roblox.com/store), the runtime is auto-installed when you export a config.

## Quick Start (with Plugin)

The plugin generates a bootstrap script automatically. After exporting, just press Play:

```lua
-- This is auto-created by the plugin in StarterPlayerScripts
local InputProService = require(
    game:GetService("ReplicatedStorage")
    :WaitForChild("InputProRuntime")
    :WaitForChild("InputProService")
)
InputProService.Init("MyGameInput")
```

Then in your game scripts:

```lua
local InputProService = require(
    game:GetService("ReplicatedStorage").InputProRuntime.InputProService
)

InputProService.BindPressed("Jump", function()
    -- Handle jump
end)

InputProService.BindStateChanged("Move", function(direction)
    -- direction is a Vector2
end)
```

## Quick Start (without Plugin)

Build input mappings entirely in code — no plugin required:

```lua
local InputProService = require(
    game:GetService("ReplicatedStorage")
    :WaitForChild("InputProRuntime")
    :WaitForChild("InputProService")
)

InputProService.InitManual()

-- Create context and actions
InputProService.CreateContext("Gameplay", 1, false)
InputProService.CreateAction("Gameplay", "Jump", Enum.InputActionType.Bool)
InputProService.CreateBinding("Jump", Enum.KeyCode.Space)
InputProService.CreateBinding("Jump", Enum.KeyCode.ButtonA)

-- Enable and listen
InputProService.SetContext("Gameplay", true)
InputProService.BindPressed("Jump", function()
    print("Jump!")
end)
```

See [`examples/ManualSetup.client.luau`](examples/ManualSetup.client.luau) for a complete example.

## Code Generation

The plugin can generate boilerplate code for your actions and insert it directly into your scripts. Select a `LocalScript` in the Explorer, then use **Edit > Insert Code** — pick an action, choose which events to bind (`Pressed`, `Released`, `StateChanged`), preview the output, and click Insert. The `require` block for InputProService is added automatically if missing.

## API Reference

Full documentation: **[InputPro Docs](https://BerDerDevStuff.github.io/InputPro/)**

### Initialization
| Method | Description |
|--------|-------------|
| `Init(configName)` | Load an exported config (from plugin) |
| `InitManual()` | Initialize for code-only setup |

### Actions
| Method | Description |
|--------|-------------|
| `GetAction(name)` | Get InputAction by name or `"Context/Name"` |
| `BindPressed(name, callback)` | Bool action pressed (key down) |
| `BindReleased(name, callback)` | Bool action released (key up) |
| `BindStateChanged(name, callback)` | Any action type value changed |

### Contexts
| Method | Description |
|--------|-------------|
| `GetContext(name)` | Get InputContext by name |
| `SetContext(name, exclusive?)` | Enable a context (exclusive disables others) |
| `DisableContext(name)` | Disable a context |
| `ContextChanged` | Signal: `(contextName, enabled)` |

### Device Detection
| Method | Description |
|--------|-------------|
| `GetActiveDevice()` | Returns `"Keyboard"`, `"Gamepad"`, or `"Touch"` |
| `ActiveDeviceChanged` | Signal: `(device)` |

### Prompt Hints
| Method | Description |
|--------|-------------|
| `CreatePromptHint(name, parent, config?)` | Auto-updating key badge UI |
| `GetInputImage(name, device?)` | Get key glyph image/name |

### Manual Creation
| Method | Description |
|--------|-------------|
| `CreateContext(name, priority, sink)` | Create InputContext from code |
| `CreateAction(context, name, type)` | Create InputAction from code |
| `CreateBinding(action, keyCode?, inputType?, config?)` | Create InputBinding from code |

## Examples

- [`examples/PluginBootstrap.client.luau`](examples/PluginBootstrap.client.luau) — What the plugin auto-generates
- [`examples/ManualSetup.client.luau`](examples/ManualSetup.client.luau) — Full manual setup without plugin
- [`examples/test_config.rbxm`](examples/test_config.rbxm) — Pre-built config with sample contexts, actions, and bindings. Insert into `StarterGui` and use with `InputProService.Init()` to test the runtime without the plugin.

## License

MIT License — see [LICENSE](LICENSE)
