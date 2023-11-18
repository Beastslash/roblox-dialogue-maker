--!strict
export type ClientSettings = {

  -- This is the default theme that will be used when talking with NPCs
  defaultThemes: {
    [number]: {
      minimumViewportWidth: number;
      minimumViewportHeight: number;
      themeName: string;
    }
  };

  -- Prevents the player from selecting responses without first viewing the dialogue
  showResponsesAfterMessageFinished: boolean;

  -- Replace this with an audio ID that'll play every time a player continues a conversation or selects a response. Replace with 0 to not play any sound.
  defaultClickSound: number;

  -- Minimum distance from a character required for keybinds should work
  minimumDistanceFromCharacter: number;

  -- Whether keybinds should work
  keybindsEnabled: boolean;

  -- Keyboard keybind to start a conversation with an NPC
  defaultChatTriggerKey: Enum.KeyCode;

  -- Gamepad keybind to start a conversation with an NPC
  defaultChatTriggerKeyGamepad: Enum.KeyCode;

  -- Keyboard keybind to continue a conversation with an NPC
  defaultChatContinueKey: Enum.KeyCode;

  -- Gamepad keybind to continue a conversation with an NPC
  defaultChatContinueKeyGamepad: Enum.KeyCode;
};

local Settings: ClientSettings = {

  -- [ Theme Settings ] --
  defaultThemes = {
    {
      minimumViewportWidth = 0;
      minimumViewportHeight = 0;
      themeName = "BigAndBoldDialogue";
    }
  };

  -- [ Response Settings ] --
  showResponsesAfterMessageFinished = true; 
  defaultClickSound = 0; 

  -- [ Chat Triggers and Keybinds ] --
  minimumDistanceFromCharacter = 10; 
  keybindsEnabled = true; 
  defaultChatTriggerKey = Enum.KeyCode.F; 
  defaultChatTriggerKeyGamepad = Enum.KeyCode.ButtonX; 
  defaultChatContinueKey = Enum.KeyCode.F; 
  defaultChatContinueKeyGamepad = Enum.KeyCode.ButtonA; 

};

return Settings;