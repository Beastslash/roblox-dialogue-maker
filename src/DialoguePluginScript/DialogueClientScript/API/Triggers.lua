--!strict
local TriggerModule = {};
local ProximityPrompts = {};
local SpeechBubbles = {};
local ClickDetectors = {};

function TriggerModule.createSpeechBubble(npc: Model, properties: {[string]: any}): BillboardGui

  SpeechBubbles[npc] = Instance.new("BillboardGui");
  SpeechBubbles[npc].Name = "SpeechBubble";
  SpeechBubbles[npc].Active = true;
  SpeechBubbles[npc].LightInfluence = 0;
  SpeechBubbles[npc].ResetOnSpawn = false;
  SpeechBubbles[npc].Size = properties.SpeechBubbleSize or properties.SpeechBubble.Size;
  SpeechBubbles[npc].StudsOffset = properties.SpeechBubbleStudsOffset or properties.SpeechBubble.StudsOffset;
  SpeechBubbles[npc].Adornee = properties.SpeechBubblePart or properties.SpeechBubble.BasePart;

  local SpeechBubbleButton = Instance.new("ImageButton");
  SpeechBubbleButton.BackgroundTransparency = 1;
  SpeechBubbleButton.BorderSizePixel = 0;
  SpeechBubbleButton.Name = "SpeechBubbleButton";
  SpeechBubbleButton.Size = UDim2.new(1,0,1,0);
  SpeechBubbleButton.Image = properties.SpeechBubbleImage or properties.SpeechBubble.Image;
  SpeechBubbleButton.Parent = SpeechBubbles[npc];

  return SpeechBubbles[npc];

end;

function TriggerModule.disableAllSpeechBubbles(): ()

  for _, speechBubble in pairs(SpeechBubbles) do

    speechBubble.Enabled = false;

  end;

end;

function TriggerModule.enableAllSpeechBubbles(): ()

  for _, speechBubble in pairs(SpeechBubbles) do

    speechBubble.Enabled = true;

  end;

end;

function TriggerModule.addClickDetector(npc: Model, clickDetector: ClickDetector): ()

  ClickDetectors[npc] = clickDetector;

end;

function TriggerModule.addProximityPrompt(npc: Model, proximityPrompt: ProximityPrompt): ()

  ProximityPrompts[npc] = proximityPrompt

end

function TriggerModule.disableAllClickDetectors(): ()

  for _, clickDetector in pairs(ClickDetectors) do

    -- Keep track of the original parent
    local OriginalParentTag = Instance.new("ObjectValue");
    OriginalParentTag.Name = "OriginalParent"
    OriginalParentTag.Value = clickDetector.Parent;
    OriginalParentTag.Parent = clickDetector;

    clickDetector.Parent = nil;

  end;

end;

function TriggerModule.enableAllClickDetectors(): ()

  for _, clickDetector in pairs(ClickDetectors) do
    
    local OriginalParent = clickDetector:FindFirstChild("OriginalParent");
    if OriginalParent:IsA("ObjectValue") and OriginalParent.Value then

      clickDetector.Parent = OriginalParent.Value;
      OriginalParent:Destroy();

    end;

  end;

end;

function TriggerModule.disableAllProximityPrompts(): ()

  for _, proximityPrompt in pairs(ProximityPrompts) do

    -- Keep track of the original parent
    local OriginalParentTag = Instance.new("ObjectValue");
    OriginalParentTag.Name = "OriginalParent"
    OriginalParentTag.Value = proximityPrompt.Parent;
    OriginalParentTag.Parent = proximityPrompt;

    proximityPrompt.Parent = nil;

  end;
end;

function TriggerModule.enableAllProximityPrompts(): ()

  for _, proximityDetector in pairs(ProximityPrompts) do
    
    local OriginalParent = proximityDetector:FindFirstChild("OriginalParent");
    if OriginalParent:IsA("ObjectValue") and OriginalParent.Value then

      proximityDetector.Parent = OriginalParent.Value;
      OriginalParent:Destroy();

    end;

  end;

end;

return TriggerModule;
