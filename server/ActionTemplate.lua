local Action = {};
local Player;				-- Silences global warnings.

Action.Synchronous = false;	-- Stops the player from proceeding to the next dialogue/leaving
							-- the conversation until the action is complete.
							-- Note: If this is an "action before" function,
							-- this causes the dialogue box to be *blank*
							-- until the action is complete.
		
Action.Variables = {CoolPlayer = Player.Name};	-- These variables will overwrite
												-- any default variables declared in the plugin.
												-- You can call these variables
												-- in your dialogue by using 
												-- [/dm-variable="REPLACE_WITH_VARIABLE_NAME"]
					
Action.Execute = function()
	
	-- This is the code that's ran when the action is called
	
end;

return Action;
