--!strict
return function(player: Player): string

  -- A string representing the value of this dialogue item. 
  -- If this is a message or a response, then this string will be the message or response content.
  -- If this is a redirect, then this string will be dialogue priority to redirect to.
  return "Hello " .. player.Name .. "!";

end
