--!strict

local RoundPhase = {
	Waiting = "Waiting",
	Buy = "Buy",
	Live = "Live",
	PostPlant = "PostPlant",
	Resolution = "Resolution",
	Complete = "Complete",
}

return table.freeze(RoundPhase)
