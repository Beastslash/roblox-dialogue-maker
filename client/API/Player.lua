local Player = {}

function Player.SetPlayer(player)
	Player.Player = player;
	Player.PlayerControls = require(player.PlayerScripts.PlayerModule):GetControls();
end;

function Player.FreezePlayer()
	Player.PlayerControls:Disable();
end;

function Player.UnfreezePlayer()
	Player.PlayerControls:Enable();
end;

return Player;
