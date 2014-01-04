

----------------------------------------------------------------------------------
--       OPTION FRAME
----------------------------------------------------------------------------------

do 
	local options = ETW_Templates:CreatePortraitFrame("ETW_OptionFrame", UIParent, "ETW Options", ETW_OPTIONICON)
	options:SetPoint("CENTER")
	options:SetSize(250, 300)

	-- Extra tweaking because optionicon not same size
	options.portraitIcon:SetPoint("TOPLEFT", -2, 5)

	ETW_Templates:MakeFrameDraggable(options)
	options:Hide()

end


----------------------------------------------------------------------------------
--       CHECK BUTTONS
----------------------------------------------------------------------------------

-- 3D model rotation
do
	local button = ETW_Templates:CreateCheckButton("ETW_Options_ModelRotation", ETW_OptionFrame, "Rotate 3D models")
	button:SetPoint("TOPLEFT", 10, -70)
	button:HookScript("OnClick", function(self,event,arg1) 
		SymphonymConfig.options.rotate3DModel = self:GetChecked()
	end)

	ETW_OptionFrame.checkModelRotation = button
end

-- In combat question scanning
do
	local button = ETW_Templates:CreateCheckButton("ETW_Options_InCombatScan", ETW_OptionFrame, "Scan for unlocks in combat")
	button:SetPoint("TOPLEFT", 10, -100)
	button:HookScript("OnClick", function(self,event,arg1) 
		SymphonymConfig.options.scanInCombat = self:GetChecked()
	end)

	ETW_OptionFrame.checkInCombat = button
end

-- Show unlock popups
do
	local button = ETW_Templates:CreateCheckButton("ETW_Options_ShowUnlockPopup", ETW_OptionFrame, "Show unlock popups")
	button:SetPoint("TOPLEFT", 10, -130)
	button:HookScript("OnClick", function(self,event,arg1) 
		SymphonymConfig.options.showUnlockPopups = self:GetChecked()
	end)

	ETW_OptionFrame.checkUnlockPopup = button
end

-- Ignore question links
do
	local button = ETW_Templates:CreateCheckButton("ETW_Options_IgnoreLinks", ETW_OptionFrame, "Ignore question links")
	button:SetPoint("TOPLEFT", 10, -160)
	button:HookScript("OnClick", function(self,event,arg1) 
		SymphonymConfig.options.ignoreLinks = self:GetChecked()
	end)

	ETW_OptionFrame.checkIgnoreLinks = button
end


----------------------------------------------------------------------------------
--       SLIDERS
----------------------------------------------------------------------------------

do

	local slider = ETW_Templates:CreateSlider("ETW_Options_PageLimit", ETW_OptionFrame, "Question page limit", 1, 10, 300)
	slider:SetPoint("CENTER",0,-75)
	slider.description:SetText("Changing the page limit requires you to reload the UI or else errors might arise.")


	slider:HookScript("OnValueChanged", function(self,event,arg1)
		SymphonymConfig.options.pageLimit = math.floor(self:GetValue())
	end)

	ETW_OptionFrame.sliderPageLimit = slider

end


----------------------------------------------------------------------------------
--       Reset button
----------------------------------------------------------------------------------

do


	local button = CreateFrame("Button", "ETW_Options_ResetData", ETW_OptionFrame, "UIPanelButtonTemplate")
	button:SetSize(150, 30)
	button:SetPoint("TOP", 25, -40)
	button:SetText("Reset saved data")

	StaticPopupDialogs["ETW_ResetSavedData"] = {
		text = "Are you sure you wish to reset all question related data saved for \"Explore the World\"?|n|nDoing so requires you to reload the UI.",
		showAlert = true,
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			SymphonymConfig.questions = SymphonymConfig_Default.questions
			ETW_Utility:PrintToChat("Deleted saved data.")
		end,
		OnCancel = function (_,reason)

		end,
		sound = "GAMEDIALOGOPEN",
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}

	button:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			StaticPopup_Show ("ETW_ResetSavedData")
		end
	end)

	ETW_OptionFrame.buttonResetData = button

end

----------------------------------------------------------------------------------
--       VALUE INITIALIZATION
----------------------------------------------------------------------------------


ETW_OptionFrame:RegisterEvent("PLAYER_LOGIN")
ETW_OptionFrame:SetScript("OnEvent", function(self, event, ...)
	if(event == "PLAYER_LOGIN") then

		-- CheckButtons
		self.checkModelRotation:SetChecked(SymphonymConfig.options.rotate3DModel)
		self.checkInCombat:SetChecked(SymphonymConfig.options.scanInCombat)
		self.checkUnlockPopup:SetChecked(SymphonymConfig.options.showUnlockPopups)
		self.checkIgnoreLinks:SetChecked(SymphonymConfig.options.ignoreLinks)

		-- Sliders
		self.sliderPageLimit:SetValue(SymphonymConfig.options.pageLimit)
	end
end)