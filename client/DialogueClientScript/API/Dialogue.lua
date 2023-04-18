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
      
      -- Get the current directory.
      CurrentDirectory = API.Dialogue.GoToDirectory(RootDirectory, DialoguePriority:split("."));
      
      if CurrentDirectory.Redirect.Value and RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then
        
        -- A redirect is available, so let's switch priorities.
        local DialoguePriorityPath = CurrentDirectory.RedirectPriority.Value:split(".");
        table.remove(DialoguePriorityPath, 1);
        DialoguePriority = table.concat(DialoguePriorityPath, ".");
        RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "After");
        CurrentDirectory = RootDirectory;
       
      elseif RemoteConnections.PlayerPassesCondition:InvokeServer(npc, CurrentDirectory) then
        
        -- A message is available, so let's display it.
        -- If there's a before action, run it.
        if CurrentDirectory.HasBeforeAction.Value then
          
          RemoteConnections.ExecuteAction:InvokeServer(npc, CurrentDirectory, "Before");
          
        end;
        
        -- Determine which text container we should use.
        local ThemeDialogueContainer = DialogueGui.DialogueContainer;
        local ResponsesEnabled = false;
        local TextContainer;
        if #CurrentDirectory.Responses:GetChildren() > 0 then
          
          -- Clear the text container just in case there was some responses left behind.
          API.Dialogue.ClearResponses(ResponseContainer);
          
          -- Use the text container with responses.
          TextContainer = ThemeDialogueContainer.NPCTextContainerWithResponses;
          ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = true;
          ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = false;
          ResponsesEnabled = true;

        else
          
          -- Use the text container without responses.
          TextContainer = ThemeDialogueContainer.NPCTextContainerWithoutResponses;
          ThemeDialogueContainer.NPCTextContainerWithoutResponses.Visible = true;
          ThemeDialogueContainer.NPCTextContainerWithResponses.Visible = false;
          ThemeDialogueContainer.ResponseContainer.Visible = false;

        end;

        -- Make the NPC stop talking if the player clicks the frame
        local NPCTalking = true;
        local WaitingForResponse = true;
        local Skipped = false;
        local FullMessageText = "";
        local NPCPaused = false;
        local ContinueDialogue;
        ContinueDialogue = function(keybind)

          -- Ensure the player is holding the key.
          if keybind and not UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKey) and not UserInputService:IsKeyDown(Keybinds.DefaultChatContinueKeyGamepad) then

            return;

          end;
          
          -- Temporarily remove the keybind so that the player doesn't skip the next message.
          ContextActionService:UnbindAction("ContinueDialogue");
          
          if NPCTalking then

            if ClickSoundEnabled then

              ClickSound:Play();

            end;

            if NPCPaused then

              NPCPaused = false;

            end;

            if AllowPlayerToSkipDelay then

              -- Replace the incomplete dialogue with the full text
              TextContainer.Line.MaxVisibleGraphemes = -1;
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
        DialogueGui.Enabled = true;
        local Message = "";
        local Position = 0;
        local Adding = false;
        local MessageText = API.Dialogue.ReplaceVariablesWithValues(npc, CurrentDirectory.Message.Value);
        local DividedText = API.Dialogue.DivideTextToFitBox(MessageText, TextContainer);
        for index, page in ipairs(DividedText) do

          -- Now we can get the new text
          FullMessageText = page.FullText;
          TextContainer.Line.Text = FullMessageText;
          for count = 0, TextContainer.Line.Text:len() do
            
            TextContainer.Line.MaxVisibleGraphemes = count;
            wait(LetterDelay);

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
        
        local ResponseChosen;
        if ResponsesEnabled and DialogueModule.PlayerTalkingWithNPC.Value then

          -- Sort response folders, because :GetChildren() doesn't guarantee it
          local ResponseFolders = CurrentDirectory.Responses:GetChildren();
          table.sort(ResponseFolders, function(folder1, folder2)
            
            return folder1.Name < folder2.Name;
            
          end);

          -- Add response buttons
          for _, response in ipairs(ResponseFolders) do

            if RemoteConnections.PlayerPassesCondition:InvokeServer(npc, response) then

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
        
        -- There is a message; however, the player failed the condition.
        -- Let's check if there's something else available.
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
