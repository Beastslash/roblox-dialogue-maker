--!strict
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

    -- Set up speech bubbles.
    local dialogueSettings = require(npc.NPCDialogueSettings) :: any;
    local SpeechBubbleEnabled = dialogueSettings.speechBubble.enabled;
    local SpeechBubblePart = dialogueSettings.speechBubble.basePart;
    if SpeechBubbleEnabled and SpeechBubblePart then

      if SpeechBubblePart:IsA("BasePart") then

        local SpeechBubble = API.Triggers.createSpeechBubble(npc, dialogueSettings);

        -- Listen if the player clicks the speech bubble
        SpeechBubble.SpeechBubbleButton.MouseButton1Click:Connect(function()

          API.Dialogue.readDialogue(npc);

        end);

        SpeechBubble.Parent = PlayerGui;

      else

        warn("[Dialogue Maker]: The SpeechBubblePart for " .. npc.Name .. " is not a Part.");

      end;

    end;

    -- Next, the prompt regions.
    local PromptRegionEnabled = dialogueSettings.promptRegion.enabled;
    local PromptRegionPart = dialogueSettings.promptRegion.part;
    if PromptRegionEnabled and PromptRegionPart then

      if PromptRegionPart:IsA("BasePart") then

        PromptRegionPart.Touched:Connect(function(part)

          -- Make sure our player touched it and not someone else
          local PlayerFromCharacter = Players:GetPlayerFromCharacter(part.Parent);
          if PlayerFromCharacter == Player then

            API.Dialogue.readDialogue(npc);

          end;

        end);

      else

        warn("[Dialogue Maker]: The PromptRegionPart for " .. npc.Name .. " is not a Part.");

      end;

    end;

    -- Now, the proximity prompts.
    local ProximityPromptEnabled = dialogueSettings.proximityPrompt.enabled;
    local ProximityPromptLocation = dialogueSettings.proximityPrompt.location;
    local ProximityPromptAutoCreate = dialogueSettings.proximityPrompt.autoCreate;
    if ProximityPromptEnabled and (ProximityPromptLocation or ProximityPromptAutoCreate) then

      if ProximityPromptAutoCreate then

        local ProximityPrompt = Instance.new("ProximityPrompt");
        ProximityPrompt.MaxActivationDistance = dialogueSettings.proximityPrompt.maxActivationDistance;
        ProximityPrompt.HoldDuration = dialogueSettings.proximityPrompt.holdDuration;
        ProximityPrompt.RequiresLineOfSight = dialogueSettings.proximityPrompt.requiresLineOfSight;
        ProximityPrompt.Parent = npc;
        ProximityPromptLocation = ProximityPrompt;

      end;

      if ProximityPromptLocation:IsA("ProximityPrompt") then

        API.Triggers.addProximityPrompt(npc, ProximityPromptLocation);

        ProximityPromptLocation.Triggered:Connect(function()

          API.Dialogue.readDialogue(npc);

        end);

      else

        warn("[Dialogue Maker]: The ProximityPromptLocation for " .. npc.Name .. " is not a ProximityPrompt.");

      end;

    end;

    -- Almost there: it's time for the click detectors.
    local ClickDetectorEnabled = dialogueSettings.clickDetector.enabled;

    local ClickDetectorLocation = dialogueSettings.clickDetector.location;
    local ClickDetectorAutoCreate = dialogueSettings.clickDetector.autoCreate;
    if ClickDetectorEnabled and (ClickDetectorLocation or ClickDetectorAutoCreate) then

      if ClickDetectorAutoCreate then

        local ClickDetector = Instance.new("ClickDetector");
        ClickDetector.MaxActivationDistance = dialogueSettings.clickDetector.activationDistance;
        ClickDetector.Parent = npc;
        ClickDetectorLocation = ClickDetector;

      end;

      if ClickDetectorLocation:IsA("ClickDetector") then

        API.Triggers.addClickDetector(npc, ClickDetectorLocation);

        ClickDetectorLocation.MouseClick:Connect(function()
          
          API.Dialogue.readDialogue(npc);
          
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
          
          API.Dialogue.readDialogue(npc);

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

  -- One NPC doesn't stop the show, but it's important for you to know which ones didn't load properly.
  if not success then

    warn("[Dialogue Maker]: Couldn't load NPC " .. npc.Name .. ": " .. msg);

  end;

end;

Player.CharacterRemoving:Connect(function()

  API.Dialogue.PlayerTalkingWithNPC.Value = false;

end);

print("[Dialogue Maker]: Finished preparing dialogue.");