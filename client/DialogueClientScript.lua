-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local ControllerService = game:GetService("ControllerService");

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
local SpeechBubble = {};

local function ReadDialogue(npc, dialogueSettings)
	
	if PlayerTalkingWithNPC then
		return;
	end;
	
	PlayerTalkingWithNPC = true;
	
	if SpeechBubble[npc] then
		SpeechBubble[npc].Enabled = false;
	end;
	
	local OriginalCDLocation;
	if dialogueSettings.ClickDetectorEnabled and dialogueSettings.ClickDetectorLocation and dialogueSettings.ClickDetectorLocation:IsA("ClickDetector") and dialogueSettings.ClickDetectorDisappearsWhenDialogueActive then
		OriginalCDLocation = dialogueSettings.ClickDetectorLocation.Parent;
		dialogueSettings.ClickDetectorLocation.Parent = nil;
	end;
	
	local DialogueContainer = npc.DialogueContainer;
	local ThemeUsed = Themes[DefaultTheme];
	
	-- Check if the theme is different from the server theme
	if dialogueSettings.Theme ~= "" then
		if Themes[dialogueSettings.Theme] then
			ThemeUsed = Themes[dialogueSettings.Theme];
		else
			warn("[Dialogue Maker] \""..dialogueSettings.Theme.."\" wasn't a theme the client downloaded from the server, so we're going to use the default theme.");
		end;
	end;
	
	local PlayerControls = require(Player.PlayerScripts.PlayerModule):GetControls();
	if dialogueSettings.FreezePlayer then
		
		-- Freeze the player
		PlayerControls:Disable();
		
	end;
	
	-- Show the dialogue GUI to the player
	local DialogueGui = ThemeUsed:Clone();
	local ResponseContainer = DialogueGui.DialogueContainer.ResponseContainer;
	local ResponseTemplate = ResponseContainer.ResponseTemplate:Clone();
	ResponseContainer.ResponseTemplate:Destroy();
	local DialoguePriority = "1";
	local RootDirectory = DialogueContainer["1"];
	local CurrentDirectory = RootDirectory;
	
	-- Show the dialouge to the player
	while PlayerTalkingWithNPC and game:GetService("RunService").Heartbeat:Wait() do
		
		local TargetDirectoryPath = DialoguePriority:split(".");
		local Attempts = #DialogueContainer:GetChildren();
		
		-- Move to the target directory
		for index, directory in ipairs(TargetDirectoryPath) do
			if CurrentDirectory.Dialogue:FindFirstChild(directory) then
				CurrentDirectory = CurrentDirectory.Dialogue[directory];
			elseif CurrentDirectory.Responses:FindFirstChild(directory) then
				CurrentDirectory = CurrentDirectory.Responses[directory];
			elseif CurrentDirectory.Redirects:FindFirstChild(directory) then
				CurrentDirectory = CurrentDirectory.Redirects[directory];
			elseif CurrentDirectory:FindFirstChild(directory) then
				CurrentDirectory = CurrentDirectory[directory];
			end;
		end;
		
		if CurrentDirectory.Redirect.Value and RemoteConnections.PlayerPassesCondition:InvokeServer(npc,CurrentDirectory) then
			
			RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"Before");
			local DialoguePriorityPath = CurrentDirectory.RedirectPriority.Value:split(".");
			table.remove(DialoguePriorityPath,1);
			DialoguePriority = table.concat(DialoguePriorityPath,".");
			CurrentDirectory = RootDirectory;
			RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"After");
			
		elseif RemoteConnections.PlayerPassesCondition:InvokeServer(npc,CurrentDirectory) then
			
			-- Run the before action if there is one
			if CurrentDirectory.HasBeforeAction.Value then
				RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"Before");
			end;
			
			-- Check if the message has any variables
			local MessageText = CurrentDirectory.Message.Value;
			for match in string.gmatch(MessageText,"%[/variable=(.+)%]") do
				
				-- Get the match from the server
				local VariableValue = RemoteConnections.GetVariable:InvokeServer(npc,match);
				if VariableValue then
					MessageText = MessageText:gsub("%[/variable=(.+)%]",VariableValue);
				end;
				
			end;
			
			-- Show the message to the player
			local ThemeDialogueContainer = DialogueGui.DialogueContainer;
			
			-- Check if there are any response options
			local TextContainer;
			local ResponsesEnabled = false;
			if #CurrentDirectory.Responses:GetChildren() > 0 then
				
				-- Clear previous responses
				for _, response in ipairs(ResponseContainer:GetChildren()) do
					if not response:IsA("UIListLayout") then
						response:Destroy();
					end;
				end;
				
				TextContainer = ThemeDialogueContainer.NPCTextContainerWithResponses;
				ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = true;
				ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = false;
				ThemeDialogueContainer.ResponseContainer.Visible = true;
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
			
			-- Make the NPC stop talking if the player clicks the frame
			Events.DialogueClicked = ThemeDialogueContainer.InputBegan:Connect(function(input)
				
				-- Make sure the player clicked the frame
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if NPCTalking then
						
						-- Check settings set by the developer
						if dialogueSettings.AllowPlayerToSkipDelay then
							
							-- Replace the incomplete dialogue with the full text
							TextContainer.Line.Text = MessageText;
							NPCTalking = false;
							
						end;
						
					elseif #CurrentDirectory.Responses:GetChildren() == 0 then
						WaitingForResponse = false;
					end;
					
				end;
				
			end);
			
			-- Put the letters of the message together for an animation effect
			for _, letter in ipairs(MessageText:split("")) do
				
				-- Check if the player wants to skip their dialogue
				if not NPCTalking or not PlayerTalkingWithNPC then
					
					break;
					
				end;
				
				Message = Message..letter;
				TextContainer.Line.Text = Message;
				
				wait(dialogueSettings.LetterDelay);
				
			end;
			NPCTalking = false;
			
			local Response;
			if ResponsesEnabled and PlayerTalkingWithNPC then
				
				-- Add response buttons
				for _, response in ipairs(CurrentDirectory.Responses:GetChildren()) do
					
					if RemoteConnections.PlayerPassesCondition:InvokeServer(npc,response) then
					
						local ResponseButton = ResponseTemplate:Clone();
						ResponseButton.Name = "Response";
						ResponseButton.Text = response.Message.Value;
						ResponseButton.Parent = ResponseContainer;
						ResponseButton.MouseButton1Click:Connect(function()
							ResponseContainer.Visible = false;
							
							Response = response;
							
							if response.HasAfterAction.Value then
								RemoteConnections.ExecuteAction:InvokeServer(npc,response,"After");
							end;
							
							WaitingForResponse = false;
						end);
						
					else
						print(false)
					end;
					
				end;
				
				ResponseContainer.CanvasSize = UDim2.new(ResponseContainer.CanvasSize.X,ResponseContainer.UIListLayout.AbsoluteContentSize.Y);
				
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
				RemoteConnections.ExecuteAction:InvokeServer(npc,CurrentDirectory,"After");
			end;
			
			if Response and PlayerTalkingWithNPC then
				
				if #Response.Dialogue:GetChildren() ~= 0 then
					
					DialoguePriority = string.sub(Response.Priority.Value..".1",3);
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
	
	if SpeechBubble[npc] then
		SpeechBubble[npc].Enabled = true;
	end;
	
	if OriginalCDLocation then
		dialogueSettings.ClickDetectorLocation.Parent = OriginalCDLocation;
	end;
	
	-- Unfreeze the player
	if dialogueSettings.FreezePlayer then
		PlayerControls:Enable();
	end;
	
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
					
					-- Create a speech bubble
					SpeechBubble[npc] = Instance.new("BillboardGui");
					SpeechBubble[npc].Name = "SpeechBubble";
					SpeechBubble[npc].Active = true;
					SpeechBubble[npc].LightInfluence = 0;
					SpeechBubble[npc].ResetOnSpawn = false;
					SpeechBubble[npc].Size = DialogueSettings.SpeechBubbleSize;
					SpeechBubble[npc].StudsOffset = DialogueSettings.StudsOffset;
					SpeechBubble[npc].Adornee = DialogueSettings.SpeechBubblePart;
					
					local SpeechBubbleButton = Instance.new("ImageButton");
					SpeechBubbleButton.BackgroundTransparency = 1;
					SpeechBubbleButton.BorderSizePixel = 0;
					SpeechBubbleButton.Name = "SpeechBubbleButton";
					SpeechBubbleButton.Size = UDim2.new(1,0,1,0);
					SpeechBubbleButton.Image = DialogueSettings.SpeechBubbleImage;
					SpeechBubbleButton.Parent = SpeechBubble[npc];
					
					-- Listen if the player clicks the speech bubble
					SpeechBubbleButton.MouseButton1Click:Connect(function()
						
						ReadDialogue(npc, DialogueSettings);
						
					end);
					
					SpeechBubble[npc].Parent = PlayerGui;
					
				else
					warn("[Dialogue Viewer] The SpeechBubblePart for "..npc.Name.." is not a Part.");
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
