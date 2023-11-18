--!strict
local Types = require(game:GetService("StarterPlayer").StarterPlayerScripts.DialogueClientScript.Types)

local settings: Types.NPCSettings = {

  general = {

    -- This will be the NPC name shown to the player.
    npcName = "NPC";

    -- When true, the NPC's name will be shown when the player talks to them.
    showName = false; 

    -- When true, the NPCNameFrame will be automatically resized to fit NPC names.
    fitName = true; 

    -- If General.FitName is true, this value will be added to the TextBounds offset of the NPC's name.
    textBoundsOffset = 30; 

    -- Change this to a theme you've added to the Themes folder in order to override default theme settings.
    themeName = "";

    -- Change this to the amount of seconds you want to wait before the next letter in the NPC's message is shown. 
    -- [accepts number >= 0]
    letterDelay = 0.025;  

    -- If true, this allows the player to show all of the message without waiting for it to be pieced back together.
    allowPlayerToSkipDelay = true; 

    -- If true, the player will freeze when the dialogue starts and will be unfrozen when the dialogue ends.
    freezePlayer = true; 

    -- If true, the conversation will end if the PrimaryParts of the NPC and the player exceed the MaximumConversationDistance.
    endConversationIfOutOfDistance = false;

    -- Maximum magnitude between the NPC's HumanoidRootPart and the player's PrimaryPart before the conversation ends. Requires EndConversationIfOutOfDistance to be true.
    maxConversationDistance = 10;

    -- If true, the NPC will look at the player character during dialogue. Requires the NPC character and the player character to be Humanoids. 
    npcLooksAtPlayerDuringDialogue = false; 

    -- The maximum angle of the NPC's neck on the X axis. Requires NPCLooksAtPlayerDuringDialogue to be true. 
    npcNeckRotationMaxX = 0.8726;

    -- The maximum angle of the NPC's neck on the Y axis. Requires NPCLooksAtPlayerDuringDialogue to be true. 
    npcNeckRotationMaxY = 1.0472; 

    -- The maximum angle of the NPC's neck on the Z axis. Requires NPCLooksAtPlayerDuringDialogue to be true.
    npcNeckRotationMaxZ = 0.8726; 

  };

  promptRegion = {

    -- Do you want the conversation to automatically start when the player touches a part? 
    enabled = false; 

    -- Change this value to a part. (Ex. workspace.Part)
    BasePart = nil; 

  };

  timeout = {

    -- When true, the conversation to automatically ends after ConversationTimeoutSeconds seconds. 
    enabled = false;	

    -- Set this to the amount of seconds you want to wait before closing the dialogue. 
    -- [accepts number >= 0]
    seconds = 0; 

    -- If true, this causes dialogue to ignore the set timeout in order to wait for the player's response. 
    waitForResponse = true; 

  };

  speechBubble = {

    -- If true, this causes a speech bubble to appear over the NPC's head.
    enabled = false;

    -- Set this to a BasePart to set the speech bubble's origin point.
    BasePart = nil;

    -- Change this to a Roblox asset ID. Example: "rbxassetid://6403436054"
    image = "";

    -- How big do you want the speech bubble to be?
    -- More info: https://create.roblox.com/docs/reference/engine/classes/BillboardGui#Size
    size = UDim2.new(1, 0, 1, 0);

    -- How far do you want the bubble away from BasePart?
    -- More info: https://create.roblox.com/docs/reference/engine/classes/BillboardGui#StudsOffset
    studsOffset = Vector3.new(0, 0, 0);

  };

  clickDetector = {

    -- If true, this causes the player to be able to trigger the dialogue by activating a ClickDetector.
    enabled = false; 

    -- If true, this automatically creates a ClickDetector inside of the NPC's model. 
    autoCreate = true; 

    -- If true, the ClickDetector's parent will be nil until the dialogue is over. This hides the cursor from the player. 
    disappearsWhenDialogueActive = true; 

    -- Replace this with the location of the ClickDetector. (Ex. workspace.Model.ClickDetector) This setting will be ignored if AutomaticallyCreateClickDetector is true. 
    Instance = nil;

  };

  proximityPrompt = {

    -- If true, this causes the player to be able to trigger the dialogue by activating the ProximityPrompt. You must set a PrimaryPart in your NPC model for this to work. 
    enabled = true; 

    -- If true, this automatically creates a ProximityPrompt inside of the NPC's model.
    autoCreate = true; 

    -- The location of the ProximityPrompt. (Ex. workspace.Model.ProximityPrompt) This setting will be ignored if AutoCreate is true. 
    Instance = nil; 

  };

};

return settings; 
