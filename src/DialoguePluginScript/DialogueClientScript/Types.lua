-- Internal effect types

export type Effect = {

  -- The effect name.
  name: string;

  -- The function that runs when the effect is called.
  run: (...any) -> (TextLabel | any);

}

export type UseEffectFunction = ({
  name: string;
  [string]: any;  
}) -> Effect;

return {};