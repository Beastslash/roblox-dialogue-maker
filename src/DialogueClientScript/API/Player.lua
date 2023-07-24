--!strict
local PlayerModule = {};
local Player = game:GetService("Players").LocalPlayer;

function PlayerModule.freezePlayer(): ()
  
  require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Disable();
  
end;

function PlayerModule.unfreezePlayer(): ()
  
  require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Enable();
  
end;

return PlayerModule;
