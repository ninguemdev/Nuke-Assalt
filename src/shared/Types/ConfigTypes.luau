--!strict

export type TeamSide = "Attackers" | "Defenders" | "Both"
export type InventorySlot = "PrimaryWeapon" | "SecondaryWeapon" | "Utility" | "SpecialEquipment" | "DefuseKit" | "Armor"

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
	slot: InventorySlot,
	team: TeamSide,
	cost: number,
	economyClass: string,
	maxPerLoadout: number?,
}

export type CatalogConfig = {
	id: string,
	name: string,
	loadoutRules: {
		maxUtilityTotal: number,
		maxSpecialEquipment: number,
		maxPrimaryWeapons: number,
		maxSecondaryWeapons: number,
		maxArmor: number,
		maxDefuseKits: number,
	},
	weapons: { CatalogItem },
	utilities: { CatalogItem },
	equipment: { CatalogItem },
}

export type RuntimeConfig = {
	id: string,
	name: string,
	featureFlags: {
		publishRuntimeDebugAttributes: boolean,
		createNetworkRemotesOnBoot: boolean,
		enforceServiceContracts: boolean,
	},
	tuning: {
		shop: {
			allowPurchaseOnlyDuringBuyPhase: boolean,
			allowDropActions: boolean,
			allowSellback: boolean,
		},
		network: {
			replicateStateSnapshots: boolean,
			publishContractVersionAttributes: boolean,
		},
		debug: {
			publishConfigAttributes: boolean,
			logBootstrapSummary: boolean,
		},
	},
}

export type RemoteDefinition = {
	name: string,
	channel: string,
	scope: string,
}

export type NetworkConfig = {
	id: string,
	name: string,
	version: string,
	remoteRootName: string,
	folders: {
		events: string,
		functions: string,
	},
	events: { RemoteDefinition },
	functions: { RemoteDefinition },
}

return nil
