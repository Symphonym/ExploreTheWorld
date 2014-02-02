
----------------------------------------------------------------------------------
--       Variables
----------------------------------------------------------------------------------

ETW_ChallengeFrame = {}
ETW_ChallengeWindow = {}

local challengeQuestions = {}

----------------------------------------------------------------------------------
--       Challenge frame
----------------------------------------------------------------------------------

local challengeFrameCount = 0
local function createChallengeButton(title, icon)
	challengeFrameCount = challengeFrameCount + 1

	local frame = CreateFrame("Frame", "ETW_ChallengeFrame"..challengeFrameCount, ETW_ChallengeFrame, "InsetFrameTemplate3")
	frame:SetSize(ETW_ChallengeFrame:GetWidth()-20, 39)
	frame:SetPoint("CENTER")

	local image = frame:CreateTexture() 
	image:SetTexture(icon)
	image:SetSize(35, 35)
	image:SetPoint("LEFT", 2, 0)

	local button = CreateFrame("Button", "ETW_ChallengeButton"..challengeFrameCount, frame, "UIPanelButtonTemplate")
	button:SetSize(frame:GetWidth()-image:GetWidth()-3, 37)
	button:SetPoint("RIGHT", 0, 1)
	button:SetText(title)

	frame.icon = image
	frame.button = button

	return frame
end

do 
	local challenge = ETW_Templates:CreatePortraitFrame("ETW_ChallengeFrame", UIParent, "ETW Challenges", "Interface\\TARGETINGFRAME\\TargetDead.blp")
	challenge:SetPoint("CENTER")
	challenge:SetSize(250, 300)
	ETW_Templates:MakeFrameDraggable(challenge)
	challenge:Hide()

	function challenge:CreateData(name, title, text, initChallengeFunction)
		self.frames[name] = {}
		self.frames[name].title = title
		self.frames[name].text = text
		self.frames[name].initChallengeFunction = initChallengeFunction
		return self.frames[name]
	end

	function challenge:ShowData(name)

		if(name == "Main") then
			for index = 1, challengeFrameCount, 1 do
				_G["ETW_ChallengeFrame"..index]:Show()
			end

			self.backButton:Hide()
			self.startButton:Hide()
		else
			for index = 1, challengeFrameCount, 1 do
				_G["ETW_ChallengeFrame"..index]:Hide()
			end

			self.backButton:Show()
			self.startButton:Show()	
		end


		self.initChallengeFunction = self.frames[name].initChallengeFunction
		self.title:SetText(self.frames[name].title)
		self.descFrame.text:SetText(self.frames[name].text)
	end

	-- Sub frames
	challenge.frames = {}
	challenge:CreateData("Main", "Challenges", ETW_CHALLENGE_DESCRIPTION)

	ETW_ChallengeFrame = challenge

	-- Description frame
	local descFrame = CreateFrame("Frame", "ETW_ChallengeDescriptionFrame", ETW_ChallengeFrame, "InsetFrameTemplate3")
	descFrame:SetSize(challenge:GetWidth()-20, 105)
	descFrame:SetPoint("TOP", 0, -60)
	-- Description text
	local desc = descFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	desc:SetSize(descFrame:GetWidth()-8, descFrame:GetHeight()-8)
	desc:SetPoint("TOP",0, -4)
	descFrame.text = desc
	challenge.descFrame = descFrame

	-- Title
	challenge.title = challenge:CreateFontString(nil, "ARTWORK", "PVPInfoTextFont")
	challenge.title:SetPoint("TOP", 15, -32)


	local backButton = CreateFrame("Button", "ETW_ChallengeBackButton", ETW_ChallengeFrame, "UIPanelButtonTemplate")
	backButton:SetSize(160, 40)
	backButton:SetPoint("BOTTOM", 0, 5)
	backButton:SetText("Back")
	backButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame:ShowData("Main")
		end
	end)
	backButton:Hide()


	local startButton = CreateFrame("Button", "ETW_ChallengeStartButton", ETW_ChallengeFrame, "UIPanelButtonTemplate")
	startButton:SetSize(160, 40)
	startButton:SetPoint("BOTTOM", 0, 45)
	startButton:SetText("Start the challenge")
	startButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			if not (ETW_IsChallengeReady()) then
				ETW_Utility:PrintErrorToChat(" Your challenge cooldown is still active!")
			elseif(ETW_ChallengeWindow.activeChallenge) then
				ETW_Utility:PrintErrorToChat(" You're already doing a challenge. Stay focused!")
			else
				ETW_ChallengeFrame.initChallengeFunction()
			end
		end
	end)
	startButton:Hide()

	challenge.backButton = backButton
	challenge.startButton = startButton


	challenge:ShowData("Main")
end

----------------------------------------------------------------------------------
--       Challenge cooldown bar
----------------------------------------------------------------------------------

local function addChallengePoints(points)

	ETW_Utility:PrintToChat(points .. " challenge points was added")
	for count = 1, points, 1 do

		SymphonymConfig.challengePoints = SymphonymConfig.challengePoints + 1

		-- Granting reward once limit is reached
		if(SymphonymConfig.challengePoints >= ETW_CHALLENGE_POINTS_REQUIRED) then
			ETW_GrantChallengeReward()
			SymphonymConfig.challengePoints = 0
		end

	end
end

local function removeChallengePoints(points)

	ETW_Utility:PrintToChat(points .. " challenge points was removed")
	local negativeScore = false
	for count = 1, math.abs(points), 1 do

		SymphonymConfig.challengePoints = SymphonymConfig.challengePoints - 1

		-- Add time to challenge cooldown for each negative point
		if(SymphonymConfig.challengePoints < 0) then
			negativeScore = true
			SymphonymConfig.challengePoints = 0
			SymphonymConfig.challengeCooldownStarted = SymphonymConfig.challengeCooldownStarted + ETW_CHALLENGE_NEGATIVE_POINT_REDUCTION
		end
	end

	if(negativeScore) then
		ETW_Utility:PrintToChat(" You received negative challenge points and had time added to your challenge cooldown.")
	end
end

do

	local statusFrame = ETW_Templates:CreateStatusBar(
		"ETW_ChallengeCooldown",
		ETW_ChallengeFrame,
		1, 100, {0,0.8,0}, ETW_ChallengeFrame.descFrame:GetWidth(), 24)
	statusFrame:SetPoint("CENTER",0,-30)

	local challengePointBar = ETW_Templates:CreateStatusBar(
		"ETW_ChallengePointBar",
		ETW_ChallengeFrame,
		0, ETW_CHALLENGE_POINTS_REQUIRED, {0,0.0,0.8}, ETW_ChallengeFrame.descFrame:GetWidth(), 20)
	challengePointBar:SetPoint("CENTER",0,-50)

	statusFrame.bar:SetScript("OnUpdate", function(self, elapsed)
		local startedTime = SymphonymConfig.challengeCooldownStarted
		local secondsPassed = time() - startedTime
		local percentagePassed = secondsPassed/ETW_CHALLENGE_COOLDOWN

		local timeleft = ETW_CHALLENGE_COOLDOWN - secondsPassed
		local minValue, maxValue = self:GetMinMaxValues()


		-- Cooldown over, challenges ready
		if(secondsPassed >= ETW_CHALLENGE_COOLDOWN) then
			self:SetValue(maxValue)
			self.text:SetText("Challenges ready")

		-- Cooldown still active, challenges not ready
		else
			-- Time left, the power of modulo
			local hours = math.floor(timeleft/3600)
			local minutes = math.floor((timeleft%3600)/60)
			local seconds = math.floor(timeleft%60)

			self.text:SetText(hours.."h "..minutes.."m "..seconds.."s")
			self:SetValue(maxValue*percentagePassed)
		end

		challengePointBar.bar:SetValue(SymphonymConfig.challengePoints)
		challengePointBar.bar.text:SetText(ETW_CHALLENGE_POINTS_REQUIRED-SymphonymConfig.challengePoints.." point(s) to question unlock")


	end)

end

----------------------------------------------------------------------------------
--       Challenge window
----------------------------------------------------------------------------------


do 
	local challenge = CreateFrame("Frame", "ETW_ChallengeWindow", UIParent, "InsetFrameTemplate3")
	challenge:SetPoint("TOPLEFT")
	challenge:SetSize(300, 150)
	ETW_Templates:MakeFrameDraggable(challenge, true)
	challenge:Hide()

	challenge.title = challenge:CreateFontString(nil, "ARTWORK", "PVPInfoTextFont")
	challenge.title:SetPoint("TOP", 0, -10)

	challenge.subTitle = challenge:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	challenge.subTitle:SetTextHeight(14)
	challenge.subTitle:SetPoint("TOP", 0, -37)

	challenge.frames = {}
	challenge.startedTime = time()
	challenge.activeChallenge = false

	function challenge:CreateChallengeFrame(name, title, subTitle, width, height, timeLimit, onShowFunction, onAnswerFunction, onExpireFunction)
		local frame = CreateFrame("Frame", nil, self)
		frame:SetSize(self:GetWidth()-40, self:GetHeight()-100)
		frame:SetPoint("TOP", 0, -100)
		frame.title = title
		frame.subTitle = subTitle
		frame.customWidth = width
		frame.customHeight = height
		frame.timeLimit = timeLimit
		frame.onExpireFunction = onExpireFunction
		frame.onAnswerFunction = onAnswerFunction
		frame.onShowFunction = onShowFunction
		frame:Hide()
		self.frames[name] = frame
		return frame
	end

	function challenge:ShowChallengeFrame(name)
		for _, value in pairs(self.frames) do
			value:Hide()
		end

		self:Show()
		self.activeSubFrame = name
		self:SetSize(self.frames[name].customWidth, self.frames[name].customHeight)
		self.title:SetText(self.frames[name].title)
		self.subTitle:SetText(self.frames[name].subTitle)
		self.frames[name]:SetSize(self:GetWidth()-40, self:GetHeight()-100)
		self.frames[name]:SetPoint("BOTTOM", 0, 10)
		self.frames[name]:Show()
		self.frames[name].onShowFunction(self.frames[name])
	end

	ETW_ChallengeWindow = challenge


	local statusFrame = ETW_Templates:CreateStatusBar(
		"ETW_ChallengeWindowStatus",
		ETW_ChallengeWindow,
		1, 100, {0,0.8,0}, ETW_ChallengeWindow:GetWidth()-40, 24)
	statusFrame:SetPoint("TOP", 0, -55)
	statusFrame.bar:SetScript("OnUpdate", function(self, elapsed)
		
		if(ETW_ChallengeWindow.activeChallenge) then
			local timelimit = ETW_ChallengeWindow.frames[ETW_ChallengeWindow.activeSubFrame].timeLimit

			local startedTime = ETW_ChallengeWindow.startedTime
			local secondsPassed = time() - startedTime
			local percentagePassed = secondsPassed/timelimit

			local timeleft = timelimit - secondsPassed


			local minValue, maxValue = self:GetMinMaxValues()
			local texture = self:GetStatusBarTexture()

			-- Time over
			if(secondsPassed >= timelimit) then
				self:SetValue(maxValue)
				self.text:SetText("Time expired")
				texture:SetVertexColor(0.8,0,0,1)

				-- Run expire function
				ETW_ChallengeWindow.activeChallenge = false
				ETW_ChallengeWindow.frames[ETW_ChallengeWindow.activeSubFrame].onExpireFunction(ETW_ChallengeWindow.frames[ETW_ChallengeWindow.activeSubFrame])

			-- Time still ticking
			else
				texture:SetVertexColor(0,0.8,0,1)

				-- Time left, the power of modulo
				local hours = math.floor(timeleft/3600)
				local minutes = math.floor((timeleft%3600)/60)
				local seconds = math.floor(timeleft%60)

				self.text:SetText(hours.."h "..minutes.."m "..seconds.."s")
				self:SetValue(maxValue*percentagePassed)
			end
		end
	end)

	ETW_ChallengeWindow.timeBar = statusFrame.bar
end
















----------------------------------------------------------------------------------
--       Single player challenge, Swift exploration
----------------------------------------------------------------------------------

do 
	local function initFunction()
		StaticPopup_Show ("ETW_StartChallenge_SwiftExploring")
	end

	ETW_ChallengeFrame:CreateData(
		"SE",
		"Single player",
		ETW_CHALLENGE_SWIFT_EXPLORING_DESCRIPTION,
		initFunction)

	local challenge = createChallengeButton("Swift Exploring", "Interface\\ICONS\\Rogue_BurstofSpeed.blp")
	challenge:SetPoint("BOTTOM", 0, 47)
	challenge.button:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame:ShowData("SE")
			SymphonymConfig.challengeCooldownStarted = SymphonymConfig.challengeCooldownStarted - 5
		end
	end)

	StaticPopupDialogs["ETW_StartChallenge_SwiftExploring"] = {
		text = "As soon as you press \"Start\" the challenge will start and the cooldown will reset",
		showAlert = true,
		button1 = "Start",
		button2 = "Cancel",
		OnAccept = function()
			SymphonymConfig.challengeCooldownStarted = time()
			ETW_ChallengeFrame:ShowData("Main")

			-- Grab a question for the challenge
			challengeQuestions = {}
			local question = ETW_GenerateChallengeQuestion()
			challengeQuestions[question.ID] = question
			ETW_ForceUpdate()

			ETW_ChallengeWindow:ShowChallengeFrame("SE")
			ETW_ChallengeWindow.activeChallenge = true
			ETW_ChallengeWindow.startedTime = time()
			ETW_ChallengeWindow.subTitle:SetText(question.name.."["..question.ID.."]")
		end,
		OnCancel = function (_,reason)

		end,
		sound = "GAMEDIALOGOPEN",
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}
end

----------------------------------------------------------------------------------
--       Single player challenge info page, Swift exploring
----------------------------------------------------------------------------------

do 
	local function resetData(self)
		self.questionButton:Disable()
		self.doneButton:Enable()
		challengeQuestions = {}
		ETW_ChallengeWindow.activeChallenge = false
		ETW_ForceUpdate()
	end

	-- Starting challenge
	local function onShowFunction(self)
		self.doneButton:Disable()
		self.questionButton:Enable()
	end

	-- Completing challenge
	local function completeFunction(self, question)
		resetData(self)

		local secondsPassed = time() - ETW_ChallengeWindow.startedTime

		local timeleft = ETW_CHALLENGE_SWIFT_EXPLORING_TIME - secondsPassed
		local minutes = math.floor(timeleft/60)

		if(minutes >= 4) then
			addChallengePoints(2)
		elseif(minutes >= 3) then
			addChallengePoints(1)
		end
	end

	-- Failing challenge, time expires
	local function onExpireFunction(self)
		resetData(self)
	end

	local frame = ETW_ChallengeWindow:CreateChallengeFrame(
		"SE",
		"Swift Exploring",
		"Woop",
		300, 115, ETW_CHALLENGE_SWIFT_EXPLORING_TIME,
		onShowFunction,
		completeFunction,
		onExpireFunction)

	local questionButton = CreateFrame("Button", "ETW_Challenge_SE_DisplayButton", frame, "UIPanelButtonTemplate")
	questionButton:SetSize(110, 30)
	questionButton:SetPoint("LEFT", 0, 7)
	questionButton:SetText("View question")
	questionButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			-- SE challenge only has 1 question but it's in a table anyhow
			for _, question in pairs(challengeQuestions) do
				ETW_DisplayQuestion(question)
				break
			end
		end
	end)

	local doneButton = CreateFrame("Button", "ETW_Challenge_SE_DoneButton", frame, "UIPanelButtonTemplate")
	doneButton:SetSize(110, 30)
	doneButton:SetPoint("RIGHT", 0, 7)
	doneButton:SetText("Done")
	doneButton:Disable()
	doneButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeWindow:Hide()
		end
	end)

	frame.questionButton = questionButton
	frame.doneButton = doneButton

end
















----------------------------------------------------------------------------------
--       Multiplayer challenge, Team Exploration
----------------------------------------------------------------------------------


local ET_Data =
{
	youAreLeader = false, -- Leader only
	players =
	{
	}, -- Leader only

	leaderName = "", -- Player only
	leaderRealm = "", -- Player only
	timeAdd = 0,
	isActive = false, -- If setup/challenge is ongoing
}

function ET_Data:Reset()
	self.players = {}
	self.players[1] = nil
	self.players[2] = nil
	self.players[3] = nil
	self.players[4] = nil
	self.players[5] = nil
	self.youAreLeader = false
	self.leaderName = nil
	self.timeAdd = 0
	self.isActive = false
end

ET_Data:Reset()

do 
	local function initFunction()
		if(IsInGroup()) then
			StaticPopup_Show ("ETW_StartChallenge_TeamExploration")
		else
			ETW_Utility:PrintErrorToChat(" You need to be in a party!")
		end
	end

	ETW_ChallengeFrame:CreateData(
		"TE",
		"Multiplayer",
		ETW_CHALLENGE_TEAM_EXPLORATION_DESCRIPTION,
		initFunction)

	local challenge = createChallengeButton("Team Exploration", "Interface\\ICONS\\Ability_Mage_StudentOfTheMind.blp")
	challenge:SetPoint("BOTTOM", 0, 5)
	challenge.button:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame:ShowData("TE")
		end
	end)

	StaticPopupDialogs["ETW_StartChallenge_TeamExploration"] = {
		text = "Pressing \"Setup\" will not start the challenge, it will take you to the setup stage.",
		showAlert = true,
		button1 = "Setup",
		button2 = "Cancel",
		OnAccept = function()
			ETW_ChallengeFrame:ShowData("Main")

			ETW_ChallengeWindow:ShowChallengeFrame("TE")
			ETW_ChallengeWindow.frames["TE"]:ShowLeaderFrame()

			ETW_ChallengeWindow.subTitle:SetText("Team setup")
		end,
		OnCancel = function (_,reason)
		end,
		sound = "GAMEDIALOGOPEN",
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}

end

----------------------------------------------------------------------------------
--       Multiplayer challenge info page, Team Exploration
----------------------------------------------------------------------------------

do 
	local function resetData()
		ET_Data:Reset()
		challengeQuestions = {}
		ETW_ChallengeWindow.activeChallenge = false
		ETW_ForceUpdate()
	end

	-- Starting challenge
	local function onShowFunction(self)
		ETW_ChallengeWindow.timeBar:SetValue(0)
		ETW_ChallengeWindow.timeBar.text:SetText("")
		self.goalStatusFrame.bar:SetValue(0)
		self.goalStatusFrame.bar.text:SetText("")
	end

	-- Completing challenge question
	local function onAnswerFunction(self, question)

		-- Leader will broadcast data to all players
		if(ET_Data.youAreLeader) then

			-- Goal question completed
			if(question.goalQuestion) then
				self.goalStatusFrame.bar:SetValue(self.goalStatusFrame.bar:GetValue() + 1)

				challengeQuestions[2] = nil
				challengeQuestions[2] = ETW_GenerateChallengeQuestion()
				challengeQuestions[2].goalQuestion = true

			-- Time question completed
			elseif(question.timeQuestion) then
				ETW_ChallengeWindow.startedTime = ETW_ChallengeWindow.startedTime + ET_Data.timeAdd

				challengeQuestions[1] = nil
				challengeQuestions[1] = ETW_GenerateChallengeQuestion()
				challengeQuestions[1].timeQuestion = true

				-- Adding more time than the max fails the challenge
				local timeLeft = time() - ETW_ChallengeWindow.startedTime
				if(timeLeft < 0) then

					-- Just remove all timeleft
					ETW_ChallengeWindow.startedTime = time() - ETW_CHALLENGE_TEAM_EXPLORATION_TIME
				end
			end

			self:BroadcastData()

		-- Players will send score update to leader
		else

			local messageType = ""

			if(question.goalQuestion) then
				question.goalQuestion = nil
				messageType = ETW_ADDONMSG_TE_GIVE_SCORE

				challengeQuestions[2] = nil
				challengeQuestions[2] = ETW_GenerateChallengeQuestion()
				challengeQuestions[2].goalQuestion = true

			elseif(question.timeQuestion) then
				question.timeQuestion = nil
				messageType = ETW_ADDONMSG_TE_GIVE_TIME

				challengeQuestions[1] = nil
				challengeQuestions[1] = ETW_GenerateChallengeQuestion()
				challengeQuestions[1].timeQuestion = true
			end

			-- Send leader score/time update
			if(messageType == ETW_ADDONMSG_TE_GIVE_SCORE or messageType == ETW_ADDONMSG_TE_GIVE_TIME) then
				SendAddonMessage(ETW_ADDONMSG_PREFIX,
					messageType,
				"WHISPER",
				ET_Data.leaderName)
			end
		end

		ETW_ForceUpdate()
	end

	-- Failing challenge, time expires
	local function onExpireFunction(self)
		removeChallengePoints(2)
		self:StopChallenge()
	end

	local frame = ETW_ChallengeWindow:CreateChallengeFrame(
		"TE",
		"Team Exploration",
		"Woop",
		300, 200, ETW_CHALLENGE_TEAM_EXPLORATION_TIME,
		onShowFunction,
		onAnswerFunction,
		onExpireFunction)

	local goalStatusFrame = ETW_Templates:CreateStatusBar(
		"ETW_ChallengeCooldown",
		frame,
		1, 100, {0,0,0.8}, ETW_ChallengeWindow:GetWidth()-40, 24)
	goalStatusFrame:SetPoint("TOP",0,10)
	frame.goalStatusFrame = goalStatusFrame


	function frame:BroadcastData()
		if(ET_Data.youAreLeader) then
			-- Broadcast to party that we're starting
			for index = 2, GetNumGroupMembers(), 1 do
				if(ET_Data.players[index] ~= nil) then
					SendAddonMessage(ETW_ADDONMSG_PREFIX,
						ETW_ADDONMSG_TE_DATA..","..
						ETW_ChallengeWindow.startedTime..","..
						self.goalStatusFrame.bar:GetValue(),
					"WHISPER",
					ET_Data.players[index])
				end
			end

			local min, max = self.goalStatusFrame.bar:GetMinMaxValues()
			self.goalStatusFrame.bar.text:SetText(self.goalStatusFrame.bar:GetValue() .. " / " .. max)

			-- Challenge completed
			if(self.goalStatusFrame.bar:GetValue() >= max) then
				self:CompleteChallenge()
			end
		end
	end

	function frame:CompleteChallenge()
		local secondsPassed = time() - ETW_ChallengeWindow.startedTime

		local timeleft = ETW_CHALLENGE_TEAM_EXPLORATION_TIME - secondsPassed
		local minutes = math.floor(timeleft/60)

		if(minutes >= 4) then
			addChallengePoints(3)
		elseif(minutes >= 3) then
			addChallengePoints(1)
		end

		resetData()
		self.goalButton:Disable()
		self.timeButton:Disable()
		self.doneButton:Enable()
	end

	function frame:StopChallenge()
		resetData()
		self.goalButton:Disable()
		self.timeButton:Disable()
		self.doneButton:Enable()
	end

	-- Setup data
	----------------------------------------------------------------------------------------------

	function frame:ShowLeaderFrame()
		frame.startButton:Show()
		frame.inviteButton:Show()
		frame.backButton:Show()

		frame.doneButton:Hide()
		frame.goalButton:Hide()
		frame.timeButton:Hide()
		frame.timeText:SetText("")
	end

	function frame:ShowChallengeFrame()
		frame.startButton:Hide()
		frame.inviteButton:Hide()
		frame.backButton:Hide()

		frame.doneButton:Show()
		frame.doneButton:Disable()
		frame.goalButton:Show()
		frame.timeButton:Show()
		frame.goalButton:Enable()
		frame.timeButton:Enable()
	end

	function frame:UpdateTimeText()
		local minutes = math.floor(ET_Data.timeAdd/60)
		local seconds = ET_Data.timeAdd % 60

		self.timeText:SetText("Time additions are: " .. minutes .."m " .. seconds .. "s")
	end

	local function startTE()
		PlaySound("ReadyCheck")

		ETW_ChallengeFrame:ShowData("Main")
		ETW_ChallengeWindow:ShowChallengeFrame("TE")
		ETW_ChallengeWindow.subTitle:SetText("Good luck " .. UnitName("player"))
		SymphonymConfig.challengeCooldownStarted = time()

		-- Grab questions for the challenge
		challengeQuestions = {}
		challengeQuestions[1] = ETW_GenerateChallengeQuestion()
		challengeQuestions[1].timeQuestion = true
		challengeQuestions[2] = ETW_GenerateChallengeQuestion()
		challengeQuestions[2].goalQuestion = true 
		ETW_ForceUpdate()

		ETW_ChallengeWindow.activeChallenge = true
		ETW_ChallengeWindow.startedTime = time()

		if(ET_Data.youAreLeader) then


			-- Get player count
			local count = 0
			for index = 2, GetNumGroupMembers(), 1 do
				if(ET_Data.players[index] ~= nil) then
					count = count + 1
				end
			end
			frame.goalStatusFrame.bar:SetMinMaxValues(0, count*ETW_CHALLENGE_TEAM_EXPLORATION_WIN_LIMIT_MULTIPLIER)


			ET_Data.timeAdd = 120 - 20*count
			frame:UpdateTimeText()

			-- Broadcast to party that we're starting
			for index = 2, GetNumGroupMembers(), 1 do
				if(ET_Data.players[index] ~= nil) then
					SendAddonMessage(ETW_ADDONMSG_PREFIX,
						ETW_ADDONMSG_TE_START..","..
						ET_Data.timeAdd..","..
						count*ETW_CHALLENGE_TEAM_EXPLORATION_WIN_LIMIT_MULTIPLIER,
					"WHISPER",
					ET_Data.players[index])
				end
			end
		end

		frame.inviteText:SetText("")
		frame.goalStatusFrame.bar:SetValue(0)
		local min, max = frame.goalStatusFrame.bar:GetMinMaxValues()
		frame.goalStatusFrame.bar.text:SetText(frame.goalStatusFrame.bar:GetValue() .. " / " .. max)

		frame:ShowChallengeFrame()
	end

	StaticPopupDialogs["ETW_StartChallenge_StartTeamExploration"] = {
		text = "Pressing \"Start\" will start the challenge and reset the challenge cooldown of all participants. It might be clever to throw out an invite again to make sure everyone is with you.",
		showAlert = true,
		button1 = "Start",
		button2 = "Cancel",
		OnAccept = function()

			local count = 0
			for index = 2, GetNumGroupMembers(), 1 do
				if(ET_Data.players[index] ~= nil) then
					count = count + 1
				end
			end

			if(count >= 1) then
				startTE()
			else
				ETW_Utility:PrintErrorToChat("Team Exploration requires 2-5 players")
			end
		end,
		OnCancel = function (_,reason)
		end,
		sound = "GAMEDIALOGOPEN",
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}

	local inviteText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	inviteText:SetPoint("LEFT", 10, -8)
	inviteText:SetText("Connected players\n\n")
	frame.inviteText = inviteText

	local timeText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	timeText:SetPoint("LEFT", 2, 20)
	frame.timeText = timeText

	local function updatePlayerList()
		local textString = "Connected players\n\n"
		for index = 2, GetNumGroupMembers(), 1 do

			if(ET_Data.players[index] ~= nil) then
				textString = textString .. ET_Data.players[index] .. "\n"
			end
		end
		inviteText:SetText(textString)
	end

	local startButton = CreateFrame("Button", "ETW_Challenge_TE_StartButton", frame, "UIPanelButtonTemplate")
	startButton:SetSize(110, 22)
	startButton:SetPoint("BOTTOMRIGHT", 0, 50)
	startButton:SetText("Start")
	startButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			if not (ET_Data.isActive) then
				ETW_Utility:PrintErrorToChat(" You can't play without team mates!")
			elseif(ET_Data.isActive and not ET_Data.youAreLeader) then
				ETW_Utility:PrintErrorToChat(" You're already signed for a Team Exploration challenge!")
			else
				StaticPopup_Show("ETW_StartChallenge_StartTeamExploration")
			end
		end
	end)

	local inviteButton = CreateFrame("Button", "ETW_Challenge_TE_InviteButton", frame, "UIPanelButtonTemplate")
	inviteButton:SetSize(110, 22)
	inviteButton:SetPoint("BOTTOMRIGHT", 0, 26)
	inviteButton:SetText("Invite")
	inviteButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			if(ETW_ChallengeWindow.activeChallenge) then
				ETW_Utility:PrintErrorToChat( "You're already part of an ongoing Team Exploration!")
			else
				ET_Data:Reset()
				ET_Data.players[1] = UnitName("player")
				ET_Data.youAreLeader = true

				-- Reset all players
				for index = 2, GetNumGroupMembers(), 1 do
					ET_Data.players[index] = nil
				end

				updatePlayerList()

				-- Broadcast to party, trying to find a 
				SendAddonMessage(ETW_ADDONMSG_PREFIX,
					ETW_ADDONMSG_TE_INVITE,
				"PARTY")
			end
		end
	end)

	local backButton = CreateFrame("Button", "ETW_Challenge_TE_BackButton", frame, "UIPanelButtonTemplate")
	backButton:SetSize(50, 20)
	backButton:SetPoint("BOTTOMRIGHT", 0, 2)
	backButton:SetText("Back")
	backButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeWindow:Hide()
		end
	end)



	frame.startButton = startButton
	frame.inviteButton = inviteButton
	frame.backButton = backButton

	local doneButton = CreateFrame("Button", "ETW_Challenge_TE_DoneButton", frame, "UIPanelButtonTemplate")
	doneButton:SetSize(110, 22)
	doneButton:SetPoint("BOTTOM", 0, 2)
	doneButton:SetText("Done")
	doneButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeWindow:Hide()
		end
	end)

	frame.doneButton = doneButton

	-- Challenge frame
	---------------------------------------------------------------------------------
	local function createQuestionButton(index)
		local questionButton = CreateFrame("Button", "ETW_Challenge_TE_QuestionButton"..index, frame, "UIPanelButtonTemplate")
		questionButton:SetSize(30, 25)
		questionButton:SetText("Q" .. index)
		questionButton:HookScript("OnClick", function(self,button,down)
			if(button == "LeftButton" and not down) then
				ETW_DisplayQuestion(challengeQuestions[index])
			end
		end)

		return questionButton 
	end

	local timeButton = CreateFrame("Button", "ETW_Challenge_TE_TimeQuestionButton", frame, "UIPanelButtonTemplate")
	timeButton:SetSize(130, 30)
	timeButton:SetPoint("LEFT")
	timeButton:SetText("Time question")
	timeButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_DisplayQuestion(challengeQuestions[1])
		end
	end)
	timeButton:Hide()

	local goalButton = CreateFrame("Button", "ETW_Challenge_TE_GoalButton", frame, "UIPanelButtonTemplate")
	goalButton:SetSize(130, 30)
	goalButton:SetPoint("RIGHT")
	goalButton:SetText("Challenge question")
	goalButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_DisplayQuestion(challengeQuestions[2])
		end
	end)
	goalButton:Hide()

	frame.timeButton = timeButton
	frame.goalButton = goalButton


	-- Client communication
	-------------------------------------------------------------------------------------------


	frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:SetScript("OnEvent", function(self, event, ...)

		if(event == "CHAT_MSG_ADDON" and ETW_IsChallengeReady()) then
			local prefix, sentMessage, channel, sender = ...

			local messageList = ETW_Utility:SplitString(sentMessage, ",")
			local messageCount = #(messageList)

			if(prefix == ETW_ADDONMSG_PREFIX and sender ~= UnitName("player") and UnitInParty(sender)) then

				-- You received an Team Exploration invite
				if(messageCount == 1 and messageList[1] == ETW_ADDONMSG_TE_INVITE) then

					StaticPopupDialogs["ETW_Challenge_TE_Invite"] = {
						text = "%s has invited you to a Team Exploration challenge, do you wish to join? They may then be able to start the challenge at any time, which will reset your challenge cooldown.",
						button1 = "Yes",
						button2 = "No",
						OnAccept = function()
							-- Reset data
							ET_Data:Reset()
							ET_Data.leaderName = sender

							ET_Data.isActive = true

							updatePlayerList()

							-- Notify leader that we want to join
							SendAddonMessage(ETW_ADDONMSG_PREFIX,
								ETW_ADDONMSG_TE_ACCEPT_INVITE,
							"WHISPER",
							sender)
						end,
						OnCancel = function (_,reason)
						end,
						sound = "GAMEDIALOGOPEN",
						timeout = 30,
						whileDead = true,
						hideOnEscape = true,
					}

					StaticPopup_Show("ETW_Challenge_TE_Invite", sender)

				-- Someone accepted our invites
				elseif(messageCount == 1 and messageList[1] == ETW_ADDONMSG_TE_ACCEPT_INVITE and ET_Data.youAreLeader
					and ETW_ChallengeWindow.activeChallenge == false) then

					ET_Data.isActive = true

					-- Add them to connected players
					local index = 2
					for index = 2, GetNumGroupMembers() do
						if(ET_Data.players[index] == nil) then
							ET_Data.players[index] = sender
							break
						end
						index = index + 1
					end

					updatePlayerList()

				-- Leader sent start command
				elseif(messageCount == 3 and messageList[1] == ETW_ADDONMSG_TE_START and not ET_Data.youAreLeader and
					ET_Data.leaderName == sender and ET_Data.isActive == true and ETW_ChallengeWindow.activeChallenge == false) then

					local timeAdd = tonumber(messageList[2])
					local winLimit = tonumber(messageList[3])

					if(timeAdd and winLimit) then
						ET_Data.timeAdd = timeAdd
						self:UpdateTimeText()
						self.goalStatusFrame.bar:SetMinMaxValues(0, winLimit)
						startTE()
					end

				-- Player receiving data from leader
				elseif(messageCount == 3 and messageList[1] == ETW_ADDONMSG_TE_DATA and not ET_Data.youAreLeader and
					ET_Data.leaderName == sender and ET_Data.isActive == true) then
					local timeStarted = tonumber(messageList[2])
					local goalScore = tonumber(messageList[3])

					if(timeStarted and goalScore) then
						local min, max = self.goalStatusFrame.bar:GetMinMaxValues()

						ETW_ChallengeWindow.startedTime = timeStarted
						self.goalStatusFrame.bar:SetValue(goalScore)
						self.goalStatusFrame.bar.text:SetText(goalScore .. " / " .. max)

						-- Challenge completed
						local min, max = self.goalStatusFrame.bar:GetMinMaxValues()
						if(self.goalStatusFrame.bar:GetValue() >= max) then
							self:CompleteChallenge()
						end
					end
				

				-- Leader receiving TIME data
				elseif(messageCount == 1 and messageList[1] == ETW_ADDONMSG_TE_GIVE_TIME and ET_Data.youAreLeader
					and ET_Data.isActive == true) then

					local playerInGame = false
					for _, player in pairs(ET_Data.players) do
						if(player == sender) then playerInGame = true break end
					end

					if(playerInGame) then
						ETW_ChallengeWindow.startedTime = ETW_ChallengeWindow.startedTime + ET_Data.timeAdd
						self:BroadcastData()
					end

				-- Leader receiving SCORE data
				elseif(messageCount == 1 and messageList[1] == ETW_ADDONMSG_TE_GIVE_SCORE and ET_Data.youAreLeader
					and ET_Data.isActive == true) then

					local playerInGame = false
					for _, player in pairs(ET_Data.players) do
						if(player == sender) then
							playerInGame = true
							break
						end
					end

					if(playerInGame) then
						self.goalStatusFrame.bar:SetValue(self.goalStatusFrame.bar:GetValue() + 1)
						self:BroadcastData()
					end
				end
			end

		end
	end)

end










----------------------------------------------------------------------------------
--       Global functions
----------------------------------------------------------------------------------

-- If the challenge cooldown has passed or not
function ETW_IsChallengeReady()
	local startedTime = SymphonymConfig.challengeCooldownStarted
	local secondsPassed = time() - startedTime -- Time since cooldown started

	return secondsPassed >= ETW_CHALLENGE_COOLDOWN
end

-- If the specified questions is part of a challenge
function ETW_IsChallengeQuestion(question)

	for _, challengeQuestion in pairs(challengeQuestions) do
		if(challengeQuestion.ID == question.ID) then
			return true
		end
	end
	return false
end

-- Handling completed questions
function ETW_ChallengeQuestionCompleted(question)

	-- Run handler for when you answer a challenge question
	if(ETW_IsChallengeQuestion(question)) then
		local subframe = ETW_ChallengeWindow.frames[ETW_ChallengeWindow.activeSubFrame]

		challengeQuestions[question.ID] = nil
		subframe.onAnswerFunction(subframe, question)
	end

end