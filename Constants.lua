

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

	SymphonymConfig_Default = ETW_Utility:CopyTable(SymphonymConfig)



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
					if(ETW_Utility:CreateSha2Hash(answer) == value) then
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
				ETW_Utility:PrintToChat("YOU WRONG")
			end

			-- Check all other answers after
			for index = 2, question.groupQuest.limit, 1 do

				if(checkAnswer(SymphonymConfig.questions[question.ID].answer[index].answer) == false) then
					correctAnswer = false
					ETW_Utility:PrintToChat("PLAYER WRONG")
					break
				end
			end

			if(correctAnswer == true) then
				isDone = true
				ETW_Utility:PrintToChat("IS TRU")
			end

		else
			local storedHash = ETW_Utility:CreateSha2Hash(SymphonymConfig.questions[question.ID].answer)

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
ETW_GROUPQUEST_CATEGORY = "Interface\\ICONS\\INV_Misc_GroupNeedMore.blp"

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
