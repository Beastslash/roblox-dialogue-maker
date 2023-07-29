--!strict
local Players = game:GetService("Players");
local ControllerService = game:GetService("ControllerService");
local RunService = game:GetService("RunService");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");
local Player = game:GetService("Players").LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local APIFolder = script.API;
local api = {
  dialogue = require(APIFolder.Dialogue);
  triggers = require(APIFolder.Triggers);
  player = require(APIFolder.Player);
};
local clientSettings = require(script.Settings);

local Types = require(script.Types);
local function readDialogue(NPC: Model, npcSettings: Types.NPCSettings)
  
  -- Make sure we can't talk to another NPC
  api.triggers.disableAllSpeechBubbles();
  api.triggers.disableAllClickDetectors();
  api.triggers.disableAllProximityPrompts();
  
  local freezePlayer = npcSettings.general.freezePlayer;
  if freezePlayer then 

    api.player.freezePlayer(); 

  end;
  
  -- Let the Dialogue module handle it.
  api.dialogue.readDialogue(NPC, npcSettings);
  
  -- Clean up.
  api.triggers.enableAllSpeechBubbles();
  api.triggers.enableAllClickDetectors();
  api.triggers.enableAllProximityPrompts();
  if freezePlayer then 

    api.player.unfreezePlayer(); 

  end;
  
end

-- Iterate through every NPC
print("[Dialogue Maker]: Preparing dialogue received from the server...");
for _, NPCLocation: ObjectValue in ipairs(script.NPCLocations:GetChildren()) do
  
  -- Make sure all NPCs aren't affected if this one doesn't load properly
  if not NPCLocation:IsA("ObjectValue") then
    
    warn("[Dialogue Maker] " .. NPCLocation.Name .. " is not an ObjectValue. Skipping...");
    continue;
    
  end;
  
  local NPC: Model = NPCLocation.Value :: Model;
  if not NPC then
    
    warn("[Dialogue Maker] " .. NPCLocation.Name .. " does not have a Value. Skipping...");
    continue;
    
  elseif not NPC:IsA("Model") then
    
    warn("[Dialogue Maker] " .. NPC.Name .. "'s Value is not a Model. Skipping...");
    continue;
    
  end
    
  local success, msg = pcall(function()
    
    -- Set up speech bubbles.
    local dialogueSettings = require(NPC:FindFirstChild("NPCDialogueSettings")) :: Types.NPCSettings;
    if dialogueSettings.speechBubble.enabled then

      local SpeechBubblePart = dialogueSettings.speechBubble.location;
      if SpeechBubblePart and SpeechBubblePart:IsA("BasePart") then

        -- Listen if the player clicks the speech bubble
        local SpeechBubble = api.triggers.createSpeechBubble(NPC, dialogueSettings);
        (SpeechBubble:FindFirstChild("SpeechBubbleButton") :: ImageButton).MouseButton1Click:Connect(function()

          api.dialogue.readDialogue(NPC, dialogueSettings);

        end);
        SpeechBubble.Parent = PlayerGui;

      else

        warn("[Dialogue Maker]: The SpeechBubblePart for " .. NPC.Name .. " is not a Part.");

      end;

    end;

    -- Next, the prompt regions.
    if dialogueSettings.promptRegion.enabled then

      local PromptRegionPart = dialogueSettings.promptRegion.location;
      if PromptRegionPart and PromptRegionPart:IsA("BasePart") then

        PromptRegionPart.Touched:Connect(function(part)

          -- Make sure our player touched it and not someone else
          local PlayerFromCharacter = Players:GetPlayerFromCharacter(part.Parent);
          if PlayerFromCharacter == Player then

            api.dialogue.readDialogue(NPC, dialogueSettings);

          end;

        end);

      else

        warn("[Dialogue Maker]: The PromptRegionPart for " .. NPC.Name .. " is not a Part.");

      end;

    end;

    -- Now, the proximity prompts.
    if dialogueSettings.proximityPrompt.enabled then

      local ProximityPrompt = dialogueSettings.proximityPrompt.location;
      if dialogueSettings.proximityPrompt.autoCreate then

        local ProximityPromptTemp = Instance.new("ProximityPrompt");
        ProximityPromptTemp.Parent = NPC;
        ProximityPrompt = ProximityPromptTemp;

      end;

      if ProximityPrompt and ProximityPrompt:IsA("ProximityPrompt") then

        api.triggers.addProximityPrompt(NPC, ProximityPrompt);

        ProximityPrompt.Triggered:Connect(function()

          api.dialogue.readDialogue(NPC, dialogueSettings);

        end);

      else

        warn("[Dialogue Maker]: The proximity prompt location for " .. NPC.Name .. " is not a ProximityPrompt.");

      end;

    end;

    -- Almost there: it's time for the click detectors.
    if dialogueSettings.clickDetector.enabled then

      local ClickDetector = dialogueSettings.clickDetector.location;
      if dialogueSettings.clickDetector.autoCreate then

        local ClickDetectorTemp = Instance.new("ClickDetector");
        ClickDetectorTemp.Parent = NPC;
        ClickDetector = ClickDetectorTemp;

      end;

      if ClickDetector and ClickDetector:IsA("ClickDetector") then

        api.triggers.addClickDetector(NPC, ClickDetector);

        ClickDetector.MouseClick:Connect(function()
          
          api.dialogue.readDialogue(NPC, dialogueSettings);
          
        end);

      else

        warn("[Dialogue Maker]: The ClickDetectorLocation for " .. NPC.Name .. " is not a ClickDetector.");

      end;

    end;

    -- Finally, the keybinds.
    if clientSettings.keybindsEnabled then

      local CanPressButton = false;
      local ReadDialogueWithKeybind;
      local defaultChatTriggerKey = clientSettings.defaultChatTriggerKey;
      local defaultChatTriggerKeyGamepad = clientSettings.defaultChatTriggerKeyGamepad;
      ReadDialogueWithKeybind = function()

        if CanPressButton and (UserInputService:IsKeyDown(defaultChatTriggerKey) or UserInputService:IsKeyDown(defaultChatTriggerKeyGamepad)) then
            
          api.dialogue.readDialogue(NPC, dialogueSettings);

        end;

      end;
      ContextActionService:BindAction("OpenDialogueWithKeybind", ReadDialogueWithKeybind, false, defaultChatTriggerKey, defaultChatTriggerKeyGamepad);

      -- Check if the player is in range
      RunService.Heartbeat:Connect(function()

        CanPressButton = Player:DistanceFromCharacter(NPC:GetPivot().Position) < clientSettings.minimumDistanceFromCharacter;

      end);

    end;

  end);

  -- One NPC doesn't stop the show, but it's important for you to know which ones didn't load properly.
  if not success then

    warn("[Dialogue Maker]: Couldn't load NPC " .. NPC.Name .. ": " .. msg);

  end;

end;

print("[Dialogue Maker]: Finished preparing dialogue.");