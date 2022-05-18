-- Get Roblox services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local RunService = game:GetService("RunService");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");
local Players = game:GetService("Players");
local Player = Players.LocalPlayer;

-- Prepare these methods
local DialogueModule = {

  PlayerTalkingWithNPC = script.PlayerTalkingWithNPC; 

};

local API;
function DialogueModule._setAPI(api)
  
  API = api;
  
end

function DialogueModule.GoToDirectory(currentDirectory: Folder, targetPath: {string}): Folder

  local CurrentPath = "1";
  for index, directory in ipairs(targetPath) do

    CurrentPath = CurrentPath .. "." .. directory;
    local Folders = {};
    for _, folderName in ipairs({"Dialogue", "Responses", "Redirects"}) do

      Folders[folderName] = currentDirectory:FindFirstChild(folderName);
      assert(Folders[folderName], "[Dialogue Maker]: The " .. folderName .. " folder is missing from " .. CurrentPath);

    end;

    currentDirectory = (Folders.Dialogue:FindFirstChild(directory) and Folders.Dialogue[directory]) 
      or (Folders.Responses:FindFirstChild(directory) and Folders.Responses[directory]) 
      or (Folders.Redirects:FindFirstChild(directory) and Folders.Redirects[directory]) 
      or currentDirectory:FindFirstChild(directory);

  end;

  return currentDirectory;

end;

function DialogueModule.ReplaceVariablesWithValues(npc: Model, text: string): string

  for match in string.gmatch(text, "%[/variable=(.+)%]") do

    -- Get the match from the server
    local VariableValue = RemoteConnections.GetVariable:InvokeServer(npc, match);
    if VariableValue then

      text = text:gsub("%[/variable=(.+)%]", VariableValue);

    end;

  end;

  return text;

end;

function DialogueModule.ClearResponses(responseContainer: Folder)

  for _, response in ipairs(responseContainer:GetChildren()) do

    if not response:IsA("UIListLayout") then

      response:Destroy();

    end;

  end;

end;

function DialogueModule.DivideTextToFitBox(text: string, textContainer: Frame): {{[number]: string}?}

  local Line = textContainer:FindFirstChild("Line"):Clone();
  Line.Name = "LineTest";
  Line.Visible = false;
  Line.Parent = textContainer;

  local Divisions = {};
  local Page = 1;
  for index, word in ipairs(text:split(" ")) do

    if index == 1 then

      Line.Text = word;

    else

      Line.Text = Line.Text .. " " .. word;

    end;

    if not Divisions[Page] then Divisions[Page] = {}; end;

    if Line.TextFits then

      table.insert(Divisions[Page],word);
      Divisions[Page].FullText = Line.Text;

    elseif not Divisions[Page][1] then

      Line.Text = "";
      for _, letter in ipairs(word:split("")) do

        Line.Text = Line.Text .. letter;
        if not Line.TextFits then

          -- Remove the letter from the text
          Line.Text = Line.Text:sub(1,string.len(Line.Text)-1);
          table.insert(Divisions[Page], Line.Text);
          Divisions[Page].FullText = Line.Text;

          -- Take it from the top
          Page = Page + 1;
          Divisions[Page] = {};
          Line.Text = letter;

        end;

      end;

      table.insert(Divisions[Page], Line.Text);
      Divisions[Page].FullText = Line.Text;

    else

      Page = Page + 1;

    end;

  end;

  Line:Destroy();

  return Divisions;

end;

local Events = {};
local DefaultClickSound = RemoteConnections.GetDefaultClickSound:InvokeServer();
local Keybinds = RemoteConnections.GetKeybinds:InvokeServer();
local DefaultMinDistance = RemoteConnections.GetMinimumDistanceFromCharacter:InvokeServer();
function DialogueModule.ReadDialogue(npc: Model)

  -- Make sure we aren't already talking to an NPC
  if not DialogueModule.PlayerTalkingWithNPC.Value then

    -- Make sure we can't talk to another NPC
    DialogueModule.PlayerTalkingWithNPC.Value = true;
    API.Triggers.DisableAllSpeechBubbles();
    API.Triggers.DisableAllClickDetectors();
    API.Triggers.DisableAllProximityPrompts();

    -- Set up variables we're gonna use
    local NPCPrimaryPart = npc.PrimaryPart;
    local DialogueContainer = npc:FindFirstChild("DialogueContainer");
    local DialogueSettings = require(DialogueContainer.Settings);
    local DialogueGui = API.GUI.CreateNewDialogueGui(DialogueSettings.Theme or (DialogueSettings.General and DialogueSettings.General.ThemeName));
    local FreezePlayer = DialogueSettings.FreezePlayer or (DialogueSettings.General and DialogueSettings.General.FreezePlayer);
    local MaxConversationDistance = DialogueSettings.MaximumConversationDistance or (DialogueSettings.General and DialogueSettings.General.MaxConversationDistance);
    local EndConversationIfOutOfDistance = DialogueSettings.EndConversationIfOutOfDistance or (DialogueSettings.General and DialogueSettings.General.EndConversationIfOutOfDistance);
    local NPCName = DialogueSettings.Name or (DialogueSettings.General and DialogueSettings.General.NPCName);
    local FitName = DialogueSettings.General and DialogueSettings.General.FitName;
    local TextBoundsOffset = (DialogueSettings.General and DialogueSettings.General.TextBoundsOffset) or 30;
    local AllowPlayerToSkipDelay = DialogueSettings.AllowPlayerToSkipDelay or (DialogueSettings.General and DialogueSettings.General.AllowPlayerToSkipDelay);
    local LetterDelay = DialogueSettings.LetterDelay or (DialogueSettings.General and DialogueSettings.General.LetterDelay);
    local TimeoutEnabled = DialogueSettings.TimeoutEnabled or (DialogueSettings.General and DialogueSettings.General.TimeoutEnabled);
    local ConversationTimeoutInSeconds = DialogueSettings.ConversationTimeoutInSeconds or (DialogueSettings.General and DialogueSettings.General.ConversationTimeoutInSeconds);
    local WaitForResponse = DialogueSettings.WaitForResponse or (DialogueSettings.General and DialogueSettings.General.WaitForResponse);
    local ResponseContainer, ResponseTemplate, ClickSound, ClickSoundEnabled, OldDialogueGui;

    -- If necessary, freeze the player
    if FreezePlayer then 

      API.Player.FreezePlayer(); 

    end;

    -- Set the theme and prepare the response template
    local function SetupDialogueGui()

      local NPCNF = DialogueGui.DialogueContainer.NPCNameFrame;

      -- Set up responses
      DialogueGui.Parent = Player:WaitForChild("PlayerGui");
      ResponseContainer = DialogueGui.DialogueContainer.ResponseContainer;
      ResponseTemplate = ResponseContainer.ResponseTemplate:Clone();

      -- Set NPC name
      NPCNF.Visible = typeof(NPCName) == "string" and NPCName ~= "";
      NPCNF.NPCName.Text = NPCName or "";
      if FitName then
        NPCNF.Size = UDim2.new(NPCNF.Size.X.Scale, NPCNF.NPCName.TextBounds.X + TextBoundsOffset, NPCNF.Size.Y.Scale, NPCNF.Size.Y.Offset);
      end;

      -- Setup click sound
      ClickSound = DialogueGui:FindFirstChild("ClickSound");
      ClickSoundEnabled = false;
      if DefaultClickSound and DefaultClickSound ~= 0 then

        if not ClickSound then

          ClickSound = Instance.new("Sound");
          ClickSound.Name = "ClickSound";
          ClickSound.Parent = DialogueGui;

        end;

        ClickSoundEnabled = true;
        DialogueGui.ClickSound.SoundId = "rbxassetid://" .. DefaultClickSound;

      end;

    end;

    SetupDialogueGui();
    API.GUI.CurrentTheme.Value = DialogueGui;

    -- Listen to theme changes
    local ThemeChangedEvent = API.GUI.CurrentTheme.Changed:Connect(function(newTheme)

      DialogueGui:Destroy();
      DialogueGui = newTheme;
      SetupDialogueGui();

    end);

    -- If necessary, end conversation if player or NPC goes out of distance
    if EndConversationIfOutOfDistance and MaxConversationDistance and NPCPrimaryPart then

      coroutine.wrap(function() 

        while RunService.Heartbeat:Wait() and DialogueModule.PlayerTalkingWithNPC.Value do

          if math.abs(NPCPrimaryPart.Position.Magnitude - Player.Character.PrimaryPart.Position.Magnitude) > MaxConversationDistance then

            DialogueModule.PlayerTalkingWithNPC.Value = false;
            break;

          end;

        end;

      end)();

    end;

    -- Show the dialouge to the player
    local DialoguePriority = "1";
    local RootDirectory = DialogueContainer["1"];
    local CurrentDirectory = RootDirectory;
    while DialogueModule.PlayerTalkingWithNPC.Value and game:GetService("RunService").Heartbeat:Wait() do

      CurrentDirectory = API.Dialogue.GoToDirectory(RootDirectory, DialoguePriority:split("."));

      if CurrentDirectory.Redirect.Value and RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then

        local DialoguePriorityPath = CurrentDirectory.RedirectPriority.Value:split(".");
        table.remove(DialoguePriorityPath, 1);
        DialoguePriority = table.concat(DialoguePriorityPath, ".");
        RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "After");
        CurrentDirectory = RootDirectory;

      elseif RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then

        local MessageText = API.Dialogue.ReplaceVariablesWithValues(npc, CurrentDirectory.Message.Value);
        local ThemeDialogueContainer = DialogueGui.DialogueContainer;
        local ResponsesEnabled = false;
        local NPCTalking = true;
        local WaitingForResponse = true;
        local Skipped = false;
        local FullMessageText = "";
        local Message = "";
        local NPCPaused = false;
        local ImportantPositions = {};
        local Position = 0;
        local Adding = false;
        local TextContainer, ContinueDialogue, ResponseChosen, DividedText;

        -- Run the before action if there is one
        if CurrentDirectory.HasBeforeAction.Value then
          RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "Before");
        end;

        if #CurrentDirectory.Responses:GetChildren() > 0 then

          API.Dialogue.ClearResponses(ResponseContainer);

          TextContainer = ThemeDialogueContainer.NPCTextContainerWithResponses;
          ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = true;
          ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = false;
          ResponsesEnabled = true;

        else

          TextContainer = ThemeDialogueContainer.NPCTextContainerWithoutResponses;
          ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = true;
          ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = false;
          ThemeDialogueContainer.ResponseContainer.Visible = false;

        end;
        DividedText = API.Dialogue.DivideTextToFitBox(MessageText, TextContainer);

        -- Make the NPC stop talking if the player clicks the frame
        ContinueDialogue = function(keybind)

          -- Make sure key is down
          if keybind and not UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKey) and not UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKeyGamepad) then

            return;

          end;

          ContextActionService:UnbindAction("ContinueDialogue");
          if NPCTalking then

            if ClickSoundEnabled then

              ClickSound:Play();

            end;

            if NPCPaused then

              NPCPaused = false;

            end;

            -- Check settings set by the developer
            if AllowPlayerToSkipDelay then

              -- Replace the incomplete dialogue with the full text
              TextContainer.Line.Text = FullMessageText;
              Skipped = true;

            end;

            ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, Keybinds.DefaultChatContinueKey, Keybinds.DefaultChatContinueKeyGamepad);

          elseif #CurrentDirectory.Responses:GetChildren() == 0 then	

            WaitingForResponse = false;

          end;
        end;

        Events.DialogueClicked = ThemeDialogueContainer.InputBegan:Connect(function(input)

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

                RunService.Heartbeat:Wait();

              end;
              ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, Keybinds.DefaultChatContinueKey, Keybinds.DefaultChatContinueKeyGamepad);

            end)();

          else

            ContextActionService:BindAction("ContinueDialogue", ContinueDialogue, false, Keybinds.DefaultChatContinueKey, Keybinds.DefaultChatContinueKeyGamepad);

          end;

        end;

        -- Put the letters of the message together for an animation effect
        if TextContainer.Line.RichText then

          -- TODO: find a way to mix rich text syntax with fonts
          local TagContentPattern = "<([^<>]-)>(.-)</";
          local TagStart, TagEnd, Tag, Content, Value, Attribute, NewPattern;
          local function UpdateTagData(str)

            -- Find the tag
            local _TagStart, _, _Tag, _ = str:find(TagContentPattern);

            if _TagStart then

              local _Attribute, _Value = nil, nil;
              if _Tag:find(" ") then

                -- Get the real tag
                local Split1 = _Tag:split(" ");
                _Tag = Split1[1];

                -- Get the real attribute and value
                local Split2 = Split1[2]:split("=");
                _Attribute, _Value = Split2[1], Split2[2];

              end

              -- Make a new pattern based on the tag we have
              local _NewPattern = TagContentPattern .. _Tag .. ">";
              local _, _TagEnd, _, _Content = str:find(_NewPattern);

              return _TagStart, _TagEnd, _Tag, _Content, _Attribute, _Value, _NewPattern;

            end;

          end;

          TagStart, TagEnd, Tag, Content, Attribute, Value, NewPattern = UpdateTagData(MessageText);

          while TagStart do

            local TagGroup = MessageText:sub(TagStart, TagEnd);
            local ContentStart, ContentEnd = TagGroup:find(Content, 1, true);

            -- Get the sub-tags inside the first one
            if not ImportantPositions[TagStart] then

              ImportantPositions[TagStart] = {};

            end;

            local ETagStart, ETagEnd, ETag, EContent, EAttr, EVal, EPattern = UpdateTagData(Content);
            while ETagStart do

              -- Add the sub tag to the table
              table.insert(ImportantPositions[TagStart], {ETag .. (EVal and (" " .. EAttr .. '=' .. EVal) or "")});

              -- Scrub the tag from the content + length
              Content = Content:gsub(Content:sub(ETagStart, ETagEnd), EContent);

              ETagStart, ETagEnd, ETag, EContent, EAttr, EVal, EPattern = UpdateTagData(Content);

            end;

            -- Change all the final content lengths
            local ContentLength = TagStart + Content:len() - 1;
            for i, _ in ipairs(ImportantPositions[TagStart]) do

              ImportantPositions[TagStart][i][2] = ContentLength;

            end;

            -- Add the main tag to the table
            table.insert(ImportantPositions[TagStart], {Tag .. (Value and (" " .. Attribute .. '=' .. Value) or ""), ContentLength});

            -- Scrub the tags from the original text
            MessageText = MessageText:gsub(TagGroup, Content, 1);

            -- Check if there's any more tags
            TagStart, TagEnd, Tag, Content, Attribute, Value, NewPattern = UpdateTagData(MessageText);

          end;

        end;

        DialogueGui.Enabled = true;
        for index, page in ipairs(DividedText) do

          -- Now we can get the new text
          FullMessageText = page.FullText;
          for wordIndex, word in ipairs(page) do 

            local Extras = "";

            if wordIndex ~= 1 then 

              Position += 1; 
              if Adding then

                ImportantPositions[Position + 1] = ImportantPositions[Position];
                Adding = false;

              end;
              Message = Message .. " ";

            end;

            for _, letter in ipairs(word:split("")) do

              Adding = false;

              -- Check if the player wants to skip their dialogue
              if Skipped or not NPCTalking or not DialogueModule.PlayerTalkingWithNPC.Value then

                break;

              end;

              Position += 1;
              local IP = ImportantPositions[Position];  
              if IP then

                local Replacement = letter;

                for _, tag in ipairs(IP) do

                  if not tag.OriginalPosition then

                    tag.OriginalPosition = Position;
                    Replacement = "<" .. tag[1] .. ">" .. Replacement .. ((Position == tag[2] and "</" .. tag[1]:match("%a+") .. ">") or "");

                  end;
                  if Position < tag[2] then 

                    Extras = Extras .. "</" .. tag[1]:match("%a+") .. ">";
                    if not ImportantPositions[Position + 1] then

                      ImportantPositions[Position + 1] = {};

                    end;
                    table.insert(ImportantPositions[Position + 1], tag);
                    Adding = true;

                  elseif tag.OriginalPosition ~= Position and Position == tag[2] then

                    Replacement = Replacement .. "</" .. tag[1]:match("%a+") .. ">";

                  end;

                end;
                Message = Message .. Replacement;

              else 

                Message = Message .. letter;

              end;
              TextContainer.Line.Text = Message .. Extras;
              Extras = "";
              wait(LetterDelay);

            end;

          end;

          if DividedText[index+1] and NPCTalking then

            -- Wait for the player to click
            ThemeDialogueContainer.ClickToContinue.Visible = true;
            NPCPaused = true;
            while NPCPaused and NPCTalking and DialogueModule.PlayerTalkingWithNPC.Value do 

              game:GetService("RunService").Heartbeat:Wait();

            end;

            -- Don't carry the old text in the next message
            Message = "";

            -- Let the NPC speak again
            ThemeDialogueContainer.ClickToContinue.Visible = false;
            NPCPaused = false;
            Skipped = false;

          end;

        end;
        NPCTalking = false;

        if ResponsesEnabled and DialogueModule.PlayerTalkingWithNPC.Value then

          -- Sort response folders, because :GetChildren() doesn't guarantee it
          local ResponseFolders = CurrentDirectory.Responses:GetChildren();
          table.sort(ResponseFolders, function(folder1, folder2)
            return folder1.Name < folder2.Name;
          end);

          -- Add response buttons
          for _, response in ipairs(ResponseFolders) do

            if RemoteConnections.PlayerPassesCondition:InvokeServer(npc,response) then

              local ResponseButton = ResponseTemplate:Clone();
              ResponseButton.Name = "Response";
              ResponseButton.Text = response.Message.Value;
              ResponseButton.Parent = ResponseContainer;
              ResponseButton.MouseButton1Click:Connect(function()

                if ClickSoundEnabled then

                  ClickSound:Play();

                end;

                ResponseContainer.Visible = false;
                ResponseChosen = response;

                if response.HasAfterAction.Value then

                  RemoteConnections.ExecuteAction:InvokeServer(npc, response, "After");

                end;

                WaitingForResponse = false;

              end);

            end;

          end;

          ResponseContainer.CanvasSize = UDim2.new(0, ResponseContainer.CanvasSize.X, 0, ResponseContainer.UIListLayout.AbsoluteContentSize.Y);
          ThemeDialogueContainer.ResponseContainer.Visible = true;

        end;

        -- Run the timeout code in the background
        coroutine.wrap(function()

          if TimeoutEnabled and ConversationTimeoutInSeconds then

            -- Wait for the player if the developer wants to
            if ResponsesEnabled and WaitForResponse then

              return;

            end;

            -- Wait the timeout set by the developer
            wait(ConversationTimeoutInSeconds);
            WaitingForResponse = false;

          end;

        end)();

        while WaitingForResponse and DialogueModule.PlayerTalkingWithNPC.Value do
          game:GetService("RunService").Heartbeat:Wait();
        end;

        -- Run after action
        if CurrentDirectory.HasAfterAction.Value and DialogueModule.PlayerTalkingWithNPC.Value then

          RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "After");

        end;

        if ResponseChosen and DialogueModule.PlayerTalkingWithNPC.Value then

          if (#ResponseChosen.Dialogue:GetChildren() ~= 0 or #ResponseChosen.Redirects:GetChildren() ~= 0) then

            DialoguePriority = string.sub(ResponseChosen.Priority.Value..".1",3);
            CurrentDirectory = RootDirectory;

          else

            DialogueGui:Destroy();
            DialogueModule.PlayerTalkingWithNPC.Value = false;

          end;

        else

          -- Check if there is more dialogue
          if DialogueModule.PlayerTalkingWithNPC.Value and (#CurrentDirectory.Dialogue:GetChildren() ~= 0 or #CurrentDirectory.Redirects:GetChildren() ~= 0) then

            DialoguePriority = DialoguePriority..".1";
            CurrentDirectory = RootDirectory;

          else

            DialogueGui:Destroy();
            DialogueModule.PlayerTalkingWithNPC.Value = false;

          end;

        end;

      elseif DialogueModule.PlayerTalkingWithNPC.Value then

        local SplitPriority = DialoguePriority:split(".");
        SplitPriority[#SplitPriority] = SplitPriority[#SplitPriority] + 1;
        DialoguePriority = table.concat(SplitPriority,".");

      end;

    end;

    -- Free the player :)
    ThemeChangedEvent:Disconnect();
    API.Triggers.EnableAllSpeechBubbles();
    API.Triggers.EnableAllClickDetectors();
    API.Triggers.EnableAllProximityPrompts();
    if FreezePlayer then 

      API.Player.UnfreezePlayer(); 

    end;

  end;

end;

return DialogueModule;