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
end;

RemoteConnections.GetDefaultTheme.OnServerInvoke = function(player)
	return Settings.DefaultTheme;
end;

RemoteConnections.GetAllThemes.OnServerInvoke = function(player)
	
	local Themes = {};
	
	for _, theme in ipairs(script.Themes:GetChildren()) do
		Themes[theme.Name] = theme:Clone();
	end;
	
	return Themes;
	
end;

RemoteConnections.PlayerPassesCondition.OnServerInvoke = function(player,npc,priority,dialogueType)
	
	-- Ensure security
	if not npc:IsA("Model") or typeof(priority) ~= "string" or typeof(dialogueType) ~= "string" then
		warn("[Dialogue Maker] "..player.Name.." failed a security check");
		error("[Dialogue Maker] Invalid parameters given to check if "..player.Name.." passes a condition");
	end;
	
	-- Search for condition
	local Condition;
	for _, condition in ipairs(script.Conditions:GetChildren()) do
		
		if condition.NPC.Value == npc and condition.Priority.Value == priority and condition.Type.Value == dialogueType then
			Condition = condition;
			break;
		end;
		
	end;
	
	-- Check if there is no condition or the condition passed
	if not Condition or require(Condition)() then
		return true;
	else
		return false;
	end;
	
end;

RemoteConnections.ExecuteAction.OnServerInvoke = function(player,npc,priority,dialogueType,beforeOrAfter)
	
	-- Ensure security
	if not npc:IsA("Model") or typeof(priority) ~= "string" or typeof(dialogueType) ~= "string" or typeof(beforeOrAfter) ~= "string" then
		warn("[Dialogue Maker] "..player.Name.." failed a security check");
		error("[Dialogue Maker] Invalid parameters given to check if "..player.Name.." passes a condition");
	end;
	
	-- Search for action
	local Action;
	for _, action in ipairs(script.Actions[beforeOrAfter]:GetChildren()) do
		
		if action.NPC.Value == npc and action.Priority.Value == priority and action.Type.Value == dialogueType then
			Action = action;
			break;
		end;
		
	end;
	
	-- Check if the action is synchronous
	local Action = require(Action);
	if Action.Synchronous then
		Action.Execute();
	else
		coroutine.wrap(Action.Execute)();
	end;

end;
