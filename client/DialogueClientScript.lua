-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local ControllerService = game:GetService("ControllerService");
local RunService = game:GetService("RunService");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections", 3);

-- Check if the DialogueMakerRemoteConnections folder was moved
assert(RemoteConnections, "[Dialogue Maker] Couldn't find the DialogueMakerRemoteConnections folder in the ReplicatedStorage.");

-- Set some constants
local THEMES = script.Themes;
local DEFAULT_THEME = RemoteConnections.GetDefaultTheme:InvokeServer();
local DEFAULT_MIN_DISTANCE = RemoteConnections.GetMinimumDistanceFromCharacter:InvokeServer();
local KEYBINDS = RemoteConnections.GetKeybinds:InvokeServer();
local DEFAULT_CLICK_SOUND = RemoteConnections.GetDefaultClickSound:InvokeServer();

local PlayerTalkingWithNPC = false;
local Events = {};
local API = require(script.ClientAPI);

local function ReadDialogue(npc, dialogueSettings)
	
	if PlayerTalkingWithNPC then
		return;
	end;
	
	PlayerTalkingWithNPC = true;
	
	API.Triggers.DisableAllSpeechBubbles();
	API.Triggers.DisableAllClickDetectors();
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
	
	-- Setup click sound
	local ClickSound = DialogueGui:FindFirstChild("ClickSound");
	local ClickSoundEnabled = false;
	if DEFAULT_CLICK_SOUND and DEFAULT_CLICK_SOUND ~= 0 then
		
		if not ClickSound then
			ClickSound = Instance.new("Sound");
			ClickSound.Name = "ClickSound";
			ClickSound.Parent = DialogueGui;
		end;
		
		ClickSoundEnabled = true;
		DialogueGui.ClickSound.SoundId = "rbxassetid://"..DEFAULT_CLICK_SOUND;
	end;
	
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
		
		if CurrentDirectory.Redirect.Value and RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then
			
			local DialoguePriorityPath = CurrentDirectory.RedirectPriority.Value:split(".");
			table.remove(DialoguePriorityPath, 1);
			DialoguePriority = table.concat(DialoguePriorityPath, ".");
			CurrentDirectory = RootDirectory;
			
			RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "After");
			
		elseif RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then
			
			-- Run the before action if there is one
			if CurrentDirectory.HasBeforeAction.Value then
				RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "Before");
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
			
			DialogueGui.Parent = PlayerGui;
			
			local NPCTalking = true;
			local WaitingForResponse = true;
			local Skipped = false;
			local FullMessageText = "";
			
			-- Make the NPC stop talking if the player clicks the frame
			local NPCPaused = false;
			local ContinueDialogue;
			ContinueDialogue = function(keybind)
				
				-- Make sure key is down
				if keybind and not UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY) and not UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD) then
					return;
				end;
				
				ContextActionService:UnbindAction("ContinueDialogue");
				if NPCTalking then
					if ClickSoundEnabled then
						ClickSound:Play();
					end;
					
					if NPCPaused then
						NPCPaused = false;
					end;
					
					-- Check settings set by the developer
					if dialogueSettings.AllowPlayerToSkipDelay then
						
						-- Replace the incomplete dialogue with the full text
						TextContainer.Line.Text = FullMessageText;
						Skipped = true;
						
					end;
					
					ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY, KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD);
					
				elseif #CurrentDirectory.Responses:GetChildren() == 0 then					
					WaitingForResponse = false;
				end;
			end;
			
			Events.DialogueClicked = ThemeDialogueContainer.InputBegan:Connect(function(input)
				
				-- Make sure the player clicked the frame
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					
					ContinueDialogue();
					
				end;
				
			end);
			
			if KEYBINDS.KEYBINDS_ENABLED then
				local KEYS_PRESSED = UserInputService:GetKeysPressed();
				local KeybindPressed = false;
				if UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY) or UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD) then
					coroutine.wrap(function()
						while UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY) or UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD) do
							RunService.Heartbeat:Wait();
						end;
						ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY, KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD);
					end)();
				else
					ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY, KEYBINDS.DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD);
				end;
			end;
			
			-- Put the letters of the message together for an animation effect
			local DividedText = API.Dialogue.DivideTextToFitBox(MessageText, TextContainer);
			for index, page in ipairs(DividedText) do
				FullMessageText = page.FullText;
				Message = "";
				for wordIndex, word in ipairs(page) do
					if wordIndex ~= 1 then Message = Message.." " end;
					for _, letter in ipairs(word:split("")) do
						
						-- Check if the player wants to skip their dialogue
						if Skipped or not NPCTalking or not PlayerTalkingWithNPC then
							
							break;
							
						end;
						
						Message = Message..letter;
						TextContainer.Line.Text = Message;
						
						wait(dialogueSettings.LetterDelay);
						
					end;
				end;
				
				if DividedText[index+1] and NPCTalking then
					ThemeDialogueContainer.ClickToContinue.Visible = true;
					NPCPaused = true;
					
					while NPCPaused and NPCTalking do 
						game:GetService("RunService").Heartbeat:Wait() 
					end;
					ThemeDialogueContainer.ClickToContinue.Visible = false;
					NPCPaused = false;
					Skipped = false;
				end;
			end;
			NPCTalking = false;
			
			local ResponseChosen;
			if ResponsesEnabled and PlayerTalkingWithNPC then
				
				-- Add response buttons
				for _, response in ipairs(CurrentDirectory.Responses:GetChildren()) do
					if RemoteConnections.PlayerPassesCondition:InvokeServer(npc,response) then
						local ResponseButton = ResponseTemplate:Clone();
						ResponseButton.Name = "Response";
						ResponseButton.Text = response.Message.Value;
						ResponseButton.Parent = ResponseContainer;
						ResponseButton.MouseButton1Click:Connect(function()
							
							if ClickSoundEnabled then
								ClickSound:Play();
							end;
							
							ResponseContainer.Visible = false;
							
							ResponseChosen = response;
							
							if response.HasAfterAction.Value then
								RemoteConnections.ExecuteAction:InvokeServer(npc,response,"After");
							end;
							
							WaitingForResponse = false;
						end);
					end;
				end;
				
				ResponseContainer.CanvasSize = UDim2.new(0,ResponseContainer.CanvasSize.X,0,ResponseContainer.UIListLayout.AbsoluteContentSize.Y);
				ThemeDialogueContainer.ResponseContainer.Visible = true;
				
			end;
			
			-- Run the timeout code in the background
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
			
			-- Run after action
			if CurrentDirectory.HasAfterAction.Value and PlayerTalkingWithNPC then
				RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "After");
			end;
			
			if ResponseChosen and PlayerTalkingWithNPC then
				
				if (#ResponseChosen.Dialogue:GetChildren() ~= 0 or #ResponseChosen.Redirects:GetChildren() ~= 0) then
					DialoguePriority = string.sub(ResponseChosen.Priority.Value..".1",3);
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
	
	API.Triggers.EnableAllSpeechBubbles();
	API.Triggers.EnableAllClickDetectors();
	if dialogueSettings.FreezePlayer then API.Player.UnfreezePlayer(); end;
	
end;

local NPCDialogue = RemoteConnections.GetNPCDialogue:InvokeServer()
	
print("[Dialogue Maker] Preparing dialogue that was received from the server...");

-- Iterate through every NPC in order to 
for _, npc in ipairs(NPCDialogue) do
	
	-- Make sure all NPCs aren't affected if this one doesn't load properly
	local success, msg = pcall(function()
		
		local DialogueSettings = require(npc.DialogueContainer.Settings);
		
		if DialogueSettings.SpeechBubbleEnabled then
			
			if DialogueSettings.SpeechBubblePart then
				
				if DialogueSettings.SpeechBubblePart:IsA("BasePart") then
					
					local SpeechBubble = API.Triggers.CreateSpeechBubble(npc, DialogueSettings);
					
					-- Listen if the player clicks the speech bubble
					SpeechBubble.SpeechBubbleButton.MouseButton1Click:Connect(function()
						
						ReadDialogue(npc, DialogueSettings);
						
					end);
					
					SpeechBubble.Parent = PlayerGui;
					
				else
					warn("[Dialogue Maker] The SpeechBubblePart for "..npc.Name.." is not a Part.");
				end;
				
			end;
			
		end;
		
		if DialogueSettings.PromptRegionEnabled then
			
			if DialogueSettings.PromptRegionPart then
				
				if DialogueSettings.PromptRegionPart:IsA("BasePart") then
					
					local PlayerTouched;
					DialogueSettings.PromptRegionPart.Touched:Connect(function(part)
						
						-- Make sure our player touched it and not someone else
						local PlayerFromCharacter = Players:GetPlayerFromCharacter(part.Parent);
						if PlayerFromCharacter == Player then
							
							ReadDialogue(npc, DialogueSettings);
							
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
					
					API.Triggers.AddClickDetector(npc, DialogueSettings.ClickDetectorLocation);
					
					DialogueSettings.ClickDetectorLocation.MouseClick:Connect(function()
						ReadDialogue(npc, DialogueSettings);
					end);
					
				else
					warn("[Dialogue Maker] The ClickDetectorLocation for "..npc.Name.." is not a ClickDetector.");
				end;
				
			end;
			
		end;
		
		if KEYBINDS.KEYBINDS_ENABLED then
			local CanPressButton = false;
			local ReadDialogueWithKeybind;
			ReadDialogueWithKeybind = function()
				if CanPressButton then
					if not UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_TRIGGER_KEY) and not UserInputService:IsKeyDown(KEYBINDS.DEFAULT_CHAT_TRIGGER_KEY_GAMEPAD) then
						return;
					end;
					ReadDialogue(npc, DialogueSettings);
				end;
			end;
			ContextActionService:BindAction("OpenDialogueWithKeybind", ReadDialogueWithKeybind, false, KEYBINDS.DEFAULT_CHAT_TRIGGER_KEY, KEYBINDS.DEFAULT_CHAT_TRIGGER_KEY_GAMEPAD);
			
			-- Check if the player is in range
			RunService.Heartbeat:Connect(function()
				if Player:DistanceFromCharacter(npc.HumanoidRootPart.Position) <= DEFAULT_MIN_DISTANCE then
					CanPressButton = true;
				else
					CanPressButton = false;
				end;
			end);
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
