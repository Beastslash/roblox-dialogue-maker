--!strict
local Selection = game:GetService("Selection");
local StarterPlayer = game:GetService("StarterPlayer");
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");
local UserInputService = game:GetService("UserInputService");
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

local CurrentDialogueContainer: Folder?;
local Model;
local viewingPriority = "";
local function repairNPC(): ()

  if not Model:FindFirstChild("DialogueContainer") then

    -- Add the dialogue container to the NPC
    local DialogueContainer = Instance.new("Folder");
    DialogueContainer.Name = "DialogueContainer";

    local SettingsScript = script.NPCSettingsTemplate:Clone();
    SettingsScript.Name = "Settings";
    SettingsScript.Parent = DialogueContainer;

    -- Create a root folder
    -- TODO: Change this to a ModuleScript
    local TempRootFolder = Instance.new("Folder");
    TempRootFolder.Name = "1";
    TempRootFolder.Parent = DialogueContainer;

    -- Create a folder for every dialogue type
    for _, folderName in ipairs({"Dialogue", "Responses", "Redirects"}) do
      local Folder = Instance.new("Folder");
      Folder.Name = folderName;
      Folder.Parent = TempRootFolder;
    end;

    -- Add the dialogue folder to the model
    DialogueContainer.Parent = Model;

    viewingPriority = "";

    return;

  end;

  CurrentDialogueContainer = Model:FindFirstChild("DialogueContainer") :: Folder;
  assert(CurrentDialogueContainer, "[Dialogue Maker] DialogueContainer not found...");
  
  if not CurrentDialogueContainer:FindFirstChild("Settings") then

    print("[Dialogue Maker] Adding settings script to "..Model.Name)

    local SettingsScript = script.NPCSettingsTemplate:Clone();
    SettingsScript.Name = "Settings";
    SettingsScript.Parent = CurrentDialogueContainer;

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
  ConvertFromRedirect: {
    [number]: RBXScriptConnection?;
  };
  ConvertToRedirect: {
    [number]: RBXScriptConnection?;
  };
  DeleteMode: RBXScriptConnection?;
  DeleteYesButton: RBXScriptConnection?;
  DeleteNoButton: RBXScriptConnection?;
  EditingMessage: {
    [number]: RBXScriptConnection?;
  };
  EditingRedirect: {
    [number]: RBXScriptConnection?;
  };
  ViewChildren: {
    [number]: RBXScriptConnection?;
  };
  ViewParent: RBXScriptConnection?;
};
local Events: EventTypes = {
  ConvertFromRedirect = {}; 
  ConvertToRedirect = {};
  EditingMessage = {}; 
  EditingRedirect = {}; 
  ViewChildren = {};
};

-- Disconnects all events.
-- @since v5.0.0
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

local Toolbar = plugin:CreateToolbar("Dialogue Maker by Beastslash");
local EditDialogueButton = Toolbar:CreateButton("Edit Dialogue", "Edit dialogue of a selected NPC. The selected object must be a singular model.", "rbxassetid://332218617");
local DeleteModeEnabled = false;
local DeletePromptShown = false;
local isDialogueEditorOpen = false;

-- Refreshes all events and GUI elements in the plugin.
-- @since v1.0.0
local function syncDialogueGUI(DirectoryDialogueScript: ModuleScript): ()

  -- Make sure everything with the NPC is OK
  repairNPC();

  -- Check if there are any past events
  disconnectEvents();
  
  local isDirectoryRoot = viewingPriority == "";
  if isDirectoryRoot then
    
    DialogueMakerFrame.ViewStatus.DialogueLocationStatus.Text = "Viewing the beginning of the conversation";
    
  else
    
    DialogueMakerFrame.ViewStatus.DialogueLocationStatus.Text = "Viewing " .. viewingPriority;

    Events.ViewParent = Tools.ViewParent.MouseButton1Click:Connect(function()

      Tools.ViewParent.BackgroundColor3 = Color3.fromRGB(159, 159, 159);

      local NewViewingPriority = viewingPriority:split(".");
      NewViewingPriority[#NewViewingPriority] = nil;
      viewingPriority = table.concat(NewViewingPriority,".");

      syncDialogueGUI(DirectoryDialogueScript.Parent);
      
    end);

    Tools.ViewParent.BackgroundColor3 = Color3.fromRGB(255, 255, 255);

  end;

  Events.DeleteMode = Tools.DeleteMode.MouseButton1Click:Connect(function()

    if DeleteModeEnabled then

      -- Disable delete mode
      DeleteModeEnabled = false;

      -- Turn the button white again
      Tools.DeleteMode.BackgroundColor3 = Color3.fromRGB(255,255,255);

      -- Tell the user that we're no longer in delete mode
      print("[Dialogue Maker] Whew. Delete Mode has been disabled.");

    else

      -- Enable delete mode
      DeleteModeEnabled = true;

      -- Turn the button red
      Tools.DeleteMode.BackgroundColor3 = Color3.fromRGB(255,46,46);

      -- Tell the user that we're in delete mode
      print("[Dialogue Maker] Warning: Delete Mode has been enabled!");

    end;

  end);

  print("[Dialogue Maker] Viewing " .. viewingPriority);

  -- Clean up the old dialogue
  for _, status in ipairs(DialogueMessageList:GetChildren()) do
    if not status:IsA("UIListLayout") then
      status:Destroy();
    end;
  end;
  
  -- Separate the dialogue item types.
  type ModuleScriptAndProperties = {ModuleScript: ModuleScript; properties: any};
  type ModuleScriptAndPropertiesArray = {[number]: ModuleScriptAndProperties};
  local responses: ModuleScriptAndPropertiesArray = {};
  local messages: ModuleScriptAndPropertiesArray = {};
  local redirects: ModuleScriptAndPropertiesArray = {};
  for _, PossibleDialogueItem in ipairs(DirectoryDialogueScript:GetChildren()) do
    
    if PossibleDialogueItem:IsA("ModuleScript") and tonumber(PossibleDialogueItem.Name) then
      
      -- Make sure the source starts with "return {"
      if PossibleDialogueItem.Source:sub(0, 8) ~= "return {" then
        
        warn("[Dialogue Maker] Possible security risk: " .. viewingPriority .. "." .. PossibleDialogueItem.Name .. " started with something besides \"return {\". Skipping over this module.");
        
      end
      
      -- Get the dialogue item type.
      local dialogueProperties = require(PossibleDialogueItem) :: any;
      if typeof(dialogueProperties) == "table" then
        
        local value = {
          ModuleScript = PossibleDialogueItem;
          properties = dialogueProperties;
        };
        if dialogueProperties.type == "response" then
          
          table.insert(responses, value);
          
        elseif dialogueProperties.type == "message" then
          
          table.insert(messages, value);
          
        elseif dialogueProperties.type == "redirect" then
          
          table.insert(redirects, value);
          
        end
        
      end
      
    end
    
  end
  
  -- Sort the directory based on priority
  local function sortByMessagePriority(dialogueA: ModuleScriptAndProperties, dialogueB: ModuleScriptAndProperties)
    
    local messageAPriority = tonumber(dialogueA.ModuleScript.Name) or math.huge;
    local messageBPriority = tonumber(dialogueB.ModuleScript.Name) or math.huge;
    
    return messageAPriority < messageBPriority;
    
  end;
  
  table.sort(responses, sortByMessagePriority);

  table.sort(messages, sortByMessagePriority);

  table.sort(redirects, sortByMessagePriority);

  -- Check if there is a redirect
  DialogueMessageList.Parent.DescriptionLabels.Text.Text = (redirects[1] and "Text / Redirect") or "Text";

  -- Keep track if a message GUI is open
  local EditingMessage = false;

  local CombinedDirectories = {responses, messages, redirects};

  -- Create new status
  for _, category in ipairs(CombinedDirectories) do

    for _, dialogue in ipairs(category) do

      local DialogueStatus = DialogueMessageTemplate:Clone();
      local SplitPriority = dialogue.Priority.Value:split(".");
      DialogueStatus.PriorityButton.Text = SplitPriority[#SplitPriority];
      DialogueStatus.Priority.PlaceholderText = dialogue.Priority.Value;
      DialogueStatus.Priority.Text = dialogue.Priority.Value;
      DialogueStatus.Message.Text = dialogue.properties.content;
      DialogueStatus.RedirectPriority.Text = dialogue.properties.content;
      DialogueStatus.Visible = true;
      DialogueStatus.Parent = DialogueMessageList;
      
      local isResponse = dialogue.properties.type == "response";
      local isRedirect = dialogue.properties.type == "redirect";
      if isResponse then

        DialogueStatus.BackgroundTransparency = 0.4;
        DialogueStatus.BackgroundColor3 = Color3.fromRGB(30,103,19);

      elseif isRedirect then

        DialogueStatus.BackgroundTransparency = 0.4;
        DialogueStatus.BackgroundColor3 = Color3.fromRGB(21,44,126);
        DialogueStatus.RedirectPriority.Visible = true;
        DialogueStatus.Message.Visible = false;

      else

        DialogueStatus.BackgroundTransparency = 1;

      end;

      local function showDeleteModePrompt()

        -- Debounce
        if DeletePromptShown then return; end;
        DeletePromptShown = true;

        -- Show the deletion options to the user
        DialogueStatus.DeleteFrame.Visible = true;

        -- Add the deletion functionality
        Events.DeleteYesButton = DialogueStatus.DeleteFrame.YesButton.MouseButton1Click:Connect(function()

          -- Hide the deletion options from the user
          DialogueStatus.DeleteFrame.Visible = false;
          
          -- Delete the dialogue
          dialogue.ModuleScript:Destroy();

          -- Allow the user to continue using the plugin
          DeletePromptShown = false;

          -- Refresh the view
          syncDialogueGUI(DirectoryDialogueScript);

        end);

        -- Give the user the option to back out
        Events.DeleteNoButton = DialogueStatus.DeleteFrame.NoButton.MouseButton1Click:Connect(function()

          -- Debounce
          if Events.DeleteNoButton then Events.DeleteNoButton:Disconnect() end;

          -- Hide the deletion options from the user
          DialogueStatus.DeleteFrame.Visible = false;

          -- Allow the user to continue using the plugin
          DeletePromptShown = false;

        end);

      end

      DialogueStatus.PriorityButton.MouseButton1Click:Connect(function()

        if DeleteModeEnabled then
          
          showDeleteModePrompt();
          
        else
          
          DialogueStatus.PriorityButton.Visible = false;
          DialogueStatus.Priority.Visible = true;
          DialogueStatus.Priority:CaptureFocus();
          local FocusEvent;
          FocusEvent = DialogueStatus.Priority.FocusLost:Connect(function(input)

            DialogueStatus.Priority.Visible = false;

            if DialogueStatus.Priority.Text ~= isResponse then

              -- Make sure the priority is valid
              local InvalidPriority = false;
              local SplitPriorityWithPeriods = DialogueStatus.Priority.Text:split("");
              if SplitPriorityWithPeriods[1] == "." or SplitPriorityWithPeriods[#SplitPriorityWithPeriods] == "." then
                
                InvalidPriority = true;
                
              end;
              local CurrentDirectory = CurrentDialogueContainer;
              SplitPriority = DialogueStatus.Priority.Text:split(".");
              if not InvalidPriority then
                for index, priority in ipairs(SplitPriority) do

                  -- Make sure everyone's a number
                  if not tonumber(priority) then
                    warn("[Dialogue Maker] "..DialogueStatus.Priority.Text.." is not a valid priority. Make sure you're not using any characters other than numbers and periods.");
                    InvalidPriority = true;
                    break;
                  end;

                  -- Make sure the folder exists
                  local TargetDirectory = CurrentDirectory:FindFirstChild(priority);
                  if not TargetDirectory and index ~= #SplitPriority then

                    warn("[Dialogue Maker] "..DialogueStatus.Priority.Text.." is not a valid priority. Make sure all parent directories exist.");
                    InvalidPriority = true;
                    break;

                  elseif index == #SplitPriority then

                    if CurrentDirectory.Parent.Dialogue:FindFirstChild(priority) or CurrentDirectory.Parent.Responses:FindFirstChild(priority) then

                      warn("[Dialogue Maker] "..DialogueStatus.Priority.Text.." is not a valid priority. Make sure that "..DialogueStatus.Priority.Text.." isn't already being used.");
                      InvalidPriority = true;

                    else

                      CurrentDirectory = (dialogue.Response.Value and CurrentDirectory.Parent.Responses) or CurrentDirectory.Parent.Dialogue;

                      local UserSplitPriority = DialogueStatus.Priority.Text:split(".");
                      dialogue.Priority.Value = DialogueStatus.Priority.Text;
                      dialogue.Name = UserSplitPriority[#UserSplitPriority];
                      dialogue.Parent = CurrentDirectory;

                    end;
                    break;

                  end;

                  CurrentDirectory = (TargetDirectory.Dialogue:FindFirstChild(priority) and TargetDirectory.Dialogue) or (TargetDirectory.Responses:FindFirstChild(priority) and TargetDirectory.Responses) or (CurrentDirectory:FindFirstChild(priority) and CurrentDirectory[priority].Dialogue);
                end;
              end;

              -- Refresh the GUI
              syncDialogueGUI(DirectoryDialogueScript);

            else
              DialogueStatus.PriorityButton.Visible = true;
            end;
          end);
        end;
      end);

      DialogueStatus.PriorityButton.MouseButton2Click:Connect(function() 

        if dialogue.Parent.Parent.Parent.Name == "Dialogue" and not isDirectoryRoot then

          -- Check if the dialogue is a message
          if isResponse then
            
            dialogue.Response.Value = false;
            
          else
            
            dialogue.Response.Value = true;
            
          end;

          -- Refresh the view.
          syncDialogueGUI(directoryDialogue);

        else

          warn("[Dialogue Maker] You can't create a response at the beginning of the conversation...yet. Create a message, view its children, and then create a response.")

        end

      end);

      if isRedirect then

        Events.ConvertFromRedirect[dialogue] = DialogueStatus.RedirectPriority.MouseButton2Click:Connect(function()

          Events.ConvertFromRedirect[dialogue]:Disconnect();
          dialogue.Redirect.Value = false;
          dialogue.Parent = (dialogue.Response.Value and directoryDialogue.Parent.Responses) or directoryDialogue.Parent.Dialogue;

          syncDialogueGUI(directoryDialogue);

        end);

        Events.EditingRedirect[dialogue] = DialogueStatus.RedirectPriority.MouseButton1Click:Connect(function()

          if not EditingMessage then

            EditingMessage = true;

            DialogueStatus.RedirectPriority.TextBox.Text = dialogue.RedirectPriority.Value;
            DialogueStatus.RedirectPriority.TextBox.Visible = true;
            DialogueStatus.RedirectPriority.TextBox:CaptureFocus();
            DialogueStatus.RedirectPriority.TextBox.FocusLost:Connect(function(enterPressed)
              if enterPressed then
                
                Events.EditingRedirect[dialogue]:Disconnect();
                disconnectEvents();

                dialogue.RedirectPriority.Value = DialogueStatus.RedirectPriority.TextBox.Text;
                DialogueStatus.RedirectPriority.TextBox.Visible = false;
                syncDialogueGUI(directoryDialogue);
                
              end;

              EditingMessage = false;

            end);

          end;

        end);

      else

        Events.ConvertToRedirect[dialogue] = DialogueStatus.Message.MouseButton2Click:Connect(function()

          dialogue.Redirect.Value = true;
          syncDialogueGUI(DirectoryDialogueScript);

        end);

        Events.EditingMessage[dialogue] = DialogueStatus.Message.MouseButton1Click:Connect(function()

          if DeleteModeEnabled then
            
            showDeleteModePrompt();
            return;
            
          end;

          if EditingMessage then
            
            return;
            
          end;

          EditingMessage = true;

          DialogueStatus.Message.TextBox.Text = dialogue.Message.Value;
          DialogueStatus.Message.TextBox.Visible = true;
          DialogueStatus.Message.TextBox:CaptureFocus();
          DialogueStatus.Message.TextBox.FocusLost:Connect(function(enterPressed)
            
            if enterPressed then
              
              dialogue.Message.Value = DialogueStatus.Message.TextBox.Text;
              DialogueStatus.Message.TextBox.Visible = false;
              syncDialogueGUI(DirectoryDialogueScript);
              
            end;
            EditingMessage = false;
            
          end);

        end);

      end

      -- Check if there's already a condition for the dialogue
      for _, condition in ipairs(ServerScriptService.DialogueServerScript.Conditions:GetChildren()) do
        if condition:IsA("ModuleScript") and condition.Priority.Value == dialogue and condition.NPC.Value == Model then
          DialogueStatus.ConditionButton.ImageColor3 = Color3.fromRGB(35, 255, 116);
        end;
      end;

      -- Check if there's already actions for the dialogue
      for _, action in ipairs(ServerScriptService.DialogueServerScript.Actions.Before:GetChildren()) do
        if action:IsA("ModuleScript") and action.Priority.Value == dialogue and action.NPC.Value == Model then
          DialogueStatus.BeforeActionButton.ImageColor3 = Color3.fromRGB(35, 255, 116);
        end
      end;

      for _, action in ipairs(ServerScriptService.DialogueServerScript.Actions.After:GetChildren()) do
        if action:IsA("ModuleScript") and action.Priority.Value == dialogue and action.NPC.Value == Model then
          DialogueStatus.AfterActionButton.ImageColor3 = Color3.fromRGB(35, 255, 116);
        end
      end;

      DialogueStatus.ConditionButton.MouseButton1Click:Connect(function()

        if DeleteModeEnabled then
          showDeleteModePrompt();
          return;
        end;

        -- Look through the condition list and find the condition we want
        local Condition;
        for _, child in ipairs(ServerScriptService.DialogueServerScript.Conditions:GetChildren()) do

          -- Check if the child is a condition
          if child:IsA("ModuleScript") and child.Priority.Value == dialogue and child.NPC.Value == Model then

            -- Return the condiiton
            Condition = child;
            break;

          end;

        end;

        if not Condition then

          -- Create a new condition
          Condition = script.ConditionTemplate:Clone();
          Condition.Priority.Value = dialogue;
          Condition.NPC.Value = Model;
          Condition.Name = "Condition";
          Condition.Parent = ServerScriptService.DialogueServerScript.Conditions;

        end;

        DialogueStatus.ConditionButton.ImageColor3 = Color3.fromRGB(35, 255, 116);

        -- Open the condition script
        plugin:OpenScript(Condition);

      end);

      local function OpenAction(beforeOrAfter: "Preceding" | "Succeeding")
        -- Look through the action list and find the condition we want
        local Action;
        for _, child in ipairs(ServerScriptService.DialogueServerScript.Actions[beforeOrAfter]:GetChildren()) do

          -- Check if the child is a condition
          if child:IsA("ModuleScript") and child.Priority.Value == dialogue and child.NPC.Value == Model then

            -- Return the condiiton
            Action = child;
            break;

          end;

        end;

        if not Action then

          -- Create a new condition
          Action = script.ActionTemplate:Clone();
          Action.Priority.Value = dialogue;
          Action.NPC.Value = Model;
          Action.Name = beforeOrAfter .. "Action";

          Action.Parent = ServerScriptService.DialogueServerScript.Actions[beforeOrAfter];

          dialogue["Has"..beforeOrAfter .. "Action"].Value = true;

        end;

        DialogueStatus[beforeOrAfter .. "ActionButton"].ImageColor3 = Color3.fromRGB(35, 255, 116);

        -- Open the condition script
        plugin:OpenScript(Action);

      end;

      DialogueStatus.AfterActionButton.MouseButton1Click:Connect(function()

        if DeleteModeEnabled then
          showDeleteModePrompt();
          return;
        end;

        OpenAction("Succeeding");

      end);

      if isRedirect then

        -- Don't show the Before Action button for redirects
        DialogueStatus.BeforeActionButton.Visible = false;
        DialogueStatus.ViewChildren.Visible = false;

      else

        -- Don't show the Before Action button for responses
        if not isResponse then
          DialogueStatus.BeforeActionButton.MouseButton1Click:Connect(function()

            if DeleteModeEnabled then
              showDeleteModePrompt();
              return;
            end;

            OpenAction("Preceding");

          end);
        else
          DialogueStatus.BeforeActionButton.Visible = false;
        end;

        Events.ViewChildren[DialogueStatus] = DialogueStatus.ViewChildren.MouseButton1Click:Connect(function()

          if DeleteModeEnabled then
            showDeleteModePrompt();
            return;
          end;

          Events.ViewChildren[DialogueStatus]:Disconnect();

          ViewingPriority = dialogue.Priority.Value;

          if Events.ViewParent then
            Events.ViewParent:Disconnect();
            Events.ViewParent = nil;
          end;

          Events.DeleteMode:Disconnect();

          -- Go to the target directory
          local Path = ViewingPriority:split(".");
          local CurrentDirectory = CurrentDialogueContainer;

          for index, directory in ipairs(Path) do
            if CurrentDirectory:FindFirstChild(directory) then
              CurrentDirectory = CurrentDirectory[directory].Dialogue;
            else
              CurrentDirectory = CurrentDirectory.Parent.Responses[directory].Dialogue;
            end;
          end;

          syncDialogueGUI(DirectoryDialogueScript);

        end);
      end;

    end;

  end;

  DialogueMessageList.CanvasSize = UDim2.new(0, 0, 0, DialogueMessageList.UIListLayout.AbsoluteContentSize.Y);

end;

local function AddDialogueToMessageList(directory: ModuleScript, text: string)

  -- Let's create the dialogue first.
  -- Get message priority
  local Priority = ViewingPriority .. "." .. (#directory.Parent.Dialogue:GetChildren()+#directory.Parent.Responses:GetChildren() + #directory.Parent.Redirects:GetChildren()) + 1;

  -- Create the dialogue script.
  local DialoguePropertiesScript = Instance.new("ModuleScript");
  DialoguePropertiesScript.Name = Priority;
  DialoguePropertiesScript.Source = [[
    --!strict

    local dialogue: {
      content: string;
      hasPrecedingAction: boolean;
      hasSucceedingAction: boolean;
      hasCondition: boolean;
      type: "message" | "redirect" | "response";
    } = {
      
      -- A preceding action script that will run before this dialogue is shown.
      hasPrecedingAction = false;

      -- A succeeding action script that will run when this dialogue completes.
      -- This will not run if this dialogue item is a redirect or response.
      hasSucceedingAction = false;
      
      -- A ModuleScript that will check if this dialogue can be shown.
      hasCondition = false;
      
      -- A string representing the value of this dialogue item. 
      -- If this is a message or a response, then this string will be the message or response content.
      -- If this is a redirect, then this string will be dialogue priority to redirect to.
      content = "]] .. text .. [[";

      -- The type of dialogue. 
      type = "message";
      
    }

    return dialogue;
  ]]

  DialoguePropertiesScript.Parent = directory;
  
  -- Now let's re-order the dialogue
  disconnectEvents();
  syncDialogueGUI(directory);

end;


local PluginGui: DockWidgetPluginGui?;

-- Open the editor when called.
-- @since v1.0.0
local function openDialogueEditor(): ()

  PluginGui = plugin:CreateDockWidgetPluginGui("Dialogue Maker", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 508, 241, 508, 241));
  PluginGui.Title = "Dialogue Maker";
  PluginGui:BindToClose(closeDialogueEditor);

  Events.AdjustSettingsRequested = Tools.AdjustSettings.MouseButton1Click:Connect(function()

    -- Make sure all of the important objects are in the NPC
    repairNPC();

    plugin:OpenScript(CurrentDialogueContainer:FindFirstChild("Settings"));

  end);

  Events.AddMessage = Tools.AddMessage.MouseButton1Click:Connect(function()

    local path = ViewingPriority:split(".");
    local CurrentDirectory = CurrentDialogueContainer;

    for _, directory in ipairs(path) do

      local TargetDirectory = CurrentDirectory:FindFirstChild(directory) or CurrentDirectory.Parent.Dialogue:FindFirstChild(directory) or CurrentDirectory.Parent.Responses:FindFirstChild(directory);
      if not TargetDirectory then

        -- Create a folder to hold dialogue and responses
        TargetDirectory = Instance.new("Folder");
        TargetDirectory.Name = directory;
        TargetDirectory.Parent = CurrentDirectory;

      end;

      if TargetDirectory.Dialogue:FindFirstChild(directory) then
        CurrentDirectory = TargetDirectory.Dialogue;
      elseif TargetDirectory.Responses:FindFirstChild(directory) then
        CurrentDirectory = TargetDirectory.Responses;
      elseif TargetDirectory:FindFirstChild(directory) then
        CurrentDirectory = TargetDirectory;
      elseif CurrentDirectory:FindFirstChild(directory) then
        CurrentDirectory = CurrentDirectory[directory].Dialogue;
      else
        CurrentDirectory = TargetDirectory.Dialogue;
      end;

    end;

    AddDialogueToMessageList(CurrentDirectory, "");

  end);

  -- Let's get the current dialogue settings
  repairNPC();
  syncDialogueGUI(CurrentDialogueContainer)
  
  local DialogueMakerFrame = DialogueMakerFrame:Clone();
  DialogueMakerFrame.ViewStatus.ModelLocationFrame.ModelLocation.Text = Model.Name;
  DialogueMakerFrame.Parent = PluginGui;
  isDialogueEditorOpen = true;

end;

-- Closes the editor when called
-- @since v1.0.0
local function closeDialogueEditor(): ()

  Events = {ViewChildren = {}; EditingMessage = {}; EditingRedirect = {}; ConvertFromRedirect = {}; ConvertToRedirect = {}};

  viewingPriority = "";

  PluginGui:Destroy();
  EditDialogueButton:SetActive(false);
  isDialogueEditorOpen = false;

end;

-- Catch the button click event
EditDialogueButton.Click:Connect(function()

  if isDialogueEditorOpen then
    
    closeDialogueEditor();
    return;
    
  end;

  local SelectedObjects = Selection:Get();

  -- Check if the user is selecting ONE object
  if #SelectedObjects == 0 then
    EditDialogueButton:SetActive(false);
    error("[Dialogue Maker] You didn't select an object.",0);
  elseif #SelectedObjects > 1 then
    EditDialogueButton:SetActive(false);
    error("[Dialogue Maker] You must select one object; not multiple objects.",0);
  end;

  Model = SelectedObjects[1];

  -- Check if the user is selecting a model
  if not Model:IsA("Model") then
    EditDialogueButton:SetActive(false);
    error("[Dialogue Maker] You must select a Model, not a "..Model.ClassName..".",0);
  end;

  -- Check if the model has a part
  local ModelHasPart = false;

  for _, object in ipairs(Model:GetChildren()) do
    if object:IsA("BasePart") then
      ModelHasPart = true;
      break;
    end
  end;

  if not ModelHasPart then
    EditDialogueButton:SetActive(false);
    error("[Dialogue Maker] Your selected model doesn't have a part inside of it.",0);
  end;

  -- Check if there is a dialogue folder in the NPC
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
  if not ReplicatedStorage:FindFirstChild("DialogueMakerRemoteConnections") then

    print("[Dialogue Maker] Adding DialogueMakerRemoteConnections to the ReplicatedStorage...");
    local DialogueMakerRemoteConnections = script.DialogueMakerRemoteConnections:Clone()
    DialogueMakerRemoteConnections.Parent = ReplicatedStorage;
    print("[Dialogue Maker] Added DialogueMakerRemoteConnections to the ReplicatedStorage.");

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
local ResetScriptsButton = Toolbar:CreateButton("Fix Scripts", "Reset DialogueMakerRemoteConnections, DialogueServerScript, and DialogueClientScript back to the a stable version.", "rbxassetid://61995002");
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
    local NewDMRC = script.DialogueMakerRemoteConnections:Clone();
    local OldDMRC = ReplicatedStorage:FindFirstChild("DialogueMakerRemoteConnections");
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
    for _, dialogueScript in ipairs({OldDialogueServerScript, OldDialogueClientScript}) do
      for _, child in ipairs(dialogueScript:GetChildren()) do
        if dialogueScript == OldDialogueServerScript then
          child.Parent = NewDialogueServerScript;
        else
          child.Parent = NewDialogueClientScript;
        end;
      end;

      -- Delete the old scripts
      dialogueScript.Parent = nil;
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

local RemoveUnusedInstancesButton = Toolbar:CreateButton("Remove Unused Instances", "Deletes unused actions, conditions, and dialogue locations.", "rbxassetid://61995002")
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
