local Action = {};

Action.Synchronous = false;	-- Stops the player from proceeding to the next dialogue/leaving
							-- the conversation until the action is complete.
							-- Note: If this is an "action before" function,
							-- this causes the dialogue box to be *blank*
							-- until the action is complete.
							
Action.Execute = function()
	
	-- This is the code that's ran when the action is called
	
end;

return Action;
