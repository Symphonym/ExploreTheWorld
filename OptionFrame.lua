

----------------------------------------------------------------------------------
--       OPTION FRAME
----------------------------------------------------------------------------------

do 
	local options = CreateFrame("Frame", "ETW_OptionFrame", UIParent, "PortraitFrameTemplate")
	options:SetFrameStrata("HIGH")
	options:SetFrameLevel(15)
	options:SetPoint("CENTER")
	options:SetSize(250, 300)

	ETW_givePortraitFrameIcon(options, ETW_OPTIONICON)
	-- Extra tweaking because optionicon not same size
	options.portraitIcon:SetPoint("TOPLEFT", -2, 5)

	options.title = options:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	options.title:SetText("ETW Options")
	options.title:SetTextHeight(13)
	options.title:SetPoint("TOP", 20, -5)

	options:RegisterForDrag("LeftButton")
	options:EnableMouse(true)
	options:SetMovable(true)

	options:SetScript("OnDragStart", function(self, button)
		self:StartMoving()
	end)
	options:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	options:Hide()

end


----------------------------------------------------------------------------------
--       CHECK BUTTONS
----------------------------------------------------------------------------------

ETW_OptionFrame.checkModelRotation = CreateFrame("CheckButton", "ETW_OptionFrame.checkModelRotation", ETW_OptionFrame, "UICheckButtonTemplate")
ETW_OptionFrame.checkModelRotation:SetPoint("LEFT", 10, 30)
ETW_OptionFrame.checkModelRotation:SetSize(30, 30)
ETW_OptionFrame.checkModelRotation:SetChecked(SymphonymConfig.options.rotate3DModel)
ETW_OptionFrame.checkModelRotation.text = _G["ETW_OptionFrame.checkModelRotationText"]
ETW_OptionFrame.checkModelRotation.text:SetText("Rotate 3D models")
ETW_OptionFrame.checkModelRotation:SetScript("OnClick", function(self,event,arg1) 
	SymphonymConfig.options.rotate3DModel = self:GetChecked()
end)

ETW_OptionFrame.checkInCombat = CreateFrame("CheckButton", "ETW_OptionFrame.checkInCombat", ETW_OptionFrame, "UICheckButtonTemplate")
ETW_OptionFrame.checkInCombat:SetPoint("LEFT", 10, 0)
ETW_OptionFrame.checkInCombat:SetSize(30, 30)
ETW_OptionFrame.checkInCombat:SetChecked(SymphonymConfig.options.scanInCombat)
ETW_OptionFrame.checkInCombat.text = _G["ETW_OptionFrame.checkInCombatText"]
ETW_OptionFrame.checkInCombat.text:SetText("Scan for question unlocks in combat")
ETW_OptionFrame.checkInCombat:SetScript("OnClick", function(self,event,arg1)
	SymphonymConfig.options.scanInCombat = self:GetChecked()
end)

ETW_OptionFrame.checkUnlockPopup = CreateFrame("CheckButton", "ETW_OptionFrame.checkUnlockPopup", ETW_OptionFrame, "UICheckButtonTemplate")
ETW_OptionFrame.checkUnlockPopup:SetPoint("LEFT", 10, -30)
ETW_OptionFrame.checkUnlockPopup:SetSize(30, 30)
ETW_OptionFrame.checkUnlockPopup:SetChecked(SymphonymConfig.options.showUnlockPopups)
ETW_OptionFrame.checkUnlockPopup.text = _G["ETW_OptionFrame.checkUnlockPopupText"]
ETW_OptionFrame.checkUnlockPopup.text:SetText("Show unlock popups")
ETW_OptionFrame.checkUnlockPopup:SetScript("OnClick", function(self,event,arg1) 
	SymphonymConfig.options.showUnlockPopups = self:GetChecked()
end)

ETW_OptionFrame.checkIgnoreLinks = CreateFrame("CheckButton", "ETW_OptionFrame.checkIgnoreLinks", ETW_OptionFrame, "UICheckButtonTemplate")
ETW_OptionFrame.checkIgnoreLinks:SetPoint("LEFT", 10, -60)
ETW_OptionFrame.checkIgnoreLinks:SetSize(30, 30)
ETW_OptionFrame.checkIgnoreLinks:SetChecked(SymphonymConfig.options.ignoreLinks)
ETW_OptionFrame.checkIgnoreLinks.text = _G["ETW_OptionFrame.checkIgnoreLinksText"]
ETW_OptionFrame.checkIgnoreLinks.text:SetText("Ignore question links")
ETW_OptionFrame.checkIgnoreLinks:SetScript("OnClick", function(self,event,arg1) 
	SymphonymConfig.options.ignoreLinks = self:GetChecked()
end)

----------------------------------------------------------------------------------
--       SLIDERS
----------------------------------------------------------------------------------

ETW_OptionFrame.sliderPageLimit = CreateFrame("Slider","ETW_OptionFrame.sliderPageLimit",ETW_OptionFrame,"OptionsSliderTemplate") --frameType, frameName, frameParent, frameTemplate   
ETW_OptionFrame.sliderPageLimit:SetPoint("CENTER",0,-110)
ETW_OptionFrame.sliderPageLimit.textLow = _G["ETW_OptionFrame.sliderPageLimitLow"]
ETW_OptionFrame.sliderPageLimit.textHigh = _G["ETW_OptionFrame.sliderPageLimitHigh"]
ETW_OptionFrame.sliderPageLimit.text = _G["ETW_OptionFrame.sliderPageLimitText"]
ETW_OptionFrame.sliderPageLimit:SetMinMaxValues(10, 300)
ETW_OptionFrame.sliderPageLimit:SetWidth(200)
ETW_OptionFrame.sliderPageLimit.minValue, ETW_OptionFrame.sliderPageLimit.maxValue = ETW_OptionFrame.sliderPageLimit:GetMinMaxValues() 
ETW_OptionFrame.sliderPageLimit.textLow:SetText(ETW_OptionFrame.sliderPageLimit.minValue)
ETW_OptionFrame.sliderPageLimit.textHigh:SetText(ETW_OptionFrame.sliderPageLimit.maxValue)
ETW_OptionFrame.sliderPageLimit.text:SetText("Question page limit: " .. SymphonymConfig.options.pageLimit)
ETW_OptionFrame.sliderPageLimit.text:SetJustifyH("LEFT")
ETW_OptionFrame.sliderPageLimit:SetValue(SymphonymConfig.options.pageLimit)
ETW_OptionFrame.sliderPageLimit:SetValueStep(1)


ETW_OptionFrame.sliderPageLimit:SetScript("OnValueChanged", function(self,event,arg1)
	self.text:SetText("Question page limit: " .. math.floor(self:GetValue()))
	SymphonymConfig.options.pageLimit = math.floor(self:GetValue())
end)

ETW_OptionFrame.sliderPageLimit.infoText = ETW_OptionFrame.sliderPageLimit:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
ETW_OptionFrame.sliderPageLimit.infoText:SetText("Changing the page limit requires a UI reload")
ETW_OptionFrame.sliderPageLimit.infoText:SetTextHeight(10)
ETW_OptionFrame.sliderPageLimit.infoText:SetPoint("CENTER", 0, -24)

----------------------------------------------------------------------------------
--       VALUE INITIALIZATION
----------------------------------------------------------------------------------


ETW_OptionFrame:RegisterEvent("PLAYER_LOGIN")
ETW_OptionFrame:SetScript("OnEvent", function(self, event, ...)
	if(event == "PLAYER_LOGIN") then

		-- CheckButtons
		ETW_OptionFrame.checkModelRotation:SetChecked(SymphonymConfig.options.rotate3DModel)
		ETW_OptionFrame.checkInCombat:SetChecked(SymphonymConfig.options.scanInCombat)
		ETW_OptionFrame.checkUnlockPopup:SetChecked(SymphonymConfig.options.showUnlockPopups)
		ETW_OptionFrame.checkIgnoreLinks:SetChecked(SymphonymConfig.options.ignoreLinks)

		-- Sliders
		ETW_OptionFrame.sliderPageLimit:SetValue(SymphonymConfig.options.pageLimit)
	end
end)