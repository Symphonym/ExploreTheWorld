
----------------------------------------------------------------------------------
--       Variables
----------------------------------------------------------------------------------


ETW_HelpFrame = {}

local pageIndex = 1
local maxPages = 8

----------------------------------------------------------------------------------
--       Functions
----------------------------------------------------------------------------------


-- Update buttons depending on index
local function updateButtons()

	ETW_HelpFrame.nextButton:Enable()
	ETW_HelpFrame.previousButton:Enable()

	if(pageIndex <= 1) then
		ETW_HelpFrame.previousButton:Disable()
	end
	if(pageIndex >= maxPages) then
		ETW_HelpFrame.nextButton:Disable()
	end

end

local function changePage(index)

	if(index < 1) then index = 1 end
	if(index > maxPages) then index = maxPages end

	pageIndex = index
	ETW_HelpFrame.pageIndexText:SetText(pageIndex .. " / " .. maxPages)
	updateButtons()

	for index = 1, maxPages, 1 do
		if(ETW_HelpFrame.pages[index] ~= nil) then
			ETW_HelpFrame.pages[index]:Hide()
		end
	end
	if(ETW_HelpFrame.pages[pageIndex] ~= nil) then
		ETW_HelpFrame.pageFrame.title:SetText(ETW_HelpFrame.pages[pageIndex].title)
		ETW_HelpFrame.pages[pageIndex]:Show()
	end
end

local function createHelpPage(title, index)

	local helpPage = CreateFrame("Frame", "ETW_HelpPage"..index, ETW_HelpFrame.pageFrame)
	helpPage:SetAllPoints(ETW_HelpFrame.pageFrame)
	helpPage.title = title

	ETW_HelpFrame.pages[index] = helpPage

	return helpPage
end









----------------------------------------------------------------------------------
--       Help frame on how everything works
----------------------------------------------------------------------------------

do
	local help = ETW_Templates:CreatePortraitFrame("ETW_HelpFrame", UIParent, "ETW Help", ETW_HELPICON)
	help:SetPoint("CENTER")
	help:SetSize(300, 280)

	help:RegisterEvent("PLAYER_LOGIN")
	help:SetScript("OnEvent", function(self, event, ...)
		if(event == "PLAYER_LOGIN") then



		end
	end)

	help.pages = {}

	-- Extra tweaking because optionicon not same size
	--options.portraitIcon:SetPoint("TOPLEFT", -2, 5)

	ETW_Templates:MakeFrameDraggable(help)
	help:Hide()

	ETW_HelpFrame = help
end


----------------------------------------------------------------------------------
--       Page switching
----------------------------------------------------------------------------------

do
	local nextButton = CreateFrame("Button", "ETW_HelpNextButton", ETW_HelpFrame, "UIPanelButtonTemplate")
	nextButton:SetSize(70, 25)
	nextButton:SetPoint("BOTTOMRIGHT", -25, 5)
	nextButton:SetText("Next")
	nextButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			changePage(pageIndex+1)
		end
	end)

	local previousButton = CreateFrame("Button", "ETW_HelpPreviousButton", ETW_HelpFrame, "UIPanelButtonTemplate")
	previousButton:SetSize(70, 25)
	previousButton:SetPoint("BOTTOMLEFT", 25, 5)
	previousButton:SetText("Previous")
	previousButton:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			changePage(pageIndex-1)
		end
	end)

	local pageIndexText = ETW_HelpFrame:CreateFontString("ETW_HelpPageText", "ARTWORK", "GameFontNormal")
	pageIndexText:SetText(pageIndex .. " / " .. maxPages)
	pageIndexText:SetPoint("BOTTOM", 0, 10)

	ETW_HelpFrame.nextButton = nextButton
	ETW_HelpFrame.previousButton = previousButton
	ETW_HelpFrame.pageIndexText = pageIndexText

	updateButtons()
end


----------------------------------------------------------------------------------
--       Page for displaying info, page frame
----------------------------------------------------------------------------------

do

	local pageFrame = CreateFrame("Frame", "ETW_HelpPageFrame", ETW_HelpFrame, "InsetFrameTemplate3")

	pageFrame.title = pageFrame:CreateFontString("ETW_HelpPageTitle", "ARTWORK", "PVPInfoTextFont")
	pageFrame.title:SetTextHeight(16)
	pageFrame.title:SetPoint("TOP", 20, 20)

	pageFrame:SetPoint("CENTER", 0, -15)
	pageFrame:SetSize(ETW_HelpFrame:GetWidth()-40, ETW_HelpFrame:GetHeight()-100)


	ETW_HelpFrame.pageFrame = pageFrame
end


----------------------------------------------------------------------------------
--       Page content, help content
----------------------------------------------------------------------------------


do

	local helpFrame = createHelpPage("The categories", 1)

	local function createCategoryInfo(categoryIcon, name)

		local category = {}
		category.iconFrame = CreateFrame("Frame", "ETW_HelpPageOneCategoryFrame"..name, helpFrame, "GlowBoxTemplate")
		category.iconFrame:SetSize(25, 25)
		category.icon = category.iconFrame:CreateTexture()
		category.icon:SetTexture(categoryIcon)
		category.icon:SetPoint("CENTER")
		category.icon:SetSize(25, 25)
		category.text = helpFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		category.text:SetText(name)
		return category
	end

	helpFrame.categoryOne = createCategoryInfo(ETW_TRACKING_CATEGORY, "Tracking")
	helpFrame.categoryOne.iconFrame:SetPoint("TOPLEFT", 25, -20)
	helpFrame.categoryOne.text:SetPoint("TOPLEFT", 80, -25)

	helpFrame.categoryTwo = createCategoryInfo(ETW_INVESTIGATION_CATEGORY, "Investigaton")
	helpFrame.categoryTwo.iconFrame:SetPoint("TOPLEFT", 25, -60)
	helpFrame.categoryTwo.text:SetPoint("TOPLEFT", 80, -65)

	helpFrame.categoryThree = createCategoryInfo(ETW_EXPLORE_CATEGORY, "Exploration")
	helpFrame.categoryThree.iconFrame:SetPoint("TOPLEFT", 25, -100)
	helpFrame.categoryThree.text:SetPoint("TOPLEFT", 80, -105)

	helpFrame.categoryFour = createCategoryInfo(ETW_GROUPQUEST_CATEGORY, "Group questions")
	helpFrame.categoryFour.iconFrame:SetPoint("TOPLEFT", 25, -140)
	helpFrame.categoryFour.text:SetPoint("TOPLEFT", 80, -145)
end

local function createIconPage(frame, iconPath, text)
	frame.iconFrame = CreateFrame("Frame", "ETW_HelpPageCategoryFrame", frame, "GlowBoxTemplate")
	frame.iconFrame:SetSize(49, 49)
	frame.iconFrame:SetPoint("TOP", 0, -20)
	frame.icon = frame.iconFrame:CreateTexture()
	frame.icon:SetTexture(iconPath)
	frame.icon:SetPoint("CENTER")
	frame.icon:SetSize(50, 50)

	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.text:SetSize(frame:GetWidth()-20, frame:GetHeight())
	frame.text:SetPoint("CENTER", 0, -30)
	frame.text:SetText(text)
end

do

	local categoryOne = createHelpPage("Tracking", 2)
	createIconPage(categoryOne, ETW_TRACKING_CATEGORY, "The purpose of the Tracking category is to locate an NPC based on what is said to you. The NPC must then be targeted in order for you to answer the question.")

	local categoryTwo = createHelpPage("Investigaton", 3)
	createIconPage(categoryTwo, ETW_INVESTIGATION_CATEGORY, "The purpose of the Investigation category is to find an area and then answer a question based on its surroundings. As you write your own answer, there is usually multiple possible answers.")

	local categoryThree = createHelpPage("Exploration", 4)
	createIconPage(categoryThree, ETW_EXPLORE_CATEGORY, "The purpose of the Exploration category is to locate a zone/area based on what is said to you. This is usually smaller subzones and not a major zone such as \"Mulgore\"")

	local categoryFour = createHelpPage("Group question", 5)
	createIconPage(categoryFour, ETW_GROUPQUEST_CATEGORY, "Group questions can be either of the three \"normal\" categories. Data is broadcasted within your party whenever your answer changes. The question can then only be answered when all participants each fulfill one answer requirement each.")
end

do
	local helpFrame = createHelpPage("Unlockable questions", 6)
	createIconPage(helpFrame, "Interface\\ICONS\\INV_Misc_Gift_05.blp", "Only a limited number of questions are unlocked by default. The rest are unlocked by exploring, entering a zone, targeting an npc, looting an item, completing X amount of questions or reading a book/tombstone/etc. Anything really.")
end

do
	local helpFrame = createHelpPage("Ranks", 7)
	createIconPage(helpFrame, "Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_FASTTRACK_RANK2.BLP", "Ranks are given based on the % of the total amount of questions that you have completed. The rank of other players is retrieved from your client. Other players can thus never have ranks which doesn't exist in your client")
end

do 
	local helpFrame = createHelpPage("Contact", 8)
	createIconPage(helpFrame, "Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_GMAIL.BLP", "If you have any feedback to give or bugs to report, or if you want to help with development and contribute with questions, use the following|ne-mail:|n|netwaddon@gmail.com")
end

----------------------------------------------------------------------------------
--       Set to default page
----------------------------------------------------------------------------------


changePage(pageIndex)