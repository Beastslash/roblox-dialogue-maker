local RunService = game:GetService("RunService");
local RemoteConnections = game:GetService("ReplicatedStorage"):WaitForChild("DialogueMakerRemoteConnections");

local NPC;
local DialogueSettings;
local ResponseTemplate;

local Events = {};

local Dialogue = {};

function Dialogue.GoToDirectory(currentDirectory, targetPath)
	
	for index, directory in ipairs(targetPath) do
		if currentDirectory.Dialogue:FindFirstChild(directory) then
			currentDirectory = currentDirectory.Dialogue[directory];
		elseif currentDirectory.Responses:FindFirstChild(directory) then
			currentDirectory = currentDirectory.Responses[directory];
		elseif currentDirectory.Redirects:FindFirstChild(directory) then
			currentDirectory = currentDirectory.Redirects[directory];
		elseif currentDirectory:FindFirstChild(directory) then
			currentDirectory = currentDirectory[directory];
		end;
	end;
	
	return currentDirectory;
end;

function Dialogue.ReplaceVariablesWithValues(npc, text)
	
	for match in string.gmatch(text, "%[%/variable=([^%]]+)%]") do
				
		-- Get the match from the server
		local VariableValue = RemoteConnections.GetVariable:InvokeServer(npc, match);
		if VariableValue then
			text = text:gsub("%[%/variable=([^%]]+)%]",VariableValue);
		end;
		
	end;
	
	return text;
	
end;

function Dialogue.PlaySound(gui, messageType)
	
	if gui:FindFirstChild("DialogueClickSound") and gui.DialogueClickSound:IsA("Sound") then
		
		if messageType == "Message" then
			gui.MessageClickSound:Play();
		elseif messageType == "Response" then
			gui.ResponseClickSound:Play();
		end;
		
	end;
	
end;

function Dialogue.ClearResponses(responseContainer)
	for _, response in ipairs(responseContainer:GetChildren()) do
		if not response:IsA("UIListLayout") then
			response:Destroy();
		end;
	end;
end;

function Dialogue.SetNPC(npc)
	NPC = npc;
end;

function Dialogue.SetDialogueSettings(dialogueSettings)
	DialogueSettings = dialogueSettings;
end;

function Dialogue.SetResponseTemplate(responseTemplate)
	ResponseTemplate = responseTemplate;
end;

function Dialogue.RunAnimation(textContainer, textContent, currentDirectory, responsesEnabled, dialoguePriority)
	
	local NPCTalking = false;
	local NPCPaused = false;
	local Skipped = false;
	local Text;
	local PlayerResponse;
	local FinishingOverflow = false;
	local WaitingForOverflow = false;
	
	local function SetTextContainerEvent(container)
		Events.DialogueClicked = container.Parent.InputBegan:Connect(function(input)
			
			-- Make sure the player clicked the frame
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				
				if NPCTalking then
					
					if NPCPaused and not FinishingOverflow then
						
						FinishingOverflow = true;
						
						if textContainer.Parent:FindFirstChild("ClickToContinue") then
							if DialogueSettings.AllowPlayerToSkipDelay then
								textContainer.Parent.ClickToContinue.Visible = true;
							else
								textContainer.Parent.ClickToContinue.Visible = false;
							end;
						end;
							
						Dialogue.PlaySound(textContainer.Parent.Parent, "Message");
							
						NPCPaused = false;
						Text = API.RichText:ContinueOverflow(textContainer, Text);
						Text:Animate(true);
						
						if Text.Overflown then
							NPCPaused = true;
						else
							WaitingForOverflow = false;
						end;
						
						if textContainer.Parent:FindFirstChild("ClickToContinue") then
							textContainer.Parent.ClickToContinue.Visible = true;
						end;
						
						FinishingOverflow = false;
							
						return;
						
					end;
					
					-- Check settings set by the developer
					if DialogueSettings.AllowPlayerToSkipDelay then
						
						-- Replace the incomplete dialogue with the full text
						Dialogue.PlaySound(textContainer.Parent.Parent, "Message");
						Text:Show(false);
						NPCPaused = true;
						
					end;
					
				elseif #currentDirectory.Responses:GetChildren() == 0 then
					WaitingForPlayerResponse = false;
					Events.DialogueClicked:Disconnect();
				end;
				
			end;
			
		end);
	end;
	
	Text = API.RichText:New(
		textContainer, 
		textContent, {
			ContainerVerticalAlignment = Enum.VerticalAlignment.Top;
			AnimateStepTime = DialogueSettings.LetterDelay;
		},
		false);
		
	WaitingForPlayerResponse = true;
	NPCTalking = true;
			
	textContainer.Visible = true;
	
	SetTextContainerEvent(textContainer);
		
	Text:Animate(true);
		
	if Text.Overflown then
		NPCPaused = true;
		WaitingForOverflow = true;
	end;
	
	while WaitingForOverflow do
		RunService.Heartbeat:Wait();
	end;
	
	NPCTalking = false;
	
	if responsesEnabled and #currentDirectory.Responses:GetChildren() ~= 0 then
		
		local ResponseContainer = textContainer.Parent.ResponseContainer;
		
		-- Add response buttons
		for _, response in ipairs(currentDirectory.Responses:GetChildren()) do
			if RemoteConnections.PlayerPassesCondition:InvokeServer(NPC, response, response.Priority.Value) then
				local ResponseButton = ResponseTemplate:Clone();
				ResponseButton.Name = "Response";
				ResponseButton.Text = response.Message.Value;
				ResponseButton.Parent = ResponseContainer;
				ResponseButton.MouseButton1Click:Connect(function()
					
					Dialogue.PlaySound(textContainer.Parent.Parent, "Response")
					
					ResponseContainer.Visible = false;
					
					PlayerResponse = response;
					
					if response.HasAfterAction.Value then
						RemoteConnections.ExecuteAction:InvokeServer(NPC, response, "After");
					end;
					
					WaitingForPlayerResponse = false;
					
				end);
			end;
		end;
		
		ResponseContainer.CanvasSize = UDim2.new(0,ResponseContainer.CanvasSize.X,0,ResponseContainer.UIListLayout.AbsoluteContentSize.Y);
		ResponseContainer.Visible = true;
		
	elseif textContainer.Parent:FindFirstChild("ClickToContinue") then
		textContainer.Parent.ClickToContinue.Visible = true;
	end;
	
	while WaitingForPlayerResponse do
		RunService.Heartbeat:Wait();
	end;
	
	if PlayerResponse then
		return {Response = PlayerResponse};
	end;
	
	return {};
	
end;

function Dialogue.PlayerResponded(response)
	WaitingForPlayerResponse = false;
end;

return Dialogue;
