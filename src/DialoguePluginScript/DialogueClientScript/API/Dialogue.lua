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

-- @since v1.0.0
function DialogueModule.getPages(contentArray: Types.ContentArray, tempLine: TextLabel): {Types.ContentArray}

  local pages: {Types.ContentArray} = {};
  local currentPage: Types.ContentArray = {};
  
  for _, contentItem in ipairs(contentArray) do
    
    if typeof(contentItem) == "table" then
      
      contentItem.runFromGetPages();
      table.insert(currentPage, contentItem);
      
    elseif typeof(contentItem) == "string" then
      
      -- Determine rich text indices.
      local richTextTagIndices: {
        [number]: {
          attributes: string?;
          endOffset: number?;
          name: string;
          startOffset: number;
        }
      } = {};
      local openTagIndices: {number} = {};
      local textCopy = contentItem;
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
              startOffset = pointer;
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

      -- 
      pointer = 1;
      repeat

        -- Check if there's rich text missing.
        tempLine.Text = contentItem;
        local richTextTags = "";
        for i = #richTextTagIndices, 1, -1 do

          local tagInfo = richTextTagIndices[i];
          if tagInfo.startOffset < pointer and tagInfo.endOffset and tagInfo.endOffset >= pointer then

            richTextTags = "<" .. tagInfo.name .. (if tagInfo.attributes and tagInfo.attributes ~= "" then " " .. tagInfo.attributes else  "") .. ">" .. richTextTags;

          end;

        end

        local richTextStart = richTextTags:len() + 1;
        tempLine.Text = richTextTags .. tempLine.Text;

        -- Check if the message fits without us having to do anything.
        local richTextAdditions = 0;
        while not tempLine.TextFits do

          -- Add rich text endings to see if that changes anything.
          local tempRichTextEndTags = "";
          local originalText = tempLine.Text;
          local tempPointer = pointer + originalText:sub(richTextStart):len();
          local function refreshTempRichTextEndTags() 

            for i = #richTextTagIndices, 1, -1 do

              local richTextTagIndex = richTextTagIndices[i];
              if richTextTagIndex.startOffset < tempPointer and richTextTagIndex.endOffset and richTextTagIndex.endOffset >= tempPointer then

                tempRichTextEndTags = tempRichTextEndTags .. "</" .. richTextTagIndices[i].name .. ">";

              elseif richTextTagIndex.startOffset > tempPointer then

                break;

              end;

            end

          end;

          tempLine.Text = originalText .. tempRichTextEndTags;
          richTextAdditions = tempRichTextEndTags:len();

          -- Check if popping off a word helps.
          if not tempLine.TextFits then

            -- Get the space that is the closest to the end of the message.
            local lastSpaceIndex = originalText:match("^.*() ");
            if not lastSpaceIndex or typeof(lastSpaceIndex) ~= "number" then

              break;

            end;

            -- Reform the message without that word.
            originalText = originalText:sub(1, lastSpaceIndex :: number - 1);
            tempPointer = pointer + originalText:sub(richTextStart):len();
            refreshTempRichTextEndTags();
            richTextAdditions = tempRichTextEndTags:len();
            tempLine.Text = originalText .. tempRichTextEndTags;

            -- 
            if not tempLine.TextFits then

              richTextAdditions = 0;
              tempLine.Text = originalText;

            end

          end;

          task.wait();

        end;

        -- Add the words to the table.
        table.insert(currentPage, tempLine.Text);

        -- Update the pointer.
        pointer += tempLine.Text:sub(richTextStart):len() - richTextAdditions;

        -- Subtract what we added to the table.
        contentItem = contentItem:sub(tempLine.Text:sub(richTextStart):len() - richTextAdditions + 2);

      until contentItem == "";
      
    end
    
  end;
  
  table.insert(pages, currentPage);

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
  local function setupDialogueGui(): ()

    -- Set up responses
    DialogueGUI.Parent = Player:WaitForChild("PlayerGui");
    GUIDialogueContainer = DialogueGUI:FindFirstChild("DialogueContainer");
    ResponseContainer = GUIDialogueContainer:FindFirstChild("ResponseContainer");
    assert(ResponseContainer and ResponseContainer:IsA("ScrollingFrame"), "[Dialogue Maker] ResponseContainer is not a ScrollingFrame");
    ResponseTemplate = ResponseContainer:FindFirstChild("ResponseTemplate"):Clone();

    -- Set NPC name
    local npcName = npcSettings.general.npcName;
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
        
        local function useEffect(effectProperties: Types.UseEffectProperties): Types.Effect
          
          -- Try to find the effect script based on the name.
          local EffectScript = DialogueClientScript.Effects:FindFirstChild(effectProperties.name);
          assert(EffectScript and EffectScript:IsA("ModuleScript"), "[Dialogue Maker] " .. effectProperties.name .. " is not a valid effect. Check your Effects folder to make sure there's a ModuleScript with that name.");
          return require(EffectScript)(effectProperties) :: Types.Effect;
          
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
        local ResponsesEnabled = false;
        local TextContainer: GuiObject;
        local NPCTextContainerWithResponses = GUIDialogueContainer:FindFirstChild("NPCTextContainerWithResponses") :: GuiObject;
        local NPCTextContainerWithoutResponses = GUIDialogueContainer:FindFirstChild("NPCTextContainerWithoutResponses") :: GuiObject;
        if #responses > 0 then

          -- Clear the text container just in case there was some responses left behind.
          DialogueModule.clearResponses(ResponseContainer);

        end;
        
        TextContainer = if #responses > 0 then NPCTextContainerWithResponses else NPCTextContainerWithoutResponses;
        NPCTextContainerWithResponses.Visible = #responses > 0;
        NPCTextContainerWithoutResponses.Visible = not (#responses > 0);
        ResponsesEnabled = #responses > 0;

        -- Ensure we have a text container line.
        local TextContainerLine: TextLabel? = TextContainer:FindFirstChild("Line") :: TextLabel;
        assert(TextContainerLine, "Line not found.");

        -- Make the NPC stop talking if the player clicks the frame
        local isNPCTalking = true;
        local WaitingForResponse = true;
        local NPCPaused = false;
        local Pointer = 1;
        local PointerBefore = 1;
        local defaultChatContinueKey = clientSettings.defaultChatContinueKey;
        local defaultChatContinueKeyGamepad = clientSettings.defaultChatContinueKeyGamepad;
        local ContinueDialogue;
        ContinueDialogue = function(keybind: Enum.KeyCode): ()

          -- Ensure the player is holding the key.
          if keybind and not UserInputService:IsKeyDown(defaultChatContinueKey) and not UserInputService:IsKeyDown(defaultChatContinueKeyGamepad) then

            return;

          end;

          -- Temporarily remove the keybind so that the player doesn't skip the next message.
          ContextActionService:UnbindAction("ContinueDialogue");

          if isNPCTalking then

            if ClickSoundEnabled and ClickSound then

              ClickSound:Play();

            end;

            if NPCPaused then

              NPCPaused = false;

            end;

            if npcSettings.general.allowPlayerToSkipDelay then

              -- Replace the incomplete dialogue with the full text
              TextContainerLine.MaxVisibleGraphemes = -1;
              Pointer = PointerBefore + TextContainerLine.ContentText:len();

            end;

            ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, defaultChatContinueKey, defaultChatContinueKeyGamepad);

          elseif #responses == 0 then	

            WaitingForResponse = false;

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
        local pages = DialogueModule.getPages(dialogueContentArray, TextContainerLine);
        
        -- Show what's on every page.
        TextContainerLine.Name = "TestLine";
        TextContainerLine.Text = "";
        TextContainerLine.Visible = false;
        DialogueGUI.Enabled = true;
        local newXOffset = 0;
        local newYOffset = 0;
        for pageIndex, page in ipairs(pages) do
          
          for dialogueContentItemIndex, dialogueContentItem in ipairs(page) do
            
            if typeof(dialogueContentItem) == "table" then

              -- The item is an effect. Let's run it.
              dialogueContentItem.run(false);

            elseif typeof(dialogueContentItem) == "string" then

              -- Pinpoint the offset where the text wraps.
              PointerBefore = Pointer;
              local TextContainerLineCopy = TextContainerLine:Clone();
              TextContainerLineCopy.Parent = TextContainerLine.Parent;
              local oldYBound = 0;
              local wrapXOffset = 0;
              local newLineY = TextContainerLineCopy.LineHeight * TextContainerLineCopy.TextSize;
              for count = 1, #dialogueContentItem do
                
                -- Check if the text wraps
                local oldText = TextContainerLineCopy.Text;
                TextContainerLineCopy.Text = oldText .. dialogueContentItem:sub(count, count);
                local currentYBound = TextContainerLineCopy.TextBounds.Y;
                if currentYBound ~= oldYBound then
                  
                  -- Change the line position.
                  TextContainerLineCopy.Position = UDim2.new(0, 0, 0, TextContainerLineCopy.Position.Y.Offset + newLineY);
                  
                  oldYBound = currentYBound;
                  
                end
                
              end
              wrapXOffset = TextContainerLineCopy.TextBounds.X;

              -- Determine new offset.
              TextContainerLineCopy.Position = UDim2.new();
              TextContainerLineCopy.Text = dialogueContentItem;
              local TextBounds = TextContainerLineCopy.TextBounds;
              
              if newXOffset + TextBounds.X > TextContainer.AbsoluteSize.X then
                
                newXOffset = 0;
                newYOffset += newLineY;
                
              end
              
              TextContainerLineCopy.Position = UDim2.new(0, newXOffset, 0, newYOffset);
              TextContainerLineCopy.Size = UDim2.new(0, TextBounds.X, 0, TextBounds.Y);
              TextContainerLineCopy.Name = pageIndex .. "_" .. dialogueContentItemIndex;
              TextContainerLineCopy.Visible = true;
              
              for count = 0, TextContainerLineCopy.Text:len() do

                TextContainerLineCopy.MaxVisibleGraphemes = count;

                task.wait(npcSettings.general.letterDelay);

                if TextContainerLineCopy.MaxVisibleGraphemes == -1 then 

                  break;

                end

                Pointer += 1;

              end;
              
              newXOffset += TextBounds.X;

            end;
            
          end
          
          -- Check if there are more pages.
          if pages[pageIndex + 1] and isNPCTalking then

            -- Wait for the player to click
            local ClickToContinueButton: GuiButton? = GUIDialogueContainer:FindFirstChild("ClickToContinue") :: GuiButton;
            if ClickToContinueButton then

              ClickToContinueButton.Visible = true;

            end;

            NPCPaused = true;
            while NPCPaused and isNPCTalking and DialogueModule.isPlayerTakingWithNPC do 

              task.wait();

            end;

            -- Let the NPC speak again
            if ClickToContinueButton then

              ClickToContinueButton.Visible = false;

            end;
            NPCPaused = false;

          end;
          
        end;
        isNPCTalking = false;

        local chosenResponse;
        if ResponsesEnabled and DialogueModule.isPlayerTakingWithNPC then

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
                WaitingForResponse = false;

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
            if ResponsesEnabled and npcSettings.timeout.waitForResponse then

              return;

            end;

            -- Wait the timeout set by the developer
            task.wait(npcSettings.timeout.seconds);
            WaitingForResponse = false;

          end;

        end)();

        while WaitingForResponse and DialogueModule.isPlayerTakingWithNPC do

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
        for _, PossibleDialogue in ipairs((if chosenResponse then chosenResponse.ModuleScript else CurrentContentScript):GetChildren()) do

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