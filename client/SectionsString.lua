--[[
	Properties 
		Text
		TextColor3
		TextTransparency
		Font
		TextSize
		TextStrokeColor3
		TextStrokeTransparency
--]]
local module = {}
local LableTable = {}
function module.SetTextLable(Lable)
	LableTable[Lable] = {
		Index = 0;
		TextTransparency = Lable.TextTransparency;
	}
	local UiList = Instance.new("UIListLayout",Lable)
	UiList.SortOrder = Enum.SortOrder.LayoutOrder
	
	local function DoTextXAlignment()
		if Lable.TextXAlignment == Enum.TextXAlignment.Center then
			UiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		elseif Lable.TextXAlignment == Enum.TextXAlignment.Left then
			UiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
		elseif Lable.TextXAlignment == Enum.TextXAlignment.Right then
			UiList.HorizontalAlignment = Enum.HorizontalAlignment.Right
		end
	end
	Lable:GetPropertyChangedSignal("TextXAlignment"):Connect(function()
		DoTextXAlignment()
	end)
	DoTextXAlignment()
	
	local function DoTextYAlignment()
		if Lable.TextYAlignment == Enum.TextYAlignment.Center then
			UiList.VerticalAlignment = Enum.VerticalAlignment.Center
		elseif Lable.TextYAlignment == Enum.TextYAlignment.Top then
			UiList.VerticalAlignment = Enum.VerticalAlignment.Top
		elseif Lable.TextYAlignment == Enum.TextYAlignment.Bottom then
			UiList.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
	end
	Lable:GetPropertyChangedSignal("TextYAlignment"):Connect(function()
		DoTextYAlignment()
	end)
	DoTextYAlignment()
	UiList.FillDirection = Enum.FillDirection.Horizontal
	Lable.TextTransparency = 1
end
function module.new(Lable,Properties)
	if LableTable[Lable] ~= nil then
		if Properties.Text == nil then
			warn(Lable.Name .. ".Text is can't be nil")
			return
		end
		local NewTextLable = Instance.new("TextLabel")
		NewTextLable.BackgroundTransparency = 1
		NewTextLable.LayoutOrder = LableTable[Lable].Index
		LableTable[Lable].Index = LableTable[Lable].Index + 1
		
		NewTextLable.Text = Properties.Text
		if Properties.TextColor3 == nil then
			NewTextLable.TextColor3 = Lable.TextColor3
		else
			NewTextLable.TextColor3 = Properties.TextColor3
		end
		
		if Properties.TextTransparency == nil then
			NewTextLable.TextTransparency = LableTable[Lable].TextTransparency
		else
			NewTextLable.TextTransparency = Properties.TextTransparency
		end
		
		if Properties.Font == nil then
			NewTextLable.Font = Lable.Font
		else
			NewTextLable.Font = Properties.Font
		end
		
		if Properties.TextSize == nil then
			NewTextLable.TextSize = Lable.TextSize
		else
			NewTextLable.TextSize = Properties.TextSize
		end
		
		if Properties.TextStrokeColor3 == nil then
			NewTextLable.TextStrokeColor3 = Lable.TextStrokeColor3
		else
			NewTextLable.TextStrokeColor3 = Properties.TextStrokeColor3
		end
		
		if Properties.TextStrokeTransparency == nil then
			NewTextLable.TextStrokeTransparency = Lable.TextStrokeTransparency
		else
			NewTextLable.TextStrokeTransparency = Properties.TextStrokeTransparency
		end
		
		NewTextLable.Parent = Lable
		
		NewTextLable.Size = UDim2.new(0,NewTextLable.TextBounds.X,0,NewTextLable.TextBounds.Y)
		return Properties.Text
	else
		warn(Lable.Name .. " is not a SectionsString")
	end
end
return module
