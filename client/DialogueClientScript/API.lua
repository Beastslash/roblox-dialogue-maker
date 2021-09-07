-- Initalize the API
print("[Dialogue Maker]: Initalizing client API...");
local API = {};
for _, module in ipairs(script:GetChildren()) do
  
  API[module.Name] = require(module);
  
end;

-- Pass the API to other methods
for _, module in pairs(API) do
  
  if typeof(module) == "table" then
    
    for funcName, funcCode in pairs(module) do
      
      local OldEnvironment = getfenv(funcCode);
      local NewEnvMT = setmetatable({
        
        script = script;
        API = API;
        
      }, {
        
        __index = function(_, index)
          
          return OldEnvironment[index]
          
        end;
        
      });
      setfenv(funcCode, NewEnvMT);
      
    end;
    
  end;
  
end;

print("[Dialogue Maker]: Client API now available!");
return API;