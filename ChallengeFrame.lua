
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
	button:Disable()

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

	function challenge:ShowFrame()
		-- Make sure challenges are disabled by default and then let OnUpdate regulate it
		for index = 1, challengeFrameCount, 1 do
			_G["ETW_ChallengeButton"..index]:Disable()
		end
		self:Show()
	end

	function challenge:CreateData(name, title, text, startFunction)
		self.frames[name] = {}
		self.frames[name].title = title
		self.frames[name].text = text
		self.frames[name].startFunction = startFunction
		return self.frames[name]
	end

	function challenge:ShowData(name)

		if(name == "Main") then
			for index = 1, challengeFrameCount, 1 do
				_G["ETW_ChallengeFrame"..index]:Show()
			end
		else
			for index = 1, challengeFrameCount, 1 do
				_G["ETW_ChallengeFrame"..index]:Hide()
			end
		end

		self.startFunction = self.frames[name].startFunction
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


	local backButton = CreateFrame("Button", "ETW_ChallengeStartButton", ETW_ChallengeFrame, "UIPanelButtonTemplate")
	backButton:SetSize(160, 40)
	backButton:SetPoint("BOTTOM", 0, 5)
	backButton:SetText("Back")
	backButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame:ShowData("Main")
		end
	end)


	local startButton = CreateFrame("Button", "ETW_ChallengeBackButton", ETW_ChallengeFrame, "UIPanelButtonTemplate")
	startButton:SetSize(160, 40)
	startButton:SetPoint("BOTTOM", 0, 45)
	startButton:SetText("Start the challenge")
	startButton:HookScript("OnClick", function(self,button,down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame.startFunction()
		end
	end)

	challenge.backButton = backButton
	challenge.startButton = startButton


	challenge:ShowData("Main")
end

----------------------------------------------------------------------------------
--       Challenge cooldown bar
----------------------------------------------------------------------------------

local function addChallengePoints(points)
	for count = 1, points, 1 do

		SymphonymConfig.challengePoints = SymphonymConfig.challengePoints + 1

		if(SymphonymConfig.challengePoints >= ETW_CHALLENGE_POINTS_REQUIRED) then
			ETW_GrantChallengeReward()
			SymphonymConfig.challengePoints = 0
		end

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

			-- Only enable challenges when we're done with the current
			if not(ETW_ChallengeWindow.activeChallenge) then
				for index = 1, challengeFrameCount, 1 do
					_G["ETW_ChallengeButton"..index]:Enable()
				end
			end

		-- Cooldown still active, challenges not ready
		else
			-- Time left, the power of modulo
			local hours = math.floor(timeleft/3600)
			local minutes = math.floor((timeleft%3600)/60)
			local seconds = math.floor(timeleft%60)

			self.text:SetText(hours.."h "..minutes.."m "..seconds.."s")
			self:SetValue(maxValue*percentagePassed)


			for index = 1, challengeFrameCount, 1 do
				_G["ETW_ChallengeButton"..index]:Disable()
			end
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
	challenge:SetPoint("CENTER")
	challenge:SetSize(300, 150)
	ETW_Templates:MakeFrameDraggable(challenge, true)
	--challenge:Hide()

	challenge.title = challenge:CreateFontString(nil, "ARTWORK", "PVPInfoTextFont")
	challenge.title:SetText("Swift exploring")
	challenge.title:SetPoint("TOP", 0, -10)

	challenge.subTitle = challenge:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	challenge.subTitle:SetTextHeight(14)
	challenge.subTitle:SetText("A good question[1337]")
	challenge.subTitle:SetPoint("TOP", 0, -37)

	challenge.frames = {}
	challenge.startedTime = time()
	challenge.activeChallenge = false

	function challenge:CreateChallengeFrame(name, title, subTitle, width, height, timeLimit, startFunction, answerQuestionFunction, expireFunction)
		local frame = CreateFrame("Frame", nil, self)
		frame:SetSize(self:GetWidth()-40, self:GetHeight()-100)
		frame:SetPoint("BOTTOM", 0, 10)
		frame.title = title
		frame.subTitle = subTitle
		frame.customWidth = width
		frame.customHeight = height
		frame.timeLimit = timeLimit
		frame.expireFunction = expireFunction
		frame.answerQuestionFunction = answerQuestionFunction
		frame.startFunction = startFunction
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
		self.frames[name]:Show()
		self:SetSize(self.frames[name].customWidth, self.frames[name].customHeight)
		self.title:SetText(self.frames[name].title)
		self.subTitle:SetText(self.frames[name].subTitle)
		self.frames[name].startFunction(self.frames[name])
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
				ETW_ChallengeWindow.frames[ETW_ChallengeWindow.activeSubFrame].expireFunction(ETW_ChallengeWindow.frames[ETW_ChallengeWindow.activeSubFrame])

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
end













----------------------------------------------------------------------------------
--       Multiplayer challenge, Explorer's Tournament
----------------------------------------------------------------------------------

do 
	local function startFunction()
		print("HERRO")
	end

	ETW_ChallengeFrame:CreateData(
		"Explorers Tournament",
		"Multiplayer",
		"Not implemented, attemping to start the challenge will probably just waste your cooldown on nothing",
		startFunction)

	local challenge = createChallengeButton("Explorer's Tournament", "Interface\\ICONS\\Ability_Mage_StudentOfTheMind.blp")
	challenge:SetPoint("BOTTOM", 0, 5)
	challenge.button:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame:ShowData("Explorers Tournament")
		end
	end)

	StaticPopupDialogs["ETW_StartChallenge_ExplorersTournament"] = {
		text = "As soon as you press \"Start\" the challenge will start and the cooldown will reset",
		showAlert = true,
		button1 = "Start",
		button2 = "Cancel",
		OnAccept = function()
			SymphonymConfig.challengeCooldownStarted = time()
			ETW_ChallengeFrame:ShowData("Main")
			ETW_ChallengeFrame:Hide()
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
--       Single player challenge, Swift exploration
----------------------------------------------------------------------------------

do 
	local function startFunction()
		StaticPopup_Show ("ETW_StartChallenge_SwiftExploring")
	end

	ETW_ChallengeFrame:CreateData(
		"Swift exploring",
		"Single player",
		ETW_CHALLENGE_SWIFT_EXPLORING_DESCRIPTION,
		startFunction)

	local challenge = createChallengeButton("Swift exploring", "Interface\\ICONS\\Rogue_BurstofSpeed.blp")
	challenge:SetPoint("BOTTOM", 0, 47)
	challenge.button:SetScript("PostClick", function(self, button, down)
		if(button == "LeftButton" and not down) then
			ETW_ChallengeFrame:ShowData("Swift exploring")
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
	local function startFunction(self)
		self.doneButton:Disable()
		self.questionButton:Enable()
	end

	-- Completing challenge
	local function completeFunction(self)
		resetData(self)
		addChallengePoints(2)
	end

	-- Failing challenge, time expires
	local function expireFunction(self)
		resetData(self)
	end

	local frame = ETW_ChallengeWindow:CreateChallengeFrame(
		"SE",
		"Swift exploring",
		"Woop",
		300, 115, 15,
		startFunction,
		completeFunction,
		expireFunction)

	local questionButton = CreateFrame("Button", "ETW_Challenge_SE_DisplayButton", frame, "UIPanelButtonTemplate")
	questionButton:SetSize(110, 30)
	questionButton:SetPoint("LEFT", 0, -15)
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
	doneButton:SetPoint("RIGHT", 0, -15)
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
		subframe.answerQuestionFunction(subframe)
	end

end