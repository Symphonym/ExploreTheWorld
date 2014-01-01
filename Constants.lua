

----------------------------------------------------------------------------------
--       DEFAULT CONFIG DATA
----------------------------------------------------------------------------------

	SymphonymConfig = 
	{
		questions = 
		{
			sorting = 
			{
				showExplore = true,
				showInvestigation = true,
				showTracking = true,
				showGroupQuest = true,
				showCompleted = true,
				showNewQuests = true
			},

			-- Question specific data is stored in here
			-- Mapping question ID to it's related data

			completed = 0
		},

		options =
		{
			rotate3DModel = true,
			scanInCombat = true,
			showUnlockPopups = true,
			ignoreLinks = false,
			pageLimit = 100,
		},

		uniqueHash = sha2.hash256(tostring(random(0, 1000)))

	}


----------------------------------------------------------------------------------
--       SHA2 HASHING and BASE64 converting
----------------------------------------------------------------------------------


-- Creates a sha2 hash of the parameter
function ETW_createHash(msg)
	return sha2.hash256(string.lower(msg))
end
-- Converts base64 to base10 data
function ETW_convertBase64(data)
	-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
	-- licensed under the terms of the LGPL2
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

----------------------------------------------------------------------------------
--      Template functions
----------------------------------------------------------------------------------

function ETW_makeFrameDraggable(frame, wholeFrame)

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

function ETW_givePortraitFrameIcon(frame, icon)
	frame.portraitIcon = frame:CreateTexture()

	if(icon == nil) then
		frame.portraitIcon:SetTexture(ETW_ADDONICON)
	else
		frame.portraitIcon:SetTexture(icon)
	end
	frame.portraitIcon:SetSize(59, 59)
	frame.portraitIcon:SetPoint("TOPLEFT", frame, -5, 7)
	frame.portraitIcon:SetDrawLayer("BORDER", 5)
end

----------------------------------------------------------------------------------
--      USEFULL FUNCTIONS
----------------------------------------------------------------------------------


-- Whether or not the specified question has been answered
function ETW_isQuestionDone(question)

	local isDone = false
	if(SymphonymConfig.questions[question.ID] and SymphonymConfig.questions[question.ID].answer) then
		
		if(question.category == ETW_GROUPQUEST_CATEGORY and question.groupQuest ~= nil) then
			local questAnswers = {}
			for index = 1, question.groupQuest.limit, 1 do
				questAnswers[index] = {}
				questAnswers[index].answer = question.groupQuest[index].answer
			end

			local function isCorrectAnswer(answers, answer)
				for _, value in pairs(answers) do
					if(ETW_createHash(answer) == value) then
						return true
					end
				end
				return false
			end

			local function checkAnswer(answer)
				for _, value in pairs(questAnswers) do
					if(value.taken == nil) then
						if(isCorrectAnswer(value.answer, answer))then
							value.taken = true
							return true
						end
					end
				end
				return false
			end

			local correctAnswer = true

			-- Check our own answer first
			if(checkAnswer(SymphonymConfig.questions[question.ID].answer[1].answer) == false) then
				correctAnswer = false
				ETW_printToChat("YOU WRONG")
			end

			-- Check all other answers after
			for index = 2, question.groupQuest.limit, 1 do

				if(checkAnswer(SymphonymConfig.questions[question.ID].answer[index].answer) == false) then
					correctAnswer = false
					ETW_printToChat("PLAYER WRONG")
					break
				end
			end

			if(correctAnswer == true) then
				isDone = true
				ETW_printToChat("IS TRU")
			end

		else
			local storedHash = ETW_createHash(SymphonymConfig.questions[question.ID].answer)

			for _, answer in pairs(question.answer) do
				if(storedHash == answer) then
					isDone = true
					break
				end
			end
		end

	end

	return isDone
end

function ETW_printToChat(msg)
	ChatFrame1:AddMessage("|cFF00FF00[Explore the World]|r|cFFFFFB00:" .. msg)
end 
function ETW_printErrorToChat(msg)
	ChatFrame1:AddMessage("|cFF00FF00[Explore the World]|r|cFFFFFB00:|cFFFF3F40" .. msg)
end

function ETW_decimalToHex(r,g,b)
	-- http://wowprogramming.com/snippets/Convert_decimal_classcolor_into_hex_27
    return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end
-- Get name of current zone, custom function and not semi-reliable WoW zone functions
function ETW_getCurrentZone()
	local zones = { GetMapZones(GetCurrentMapContinent()) }
	local zone = zones[GetCurrentMapZone()]
	if(zone == nil) then
		return GetRealZoneText()
	else
		return zone
	end
end


-- single char string splitter, sep *must* be a single char pattern
-- *probably* escaped with % if it has any special pattern meaning, eg "%." not "."
-- so good for splitting paths on "/" or "%." which is a common need
--http://lua-users.org/wiki/SplitJoin
function ETW_csplit(str,sep)
	local ret={}
	local n=1
	for w in str:gmatch("([^"..sep.."]*)") do
		ret[n]=ret[n] or w -- only set once (so the blank after a string is ignored)
		if w=="" then n=n+1 end -- step forwards on a blank but not a string
	end
	return ret
end


----------------------------------------------------------------------------------
--      GLOBAL VARIABLES
----------------------------------------------------------------------------------



-- Size of the question buttons
ETW_LISTITEM_WIDTH = 219
ETW_LISTITEM_HEIGHT = 30
ETW_LISTITEM_ALIGN = "TOPRIGHT"


ETW_DEFAULT_BACKDROP = {
  -- path to the background texture
  --bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  
  -- path to the border texture
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  -- true to repeat the background texture to fill the frame, false to scale it
  tile = true,
  -- size (width or height) of the square repeating background tiles (in pixels)
  tileSize = 16,
  -- thickness of edge segments and square size of edge corners (in pixels)
  edgeSize = 16,
  -- distance from the edges of the frame to those of the background texture (in pixels)
  offsets = {
    left = 11,
    right = 0,
    top = 0,
    bottom = 0
  }
}

-- Used as a hybrid for category icon and category identifier
ETW_EXPLORE_CATEGORY = "Interface\\ICONS\\Achievement_Zone_UnGoroCrater_01.blp"
ETW_INVESTIGATION_CATEGORY = "Interface\\ICONS\\INV_Misc_Spyglass_01.blp"
ETW_TRACKING_CATEGORY = "Interface\\ICONS\\Ability_Tracking.blp"
ETW_GROUPQUEST_CATEGORY = "Interface\\ICONS\\inv_mask_01.blp"

ETW_DEFAULT_QUESTION_TEXTURE = "Interface\\Glues\\Models\\UI_Worgen\\UI_Worgen_BG05a.blp"

-- Names of the dropdown menu
ETW_EXPLORE_DROPDOWN_NAME = "Explore"
ETW_INVESTIGATION_DROPDOWN_NAME = "Investigation"
ETW_TRACKING_DROPDOWN_NAME = "Tracking"
ETW_GROUPQUEST_DROPDOWN_NAME = "Group question"
ETW_COMPLETED_DROPDOWN_NAME = "Completed quests"
ETW_NEWQUEST_DROPDOWN_NAME = "New quests"

-- Names of the different things you can unlock questions from
ETW_ITEM_UNLOCK_NAME = "Item"
ETW_NPC_UNLOCK_NAME = "Npc"
ETW_ZONE_UNLOCK_NAME = "Zone"
ETW_WORLDOBJECT_UNLOCK_NAME = "Lore"
ETW_PROGRESS_UNLOCK_NAME = "Progress"

-- Icons of the addon
ETW_ADDONICON = "Interface\\WorldMap\\WorldMap-Icon.blp"
ETW_OPTIONICON = "Interface\\TUTORIALFRAME\\UI-HELP-PORTRAIT.blp"

-- Background for the description frame of the questions
ETW_QUESTLOG_BACKGROUND = "Interface\\QUESTFRAME\\QuestBG.blp"

-- Linkbutton data
ETW_LINKBUTTON_NORMAL = "Interface\\GossipFrame\\HealerGossipIcon.blp"
ETW_LINKBUTTON_HIGHLIGHT = "Interface\\GossipFrame\\BinderGossipIcon.blp"

-- Default zooming of the optional 3D model
ETW_MODEL_NPC_ZOOM = 0.5
ETW_MODEL_NPC_MINZOOM = 0.0
ETW_MODEL_NPC_MAXZOOM = 0.8

ETW_MODEL_MISC_ZOOM = 3

-- Group quest constants
ETW_PLAYERS_MAX = 4
ETW_PLAYERS_TOTALMAX = 5

-- Popup constants
ETW_POPUP_SOUND = "Sound\\INTERFACE\\UI_Cutscene_Stinger.ogg"
ETW_UNLOCK_POPUP_ICON = "Interface\\ICONS\\INV_Misc_Map02.blp"
ETW_CLASSICONS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes.blp"

-- Custom addon prefix for linking questions
ETW_ADDONMSG_LINK = "ETW_QuestionLink"
ETW_ADDONMSG_GROUPQUEST = "ETW_GroupQuest"

-- Button highlighting
ETW_RED_HIGHLIGHT = {1, 0, 0, 0.3}
ETW_GREEN_HIGHLIGHT = {0, 1, 0, 0.3}
ETW_BLUE_HIGHLIGHT = {0, 0, 1, 0.3}
ETW_NO_HIGHLIGHT = {0, 0, 0, 0}

ETW_CREDIT_STRING = [[
Created by: 
Jakob Larsson|n|n|cFFF58CBAProgrammer|n|rDefias Brotherhood, EU|n|cFFC41F3BHorde|r

Thanks to:
]]
ETW_THANKSTO_STRING = [[
Karl Marelius,|cFF0070DE Tezlo|r (Primary tester)
Niklas löf Arefjärd,|cFFC79C6E Stahli|r (Tester)
]]
