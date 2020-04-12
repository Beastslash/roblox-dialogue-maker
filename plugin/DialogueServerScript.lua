-- Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");

-- Get dialogue settings
local Settings = require(script.Settings);

-- Make sure that we have a connection with the remote functions/events
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections",3);
if not RemoteConnections then
	error("[Dialogue Maker] The DialogueMakerRemoteConnections folder couldn't be found in the ReplicatedStorage.");
end;

local DialogueLocations = {};
local DialogueLocationsFolder = script.DialogueLocations;

-- Add every dialogue that's in the folder to the dialogue array
for _, value in ipairs(DialogueLocationsFolder:GetChildren()) do
	if value.Value:FindFirstChild("DialogueContainer") then
		table.insert(DialogueLocations, value.Value);
	end;	
end;

RemoteConnections.GetNPCDialogue.OnServerInvoke = function(player)
	return DialogueLocations;
end

RemoteConnections.GetDefaultTheme.OnServerInvoke = function(player)
	return Settings.DefaultTheme;
end

RemoteConnections.GetAllThemes.OnServerInvoke = function(player)
	
	local Themes = {}
	
	for _, theme in ipairs(script.Themes:GetChildren()) do
		table.insert(Themes, theme:Clone());
	end;
	
	return Themes;
	
end
