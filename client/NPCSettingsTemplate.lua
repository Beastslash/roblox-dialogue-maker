return {

  General = {
    
    NPCName = ""; -- Change this to a theme you've added to the Themes folder in order to override default theme settings. [accepts string]

    ShowName = false; -- When true, the NPC's name will be shown when the player talks to them. [accepts boolean]

    ThemeName = ""; -- Change this to the NPC's name. [accepts string]
    
    LetterDelay = 0.025; -- Change this to the amount of seconds you want to wait before the next letter in the NPC's message is shown. [accepts number >= 0]
    
    AllowPlayerToSkipDelay = true; -- If true, this allows the player to show all of the message without waiting for it to be pieced back together. [accepts boolean]
    
    FreezePlayer = true; -- If true, the player will freeze when the dialogue starts and will be unfrozen when the dialogue ends. [accepts boolean]
    
    EndConversationIfOutOfDistance = false; -- If true, the conversation will end if the PrimaryParts of the NPC and the player exceed the MaximumConversationDistance. [accepts boolean]

    MaxConversationDistance = 10; -- Maximum magnitude between the NPC's HumanoidRootPart and the player's PrimaryPart before the conversation ends. Requires EndConversationIfOutOfDistance to be true. [accepts number]
    
  };

  PromptRegion = {
    
    Enabled = false; -- Do you want the conversation to automatically start when the player touches a part? [accepts boolean]
    
    BasePart = nil; -- Change this value to a part. (Ex. workspace.Part) [accepts BasePart (i.e. Part, MeshPart, etc.) or nil]
    
  };

  Timeout = {
    
    Enabled = false;	-- When true, the conversation to automatically ends after ConversationTimeoutSeconds seconds. [accepts boolean]
    
    Seconds = 0; -- Set this to the amount of seconds you want to wait before closing the dialogue. [accepts number >= 0]
    
    WaitForResponse = true; -- If true, this causes dialogue to ignore the set timeout in order to wait for the player's response. [accepts boolean]
    
  };

  SpeechBubble = {
    
    Enabled = false; -- If true, this causes a speech bubble to appear over the NPC's head. [accepts boolean]
    
    BasePart = nil; -- Set this to a BasePart to set the speech bubble's origin point. [accepts BasePart or nil]
    
    Image = "rbxassetid://4883127463"; -- Set this to a speech bubble image to appear over the NPC's head. [accepts string (roblox asset)]
    
    StudsOffset = Vector3.new(0, 2, 0); -- Replace this with how far you want the speech bubble to be from the NPC's head. Measured in studs. [accepts Vector3]
    
    Size = UDim2.new(2.5, 0, 2.5, 0); -- Replace this with how big you want the speech bubble to be. [accepts UDim2]
    
  };

  ClickDetector = {
    
  
    Enabled = false; -- If true, this causes the player to be able to trigger the dialogue by activating a ClickDetector. [accepts boolean]
    
    AutoCreate = true; -- If true, this automatically creates a ClickDetector inside of the NPC's model. [accepts boolean]
    
    DisappearsWhenDialogueActive = true; -- If true, the ClickDetector's parent will be nil until the dialogue is over. This hides the cursor from the player. [accepts boolean]
    
    Location = nil; -- Replace this with the location of the ClickDetector. (Ex. workspace.Model.ClickDetector) This setting will be ignored if AutomaticallyCreateClickDetector is true. [accepts ClickDetector or nil]
    
    ActivationDistance = 32; -- Replace this with the distance you want the player to be able to activate the ClickDetector. This setting will be ignored if AutomaticallyCreateClickDetector is false. [accepts number]
    
    CursorImage = ""; -- Replace this with an image of the cursor you want to appear when the player hovers over the NPC. If this is an empty string, the default mouse cursor will be used. This setting will be ignored if AutomaticallyCreateClickDetector is false. [accepts string or nil]
    
  };

  ProximityPrompt = {
    
    Enabled = true; -- If true, this causes the player to be able to trigger the dialogue by activating the ProximityPrompt. [accepts boolean]
    
    AutoCreate = true; -- If true, this automatically creates a ProximityPrompt inside of the NPC's model. [accepts boolean]
    
    Location = nil; -- The location of the ProximityPrompt. (Ex. workspace.Model.ProximityPrompt) This setting will be ignored if AutoCreate is true. [accepts ProximityPrompt or nil]
    
    MaxActivationDistance = 15; -- The distance you want the player to be able to activate the ProximityPrompt. This setting will be ignored if AutoCreate is false. [accepts number]
    GamepadKeyCode = Enum.KeyCode.ButtonX; -- The gamepad keycode you want the player to press to activate the ProximityPrompt. This setting will be ignored if AutoCreate is false. [accepts Enum.KeyCode]
    
    KeyboardKeyCode = Enum.KeyCode.E; -- The keyboard keycode you want the player to press to activate the ProximityPrompt. This setting will be ignored if AutoCreate is false. [accepts Enum.KeyCode]
    
    ObjectText = ""; -- The text shown above the "Interact" text on the ProximityPrompt. This setting will be ignored if AutoCreate is false. [accepts string]
    
    HoldDuration = 0; -- The amount of seconds that you want the player to press the action key before triggering the ProximityPrompt. This setting will be ignored if AutoCreate is false. [accepts number]
    
    RequiresLineOfSight = false; -- If true, the player will be presented with the ProximityPrompt even when the ProximityPrompt is obstructed from the player's line of sight. [accepts boolean]
    
  };

};
