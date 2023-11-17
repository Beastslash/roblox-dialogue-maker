--!strict
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService");
local Players = game:GetService("Players");
local Player = Players.LocalPlayer;

local DialogueModule = {
  isPlayerTakingWithNPC = false;  
};

local DialogueClientScript = script.Parent.Parent;
local Types = require(DialogueClientScript.Types);

local clientSettings = require(DialogueClientScript.Settings);
local defaultThemes = clientSettings.defaultThemes;
function DialogueModule.getDefaultThemeName(viewportWidth: number, viewportHeight: number): string

  assert(defaultThemes, "[Dialogue Maker] Couldn't get default themes from the server.");

  local defaultThemeName;
  for _, themeInfo in ipairs(defaultThemes) do

    if viewportWidth >= themeInfo.minimumViewportWidth and viewportHeight >= themeInfo.minimumViewportHeight then

      defaultThemeName = themeInfo.themeName;

    end

  end

  return defaultThemeName;

end;

function DialogueModule.createNewDialogueGui(themeName: string?): ScreenGui

  -- Check if we have the theme
  local ThemeFolder = DialogueClientScript.Themes;
  local DialogueGui = ThemeFolder:FindFirstChild(themeName);
  if themeName and not DialogueGui then

    if themeName ~= "" then

      warn("[Dialogue Maker]: Can't find theme \"" .. themeName .. "\" in the Themes folder of the DialogueClientScript. Using default theme...");

    end

    local ScreenGuiTest = Instance.new("ScreenGui");
    ScreenGuiTest.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui");
    local ViewportSize = ScreenGuiTest.AbsoluteSize;
    local DefaultThemeName = DialogueModule.getDefaultThemeName(ViewportSize.X, ViewportSize.Y);
    ScreenGuiTest:Destroy();
    DialogueGui = ThemeFolder:FindFirstChild(DefaultThemeName);

  end

  if not DialogueGui then

    error("[Dialogue Maker]: There isn't a default theme", 0);

  end

  -- Return the theme
  return DialogueGui:Clone();

end;

-- Searches for a ModuleScript based on a given directory. Errors if it doesn't exist. 
-- @since v1.0.0
-- @returns A module script of a given directory.
function DialogueModule.goToDirectory(DialogueContainerFolder: Folder, targetPath: {string}): ModuleScript

  local currentPath = "";
  local CurrentDirectoryScript: ModuleScript | Folder = DialogueContainerFolder;
  for index, directory in ipairs(targetPath) do

    currentPath = currentPath .. (if currentPath ~= "" then "." else "") .. directory;
    local PossibleDirectory = CurrentDirectoryScript:FindFirstChild(directory);
    if not PossibleDirectory or not PossibleDirectory:IsA("ModuleScript") then

      error("[Dialogue Maker]" .. currentPath .. " is not a ModuleScript");

    end
    CurrentDirectoryScript = PossibleDirectory;

  end;
  
  if CurrentDirectoryScript:IsA("Folder") then
    
    error("[Dialogue Maker] Target path (" .. table.concat(targetPath, ".") .. ") not found.");
    
  end
  
  return CurrentDirectoryScript;

end;

-- @since v1.0.0
function DialogueModule.clearResponses(responseContainer: ScrollingFrame): ()

  for _, response in ipairs(responseContainer:GetChildren()) do

    if not response:IsA("UIListLayout") then

      response:Destroy();

    end;

  end;

end;

type Page = {{type: "text"; text: string; size: UDim2} | Types.Effect};

type Pages = {Page};

-- @since v5.0.0
function DialogueModule.getPages(contentArray: Types.ContentArray, TextContainer: GuiObject, TextLabel: TextLabel): Pages
  
  local pages: Pages = {};
  local currentPage: Page = {};
  local TextContainerClone = TextContainer:Clone();
  local TextLabelClone;
  
  TextContainerClone.Visible = false;
  TextContainerClone.Parent = TextContainer.Parent;
  
  if TextContainerClone:FindFirstChild("Segment") then
    
    TextContainerClone:FindFirstChild("Segment"):Destroy();
    
  end
  
  local function newPage()
    
    table.insert(pages, currentPage);
    currentPage = {};
    
    for _, child in ipairs(TextContainerClone:GetChildren()) do
      
      child:Destroy();
      
    end
    
    TextLabelClone = TextLabel:Clone();
    TextLabelClone.Parent = TextContainerClone;
    TextLabelClone.Size = UDim2.new(1, 0, 1, 0);
    
  end
  
  local xSizeOffset = 0;
  
  for contentArrayIndex, contentArrayItem in ipairs(contentArray) do
    
    local function addTextLabelToPage(TextLabel: TextLabel)
      
      table.insert(currentPage, {
        type = "text";
        text = TextLabel.Text;
        size = TextLabel.Size;
      });
      
    end
    
    local contentArrayItemType = typeof(contentArrayItem);
    
    if contentArrayItemType == "string" then
      
      TextLabelClone = TextLabel:Clone();
      
      -- Calculate the X size offset.
      local TextWrapper = TextContainerClone:FindFirstChild("TextWrapper");
      assert(TextWrapper and TextWrapper:IsA("UIListLayout"), "[Dialogue Maker] TextWrapper not found");
      
      local lastSpaceIndex: number? = nil;
      
      repeat
        
        if lastSpaceIndex then
          
          TextLabelClone.Text = (contentArrayItem :: string):sub(lastSpaceIndex);
          
        else 
          
          TextLabelClone.Text = contentArrayItem :: string;
          
        end
        
        TextLabelClone.Size = UDim2.new(1, -xSizeOffset, 1, -TextWrapper.AbsoluteContentSize.Y);
        TextLabelClone.Parent = TextContainerClone;
        
        if not TextLabelClone.TextFits then
          
          -- Check if we should add a new page.
          if TextWrapper.AbsoluteContentSize.Y > TextContainerClone.AbsoluteSize.Y then

            -- Add the current page to the page list.
            newPage();

            -- Reset the TextLabel size.
            TextLabelClone.Text = contentArrayItem :: string;

          end
          
        end
        
        if TextLabelClone.TextFits then
          
          local function getRichTextIndices(text: string)

            local richTextTagIndices: {
              [number]: {
                attributes: string?;
                endOffset: number?;
                name: string;
                startOffset: number;
              }
            } = {};
            local openTagIndices: {number} = {};
            local textCopy = text;
            local tagPattern = "<[^<>]->";
            local pointer = 1;
            for tag in textCopy:gmatch(tagPattern) do

              -- Get the tag name and attributes.
              local tagText = tag:match("<([^<>]-)>");
              if tagText then

                local firstSpaceIndex = tagText:find(" ");
                local tagTextLength = tagText:len();
                local name = tagText:sub(1, (firstSpaceIndex and firstSpaceIndex - 1) or tagTextLength);
                if name:sub(1, 1) == "/" then

                  for _, index in ipairs(openTagIndices) do

                    if richTextTagIndices[index].name == name:sub(2) then

                      -- Add a tag end offset.
                      local _, endOffset = textCopy:find(tagPattern);
                      if endOffset then

                        richTextTagIndices[index].endOffset = pointer + endOffset;

                      end;

                      -- Remove the tag from the open tag table.
                      table.remove(openTagIndices, index);
                      break;

                    end

                  end

                else

                  -- Get the tag start offset.
                  local startOffset = pointer;
                  local attributes = firstSpaceIndex and tagText:sub(firstSpaceIndex + 1) or "";
                  table.insert(richTextTagIndices, {
                    name = name;
                    attributes = attributes;
                    startOffset = textCopy:find(tagPattern) :: number + pointer - 1;
                  });
                  table.insert(openTagIndices, #richTextTagIndices);

                end

                -- Remove the tag from our copy.
                local _, pointerUpdate = textCopy:find(tagPattern);
                if pointerUpdate then

                  pointer += pointerUpdate - 1;
                  textCopy = textCopy:sub(pointerUpdate);

                end;

              end;

            end

            return richTextTagIndices;

          end

          local function getLineBreakPositions(text: string, TextLabel: TextLabel, isRichText: boolean): {number}

            -- Iterate through each character.
            local breakpoints: {number} = {};
            TextLabel.Text = "";
            local lastSpaceIndex: number = 1;
            local skipCounter = 0;
            local remainingRichTextTags = getRichTextIndices(text);
            for index, character in ipairs(text:split("")) do

              -- Check if this is an offset.
              if skipCounter ~= 0 then

                skipCounter -= 1;
                continue;

              end

              if isRichText then

                for _, richTextTagIndex in ipairs(remainingRichTextTags) do

                  if richTextTagIndex.startOffset == index then

                    skipCounter = ("<" .. richTextTagIndex.name .. (if richTextTagIndex.attributes and richTextTagIndex.attributes ~= "" then " " .. richTextTagIndex.attributes else "") .. ">"):len() - 1;
                    break;

                  elseif richTextTagIndex.endOffset :: number - ("</" .. richTextTagIndex.name .. ">"):len() == index then

                    skipCounter = ("</" .. richTextTagIndex.name .. ">"):len() - 1;
                    break;

                  end

                end

              end;

              if skipCounter > 0 then

                continue;

              end

              -- Keep track of spaces.
              if character == " " then

                lastSpaceIndex = index;

              end

              -- Keep track of the original text bounds.
              local originalTextBoundsY = TextLabel.TextBounds.Y;

              -- Add the character and applicable rich text tags.
              TextLabel.Text = TextLabel.ContentText .. character;
              if isRichText then

                for _, richTextTagInfo in ipairs(remainingRichTextTags) do
                  
                  local startOffset = richTextTagInfo.startOffset;
                  local endOffset = richTextTagInfo.endOffset :: number;
                  if index >= startOffset and endOffset > (breakpoints[#breakpoints] or 0) then

                    local prefix = "<" .. richTextTagInfo.name .. (if richTextTagInfo.attributes and richTextTagInfo.attributes ~= "" then " " .. richTextTagInfo.attributes else "") .. ">";
                    local suffix = "</" .. richTextTagInfo.name .. ">";
                    local startOffset = startOffset - (breakpoints[#breakpoints] or 0);
                    local endOffset = (endOffset - (breakpoints[#breakpoints] or 0)) - prefix:len() - suffix:len();
                    TextLabel.Text = TextLabel.ContentText:sub(1, startOffset - 1) .. prefix .. TextLabel.ContentText:sub(startOffset, endOffset - 1) .. suffix .. TextLabel.ContentText:sub(endOffset);

                  end

                end

              end;


              if TextLabel.TextBounds.Y > originalTextBoundsY then

                local currentTextBoundsY = TextLabel.TextBounds.Y;
                TextLabel.TextWrapped = false;

                if TextLabel.TextBounds.Y < currentTextBoundsY then

                  table.insert(breakpoints, lastSpaceIndex);
                  TextLabel.Text = text:sub(lastSpaceIndex + 1, index);

                end

                TextLabel.TextWrapped = true;

              end

            end

            -- Return breakpoints.
            return breakpoints;

          end
          
          local breakpoints = getLineBreakPositions(contentArrayItem :: string, TextLabelClone, TextLabelClone.RichText);
          local lastBreakpointIndex = breakpoints[#breakpoints];
          
          if lastBreakpointIndex then
            
            -- Create another TextLabel to replace the last line of text.
            -- This will allow the TextWrapper to accurately calculate 
            -- how much space is available on the X-axis.
            local ParagraphTextLabel = TextLabelClone:Clone();
            ParagraphTextLabel.Text = (contentArrayItem :: string):sub(1, lastBreakpointIndex);
            ParagraphTextLabel.Parent = TextLabelClone.Parent;
            ParagraphTextLabel.Size = UDim2.new(0, ParagraphTextLabel.TextBounds.X, 0, ParagraphTextLabel.TextBounds.Y);
            addTextLabelToPage(ParagraphTextLabel);
            
            -- Fix the TextLabelClone's text back.
            TextLabelClone.Parent = nil;
            TextLabelClone.Parent = ParagraphTextLabel.Parent;
            TextLabelClone.Text = (contentArrayItem :: string):sub(lastBreakpointIndex);
            
          end;
          
          TextLabelClone.Size = UDim2.new(0, TextLabelClone.TextBounds.X, 0, TextLabelClone.TextBounds.Y);
          addTextLabelToPage(TextLabelClone);
          
          xSizeOffset = if TextContainerClone.AbsolutePosition.X == TextLabelClone.AbsolutePosition.X then 0 else xSizeOffset + TextLabelClone.TextBounds.X;
          
          lastSpaceIndex = nil;
          
        else
          
          -- Remove a word from the text until we can fit the text.
          lastSpaceIndex = 0;
          repeat

            lastSpaceIndex = table.pack(TextLabelClone.Text:find(".* "))[2] :: number;
            TextLabelClone.Parent:Clone().Parent = workspace
            assert(lastSpaceIndex, "[Dialogue Maker] Unable to fit text in text container even after removing the spaces. Is the text too big?");
            TextLabelClone.Text = TextLabelClone.Text:sub(1, lastSpaceIndex :: number - 1)
            
          until TextLabelClone.TextFits;
          
          -- Add the remaining text to a new page.
          addTextLabelToPage(TextLabelClone);
          newPage();
          
          xSizeOffset = 0;
          
        end

      until not lastSpaceIndex;
      
    elseif contentArrayItemType == "table" then
      
      -- TODO: Add effects
      
    end;
    
  end
  
  TextContainerClone:Destroy();
  
  -- Return all pages for this message.
  if currentPage[1] then
    
    newPage();
    
  end
  
  return pages;

end;

local isPlayerTakingWithNPC = false;

-- @since v1.0.0
function DialogueModule.readDialogue(NPC: Model, npcSettings: Types.NPCSettings): ()

  local Events = {};

  -- Make sure we aren't already talking to an NPC
  assert(not DialogueModule.isPlayerTakingWithNPC, "[Dialogue Maker] Cannot read dialogue because player is currently talking with another NPC.");
  DialogueModule.isPlayerTakingWithNPC = true;

  -- Make sure we have a DialogueContainer.
  local NPCDialogueContainer: Folder? = NPC:FindFirstChild("DialogueContainer") :: Folder;
  assert(NPCDialogueContainer, "DialogueContainer not found in NPC.");

  -- Check if the NPC needs to look at the player.
  if npcSettings.general.npcLooksAtPlayerDuringDialogue and npcSettings.general.npcNeckRotationMaxY then

    -- Handle this in a coroutine because the look shouldn't stop the dialogue.
    coroutine.wrap(function()

      local NPCHead: BasePart? = NPC:FindFirstChild("Head") :: BasePart;
      local NPCPrimaryPart: BasePart? = NPC.PrimaryPart :: BasePart;
      local NPCHumanoid: Humanoid? = NPC:FindFirstChild("Humanoid") :: Humanoid;
      local NPCTorso: BasePart? = NPCHumanoid and NPCHumanoid.RigType == Enum.HumanoidRigType.R6 and (NPC:FindFirstChild("Torso") :: BasePart) or nil;
      local NPCNeckParent = NPCTorso or NPCHead;
      local NPCNeck: Motor6D? = NPCNeckParent and NPCNeckParent:FindFirstChild("Neck") :: Motor6D;
      local PlayerCharacter: Model? = Player.Character;
      local PlayerHead: BasePart? = (PlayerCharacter and PlayerCharacter:FindFirstChild("Head") :: BasePart);
      if NPCNeck then

        -- Set the base position.
        NPCNeck.C0 = CFrame.new(NPCNeck.C0.Position) * CFrame.fromOrientation(0, 0, 0);
        NPCNeck.C1 = CFrame.new(NPCNeck.C1.Position) * CFrame.fromOrientation(0, 0, 0);
        local OriginalC0 = NPCNeck.C0;
        local OriginalC1 = NPCNeck.C1;

        while DialogueModule.isPlayerTakingWithNPC and NPCPrimaryPart and NPCHead and NPCNeck and PlayerHead and task.wait() do

          local maxRotationX = npcSettings.general.npcNeckRotationMaxX;
          local maxRotationY = npcSettings.general.npcNeckRotationMaxY;
          local maxRotationZ = npcSettings.general.npcNeckRotationMaxZ;
          local goalRotationX, goalRotationY, goalRotationZ = CFrame.new(NPCHead.Position, PlayerHead.Position):ToOrientation();
          local rotationOffsetX = goalRotationX - math.rad(NPCPrimaryPart.Orientation.X);
          local rotationOffsetY = goalRotationY - math.rad(NPCPrimaryPart.Orientation.Y);
          local rotationOffsetZ = goalRotationZ - math.rad(NPCPrimaryPart.Orientation.Z);
          local rotationXAbs = math.abs(rotationOffsetX);
          local rotationYAbs = math.abs(rotationOffsetY);
          local rotationZAbs = math.abs(rotationOffsetZ);
          TweenService:Create(NPCNeck, TweenInfo.new(0.3), {
            C0 = CFrame.new(NPCNeck.C0.Position) * CFrame.fromOrientation(
            ((rotationXAbs > maxRotationX and maxRotationX * (rotationOffsetX / rotationXAbs) * ((rotationXAbs > math.pi and -1) or 1)) or rotationOffsetX), 
            ((rotationYAbs > maxRotationY and maxRotationY * (rotationOffsetY / rotationYAbs) * ((rotationYAbs > math.pi and -1) or 1)) or rotationOffsetY), 
            ((rotationZAbs > maxRotationZ and maxRotationZ * (rotationOffsetZ / rotationZAbs) * ((rotationZAbs > math.pi and -1) or 1)) or rotationOffsetZ)
            )
          }):Play();

        end

        TweenService:Create(NPCNeck, TweenInfo.new(0.3), {C0 = OriginalC0, C1 = OriginalC1}):Play();

      end

    end)();

  end

  -- Set the theme and prepare the response template
  local DialogueGUI: ScreenGui = DialogueModule.createNewDialogueGui(npcSettings.general.themeName);
  local ResponseContainer, ResponseTemplate, ClickSound: Sound?, ClickSoundEnabled, OldDialogueGui;
  local GUIDialogueContainer = DialogueGUI:FindFirstChild("DialogueContainer");
  local npcName = npcSettings.general.npcName;
  local function setupDialogueGui(): ()

    -- Set up responses
    DialogueGUI.Parent = Player:WaitForChild("PlayerGui");
    GUIDialogueContainer = DialogueGUI:FindFirstChild("DialogueContainer");
    ResponseContainer = GUIDialogueContainer:FindFirstChild("ResponseContainer");
    assert(ResponseContainer and ResponseContainer:IsA("ScrollingFrame"), "[Dialogue Maker] ResponseContainer is not a ScrollingFrame");
    ResponseTemplate = ResponseContainer:FindFirstChild("ResponseTemplate"):Clone();

    -- Set NPC name
    local NPCNameContainer = GUIDialogueContainer:FindFirstChild("NPCNameContainer");
    if NPCNameContainer:IsA("GuiObject") then

      local NPCNameTextClass = NPCNameContainer:FindFirstChild("NPCName");
      if NPCNameTextClass:IsA("TextLabel") then

        NPCNameTextClass.Text = npcName;
        if npcSettings.general.fitName then

          NPCNameContainer.Size = UDim2.new(NPCNameContainer.Size.X.Scale, NPCNameTextClass.TextBounds.X + npcSettings.general.textBoundsOffset, NPCNameContainer.Size.Y.Scale, NPCNameContainer.Size.Y.Offset);

        end;

        NPCNameContainer.Visible = npcName ~= "";

      end

    end;

    -- Setup click sound
    local PossibleClickSound = DialogueGUI:FindFirstChild("ClickSound");
    if PossibleClickSound and PossibleClickSound:IsA("Sound") then

      ClickSound = PossibleClickSound;

    end;

    ClickSoundEnabled = false;

    local defaultClickSound = clientSettings.defaultClickSound;
    if defaultClickSound and defaultClickSound ~= 0 then

      if not ClickSound then

        local NewClickSound = Instance.new("Sound");
        NewClickSound.Name = "ClickSound";
        NewClickSound.Parent = DialogueGUI;
        ClickSound = NewClickSound;

      end;

      ClickSoundEnabled = true;
      (ClickSound :: Sound).SoundId = "rbxassetid://" .. defaultClickSound;

    end;

  end;

  setupDialogueGui();

  if GUIDialogueContainer:IsA("GuiObject") and ResponseContainer:IsA("ScrollingFrame") and ResponseTemplate:IsA("TextButton") then

    -- Initialize the theme, then listen for changes
    script.CurrentTheme.Value = DialogueGUI;
    local ThemeChangedEvent = script.CurrentTheme.Changed:Connect(function(newTheme)

      DialogueGUI:Destroy();
      DialogueGUI = newTheme;
      setupDialogueGui();

    end);

    -- If necessary, end conversation if player or NPC goes out of distance
    local NPCPrimaryPart = NPC.PrimaryPart;
    local MaxConversationDistance = npcSettings.general.maxConversationDistance;
    local EndConversationIfOutOfDistance = npcSettings.general.endConversationIfOutOfDistance;
    if EndConversationIfOutOfDistance and MaxConversationDistance and NPCPrimaryPart then

      coroutine.wrap(function() 

        while task.wait() and DialogueModule.isPlayerTakingWithNPC do

          if math.abs(NPCPrimaryPart.Position.Magnitude - Player.Character.PrimaryPart.Position.Magnitude) > MaxConversationDistance then

            DialogueModule.isPlayerTakingWithNPC = false;
            break;

          end;

        end;

      end)();

    end;

    -- Show the dialouge to the player
    local currentDialoguePriority = "1";
    local CurrentContentScript: ModuleScript;
    while DialogueModule.isPlayerTakingWithNPC and task.wait() do

      -- Get the current directory.
      CurrentContentScript = DialogueModule.goToDirectory(NPCDialogueContainer, currentDialoguePriority:split("."));
      local dialogueType = CurrentContentScript:GetAttribute("DialogueType");

      -- Checks if the local player passes a condition.
      -- @since v5.0.0
      local function doesPlayerPassCondition(ContentScript: ModuleScript): boolean

        -- Search for condition
        for _, PossibleCondition in ipairs(DialogueClientScript.Conditions:GetChildren()) do

          if PossibleCondition.ContentScript.Value == ContentScript then

            -- Check if there is no condition or the condition passed
            return (require(PossibleCondition) :: () -> boolean)();

          end;

        end;

        return true;

      end

      if doesPlayerPassCondition(CurrentContentScript) then
        
        local function useEffect(effectName: string, ...: any): Types.Effect
          
          -- Try to find the effect script based on the name.
          local EffectScript = DialogueClientScript.Effects:FindFirstChild(effectName);
          assert(EffectScript and EffectScript:IsA("ModuleScript"), "[Dialogue Maker] " .. effectName .. " is not a valid effect. Check your Effects folder to make sure there's a ModuleScript with that name.");
          return require(EffectScript)(...) :: Types.Effect;
          
        end;
        
        local dialogueContentArray = (require(CurrentContentScript) :: (useEffect: typeof(useEffect)) -> Types.ContentArray)(useEffect);
        if dialogueType == "Redirect" then

          -- A redirect is available, so let's switch priorities.
          assert(typeof(dialogueContentArray[1]) == "string", "[Dialogue Maker] Item at index 1 is not a directory.");
          currentDialoguePriority = dialogueContentArray[1] :: string;
          continue;

        end;

        -- Get a list of responses from the dialogue.
        local responses: {{ModuleScript: ModuleScript; properties: any}} = {};
        for _, PossibleResponse in ipairs(CurrentContentScript:GetChildren()) do

          if PossibleResponse:IsA("ModuleScript") and tonumber(PossibleResponse.Name) and PossibleResponse:GetAttribute("DialogueType") == "Response" then

            table.insert(responses, {
              ModuleScript = PossibleResponse,
              properties = require(PossibleResponse) :: any
            });

          end

        end

        -- Determine which text container we should use.
        local areResponsesEnabled = false;
        local NPCTextContainerWithResponses = GUIDialogueContainer:FindFirstChild("NPCTextContainerWithResponses") :: GuiObject;
        local NPCTextContainerWithoutResponses = GUIDialogueContainer:FindFirstChild("NPCTextContainerWithoutResponses") :: GuiObject;
        if #responses > 0 then

          -- Clear the text container just in case there was some responses left behind.
          DialogueModule.clearResponses(ResponseContainer);

        end;
        
        local TextContainer = if #responses > 0 then NPCTextContainerWithResponses else NPCTextContainerWithoutResponses;
        NPCTextContainerWithResponses.Visible = #responses > 0;
        NPCTextContainerWithoutResponses.Visible = not (#responses > 0);
        areResponsesEnabled = #responses > 0;

        -- Ensure we have a text container line.
        local TextContainerLine: TextLabel? = TextContainer:FindFirstChild("Segment") :: TextLabel;
        assert(TextContainerLine, "[Dialogue Maker] Segment not found.");

        -- Make the NPC stop talking if the player clicks the frame
        local isNPCTalking = true;
        local isNPCPaused = false;
        local isSkipping = false;
        local isWaitingForPlayerResponse = true;
        local onSkip;
        local defaultChatContinueKey = clientSettings.defaultChatContinueKey;
        local defaultChatContinueKeyGamepad = clientSettings.defaultChatContinueKeyGamepad;
        local ContinueDialogue = function(keybind: Enum.KeyCode?): ()

          -- Ensure the player is holding the key.
          if isSkipping or (keybind and not UserInputService:IsKeyDown(defaultChatContinueKey) and not UserInputService:IsKeyDown(defaultChatContinueKeyGamepad)) then

            return;

          end;

          if isNPCTalking then

            if ClickSoundEnabled and ClickSound then

              ClickSound:Play();

            end;

            if isNPCPaused then

              isNPCPaused = false;

            end;

            if npcSettings.general.allowPlayerToSkipDelay then
              
              isSkipping = true;
              onSkip();

            end;

          elseif #responses == 0 then	

            isWaitingForPlayerResponse = false;

          end;

        end;

        Events.DialogueClicked = GUIDialogueContainer.InputBegan:Connect(function(input)

          -- Make sure the player clicked the frame
          if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            
            ContinueDialogue();

          end;

        end);

        if clientSettings.keybindsEnabled then

          local KEYS_PRESSED = UserInputService:GetKeysPressed();
          local KeybindPressed = false;
          if UserInputService:IsKeyDown(defaultChatContinueKey) or UserInputService:IsKeyDown(defaultChatContinueKeyGamepad) then

            coroutine.wrap(function()

              while UserInputService:IsKeyDown(defaultChatContinueKey) or UserInputService:IsKeyDown(defaultChatContinueKeyGamepad) do

                task.wait();

              end;
              ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, defaultChatContinueKey, defaultChatContinueKeyGamepad);

            end)();

          else

            ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, defaultChatContinueKey, defaultChatContinueKeyGamepad);

          end;

        end;

        -- Determine how many pages we need to show the dialogue.
        local pages = DialogueModule.getPages(dialogueContentArray, TextContainer, TextContainerLine);
        
        -- Show what's on every page.
        TextContainerLine.Text = "";
        TextContainerLine.Visible = false;
        DialogueGUI.Enabled = true;
        for pageIndex, page in ipairs(pages) do
          
          local componentsToDelete = {};
          
          for dialogueContentItemIndex, dialogueContentItem in ipairs(page) do
            
            if dialogueContentItem.type == "effect" then

              -- The item is an effect. Let's run it.
              print("[Dialogue Maker] [" .. dialogueContentItemIndex .. "/" .. #page .. "] [Effect] " .. (npcName or "Unknown NPC") .. ": " .. dialogueContentItem.name);
              dialogueContentItem.run(isSkipping);

            elseif dialogueContentItem.type == "text" then
              
              -- Print to the debug console.
              print("[Dialogue Maker] [" .. dialogueContentItemIndex .. "/" .. #page .. "] [Message] " .. (npcName or "Unknown NPC") .. ": " .. dialogueContentItem.text);
              
              -- Determine new offset.
              local TextContainerLineCopy = TextContainerLine:Clone();
              TextContainerLineCopy.Position = UDim2.new();
              TextContainerLineCopy.Text = dialogueContentItem.text;
              TextContainerLineCopy.Size = dialogueContentItem.size :: UDim2;
              TextContainerLineCopy.Name = pageIndex .. "_" .. dialogueContentItemIndex;
              TextContainerLineCopy.Visible = true;
              TextContainerLineCopy.Parent = TextContainerLine.Parent;
              
              table.insert(componentsToDelete, TextContainerLineCopy);
              
              onSkip = function()
                
                TextContainerLineCopy.MaxVisibleGraphemes = -1;
                
              end;
              
              if isSkipping then
                
                onSkip();
                
              else
                
                for count = 1, #TextContainerLineCopy.Text do

                  TextContainerLineCopy.MaxVisibleGraphemes = count;

                  task.wait(npcSettings.general.letterDelay);

                  if TextContainerLineCopy.MaxVisibleGraphemes == -1 then 

                    break;

                  end

                end;
                
              end;

            end;
            
          end
          
          -- Check if there are more pages.
          if pages[pageIndex + 1] and isNPCTalking then

            -- Wait for the player to click
            local ClickToContinueButton: GuiButton? = GUIDialogueContainer:FindFirstChild("ClickToContinue") :: GuiButton;
            if ClickToContinueButton then

              ClickToContinueButton.Visible = true;

            end;

            isNPCPaused = true;
            while isNPCPaused and isNPCTalking and DialogueModule.isPlayerTakingWithNPC do 

              task.wait();

            end;

            -- Let the NPC speak again
            if ClickToContinueButton then

              ClickToContinueButton.Visible = false;

            end;
            isNPCPaused = false;

          end;
          
        end;
        isSkipping = false;
        isNPCTalking = false;

        local chosenResponse;
        if areResponsesEnabled and DialogueModule.isPlayerTakingWithNPC then

          -- Sort responses because :GetChildren() doesn't guarantee it
          table.sort(responses, function(folder1, folder2)

            return folder1.ModuleScript.Name < folder2.ModuleScript.Name;

          end);

          -- Add response buttons
          for _, response in ipairs(responses) do

            if doesPlayerPassCondition(response.ModuleScript) then

              local ResponseButton = ResponseTemplate:Clone();
              ResponseButton.Name = "Response";
              ResponseButton.Text = response.properties()[1];
              ResponseButton.Parent = ResponseContainer;
              ResponseButton.MouseButton1Click:Connect(function()

                -- Acknowledge that the player clicked the button.
                print("[Dialogue Maker] [Response] " .. Player.Name .. " (" .. Player.UserId .. "): " .. ResponseButton.Text);
                ResponseContainer.Visible = false;

                if ClickSoundEnabled and ClickSound then

                  ClickSound:Play();

                end;

                chosenResponse = response;
                isWaitingForPlayerResponse = false;

              end);

            end;

          end;

          ResponseContainer.CanvasSize = UDim2.new(0, ResponseContainer.CanvasSize.X.Offset, 0, (ResponseContainer:FindFirstChild("UIListLayout") :: UIListLayout).AbsoluteContentSize.Y);
          ResponseContainer.Visible = true;

        end;

        -- Run the timeout code in the background
        coroutine.wrap(function()

          if npcSettings.timeout.enabled then

            -- Wait for the player if the developer wants to
            if not areResponsesEnabled or not npcSettings.timeout.waitForResponse then

              -- Wait the timeout set by the developer
              task.wait(npcSettings.timeout.seconds);
              isWaitingForPlayerResponse = false;

            end;

          end;

        end)();

        while isWaitingForPlayerResponse and DialogueModule.isPlayerTakingWithNPC do

          task.wait();

        end;

        -- Run action
        if DialogueModule.isPlayerTakingWithNPC then

          for _, PossibleAction in ipairs(DialogueClientScript.Actions:GetChildren()) do

            if PossibleAction.ContentScript.Value == CurrentContentScript then

              (require(PossibleAction) :: () -> ())();
              break;

            end;

          end;

        end;

        -- Check if there is more dialogue.
        local hasPossibleDialogue = false;
        local NextScript = if chosenResponse then chosenResponse.ModuleScript else CurrentContentScript;
        for _, PossibleDialogue in ipairs(NextScript:GetChildren()) do

          local DialogueType = PossibleDialogue:GetAttribute("DialogueType");
          if PossibleDialogue:IsA("ModuleScript") and tonumber(PossibleDialogue.Name) and (DialogueType == "Message" or DialogueType == "Redirect") then

            hasPossibleDialogue = true;
            break;

          end

        end

        if DialogueModule.isPlayerTakingWithNPC and hasPossibleDialogue then

          currentDialoguePriority = (if chosenResponse then currentDialoguePriority .. "." .. chosenResponse.ModuleScript.Name else currentDialoguePriority) .. ".1";

        else

          DialogueGUI:Destroy();
          DialogueModule.isPlayerTakingWithNPC = false;

        end;

      elseif DialogueModule.isPlayerTakingWithNPC then

        -- There is a message; however, the player failed the condition.
        -- Let's check if there's something else available.
        local SplitPriority = currentDialoguePriority:split(".");
        SplitPriority[#SplitPriority] = tostring(tonumber(SplitPriority[#SplitPriority]) :: number + 1);
        currentDialoguePriority = table.concat(SplitPriority, ".");

      end;

    end;

    -- Free the player :)
    ThemeChangedEvent:Disconnect();

  end;

  DialogueModule.isPlayerTakingWithNPC = false;

end;

Player.CharacterRemoving:Connect(function()

  DialogueModule.isPlayerTakingWithNPC = false;

end);

return DialogueModule;
