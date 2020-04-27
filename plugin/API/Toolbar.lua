local Selection = game:GetService("Selection");
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");


local Toolbar = {};
API = nil;

function Toolbar.Initialize()
	
	-- Create the toolbar and its buttons
	local Toolbar = plugin:CreateToolbar("Dialogue Maker by Beastslash");
	
	local EditDialogueButton = Toolbar:CreateButton(
		"Edit Dialogue", 
		"Edit dialogue of a selected NPC. The selected object must be a singular model.",
		"rbxassetid://332218617");
		
	local ResetScriptsButton = Toolbar:CreateButton(
		"Repair Scripts", 
		"Replace all Dialogue Maker scripts with original scripts. "
		.."This will remove any modifications you made to the scripts, "
		.."but it may repair problems you may have with the plugin.",
		"rbxassetid://332218617");
		
	
	-- Start of toolbar API
	EditDialogueButton.Click:Connect(function()
		
		if API.Editor.DialogueMakerIsOpen() then
			API.Editor.CloseDialogueMaker();
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
		
		local Model = SelectedObjects[1];
		
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
		
		API.Editor.SetModel(Model);
		
		-- Check if there is a dialogue folder in the NPC
		API.Editor.RepairNPC(true);
		
		-- Add the chat receiver script in the starter player scripts
		if not StarterPlayerScripts:FindFirstChild("DialogueClientScript") then
			
			print("[Dialogue Maker] Adding DialogueClientScript to the StarterPlayerScripts...");
			local DialogueClientScript = script.Parent.Parent.GameScripts.DialogueClientScript:Clone()
			DialogueClientScript.Parent = StarterPlayerScripts;
			DialogueClientScript.Disabled = false;
			print("[Dialogue Maker] Added DialogueClientScript to the StarterPlayerScripts.");
			
		end;
		
		-- Add the chat receiver script in the starter player scripts
		if not ReplicatedStorage:FindFirstChild("DialogueMakerRemoteConnections") then
			
			print("[Dialogue Maker] Adding DialogueMakerRemoteConnections to the ReplicatedStorage...");
			local DialogueMakerRemoteConnections = script.Parent.Parent.GameScripts.DialogueMakerRemoteConnections:Clone()
			DialogueMakerRemoteConnections.Parent = ReplicatedStorage;
			print("[Dialogue Maker] Added DialogueMakerRemoteConnections to the ReplicatedStorage.");
			
		end;
		
		-- Add the chat receiver script in the starter player scripts
		if not ServerScriptService:FindFirstChild("DialogueServerScript") then
			
			print("[Dialogue Maker] Adding DialogueServerScript to the ServerScriptService...");
			local DialogueServerScript = script.Parent.Parent.GameScripts.DialogueServerScript:Clone();
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
		API.Editor.OpenDialogueMaker();
		
	end);
	
	local ResettingScripts = false;
	ResetScriptsButton.Click:Connect(function()
		
		-- Debounce
		if ResettingScripts then
			warn("[Dialogue Maker] Scripts are currently being reset!");
			return;
		end;
		ResettingScripts = true;
		
		print("[Dialogue Maker] Resetting all dialogue scripts...");
		
		-- Replace client script
		local DialogueClientScript = StarterPlayerScripts:FindFirstChild("DialogueClientScript");
		local ThemesFolder;
		if DialogueClientScript then
			if DialogueClientScript:FindFirstChild("Themes") and DialogueClientScript.Themes:IsA("Folder") then
				ThemesFolder = DialogueClientScript.Themes:Clone();
			end;
			DialogueClientScript:Destroy();
		end;
		DialogueClientScript = script.Parent.Parent.GameScripts.DialogueClientScript:Clone();
		DialogueClientScript.Disabled = false;
		DialogueClientScript.Parent = StarterPlayerScripts;
		if ThemesFolder then
			DialogueClientScript.Themes:Destroy();
			ThemesFolder.Parent = DialogueClientScript;
		end;
		
		-- Replace server script
		local DialogueServerScript = ServerScriptService:FindFirstChild("DialogueServerScript");
		local ActionsFolder;
		local ConditionsFolder;
		local DefaultVariablesFolder;
		local DialogueLocationsFolder;
		local SettingsModule;
		if DialogueServerScript and DialogueServerScript:IsA("Script") then
			if DialogueServerScript:FindFirstChild("Actions") then
				ActionsFolder = DialogueServerScript.Actions:Clone();
			end;
			if DialogueServerScript:FindFirstChild("Conditions") then
				ConditionsFolder = DialogueServerScript.Conditions:Clone();
			end;
			if DialogueServerScript:FindFirstChild("DefaultVariablesFolder") then
				DefaultVariablesFolder = DialogueServerScript.DefaultVariables:Clone();
			end;
			if DialogueServerScript:FindFirstChild("DialogueLocations") then
				DialogueLocationsFolder = DialogueServerScript.DialogueLocations:Clone();
			end;
			if DialogueServerScript:FindFirstChild("Settings") then
				SettingsModule = DialogueServerScript.Settings:Clone();
			end;
		end;
		DialogueServerScript:Destroy();
		
		-- Replace the scripts
		DialogueServerScript = script.Parent.Parent.GameScripts.DialogueServerScript:Clone();
		DialogueServerScript.Disabled = false;
		DialogueServerScript.Parent = ServerScriptService;
		if ActionsFolder then
			DialogueServerScript.Actions:Destroy();
			ActionsFolder.Parent = DialogueServerScript;
		end;
		if ConditionsFolder then
			DialogueServerScript.Conditions:Destroy();
			ConditionsFolder.Parent = DialogueServerScript;
		end;
		if DefaultVariablesFolder then
			DialogueServerScript.DefaultVariables:Destroy();
			DefaultVariablesFolder.Parent = DialogueServerScript;
		end;
		if DialogueLocationsFolder then
			DialogueServerScript.DialogueLocations:Destroy();
			DialogueLocationsFolder.Parent = DialogueServerScript;
		end;
		if SettingsModule then
			DialogueServerScript.Settings:Destroy();
			SettingsModule.Parent = DialogueServerScript;
		end;
		
		ResettingScripts = false;
		
		print("[Dialogue Maker] Successfully reset all Dialogue Maker scripts.");
		
	end);
	
end;

return Toolbar;
