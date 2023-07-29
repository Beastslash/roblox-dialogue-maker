--!strict
-- This effect pauses NPC dialogue until a specified amount of time passes.
-- Developer: Christian "Sudobeast" Toney

local Types = require(script.Parent.Parent.Types);

export type PauseEffectProperties = {
  
  -- The amount of seconds before the dialogue continues.
  seconds: number;
  
}

local shouldSkip = false;

local effect: Types.Effect = {
  
  name = "Pause";
  
  run = function(effectProperties: PauseEffectProperties, isSkipping: boolean): ()
    
    -- Skip the effect if necessary.
    if not isSkipping then
      
      -- Start the timer.
      local timeReached = false;    
      coroutine.wrap(function()
        
        task.wait(effectProperties.seconds);
        timeReached = true;
        
      end)();
      
      repeat
        
        -- Allow Dialogue Maker to skip the timer if necessary.
        task.wait();
        
        if shouldSkip then
          
          shouldSkip = false;
          break;
          
        end
        
      until timeReached;
      
    end;
    
  end;
  
  onSkip = function(): ()
    
    shouldSkip = true;
    
  end;
  
}

return effect;
