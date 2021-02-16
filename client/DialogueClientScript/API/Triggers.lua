local Triggers = {};

local SpeechBubbles = {};
local ClickDetectors = {};

function Triggers.AddSpeechBubble(npc, speechBubble)
	SpeechBubbles[npc] = speechBubble;
end;

function Triggers.CreateSpeechBubble(npc, properties)
	SpeechBubbles[npc] = Instance.new("BillboardGui");
	for property, value in pairs({
		Name = "SpeechBubble";
		Active = true;
		LightInfluence = 0;
		ResetOnSpawn = false;
		Size = properties.SpeechBubble.Size;
    StudsOffset = properties.StudsOffset;
    Adornee = properties.SpeechBubblePart;
	}) do
		SpeechBubbles[npc][property] = value;
	end;

  local SpeechBubbleButton = Instance.new("ImageButton");
  for property, value in pairs({
    BackgroundTransparency = 1;
    BorderSizePixel = 0;
    Name = "SpeechBubbleButton";
    Size = UDim2.new(1,0,1,0);
    Image = properties.SpeechBubbleImage;
    Parent = SpeechBubbles[npc];
  }) do
    SpeechBubbleButton[property] = value;
  end;

	return SpeechBubbles[npc];
end;

function Triggers.DisableAllSpeechBubbles()
  for _, speechBubble in pairs(SpeechBubbles) do
    speechBubble.Enabled = false;
  end;
end;

function Triggers.EnableAllSpeechBubbles()
  for _, speechBubble in pairs(SpeechBubbles) do
    speechBubble.Enabled = true;
  end;
end;

function Triggers.AddClickDetector(npc, clickDetector)
  ClickDetectors[npc] = clickDetector;
end;

function Triggers.DisableAllClickDetectors()
  for _, clickDetector in pairs(ClickDetectors) do

    -- Keep track of the original parent
    local OriginalParentTag = Instance.new("ObjectValue");
    OriginalParentTag.Name = "OriginalParent"
    OriginalParentTag.Value = clickDetector.Parent;
    OriginalParentTag.Parent = clickDetector;

    clickDetector.Parent = nil;

  end;
end;

function Triggers.EnableAllClickDetectors()
  for _, clickDetector in pairs(ClickDetectors) do
    if clickDetector:FindFirstChild("OriginalParent") and clickDetector.OriginalParent:IsA("ObjectValue") and clickDetector.OriginalParent.Value then
      clickDetector.Parent = clickDetector.OriginalParent.Value;
      clickDetector.OriginalParent:Destroy();
    end;
  end;
end;

return Triggers;