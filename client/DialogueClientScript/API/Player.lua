local PlayerModule = {};

function PlayerModule.ReadyPlayerControls()
  local Player = game:GetService("Players").LocalPlayer;
  PlayerModule.PlayerControls = require(Player.PlayerScripts.PlayerModule):GetControls();
end;

function PlayerModule.FreezePlayer()
  PlayerModule.PlayerControls:Disable();
end;

function PlayerModule.UnfreezePlayer()
  PlayerModule.PlayerControls:Enable();
end;

return PlayerModule;