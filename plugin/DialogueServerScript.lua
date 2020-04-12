-- Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");

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

Players.PlayerAdded:Connect(function(player) 
	RemoteConnections.SendNPCDialogueToPlayer:FireClient(player,DialogueLocations);
end);
