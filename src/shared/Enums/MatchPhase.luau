--!strict

local MatchPhase = {
	WaitingForPlayers = "WaitingForPlayers",
	BuyPhase = "BuyPhase",
	LiveRound = "LiveRound",
	SideSwap = "SideSwap",
	PostRound = "PostRound",
	MatchComplete = "MatchComplete",
}

return table.freeze(MatchPhase)
