--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Player = game:GetService("Players").LocalPlayer;

return function(): {string}
  
  -- Any code here will causes the dialogue box to be *blank* until this function returns.
  
  -- A string representing the value of this dialogue item. 
  -- If this is a message or a response, then this string will be the message or response content.
  -- If this is a redirect, then this string will be dialogue priority to redirect to.
  return {"Hi " .. Player.Name .. "!"};

end