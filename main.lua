
--[[ TODO:
	New categories:
		Investigation: Locate place and answer a question related to the surroundings.
		Tracking: Locate and target an NPC
					Have questionbox be locked and have the text in it always be the name
					of your latest target. When the text in it is the npc, then press answer.
		Explore: Find semi obscure zones, just by exploring them.


]]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       DECLARE VARIABLES
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Allocate tables
local frameName = "ETW_Frame"
ETW_Frame = {}

-- Scanner functions
local scanInventory, scanZone, scanNpc, scanWorldObjects, scanProgress

-- Updating functions
local updatePageIndex, updateProgressText, updateScrollbarSize,
	updateQuestList

-- Utility functions
local changePageIndex, showUnlockPopup, getLoreRank,
	displayQuestion, createListButton, addETWQuestion

-- Slash command
SLASH_EXPLORETHEWORLD1, SLASH_EXPLORETHEWORLD2 = '/etw', '/exploretheworld'
function SlashCmdList.EXPLORETHEWORLD(msg, editbox)
	ETW_Frame:Show()
end
















--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Updating functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- Updates the displayed page index and enables/disables page switching buttons
local function updatePageIndex()
	ETW_Frame.pageIndexBox:SetText(tostring((ETW_Frame.questionList.pageIndex+1).."/"..(ETW_Frame.questionList.maxPageIndex+1)))
	
	-- Enable/disable page switching buttons depending on pageindex
	if(ETW_Frame.questionList.pageIndex == ETW_Frame.questionList.maxPageIndex) then
		ETW_Frame.rightPageButton:Disable()
		ETW_Frame.rightEndPageButton:Disable()
	else
		ETW_Frame.rightPageButton:Enable()
		ETW_Frame.rightEndPageButton:Enable()
	end

	if(ETW_Frame.questionList.pageIndex == 0) then
		ETW_Frame.leftPageButton:Disable()
		ETW_Frame.leftEndPageButton:Disable()
	else
		ETW_Frame.leftPageButton:Enable()
		ETW_Frame.leftEndPageButton:Enable()
	end
end

-- Refresh progress text of completed qs
local function updateProgressText()
	ETW_Frame.progressText:SetText(SymphonymConfig.questions.completed .." / " .. ETW_LoreQuestions.size .. " completed quests")
end

-- Update scrollbar size, making it exactly fit the window
local function updateScrollbarSize()

	local maxScroll = (ETW_LISTITEM_HEIGHT*ETW_Frame.questionList.pages[ETW_Frame.questionList.pageIndex].count) - ETW_Frame.scrollFrame:GetHeight()
	if(maxScroll < 0) then
		ETW_Frame.scrollBar:SetValue(0)
		ETW_Frame.scrollBar:Disable()
	else
		ETW_Frame.scrollBar:Enable()
		ETW_Frame.scrollBar:SetMinMaxValues(1, maxScroll)
		ETW_Frame.scrollBar:SetValueStep(1)

		if(ETW_Frame.scrollBar:GetValue() <= 0) then
			ETW_Frame.scrollBar:SetValue(1)
		end
	end
end

-- Sort and update position of questions in the list
function updateQuestList()

	-- SHITTY, FUNCTIONAL, SORTING, SFS FOR SHORT
	-- default sorting won't work due to it not being a consecutive array, I THINK

	local categorySorted = {}
	local buttonIndex = 0

	-- Divide questions into separate tables by category
	for _, value in pairs(ETW_Frame.questionList.pages[ETW_Frame.questionList.pageIndex].items) do
		if(categorySorted[value.category] == nil) then
			categorySorted[value.category] = {}
		end

		-- Sorting checks TODO: Tidy this up
		local sortingConfig = SymphonymConfig.questions.sorting
		local questionConfig = SymphonymConfig.questions[value.ID]

		local passesCategorySort = 
			(sortingConfig.showExplore and value.category == ETW_EXPLORE_CATEGORY) or
			(sortingConfig.showInvestigation and value.category == ETW_INVESTIGATION_CATEGORY) or
			(sortingConfig.showTracking and value.category == ETW_TRACKING_CATEGORY)

		local passesCompletedQuestCheck = 
			(sortingConfig.showCompleted == true and ETW_isQuestionDone(value) == true)
		local isCompletedQuest = ETW_isQuestionDone(value)


		local passesNewQuestCheck = 
			(sortingConfig.showNewQuests and questionConfig ~= nil and questionConfig.newQuest == true)
		local isNewQuest = questionConfig ~= nil and questionConfig.newQuest == true

		-- This took ages to finally get working as intended, I'm still not sure if I understand why it works correctly
		-- ,but it does, so please don't touch :[
		if (passesNewQuestCheck == true or passesCompletedQuestCheck == true or 
			(passesCategorySort == true and passesNewQuestCheck == false and isCompletedQuest == false and isNewQuest == false) or
			(passesCategorySort == true and passesCompletedQuestCheck == false and isCompletedQuest == false and isNewQuest == false)) then
			
			if(ETW_Frame.searchBox:GetText() == "" or ETW_Frame.searchBox:GetText() == "Search" or
				(string.find(string.lower(value.name), string.lower(ETW_Frame.searchBox:GetText())) ~= nil) or
				(string.find(string.lower(tostring(value.ID)), string.lower(ETW_Frame.searchBox:GetText())) ~= nil)) then

				value.buttonIndex = buttonIndex
				value.pageIndex = ETW_Frame.questionList.pageIndex

				ETW_Frame.questionList.buttons[buttonIndex]:setQuestionToButton(value)
				ETW_Frame.questionList.buttons[buttonIndex]:Show()
				buttonIndex = buttonIndex + 1

				table.insert(categorySorted[value.category], value)

			end
		end
				

	end

	for remainingButtonIndex = buttonIndex, SymphonymConfig.options.pageLimit, 1 do
		ETW_Frame.questionList.buttons[remainingButtonIndex]:Hide()
	end

	-- Simply iterate the above table, guaranteeing they will be sorted categorywise
	local index = 0
	for _, categoryList in pairs(categorySorted) do
		for _, question in pairs(categoryList) do

			ETW_Frame.questionList.buttons[question.buttonIndex]:SetPoint(ETW_LISTITEM_ALIGN, 0, index * -ETW_LISTITEM_HEIGHT) --question.listItem:SetPoint("TOP", 0, index * -ETW_LISTITEM_HEIGHT)
			index = index + 1

		end
	end
	ETW_Frame.questionList.pages[ETW_Frame.questionList.pageIndex].count = index

	updateScrollbarSize()

end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Utility functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------




-- Changes page index of question list
local function changePageIndex(index)
	if(index < 0) then
		ETW_Frame.questionList.pageIndex = 0
	elseif(index > ETW_Frame.questionList.maxPageIndex) then
		ETW_Frame.questionList.pageIndex = ETW_Frame.questionList.maxPageIndex
	else
		ETW_Frame.questionList.pageIndex = index
	end
	updatePageIndex()
	updateQuestList()
end

-- Shows unlock popup if more than 0 unlocks where specified as arguments
local function showUnlockPopup(itemUnlocks, zoneUnlocks, npcUnlocks, worldObjectUnlocks, progressUnlocks)
	local questsUnlocked = ETW_ShowUnlockPopup(itemUnlocks, zoneUnlocks, npcUnlocks, worldObjectUnlocks, progressUnlocks)

	-- If new quests were unlocked, move to the last page as new quests will be pushed there
	if(questsUnlocked > 0) then
		changePageIndex(ETW_Frame.questionList.maxPageIndex)
	end
end

-- Retrieves the current lore rank
local function getLoreRank()
	return ETW_GetLoreRank((SymphonymConfig.questions.completed / ETW_LoreQuestions.size) * 100)
end


local function displayQuestion(question)

	local questionFrame = ETW_Frame.questionFrame

	-- Set questionFrame info to the corresponding data
	questionFrame.question = question
	questionFrame.titleFrame.title:SetText(question.name)
	questionFrame.titleFrame.categoryIcon:SetTexture(question.category)
	questionFrame.descriptionFrame.text:SetText(question.description)
	questionFrame.imageFrame.image:SetTexture(question.texturepath) -- Texture data
	questionFrame.imageFrame.image:SetSize(question.texturewidth, question.textureheight-5)
	questionFrame.imageFrame.image:SetTexCoord(question.textureCropLeft, question.textureCropRight, question.textureCropTop, question.textureCropBottom)
	questionFrame.imageFrame:SetSize(question.texturewidth, question.textureheight)
	questionFrame.answerBox:SetText("") -- Clear text of answerbox
	questionFrame.answerBox.fade.text:SetText("") -- Clear fading text

	-- Display author text
	if(question.author == nil) then
		questionFrame.authorText:SetText("Question made by: Jakob Larsson (Addon author)")
	else
		questionFrame.authorText:SetText("Question made by: " .. question.author)
	end

	-- Display "selectArrow" next to list button
	ETW_Frame.questionList.selectArrow:Show()
	ETW_Frame.questionFrame.selectUpArrow:Hide()
	ETW_Frame.questionFrame.selectDownArrow:Hide()
	ETW_Frame.questionList.selectArrow:SetPoint("LEFT", ETW_Frame.questionList.buttons[question.buttonIndex], "LEFT", -20, 0)

	-- Remove the "new quest" blue glow
	if(SymphonymConfig.questions[question.ID] and SymphonymConfig.questions[question.ID].newQuest) then
		SymphonymConfig.questions[question.ID].newQuest = nil
		ETW_Frame.questionList.buttons[question.buttonIndex]:highlightNone()
	end

	-- Disable answerBox and button if question is answered already
	if(ETW_isQuestionDone(question)) then
		questionFrame:completeQuestion()
		questionFrame.answerBox:SetText(SymphonymConfig.questions[question.ID].answer)
	else
		questionFrame.confirmButton:Enable()
		questionFrame.answerBox:Enable()

		-- Reset alpha when switching between questions
		questionFrame.answerBox.fade:SetAlpha(0)
		questionFrame.answerBox.fade.text:SetAlpha(0)
	end

	-- Display model, if any
	if(question.modelId ~= nil or question.modelPath ~= nil) then

		questionFrame.imageFrame.npcModel:ClearModel()
		questionFrame.imageFrame.miscModel:ClearModel()

		-- Set model
		if(question.modelId ~= nil) then
			questionFrame.imageFrame.npcModel:SetDisplayInfo(tonumber(ETW_convertBase64(question.modelId)))
			questionFrame.imageFrame.npcModel:SetPortraitZoom(questionFrame.imageFrame.npcModel.zoom)
			questionFrame.imageFrame.npcModel:Show()

			questionFrame.imageFrame.miscModel:Hide()
		elseif(question.modelPath ~= nil) then

			-- When it is in encrypted form, escaping backslashes is not required and actually invalidates the path
			local modelPath = string.gsub(tostring(ETW_convertBase64(question.modelPath)), "\\\\", "\\")

			questionFrame.imageFrame.miscModel:SetModel(modelPath)
			questionFrame.imageFrame.miscModel:SetCamDistanceScale(questionFrame.imageFrame.miscModel.zoom)
			questionFrame.imageFrame.miscModel:Show()

			questionFrame.imageFrame.npcModel:Hide()
		end

		-- Model Y offset, to make it look tidy
		if(question.modelYOffset ~= nil) then
			questionFrame.imageFrame.miscModel:SetPosition(0,0,-0.1+question.modelYOffset)
		else
			questionFrame.imageFrame.miscModel:SetPosition(0,0,-0.1)
			questionFrame.imageFrame.npcModel:SetPosition(0,0,-0.1)
		end

		-- Misc model zoom
		if(question.modelZoom ~= nil) then
			questionFrame.imageFrame.miscModel:SetCamDistanceScale(question.modelZoom)
		end

	else
		questionFrame.imageFrame.npcModel:Hide()
		questionFrame.imageFrame.miscModel:Hide()
	end

	-- Set custom functionality depending on category
	if(question.category == ETW_EXPLORE_CATEGORY or question.category == ETW_TRACKING_CATEGORY) then
		questionFrame.answerBox:Disable()

		if not (ETW_isQuestionDone(question)) then

			-- Text in answerbox on Tracking category will always show name of targeted npc
			if(question.category == ETW_TRACKING_CATEGORY) then
				questionFrame.answerBox:RegisterEvent("PLAYER_TARGET_CHANGED")

				if(UnitName("target") ~= nil) then
					questionFrame.answerBox:SetText(UnitName("target"))
				else
					questionFrame.answerBox:SetText("No target :[")
				end

				questionFrame.answerBox:SetScript("OnEvent", function(self, event, ...)
					if(event == "PLAYER_TARGET_CHANGED") then
						if(UnitName("target") ~= nil) then
							questionFrame.answerBox:SetText(UnitName("target"))
						else
							questionFrame.answerBox:SetText("No target :[")
						end
					end
				end)

			-- Text in answerbox on Explore category will always show name of the current zone
			elseif(question.category == ETW_EXPLORE_CATEGORY) then
				questionFrame.answerBox:RegisterEvent("ZONE_CHANGED_NEW_AREA")
				questionFrame.answerBox:RegisterEvent("ZONE_CHANGED")

				questionFrame.answerBox:SetText(GetSubZoneText())

				if(string.len(questionFrame.answerBox:GetText()) <= 0) then
					questionFrame.answerBox:SetText(GetRealZoneText())
				end

				questionFrame.answerBox:SetScript("OnEvent", function(self, event, ...)
					if(event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED") then
						self:SetText(GetSubZoneText())

						if(string.len(self:GetText()) <= 0) then
							self:SetText(GetRealZoneText())
						end
					end
				end)
			end
		else
			questionFrame.answerBox:unregisterInputEvents()
		end

	else
		ETW_Frame.questionFrame.answerBox:Enable()
		ETW_Frame.questionFrame.answerBox:unregisterInputEvents()
	end

	PlaySound("igQuestLogOpen")

	-- Show questionframe, hide startframe
	questionFrame:Show()
	ETW_Frame.startFrame:Hide()
end

-- Create button function
local function createListButton()

	-- Create a button for the questionlist
	local listButton = CreateFrame("Button", nil, ETW_Frame.questionList, "UIPanelButtonTemplate")
	listButton:SetSize(ETW_LISTITEM_WIDTH, ETW_LISTITEM_HEIGHT)
	listButton:SetPoint(ETW_LISTITEM_ALIGN) -- Align it to the top by default

	-- Listitem text, displayed on top of it 
	local textFormat = listButton:CreateFontString(nil, nil, "GameFontNormal")
	textFormat:SetPoint("LEFT", 27, 0)
	textFormat:SetTextHeight(12)

	listButton:SetFontString(textFormat)

	-- Listitem category icon, so you can easily see it's category
	listButton.icon = listButton:CreateTexture()
	listButton.icon:SetSize(ETW_LISTITEM_HEIGHT-6, ETW_LISTITEM_HEIGHT-6)
	listButton.icon:SetPoint("LEFT", 1, -1)
	
	listButton.icon:SetDrawLayer("OVERLAY", 6)

	-- Highlight on top of the button, indicating different statuses
	listButton.highlight = listButton:CreateTexture()

	function listButton:highlightNone()
		self.highlight:SetAllPoints(listButton) 
		self.highlight:SetTexture(unpack(ETW_NO_HIGHLIGHT))
	end
	function listButton:highlightRed()
		self.highlight:SetAllPoints(listButton) 
		self.highlight:SetTexture(unpack(ETW_RED_HIGHLIGHT))
	end
	function listButton:highlightGreen()
		self.highlight:SetAllPoints(listButton) 
		self.highlight:SetTexture(unpack(ETW_GREEN_HIGHLIGHT))
	end
	function listButton:highlightBlue()
		self.highlight:SetAllPoints(listButton) 
		self.highlight:SetTexture(unpack(ETW_BLUE_HIGHLIGHT))
	end
	function listButton:setQuestionToButton(question)
		self.icon:SetTexture(question.category)
		self.question = question
		self:SetText("[" .. question.ID .. "] " .. question.name)

		local configData = SymphonymConfig.questions[question.ID]

		-- Validate answer
		if configData ~= nil then
			if(configData.newQuest) then
				ETW_Frame.questionList.buttons[question.buttonIndex]:highlightBlue()
			elseif(ETW_isQuestionDone(question)) then
				ETW_Frame.questionList.buttons[question.buttonIndex]:highlightGreen()
			else
				ETW_Frame.questionList.buttons[question.buttonIndex]:highlightNone()
			end
		else
			ETW_Frame.questionList.buttons[question.buttonIndex]:highlightNone()
		end

	end


	-- What will happen when the question is pressed
	listButton:SetScript("PostClick", function(self, button, down)

		if(button == "LeftButton" and not down) then
			displayQuestion(self.question)
		end
	end)

	return listButton
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       ADD QUESTION
--------------------------------------------------------------------------------------------------------------------------------------------------------------------


function addETWQuestion(question)

	-- If questions already exists in the list, abort adding a new one
	if(ETW_Frame.questionList.items[question.ID] ~= nil) then
		return
	end


	-- Create new page if none exists
	if(ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex] == nil) then
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex] = {}
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].items = {}
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].totalCount = 0
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].count = 0
	end

	-- Limit page question count
	if not(ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].totalCount + 1 <= SymphonymConfig.options.pageLimit) then
		ETW_Frame.questionList.maxPageIndex = ETW_Frame.questionList.maxPageIndex + 1
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex] = {}
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].items = {}
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].totalCount = 0
		ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].count = 0
	end

	changePageIndex(ETW_Frame.questionList.maxPageIndex)
	question.buttonIndex = 0

	ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].items[question.ID] = question
	ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].totalCount = ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].totalCount + 1
	ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].count = ETW_Frame.questionList.pages[ETW_Frame.questionList.maxPageIndex].totalCount


	-- Insert question to question list
	ETW_Frame.questionList.items[question.ID] = question
end

































--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Main frame
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
	-- Create the mainframe containing everything
	local frame = CreateFrame("Frame", "ETW_Frame", UIParent, "PortraitFrameTemplate");
	frame:SetWidth(550);
	frame:SetHeight(500);
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(10)

	-- Create title text
	local title = frame:CreateFontString(frameName.."Title", "BACKGROUND", "GameFontNormal")
	title:SetSize(frame:GetWidth(), 220)
	title:SetPoint("CENTER", frame, "TOP", 0, -12);
	title:SetTextHeight(13);
	title:SetText("|cFF00FF00Explore the World|r   Version " .. GetAddOnMetadata("ExploreTheWorld", "Version"))

	-- Template functions
	ETW_makeFrameDraggable(frame)
	ETW_givePortraitFrameIcon(frame)

	-- Option window button
	local optionButton = CreateFrame("Button", frameName.."OptionButton", frame, "UIPanelButtonTemplate")
	optionButton:SetSize(60, 18)
	optionButton:SetPoint("TOPRIGHT", -25, -2)
	optionButton:SetText("Options")
	optionButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_OptionFrame:Show()
		end
	end)

	-- Highlight for icon, when you hover over it
	local iconHighlight = frame:CreateTexture(frameName.."IconHighlight")
	iconHighlight:SetTexture("Interface\\UNITPOWERBARALT\\WowUI_Circular_Frame.blp")
	iconHighlight:SetSize(100, 100)
	iconHighlight:SetPoint("TOPLEFT", frame, -25, 27)
	iconHighlight:SetDrawLayer("BORDER", 6)
	iconHighlight:SetAlpha(0.5)
	iconHighlight:Hide()
	frame.iconHighlight = iconHighlight

	-- Frame for icon, used when targeting it
	local iconFrame = CreateFrame("Frame", frameName.."IconFrame", frame)
	iconFrame:SetAllPoints(frame.portraitIcon)
	iconFrame:SetScript("OnMouseUp", function(self, button)
		if(frame.iconHighlight:IsMouseOver()) then
			ETW_Frame.startFrame:showFrame()
			ETW_Frame.questionFrame:Hide()
		end
		frame.iconHighlight:SetAlpha(0.5)
	end)
	iconFrame:SetScript("OnMouseDown", function(self, button)
		frame.iconHighlight:SetAlpha(0.8)
		PlaySound("GAMEDIALOGOPEN")
	end)
	iconFrame:SetScript("OnEnter", function(self, motion)
		frame.iconHighlight:Show()
	end)
	iconFrame:SetScript("OnLeave", function(self, motion)
		frame.iconHighlight:Hide()
	end)

	-- Quest progress text, showing quests done / maximum quests
	local progressText = frame:CreateFontString(frameName.."ProgressText", "BACKGROUND", "GameFontNormal")
	progressText:SetPoint("TOPLEFT", 70, -40)
	frame.progressText = progressText

	frame:Hide()
	ETW_Frame = frame
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       SCROLLBAR & SCROLLFRAME
--------------------------------------------------------------------------------------------------------------------------------------------------------------------


do
	-- ScrollFrame for all the unlocked questions, i.e the boundaries of the scroll window 
	local scrollFrame = CreateFrame("ScrollFrame", frameName.."ScrollFrame", ETW_Frame) 
	scrollFrame:SetPoint("TOPLEFT", -40, -90) 
	scrollFrame:SetPoint("BOTTOMRIGHT", -320, 26)
	scrollFrame.background = scrollFrame:CreateTexture() 
	scrollFrame.background:SetPoint("TOPRIGHT")
	scrollFrame.background:SetSize(ETW_LISTITEM_WIDTH, scrollFrame:GetHeight())
	scrollFrame.background:SetTexture(0,0,0,0.5)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		if(ETW_Frame.scrollBar:IsEnabled()) then
			local sliderMin, sliderMax = ETW_Frame.scrollBar:GetMinMaxValues()
			local sliderValue = math.floor(ETW_Frame.scrollBar:GetValue() + (sliderMax*(-delta*0.05)))
			ETW_Frame.scrollBar:SetValue(sliderValue)
		end
	end)

	-- Scrollbar for all the unlocked questions
	local scrollBar = CreateFrame("Slider", frameName.."ScrollBar", scrollFrame, "UIPanelScrollBarTemplate") 
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16) 
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16) 
	scrollBar:SetWidth(16)
	scrollBar:EnableMouseWheel(true)
	scrollBar:SetScript("OnValueChanged", function (self, value) 
		self:GetParent():SetVerticalScroll(value)

		if(ETW_Frame.questionList.selectArrow:GetTop()) then
			if(ETW_Frame.questionList.selectArrow:GetTop() > ETW_Frame.scrollFrame:GetTop()) then
				ETW_Frame.questionFrame.selectDownArrow:Hide()
				ETW_Frame.questionFrame.selectUpArrow:Show()
			elseif (ETW_Frame.questionList.selectArrow:GetBottom()+1 < ETW_Frame.scrollFrame:GetBottom()) then
				ETW_Frame.questionFrame.selectUpArrow:Hide()
				ETW_Frame.questionFrame.selectDownArrow:Show()
			else
				ETW_Frame.questionFrame.selectUpArrow:Hide()
				ETW_Frame.questionFrame.selectDownArrow:Hide()
			end
		end
	end)
	scrollBar:SetScript("OnMouseWheel", function(self, delta)
		if(self:IsEnabled()) then
			local sliderMin, sliderMax = self:GetMinMaxValues()
			local sliderValue = math.floor(self:GetValue() + (sliderMax*(-delta*0.05)))
			self:SetValue(sliderValue)
		end
	end)

	-- Background of the scrollbar
	scrollBar.background = scrollBar:CreateTexture(nil, "BACKGROUND") 
	scrollBar.background:SetAllPoints(scrollBar) 
	scrollBar.background:SetTexture(0, 0, 0, 0.4)

	ETW_Frame.scrollFrame = scrollFrame
	ETW_Frame.scrollBar = scrollBar

end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Drop down menu for filtering
--------------------------------------------------------------------------------------------------------------------------------------------------------------------


ETW_DropDownMenu = CreateFrame("Button", "ETW_DropDownMenu", ETW_Frame, "UIDropDownMenuTemplate")
ETW_DropDownMenu:Show()

local items = {
	ETW_EXPLORE_DROPDOWN_NAME,
	ETW_INVESTIGATION_DROPDOWN_NAME,
	ETW_TRACKING_DROPDOWN_NAME,
	ETW_COMPLETED_DROPDOWN_NAME,
	ETW_NEWQUEST_DROPDOWN_NAME,
}

local function ETW_InitDropDownMenu(self, level)
	local info = UIDropDownMenu_CreateInfo()
	for k,v in pairs(items) do
		info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.isNotRadio = true
		info.keepShownOnClick = true

		-- Load checked state from config
		if(info.text == ETW_EXPLORE_DROPDOWN_NAME) then
			info.checked = SymphonymConfig.questions.sorting.showExplore
		elseif(info.text == ETW_INVESTIGATION_DROPDOWN_NAME) then
			info.checked = SymphonymConfig.questions.sorting.showInvestigation
		elseif(info.text == ETW_TRACKING_DROPDOWN_NAME) then
			info.checked = SymphonymConfig.questions.sorting.showTracking
		elseif(info.text == ETW_COMPLETED_DROPDOWN_NAME) then
			info.checked = SymphonymConfig.questions.sorting.showCompleted
		elseif(info.text == ETW_NEWQUEST_DROPDOWN_NAME) then
			info.checked = SymphonymConfig.questions.sorting.showNewQuests
		end

		info.func = function(self)

			-- Store sorting options in config
			if(self:GetText() == ETW_EXPLORE_DROPDOWN_NAME) then
				SymphonymConfig.questions.sorting.showExplore = self.checked
			elseif(self:GetText() == ETW_INVESTIGATION_DROPDOWN_NAME) then
				SymphonymConfig.questions.sorting.showInvestigation = self.checked
			elseif(self:GetText() == ETW_TRACKING_DROPDOWN_NAME) then
				SymphonymConfig.questions.sorting.showTracking = self.checked
			elseif(self:GetText() == ETW_COMPLETED_DROPDOWN_NAME) then
				SymphonymConfig.questions.sorting.showCompleted = self.checked
			elseif(self:GetText() == ETW_NEWQUEST_DROPDOWN_NAME) then
				SymphonymConfig.questions.sorting.showNewQuests = self.checked
			end

			updateQuestList()

		 end
		UIDropDownMenu_AddButton(info, level)
	end
end

UIDropDownMenu_SetWidth(ETW_DropDownMenu, 150)
UIDropDownMenu_SetButtonWidth(ETW_DropDownMenu, 124)
UIDropDownMenu_JustifyText(ETW_DropDownMenu, "LEFT")

ETW_DropDownMenuOpenButton = CreateFrame("Button", "ETW_DropDownMenuOpenButton", ETW_Frame, "UIMenuButtonStretchTemplate")
ETW_DropDownMenuOpenButton:SetPoint("TOPLEFT", 10, -63)
ETW_DropDownMenuOpenButton:SetText("Filter")
ETW_DropDownMenuOpenButton:SetSize(70, 20)
ETW_DropDownMenuOpenButton.rightArrow:Show()

ETW_DropDownMenuOpenButton:SetScript("PostClick", function(self, button, down)
	if(button == "LeftButton" and not down) then
		ToggleDropDownMenu(1, nil, ETW_DropDownMenu, "ETW_DropDownMenuOpenButton", 0, 0)
	end
end)
ETW_DropDownMenuOpenButton:Show()


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Search box
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
	-- Answerbox in which you input your answer
	local searchBox = CreateFrame("EditBox", frameName.."SearchBox", ETW_Frame, "SearchBoxTemplate")
	searchBox:SetPoint("TOPLEFT", 15+ETW_DropDownMenuOpenButton:GetWidth(), -63)
	searchBox:SetSize(136, 20)
	searchBox:SetAutoFocus(false)

	searchBox:SetScript("OnTextChanged", function(self, userInput)
		updateQuestList()
	end)
	ETW_Frame.searchBox = searchBox
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Content frame, where all the content goes
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
	-- Frame for displaying content (i.e not the QuestionList)
	local contentFrame = CreateFrame("Frame", nil, ETW_Frame)
	contentFrame:SetPoint("TOPLEFT", 16+ETW_LISTITEM_WIDTH+ETW_Frame.scrollBar:GetWidth(), -22) 
	contentFrame:SetPoint("BOTTOMRIGHT", -10, 4)
	contentFrame:SetSize(ETW_Frame:GetWidth()-ETW_Frame.scrollFrame:GetWidth(), ETW_Frame:GetHeight())
	ETW_Frame.contentFrame = contentFrame
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Start frame, the frame you see at startup
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do

	local startFrame = CreateFrame("Frame", nil, ETW_Frame.contentFrame)
	startFrame:SetAllPoints()
	startFrame:SetPoint("CENTER")

	startFrame.icon = startFrame:CreateTexture()
	startFrame.icon:SetTexture(ETW_ADDONICON)
	startFrame.icon:SetSize(70, 70)
	startFrame.icon:SetPoint("CENTER", startFrame, 0, 120)

	startFrame.iconBorder = startFrame:CreateTexture()
	startFrame.iconBorder:SetTexture("Interface\\UNITPOWERBARALT\\Mechanical_Circular_Frame.blp")
	startFrame.iconBorder:SetSize(115, 115)
	startFrame.iconBorder:SetPoint("CENTER", startFrame, 0, 120)
	startFrame.iconBorder:SetDrawLayer("OVERLAY", 6)

	startFrame.title = startFrame:CreateFontString(nil, "BACKGROUND", "QuestTitleFontBlackShadow")
	startFrame.title:SetText("Explore the World")
	startFrame.title:SetTextHeight(25)
	startFrame.title:SetPoint("TOP", 0, -40)

	startFrame.welcomeText = startFrame:CreateFontString(nil, "BACKGROUND", "QuestTitleFontBlackShadow")
	startFrame.welcomeText:SetTextHeight(18)
	startFrame.welcomeText:SetPoint("CENTER", 0, 65)

	startFrame.rankText = startFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	startFrame.rankText:SetTextHeight(14)
	startFrame.rankText:SetPoint("CENTER", 0, 45)

	startFrame.authorFrame = CreateFrame("Frame", "startFrame.authorFrame", startFrame, "InsetFrameTemplate3")
	startFrame.authorFrame:SetSize(startFrame:GetWidth()-20, 250)
	startFrame.authorFrame:SetPoint("CENTER", 0, -100)

	startFrame.authorFrame.text = startFrame.authorFrame:CreateFontString(nil, "FOREGROUND", "GameFontNormal")
	startFrame.authorFrame.text:SetText(ETW_CREDIT_STRING)
	startFrame.authorFrame.text:SetTextHeight(15)
	startFrame.authorFrame.text:SetJustifyH("LEFT")
	startFrame.authorFrame.text:SetPoint("TOPLEFT", 15, -20)

	startFrame.authorFrame.thanksText = startFrame.authorFrame:CreateFontString(nil, "FOREGROUND", "GameFontNormal")
	startFrame.authorFrame.thanksText:SetText(ETW_THANKSTO_STRING)
	startFrame.authorFrame.thanksText:SetTextHeight(12)
	startFrame.authorFrame.thanksText:SetJustifyH("LEFT")
	startFrame.authorFrame.thanksText:SetPoint("TOPLEFT", 15, -150)

	function startFrame:showFrame()
		local class, classFileName = UnitClass("player")
		local classColor = RAID_CLASS_COLORS[classFileName]
		local classR, classG, classB = classColor.r, classColor.g, classColor.b

		self.welcomeText:SetText(ETW_decimalToHex(classR, classG, classB) .. UnitName("player") .. "|r")
		self.rankText:SetText(getLoreRank())

		ETW_Frame.questionList.selectArrow:Hide()
		self:Show()
	end
	startFrame:Show()
	ETW_Frame.startFrame = startFrame

end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       QUESTION LIST
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do

	-- Content frame inside the ScrollFrame containing all the unlocked questions
	local questionList = CreateFrame("Frame", nil, ETW_Frame.scrollFrame) 
	-- Height doesn't matter as the frame won't be used for containing things, width 
	-- will be used by listItems to fit the questionList accordingly
	questionList:SetSize(ETW_Frame.scrollFrame:GetWidth(), 1)

	questionList.items = {}
	questionList.pages = {}
	questionList.pageIndex = 0
	questionList.maxPageIndex = 0
	questionList.buttons = {}

	-- Update list when you enter the world
	questionList:RegisterEvent("PLAYER_LOGIN")
	questionList:SetScript("OnEvent", function(self, event, ...)

		if (event == "PLAYER_LOGIN") then
			
			-- Pre allocate buttons for list
			for buttonIndex = 0, SymphonymConfig.options.pageLimit, 1 do
				ETW_Frame.questionList.buttons[buttonIndex] = createListButton()
			end

			-- ID's already loaded, as each ID must be unique
			local loadedIDs = {}
			local questionCount = 0

			-- Iterate all questions and load the unlocked ones into the list
			for _, question in pairs(ETW_LoreQuestions) do

				questionCount = questionCount + 1

				-- Don't allow for duplicate ID's
				if(loadedIDs[question.ID] ~= nil) then
					ETW_Frame.contentFrame:Hide()
					ETW_Frame.questionList:Hide()
					message("You have a corrupt version, which is bad :/")
					break
				else
					loadedIDs[question.ID] = "Loaded"
				end

				-- Store unlocking data in a separate table for easier access by the unlock scanner
				if(question.zoneUnlockHash) then
					for _, zoneHash in pairs(question.zoneUnlockHash) do
						if not ETW_UnlockTable.zones[zoneHash] then
							ETW_UnlockTable.zones[zoneHash] = {}
						end
						ETW_UnlockTable.zones[zoneHash][question.ID] = question
					end
				end
				if(question.itemUnlockHash) then
					for _, itemHash in pairs(question.itemUnlockHash) do
						if not ETW_UnlockTable.items[itemHash] then
							ETW_UnlockTable.items[itemHash] = {}
						end
						ETW_UnlockTable.items[itemHash][question.ID] = question
					end
				end
				if(question.npcUnlockHash) then
					for _, npcHash in pairs(question.npcUnlockHash) do
						if not ETW_UnlockTable.npcs[npcHash] then
							ETW_UnlockTable.npcs[npcHash] = {}
						end
						ETW_UnlockTable.npcs[npcHash][question.ID] = question
					end
				end
				if(question.worldObjectUnlockHash) then
					for _, worldObjectHash in pairs(question.worldObjectUnlockHash) do
						if not ETW_UnlockTable.worldObjects[worldObjectHash] then
							ETW_UnlockTable.worldObjects[worldObjectHash] = {}
						end
						ETW_UnlockTable.worldObjects[worldObjectHash][question.ID] = question
					end
				end
				if(question.progressUnlockHash) then
					if not ETW_UnlockTable.progress[question.progressUnlockHash] then
						ETW_UnlockTable.progress[question.progressUnlockHash] = {}
					end

					ETW_UnlockTable.progress[question.progressUnlockHash][question.ID] = question
				end

				-- Set default values for question
				if(question.texturewidth == nil) then
					question.texturewidth = ETW_Frame.contentFrame:GetWidth()-60
				end
				if(question.textureheight == nil) then
					question.textureheight = ETW_Frame.contentFrame:GetHeight()*0.3
				end

				if(question.texturepath == nil) then
					question.texturepath = ETW_DEFAULT_QUESTION_TEXTURE
				end

				if(question.textureCropLeft == nil) then
					question.textureCropLeft = 0
				end
				if(question.textureCropRight == nil) then
					question.textureCropRight = 1
				end
				if(question.textureCropTop == nil) then
					question.textureCropTop = 0
				end
				if(question.textureCropBottom == nil) then
					question.textureCropBottom = 1
				end

				if(question.zoneRequirementUnlockCopy == true) then
					question.zoneRequirementUnlockHash = question.zoneRequirementHash
				end

				local currentConfig = SymphonymConfig.questions[question.ID]

				-- First 20 ID's are unlocked by default
				if question.ID < 20 then
					addETWQuestion(question)

				-- Other ID's must be unlocked
				elseif (currentConfig) then
					local uniqueHash = currentConfig.uniqueHash

					-- Unlocking is determined if a account and question specific hash is stored in the config file
					-- , these values are set when a question is unlocked
					-- Actually is just user specific now, I scrapped battle.net tag usage because I don't want it
					-- to be dependent on battle.net and a stable connection with it n stuff. :I
					if (ETW_createHash(SymphonymConfig.uniqueHash .. question.ID) == uniqueHash) then 
						addETWQuestion(question)
					end
				end

			end

			-- Initialize data
			UIDropDownMenu_Initialize(ETW_DropDownMenu, ETW_InitDropDownMenu, "MENU")
			updatePageIndex()

			-- Store total amount of questions
			ETW_LoreQuestions.size = questionCount

			changePageIndex(0) -- Set starting page index to 0
			updateProgressText() -- Update the completed quest text

			ETW_Frame.startFrame:showFrame()
			ETW_printToChat(" Successfully initialized addon. Welcome " .. UnitName("player"))
		end
	end)

	-- Make questionlist a child of the scrollframe so its visibility stays within the scrollframe
	ETW_Frame.scrollFrame:SetScrollChild(questionList)
	ETW_Frame.questionList = questionList

end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       PAGE SWITCHING
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
	-- Page number display
	local pageIndexBox = CreateFrame("EditBox", frameName.."PageIndexBox", ETW_Frame, "InputBoxTemplate")
	pageIndexBox:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2), -13)
	pageIndexBox:SetSize(80, 20)
	pageIndexBox:SetJustifyH("CENTER")
	pageIndexBox:SetAutoFocus(false)
	pageIndexBox:SetScript("OnEditFocusGained", function(self)
		self:SetText("")
	end)
	pageIndexBox:SetScript("OnEditFocusLost", function(self)
		updatePageIndex()
	end)
	pageIndexBox:SetScript("OnEnterPressed", function(self)
		local index = tonumber(self:GetText())
		if(index ~= nil) then
			-- Subtract one from index as the visible index is + 1 to make first
			-- page 1 instead of 0
			changePageIndex(index - 1)
		end

		self:ClearFocus()
	end)


	-- Left page end toggling
	local leftEnd = CreateFrame("Button", frameName.."LeftEndPageButton", ETW_Frame, "UIPanelButtonTemplate")
	leftEnd:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2)-85, -13)
	leftEnd:SetSize(25, 20)
	leftEnd:SetText("<<")
	leftEnd:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			changePageIndex(0)
		end
	end)

	-- Left page toggling
	local left = CreateFrame("Button", frameName.."LeftPageButton", ETW_Frame, "UIPanelButtonTemplate")
	left:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2)-62, -13)
	left:SetSize(20, 20)
	left:SetText("<")
	left:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			if(ETW_Frame.questionList.pageIndex >= 1) then
				changePageIndex(ETW_Frame.questionList.pageIndex - 1)
			end
		end
	end)


	-- Right page toggling
	local rightEnd = CreateFrame("Button", frameName.."RightEndPageButton", ETW_Frame, "UIPanelButtonTemplate")
	rightEnd:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2)+85, -13)
	rightEnd:SetSize(25, 20)
	rightEnd:SetText(">>")
	rightEnd:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			changePageIndex(ETW_Frame.questionList.maxPageIndex)
		end
	end)

	-- Right page toggling
	local right = CreateFrame("Button", frameName.."RightPageButton", ETW_Frame, "UIPanelButtonTemplate")
	right:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2)+62, -13)
	right:SetSize(20, 20)
	right:SetText(">")
	right:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			if(ETW_Frame.questionList.pageIndex < ETW_Frame.questionList.maxPageIndex) then
				changePageIndex(ETW_Frame.questionList.pageIndex + 1)
			end
		end
	end)

	ETW_Frame.pageIndexBox = pageIndexBox
	ETW_Frame.leftPageButton = left
	ETW_Frame.leftEndPageButton = leftEnd
	ETW_Frame.rightPageButton = right
	ETW_Frame.rightEndPageButton = rightEnd
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       QUESTION FRAME
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function linkToQuestion(questionID)

	local question = ETW_Frame.questionList.items[questionID]
	if(question == nil) then
		ETW_printErrorToChat("Could not open question link, question not unlocked")
		return
	end

	ETW_Frame:Show()
	changePageIndex(question.pageIndex)
	displayQuestion(question)
end

do
	local questionFrame = CreateFrame("Frame", nil, ETW_Frame.contentFrame)
	questionFrame:SetAllPoints()
	questionFrame:SetPoint("CENTER")

	-- Select arrow, displayed next to question list
	ETW_Frame.questionList.selectArrow = ETW_Frame.questionList:CreateTexture()
	ETW_Frame.questionList.selectArrow:SetTexture(ETW_ADDONICON)
	ETW_Frame.questionList.selectArrow:SetSize(20, 20)
	ETW_Frame.questionList.selectArrow:Hide()

	-- If selected question is out of view, display a lil icon by the top/bottom
	questionFrame.selectUpArrow = questionFrame:CreateTexture()
	questionFrame.selectUpArrow:SetTexture(ETW_ADDONICON)
	questionFrame.selectUpArrow:SetSize(30, 30)
	questionFrame.selectUpArrow:SetPoint("TOPLEFT", ETW_Frame.scrollFrame, "TOPLEFT", 22, 5)
	questionFrame.selectUpArrow:Hide()

	questionFrame.selectDownArrow = questionFrame:CreateTexture()
	questionFrame.selectDownArrow:SetTexture(ETW_ADDONICON)
	questionFrame.selectDownArrow:SetSize(30, 30)
	questionFrame.selectDownArrow:SetPoint("BOTTOMLEFT", ETW_Frame.scrollFrame, "BOTTOMLEFT", 22, -2)
	questionFrame.selectDownArrow:Hide()


	-- Link button, to link question to a friend
	questionFrame.linkButton = CreateFrame("Button", nil, questionFrame)
	questionFrame.linkButton:SetSize(15, 15)
	questionFrame.linkButton:SetPoint("TOPRIGHT", -5, -10)

	questionFrame.linkButton.inputFrame = CreateFrame("Frame", nil, questionFrame.linkButton, "BasicFrameTemplate")
	questionFrame.linkButton.inputFrame:SetSize(150, 50)
	questionFrame.linkButton.inputFrame:SetPoint("CENTER", 0, 35)
	questionFrame.linkButton.inputFrame:EnableMouse(true)
	questionFrame.linkButton.inputFrame:Hide()

	questionFrame.linkButton.inputFrame.text = questionFrame.linkButton.inputFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightLeft")
	questionFrame.linkButton.inputFrame.text:SetText("Link to:")
	questionFrame.linkButton.inputFrame.text:SetPoint("TOPLEFT", 5, -4)

	questionFrame.linkButton.inputFrame.input = CreateFrame("EditBox", frameName.."LinkInputBox", questionFrame.linkButton.inputFrame, "InputBoxTemplate")
	questionFrame.linkButton.inputFrame.input:SetSize(questionFrame.linkButton.inputFrame:GetWidth()-20, 30)
	questionFrame.linkButton.inputFrame.input:SetPoint("BOTTOM", 0, 2)
	questionFrame.linkButton.inputFrame.input:SetScript("OnEnterPressed", function(self)
		ETW_printToChat(" Linking question " .. questionFrame.question.name .. "[" .. questionFrame.question.ID .. "] to '" .. self:GetText() .. "'")
		SendAddonMessage(ETW_ADDONMSG_LINK, tostring(questionFrame.question.ID) .. ","..getLoreRank()..","..GetAddOnMetadata("ExploreTheWorld", "Version"), "WHISPER" , self:GetText())
		questionFrame.linkButton.inputFrame:Hide()
	end)

	RegisterAddonMessagePrefix(ETW_ADDONMSG_LINK)
	questionFrame.linkButton.inputFrame:RegisterEvent("CHAT_MSG_ADDON")
	questionFrame.linkButton.inputFrame:SetScript("OnEvent", function(self, event, ...)

		if(event == "CHAT_MSG_ADDON" and not SymphonymConfig.options.ignoreLinks) then
			local prefix, sentMessage, channel, sender = ...

			local questionID = tonumber(sentMessage)
			local senderRank = "Corrupted quester"
			local senderVersion = "Unknown"

			local splitIndex = 0
			for _, splitString in pairs(ETW_csplit(sentMessage, ",")) do
				if(splitIndex == 0) then
					questionID = tonumber(splitString)
				elseif(splitIndex == 1) then
					senderRank = tostring(splitString)
				elseif(splitIndex == 2) then
					senderVersion = tostring(splitString)
				end
				splitIndex = splitIndex + 1
			end
			if(prefix == ETW_ADDONMSG_LINK and not IsIgnored(sender) and questionID ~= nil) then
				ETW_ShowLinkPopup(sender, senderRank, senderVersion, questionID, linkToQuestion)
			end

		end

	end)

	questionFrame.linkButton:RegisterForClicks("LeftButton")
	questionFrame.linkButton:SetNormalTexture(ETW_LINKBUTTON_NORMAL)
	questionFrame.linkButton:SetHighlightTexture(ETW_LINKBUTTON_HIGHLIGHT)
	questionFrame.linkButton:SetPushedTexture(ETW_LINKBUTTON_NORMAL)
	questionFrame.linkButton:SetScript("OnMouseDown", function(self, button)
		if(button == "LeftButton") then
			questionFrame.linkButton.inputFrame:Show()
		end
	end)

	-- Title frame for title stuff
	questionFrame.titleFrame = CreateFrame("Frame", nil, questionFrame, "InsetFrameTemplate3")
	questionFrame.titleFrame:SetSize(ETW_Frame.contentFrame:GetWidth()-20, 40)
	questionFrame.titleFrame:SetPoint("TOP", 0, -15)
	-- Title text of the question frame, used for displaying name of the question
	questionFrame.titleFrame.title = questionFrame.titleFrame:CreateFontString(nil, "BACKGROUND", "QuestTitleFontBlackShadow")
	questionFrame.titleFrame.title:SetTextHeight(18)
	questionFrame.titleFrame.title:SetPoint("LEFT", 44, 0)
	-- Categoryicon to be displayed alongside the title
	questionFrame.titleFrame.categoryIcon = questionFrame.titleFrame:CreateTexture()
	questionFrame.titleFrame.categoryIcon:SetSize(30, 30)
	questionFrame.titleFrame.categoryIcon:SetPoint("LEFT", 5, 0)

	-- Author text, i.e the person who created the question
	questionFrame.authorText = questionFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	questionFrame.authorText:SetTextHeight(10)
	questionFrame.authorText:SetPoint("BOTTOMRIGHT", -20, 4)

	-- Frame for the text that describes the question
	questionFrame.descriptionFrame = CreateFrame("Frame", "questionFrame.descriptionFrame", questionFrame, "InsetFrameTemplate2")
	questionFrame.descriptionFrame:SetSize(ETW_Frame.contentFrame:GetWidth()-20, ETW_Frame.contentFrame:GetHeight()*0.35)
	questionFrame.descriptionFrame:SetPoint("CENTER", 0, -69)
	--questionFrame.descriptionFrame:SetBackdrop(ETW_DEFAULT_BACKDROP)

	-- Text of the description frame, i.e the text that describes the question
	questionFrame.descriptionFrame.text = questionFrame.descriptionFrame:CreateFontString(nil, nil, "QuestFont");
	questionFrame.descriptionFrame.text:SetSize(questionFrame.descriptionFrame:GetWidth()-40, questionFrame.descriptionFrame:GetHeight()-40)
	questionFrame.descriptionFrame.text:SetPoint("CENTER")

	-- Background of the descriptionframe
	questionFrame.descriptionFrame.background = questionFrame.descriptionFrame:CreateTexture(nil, "BACKGROUND")
	questionFrame.descriptionFrame.background:SetTexture(ETW_QUESTLOG_BACKGROUND)
	questionFrame.descriptionFrame.background:SetTexCoord(0.01, 0.6, 0, 0.68)
	--questionFrame.descriptionFrame.background:SetSize(questionFrame.descriptionFrame:GetWidth()-7, questionFrame.descriptionFrame:GetHeight()-6)
	--questionFrame.descriptionFrame.background:SetPoint("TOPLEFT", 7, -7)
	questionFrame.descriptionFrame.background:SetAllPoints()
	questionFrame:Hide()

	-- Answerbox in which you input your answer
	questionFrame.answerBox = CreateFrame("EditBox", "questionFrame.answerBox", questionFrame, "InputBoxTemplate")
	questionFrame.answerBox:SetPoint("BOTTOMLEFT", 9, 20)
	questionFrame.answerBox:SetSize(questionFrame:GetWidth()-90, 20)
	questionFrame.answerBox:SetAutoFocus(false)
	-- Answerbox title
	questionFrame.answerBox.text = questionFrame.answerBox:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
	questionFrame.answerBox.text:SetPoint("LEFT", questionFrame.answerBox, "LEFT", 0, 20)
	questionFrame.answerBox.text:SetText("Your answer:")

	-- Fade effect when correct/incorrcect answer are given
	questionFrame.answerBox.fade = questionFrame.answerBox:CreateTexture()
	questionFrame.answerBox.fade:SetAllPoints()
	questionFrame.answerBox.fade:SetPoint("LEFT", -11, 0)
	questionFrame.answerBox.fade.elapsedTime = 0

	-- Extra popup text fading alongside the normal fade
	questionFrame.answerBox.fade.text = questionFrame.answerBox:CreateFontString(nil, "BACKGROUND", "GameFontNormalLeftRed")
	questionFrame.answerBox.fade.text:SetTextHeight(16)
	questionFrame.answerBox.fade.text:SetText("ERROR YO")
	questionFrame.answerBox.fade.text:SetPoint("BOTTOM", questionFrame, "BOTTOM", 0, 60)
	function questionFrame.answerBox.fade:SetErrorColor()
		self.text:SetTextColor(1,0,0, 1)
		self:SetTexture(1,0,0, 0.3)
		self:SetAlpha(1)
	end
	function questionFrame.answerBox.fade:SetSuccessColor()
		self.text:SetTextColor(0,1,0, 1)
		self:SetTexture(0,1,0, 0.3)
		self:SetAlpha(1)
	end
	function questionFrame.answerBox:unregisterInputEvents()
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		self:UnregisterEvent("ZONE_CHANGED")
	end

	questionFrame.answerBox:SetScript("OnUpdate", function(self, elapsed)

		-- The fading effect
		if(self.fade.fading) then

			local fadeDuration, valueMax = 2, 1

			self.fade.elapsedTime = self.fade.elapsedTime + elapsed
			self.fade.fadeAlpha = valueMax - ((self.fade.elapsedTime/fadeDuration) * valueMax)

			if(self.fade.fadeAlpha <= 0) then
				self.fade.fading = false
				self.fade.fadeAlpha = 0
			end

			self.fade:SetAlpha(self.fade.fadeAlpha)
			self.fade.text:SetAlpha(self.fade.fadeAlpha)
		end
	end)
	-- Allow enter to be pressed when typing in answerbox to check answer
	questionFrame.answerBox:SetScript("OnEnterPressed", function(self)
		questionFrame:checkAnswer()
	end)

	-- Confirmbutton for answering question by clicking a button instead of pressing enter
	questionFrame.confirmButton = CreateFrame("Button", nil, questionFrame, "UIPanelButtonTemplate")
	questionFrame.confirmButton:SetSize(questionFrame:GetWidth()-(questionFrame.answerBox:GetWidth()+10), 25)
	questionFrame.confirmButton:SetPoint("BOTTOMRIGHT", 0, 18)
	questionFrame.confirmButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			questionFrame:checkAnswer()
		end
	end)

	-- Confirmbutton title text
	questionFrame.confirmButton.text = questionFrame.confirmButton:CreateFontString(nil, nil, "GameFontNormal");
	questionFrame.confirmButton.text:SetText("Confirm")
	questionFrame.confirmButton.text:SetPoint("CENTER")

	-- Image frame for display images alongside the question
	questionFrame.imageFrame = CreateFrame("Frame", "questionFrame.imageFrame", questionFrame, "GlowBoxTemplate")
	questionFrame.imageFrame:SetPoint("CENTER", 0, 100)
	questionFrame.imageFrame.image = questionFrame.imageFrame:CreateTexture(nil, "BACKGROUND")
	questionFrame.imageFrame.image:SetAllPoints(questionFrame.imageFrame)


	-- 3D model viewer for NPC's
	questionFrame.imageFrame.npcModel = CreateFrame("PlayerModel","questionFrame.imageFrame.npcModel",questionFrame.imageFrame)
	questionFrame.imageFrame.npcModel:SetAllPoints(questionFrame.imageFrame.image)
	questionFrame.imageFrame.npcModel.rotation = 0
	questionFrame.imageFrame.npcModel.zoom = ETW_MODEL_NPC_ZOOM
	questionFrame.imageFrame.npcModel:SetScript("OnUpdate", function(self, elapsed)

		if(SymphonymConfig.options.rotate3DModel) then
			if(questionFrame:IsShown() and questionFrame.imageFrame.npcModel:IsShown()) then
				self.rotation = self.rotation + elapsed

				if(self.rotation >= 2*math.pi) then
					self.rotation = 0
				end

				self:SetFacing(self.rotation)
			end
		end
	end)
	questionFrame.imageFrame.npcModel:SetScript("OnMouseWheel", function(self, delta)
		self.zoom = self.zoom + delta*(ETW_MODEL_NPC_MAXZOOM*0.05)
		if(self.zoom < ETW_MODEL_NPC_MINZOOM) then
			self.zoom = ETW_MODEL_NPC_MINZOOM
		elseif(self.zoom > ETW_MODEL_NPC_MAXZOOM) then
			self.zoom = ETW_MODEL_NPC_MAXZOOM
		end

		self:SetPortraitZoom(self.zoom)
	end)
	questionFrame.imageFrame.npcModel.resetButton = CreateFrame("Button","questionFrame.imageFrame.npcModel.resetButton",questionFrame.imageFrame.npcModel, "UIPanelButtonTemplate")
	questionFrame.imageFrame.npcModel.resetButton:SetText("Reset")
	questionFrame.imageFrame.npcModel.resetButton:SetPoint("BOTTOMRIGHT", questionFrame.imageFrame, "BOTTOMRIGHT")
	questionFrame.imageFrame.npcModel.resetButton:SetSize(45, 20)
	questionFrame.imageFrame.npcModel.resetButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			questionFrame.imageFrame.npcModel.zoom = ETW_MODEL_NPC_ZOOM
			questionFrame.imageFrame.npcModel:SetPortraitZoom(ETW_MODEL_NPC_ZOOM)
			questionFrame.imageFrame.npcModel.rotation = 0
			questionFrame.imageFrame.npcModel:SetFacing(0)
		end
	end)
	questionFrame.imageFrame.npcModel:Hide()

	-- 3D model viewer for model's that are not NPC's with displayid's
	questionFrame.imageFrame.miscModel = CreateFrame("PlayerModel","questionFrame.imageFrame.miscModel",questionFrame.imageFrame)
	questionFrame.imageFrame.miscModel:SetAllPoints(questionFrame.imageFrame.image)
	questionFrame.imageFrame.miscModel.rotation = 0
	questionFrame.imageFrame.miscModel.zoom = ETW_MODEL_MISC_ZOOM
	questionFrame.imageFrame.miscModel:SetScript("OnUpdate", function(self, elapsed)

		if(questionFrame:IsShown() and questionFrame.imageFrame.miscModel:IsShown()) then
			self.rotation = self.rotation + elapsed

			if(self.rotation >= 2*math.pi) then
				self.rotation = 0
			end

			self:SetFacing(self.rotation)
		end
	end)
	questionFrame.imageFrame.miscModel:Hide()

	-- Modifies functionality of questionframe when a question is completed
	function questionFrame:completeQuestion()
		self.answerBox.fade.fading = false
		self.answerBox.fade:SetSuccessColor()
		self.answerBox.fade.text:SetText("Correct answer!")

		self.answerBox:Disable()
		self.confirmButton:Disable()
	end

	-- Checks if the answer in the answerbox is the correct one, by crosschecking hash values
	function questionFrame:checkAnswer()

		-- Optional zone required, a zone you have to be in to answer the question
		local zoneRequirement = false
		self.answerBox.fade.text:SetText("You're not at the required zone")

		if(self.question.zoneRequirementHash ~= nil) then
			for _, zoneHash in pairs(self.question.zoneRequirementHash) do

				-- Matching zones
				if(ETW_createHash(GetSubZoneText()) == zoneHash or
					ETW_createHash(ETW_getCurrentZone()) == zoneHash) then
					zoneRequirement = true
					break
				end
			end
		end

		self.answerBox.fade.fading = true
		self.answerBox.fade.fadeAlpha = 1
		self.answerBox.fade.elapsedTime = 0

		local correctAnswer = false
		local userAnswerHash = ETW_createHash(self.answerBox:GetText())

		-- Multiple answer support :D
		for _, answer in pairs(self.question.answer) do
			if(userAnswerHash == answer) then
				correctAnswer = true
				break
			end
			if(correctAnswer == true) then break end
		end

		-- Hash a lowercase version of the text in the answerbox and compare to answer
		if(zoneRequirement and correctAnswer) then

			-- Create config table for question if none exists
			if not(SymphonymConfig.questions[self.question.ID]) then
				SymphonymConfig.questions[self.question.ID] = {}
			end

			-- Disable input events for answerbox as answer is already inputted
			self.answerBox:unregisterInputEvents()

			-- Unlock sound
			PlaySound("igQuestListComplete")
			self:completeQuestion()

			-- Store answer in config file, as it is now known anyway
			SymphonymConfig.questions[self.question.ID].answer = self.answerBox:GetText()

			-- Append completed qs
			SymphonymConfig.questions.completed = SymphonymConfig.questions.completed + 1

			-- Update completed quests after completing this question
			updateProgressText()

			showUnlockPopup(nil, nil, nil, nil, scanProgress())
			ETW_Frame.questionList.buttons[self.question.buttonIndex]:highlightGreen()
		else
			PlaySound("igPlayerInviteDecline")
			if (zoneRequirement) then
				self.answerBox.fade.text:SetText("Incorrect answer!")
			end
			self.answerBox.fade:SetErrorColor()
		end
	end


	ETW_Frame.questionFrame = questionFrame
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       UNLOCK SCANNER
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function unlockQuestion(question)

	SymphonymConfig.questions[question.ID] = {}
	SymphonymConfig.questions[question.ID].uniqueHash = ETW_createHash(SymphonymConfig.uniqueHash .. question.ID)
	SymphonymConfig.questions[question.ID].newQuest = true

	addETWQuestion(question)

	updateQuestList()
end

local function meetsZoneUnlockRequirement(question)

	if(question.zoneRequirementUnlockHash ~= nil) then
		for _, zoneHash in pairs(question.zoneRequirementUnlockHash) do
			if(ETW_createHash(GetSubZoneText()) == zoneHash or
				ETW_createHash(ETW_getCurrentZone()) == zoneHash) then
				return true
			end
		end

		-- We have iterated all requirements and have not returned true, requirements not met
		return false
	else
		return true
	end
end

scanInventory = function(bagID)

	local itemsUnlocked = 0
	local bagslots = GetContainerNumSlots(bagID)

	-- Make sure we don't add an item twice if there's two of them in the inventory
	local duplicateHash = {}

	if(bagslots) then
		for bagSlot = 0, bagslots, 1 do
			local itemID = GetContainerItemID(bagID, bagSlot)
			if(itemID) then

				local itemHash = ETW_createHash(tostring(itemID))
				local itemList = ETW_UnlockTable.items[itemHash]

				if(itemList and duplicateHash[itemHash] == nil) then
					for _, value in pairs(itemList) do
						duplicateHash[itemHash] = "Taken"

						-- Make sure item isn't already in the list
						if(ETW_Frame.questionList.items[value.ID] == nil) then

							if(meetsZoneUnlockRequirement(value)) then
								unlockQuestion(value)
								itemsUnlocked = itemsUnlocked + 1
							end
						end
					end
				end
			end
		end
	end

	return itemsUnlocked
end

scanZone = function()
	local zonesUnlocked = 0
	local subzoneHash = ETW_createHash(GetSubZoneText())
	local zoneHash = ETW_createHash(ETW_getCurrentZone())

	local zoneList = ETW_UnlockTable.zones[zoneHash]

	if (zoneList == nil) then
		zoneList = ETW_UnlockTable.zones[subzoneHash]
	end

	if(zoneList ~= nil) then
		for _, value in pairs(zoneList) do
			if(ETW_Frame.questionList.items[value.ID] == nil) then

				if(meetsZoneUnlockRequirement(value)) then
					unlockQuestion(value)
					zonesUnlocked = zonesUnlocked + 1
				end
			end
		end
	end

	return zonesUnlocked
end

scanNpc = function()
	local npcsUnlocked = 0
	local npcName = UnitName("target")

	if(npcName) then
		local npcHash = ETW_createHash(npcName)

		local npcList = ETW_UnlockTable.npcs[npcHash]

		if(npcList) then
			for _, value in pairs(npcList) do
				if(ETW_Frame.questionList.items[value.ID] == nil) then

					if(meetsZoneUnlockRequirement(value)) then
						unlockQuestion(value)
						npcsUnlocked = npcsUnlocked + 1
					end
				end
			end
		end
	end

	return npcsUnlocked
end

scanWorldObjects = function()
	local worldObjectsUnlocked = 0
	local worldObjectName = ItemTextGetItem()

	if(worldObjectName) then
		local worldObjectHash = ETW_createHash(worldObjectName)

		local worldObjectList = ETW_UnlockTable.worldObjects[worldObjectHash]

		if(worldObjectList) then
			for _, value in pairs(worldObjectList) do
				if(ETW_Frame.questionList.items[value.ID] == nil) then

					if(meetsZoneUnlockRequirement(value)) then
						unlockQuestion(value)
						worldObjectsUnlocked = worldObjectsUnlocked + 1
					end
				end
			end
		end
	end

	return worldObjectsUnlocked
end

scanProgress = function()
	local progressUnlocked = 0
	local progress = SymphonymConfig.questions.completed
	local progressHash = ETW_createHash(tostring(progress))

	local progressList = ETW_UnlockTable.progress[progressHash]

	if(progressList) then
		for _, value in pairs(progressList) do
			if(ETW_Frame.questionList.items[value.ID] == nil) then

				if(meetsZoneUnlockRequirement(value)) then
					unlockQuestion(value)
					progressUnlocked = progressUnlocked + 1
				end
			end
		end
	end

	return progressUnlocked
end

do
	local unlockScanner = CreateFrame("Frame", nil, UIParent)
	unlockScanner:RegisterEvent("BAG_UPDATE")
	unlockScanner:RegisterEvent("ITEM_PUSH")
	unlockScanner:RegisterEvent("ZONE_CHANGED")
	unlockScanner:RegisterEvent("PLAYER_TARGET_CHANGED")
	unlockScanner:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	unlockScanner:RegisterEvent("ITEM_TEXT_BEGIN")
	unlockScanner:SetScript("OnEvent", function(self, event, ...)

		local inCombat = UnitAffectingCombat("player")

		if(inCombat == nil or (inCombat and SymphonymConfig.options.scanInCombat)) then

			local itemsUnlocked = 0
			local zonesUnlocked = 0
			local npcsUnlocked = 0
			local worldObjectsUnlocked = 0

			if(event == "BAG_UPDATE" or event == "ITEM_PUSH") then
				local bagID = ...
				itemsUnlocked = scanInventory(bagID)
			end
			if (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA") then
				zonesUnlocked = scanZone()
			end
			if (event == "PLAYER_TARGET_CHANGED") then
				npcsUnlocked = scanNpc()
			end
			if (event == "ITEM_TEXT_BEGIN") then
				worldObjectsUnlocked = scanWorldObjects()
			end

			showUnlockPopup(itemsUnlocked, zonesUnlocked, npcsUnlocked, worldObjectsUnlocked)

		end
	end)

	ETW_Frame.unlockScanner = unlockScanner
end
