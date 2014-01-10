

local ETW_LoreRanks = 
{
	{
		minimumPercentage = 0,
		rank = "Just got the addon"
	},
	{
		minimumPercentage = 20,
		rank = "Casual is casual"
	},
	{
		minimumPercentage = 30,
		rank = "Not even halfway"
	},
	{
		minimumPercentage = 50,
		rank = "Halfway to greatness"
	},
	{
		minimumPercentage = 75,
		rank = "Not mediocre anymore"
	},
	{
		minimumPercentage = 90,
		rank = "Lorewalking the Lore"
	}

}

function ETW_GetQuestionRank(percentageDone)
	local lastRank = nil
	for _, rank in pairs(ETW_LoreRanks) do
		if(lastRank == nil) then
			lastRank = rank
		elseif(rank.minimumPercentage <= percentageDone  and rank.minimumPercentage > lastRank.minimumPercentage) then
			lastRank = rank
		end
	end

	return lastRank.rank
end