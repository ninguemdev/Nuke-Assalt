--!strict

export type TeamSide = "Attackers" | "Defenders" | "Both"

export type MatchConfig = {
	id: string,
	name: string,
	format: {
		roundsToWin: number,
		swapAfterRounds: number,
	},
	timers: {
		buyPhaseSeconds: number,
		roundSeconds: number,
		plantSeconds: number,
		defuseSeconds: number,
		defuseWithKitSeconds: number,
		postPlantSeconds: number,
		roundEndSeconds: number,
	},
}

export type EconomyConfig = {
	id: string,
	name: string,
	startingMoney: number,
	winReward: number,
	lossBonusSequence: { number },
	plantReward: number,
	defuseReward: number,
	killRewards: {
		pistol: number,
		rifle: number,
		smg: number,
		sniper: number,
		utility: number,
	},
}

export type CatalogItem = {
	id: string,
	name: string,
	itemType: string,
	team: TeamSide,
	cost: number,
	maxPerLoadout: number?,
}

export type CatalogConfig = {
	id: string,
	name: string,
	weapons: { CatalogItem },
	utilities: { CatalogItem },
	equipment: { CatalogItem },
}

return nil
