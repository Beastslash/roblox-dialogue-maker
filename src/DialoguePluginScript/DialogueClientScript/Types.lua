export type ContentArray = {string | Effect};

export type Effect = {
  
  type: "effect";
  
  run: (isPlayerSkipping: boolean) -> any;

  getMaxDimensions: () -> {x: number, y: number};

  getBreakpoints: () -> {number};

  onSkip: () -> any;
  
  name: string;

}

export type NPCSettings = {

  general: {

    npcName: string; 

    showName: boolean; 

    fitName: boolean; 

    textBoundsOffset: number; 

    themeName: string; 

    letterDelay: number; 

    allowPlayerToSkipDelay: boolean; 

    freezePlayer: boolean; 

    endConversationIfOutOfDistance: boolean;

    maxConversationDistance: number;

    npcLooksAtPlayerDuringDialogue: boolean;

    npcNeckRotationMaxX: number;

    npcNeckRotationMaxY: number;

    npcNeckRotationMaxZ: number;

  };

  promptRegion: {

    enabled: boolean;

    location: BasePart?;

  };

  timeout: {

    enabled: boolean;

    seconds: number;

    waitForResponse: boolean;

  };

  speechBubble: {

    enabled: boolean;

    location: BasePart?;

  };

  clickDetector: {

    enabled: boolean;

    autoCreate: boolean;

    disappearsWhenDialogueActive: boolean;

    location: ClickDetector?;

  };

  proximityPrompt: {

    enabled: boolean;

    autoCreate: boolean;

    location: ProximityPrompt?;

  };

};

export type UseEffectFunction = (effectName: string, effectProperties: {[string]: any}) -> Effect;

export type RichTextTagInformation = {
  attributes: string?;
  endOffset: number?;
  name: string;
  startOffset: number;
}

export type Page = {{type: "text"; text: string; size: UDim2} | Effect};

return {};
