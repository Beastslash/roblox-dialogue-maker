--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");
local TweenService = game:GetService("TweenService");
local Players = game:GetService("Players");
local Player = Players.LocalPlayer;

local DialogueModule = {

  PlayerTalkingWithNPC = script.PlayerTalkingWithNPC; 

};

local API;

-- @since v1.0.0
function DialogueModule._setAPI(api: any): ()

  API = api;

end

-- Searches for a ModuleScript based on a given directory. Errors if it doesn't exist. 
-- @since v1.0.0
-- @returns A module script of a given directory.
function DialogueModule.goToDirectory(CurrentDirectoryScript: ModuleScript, targetPath: {string}): ModuleScript
  
  local currentPath = "";
  for index, directory in ipairs(targetPath) do
    
    currentPath = currentPath .. (if currentPath ~= "" then "." else "") .. directory;
    local PossibleDirectory = CurrentDirectoryScript:FindFirstChild(directory);
    if not PossibleDirectory or not PossibleDirectory:IsA("ModuleScript") then
      
      error("[Dialogue Maker]" .. currentPath .. " is not a ModuleScript");
      
    end
    CurrentDirectoryScript = PossibleDirectory;

  end;

  return CurrentDirectoryScript;

end;

-- @since v1.0.0
function DialogueModule.retrievePausePoints(text: string, tempLine: TextLabel): (string, {number})

  local PausePoints: {
    [number]: number
  } = {};

  local Pattern: string = "%[/wait time=(%d+%.?%d+)%]";
  tempLine.Text = text;
  for pauseTime: string in string.gmatch(tempLine.ContentText, Pattern) do

    -- Get the index.
    local Index: number? = tempLine.ContentText:find(Pattern);

    -- Add the data to the table.
    local Time: number? = tonumber(pauseTime);
    if Time and Index then

      PausePoints[Index] = Time;

      -- Remove the string.
      tempLine.Text = tempLine.Text:gsub(Pattern, "", 1);

    end;

  end;

  return tempLine.Text, PausePoints;

end;

-- @since v1.0.0
function DialogueModule.clearResponses(responseContainer: Folder): ()

  for _, response in ipairs(responseContainer:GetChildren()) do

    if not response:IsA("UIListLayout") then

      response:Destroy();

    end;

  end;

end;

-- @since v1.0.0
function DialogueModule.divideTextToFitBox(text: string, tempLine: TextLabel): {string}

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
  local MessageParts = {};
  repeat

    -- Check if there's rich text missing.
    tempLine.Text = text;
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
    table.insert(MessageParts, tempLine.Text);

    -- Update the pointer.
    pointer += tempLine.Text:sub(richTextStart):len() - richTextAdditions;

    -- Subtract what we added to the table.
    text = text:sub(tempLine.Text:sub(richTextStart):len() - richTextAdditions + 2);

  until text == "";

  return MessageParts;

end;

-- @since v1.0.0
function DialogueModule.ReadDialogue(npc: Model): ()
  
  local Events = {};
  local DefaultClickSound = RemoteConnections.GetDefaultClickSound:InvokeServer();
  local Keybinds = RemoteConnections.GetKeybinds:InvokeServer();
  local DefaultMinDistance = RemoteConnections.GetMinimumDistanceFromCharacter:InvokeServer();

  -- Make sure we aren't already talking to an NPC
  if not DialogueModule.PlayerTalkingWithNPC.Value then

    DialogueModule.PlayerTalkingWithNPC.Value = true;
    
    local ranSuccessfully, errorMessage = pcall(function()
      
      -- Make sure we have a DialogueContainer.
      local NPCDialogueContainer: Folder? = npc:FindFirstChild("DialogueContainer") :: Folder;
      assert(NPCDialogueContainer, "DialogueContainer not found in NPC.");
      
      -- Make sure we can't talk to another NPC
      API.Triggers.disableAllSpeechBubbles();
      API.Triggers.disableAllClickDetectors();
      API.Triggers.disableAllProximityPrompts();
      
      -- Verify NPCSettingsScript.
      local NPCSettingsScript = NPCDialogueContainer:FindFirstChild("Settings");
      if not NPCSettingsScript or not NPCSettingsScript:IsA("ModuleScript") then
        
        error("NPC settings script not found.");
        
      end;
      local DialogueSettings = require(NPCSettingsScript) :: any;
      local FreezePlayer = DialogueSettings.FreezePlayer or (DialogueSettings.General and DialogueSettings.General.FreezePlayer);
      if FreezePlayer then 

        API.Player.freezePlayer(); 

      end;

      -- Check if the NPC needs to look at the player.
      if DialogueSettings.General.NPCLooksAtPlayerDuringDialogue and DialogueSettings.General.NPCNeckRotationMaxY then

        -- Handle this in a coroutine because the look shouldn't stop the dialogue.
        coroutine.wrap(function()

          local NPCHead: BasePart? = npc:FindFirstChild("Head") :: BasePart;
          local NPCPrimaryPart: BasePart? = npc.PrimaryPart :: BasePart;
          local NPCHumanoid: Humanoid? = npc:FindFirstChild("Humanoid") :: Humanoid;
          local NPCTorso: BasePart? = NPCHumanoid and NPCHumanoid.RigType == Enum.HumanoidRigType.R6 and (npc:FindFirstChild("Torso") :: BasePart) or nil;
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

            while DialogueModule.PlayerTalkingWithNPC.Value and NPCPrimaryPart and NPCHead and NPCNeck and PlayerHead and task.wait() do

              local maxRotationX = DialogueSettings.General.NPCNeckRotationMaxX;
              local maxRotationY = DialogueSettings.General.NPCNeckRotationMaxY;
              local maxRotationZ = DialogueSettings.General.NPCNeckRotationMaxZ;
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
      local DialogueGUI: ScreenGui = API.GUI.createNewDialogueGUI(DialogueSettings.Theme or (DialogueSettings.General and DialogueSettings.General.ThemeName));
      local ResponseContainer, ResponseTemplate, ClickSound: Sound?, ClickSoundEnabled, OldDialogueGui;
      local GUIDialogueContainer = DialogueGUI:FindFirstChild("DialogueContainer");
      local function SetupDialogueGui()

        -- Set up responses
        DialogueGUI.Parent = Player:WaitForChild("PlayerGui");
        GUIDialogueContainer = DialogueGUI:FindFirstChild("DialogueContainer");
        ResponseContainer = GUIDialogueContainer:FindFirstChild("ResponseContainer");
        if not ResponseContainer or not ResponseContainer:IsA("ScrollingFrame") then
          
          error("ResponseContainer is not a ScrollingFrame");
          
        end
        ResponseTemplate = ResponseContainer:FindFirstChild("ResponseTemplate"):Clone();
        
        -- Set NPC name
        local NPCName = DialogueSettings.general.npcName;
        local NPCNameContainer = GUIDialogueContainer:FindFirstChild("NPCNameContainer");
        if NPCNameContainer:IsA("GuiObject") then
          
          local NPCNameTextClass = NPCNameContainer:FindFirstChild("NPCName");
          if NPCNameTextClass:IsA("TextLabel") then
            
            NPCNameTextClass.Text = NPCName;
            if DialogueSettings.General and DialogueSettings.General.FitName then

              local TextBoundsOffset = (DialogueSettings.General and DialogueSettings.General.TextBoundsOffset) or 30;
              NPCNameContainer.Size = UDim2.new(NPCNameContainer.Size.X.Scale, NPCNameTextClass.TextBounds.X + TextBoundsOffset, NPCNameContainer.Size.Y.Scale, NPCNameContainer.Size.Y.Offset);
              
            end;
            
            NPCNameContainer.Visible = typeof(NPCName) == "string" and NPCName ~= "";

          end
          
        end;

        -- Setup click sound
        local PossibleClickSound = DialogueGUI:FindFirstChild("ClickSound");
        if PossibleClickSound:IsA("Sound") then
          
          ClickSound = PossibleClickSound;
          
        end
        ClickSoundEnabled = false;
        if DefaultClickSound and DefaultClickSound ~= 0 then

          if not ClickSound then

            local NewClickSound = Instance.new("Sound");
            NewClickSound.Name = "ClickSound";
            NewClickSound.Parent = DialogueGUI;
            ClickSound = NewClickSound;
            
          end;

          ClickSoundEnabled = true;
          (ClickSound :: Sound).SoundId = "rbxassetid://" .. DefaultClickSound;

        end;

      end;

      SetupDialogueGui();
      
      if GUIDialogueContainer:IsA("GuiObject") and ResponseContainer:IsA("ScrollingFrame") and ResponseTemplate:IsA("TextButton") then

        -- Initialize the theme, then listen for changes
        API.GUI.CurrentTheme.Value = DialogueGUI;
        local ThemeChangedEvent = API.GUI.CurrentTheme.Changed:Connect(function(newTheme)

          DialogueGUI:Destroy();
          DialogueGUI = newTheme;
          SetupDialogueGui();

        end);

        -- If necessary, end conversation if player or NPC goes out of distance
        local NPCPrimaryPart = npc.PrimaryPart;
        local MaxConversationDistance = DialogueSettings.MaximumConversationDistance or (DialogueSettings.General and DialogueSettings.General.MaxConversationDistance);
        local EndConversationIfOutOfDistance = DialogueSettings.EndConversationIfOutOfDistance or (DialogueSettings.General and DialogueSettings.General.EndConversationIfOutOfDistance);
        if EndConversationIfOutOfDistance and MaxConversationDistance and NPCPrimaryPart then

          coroutine.wrap(function() 

            while task.wait() and DialogueModule.PlayerTalkingWithNPC.Value do

              if math.abs(NPCPrimaryPart.Position.Magnitude - Player.Character.PrimaryPart.Position.Magnitude) > MaxConversationDistance then

                DialogueModule.PlayerTalkingWithNPC.Value = false;
                break;

              end;

            end;

          end)();

        end;

        -- Show the dialouge to the player
        local DialoguePriority = "1";
        local rootDialogueScript = NPCDialogueContainer:FindFirstChild("1");
        local currentDialogueScript = rootDialogueScript; -- was currentDirectory
        while DialogueModule.PlayerTalkingWithNPC.Value and task.wait() do

          -- Get the current directory.
          currentDialogueScript = API.Dialogue.goToDirectory(rootDialogueScript, DialoguePriority:split("."));
          local currentDialogueProperties = require(currentDialogueScript) :: any;

          if currentDialogueProperties.type == "redirect" and RemoteConnections.PlayerPassesCondition:InvokeServer(npc, currentDialogueScript) then

            -- A redirect is available, so let's switch priorities.
            local DialoguePriorityPath = currentDialogueProperties.content:split(".");
            table.remove(DialoguePriorityPath, 1);
            DialoguePriority = table.concat(DialoguePriorityPath, ".");
            RemoteConnections.ExecuteAction:InvokeServer(npc, currentDialogueScript, "After");
            currentDialogueScript = rootDialogueScript;

          elseif RemoteConnections.PlayerPassesCondition:InvokeServer(npc, currentDialogueScript) then

            -- A message is available, so let's display it.
            -- First, let's run the preceding action.
            RemoteConnections.ExecuteAction:InvokeServer(npc, currentDialogueScript, "Preceding");
            
            -- Get a list of responses from the dialogue.
            local responses: {{ModuleScript: ModuleScript; properties: any}} = {};
            for _, PossibleResponse in ipairs(currentDialogueScript:GetChildren()) do
              
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
              API.Dialogue.ClearResponses(ResponseContainer);

              -- Use the text container with responses.
              TextContainer = NPCTextContainerWithResponses;
              NPCTextContainerWithResponses.Visible = true;
              NPCTextContainerWithoutResponses.Visible = false;
              ResponsesEnabled = true;

            else

              -- Use the text container without responses.
              TextContainer = NPCTextContainerWithoutResponses;
              NPCTextContainerWithoutResponses.Visible = true;
              NPCTextContainerWithResponses.Visible = false;
              ResponseContainer.Visible = false;

            end;
            
            -- Ensure we have a text container line.
            local textContainerLine: TextLabel? = TextContainer:FindFirstChild("Line") :: TextLabel;
            assert(textContainerLine, "Line not found.");

            -- Make the NPC stop talking if the player clicks the frame
            local NPCTalking = true;
            local WaitingForResponse = true;
            local Skipped = false;
            local FullMessageText = "";
            local NPCPaused = false;
            local ContinueDialogue;
            local Pointer = 1;
            local PointerBefore = 1;
            ContinueDialogue = function(keybind)

              -- Ensure the player is holding the key.
              if keybind and not UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKey) and not UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKeyGamepad) then

                return;

              end;

              -- Temporarily remove the keybind so that the player doesn't skip the next message.
              ContextActionService:UnbindAction("ContinueDialogue");

              if NPCTalking then

                if ClickSoundEnabled and ClickSound then

                  ClickSound:Play();

                end;

                if NPCPaused then

                  NPCPaused = false;

                end;

                if DialogueSettings.AllowPlayerToSkipDelay or (DialogueSettings.General and DialogueSettings.General.AllowPlayerToSkipDelay) then

                  -- Replace the incomplete dialogue with the full text
                  textContainerLine.MaxVisibleGraphemes = -1;
                  Pointer = PointerBefore + textContainerLine.ContentText:len();

                end;

                ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, Keybinds.DefaultChatContinueKey, Keybinds.DefaultChatContinueKeyGamepad);

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

            if Keybinds.KeybindsEnabled then

              local KEYS_PRESSED = UserInputService:GetKeysPressed();
              local KeybindPressed = false;
              if UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKey) or UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKeyGamepad) then

                coroutine.wrap(function()

                  while UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKey) or UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKeyGamepad) do

                    task.wait();

                  end;
                  ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, Keybinds.DefaultChatContinueKey, Keybinds.DefaultChatContinueKeyGamepad);

                end)();

              else

                ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, Keybinds.DefaultChatContinueKey, Keybinds.DefaultChatContinueKeyGamepad);

              end;

            end;

            -- Put the letters of the message together for an animation effect
            DialogueGUI.Enabled = true;
            local Position = 0;
            local Adding = false;
            local MessageTextWithPauses = currentDialogueProperties.content;

            -- Clone the TextLabel.
            local TempLine: TextLabel = textContainerLine:Clone();
            TempLine.Name = "LineTest";
            TempLine.Visible = false;
            TempLine.Parent = TextContainer;

            local MessageText, PausePoints = API.Dialogue.retrievePausePoints(MessageTextWithPauses, TempLine);
            local DividedText = API.Dialogue.DivideTextToFitBox(MessageText, TempLine);
            TempLine:Destroy();

            for index, page in ipairs(DividedText) do

              -- Now we can get the new text
              PointerBefore = Pointer;
              FullMessageText = page;
              textContainerLine.Text = FullMessageText;
              for count = 0, textContainerLine.Text:len() do

                textContainerLine.MaxVisibleGraphemes = count;

                task.wait(PausePoints[Pointer] or DialogueSettings.LetterDelay or (DialogueSettings.General and DialogueSettings.General.LetterDelay));

                if textContainerLine.MaxVisibleGraphemes == -1 then 

                  break;

                end

                Pointer += 1;

              end;

              if DividedText[index + 1] and NPCTalking then

                -- Wait for the player to click
                local ClickToContinueButton = GUIDialogueContainer:FindFirstChild("ClickToContinue") :: GuiButton;
                ClickToContinueButton.Visible = true;
                NPCPaused = true;
                while NPCPaused and NPCTalking and DialogueModule.PlayerTalkingWithNPC.Value do 

                  task.wait();

                end;

                -- Let the NPC speak again
                ClickToContinueButton.Visible = false;
                NPCPaused = false;

              end;

            end;
            NPCTalking = false;

            local chosenResponse;
            if ResponsesEnabled and DialogueModule.PlayerTalkingWithNPC.Value then

              -- Sort responses because :GetChildren() doesn't guarantee it
              table.sort(responses, function(folder1, folder2)

                return folder1.ModuleScript.Name < folder2.ModuleScript.Name;

              end);

              -- Add response buttons
              for _, response in ipairs(responses) do

                if RemoteConnections.PlayerPassesCondition:InvokeServer(npc, response) then

                  local ResponseButton = ResponseTemplate:Clone();
                  ResponseButton.Name = "Response";
                  ResponseButton.Text = response.properties.content;
                  ResponseButton.Parent = ResponseContainer;
                  ResponseButton.MouseButton1Click:Connect(function()
                    
                    -- Acknowledge that the player clicked the button.
                    print("[Dialogue Maker] [Response] " .. Player.Name .. " (" .. Player.UserId .. "): " .. ResponseButton.Text);
                    ResponseContainer.Visible = false;
                    
                    if ClickSoundEnabled and ClickSound then

                      ClickSound:Play();

                    end;

                    chosenResponse = response;
                    
                    -- Run the succeeding response.
                    RemoteConnections.ExecuteAction:InvokeServer(npc, response, "Succeeding");

                    WaitingForResponse = false;

                  end);

                end;

              end;

              ResponseContainer.CanvasSize = UDim2.new(0, ResponseContainer.CanvasSize.X.Offset, 0, (ResponseContainer:FindFirstChild("UIListLayout") :: UIListLayout).AbsoluteContentSize.Y);
              ResponseContainer.Visible = true;

            end;

            -- Run the timeout code in the background
            coroutine.wrap(function()

              local ConversationTimeoutInSeconds: number? = DialogueSettings.ConversationTimeoutInSeconds or (DialogueSettings.General and DialogueSettings.General.ConversationTimeoutInSeconds);
              local TimeoutEnabled = DialogueSettings.TimeoutEnabled or (DialogueSettings.General and DialogueSettings.General.TimeoutEnabled);
              if TimeoutEnabled and ConversationTimeoutInSeconds then

                -- Wait for the player if the developer wants to
                local WaitForResponse = DialogueSettings.WaitForResponse or (DialogueSettings.General and DialogueSettings.General.WaitForResponse);
                if ResponsesEnabled and WaitForResponse then

                  return;

                end;

                -- Wait the timeout set by the developer
                task.wait(ConversationTimeoutInSeconds);
                WaitingForResponse = false;

              end;

            end)();

            while WaitingForResponse and DialogueModule.PlayerTalkingWithNPC.Value do

              task.wait();

            end;

            -- Run after action
            if currentDialogueProperties.hasSucceedingAction and DialogueModule.PlayerTalkingWithNPC.Value then

              RemoteConnections.ExecuteAction:InvokeServer(npc, currentDialogueScript, "Succeeding");

            end;

            -- Check if there is more dialogue.
            local hasPossibleDialogue = false;
            for _, PossibleDialogue in ipairs((if chosenResponse then chosenResponse.ModuleScript else currentDialogueScript):GetChildren()) do

              local DialogueType = PossibleDialogue:GetAttribute("DialogueType");
              if PossibleDialogue:IsA("ModuleScript") and tonumber(PossibleDialogue.Name) and (DialogueType == "Message" or DialogueType == "Redirect") then

                hasPossibleDialogue = true;
                break;

              end

            end
            
            if DialogueModule.PlayerTalkingWithNPC.Value and hasPossibleDialogue then

              DialoguePriority = if chosenResponse then string.sub(chosenResponse.ModuleScript.Name .. ".1", 3) else DialoguePriority .. ".1";
              currentDialogueScript = rootDialogueScript;

            else

              DialogueGUI:Destroy();
              DialogueModule.PlayerTalkingWithNPC.Value = false;

            end;

          elseif DialogueModule.PlayerTalkingWithNPC.Value then

            -- There is a message; however, the player failed the condition.
            -- Let's check if there's something else available.
            local SplitPriority = DialoguePriority:split(".");
            SplitPriority[#SplitPriority] = tostring(tonumber(SplitPriority[#SplitPriority]) :: number + 1);
            DialoguePriority = table.concat(SplitPriority, ".");

          end;

        end;

        -- Free the player :)
        ThemeChangedEvent:Disconnect();
        API.Triggers.enableAllSpeechBubbles();
        API.Triggers.enableAllClickDetectors();
        API.Triggers.enableAllProximityPrompts();
        if FreezePlayer then 

          API.Player.unfreezePlayer(); 

        end;
        
      end
      
    end);
    
    DialogueModule.PlayerTalkingWithNPC.Value = false;
    
    if not ranSuccessfully then
      
      error("[Dialogue Maker] " .. errorMessage);
      
    end

  end;

end;

return DialogueModule;
