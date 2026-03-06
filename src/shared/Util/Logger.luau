--!strict

local Logger = {}

local function formatMessage(level: string, scope: string, message: string): string
	return string.format("[NukeAssalt][%s][%s] %s", level, scope, message)
end

function Logger.info(scope: string, message: string)
	print(formatMessage("Info", scope, message))
end

function Logger.warn(scope: string, message: string)
	warn(formatMessage("Warn", scope, message))
end

return table.freeze(Logger)
