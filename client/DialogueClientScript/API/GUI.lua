-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");

-- Prepare these methods
local GUIModule = {
  CurrentTheme = nil;
  ThemeChanged = Instance.new("BindableEvent");
};

setmetatable(GUIModule, {
  __newindex = function(self, index, value)
    
    if index == "CurrentTheme" then
      
      GUIModule.ThemeChanged:Fire(value);
      
    end;
    
    rawset(self, index, value);
    
  end;
});

local DefaultThemeName = nil;
function GUIModule.GetDefaultThemeName(): string

  -- Check if the theme is in the cache
  if DefaultThemeName then
    
    return DefaultThemeName;
    
  end;

  -- Call up the server.
  return RemoteConnections.GetDefaultTheme:InvokeServer();

end;

function GUIModule.CreateNewDialogueGui(theme: string?): ScreenGui
  
  -- Check if we have the theme
  local ThemeFolder = script.Parent.Themes;
  local ThemeName = (theme ~= "" and theme) or GUIModule.GetDefaultThemeName();
  local DialogueGui = ThemeName and ThemeFolder:FindFirstChild(ThemeName);
  if not DialogueGui then
    
    error("[Dialogue Maker]: There isn't a default theme", 0);
    
  elseif ThemeName == DefaultThemeName and theme and theme ~= DefaultThemeName then
    
    warn("[Dialogue Maker]: Can't find theme \"" .. theme .. "\" in the Themes folder of the DialogueClientScript. Using default theme...");
    
  end
  
  -- Return the theme
  return DialogueGui:Clone();

end;

ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections").ChangeTheme.OnClientInvoke = function(themeName)
  
  GUIModule.CurrentTheme = nil;
  GUIModule.CurrentTheme = GUIModule.CreateNewDialogueGui(themeName);
  
end;

return GUIModule;