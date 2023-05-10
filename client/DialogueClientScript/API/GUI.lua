-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");

-- Prepare these methods
local GUIModule = {
  CurrentTheme = script.CurrentTheme;
};

local DefaultThemes: {
  [number]: {
    MinimumViewportWidth: number;
    MinimumViewportHeight: number;
    ThemeName: string;
  }  
}? = nil;
function GUIModule.GetDefaultThemeName(viewportWidth: number, viewportHeight: number): string

  -- Check if the theme is in the cache
  if not DefaultThemes then
    
    DefaultThemes = RemoteConnections.GetDefaultThemes:InvokeServer();
    
  end;
  assert(DefaultThemes, "[Dialogue Maker] Couldn't get default themes from the server.");

  local DefaultThemeName;
  for _, themeInfo in ipairs(DefaultThemes) do
    
    if viewportWidth >= themeInfo.MinimumViewportWidth and viewportHeight >= themeInfo.MinimumViewportHeight then
      
      DefaultThemeName = themeInfo.ThemeName;
      
    end
    
  end
  
  return DefaultThemeName;

end;

function GUIModule.CreateNewDialogueGui(theme: string?): ScreenGui
  
  -- Check if we have the theme
  local ThemeFolder = script.Parent.Parent.Themes;
  local DialogueGui = ThemeFolder:FindFirstChild(theme);
  if theme and not DialogueGui then
    
    if theme ~= "" then
      
      warn("[Dialogue Maker]: Can't find theme \"" .. theme .. "\" in the Themes folder of the DialogueClientScript. Using default theme...");

    end

    local ScreenGuiTest = Instance.new("ScreenGui");
    ScreenGuiTest.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui");
    local ViewportSize = ScreenGuiTest.AbsoluteSize;
    local DefaultThemeName = GUIModule.GetDefaultThemeName(ViewportSize.X, ViewportSize.Y);
    ScreenGuiTest:Destroy();
    DialogueGui = ThemeFolder:FindFirstChild(DefaultThemeName);
    
  end
  
  if not DialogueGui then

    error("[Dialogue Maker]: There isn't a default theme", 0);

  end
  
  -- Return the theme
  return DialogueGui:Clone();

end;

ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections").ChangeTheme.OnClientInvoke = function(themeName)
  
  script.CurrentTheme.Value = GUIModule.CreateNewDialogueGui(themeName);
  
end;

return GUIModule;
