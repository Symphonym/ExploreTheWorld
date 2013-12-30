

local ETW_LoreRanks = 
{
	{
		minimumPercentage = 0,
		rank = "Quest Observer"
	},
	{
		minimumPercentage = 20,
		rank = "Mediocre Guy To ask With Lore Questions"
	},
	{
		minimumPercentage = 30,
		rank = "Quest Completer"
	},
	{
		minimumPercentage = 50,
		rank = "Mediocre Guy To ask With Lore Questions"
	},
	{
		minimumPercentage = 90,
		rank = "Red Shirt Guy"
	}

}

function ETW_GetLoreRank(percentageDone)
	local lastRank = nil
	for _, rank in pairs(ETW_LoreRanks) do
		if(lastRank == nil) then
			lastRank = rank
		elseif(rank.minimumPercentage < percentageDone  and rank.minimumPercentage > lastRank.minimumPercentage) then
			lastRank = rank
		end
	end

	return lastRank.rank
end