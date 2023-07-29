export type ContentArray = {[number]: string | Effect};

export type Effect = {

  run: (isPlayerSkipping: boolean) -> any;
  
  runFromGetPages: () -> any;
  
  onSkip: () -> any;

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

export type UseEffectProperties = {

  name: string;

  [string]: any;  

};

export type UseEffectFunction = (effectProperties: UseEffectProperties) -> Effect;

return {};