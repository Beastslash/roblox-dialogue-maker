local PlayerModule = {};
local Player = game:GetService("Players").LocalPlayer;

function PlayerModule.FreezePlayer()
  -- Using :WaitForChild() causes the "unknown require" warning to go away.
  -- Roblox, please fix this lol
  require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Disable();
end;

function PlayerModule.UnfreezePlayer()
  require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Enable();
end;

return PlayerModule;