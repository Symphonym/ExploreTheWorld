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
	SendAddonMessage(
	ETW_ADDONMSG_PREFIX,
		ETW_ADDONMSG_GROUPQUEST_REPORT..","..
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
		for _, zoneData in pairs(zoneReq) do

			local zoneReq = true
			local subZoneReq = true

			if(zoneData.zone ~= nil and ETW_Utility:CreateSha2Hash(realZone) ~= zoneData.zone) then
				zoneReq = false
			end
			if(zoneData.subZone ~= nil and ETW_Utility:CreateSha2Hash(subZone) ~= zoneData.subZone) then
				subZoneReq = false
			end


			if(zoneReq == true and subZoneReq == true) then
				return true
			end
		end
		return false
	end

	local function isCorrectAnswer(answers, answer)
		for _, value in pairs(answers) do
			if(ETW_Utility:CreateSha2Hash(answer) == value) then
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
	if(checkAnswer(yourAnswer, ETW_Utility:GetSubZone(), ETW_Utility:GetCurrentZone()) == false) then
		correctAnswer = false
	end

	-- For "Not the required zone" text to display semi-correctly
	local inTheRequiredZone = false
	for _, value in pairs(questsAnswers) do
		if(meetsZoneReq(value.zoneReq, ETW_Utility:GetSubZone(), ETW_Utility:GetCurrentZone()) == true) then
			inTheRequiredZone = true
		end
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

	-- Make sure each answer has been used by a player
	local allAnswersUsed = true
	for _, value in pairs(questsAnswers) do
		if(value.taken ~= true) then
			allAnswersUsed = false
		end
	end
	if(allAnswersUsed == false) then correctAnswer = false end

	return correctAnswer, inTheRequiredZone
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
	groupFrame:SetFrameStrata("TOOLTIP")
	groupFrame:SetToplevel(true)
	ETW_Templates:MakeFrameDraggable(groupFrame, 1)

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
			self:SetPoint("CENTER", ETW_Frame, "RIGHT", groupFrame:GetWidth()/2, 0)
			self:Show()
		else
			self:Hide()
		end
	end

	groupFrame:RegisterEvent("CHAT_MSG_ADDON")
	groupFrame:SetScript("OnEvent", function(self, event, ...)
		
		if(event == "CHAT_MSG_ADDON") then

			local prefix, sentMessage, channel, sender = ...
			local messageList = ETW_Utility:SplitString(sentMessage, ",")
			local messageCount = #(messageList)

			if(messageCount == 7 and prefix == ETW_ADDONMSG_PREFIX) then

				-- First item is always topic/prefix
				local messageTitle = messageList[1]

				-- Second and third items are always name and realm of sender, because I don't
				-- trust the "sender" variable :I
				local senderName, senderRealm = messageList[2], messageList[3]

				local senderNotMe = not (senderName == UnitName("player") and senderRealm == GetRealmName())

				if(messageTitle == ETW_ADDONMSG_GROUPQUEST_REPORT and senderNotMe or messageTitle == ETW_ADDONMSG_GROUPQUEST_REPLY and senderNotMe) then

					-- We're receiving data from other players
					local questionID = tonumber(messageList[4])
					local senderAnswer = messageList[5]
					local senderSubZone = messageList[6]
					local senderZone = messageList[7]

					-- Make sure you have the group quest
					if(ETW_Frame.questionList.items[questionID] ~= nil and groupQuest.activeQuest) then

						-- Make sure it's data about the question we're on
						if(groupQuest.question ~= nil and groupQuest.question.ID == questionID) then

							-- Load group question data
							groupQuest.question = ETW_Frame.questionList.items[questionID]
							groupQuest.playerReq = ETW_Frame.questionList.items[questionID].groupQuest.limit

							for index = 1, groupQuest.playerReq, 1 do
								if(groupQuest[index].name == senderName and groupQuest[index].realm == senderRealm or
									groupQuest[index].isActive == false) then

									groupQuest[index].isActive = true
									groupQuest[index].name = senderName
									groupQuest[index].realm = senderRealm
									groupQuest[index].subZone = senderSubZone
									groupQuest[index].realZone = senderZone

									if(groupQuest.completedQuest == false) then
										groupQuest[index].answerBox:SetText(senderAnswer)
										groupQuest[index].answerBox.text:SetText(senderName.."-"..senderRealm)
									end


									-- Give the sender our data as well
									if(messageTitle == ETW_ADDONMSG_GROUPQUEST_REPORT) then

										SendAddonMessage(ETW_ADDONMSG_PREFIX,
											ETW_ADDONMSG_GROUPQUEST_REPLY..","..
											UnitName("player")..","..
											GetRealmName()..","..
											questionID..","..
											ETW_Frame.questionFrame.answerBox:GetText()..","..
											ETW_Utility:GetSubZone()..","..
											ETW_Utility:GetCurrentZone(),
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