
--[[ TODO:
	New categories:
		Investigation: Locate place and answer a question related to the surroundings.
		Tracking: Locate and target an NPC
					Have questionbox be locked and have the text in it always be the name
					of your latest target. When the text in it is the npc, then press answer.
		Explore: Find semi obscure zones, just by exploring them.


]]

-- TODO: Zone text works for group quest, if no zone req was met, say ur in wrong zone
-- TODO: Reset button for all saved progress, makes bugtesting easier as well because u dont
-- have to restart client all the time
-- TODO default config save, make copytable function
-- TODO cleanup, make zoneRequirementHash mandatory, print to chat when it's missing and such
-- consider making zonereq mandatory, might have followup questions n shit

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       DECLARE VARIABLES
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Allocate tables
local frameName = "ETW_Frame"
ETW_Frame = {}

-- Scanner functions
local scanInventory, scanZone, scanNpc, scanWorldObjects, scanProgress, scanQuestion

-- Updating functions
local updatePageIndex, updateProgressText, updateScrollbarSize,
	updateQuestList

-- Utility functions
local changePageIndex, showUnlockPopup, getQuestionRank,
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

local function updateButtonSelection()

	local displayedQuestion = ETW_Frame.questionFrame.question
	local dispalyedQuestionIsVisible = ETW_Frame.questionFrame.questionIsInList

		-- Select arrow displaying
	if (displayedQuestion ~= nil and dispalyedQuestionIsVisible) then
		local button = ETW_Frame.questionList.buttons[displayedQuestion.buttonIndex]

		if(button:GetTop() > ETW_Frame.scrollFrame:GetTop()) then
			ETW_Frame.questionFrame.selectDownArrow:Hide()
			ETW_Frame.questionFrame.selectUpArrow:Show()
		elseif (button:GetBottom()+1 < ETW_Frame.scrollFrame:GetBottom()) then
			ETW_Frame.questionFrame.selectUpArrow:Hide()
			ETW_Frame.questionFrame.selectDownArrow:Show()
		else
			ETW_Frame.questionFrame.selectUpArrow:Hide()
			ETW_Frame.questionFrame.selectDownArrow:Hide()
		end
	else
		ETW_Frame.questionFrame.selectUpArrow:Hide()
		ETW_Frame.questionFrame.selectDownArrow:Hide()
	end

end


-- Sort and update position of questions in the list
function updateQuestList()

	-- SHITTY, FUNCTIONAL, SORTING, SFS FOR SHORT
	-- default sorting won't work due to it not being a consecutive array, I THINK

	local categorySorted = {}
	local buttonIndex = 1

	ETW_Frame.questionFrame.questionIsInList = false
	local displayedQuestion = ETW_Frame.questionFrame.question

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
			(sortingConfig.showTracking and value.category == ETW_TRACKING_CATEGORY) or 
			(sortingConfig.showGroupQuest and value.category == ETW_GROUPQUEST_CATEGORY)

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
				ETW_Frame.questionList.buttons[buttonIndex]:deselectButton()


				-- Check if the displayed question is in the question list
				if((displayedQuestion ~= nil and displayedQuestion.ID == value.ID) or displayedQuestion == nil) then
					ETW_Frame.questionFrame.questionIsInList = true
				end

				ETW_Frame.questionList.buttons[buttonIndex]:setQuestionToButton(value)
				ETW_Frame.questionList.buttons[buttonIndex]:Show()
				buttonIndex = buttonIndex + 1

				table.insert(categorySorted[value.category], value)

			end
		end
	end



	-- Selection updating, selecting the button that we're currently displaying
	if(displayedQuestion ~= nil and ETW_Frame.questionFrame.questionIsInList == true) then
		local button = ETW_Frame.questionList.buttons[displayedQuestion.buttonIndex]
		button:selectButton()
	end

	-- Hide unused buttons, if any
	for remainingButtonIndex = buttonIndex, SymphonymConfig.options.pageLimit, 1 do
		ETW_Frame.questionList.buttons[remainingButtonIndex]:Hide()
	end


	-- Simply iterate the above table, guaranteeing they will be sorted categorywise
	local index = 0
	for _, categoryList in pairs(categorySorted) do
		for _, question in pairs(categoryList) do

			ETW_Frame.questionList.buttons[question.buttonIndex]:SetPoint(ETW_LISTITEM_ALIGN, 1, index * -ETW_LISTITEM_HEIGHT) --question.listItem:SetPoint("TOP", 0, index * -ETW_LISTITEM_HEIGHT)
			index = index + 1
		end
	end
	ETW_Frame.questionList.pages[ETW_Frame.questionList.pageIndex].count = index

	updateScrollbarSize()
	updateButtonSelection()

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
local function showUnlockPopup(itemUnlocks, zoneUnlocks, npcUnlocks, worldObjectUnlocks, progressUnlocks, questionUnlocks)
	local questsUnlocked = ETW_ShowUnlockPopup(itemUnlocks, zoneUnlocks, npcUnlocks, worldObjectUnlocks, progressUnlocks, questionUnlocks)

	-- If new quests were unlocked, move to the last page as new quests will be pushed there
	if(questsUnlocked > 0) then
		changePageIndex(ETW_Frame.questionList.maxPageIndex)
	end
end

-- Retrieves the current lore rank
local function getQuestionRank()
	return ETW_GetQuestionRank((SymphonymConfig.questions.completed / ETW_LoreQuestions.size) * 100)
end


local function displayQuestion(question)

	local questionFrame = ETW_Frame.questionFrame
	local defaultQuestion = ETW_LoreQuestions.defaultQuestion

	if(questionFrame.question ~= nil) then
		ETW_Frame.questionList.buttons[questionFrame.question.buttonIndex]:deselectButton()
	end

	-- Set questionFrame info to the corresponding data
	questionFrame.question = question
	questionFrame.titleFrame.title:SetText(question.name)
	questionFrame.titleFrame.categoryIcon:SetTexture(question.category)
	questionFrame.continentFrame.continentIcon:SetTexture(question.continent)
	questionFrame.descriptionFrame.text:SetText(question.description)
	questionFrame.imageFrame.image:SetTexture(question.texturepath and question.texturepath or defaultQuestion.texturepath) -- Texture data
	questionFrame.answerBox:SetText("") -- Clear text of answerbox
	questionFrame.answerBox.fade.text:SetText("") -- Clear fading text

	-- Attributes with default data
	questionFrame.imageFrame.image:SetSize(
		question.texturewidth and question.texturewidth or defaultQuestion.texturewidth,
		question.textureheight and question.textureheight or defaultQuestion.textureheight)
	questionFrame.imageFrame:SetSize(
		question.texturewidth and question.texturewidth or defaultQuestion.texturewidth,
		question.textureheight and question.textureheight or defaultQuestion.textureheight)
	questionFrame.imageFrame.image:SetTexCoord(
		question.textureCropLeft and question.textureCropLeft or defaultQuestion.textureCropLeft,
		question.textureCropRight and question.textureCropRight or defaultQuestion.textureCropRight,
		question.textureCropTop and question.textureCropTop or defaultQuestion.textureCropTop,
		question.textureCropBottom and question.textureCropBottom or defaultQuestion.textureCropBottom)

	-- Display author text
	if(question.author == nil) then
		questionFrame.authorText:SetText("Question made by: Jakob Larsson (Addon author)")
	else
		questionFrame.authorText:SetText("Question made by: " .. question.author)
	end

	-- Display "selectArrow" next to list button
	updateButtonSelection()
	ETW_Frame.questionList.buttons[question.buttonIndex]:selectButton(question)

	-- Remove the "new quest" blue glow
	if(SymphonymConfig.questions[question.ID] and SymphonymConfig.questions[question.ID].newQuest) then
		SymphonymConfig.questions[question.ID].newQuest = nil
		ETW_Frame.questionList.buttons[question.buttonIndex]:highlightNone()
	end

	-- Display model, if any
	if(question.modelId ~= nil or question.modelPath ~= nil) then

		questionFrame.imageFrame.npcModel:ClearModel()
		questionFrame.imageFrame.miscModel:ClearModel()

		-- Set model
		if(question.modelId ~= nil) then
			questionFrame.imageFrame.npcModel:SetDisplayInfo(tonumber(ETW_Utility:ConvertBase64(question.modelId)))
			questionFrame.imageFrame.npcModel:SetPortraitZoom(questionFrame.imageFrame.npcModel.zoom)
			questionFrame.imageFrame.npcModel:Show()

			questionFrame.imageFrame.miscModel:Hide()
		elseif(question.modelPath ~= nil) then

			-- When it is in encrypted form, escaping backslashes is not required and actually invalidates the path
			local modelPath = string.gsub(tostring(ETW_Utility:ConvertBase64(question.modelPath)), "\\\\", "\\")

			questionFrame.imageFrame.miscModel:SetModel(modelPath)
			questionFrame.imageFrame.miscModel:SetCamDistanceScale(questionFrame.imageFrame.miscModel.zoom)
			questionFrame.imageFrame.miscModel:Show()

			questionFrame.imageFrame.npcModel:Hide()
		end

		-- Model Y and X offset, to make it look tidy
		local xoffset, yoffset = 0, 0
		if(question.modelYOffset ~= nil) then yoffset = question.modelYOffset end
		if(question.modelYOffset ~= nil) then xoffset = question.modelXOffset end

		questionFrame.imageFrame.miscModel:SetPosition(0,xoffset,-0.1+yoffset)
		questionFrame.imageFrame.npcModel:SetPosition(0,xoffset,-0.1+yoffset)

		-- Misc model zoom
		if(question.modelZoom ~= nil) then
			questionFrame.imageFrame.miscModel:SetCamDistanceScale(question.modelZoom)
		end

	else
		questionFrame.imageFrame.npcModel:Hide()
		questionFrame.imageFrame.miscModel:Hide()
	end

	-- Set custom functionality depending on category
	local realCategory = question.category

	-- Use custom group quest category if any
	if(question.groupQuestCategory ~= nil) then
		realCategory = question.groupQuestCategory
		questionFrame.titleFrame.categoryIcon:SetTexture(question.groupQuestCategory)
	end

	-- Broadcast group question data in investigation on text typing
	questionFrame.answerBox:HookScript("OnTextChanged", function(self, userInput)

		-- Send info to group quest players if it's a groupquest
		if(questionFrame.question.category == ETW_GROUPQUEST_CATEGORY and
			ETW_IsGroupQuestActive(questionFrame.question) and
			realCategory == ETW_INVESTIGATION_CATEGORY) then
			ETW_BroadcastGroupQuestData(
				questionFrame.question.ID..","..
				questionFrame.answerBox:GetText()..","..
				ETW_Utility:GetSubZone()..","..
				ETW_Utility:GetCurrentZone())
		end

	end)

	-- Disable answerBox and button if question is answered already
	if(ETW_isQuestionDone(question)) then
		questionFrame:completeQuestion()

		if(questionFrame.question.category ~= ETW_GROUPQUEST_CATEGORY) then
			questionFrame.answerBox:SetText(SymphonymConfig.questions[question.ID].answer)
		else
			questionFrame.answerBox:SetText(SymphonymConfig.questions[question.ID].answer[1].answer)
		end
	else
		questionFrame.confirmButton:Enable()
		questionFrame.answerBox:Enable()

		-- Reset alpha when switching between questions
		questionFrame.answerBox.fade:SetAlpha(0)
		questionFrame.answerBox.fade.text:SetAlpha(0)
	end

	-- All categories will broadcast zones if group question
	questionFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	questionFrame:RegisterEvent("ZONE_CHANGED")
	questionFrame:SetScript("OnEvent", function(self, event, ...)
		if(event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED") then

			-- Send info to group quest players if it's a groupquest
			if(self.question ~= nil and self.question.category == ETW_GROUPQUEST_CATEGORY and
				ETW_IsGroupQuestActive(questionFrame.question)) then
				ETW_BroadcastGroupQuestData(
					self.question.ID..","..
					self.answerBox:GetText()..","..
					ETW_Utility:GetSubZone()..","..
					ETW_Utility:GetCurrentZone())
			end
		end
	end)

	if(realCategory == ETW_EXPLORE_CATEGORY or realCategory == ETW_TRACKING_CATEGORY) then
		questionFrame.answerBox:Disable()

		if not (ETW_isQuestionDone(question)) then

			-- Text in answerbox on Tracking category will always show name of targeted npc
			if(realCategory == ETW_TRACKING_CATEGORY) then
				questionFrame.answerBox:RegisterEvent("PLAYER_TARGET_CHANGED")

				if(UnitName("target") ~= nil) then
					questionFrame.answerBox:SetText(UnitName("target"))
				else
					questionFrame.answerBox:SetText("No target :[")
				end

				questionFrame.answerBox:SetScript("OnEvent", function(self, event, ...)
					if(event == "PLAYER_TARGET_CHANGED") then
						if(UnitName("target") ~= nil) then
							self:SetText(UnitName("target"))
						else
							self:SetText("No target :[")
						end

						-- Send info to group quest players if it's a groupquest
						if(questionFrame.question ~= nil and questionFrame.question.category == ETW_GROUPQUEST_CATEGORY and
							ETW_IsGroupQuestActive(questionFrame.question)) then
							ETW_BroadcastGroupQuestData(
								questionFrame.question.ID..","..
								questionFrame.answerBox:GetText()..","..
								ETW_Utility:GetSubZone()..","..
								ETW_Utility:GetCurrentZone())
						end
					end
				end)

			-- Text in answerbox on Explore category will always show name of the current zone
			elseif(realCategory == ETW_EXPLORE_CATEGORY) then
				questionFrame.answerBox:RegisterEvent("ZONE_CHANGED_NEW_AREA")
				questionFrame.answerBox:RegisterEvent("ZONE_CHANGED")

				questionFrame.answerBox:SetText(ETW_Utility:GetSubZone())

				questionFrame.answerBox:SetScript("OnEvent", function(self, event, ...)
					if(event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED") then
						self:SetText(ETW_Utility:GetSubZone())

						-- Send info to group quest players if it's a groupquest
						if(questionFrame.question ~= nil and questionFrame.question.category == ETW_GROUPQUEST_CATEGORY and
							ETW_IsGroupQuestActive(questionFrame.question)) then
							ETW_BroadcastGroupQuestData(
								questionFrame.question.ID..","..
								questionFrame.answerBox:GetText()..","..
								ETW_Utility:GetSubZone()..","..
								ETW_Utility:GetCurrentZone())
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

	-- Show group frame if group quest
	if(question.category == ETW_GROUPQUEST_CATEGORY) then
		ETW_StartGroupQuest(question)
		ETW_BroadcastGroupQuestData(
			questionFrame.question.ID..","..
			questionFrame.answerBox:GetText()..","..
			ETW_Utility:GetSubZone()..","..
			ETW_Utility:GetCurrentZone())
	else
		ETW_CancelGroupQuest()
	end


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
	listButton:SetToplevel(true)

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
	listButton.highlight:SetAllPoints(listButton) 

	function listButton:highlightNone()
		self.highlight:SetTexture(unpack(ETW_NO_HIGHLIGHT))
	end
	function listButton:highlightRed()
		self.highlight:SetTexture(unpack(ETW_RED_HIGHLIGHT))
	end
	function listButton:highlightGreen()
		self.highlight:SetTexture(unpack(ETW_GREEN_HIGHLIGHT))
	end
	function listButton:highlightBlue()
		self.highlight:SetTexture(unpack(ETW_BLUE_HIGHLIGHT))
	end

	-- Highlight on top of the button, indicating if it's selected
	listButton.selectHighlight = listButton:CreateTexture()
	listButton.selectHighlight:SetAllPoints(listButton)
	listButton.selectHighlight:SetDrawLayer("ARTWORK", 5)
	function listButton:selectButton()
		self.selectHighlight:SetTexture(1,1,1,0.3)
	end
	function listButton:deselectButton()
		self.selectHighlight:SetTexture(0,0,0,0)
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

	local questionList = ETW_Frame.questionList

	-- If questions already exists in the list, abort adding a new one
	if(questionList.items[question.ID] ~= nil) then
		return
	end

	local function newPage()
		questionList.pages[questionList.maxPageIndex] = {}
		questionList.pages[questionList.maxPageIndex].items = {}
		questionList.pages[questionList.maxPageIndex].totalCount = 0
		questionList.pages[questionList.maxPageIndex].count = 0
	end

	-- Create new page if none exists
	if(questionList.pages[questionList.maxPageIndex] == nil) then
		newPage()
	end

	-- Limit page question count
	if not(questionList.pages[questionList.maxPageIndex].totalCount + 1 <= SymphonymConfig.options.pageLimit) then
		questionList.maxPageIndex = questionList.maxPageIndex + 1
		newPage()
	end

	changePageIndex(questionList.maxPageIndex)
	question.buttonIndex = 0

	questionList.pages[questionList.maxPageIndex].items[question.ID] = question
	questionList.pages[questionList.maxPageIndex].totalCount = questionList.pages[questionList.maxPageIndex].totalCount + 1
	questionList.pages[questionList.maxPageIndex].count = questionList.pages[questionList.maxPageIndex].totalCount


	-- Insert question to question list
	questionList.items[question.ID] = question
end

































--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Main frame
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
	-- Create the mainframe containing everything

	local frame = ETW_Templates:CreatePortraitFrame("ETW_MainFrame", UIParent, "|cFF00FF00Explore the World|r   Version " .. GetAddOnMetadata("ExploreTheWorld", "Version"), ETW_ADDONICON)
	frame:SetWidth(550);
	frame:SetHeight(500);
	frame:SetPoint("CENTER")
	-- TODO _G["ETW_MainFrameBg"]:SetTexture("Interface\\LFGFRAME\\UI-LFG-BACKGROUND-HYJALPAST.BLP")

	ETW_Templates:MakeFrameDraggable(frame)

	-- Option window button
	local optionButton = CreateFrame("Button", "ETW_OptionMenuButton", frame, "UIPanelButtonTemplate")
	optionButton:SetSize(60, 18)
	optionButton:SetPoint("TOPRIGHT", -25, -2)
	optionButton:SetText("Options")
	optionButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_OptionFrame:Show()
		end
	end)

	-- Frame for icon, used when targeting it
	local iconFrame = CreateFrame("Frame", nil, frame)
	iconFrame:SetAllPoints(frame.portraitIcon)
	iconFrame:SetScript("OnMouseDown", function(self, button)
		frame.portraitIcon:SetVertexColor(0.5,0.5,0.5,1)
	end)
	iconFrame:SetScript("OnMouseUp", function(self, button)
		ETW_Frame.startFrame:showFrame()
		ETW_Frame.questionFrame:hideFrame()
		frame.portraitIcon:SetVertexColor(1,1,1,1)
		PlaySound("GAMEDIALOGOPEN")
	end)
	iconFrame:SetScript("OnEnter", function(self, motion)
		frame.portraitIcon:SetVertexColor(0.8,0.99,0.8,1)
	end)
	iconFrame:SetScript("OnLeave", function(self, motion)
		frame.portraitIcon:SetVertexColor(1,1,1,1)
	end)

	-- Quest progress text, showing quests done / maximum quests
	local progressText = frame:CreateFontString("ETW_CompletedQuestText", "ARTWORK", "GameFontNormal")
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
	local scrollFrame = CreateFrame("ScrollFrame", "ETW_QuestionScrollFrame", ETW_Frame) 
	scrollFrame:SetPoint("TOPLEFT", 10, -90) 
	scrollFrame:SetPoint("BOTTOMRIGHT", -320, 26)
	scrollFrame.background = scrollFrame:CreateTexture() 
	scrollFrame.background:SetAllPoints()
	scrollFrame.background:SetTexture(0,0,0,0.5)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		if(ETW_Frame.scrollBar:IsEnabled()) then
			local sliderMin, sliderMax = ETW_Frame.scrollBar:GetMinMaxValues()
			local sliderValue = math.floor(ETW_Frame.scrollBar:GetValue() + (sliderMax*(-delta*0.05)))
			ETW_Frame.scrollBar:SetValue(sliderValue)
		end
	end)

	-- Scrollbar for all the unlocked questions
	local scrollBar = CreateFrame("Slider", "ETW_QuestionScrollbar", scrollFrame, "UIPanelScrollBarTemplate") 
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16) 
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16) 
	scrollBar:SetWidth(16)
	scrollBar:EnableMouseWheel(true)
	scrollBar:SetScript("OnValueChanged", function (self, value) 
		self:GetParent():SetVerticalScroll(value)

		updateButtonSelection()
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
	ETW_GROUPQUEST_DROPDOWN_NAME,
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
		elseif(info.text == ETW_GROUPQUEST_DROPDOWN_NAME) then
			info.checked = SymphonymConfig.questions.sorting.showGroupQuest
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
			elseif(self:GetText() == ETW_GROUPQUEST_DROPDOWN_NAME) then
				SymphonymConfig.questions.sorting.showGroupQuest = self.checked
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
--       Search box for searching questions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
	-- Answerbox in which you input your answer
	local searchBox = CreateFrame("EditBox", "ETW_QuestionSearchBox", ETW_Frame, "SearchBoxTemplate")
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

	-- Icon frame
	startFrame.titleFrame = CreateFrame("Frame", "ETW_StartTitleFrame", startFrame, "InsetFrameTemplate3")
	startFrame.titleFrame:SetSize(startFrame:GetWidth()-20, 140)
	startFrame.titleFrame.Bg:SetTexture("Interface\\LFGFRAME\\UI-LFG-BACKGROUND-HYJALPAST.BLP")
	startFrame.titleFrame.Bg:SetSize(startFrame.titleFrame:GetWidth(), startFrame.titleFrame:GetHeight())
	startFrame.titleFrame.Bg:SetTexCoord(0, 1, 0, 1)
	startFrame.titleFrame:SetPoint("TOP", 0, -15)


	-- Title in large font displayed at the top
	startFrame.title = startFrame.titleFrame:CreateFontString(nil, "ARTWORK", "QuestTitleFontBlackShadow")
	startFrame.title:SetText("Explore the World")
	startFrame.title:SetTextHeight(25)
	startFrame.title:SetPoint("TOP", 0, -25)


	-- Welcome frame
	startFrame.welcomeFrame = CreateFrame("Frame", "ETW_WelcomeFrame", startFrame, "InsetFrameTemplate3")
	startFrame.welcomeFrame:SetSize(startFrame:GetWidth()-20, 50)
	startFrame.welcomeFrame:SetPoint("CENTER", 0, 53)

	-- Text displaying your name in class colors
	startFrame.welcomeText = startFrame.welcomeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	startFrame.welcomeText:SetTextHeight(18)
	startFrame.welcomeText:SetPoint("TOPLEFT", 10, -7)

	-- Text displaying your rank
	startFrame.rankText = startFrame.welcomeFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	startFrame.rankText:SetTextHeight(14)
	startFrame.rankText:SetPoint("TOPLEFT", 10, -27)

	-- Frame containing author info
	startFrame.authorFrame = CreateFrame("Frame", "ETW_CreditFrame", startFrame, "InsetFrameTemplate3")
	startFrame.authorFrame:SetSize(startFrame:GetWidth()-20, 250)
	startFrame.authorFrame:SetPoint("CENTER", 0, -100)

	startFrame.authorFrame.text = startFrame.authorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	startFrame.authorFrame.text:SetText(ETW_CREDIT_STRING)
	startFrame.authorFrame.text:SetTextHeight(12)
	startFrame.authorFrame.text:SetJustifyH("LEFT")
	startFrame.authorFrame.text:SetPoint("TOPLEFT", 15, -10)

	function startFrame:showFrame()
		local class, classFileName = UnitClass("player")
		local classColor = RAID_CLASS_COLORS[classFileName]
		local classR, classG, classB = classColor.r, classColor.g, classColor.b

		self.welcomeText:SetText("Name: "..ETW_Utility:RGBToStringColor(classR, classG, classB) .. UnitName("player") .. "|r")
		self.rankText:SetText("Rank: ".. ETW_Utility:RGBToStringColor(0.6, (SymphonymConfig.questions.completed / ETW_LoreQuestions.size), 0) ..getQuestionRank())

		self:Show()
	end


		-- ScrollFrame for all the unlocked questions, i.e the boundaries of the scroll window 
	local scrollFrame = CreateFrame("ScrollFrame", "ETW_CreditScrollFrame", startFrame.authorFrame) 
	scrollFrame:SetPoint("TOPLEFT", 15, -120) 
	scrollFrame:SetPoint("BOTTOMRIGHT", -25, 14)

	scrollFrame.background = CreateFrame("Frame", "ETW_CreditScrollFrameBackground", scrollFrame, "InsetFrameTemplate3")
	scrollFrame.background:SetPoint("TOPLEFT", 0, 2)
	scrollFrame.background:SetSize(scrollFrame:GetWidth(), scrollFrame:GetHeight()+8)
	scrollFrame.background:SetFrameLevel(7)

	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local scrollbar = ETW_Frame.startFrame.scrollBar
		if(scrollbar:IsEnabled()) then
			local sliderMin, sliderMax = scrollbar:GetMinMaxValues()
			local sliderValue = math.floor(scrollbar:GetValue() + (sliderMax*(-delta*0.05)))
			scrollbar:SetValue(sliderValue)
		end
	end)

	scrollFrame.contentFrame = CreateFrame("Frame", nil, scrollFrame)
	scrollFrame.contentFrame:SetSize(100, 1)
	scrollFrame.contentFrame:SetFrameLevel(10)

	scrollFrame.contentFrame.creditText = scrollFrame.contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	scrollFrame.contentFrame.creditText:SetTextHeight(10)
	scrollFrame.contentFrame.creditText:SetJustifyH("LEFT")
	scrollFrame.contentFrame.creditText:SetPoint("TOP", 35, -5)
	scrollFrame.contentFrame.creditText:SetText(ETW_THANKSTO_STRING)

	scrollFrame:SetScrollChild(scrollFrame.contentFrame)



	-- Scrollbar for all the unlocked questions
	local scrollBar = CreateFrame("Slider", "ETW_CreditScrollbar", scrollFrame, "UIPanelScrollBarTemplate") 
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16) 
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16) 
	scrollBar:SetWidth(16)
	scrollBar:EnableMouseWheel(true)
	scrollBar:SetMinMaxValues(0, 100)
	scrollBar:SetValue(0)
	scrollBar:SetValueStep(1)

	scrollBar:SetScript("OnValueChanged", function (self, value) 
		self:GetParent():SetVerticalScroll(value)
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

	ETW_Frame.startFrame = startFrame
	ETW_Frame.startFrame.scrollFrame = scrollFrame
	ETW_Frame.startFrame.scrollBar = scrollBar

	startFrame:Show()

end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       QUESTION LIST
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

do

	local function printAttributeMissing(questionIdentifier, attributeName)
		ETW_Utility:PrintErrorToChat("Invalid question: " .. questionIdentifier)
		ETW_Utility:PrintErrorToChat("Attribute missing: |cFFFFFB00" .. attributeName)
	end

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
			for buttonIndex = 1, SymphonymConfig.options.pageLimit, 1 do
				ETW_Frame.questionList.buttons[buttonIndex] = createListButton()
			end

			-- ID's already loaded, as each ID must be unique
			local loadedIDs = {}
			local questionCount = 0

			-- Iterate all questions and load the unlocked ones into the list
			for _, question in pairs(ETW_LoreQuestions.questions) do

				questionCount = questionCount + 1

				-- Check for invalid question formats
				if(question.ID == nil) then printAttributeMissing("Index ".. questionCount, "ID") end
				if(question.name == nil) then printAttributeMissing("ID " .. question.ID, "name") end
				if(question.description == nil) then printAttributeMissing("ID " .. question.ID, "description") end
				if(question.category == nil) then printAttributeMissing("ID " .. question.ID, "category") end
				if(question.category == ETW_GROUPQUEST_CATEGORY and question.groupQuest == nil) then
					printAttributeMissing("ID " .. question.ID, "groupQuest")
				end
				if(question.continent == nil) then printAttributeMissing("ID " .. question.ID, "continent") end
				if(question.category == ETW_GROUPQUEST_CATEGORY and question.groupQuestCategory == nil) then
					printAttributeMissing("ID " .. question.ID, "groupQuestCategory")
				end
				if(question.category ~= ETW_GROUPQUEST_CATEGORY and question.answer == nil) then
					printAttributeMissing("ID " .. question.ID, "answer")
				end
				if(question.category ~= ETW_GROUPQUEST_CATEGORY and question.zoneRequirementHash == nil) then
					printAttributeMissing("ID " .. question.ID, "zoneRequirementHash")
				end
				if(question.ID > ETW_DEFAULT_QUESTION_ID) then
					if(question.zoneUnlockHash == nil and
						question.itemUnlockHash == nil and
						question.npcUnlockHash == nil and
						question.worldObjectHash == nil and
						question.progressUnlockHash == nil and
						question.questionUnlock == nil) then
						printAttributeMissing("ID " .. question.ID, "any unlock attribute")
					end
				end

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
				if(question.questionUnlock) then
					for _, questionBase64 in pairs(question.questionUnlock) do
						local normalFormat = tonumber(ETW_Utility:ConvertBase64(questionBase64))
						if not ETW_UnlockTable.questions[normalFormat] then
							ETW_UnlockTable.questions[normalFormat] = {}
						end
						ETW_UnlockTable.questions[normalFormat][question.ID] = question
					end
				end
				if(question.progressUnlockHash) then
					if not ETW_UnlockTable.progress[question.progressUnlockHash] then
						ETW_UnlockTable.progress[question.progressUnlockHash] = {}
					end

					ETW_UnlockTable.progress[question.progressUnlockHash][question.ID] = question
				end

				if(question.zoneRequirementUnlockCopy == true) then
					question.zoneRequirementUnlockHash = question.zoneRequirementHash
				end

				-- Count available data for group quest, i.e how many players are needed for the question
				if(question.category == ETW_GROUPQUEST_CATEGORY) then
					question.groupQuest.limit = 0
					for index = 1, ETW_PLAYERS_TOTALMAX, 1 do
						if(question.groupQuest[index] == nil) then
							break
						else
							question.groupQuest.limit = question.groupQuest.limit + 1
						end
					end

					if(question.groupQuest.limit < 2 or question.groupQuest.limit > 5) then
						ETW_Utility:PrintErrorToChat("Invalid question: ID" .. question.ID)
						ETW_Utility:PrintErrorToChat("Group questions can't have " .. question.groupQuest.limit .. " answers")
					end
				end

				local currentConfig = SymphonymConfig.questions[question.ID]

				-- First ETW_DEFAULT_QUESTION_ID ID's are unlocked by default
				if question.ID <= ETW_DEFAULT_QUESTION_ID then
					addETWQuestion(question)

				-- Other ID's must be unlocked
				elseif (currentConfig) then
					local uniqueHash = currentConfig.uniqueHash

					-- Unlocking is determined if an account and question specific hash is stored in the config file
					-- , these values are set when a question is unlocked
					-- Actually is just user specific now, I scrapped battle.net tag usage because I don't want it
					-- to be dependent on battle.net and a stable connection with it n stuff. :I
					if (ETW_Utility:CreateSha2Hash(SymphonymConfig.uniqueHash .. question.ID) == uniqueHash) then 
						addETWQuestion(question)
					end
				end

			end

			-- Initialize data
			UIDropDownMenu_Initialize(ETW_DropDownMenu, ETW_InitDropDownMenu, "MENU")
			updatePageIndex()

			-- Store total amount of questions
			ETW_LoreQuestions.size = questionCount

			-- Force update progress unlocks if more questions has been added
			if(SymphonymConfig.totalQuestionCount ~= ETW_LoreQuestions.size) then
				showUnlockPopup(nil, nil, nil, nil, scanProgress(true))
			end
			SymphonymConfig.totalQuestionCount = ETW_LoreQuestions.size

			changePageIndex(0) -- Set starting page index to 0
			updateProgressText() -- Update the completed quest text

			ETW_Frame.startFrame:showFrame()
			ETW_Utility:PrintToChat(" Successfully initialized addon. Welcome " .. UnitName("player"))
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
	local pageIndexBox = CreateFrame("EditBox", "ETW_PageIndexBox", ETW_Frame, "InputBoxTemplate")
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
	local leftEnd = CreateFrame("Button", "ETW_LeftEndPageButton", ETW_Frame, "UIPanelButtonTemplate")
	leftEnd:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2)-85, -13)
	leftEnd:SetSize(25, 20)
	leftEnd:SetText("<<")
	leftEnd:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			changePageIndex(0)
		end
	end)

	-- Left page toggling
	local left = CreateFrame("Button", "ETW_LeftPageButton", ETW_Frame, "UIPanelButtonTemplate")
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
	local rightEnd = CreateFrame("Button", "ETW_RightEndPageButton", ETW_Frame, "UIPanelButtonTemplate")
	rightEnd:SetPoint("CENTER", ETW_Frame.scrollFrame, "BOTTOMRIGHT", (-ETW_LISTITEM_WIDTH/2)+85, -13)
	rightEnd:SetSize(25, 20)
	rightEnd:SetText(">>")
	rightEnd:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			changePageIndex(ETW_Frame.questionList.maxPageIndex)
		end
	end)

	-- Right page toggling
	local right = CreateFrame("Button", "ETW_RightPageButton", ETW_Frame, "UIPanelButtonTemplate")
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

-- Function ran when got a link to question
local function linkToQuestion(questionID)

	local question = ETW_Frame.questionList.items[questionID]
	if(question == nil) then
		ETW_Utility:PrintErrorToChat("Could not open question link, question not unlocked")
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

	-- If selected question is out of view, display a lil icon by the top/bottom
	questionFrame.selectUpArrow = questionFrame:CreateTexture()
	questionFrame.selectUpArrow:SetTexture(ETW_SELECTION_BOUNDS_TEXTURE)
	questionFrame.selectUpArrow:SetSize(ETW_LISTITEM_WIDTH-2, 30)
	questionFrame.selectUpArrow:SetAlpha(0.7)
	questionFrame.selectUpArrow:SetPoint("TOPLEFT", ETW_Frame.scrollFrame, "TOPLEFT", 2, 0)
	questionFrame.selectUpArrow:Hide()

	questionFrame.selectDownArrow = questionFrame:CreateTexture()
	questionFrame.selectDownArrow:SetTexture(ETW_SELECTION_BOUNDS_TEXTURE)
	questionFrame.selectDownArrow:SetSize(ETW_LISTITEM_WIDTH-2, 30)
	questionFrame.selectDownArrow:SetTexCoord(0,1,1,0)
	questionFrame.selectDownArrow:SetAlpha(0.7)
	questionFrame.selectDownArrow:SetPoint("BOTTOMLEFT", ETW_Frame.scrollFrame, "BOTTOMLEFT", 2, -2)
	questionFrame.selectDownArrow:Hide()

	function questionFrame:hideFrame()
		local displayedQuestion = ETW_Frame.questionFrame.question

		if(displayedQuestion ~= nil) then
			ETW_Frame.questionList.buttons[displayedQuestion.buttonIndex]:deselectButton()
			ETW_Frame.questionFrame.question = nil
		end

		self:Hide()
	end


	-- Link button, to link question to a friend
	questionFrame.linkButton = CreateFrame("Button", nil, questionFrame)
	questionFrame.linkButton:SetSize(15, 15)
	questionFrame.linkButton:SetPoint("TOPRIGHT", -5, -10)

	questionFrame.linkButton.inputFrame = CreateFrame("Frame", "ETW_LinkInputFrame", questionFrame.linkButton, "BasicFrameTemplate")
	questionFrame.linkButton.inputFrame:SetSize(150, 50)
	questionFrame.linkButton.inputFrame:SetPoint("CENTER", 0, 35)
	questionFrame.linkButton.inputFrame:EnableMouse(true)
	questionFrame.linkButton.inputFrame:Hide()

	questionFrame.linkButton.inputFrame.text = questionFrame.linkButton.inputFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
	questionFrame.linkButton.inputFrame.text:SetText("Link to:")
	questionFrame.linkButton.inputFrame.text:SetPoint("TOPLEFT", 5, -4)

	questionFrame.linkButton.inputFrame.input = CreateFrame("EditBox", "ETW_LinkInputBox", questionFrame.linkButton.inputFrame, "InputBoxTemplate")
	questionFrame.linkButton.inputFrame.input:SetSize(questionFrame.linkButton.inputFrame:GetWidth()-20, 30)
	questionFrame.linkButton.inputFrame.input:SetPoint("BOTTOM", 0, 2)
	questionFrame.linkButton.inputFrame.input:SetScript("OnEnterPressed", function(self)

		ETW_Utility:PrintToChat(" Linking question " .. questionFrame.question.name .. "[" .. questionFrame.question.ID .. "] to '" .. self:GetText() .. "'")
		SendAddonMessage(ETW_ADDONMSG_PREFIX,
			ETW_ADDONMSG_LINK..","..
			tostring(questionFrame.question.ID)..","..
			SymphonymConfig.questions.completed..","..
			ETW_LoreQuestions.size..","..
			GetAddOnMetadata("ExploreTheWorld", "Version"),
		"WHISPER" , self:GetText())
		questionFrame.linkButton.inputFrame:Hide()

	end)

	questionFrame.linkButton.inputFrame:RegisterEvent("CHAT_MSG_ADDON")
	questionFrame.linkButton.inputFrame:SetScript("OnEvent", function(self, event, ...)

		if(event == "CHAT_MSG_ADDON" and not SymphonymConfig.options.ignoreLinks) then
			local prefix, sentMessage, channel, sender = ...

			local messageList = ETW_Utility:SplitString(sentMessage, ",")
			local messageCount = #(messageList)

			-- Make sure the message is valid
			if(prefix == ETW_ADDONMSG_PREFIX) then

				if(messageCount == 5 and messageList[1] == ETW_ADDONMSG_LINK and not IsIgnored(sender)) then

					local questionID = tonumber(messageList[2])
					local senderCompleted, senderTotalQs = tonumber(messageList[3]), tonumber(messageList[4])

					local senderRank = "Corrupted"
					if(senderCompleted and senderTotalQs) then
						senderRank = ETW_GetQuestionRank((senderCompleted/senderTotalQs) * 100)
					end
					local senderVersion = messageList[5]

					if(questionID ~= nil) then
						ETW_ShowLinkPopup(sender, senderRank, senderVersion, questionID, linkToQuestion)
					end

				end
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
	questionFrame.titleFrame = CreateFrame("Frame", "ETW_QuestionTitleFrame", questionFrame, "InsetFrameTemplate3")
	questionFrame.titleFrame:SetSize(ETW_Frame.contentFrame:GetWidth()-20, 40)
	questionFrame.titleFrame:SetPoint("TOP", 0, -15)
	-- Title text of the question frame, used for displaying name of the question
	questionFrame.titleFrame.title = questionFrame.titleFrame:CreateFontString(nil, "ARTWORK", "QuestTitleFontBlackShadow")
	questionFrame.titleFrame.title:SetTextHeight(18)
	questionFrame.titleFrame.title:SetPoint("LEFT", 44, 0)
	-- Categoryicon to be displayed alongside the title
	questionFrame.titleFrame.categoryIcon = questionFrame.titleFrame:CreateTexture()
	questionFrame.titleFrame.categoryIcon:SetSize(30, 30)
	questionFrame.titleFrame.categoryIcon:SetPoint("LEFT", 5, 0)

	-- Continenticon show what continent the question is on
	questionFrame.continentFrame = CreateFrame("Frame", "ETW_ContinentFrame", questionFrame, "InsetFrameTemplate3")
	questionFrame.continentFrame:SetSize(40, 40)
	questionFrame.continentFrame:SetPoint("CENTER", questionFrame.titleFrame, "RIGHT", -10, -30)
	questionFrame.continentFrame.continentIcon = questionFrame.continentFrame:CreateTexture()
	questionFrame.continentFrame.continentIcon:SetSize(35, 35)
	questionFrame.continentFrame.continentIcon:SetPoint("CENTER")

	-- Author text, i.e the person who created the question
	questionFrame.authorText = questionFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	questionFrame.authorText:SetTextHeight(10)
	questionFrame.authorText:SetPoint("BOTTOMRIGHT", -20, 4)

	-- Frame for the text that describes the question
	questionFrame.descriptionFrame = CreateFrame("Frame", "ETW_QuestionDescriptionFrame", questionFrame, "InsetFrameTemplate2")
	questionFrame.descriptionFrame:SetSize(ETW_Frame.contentFrame:GetWidth()-20, ETW_Frame.contentFrame:GetHeight()*0.35)
	questionFrame.descriptionFrame:SetPoint("CENTER", 0, -69)

	-- Text of the description frame, i.e the text that describes the question
	questionFrame.descriptionFrame.text = questionFrame.descriptionFrame:CreateFontString(nil, nil, "QuestFont");
	questionFrame.descriptionFrame.text:SetSize(questionFrame.descriptionFrame:GetWidth()-40, questionFrame.descriptionFrame:GetHeight()-40)
	questionFrame.descriptionFrame.text:SetPoint("CENTER")

	-- Background of the descriptionframe
	questionFrame.descriptionFrame.background = questionFrame.descriptionFrame:CreateTexture(nil, "BACKGROUND")
	questionFrame.descriptionFrame.background:SetTexture(ETW_QUESTLOG_BACKGROUND)
	questionFrame.descriptionFrame.background:SetTexCoord(0.01, 0.6, 0, 0.68)
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
		questionFrame:validateAnswer()
	end)

	-- Confirmbutton for answering question by clicking a button instead of pressing enter
	questionFrame.confirmButton = CreateFrame("Button", nil, questionFrame, "UIPanelButtonTemplate")
	questionFrame.confirmButton:SetSize(questionFrame:GetWidth()-(questionFrame.answerBox:GetWidth()+10), 25)
	questionFrame.confirmButton:SetPoint("BOTTOMRIGHT", 0, 18)
	questionFrame.confirmButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_Utility:PrintToChat(ETW_Utility:GetCurrentZone())
			ETW_Utility:PrintToChat(GetSubZoneText())
			ETW_Utility:PrintToChat(GetMinimapZoneText())
			questionFrame:validateAnswer()
		end
	end)

	-- Confirmbutton title text
	questionFrame.confirmButton.text = questionFrame.confirmButton:CreateFontString(nil, nil, "GameFontNormal");
	questionFrame.confirmButton.text:SetText("Confirm")
	questionFrame.confirmButton.text:SetPoint("CENTER")

	-- Image frame for display images alongside the question
	questionFrame.imageFrame = CreateFrame("Frame", "questionFrame.imageFrame", questionFrame, "GlowBoxTemplate")
	questionFrame.imageFrame:SetPoint("CENTER", 0, 97)
	questionFrame.imageFrame.image = questionFrame.imageFrame:CreateTexture(nil, "BACKGROUND")
	questionFrame.imageFrame.image:SetAllPoints(questionFrame.imageFrame)


	-- 3D model viewer for NPC's
	questionFrame.imageFrame.npcModel = ETW_Templates:CreateRotatingModel("ETW_NpcModelFrame", questionFrame.imageFrame)
	questionFrame.imageFrame.npcModel:SetAllPoints(questionFrame.imageFrame.image)
	questionFrame.imageFrame.npcModel.zoom = ETW_MODEL_NPC_ZOOM
	questionFrame.imageFrame.npcModel:SetScript("OnMouseWheel", function(self, delta)
		self.zoom = self.zoom + delta*(ETW_MODEL_NPC_MAXZOOM*0.05)
		if(self.zoom < ETW_MODEL_NPC_MINZOOM) then
			self.zoom = ETW_MODEL_NPC_MINZOOM
		elseif(self.zoom > ETW_MODEL_NPC_MAXZOOM) then
			self.zoom = ETW_MODEL_NPC_MAXZOOM
		end

		self:SetPortraitZoom(self.zoom)
	end)
	questionFrame.imageFrame.npcModel.resetButton:HookScript("OnClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			questionFrame.imageFrame.npcModel.zoom = ETW_MODEL_NPC_ZOOM
			questionFrame.imageFrame.npcModel:SetPortraitZoom(ETW_MODEL_NPC_ZOOM)
			questionFrame.imageFrame.npcModel.rotation = 0
			questionFrame.imageFrame.npcModel:SetFacing(0)
		end
	end)
	questionFrame.imageFrame.npcModel:Hide()

	-- 3D model viewer for model's that are not NPC's with displayid's
	questionFrame.imageFrame.miscModel = ETW_Templates:CreateRotatingModel("ETW_MiscModelFrame", questionFrame.imageFrame)
	questionFrame.imageFrame.miscModel:SetAllPoints(questionFrame.imageFrame.image)
	questionFrame.imageFrame.miscModel.zoom = ETW_MODEL_MISC_ZOOM
	questionFrame.imageFrame.miscModel.resetButton:Hide()
	questionFrame.imageFrame.miscModel:Hide()

	-- Modifies functionality of questionframe when a question is completed
	function questionFrame:completeQuestion()
		self.answerBox.fade.fading = false
		self.answerBox.fade:SetSuccessColor()
		self.answerBox.fade.text:SetText("Correct answer!")

		self.answerBox:Disable()
		self.confirmButton:Disable()

		-- Update completed quests after completing this question
		updateProgressText()
	end

	function questionFrame:checkZoneRequirement()
		if(self.question.zoneRequirementHash ~= nil) then
			for _, zoneData in pairs(self.question.zoneRequirementHash) do

				local zoneReq = true
				local subZoneReq = true

				if(zoneData.zone ~= nil and ETW_Utility:CreateSha2Hash(ETW_Utility:GetCurrentZone()) ~= zoneData.zone) then
					zoneReq = false
				end
				if(zoneData.subZone ~= nil and ETW_Utility:CreateSha2Hash(ETW_Utility:GetSubZone()) ~= zoneData.subZone) then
					subZoneReq = false
				end

				-- If you match one of the zone requirements, then return true
				if(zoneReq and subZoneReq) then
					return true
				end
			end
			return false
		else
			return true
		end

	end

	function questionFrame:checkAnswer()
		local correctAnswer = false

		-- Check group quest answer
		-- Group quests answer check answer and zonereq in same function, so this function just returns false
		if(self.question.category == ETW_GROUPQUEST_CATEGORY and self.question.groupQuest ~= nil) then
			return false

		-- Check normal answer
		else

			local userAnswerHash = ETW_Utility:CreateSha2Hash(self.answerBox:GetText())

			-- Multiple answer support :D
			for _, answer in pairs(self.question.answer) do
				if(userAnswerHash == answer) then
					correctAnswer = true
					break
				end
				if(correctAnswer == true) then break end
			end
		end

		return correctAnswer
	end

	function questionFrame:saveAnswer()
		-- Create config table for question if none exists
		if not(SymphonymConfig.questions[self.question.ID]) then
			SymphonymConfig.questions[self.question.ID] = {}
		end

		if(self.question.category == ETW_GROUPQUEST_CATEGORY) then
			ETW_SaveGroupQuestAnswer(self.answerBox:GetText())
		else
			SymphonymConfig.questions[self.question.ID].answer = self.answerBox:GetText()
		end
	end

	-- Checks if the answer in the answerbox is the correct one, by crosschecking hash values
	function questionFrame:validateAnswer()

		-- Optional zone required, a zone you have to be in to answer the question
		local zoneRequirement = self:checkZoneRequirement()
		local correctAnswer = self:checkAnswer()

		-- Reset fade variables
		self.answerBox.fade.text:SetText("You're not at the required zone")
		self.answerBox.fade.fading = true
		self.answerBox.fade.fadeAlpha = 1
		self.answerBox.fade.elapsedTime = 0

		if(self.question.category == ETW_GROUPQUEST_CATEGORY and self.question.groupQuest ~= nil) then
			correctAnswer, zoneRequirement = ETW_CheckGroupQuestAnswer(self.answerBox:GetText())
		end

		-- Hash a lowercase version of the text in the answerbox and compare to answer
		if(zoneRequirement and correctAnswer) then

			-- Disable input events for answerbox as answer is already inputted
			self.answerBox:unregisterInputEvents()

			-- Store plain answer in config file, as it is now known to us anyway
			self:saveAnswer()

			-- Append completed qs
			SymphonymConfig.questions.completed = SymphonymConfig.questions.completed + 1

			-- Unlock sound
			PlaySound("igQuestListComplete")
			self:completeQuestion()

			-- Unlock questions from completion
			showUnlockPopup(nil, nil, nil, nil, scanProgress(), scanQuestion(self.question.ID))
			
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
	SymphonymConfig.questions[question.ID].uniqueHash = ETW_Utility:CreateSha2Hash(SymphonymConfig.uniqueHash .. question.ID)
	SymphonymConfig.questions[question.ID].newQuest = true

	addETWQuestion(question)

	updateQuestList()
end

local function meetsZoneUnlockRequirement(question)

	if(question.zoneRequirementUnlockHash ~= nil) then
		for _, zoneData in pairs(question.zoneRequirementUnlockHash) do
			local zoneReq = true
			local subZoneReq = true

			if(zoneData.zone ~= nil and ETW_Utility:CreateSha2Hash(ETW_Utility:GetCurrentZone()) ~= zoneData.zone) then
				zoneReq = false
			end
			if(zoneData.subZone ~= nil and ETW_Utility:CreateSha2Hash(ETW_Utility:GetSubZone()) ~= zoneData.subZone) then
				subZoneReq = false
			end

			-- If you match one of the zone requirements, then return true
			if(zoneReq and subZoneReq) then
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

				local itemHash = ETW_Utility:CreateSha2Hash(tostring(itemID))
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

	local function scanZoneList(zoneList)
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
	end

	local subzoneHash = ETW_Utility:CreateSha2Hash(ETW_Utility:GetSubZone())
	local zoneHash = ETW_Utility:CreateSha2Hash(ETW_Utility:GetCurrentZone())

	scanZoneList(ETW_UnlockTable.zones[zoneHash])
	scanZoneList(ETW_UnlockTable.zones[subzoneHash])

	return zonesUnlocked
end

scanNpc = function()
	local npcsUnlocked = 0
	local npcName = UnitName("target")

	if(npcName) then
		local npcHash = ETW_Utility:CreateSha2Hash(npcName)

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
		local worldObjectHash = ETW_Utility:CreateSha2Hash(worldObjectName)

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

scanProgress = function(fullScan)
	local progressUnlocked = 0


	local function checkList(progressList)
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
	end

	if(fullScan) then
		for completedQs = 0, SymphonymConfig.questions.completed, 1 do
			local progressHash = ETW_Utility:CreateSha2Hash(tostring(completedQs))
			checkList(ETW_UnlockTable.progress[progressHash])
		end
	else
		local progress = SymphonymConfig.questions.completed
		local progressHash = ETW_Utility:CreateSha2Hash(tostring(progress))
		checkList(ETW_UnlockTable.progress[progressHash])
	end



	return progressUnlocked
end

scanQuestion = function(questionID)
	local questionsUnlocked = 0
	local questionList = ETW_UnlockTable.questions[questionID]

	if(questionList) then
		for _, value in pairs(questionList) do
			if(ETW_Frame.questionList.items[value.ID] == nil) then
				unlockQuestion(value)
				questionsUnlocked = questionsUnlocked + 1
			end
		end
	end

	return questionsUnlocked
end

do
	local unlockScanner = CreateFrame("Frame", nil, UIParent)
	unlockScanner:RegisterEvent("BAG_UPDATE")
	unlockScanner:RegisterEvent("ITEM_PUSH")
	unlockScanner:RegisterEvent("ZONE_CHANGED")
	unlockScanner:RegisterEvent("PLAYER_TARGET_CHANGED")
	unlockScanner:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	unlockScanner:RegisterEvent("ITEM_TEXT_BEGIN")
	unlockScanner:RegisterEvent("PLAYER_LOGIN")
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
