-- Get Roblox services
local Players = game:GetService("Players");
local ControllerService = game:GetService("ControllerService");
local RunService = game:GetService("RunService");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");
local Player = game:GetService("Players").LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");
local ReplicatedStorage = game:GetService("ReplicatedStorage");

-- Check if the DialogueMakerRemoteConnections folder was moved
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections", 3);
assert(RemoteConnections, "[Dialogue Maker]: Couldn't find the DialogueMakerRemoteConnections folder in the ReplicatedStorage.");

-- Set some constants
local API = require(script.API);
local Keybinds = RemoteConnections.GetKeybinds:InvokeServer();
local DefaultMinDistance = RemoteConnections.GetMinimumDistanceFromCharacter:InvokeServer();

-- Iterate through every NPC
print("[Dialogue Maker]: Preparing dialogue received from the server...");

local NPCDialogue = RemoteConnections.GetNPCDialogue:InvokeServer();
for _, npc in ipairs(NPCDialogue) do

  -- Make sure all NPCs aren't affected if this one doesn't load properly
  local success, msg = pcall(function()
    
    -- Get speech bubble settings.
    local DialogueSettings = require(npc.DialogueContainer.Settings);
    local SpeechBubbleSettingsIsTable = typeof(DialogueSettings.SpeechBubble) == "table";
    local SpeechBubbleEnabled = DialogueSettings.SpeechBubbleEnabled or (SpeechBubbleSettingsIsTable and DialogueSettings.SpeechBubble.Enabled);
    local SpeechBubblePart = DialogueSettings.SpeechBubblePart or (SpeechBubbleSettingsIsTable and DialogueSettings.SpeechBubble.BasePart);
    
    -- Get prompt region settings.
    local PromptRegionSettingsIsTable = typeof(DialogueSettings.PromptRegion) == "table";
    local PromptRegionEnabled = DialogueSettings.PromptRegionEnabled or (PromptRegionSettingsIsTable and DialogueSettings.PromptRegion.Enabled);
    local PromptRegionPart = DialogueSettings.PromptRegionPart or (PromptRegionSettingsIsTable and DialogueSettings.PromptRegion.Part);
    
    -- Get proximity prompt settings.
    local ProximityPromptSettingsIsTable = typeof(DialogueSettings.ProximityPrompt) == "table";
    local ProximityPromptEnabled = DialogueSettings.ProximityPromptEnabled or (ProximityPromptSettingsIsTable and DialogueSettings.ProximityPrompt.Enabled);
    local ProximityPromptLocation = DialogueSettings.ProximityPromptLocation or (ProximityPromptSettingsIsTable and DialogueSettings.ProximityPrompt.Location);
    local ProximityPromptAutoCreate = DialogueSettings.AutomaticallyCreateProximityPrompt or (ProximityPromptSettingsIsTable and DialogueSettings.ProximityPrompt.AutoCreate);
    local ProximityPromptActivationDistance = DialogueSettings.ProximityPromptActivationDistance or (ProximityPromptSettingsIsTable and DialogueSettings.ProximityPrompt.MaxActivationDistance);
    local ProximityPromptHoldDuration = DialogueSettings.ProximityPromptHoldDuration or (ProximityPromptSettingsIsTable and DialogueSettings.ProximityPrompt.HoldDuration);
    local ProximityPromptRequiresLineOfSight = DialogueSettings.ProximityPromptRequiresLineOfSight or (ProximityPromptSettingsIsTable and DialogueSettings.ProximityPrompt.RequiresLineOfSight);
    
    -- Get click detector settings.
    local ClickDetectorSettingsIsTable = typeof(DialogueSettings.ClickDetector) == "table";
    local ClickDetectorEnabled = DialogueSettings.ClickDetectorEnabled or (ClickDetectorSettingsIsTable and DialogueSettings.ClickDetector.Enabled);
    local ClickDetectorLocation = DialogueSettings.ClickDetectorLocation or (ClickDetectorSettingsIsTable and DialogueSettings.ClickDetector.Location);
    local ClickDetectorAutoCreate = DialogueSettings.AutomaticallyCreateClickDetector or (ClickDetectorSettingsIsTable and DialogueSettings.ClickDetector.AutoCreate);
    local ClickDetectorActivationDistance = DialogueSettings.DetectorActivationDistance or (ClickDetectorSettingsIsTable and DialogueSettings.ClickDetector.ActivationDistance);
    
    -- Now it's time to set up speech bubbles.
    if SpeechBubbleEnabled and SpeechBubblePart then

      if SpeechBubblePart:IsA("BasePart") then

        local SpeechBubble = API.Triggers.CreateSpeechBubble(npc, DialogueSettings);

        -- Listen if the player clicks the speech bubble
        SpeechBubble.SpeechBubbleButton.MouseButton1Click:Connect(function()

          API.Dialogue.ReadDialogue(npc);

        end);

        SpeechBubble.Parent = PlayerGui;

      else

        warn("[Dialogue Maker]: The SpeechBubblePart for " .. npc.Name .. " is not a Part.");

      end;

    end;
    
    -- Next, the prompt regions.
    if PromptRegionEnabled and PromptRegionPart then

      if PromptRegionPart:IsA("BasePart") then

        PromptRegionPart.Touched:Connect(function(part)

          -- Make sure our player touched it and not someone else
          local PlayerFromCharacter = Players:GetPlayerFromCharacter(part.Parent);
          if PlayerFromCharacter == Player then

            API.Dialogue.ReadDialogue(npc);

          end;

        end);

      else

        warn("[Dialogue Maker]: The PromptRegionPart for " .. npc.Name .. " is not a Part.");

      end;

    end;
    
    -- Now, the proximity prompts.
    if ProximityPromptEnabled and (ProximityPromptLocation or ProximityPromptAutoCreate) then

      if ProximityPromptAutoCreate then

        local ProximityPrompt = Instance.new("ProximityPrompt");
        ProximityPrompt.MaxActivationDistance = ProximityPromptActivationDistance;
        ProximityPrompt.HoldDuration = ProximityPromptHoldDuration;
        ProximityPrompt.RequiresLineOfSight = ProximityPromptRequiresLineOfSight;

        -- TODO: Remove in v4.0.0
        if typeof(DialogueSettings.ProximityPrompt) == "table" then
          ProximityPrompt.GamepadKeyCode = DialogueSettings.ProximityPrompt.GamepadKeyCode;
          ProximityPrompt.KeyboardKeyCode = DialogueSettings.ProximityPrompt.KeyboardKeyCode;
          ProximityPrompt.ObjectText = DialogueSettings.ProximityPrompt.ObjectText;
        end;

        ProximityPrompt.Parent = npc;
        ProximityPromptLocation = ProximityPrompt;

      end;

      if ProximityPromptLocation:IsA("ProximityPrompt") then

        API.Triggers.AddProximityPrompt(npc, ProximityPromptLocation);

        ProximityPromptLocation.Triggered:Connect(function()

          API.Dialogue.ReadDialogue(npc);

        end);

      else

        warn("[Dialogue Maker]: The ProximityPromptLocation for " .. npc.Name .. " is not a ProximityPrompt.");

      end;

    end;
    
    -- Almost there: it's time for the click detectors.
    if ClickDetectorEnabled and (ClickDetectorLocation or ClickDetectorAutoCreate) then

      if ClickDetectorAutoCreate then

        local ClickDetector = Instance.new("ClickDetector");
        ClickDetector.MaxActivationDistance = ClickDetectorActivationDistance;
        ClickDetector.Parent = npc;
        ClickDetectorLocation = ClickDetector;

      end;

      if ClickDetectorLocation:IsA("ClickDetector") then

        API.Triggers.AddClickDetector(npc, ClickDetectorLocation);

        ClickDetectorLocation.MouseClick:Connect(function()
          API.Dialogue.ReadDialogue(npc);
        end);

      else

        warn("[Dialogue Maker]: The ClickDetectorLocation for " .. npc.Name .. " is not a ClickDetector.");

      end;

    end;
    
    -- Finally, the keybinds.
    if Keybinds.KeybindsEnabled then

      local CanPressButton = false;
      local ReadDialogueWithKeybind;
      ReadDialogueWithKeybind = function()

        if CanPressButton then

          if not UserInputService:IsKeyDown(Keybinds.DefaultChatTriggerKey) and not UserInputService:IsKeyDown(Keybinds.DefaultChatTriggerKeyGamepad) then
            return;

          end;
          API.Dialogue.ReadDialogue(npc);

        end;

      end;
      ContextActionService:BindAction("OpenDialogueWithKeybind", ReadDialogueWithKeybind, false, Keybinds.DefaultChatTriggerKey, Keybinds.DefaultChatTriggerKeyGamepad);

      -- Check if the player is in range
      RunService.Heartbeat:Connect(function()

        if Player:DistanceFromCharacter(npc:GetPivot().Position) < DefaultMinDistance then

          CanPressButton = true;

        else

          CanPressButton = false;

        end;

      end);

    end;

  end);
  
  -- One NPC doesn't stop the show, but it's important for you
  -- to know which ones didn't load properly.
  if not success then

    warn("[Dialogue Maker]: Couldn't load NPC " .. npc.Name .. ": " .. msg);

  end;

end;

Player.CharacterRemoving:Connect(function()

  API.Dialogue.PlayerTalkingWithNPC.Value = false;

end);

print("[Dialogue Maker]: Finished preparing dialogue.");