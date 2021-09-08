return {
	
	-- [ Theme Settings ] --
	DefaultTheme = "BigAndBoldDialogue"; -- This is the default theme that will be used when talking with NPCs
	
	-- [ Response Settings ] --
	ShowResponsesAfterMessageFinished = true; -- Prevents the player from selecting responses without first viewing the dialogue
	DefaultClickSound = 0; -- Replace this with an audio ID that'll play every time a player continues a conversation or selects a response. Replace with 0 to not play any sound.
	
	-- [ Chat Triggers and Keybinds ] --
	MinimumDistanceFromCharacter = 10; -- Minimum distance from a character required for keybinds should work
	KeybindsEnabled = true; -- Whether or not keybinds should work
	DefaultChatTriggerKey = Enum.KeyCode.F; -- Keyboard keybind to start a conversation with an NPC
	DefaultChatTriggerKeyGamepad = Enum.KeyCode.ButtonX; -- Gamepad keybind to start a conversation with an NPC
	DefaultChatContinueKey = Enum.KeyCode.F; -- Keyboard keybind to continue a conversation with an NPC
	DefaultChatContinueKeyGamepad = Enum.KeyCode.ButtonA; -- Gamepad keybind to continue a conversation with an NPC
	
};