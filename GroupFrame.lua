--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--      Group quest extra frame and data
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

local frameName = "ETW_GroupFrame"
ETW_GroupFrame = {}

local groupQuest = 
{
	[1] = 
		{
			name = "",
			realm = "",
			isActive = false,
			answerBox = nil,
			subZone = "",
			realZone
		},
	[2] = 
		{
			name = "",
			realm = "",
			isActive = false,
			answerBox = nil,
			subZone = "",
			realZone
		},
	[3] = 
		{
			name = "",
			realm = "",
			isActive = false,
			answerBox = nil,
			subZone = "",
			realZone
		},
	[4] = 
		{
			name = "",
			realm = "",
			isActive = false,
			answerBox = nil,
			subZone = "",
			realZone
		},

	playerReq = 0,
	activeQuest = false, -- Whether or not the quest is currently being done
	question = nil, -- The question itself with all the data
	completedQuest = false
}

function ETW_StartGroupQuest(question)

	if(groupQuest.activeQuest == false) then
		ETW_GroupFrame:ShowGroupFrame(question)
		groupQuest.activeQuest = true
	end


end

function ETW_CancelGroupQuest()

	groupQuest.question = nil
	groupQuest.activeQuest = false
	groupQuest.playerReq = 0
	groupQuest.completedQuest = false

	for index = 1, ETW_PLAYERS_MAX, 1 do
		groupQuest[index].isActive = false
		groupQuest[index].name = ""
		groupQuest[index].realm = ""
		groupQuest[index].subZone = ""
		groupQuest[index].realZone = ""
	end

	ETW_GroupFrame:Hide()
end

function ETW_BroadcastGroupQuestData(data)

	SendAddonMessage(ETW_ADDONMSG_GROUPQUEST,
		UnitName("player")..","..
		GetRealmName()..","..
		"GiveData,"..
		UnitName("player")..","..
		GetRealmName()..","..
		data,
	"PARTY")
end

function ETW_CheckGroupQuestAnswer(yourAnswer)

	local correctAnswer = true

	local questsAnswers = {}
	for index = 1, groupQuest.playerReq, 1 do
		questsAnswers[index] = {}
		questsAnswers[index].answer = groupQuest.question.groupQuest[index].answer
		questsAnswers[index].zoneReq = groupQuest.question.groupQuest[index].zoneRequirementHash
	end

	local function meetsZoneReq(zoneReq, subZone, realZone)
		if(zoneReq == nil) then
			return true
		end
		for _, value in pairs(zoneReq) do
			if(ETW_createHash(subZone) == value or ETW_createHash(realZone) == value) then
				return true
			end
		end
		return false
	end

	local function isCorrectAnswer(answers, answer)
		for _, value in pairs(answers) do
			if(ETW_createHash(answer) == value) then
				return true
			end
		end
		return false
	end

	local function checkAnswer(answer, subZone, realZone)
		for _, value in pairs(questsAnswers) do
			if(value.taken == nil) then
				if(isCorrectAnswer(value.answer, answer) and meetsZoneReq(value.zoneReq, subZone, realZone))then
					value.taken = true
					return true
				end
			end
		end
		return false
	end
	-- Check our own answer first
	if(checkAnswer(yourAnswer, GetSubZoneText(), ETW_getCurrentZone()) == false) then
		correctAnswer = false
	end

	-- Check all other answers after
	for index = 1, groupQuest.playerReq, 1 do
		if(groupQuest[index].isActive == true) then

			if(checkAnswer(
				groupQuest[index].answerBox:GetText(),
				groupQuest[index].subZone,
				groupQuest[index].realZone) == false) then

				correctAnswer = false
				groupQuest[index].answerBox:SetErrorColor()
			else
				groupQuest[index].answerBox:SetSuccessColor()
			end
		end
	end

	return correctAnswer
end


function ETW_SaveGroupQuestAnswer(yourAnswer)
	SymphonymConfig.questions[groupQuest.question.ID] = {}
	SymphonymConfig.questions[groupQuest.question.ID].answer = {}


	local function saveAnswer(index, name, realm, answer)
		SymphonymConfig.questions[groupQuest.question.ID].answer[index] = {}
		SymphonymConfig.questions[groupQuest.question.ID].answer[index].playerName = name
		SymphonymConfig.questions[groupQuest.question.ID].answer[index].playerRealm = realm
		SymphonymConfig.questions[groupQuest.question.ID].answer[index].answer = answer
	end

	saveAnswer(1, UnitName("player"), GetRealmName(), yourAnswer)
	for index = 1, groupQuest.playerReq, 1 do
		if(groupQuest[index].isActive == true) then
			saveAnswer(index+1, groupQuest[index].name, groupQuest[index].realm, groupQuest[index].answerBox:GetText())
		end
	end
end
function ETW_IsGroupQuestActive(question)
	if(groupQuest.question == nil) then
		return false
	else
		if(groupQuest.question.ID == question.ID and groupQuest.activeQuest == true) then
			return true
		else
			return false
		end
	end
end

do

	local groupFrame = CreateFrame("Frame", frameName, UIParent, "BasicFrameTemplate")
	groupFrame:SetPoint("CENTER", ETW_Frame, "RIGHT", groupFrame:GetWidth()/2, 0)
	groupFrame:SetFrameStrata("TOOLTIP")

	groupFrame.title = groupFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	groupFrame.title:SetPoint("CENTER", groupFrame, "TOP", 0, -12);
	groupFrame.title:SetTextHeight(13);
	groupFrame.title:SetText("Group frame")

	local function createAnswerBox(name)
		local answerBox = CreateFrame("EditBox", name, groupFrame, "InputBoxTemplate")
		answerBox:SetSize(230, 20)
		answerBox:SetAutoFocus(false)
		answerBox:Disable()

		answerBox.text = answerBox:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
		answerBox.text:SetPoint("LEFT", answerBox, "LEFT", 0, 20)

		answerBox.foreground = answerBox:CreateTexture()
		answerBox.foreground:SetAllPoints()
		answerBox.foreground:SetAlpha(0)

		function answerBox:SetSuccessColor()
			self.foreground:SetTexture(0,1,0, 0.3)
			self.foreground:SetAlpha(1)
		end
		function answerBox:SetErrorColor()
			self.foreground:SetTexture(1,0,0, 0.3)
			self.foreground:SetAlpha(1)
		end

		return answerBox
	end

	-- Create answerboxes for each player
	local answer1 = createAnswerBox(frameName.."AnswerBox1")
	answer1:SetPoint("TOPLEFT", 10, -55)
	groupQuest[1].answerBox = answer1

	local answer2 = createAnswerBox(frameName.."AnswerBox2")
	answer2:SetPoint("TOPLEFT", 10, -100)
	groupQuest[2].answerBox = answer2

	local answer3 = createAnswerBox(frameName.."AnswerBox3")
	answer3:SetPoint("TOPLEFT", 10, -145)
	groupQuest[3].answerBox = answer3

	local answer4 = createAnswerBox(frameName.."AnswerBox4")
	answer4:SetPoint("TOPLEFT", 10, -190)
	groupQuest[4].answerBox = answer4


	function groupFrame:ShowGroupFrame(question)
		groupQuest.playerReq = question.groupQuest.limit - 1 --(Exclude ourselves)
		groupQuest.question = question
		groupFrame.title:SetText(question.name.." ["..question.ID.."]")

		local function prepareAnswerbox(index)
			groupQuest[index].answerBox.text:SetText("No player available")
			groupQuest[index].answerBox:SetText("")
			groupQuest[index].answerBox.foreground:SetAlpha(0)
		end

		-- Reset player data
		for index = 1, ETW_PLAYERS_MAX, 1 do
			groupQuest[index].isActive = false
			groupQuest[index].name = ""
			groupQuest[index].realm = ""
			groupQuest[index].subZone = ""
			groupQuest[index].realZone = ""
			prepareAnswerbox(index)
		end

		if(ETW_isQuestionDone(question)) then
			groupQuest.completedQuest = true

			for index = 1, groupQuest.playerReq, 1 do
				local configFile = SymphonymConfig.questions[question.ID].answer[index+1] -- First index is you
				groupQuest[index].answerBox.text:SetText(configFile.playerName.."-"..configFile.playerRealm)
				groupQuest[index].answerBox:SetText(configFile.answer)
				groupQuest[index].answerBox:SetSuccessColor()
			end
		else
			groupQuest.completedQuest = false
		end

		for index = 1, ETW_PLAYERS_MAX, 1 do
			if(index <= groupQuest.playerReq) then
				groupQuest[index].answerBox:Show()
			else
				groupQuest[index].answerBox:Hide()
			end
		end

		-- Show group frame
		if(groupQuest.playerReq >= 1) then
			self:SetSize(250, 55*groupQuest.playerReq + (ETW_PLAYERS_MAX/groupQuest.playerReq)*8)
			ETW_makeFrameDraggable(self, 1)
			self:SetPoint("CENTER")
			self:Show()
		else
			self:Hide()
		end
	end

	RegisterAddonMessagePrefix(ETW_ADDONMSG_GROUPQUEST)
	groupFrame:RegisterEvent("CHAT_MSG_ADDON")
	groupFrame:SetScript("OnEvent", function(self, event, ...)
		
		if(event == "CHAT_MSG_ADDON") then

			local prefix, sentMessage, channel, sender = ...
			local messageList = ETW_csplit(sentMessage, ",")

			if(prefix == ETW_ADDONMSG_GROUPQUEST and sender ~= UnitName("player")) then

				-- First two items are always name and realm
				local senderName, senderRealm = messageList[1], messageList[2]

				local messageTitle = messageList[3]


				if(messageTitle == "GiveData" or messageTitle == "ReplyData") then

					-- The leader of the quest is giving us data about the other players
					local playerName = messageList[4]
					local playerRealm = messageList[5]
					local questionID = tonumber(messageList[6])
					local playerAnswer = messageList[7]
					local playerSubZone = messageList[8]
					local playerZone = messageList[9]

					-- Make sure you have the group quest
					if(ETW_Frame.questionList.items[questionID] ~= nil and groupQuest.activeQuest) then

						-- Make sure it's data about the question we're on
						if(groupQuest.question ~= nil and groupQuest.question.ID == questionID) then

							-- Load group question data
							groupQuest.question = ETW_Frame.questionList.items[questionID]
							groupQuest.playerReq = ETW_Frame.questionList.items[questionID].groupQuest.limit

							for index = 1, groupQuest.playerReq, 1 do
								if(groupQuest[index].name == playerName and groupQuest[index].realm == playerRealm or
									groupQuest[index].isActive == false) then

									groupQuest[index].isActive = true
									groupQuest[index].name = playerName
									groupQuest[index].realm = playerRealm
									groupQuest[index].subZone = playerSubZone
									groupQuest[index].realZone = playerZone

									if(groupQuest.completedQuest == false) then
										groupQuest[index].answerBox:SetText(playerAnswer)
										groupQuest[index].answerBox.text:SetText(playerName.."-"..playerRealm)
									end


									if(messageTitle == "GiveData") then

										-- Give the sender our data as well
										SendAddonMessage(ETW_ADDONMSG_GROUPQUEST,
											UnitName("player")..","..
											GetRealmName()..","..
											"ReplyData,"..
											UnitName("player")..","..
											GetRealmName()..","..
											questionID..","..
											ETW_Frame.questionFrame.answerBox:GetText()..","..
											GetSubZoneText()..","..
											ETW_getCurrentZone(),
										"WHISPER",
										senderName.."-"..senderRealm)

									end

									break
								end
							end
						end
					end
				end
			end

		end
	end)

	ETW_GroupFrame = groupFrame
end