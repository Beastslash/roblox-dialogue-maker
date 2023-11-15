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

type Page = {{type: "string" | "effect", size: UDim2?; position: UDim2?; value: string | Types.Effect}};

-- @since v1.0.0
function DialogueModule.getPages(contentArray: Types.ContentArray, TextContainer: GuiObject, TextLabel: TextLabel): {Page}
  
  -- If the content array contains just one string, attempt to fit it in one TextLabel.
  if #contentArray == 1 and typeof(contentArray[1]) == "string" then
    
    local TempTextLabel = TextLabel:Clone();
    TempTextLabel.Text = contentArray[1] :: string;
    TempTextLabel.Parent = TextContainer;
    
    if TempTextLabel.TextFits then
      
      -- Fastest case scenario!
      TempTextLabel:Destroy();
      return {{{
        type = "string",
        size = UDim2.new(1, 0, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        value = contentArray[1]
      }}};
      
    end;
    
  end;
  
  -- Get the max dimensions and breakpoints of every effect.
  local effectMetadata = {};
  for _, possibleEffect in ipairs(contentArray) do
    
    if typeof(possibleEffect) == "table" then
      
      table.insert(effectMetadata, {
        dimensions = possibleEffect.getMaxDimensions(),
        breakpoints = possibleEffect.getBreakpoints()
      });
      
    end;
    
  end;
  
  local pages: {Page} = {};
  local currentPage: Page = {};
  local currentX = 0;
  local currentY = 0;
  
  for index = 1, #contentArray do
    
    local contentItem = contentArray[index];
    
    -- Determine if the item is a raw message or an effect.
    if typeof(contentItem) == "string" then

      -- Check if the text fits already.
      local TempTextLabel = TextLabel:Clone();
      
      if currentX ~= 0 then
        
        -- The text'll have to fit on one line.
        TempTextLabel.Size = UDim2.new(1, -currentX, 0, TempTextLabel.TextSize * TempTextLabel.LineHeight);
        
      end;

      TempTextLabel.Position = UDim2.new(0, currentX, 0, currentY);
      TempTextLabel.Text = contentItem;
      TempTextLabel.Parent = TextContainer;
      
      -- Find all space indices.
      local spaceIndices: {number} = {};
      local spacePointer = 1;
      local textCopy = TempTextLabel.Text;
      while textCopy:find(" ", spacePointer) do

        local _, lastIndex = textCopy:find(" ", spacePointer);
        table.insert(spaceIndices, lastIndex :: number);
        spacePointer = (lastIndex :: number) + 1;

      end;
      
      if TempTextLabel.TextFits then
        
        -- Finding the Y bound is very easy.
        currentY += TempTextLabel.TextBounds.Y - (TempTextLabel.TextSize * TempTextLabel.LineHeight);

        -- Finding the current X bound can be more complex.
        if TempTextLabel.Size.Y.Offset ~= TempTextLabel.TextSize then
          
          -- By erasing every row except for the last row, TempTextLabel.TextBounds.X becomes accurate.
          local originalYBound = TempTextLabel.TextBounds.Y;
          for spaceIndex = #spaceIndices, 1, -1 do
            
            TempTextLabel.Text = TempTextLabel.Text:sub(1, spaceIndices[spaceIndex] + 1);

            if originalYBound ~= TempTextLabel.TextBounds.Y then

              break;

            end;
            
          end;
          
          TempTextLabel.Text = textCopy:sub(TempTextLabel.Text:len());
          
        end;

        currentX = TempTextLabel.TextBounds.X;
        
        -- Add the text to the current page, then move on!
        table.insert(currentPage, {
          type = "string",
          size = TempTextLabel.Size,
          position = TempTextLabel.Position,
          value = contentItem
        });
        
        TempTextLabel:Destroy();
        
        continue;
        
      end;
      
      -- Let's try to individually remove the words.
      for currentIndex = #spaceIndices, 1, -1 do
        
        TempTextLabel.Text = TempTextLabel.Text:sub(0, currentIndex);
        
        if TempTextLabel.TextFits then

          table.insert(currentPage, {
            type = "string",
            size = TempTextLabel.Size,
            position = TempTextLabel.Position,
            value = TempTextLabel.Text
          });
          break;
          
        end
        
      end;
      
      -- Start a new page to see if it'll fit.
      currentX = 0;
      currentY = 0;
      
    else
      
      table.insert(currentPage, {
        type = "effect",
        size = UDim2.new(),
        position = UDim2.new(),
        value = contentItem
      })
      
    end
    
  end;
  
  -- Insert the last page
  table.insert(pages, currentPage);
  
  -- We're done!
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
        local TextContainerLine: TextLabel? = TextContainer:FindFirstChild("Line") :: TextLabel;
        assert(TextContainerLine, "Line not found.");

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
              print("[Dialogue Maker] [" .. dialogueContentItemIndex .. "/" .. #page .. "] [Effect] " .. (npcName or "Unknown NPC") .. ": " .. (dialogueContentItem.value :: Types.Effect).name);
              (dialogueContentItem.value :: Types.Effect).run(isSkipping);

            elseif dialogueContentItem.type == "string" then
              
              -- Print to the debug console.
              print("[Dialogue Maker] [" .. dialogueContentItemIndex .. "/" .. #page .. "] [Message] " .. (npcName or "Unknown NPC") .. ": " .. dialogueContentItem.value :: string);
              
              -- Determine new offset.
              local TextContainerLineCopy = TextContainerLine:Clone();
              TextContainerLineCopy.Position = UDim2.new();
              TextContainerLineCopy.Text = dialogueContentItem.value :: string;
              TextContainerLineCopy.Position = dialogueContentItem.position :: UDim2;
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
