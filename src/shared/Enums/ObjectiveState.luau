--!strict

local ObjectiveState = {
	Idle = "Idle",
	Carrying = "Carrying",
	Dropped = "Dropped",
	Planting = "Planting",
	Planted = "Planted",
	Defusing = "Defusing",
	Defused = "Defused",
	Exploded = "Exploded",
}

return table.freeze(ObjectiveState)
