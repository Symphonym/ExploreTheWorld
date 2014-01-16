
local POPUP_ALPHA = 0.9

local function createPopupFrame(name, title, icon)

	local popupFrame = ETW_Templates:CreatePortraitFrame(name, UIParent, title, ETW_ADDONICON)
	popupFrame:SetSize(250, 140)
	popupFrame:SetAlpha(POPUP_ALPHA)

	popupFrame.icon = popupFrame:CreateTexture()
	popupFrame.icon:SetTexture(icon)
	popupFrame.icon:SetSize(50, 50)
	popupFrame.icon:SetPoint("LEFT", 15, -28)

	ETW_Templates:MakeFrameDraggable(popupFrame, true)

	return popupFrame

end

----------------------------------------------------------------------------------
--       POPUP FRAME FOR QUEST UNLOCKS
----------------------------------------------------------------------------------


local ETW_PopupFrame = createPopupFrame("ETW_PopupFrame", "Question unlocked", ETW_UNLOCK_POPUP_ICON)
ETW_PopupFrame:SetPoint("TOP", 0, -100)

ETW_PopupFrame.text = ETW_PopupFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
ETW_PopupFrame.text:SetTextHeight(14)
ETW_PopupFrame.text:SetText("Quests unlocked")
ETW_PopupFrame.text:SetPoint("LEFT", 80, 19)

ETW_PopupFrame.unlockText = ETW_PopupFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
ETW_PopupFrame.unlockText:SetTextHeight(12)
ETW_PopupFrame.unlockText:SetPoint("LEFT", 80, 5)

ETW_PopupFrame.infoText = ETW_PopupFrame:CreateFontString(nil, "ARTWORK", "QuestTitleFontBlackShadow")
ETW_PopupFrame.infoText:SetTextHeight(14)
ETW_PopupFrame.infoText:SetPoint("CENTER", 25, -18)

ETW_PopupFrame.fading = false
ETW_PopupFrame.fadeAlpha = 1
ETW_PopupFrame.elapsedTime = 0

ETW_PopupFrame.itemUnlock = {}
ETW_PopupFrame.zoneUnlock = {}
ETW_PopupFrame.npcUnlock = {}
ETW_PopupFrame.worldObjectUnlock = {}
ETW_PopupFrame.progressUnlock = {}
ETW_PopupFrame.questionUnlock = {}

ETW_PopupFrame.itemUnlock.name = "|cFFD19D76" .. ETW_ITEM_UNLOCK_NAME .. "|r"
ETW_PopupFrame.zoneUnlock.name = "|cFF339504" .. ETW_ZONE_UNLOCK_NAME .. "|r"
ETW_PopupFrame.npcUnlock.name = "|cFF66A3C8" .. ETW_NPC_UNLOCK_NAME .. "|r"
ETW_PopupFrame.worldObjectUnlock.name = "|cFFEE7D0A" .. ETW_WORLDOBJECT_UNLOCK_NAME .. "|r"
ETW_PopupFrame.progressUnlock.name = "|cFFDB41A6" .. ETW_PROGRESS_UNLOCK_NAME .. "|r"
ETW_PopupFrame.questionUnlock.name = "|cFFFFF569" .. ETW_QUESTION_UNLOCK_NAME .. "|r"

function ETW_PopupFrame:resetUnlockVariables()
	self.unlockCount = 0

	self.itemUnlock.display = false
	self.zoneUnlock.display = false
	self.npcUnlock.display = false
	self.worldObjectUnlock.display = false
	self.progressUnlock.display = false
	self.questionUnlock.display = false

end

function ETW_PopupFrame:hidePopup()
	self:resetUnlockVariables()
	self:Hide()
end

function ETW_PopupFrame:restartFade()
	self.fading = false
	self:SetAlpha(POPUP_ALPHA)
end
function ETW_PopupFrame:continueFade()
	self.fading = true
	self.fadeAlpha = POPUP_ALPHA
	self.elapsedTime = 0
end

ETW_PopupFrame:SetScript("OnEnter", function(self, motion)
	self:restartFade()
end)
ETW_PopupFrame:SetScript("OnLeave", function(self, motion)
	self:continueFade()
end)

ETW_PopupFrame.acceptButton = CreateFrame("Button", nil, ETW_PopupFrame, "UIPanelButtonTemplate")
ETW_PopupFrame.acceptButton:SetText("View")
ETW_PopupFrame.acceptButton:SetSize(100, 28)
ETW_PopupFrame.acceptButton:SetPoint("BOTTOM", 30, 4)
ETW_PopupFrame.acceptButton:SetScript("PostClick", function(self, button, down)
	if(button == "LeftButton" and not down) then
		ETW_Frame:Show()
		ETW_PopupFrame:hidePopup()
	end
end)
ETW_PopupFrame.acceptButton:SetScript("OnEnter", function(self, motion)
	ETW_PopupFrame:restartFade()
end)
ETW_PopupFrame.acceptButton:SetScript("OnLeave", function(self, motion)
	ETW_PopupFrame:continueFade()
end)


ETW_PopupFrame:SetScript("OnUpdate", function(self, elapsed) 
	if(self.fading) then

		if(elapsed >= 0.1) then
			elapsed = 0.1
		end

		local fadeDuration, valueMax = 3, POPUP_ALPHA

		self.elapsedTime = self.elapsedTime + elapsed

		self.fadeAlpha = valueMax - ((self.elapsedTime/fadeDuration) * valueMax)
		if(self.fadeAlpha <= 0) then
			self.fading = false
			self.fadeAlpha = 0
			self:hidePopup()
		end

		self:SetAlpha(self.fadeAlpha)
	end
end)

ETW_PopupFrame:resetUnlockVariables()

ETW_PopupFrame:Hide()

function ETW_ShowUnlockPopup(itemUnlocks, zoneUnlocks, npcUnlocks, worldObjectUnlocks, progressUnlocks, questionUnlocks)

	local questsUnlocked = 0

	if(SymphonymConfig.options.showUnlockPopups) then
	
		local questTypeInfo = {}
		questTypeInfo.size = 0

		if (itemUnlocks and itemUnlocks > 0) then
			ETW_PopupFrame.itemUnlock.display = true
			questsUnlocked = questsUnlocked + itemUnlocks
			ETW_Utility:PrintToChat(" You unlocked " .. itemUnlocks .. " quest(s) from " .. ETW_PopupFrame.itemUnlock.name)
		end
		if (zoneUnlocks and zoneUnlocks > 0) then
			ETW_PopupFrame.zoneUnlock.display = true
			questsUnlocked = questsUnlocked + zoneUnlocks
			ETW_Utility:PrintToChat(" You unlocked " .. zoneUnlocks .. " quest(s) from " .. ETW_PopupFrame.zoneUnlock.name)
		end
		if (npcUnlocks and npcUnlocks > 0) then
			ETW_PopupFrame.npcUnlock.display = true
			questsUnlocked = questsUnlocked + npcUnlocks
			ETW_Utility:PrintToChat(" You unlocked " .. npcUnlocks .. " quest(s) from " .. ETW_PopupFrame.npcUnlock.name)
		end
		if (worldObjectUnlocks and worldObjectUnlocks > 0) then
			ETW_PopupFrame.worldObjectUnlock.display = true
			questsUnlocked = questsUnlocked + worldObjectUnlocks
			ETW_Utility:PrintToChat(" You unlocked " .. worldObjectUnlocks .. " quest(s) from " .. ETW_PopupFrame.worldObjectUnlock.name)
		end
		if (progressUnlocks and progressUnlocks > 0) then
			ETW_PopupFrame.progressUnlock.display = true
			questsUnlocked = questsUnlocked + progressUnlocks
			ETW_Utility:PrintToChat(" You unlocked " .. progressUnlocks .. " quest(s) from " .. ETW_PopupFrame.progressUnlock.name)
		end
		if (questionUnlocks and questionUnlocks > 0) then
			ETW_PopupFrame.questionUnlock.display = true
			questsUnlocked = questsUnlocked + questionUnlocks
			ETW_Utility:PrintToChat(" You unlocked " .. questionUnlocks .. " quest(s) from " .. ETW_PopupFrame.questionUnlock.name)
		end


		if(ETW_PopupFrame.itemUnlock.display == true) then table.insert(questTypeInfo, ETW_PopupFrame.itemUnlock.name) end
		if(ETW_PopupFrame.zoneUnlock.display == true) then table.insert(questTypeInfo, ETW_PopupFrame.zoneUnlock.name) end
		if(ETW_PopupFrame.npcUnlock.display == true) then table.insert(questTypeInfo, ETW_PopupFrame.npcUnlock.name) end
		if(ETW_PopupFrame.worldObjectUnlock.display == true) then table.insert(questTypeInfo, ETW_PopupFrame.worldObjectUnlock.name) end
		if(ETW_PopupFrame.progressUnlock.display == true) then table.insert(questTypeInfo, ETW_PopupFrame.progressUnlock.name) end
		if(ETW_PopupFrame.questionUnlock.display == true) then table.insert(questTypeInfo, ETW_PopupFrame.questionUnlock.name) end

		if(ETW_PopupFrame.itemUnlock.display == true) then questTypeInfo.size = questTypeInfo.size + 1 end
		if(ETW_PopupFrame.zoneUnlock.display == true) then questTypeInfo.size = questTypeInfo.size + 1 end
		if(ETW_PopupFrame.npcUnlock.display == true) then questTypeInfo.size = questTypeInfo.size + 1 end
		if(ETW_PopupFrame.worldObjectUnlock.display == true) then questTypeInfo.size = questTypeInfo.size + 1 end
		if(ETW_PopupFrame.progressUnlock.display == true) then questTypeInfo.size = questTypeInfo.size + 1 end
		if(ETW_PopupFrame.questionUnlock.display == true) then questTypeInfo.size = questTypeInfo.size + 1 end


		-- Format extra info text
		local extraText = ""
		for count, value in ipairs(questTypeInfo) do
			extraText = extraText .. value

			if(count < questTypeInfo.size) then
				extraText = extraText .. ", "
			end

			if(count == 3) then
				extraText = extraText .. "|n"
			end
		end

		if(questsUnlocked > 0) then
			ETW_PopupFrame.unlockCount = ETW_PopupFrame.unlockCount + questsUnlocked

			PlaySound("QUESTADDED")
			ETW_PopupFrame:Show()
			ETW_PopupFrame.unlockText:SetText(ETW_PopupFrame.unlockCount .. " quest(s) unlocked!")
			ETW_PopupFrame.infoText:SetText(extraText)

			ETW_PopupFrame.fading = true
			ETW_PopupFrame.fadeAlpha = POPUP_ALPHA
			ETW_PopupFrame.elapsedTime = 0
		end
	end
	
	return questsUnlocked

end


----------------------------------------------------------------------------------
--       POPUP FRAME FOR QUESTION LINKING
----------------------------------------------------------------------------------


local ETW_LinkPopupFrame = createPopupFrame("ETW_LinkPopupFrame", "Question link", ETW_CLASSICONS)
ETW_LinkPopupFrame:SetPoint("TOP", 0, -300)
ETW_LinkPopupFrame.redirectFunction = function(questionID) end

ETW_LinkPopupFrame.text = ETW_LinkPopupFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
ETW_LinkPopupFrame.text:SetTextHeight(14)
ETW_LinkPopupFrame.text:SetPoint("LEFT", 80, 19)

ETW_LinkPopupFrame.rankText = ETW_LinkPopupFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
ETW_LinkPopupFrame.rankText:SetTextHeight(12)
ETW_LinkPopupFrame.rankText:SetPoint("LEFT", 80, 7)

ETW_LinkPopupFrame.versionText = ETW_LinkPopupFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
ETW_LinkPopupFrame.versionText:SetTextHeight(10)
ETW_LinkPopupFrame.versionText:SetPoint("TOPLEFT", 62, -24)

ETW_LinkPopupFrame.extraText = ETW_LinkPopupFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
ETW_LinkPopupFrame.extraText:SetTextHeight(12)
ETW_LinkPopupFrame.extraText:SetPoint("CENTER", 10, -18)

ETW_LinkPopupFrame.acceptButton = CreateFrame("Button", nil, ETW_LinkPopupFrame, "UIPanelButtonTemplate")
ETW_LinkPopupFrame.acceptButton:SetText("View")
ETW_LinkPopupFrame.acceptButton:SetSize(60, 28)
ETW_LinkPopupFrame.acceptButton:SetPoint("BOTTOM", -20, 4)
ETW_LinkPopupFrame.acceptButton:SetScript("PostClick", function(self, button, down)
	if(button == "LeftButton" and not down) then
		ETW_LinkPopupFrame.redirectFunction(ETW_LinkPopupFrame.questionID)
		ETW_LinkPopupFrame:Hide()
	end
end)

ETW_LinkPopupFrame.declineButton = CreateFrame("Button", nil, ETW_LinkPopupFrame, "UIPanelButtonTemplate")
ETW_LinkPopupFrame.declineButton:SetText("Close")
ETW_LinkPopupFrame.declineButton:SetSize(60, 28)
ETW_LinkPopupFrame.declineButton:SetPoint("BOTTOM", 45, 4)
ETW_LinkPopupFrame.declineButton:SetScript("PostClick", function(self, button, down)
	if(button == "LeftButton" and not down) then
		ETW_LinkPopupFrame:Hide()
	end
end)
ETW_LinkPopupFrame:Hide()


-- REMOVE TEST LINK POPUP
function ETW_ShowLinkPopup(sender, senderRank, senderVersion, questionID, redirectFunction)
	
	PlaySoundFile(ETW_POPUP_SOUND)
	local class, classFileName = UnitClass("player", sender)
	local senderLvl = UnitLevel("player", sender)
	
	ETW_LinkPopupFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]))

	ETW_LinkPopupFrame.text:SetText(sender .. "  [Lvl. " .. senderLvl .. "]")
	ETW_LinkPopupFrame.rankText:SetText(senderRank)
	ETW_LinkPopupFrame.versionText:SetText("Sender using version: " .. senderVersion)
	ETW_LinkPopupFrame.extraText:SetText("Linked #" .. questionID)
	ETW_LinkPopupFrame.questionID = questionID
	ETW_LinkPopupFrame.redirectFunction = redirectFunction
	ETW_LinkPopupFrame:Show()

end