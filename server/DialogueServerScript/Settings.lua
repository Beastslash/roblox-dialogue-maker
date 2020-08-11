return {
	
	-- [ Theme Settings ] --
	DEFAULT_THEME = "BareBonesDialogue"; -- This is the default theme that will be used when talking with NPCs
	
	-- [ Response Settings ] --
	SHOW_RESPONSES_AFTER_MSG_FINISHED = true; -- Prevents the player from selecting responses without first viewing the dialogue
	DEFAULT_CLICK_SOUND = 0; -- Replace this with an audio ID that'll play every time a player continues a conversation or selects a response. Replace with 0 to not play any sound.
	
	-- [ Chat Triggers and Keybinds ] --
	MIN_DISTANCE_FROM_CHARACTER = 10; -- Minimum distance from a character required for keybinds should work
	KEYBINDS_ENABLED = true; -- Whether or not keybinds should work
	DEFAULT_CHAT_TRIGGER_KEY = Enum.KeyCode.F; -- Keyboard keybind to start a conversation with an NPC
	DEFAULT_CHAT_TRIGGER_KEY_GAMEPAD = Enum.KeyCode.ButtonX; -- Gamepad keybind to start a conversation with an NPC
	DEFAULT_CHAT_CONTINUE_KEY = Enum.KeyCode.F; -- Keyboard keybind to continue a conversation with an NPC
	DEFAULT_CHAT_CONTINUE_KEY_GAMEPAD = Enum.KeyCode.ButtonA; -- Gamepad keybind to continue a conversation with an NPC
	
};