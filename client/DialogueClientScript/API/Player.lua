local PlayerModule = {};

function PlayerModule.SetPlayer(player)
  PlayerModule.Player = player;
  PlayerModule.PlayerControls = require(player.PlayerScripts.PlayerModule):GetControls();
end;

function PlayerModule.FreezePlayer()
  PlayerModule.PlayerControls:Disable();
end;

function PlayerModule.UnfreezePlayer()
  PlayerModule.PlayerControls:Enable();
end;

return PlayerModule;