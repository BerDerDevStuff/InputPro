-- InputProService — Client-side runtime for the InputPro plugin.
-- Author: BerDeryaDev1010
-- License: MIT
--
-- Manages InputContext/InputAction/InputBinding instances created by the plugin export.
--
-- Usage:
--   local InputProService = require(path.to.InputProService)
--   InputProService.Init("MyGameInput")
--   InputProService.SetContext("Gameplay", true)
--
--   InputProService.BindPressed("Jump", function()
--       -- Handle jump press
--   end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local InputProService = {}

type Connection = {
	Disconnect: (self: Connection) -> ()
}

type ContextChangedSignal = {
	Connect: (self: ContextChangedSignal, callback: (contextName: string, enabled: boolean) -> ()) -> RBXScriptConnection,
	Once: (self: ContextChangedSignal, callback: (contextName: string, enabled: boolean) -> ()) -> RBXScriptConnection,
	Wait: (self: ContextChangedSignal) -> (string, boolean)
}

local contextChangedBindable = Instance.new("BindableEvent")
local deviceChangedBindable = Instance.new("BindableEvent")

InputProService.ContextChanged = (contextChangedBindable.Event :: any) :: ContextChangedSignal

InputProService.ActiveDeviceChanged = deviceChangedBindable.Event


local _isInitialized = false
local _initSignal = Instance.new("BindableEvent")
local _configFolder: Folder? = nil
local _contexts: {[string]: InputContext} = {}
local _actions: {[string]: InputAction} = {}
local _activeContexts: {string} = {}

local function waitForInit()
	if _isInitialized then return end
	while not _isInitialized do
		task.wait(0.1)
	end
end

local _activeDevice = "Keyboard"

local function getDeviceCategory(inputType: Enum.UserInputType): string?
	if inputType == Enum.UserInputType.Keyboard
		or inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseButton3
		or inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.MouseWheel then
		return "Keyboard"
	elseif inputType == Enum.UserInputType.Gamepad1
		or inputType == Enum.UserInputType.Gamepad2
		or inputType == Enum.UserInputType.Gamepad3
		or inputType == Enum.UserInputType.Gamepad4 then
		return "Gamepad"
	elseif inputType == Enum.UserInputType.Touch then
		return "Touch"
	end
	return nil
end

local _initialCategory = getDeviceCategory(UserInputService:GetLastInputType())
if _initialCategory then
	_activeDevice = _initialCategory
end

UserInputService.LastInputTypeChanged:Connect(function(inputType)
	local category = getDeviceCategory(inputType)
	if category and category ~= _activeDevice then
		_activeDevice = category
		deviceChangedBindable:Fire(category)
	end
end)

local function _isGamepadKeyCode(keyCode: Enum.KeyCode): boolean
	local name = keyCode.Name
	return name:match("^Button") ~= nil
		or name:match("^DPad") ~= nil
		or name:match("^Thumbstick") ~= nil
end

local KEY_DISPLAY_NAMES = {
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
	Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	LeftShift = "LShift", RightShift = "RShift",
	LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftAlt = "LAlt", RightAlt = "RAlt",
	Return = "Enter", Backspace = "Bksp",
	BackQuote = "`", Minus = "-", Equals = "=",
	LeftBracket = "[", RightBracket = "]",
	BackSlash = "\\", Semicolon = ";", Quote = "'",
	Comma = ",", Period = ".", Slash = "/",
}

local function _getKeyDisplayName(keyCode: Enum.KeyCode): string
	return KEY_DISPLAY_NAMES[keyCode.Name] or keyCode.Name
end

local function cacheResources(folder: Folder)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("InputContext") then
			_contexts[child.Name] = child

			for _, action in ipairs(child:GetChildren()) do
				if action:IsA("InputAction") then
					if _actions[action.Name] then
						warn("InputProService: Duplicate action name '" .. action.Name .. "'. Use 'ContextName/ActionName' for access.")
					end
					_actions[action.Name] = action
					_actions[child.Name .. "/" .. action.Name] = action
				end
			end
		end
	end
end

local function setupTouchBindings(folder: Folder)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	for _, child in ipairs(folder:GetChildren()) do
		if not child:IsA("InputContext") then continue end

		for _, action in ipairs(child:GetChildren()) do
			if not action:IsA("InputAction") then continue end

			local buttonPath = action:GetAttribute("TouchButtonPath")
			if not buttonPath or buttonPath == "" then continue end

			local pathParts = string.split(buttonPath, ".")
			local current: Instance? = playerGui

			local startIdx = 1
			for i, part in ipairs(pathParts) do
				if part == "PlayerGui" or part == "StarterGui" then
					startIdx = i + 1
					break
				end
			end

			for i = startIdx, #pathParts do
				if current then
					current = current:FindFirstChild(pathParts[i])
				end
			end

			if current and current:IsA("GuiButton") then
				local binding = Instance.new("InputBinding")
				binding.Name = "TouchBind_" .. current.Name
				binding.UIButton = current
				binding.Parent = action
			end
		end
	end
end

--- Mark the service as initialized without loading a config folder.
--- Use this when building input mappings entirely from code via the Manual Creation API.
function InputProService.InitManual()
	if _isInitialized then return end
	_isInitialized = true
	_initSignal:Fire()
end

--- Initialize from an exported config folder.
--- Looks for PlayerGui/InputPro/<configName> (exported from StarterGui by the plugin).
--- Call this once at the start of your game.
---@param configName string — The name you used when exporting from the plugin.
function InputProService.Init(configName: string)
	if _isInitialized then return end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local root = playerGui:WaitForChild("InputPro", 5)

	if not root then
		warn("InputProService: No 'InputPro' folder found in PlayerGui. Did you export your config?")
		_isInitialized = true
		_initSignal:Fire()
		return
	end

	local configFolder = root:FindFirstChild(configName)
	if not configFolder then
		warn("InputProService: Configuration '" .. configName .. "' not found.")
		_isInitialized = true
		_initSignal:Fire()
		return
	end

	cacheResources(configFolder)
	setupTouchBindings(configFolder)

	_configFolder = configFolder
	_isInitialized = true
	_initSignal:Fire()

	local defaultContext = configFolder:GetAttribute("DefaultContext")
	if defaultContext and _contexts[defaultContext] then
		InputProService.SetContext(defaultContext, false)
	end
end


--- Enable a context. If exclusive is true, all other contexts are disabled first.
---@param contextName string — Name of the context to enable.
---@param exclusive boolean? — If true, disables all other contexts. Default false.
function InputProService.SetContext(contextName: string, exclusive: boolean?)
	local context = _contexts[contextName]
	if not context then
		warn("InputProService: Context '" .. contextName .. "' not found.")
		return
	end

	if exclusive then
		for name, ctx in pairs(_contexts) do
			if name ~= contextName then
				ctx.Enabled = false
			end
		end
		_activeContexts = { contextName }
	else
		if not table.find(_activeContexts, contextName) then
			table.insert(_activeContexts, contextName)
		end
	end

	context.Enabled = true
	contextChangedBindable:Fire(contextName, true)
end

--- Disable a specific context.
---@param contextName string — Name of the context to disable.
function InputProService.DisableContext(contextName: string)
	local context = _contexts[contextName]
	if not context then return end

	context.Enabled = false

	for i, name in ipairs(_activeContexts) do
		if name == contextName then
			table.remove(_activeContexts, i)
			break
		end
	end

	contextChangedBindable:Fire(contextName, false)
end

--- Returns the InputContext instance by name, or nil if not found.
---@param name string — Context name.
---@return InputContext?
function InputProService.GetContext(name: string): InputContext?
	return _contexts[name]
end

--- Returns the InputAction instance by name, or nil if not found.
--- Supports both simple names ("Jump") and qualified names ("Gameplay/Jump").
---@param name string — Action name or "ContextName/ActionName".
---@return InputAction?
function InputProService.GetAction(name: string): InputAction?
	return _actions[name]
end

--- Connect to the Pressed event of a Bool-type action.
--- Fires when the action transitions from false to true.
---@param actionName string — Name of the action.
---@param callback () -> () — Function to call on press.
---@return Connection — Call :Disconnect() to stop listening.
function InputProService.BindPressed(actionName: string, callback: () -> ()): Connection
	waitForInit()
	local action = _actions[actionName]
	if not action then
		warn("InputProService: Action '" .. actionName .. "' not found.")
		return { Disconnect = function() end }
	end

	local conn = action.Pressed:Connect(callback)
	return { Disconnect = function() conn:Disconnect() end }
end

--- Connect to the Released event of a Bool-type action.
--- Fires when the action transitions from true to false.
---@param actionName string — Name of the action.
---@param callback () -> () — Function to call on release.
---@return Connection — Call :Disconnect() to stop listening.
function InputProService.BindReleased(actionName: string, callback: () -> ()): Connection
	waitForInit()
	local action = _actions[actionName]
	if not action then
		warn("InputProService: Action '" .. actionName .. "' not found.")
		return { Disconnect = function() end }
	end

	local conn = action.Released:Connect(callback)
	return { Disconnect = function() conn:Disconnect() end }
end

--- Connect to the StateChanged event of any action type.
--- For Bool: receives true/false. For Direction1D: number.
--- For Direction2D: Vector2. For Direction3D: Vector3.
---@param actionName string — Name of the action.
---@param callback (value: any) -> () — Function receiving the new state value.
---@return Connection — Call :Disconnect() to stop listening.
function InputProService.BindStateChanged(actionName: string, callback: (value: any) -> ()): Connection
	waitForInit()
	local action = _actions[actionName]
	if not action then
		warn("InputProService: Action '" .. actionName .. "' not found.")
		return { Disconnect = function() end }
	end

	local conn = action.StateChanged:Connect(callback)
	return { Disconnect = function() conn:Disconnect() end }
end

--- Returns the current active input device category: "Keyboard", "Gamepad", or "Touch".
---@return string
function InputProService.GetActiveDevice(): string
	return _activeDevice
end

--- Returns the image asset and/or key name for an action's binding on the current device.
--- For gamepad: returns (assetId, keyCodeName) using GetImageForKeyCode.
--- For keyboard: returns (nil, displayName) e.g. "E", "Space", "LShift".
--- For touch or no matching binding: returns (nil, nil).
---@param actionName string — Action name or "ContextName/ActionName".
---@param device string? — Override device ("Keyboard", "Gamepad", "Touch"). Uses active device if nil.
---@return string? imageAssetId
---@return string? keyDisplayName
function InputProService.GetInputImage(actionName: string, device: string?): (string?, string?)
	waitForInit()
	local action = _actions[actionName]
	if not action then
		warn("InputProService: Action '" .. actionName .. "' not found.")
		return nil, nil
	end

	local targetDevice = device or _activeDevice
	if targetDevice == "Touch" then return nil, nil end

	local MOUSE_ICONS = {
		Keyboard_MouseLeftButton   = { image = "rbxassetid://123465006244232", name = "MouseLeftButton" },
		Keyboard_MouseRightButton  = { image = "rbxassetid://126168658869414", name = "MouseRightButton" },
		Keyboard_MouseMiddleButton = { image = "rbxassetid://85495289721827",  name = "MouseMiddleButton" },
	}

	for _, child in ipairs(action:GetChildren()) do
		if not child:IsA("InputBinding") then continue end

		-- Mouse button bindings (KeyCode is Unknown, name encodes the input type)
		if targetDevice == "Keyboard" and MOUSE_ICONS[child.Name] then
			local info = MOUSE_ICONS[child.Name]
			return info.image, info.name
		end

		local keyCode = child.KeyCode
		if keyCode == Enum.KeyCode.Unknown then continue end

		local isGamepad = _isGamepadKeyCode(keyCode)

		if targetDevice == "Gamepad" and isGamepad then
			local image = UserInputService:GetImageForKeyCode(keyCode)
			if image and image ~= "" then
				return image, keyCode.Name
			end
			return nil, keyCode.Name
		elseif targetDevice == "Keyboard" and not isGamepad then
			return nil, _getKeyDisplayName(keyCode)
		end
	end

	return nil, nil
end

--- Corner positions for prompt hint badges.
InputProService.PromptCorner = {
	TopLeft = "TopLeft",
	TopRight = "TopRight",
	BottomLeft = "BottomLeft",
	BottomRight = "BottomRight",
	Center = "Center",
}

local function createDefaultBadge(actionName: string, size: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "PromptHint_" .. actionName
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = frame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(200, 200, 200)
	uiStroke.Thickness = 1.5
	uiStroke.Parent = frame

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "GlyphImage"
	imageLabel.Size = UDim2.fromScale(0.7, 0.7)
	imageLabel.Position = UDim2.fromScale(0.5, 0.5)
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.BackgroundTransparency = 1
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.Visible = false
	imageLabel.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "KeyText"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.Visible = false
	textLabel.Parent = frame

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 18
	textConstraint.MinTextSize = 6
	textConstraint.Parent = textLabel

	return frame
end

--- Creates a key badge on a GuiObject showing the bound input for an action.
--- Clones from PromptHintTemplate in the config folder if available, otherwise uses a default.
--- Auto-updates when the player switches between keyboard/gamepad. Hidden on touch.
--- Note: If badges overlap with sibling UI elements, set the parent ScreenGui's
--- ZIndexBehavior to Enum.ZIndexBehavior.Global for correct layering.
---@param actionName string — Action name.
---@param parent GuiObject — The UI element to attach the badge to.
---@param config table? — Optional: { Corner: string?, Size: number?, Offset: Vector2? }
---@return table — { Frame: Frame, Update: () -> (), Destroy: () -> () }
function InputProService.CreatePromptHint(actionName: string, parent: GuiObject, config: {
	Corner: string?,
	Size: number?,
	Offset: Vector2?,
}?)
	waitForInit()
	config = config or {}
	local corner = config.Corner or "TopRight"
	local size = config.Size or 32
	local offset = config.Offset or Vector2.new(0, 0)

	local cornerPositions = {
		TopLeft = UDim2.new(0, offset.X, 0, offset.Y),
		TopRight = UDim2.new(1, offset.X, 0, offset.Y),
		BottomLeft = UDim2.new(0, offset.X, 1, offset.Y),
		BottomRight = UDim2.new(1, offset.X, 1, offset.Y),
		Center = UDim2.new(0.5, offset.X, 0.5, offset.Y),
	}

	-- Clone from template or create default
	local frame
	local template = _configFolder and _configFolder:FindFirstChild("PromptHintTemplate")
	if template then
		frame = template:Clone()
		frame.Name = "PromptHint_" .. actionName
		frame.Size = UDim2.fromOffset(size, size)
	else
		frame = createDefaultBadge(actionName, size)
	end

	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = cornerPositions[corner] or cornerPositions.TopRight
	frame.ZIndex = 100

	-- Ensure all children also render above surrounding elements
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.ZIndex = 999
		end
	end

	local imageLabel = frame:FindFirstChild("GlyphImage")
	local textLabel = frame:FindFirstChild("KeyText")

	local function update()
		if _activeDevice == "Touch" then
			frame.Visible = false
			return
		end

		local image, keyName = InputProService.GetInputImage(actionName)

		if image and image ~= "" and imageLabel then
			imageLabel.Image = image
			imageLabel.Visible = true
			if textLabel then textLabel.Visible = false end
			frame.Visible = true
		elseif keyName and textLabel then
			textLabel.Text = keyName
			textLabel.Visible = true
			if imageLabel then imageLabel.Visible = false end
			frame.Visible = true
		else
			frame.Visible = false
		end
	end

	local conn = deviceChangedBindable.Event:Connect(update)
	frame.Parent = parent
	update()

	return {
		Frame = frame,
		Update = update,
		Destroy = function()
			conn:Disconnect()
			frame:Destroy()
		end,
	}
end

--- Create a new InputContext at runtime.
-- name: Context name (must be unique).
-- priority: Higher numbers are processed first.
-- sink: If true, blocks input from reaching lower-priority contexts.
function InputProService.CreateContext(name: string, priority: number, sink: boolean): InputContext
	if _contexts[name] then
		warn("InputProService: Context '" .. name .. "' already exists.")
		return _contexts[name]
	end

	local context = Instance.new("InputContext")
	context.Name = name
	context.Priority = priority or 0
	context.Sink = sink or false
	context.Enabled = false

	local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
	local root = playerScripts:FindFirstChild("InputProRuntime")
	if not root then
		root = Instance.new("Folder")
		root.Name = "InputProRuntime"
		root.Parent = playerScripts
	end
	context.Parent = root

	_contexts[name] = context
	return context
end

--- Create a new InputAction under an existing context.
-- contextName: Parent context name.
-- actionName: Action name (must be unique).
-- actionType: Bool, Direction1D, Direction2D, Direction3D, or ViewportPosition.
function InputProService.CreateAction(contextName: string, actionName: string, actionType: Enum.InputActionType): InputAction?
	local context = _contexts[contextName]
	if not context then
		warn("InputProService: Context '" .. contextName .. "' not found.")
		return nil
	end

	if _actions[actionName] then
		warn("InputProService: Action '" .. actionName .. "' already exists.")
		return _actions[actionName]
	end

	local action = Instance.new("InputAction")
	action.Name = actionName
	action.Type = actionType
	action.Parent = context

	_actions[actionName] = action
	_actions[contextName .. "/" .. actionName] = action
	return action
end

local ANALOG_TRIGGER_KEYS = {
	[Enum.KeyCode.ButtonR2] = true,
	[Enum.KeyCode.ButtonL2] = true,
}

--- Create a new InputBinding under an existing action.
-- actionName: Parent action name.
-- inputCode: Key/button to bind (keyboard/gamepad). Optional.
-- inputType: Fallback for mouse buttons etc. Optional.
-- config: Optional table { PressedThreshold: number?, ReleasedThreshold: number? }
function InputProService.CreateBinding(actionName: string, inputCode: Enum.KeyCode?, inputType: Enum.UserInputType?, config: {
	PressedThreshold: number?,
	ReleasedThreshold: number?,
}?): InputBinding?
	local action = _actions[actionName]
	if not action then
		warn("InputProService: Action '" .. actionName .. "' not found.")
		return nil
	end

	local binding = Instance.new("InputBinding")

	if inputCode and inputCode ~= Enum.KeyCode.Unknown then
		binding.Name = "Bind_" .. inputCode.Name
		binding.KeyCode = inputCode

		if config and config.PressedThreshold then
			binding.PressedThreshold = config.PressedThreshold
		elseif ANALOG_TRIGGER_KEYS[inputCode] then
			binding.PressedThreshold = 0.1
		end
		if config and config.ReleasedThreshold then
			binding.ReleasedThreshold = config.ReleasedThreshold
		elseif ANALOG_TRIGGER_KEYS[inputCode] then
			binding.ReleasedThreshold = 0.1
		end
	elseif inputType then
		local MOUSE_NAMES = {
			[Enum.UserInputType.MouseButton1] = "MouseLeftButton",
			[Enum.UserInputType.MouseButton2] = "MouseRightButton",
			[Enum.UserInputType.MouseButton3] = "MouseMiddleButton",
		}
		binding.Name = "Keyboard_" .. (MOUSE_NAMES[inputType] or inputType.Name)
	else
		binding:Destroy()
		warn("InputProService: Invalid parameters for CreateBinding.")
		return nil
	end

	binding.Parent = action
	return binding
end

return InputProService
