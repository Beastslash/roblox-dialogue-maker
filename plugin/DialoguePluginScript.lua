-- Roblox services
local Selection = game:GetService("Selection");
local StarterPlayer = game:GetService("StarterPlayer");
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");
local UserInputService = game:GetService("UserInputService");

-- Toolbar configuration
local Toolbar = plugin:CreateToolbar("Dialogue Maker by Beastslash");
local EditDialogueButton = Toolbar:CreateButton("Edit Dialogue", "Edit dialogue of a selected NPC. The selected object must be a singular model.","rbxassetid://332218617");
local PluginGui;
local DialogueMakerFrame = script.DialogueMakerGUI.MainFrame:Clone();
local DialogueMessageList = DialogueMakerFrame.DialogueContainer.DialogueMessageList;
local DialogueMessageTemplate = DialogueMessageList.DialogueMessageTemplate:Clone();
local Tools = DialogueMakerFrame.Tools;
local Events = {EditingMessage = {}; EditingRedirect = {}; ConvertFromRedirect = {}; ConvertToRedirect = {}};

DialogueMakerFrame.DialogueContainer.DialogueMessageList.DialogueMessageTemplate:Destroy();

local DialogueMakerOpen = false;
local CurrentDialogueContainer;
local ViewingPriority = "1";
local ViewingA = "Dialogue";

local Model;

-- Close the editor when called
local function CloseDialogueEditor()
	
	-- Disconnect all events
	for key, event in pairs(Events) do
		if event.Connected then
			event:Disconnect();
		end;
		Events[key] = nil;
	end;
	
	Events = {EditingMessage = {}; EditingRedirect = {}; ConvertFromRedirect = {}; ConvertToRedirect = {}};
	
	ViewingPriority = "1";
	DialogueMakerFrame = DialogueMakerFrame:Clone();
	DialogueMessageList = DialogueMakerFrame.DialogueContainer.DialogueMessageList;
	DialogueMessageTemplate = DialogueMessageTemplate:Clone();
	Tools = DialogueMakerFrame.Tools;
	
	PluginGui:Destroy();
	EditDialogueButton:SetActive(false);
	DialogueEditorOpen = false;
	
end;

local DeleteModeEnabled = false;
local DeletePromptShown = false;

local function RepairNPC()
	
	if not Model:FindFirstChild("DialogueContainer") then
		
		if new then
			print("[Dialogue Maker] Created a DialogueContainer inside of "..Model.Name)
		else
			warn("[Dialogue Maker] "..Model.Name.."'s DialogueContainer was moved or deleted! Creating a new one...");
		end
		
		-- Add the dialogue container to the NPC
		CurrentDialogueContainer = Instance.new("Folder");
		CurrentDialogueContainer.Name = "DialogueContainer";
		
		local SettingsScript = script.NPCSettingsTemplate:Clone();
		SettingsScript.Name = "Settings";
		SettingsScript.Parent = CurrentDialogueContainer;
		
		-- Create a root folder
		local TempRootFolder = Instance.new("Folder");
		TempRootFolder.Name = "1";
		TempRootFolder.Parent = CurrentDialogueContainer;
				
		-- Create a folder to hold dialogue
		local Dialogue = Instance.new("Folder");
		Dialogue.Name = "Dialogue";
		Dialogue.Parent = TempRootFolder;
		
		-- Create a folder to hold responses
		local Responses = Instance.new("Folder");
		Responses.Name = "Responses";
		Responses.Parent = TempRootFolder;
		
		-- Create a folder to hold redirects
		local Redirects = Instance.new("Folder");
		Redirects.Name = "Redirects";
		Redirects.Parent = TempRootFolder;
		
		-- Add the dialogue folder to the model
		CurrentDialogueContainer.Parent = Model;
		
		ViewingPriority = "1";
		
		-- There's nothing else we can do to repair the scripts; we can't find em!
		return;
		
	end;
	
	CurrentDialogueContainer = Model:FindFirstChild("DialogueContainer");
	
	if not CurrentDialogueContainer:FindFirstChild("Settings") then
		
		print("[Dialogue Maker] Adding settings script to "..Model.Name)
		
		local SettingsScript = script.NPCSettingsTemplate:Clone();
		SettingsScript.Name = "Settings";
		SettingsScript.Parent = CurrentDialogueContainer;
		
		print("[Dialogue Maker] Added settings script to "..Model.Name)
		
	end;
	
end;

local function SyncDialogueGui(directoryDialogue)
	
	-- Make sure everything with the NPC is OK
	RepairNPC();
	
	if ViewingPriority == "1" then
		DialogueMakerFrame.ViewStatus.DialogueLocationStatus.Text = "Viewing the beginning of the conversation";
	else
		DialogueMakerFrame.ViewStatus.DialogueLocationStatus.Text = "Viewing "..ViewingPriority;
		
		Events.ViewParent = Tools.ViewParent.MouseButton1Click:Connect(function()
			Events.ViewParent:Disconnect();
			Events.DeleteMode:Disconnect();
			
			Tools.ViewParent.BackgroundColor3 = Color3.fromRGB(159,159,159);
			
			local NewViewingPriority = ViewingPriority:split(".");
			NewViewingPriority[#NewViewingPriority] = nil;
			ViewingPriority = table.concat(NewViewingPriority,".");
			
			SyncDialogueGui(directoryDialogue.Parent.Parent.Parent.Dialogue);
		end);
			
		Tools.ViewParent.BackgroundColor3 = Color3.fromRGB(255,255,255);
		
	end;
	
	Events.DeleteMode = Tools.DeleteMode.MouseButton1Click:Connect(function()
		
		if DeleteModeEnabled then
			
			-- Disable delete mode
			DeleteModeEnabled = false;
			
			-- Turn the button white again
			Tools.DeleteMode.BackgroundColor3 = Color3.fromRGB(255,255,255);
			
			-- Tell the user that we're no longer in delete mode
			print("[Dialogue Maker] Whew. Delete Mode has been disabled.");
			
		else
			
			-- Enable delete mode
			DeleteModeEnabled = true;
			
			-- Turn the button red
			Tools.DeleteMode.BackgroundColor3 = Color3.fromRGB(255,46,46);
			
			-- Tell the user that we're in delete mode
			print("[Dialogue Maker] Warning: Delete Mode has been enabled!");
			
		end;
		
	end);
	
	print("[Dialogue Maker] Viewing "..ViewingPriority);
	
	if directoryDialogue.Parent:FindFirstChild("Response") and directoryDialogue.Parent.Response.Value then
		ViewingA = "Response";
	else
		ViewingA = "Dialogue";
	end;
	
	-- Clean up the old dialogue
	for _, status in ipairs(DialogueMessageList:GetChildren()) do
		
		if not status:IsA("UIListLayout") then
			status:Destroy();
		end;
		
	end;
	
	-- Sort the directory based on priority
	local function SortByMessagePriority(messageA, messageB)
		local MessageAPrioritySplit = messageA.Priority.Value:split(".");
		local MessageAPriority = tonumber(MessageAPrioritySplit[#MessageAPrioritySplit]);
		local MessageBPrioritySplit = messageB.Priority.Value:split(".");
		local MessageBPriority = tonumber(MessageBPrioritySplit[#MessageAPrioritySplit]);
		
		return MessageAPriority < MessageBPriority;
	end
	
	local ResponseChildren = directoryDialogue.Parent.Responses:GetChildren();
	table.sort(ResponseChildren, SortByMessagePriority);
	
	local MessageChildren = directoryDialogue.Parent.Dialogue:GetChildren();
	table.sort(MessageChildren, SortByMessagePriority);
	
	local RedirectChildren = directoryDialogue.Parent.Redirects:GetChildren();
	table.sort(RedirectChildren, SortByMessagePriority);
	
	-- Check if there is a redirect
	if RedirectChildren[1] then
		DialogueMessageList.Parent.DescriptionLabels.Text.Text = "Text / Redirect";
	else
		DialogueMessageList.Parent.DescriptionLabels.Text.Text = "Text";
	end;
	
	-- Keep track if a message GUI is open
	local EditingMessage = false;
	
	local CombinedDirectories = {ResponseChildren = ResponseChildren; MessageChildren = MessageChildren; RedirectChildren = RedirectChildren}
	
	-- Create new status
	for _, category in pairs(CombinedDirectories) do
		
		for _, dialogue in ipairs(category) do
			
			local DialogueStatus = DialogueMessageTemplate:Clone();
			local SplitPriority = dialogue.Priority.Value:split(".")
			DialogueStatus.PriorityButton.Text = SplitPriority[#SplitPriority];
			DialogueStatus.Priority.PlaceholderText = dialogue.Priority.Value;
			DialogueStatus.Priority.Text = dialogue.Priority.Value;
			DialogueStatus.Message.Text = dialogue.Message.Value;
			DialogueStatus.RedirectPriority.Text = dialogue.RedirectPriority.Value;
			DialogueStatus.Visible = true;
			DialogueStatus.Parent = DialogueMessageList;
			
			if dialogue.Response.Value then
				
				DialogueStatus.BackgroundTransparency = 0.4;
				DialogueStatus.BackgroundColor3 = Color3.fromRGB(30,103,19);
				
			elseif dialogue.Redirect.Value then
				
				DialogueStatus.BackgroundTransparency = 0.4;
				DialogueStatus.BackgroundColor3 = Color3.fromRGB(21,44,126);
				DialogueStatus.RedirectPriority.Visible = true;
				DialogueStatus.RedirectPriority.TextBox.PlaceholderText = "Type the exact priority you want to redirect to."
				DialogueStatus.Message.Visible = false;
				
			else
				
				DialogueStatus.BackgroundTransparency = 1;
				
			end;
			
			local function ShowDeleteModePrompt()
				
				-- Debounce
				if DeletePromptShown then
					return;
				end;
				
				DeletePromptShown = true;
				
				-- Show the deletion options to the user
				DialogueStatus.DeleteFrame.Visible = true;
				
				-- Add the deletion functionality
				Events.DeleteYesButton = DialogueStatus.DeleteFrame.YesButton.MouseButton1Click:Connect(function()
					
					-- Debounce
					Events.DeleteYesButton:Disconnect();
					Events.DeleteNoButton:Disconnect();
					Events.DeleteMode:Disconnect();
					
					-- Delete the dialogue
					dialogue:Destroy();
					
					-- Hide the deletion options from the user
					DialogueStatus.DeleteFrame.Visible = false;
					
					-- Allow the user to continue using the plugin
					DeletePromptShown = false;
					
					-- Refresh the view
					SyncDialogueGui(directoryDialogue);
					
				end);
				
				-- Give the user the option to back out
				Events.DeleteNoButton = DialogueStatus.DeleteFrame.NoButton.MouseButton1Click:Connect(function()
					
					-- Debounce
					Events.DeleteNoButton:Disconnect();
					Events.DeleteYesButton:Disconnect();
					
					-- Hide the deletion options from the user
					DialogueStatus.DeleteFrame.Visible = false;
					
					-- Allow the user to continue using the plugin
					DeletePromptShown = false;
					
				end);
				
			end
			
			DialogueStatus.PriorityButton.MouseButton1Click:Connect(function()
				
				if DeleteModeEnabled then
					
					ShowDeleteModePrompt()
					
				else
				
					DialogueStatus.PriorityButton.Visible = false;
					DialogueStatus.Priority.Visible = true;
					DialogueStatus.Priority:CaptureFocus();
					local FocusEvent;
					FocusEvent = DialogueStatus.Priority.FocusLost:Connect(function(input)
						
						DialogueStatus.Priority.Visible = false;
						
						if DialogueStatus.Priority.Text ~= dialogue.Response.Value then
							
							SplitPriority = DialogueStatus.Priority.Text:split(".");
							local SplitPriorityWithPeriods = DialogueStatus.Priority.Text:split("");
							
							-- Make sure the priority is valid
							local InvalidPriority = false;
							if SplitPriorityWithPeriods[1] == "." or SplitPriorityWithPeriods[#SplitPriorityWithPeriods] == "." then
								InvalidPriority = true;
							end;
							local CurrentDirectory = CurrentDialogueContainer;
							if not InvalidPriority then
								for index, priority in ipairs(SplitPriority) do
									
									-- Make sure everyone's a number
									if not tonumber(priority) then
										warn("[Dialogue Maker] "..DialogueStatus.Priority.Text.." is not a valid priority. Make sure you're not using any characters other than numbers and periods.");
										InvalidPriority = true;
										break;
									end;
									
									-- Make sure the folder exists
									local TargetDirectory = CurrentDirectory:FindFirstChild(priority);
									if not TargetDirectory and index ~= #SplitPriority then
										
										warn("[Dialogue Maker] "..DialogueStatus.Priority.Text.." is not a valid priority. Make sure all parent directories exist.");
										InvalidPriority = true;
										break;
										
									elseif index == #SplitPriority then
										
										if CurrentDirectory.Parent.Dialogue:FindFirstChild(priority) or CurrentDirectory.Parent.Responses:FindFirstChild(priority) then
											
											warn("[Dialogue Maker] "..DialogueStatus.Priority.Text.." is not a valid priority. Make sure that "..DialogueStatus.Priority.Text.." isn't already being used.");
											InvalidPriority = true;
										
										else
											
											if dialogue.Response.Value then
												CurrentDirectory = CurrentDirectory.Parent.Responses;
											else
												CurrentDirectory = CurrentDirectory.Parent.Dialogue;
											end;
											
											local UserSplitPriority = DialogueStatus.Priority.Text:split(".");
											dialogue.Priority.Value = DialogueStatus.Priority.Text;
											dialogue.Name = UserSplitPriority[#UserSplitPriority];
											dialogue.Parent = CurrentDirectory;
											
										end;
										break;
										
									end;
									
									if TargetDirectory.Dialogue:FindFirstChild(priority) then
										CurrentDirectory = TargetDirectory.Dialogue;
									elseif TargetDirectory.Responses:FindFirstChild(priority) then
										CurrentDirectory = TargetDirectory.Responses;
									elseif CurrentDirectory:FindFirstChild(priority) then
										CurrentDirectory = CurrentDirectory[priority].Dialogue;
									end;
									
								end;
							end;
							
							-- Refresh the GUI
							SyncDialogueGui(directoryDialogue);
							
						else
							
							DialogueStatus.PriorityButton.Visible = true;
							
						end;
						
					
					end);
				
				end;
				
			end);
			
			DialogueStatus.PriorityButton.MouseButton2Click:Connect(function() 
				
				if dialogue.Parent.Parent.Parent.Name == "Dialogue" and ViewingPriority ~= "1" then
							
					-- Check if the dialogue is a message
					if dialogue.Response.Value then
						dialogue.Response.Value = false;
						dialogue.Parent = directoryDialogue.Parent.Dialogue;
					else
						dialogue.Response.Value = true;
						dialogue.Parent = directoryDialogue.Parent.Responses;
					end;
					
				end;
				
				SyncDialogueGui(directoryDialogue);
				
			end);
			
			if dialogue.Redirect.Value then
				
				Events.ConvertFromRedirect[dialogue] = DialogueStatus.RedirectPriority.MouseButton2Click:Connect(function()
				
					Events.ConvertFromRedirect[dialogue]:Disconnect();
					Events.DeleteMode:Disconnect();
					if Events.ViewParent then
						Events.ViewParent:Disconnect();
						Events.ViewParent = nil;
					end;
				
					dialogue.Redirect.Value = false;
					if dialogue.Response.Value then
						dialogue.Parent = directoryDialogue.Parent.Responses;
					else
						dialogue.Parent = directoryDialogue.Parent.Dialogue;
					end;
					
					SyncDialogueGui(directoryDialogue);
					
				end);
					
				Events.EditingRedirect[dialogue] = DialogueStatus.RedirectPriority.MouseButton1Click:Connect(function()
					
					if EditingMessage then
						return;
					end;
					
					EditingMessage = true;
					
					DialogueStatus.RedirectPriority.TextBox.Text = dialogue.Message.Value;
					DialogueStatus.RedirectPriority.TextBox.Visible = true;
					DialogueStatus.RedirectPriority.TextBox:CaptureFocus();
					DialogueStatus.RedirectPriority.TextBox.FocusLost:Connect(function(enterPressed)
						if enterPressed then
							Events.EditingRedirect[dialogue]:Disconnect();
							Events.DeleteMode:Disconnect();
							if Events.ViewParent then
								Events.ViewParent:Disconnect();
								Events.ViewParent = nil;
							end;
							
							dialogue.RedirectPriority.Value = DialogueStatus.RedirectPriority.TextBox.Text;
							DialogueStatus.RedirectPriority.TextBox.Visible = false;
							SyncDialogueGui(directoryDialogue);
						end;
						EditingMessage = false;
					end);
					
				end);
				
			else
				
				Events.ConvertToRedirect[dialogue] = DialogueStatus.Message.MouseButton2Click:Connect(function()
					
					Events.ConvertToRedirect[dialogue]:Disconnect();
					Events.DeleteMode:Disconnect();
					if Events.ViewParent then
						Events.ViewParent:Disconnect();
						Events.ViewParent = nil;
					end;
					
					dialogue.Redirect.Value = true;
					dialogue.Parent = directoryDialogue.Parent.Redirects;
					SyncDialogueGui(directoryDialogue);
					
				end);
				
				Events.EditingMessage[dialogue] = DialogueStatus.Message.MouseButton1Click:Connect(function()
				
					if EditingMessage then
						return;
					end;
					
					EditingMessage = true;
					
					DialogueStatus.Message.TextBox.Text = dialogue.Message.Value;
					DialogueStatus.Message.TextBox.Visible = true;
					DialogueStatus.Message.TextBox:CaptureFocus();
					DialogueStatus.Message.TextBox.FocusLost:Connect(function(enterPressed)
						if enterPressed then
							Events.EditingMessage[dialogue]:Disconnect();
							Events.DeleteMode:Disconnect();
							if Events.ViewParent then
								Events.ViewParent:Disconnect();
								Events.ViewParent = nil;
							end;
							dialogue.Message.Value = DialogueStatus.Message.TextBox.Text;
							DialogueStatus.Message.TextBox.Visible = false;
							SyncDialogueGui(directoryDialogue);
						end;
						EditingMessage = false;
					end);
					
				end);
				
			end
			
			DialogueStatus.ConditionButton.MouseButton1Click:Connect(function()
				
				-- Look through the condition list and find the condition we want
				local Condition;
				for _, child in ipairs(ServerScriptService.DialogueServerScript.Conditions:GetChildren()) do
					
					-- Check if the child is a condition
					if child:IsA("ModuleScript") and child.Priority.Value == dialogue and child.NPC.Value == Model then
						
						-- Return the condiiton
						Condition = child;
						break;
						
					end;
					
				end;
				
				if not Condition then
					
					-- Create a new condition
					Condition = script.ConditionTemplate:Clone();
					Condition.Priority.Value = dialogue;
					Condition.NPC.Value = Model;
					Condition.Name = "Condition";
					Condition.Parent = ServerScriptService.DialogueServerScript.Conditions;
					
				end;
				
				-- Open the condition script
				plugin:OpenScript(Condition);
				
			end);
				
			local function OpenAction(beforeOrAfter)
				-- Look through the action list and find the condition we want
				local Action;
				for _, child in ipairs(ServerScriptService.DialogueServerScript.Actions[beforeOrAfter]:GetChildren()) do
					
					-- Check if the child is a condition
					if child:IsA("ModuleScript") and child.Priority.Value == dialogue and child.NPC.Value == Model then
						
						-- Return the condiiton
						Action = child;
						break;
						
					end;
					
				end;
				
				if not Action then
					
					-- Create a new condition
					Action = script.ActionTemplate:Clone();
					Action.Priority.Value = dialogue;
					Action.NPC.Value = Model;
					Action.Name = beforeOrAfter.."Action";
					
					Action.Parent = ServerScriptService.DialogueServerScript.Actions[beforeOrAfter];
					
					dialogue["Has"..beforeOrAfter.."Action"].Value = true;
					
				end;
				
				-- Open the condition script
				plugin:OpenScript(Action);
				
			end;
			
			DialogueStatus.BeforeActionButton.MouseButton1Click:Connect(function()
				
				OpenAction("Before");
				
			end);
				
			DialogueStatus.AfterActionButton.MouseButton1Click:Connect(function()
				
				OpenAction("After");
				
			end);
			
			if dialogue.Redirect.Value then
				DialogueStatus.ViewChildren.Visible = false;
			else
				DialogueStatus.ViewChildren.MouseButton1Click:Connect(function()
					
					ViewingPriority = dialogue.Priority.Value;
					
					if Events.ViewParent then
						Events.ViewParent:Disconnect();
						Events.ViewParent = nil;
					end;
					
					Events.DeleteMode:Disconnect();
					
					-- Go to the target directory
					local Path = ViewingPriority:split(".");
					local CurrentDirectory = CurrentDialogueContainer;
					
					for index, directory in ipairs(Path) do
						if CurrentDirectory:FindFirstChild(directory) then
							CurrentDirectory = CurrentDirectory[directory].Dialogue;
						else
							CurrentDirectory = CurrentDirectory.Parent.Responses[directory].Dialogue;
						end;
					end;
					
					SyncDialogueGui(CurrentDirectory);
					
				end);
			end;
			
			
		end;
	
	end;
	
	DialogueMessageList.CanvasSize = UDim2.new(0,0,0,DialogueMessageList.UIListLayout.AbsoluteContentSize.Y);
	
end;

local function AddDialogueToMessageList(directory,text)
	
	-- Let's create the dialogue first.
	-- Get message priority
	local Priority = ViewingPriority.."."..(#directory.Parent.Dialogue:GetChildren()+#directory.Parent.Responses:GetChildren()+#directory.Parent.Redirects:GetChildren())+1;
	
	-- Create the dialogue folder
	local DialogueObj = Instance.new("Folder");
	DialogueObj.Name = (#directory.Parent.Dialogue:GetChildren()+#directory.Parent.Responses:GetChildren()+#directory.Parent.Redirects:GetChildren())+1;
	
	local DialoguePriority = Instance.new("StringValue");
	DialoguePriority.Name = "Priority";
	DialoguePriority.Value = Priority;
	DialoguePriority.Parent = DialogueObj;
	
	local DialogueMessage = Instance.new("StringValue");
	DialogueMessage.Name = "Message";
	DialogueMessage.Value = text;
	DialogueMessage.Parent = DialogueObj;
	
	local DialogueActive = Instance.new("BoolValue");
	DialogueActive.Name = "Active";
	DialogueActive.Value = true;
	DialogueActive.Parent = DialogueObj;
	
	local Response = Instance.new("BoolValue");
	Response.Name = "Response";
	Response.Parent = DialogueObj;
	
	local Redirect = Instance.new("BoolValue");
	Redirect.Name = "Redirect";
	Redirect.Parent = DialogueObj;
	
	local RedirectPriority = Instance.new("StringValue");
	RedirectPriority.Name = "RedirectPriority";
	RedirectPriority.Value = text;
	RedirectPriority.Parent = DialogueObj;
	
	local DialogueBeforeAction = Instance.new("BoolValue");
	DialogueBeforeAction.Name = "HasBeforeAction";
	DialogueBeforeAction.Parent = DialogueObj;
	
	local DialogueAfterAction = Instance.new("BoolValue");
	DialogueAfterAction.Name = "HasAfterAction";
	DialogueAfterAction.Parent = DialogueObj;
	
	local DialogueChildDialogue = Instance.new("Folder");
	DialogueChildDialogue.Name = "Dialogue"
	DialogueChildDialogue.Parent = DialogueObj;
	
	local DialogueChildResponses = Instance.new("Folder");
	DialogueChildResponses.Name = "Responses";
	DialogueChildResponses.Parent = DialogueObj;
	
	-- Create a folder to hold responses
	local Redirects = Instance.new("Folder");
	Redirects.Name = "Redirects";
	Redirects.Parent = DialogueObj;
	
	DialogueObj.Parent = directory.Parent.Dialogue;
	
	if Events.ViewParent then
		Events.ViewParent:Disconnect();
		Events.ViewParent = nil;
	end;
	
	Events.DeleteMode:Disconnect();
	
	-- Now let's re-order the dialogue
	SyncDialogueGui(directory.Parent.Dialogue);
	
end;

-- Open the editor when called
local function OpenDialogueEditor()
	
	PluginGui = plugin:CreateDockWidgetPluginGui("Dialogue Maker", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,true,true,508,241,508,241));
	PluginGui.Title = "Dialogue Maker";
	PluginGui:BindToClose(CloseDialogueEditor);
	
	Events.AdjustSettingsRequested = Tools.AdjustSettings.MouseButton1Click:Connect(function()
		
		-- Make sure all of the important objects are in the NPC
		RepairNPC();
		
		plugin:OpenScript(CurrentDialogueContainer:FindFirstChild("Settings"));
		
	end);
	
	Events.ChangeDefaultVariables = Tools.EditVariables.MouseButton1Click:Connect(function()
		
		-- Look for the default variables script
		local DefaultVariablesFolder = ServerScriptService.DialogueServerScript.DefaultVariables;
		local DefaultVariablesScript;
		for _, variablesScript in ipairs(DefaultVariablesFolder:GetChildren()) do
			if variablesScript.NPC.Value == Model then
				DefaultVariablesScript = variablesScript;
				break;
			end;
		end;
		
		-- Create a default variables script if there isn't one
		if not DefaultVariablesScript then
			DefaultVariablesScript = script.DefaultVariablesTemplate:Clone();
			DefaultVariablesScript.Name = "DefaultVariables";
			DefaultVariablesScript.NPC.Value = Model;
		end;
		
		-- Open the script
		plugin:OpenScript(DefaultVariablesScript);
		
	end);
	
	Events.AddDialogue = Tools.AddDialogue.MouseButton1Click:Connect(function()
		
		local Path = ViewingPriority:split(".");
		local CurrentDirectory = CurrentDialogueContainer;
		for _, directory in ipairs(Path) do
			
			local TargetDirectory = CurrentDirectory:FindFirstChild(directory);
			if not TargetDirectory then
				
				-- Create a folder to hold dialogue and responses
				TargetDirectory = Instance.new("Folder");
				TargetDirectory.Name = directory;
				
				-- Create a folder to hold dialogue
				local Dialogue = Instance.new("Folder");
				Dialogue.Name = "Dialogue";
				Dialogue.Parent = TargetDirectory;
				
				-- Create a folder to hold responses
				local Responses = Instance.new("Folder");
				Responses.Name = "Responses";
				Responses.Parent = TargetDirectory;
				
				-- Create a folder to hold responses
				local Redirects = Instance.new("Folder");
				Redirects.Name = "Redirects";
				Redirects.Parent = TargetDirectory;
				
				TargetDirectory.Parent = CurrentDirectory;
				
			end;
			
			if TargetDirectory.Dialogue:FindFirstChild(directory) then
				CurrentDirectory = TargetDirectory.Dialogue;
			elseif TargetDirectory.Responses:FindFirstChild(directory) then
				CurrentDirectory = TargetDirectory.Responses;
			elseif CurrentDirectory:FindFirstChild(directory) then
				CurrentDirectory = CurrentDirectory[directory].Dialogue;
			end;
			
		end;
		
		AddDialogueToMessageList(CurrentDirectory,"");
		
	end);
	
	-- Let's get the current dialogue settings
	RepairNPC();
	SyncDialogueGui(CurrentDialogueContainer["1"].Dialogue)
	
	DialogueMakerFrame.ViewStatus.ModelLocationFrame.ModelLocation.Text = Model.Name;
	DialogueMakerFrame.Parent = PluginGui;
	DialogueEditorOpen = true;
	
end;

-- Catch the button click event
EditDialogueButton.Click:Connect(function()
	
	if DialogueEditorOpen then
		CloseDialogueEditor();
		return;
	end;
	
	local SelectedObjects = Selection:Get();
	
	-- Check if the user is selecting ONE object
	if #SelectedObjects == 0 then
		EditDialogueButton:SetActive(false);
		error("[Dialogue Maker] You didn't select an object.",0);
	elseif #SelectedObjects > 1 then
		EditDialogueButton:SetActive(false);
		error("[Dialogue Maker] You must select one object; not multiple objects.",0);
	end;
	
	Model = SelectedObjects[1];
	
	-- Check if the user is selecting a model
	if not Model:IsA("Model") then
		EditDialogueButton:SetActive(false);
		error("[Dialogue Maker] You must select a Model, not a "..Model.ClassName..".",0);
	end;
	
	-- Check if the model has a part
	local ModelHasPart = false;
	
	for _, object in ipairs(Model:GetChildren()) do
		if object:IsA("BasePart") then
			ModelHasPart = true;
			break;
		end
	end;
	
	if not ModelHasPart then
		EditDialogueButton:SetActive(false);
		error("[Dialogue Maker] Your selected model doesn't have a part inside of it.",0);
	end;
	
	-- Check if there is a dialogue folder in the NPC
	RepairNPC(true);
	
	-- Add the chat receiver script in the starter player scripts
	if not StarterPlayerScripts:FindFirstChild("DialogueClientScript") then
		
		print("[Dialogue Maker] Adding DialogueClientScript to the StarterPlayerScripts...");
		local DialogueClientScript = script.DialogueClientScript:Clone()
		DialogueClientScript.Parent = StarterPlayerScripts;
		DialogueClientScript.Disabled = false;
		print("[Dialogue Maker] Added DialogueClientScript to the StarterPlayerScripts.");
		
	end;
	
	-- Add the chat receiver script in the starter player scripts
	if not ReplicatedStorage:FindFirstChild("DialogueMakerRemoteConnections") then
		
		print("[Dialogue Maker] Adding DialogueMakerRemoteConnections to the ReplicatedStorage...");
		local DialogueMakerRemoteConnections = script.DialogueMakerRemoteConnections:Clone()
		DialogueMakerRemoteConnections.Parent = ReplicatedStorage;
		print("[Dialogue Maker] Added DialogueMakerRemoteConnections to the ReplicatedStorage.");
		
	end;
	
	-- Add the chat receiver script in the starter player scripts
	if not ServerScriptService:FindFirstChild("DialogueServerScript") then
		
		print("[Dialogue Maker] Adding DialogueServerScript to the ServerScriptService...");
		local DialogueServerScript = script.DialogueServerScript:Clone();
		DialogueServerScript.Parent = ServerScriptService;
		DialogueServerScript.Disabled = false;
		print("[Dialogue Maker] Added DialogueServerScript to the ServerScriptService.");
		
		-- Add this model to the DialogueManager
		local DialogueLocation = Instance.new("ObjectValue");
		DialogueLocation.Value = Model;
		DialogueLocation.Name = "DialogueLocation";
		DialogueLocation.Parent = DialogueServerScript.DialogueLocations;
		
	end;
	
	-- Now we can open the dialogue editor.
	OpenDialogueEditor();
	
end);
