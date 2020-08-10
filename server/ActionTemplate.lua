local Action = {};
Player = nil;	-- Silences global warnings.

Action.Synchronous = false;	-- Stops the player from proceeding to the next dialogue/leaving
							-- the conversation until the action is complete.
							-- Note: If this is an "action before" function,
							-- this causes the dialogue box to be *blank*
							-- until the action is complete.
		
Action.Variables = function()
	
	-- This function is ran prior to the Execute function.
	-- It's meant for setting conversation variables.
	-- It's helpful if you want this to be an asynchronous action,
	-- yet need to set variables for the dialogue that'll appear next.
	
	return {};	-- These variables will overwrite any conversation variables you describe.
				-- You can call these variables in your dialogue by using 
				-- [/variable=REPLACE_WITH_VARIABLE_NAME]
	
end 	
					
Action.Execute = function()
	
	-- This is the code that's ran when the action is called.
	
end;

return Action;