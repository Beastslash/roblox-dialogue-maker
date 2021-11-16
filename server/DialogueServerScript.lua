-- Roblox services
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

RemoteConnections.GetNPCDialogue.OnServerInvoke = function(player)

  return DialogueLocations;

end;

RemoteConnections.GetDefaultTheme.OnServerInvoke = function(player)

  return Settings.DefaultTheme;

end;

RemoteConnections.GetAllThemes.OnServerInvoke = function(player)

  local ThemeFolder = script:FindFirstChild("Themes");
  if ThemeFolder then

    local Themes = {};

    for _, theme in ipairs(ThemeFolder:GetChildren()) do
      Themes[theme.Name] = theme:Clone();
    end;

    return Themes;

  end;

end;

RemoteConnections.PlayerPassesCondition.OnServerInvoke = function(player, npc, priority)

  -- Ensure security
  if not npc:IsA("Model") or not priority:IsA("Folder") then

    warn("[Dialogue Maker]: " .. player.Name .. " failed a security check");
    error("[Dialogue Maker]: Invalid parameters given to check if " .. player.Name .. " passes a condition", 0);

  end;

  -- Search for condition
  local Condition;
  for _, condition in ipairs(script.Conditions:GetChildren()) do

    if condition.NPC.Value == npc and condition.Priority.Value == priority then

      Condition = condition;
      break;

    end;

  end;

  -- Check if there is no condition or the condition passed
  if not Condition or require(Condition)(player) then

    return true;

  else

    return false;

  end;

end;

local ActionCache = {};
local DialogueVariables = {};
RemoteConnections.ExecuteAction.OnServerInvoke = function(player, npc, priority, beforeOrAfter)

  -- Ensure security
  if not npc:IsA("Model") or not priority:IsA("Folder") or typeof(beforeOrAfter) ~= "string" then

    warn("[Dialogue Maker]: " .. player.Name .. " failed a security check");
    error("[Dialogue Maker]: Invalid parameters given to check if " .. player.Name .. " passes a condition", 0);

  end;

  -- Search for action
  local Action;
  if ActionCache[npc] and ActionCache[npc][beforeOrAfter][priority] then

    Action = ActionCache[npc][beforeOrAfter][priority];

  elseif not ActionCache[npc] then

    ActionCache[npc] = {
      Before = {};
      After = {};
    };

  end;

  if not Action then

    local ActionScripts = script.Actions:FindFirstChild(beforeOrAfter):GetChildren();
    for _, action in ipairs(ActionScripts) do

      if action.NPC.Value == npc and action.Priority.Value == priority then

        Action = action;
        break;

      end;

    end;

    if not Action then

      return;

    end;

    -- Add the player to the action
    Action = require(Action);

    -- Check if there are any variables the user wants us to overwrite
    for variable, value in pairs(Action.Variables(player)) do

      if not DialogueVariables[player] then

        DialogueVariables[player] = {};

      end;

      if not DialogueVariables[player][npc] then

        DialogueVariables[player][npc] = {};

      end;

      DialogueVariables[player][npc][variable] = value;

    end;


    ActionCache[npc][beforeOrAfter][priority] = Action;

  end;

  -- Check if the action is synchronous
  if Action then

    if Action.Synchronous then

      Action.Execute(player);

    else

      coroutine.wrap(Action.Execute)(player);

    end;

  end;

end;

RemoteConnections.GetVariable.OnServerInvoke = function(player, npc, variable)

  -- Ensure security
  if not npc:IsA("Model") or typeof(variable) ~= "string" then

    warn("[Dialogue Maker]: " .. player.Name .. " failed a security check");
    error("[Dialogue Maker]: Invalid parameters given to check if " .. player.Name .. " passes a condition", 0);

  end;

  if not DialogueVariables[player] then

    DialogueVariables[player] = {};

  end;

  if not DialogueVariables[player][npc] then

    DialogueVariables[player][npc] = {
      PlayerName = player.Name;
    };

  end;

  -- Check the current variables
  if not DialogueVariables[player][npc][variable] then

    -- Check for default variables
    for _, variablesScript in ipairs(script.DefaultVariables:GetChildren()) do

      if variablesScript.NPC.Value == npc then

        local DefaultVariablesScript = require(variablesScript);
        for defaultVariable, value in pairs(DefaultVariablesScript) do

          DialogueVariables[player][npc][defaultVariable] = value;

        end;
        break;

      end;

    end;

  end;

  if DialogueVariables[player][npc][variable] then

    return DialogueVariables[player][npc][variable];

  end;

end;

RemoteConnections.GetMinimumDistanceFromCharacter.OnServerInvoke = function()

  return Settings.MinimumDistanceFromCharacter;

end;

RemoteConnections.GetKeybinds.OnServerInvoke = function()

  return {

    KeybindsEnabled = Settings.KeybindsEnabled;
    DefaultChatTriggerKey = Settings.DefaultChatTriggerKey;
    DefaultChatTriggerKeyGamepad = Settings.DefaultChatTriggerKeyGamepad;
    DefaultChatContinueKey = Settings.DefaultChatContinueKey;
    DefaultChatContinueKeyGamepad = Settings.DefaultChatContinueKeyGamepad;

  };

end;

RemoteConnections.GetDefaultClickSound.OnServerInvoke = function()

  return Settings.DefaultClickSound;

end;