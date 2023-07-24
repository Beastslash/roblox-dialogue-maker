--!strict
return function(player: Player): boolean
	
	-- In order for this condition to pass, it must return true.
	-- Otherwise, lower priority dialogue/responses or no dialogue/responses will be used.
	return true;
	
end;
