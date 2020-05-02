-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local ControllerService = game:GetService("ControllerService");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections",3);

-- Check if the DialogueMakerRemoteConnections folder was moved
if not RemoteConnections then
	error("[Dialogue Maker] Couldn't find the DialogueMakerRemoteConnections folder in the ReplicatedStorage.",0)
end;

-- Get themes
local Themes = script.Themes;
local DefaultTheme = RemoteConnections.GetDefaultTheme:InvokeServer();
local PlayerTalkingWithNPC = false;
local Events = {};

local TouchTimeout = RemoteConnections.GetTouchTimeout:InvokeServer();
local API = require(script.ClientAPI);

local function ReadDialogue(npc, dialogueSettings)
	
	if PlayerTalkingWithNPC then
		return;
	end;
	
	PlayerTalkingWithNPC = true;
	
	API.Trigger.DisableAllSpeechBubbles();
	API.Trigger.DisableAllClickDetectors();
	API.Player.SetPlayer(Player);
	
	if dialogueSettings.FreezePlayer then API.Player.FreezePlayer(); end;
	
	-- Show the dialogue GUI to the player
	local DialogueContainer = npc.DialogueContainer;
	local DialogueGui = API.Gui.CreateNewDialogueGui(dialogueSettings.Theme);
	local ResponseContainer = DialogueGui.DialogueContainer.ResponseContainer;
	local ResponseTemplate = ResponseContainer.ResponseTemplate:Clone();
	ResponseContainer.ResponseTemplate:Destroy();
	
	local DialoguePriority = "1";
	
	local RootDirectory = DialogueContainer["1"];
	local CurrentDirectory = RootDirectory;
	
	-- Check if the NPC has a name
	if typeof(dialogueSettings.Name) == "string" and dialogueSettings.Name ~= "" then
		DialogueGui.DialogueContainer.NPCNameFrame.Visible = true;
		DialogueGui.DialogueContainer.NPCNameFrame.NPCName.Text = dialogueSettings.Name;
	else
		DialogueGui.DialogueContainer.NPCNameFrame.Visible = false;
	end;
	
	-- Show the dialouge to the player
	while PlayerTalkingWithNPC and game:GetService("RunService").Heartbeat:Wait() do
		
		CurrentDirectory = API.Dialogue.GoToDirectory(RootDirectory, DialoguePriority:split("."));
		
		if CurrentDirectory.Redirect.Value and RemoteConnections.PlayerPassesCondition:InvokeServer(npc,CurrentDirectory) then
			
			RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"Before");
			
			local DialoguePriorityPath = CurrentDirectory.RedirectPriority.Value:split(".");
			table.remove(DialoguePriorityPath,1);
			DialoguePriority = table.concat(DialoguePriorityPath,".");
			CurrentDirectory = RootDirectory;
			
			RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"After");
			
		elseif RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then
			
			-- Run the before action if there is one
			if CurrentDirectory.HasBeforeAction.Value then
				RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"Before");
			end;
			
			-- Check if the message has any variables
			local MessageText = API.Dialogue.ReplaceVariablesWithValues(npc, CurrentDirectory.Message.Value);
			
			-- Show the message to the player
			local ThemeDialogueContainer = DialogueGui.DialogueContainer;
			
			-- Check if there are any response options
			local TextContainer;
			local ResponsesEnabled = false;
			if #CurrentDirectory.Responses:GetChildren() > 0 then
				
				API.Dialogue.ClearResponses(ResponseContainer);
				
				TextContainer = ThemeDialogueContainer.NPCTextContainerWithResponses;
				ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = true;
				ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = false;
				ResponsesEnabled = true;
				
			else
				
				TextContainer = ThemeDialogueContainer.NPCTextContainerWithoutResponses;
				ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = true;
				ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = false;
				ThemeDialogueContainer.ResponseContainer.Visible = false;
				
			end;
			
			local Message = "";
			
			if ThemeDialogueContainer:FindFirstChild("ClickToContinue") then
				if dialogueSettings.AllowPlayerToSkipDelay then
					ThemeDialogueContainer.ClickToContinue.Visible = true;
				else
					ThemeDialogueContainer.ClickToContinue.Visible = false;
				end;
			end;
			
			DialogueGui.Parent = PlayerGui;
			
			local NPCTalking = true;
			local WaitingForResponse = true;
			local Skipped = false;
			local FullMessageText = "";
			
			-- Put the letters of the message together for an animation effect
			API.Dialogue.SetDialogueSettings(dialogueSettings);
			API.Dialogue.SetNPC(npc);
			API.Dialogue.SetResponseTemplate(ResponseTemplate);
			local TextAnimation = API.Dialogue.RunAnimation(
				TextContainer, 
				MessageText, 
				CurrentDirectory, 
				ResponsesEnabled,
				DialoguePriority);
			
			-- Run the timeout code in the background
			--[[
			coroutine.wrap(function()
				
				if dialogueSettings.TimeoutEnabled and dialogueSettings.ConversationTimeoutInSeconds then
					
					-- Wait for the player if the developer wants to
					if ResponsesEnabled and dialogueSettings.WaitForResponse then
						return;
					end;
					
					-- Wait the timeout set by the developer
					wait(dialogueSettings.ConversationTimeoutInSeconds);
					WaitingForResponse = false;
					
				end;
				
			end)();
			
			while WaitingForResponse and PlayerTalkingWithNPC do
				game:GetService("RunService").Heartbeat:Wait();
			end;
			]]--
			
			-- Run after action
			if CurrentDirectory.HasAfterAction.Value and PlayerTalkingWithNPC then
				RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"After");
			end;
			
			if TextAnimation.Response and PlayerTalkingWithNPC then
				
				if (#TextAnimation.Response.Dialogue:GetChildren() ~= 0 or #TextAnimation.Response.Redirects:GetChildren() ~= 0) then
					
					DialoguePriority = string.sub(TextAnimation.Response.Priority.Value..".1",3);
					CurrentDirectory = RootDirectory;
					
				else
					DialogueGui:Destroy();
					PlayerTalkingWithNPC = false;
				end;
				
			else
				
				-- Check if there is more dialogue
				if PlayerTalkingWithNPC and (#CurrentDirectory.Dialogue:GetChildren() ~= 0 or #CurrentDirectory.Redirects:GetChildren() ~= 0) then
					DialoguePriority = DialoguePriority..".1";
					CurrentDirectory = RootDirectory;
				else
					DialogueGui:Destroy();
					PlayerTalkingWithNPC = false;
				end;
				
			end;
			
		elseif PlayerTalkingWithNPC then
			
			local SplitPriority = DialoguePriority:split(".");
			SplitPriority[#SplitPriority] = SplitPriority[#SplitPriority] + 1;
			DialoguePriority = table.concat(SplitPriority,".");
			
		end;
		
	end;
	
	API.Trigger.EnableAllSpeechBubbles();
	API.Trigger.EnableAllClickDetectors();
	if dialogueSettings.FreezePlayer then API.Player.UnfreezePlayer(); end;
	
end;

local NPCDialogue = RemoteConnections.GetNPCDialogue:InvokeServer()
	
print("[Dialogue Maker] Preparing dialogue that was received from the server...");

local ProximityNPCs = {};

-- Iterate through every NPC in order to 
for _, npc in ipairs(NPCDialogue) do
	
	-- Make sure all NPCs aren't affected if this one doesn't load properly
	local success, msg = pcall(function()
		
		local DialogueSettings = require(npc.DialogueContainer.Settings);
		
		if DialogueSettings.SpeechBubbleEnabled then
			
			if DialogueSettings.SpeechBubblePart then
				
				if DialogueSettings.SpeechBubblePart:IsA("BasePart") then
					
					local SpeechBubble = API.Trigger.CreateSpeechBubble(npc, DialogueSettings);
					
					-- Listen if the player clicks the speech bubble
					SpeechBubble.SpeechBubbleButton.MouseButton1Click:Connect(function()
						
						ReadDialogue(npc, DialogueSettings);
						
					end);
					
					SpeechBubble.Parent = PlayerGui;
					
				else
					warn("[Dialogue Viewer] The SpeechBubblePart for "..npc.Name.." is not a Part.");
				end;
				
			end;
			
		end;
		
		if DialogueSettings.PromptRegionEnabled then
			
			if DialogueSettings.PromptRegionPart then
				
				if DialogueSettings.PromptRegionPart:IsA("BasePart") then
					
					API.Gui.SetKeybindGuis(
						npc, 
						API.Gui.GetThemeFolderFromSettings(DialogueSettings),
						DialogueSettings.PromptRegionPart);
					
					local PlayerTouched;
					local LastTouchedTime;
					local HotkeyShown = false;
					
					local function ShowHotkey()
								
						-- Debounce
						if HotkeyShown then
							return;
						end;
						
						HotkeyShown = true;
						
						API.Gui.ToggleKeyboardKeybindGui(npc, true);
						
						local function StartConversation()
							Events.HotkeyGamepadPress:Disconnect();
							Events.HotkeyKeyboardPress:Disconnect();
							ReadDialogue(npc, DialogueSettings);
						end;
						
						local function CheckButton(input)
							if not PlayerTalkingWithNPC and (input.KeyCode == DialogueSettings.PromptRegionHotkeyKeyboard or input.KeyCode == DialogueSettings.PromptRegionHotkeyGamepad) then
								StartConversation();
							end;
						end
						
						if Events.HotkeyKeyboardPress then
							Events.HotkeyKeyboardPress:Disconnect();
						end;
						
						if Events.HotkeyGamepadPress then
							Events.HotkeyGamepadPress:Disconnect()
						end
						
						Events.HotkeyKeyboardPress = UserInputService.InputBegan:Connect(CheckButton);
						Events.HotkeyGamepadPress = UserInputService.InputBegan:Connect(CheckButton);
						
					end;
					
					local function HideHotkey()
						
						-- Debounce
						if not HotkeyShown then
							return;
						end;
						
						HotkeyShown = false;
						
						API.Gui.ToggleKeyboardKeybindGui(npc, false);
						
						if Events.HotkeyGamepadPress then
							Events.HotkeyGamepadPress:Disconnect();
						end;
						
						if Events.HotkeyKeyboardPress then
							Events.HotkeyKeyboardPress:Disconnect();
						end;
						
					end;
					
					RunService.Stepped:Connect(function()
							
						if PlayerTalkingWithNPC then
							HideHotkey();
						else
							local Distance = Player:DistanceFromCharacter(DialogueSettings.PromptRegionPart.Position);
							if Distance <= DialogueSettings.PromptRegionPartDistance then
								if DialogueSettings.PromptRegionAutoStart then
									if not LastTouchedTime or os.time() - TouchTimeout > LastTouchedTime then
										LastTouchedTime = os.time();
										HideHotkey();
										ReadDialogue(npc, DialogueSettings);
									else
										ShowHotkey();
									end;
								elseif DialogueSettings.PromptRegionHotkeyEnabled then
									ShowHotkey();
								end;
							else
								HideHotkey();
							end;
						end;
						
					end);
					
				else
					warn("[Dialogue Maker] The PromptRegionPart for "..npc.Name.." is not a Part.");
				end;
				
			end;
			
		end;
		
		if DialogueSettings.ClickDetectorEnabled then
			
			if DialogueSettings.ClickDetectorLocation or DialogueSettings.AutomaticallyCreateClickDetector then
				
				if DialogueSettings.AutomaticallyCreateClickDetector then
					
					local ClickDetector = Instance.new("ClickDetector");
					ClickDetector.MaxActivationDistance = DialogueSettings.DetectorActivationDistance;
					ClickDetector.Parent = npc;
					
					DialogueSettings.ClickDetectorLocation = ClickDetector;
					
				end;
				
				if DialogueSettings.ClickDetectorLocation:IsA("ClickDetector") then
					
					API.Trigger.AddClickDetector(npc, DialogueSettings.ClickDetectorLocation);
					
					DialogueSettings.ClickDetectorLocation.MouseClick:Connect(function()
						ReadDialogue(npc, DialogueSettings);
					end);
					
				else
					warn("[Dialogue Maker] The ClickDetectorLocation for "..npc.Name.." is not a ClickDetector.");
				end;
				
			end;
			
		end;
		
	end);
		
	if not success then
		warn("[Dialogue Maker] Couldn't load NPC "..npc.Name..": "..msg);
	end;
	
end;

print("[Dialogue Maker] Finished preparing dialogue.");

Player.CharacterRemoving:Connect(function()
	
	PlayerTalkingWithNPC = false;
	
end);
