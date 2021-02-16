local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");

local DefaultThemeName = nil;

local GUI = {};

function GUI.CreateNewDialogueGui(theme)
	local ThemeFolder = script.Parent.Parent.Themes;
	local DialogueGui;

	if theme and theme ~= "" then
		DialogueGui = ThemeFolder:FindFirstChild(theme);
		if not DialogueGui then
			warn("[Dialogue Maker] Can't find theme \""..theme.."\" in the Themes folder of the DialogueClientScript. Using default theme...");
		end;
	end;

	if not DialogueGui then
		DialogueGui = ThemeFolder:FindFirstChild(GUI.GetDefaultThemeName());
		if not DialogueGui then
			error("[Dialogue Maker] Default theme \""..GUI.GetDefaultThemeName().."\" couldn't be found in the themes folder.");
		end;
	end;

	return DialogueGui:Clone();
end;

function GUI.GetDefaultThemeName()

	-- Check if the theme is in the cache
	if DefaultThemeName then
		return DefaultThemeName;
	end;

	-- Call up the server.
	return RemoteConnections.GetDefaultTheme:InvokeServer();

end;

return GUI;