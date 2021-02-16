local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RemoteConnections = ReplicatedStorage:WaitForChild("DialogueMakerRemoteConnections");

local Dialogue = {};

function Dialogue.GoToDirectory(currentDirectory, targetPath)

  for index, directory in ipairs(targetPath) do
    if currentDirectory.Dialogue:FindFirstChild(directory) then
      currentDirectory = currentDirectory.Dialogue[directory];
    elseif currentDirectory.Responses:FindFirstChild(directory) then
      currentDirectory = currentDirectory.Responses[directory];
    elseif currentDirectory.Redirects:FindFirstChild(directory) then
      currentDirectory = currentDirectory.Redirects[directory];
    elseif currentDirectory:FindFirstChild(directory) then
      currentDirectory = currentDirectory[directory];
    end;
  end;

  return currentDirectory;
end;

function Dialogue.ReplaceVariablesWithValues(npc, text)

  for match in string.gmatch(text, "%[/variable=(.+)%]") do
    
    -- Get the match from the server
    local VariableValue = RemoteConnections.GetVariable:InvokeServer(npc, match);
    if VariableValue then
      text = text:gsub("%[/variable=(.+)%]",VariableValue);
    end;
    
  end;

  return text;
end;

function Dialogue.ClearResponses(responseContainer)
  for _, response in ipairs(responseContainer:GetChildren()) do
    if not response:IsA("UIListLayout") then
      response:Destroy();
    end;
  end;
end;

function Dialogue.DivideTextToFitBox(text, textContainer)

  local Line = textContainer.Line:Clone();
  Line.Name = "LineTest"
  Line.Visible = false;
  Line.Parent = textContainer;

  local Divisions = {};
  local Page = 1;

  for index, word in ipairs(text:split(" ")) do
    if index == 1 then
      Line.Text = word;
    else
      Line.Text = Line.Text.." "..word
    end;

    if not Divisions[Page] then Divisions[Page] = {}; end;

    if Line.TextFits then
      table.insert(Divisions[Page],word);
      Divisions[Page].FullText = Line.Text;
    elseif not Divisions[Page][1] then
      Line.Text = "";
      for _, letter in ipairs(word:split("")) do
        Line.Text = Line.Text..letter;
        if not Line.TextFits then
          -- Remove the letter from the text
          Line.Text = Line.Text:sub(1,string.len(Line.Text)-1);
          table.insert(Divisions[Page], Line.Text);
          Divisions[Page].FullText = Line.Text;

          -- Take it from the top
          Page = Page + 1;
          Divisions[Page] = {};
          Line.Text = letter;

        end;
      end;

      table.insert(Divisions[Page], Line.Text);
      Divisions[Page].FullText = Line.Text;

    else
      Page = Page + 1;
    end;
  end;

  Line:Destroy();

  return Divisions;

end;

return Dialogue;