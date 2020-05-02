local Trigger = {}

local SpeechBubbles = {};
local ClickDetectors = {};

function Trigger.AddSpeechBubble(npc, speechBubble)
	SpeechBubbles[npc] = speechBubble;
end;

function Trigger.CreateSpeechBubble(npc, properties)
	
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

function Trigger.DisableAllSpeechBubbles()
	for _, speechBubble in pairs(SpeechBubbles) do
		speechBubble.Enabled = false;
	end;
end;

function Trigger.EnableAllSpeechBubbles()
	for _, speechBubble in pairs(SpeechBubbles) do
		speechBubble.Enabled = true;
	end;
end;

function Trigger.AddClickDetector(npc, clickDetector)
	ClickDetectors[npc] = clickDetector;
end;

function Trigger.DisableAllClickDetectors()
	for _, clickDetector in pairs(ClickDetectors) do
		
		-- Keep track of the original parent
		local OriginalParentTag = Instance.new("ObjectValue");
		OriginalParentTag.Name = "OriginalParent"
		OriginalParentTag.Value = clickDetector.Parent;
		OriginalParentTag.Parent = clickDetector;
		
		clickDetector.Parent = nil;
		
	end;
end;

function Trigger.EnableAllClickDetectors()
	for _, clickDetector in pairs(ClickDetectors) do
		if clickDetector:FindFirstChild("OriginalParent") and clickDetector.OriginalParent:IsA("ObjectValue") and clickDetector.OriginalParent.Value then
			clickDetector.Parent = clickDetector.OriginalParent.Value;
			clickDetector.OriginalParent:Destroy();
		end;
	end;
end;

return Trigger;
