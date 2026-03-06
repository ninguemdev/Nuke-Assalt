--!strict

export type TeamSide = "Attackers" | "Defenders" | "Both"
export type InventorySlot = "PrimaryWeapon" | "SecondaryWeapon" | "Utility" | "SpecialEquipment" | "DefuseKit" | "Armor"

export type MatchConfig = {
	id: string,
	name: string,
	format: {
		roundsToWin: number,
		swapAfterRounds: number,
		minimumPlayersToStart: number,
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

export type MapVector3 = {
	x: number,
	y: number,
	z: number,
}

export type MapColor3 = {
	r: number,
	g: number,
	b: number,
}

export type MapSpawnDefinition = {
	id: string,
	name: string,
	team: string,
	position: MapVector3,
}

export type MapCalloutDefinition = {
	id: string,
	name: string,
	position: MapVector3,
}

export type MapRouteDefinition = {
	id: string,
	name: string,
	fromCalloutId: string,
	toCalloutId: string,
	siteId: string,
}

export type MapPlantZoneDefinition = {
	id: string,
	name: string,
	position: MapVector3,
	size: MapVector3,
}

export type MapBombsiteDefinition = {
	id: string,
	name: string,
	calloutIds: { string },
	entryRouteIds: { string },
	plantZones: { MapPlantZoneDefinition },
}

export type MapAnchorPointDefinition = {
	id: string,
	name: string,
	anchorType: string,
	siteId: string,
	calloutId: string,
	position: MapVector3,
	insidePlantZone: boolean,
}

export type MapGeometryDefinition = {
	id: string,
	name: string,
	position: MapVector3,
	size: MapVector3,
	color: MapColor3,
	material: string,
	transparency: number,
	canCollide: boolean,
}

export type MapConfig = {
	id: string,
	name: string,
	theme: string,
	workspaceModelName: string,
	spawns: { MapSpawnDefinition },
	callouts: { MapCalloutDefinition },
	routes: { MapRouteDefinition },
	bombsites: { MapBombsiteDefinition },
	anchorPoints: { MapAnchorPointDefinition },
	geometry: { MapGeometryDefinition },
}

export type CombatConfig = {
	id: string,
	name: string,
	health: {
		maxHealth: number,
		allowFriendlyFire: boolean,
	},
	hitZones: {
		defaultZone: string,
		aliases: {
			head: { string },
			torso: { string },
			arms: { string },
			legs: { string },
		},
		multipliers: {
			head: number,
			torso: number,
			arms: number,
			legs: number,
		},
	},
	movement: {
		walkSpeed: number,
		sprintSpeed: number,
		crouchSpeed: number,
		jumpPower: number,
		crouchCameraOffsetY: number,
		firstPersonMinZoom: number,
		firstPersonMaxZoom: number,
		moveAccuracyMultiplier: number,
		sprintAccuracyMultiplier: number,
		crouchAccuracyMultiplier: number,
		jumpAccuracyMultiplier: number,
	},
	avatar: {
		expectedRigType: string,
		loadCharacterAppearance: boolean,
		stripAccessories: boolean,
		stripCharacterMeshes: boolean,
		showLocalBodyInFirstPerson: boolean,
		showOnlyArmsInFirstPerson: boolean,
		hideHeadInFirstPerson: boolean,
		preserveAppearanceFields: { string },
		studioFallbackAppearance: {
			mode: string,
			face: number,
			shirt: number,
			pants: number,
			graphicTShirt: number,
			bodyColors: {
				head: MapColor3,
				torso: MapColor3,
				leftArm: MapColor3,
				rightArm: MapColor3,
				leftLeg: MapColor3,
				rightLeg: MapColor3,
			},
		},
	},
	animation: {
		profileId: string,
		blendTimeSeconds: number,
		walkTrackSpeed: number,
		runTrackSpeed: number,
		crouchTrackSpeed: number,
		tracks: {
			idle: number,
			walk: number,
			run: number,
			jump: number,
			fall: number,
			crouch: number,
		},
	},
	debug: {
		enableDebugDamageRemote: boolean,
		defaultDamage: number,
	},
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
