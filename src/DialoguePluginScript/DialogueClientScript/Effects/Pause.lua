--!strict
-- This effect pauses NPC dialogue until a specified amount of time passes.
-- Developer: Christian "Sudobeast" Toney

local Types = require(script.Parent.Parent.Types);

export type PauseEffectProperties = {

  -- The amount of seconds before the dialogue continues.
  seconds: number;

}

local shouldSkip = false;

return function(effectProperties: {[string]: any}): Types.Effect
  
  return {
    
    type = "effect";

    name = "Pause";

    run = function(isSkipping: boolean): ()

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

    getBreakpoints = function()

      return {}

    end;

    getMaxDimensions = function()

      return {x = 0, y = 0};

    end;

    onSkip = function(): ()

      shouldSkip = true;

    end;

  }
  
end;
