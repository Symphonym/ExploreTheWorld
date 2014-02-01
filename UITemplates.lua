

ETW_Templates = {}

-- Ensures that new frames in the medium strata are always ontop of eachother
ETW_Templates.mediumLevel = 1
function ETW_Templates:GetMediumLevel()
	self.mediumLevel = self.mediumLevel + 1
	return self.mediumLevel
end

-------------------------------------------------------------------------------------
--  UI frame templates
-------------------------------------------------------------------------------------

-- Portrait frame template
function ETW_Templates:CreatePortraitFrame(globalName, parent, title, portraitIcon)
	local frame = CreateFrame("Frame", globalName, parent, "PortraitFrameTemplate")
	frame:SetSize(300, 200)

	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(ETW_Templates:GetMediumLevel())
	frame:SetToplevel(true)

	frame.title = frame.TitleText
	frame.title:SetText(title)

	frame.portraitIcon = _G[globalName.."Portrait"]
	frame.portraitIcon:SetTexture(portraitIcon)

	return frame
end

-- Checkbutton template
function ETW_Templates:CreateCheckButton(globalName, parent, title)
	local button = CreateFrame("CheckButton", globalName, parent, "InterfaceOptionsCheckButtonTemplate")
	button:SetSize(30, 30)

	button.title = _G[globalName.."Text"]
	button.title:SetText(title)
	button.title:SetFontObject("GameFontNormal")

	return button
end

-- Slider template
function ETW_Templates:CreateSlider(globalName, parent, title, step, min, max)
	local slider = CreateFrame("Slider", globalName , parent, "OptionsSliderTemplate")
	slider:SetValueStep(step)
	slider:SetMinMaxValues(min, max)
	slider:SetOrientation("HORIZONTAL")
	slider:SetWidth(200)

	-- Slider title, displayed at top
	slider.title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	slider.title:SetPoint("TOP", 0, 15)
	slider.title:SetText(title)

	-- Slider low/high text
	slider.lowText = _G[globalName.."Low"]
	slider.lowText:SetText(min)

	slider.highText = _G[globalName.."High"]
	slider.highText:SetText(max)

	-- Editable value box for the slider
	slider.valueBox = CreateFrame("EditBox", globalName, slider, "InputBoxTemplate")
	slider.valueBox:SetSize(60, 30)
	slider.valueBox:SetPoint("BOTTOM", 0, -24)
	slider.valueBox:SetAutoFocus(false)
	slider.valueBox:SetJustifyH("CENTER")

	slider.valueBox:SetScript("OnEditFocusGained", function(self)
		self:SetText("")
	end)
	slider.valueBox:SetScript("OnEditFocusLost", function(self)
		self:SetText(math.floor(slider:GetValue()))
	end)
	slider.valueBox:SetScript("OnEnterPressed", function(self)
		local number = tonumber(self:GetText())

		if(number ~= nil) then
			local min, max = slider:GetMinMaxValues()
			if(number > max) then number = max
			elseif(number < min) then number = min end

			slider:SetValue(number)
		end
	end)

	-- Display slider value in valueBox
	slider:SetScript("OnValueChanged", function(self, value)
		self.valueBox:SetText(math.floor(value))
		self.valueBox:ClearFocus()
	end)

	-- Extra description below the slider
	slider.description = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	slider.description:SetWidth(slider:GetWidth())
	slider.description:SetTextHeight(10)
	slider.description:SetPoint("TOP", slider, "BOTTOM", 0, -28)

	return slider
end

-- Edit box template
function ETW_Templates:CreateEditBox(globalName, parent, title)

	local editbox = CreateFrame("EditBox", globalName, parent, "InputBoxTemplate")
	editbox:SetSize(100, 30)

	editbox.text = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	editbox.text:SetPoint("TOPLEFT", 2, 22)
	editbox.text:SetText(title)

	return editbox
end

-- Question 3D model frame template
function ETW_Templates:CreateRotatingModel(globalName, parent)

	local model = CreateFrame("PlayerModel",globalName, parent)
	model:SetSize(100, 100)
	model.rotation = 0
	model:SetScript("OnUpdate", function(self, elapsed)

		if(SymphonymConfig.options.rotate3DModel and self:IsShown()) then
			self.rotation = self.rotation + elapsed

			if(self.rotation >= 2*math.pi) then
				self.rotation = 2*math.pi - self.rotation
			end

			self:SetFacing(self.rotation)
		end
	end)
	model.resetButton = CreateFrame("Button", globalName.."ResetButton", model, "UIPanelButtonTemplate")
	model.resetButton:SetText("Reset")
	model.resetButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
	model.resetButton:SetSize(45, 20)

	return model
end

-- Status bar
function ETW_Templates:CreateStatusBar(globalName, parent, minValue, maxValue, barColor, width, height)

	local statusFrame = CreateFrame("Frame", globalName.."Frame", parent, "InsetFrameTemplate3")
	statusFrame:SetSize(width,height)

	local statusbar = CreateFrame("StatusBar", globalName, statusFrame)
	statusbar:SetPoint("CENTER")
	statusbar:SetSize(width-6,height-9)
	
	-- Statusbar background
	statusbar.bg = statusbar:CreateTexture(nil,"BACKGROUND",nil,-8)
	statusbar.bg:SetAllPoints(statusbar)
	statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar.blp")
	statusbar.bg:SetVertexColor(unpack(barColor),0.2)
	
	-- Statusbar texture
	local texture = statusbar:CreateTexture(nil,"BACKGROUND",nil,-6)
	texture:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar.blp")
	texture:SetVertexColor(unpack(barColor),1)
	statusbar:SetStatusBarTexture(texture)
	statusbar:SetStatusBarColor(unpack(barColor))

	statusbar.text = statusbar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	statusbar.text:SetPoint("CENTER")

	-- Values
	statusbar:SetMinMaxValues(minValue, maxValue)
	statusbar:SetValue(0)

	statusFrame.bar = statusbar

	return statusFrame
end


-------------------------------------------------------------------------------------
--  UI utility templates
-------------------------------------------------------------------------------------


function ETW_Templates:MakeFrameDraggable(frame, wholeFrame)

	frame:RegisterForDrag("LeftButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)

	-- Drag by title region
	if(wholeFrame == nil) then
		frame:CreateTitleRegion():SetSize(frame:GetWidth(), 20)
		frame:GetTitleRegion():SetPoint("TOPLEFT", frame)
		frame:SetScript("OnDragStart", function(self, button)
			if self:GetTitleRegion():IsMouseOver() then
				self:StartMoving()
			end
		end)

	-- Drag by whole frame
	else
		frame:SetScript("OnDragStart", function(self, button)
				self:StartMoving()
		end)
	end

	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
end