local RemoteConnections = game:GetService("ReplicatedStorage"):WaitForChild("DialogueMakerRemoteConnections");

local Gui = {}

local DefaultThemeName;
local ThemesFolder = script.Parent.Parent.Themes;
local ThemeFolder;
local KeybindGuis = {};

function Gui.GetDefaultThemeName()
	
	-- Check if the theme is in the cache
	if DefaultThemeName then
		return DefaultThemeName;
	end;
	
	-- Call up the server.
	return RemoteConnections.GetDefaultTheme:InvokeServer();
	
end;

function Gui.GetThemeFolder(theme)
	
	local DialogueFolder;
	
	if theme and theme ~= "" then
		DialogueFolder = ThemesFolder:FindFirstChild(theme);
		if not DialogueFolder then
			warn("[Dialogue Maker] Can't find theme \""..theme.."\" in the Themes folder of the DialogueClientScript.");
		end;
	end;
	
	return DialogueFolder;
	
end;

function Gui.GetThemeFolderFromSettings(dialogueSettings)
	
	if dialogueSettings.Theme and dialogueSettings.Theme ~= "" then
		return Gui.GetThemeFolder(dialogueSettings.Theme);
	else
		return Gui.GetThemeFolder(Gui.GetDefaultThemeName());
	end;
	
end;

function Gui.CreateNewDialogueGui(theme)

	ThemeFolder = Gui.GetThemeFolder(theme);
	
	if not ThemeFolder then
		ThemeFolder = ThemesFolder:FindFirstChild(Gui.GetDefaultThemeName());
		if not ThemeFolder then
			error("[Dialogue Maker] Default theme \""..Gui.GetDefaultThemeName().."\" couldn't be found in the themes folder.");
		end;
	end;
	
	return ThemeFolder.DialogueGui:Clone();
	
end;

function Gui.SetKeybindGuis(npc, themeFolder, keybindPart)
	
	if not npc:IsA("Model") or not themeFolder:IsA("Folder") or not keybindPart:IsA("BasePart") then
		error("[Dialogue Maker] Type error!");
	end;
	
	if not KeybindGuis[npc] then
		KeybindGuis[npc] = {};
	end;
	
	KeybindGuis[npc].KeyboardKeybindGui = themeFolder:FindFirstChild("KeyboardKeybindGui");
	KeybindGuis[npc].GamepadKeybindGui = themeFolder:FindFirstChild("GamepadKeybindGui");
	
	if KeybindGuis[npc].KeyboardKeybindGui and KeybindGuis[npc].KeyboardKeybindGui:IsA("BillboardGui") then
		KeybindGuis[npc].KeyboardKeybindGui.Enabled = false;
		KeybindGuis[npc].KeyboardKeybindGui.Parent = keybindPart;
	end;
	
	if KeybindGuis[npc].GamepadKeybindGui and KeybindGuis[npc].GamepadKeybindGui:IsA("BillboardGui") then
		KeybindGuis[npc].GamepadKeybindGui.Enabled = false;
		KeybindGuis[npc].GamepadKeybindGui.Parent = keybindPart;
	end;
	
end;

function Gui.ToggleKeyboardKeybindGui(npc, guiEnabled)
	
	if not npc:IsA("Model") or typeof(guiEnabled) ~= "boolean" then
		error("[Dialogue Maker] Type error!");
	end;
	
	if not KeybindGuis[npc] or not KeybindGuis[npc].KeyboardKeybindGui then
		error("[Dialogue Maker] "..npc.Name.." doesn't have a KeyboardKeybindGui!");
	end
	
	KeybindGuis[npc].KeyboardKeybindGui.Enabled = guiEnabled;
	
end;

return Gui;
