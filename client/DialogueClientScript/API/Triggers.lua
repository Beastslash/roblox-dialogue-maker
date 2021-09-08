local TriggerModule = {};

local ProximityPrompts = {};
local SpeechBubbles = {};
local ClickDetectors = {};

function TriggerModule.AddSpeechBubble(npc: Model, speechBubble)
  
  SpeechBubbles[npc] = speechBubble;
  
end;

function TriggerModule.CreateSpeechBubble(npc: Model, properties: {[string]: any}): BillboardGui

  SpeechBubbles[npc] = Instance.new("BillboardGui");
  SpeechBubbles[npc].Name = "SpeechBubble";
  SpeechBubbles[npc].Active = true;
  SpeechBubbles[npc].LightInfluence = 0;
  SpeechBubbles[npc].ResetOnSpawn = false;
  SpeechBubbles[npc].Size = properties.SpeechBubbleSize;
  SpeechBubbles[npc].StudsOffset = properties.SpeechBubbleStudsOffset;
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

function TriggerModule.DisableAllSpeechBubbles()
  
  for _, speechBubble in pairs(SpeechBubbles) do
    
    speechBubble.Enabled = false;
    
  end;
  
end;

function TriggerModule.EnableAllSpeechBubbles()
  
  for _, speechBubble in pairs(SpeechBubbles) do
    
    speechBubble.Enabled = true;
    
  end;
  
end;

function TriggerModule.AddClickDetector(npc: Model, clickDetector: ClickDetector)
  
  ClickDetectors[npc] = clickDetector;
  
end;

function TriggerModule.AddProximityPrompt(npc: Model, proximityPrompt: ProximityPrompt)
  
  ProximityPrompts[npc] = proximityPrompt
  
end

function TriggerModule.DisableAllClickDetectors()
  
  for _, clickDetector in pairs(ClickDetectors) do

    -- Keep track of the original parent
    local OriginalParentTag = Instance.new("ObjectValue");
    OriginalParentTag.Name = "OriginalParent"
    OriginalParentTag.Value = clickDetector.Parent;
    OriginalParentTag.Parent = clickDetector;

    clickDetector.Parent = nil;

  end;
  
end;

function TriggerModule.EnableAllClickDetectors()
  
  for _, clickDetector in pairs(ClickDetectors) do
    
    if clickDetector:FindFirstChild("OriginalParent") and clickDetector.OriginalParent:IsA("ObjectValue") and clickDetector.OriginalParent.Value then
      
      clickDetector.Parent = clickDetector.OriginalParent.Value;
      clickDetector.OriginalParent:Destroy();
      
    end;
    
  end;
  
end;

function TriggerModule.DisableAllProximityPrompts()
  
  for _, proximityPrompt in pairs(ProximityPrompts) do

    -- Keep track of the original parent
    local OriginalParentTag = Instance.new("ObjectValue");
    OriginalParentTag.Name = "OriginalParent"
    OriginalParentTag.Value = proximityPrompt.Parent;
    OriginalParentTag.Parent = proximityPrompt;

    proximityPrompt.Parent = nil;

  end;
end;

function TriggerModule.EnableAllProximityPrompts()
  
  for _, proximityDetector in pairs(ProximityPrompts) do
    
    if proximityDetector:FindFirstChild("OriginalParent") and proximityDetector.OriginalParent:IsA("ObjectValue") and proximityDetector.OriginalParent.Value then
      
      proximityDetector.Parent = proximityDetector.OriginalParent.Value;
      proximityDetector.OriginalParent:Destroy();
      
    end;
    
  end;
  
end;

return TriggerModule;