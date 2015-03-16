local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("EasyDKP", "frFR" )
if not L then return end
------------
--Example & Info
------------
--[[
	If you want to translate:
	1. Go to enUS.lua in the same folder , this is where all strings are stored.
	2. You want to translate main window title for example.
	3. Find in enUS.lua appropriate key , in this case    -->  "#wndMain:Title"  <--
	4. Copy whole line that is --> L["#wndMain:Title"] = "RaidOps - DKP/EPGP Management"  <--
	5. Paste in deDE.lua or frFR.lua file
	6. Translate the value , that is --> "RaidOps - DKP/EPGP Management" <--
]]

L["#wndMain:Title"] = "RaidOps - DKP/EPGP Management (in French :D)" 
