local RemoteConnections = game:GetService("ReplicatedStorage"):WaitForChild("DialogueMakerRemoteConnections");

local Gui = {}

local DefaultThemeName;

function Gui.GetDefaultThemeName()
	
	-- Check if the theme is in the cache
	if DefaultThemeName then
		return DefaultThemeName;
	end;
	
	-- Call up the server.
	return RemoteConnections.GetDefaultTheme:InvokeServer();
	
end;

function Gui.CreateNewDialogueGui(theme)
	
	local ThemesFolder = script.Parent.Parent.Themes;
	local DialogueFolder;
	
	if theme and theme ~= "" then
		DialogueFolder = ThemesFolder:FindFirstChild(theme);
		if not DialogueFolder then
			warn("[Dialogue Maker] Can't find theme \""..theme.."\" in the Themes folder of the DialogueClientScript. Using default theme...");
		end;
	end;
	
	if not DialogueFolder then
		DialogueFolder = ThemesFolder:FindFirstChild(Gui.GetDefaultThemeName());
		if not DialogueFolder then
			error("[Dialogue Maker] Default theme \""..Gui.GetDefaultThemeName().."\" couldn't be found in the themes folder.");
		end;
	end;
	
	return DialogueFolder.DialogueGui:Clone();
	
end;

return Gui;
