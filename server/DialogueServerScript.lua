--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");

-- Get dialogue Settings
local Settings = require(script.Settings);

-- Make sure that we have a connection with the remote functions/events
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections", 3);
assert(RemoteConnections, "[Dialogue Maker]: The DialogueMakerRemoteConnections folder couldn't be found in the ReplicatedStorage.");

-- Add every dialogue that's in the folder to the dialogue array
local DialogueLocations = {};
local DialogueLocationsFolder = script.DialogueLocations;
for _, value in ipairs(DialogueLocationsFolder:GetChildren()) do

  if value.Value and value.Value:FindFirstChild("DialogueContainer") then

    table.insert(DialogueLocations, value.Value);

  end;	

end;

RemoteConnections.GetNPCDialogue.OnServerInvoke = function(player): any

  return DialogueLocations;

end;

RemoteConnections.GetDefaultThemes.OnServerInvoke = function(player): any

  return Settings.DefaultTheme;

end;

RemoteConnections.GetAllThemes.OnServerInvoke = function(player): {[string]: GuiObject}

  local Themes = {};
  local ThemeFolder = script:FindFirstChild("Themes");
  
  if ThemeFolder then

    for _, theme in ipairs(ThemeFolder:GetChildren()) do
      Themes[theme.Name] = theme:Clone();
    end;

  end;
  
  return Themes;

end;

RemoteConnections.PlayerPassesCondition.OnServerInvoke = function(Player: Player, NPC: Model, ContentScript: ModuleScript): boolean

  -- Ensure security
  if not NPC:IsA("Model") or not ContentScript:IsA("ModuleScript") then

    warn("[Dialogue Maker]: " .. Player.Name .. " failed a security check");
    error("[Dialogue Maker]: Invalid parameters given to check if " .. Player.Name .. " passes a condition", 0);

  end;

  -- Search for condition
  local Condition;
  for _, condition in ipairs(script.Conditions:GetChildren()) do

    if condition.NPC.Value == NPC and condition.Priority.Value == ContentScript then

      Condition = condition;
      break;

    end;

  end;

  -- Check if there is no condition or the condition passed
  if not Condition or (require(Condition) :: (Player) -> boolean)(Player) then

    return true;

  else

    return false;

  end;

end;

local ActionCache = {};
local DialogueVariables = {};
RemoteConnections.ExecuteAction.OnServerInvoke = function(Player: Player, NPC: Model, ContentScript: ModuleScript, beforeOrAfter: "Preceding" | "Succeeding"): ()

  -- Ensure security
  if not NPC:IsA("Model") or not ContentScript:IsA("ModuleScript") or typeof(beforeOrAfter) ~= "string" then

    warn("[Dialogue Maker]: " .. Player.Name .. " failed a security check");
    error("[Dialogue Maker]: Invalid parameters given to check if " .. Player.Name .. " passes a condition", 0);

  end;

  -- Search for action
  local Action;
  if ActionCache[NPC] and ActionCache[NPC][beforeOrAfter][ContentScript] then

    Action = ActionCache[NPC][beforeOrAfter][ContentScript];

  elseif not ActionCache[NPC] then

    ActionCache[NPC] = {
      Before = {};
      After = {};
    };

  end;

  if not Action then

    local ActionScripts = script.Actions:FindFirstChild(beforeOrAfter):GetChildren();
    for _, action in ipairs(ActionScripts) do

      if action.NPC.Value == NPC and action.Priority.Value == ContentScript then

        Action = action;
        break;

      end;

    end;

    if not Action then

      return;

    end;

    -- Add the player to the action
    ActionCache[NPC][beforeOrAfter][ContentScript] = require(Action) :: any;

  end;

  -- Check if the action is synchronous
  if Action then

    if Action.Synchronous then

      Action.Execute(Player);

    else

      coroutine.wrap(Action.Execute)(Player);

    end;

  end;

end;

RemoteConnections.GetMinimumDistanceFromCharacter.OnServerInvoke = function(): number

  return Settings.MinimumDistanceFromCharacter;

end;

RemoteConnections.GetKeybinds.OnServerInvoke = function(): any

  return {

    KeybindsEnabled = Settings.KeybindsEnabled;
    DefaultChatTriggerKey = Settings.DefaultChatTriggerKey;
    DefaultChatTriggerKeyGamepad = Settings.DefaultChatTriggerKeyGamepad;
    DefaultChatContinueKey = Settings.DefaultChatContinueKey;
    DefaultChatContinueKeyGamepad = Settings.DefaultChatContinueKeyGamepad;

  };

end;

RemoteConnections.GetDefaultClickSound.OnServerInvoke = function(): number

  return Settings.DefaultClickSound;

end;
