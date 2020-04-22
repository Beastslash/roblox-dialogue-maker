local API = {
	Gui = {};
	Dialogue = {};
	Triggers = {};
	Player = {};
};

-- Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");

local DefaultThemeName;
local SpeechBubbles = {};
local ClickDetectors = {};

function API.Gui.GetDefaultThemeName()
	
	-- Check if the theme is in the cache
	if DefaultThemeName then
		return DefaultThemeName;
	end;
	
	-- Call up the server.
	return RemoteConnections.GetDefaultTheme:InvokeServer();
	
end;

function API.Gui.CreateNewDialogueGui(theme)
	
	local ThemeFolder = script.Parent.Themes;
	local DialogueGui;
	
	if theme and theme ~= "" then
		DialogueGui = ThemeFolder:FindFirstChild(theme);
		if not DialogueGui then
			warn("[Dialogue Maker] Can't find theme \""..theme.."\" in the Themes folder of the DialogueClientScript. Using default theme...");
		end;
	end;
	
	if not DialogueGui then
		DialogueGui = ThemeFolder:FindFirstChild(API.Gui.GetDefaultThemeName());
		if not DialogueGui then
			error("[Dialogue Maker] Default theme \""..API.GetDefaultThemeName().."\" couldn't be found in the themes folder.");
		end;
	end;
	
	return DialogueGui:Clone();
	
end;

function API.Triggers.AddSpeechBubble(npc, speechBubble)
	SpeechBubbles[npc] = speechBubble;
end;

function API.Triggers.CreateSpeechBubble(npc, properties)
	
	SpeechBubbles[npc] = Instance.new("BillboardGui");
	SpeechBubbles[npc].Name = "SpeechBubble";
	SpeechBubbles[npc].Active = true;
	SpeechBubbles[npc].LightInfluence = 0;
	SpeechBubbles[npc].ResetOnSpawn = false;
	SpeechBubbles[npc].Size = properties.SpeechBubbleSize;
	SpeechBubbles[npc].StudsOffset = properties.StudsOffset;
	SpeechBubbles[npc].Adornee = properties.SpeechBubblePart;
	
	local SpeechBubbleButton = Instance.new("ImageButton");
	SpeechBubbleButton.BackgroundTransparency = 1;
	SpeechBubbleButton.BorderSizePixel = 0;
	SpeechBubbleButton.Name = "SpeechBubbleButton";
	SpeechBubbleButton.Size = UDim2.new(1,0,1,0);
	SpeechBubbleButton.Image = properties.SpeechBubbleImage;
	SpeechBubbleButton.Parent = SpeechBubbles[npc];
	
	return SpeechBubbles[npc];
	
end;

function API.Triggers.DisableAllSpeechBubbles()
	for _, speechBubble in pairs(SpeechBubbles) do
		speechBubble.Enabled = false;
	end;
end;

function API.Triggers.EnableAllSpeechBubbles()
	for _, speechBubble in pairs(SpeechBubbles) do
		speechBubble.Enabled = true;
	end;
end;

function API.Triggers.AddClickDetector(npc, clickDetector)
	ClickDetectors[npc] = clickDetector;
end;

function API.Triggers.DisableAllClickDetectors()
	for _, clickDetector in pairs(ClickDetectors) do
		
		-- Keep track of the original parent
		local OriginalParentTag = Instance.new("ObjectValue");
		OriginalParentTag.Name = "OriginalParent"
		OriginalParentTag.Value = clickDetector.Parent;
		OriginalParentTag.Parent = clickDetector;
		
		clickDetector.Parent = nil;
		
	end;
end;

function API.Triggers.EnableAllClickDetectors()
	for _, clickDetector in pairs(ClickDetectors) do
		if clickDetector:FindFirstChild("OriginalParent") and clickDetector.OriginalParent:IsA("ObjectValue") and clickDetector.OriginalParent.Value then
			clickDetector.Parent = clickDetector.OriginalParent.Value;
			clickDetector.OriginalParent:Destroy();
		end;
	end;
end;

function API.Player.SetPlayer(player)
	API.Player.Player = player;
	API.Player.PlayerControls = require(player.PlayerScripts.PlayerModule):GetControls();
end;

function API.Player.FreezePlayer()
	API.Player.PlayerControls:Disable();
end;

function API.Player.UnfreezePlayer()
	API.Player.PlayerControls:Enable();
end;

function API.Dialogue.GoToDirectory(currentDirectory, targetPath)
	
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

function API.Dialogue.ReplaceVariablesWithValues(npc, text)
	
	for match in string.gmatch(text, "%[/variable=(.+)%]") do
				
		-- Get the match from the server
		local VariableValue = RemoteConnections.GetVariable:InvokeServer(npc, match);
		if VariableValue then
			text = text:gsub("%[/variable=(.+)%]",VariableValue);
		end;
		
	end;
	
	return text;
	
end;

function API.Dialogue.ClearResponses(responseContainer)
	for _, response in ipairs(responseContainer:GetChildren()) do
		if not response:IsA("UIListLayout") then
			response:Destroy();
		end;
	end;
end;

function API.Dialogue.DivideTextToFitBox(text, textContainer)
	
	local Line = textContainer.Line:Clone();
	Line.Name = "LineTest"
	Line.Visible = false;
	Line.Parent = textContainer;
	
	local Divisions = {};
	local Page = 1;
	
	for index, word in ipairs(text:split(" ")) do
		if index == 1 then
			Line.Text = word;
		else
			Line.Text = Line.Text.." "..word
		end;
		
		if not Divisions[Page] then Divisions[Page] = {}; end;
		
		if Line.TextFits then
			table.insert(Divisions[Page],word);
			Divisions[Page].FullText = Line.Text;
		elseif not Divisions[Page][1] then
			Line.Text = "";
			for _, letter in ipairs(word:split("")) do
				Line.Text = Line.Text..letter;
				if not Line.TextFits then
					-- Remove the letter from the text
					Line.Text = Line.Text:sub(1,string.len(Line.Text)-1);
					table.insert(Divisions[Page], Line.Text);
					Divisions[Page].FullText = Line.Text;
					
					-- Take it from the top
					Page = Page + 1;
					Divisions[Page] = {};
					Line.Text = letter;
					
				end;
			end;
			
			table.insert(Divisions[Page], Line.Text);
			Divisions[Page].FullText = Line.Text;
			
		else
			Page = Page + 1;
		end;
	end;
	
	Line:Destroy();
	
	return Divisions;
	
end;

return API;
