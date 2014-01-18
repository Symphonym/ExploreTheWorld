--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--       Inspect frame extras
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

ETW_InspectFrame = {}

do
	local inspectFrame = CreateFrame("Frame", nil, UIParent)
	inspectFrame:RegisterEvent("INSPECT_READY")
	inspectFrame:RegisterEvent("CHAT_MSG_ADDON")
	inspectFrame:SetScript("OnEvent", function(self, event, ...)
		if(event == "INSPECT_READY") then

			if(ETW_InspectFrame.container == nil) then
				local frame = CreateFrame("Frame", "ETW_InspectFrame", InspectPaperDollFrame, "InsetFrameTemplate3")
				frame:SetWidth(230);
				frame:SetHeight(22);
				frame:SetPoint("TOP", 0, -38)

				frame.text = frame:CreateFontString("ETW_InspectFrameText", "ARTWORK", "GameFontNormalSmall")
				frame.text:SetPoint("CENTER")

				frame:SetScript("OnEnter", function(self, motion)
					self:UpdateTooltip()
				end)
				frame:SetScript("OnLeave", function(self, motion)
					GameTooltip:FadeOut()
				end)

				function frame:UpdateSize()
					self:SetWidth(self.text:GetStringWidth()+16)
				end
				function frame:UpdateTooltip()

					GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
					GameTooltip:AddLine("|cFF00FF00Explore the World")

					if(self.playerRank == nil or self.playerCompleted == nil or self.playerTotal == nil or self.playerVersion == nil) then
						GameTooltip:AddLine("No data received")
					else
						GameTooltip:AddLine("Rank: "..ETW_Utility:RGBToStringColor(0.6, (self.playerCompleted / self.playerTotal), 0)..self.playerRank)
						GameTooltip:AddLine("Completed quests: |cFF00FF00"..self.playerCompleted)
						GameTooltip:AddLine("Total quests: |cFF00FF00"..self.playerTotal)
						GameTooltip:AddLine("Using version: |cFF00FF00"..self.playerVersion)
					end

					GameTooltip:Show()
				end

				ETW_InspectFrame.container = frame
			end

			-- Save received data for tooltip
			ETW_InspectFrame.container.playerRank = nil
			ETW_InspectFrame.container.playerCompleted = nil
			ETW_InspectFrame.container.playerTotal = nil
			ETW_InspectFrame.container.playerVersion = nil

			ETW_InspectFrame.container.text:SetText(ETW_Utility:RGBToStringColor(0.6, 0, 0) .. " Unknown |r(??/??)")
			ETW_InspectFrame.container:UpdateSize()

			local targetName, targetRealm = UnitName("target")
			if(targetRealm == nil) then
				targetRealm = GetRealmName()
			end

			-- Request inspect data from the player
			SendAddonMessage(ETW_ADDONMSG_PREFIX,
				ETW_ADDONMSG_INSPECT_REQUEST..","..
				UnitName("player")..","..
				GetRealmName(),
			"WHISPER",
			targetName.."-"..targetRealm)

		elseif(event == "CHAT_MSG_ADDON") then
			local prefix, sentMessage, channel, sender = ...

			local messageList = ETW_Utility:SplitString(sentMessage, ",")
			local messageCount = #(messageList)

			if(prefix == ETW_ADDONMSG_PREFIX) then

				-- Request data
				if(messageCount == 3 and messageList[1] == ETW_ADDONMSG_INSPECT_REQUEST and not SymphonymConfig.options.ignoreLinks) then

					-- Custom name/realm data, don't fully trust the sender variable for CRZ and such
					local senderName = messageList[2]
					local senderRealm = messageList[3]

					-- Reply with data
					SendAddonMessage(ETW_ADDONMSG_PREFIX,
						ETW_ADDONMSG_INSPECT_REPORT..","..
						SymphonymConfig.questions.completed..","..
						ETW_LoreQuestions.size..","..
						GetAddOnMetadata("ExploreTheWorld","Version"),
					"WHISPER",
					senderName.."-"..senderRealm)

				-- Receive data
				elseif(messageCount == 4 and messageList[1] == ETW_ADDONMSG_INSPECT_REPORT) then

					local senderCompleted = tonumber(messageList[2])
					local senderTotalQs = tonumber(messageList[3])
					local senderVersion = messageList[4]

					-- Make sure data is valid
					if(senderCompleted and senderTotalQs) then
						ETW_InspectFrame.container.text:SetText(
							ETW_Utility:RGBToStringColor(0.6, (senderCompleted / senderTotalQs), 0) ..ETW_GetQuestionRank((senderCompleted/senderTotalQs) * 100).."|r ("..senderCompleted.."/"..senderTotalQs..")")
						ETW_InspectFrame.container:UpdateSize()

						-- Save received data for tooltips
						ETW_InspectFrame.container.playerRank = ETW_GetQuestionRank((senderCompleted/senderTotalQs) * 100)
						ETW_InspectFrame.container.playerCompleted = senderCompleted
						ETW_InspectFrame.container.playerTotal = senderTotalQs
						ETW_InspectFrame.container.playerVersion = senderVersion
					end
				end
			end

		end
	end)

	ETW_InspectFrame = inspectFrame

end
