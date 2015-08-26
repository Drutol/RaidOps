local DKP = Apollo.GetAddon("RaidOps")
--[[
replace "EXPORT_STRING_HERE_JUST_REPLACE_THIS_PLACEHOLDER" with the string downloaded from website

do /reloadui , go to export window , press button on the left and the string has been copied to the addon

How this file looks by default:
local DKP = Apollo.GetAddon("RaidOps")

function DKP:GetExportStringFromFile()
	return [===[EXPORT_STRING_HERE_JUST_REPLACE_THIS_PLACEHOLDER]===]
end
]]
function DKP:GetExportStringFromFile()
	return [===[EXPORT_STRING_HERE_JUST_REPLACE_THIS_PLACEHOLDER]===]
end