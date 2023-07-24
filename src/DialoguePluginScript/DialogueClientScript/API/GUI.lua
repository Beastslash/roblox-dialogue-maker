-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");

-- Prepare these methods
local GUIModule = {
  CurrentTheme = script.CurrentTheme;
};

local clientSettings = require(script.Parent.Parent.Settings);
local defaultThemes = clientSettings.defaultThemes;
function GUIModule.getDefaultThemeName(viewportWidth: number, viewportHeight: number): string

  assert(defaultThemes, "[Dialogue Maker] Couldn't get default themes from the server.");

  local defaultThemeName;
  for _, themeInfo in ipairs(defaultThemes) do

    if viewportWidth >= themeInfo.minimumViewportWidth and viewportHeight >= themeInfo.minimumViewportHeight then

      defaultThemeName = themeInfo.themeName;

    end

  end

  return defaultThemeName;

end;

function GUIModule.createNewDialogueGui(themeName: string?): ScreenGui

  -- Check if we have the theme
  local ThemeFolder = script.Parent.Parent.Themes;
  local DialogueGui = ThemeFolder:FindFirstChild(themeName);
  if themeName and not DialogueGui then

    if themeName ~= "" then

      warn("[Dialogue Maker]: Can't find theme \"" .. themeName .. "\" in the Themes folder of the DialogueClientScript. Using default theme...");

    end

    local ScreenGuiTest = Instance.new("ScreenGui");
    ScreenGuiTest.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui");
    local ViewportSize = ScreenGuiTest.AbsoluteSize;
    local DefaultThemeName = GUIModule.getDefaultThemeName(ViewportSize.X, ViewportSize.Y);
    ScreenGuiTest:Destroy();
    DialogueGui = ThemeFolder:FindFirstChild(DefaultThemeName);

  end

  if not DialogueGui then

    error("[Dialogue Maker]: There isn't a default theme", 0);

  end

  -- Return the theme
  return DialogueGui:Clone();

end;

return GUIModule;