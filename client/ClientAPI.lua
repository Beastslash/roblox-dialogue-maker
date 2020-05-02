local API = {
	Gui = require(script.GUI);
	Dialogue = require(script.Dialogue);
	Trigger = require(script.Trigger);
	Player = require(script.Player);
	RichText = require(script.RichText);
};

-- Sync the variables of the API methods
for _, module in pairs(API) do
	
	if typeof(module) == "table" then
		
		local APIModule = module;
		for name, method in pairs(APIModule) do
			
			if typeof(method) == "function" then
				
				-- Set API environments
				local OldEnvironment = getfenv(method);
				setfenv(method, setmetatable({
					API = API;
				},{
					__index = function(_, index)
						if OldEnvironment[index] then
							return OldEnvironment[index];
						end;
					end;
				}));
				
			end;
			
		end;
		
		
	end;
	
end;

return API;
