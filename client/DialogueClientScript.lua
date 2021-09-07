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

    local DialogueSettings = require(npc.DialogueContainer.Settings);
    if DialogueSettings.SpeechBubbleEnabled and DialogueSettings.SpeechBubblePart then
      
      if DialogueSettings.SpeechBubblePart:IsA("BasePart") then
        
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

    if DialogueSettings.PromptRegionEnabled and DialogueSettings.PromptRegionPart then
      
      if DialogueSettings.PromptRegionPart:IsA("BasePart") then
        
        DialogueSettings.PromptRegionPart.Touched:Connect(function(part)

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

    if DialogueSettings.ProximityPromptEnabled and (DialogueSettings.ProximityPromptLocation or DialogueSettings.AutomaticallyCreateProximityPrompt) then
      
      if (DialogueSettings.AutomaticallyCreateProximityPrompt) then
        
        local ProximityPrompt = Instance.new("ProximityPrompt");
        ProximityPrompt.MaxActivationDistance = DialogueSettings.ProximityPromptActivationDistance;
        ProximityPrompt.HoldDuration = DialogueSettings.ProximityPromptHoldDuration;
        ProximityPrompt.RequiresLineOfSight = DialogueSettings.ProximityPromptRequiresLineOfSight;
        ProximityPrompt.Parent = npc;

        DialogueSettings.ProximityPromptLocation = ProximityPrompt;

      end;

      if DialogueSettings.ProximityPromptLocation:IsA("ProximityPrompt") then

        API.Triggers.AddProximityPrompt(npc, DialogueSettings.ProximityPromptLocation);

        DialogueSettings.ProximityPromptLocation.Triggered:Connect(function()
          
          API.Dialogue.ReadDialogue(npc);
          
        end);

      else
        
        warn("[Dialogue Maker]: The ProximityPromptLocation for " .. npc.Name .. " is not a ProximityPrompt.");
        
      end;

    end

    if DialogueSettings.ClickDetectorEnabled and (DialogueSettings.ClickDetectorLocation or DialogueSettings.AutomaticallyCreateClickDetector) then
      
      if DialogueSettings.AutomaticallyCreateClickDetector then

        local ClickDetector = Instance.new("ClickDetector");
        ClickDetector.MaxActivationDistance = DialogueSettings.DetectorActivationDistance;
        ClickDetector.Parent = npc;

        DialogueSettings.ClickDetectorLocation = ClickDetector;

      end;

      if DialogueSettings.ClickDetectorLocation:IsA("ClickDetector") then

        API.Triggers.AddClickDetector(npc, DialogueSettings.ClickDetectorLocation);

        DialogueSettings.ClickDetectorLocation.MouseClick:Connect(function()
          API.Dialogue.ReadDialogue(npc);
        end);

      else
        
        warn("[Dialogue Maker]: The ClickDetectorLocation for " .. npc.Name .. " is not a ClickDetector.");
        
      end;

    end;

    if Keybinds.KEYBINDS_ENABLED then
      
      local CanPressButton = false;
      local ReadDialogueWithKeybind;
      ReadDialogueWithKeybind = function()
        
        if CanPressButton then
          
          if not UserInputService:IsKeyDown(Keybinds.DEFAULT_CHAT_TRIGGER_KEY) and not UserInputService:IsKeyDown(Keybinds.DEFAULT_CHAT_TRIGGER_KEY_GAMEPAD) then
            return;
            
          end;
          API.Dialogue.ReadDialogue(npc);
          
        end;
        
      end;
      ContextActionService:BindAction("OpenDialogueWithKeybind", ReadDialogueWithKeybind, false, Keybinds.DEFAULT_CHAT_TRIGGER_KEY, Keybinds.DEFAULT_CHAT_TRIGGER_KEY_GAMEPAD);

      -- Check if the player is in range
      RunService.Heartbeat:Connect(function()
        
        if Player:DistanceFromCharacter(npc.HumanoidRootPart.Position) <= DefaultMinDistance then
          
          CanPressButton = true;
          
        else
          
          CanPressButton = false;
          
        end;
        
      end);
      
    end;

  end);

  if not success then
    
    warn("[Dialogue Maker]: Couldn't load NPC " .. npc.Name .. ": " .. msg);
    
  end;

end;

Player.CharacterRemoving:Connect(function()

  API.Dialogue.PlayerTalkingWithNPC.Value = false;

end);

print("[Dialogue Maker]: Finished preparing dialogue.");