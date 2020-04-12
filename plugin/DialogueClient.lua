--[[

	DialogueClient.lua
	Written by Christian Toney (DraconicChris)

]]--

-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");

local Player = Players.LocalPlayer;
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections",3);

-- Check if the DialogueMakerRemoteConnections folder was moved
if not RemoteConnections then
	error("[Dialogue Maker] Couldn't find the DialogueMakerRemoteConnections folder in the ReplicatedStorage.",0)
end;

local function ReadDialogue(npc)
	
end;

RemoteConnections.SendNPCDialogueToPlayer.OnClientEvent:Connect(function(npcs)
	
	print("[Dialogue Maker] Preparing dialogue that was received from the server...");
	
	-- Iterate through every NPC in order to 
	for _, npc in ipairs(npcs) do
		
		-- Make sure all NPCs aren't affected if this one doesn't load properly
		local success, msg = pcall(function()
			
			local DialogueSettings = npc.DialogueContainer.Settings;
			
			if DialogueSettings.SpeechBubbleEnabled.Value then
				
				if DialogueSettings.SpeechBubblePart.Value then
					
					if DialogueSettings.SpeechBubblePart.Value:IsA("Part") then
						
						local SpeechBubble = Instance.new("BillboardGui");
						SpeechBubble.Name = "SpeechBubble";
						SpeechBubble.LightInfluence = 0;
						SpeechBubble.ResetOnSpawn = false;
						SpeechBubble.Size = UDim2.new(2.5,0,2.5,0);
						SpeechBubble.StudsOffset = Vector3.new(0,2,0);
						
						local SpeechBubbleImage = Instance.new("ImageLabel");
						SpeechBubbleImage.Name = "SpeechBubbleImage";
						SpeechBubbleImage.Size = UDim2.new(1,0,1,0);
						SpeechBubbleImage.Image = "rbxassetid://4883127463";
						SpeechBubbleImage.Parent = SpeechBubble;
						
						SpeechBubble.Parent = DialogueSettings.SpeechBubblePart.Value;
						
					else
						warn("[Dialogue Viewer] The SpeechBubblePart for "..npc.Name.." is not a Part.");
					end;
					
				end;
				
			end;
			
			if DialogueSettings.PromptRegionEnabled.Value then
				
				if DialogueSettings.PromptRegionPart.Value then
					
					if DialogueSettings.PromptRegionPart.Value:IsA("Part") then
						
						local PlayerTouched;
						DialogueSettings.PromptRegionPart.Value.Touched:Connect(function(part)
							
							-- Make sure our player touched it and not someone else
							local PlayerFromCharacter = Players:GetPlayerFromCharacter(part.Parent);
							if PlayerFromCharacter == Player then
								ReadDialogue(npc);
							end;
							
						end);
							
					else
						warn("[Dialogue Viewer] The PromptRegionPart for "..npc.Name.." is not a Part.");
					end;
					
				end;
				
			end;
			
			if DialogueSettings.ClickEnabled.Value then
				
				if DialogueSettings.ClickDetectorLocation.Value then
					
					if DialogueSettings.ClickDetectorLocation.Value:IsA("ClickDetector") then
						
						DialogueSettings.ClickDetectorLocation.Value.MouseClick:Connect(function()
							ReadDialogue(npc);
						end);
						
					else
						warn("[Dialogue Viewer] The ClickDetectorLocation for "..npc.Name.." is not a ClickDetector.");
					end;
					
				end;
				
			end;
			
		end)
		
	end;
	
	print("[Dialogue Maker] Finished preparing dialogue.");
	
end);
