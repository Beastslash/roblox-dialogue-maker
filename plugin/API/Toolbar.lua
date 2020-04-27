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
	
end;

return Toolbar;
