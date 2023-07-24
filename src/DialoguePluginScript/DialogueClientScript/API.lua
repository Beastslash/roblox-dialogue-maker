--!strict
print("[Dialogue Maker]: Initializing client API...");

local API = {};

for _, instance in ipairs(script:GetChildren()) do
  
  -- Get the table.  
  local module = require(instance) :: any;
  
  -- Check if we need to set the API.
  if module._setAPI then
    
    module._setAPI(API);
    
  end;
  
  -- Add it to the table.
  API[instance.Name] = module;
  
end;

-- And we're done!
print("[Dialogue Maker]: Client API now available!");

return API;
