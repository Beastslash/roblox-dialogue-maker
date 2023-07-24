--!strict
local Selection = game:GetService("Selection");
local StarterPlayer = game:GetService("StarterPlayer");
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");
local ChangeHistoryService = game:GetService("ChangeHistoryService");

-- Make sure we have all of the plugin GUI stuff.
local DialogueMakerFrame: Frame = script.DialogueMakerGUI.MainFrame:Clone();
assert(DialogueMakerFrame, "[Dialogue Maker] Couldn't start because DialogueMakerGUI lacks a MainFrame. Try reinstalling the plugin.");

local DialogueContainer: Frame = DialogueMakerFrame:FindFirstChild("DialogueContainer") :: Frame;
assert(DialogueContainer, "[Dialogue Maker] Couldn't start because MainFrame lacks a DialogueContainer. Try reinstalling the plugin.");

local DialogueMessageList: ScrollingFrame = DialogueContainer:FindFirstChild("DialogueMessageList") :: ScrollingFrame;
assert(DialogueMessageList, "[Dialogue Maker] Couldn't start because DialogueContainer lacks a DialogueMessageList. Try reinstalling the plugin.");

local DialogueMessageTemplate: Frame = DialogueMessageList:FindFirstChild("DialogueMessageTemplate") :: Frame;
assert(DialogueMessageList, "[Dialogue Maker] Couldn't start because DialogueMessageList lacks a DialogueMessageTemplate. Try reinstalling the plugin.");
local DialogueMessageTemplateClone: Frame = (DialogueMessageTemplate :: Frame):Clone();
(DialogueMessageTemplate :: Frame):Destroy();
DialogueMessageTemplate = DialogueMessageTemplateClone;

local Tools: Frame = DialogueMakerFrame:FindFirstChild("Tools") :: Frame;
assert(Tools, "[Dialogue Maker] Couldn't start because DialogueMakerGUI lacks Tools. Try reinstalling the plugin.");

local CurrentDialogueContainer: ModuleScript?;
local Model;
local viewingPriority = "";
local function repairNPC(): ()

  if not Model:FindFirstChild("DialogueContainer") then

    -- Add the dialogue container to the NPC
    local DialogueContainer = Instance.new("Folder");
    DialogueContainer.Name = "DialogueContainer";

    -- Add the dialogue folder to the model
    DialogueContainer.Parent = Model;
    viewingPriority = "";

    return;

  end;

  CurrentDialogueContainer = Model:FindFirstChild("DialogueContainer") :: ModuleScript;
  assert(CurrentDialogueContainer, "[Dialogue Maker] DialogueContainer not found...");
  
  if not Model:FindFirstChild("NPCDialogueSettings") then

    print("[Dialogue Maker] Adding settings script to "..Model.Name)

    local SettingsScript = script.NPCSettingsTemplate:Clone();
    SettingsScript.Name = "NPCDialogueSettings";
    SettingsScript.Parent = Model;

    print("[Dialogue Maker] Added settings script to "..Model.Name)

  end;

  -- Check if they're registered on the sevrer
  local DialogueServerScript = ServerScriptService:FindFirstChild("DialogueServerScript");

  assert(DialogueServerScript, "[Dialogue Maker] DialogueServerScript wasn't found in the ServerScriptService! \nPlease replace the script by pressing the \"Fix Scripts\" button.");

  local NPCRegistered;
  for _, dialogueLocation in ipairs(DialogueServerScript.DialogueLocations:GetChildren()) do
    
    if dialogueLocation.Value == Model then
      
      NPCRegistered = true;
      break;
      
    end
    
  end;

  if not NPCRegistered then
    
    -- Add this model to the DialogueManager
    local DialogueLocation = Instance.new("ObjectValue");
    DialogueLocation.Value = Model;
    DialogueLocation.Name = "DialogueLocation";
    DialogueLocation.Parent = DialogueServerScript.DialogueLocations;
    
  end

end;

type EventTypes = {
  AddMessage: RBXScriptConnection?;
  AdjustSettingsRequested: RBXScriptConnection?;
  ChildAdded: RBXScriptConnection?;
  ChildRemoved: RBXScriptConnection?;
  DeleteMode: RBXScriptConnection?;
  DeleteYesButton: RBXScriptConnection?;
  DeleteNoButton: RBXScriptConnection?;
  ViewChildren: {RBXScriptConnection?};
  ViewParent: RBXScriptConnection?;
};

local Events: EventTypes = {
  ViewChildren = {};
};

local Toolbar = plugin:CreateToolbar("Dialogue Maker by Beastslash");
local EditDialogueButton = Toolbar:CreateButton("Edit Dialogue", "Edit dialogue of a selected NPC. The selected object must be a singular model.", "rbxassetid://14109181603");
local isDeleteModeEnabled = false;
local DeletePromptShown = false;
local isDialogueEditorOpen = false;
local ViewStatus = DialogueMakerFrame:FindFirstChild("ViewStatus");
local DialogueLocationStatus = ViewStatus:FindFirstChild("DialogueLocationStatus") :: TextLabel;
local ModelLocationFrame = ViewStatus:FindFirstChild("ModelLocationFrame");

type DialogueContainerClass = ModuleScript | Folder;

local function disconnectEvents(): ()
  
  for key, PossibleEvent: RBXScriptConnection | {[number]: RBXScriptConnection} in pairs(Events) do

    if typeof(PossibleEvent) == "table" then

      for _, event in ipairs(PossibleEvent) do

        event:Disconnect()

      end
      Events[key] = {};

    else

      PossibleEvent:Disconnect();
      Events[key] = nil;

    end;

  end;
  
end

-- Refreshes all events and GUI elements in the plugin.
-- @since v1.0.0
local function syncDialogueGUI(DirectoryContentScript: DialogueContainerClass): ()

  -- Make sure everything with the NPC is OK
  repairNPC();

  -- Disconnect any past event
  disconnectEvents();
  
  -- Hook some button events
  assert(CurrentDialogueContainer, "[Dialogue Maker] CurrentDialogueContainer not found");
  Events.AdjustSettingsRequested = (Tools:FindFirstChild("AdjustSettings") :: TextButton).MouseButton1Click:Connect(function()

    -- Make sure all of the important objects are in the NPC
    repairNPC();

    plugin:OpenScript(Model:FindFirstChild("NPCDialogueSettings"));

  end);
  
  Events.AddMessage = (Tools:FindFirstChild("AddMessage") :: TextButton).MouseButton1Click:Connect(function()

    local CurrentDirectory = CurrentDialogueContainer;
    
    if viewingPriority ~= "" then
      
      local path = viewingPriority:split(".");
      for _, directory in ipairs(path) do

        CurrentDirectory = CurrentDirectory:FindFirstChild(directory) :: ModuleScript;

      end;
      
    end

    -- Create the dialogue script.
    local targetPriority = 1;
    for _, Child in ipairs(CurrentDirectory:GetChildren()) do
      
      local comparedName = tonumber(Child.Name);
      if comparedName and comparedName >= targetPriority then
        
        targetPriority = comparedName + 1;
        
      end
      
    end;
    
    local MessageContentScript = script.ContentTemplate:Clone();
    MessageContentScript.Name = targetPriority;
    MessageContentScript:SetAttribute("DialogueType", "Message");
    MessageContentScript.Parent = CurrentDirectory;

    -- Now let's re-order the dialogue
    syncDialogueGUI(CurrentDirectory);

  end);
  
  if viewingPriority == "" then
    
    DialogueLocationStatus.Text = "Viewing the beginning of the conversation";
    
  else
    
    DialogueLocationStatus.Text = "Viewing " .. viewingPriority;
    
    local ViewParentButton = Tools:FindFirstChild("ViewParent") :: TextButton;
    local ViewParentTextLabel = ViewParentButton:FindFirstChild("TextLabel") :: TextLabel;
    local ViewParentImageLabel = ViewParentButton:FindFirstChild("ImageLabel") :: ImageLabel;
    Events.ViewParent = ViewParentButton.MouseButton1Click:Connect(function()
      
      local GRAY = Color3.fromRGB(149, 149, 149);
      ViewParentTextLabel.TextColor3 = GRAY;
      ViewParentImageLabel.ImageColor3 = GRAY;
      ViewParentButton.BackgroundTransparency = 1;

      local NewViewingPriority = viewingPriority:split(".");
      NewViewingPriority[#NewViewingPriority] = nil;
      viewingPriority = table.concat(NewViewingPriority,".");

      syncDialogueGUI(DirectoryContentScript.Parent :: DialogueContainerClass);
      
    end);

    local WHITE = Color3.fromRGB(255, 255, 255);
    ViewParentTextLabel.TextColor3 = WHITE;
    ViewParentImageLabel.ImageColor3 = WHITE;
    ViewParentButton.BackgroundTransparency = 0;

  end;
  
  local DeleteModeButton = Tools:FindFirstChild("DeleteMode") :: TextButton;
  local DeleteModeImageLabel = DeleteModeButton:FindFirstChild("ImageLabel") :: ImageLabel;
  local DeleteModeTextLabel = DeleteModeButton:FindFirstChild("TextLabel") :: TextLabel;
  Events.DeleteMode = DeleteModeButton.MouseButton1Click:Connect(function()
    
    -- Toggle delete mode and tell the current status to the developer.
    isDeleteModeEnabled = not isDeleteModeEnabled;
    
    DeleteModeButton.BackgroundColor3 = if isDeleteModeEnabled then Color3.fromRGB(217, 39, 39) else Color3.fromRGB(74, 74, 74);
    
    print("[Dialogue Maker] " .. if isDeleteModeEnabled then "Warning: Delete Mode has been enabled!" else "Whew. Delete Mode has been disabled.");

  end);

  print("[Dialogue Maker] " .. DialogueLocationStatus.Text);

  -- Clean up the old dialogue
  for _, status in ipairs(DialogueMessageList:GetChildren()) do
    
    if not status:IsA("UIListLayout") then
      
      status:Destroy();
      
    end;
    
  end;
  
  -- Separate the dialogue item types.
  local responses: {ModuleScript} = {};
  local messages: {ModuleScript} = {};
  local redirects: {ModuleScript} = {};
  for _, PossibleDialogueItem in ipairs(DirectoryContentScript:GetChildren()) do
    
    if PossibleDialogueItem:IsA("ModuleScript") and tonumber(PossibleDialogueItem.Name) then
      
      -- Get the dialogue item type.
      local DialogueType = PossibleDialogueItem:GetAttribute("DialogueType");
      if DialogueType == "Response" then
        
        table.insert(responses, PossibleDialogueItem);
        
      elseif DialogueType == "Message" then

        table.insert(messages, PossibleDialogueItem);
        
      elseif DialogueType == "Redirect" then

        table.insert(redirects, PossibleDialogueItem);
        
      end
      
    end
    
  end
  
  -- Sort the directory based on priority
  local function sortByMessagePriority(dialogueA: ModuleScript, dialogueB: ModuleScript)
    
    local messageAPriority = tonumber(dialogueA.Name) or math.huge;
    local messageBPriority = tonumber(dialogueB.Name) or math.huge;
    
    return messageAPriority < messageBPriority;
    
  end;
  
  table.sort(responses, sortByMessagePriority);
  table.sort(messages, sortByMessagePriority);
  table.sort(redirects, sortByMessagePriority);

  -- Keep track if a message GUI is open
  local function refreshDialogueGUI()

    syncDialogueGUI(DirectoryContentScript) 

  end;
  
  -- Create new status
  for _, category in ipairs({responses, messages, redirects}) do

    for _, ContentScript in ipairs(category) do

      local DialogueMessageContainer = DialogueMessageTemplate:Clone();
      local DialogueMessageContainerChildContainer = DialogueMessageContainer:FindFirstChild("Container") :: Frame;
      local DialogueMessagePriorityTextBox = DialogueMessageContainerChildContainer:FindFirstChild("Priority") :: TextBox;
      local DialogueMessageTypeDropdownButton = DialogueMessageContainerChildContainer:FindFirstChild("DialogueTypeDropdown") :: TextButton;
      local splitPriority = viewingPriority:split(".");
      if viewingPriority == "" then table.remove(splitPriority, 1) end;
      table.insert(splitPriority, ContentScript.Name);
      (DialogueMessageTypeDropdownButton:FindFirstChild("DialogueType") :: TextLabel).Text = ContentScript:GetAttribute("DialogueType");
      DialogueMessagePriorityTextBox.PlaceholderText = splitPriority[#splitPriority];
      DialogueMessagePriorityTextBox.Text = splitPriority[#splitPriority];
      DialogueMessageContainer.Visible = true;
      DialogueMessageContainer.Parent = DialogueMessageList;
      
      local dialogueType = ContentScript:GetAttribute("DialogueType");
      local isResponse = dialogueType == "Response";
      local isRedirect = dialogueType == "Redirect";
      if isResponse then

        DialogueMessageContainer.BackgroundTransparency = 0.4;
        DialogueMessageContainer.BackgroundColor3 = Color3.fromRGB(30,103,19);

      elseif isRedirect then

        DialogueMessageContainer.BackgroundTransparency = 0.4;
        DialogueMessageContainer.BackgroundColor3 = Color3.fromRGB(21,44,126);

      else

        DialogueMessageContainer.BackgroundTransparency = 1;

      end;

      local function showDeleteModePrompt(): ()

        if DeletePromptShown then return; end;
        
        DeletePromptShown = true;

        -- Show the deletion options to the user
        local DeleteFrame = DialogueMessageContainer:FindFirstChild("DeleteFrame") :: Frame;
        DeleteFrame.Visible = true;

        -- Add the deletion functionality
        Events.DeleteYesButton = (DeleteFrame:FindFirstChild("YesButton") :: TextButton).MouseButton1Click:Connect(function()

          -- Hide the deletion options from the user
          DeleteFrame.Visible = false;
          
          -- Delete the dialogue
          ContentScript:Destroy();
          
          -- Allow the user to continue using the plugin
          DeletePromptShown = false;

        end);

        -- Give the user the option to back out
        Events.DeleteNoButton = (DeleteFrame:FindFirstChild("NoButton") :: TextButton).MouseButton1Click:Connect(function()

          -- Debounce
          if Events.DeleteNoButton then Events.DeleteNoButton:Disconnect() end;

          -- Hide the deletion options from the user
          DeleteFrame.Visible = false;

          -- Allow the user to continue using the plugin
          DeletePromptShown = false;

        end);

      end;
      
      local FocusEvent;
      FocusEvent = DialogueMessagePriorityTextBox.FocusLost:Connect(function(input)

        -- Make sure the priority is valid
        local isUserTextInvalid = false;
        local userText = DialogueMessagePriorityTextBox.Text;
        if userText:sub(1, 1) == "." or userText:sub(userText:len()) == "." then
          
          isUserTextInvalid = true;
          
        end;
        
        local CurrentDirectory = CurrentDialogueContainer;
        splitPriority = DialogueMessagePriorityTextBox.Text:split(".");
        if not isUserTextInvalid then
          
          for index, priority in ipairs(splitPriority) do

            -- Make sure everyone's a number
            if not tonumber(priority) then
              
              warn("[Dialogue Maker] " .. DialogueMessagePriorityTextBox.Text .. " is not a valid priority. Make sure you're not using any characters other than numbers and periods.");
              isUserTextInvalid = true;
              break;
              
            end;

            -- Make sure the folder exists
            local TargetDirectory = CurrentDirectory:FindFirstChild(priority);
            if not TargetDirectory and index ~= #splitPriority then

              warn("[Dialogue Maker] " .. DialogueMessagePriorityTextBox.Text .. " is not a valid priority. Make sure all parent directories exist.");
              isUserTextInvalid = true;
              break;

            elseif index == #splitPriority then

              if TargetDirectory then

                warn("[Dialogue Maker] " .. DialogueMessagePriorityTextBox.Text .. " is not a valid priority. Make sure that " .. DialogueMessagePriorityTextBox.Text .. " isn't already being used.");
                isUserTextInvalid = true;

              else

                CurrentDirectory = ContentScript;
                local UserSplitPriority = DialogueMessagePriorityTextBox.Text:split(".");
                ContentScript.Name = UserSplitPriority[#UserSplitPriority];
                ContentScript.Parent = CurrentDirectory;

              end;
              break;

            end;

            CurrentDirectory = CurrentDirectory:FindFirstChild(priority) :: ModuleScript;
            
          end;
          
        end;

        -- Refresh the GUI
        refreshDialogueGUI();
        
      end);
      
      local function openSpecialScript(Folder: Folder, Template: ModuleScript): ()

        -- Search through the script list
        local SpecialScript;
        for _, PossibleSpecialScript in ipairs(Folder:GetChildren()) do

          if PossibleSpecialScript:IsA("ModuleScript") and (PossibleSpecialScript:FindFirstChild("ContentScript") :: ObjectValue).Value == ContentScript then

            SpecialScript = PossibleSpecialScript;
            break;

          end;

        end;

        if not SpecialScript then
          
          local TempSpecialScript = Template:Clone();
          TempSpecialScript.Name = table.concat(splitPriority, ".");
          (TempSpecialScript:FindFirstChild("ContentScript") :: ObjectValue).Value = ContentScript;
          TempSpecialScript.Parent = Folder;
          SpecialScript = TempSpecialScript;

        end;

        -- Open the condition script
        plugin:OpenScript(SpecialScript);

      end;
      
      local OpenScriptsButton = DialogueMessageContainerChildContainer:FindFirstChild("OpenScripts");
      local OpenScriptsList = OpenScriptsButton:FindFirstChild("List");
      local ConditionButton = OpenScriptsList:FindFirstChild("Condition") :: TextButton;
      ConditionButton.MouseButton1Click:Connect(function()

        openSpecialScript(ServerScriptService.DialogueServerScript.Conditions, script.ConditionTemplate);

      end);
      
      local PrecedingActionButton = OpenScriptsList:FindFirstChild("PrecedingAction") :: TextButton;
      PrecedingActionButton.MouseButton1Click:Connect(function()

        openSpecialScript(ServerScriptService.DialogueServerScript.Actions.Preceding, script.ActionTemplate);

      end);
      
      local ViewChildrenButton = DialogueMessageContainerChildContainer:FindFirstChild("ViewChildren") :: TextButton;
      local SucceedingActionButton = OpenScriptsList:FindFirstChild("PrecedingAction") :: TextButton;
      if isRedirect then

        -- Don't show the Before Action button for redirects
        SucceedingActionButton.Visible = false;
        ViewChildrenButton.Visible = false;

      else

        -- Don't show the Before Action button for responses
        if not isResponse then
          
          SucceedingActionButton.MouseButton1Click:Connect(function()

            openSpecialScript(ServerScriptService.DialogueServerScript.Actions.Succeeding, script.ActionTemplate);

          end);
          
        else
          
          SucceedingActionButton.Visible = false;
          
        end;

        table.insert(Events.ViewChildren, ViewChildrenButton.MouseButton1Click:Connect(function()

          if isDeleteModeEnabled then
            
            showDeleteModePrompt();
            return;
            
          end;

          ViewChildrenButton.Visible = false;
          
          -- Go to the target directory
          viewingPriority = table.concat(splitPriority, ".");
          local CurrentDirectory = CurrentDialogueContainer;
          
          for index, directory in ipairs(splitPriority) do
              
            CurrentDirectory = CurrentDirectory:FindFirstChild(directory) :: ModuleScript;
            
          end;

          syncDialogueGUI(ContentScript);

        end));
        
      end;

    end;

  end;

  DialogueMessageList.CanvasSize = UDim2.new(0, 0, 0, (DialogueMessageList:FindFirstChild("UIListLayout") :: UIListLayout).AbsoluteContentSize.Y);
  
  -- Listen for changes
  Events.ChildAdded = DirectoryContentScript.ChildAdded:Connect(refreshDialogueGUI);
  Events.ChildRemoved = DirectoryContentScript.ChildRemoved:Connect(refreshDialogueGUI);

end;


local PluginGui: DockWidgetPluginGui?;

-- Closes the editor when called
-- @since v1.0.0
local function closeDialogueEditor(): ()

  disconnectEvents();

  viewingPriority = "";
  
  DialogueMakerFrame.Parent = nil;

  if PluginGui then PluginGui:Destroy(); end;
  EditDialogueButton:SetActive(false);
  isDialogueEditorOpen = false;

end;

-- Open the editor when called.
-- @since v1.0.0
local function openDialogueEditor(): ()

  PluginGui = plugin:CreateDockWidgetPluginGui("Dialogue Maker", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 525, 241, 525, 139));
  repairNPC();
  if PluginGui and CurrentDialogueContainer then
    
    PluginGui.Title = "Dialogue Maker";
    PluginGui:BindToClose(closeDialogueEditor);
    
    (ModelLocationFrame:FindFirstChild("ModelLocation") :: TextLabel).Text = Model.Name;
    DialogueMakerFrame.Parent = PluginGui;
    isDialogueEditorOpen = true;

    -- Let's get the current dialogue settings
    syncDialogueGUI(CurrentDialogueContainer)
    
  end;

end;

-- Catch the button click event
EditDialogueButton.Click:Connect(function()

  if isDialogueEditorOpen then
    
    closeDialogueEditor();
    return;
    
  end;

  local isTestSuccessful, errorMessage = pcall(function()
    
    -- Check if the user is selecting an object.
    local SelectedObjects = Selection:Get();
    assert(#SelectedObjects ~= 0, "You didn't select an object.");
    assert(#SelectedObjects == 1, "You must select one object; not multiple objects.");

    -- Check if the model has a part
    Model = SelectedObjects[1];
    assert(Model:IsA("Model"), "You must select a Model, not a "..Model.ClassName..".");

    local ModelHasPart = false;
    for _, object in ipairs(Model:GetChildren()) do
      
      if object:IsA("BasePart") then
        
        ModelHasPart = true;
        break;
        
      end
      
    end;

    assert(ModelHasPart, "Your selected model doesn't have a part inside of it.");
    
  end);
  
  if not isTestSuccessful then

    EditDialogueButton:SetActive(false);
    error("[Dialogue Maker] " .. errorMessage, 0);
    
  end

  -- Verify NPC dialogue folder
  repairNPC();

  -- Add the chat receiver script in the starter player scripts
  if not StarterPlayerScripts:FindFirstChild("DialogueClientScript") then

    print("[Dialogue Maker] Adding DialogueClientScript to the StarterPlayerScripts...");
    local DialogueClientScript = script.DialogueClientScript:Clone()
    DialogueClientScript.Parent = StarterPlayerScripts;
    DialogueClientScript.Disabled = false;
    print("[Dialogue Maker] Added DialogueClientScript to the StarterPlayerScripts.");

  end;

  -- Add the chat receiver script in the starter player scripts
  if not ReplicatedStorage:FindFirstChild("DialogueMakerSharedDependencies") then

    print("[Dialogue Maker] Adding DialogueMakerSharedDependencies to the ReplicatedStorage...");
    local DialogueMakerSharedDependencies = script.DialogueMakerSharedDependencies:Clone()
    DialogueMakerSharedDependencies.Parent = ReplicatedStorage;
    print("[Dialogue Maker] Added DialogueMakerSharedDependencies to the ReplicatedStorage.");

  end;

  -- Add the chat receiver script in the starter player scripts
  if not ServerScriptService:FindFirstChild("DialogueServerScript") then

    print("[Dialogue Maker] Adding DialogueServerScript to the ServerScriptService...");
    local DialogueServerScript = script.DialogueServerScript:Clone();
    DialogueServerScript.Parent = ServerScriptService;
    DialogueServerScript.Disabled = false;
    print("[Dialogue Maker] Added DialogueServerScript to the ServerScriptService.");

    -- Add this model to the DialogueManager
    local DialogueLocation = Instance.new("ObjectValue");
    DialogueLocation.Value = Model;
    DialogueLocation.Name = "DialogueLocation";
    DialogueLocation.Parent = DialogueServerScript.DialogueLocations;

  end;

  -- Now we can open the dialogue editor.
  openDialogueEditor();

end);

local isBusy = false;
local ResetScriptsButton = Toolbar:CreateButton("Fix Scripts", "Reset DialogueMakerSharedDependencies, DialogueServerScript, and DialogueClientScript back to the a stable version.", "rbxassetid://14109193905");
ResetScriptsButton.Click:Connect(function()

  -- Debounce
  assert(not isBusy, "[Dialogue Maker] One moment please...");
  isBusy = true;

  local Success, Msg = pcall(function()
    -- Set an undo point
    ChangeHistoryService:SetWaypoint("Resetting Dialogue Maker scripts");

    -- Make copies
    local NewDialogueServerScript = script.DialogueServerScript:Clone();
    local NewDialogueClientScript = script.DialogueClientScript:Clone();
    local ClientAPI = NewDialogueClientScript.API:Clone();
    local NewThemes = NewDialogueClientScript.Themes:Clone();

    -- Save the old copies
    local OldDialogueServerScript = ServerScriptService:FindFirstChild("DialogueServerScript") or NewDialogueServerScript:Clone();
    local OldDialogueClientScript = StarterPlayerScripts:FindFirstChild("DialogueClientScript") or NewDialogueClientScript:Clone();

    -- Remove the children from the new copies
    for _, dialogueScript in ipairs({NewDialogueServerScript, NewDialogueClientScript}) do
      for _, child in ipairs(dialogueScript:GetChildren()) do
        child.Parent = nil;
      end;

      -- Enable the scripts
      dialogueScript.Disabled = false;
    end;

    -- Remove connections from ReplicatedStorage
    local NewDMRC = script.DialogueMakerSharedDependencies:Clone();
    local OldDMRC = ReplicatedStorage:FindFirstChild("DialogueMakerSharedDependencies");
    if OldDMRC then
      
      OldDMRC.Parent = nil;
      
    end;

    -- Check for themes
    local OldThemes = OldDialogueClientScript:FindFirstChild("Themes");
    if not OldThemes then
      
      NewThemes.Parent = OldDialogueClientScript;
      
    end;

    -- Check for API
    local OldAPI = OldDialogueClientScript:FindFirstChild("API");
    if OldAPI then
      
      OldAPI.Parent = nil;
      
    end

    -- Take the children from the old scripts
    for _, DialogueMakerScript in ipairs({OldDialogueServerScript, OldDialogueClientScript}) do
      
      for _, child in ipairs(DialogueMakerScript:GetChildren()) do
        
        child.Parent = if DialogueMakerScript == OldDialogueServerScript then NewDialogueServerScript else NewDialogueClientScript;
        
      end;

      -- Delete the old scripts
      DialogueMakerScript.Parent = nil;
      
    end;

    -- Put the new instances in their places
    NewDialogueServerScript.Parent = ServerScriptService;
    NewDialogueClientScript.Parent = StarterPlayerScripts;
    ClientAPI.Parent = NewDialogueClientScript;
    NewDMRC.Parent = ReplicatedStorage;

    -- Finalize the undo point
    ChangeHistoryService:SetWaypoint("Reset Dialogue Maker scripts");
    
  end)

  -- Done!
  isBusy = false;
  print("[Dialogue Maker] " .. if Success then "Fixed Dialogue Maker scripts!" else ("Couldn't fix scripts: " .. Msg));

end);

local RemoveUnusedInstancesButton = Toolbar:CreateButton("Remove Unused Instances", "Deletes unused actions, conditions, and dialogue locations.", "rbxassetid://14109207161")
RemoveUnusedInstancesButton.Click:Connect(function()

  assert(not isBusy, "[Dialogue Maker] One moment please...");
  isBusy = true;

  local Count = 0;
  pcall(function()
    
    local DSS = ServerScriptService:FindFirstChild("DialogueServerScript");
    if not DSS then
      
      warn("[Dialogue Maker] There isn't a DialogueServerScript in the ServerScriptService!");
      isBusy = false;
      return;
      
    end;

    -- Set an undo point
    ChangeHistoryService:SetWaypoint("Removing unused Dialogue Maker instances");

    -- Remove the unused instances
    for _, folder in ipairs(DSS:GetChildren()) do

      if not folder:IsA("Folder") then

        continue;

      end

      for _, child in ipairs(folder:GetChildren()) do

        if folder.Name == "Actions" then

          for _, module in ipairs(child:GetChildren()) do

            local NPC = module:FindFirstChild("NPC");
            if not NPC or not NPC.Value or not NPC.Value.Parent then

              Count += 1;
              module.Parent = nil;

            end

          end

        elseif folder.Name ~= "DialogueLocations" then

          local NPC = child:FindFirstChild("NPC");
          if not NPC or not NPC.Value or not NPC.Value.Parent then

            Count += 1;
            child.Parent = nil;

          end

        elseif not child.Value or not child.Value.Parent then

          Count += 1;
          child.Parent = nil;

        end;

      end;

    end;

    -- Finalize the undo point
    ChangeHistoryService:SetWaypoint("Removed unused Dialogue Maker instances");
  end)

  -- Done!
  isBusy = false;
  local Plural = if Count ~= 1 then "s" else "";
  print("[Dialogue Maker] Removed unused " .. Count .. " Dialogue Maker instance" .. Plural .. "!")

end);
