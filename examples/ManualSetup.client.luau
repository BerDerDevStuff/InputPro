-- InputPro Manual Setup Example
-- Shows how to use InputProService without the plugin — build everything in code.
--
-- Place in: StarterPlayerScripts/
-- Requires: InputProService in ReplicatedStorage/InputProRuntime/

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputProService = require(
	ReplicatedStorage:WaitForChild("InputProRuntime"):WaitForChild("InputProService")
)

-- ============================================================================
-- 1. INITIALIZE (manual mode — no exported config needed)
-- ============================================================================

InputProService.InitManual()

-- ============================================================================
-- 2. CREATE CONTEXTS
-- ============================================================================
-- Contexts group actions and control when they're active.
-- Higher priority contexts process input first.
-- Sink = true means input won't pass to lower-priority contexts.

InputProService.CreateContext("Gameplay", 1, false)
InputProService.CreateContext("UI", 2, true) -- UI has higher priority and sinks

-- ============================================================================
-- 3. CREATE ACTIONS
-- ============================================================================
-- Action types:
--   Bool          — on/off (jump, shoot, interact)
--   Direction1D   — single axis (throttle, zoom)
--   Direction2D   — two axes (movement, camera)
--   Direction3D   — three axes (flight)
--   ViewportPosition — screen coordinates (mouse cursor)

InputProService.CreateAction("Gameplay", "Jump", Enum.InputActionType.Bool)
InputProService.CreateAction("Gameplay", "Sprint", Enum.InputActionType.Bool)
InputProService.CreateAction("Gameplay", "Interact", Enum.InputActionType.Bool)
InputProService.CreateAction("Gameplay", "Move", Enum.InputActionType.Direction2D)
InputProService.CreateAction("UI", "CloseMenu", Enum.InputActionType.Bool)
InputProService.CreateAction("UI", "Confirm", Enum.InputActionType.Bool)

-- ============================================================================
-- 4. CREATE BINDINGS
-- ============================================================================
-- Each action can have multiple bindings (keyboard + gamepad).
-- For analog triggers (R2/L2), you can set custom thresholds.

-- Jump: Space (keyboard) + A button (gamepad)
InputProService.CreateBinding("Jump", Enum.KeyCode.Space)
InputProService.CreateBinding("Jump", Enum.KeyCode.ButtonA)

-- Sprint: Left Shift (keyboard) + Left Trigger (gamepad, with threshold)
InputProService.CreateBinding("Sprint", Enum.KeyCode.LeftShift)
InputProService.CreateBinding("Sprint", Enum.KeyCode.ButtonL2, nil, {
	PressedThreshold = 0.3,
	ReleasedThreshold = 0.2,
})

-- Interact: E key + Y button
InputProService.CreateBinding("Interact", Enum.KeyCode.E)
InputProService.CreateBinding("Interact", Enum.KeyCode.ButtonY)

-- Move: WASD + left thumbstick
InputProService.CreateBinding("Move", Enum.KeyCode.W)
InputProService.CreateBinding("Move", Enum.KeyCode.S)
InputProService.CreateBinding("Move", Enum.KeyCode.A)
InputProService.CreateBinding("Move", Enum.KeyCode.D)
InputProService.CreateBinding("Move", Enum.KeyCode.Thumbstick1)

-- UI: Escape/B to close, Enter/A to confirm
InputProService.CreateBinding("CloseMenu", Enum.KeyCode.Escape)
InputProService.CreateBinding("CloseMenu", Enum.KeyCode.ButtonB)
InputProService.CreateBinding("Confirm", Enum.KeyCode.Return)
InputProService.CreateBinding("Confirm", Enum.KeyCode.ButtonA)

-- ============================================================================
-- 5. ENABLE DEFAULT CONTEXT
-- ============================================================================

InputProService.SetContext("Gameplay", true)

-- ============================================================================
-- 6. CONNECT EVENTS
-- ============================================================================

-- Bool actions: BindPressed / BindReleased
InputProService.BindPressed("Jump", function()
	local character = Players.LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

InputProService.BindPressed("Sprint", function()
	local character = Players.LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then humanoid.WalkSpeed = 32 end
	end
end)

InputProService.BindReleased("Sprint", function()
	local character = Players.LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then humanoid.WalkSpeed = 16 end
	end
end)

InputProService.BindPressed("Interact", function()
	print("Interact pressed!")
end)

-- Direction2D: BindStateChanged receives a Vector2
InputProService.BindStateChanged("Move", function(value)
	-- value.X = left/right (-1 to 1), value.Y = forward/back (-1 to 1)
	print("Move:", value)
end)

-- UI actions
InputProService.BindPressed("CloseMenu", function()
	-- Switch back to Gameplay exclusively
	InputProService.SetContext("Gameplay", true)
	print("Menu closed")
end)

InputProService.BindPressed("Confirm", function()
	print("Confirmed!")
end)

-- ============================================================================
-- 7. CONTEXT SWITCHING EXAMPLE
-- ============================================================================

-- Open a menu: switch to UI context exclusively
local function openMenu()
	InputProService.SetContext("UI", true)
	print("Menu opened — UI context active")
end

-- Listen for context changes
InputProService.ContextChanged:Connect(function(name, enabled)
	print("Context:", name, enabled and "enabled" or "disabled")
end)

-- ============================================================================
-- 8. DEVICE DETECTION
-- ============================================================================

print("Current device:", InputProService.GetActiveDevice())

InputProService.ActiveDeviceChanged:Connect(function(device)
	print("Switched to:", device) -- "Keyboard", "Gamepad", or "Touch"
end)

-- ============================================================================
-- 9. PROMPT HINTS
-- ============================================================================
-- Creates an auto-updating key badge on a UI element.
-- Shows "E" on keyboard, gamepad glyph on controller, hides on touch.

--[[
-- Example: attach a prompt hint to a BillboardGui button
local hint = InputProService.CreatePromptHint("Interact", someGuiButton, {
	Corner = "TopRight",
	Size = 28,
	Offset = Vector2.new(4, 4),
})

-- hint.Frame   — the UI Frame instance
-- hint.Update() — force refresh
-- hint.Destroy() — cleanup
--]]
