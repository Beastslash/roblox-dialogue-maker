local PlayerModule = {};
local Player = game:GetService("Players").LocalPlayer;

function PlayerModule.FreezePlayer()
  require(Player.PlayerScripts.PlayerModule):GetControls():Disable();
end;

function PlayerModule.UnfreezePlayer()
  require(Player.PlayerScripts.PlayerModule):GetControls():Enable();
end;

return PlayerModule;