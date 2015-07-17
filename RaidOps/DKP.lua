-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOps
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------
 --         ^                       ^
--         |\   \        /        /|
--        /  \  |\__  __/|       /  \
--       / /\ \ \ _ \/ _ /      /    \
--      / / /\ \ {*}\/{*}      /  / \ \
--      | | | \ \( (00) )     /  // |\ \
--      | | | |\ \(V""V)\    /  / | || \| 
--      | | | | \ |^--^| \  /  / || || || 
--     / / /  | |( WWWW__ \/  /| || || ||
--    | | | | | |  \______\  / / || || || 
--    | | | / | | )|______\ ) | / | || ||
--    / / /  / /  /______/   /| \ \ || ||
--   / / /  / /  /\_____/  |/ /__\ \ \ \ \
--   | | | / /  /\______/    \   \__| \ \ \
--   | | | | | |\______ __    \_    \__|_| \
--   | | ,___ /\______ _  _     \_       \  |
--   | |/    /\_____  /    \      \__     \ |    /\
--   |/ |   |\______ |      |        \___  \ |__/  \
--   v  |   |\______ |      |            \___/     |
--      |   |\______ |      |                    __/
--      \   \________\_    _\               ____/
--     __/   /\_____ __/   /   )\_,      _____/
--    /  ___/  \uuuu/  ___/___)    \______/
--    VVV  V        VVV  V 

-- Beware! Here be dragons!

require "Apollo"
require "Window"
require "ICComm"

-----------------------------------------------------------------------------------------------
-- DKP Module Definition
-----------------------------------------------------------------------------------------------
local DKP = {} 
 ----------------------------------------------------------------------------------------------
-- OneVersion Support 
-----------------------------------------------------------------------------------------------
local Major, Minor, Patch, Suffix = 2, 25, 0, 0
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrNormalText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloNormal")

local knLabelSpacing = 14
local knLabelWidth = 103
 
 local ktClassToIcon =
{
	[GameLib.CodeEnumClass.Medic]       	= "Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Esper]       	= "Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "Icon_Windows_UI_CRB_Spellslinger",
}

local ktClassToString =
{
	[GameLib.CodeEnumClass.Medic]       	= "Medic",
	[GameLib.CodeEnumClass.Esper]       	= "Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "Spellslinger",
}

local ktStringToIcon = {}

local ktStringToIconOrig =
{
	["Medic"]       	= "Icon_Windows_UI_CRB_Medic",
	["Esper"]       	= "Icon_Windows_UI_CRB_Esper",
	["Warrior"]     	= "Icon_Windows_UI_CRB_Warrior",
	["Stalker"]     	= "Icon_Windows_UI_CRB_Stalker",
	["Engineer"]    	= "Icon_Windows_UI_CRB_Engineer",
	["Spellslinger"]  	= "Icon_Windows_UI_CRB_Spellslinger",
}

local ktStringToNewIconOrig =
{
	["Medic"]       	= "BK3:UI_Icon_CharacterCreate_Class_Medic",
	["Esper"]       	= "BK3:UI_Icon_CharacterCreate_Class_Esper",
	["Warrior"]     	= "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	["Stalker"]     	= "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	["Engineer"]    	= "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	["Spellslinger"]  	= "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
}

local umplauteConversions = {
	["ä"] = "ae",
	["ö"] = "oe",
	["ü"] = "ue",
	["ß"] = "ss",
	["Ü"] = "Ue",
	["Ö"] = "Oe",
	["Ä"] = "Ae",
	["Ú"] = "U",
	["ú"] = "u",
 }
 
local ktRoleStringToIcon =
{
	["DPS"] = "IconSprites:Icon_Windows_UI_CRB_Attribute_BruteForce",
	["Heal"] = "IconSprites:Icon_Windows_UI_CRB_Attribute_Health",
	["Tank"] = "IconSprites:Icon_Windows_UI_CRB_Attribute_Shield",
	["None"] = "",
}

local ktClassOrderDefault = 
{
	[1] = "Esper",
	[2] = "Spellslinger",
	[3] = "Medic",
	[4] = "Stalker",
	[5] = "Warrior",
	[6] = "Engineer",
}

local ktUndoActions = 
{
	--Players
	["addp"] = "{Added Player}",
	["addmp"] = "{Added Many Players}",
	["remp"] = "{Removed Player}",
	["mremp"] = "{Removed Multiple Players}",
	--Alts
	["amrg"] = "{Merged %s with %s}",
	["acon"] = "{Converted %s to %s's alt}",

	--CustomEvents
	["cetrig"] = "{Award for %s , ID : %s}",
	--TimedAwards
	["tawardep"] = "{Timed EP Award}",
	["tawardgp"] = "{Timed GP Award}",
	["tawarddkp"] = "{Timed DKP Award}",
	["taward"] = "{Timed Award}",
	--Add
	["adddkp"] = "{Added DKP}",
	["addep"] = "{Added EP}",
	["addgp"] = "{Added GP}"	,
	["madddkp"] = "{Mass Added DKP}",
	["maddep"] = "{Mass Added EP}",
	["maddgp"] = "{Mass Added GP}",	
	--Subtract
	["subdkp"] = "{Subtracted DKP}",
	["subep"] = "{Subtracted EP}",
	["subgp"] = "{Subtracted GP}",
	["msubdkp"] = "{Mass Subtracted DKP}",
	["msubep"] = "{Mass Subtracted EP}",
	["msubgp"] = "{Mass Subtracted GP}",	
	--Set
	["setdkp"] = "{Set DKP}",
	["setep"] = "{Set EP}",
	["setgp"] = "{Set GP}",
	["msetdkp"] = "{Mass Set DKP}",
	["msetep"] = "{Mass Set EP}",
	["msetgp"] = "{Mass Set GP}",
	--Raid
	["raward"] = "{Raid Award}",
	--Item
	["itreass"] = "Reassigned %s from %s to %s",
	["itrem"] = "Removed %s from %s",
	["maward"] = "Awarded %s with %s",
	--Decay
	["dkpdec"] = "{DKP Decay}"

}
local ktQual = 
{
	["Gray"] = true,
	["White"] = true,
	["Green"] = true,
	["Blue"] = true,
	["Purple"] = true,
	["Orange"] = true,
	["Pink"] = true,
}

		
local RAID_GA = 0
local RAID_DS = 1
local RAID_Y = 2

-- Changelog
local strChangelog = 
[===[
---RaidOps version 2.25---
{13/07/2015}
DKP decay overhaul.
Added DKP precision sliders.
Fixed Auto Comment not recognizing DKP changes.
DKP decay is registered in Recent Activity.
Added Option to credit player with attendance manually. 
Added Option to remove player's attendance manually. 
When switching to Mass Edit currently selected player will transition to this mode.
---RaidOps version 2.24---
{12/07/2015}
Fixed GP values on tokens' tooltips - standalone.
Added option to import/export settings only.
Fixed LUA error on attemting to clear raids based on day difference.
Small UI fixes and enhancements.
Another iteration of Custom events UI maybe the final one.
From versions 2.23 b and c :
Added option to filter out trash items in website export.
Added option to filter Item label with Loot Logs filtering.
---RaidOps version 2.23---
{08/07/2015}
Added Decay reminder.
Fixed Gp values not showing on certain item types - for standalone tooltips.
Added option to start and stop 'Timed Award' on raid session start/end.
Fixed small Attendace + Raid Queue UI bug.
Time award timer is now saved between sessions.
---RaidOps version 2.22---
{05/07/2015}
Added Raid Queue option to Timed Award.
Added On-screen notification for Timed Award.
Added option to grant award on timer's start for Timed Award.
After value in logs will be now present for '{Decay}' log.
Data for Hrs label is now pulled from Raid Sessions.
Dropped Base64 Encoding for import/export.
Added 4 new tutorials.
Item tooltip no longer requires EToolTip addon , compatibilty remains.
Added some condition checks to players' attendances.
---RaidOps version 2.21---
{03/07/2015}
Added option to hide Standby players from main roster.
Fixed error on raid session start.
Raid types in Raid Summaries are now colored.
---RaidOps version 2.20---
{30/06/2015}
Fixed LUA error when attempting to enable offspec in PopUp window while the GP value equals 0.
Complete reskin of loot logs.
Changed sliders appearance.
Sliders will now indicate the current value.
Added 'disable' option do Max Days slider in Loot Logs.
Added option to specify class order when grouping by class.
Added stock context menu to item label.
Raid session will now convert all alts' names to their main's name.Solves problem of missing or multiple entries.
Added option to make GP value unable to drop below BaseGP value.
Fixed Loot Logs's day filter not counting months.
Fixed tutorial window not destroying glow on tutorial exit.
Added all missing Datascape map ids for raid summaries. 

NOTE: Decreased freqency of updates is caused by me developing completly different addon and some irl stuff. More info at a later date.
 ]===]

-- Localization stuff
local ktLocales = {
	[1] = "enUS",
	[2] = "deDE",
	[3] = "frFR",
	[4] = "koKR",
}

local function GetLocale()
	local strCancel = Apollo.GetString(1)
	
	-- German
	if strCancel == "Abbrechen" then 
		return ktLocales[2]
	end
	
	-- French
	if strCancel == "Annuler" then
		return ktLocales[3]
	end
	
	-- Other
	return ktLocales[1]
end
local strLocale = GetLocale()
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local selectedMembers =  {}
function DKP:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tItems = {}
	o.wndSelectedListItem = nil 
	
    return o
end

function DKP:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	}
	self.tItems = {}
	purge_database = 0
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- DKP OnLoad
-----------------------------------------------------------------------------------------------
function DKP:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("DKP.xml")
	self.xmlDoc2 = XmlDoc.CreateFromFile("DKP2.xml")
	self.xmlDoc3 = XmlDoc.CreateFromFile("DKP3.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- DKP OnDocLoaded
-----------------------------------------------------------------------------------------------
function DKP:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "DKPMain", nil, self)
		self.wndSettings = Apollo.LoadForm(self.xmlDoc, "Settings" , nil , self)
		self.wndExport = Apollo.LoadForm(self.xmlDoc, "Export" , nil , self)
		self.wndPopUp = Apollo.LoadForm(self.xmlDoc, "MasterLootPopUp" , nil ,self)
		self.wndStandby = Apollo.LoadForm(self.xmlDoc2, "StandbyList" , nil , self)
		self.wndCredits = Apollo.LoadForm(self.xmlDoc2, "Thanks" , nil , self)
		self.wndChangelog = Apollo.LoadForm(self.xmlDoc2, "Changelog" , nil , self)
		
		
		--Localisation
		
		self.GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
		self.Locale = self.GeminiLocale:GetLocale("RaidOps", true)
		self.GeminiLocale:TranslateWindow(self.Locale, self.wndMain)
		self.GeminiLocale:TranslateWindow(self.Locale, self.wndSettings)
		
		--Tooltip Translation
		
		--Controls
		self.wndMain:FindChild("LogHelp"):SetTooltip(self.Locale["#wndMain:Tooltips:Controls:QuestionMark"])
		self.wndMain:FindChild("TokenGroup"):SetTooltip(self.Locale["#wndMain:Tooltips:Controls:GroupTokens"])
		--wndMain
		self.wndMain:FindChild("Refresh"):SetTooltip(self.Locale["#wndMain:Tooltips:Refresh"])
		self.wndMain:FindChild("CurrentlyListedAmount"):SetTooltip(self.Locale["#wndMain:Tooltips:Counter"])
		self.wndMain:FindChild("ButtonLL"):SetTooltip(self.Locale["#wndMain:Tooltips:LLButton"])
		self.wndMain:FindChild("ButtonCE"):SetTooltip(self.Locale["#wndMain:Tooltips:CEButton"])
		self.wndMain:FindChild("ButtonInv"):SetTooltip(self.Locale["#wndMain:Tooltips:InvButton"])
		self.wndMain:FindChild("ButtonGBL"):SetTooltip(self.Locale["#wndMain:Tooltips:GBLButton"])
		self.wndMain:FindChild("ButtonGBL"):SetTooltip(self.Locale["#wndMain:Tooltips:GBLButton"])
		self.wndMain:FindChild("RaidOnly"):SetTooltip(self.Locale["#wndMain:Tooltips:RaidOnlyButton"])
		self.wndMain:FindChild("OnlineOnly"):SetTooltip(self.Locale["#wndMain:Tooltips:OnlineOnlyButton"])
		self.wndMain:FindChild("MassEdit"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEditButton"])
		self.wndMain:FindChild("RaidQueue"):SetTooltip(self.Locale["#wndMain:Tooltips:RaidQueue"])
		self.wndMain:FindChild("ClearQueue"):SetTooltip(self.Locale["#wndMain:Tooltips:ClearRaidQueue"])
		--massEditControls
		self.wndMain:FindChild("ButtonSelectRaidOnly"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEdit:SelectRaid"])
		self.wndMain:FindChild("ButtonDeselectAll"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEdit:DeselectAll"])
		self.wndMain:FindChild("ButtonSelectAll"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEdit:SelectAll"])
		self.wndMain:FindChild("ButtonInvite"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEdit:Invite"])
		self.wndMain:FindChild("ButtonInvert"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEdit:Invert"])
		self.wndMain:FindChild("ButtonRemoveAll"):SetTooltip(self.Locale["#wndMain:Tooltips:MassEdit:Remove"])
		--wndSettings
		self.wndSettings:FindChild("ButtonSettingsNameplatreAffiliation"):SetTooltip(self.Locale["#wndSettings:Tooltips:AccCreation"])
		self.wndSettings:FindChild("CatPopUp"):FindChild("PopUPDec"):SetTooltip(self.Locale["#wndSettings:Tooltips:PopUPDec"])
		self.wndSettings:FindChild("ButtonShowGP"):SetTooltip(self.Locale["#wndSettings:Tooltips:GPTooltip"])
		self.wndSettings:FindChild("ButtonSettingsBidModule"):SetTooltip(self.Locale["#wndSettings:Tooltips:EnableBidding"])
		self.wndSettings:FindChild("RemoveErrorInvites"):SetTooltip(self.Locale["#wndSettings:Tooltips:InvErr"])
		self.wndSettings:FindChild("ButtonShowStandby"):SetTooltip(self.Locale["#wndSettings:Tooltips:Standby"])
		self.wndSettings:FindChild("FilterKeywordsButton"):SetTooltip(self.Locale["#wndSettings:Tooltips:FilterKey"])
		self.wndSettings:FindChild("ButtonSettingsPurge"):SetTooltip(self.Locale["#wndSettings:Tooltips:Purge"])
		--
		
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		if self.wndMainLoc ~= nil then 
			if self.tItems.wndMainLoc and self.tItems.wndMainLoc.nOffsets[1] ~= 0 then
				self.wndMain:MoveToLocation(self.wndMainLoc) 
				self.wndMainLoc = nil
			end
		end
		if self.tItems.wndPopUpLoc ~= nil and self.tItems.wndPopUpLoc.nOffsets[1] ~= 0 then 
			self.wndPopUp:MoveToLocation(WindowLocation.new(self.tItems.wndPopUpLoc))
			self.tItems.wndPopUpLoc = nil
		end


		Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
		self.wndItemList = self.wndMain:FindChild("ItemList")
		self.wndMain:Show(false, true)
		self.wndSettings:Show(false , true)
		self.wndExport:Show(false , true)
		self.wndPopUp:Show(false, true)
		self.wndStandby:Show(false,true)
		self.wndCredits:Show(false,true)
		self.wndChangelog:Show(false,true)
		Apollo.RegisterSlashCommand("epgp", "OnDKPOn", self)
		Apollo.RegisterSlashCommand("ropsml", "MLSettingShow", self)
		Apollo.RegisterSlashCommand("nb", "Bid2ShowNetworkBidding", self)
		Apollo.RegisterSlashCommand("dbgf", "DebugFetch", self)
		Apollo.RegisterTimerHandler(10, "OnTimer", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		Apollo.RegisterEventHandler("Group_Invite_Result","InviteOnResult", self)
		
		self.timer = ApolloTimer.Create(10, true, "OnTimer", self)

		local setButton = self.wndMain:FindChild("ButtonSet")
		local addButton = self.wndMain:FindChild("ButtonAdd")
		local subtractButton = self.wndMain:FindChild("ButtonSubtract")
		setButton:Enable(false)
		addButton:Enable(false)
		subtractButton:Enable(false)
		self.ActiveAuctions = {}
		if self.tItems["alts"] == nil then self.tItems["alts"] = {} end
		if self.tItems["settings"] == nil then
			self.tItems["settings"] = {}
			self.tItems["settings"].whisp = 1
			self.tItems["settings"].logs =1
			self.tItems["settings"].guildname = nil
			self.tItems["settings"].dkp = 200 -- mass add
			self.tItems["settings"].default_dkp = 500
			self.tItems["settings"].collect_new = 0
			self.tItems["settings"].forceCheck = 0
			self.tItems["settings"].lowercase = 0
			self.tItems["settings"].BidEnable = 1
			self.tItems["settings"].PopupEnable = 1
		end
		if self.tItems["settings"].forceCheck == nil then self.tItems["settings"].forceCheck = 0 end
		if self.tItems["settings"].lowercase == nil then self.tItems["settings"].lowercase = 0 end
		if self.tItems["settings"].BidEnable == nil then self.tItems["settings"].BidEnable = 1 end
		if self.tItems["settings"].PopupEnable == nil then self.tItems["settings"].PopupEnable = 1 end 
		if self.tItems["settings"].LabelOptions == nil then
			self.tItems["settings"].LabelOptions = {}
			self.tItems["settings"].LabelOptions[1] = "Name"
			self.tItems["settings"].LabelOptions[2]= "EP"
			self.tItems["settings"].LabelOptions[3] = "GP"
			self.tItems["settings"].LabelOptions[4] = "PR"
			self.tItems["settings"].LabelOptions[5] = "Nil"
		end
		if self.tItems["settings"].LabelSortOrder == nil then self.tItems["settings"].LabelSortOrder = "asc" end
		if self.tItems["settings"].Precision == nil then self.tItems["settings"].Precision = 1 end
		if self.tItems["settings"].PrecisionEPGP == nil then self.tItems["settings"].PrecisionEPGP = 1 end
		if self.tItems["settings"].nPrecisionDKP == nil then self.tItems["settings"].nPrecisionDKP = 2 end
		if self.tItems["settings"].CheckAffiliation == nil then self.tItems["settings"].CheckAffiliation = 0 end
		if self.tItems["settings"].GroupByClass == nil then  self.tItems["settings"].GroupByClass = false end
		if self.tItems["settings"].FilterEquippable == nil then self.tItems["settings"].FilterEquippable = false end
		if self.tItems["settings"].FilterWords == nil then self.tItems["settings"].FilterWords = false end
		if self.tItems["settings"].networking == nil then self.tItems["settings"].networking = true end
		if self.tItems["settings"].bTrackUndo == nil then self.tItems["settings"].bTrackUndo = true end
		if self.tItems["settings"].nPopUpGPRed == nil then self.tItems["settings"].nPopUpGPRed = 25 end
		if self.tItems["settings"].bColorIcons == nil then self.tItems["settings"].bColorIcons = true end
		if self.tItems["settings"].bDisplayRoles == nil then self.tItems["settings"].bDisplayRoles = true end
		if self.tItems["settings"].bSaveUndo == nil then self.tItems["settings"].bSaveUndo = true end
		if self.tItems["settings"].bSkipGB == nil then self.tItems["settings"].bSkipGB = false end
		if self.tItems["settings"].bRemErrInv == nil then self.tItems["settings"].bRemErrInv = true end
		if self.tItems["settings"].bDisplayCounter == nil then self.tItems["settings"].bDisplayCounter = true end
		if self.tItems["settings"].bCountSelected == nil then self.tItems["settings"].bCountSelected = false end
		if self.tItems["settings"].bTrackTimedAwardUndo == nil then self.tItems["settings"].bTrackTimedAwardUndo = false end
		if self.tItems["settings"].bLootLogs == nil then self.tItems["settings"].bLootLogs = true end
		if self.tItems["settings"].strLootFiltering == nil then self.tItems["settings"].strLootFiltering = "Nil" end
		if self.tItems["settings"].strDateFormat == nil then self.tItems["settings"].strDateFormat = "EU" end
		if self.tItems["settings"].bPopUpRandomSkip == nil then self.tItems["settings"].bPopUpRandomSkip = false end
		if self.tItems["settings"].bHideStandby == nil then self.tItems["settings"].bHideStandby = false end
		if self.tItems["settings"].nMinIlvl == nil then self.tItems["settings"].nMinIlvl = 1 end
		if self.tItems["Standby"] == nil then self.tItems["Standby"] = {} end
		if self.tItems.tQueuedPlayers == nil then self.tItems.tQueuedPlayers = {} end
		self.wndTimeAward = self.wndMain:FindChild("TimeAward")
		self.wndTimeAward:Show(false,true)
		self.MassEdit = false
		self.wndMain:FindChild("MassEditControls"):SetOpacity(0)
		self:delay(1,function (tContext)
			tContext.wndMain:FindChild("MassEditControls"):Show(false)
		end)
		-- Colors
		if self.tItems["settings"].bColorIcons then ktStringToIcon = ktStringToNewIconOrig else ktStringToIcon = ktStringToIconOrig end
		-- Inits
		self:TimeAwardRestore()
		self:COInit()
		self:EPGPInit()
		self:ConInit()
		self:AltsInit()
		self:LogsInit()
		self:GIInit()
		self:InvitesInit()
		self:LLInit()
		self:DFInit()
		self:CloseBigPOPUP()
		self:FLInit()
		self:UndoInit()
		self:CEInit()
		self:FQInit()
		self:RIInit()
		self:MAInit()
		self:RenameInit()
		self:NotificationInit()
		self:MresInit()
		self:LabelInit()
		self:ReassInit()
		self:IBInit()
		self:WebInit()
		self:SupportInit()
		self:AttInit()
		self:RSInit()
		self:TutInit()
		self:TutListInit()
		self:DRInit()
		self:DecayInit()
		self:GroupInit()
		self:GroupDialogInit()

		
		self.wndMain:FindChild("ShowDPS"):SetCheck(true)
		self.wndMain:FindChild("ShowHeal"):SetCheck(true)
		self.wndMain:FindChild("ShowTank"):SetCheck(true)
		
		-- wndMain resizing

		self.wndMain:SetSizingMinimum(1057,778)
		self.wndMain:SetSizingMaximum(1540,778)



		-- Bidding
		
		self.tSelectedItems = {}
		self.bAwardingOnePlayer = false
		self.tPopUpExceptions = {}
		self.tPopUpItemGPvalues = {}
		
		
		self.SortedLabel = nil
		self:LabelUpdateList() --<<<< With Show ALL
		self:UpdateItemCount()
		self.wndMain:FindChild("Decay"):Show(false)

		self:ControlsUpdateQuickAddButtons()
		self:EnableActionButtons()
		self.wndChangelog:FindChild("Log"):SetText(strChangelog)
		
		if self.tItems["settings"].BidEnable == 1 then self:BidBeginInit()
		else
			self.wndMain:FindChild("CustomAuction"):Show(false)
			self.wndMain:FindChild("BidCustomStart"):Show(false)
			self.wndMain:FindChild("LabelAuction"):Show(false)
			self:DSInit()
		end

		self:SettingsRestore()
		
		if self:GetPlayerByIDByName("Guild Bank") == -1 then
			self:OnUnitCreated("Guild Bank",true)
		end
		self.wndMain:FindChild("ButtonNB"):Enable(false)

		--DEBUG
		if not self.tItems["settings"].tDebugLogs then self.tItems["settings"].tDebugLogs = {} end


		--OneVersion
		self:delay(2,function() Event_FireGenericEvent("OneVersion_ReportAddonInfo", "RaidOps", Major, Minor, Patch) end)
	end
end

-----
-- Debug
-----
function DKP:DebugFetch()
	local wnd = Apollo.LoadForm(self.xmlDoc3,"DbgOutput",nil,self)
	local str = self:dbggetlogs()
	wnd:FindChild("Output"):SetText(#str > 29999 and "Reached limit of 30k" or str)
	self:RequestRoster()
end

function DKP:dbglog(strMsg)
	--table.insert(self.tItems["settings"].tDebugLogs,"["..os.date("%X",os.time()).."] "..strMsg)
end

function DKP:dbggetlogs()
	local str = ""
	for k , log in ipairs(self.tItems["settings"].tDebugLogs) do
		str = str .. log .. "\n"
	end
	return str
end

function DKP:ChangelogShow()
	self.wndChangelog:Show(true,false)
	self.wndChangelog:ToFront()
end

function DKP:ChangelogHide()
	self.wndChangelog:Show(false,false)
end

function DKP:CreditsShow()
	self.wndCredits:Show(true,false)
	self.wndCredits:ToFront()
end

function DKP:CreditsHide()
	self.wndCredits:Show(false,false)
end
---------------
-- Delay
---------------
local tDelayActions = {}
local bDelayRunning = false
function DKP:delay(nSecs,func,args)
	table.insert(tDelayActions,{func = func , delay = nSecs , args = args})
	if not bDelayRunning then
		Apollo.RegisterTimerHandler(1,"DelayTimer",self)
		self.delayTimer = ApolloTimer.Create(1,true,"DelayTimer",self)
		bDelayRunning = true
	end
	return #tDelayActions
end

function DKP:DelayTimer()
	for k , event in ipairs(tDelayActions) do
		event.delay = event.delay - 1
		if event.delay == 0 then
			event.func(self)
			table.remove(tDelayActions,k)
		end
	end

	if #tDelayActions == 0 then 
		self.delayTimer:Stop() 
		bDelayRunning = false
	end
end

---------------
--Undo
---------------
local tUndoActions = {}
local tRedoActions = {}

function DKP:UndoClose()
	self.wndActivity:Show(false,false)
end

function DKP:UndoInit()
	self.wndActivity = Apollo.LoadForm(self.xmlDoc,"UndoLogs",nil,self)
	self.wndActivity:Show(false,true)
	self.wndActivity:FindChild("Redo"):Enable(false)
end

function DKP:UndoAddActivity(strType,strMod,tMembers,bRemoval,strForceComment,bAddAlt)
	if not self.tItems["settings"].bTrackUndo then return end
	local tMembersNames = {}
	local strComment = ""
	if bRemoval == true or bRemoval == false then strComment = "--" 
	elseif self:string_starts(strType,"Award for") then  strComment = "--" 
	elseif strType == ktUndoActions["addmp"] then  strComment = "--" 
	elseif strType == ktUndoActions["remp"] then  strComment = "--" 
	elseif strType == ktUndoActions["mremp"] then  strComment = "--" 
	elseif strType == ktUndoActions["dkpdec"] then  strComment = "--" 
	elseif self.tItems["settings"].logs == 1 then 
		strComment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
		if strComment == "Comment" or strComment == "Comments Disabled"  then strComment = "--" end
	end
	if strForceComment then strComment = strForceComment end
	for k,player in ipairs(tMembers) do table.insert(tMembersNames,player.strName) end
	table.sort(tMembersNames,raidOpsSortCategories)
	table.insert(tUndoActions,1,{tAffectedNames = tMembersNames,strType = strType,strMod = strMod,nAffected = #tMembers,strData = serpent.dump(tMembers),bRemove = bRemoval,strTimestamp = self:ConvertDate(os.date("%x",os.time())) .. " " .. os.date("%X",os.time()),strComment = strComment,bAddAlt = bAddAlt})
	if #tUndoActions > 20 then table.remove(tUndoActions,21) end
	self:UndoPopulate()
	tRedoActions = {} 
	self.wndActivity:FindChild("Redo"):Enable(false)
end

function DKP:UndoAddRevertActivity(tMembers)
	table.insert(tRedoActions,1,{strData = serpent.dump(tMembers) , bRemove = tUndoActions[1].bRemove , tUndoData = tUndoActions[1]})
	self.wndActivity:FindChild("Redo"):Enable(true)
end

function DKP:UndoRedo()
	local tMembersToRevert = serpent.load(tRedoActions[1].strData)
	if tMembersToRevert then
		for k,revertee in ipairs(tMembersToRevert) do
			if tRedoActions[1].bRemove == nil then
				for k,player in ipairs(self.tItems) do
					if player.strName == revertee.strName then -- modifications 
						self.tItems[k] = revertee
						break
					end
				end
			elseif tRedoActions[1].bRemove == true then --bRemove is inverted (redo)
				for k,player in ipairs(self.tItems) do
					if player.strName == revertee.strName then table.remove(self.tItems,k) break end
				end
			elseif tRedoActions[1].bRemove == false  and self:GetPlayerByIDByName(revertee.strName) == -1 then 
				table.insert(self.tItems,revertee) -- adding player
			end
		end
		self:RefreshMainItemList()
	end	

	table.insert(tUndoActions,1,tRedoActions[1].tUndoData)
	self:UndoPopulate()
	table.remove(tRedoActions,1)
	if #tRedoActions == 0 then self.wndActivity:FindChild("Redo"):Enable(false) end
end

function DKP:GetPlayerByIDByName(strName)
 
	local strPlayer = ""
	for uchar in string.gfind(strName, "([%z\1-\127\194-\244][\128-\191]*)") do
		if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
		strPlayer = strPlayer .. uchar
	end
	strName = strPlayer
	
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(strName) then return i end
	end
	
	for j,alt in pairs(self.tItems["alts"]) do
		if string.lower(strName) == string.lower(j) then return self.tItems["alts"][j] end
	end

	
	return -1
end

function DKP:Undo()
	if #tUndoActions > 0 then
		local tMembersToRevert = serpent.load(tUndoActions[1].strData)
		
		if tUndoActions[1].bAddAlt == nil then
			local tRevertMembers = {}
			if tMembersToRevert then
				for k,revertee in ipairs(tMembersToRevert) do
					if tUndoActions[1].bRemove == nil or tUndoActions[1].bRemove == false then
						local ID = self:GetPlayerByIDByName(revertee.strName)
						if ID ~= -1 then
							table.insert(tRevertMembers,self.tItems[ID])
						end
					elseif tUndoActions[1].bRemove == true then
						table.insert(tRevertMembers,revertee)
					end
				end			
			end
			self:UndoAddRevertActivity(tRevertMembers)
		end

		if tMembersToRevert then
			for k,revertee in ipairs(tMembersToRevert) do
				if tUndoActions[1].bRemove == nil then
					for k,player in ipairs(self.tItems) do
						if player.strName == revertee.strName then -- modifications 
							self.tItems[k] = revertee
							--[[if string.find(tUndoActions[1].strType,"Reassigned") then
								local item = Item.GetDataFromId(tUndoActions[1].item)
								if item then
									if k == 1 then -- Giver -> Add
										self
									elseif k == 2 then -- Recipient -> Rem

									end
								end
							end]]
							break
						end
					end
				elseif tUndoActions[1].bRemove == true and self:GetPlayerByIDByName(revertee.strName) == -1 then
					table.insert(self.tItems,revertee) -- adding player
				elseif tUndoActions[1].bRemove == false then 
					for k,player in ipairs(self.tItems) do
						if player.strName == revertee.strName then table.remove(self.tItems,k) break end
					end
				end
			end
			table.remove(tUndoActions,1)
			self:UndoPopulate()
			self:RefreshMainItemList()
		end	
	end
end

function DKP:UndoPopulate()
	local grid = self.wndActivity:FindChild("Grid")
	
	grid:DeleteAll()
	
	for k,activity in ipairs(tUndoActions) do
		grid:AddRow(k)
		grid:SetCellData(k,1,k)
		if activity.strAction then grid:SetCellData(k,2,activity.strAction) else
			grid:SetCellData(k,2,activity.strType)
			grid:SetCellData(k,3,activity.strMod)
			grid:SetCellData(k,4,activity.nAffected)
			local strAffected = ""
			for k, affected in ipairs(activity.tAffectedNames) do
				strAffected = strAffected .. affected ..  " , "
			end
			grid:SetCellData(k,5,strAffected)
			if activity.strComment then grid:SetCellData(k,6,activity.strComment) else grid:SetCellData(k,6,"--")	end
			grid:SetCellData(k,7,activity.strTimestamp)	
		end
	end
	
	--grid:ArrangeChildrenVert(0,function(a,b) return tonumber(a) < tonumber(b) end)
end

function DKP:UndoShowActions()
	if not self.wndActivity:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndActivity:Move(tCursor.x - 400, tCursor.y - 400, self.wndActivity:GetWidth(), self.wndActivity:GetHeight())
	end
	
	self.wndActivity:Show(true,false)
	self.wndActivity:ToFront()
	self:UndoPopulate()
end

function DKP:UndoClear()
	tUndoActions = {}
	self:UndoPopulate()
end

function DKP:UndoTrackEnable()
	self.tItems["settings"].bTrackUndo = true 
end

function DKP:UndoTrackDisable()
	self.tItems["settings"].bTrackUndo = false 
end

---------------
--Guild Import
---------------


local tGuildRoster
local tAcceptedRanks = {}

function DKP:CloseBigPOPUP()
	self.wndMain:FindChild("BIGPOPUP"):Show(false,true)
end

function DKP:GIInit()
	self.wndGuildImport = Apollo.LoadForm(self.xmlDoc,"GuildImport",nil,self)
	self.wndGuildImport:Show(false,true)
	self:ImportFromGuild()
end

function DKP:GIShow()
	if not self.wndGuildImport:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndGuildImport:Move(tCursor.x - 100, tCursor.y - 100, self.wndGuildImport:GetWidth(), self.wndGuildImport:GetHeight())
	end
	
	self.wndGuildImport:Show(true,false)
	self.wndGuildImport:ToFront()
	
	self:GIPopulateRanks()
end

function DKP:GIClose()
	self.wndGuildImport:Show(false,false)
end

function DKP:GIPopulateRanks()
	if self.uGuild then
		local tRanks = self.uGuild:GetRanks()
		for k,rank in ipairs(tRanks) do
			if k > 10 then break end
			self.wndGuildImport:FindChild(tostring(k)):SetText(rank.strName)
			self.wndGuildImport:FindChild(tostring(k)):SetData(rank)
			if rank.strName == "" then self.wndGuildImport:FindChild(tostring(k)):Enable(false) end
		end
	end
end

function DKP:GIRankAdded(wndHandler,wndControl)
	table.insert(tAcceptedRanks,tonumber(wndControl:GetName()))
	Event_FireGenericEvent("GIRankSelect")
	self:GIUpdateCount()
end

function DKP:GIRankRemoved(wndHandler,wndControl)
	for k,rank in ipairs(tAcceptedRanks) do
		if rank == tonumber(wndControl:GetName()) then table.remove(tAcceptedRanks,k) break end
	end
	
	self:GIUpdateCount()
end

function DKP:GIIsGoodRank(nRank)
	for k,rank in ipairs(tAcceptedRanks) do
		if rank == nRank then return true end
	end
	
	return false
end

function DKP:GIImport()
	if tonumber(self.wndGuildImport:FindChild("MinLevel"):GetText()) == nil then return end
	local tMembers = {}
	for k,member in ipairs(tGuildRoster) do
		if self:GIIsGoodRank(member.nRank) and member.nLevel >= tonumber(self.wndGuildImport:FindChild("MinLevel"):GetText()) and self:GetPlayerByIDByName(member.strName) == -1 then 
			self:OnUnitCreated(member.strName,true,true)
			self:RegisterPlayerClass(self:GetPlayerByIDByName(member.strName),member.strClass)
			table.insert(tMembers,self.tItems[self:GetPlayerByIDByName(member.strName)])
		end
	end
	self:UndoAddActivity(#tMembers == 1 and ktUndoActions["addp"] or ktUndoActions["addmp"],"--",tMembers,nil,nil,false)
	self:RefreshMainItemList()
	self:GIUpdateCount()
	Event_FireGenericEvent("GIImport")

	
end

function DKP:GIUpdateCount()
	if tGuildRoster then
		if tonumber(self.wndGuildImport:FindChild("MinLevel"):GetText()) == nil then 
			self.wndGuildImport:FindChild("Count"):SetText("0")
			return 
		end
		local tMembers = {}
		for k,member in ipairs(tGuildRoster) do
			if self:GIIsGoodRank(member.nRank) and member.nLevel >= tonumber(self.wndGuildImport:FindChild("MinLevel"):GetText()) and self:GetPlayerByIDByName(member.strName) == -1 then table.insert(tMembers,member) end
		end
		self.wndGuildImport:FindChild("Count"):SetText(#tMembers)
	end
end

function DKP:ImportFromGuild()
	Apollo.RegisterEventHandler("GuildRoster","GotRoster", self)
	local guilds = GuildLib.GetGuilds() or {}
	for k,guild in ipairs(guilds) do 
		if guild:GetType() == GuildLib.GuildType_Guild then
			guild:RequestMembers()
			self.uGuild = guild
			break
		end
	end
end

function DKP:GotRoster(guildCurr, tRoster)
	Apollo.RemoveEventHandler("GuildRoster",self)
	tGuildRoster = tRoster
	if self.wndGuildImport:IsShown() then self:GIPopulateRanks() end
	if self.wndMain:FindChild("OnlineOnly"):IsChecked() then self:RefreshMainItemList() end
end

function DKP:FixOddCharacterInNames()
	for k,player in ipairs(self.tItems) do
		strNewName = ""
		for uchar in string.gfind(player.strName, "([%z\1-\127\194-\244][\128-\191]*)") do
			if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
			strNewName = strNewName .. uchar
		end
		
		player.strName = strNewName
	end
	self:RefreshMainItemList()
end

function DKP:OnUnitCreated(unit,isStr,bForceNoRefresh)
	local strName
	if isStr ~=nil then
		if isStr == false then
			if not unit:IsACharacter() then
				strName = unit:GetName()
				return
			end
		else
			strName = unit
		end
	else
		if not unit:IsACharacter() then
			return
		end
		strName = unit:GetName()
	end
	if self.tItems["settings"].lowercase == 1 then strName = string.lower(strName) end

	
	-- we don't like umlauts so we gonna get rid of them :)
	strNewName = ""
	for uchar in string.gfind(strName, "([%z\1-\127\194-\244][\128-\191]*)") do
		if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
		strNewName = strNewName .. uchar
	end
	
	strName = strNewName
	
	local isNew=true
	if self.tItems == nil then isNew = true end
	local existingID = self:GetPlayerByIDByName(strName)
	
	if existingID == -1 then
		local newPlayer = {}
		newPlayer.strName = strName
		newPlayer.net = self.tItems["settings"].default_dkp
		newPlayer.tot = self.tItems["settings"].default_dkp
		newPlayer.Hrs = 0
		newPlayer.EP = self.tItems["EPGP"].MinEP
		newPlayer.GP = self.tItems["EPGP"].BaseGP
		newPlayer.alts = {}
		newPlayer.logs = {}
		newPlayer.role = "DPS"
		newPlayer.offrole = "None"
		newPlayer.tLLogs = {}
		table.insert(self.tItems,newPlayer)
	end
	if bForceNoRefresh == nil then self:RefreshMainItemList() end
end

function DKP:OnTimer()
	if self.tItems["settings"].collect_new == 1 then
		for k=1,GroupLib.GetMemberCount(),1 do
			if self.tItems["settings"].CheckAffiliation == 1 then
				local member = GroupLib.GetUnitForGroupMember(k)
					if member ~= nil and member:GetGuildName() ~= nil  then
						if self:GetPlayerByIDByName(member:GetName()) == -1 and member:GetGuildName() ~= nil and self.tItems["settings"].guildname ~= nil   and string.lower(member:GetGuildName()) == string.lower(self.tItems["settings"].guildname)  then
							self:OnUnitCreated(member)
							self:RegisterPlayerClass(self:GetPlayerByIDByName(member:GetName()),member:GetClassId())
						end				
					end		
			else
				local unit_member = GroupLib.GetGroupMember(k)
				if unit_member ~= nil and self:GetPlayerByIDByName(unit_member.strCharacterName) == -1 then
					self:OnUnitCreated(unit_member.strCharacterName,true)
					self:RegisterPlayerClass(self:GetPlayerByIDByName(unit_member.strCharacterName),unit_member.strClassName)
				end
			end
		end
	end
end

function DKP:RegisterPlayerClass(ID,strClass)
	
	if ID ~= -1 then
		if self.tItems[ID].class == nil then
			if type(strClass) ~= "string" then strClass = ktClassToString[strClass] end
			self.tItems[ID].class = strClass
		end
	end
end
-----------------------------------------------------------------------------------------------
-- DKP Functions
-----------------------------------------------------------------------------------------------
function DKP:OnDKPOn()
	self.wndMain:Show(true,false)
	Event_FireGenericEvent("MainWindowShow")
end


-----------------------------------------------------------------------------------------------
-- DKPForm Functions
-----------------------------------------------------------------------------------------------

function DKP:OnOK()
	self.wndMain:Close() 
end


function DKP:OnCancel()
	self.wndMain:Close() 
end


function DKP:SetDKP(cycling)
	if self.MassEdit == true and cycling ~= true then
		self:MassEditModify("Set")
		return
	end

	if self.wndSelectedListItem ~= nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText()
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			local value = tonumber(self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText())
			if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
				if self.tItems["EPGP"].Enable == 1 then
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
						comment = "Set EP"
					elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
						comment = "Set GP"
					end
				else
					comment = "Set DKP"
				end
			end
			if self.tItems["EPGP"].Enable == 0 then	
				if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(ktUndoActions["setdkp"],value,{[1] = self.tItems[ID]},nil,comment) end
				self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",value))
				local ID = self:GetPlayerByIDByName(strName)
				
				local oldTot = tonumber(self.tItems[ID].net)
				self.tItems[ID].net = value
				local newTot = tonumber(self.tItems[ID].net)
				local modifierTot = newTot - oldTot
				local currentTot = tonumber(self.tItems[ID].tot)
				currentTot = currentTot + modifierTot
				local wndTot = self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Tot")))
				self.tItems[ID].tot = currentTot
				if wndTot ~= nil then
					wndTot:SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",self.tItems[ID].tot))
				end
				self:DetailAddLog(comment,"{DKP}",modifierTot,ID)
			else
				local ID = self:GetPlayerByIDByName(strName)
				if cycling ~= true and self.tItems["settings"].bTrackUndo then 	
					self:UndoAddActivity(self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() and ktUndoActions["setgp"] or ktUndoActions["setep"],value,{[1] = self.tItems[ID]},nil,comment) 
				end
				local modEP = self.tItems[ID].EP
				local modGP = self.tItems[ID].GP
				if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() == true then
					if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
						self:EPGPSet(strName,value,value)
						self:DetailAddLog(comment,"{EP}",self.tItems[ID].EP - modEP,ID)
						self:DetailAddLog(comment,"{GP}",self.tItems[ID].GP - modGP,ID)
					else
						self:EPGPSet(strName,value,nil)
						self:DetailAddLog(comment,"{EP}",self.tItems[ID].EP - modEP,ID)
					end
				else 
					if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
						self:EPGPSet(strName,nil,value)
						self:DetailAddLog(comment,"{GP}",self.tItems[ID].GP - modGP,ID)
					else
						self:EPGPSet(strName,nil,nil)
						Print("Nothing added , check EP or GP in the controls box")
					end
				end					
				if self:LabelGetColumnNumberForValue("EP") ~= -1 then
					self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("EP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].EP))
				end
				if self:LabelGetColumnNumberForValue("GP") ~= -1 then
					self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].GP))
				end
				if self:LabelGetColumnNumberForValue("RealGP") ~= -1 then
					self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("RealGP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].GP - self.tItems["EPGP"].BaseGP))
				end
				if self:LabelGetColumnNumberForValue("PR") ~= -1 then
					if self.tItems[ID].GP ~= 0 then 
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f", self.tItems[ID].EP/self.tItems[ID].GP))
					else
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText("0")
					end
				end	
			end
		else
			Print("Name Label is Required")
		end
	else
		Print("You haven't selected any player")
	end
end



function DKP:Search( wndHandler, wndControl, strText )
	if strText ~= "" then
		self.SearchString = strText
	else
		wndControl:SetText("Search")
		self.SearchString = nil
	end
	if self.tItems["settings"].GroupByClass then self:RefreshMainItemListAndGroupByClass() else self:RefreshMainItemList() end
end
function DKP:string_starts(String,Start)
	return string.sub(string.lower(String),1,string.len(Start))==string.lower(Start)
end

function DKP:ResetSearchBox()
	self.wndMain:FindChild("EditBox1"):SetText("Search")
end

-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------
function DKP:UpdateItemCount()
	local count = 0
	if not self.tItems["settings"].bCountSelected and self.MassEdit or not self.MassEdit then 
		count = #self:MainItemListGetChildren()
	elseif self.MassEdit then
		count = #selectedMembers
	end
	
	
	
	if count == 0 then
		self.wndMain:FindChild("CurrentlyListedAmount"):SetText("-")
	else
		self.wndMain:FindChild("CurrentlyListedAmount"):SetText(tostring(count))
	end
end


function DKP:OnListItemSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self.wndSelectedListItem = wndControl
	self:EnableActionButtons()
	Event_FireGenericEvent("PlayerEntrySelected")
end

function DKP:OnListItemDeselected()
	self.wndSelectedListItem = nil
	self:EnableActionButtons()
end

function DKP:ShowDetails(wndHandler,wndControl,eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then 
		self:OnDetailsClose()
		if self:LabelGetColumnNumberForValue("Name") ~= -1 and wndControl:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))) then
			self:DetailShow(wndControl:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText())
		end 
	end
end

function DKP:OnSave(eLevel)
	   	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
		if newImportedDatabaseGlobal ~= nil then self.tItems = newImportedDatabaseGlobal end
		local tSave = {}
		if purge_database == 0 then
			
			
			-- Time award awards
			
			self.tItems["AwardTimer"].EP = self.wndTimeAward:FindChild("Settings"):FindChild("EP"):IsChecked()
			self.tItems["AwardTimer"].GP = self.wndTimeAward:FindChild("Settings"):FindChild("GP"):IsChecked()
			self.tItems["AwardTimer"].DKP = self.wndTimeAward:FindChild("Settings"):FindChild("DKP"):IsChecked()
			
			
			for k,player in ipairs(self.tItems) do
				tSave[k] = {}
				tSave[k].strName = player.strName
				tSave[k].net = player.net
				tSave[k].tot = player.tot
				tSave[k].TradeCap = player.TradeCap
				tSave[k].EP = player.EP
				tSave[k].GP = player.GP
				tSave[k].class = player.class
				tSave[k].alts = player.alts
				tSave[k].logs = player.logs
				tSave[k].role = player.role
				tSave[k].offrole = player.offrole
				tSave[k].tLLogs = player.tLLogs
				tSave[k].tAtt = player.tAtt
			end
			if self.tItems["alts"] ~= nil then
				tSave["alts"]=self.tItems["alts"]
			end
			
			tSave["settings"] = self.tItems["settings"]
			tSave["trades"] = self.tItems["trades"]
			tSave["EPGP"] = self.tItems["EPGP"]
			tSave["Standby"] = self.tItems["Standby"]
			tSave["AwardTimer"] = self.tItems["AwardTimer"]
			tSave["BidSlots"] = self.tItems["BidSlots"]
			tSave["Auctions"] = {}
			tSave["MyChoices"] = self.MyChoices
			tSave["MyVotes"] = self.MyVotes
			tSave["CE"] = self.tItems["CE"]
			tSave.tRaids = self.tItems.tRaids
			if self.tItems["settings"].bSaveUndo then tSave["ALogs"] = tUndoActions end
			tSave.wndMainLoc = self.wndMain:GetLocation():ToTable()
			tSave.wndPopUpLoc = self.wndPopUp:GetLocation():ToTable()
			tSave.wndLLLoc = self.wndLL:GetLocation():ToTable()
			tSave.wndSessionToolbarLoc = self.wndSessionToolbar:GetLocation():ToTable()
			tSave.raidSession = self:AttGetSavePackage()
			if self.wndBid2 then
				tSave.wndNBLoc = self.wndBid2:GetLocation():ToTable()
			end
			tSave.newUpdateAltCleanup = self.tItems.newUpdateAltCleanup
			tSave.tQueuedPlayers = self.tItems.tQueuedPlayers
			tSave.nTATimer = self.NextAward
			if self.ActiveAuctions then
				for k,auction in ipairs(self.ActiveAuctions) do
					if auction.bActive or auction.nTimeLeft > 0 then table.insert(tSave["Auctions"],{itemID = auction.wnd:GetData(),bidders = auction.bidders,votes = auction.votes,bMaster = auction.bMaster,progress = auction.nTimeLeft}) end
				end
			end
		else
			tSave["purged"] = true
		end

	return tSave
end

function DKP:OnRestore(eLevel, tData)	
		if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
		self.tItems = tData
		if self.tItems["EPGP"] ~= nil then
			self.ItemDatabase = self.tItems["EPGP"].Loot
			self.tItems["EPGP"].Loot = nil
		end
		
		if self.tItems["EPGP"] == nil then 
			self.tItems["EPGP"] = {}
			self.tItems["EPGP"].Enable = 0 
		end
		
		tUndoActions = tData["ALogs"] or {}
		self.tItems["ALogs"] = nil
		
		counter=table.maxn(self.tItems)+1
		if tData["alts"] == nil then
			self.tItems["alts"] = {}
		end
		self.NextAward = tData.nTATimer
		self.wndMainLoc = WindowLocation.new(tData.wndMainLoc)
		if self.tItems["purged"] then self.bPostPurge = true end
		self.tItems["purged"] = nil
 end


function DKP:ShowAll()
	self:RefreshMainItemList()
end
function DKP:ForceRefresh()
	self:RefreshMainItemList()
end

function DKP:AddDKP(cycling) -- Mass Edit check
	if self.MassEdit == true and cycling ~= true then
		self:MassEditModify("Add")
		return
	end
	Event_FireGenericEvent("ModifiedSomething")
	if self.wndSelectedListItem ~=nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText()
			local value = tonumber(self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText())
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
				if self.tItems["EPGP"].Enable == 1 then
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
						comment = "Add EP"
					elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
						comment = "Add GP"
					end
				else
					comment = "Add DKP"
				end
			end
			local ID = self:GetPlayerByIDByName(strName)
			if ID ~= -1  then
				if self.tItems["EPGP"].Enable == 0 then
				    if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(ktUndoActions["adddkp"],value,{[1] = self.tItems[ID]},nil,comment)  end
   				    local modifier = self.tItems[ID].net
					self.tItems[ID].net = self.tItems[ID].net + value
					self.tItems[ID].tot = self.tItems[ID].tot + value
					modifier = self.tItems[ID].net - modifier
					if self:LabelGetColumnNumberForValue("Net") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",self.tItems[ID].net))
					end
					if self:LabelGetColumnNumberForValue("Tot") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Tot"))):SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",self.tItems[ID].tot))
					end
					
					self:DetailAddLog(comment,"{DKP}",modifier,ID)
				else
					if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() and ktUndoActions["addgp"] or ktUndoActions["addep"],value,{[1] = self.tItems[ID]},nil,comment)  end
					local modEP = self.tItems[ID].EP
					local modGP = self.tItems[ID].GP
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() == true then
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPAdd(strName,value,value)
							self:DetailAddLog(comment,"{EP}",self.tItems[ID].EP - modEP,ID)
							self:DetailAddLog(comment,"{GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPAdd(strName,value,nil)
							self:DetailAddLog(comment,"{EP}",self.tItems[ID].EP - modEP,ID)
						end
					else 
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPAdd(strName,nil,value)
							self:DetailAddLog(comment,"{GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPAdd(strName,nil,nil)
							Print("Nothing added , check EP or GP in the controls box")
						end
					end					
					if self:LabelGetColumnNumberForValue("EP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("EP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].EP))
					end
					if self:LabelGetColumnNumberForValue("GP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].GP))
					end		
					if self:LabelGetColumnNumberForValue("RealGP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("RealGP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].GP - self.tItems["EPGP"].BaseGP))
					end
					if self:LabelGetColumnNumberForValue("PR") ~= -1 then
						if self.tItems[ID].GP ~= 0 then 
							self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f",self.tItems[ID].EP/self.tItems[ID].GP))
						else
							self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText("0")
						end
					end	
				
					
				end
				
			end
		else
			Print("Name Label is required")
		end
	else
		Print("You haven't selected any player")
	end

end

function DKP:SubtractDKP(cycling)
	if self.MassEdit == true and cycling ~= true then
		self:MassEditModify("Sub")
		return
	end
	Event_FireGenericEvent("ModifiedSomething")
	if self.wndSelectedListItem ~=nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText()
			local value = tonumber(self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText())
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			local ID = self:GetPlayerByIDByName(strName)
			if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
				if self.tItems["EPGP"].Enable == 1 then
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
						comment = "Subtract EP"
					elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
						comment = "Subtract GP"
					end
				else
					comment = "Subtract DKP"
				end
			end
			if ID ~= -1 then
				if self.tItems["EPGP"].Enable == 0 then
					if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(ktUndoActions["subdkp"],value,{[1] = self.tItems[ID]},nil,comment) end
					local modifier = self.tItems[ID].net
					self.tItems[ID].net = self.tItems[ID].net - value
					modifier = self.tItems[ID].net - modifier
					if self:LabelGetColumnNumberForValue("Net") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",self.tItems[ID].net))
					end
					
					self:DetailAddLog(comment,"{DKP}",modifier,ID)
				else
					if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() and ktUndoActions["subgp"] or ktUndoActions["subep"],value,{[1] = self.tItems[ID]},nil,comment)  end
					local modEP = self.tItems[ID].EP
					local modGP = self.tItems[ID].GP
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() == true then
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPSubtract(strName,value,value)
							self:DetailAddLog(comment,"{EP}",self.tItems[ID].EP - modEP,ID)
							self:DetailAddLog(comment,"{GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPSubtract(strName,value,nil)
							self:DetailAddLog(comment,"{EP}",self.tItems[ID].EP - modEP,ID)
						end
					else 
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPSubtract(strName,nil,value)
							self:DetailAddLog(comment,"{GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPSubtract(strName,nil,nil)
							Print("Nothing added , check EP or GP in the controls box")
						end
					end
					if self:LabelGetColumnNumberForValue("EP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("EP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].EP))
					end
					if self:LabelGetColumnNumberForValue("GP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].GP))
					end
					if self:LabelGetColumnNumberForValue("RealGP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("RealGP"))):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[ID].GP - self.tItems["EPGP"].BaseGP))
					end
					if self:LabelGetColumnNumberForValue("PR") ~= -1 then
						if self.tItems[ID].GP ~= 0 then 
							self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f",self.tItems[ID].EP/self.tItems[ID].GP))
						else
							self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText("0")
						end
					end					
					
				end
			end
			
			
				-- if cycling ~= true then
					-- self:ResetCommentBoxFull()
					-- self:ResetDKPInputBoxFull()
					-- self:ResetInputAndComment()
				-- end
		else
			Print("Name Label is required")
		end
	else
		Print("You haven't selected any player")
	end
end

function DKP:Add100DKP()
	Event_FireGenericEvent("ModifiedSomething")
	if self.tItems["EPGP"].Enable == 0 then
		local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
		if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
			if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
				comment = "Add EP (whole raid)"
			elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
				comment = "Add GP (whole raid)"
			end
		end
		local tMembers = {}
		for i=1,GroupLib.GetMemberCount() do
			local player = GroupLib.GetGroupMember(i)
			local ID = self:GetPlayerByIDByName(player.strCharacterName)
			
			if ID ~= -1 then
				if self.tItems["settings"].bTrackUndo then table.insert(tMembers,self.tItems[ID]) end 
				self.tItems[ID].net = self.tItems[ID].net + tonumber(self.tItems["settings"].dkp)
				self.tItems[ID].tot = self.tItems[ID].tot + tonumber(self.tItems["settings"].dkp)
				
				self:DetailAddLog(comment,"{DKP}",tostring(self.tItems["settings"].dkp),ID)
			end
		end
		self:ShowAll()
		if self.tItems["settings"].bTrackUndo and tMembers then self:UndoAddActivity(ktUndoActions["raward"],self.tItems["settings"].dkp,tMembers,nil,comment) end
	else
		local EP
		local GP
		if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then EP = self.tItems["settings"].dkp end
		if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then GP = self.tItems["settings"].dkp end
		self:EPGPAwardRaid(EP,GP)
	end
	self:EnableActionButtons()
end

function DKP:OnChatMessage(channelCurrent, tMessage)	
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Loot then 
		if strLocale == "enUS" then
			self:dbglog("---New PopUp Query---")
			local itemStr = ""
			local strName = ""
			local strTextLoot = ""
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextLoot = strTextLoot .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
			local bFound = false 
			local bMeetLevel = false
			local bMeetQual = false
			for word in string.gmatch(strTextLoot,"%S+") do
				table.insert(words,word)
			end
			
			if words[1] ~= "The"  then self:dbglog(">Query Fail > Reason: 'msg type check'") return end
	
			local collectingItem = true
			for i=5 , table.getn(words) do
				if words[i] == "to" then collectingItem = false end
				if collectingItem == true then
					itemStr = itemStr .." ".. words[i]
				elseif words[i] ~= "to" then
					strName = strName .. " " .. words[i]
				end
			end
			self:dbglog(string.format(">Query updated > %s > %s",strName,itemStr))
			
			for word in string.gmatch(string.sub(itemStr,2),"%S+") do
				for fWord in string.gmatch(self.tItems["settings"].strFilteredKeywords, '([^;]+)') do
					if self.tItems["settings"].strLootFiltering == "WL" then
						if string.lower(fWord) == string.lower(word) then bFound = true break end
					elseif self.tItems["settings"].strLootFiltering == "BL" then
						if string.lower(fWord) == string.lower(word) then self:dbglog(">Query Fail > Reason: 'Blacklisted'") return end
					end
				end
				if bFound then break end
			end
			self:dbglog(">Query passed > blacklist")

			if self.ItemDatabase and self.ItemDatabase[string.sub(itemStr,2)] then
				local item = Item.GetDataFromId(self.ItemDatabase[string.sub(itemStr,2)].ID)
				if item:GetDetailedInfo().tPrimary.nEffectiveLevel  >= self.tItems["settings"].nMinIlvl then bMeetLevel = true end
				bMeetQual = self.tItems["settings"].tFilterQual[self:EPGPGetQualityStringByID(item:GetItemQuality())]
				if not item:IsEquippable() and not bFound and self.tItems["settings"].FilterEquippable or not bMeetLevel and not bFound or not bFound and not bMeetQual then self:dbglog(">Query Fail > Reason: 'Filtered out'") return end
			elseif self.tItems["settings"].strLootFiltering == "WL" and not bFound then
				self:dbglog(">Query Fail > Reason: 'No item record + not whitelisted'")
				return
			end
		
			
			self:Bid2CloseOnAssign(string.sub(itemStr,2))
			strName = string.sub(strName,2)
			if not self.tItems["settings"].bLLAfterPopUp then self:LLAddLog(strName:sub(1, #strName - 1),string.sub(itemStr,2)) end

			if strName ~= "" and itemStr ~= "" then
				if self.tItems["settings"].PopupEnable == 1 then self:dbglog(">Query Success > Passed to pop-up ---Query End----") self:PopUpWindowOpen(strName:sub(1, #strName - 1),string.sub(itemStr,2)) end
			end
		elseif strLocale == "deDE" then
			local strItem = ""
			local strName = ""
			local strTextLoot = ""
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextLoot = strTextLoot .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
			local bFound = false
			for word in string.gmatch(strTextLoot,"%S+") do
				table.insert(words,word)
			end
			 if words[1] ~= "Der" then return end
			 strName = words[#words - 2] .. " " .. words[#words - 1]
			 for k=4,#words - 3 do
				strItem = strItem .. " " .. words[k]
			 end
			 
			for word in string.gmatch(string.sub(itemStr,2),"%S+") do
				for fWord in string.gmatch(self.tItems["settings"].strFilteredKeywords, '([^;]+)') do
					if self.tItems["settings"].strLootFiltering == "WL" then
						if string.lower(fWord) == string.lower(word) then bFound = true break end
					elseif self.tItems["settings"].strLootFiltering == "BL" then
						if string.lower(fWord) == string.lower(word) then return end
					end
				end
				if bFound then break end
			end
			
			if self.ItemDatabase[string.sub(itemStr,2)] then
				local item = Item.GetDataFromId(self.ItemDatabase[string.sub(itemStr,2)].ID)
				if item:GetDetailedInfo().tPrimary.nEffectiveLevel  >= self.tItems["settings"].nMinIlvl then bMeetLevel = true end
				bMeetQual = self.tItems["settings"].tFilterQual[self:EPGPGetQualityStringByID(item:GetItemQuality())]
				if not item:IsEquippable() and not bFound and self.tItems["settings"].FilterEquippable or not bMeetLevel and not bFound or not bFound and not bMeetQual then return end
			elseif self.tItems["settings"].strLootFiltering == "WL" and not bFound then
				return
			end
			 
		    strItem = string.sub(strItem,2)
			
			if self.tItems["settings"].FilterEquippable and self.ItemDatabase[strItem] then
				local item = Item.GetDataFromId(self.ItemDatabase[strItem].ID)
				if not item:IsEquippable() and not bFound then return end
			elseif not self.tItems["settings"].FilterEquippable and self.tItems["settings"].strLootFiltering == "WL" and not bFound then
				return
			end
			 
			 
			 if self.tItems["settings"].PopupEnable == 1 then self:PopUpWindowOpen(strName,strItem) end
			 self:Bid2CloseOnAssign(strItem)
			 if not self.tItems["settings"].bLLAfterPopUp then self:LLAddLog(strName,strItem) end
		end
	end
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper or channelCurrent:GetType() == ChatSystemLib.ChatChannel_Guild then
		if self.tItems["settings"].bRIEnable then
			if tMessage.arMessageSegments[1].strText == "!" .. self.tItems["settings"].strRIcmd then
				self:RIProcessInviteRequest(tMessage.strSender)
			end
		end
	end

	--[[if channelCurrent:GetType() == ChatSystemLib.ChatChannel_NPCSay and GroupLib.InRaid() then
		local strText = ""
		for i=1, table.getn(tMessage.arMessageSegments) do
			strText = strText .. tMessage.arMessageSegments[i].strText
		end
		if strText == "No! The convergence will be your doom!" then --Noxmind
			local tBosses = {}
			for k,event in ipairs(self.tItems["CE"]) do 
				if event.uType ~= "Unit" then table.insert(tBosses,{bType = event.bType,ID = k}) end
			end
			for k,boss in ipairs(tBosses) do
				if boss.bType ~= "Phageborn Convergence" then
					self:CETriggerEvent(boss.ID)
				end
			end
		end
	end]]
	if self.tItems["settings"].whisp == 1 then
		if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper then
			local senderStr = tMessage.strSender
			if string.lower(senderStr) == string.lower(GameLib.GetPlayerUnit():GetName()) then return end
			
			
			
			local segment = tMessage.arMessageSegments[1]
			local strMessage = segment.strText
			if strMessage=="!dkp" then
				local PlayerDKP 
				local PlayerTOT
				for i=1,table.maxn(self.tItems) do
					if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(senderStr) then
						PlayerDKP = self.tItems[i].net
						PlayerTOT = self.tItems[i].tot
						break	
					end
				end
				if PlayerDKP ~=nil then
					local strToSend = "/w " .. senderStr .. " Net:" .. PlayerDKP .. " Tot:" .. PlayerTOT 
					ChatSystemLib.Command( strToSend )
				else
					local strToSend = "/w " .. senderStr .." You don't have an account yet.You will get one once you join your first raid"
					ChatSystemLib.Command( strToSend )
				end
			elseif strMessage == "!ep" then
				local ID = self:GetPlayerByIDByName(senderStr)
				if ID ~= -1 then
					ChatSystemLib.Command("/w " .. senderStr .. " Your current EP is : " ..self.tItems[ID].EP)
				end
			elseif strMessage == "!gp" then
				local ID = self:GetPlayerByIDByName(senderStr)
				if ID ~= -1 then
					ChatSystemLib.Command("/w " .. senderStr .. " Your current GP is : " ..self.tItems[ID].GP)
				end
			elseif strMessage == "!pr" then
				ChatSystemLib.Command("/w " .. senderStr .. " Your current PR is : " .. self:EPGPGetPRByName(senderStr))
			elseif strMessage == "!top5" then
				local arr = {}
				for i=1,table.maxn(self.tItems) do
					if self.tItems[i]~= nil then
						table.insert(arr,{ID = i ,strName = self.tItems[i].strName, value = self.tItems["EPGP"].Enable == 1 and tonumber(self:EPGPGetPRByName(self.tItems[i].strName)) or tonumber(self.tItems[i].net)})
					end
				end
				table.sort(arr,compare_easyDKPRaidOps)
				local retarr = {}
				for k,entry in ipairs(arr) do
					table.insert(retarr,entry)
					if k == 5 then break end
				end
				for k , entry in ipairs(retarr) do
					if k > 5 then break end
					if self.tItems["EPGP"].Enable == 1 then
						ChatSystemLib.Command("/w " .. senderStr .. " " .. k ..". " .. self.tItems[entry.ID].strName .. "   PR:   " .. self:EPGPGetPRByName(entry.strName))
					else
						ChatSystemLib.Command("/w " .. senderStr .. " " .. k ..". " .. self.tItems[entry.ID].strName .. "   DKP:   " .. self.tItems[entry.ID].net)
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- DKPMain Functions
---------------------------------------------------------------------------------------------------
function DKP:InputBoxTextReset( wndHandler, wndControl, strText )
	local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
	local strDKP = wndCommentBox:GetText()
	if strText == "" then
		local wndInputBox = self.wndMain:FindChild("Controls"):FindChild("EditBox1")
		wndInputBox:SetText("Input Value")
	end
	if strText == "Input Value" or strText == "" then
		self:ResetInputAndComment()
	end
	if strDKP == "Comment" or strDKP == "" then
		self:ResetInputAndComment()
	end
	if tonumber(strText) then Event_FireGenericEvent("TypedInputValue") end
end

function compare_easyDKP(a,b)
	return a.value > b.value
end

--Old as heck
function DKP:EnableActionButtons( wndHandler, wndControl, strText )
	local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
	local wndInputBox = self.wndMain:FindChild("Controls"):FindChild("EditBox1")
	local val = tonumber(wndInputBox:GetText())

	
	if self.tItems["settings"].bAutoLog and wndCommentBox:GetText() == "Comment" then wndCommentBox:SetText("Comment - Auto") end
	local strComment = wndCommentBox:GetText()
	
	if val and strComment ~= "Comment" and self.wndSelectedListItem or val and strComment ~= "Comment" and #selectedMembers > 0 and self.MassEdit then
		self.wndMain:FindChild("ButtonSet"):Enable(true)
		self.wndMain:FindChild("ButtonAdd"):Enable(true)
		self.wndMain:FindChild("ButtonSubtract"):Enable(true)
	else 
		self:ResetInputAndComment()
	end
end

function DKP:ResetInputAndComment()
	self.wndMain:FindChild("Controls"):FindChild("ButtonSet"):Enable(false)
	self.wndMain:FindChild("Controls"):FindChild("ButtonAdd"):Enable(false)
	self.wndMain:FindChild("Controls"):FindChild("ButtonSubtract"):Enable(false)
end

function DKP:ResetCommentBox( wndHandler, wndControl, strText )
	if strText == "" then
		if not self.tItems["settings"].bAutoLog then
			self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment")
		else
			self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment - Auto")
		end
	end
end

function DKP:ResetCommentBoxFull( wndHandler, wndControl, strText )
	local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
	if self.tItems["settings"].logs == 1 then
		if not self.tItems["settings"].bAutoLog then
			self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment")
		else
			self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment - Auto")
		end
	else
		wndCommentBox:SetText("Comments Disabled")
	end
end
function DKP:ResetDKPInputBoxFull( wndHandler, wndControl, strText )
	self.wndMain:FindChild("Controls"):FindChild("EditBox1"):SetText("Input Value")
end

function DKP:CheckNameSpelling( wndHandler, wndControl, strText )
	if strText == "" then
		wndControl:SetText("Input New Entry Name")
	end
end

function DKP:ControlsAddPlayerByName( wndHandler, wndControl, eMouseButton )
	local strName = self.wndMain:FindChild("Controls"):FindChild("EditBoxPlayerName"):GetText()
	local counter = 0
	for word in string.gmatch(strName,"%S+") do
		counter = counter + 1
	end
	if counter ~= 2 then
		self.wndMain:FindChild("Controls"):FindChild("EditBoxPlayerName"):SetText("Input New Entry Name")
		return
	end

	self:OnUnitCreated(strName,true)
	self.wndMain:FindChild("Controls"):FindChild("EditBoxPlayerName"):SetText("Input New Entry Name")
	self:UndoAddActivity(ktUndoActions["addp"],"--",{[1] = self.tItems[self:GetPlayerByIDByName(strName)]},false)

end

function DKP:ReloadUI( wndHandler, wndControl, eMouseButton )
	ChatSystemLib.Command( "/reloadui" )
end

function DKP:ControlsSetQuickAdd( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["settings"].dkp = tonumber(strText)
		self:ControlsUpdateQuickAddButtons()
	else
		wndControl:SetText(self.tItems["settings"].dkp)
	end
end

function DKP:ControlsUpdateQuickAddButtons()
	self.wndMain:FindChild("Controls"):FindChild("QuickAddShortCut"):SetText(self.tItems["settings"].dkp)
end

---------------------------------------------------------------------------------------------------
-- Time Award
---------------------------------------------------------------------------------------------------

function DKP:TimedAwardShow( wndHandler, wndControl, eMouseButton )
	self.wndTimeAward:Show(true,false)
	self:TimeAwardRefresh()
end

function DKP:TimedAwardClose( wndHandler, wndControl, eMouseButton )
	self.wndTimeAward:Show(false,false)
end

function DKP:TimeAwardStop( wndHandler, wndControl, eMouseButton )
	if self.tItems["AwardTimer"].running == 1 then
		if self.tItems["AwardTimer"].amount ~= nil and self.tItems["AwardTimer"].period ~= nil then
			self.AwardTimer:Stop()
			Apollo.RemoveEventHandler("TimeAwardTimer", self)
			self.NextAward = nil
			self.tItems["AwardTimer"].running = 0
		end
	end
	self:TimeAwardRefresh()
end

function DKP:TimeAwardStart(bReset)
	if self.tItems["AwardTimer"].running == 0 and self.tItems["AwardTimer"].amount ~= nil and self.tItems["AwardTimer"].period ~= nil then
		Apollo.RegisterTimerHandler(1, "TimeAwardTimer", self)
		self.AwardTimer = ApolloTimer.Create(1, true, "TimeAwardTimer", self)
		if not self.NextAward then self.NextAward = self.tItems["AwardTimer"].period end
		self.tItems["AwardTimer"].running = 1
		if self.tItems["AwardTimer"].strTrigType == "Start" then self:TimeAwardAward() end
	end
	self:TimeAwardRefresh()
end

function DKP:TimeAwardRefresh()
	if self.tItems["AwardTimer"].running == 1 then
		self.wndTimeAward:FindChild("StateFrame"):FindChild("State"):SetSprite("achievements:sprAchievements_Icon_Complete")
		local diff =  os.date("*t",self.NextAward)
		if diff ~= nil then
			self.wndTimeAward:FindChild("CountDown"):SetText((diff.hour-1 <=9 and "0" or "" ) .. (diff.hour-1 < 0 and "0" or diff.hour-1) .. ":" .. (diff.min <=9 and "0" or "") .. diff.min .. ":".. (diff.sec <=9 and "0" or "") .. diff.sec)
		else
			self.wndTimeAward:FindChild("CountDown"):SetText("--:--:--")
		end
		self.wndMain:FindChild("TimeAwardIndicator"):Show(true,false)
	else
		self.wndTimeAward:FindChild("StateFrame"):FindChild("State"):SetSprite("ClientSprites:LootCloseBox_Holo")
		self.wndTimeAward:FindChild("CountDown"):SetText(self.Locale["#wndMain:TimedAward:Disabled"])
		self.wndMain:FindChild("TimeAwardIndicator"):Show(false,false)
	end
end

function DKP:TimeAwardRestore()
	if self.tItems["AwardTimer"] == nil then self.tItems["AwardTimer"] = {} end

	if self.tItems["AwardTimer"].running == 1 then
		if not self.NextAward then self.NextAward = self.tItems["settings"].period end
		self.tItems["AwardTimer"].running = 0
		self:TimeAwardStart(true)
	end
	if self.tItems["AwardTimer"].running == nil then 
		self.tItems["AwardTimer"].running = 0
	end
	
	if self.tItems["AwardTimer"].EP == true then
		self.wndTimeAward:FindChild("Settings"):FindChild("EP"):SetCheck(true)
	end
	
	if self.tItems["AwardTimer"].GP == true then
		self.wndTimeAward:FindChild("Settings"):FindChild("GP"):SetCheck(true)
	end
	
	if self.tItems["AwardTimer"].DKP == true then
		self.wndTimeAward:FindChild("Settings"):FindChild("DKP"):SetCheck(true)
	end
	
	if self.tItems["AwardTimer"].bScreenNotify then
		self.wndTimeAward:FindChild("Options"):FindChild("ScreenNotify"):SetCheck(true)
	end
	
	if self.tItems["AwardTimer"].Notify == 1 then
		self.wndTimeAward:FindChild("Options"):FindChild("Notify"):SetCheck(true)
	end

	self.wndTimeAward:FindChild("Queue"):SetCheck(self.tItems["AwardTimer"].bQueue)
	if not self.tItems["AwardTimer"].strTrigType then self.tItems["AwardTimer"].strTrigType = "End" end
	self.wndTimeAward:FindChild("Options"):FindChild(self.tItems["AwardTimer"].strTrigType):SetCheck(true)
	
	if self.tItems["AwardTimer"].amount ~= nil then self.wndTimeAward:FindChild("Settings"):FindChild("HowMuch"):SetText(self.tItems["AwardTimer"].amount) end
	if self.tItems["AwardTimer"].period ~= nil then self.wndTimeAward:FindChild("Settings"):FindChild("Period"):SetText(self.tItems["AwardTimer"].period) end
	self:TimeAwardRefresh()
end

function DKP:TimeAwardTimer()
	self:TimeAwardRefresh()
	if self.NextAward <= 0 then
		self:TimeAwardAward()
		self.NextAward = self.tItems["AwardTimer"].period
		if self.tItems["AwardTimer"].Notify == 1 then
			self:TimeAwardPostNotification()
		end
	else
		self.NextAward = self.NextAward - 1
	end
end

function DKP:TimeAwardAward()
	local raidMembers =  {}
	for i=1,GroupLib.GetMemberCount() do
		local unit_member = GroupLib.GetGroupMember(i)
		table.insert(raidMembers,unit_member.strCharacterName)
	end
	if self.tItems["AwardTimer"].bQueue then
		for k,queued in ipairs(self.tItems.tQueuedPlayers) do
			if self.tItems[queued] then 
				local bFound = false
				for k,member in ipairs(raidMembers) do if string.lower(member) == string.lower(self.tItems[queued].strName) then bFound = true break end end
				if not bFound then table.insert(raidMembers,self.tItems[queued].strName) end
			end
		end
	end
	local tMembers = {}
	if self.tItems["settings"].bTrackUndo  and self.tItems["settings"].bTrackTimedAwardUndo then	
		for k, member in ipairs(raidMembers) do
			local ID = self:GetPlayerByIDByName(member)
			if ID ~= -1  then
				table.insert(tMembers,self.tItems[ID])
			end
		end
		self:UndoAddActivity(ktUndoActions["taward"],self.tItems["AwardTimer"].amount,tMembers)
	end
	

	for k, member in ipairs(raidMembers) do
		local ID = self:GetPlayerByIDByName(member)
		if ID ~= -1 then
			if self.wndTimeAward:FindChild("Settings"):FindChild("EP"):IsChecked() then
				self.tItems[ID].EP = self.tItems[ID].EP + self.tItems["AwardTimer"].amount
				self:DetailAddLog("Timed Award","{EP}",self.tItems["AwardTimer"].amount,ID)
			end
			
			if self.wndTimeAward:FindChild("Settings"):FindChild("GP"):IsChecked() then
				self.tItems[ID].GP = self.tItems[ID].GP + self.tItems["AwardTimer"].amount
				self:DetailAddLog("Timed Award","{GP}",self.tItems["AwardTimer"].amount,ID)
			end
			
			if self.wndTimeAward:FindChild("Settings"):FindChild("DKP"):IsChecked() then
				self.tItems[ID].net = self.tItems[ID].net + self.tItems["AwardTimer"].amount
				self.tItems[ID].tot = self.tItems[ID].tot + self.tItems["AwardTimer"].amount
				self:DetailAddLog("Timed Award","{DKP}",self.tItems["AwardTimer"].amount,ID)
			end
		end
	end
	if self.wndNot and not self.wndNot:IsShown() and self.tItems["AwardTimer"].bScreenNotify then self:NotificationStart("Time Award granted.",5,2) end
	self:ShowAll()
end

function DKP:TimeAwardSetTrigType(wndHandler,wndControl)
	self.tItems["AwardTimer"].strTrigType = wndControl:GetName()
end

function DKP:TimeAwardSetAmount( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["AwardTimer"].amount = tonumber(strText)
	else
		wndControl:SetText("")
		self.tItems["AwardTimer"].amount = nil
	end
end

function DKP:TimeAwardPeriodChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["AwardTimer"].period = tonumber(strText)
		if self.NextAward ~= nil and self.NextAward > self.tItems["AwardTimer"].period then
			self.NextAward = self.tItems["AwardTimer"].period
			self:TimeAwardRefresh()
		end
	else
		wndControl:SetText("")
		self.tItems["AwardTimer"].period = nil
	end
end

function DKP:TimeAwardEnableScreenNotify( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].bScreenNotify = true
end

function DKP:TimeAwardDisableScreenNotify( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].bScreenNotify = false
end

function DKP:TimeAwardEnableNotification( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].Notify = 1
end

function DKP:TimeAwardDisableNotification( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].Notify = 0
end

function DKP:TimeAwardEnableQueue()
	self.tItems["AwardTimer"].bQueue = true
end

function DKP:TimeAwardDisableQueue()
	self.tItems["AwardTimer"].bQueue = false
end

function DKP:TimeAwardPostNotification()
	ChatSystemLib.Command("/party [RaidOps] Timed awards have been granted")
end
---------------------------------------------------------------------------------------------------
-- Mass Edit
---------------------------------------------------------------------------------------------------

function DKP:MassEditEnable( wndHandler, wndControl, eMouseButton )
	local selectedID
	if self.wndSelectedListItem then
		selectedID = self.wndSelectedListItem:GetData()
	end

	self.wndSelectedListItem = nil
	selectedMembers = {}
	self.MassEdit = true
	self:RefreshMainItemList()
	if selectedID then for k , child in ipairs(self:MainItemListGetChildren()) do if child:GetData() == selectedID then child:SetCheck(true) table.insert(selectedMembers,child) break end end end
	self.wndMain:FindChild("MassEditControls"):SetOpacity(1)
	self.wndMain:FindChild("MassEditControls"):Show(true,false)
	self:EnableActionButtons()
end

function DKP:MassEditDisable( wndHandler, wndControl, eMouseButton )
	self.wndSelectedListItem = nil
	self.MassEdit = false
	self:RefreshMainItemList()
	self.wndMain:FindChild("MassEditControls"):SetOpacity(0)
	self:delay(1,function(tContext) if not self.MassEdit then tContext.wndMain:FindChild("MassEditControls"):Show(false,false) end end)
	self:EnableActionButtons()
end

function DKP:MassEditSelectRaid( wndHandler, wndControl, eMouseButton )
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	selectedMembers = {}
	local children = self:MainItemListGetChildren()
	for k,child in ipairs(children) do
		if self:IsPlayerInRaid(child:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText()) then
			child:SetCheck(true)
			table.insert(selectedMembers,child)
		end
	end
end

local bInviteSuspend = false
function DKP:MassEditInvite()
	local strRealm = GameLib.GetRealmName()
	local strMsg = "Raid time!"
	local invitedIDs = {}
	for k,wnd in ipairs(selectedMembers) do
		if k >= 4 and not GroupLib.InRaid() then 
			bInviteSuspend = true
			break			
		end
		if wnd:GetData() and self.tItems[wnd:GetData()] then
			GroupLib.Invite(self.tItems[wnd:GetData()].strName,strRealm,strMessage)
			table.insert(invitedIDs,wnd:GetData())
		end
	end
	self:InviteOpen(invitedIDs)
end

function DKP:MassEditLL()
	if #selectedMembers == 0 then return end
	local tIDs = {}
	for k , wnd in ipairs(selectedMembers) do table.insert(tIDs,wnd:GetData()) end
	self:LLOpen(tIDs)
end

function DKP:MassEditCreditAtt()
	if not self.tOverrideFilter then
		local tIDs = {}
		for k , player in ipairs(selectedMembers) do
			table.insert(tIDs,player:GetData())
		end
		self:RSShow(true,tIDs)
	else
		local nTime = self.tItems.tRaids[self.nOverrideSource].finishTime
		for  k , wnd in ipairs(selectedMembers) do
			local player = self.tItems[wnd:GetData()]
			for j , att in ipairs(player.tAtt or {}) do
				if att.nTime == nTime then 
					table.remove(player.tAtt,j) 
					for i , id in ipairs(self.tOverrideFilter) do if id == wnd:GetData() then table.remove(self.tOverrideFilter,i) break end end
				end
			end
		end
		self:RefreshMainItemList()
	end
end

function DKP:MassEditInviteContinue()
	local strRealm = GameLib.GetRealmName()
	local strMsg = "Raid time!"
	local invitedIDs = {}
	for k,wnd in ipairs(selectedMembers) do
		if wnd:GetData() and self.tItems[wnd:GetData()] then
			GroupLib.Invite(self.tItems[wnd:GetData()].strName,strRealm,strMessage)
			table.insert(invitedIDs,wnd:GetData())
		end
	end
	self:InviteOpen(invitedIDs)
end

function DKP:MassEditInvert()
	local newSelectedMembers = {}
	local children = self:MainItemListGetChildren()
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	for k,child in ipairs(children) do
		local found = false
		for j,wnd in ipairs(selectedMembers) do
			if wnd == child then found = true break end
		end
		if not found then table.insert(newSelectedMembers,child) end
	end
	selectedMembers = newSelectedMembers
	newSelectedMembers = nil 
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(true)
	end
	self:UpdateItemCount()
	
end

function DKP:MassEditDeselect( wndHandler, wndControl, eMouseButton )
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	selectedMembers = {}
	self:UpdateItemCount()
end

function DKP:MassEditSelectConfirmed()
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	selectedMembers = {}
	for k,child in ipairs(self:MainItemListGetChildren()) do
		for k , strConfirmed in ipairs(self.tItems["settings"].tConfirmed) do
			if strConfirmed == self.tItems[child:GetData()].strName then
				table.insert(selectedMembers,child)
				child:SetCheck(true)
				break
			end
		end

	end

	self:UpdateItemCount()
end

function DKP:MassEditSelectAll( wndHandler, wndControl, eMouseButton )
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	selectedMembers = {}
	local children = self:MainItemListGetChildren()
	for k,child in ipairs(children) do
		table.insert(selectedMembers,child)
		child:SetCheck(true)
	end
	self:UpdateItemCount()
end

function DKP:MassEditRemove( wndHandler, wndControl, eMouseButton )
	self:RaidQueueClear()
	local tMembers = {}
	for k,wnd in ipairs(selectedMembers) do
		if wnd:GetData() and self.tItems[wnd:GetData()] then
			table.insert(tMembers,self.tItems[wnd:GetData()])
		end
	end
	self:UndoAddActivity(#tMembers == 1 and ktUndoActions["remp"] or ktUndoActions["mremp"],"--",tMembers,true)
	
	for k,wnd in ipairs(selectedMembers) do 
		local ID = self:GetPlayerByIDByName(wnd:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
		if ID ~= -1 then
			table.remove(self.tItems,ID)
		end
	end
	self:AltsBuildDictionary()
	self:RaidQueueRestore(save)
	self:RefreshMainItemList()
end

function DKP:MassEditModify(what) -- "Add" "Sub" "Set" 
	--we're gonna just change self.wndSelectedListItem and call the specific function
	local tMembers = {}
	local strType
	for k,wnd in ipairs(selectedMembers) do
		local player = self.tItems[wnd:GetData()]
		table.insert(tMembers,player)
	end
		local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
		if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
			if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
				if what == "Add" then
					comment = "Add EP"
				elseif what == "Sub" then
					comment = "Subtract EP"
				elseif what == "Set" then
					comment = "Set EP"
				end
			elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
				if what == "Add" then
					comment = "Add GP"
				elseif what == "Sub" then
					comment = "Subtract GP"
				elseif what == "Set" then
					comment = "Set GP"
				end
			elseif self.tItems["EPGP"].Enable == 0 then
				if what == "Add" then
					comment = "Add DKP"
				elseif what == "Sub" then
					comment = "Subtract DKP"
				elseif what == "Set" then
					comment = "Set DKP"
				end
			end
		end


	if what == "Add" then
		if self.tItems["EPGP"].Enable == 0 then
		strType = ktUndoActions["madddkp"]
		else
			if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then 
				strType = ktUndoActions["maddgp"] 
			else
				strType = ktUndoActions["maddep"]
			end
		end

		
		if tMembers then self:UndoAddActivity(strType,self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText(),tMembers,nil,comment) end 
		
		for i,wnd in ipairs(selectedMembers) do
			self.wndSelectedListItem = wnd
			self:AddDKP(true) -- information to function not to cause stack overflow
		end	
	elseif what == "Sub" then
		if self.tItems["EPGP"].Enable == 0 then
			strType = ktUndoActions["msubdkp"]
		else
			if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then 
				strType = ktUndoActions["msubgp"] 
			else
				strType = ktUndoActions["msubep"]
			end
		end
		
		if tMembers then self:UndoAddActivity(strType,self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText(),tMembers,nil,comment) end 
		
		for i,wnd in ipairs(selectedMembers) do
			if self.tItems["settings"].bTrackUndo and wnd:GetData() then table.insert(tMembers,self.tItems[wnd:GetData()]) end
			self.wndSelectedListItem = wnd
			self:SubtractDKP(true) 
		end
	elseif what == "Set" then
		if self.tItems["EPGP"].Enable == 0 then
			strType = ktUndoActions["msetdkp"]
		else
			if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then 
				strType = ktUndoActions["msetgp"] 
			else
				strType = ktUndoActions["msetep"]
			end
		end		
		
		if tMembers then self:UndoAddActivity(strType,self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText(),tMembers,nil,comment) end 
		
		for i,wnd in ipairs(selectedMembers) do
			if self.tItems["settings"].bTrackUndo and wnd:GetData() then table.insert(tMembers,self.tItems[wnd:GetData()]) end
			self.wndSelectedListItem = wnd
			self:SetDKP(true) 
		end
	end
end
function DKP:MassEditItemSelected( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	table.insert(selectedMembers,wndControl)
	self:UpdateItemCount()
	self:EnableActionButtons()
end

function DKP:MassEditItemDeselected( wndHandler, wndControl, eMouseButton)
	for i,wnd in ipairs(selectedMembers) do
		if wnd == wndControl then 
			table.remove(selectedMembers,i) 
			break
		end
	end
	self:UpdateItemCount()
	self:EnableActionButtons()
end

function DKP:StartOnlineRefreshTimer()
	self.OnlineRefreshTimer = ApolloTimer.Create(10, true, "OnlineUpdate", self)
	Apollo.RegisterTimerHandler(10, "OnlineUpdate", self)
end

function DKP:StopOnlineRefreshTimer()
	self.OnlineRefreshTimer = nil
	Apollo.RemoveEventHandler("OnlineUpdate", self)
end

function DKP:OnlineUpdate()
	self:ImportFromGuild()
end

function DKP:ConvertDate(strDate)
	if self.tItems["settings"].strDateFormat == "EU" then
		local words = {}
		for word in string.gmatch(strDate,"([^/]+)") do
			table.insert(words,word)
		end

		return words[2] .. "/" .. words[1] .. "/" .. words[3]
	else
		return strDate
	end
end

function DKP:GetOnlinePlayers()
	local tOnlineMembers = {}
	for k,player in ipairs(tGuildRoster) do
		if player.fLastOnline == 0 then 
			local strNewName = ""
			for uchar in string.gfind(player.strName, "([%z\1-\127\194-\244][\128-\191]*)") do
				if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
				strNewName = strNewName .. uchar
			end
			table.insert(tOnlineMembers,strNewName) 
		end
	end
	return tOnlineMembers
end

function DKP:IsPlayerOnline(tPlayers,strPlayer)
	for k,player in ipairs(tPlayers) do
		if player == strPlayer then return true end
	end
	return false
end

function DKP:IsPlayerRoleDesired(strRole)
	if strRole == "DPS" and self.wndMain:FindChild("ShowDPS"):IsChecked() then return true end
	if strRole == "Heal" and self.wndMain:FindChild("ShowHeal"):IsChecked() then return true end
	if strRole == "Tank" and self.wndMain:FindChild("ShowTank"):IsChecked() then return true end
	return false
end

function DKP:AddFilterRule(tIDs,nSource)
	self.tOverrideFilter = tIDs
	self.nOverrideSource = nSource -- Raid ID
	self:RefreshMainItemList()
	self.wndMain:FindChild("FilterAlert"):Show(true)
end

function DKP:ClearFilterRule()
	self.tOverrideFilter = nil
	self.nOverrideSource = nil
	self:RefreshMainItemList()
	self.wndMain:FindChild("FilterAlert"):Show(false)
end

function DKP:MainItemListGetChildren()
	local children = self.wndItemList:GetChildren()
	for k , child in ipairs(children) do
		if string.find(child:GetName(),"Group") then children[k] = nil end
	end
	return children
end

function DKP:RefreshMainItemList()
	local tIDs = self.tOverrideFilter
	self.nHScroll = self.wndItemList:GetVScrollPos()
	if self.tItems["settings"].GroupByClass then self:RefreshMainItemListAndGroupByClass() return end
	local selectedPlayer = ""
	if self:LabelGetColumnNumberForValue("Name") > 0 then
		if self.MassEdit then
			selectedPlayer = {}
			for k,player in ipairs(selectedMembers) do
				--for k,wnd in ipairs(player:GetChildren()) do Print(wnd:GetName()) end
				table.insert(selectedPlayer,player:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
			end
		elseif self.wndSelectedListItem and self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name"))  then
			selectedPlayer = self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText()
		end
	end
	selectedMembers = {}
	self.wndSelectedListItem = nil
	self.wndItemList:DestroyChildren()
	local nameLabel = self:LabelGetColumnNumberForValue("Name")
	local tOnlineMembers
	if self.wndMain:FindChild("OnlineOnly"):IsChecked() then tOnlineMembers = self:GetOnlinePlayers() end
	-- For groups sake we need to wrap this thing once more
	if #self.tItems["settings"].Groups > 0 then -- provided that there's something to care about
		-- prepare free IDs
	end
	-- Main display mechanism = tons of condition checks
	for i , group in ipairs((#self.tItems["settings"].Groups > 0 and self.tItems["settings"].bEnableGroups) and self.tItems["settings"].Groups or {[1] = {tIDs = "all"}}) do -- wrapped in one more for loop to create groups those ppl in groups
		if group.tIDs ~= "all" then
			local wndGroupBar = Apollo.LoadForm(self.xmlDoc,"ListItemGroupBar",self.wndItemList,self)
			wndGroupBar:FindChild("GroupName"):SetText(group.strName)
			wndGroupBar:FindChild("Expand"):SetCheck(group.bExpand)
			wndGroupBar:SetData(i)
		end
		if group.bExpand or group.tIDs == "all" then
			for k , player in ipairs(type(tIDs) == "table" and tIDs or self.tItems) do
				local playerId = type(tIDs) == "table" and player or k
				local bFound = true
				if group.tIDs ~= "all" then -- if there's group
					bFound = false
					for j , id in ipairs(group.tIDs) do
						if id == playerId then bFound = true break end
					end
				end
				if type(tIDs) == "table" then player = self.tItems[player] end
				if player.strName ~= "Guild Bank" and bFound then
					if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
						if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInQueue(player.strName) then
							if not self.wndMain:FindChild("OnlineOnly"):IsChecked() or self.wndMain:FindChild("OnlineOnly"):IsChecked() and self:IsPlayerOnline(tOnlineMembers,player.strName) then
								if self:IsPlayerRoleDesired(player.role) then
									if self.tItems["settings"].bHideStandby and not self.tItems["Standby"][string.lower(player.strName)] or not self.tItems["settings"].bHideStandby then	
										if not self.MassEdit then
											player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
										else
											player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
										end
										--Creating player's window
										self:UpdateItem(player)

										if not self.MassEdit then
											if player.strName == selectedPlayer then
												self.wndSelectedListItem = player.wnd
												player.wnd:SetCheck(true)	
											end
										else
											local found = false
											
											for k,prevPlayer in ipairs(selectedPlayer) do
												if prevPlayer == player.strName then
													found = true
													break
												end
											end
											if found then
												table.insert(selectedMembers,player.wnd)
												player.wnd:SetCheck(true)
											end
											
										end
										player.wnd:SetData(playerId)
									end
								end
							end
						end
					end
				end
			end
		end
	end
	self:RaidQueueShow()
	self.wndItemList:ArrangeChildrenVert(0,easyDKPSortPlayerbyLabel)
	if self.tItems["settings"].bDisplayCounter then
		for k,child in ipairs(self:MainItemListGetChildren()) do
			child:FindChild("Counter"):Show(true)
			child:FindChild("Counter"):SetText(k..".")
		end
	end
	self.wndItemList:SetVScrollPos(self.nHScroll)
	self:UpdateItemCount()
end

function DKP:IsPlayerInRaid(strPlayer)
	local raidPre = self:Bid2GetTargetsTable()
	local raid = {}
	for k,player in ipairs(raidPre) do
		local strNewPlayer = ""
		for uchar in string.gfind(player, "([%z\1-\127\194-\244][\128-\191]*)") do
			if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
			strNewPlayer = strNewPlayer .. uchar
		end
		table.insert(raid,strNewPlayer)
	end
	
	
	for k,player in ipairs(raid) do
		for j,alt in pairs(self.tItems["alts"]) do
			if string.lower(j) == string.lower(player) then
				raid[k] = self.tItems[alt].strName
				break
			end
		end
	end
	table.insert(raid,GameLib.GetPlayerUnit():GetName())
	for k,player in ipairs(raid) do
		if string.lower(strPlayer) == string.lower(player) then return true end
	end
	return false
end

function DKP:UpdateItem(playerItem,k,bAddedClass)
	if playerItem.wnd == nil then return end
	-- Alt check
	playerItem.alt = nil
	if self.wndMain:FindChild("RaidOnly"):IsChecked() then
		local raid = self:Bid2GetTargetsTable()
		for j,alt in ipairs(playerItem.alts) do
			for i,raider in ipairs(raid) do
				if string.lower(alt) == string.lower(raider) then 
					playerItem.alt = alt 
					break
				end
			end
			if playerItem.alt then break end
		end
	end

	local nStats = 0
	for k , child in ipairs(playerItem.wnd:GetChildren()) do
		if string.find(child:GetName(),"Stat") then nStats = nStats + 1 end
	end


	if nStats < self.currentLabelCount then
		for k=1,self.currentLabelCount - nStats do

			local wndLastStat = playerItem.wnd:FindChild("Stat5")
			local nLastStat = 5
			for k , child in ipairs(playerItem.wnd:GetChildren()) do
				if string.find(child:GetName(),"Stat") and child:IsShown() and tonumber(string.sub(child:GetName(),5)) > nLastStat then 
					nLastStat = tonumber(string.sub(child:GetName(),5))
					wndLastStat = child 
				end
			end
			local wndStat = playerItem.wnd:FindChild("Stat"..nLastStat+1)
			if not wndStat then
				wndStat = Apollo.LoadForm(self.xmlDoc,"StatX",playerItem.wnd,self)
				local l,t,r,b = wndLastStat:GetAnchorOffsets()
				wndStat:SetName("Stat"..nLastStat+1)
				wndStat:SetAnchorOffsets(l + knLabelWidth + knLabelSpacing,t,r + knLabelSpacing + knLabelWidth ,b)
			else
				wndStat:Show(true)
			end
		end
	else
		for k=5,9 do --max 9 labels 
			if k > self.currentLabelCount then
				if playerItem.wnd:FindChild("Stat"..k) then playerItem.wnd:FindChild("Stat"..k):Show(false) end
			end
		end
	end



	if self.tItems["settings"].GroupByClass then
		if k and k == 1 or bAddedClass == false then playerItem.wnd:FindChild("NewClass"):Show(true,false) end
	end

	local nGAs = 0
	local nDSs = 0
	local nYs = 0
	local totalRaids = self.tItems.tRaids and #self.tItems.tRaids or 0

	for k, raid in ipairs(self.tItems.tRaids or {}) do
		if raid.raidType == RAID_GA then nGAs = nGAs + 1
		elseif raid.raidType == RAID_DS then nDSs = nDSs + 1
		elseif raid.raidType == RAID_Y then nYs = nYs + 1
		end
	end


	for i=1,self.currentLabelCount do
		if self.tItems["settings"].LabelOptions[i] ~= "Nil" then
			if self.tItems["settings"].LabelOptions[i] == "Name" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.strName)
				if i ~= 1 then
					local wnd = playerItem.wnd:FindChild("Stat"..i)
					local l,t,r,b = wnd:GetAnchorOffsets()
					wnd:SetAnchorOffsets(l-20,t,r+20,b)
				end
			elseif self.tItems["settings"].LabelOptions[i] == "Net" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",playerItem.net))
			elseif self.tItems["settings"].LabelOptions[i] == "Tot" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..self.tItems["settings"].nPrecisionDKP.."f",playerItem.tot))
			elseif self.tItems["settings"].LabelOptions[i] == "Raids" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.raids or "0")
			elseif self.tItems["settings"].LabelOptions[i] == "Item" then
				if playerItem.tLLogs and #playerItem.tLLogs > 0 then
					local itemID 
					local counter = 1
					local item
					while not itemID do
						if playerItem.tLLogs[counter] then
							item = Item.GetDataFromId(playerItem.tLLogs[counter].itemID)
							if self.tItems["settings"].bUseFilterForItemLabel then
								if self:LLMeetsFilters(item,playerItem,playerItem.tLLogs[counter].nGP) then
									itemID = playerItem.tLLogs[counter].itemID
								end
							else
								itemID = playerItem.tLLogs[counter].itemID
							end
						end
						if counter > #playerItem.tLLogs then
							itemID = 'lol'
						end
						counter = counter + 1
					end
					item = Item.GetDataFromId(itemID)
					if item then
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
						local wnd = Apollo.LoadForm(self.xmlDoc,"LoadIconToStat",playerItem.wnd:FindChild("Stat"..tostring(i)),self)
						wnd:SetSprite(item:GetIcon())
						wnd:SetData(item)
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetText("")
						local l,t,r,b = playerItem.wnd:FindChild("Stat"..tostring(i)):GetAnchorOffsets()
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetAnchorOffsets(l+32.5,t,r-32.5,b)
						Tooltip.GetItemTooltipForm(self,wnd, item  ,{bPrimary = true, bSelling = false})
					end
				end
			elseif self.tItems["settings"].LabelOptions[i] == "Hrs" then
				local nSecs = 0
				for k ,tAtt in ipairs(playerItem.tAtt or {}) do
					nSecs = nSecs + tAtt.nSecs
				end
				if nSecs > 0 then
					nSecs = nSecs / 3600
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%.4f",nSecs))
				else
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(0)
				end
			elseif self.tItems["settings"].LabelOptions[i] == "Spent" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(tonumber(playerItem.tot)-tonumber(playerItem.net))
			elseif self.tItems["settings"].LabelOptions[i] == "Priority" then
				if tonumber(playerItem.tot)-tonumber(playerItem.net) ~= 0 then
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f",tonumber(playerItem.tot)/(tonumber(playerItem.tot)-tonumber(playerItem.net))))
				else
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText("0")
				end
			elseif self.tItems["settings"].LabelOptions[i] == "EP" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",playerItem.EP))
			elseif self.tItems["settings"].LabelOptions[i] == "GP" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",playerItem.GP))
			elseif self.tItems["settings"].LabelOptions[i] == "PR" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(self:EPGPGetPRByName(playerItem.strName))
			elseif self.tItems["settings"].LabelOptions[i] == "RealGP" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",playerItem.GP - self.tItems["EPGP"].BaseGP))
			--Att
			elseif self.tItems["settings"].LabelOptions[i] == "%GA" then
				local raidCount = 0
				for k , att in ipairs(playerItem.tAtt or {}) do
					if att.raidType == RAID_GA then raidCount = raidCount + 1 end
				end
				playerItem.wnd:FindChild("Stat"..i):SetText(raidCount == 0 and "--" or (nGAs > 0 and string.format("%.2f",(raidCount*100)/nGAs).. "%" or "--"))
			elseif self.tItems["settings"].LabelOptions[i] == "%DS" then
				local raidCount = 0
				for k , att in ipairs(playerItem.tAtt or {}) do
					if att.raidType == RAID_DS then raidCount = raidCount + 1 end
				end
				playerItem.wnd:FindChild("Stat"..i):SetText(raidCount == 0 and "--" or (nDSs > 0 and  string.format("%.2f",(raidCount*100)/nDSs).. "%" or "--"))
			elseif self.tItems["settings"].LabelOptions[i] == "%Y" then
				local raidCount = 0
				for k , att in ipairs(playerItem.tAtt or {}) do
					if att.raidType == RAID_Y then raidCount = raidCount + 1 end
				end
				playerItem.wnd:FindChild("Stat"..i):SetText(raidCount == 0 and "--" or (nYs > 0 and  string.format("%.2f",(raidCount*100)/nYs).. "%" or "--"))
			elseif self.tItems["settings"].LabelOptions[i] == "%Total" then
				local raidCount = playerItem.tAtt and #playerItem.tAtt or 0
				if totalRaids > 0 then
					playerItem.wnd:FindChild("Stat"..i):SetText(string.format("%.2f",(raidCount*100)/totalRaids).."%")
				else
					playerItem.wnd:FindChild("Stat"..i):SetText("--")
				end
			elseif self.tItems["settings"].LabelOptions[i] == "GA" then
				local raidCount = 0
				for k , att in ipairs(playerItem.tAtt or {}) do
					if att.raidType == RAID_GA then raidCount = raidCount + 1 end
				end
				playerItem.wnd:FindChild("Stat"..i):SetText(raidCount .. " / " .. nGAs)
			elseif self.tItems["settings"].LabelOptions[i] == "DS" then
								local raidCount = 0
				for k , att in ipairs(playerItem.tAtt or {}) do
					if att.raidType == RAID_DS then raidCount = raidCount + 1 end
				end
				playerItem.wnd:FindChild("Stat"..i):SetText(raidCount .. " / " .. nDSs)
			elseif self.tItems["settings"].LabelOptions[i] == "Y" then
				local raidCount = 0
				for k , att in ipairs(playerItem.tAtt or {}) do
					if att.raidType == RAID_Y then raidCount = raidCount + 1 end
				end
				playerItem.wnd:FindChild("Stat"..i):SetText(raidCount .. " / " .. nYs)
			elseif self.tItems["settings"].LabelOptions[i] == "Total" then
				local raidCount = playerItem.tAtt and #playerItem.tAtt or 0
				if totalRaids > 0 then
					playerItem.wnd:FindChild("Stat"..i):SetText(raidCount.. " / " .. totalRaids)
				else
					playerItem.wnd:FindChild("Stat"..i):SetText("0 / 0")
				end
				
			end
		end
		if self.SortedLabel and i == self.SortedLabel then playerItem.wnd:FindChild("Stat"..i):SetTextColor("ChannelAdvice") else playerItem.wnd:FindChild("Stat"..i):SetTextColor("white") end
	end
	local wndClassIcon = self.tItems["settings"].bColorIcons and playerItem.wnd:FindChild("ClassIconBigger") or playerItem.wnd:FindChild("ClassIcon")
	if playerItem.class then 
		wndClassIcon:SetSprite(ktStringToIcon[playerItem.class])
		wndClassIcon:Show(true,false)
	else 
		playerItem.wnd:FindChild("ClassIcon"):Show(false,false) 
		playerItem.wnd:FindChild("ClassIconBigger"):Show(false,false) 
	end
	if self.tItems["settings"].bDisplayRoles and playerItem.role then playerItem.wnd:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[playerItem.role]) else playerItem.wnd:FindChild("RoleIcon"):Show(false) end
	if playerItem.alt then
		playerItem.wnd:FindChild("Alt"):SetTooltip("Playing as : " .. playerItem.alt)
		playerItem.wnd:FindChild("Alt"):Show(true,false)
	end
	if self.tItems["settings"].bRIEnable then
		for k , strConfirmed in ipairs(self.tItems["settings"].tConfirmed) do
			if playerItem.strName == strConfirmed then
				playerItem.wnd:FindChild("Confirmation"):Show(true)
			end
		end
	end
end

function DKP:LabelFireContextMenuForItemLabel(wndHandler,wndControl,eMouseButton)
	if wndHandler ~= wndControl or  eMouseButton ~= GameLib.CodeEnumInputMouse.Right  then return end
	Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndControl:GetData())
end

---------------------------------------------------------------------------------------------------
-- wndMain resize logic
---------------------------------------------------------------------------------------------------

local prevWidth

function DKP:MresInit()
	self.wndLabelBar = self.wndMain:FindChild("LabelBar")
	self.currentLabelCount = 5
	local nLabelsToRender 
	
	prevWidth = self.wndMain:GetWidth()
	if prevWidth <= 1060 then 
		nLabelsToRender = 5
	else
		local nAddWidth = prevWidth - 1057
		if nAddWidth / (knLabelSpacing+knLabelWidth) >= 1 then
			nLabelsToRender = math.floor(nAddWidth / (knLabelSpacing+knLabelWidth)) + 5
		else
			nLabelsToRender = 5
		end
	end
	for k=5,nLabelsToRender do
		self:MresRenderLabels(k)
	end
end

function DKP:MresOnResize()
	if prevWidth ~= self.wndMain:GetWidth() then 
			Event_FireGenericEvent("MresResized")
			prevWidth = self.wndMain:GetWidth()
			if prevWidth <= 1060 then 
				nLabelsToRender = 5
			else
				local nAddWidth = prevWidth - 1050
				if nAddWidth / (knLabelSpacing+knLabelWidth) >= 1 then
					nLabelsToRender = math.floor(nAddWidth / (knLabelSpacing+knLabelWidth)) + 5
				else
					nLabelsToRender = 5
				end
			end
	end
	self:MresRenderLabels(nLabelsToRender)
end

function DKP:MresRenderLabels(nCount)
	if nCount and nCount ~= self.currentLabelCount then
		nCount = nCount
		if nCount > self.currentLabelCount then
			local wndLastLabel = self.wndLabelBar:FindChild("Label5")
			local nLastLabel = 5
			for k , child in ipairs(self.wndLabelBar:GetChildren()) do
				if child:GetName() ~= "Button" and child:IsShown() and tonumber(string.sub(child:GetName(),6)) > nLastLabel then 
					nLastLabel = tonumber(string.sub(child:GetName(),6))
					wndLastLabel = child 
				end
			end
			local wndLabel = self.wndLabelBar:FindChild("Label"..nLastLabel+1)
			if not wndLabel then
				wndLabel = Apollo.LoadForm(self.xmlDoc,"LabelX",self.wndLabelBar,self)

				local l,t,r,b = wndLastLabel:GetAnchorOffsets()
				wndLabel:SetName("Label"..nLastLabel+1)
				wndLabel:SetText(self.tItems["settings"].LabelOptions[nLastLabel+1])
				wndLabel:SetAnchorOffsets(l + knLabelWidth + knLabelSpacing,t,r + knLabelSpacing + knLabelWidth ,b)
				if not self.tItems["settings"].LabelOptions[nLastLabel+1] then self.tItems["settings"].LabelOptions[nLastLabel+1] = "Nil" end
				wndLabel:SetText(self.tItems["settings"].LabelOptions[nLastLabel+1])
			else
				wndLabel:Show(true)
			end
		else	
			for k=5,9 do --max 9 labels 
				if k > nCount then
					if self.wndLabelBar:FindChild("Label"..k) then self.wndLabelBar:FindChild("Label"..k):Show(false) end
				end
			end
		end
		local bHidden = false
		for k=5,9 do --max 9 labels 
			if k > nCount then
				if self.tItems["settings"].LabelOptions[k] ~= "Nil" then
					bHidden = true
				end
			end
		end
		self.wndMain:FindChild("HiddenColumns"):Show(bHidden)
		self.currentLabelCount = nCount
		self:RefreshMainItemList()
	end
end



---------------------------------------------------------------------------------------------------
-- Label Setting
---------------------------------------------------------------------------------------------------
local ktDefaultProfiles =
{
	[1] = 
	{
		[1] = "Name",
		[2] = "EP",
		[3] = "GP",
		[4] = "PR",
		[5] = "Item",
		[6] = "Nil",
		[7] = "Nil",
		[8] = "Nil",
		[9] = "Nil",
	},
	[2] = 
	{
		[1] = "Name",
		[2] = "%GA",
		[3] = "%DS",
		[4] = "%Y",
		[5] = "%Total",
		[6] = "GA",
		[7] = "DS",
		[8] = "Y",
		[9] = "Total",
	},
}


function DKP:LabelInit()
	self.wndLabelMenu = Apollo.LoadForm(self.xmlDoc,"LabelSelection",nil,self)
	self.wndLabelMenu:Show(false)

	if not self.tItems["settings"].nLabelProfile then self.tItems["settings"].nLabelProfile = 1 end
	if not self.tItems["settings"].tLabelProfiles then 
		self.tItems["settings"].tLabelProfiles = ktDefaultProfiles 
		if self.tItems["settings"].LabelOptions then self.tItems["settings"].tLabelProfiles[1] = self.tItems["settings"].LabelOptions end
	end

	self.tItems["settings"].LabelOptions = self.tItems["settings"].tLabelProfiles[self.tItems["settings"].nLabelProfile]
	self.wndMain:FindChild("Prof"..self.tItems["settings"].nLabelProfile):SetCheck(true)
	
	self:LabelUpdateList()
	if not self.currentLabelCount then self:MresOnResize() end
end

function DKP:LabelProfileChanged(wndHandler,wndControl)
	self.tItems["settings"].nLabelProfile = tonumber(wndControl:GetText())
	self.tItems["settings"].LabelOptions = self.tItems["settings"].tLabelProfiles[self.tItems["settings"].nLabelProfile]
	self.SortedLabel = nil
	self:LabelHideIndicators()
	self:LabelUpdateList()
end

function DKP:LabelMenuOpen(wndHandler,wndControl)
	if not string.find(wndControl:GetName(),"Label") then return end
	local tCursor = Apollo.GetMouse()
	self.wndLabelMenu:Move(tCursor.x - 50, tCursor.y + 30, self.wndLabelMenu:GetWidth(), self.wndLabelMenu:GetHeight())
	Event_FireGenericEvent("LabelSelectionOpen")
	self.wndLabelMenu:Show(true,false)
	self.wndLabelMenu:ToFront()
	self.CurrentlyEditedLabel = tonumber(string.sub(wndControl:GetName(),6))
end

function DKP:LabelMenuHide()
	self.wndLabelMenu:Show(false,false)
end

function DKP:LabelCheckType( wndHandler, wndControl, eMouseButton )
	if self.CurrentlyEditedLabel ~= nil then

		for i=1,self.currentLabelCount do
			if self.tItems["settings"].LabelOptions[i] == wndControl:GetName() then
				 self.tItems["settings"].LabelOptions[i] = "Nil"
				 if self.SortedLabel == i then self.SortedLabel = self.CurrentlyEditedLabel end

			end
		end
		self.tItems["settings"].tLabelProfiles[self.tItems["settings"].nLabelProfile][self.CurrentlyEditedLabel] = wndControl:GetName()
		self.tItems["settings"].LabelOptions[self.CurrentlyEditedLabel] = wndControl:GetName()
	end
	if self.SortedLabel == self:LabelGetColumnNumberForValue("Item") then self.SortedLabel = nil end
	if self.tItems["settings"].LabelOptions[self.SortedLabel] == "Nil" then self.SortedLabel = nil end

	Event_FireGenericEvent("LabelChanged")


	self:LabelUpdateList()
	self:LabelHideIndicators()
end

function DKP:LabelUpdateList() 
	-- Label Bar first
	for i=1,self.currentLabelCount do
		if not self.tItems["settings"].LabelOptions[i] then self.tItems["settings"].LabelOptions[i] = "Nil" end
		self.wndLabelBar:FindChild("Label"..tostring(i)):Show(true,false)
		self.wndLabelBar:FindChild("Label"..tostring(i)):SetText(self.tItems["settings"].LabelOptions[i])
		self.wndLabelBar:FindChild("Label"..tostring(i)):SetTooltip(self:LabelAddTooltipByValue(self.tItems["settings"].LabelOptions[i]))

		if self.SortedLabel and self.SortedLabel == i then
			self.wndLabelBar:FindChild("Label"..tostring(i)):FindChild("SortIndicator"):Show(true)
		end
	end
	-- Check for priority sorting
	self:RefreshMainItemList()

end

function DKP:LabelAddTooltipByValue(value)
	return self.Locale["#LabelTooltips:"..value]
end

function DKP:LabelGetColumnNumberForValue(value)
	for i=1,self.currentLabelCount or 9 do
		if self.tItems["settings"].LabelOptions[i] == value then return i end
	end
	return -1
end

function easyDKPSortPlayerbyLabel(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if DKPInstance.SortedLabel then
		local sortBy = DKPInstance.tItems["settings"].LabelOptions[DKPInstance.SortedLabel]
		local label = "Stat"..DKPInstance.SortedLabel
		if a:FindChild(label) and b:FindChild(label) then
			local val1 = tonumber(a:FindChild(label):GetText())
			local val2 = tonumber(b:FindChild(label):GetText())
			if not val1 then val1 = tonumber(string.sub(a:FindChild(label):GetText(),1,#a:FindChild(label):GetText()-1)) end
			if not val2 then val2 = tonumber(string.sub(b:FindChild(label):GetText(),1,#b:FindChild(label):GetText()-1)) end
			if DKPInstance.tItems["settings"].LabelSortOrder == "asc" then
				if not val1 or not val2 then return a:FindChild(label):GetText() > b:FindChild(label):GetText() end
				if sortBy ~= "Name" then
					return val1 > val2
				elseif sortBy ~= "Item" then
					return a:FindChild(label):GetText() > b:FindChild(label):GetText()
				end
			else
				if not val1 or not val2 then return a:FindChild(label):GetText() < b:FindChild(label):GetText() end
				if sortBy ~= "Name" then
					return val1 < val2
				elseif sortBy ~= "Item" then
					return a:FindChild(label):GetText() < b:FindChild(label):GetText()
				end
			end
		end
	end
end

function easyDKPSortPlayerbyLabelNotWnd(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if DKPInstance.SortedLabel then
		local sortBy = DKPInstance.tItems["settings"].LabelOptions[DKPInstance.SortedLabel]
		local label = "Stat"..DKPInstance.SortedLabel
		if DKPInstance.tItems["settings"].LabelSortOrder == "asc" then
			if sortBy == "Name" then return a.strName > b.strName 
			elseif sortBy == "Net" then return tonumber(a.net) > tonumber(b.net)
			elseif sortBy == "Tot" then return tonumber(a.tot) > tonumber(b.tot) 
			elseif sortBy == "Spent" then return tonumber(a.tot) - tonumber(a.net) > tonumber(b.tot) - tonumber(b.net)
			elseif sortBy == "Hrs" then 
			 	local nSecsA = 0
				for k ,tAtt in ipairs(a.tAtt or {}) do
					nSecsA = nSecsA + tAtt.nSecs
				end			 	

				local nSecsB = 0
				for k ,tAtt in ipairs(b.tAtt or {}) do
					nSecsB = nSecsB + tAtt.nSecs
				end
				return nSecsA > nSecsB
			elseif sortBy == "Priority" then 
				if tonumber(a.tot)-tonumber(a.net) == 0 then return b end
				if tonumber(b.tot)-tonumber(b.net) == 0 then return a end
				local pra = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(a.tot)/(tonumber(a.tot)-tonumber(a.net))))
				local prb = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(b.tot)/(tonumber(b.tot)-tonumber(b.net))))
				return pra > prb
			elseif sortBy == "EP" then return a.EP > b.EP
			elseif sortBy == "GP" then return a.GP > b.GP
			elseif sortBy == "PR" then return  tonumber(DKPInstance:EPGPGetPRByName(a.strName)) > tonumber(DKPInstance:EPGPGetPRByName(b.strName))
			elseif sortBy == "%GA" then return DKPInstance:GetRaidTypeCount(a.tAtt,RAID_GA) > DKPInstance:GetRaidTypeCount(b.tAtt,RAID_GA)
			elseif sortBy == "%DS" then return DKPInstance:GetRaidTypeCount(a.tAtt,RAID_DS) > DKPInstance:GetRaidTypeCount(b.tAtt,RAID_DS)
			elseif sortBy == "%Y" then return DKPInstance:GetRaidTypeCount(a.tAtt,RAID_Y) > DKPInstance:GetRaidTypeCount(b.tAtt,RAID_Y)
			elseif sortBy == "%Total" then return (a.tAtt and #a.tAtt or 0) > (b.tAtt and #b.tAtt or 0)
			end
		else
			if sortBy == "Name" then return a.strName < b.strName 
			elseif sortBy == "Net" then return tonumber(a.net) < tonumber(b.net)
			elseif sortBy == "Tot" then return tonumber(a.tot) < tonumber(b.tot) 
			elseif sortBy == "Spent" then return tonumber(a.tot) - tonumber(a.net) < tonumber(b.tot) - tonumber(b.net)
			elseif sortBy == "Hrs" then  
				local nSecsA = 0
				for k ,tAtt in ipairs(a.tAtt or {}) do
					nSecsA = nSecsA + tAtt.nSecs
				end			 	

				local nSecsB = 0
				for k ,tAtt in ipairs(b.tAtt or {}) do
					nSecsB = nSecsB + tAtt.nSecs
				end
				return nSecsA < nSecsB
			elseif sortBy == "Priority" then 
				if tonumber(a.tot)-tonumber(a.net) == 0 then return b end
				if tonumber(b.tot)-tonumber(b.net) == 0 then return a end
				local pra = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(a.tot)/(tonumber(a.tot)-tonumber(a.net))))
				local prb = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(b.tot)/(tonumber(b.tot)-tonumber(b.net))))
				return pra < prb
			elseif sortBy == "EP" then return a.EP < b.EP
			elseif sortBy == "GP" then return a.GP < b.GP
			elseif sortBy == "PR" then return  tonumber(DKPInstance:EPGPGetPRByName(a.strName)) < tonumber(DKPInstance:EPGPGetPRByName(b.strName))
			elseif sortBy == "%GA" then return DKPInstance:GetRaidTypeCount(a.tAtt,RAID_GA) < DKPInstance:GetRaidTypeCount(b.tAtt,RAID_GA)
			elseif sortBy == "%DS" then return DKPInstance:GetRaidTypeCount(a.tAtt,RAID_DS) < DKPInstance:GetRaidTypeCount(b.tAtt,RAID_DS)
			elseif sortBy == "%Y" then return DKPInstance:GetRaidTypeCount(a.tAtt,RAID_Y) < DKPInstance:GetRaidTypeCount(b.tAtt,RAID_Y)
			elseif sortBy == "%Total" then return (a.tAtt and #a.tAtt or 0) < (b.tAtt and #b.tAtt or 0)
			end
		end
	end
end

function DKP:GetRaidTypeCount(tAtt,nType)
	local counter = 0
	for k , att in ipairs(tAtt or {}) do
		if att.raidType == nType then counter = counter + 1 end
	end
	return counter
end

function DKP:RefreshMainItemListAndGroupByClass()
	local tIDs = self.tOverrideFilter
	local selectedPlayer = ""
	if self:LabelGetColumnNumberForValue("Name") > 0 then
		if self.MassEdit then
			selectedPlayer = {}
			for k,player in ipairs(selectedMembers) do
				table.insert(selectedPlayer,player:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
			end
		elseif self.wndSelectedListItem and self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")) then
			selectedPlayer = self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText()
		end
	end
	selectedMembers = {}
	self.wndItemList:DestroyChildren()
	local esp = {}
	local war = {}
	local spe = {}
	local med = {}
	local sta = {}
	local eng = {}
	local unknown = {}
	if not self.wndMain:FindChild("Controls"):FindChild("GroupByClass"):FindChild("TokenGroup"):IsChecked() then
		for k,player in ipairs(tIDs and tIDs or self.tItems) do
			if type(tIDs) == "table" then player = self.tItems[player] end
			if player.strName ~= "Guild Bank" then
				if player.class ~= nil then
					if player.class == self.tItems["settings"].tClassOrder[1] then
						table.insert(esp,player)
					elseif player.class == self.tItems["settings"].tClassOrder[2] then
						table.insert(eng,player)
					elseif player.class == self.tItems["settings"].tClassOrder[3] then
						table.insert(med,player)
					elseif player.class == self.tItems["settings"].tClassOrder[4] then
						table.insert(war,player)
					elseif player.class == self.tItems["settings"].tClassOrder[5] then
						table.insert(sta,player)
					elseif player.class == self.tItems["settings"].tClassOrder[6] then
						table.insert(spe,player)
					end
				else
					table.insert(unknown,player)
				end
			end
		end
	else
		for k,player in ipairs(tIDs and tIDs or self.tItems) do
			if type(tIDs) == "table" then player = self.tItems[player] end
			if player.strName ~= "Guild Bank" then
				if player.class ~= nil then
					if player.class == "Esper" then
						table.insert(esp,player)
					elseif player.class == "Engineer" then
						table.insert(eng,player)
					elseif player.class == "Medic" then
						table.insert(med,player)
					elseif player.class == "Warrior" then
						table.insert(eng,player)
					elseif player.class == "Stalker" then
						table.insert(med,player)
					elseif player.class == "Spellslinger" then
						table.insert(esp,player)
					end
				else
					table.insert(unknown,player)
				end
			end
		end
	end
	
	local tables = {}
	
	table.insert(tables,esp)
	table.insert(tables,eng)
	table.insert(tables,med)
	table.insert(tables,war)
	table.insert(tables,sta)
	table.insert(tables,spe)
	table.insert(tables,unknown)

	
	local tOnlineMembers
	if self.wndMain:FindChild("OnlineOnly"):IsChecked() then tOnlineMembers = self:GetOnlinePlayers() end
	
	for j,tab in ipairs(tables) do
		table.sort(tab,easyDKPSortPlayerbyLabelNotWnd)
		local added = false
		local nCounter = 1
		for k,player in ipairs(tab) do
			if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
				if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInQueue(player.strName) then
					if not self.wndMain:FindChild("OnlineOnly"):IsChecked() or self.wndMain:FindChild("OnlineOnly"):IsChecked() and self:IsPlayerOnline(tOnlineMembers,player.strName) then	
						if self:IsPlayerRoleDesired(player.role) then	
							if self.tItems["settings"].bHideStandby and not self.tItems["Standby"][string.lower(player.strName)] or not self.tItems["settings"].bHideStandby then
								if not self.MassEdit then
									player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
								else
									player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
								end
								
								self:UpdateItem(player,k,added)
								if not self.MassEdit then
									if player.strName == selectedPlayer then
										self.wndSelectedListItem = player.wnd
										player.wnd:SetCheck(true)	
									end
								else
									local found = false
									
									for k,prevPlayer in ipairs(selectedPlayer) do
										if prevPlayer == player.strName then
											found = true
											break
										end
									end
									if found then
										table.insert(selectedMembers,player.wnd)
										player.wnd:SetCheck(true)
									end
									
								end
								if self.tItems["settings"].bDisplayCounter then
									player.wnd:FindChild("Counter"):SetText(nCounter..".")
									player.wnd:FindChild("Counter"):Show(true)
								end
								nCounter = nCounter + 1 
								player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
								added = true
							end
						end
					end
				end
			end
		end
	end
	
	self:RaidQueueShow()
	self.wndItemList:ArrangeChildrenVert()
	self.wndItemList:SetVScrollPos(self.nHScroll)
	self:UpdateItemCount()
end

function DKP:LabelSort(wndHandler,wndControl,eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then 
		Event_FireGenericEvent("LabelSorted") 
		if wndControl then 
			if self:LabelIsSortable(wndControl:GetText()) then
				if wndControl:GetData() then 
					self:LabelSwapSortIndicator(wndControl)
				else 
					self:LabelSetSortIndicator(wndControl,"desc")
				end
				self.SortedLabel = self:LabelGetColumnNumberForValue(wndControl:GetText())
				if self.tItems["settings"].GroupByClass then self:RefreshMainItemListAndGroupByClass() else 
					self.wndMain:FindChild("ItemList"):ArrangeChildrenVert(0,easyDKPSortPlayerbyLabel) 
					self:LabelUpdateColorHighlight()
				end
			end
		elseif self.SortedLabel then
				if self.tItems["settings"].GroupByClass then self:RefreshMainItemListAndGroupByClass() else 
					self.wndMain:FindChild("ItemList"):ArrangeChildrenVert(0,easyDKPSortPlayerbyLabel) 
					self:LabelUpdateColorHighlight()
				end
		end
		
	else
		self:LabelMenuOpen(wndHandler,wndControl)
	end
	if self.tItems["settings"].bDisplayCounter and not self.tItems["settings"].GroupByClass then
		for k,child in ipairs(self:MainItemListGetChildren()) do
			child:FindChild("Counter"):Show(true)
			child:FindChild("Counter"):SetText(k..".")
		end
	end
	self:LabelHideIndicators()
end

function DKP:LabelUpdateColorHighlight()
	if self.SortedLabel then
		local label = "Stat"..self.SortedLabel
		for k,child in ipairs(self:MainItemListGetChildren()) do	
			for j,stat in ipairs(child:GetChildren()) do
				if stat:GetName() == label then stat:SetTextColor("ChannelAdvice") else stat:SetTextColor("white") end
			end
		end
	end

end
function DKP:LabelHideIndicators()
	local wndLabelBar = self.wndMain:FindChild("LabelBar")
	for i=1,self.currentLabelCount do
		if i ~= self.SortedLabel then
			wndLabelBar:FindChild("Label"..i):FindChild("SortIndicator"):Show(false,false)
		else
			wndLabelBar:FindChild("Label"..i):FindChild("SortIndicator"):Show(true,false)
		end
	end

end

function DKP:LabelIsSortable(strLabel) 
	if strLabel == "Item" or strLabel == "Nil" or strLabel == "GA" or strLabel == "DS" or strLabel == "Y" or strLabel == "Total" then return false else return true end
end

function DKP:LabelSwapSortIndicator(wnd)
	if wnd:GetData() == "asc" then 
		wnd:FindChild("SortIndicator"):SetSprite("CRB_PlayerPathSprites:sprPP_SciSpawnArrowDown")
		wnd:SetData("desc")
		self.tItems["settings"].LabelSortOrder = "desc"
	else
		wnd:FindChild("SortIndicator"):SetSprite("CRB_PlayerPathSprites:sprPP_SciSpawnArrowUp")
		wnd:SetData("asc")
		self.tItems["settings"].LabelSortOrder = "asc"
	end
end

function DKP:LabelSetSortIndicator(wnd,strState) -- asc desc
	if not wnd:FindChild("SortIndicator") then return end 
	if strState == "asc" then
		wnd:FindChild("SortIndicator"):SetSprite("CRB_PlayerPathSprites:sprPP_SciSpawnArrowUp")
		wnd:SetData("asc")
		self.tItems["settings"].LabelSortOrder = "asc"
	else
		wnd:FindChild("SortIndicator"):SetSprite("CRB_PlayerPathSprites:sprPP_SciSpawnArrowDown")
		wnd:SetData("desc")
		self.tItems["settings"].LabelSortOrder = "desc"
	end
end
---------------------------------------------------------------------------------------------------
-- Decay Functions
---------------------------------------------------------------------------------------------------
function DKP:DecayInit()
	if self.tItems["settings"].bDecayNegativeHelp == nil then self.tItems["settings"].bDecayNegativeHelp = true end
	if self.tItems["settings"].bDecayMinValue == nil then self.tItems["settings"].bDecayMinValue = false end
	if self.tItems["settings"].nDecayMinValue == nil then self.tItems["settings"].nDecayMinValue = 0 end
	if self.tItems["settings"].nDecayValue == nil then self.tItems["settings"].nDecayValue = 25 end

	local wndDecay = self.wndMain:FindChild("Decay")
	wndDecay:FindChild("NegativeHelp"):SetCheck(self.tItems["settings"].bDecayNegativeHelp)
	wndDecay:FindChild("MinNet"):SetCheck(self.tItems["settings"].bDecayMinValue)
	wndDecay:FindChild("MinNetValue"):SetText(self.tItems["settings"].nDecayMinValue)
	wndDecay:FindChild("DecayValue"):SetText(self.tItems["settings"].nDecayValue)
end
function DKP:DecayShow( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("Decay"):Show(true,false)
	
	self.wndMain:FindChild("EPGPDecayShow"):SetCheck(false)
	self.wndMain:FindChild("EPGPDecay"):Show(false)
end

function DKP:DecayHide( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("Decay"):Show(false,false)
end

function DKP:DecayNegativeHelpEnable()
	self.tItems["settings"].bDecayNegativeHelp = true
end

function DKP:DecayNegativeHelpDisable()
	self.tItems["settings"].bDecayNegativeHelp = false
end

function DKP:DecayMinNetEnable()
	self.tItems["settings"].bDecayMinValue = true
end

function DKP:DecayMinNetDisable()
	self.tItems["settings"].bDecayMinValue = false
end

function DKP:DecaySetMinNetValue(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val > 0 then
		self.tItems["settings"].nDecayMinValue = val
	else
		wndControl:SetText(self.tItems["settings"].nDecayMinValue)
	end
end

function DKP:DecaySetDecayValue(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val >= 0 and val <= 100 then
		self.tItems["settings"].nDecayValue = val
	else
		wndControl:SetText(self.tItems["settings"].nDecayValue)
	end
end

function DKP:DecayDecay()
	if self.tItems["settings"].bTrackUndo then
		local tMembers = {}
		for k,player in ipairs(self.tItems) do
			if self:DecayIsPlayerEligibleForDecay(player) then
				table.insert(tMembers,player)
			end
		end
		local strType = ktUndoActions["dkpdec"]

		if #tMembers > 0 then self:UndoAddActivity(strType,self.tItems["settings"].nDecayValue.."%",tMembers) end
	end

	for k , player in ipairs(self.tItems) do


		if self:DecayIsPlayerEligibleForDecay(player) then
			local mod
			if self.tItems["settings"].bDecayNegativeHelp and player.net < 0 then
				mod = player.net*-1 * self.tItems["settings"].nDecayValue / 100
				player.net = player.net + mod
			elseif not self.tItems["settings"].bDecayNegativeHelp and player.net < 0 then
				mod = player.net * self.tItems["settings"].nDecayValue / 100
				player.net = player.net + mod
			elseif player.net > 0 then
				mod = player.net * self.tItems["settings"].nDecayValue / 100
				player.net = player.net - mod
				mod = mod * -1
			end
			self:DetailAddLog("DKP Decay","{Decay}",mod,k)
		end



	end
	self:DROnDecay()
	self:RefreshMainItemList()
end

function DKP:DecayIsPlayerEligibleForDecay(player)
	if not self.tItems["Standby"][string.lower(player.strName)] == nil then return false end
	if self.tItems["settings"].bDecayMinValue and player.net <= self.tItems["settings"].nDecayMinValue and player.net > 0 then return false end
	return true
end

---------------------------------------------------------------------------------------------------
-- MemberDetails Functions
---------------------------------------------------------------------------------------------------
function DKP:OnDetailsClose()
	self.wndContext:Close()
end

---------------------------------------------------------------------------------------------------
-- Settings Functions
---------------------------------------------------------------------------------------------------

function DKP:SettingsCloseWindow( wndHandler, wndControl, eMouseButton )
	self.wndSettings:Show(false,false)
end

function DKP:SettingsShowWindow( wndHandler, wndControl, eMouseButton )
	self.wndSettings:Show(true,false)
	self.wndSettings:ToFront()
end

function DKP:SettingsLogsEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].logs = 1
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment")
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):Enable(true)
end

function DKP:SettingsLootLogsEnable()
	self.tItems["settings"].bLootLogs = true
end

function DKP:SettingsLootLogsDisable()
	self.tItems["settings"].bLootLogs = false
end

function DKP:SettingsWhisperEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].whisp = 1
end

function DKP:SettingsLogsDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].logs = 0
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comments Disabled")
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):Enable(false)
	self:EnableActionButtons()
end

function DKP:SettingsWhisperDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].whisp = 0
end

function DKP:SettingsSetQuickDKP( wndHandler, wndControl, eMouseButton )
	local value = self.wndSettings:FindChild("EditBoxQuickAdd"):GetText()
	self.tItems["settings"].dkp = tonumber(value)
	
	self:ControlsUpdateQuickAddButtons()
end

function DKP:SettingsSkipGBAssignEnable()
	self.tItems["settings"].bPopUpRandomSkip = true
end

function DKP:SettingsSkipGBAssignDisable()
	self.tItems["settings"].bPopUpRandomSkip = false
end

function DKP:SettingsExportSettings()
	self:ExportShowPreloadedText(serpent.dump({["settings"] = self.tItems["settings"],["EPGP"] = self.tItems["EPGP"],["CE"] = self.tItems["CE"]}))
end



function DKP:SettingsRestore()
	local isChecked
	--WHISP
	if self.tItems["settings"].whisp == 1 then isChecked = true else isChecked = false end
	local wndWhisp = self.wndSettings:FindChild("ButtonSettingsWhisp"):SetCheck(isChecked)
	--LOGS
	if self.tItems["settings"].logs == 1 then isChecked = true else isChecked = false end
	local wndLogs = self.wndSettings:FindChild("ButtonSettingsLogs"):SetCheck(isChecked)
	if self.tItems["settings"].logs == 0 then
		self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comments Disabled")
		self.wndMain:FindChild("Controls"):FindChild("EditBox"):Enable(false)
	end
	--GUILD CHeCK
	if self.tItems["settings"].forceCheck == 1 then isChecked = true else isChecked = false end
	self.wndSettings:FindChild("ButtonSettingsForceGuildCheck"):SetCheck(isChecked)
	--COLLECT NEW
	if self.tItems["settings"].collect_new == 1 then isChecked = true else isChecked = false end
	local wndLogs = self.wndSettings:FindChild("ButtonSettingsPlayerCollection"):SetCheck(isChecked)

	--LOWERCASE
	if self.tItems["settings"].lowercase == 1 then isChecked = true else isChecked = false end
	self.wndSettings:FindChild("ButtonSettingsCaseSensitivity"):SetCheck(isChecked)
	--Bid
	if self.tItems["settings"].BidEnable == 1 then isChecked = true else isChecked = false end
	self.wndSettings:FindChild("ButtonSettingsBidModule"):SetCheck(isChecked)
	self.wndSettings:FindChild("ButtonSettingsForceGuildCheck"):Enable(isChecked)
	if isChecked == false then 
		self.tItems["settings"].forceCheck = 0
		self.wndSettings:FindChild("ButtonSettingsForceGuildCheck"):SetCheck(false)
	end
	--PopUp
	if self.tItems["settings"].PopupEnable == 1 then isChecked = true else isChecked = false end
	self.wndSettings:FindChild("ButtonSettingsPopUp"):SetCheck(isChecked)
	
	--RANDOM
	self.wndSettings:FindChild("EditBoxDefaultDKP"):SetText(tostring(self.tItems["settings"].default_dkp))
	if self.tItems["removed"] ~= nil then removed = self.tItems["removed"] end
	self.wndSettings:FindChild("ExportSettings"):SetRotation(180)

	--GroupByClass
	self.wndMain:FindChild("Controls"):FindChild("GroupByClass"):SetCheck(self.tItems["settings"].GroupByClass)
	-- PopUp reduction
	self.wndSettings:FindChild("PopUPGPRed"):FindChild("EditBox"):SetText(self.tItems["settings"].nPopUpGPRed)
	-- Undo
	self.wndSettings:FindChild("TrackUndo"):SetCheck(self.tItems["settings"].bTrackUndo)
	
	--Networking
	self.wndSettings:FindChild("ButtonSettingsHideStandby"):SetCheck(self.tItems["settings"].bHideStandby)
	self.wndSettings:FindChild("ButtonSettingsEquip"):SetCheck(self.tItems["settings"].FilterEquippable)
	
	--Sliders
	self.wndSettings:FindChild("Precision"):SetValue(self.tItems["settings"].Precision)
	self.wndSettings:FindChild("PrecisionEPGP"):SetValue(self.tItems["settings"].PrecisionEPGP)
	self.wndSettings:FindChild("PrecisionTitle"):SetText(string.format(self.Locale["#wndSettings:PRPrec"].. " - %d",self.tItems["settings"].Precision))
	self.wndSettings:FindChild("PrecisionEPGPTitle"):SetText(string.format(self.Locale["#wndSettings:EPGPPrec"].. " - %d",self.tItems["settings"].PrecisionEPGP))
	self.wndSettings:FindChild("PrecisionDKPTitle"):SetText(string.format(self.Locale["#wndSettings:DKPPrec"].. " - %d",self.tItems["settings"].nPrecisionDKP))
	--Affiliation
	if self.tItems["settings"].CheckAffiliation == 1 then self.wndSettings:FindChild("ButtonSettingsNameplatreAffiliation"):SetCheck(true) end

	if self.tItems["settings"].bTrackUndo then self.wndSettings:FindChild("TrackUndo"):SetCheck(true) end
	if not self.tItems["settings"].bSkipBidders then self.tItems["settings"].bSkipBidders = false end
	if self.tItems["settings"].bLLAfterPopUp == nil then self.tItems["settings"].bLLAfterPopUp = false end

	if self.tItems["settings"].bUseFilterForItemLabel == nil then self.tItems["settings"].bUseFilterForItemLabel = true end

	-- Sorry for this abomination above :(
	
	self.wndSettings:FindChild("UseColorIcons"):SetCheck(self.tItems["settings"].bColorIcons)
	self.wndSettings:FindChild("DisplayRoles"):SetCheck(self.tItems["settings"].bDisplayRoles)
	self.wndSettings:FindChild("SaveUndo"):SetCheck(self.tItems["settings"].bSaveUndo)
	self.wndSettings:FindChild("SkipGB"):SetCheck(self.tItems["settings"].bSkipGB)
	self.wndSettings:FindChild("RemoveErrorInvites"):SetCheck(self.tItems["settings"].bRemErrInv)
	self.wndSettings:FindChild("DisplayCounter"):SetCheck(self.tItems["settings"].bDisplayCounter)
	self.wndSettings:FindChild("CountSelected"):SetCheck(self.tItems["settings"].bCountSelected)
	self.wndSettings:FindChild("TrackTimedUndo"):SetCheck(self.tItems["settings"].bTrackTimedAwardUndo)
	self.wndSettings:FindChild("EnableLootLogs"):SetCheck(self.tItems["settings"].bLootLogs)
	self.wndSettings:FindChild("SkipRandomAssign"):SetCheck(self.tItems["settings"].bPopUpRandomSkip)
	self.wndSettings:FindChild("AutoLog"):SetCheck(self.tItems["settings"].bAutoLog)
	self.wndSettings:FindChild("SkipWinner"):SetCheck(self.tItems["settings"].bSkipBidders)
	self.wndSettings:FindChild("LLonPopUp"):SetCheck(self.tItems["settings"].bLLAfterPopUp)
	self.wndSettings:FindChild(self.tItems["settings"].strDateFormat):SetCheck(true)
	self.wndSettings:FindChild("FilterItemLabel"):SetCheck(self.tItems["settings"].bUseFilterForItemLabel)

	--Export
	if self.tItems["settings"].bUseFilterForWebsiteExport == nil then self.tItems["settings"].bUseFilterForWebsiteExport = true end
	self.wndExport:FindChild("LLogsFromExport"):SetCheck(self.tItems["settings"].bUseFilterForWebsiteExport)
	
	self.wndSettings:FindChild("MinLvl"):SetText(self.tItems["settings"].nMinIlvl)
	if self.tItems["settings"].strLootFiltering ~= "Nil" then self.wndSettings:FindChild(self.tItems["settings"].strLootFiltering):SetCheck(true) end
	self.wndSettings:FindChild("SlashCommands"):SetTooltip(" /epgp - For main roster window \n" ..
									 " /ropsml - For Master Looter Settings window \n" ..
									 " /nb - For Network Bidding window \n" ..
									 " /chatbid - For Chat Bidding window \n")
									 
end

function DKP:SettingsLLAfterPopUpEnable()
	self.tItems["settings"].bLLAfterPopUp = true
end

function DKP:SettingsLLAfterPopUpDisable()
	self.tItems["settings"].bLLAfterPopUp = false
end

function DKP:SettingsEnablePlayerCollection( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].collect_new = 1
end

function DKP:SettingsDisablePlayerCollection( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].collect_new = 0
end

function DKP:SetDefaultDKP( wndHandler, wndControl, strText )
	if tonumber(strText) == nil then wndControl:SetText(self.tItems["settings"].default_dkp) return end
	self.tItems["settings"].default_dkp = tonumber(strText)
end

function DKP:SettingsPurgeDatabaseOn( wndHandler, wndControl, eMouseButton )
		purge_database = 1
		self.wndSettings:FindChild("PurgeAlert"):Show(true,false)
end

function DKP:SettingsPurgeDatabaseOff()
		purge_database = 0
		self.wndSettings:FindChild("PurgeAlert"):Show(false,false)
end

function DKP:SettingsColorIconsEnable()
	self.tItems["settings"].bColorIcons = true
	self:BidUpdateColorScheme()
	ktStringToIcon = ktStringToNewIconOrig
	self:RefreshMainItemList()
end

function DKP:SettingsColorIconsDisable()
	self.tItems["settings"].bColorIcons = false
	self:BidUpdateColorScheme()
	ktStringToIcon = ktStringToIconOrig
	self:RefreshMainItemList()
end

function DKP:SettingsDisplayRolesEnable()
	self.tItems["settings"].bDisplayRoles = true
	self:RefreshMainItemList()
end

function DKP:SettingsDisplayRolesDisable()
	self.tItems["settings"].bDisplayRoles = false
	self:RefreshMainItemList()
end

function DKP:SettingsSetMinIlvl(wndHandler,wndControl,strText)
	local value = tonumber(strText)
	if value and value > 0 then
		self.tItems["settings"].nMinIlvl = value
	else
		wndControl:SetText(self.tItems["settings"].nMinIlvl)
	end
end

function DKP:SettingsSaveUndoEnable()
	self.tItems["settings"].bSaveUndo = true
end

function DKP:SettingsSaveUndoDisable()
	self.tItems["settings"].bSaveUndo = false
end

function DKP:SettingsSkipGBEnable()
	self.tItems["settings"].bSkipGB = true
end

function DKP:SettingsSkipGBDisable()
	self.tItems["settings"].bSkipGB = false
end

function DKP:SettingsSkipBidderEnable()
	self.tItems["settings"].bSkipBidders = true
end

function DKP:SettingsSkipBidderDisable()
	self.tItems["settings"].bSkipBidders = false
end

function DKP:SettingsRemoveInvErrorsEnable()
	self.tItems["settings"].bRemErrInv = true
end

function DKP:SettingsRemoveInvErrorsDisable()
	self.tItems["settings"].bRemErrInv = false	
end

function DKP:SettingsDisplayCounterEnable()
	self.tItems["settings"].bDisplayCounter = true
	self:RefreshMainItemList()
end

function DKP:SettingsDisplayCounterDisable()
	self.tItems["settings"].bDisplayCounter = false
	self:RefreshMainItemList()
end

function DKP:SettingsFilterItemLabelEnable()
	self.tItems["settings"].bUseFilterForItemLabel = true
end

function DKP:SettingsFilterItemLabelDisable()
	self.tItems["settings"].bUseFilterForItemLabel = true
end

function DKP:SettingsAutoLogsEnable()
	self.tItems["settings"].bAutoLog = true
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment - Auto")
	self:EnableActionButtons()
end

function DKP:SettingsAutoLogsDisable()
	self.tItems["settings"].bAutoLog = false
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment")
	self:EnableActionButtons()
end

function DKP:SettingsCheckFetchedNameSpelling( wndHandler, wndControl, strText )
	if strText == "" then
		wndControl:SetText("Enter Name of Player to Fetch Data from")
	end
end


function DKP:SettingsEnableForceGuildCheckEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].forceCheck = 1
end

function DKP:SettingsEnableForceGuildCheckDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].forceCheck = 0
end

function DKP:SettingsPopUpGPReductionValueChanged(wndHandler,wndControl,strText)
	if tonumber(strText) then
		local value = tonumber(strText)
		if value >= 0 and value <= 100 then 
			self.tItems["settings"].nPopUpGPRed = value
		else
			wndControl:SetText(self.tItems["settings"].nPopUpGPRed) 
		end
	else
		wndControl:SetText(self.tItems["settings"].nPopUpGPRed) 
	end
end

function DKP:SettingsEnableForceLowerCaseEnable( wndHandler, wndControl, eMouseButton )
	for i=1 , table.maxn(self.tItems) do 
		if self.tItems[i] ~= nil then
			self.tItems[i].strName = string.lower(self.tItems[i].strName)
			if self.tItems[i].alts ~= nil then
				for j=1,table.getn(self.tItems[i].alts) do
					self.tItems["alts"][self.tItems[i].alts[j].strName] = nil
					self.tItems[i].alts[j].strName = string.lower(self.tItems[i].alts[j].strName)
					self.tItems["alts"][self.tItems[i].alts[j].strName] = i
				end
			end
		end
	end
	self.tItems["settings"].lowercase = 1
	self:ForceRefresh()
end

function DKP:SettingsEnableForceLowerCaseDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].lowercase = 0
end

function DKP:SettingsBidEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].BidEnable = 1
	self.wndSettings:FindChild("ButtonSettingsForceGuildCheck"):Enable(true)
end

function DKP:SettingsBidDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].BidEnable = 0
	self.tItems["settings"].forceCheck = 0
	self.wndSettings:FindChild("ButtonSettingsForceGuildCheck"):Enable(false)
	self.wndSettings:FindChild("ButtonSettingsForceGuildCheck"):SetCheck(false)
end

function DKP:SettingsPopupEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].PopupEnable = 1
end

function DKP:SettingsPopupDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].PopupEnable = 0
end

function DKP:SettingsFilterWordsEnable()
	self.tItems["settings"].FilterWords = true
end

function DKP:SettingsFilterWordsDisable()
	self.tItems["settings"].FilterWords = false
end

function DKP:SettingsTrackEquipableEnable()
	self.tItems["settings"].FilterEquippable = true
end

function DKP:SettingsTrackEquipableDisable()
	self.tItems["settings"].FilterEquippable = false
end

function DKP:SettingsEnableFilter( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].CheckAffiliation = 1
end

function DKP:SettingsDisableFilter( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].CheckAffiliation = 0
end

function DKP:SettingsEnableStandbyHide()
	self.tItems["settings"].bHideStandby = true
	self:RefreshMainItemList()
end

function DKP:SettingsDisableStandbyHide()
	self.tItems["settings"].bHideStandby = false
	self:RefreshMainItemList()
end

function DKP:SettingGroupByClassOn()
	self.tItems["settings"].GroupByClass = true
	self:RefreshMainItemList()
	Event_FireGenericEvent("GroupByClassEnabled")
end	

function DKP:SettingGroupByClassOff()
	self.tItems["settings"].GroupByClass = false
	self:RefreshMainItemList()
end

function DKP:SettingsCountSelectedEnable()
	self.tItems["settings"].bCountSelected = true
	self:UpdateItemCount()
end

function DKP:SettingsCountSelectedDisable()
	self.tItems["settings"].bCountSelected = false
	self:UpdateItemCount()
end

function DKP:SettingsTimedUndoEnable()
	self.tItems["settings"].bTrackTimedAwardUndo = true
end

function DKP:SettingsTimedUndoDisable()
	self.tItems["settings"].bTrackTimedAwardUndo = false
end

function DKP:SettingsSetLootFilterMode(wndHandler,wndControl)
	self.tItems["settings"].strLootFiltering = wndControl:GetName()
end

function DKP:SettingsDisableLootFilter()
	self.tItems["settings"].strLootFiltering = "Nil"
end

function DKP:SettingsSetPrecision( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].Precision then
		self.tItems["settings"].Precision = math.floor(fNewValue)
		self:ShowAll()
		self.wndSettings:FindChild("PrecisionTitle"):SetText(string.format(self.Locale["#wndSettings:PRPrec"].. " - %d",self.tItems["settings"].Precision))
	end
end

function DKP:SettingsSetPrecisionEPGP( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].PrecisionEPGP then
		self.tItems["settings"].PrecisionEPGP = math.floor(fNewValue)
		self:ShowAll()
		self.wndSettings:FindChild("PrecisionEPGPTitle"):SetText(string.format(self.Locale["#wndSettings:EPGPPrec"].. " - %d",self.tItems["settings"].PrecisionEPGP))
	end
end

function DKP:SettingsSetDKPPrecision( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].nPrecisionDKP then
		self.tItems["settings"].nPrecisionDKP = math.floor(fNewValue)
		self:ShowAll()
		self.wndSettings:FindChild("PrecisionDKPTitle"):SetText(string.format(self.Locale["#wndSettings:DKPPrec"].. " - %d",self.tItems["settings"].nPrecisionDKP))
	end
end

function DKP:SettingsEnableFillingBidMinValues()
	self.tItems["BidSlots"].Enable = 1
end

function DKP:SettingsDisableFillingBidMinValues()
	self.tItems["BidSlots"].Enable = 0
end

---------------------------------------------------------------------------------------------------
-- Export Functions
---------------------------------------------------------------------------------------------------
local strConcatedString

function DKP:ExportExport()

	if not self.wndExport:FindChild("List"):IsChecked() then
		if self.wndExport:FindChild("EPGP"):IsChecked() then
			if self.wndExport:FindChild("ButtonExportCSV"):IsChecked() then
				self:ExportSetOutputText(self:ExportAsCSVEPGP())
			elseif  self.wndExport:FindChild("ButtonExportHTML"):IsChecked() then
				self:ExportSetOutputText(self:ExportAsHTMLEPGP())
			elseif  self.wndExport:FindChild("ButtonExportFromattedHTML"):IsChecked() then
				self:ExportSetOutputText(self:ExportAsFormattedHTMLEPGP())
			end
		elseif self.wndExport:FindChild("DKP"):IsChecked() then
			if self.wndExport:FindChild("ButtonExportCSV"):IsChecked() then
				self:ExportSetOutputText(self:ExportAsCSVDKP())
			elseif  self.wndExport:FindChild("ButtonExportHTML"):IsChecked() then
				self:ExportSetOutputText(self:ExportAsHTMLDKP())
			elseif  self.wndExport:FindChild("ButtonExportFromattedHTML"):IsChecked() then
				self:ExportSetOutputText(self:ExportAsFormattedHTMLDKP())
			end
		end
	else
		if self.wndExport:FindChild("ButtonExportCSV"):IsChecked() then
			self:ExportSetOutputText(self:ExportAsCSVList())
		elseif  self.wndExport:FindChild("ButtonExportHTML"):IsChecked() then
			self:ExportSetOutputText(self:ExportAsHTMLList())
		elseif  self.wndExport:FindChild("ButtonExportFromattedHTML"):IsChecked() then
			self:ExportSetOutputText(self:ExportAsFormattedHTMLList())
		end
	end
	
	if self.wndExport:FindChild("ButtonExportSerialize"):IsChecked() then
		local exportTables = {}
		exportTables.tPlayers = {}
		for k , player in ipairs(self.tItems) do
			local tPlayer = {}
			tPlayer.strName = player.strName
			tPlayer.net = player.net
			tPlayer.tot = player.tot
			tPlayer.Hrs = player.Hrs
			tPlayer.logs = player.logs
			tPlayer.EP = player.EP
			tPlayer.GP = player.GP
			tPlayer.class = player.class
			tPlayer.alts = player.alts
			tPlayer.role = player.role
			tPlayer.offrole = player.offrole
			tPlayer.tLLogs = player.tLLogs
			tPlayer.tAtt = player.tAtt
			table.insert(exportTables.tPlayers,tPlayer)
		end
		exportTables.tRaids = self.tItems.tRaids
		exportTables.tSettings = self.tItems["settings"]
		exportTables.tEPGP = self.tItems["EPGP"]
		exportTables.tStandby = self.tItems["Standby"]
		exportTables.tCE = self.tItems["CE"]
		

		self:ExportSetOutputText(serpent.dump(exportTables))

	elseif self.wndExport:FindChild("ButtonImport"):IsChecked() then
		self.wndExport:FindChild("ClearString"):Show(false)
		self.wndExport:FindChild("StoredLength"):SetText("0")
		local strImportString = strConcatedString
		strConcatedString = nil
		if not strImportString then strImportString = self.wndExport:FindChild("ExportBox"):GetText() end
		if string.sub(strImportString, 1, 2) == '[' or string.sub(strImportString, 1, 1) == '{' then
			local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
			local tImportedPlayers = JSON.decode(strImportString)
			if tImportedPlayers then

				for k,player in ipairs(self.tItems) do
					self.tItems[k] = nil
				end
				for k,raid in ipairs(self.tItems.tRaids or {}) do
					if self.tItems.tRaids then self.tItems.tRaids[k] = nil end
				end
				for k , player in ipairs(tImportedPlayers['tMembers'] or tImportedPlayers) do
					table.insert(self.tItems,player)
				end
				if not self.tItems.tRaids then self.tItems.tRaids = {} end
				for k , raid in ipairs(tImportedPlayers['tRaids'] or {}) do
					table.insert(self.tItems.tRaids,raid)
				end
 				self:AltsBuildDictionary()
				for alt , owner in ipairs(self.tItems["alts"]) do
					for k , player in ipairs(self.tItems) do
						if string.lower(player.strName) == string.lower(alt) then table.remove(self.tItems,k) end
						break
					end
				end
				self:AltsBuildDictionary()
			end
			ChatSystemLib.Command("/reloadui")
		else
			local tImportedTables
			if string.sub(strImportString, 1, 2) == 'do' then
				tImportedTables = serpent.load(strImportString)
			else
				tImportedTables = serpent.load(Base64.Decode(strImportString))
			end

			if tImportedTables and tImportedTables.tPlayers and tImportedTables.tSettings and tImportedTables.tStandby and tImportedTables.tCE then
				for k,player in ipairs(self.tItems) do
					self.tItems[k] = nil
				end
				for k,player in ipairs(tImportedTables.tPlayers) do
					table.insert(self.tItems,player)
				end
				for k,player in ipairs(self.tItems) do
					if not self.tItems[k].logs then self.tItems[k].logs = {} end
				end
				self.tItems["settings"] = tImportedTables.tSettings
				self.tItems["EPGP"] = tImportedTables.tEPGP
				self.tItems["Standby"] = tImportedTables.tStandby
				self.tItems["CE"] = tImportedTables.tCE
				self.tItems.tRaids = tImportedTables.tRaids
				self:AltsBuildDictionary()
				for alt , owner in ipairs(self.tItems["alts"]) do
					for k , player in ipairs(self.tItems) do
						if string.lower(player.strName) == string.lower(alt) then table.remove(self.tItems,k) end
						break
					end
				end
				self:AltsBuildDictionary()
				ChatSystemLib.Command("/reloadui")
			elseif tImportedTables["settings"] and tImportedTables["EPGP"] then
				self.tItems["settings"] = tImportedTables["settings"]
				self.tItems["EPGP"] = tImportedTables["EPGP"]
				self.tItems["CE"] = tImportedTables["CE"]
				ChatSystemLib.Command("/reloadui")
			else
				Print("Error processing database")
			end
		end
	end

	if self.wndExport:FindChild("WebExport"):IsChecked() then
		local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
		local tTestTable = {}
		tTestTable['tMembers'] = {}
		tTestTable['tRaids'] = self.tItems.tRaids
		for k , player in ipairs(self.tItems) do
			local tCopy = {}
			tCopy.strName = player.strName
			tCopy.net = player.net
			tCopy.tot = player.tot
			tCopy.EP = player.EP
			tCopy.GP = player.GP
			tCopy.class = player.class
			tCopy.alts = player.alts
			tCopy.logs = player.logs
			tCopy.role = player.role
			tCopy.offrole = player.offrole
			tCopy.tLLogs = player.tLLogs
			tCopy.tAtt = player.tAtt
			tCopy.tLLogs = {}
			table.insert(tTestTable['tMembers'],tCopy)
			for k , entry in ipairs(player.tLLogs) do
				if self.tItems["settings"].bUseFilterForWebsiteExport and self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),player,entry.nGP) or not self.tItems["settings"].bUseFilterForWebsiteExport then
					table.insert(tTestTable['tMembers'][#tTestTable['tMembers']].tLLogs,entry)
				end 
			end
		end
		self:ExportSetOutputText(JSON.encode(tTestTable))
	    
	end
end

function DKP:ExportEnableLootFiltering()
	self.tItems["settings"].bUseFilterForWebsiteExport = true
end

function DKP:ExportDisableLootFiltering()
	self.tItems["settings"].bUseFilterForWebsiteExport = false
end

function DKP:ExportAddStringPart()
	self.wndExport:FindChild("ClearString"):Show(true)
	if not strConcatedString then
		strConcatedString = self.wndExport:FindChild("ExportBox"):GetText()
		self.wndExport:FindChild("StoredLength"):SetText(string.len(strConcatedString))
	else
		strConcatedString = strConcatedString .. self.wndExport:FindChild("ExportBox"):GetText()
		self.wndExport:FindChild("StoredLength"):SetText(string.len(strConcatedString))
	end
	self.wndExport:FindChild("ExportBox"):SetText("")
end

function DKP:ExportResetString()
	self.wndExport:FindChild("StoredLength"):SetText("0")
	self.wndExport:FindChild("ClearString"):Show(false)
	strConcatedString = nil
end

function DKP:ExportSetOutputText(strText)
	if string.len(strText) < 30000 then self.wndExport:FindChild("ExportBox"):SetText(strText) else self.wndExport:FindChild("ExportBox"):SetText("String is too long , use copy to clipboard button.") end
	self.wndExport:FindChild("ButtonCopy"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, strText)
end

function DKP:ExportCloseWindow( wndHandler, wndControl, eMouseButton )
	self.wndExport:Show(false,false)
	self.wndExport:FindChild("ExportBox"):SetText("")
end

function DKP:ExportShowWindow( wndHandler, wndControl, eMouseButton )
	self.wndExport:Show(true,false)
	self.wndExport:FindChild("ButtonExportCSV"):SetCheck(true)
	self.wndExport:ToFront()
end

function DKP:ExportShowPreloadedText(exportString)
	self.wndExport:Show(true,false)
	self.wndExport:FindChild("ExportBox"):SetText(exportString)
	self.wndExport:FindChild("ButtonCopy"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, exportString)
	self.wndExport:ToFront()
	self.wndExport:FindChild("ButtonExportHTML"):SetCheck(false)
	self.wndExport:FindChild("ButtonExportCSV"):SetCheck(false)
end

function DKP:ExportAsCSVEPGP()
	local strCSV = "Player;EP;GP;PR\n"
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if self.tItems[i].GP ~= 0 then 
				strCSV = strCSV .. self.tItems[i].strName .. ";" .. self.tItems[i].EP .. ";".. self.tItems[i].GP .. ";" .. self.tItems[i].EP/self.tItems[i].GP .. "\n"
			else
				strCSV = strCSV .. self.tItems[i].strName .. ";" .. self.tItems[i].EP .. ";".. self.tItems[i].GP .. ";" .. "0" .. "\n"
			end
		end
	end
	return strCSV
end

function DKP:ExportAsCSVList()
	local strCSV = ""
	for k=1,self.currentLabelCount do
		if self.tItems["settings"].LabelOptions[k] then
			strCSV = strCSV .. self.tItems["settings"].LabelOptions[k] .. ";"
		end
	end
	strCSV = strCSV .. "\n"
	for k,child in ipairs(self:MainItemListGetChildren()) do
		for j=1,self.currentLabelCount do
			strCSV = strCSV .. child:FindChild("Stat"..j):GetText() .. ";"
		end
		strCSV = strCSV .. "\n"
	end
	return strCSV
end



function DKP:ExportAsCSVDKP()
	local strCSV = "Player;Net;Tot\n"
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i]~= nil then
			strCSV = strCSV .. self.tItems[i].strName .. ";" .. self.tItems[i].net .. ";".. self.tItems[i].tot .. "\n"
		end
	end
	return strCSV
end

function DKP:ExportAsHTMLEPGP()
	local strHTML = "<!DOCTYPE html><html><head><style>\ntable, th, td {    border: 1px solid black;    border-collapse: collapse;}th, td {    padding: 5px;}</style></head>\n<body><table style=".."width:100%"..">\n"
	strHTML = strHTML .. "<tr><th>" .. "Player Name" .. "</th><th>" .. "EP" .. "</th><th>" .. "GP" .. "</th><th>" .. "PR" .."</th></tr>\n"
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if self.tItems[i].GP ~= 0 then
				strHTML = strHTML .. "<tr><th>" .. self.tItems[i].strName .. "</th><th>" .. self.tItems[i].EP .. "</th><th>" .. self.tItems[i].GP .. "</th><th>" .. self.tItems[i].EP/self.tItems[i].GP .. "</tr>\n"
			else
				strHTML = strHTML .. "<tr><th>" .. self.tItems[i].strName .. "</th><th>" .. self.tItems[i].EP .. "</th><th>" .. self.tItems[i].GP .. "</th><th>" .. self.tItems[i].EP/self.tItems[i].GP .. "</tr>\n"
			end
		end
	end
	strHTML = strHTML .. "\n</table>\n</body>\n</html>"
	return strHTML

end

function DKP:ExportAsHTMLList()
	local strHTML = "<!DOCTYPE html><html><head><style>\ntable, th, td {    border: 1px solid black;    border-collapse: collapse;}th, td {    padding: 5px;}</style></head>\n<body><table style=".."width:100%"..">\n"
	strHTML = strHTML .. "<tr><th>" .. self.tItems["settings"].LabelOptions[1] .. "</th><th>" .. self.tItems["settings"].LabelOptions[2] .. "</th><th>" .. self.tItems["settings"].LabelOptions[3] .. "</th><th>" .. self.tItems["settings"].LabelOptions[4] .."</th><th>" .. self.tItems["settings"].LabelOptions[5] ..  "</th></tr>\n<tr>"
	for k,child in ipairs(self:MainItemListGetChildren()) do
		for j=1,self.currentLabelCount do
			strHTML = strHTML .. "<th>" .. child:FindChild("Stat"..j):GetText() .. "</th>"
		end
		strHTML = strHTML .. "</tr>\n<tr>"
	end
	strHTML = strHTML .. "\n</table>\n</body>\n</html>"
	return strHTML

end

function DKP:ExportAsFormattedHTMLEPGP()
	local formatedTable ={}
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i]~= nil then
			formatedTable[self.tItems[i].strName] = {}
			formatedTable[self.tItems[i].strName].EP = self.tItems[i].EP
			formatedTable[self.tItems[i].strName].GP = self.tItems[i].GP
			if self.tItems[i].GP ~= 0 then
				formatedTable[self.tItems[i].strName].PR = self.tItems[i].EP/self.tItems[i].GP
			else
				formatedTable[self.tItems[i].strName].PR = 0
			end
			if self.tItems[i].logs ~= nil then
				formatedTable[self.tItems[i].strName]["Logs"] = {}
				for k,logs in ipairs(self.tItems[i].logs) do
					if string.find(logs.strType,"EP") or string.find(logs.strType,"GP") then 
						table.insert(formatedTable[self.tItems[i].strName]["Logs"],logs)
					end
				end
			end
			if formatedTable[self.tItems[i].strName]["Logs"] ~= nil and #formatedTable[self.tItems[i].strName]["Logs"] < 1 then formatedTable[self.tItems[i].strName]["Logs"] = nil end
		end
	end

	return tohtml(formatedTable)
end

function DKP:ExportAsFormattedHTMLList()
	local formatedTable ={}
	for k,child in ipairs(self:MainItemListGetChildren()) do
		table.insert(formatedTable,{[self.tItems["settings"].LabelOptions[1]] = child:FindChild("Stat1"):GetText(),[self.tItems["settings"].LabelOptions[2]] = child:FindChild("Stat2"):GetText(),[self.tItems["settings"].LabelOptions[3]] = child:FindChild("Stat3"):GetText(),[self.tItems["settings"].LabelOptions[4]] = child:FindChild("Stat4"):GetText(),[self.tItems["settings"].LabelOptions[5]] = child:FindChild("Stat5"):GetText()})
	end

	return tohtml(formatedTable)
end

function DKP:ExportAsFormattedHTMLDKP()
	local formatedTable ={}
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i]~= nil then
			formatedTable[self.tItems[i].strName] = {}
			formatedTable[self.tItems[i].strName].Net = self.tItems[i].net
			formatedTable[self.tItems[i].strName].Tot = self.tItems[i].tot
			if self.tItems[i].logs ~= nil then
				formatedTable[self.tItems[i].strName]["Logs"] = {}
				for k,logs in ipairs(self.tItems[i].logs) do
					if string.find(logs.comment,"EP") == nil and string.find(logs.comment,"GP") == nil then 
						table.insert(formatedTable[self.tItems[i].strName]["Logs"],logs)
					end
				end
				if #formatedTable[self.tItems[i].strName]["Logs"] < 1 then formatedTable[self.tItems[i].strName]["Logs"] = nil end
			end
			
		end
	end

	return tohtml(formatedTable)
end

function DKP:ExportAsHTMLDKP()
	local strHTML = "<!DOCTYPE html><html><head><style>\ntable, th, td {    border: 1px solid black;    border-collapse: collapse;}th, td {    padding: 5px;}</style></head>\n<body><table style=".."width:100%"..">\n"
	strHTML = strHTML .. "<tr><th>" .. "Player Name" .. "</th><th>" .. "Net" .. "</th><th>" .. "Tot" .. "</th></tr>\n"
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			strHTML = strHTML .. "<tr><th>" .. self.tItems[i].strName .. "</th><th>" .. self.tItems[i].net .. "</th><th>" .. self.tItems[i].tot .. "</th></tr>\n"
		end
	end
	strHTML = strHTML .. "\n</table>\n</body>\n</html>"
	return strHTML
end

---------------------------------------------------------------------------------------------------
-- MasterLootPopUp Functions
---------------------------------------------------------------------------------------------------
local currEntry
local tQueue = {}

function DKP:PopUpAccept()
	self:PopUpAssign()
end

function DKP:PopUpAwardGuildBank()
	if self:GetPlayerByIDByName("Guild Bank") ~= -1 then self:DetailAddLog(currEntry.item:GetName(),"{Com}","-",self:GetPlayerByIDByName("Guild Bank")) end
	currEntry = nil
	self:PopUpCheckUpdate()
end

function DKP:PopUpModifyGPValue(wndHandler,wndControl)
	local value = tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())
	if self.tItems["settings"].nPopUpGPRed > 0 and self.tItems["settings"].nPopUpGPRed < 100 then
		local nDecrease = 100 - self.tItems["settings"].nPopUpGPRed
		if wndControl:IsChecked() then 
			if value and nDecrease ~= 0 then
				value = (value*nDecrease)/100
			end
		else
			if value and nDecrease ~= 0 then
				value = (100*value)/nDecrease
			end
		end
	elseif value then
		if self.tItems["settings"].nPopUpGPRed == 100 then
			if wndControl:IsChecked() then 
				value = 0
			else
				value = currEntry.nGP
			end
		end
	end
	if value then self.wndPopUp:FindChild("EditBoxDKP"):SetText(value) end
end

function DKP:PopUpWindowOpen(strNameOrig,strItem)
	self:dbglog(">PopUp Request > Received ---PopUp Request Begin---")
	local entry = {}
	local strName = ""
	for uchar in string.gfind(strNameOrig, "([%z\1-\127\194-\244][\128-\191]*)") do
		if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
		strName = strName .. uchar
	end

	entry.strName = strName

	-- Cheking whether to skip and if data is valid 

	if self.ItemDatabase and self.ItemDatabase[strItem] and self:GetPlayerByIDByName(strName) ~= -1 then
		entry.item = Item.GetDataFromId(self.ItemDatabase[strItem].ID)
	else self:dbglog(">PopUp request fail > Reason: 'wrong player ID or item not found'") return end

	if self.tItems["settings"].bPopUpRandomSkip and self.strRandomWinner and strName == self.strRandomWinner then self.strRandomWinner = nil return self:dbglog(">PopUp request end > random winnder filter") end

	if self:GetPlayerByIDByName("Guild Bank") ~= -1 and strName == "Guild Bank" and self.tItems["settings"].bSkipGB then 
		self:DetailAddLog(strItem,"{Com}","-",self:GetPlayerByIDByName("Guild Bank")) 
		return
	end

	if self:PopUpIsBidWinner(strName) then
		self:PopUpAssign(entry,self.tPopUpItemGPvalues[strItem])
		self.tPopUpItemGPvalues[strItem] = nil
		self:dbglog(">PopUp request end > bid winner")
		return
	end

	-- Set GP value

	if self.tPopUpItemGPvalues[strItem] then
		entry.nGP = self.tPopUpItemGPvalues[strItem]
		self.tPopUpItemGPvalues[strItem] = nil
	else
		entry.nGP = self:EPGPGetItemCostByID(entry.item:GetItemId(),true)
	end

	-- Store in queue

	table.insert(tQueue,1,entry)

	-- update if necessary

	self:PopUpCheckUpdate()
	self:dbglog(">PopUp request succes > entry passed to window:" .. string.format(" %s , %s , %s : %s",strName,entry.item:GetName(),entry.item:GetName(),entry.item:GetItemId()))
end

function DKP:PopUpCheckUpdate()
	if not currEntry then
		currEntry = tQueue[1]
		table.remove(tQueue,1)
	end
	self:PopUpPopulate()
end

function DKP:PopUpPopulate()
	if not currEntry then 
		self.wndPopUp:Show(false,false)
		return 
	end
	self.wndPopUp:FindChild("LabelName"):SetText(currEntry.strName)
	self.wndPopUp:FindChild("LabelItem"):SetText(currEntry.item:GetName())
	self.wndPopUp:FindChild("LabelCurrency"):SetText(self.tItems["EPGP"].Enable == 1 and "GP." or "DKP.")
	self.wndPopUp:FindChild("GPOffspec"):Show(self.tItems["EPGP"].Enable == 1 and true or false)
	self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
	self.wndPopUp:FindChild("EditBoxDKP"):SetText(currEntry.nGP)
	self.wndPopUp:FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(currEntry.item:GetItemQuality()))
	self.wndPopUp:FindChild("ItemIcon"):SetSprite(currEntry.item:GetIcon())
	Tooltip.GetItemTooltipForm(self,self.wndPopUp:FindChild("Frame"),currEntry.item,{})

	self.wndPopUp:FindChild("QueueLength"):SetText(#tQueue)
	if #tQueue == 0 then
		self.wndPopUp:FindChild("ButtonSkip"):Enable(false)
	else
		self.wndPopUp:FindChild("ButtonSkip"):Enable(true)
	end
	self.wndPopUp:Show(true,false)
	self.wndPopUp:ToFront()
end

function DKP:PopUpAssign(entry,nPrice)
	if not nPrice then nPrice = self:PopUpGetCurrentPrice() end
	if not nPrice then return end
	if not entry then entry = currEntry end
	if not entry then return end
	-- Data provided let's go!

	self:UndoAddActivity(string.format(ktUndoActions["maward"],entry.strName,entry.item:GetName()),nPrice,{[1] = self.tItems[self:GetPlayerByIDByName(entry.strName)]},nil,"--")
	if self.tItems["settings"].bLLAfterPopUp then self:LLAddLog(entry.strName,entry.item:GetName()) end
	self:LLUpdateItemCost(entry.strName,entry.item:GetItemId(),nPrice)
	local ID = self:GetPlayerByIDByName(entry.strName)

	if self.tItems["EPGP"].Enable == 1 then
		self:EPGPAdd(entry.strName,nil,nPrice)
		self:DetailAddLog(entry.item:GetName(),"{GP}",nPrice,self:GetPlayerByIDByName(entry.strName))
	else
		self.tItems[ID].net = self.tItems[ID].net - nPrice
		self:DetailAddLog(entry.item:GetName(),"{DKP}",nPrice,self:GetPlayerByIDByName(entry.strName))
	end

	currEntry = nil
	self:PopUpCheckUpdate()

	if self.tItems[ID].wnd then self:UpdateItem(self.tItems[ID]) end
end

function DKP:PopUpGetCurrentPrice()
	return tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())
end

function DKP:PopUpIsBidWinner(strName)
	if not self.tItems["settings"].bSkipBidders then return false end
	for i,strBidder in ipairs(self.tPopUpExceptions) do
		if strName == strBidder then 
			table.remove(self.tPopUpExceptions,i)
			return true 
		end
	end
	return false
end

function DKP:PopUpForceClose( wndHandler, wndControl, eMouseButton )
	tQueue = {}
	currEntry = nil
	self:PopUpCheckUpdate()
end

function DKP:PopUpSkip( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("PopUpSkip")
	currEntry = nil
	self:PopUpCheckUpdate()
end

---------------------------------------------------------------------------------------------------
-- StandbyList Functions
---------------------------------------------------------------------------------------------------
local selectedStandby = {}

function DKP:StandbyListAdd( wndHandler, wndControl, strText )
	if self:GetPlayerByIDByName(strText) ~= -1 then
		self.tItems["Standby"][string.lower(strText)] = {}
		self.tItems["Standby"][string.lower(strText)].strName = strText
		self.tItems["Standby"][string.lower(strText)].strDate = self:ConvertDate(os.date("%x",os.time()))
	end
	if self.wndStandby:IsShown() then self:StandbyListPopulate() end
	if wndControl ~= nil then wndControl:SetText("") end
end

function DKP:StandbyListRemove( wndHandler, wndControl, eMouseButton,strText )
	if type(strText) == "boolean" then 
		for k,item in ipairs(selectedStandby) do
			self.tItems["Standby"][string.lower(item)] = nil
		end
	else
		for k,item in pairs(self.tItems["Standby"]) do
			if string.lower(k) == string.lower(strText) then self.tItems["Standby"][k] = nil end
		end
	end
	if self.wndStandby:IsShown() then self:StandbyListPopulate() end
end

function DKP:StandbyListClose( wndHandler, wndControl, eMouseButton )
	self.wndStandby:Show(false,false)
end

function DKP:StandbyListShow( wndHandler, wndControl, eMouseButton )
	self.wndStandby:Show(true,false)
	self:StandbyListPopulate()
	self.wndStandby:ToFront()
end

function DKP:StandbyListPopulate()
	selectedStandby = {}
	self.wndStandby:FindChild("List"):DestroyChildren()
	for k,item in pairs(self.tItems["Standby"]) do
		local wnd = Apollo.LoadForm(self.xmlDoc2,"ItemStandby",self.wndStandby:FindChild("List"),self)
		wnd:FindChild("PlayerName"):SetText(self.tItems["Standby"][k].strName)
		wnd:FindChild("Date"):SetText(self.tItems["Standby"][k].strDate)
	end
	self.wndStandby:FindChild("List"):ArrangeChildrenVert()
end

function DKP:StandbyLisItemSelected( wndHandler, wndControl, eMouseButton )
	table.insert(selectedStandby,string.lower(wndControl:FindChild("PlayerName"):GetText()))
end

function DKP:StandbyListItemDeselected( wndHandler, wndControl, eMouseButton )
	for k,item in ipairs (selectedStandby) do
		if string.lower(item) == string.lower(wndControl:FindChild("PlayerName"):GetText()) then
			table.remove(selectedStandby,k)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Data Sharing
-----------------------------------------------------------------------------------------------

function DKP:DSInit()
	self.wndDS = Apollo.LoadForm(self.xmlDoc,"DataSharing",nil,self)
	self.wndDS:Show(false,true)
	
	if self.tItems["settings"].DS == nil then self.tItems["settings"].DS = {} end
	if self.tItems["settings"].DS.enable == nil then self.tItems["settings"].DS.enable = true end
	if self.tItems["settings"].DS.raidMembersOnly == nil then self.tItems["settings"].DS.raidMembersOnly = false end
	if self.tItems["settings"].DS.aboutRaidMembers == nil then self.tItems["settings"].DS.aboutRaidMembers = false end
	if self.tItems["settings"].DS.logs == nil then self.tItems["settings"].DS.logs = true end
	if self.tItems["settings"].DS.tLogs == nil then self.tItems["settings"].DS.tLogs = {} end
	if self.tItems["settings"].DS.shareLogs == nil then self.tItems["settings"].DS.shareLogs = true end
	
	if self.tItems["settings"].DS.enable then self.wndDS:FindChild("AllowShare"):SetCheck(true) end
	if self.tItems["settings"].DS.raidMembersOnly then self.wndDS:FindChild("ShareMembers"):SetCheck(true) end
	if self.tItems["settings"].DS.aboutRaidMembers then self.wndDS:FindChild("ShareAboutMembers"):SetCheck(true) end
	if self.tItems["settings"].DS.logs then self.wndDS:FindChild("Logs"):SetCheck(true) end
	if self.tItems["settings"].DS.shareLogs then self.wndDS:FindChild("AllowLogs"):SetCheck(true) end
	
end

--- wnd logic

function DKP:DSShow()
	self.wndDS:Show(true,false)
	self.wndDS:ToFront()
	self:DSPopulateLogs()
end

function DKP:DSClose()
	self.wndDS:Show(false,true)
end

--- controls logic

function DKP:DSAboutMembersEnable()
	self.tItems["settings"].DS.aboutRaidMembers = true
end

function DKP:DSAboutMembersDisable()
	self.tItems["settings"].DS.aboutRaidMembers = false
end

function DKP:DSOnlyMembersEnable()
	self.tItems["settings"].DS.raidMembersOnly = true
end

function DKP:DSOnlyMembersDisable()
	self.tItems["settings"].DS.raidMembersOnly = false
end

function DKP:DSEnable()
	self.tItems["settings"].DS.enable = true
end

function DKP:DSDisable()
	self.tItems["settings"].DS.enable = false
end

function DKP:DSLogsEnable()
	self.tItems["settings"].DS.logs = true
end

function DKP:DSLogsDisable()
	self.tItems["settings"].DS.logs = false
end

function DKP:DSLogsShareEnable()
	self.tItems["settings"].DS.shareLogs = true
end

function DKP:DSLogsShareDisable()
	self.tItems["settings"].DS.shareLogs = false
end

function DKP:DSAddLog(strRequester,state)
	table.insert(self.tItems["settings"].DS.tLogs,1,{strPlayer = strRequester,strState = state})
	if #self.tItems["settings"].DS.tLogs > 30 then table.remove(self.tItems["settings"].DS.tLogs,30) end
	self:DSPopulateLogs()
end

--- Data preparation

function DKP:DSGetEncodedStandings(strRequester)
	
	if self.tItems["settings"].DS.raidMembersOnly and not self:IsPlayerInRaid(strRequester) then 
		if self.tItems["settings"].DS.logs then self:DSAddLog(strRequester,"Fail") end
		return "Only Raid Members can fetch data" 
	end
	
	local tStandings = {}
	tStandings.EPGP = self.tItems["EPGP"].Enable
	for k,player in ipairs(self.tItems) do
		if self.tItems["settings"].DS.aboutRaidMembers and self:IsPlayerInRaid(player.strName) or not self.tItems["settings"].DS.aboutRaidMembers then
			tStandings[player.strName] = {}
			tStandings[player.strName].class = player.class
			if self.tItems["EPGP"].Enable == 1 then
				tStandings[player.strName].EP = player.EP
				tStandings[player.strName].GP = player.GP
				tStandings[player.strName].PR = self:EPGPGetPRByName(player.strName)
			else
				tStandings[player.strName].net = player.net
				tStandings[player.strName].tot = player.tot
			end
		end
	end
	if self.tItems["settings"].DS.logs then
		self:DSAddLog(strRequester,"Succes")
	end
	
	return Base64.Encode(serpent.dump(tStandings))
end

function DKP:DSGetEncodedLogs(strRequester)
	if self.tItems["settings"].DS.shareLogs then
		local ID = self:GetPlayerByIDByName(strRequester)
		if ID ~= -1 then
			if self.tItems["settings"].DS.logs then self:DSAddLog(strRequester,"Logs") end
			local tLogs = self.tItems[ID].logs
			return Base64.Encode(serpent.dump(tLogs))
		end
	end
	return "Only Raid Members can fetch data"
end

function DKP:DSPopulateLogs()
	local strLogs = ""
	for k,entry in ipairs(self.tItems["settings"].DS.tLogs) do
		if entry.strPlayer then
			strLogs = strLogs .. entry.strPlayer .. " :\n " .. entry.strState .. "\n"
		end
	end
	self.wndDS:FindChild("LogsBox"):SetText(strLogs)
end
-----------------------------------------------------------------------------------------------
-- Context Menu
-----------------------------------------------------------------------------------------------

function DKP:ConInit()
	self.wndContext = Apollo.LoadForm(self.xmlDoc,"PlayerContext",nil,self)
	self.wndContext:Show(false,true)
end

function DKP:ConChangeClass(wndHandler,wndControl)
	local strCurrClass = wndControl:GetText()
	if strCurrClass == "Esper" then strCurrClass = "Medic" 
	elseif strCurrClass == "Medic" then strCurrClass = "Warrior" 
	elseif strCurrClass == "Warrior" then strCurrClass = "Stalker" 
	elseif strCurrClass == "Stalker" then strCurrClass = "Engineer" 
	elseif strCurrClass == "Engineer" then strCurrClass = "Spellslinger" 
	elseif strCurrClass == "Spellslinger" then strCurrClass = "Esper"
	elseif strCurrClass == "Set Class" then strCurrClass = "Esper"
	end
	wndControl:SetText(strCurrClass)
	self.tItems[self.wndContext:GetData()].class = strCurrClass
	self.wndContext:FindChild("Class"):FindChild("ClassIcon"):SetSprite(ktStringToIcon[strCurrClass])
end

function DKP:ConChangeClassInverted(wndHandler,wndControl)
	local strCurrClass = wndControl:GetText()
	if strCurrClass == "Medic" then strCurrClass = "Esper" 
	elseif strCurrClass == "Warrior" then strCurrClass = "Medic" 
	elseif strCurrClass == "Stalker" then strCurrClass = "Warrior" 
	elseif strCurrClass == "Engineer" then strCurrClass = "Stalker" 
	elseif strCurrClass == "Spellslinger" then strCurrClass = "Engineer" 
	elseif strCurrClass == "Esper" then strCurrClass = "Spellslinger"
	elseif strCurrClass == "Set Class" then strCurrClass = "Esper"
	end
	wndControl:SetText(strCurrClass)
	self.tItems[self.wndContext:GetData()].class = strCurrClass
	self.wndContext:FindChild("Class"):FindChild("ClassIcon"):SetSprite(ktStringToIcon[strCurrClass])
end

function DKP:ConChangeRole(wndHandler,wndControl)
	local strRole = self:ConGetNextRole(self.tItems[self.wndContext:GetData()])
	self.tItems[self.wndContext:GetData()].role = strRole
	wndControl:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[strRole])
	wndControl:SetText(strRole)
end

function DKP:ConChangeOffRole(wndHandler,wndControl)
	local strRole = self:ConGetNextOffRole(self.tItems[self.wndContext:GetData()])
	self.tItems[self.wndContext:GetData()].offrole = strRole
	wndControl:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[strRole])
	wndControl:SetText(strRole)
end

function DKP:ConGetNextRole(player)
	if player.class == "Spellslinger" or player.class == "Esper" or player.class == "Medic" then
		if player.role then
			if player.role == "DPS" then return "Heal" else return "DPS" end
		else
			return "DPS"
		end
	else
		if player.role then
			if player.role == "DPS" then return "Tank" else return "DPS" end
		else
			return "DPS"
		end
	end
end

function DKP:ConGetNextOffRole(player)
	if player.class == "Spellslinger" or player.class == "Esper" or player.class == "Medic" then
		if player.offrole then
			if player.offrole == "DPS" then return "Heal" 
			elseif player.offrole == "Heal" then return "None" 
			elseif player.offrole == "None" then return "DPS" 
			end
		else
			return "DPS"
		end
	else
		if player.offrole then
			if player.offrole == "DPS" then return "Tank" 
			elseif player.offrole == "Tank" then return "None" 
			elseif player.offrole == "None" then return "DPS" 
			end
		else
			return "DPS"
		end
	end
end

function DKP:ConShow(wndHandler,wndControl,eMouseButton)
	if wndControl ~= wndHandler then return end
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and self:LabelGetColumnNumberForValue("Name") > 0 and wndControl:IsMouseTarget() then 
		Event_FireGenericEvent("ContextMenuOpen")
		local tCursor = Apollo.GetMouse()
		self.wndContext:Move(tCursor.x, tCursor.y, self.wndContext:GetWidth(), self.wndContext:GetHeight())
		self.wndContext:Show(true,false)
		local ID = self:GetPlayerByIDByName(wndControl:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
		self.wndContext:SetData(ID) -- PlayerID
		self.wndContext:ToFront()
		if self.tItems["Standby"] and self.tItems[ID] and self.tItems["Standby"][string.lower(self.tItems[ID].strName)] ~= nil then self.wndContext:FindChild("Standby"):SetCheck(true) else self.wndContext:FindChild("Standby"):SetCheck(false) end
		wndControl:FindChild("OnContext"):Show(true,false)
		self.wndContext:FindChild("Class"):SetText(self.tItems[ID].class or "Set Class") 
		if self.tItems[ID].class then
			self.wndContext:FindChild("Class"):FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
		end
		if self.tItems[ID].role then
			self.wndContext:FindChild("MainRole"):SetText(self.tItems[ID].role)
			self.wndContext:FindChild("MainRole"):FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[self.tItems[ID].role])			
		end
		if self.tItems[ID].offrole then
			self.wndContext:FindChild("OffspecRole"):SetText(self.tItems[ID].offrole)
			self.wndContext:FindChild("OffspecRole"):FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[self.tItems[ID].offrole])
		end
	end
end

function DKP:ConAlts()
	self:AltsShow()
end

function DKP:ConLogs()
	self:LogsShow()
end

function DKP:ConRename()
	self:RenameShow(self.wndContext:GetData())
end

function DKP:ConLootLogs()
	self:LLOpen({[1] = self.wndContext:GetData()})
end

function DKP:ConManualAward()
	Event_FireGenericEvent("ManualAssignOpen")
	self:MAOpen(self.wndContext:GetData())
end

function DKP:ConStandbyEnable()
	self:StandbyListAdd(nil,nil,self.tItems[self.wndContext:GetData()].strName)
end

function DKP:ConStandbyDisable()
	self:StandbyListRemove(nil,nil,nil,self.tItems[self.wndContext:GetData()].strName)
end

function DKP:ConRemove(wndHandler,wndControl)
	if not wndControl:FindChild("Confirm"):IsShown() then wndControl:FindChild("Confirm"):Show(true,false) else wndControl:FindChild("Confirm"):Show(false,false) end
end

function DKP:ConRemoveFinal(wndHandler,wndControl)
	local save = self:RaidQueueSaveRestoreAndClear()
	self:StandbyListRemove(nil,nil,nil,self.tItems[self.wndContext:GetData()].strName)
	self:UndoAddActivity(ktUndoActions["remp"],"--",{[1] = self.tItems[self.wndContext:GetData()]},true)
	self:AltsBuildDictionary()
	table.remove(self.tItems,self.wndContext:GetData())
	self.wndContext:Close()
	self.wndSelectedListItem = nil
	wndControl:Show(false,false)
	self:RaidQueueRestore(save)
	self:RefreshMainItemList()
end

function DKP:ConRemoveContextIndicator()
	if self:LabelGetColumnNumberForValue("Name")  > 0 and self.tItems[self.wndContext:GetData()] then
		local name = self.tItems[self.wndContext:GetData()].strName
		local label = "Stat"..self:LabelGetColumnNumberForValue("Name")
		for k,child in ipairs(self:MainItemListGetChildren()) do
			if child:FindChild(label):GetText() == name then
				child:FindChild("OnContext"):Show(false,false)
				break
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Alts
-----------------------------------------------------------------------------------------------

function DKP:AltsShow()
	if not self.wndAlts:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndAlts:Move(tCursor.x, tCursor.y, self.wndAlts:GetWidth(), self.wndAlts:GetHeight())
	end
	self.wndContext:Close()
	self.wndAlts:ToFront()
	
	self.wndAlts:Show(true,false)
	self.wndAlts:SetData(self.wndContext:GetData())
	
	if self.tItems[self.wndAlts:GetData()].alts == nil then self.tItems[self.wndAlts:GetData()].alts = {} end
	
	self.wndAlts:FindChild("Player"):SetText(self.tItems[self.wndAlts:GetData()].strName)
	self.wndAlts:FindChild("FoundBox"):Show(false,false)
	self:AltsPopulate()
end

function DKP:AltsPopulate()
	self.wndAlts:FindChild("List"):DestroyChildren()
	for k,alt in ipairs(self.tItems[self.wndAlts:GetData()].alts) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"AltBar",self.wndAlts:FindChild("List"),self)
		wnd:FindChild("AltName"):SetText(alt)
		wnd:SetData(k)
	end
	self.wndAlts:FindChild("List"):ArrangeChildrenVert()
end

function DKP:AltsRemove(wndHandler,wndControl)
	table.remove(self.tItems[self.wndAlts:GetData()].alts,wndControl:GetParent():GetData())
	self.tItems["alts"][string.lower(wndControl:GetParent():FindChild("AltName"):GetText())] = nil
	self:AltsPopulate()
end

function DKP:AltsAdd()
	local strAlt = self.wndAlts:FindChild("NewAltBox"):GetText()
	if string.lower(strAlt) == string.lower(self.tItems[self.wndAlts:GetData()].strName) then return end
	self.wndAlts:FindChild("FoundBox"):Show(false,false)
	local ID 
	for k,player in ipairs(self.tItems) do if string.lower(player.strName) == string.lower(strAlt) then ID = k break end end
	if ID == nil then -- just add
		if self.tItems["alts"][strAlt] == nil then
			table.insert(self.tItems[self.wndAlts:GetData()].alts,strAlt)
			self.tItems["alts"][strAlt] = self.wndAlts:GetData()
			self.wndAlts:FindChild("NewAltBox"):SetText("")
			self.wndAlts:FindChild("FoundBox"):Show(false,false)
			self:AltsPopulate()
		else
			Print("Alt already registred") 
		end
	elseif self.tItems["alts"][strAlt] == nil then -- further input required
		self.wndAlts:FindChild("FoundBox"):Show(true,false)
	else
		Print("Alt already registred") 
	end
end

function DKP:AltsAddMerge()
	local mergedPlayer = self.tItems[self:GetPlayerByIDByName(self.wndAlts:FindChild("NewAltBox"):GetText())]
	local save = self:RaidQueueSaveRestoreAndClear()
	self.tItems[self.wndAlts:GetData()].net =  self.tItems[self.wndAlts:GetData()].net + mergedPlayer.net
	self.tItems[self.wndAlts:GetData()].tot =  self.tItems[self.wndAlts:GetData()].tot + mergedPlayer.tot
	self.tItems[self.wndAlts:GetData()].EP =  self.tItems[self.wndAlts:GetData()].EP + mergedPlayer.EP
	self.tItems[self.wndAlts:GetData()].GP =  self.tItems[self.wndAlts:GetData()].GP + mergedPlayer.GP
	self.tItems[self.wndAlts:GetData()].Hrs =  self.tItems[self.wndAlts:GetData()].Hrs + mergedPlayer.Hrs
	
	local recipent = self.tItems[self.wndAlts:GetData()].strName
	
	if self.tItems["settings"].bTrackUndo then
		self:UndoAddActivity(string.format(ktUndoActions["amrg"],mergedPlayer.strName,recipent),"--",{[1] = mergedPlayer},true,nil,true)
	end
	table.remove(self.tItems,self:GetPlayerByIDByName(self.wndAlts:FindChild("NewAltBox"):GetText()))
	
	for k,player in ipairs(self.tItems) do if player.strName == recipent then self.wndAlts:SetData(k) end end
	
	table.insert(self.tItems[self.wndAlts:GetData()].alts,self.wndAlts:FindChild("NewAltBox"):GetText())
	
	self.tItems["alts"][string.lower(self.wndAlts:FindChild("NewAltBox"):GetText())] = self.wndAlts:GetData()
	self.wndAlts:FindChild("NewAltBox"):SetText("")
	self:RaidQueueRestore(save)
	self:RefreshMainItemList()
	self.wndAlts:FindChild("FoundBox"):Show(false,false)
	self:AltsPopulate()
end

function DKP:AltsDictionaryShow()
	self.wndAltsDict:Show(true,false)
	self.wndAltsDict:ToFront()
	
	local strAlts = ""
	for alt , owner in pairs(self.tItems["alts"]) do
		if self.tItems[owner] then
			strAlts = strAlts .. self.tItems[owner].strName .. " : " .. alt .. "\n"
		end
	end	
	self.wndAltsDict:FindChild("List"):SetText(strAlts)
	
end

function DKP:AltsBuildDictionary()
	self.tItems["alts"] = {}
	for k , player in ipairs(self.tItems) do
		for j , alt in ipairs(player.alts) do
			self.tItems["alts"][string.lower(alt)] =  k
		end
	end
end

function DKP:AltsDictionaryHide()
	self.wndAltsDict:Show(false,false)
end

function DKP:AltsAddConvert()
	local recipent = self.tItems[self.wndAlts:GetData()].strName
	local save = self:RaidQueueSaveRestoreAndClear()
	local convertedPlayer = self.tItems[self:GetPlayerByIDByName(self.wndAlts:FindChild("NewAltBox"):GetText())]
	if self.tItems["settings"].bTrackUndo then
		self:UndoAddActivity(string.format(ktUndoActions["acon"],convertedPlayer.strName,recipent),"--",{[1] = convertedPlayer},true,nil,true)
	end

	table.remove(self.tItems,self:GetPlayerByIDByName(self.wndAlts:FindChild("NewAltBox"):GetText()))
	
	for k,player in ipairs(self.tItems) do if player.strName == recipent then self.wndAlts:SetData(k) end end
	
	table.insert(self.tItems[self.wndAlts:GetData()].alts,self.wndAlts:FindChild("NewAltBox"):GetText())

	self.tItems["alts"][string.lower(self.wndAlts:FindChild("NewAltBox"):GetText())] = self.wndAlts:GetData()
	self.wndAlts:FindChild("NewAltBox"):SetText("")
	self:RaidQueueRestore(save)
	self:RefreshMainItemList()
	self.wndAlts:FindChild("FoundBox"):Show(false,false)
	self:AltsPopulate()
end

function DKP:AltsInit()
	self.wndAlts = Apollo.LoadForm(self.xmlDoc,"Alts",nil,self)
	self.wndAltsDict = Apollo.LoadForm(self.xmlDoc2,"AltsDictionary",nil,self)
	self.wndAlts:Show(false,true)
	self.wndAltsDict:Show(false,true)
	self.wndAlts:FindChild("Art"):SetOpacity(.5)
end

function DKP:AltsClose()
	self.wndAlts:Show(false,false)
end

-----------------------------------------------------------------------------------------------
-- Logs
-----------------------------------------------------------------------------------------------

function DKP:LogsInit()
	self.wndLogs = Apollo.LoadForm(self.xmlDoc,"Logs",nil,self)
	self.wndLogs:Show(false,true)
	self.wndLogs:SetSizingMinimum(751,332)
	self.wndLogs:SetSizingMaximum(751,435)
end

function DKP:LogsExport()
	strExport = ""
	for k,entry in ipairs(self.tItems[self.wndLogs:GetData()].logs) do
		strExport = strExport .. entry.strComment .. ";" .. entry.strType .. ";" .. entry.strModifier .. ";" .. (entry.strTimestamp and entry.strTimestamp or self:ConvertDate(os.date("%x",entry.nDate)) .. "  " .. os.date("%X",entry.nDate)) .. "\n"
	end
	self:ExportShowPreloadedText(strExport)
end

function DKP:LogsOpenGuildBank()
	if self:GetPlayerByIDByName("Guild Bank") ~= -1 then self:LogsShow(self:GetPlayerByIDByName("Guild Bank")) end
end

function DKP:LogsShow(nOverride)
	if not self.wndLogs:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndLogs:Move(tCursor.x - 100, tCursor.y - 100, self.wndLogs:GetWidth(), self.wndLogs:GetHeight())
	end
	
	self.wndContext:Close()
	self.wndLogs:Show(true,false)
	self.wndLogs:ToFront()
	
	if nOverride then self.wndContext:SetData(nOverride) end
	
	self.wndLogs:SetData(self.wndContext:GetData())
	
	if self.tItems[self.wndLogs:GetData()].logs == nil then self.tItems[self.wndLogs:GetData()].logs = {} end
	
	self.wndLogs:FindChild("Player"):SetText(self.tItems[self.wndLogs:GetData()].strName)
	self:LogsPopulate()
	
end

function DKP:LogsPopulate()
	local grid = self.wndLogs:FindChild("Grid")
	grid:DeleteAll()
	for k,entry in ipairs(self.tItems[self.wndLogs:GetData()].logs) do
		grid:AddRow(k..".")
		grid:SetCellData(k,1,entry.strComment)
		grid:SetCellData(k,4,entry.strType)
		if entry.strModifier then
			grid:SetCellData(k,2,entry.strModifier)
		end
		if entry.strTimestamp then
			grid:SetCellData(k,5,entry.strTimestamp)
		elseif entry.nDate then
			grid:SetCellData(k,5,self:ConvertDate(os.date("%x",entry.nDate)) .. "  " .. os.date("%X",entry.nDate))
		end
		if entry.nAfter then
			grid:SetCellData(k,3,entry.nAfter)
		end
	end
end

function DKP:DetailAddLog(strCommentPre,strType,strModifier,ID)
	if self.tItems["settings"].logs == 1 then
		local strComment = ""
		for uchar in string.gfind(strCommentPre, "([%z\1-\127\194-\244][\128-\191]*)") do
			if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
			strComment = strComment .. uchar
		end
	
		local after
		if strType == "{EP}" then after = self.tItems[ID].EP
		elseif strType == "{GP}" then after = self.tItems[ID].GP
		elseif strType == "{DKP}" then after = self.tItems[ID].net
		elseif strType == "{Decay}" and string.find(strComment,"GP") then after = self.tItems[ID].GP
		elseif strType == "{Decay}" and string.find(strComment,"EP") then after = self.tItems[ID].EP
		elseif strType == "{Decay}" and string.find(strComment,"DKP") then after = self.tItems[ID].net
		end

		if strType == "{Decay}" and self.tItems[ID].strName == "Guild Bank" then return end

		table.insert(self.tItems[ID].logs,1,{strComment = strComment,strType = strType, strModifier = strModifier,nDate = os.time(),nAfter = (after == nil and "" or after)})
		if #self.tItems[ID].logs >= 15 then 
			for k=15,#self.tItems[ID].logs do
				self.tItems[ID].logs[k] = nil
			end
		end
		if self.wndLogs:GetData() == ID then self:LogsPopulate() end

	end
end

function DKP:LogsClose()
	self.wndLogs:Show(false,false)
end

-----------------------------------------------------------------------------------------------
-- RaidQueue
-----------------------------------------------------------------------------------------------

function DKP:RaidQueueAdd(wndHandler,wndControl)
	table.insert(self.tItems.tQueuedPlayers,wndControl:GetParent():GetData())
	self:RaidQueueShowClearButton()
end

function DKP:RaidQueueRemove(wndHandler,wndControl)
	for k,player in ipairs(self.tItems.tQueuedPlayers) do
		if player == wndControl:GetParent():GetData() then table.remove(self.tItems.tQueuedPlayers,k) break end
	end
	if not self.wndMain:FindChild("RaidQueue"):IsChecked() then wndControl:Show(false) end
	if self.wndMain:FindChild("RaidOnly"):IsChecked() then self:RefreshMainItemList() end
	self:RaidQueueShowClearButton()
end

function DKP:IsPlayerInQueue(strPlayer,ID)
	if ID and self.tItems[ID] then strPlayer = self.tItems[ID].strName end
	for k,player in ipairs(self.tItems.tQueuedPlayers) do
		if self.tItems[player] then
			if self.tItems[player].strName == strPlayer then return true end
		end
	end
	return false
end

function DKP:RaidQueueClear(bShow)
	self.tItems.tQueuedPlayers = {}
	for k,child in ipairs(self:MainItemListGetChildren()) do
		child:FindChild("Standby"):SetCheck(false)
	end
	if self.wndMain:FindChild("RaidOnly"):IsChecked() then self:RefreshMainItemList() end
	if not bShow then self:RaidQueueShow() end
end

function DKP:RaidQueueSaveRestoreAndClear()
	local tNames = {}
	for k,player in ipairs(self.tItems.tQueuedPlayers) do
		if self.tItems[player] then
			table.insert(tNames,self.tItems[player].strName)
		end
	end
	self:RaidQueueClear(true)
	return tNames
end

function DKP:RaidQueueRestore(tNames)
	if not tNames then return end
	for k , name in ipairs(tNames) do
		if self:GetPlayerByIDByName(name) ~= -1 then
			table.insert(self.tItems.tQueuedPlayers,self:GetPlayerByIDByName(name))
		end
	end
end

function DKP:RaidQueueShow()
	for k,child in ipairs(self:MainItemListGetChildren()) do
		Print(child:GetName())
		if self.wndMain:FindChild("RaidQueue"):IsChecked() then child:FindChild("Standby"):Show(true,false) else child:FindChild("Standby"):Show(false,false) end
		if self:IsPlayerInQueue(nil,child:GetData()) then 
			child:FindChild("Standby"):Show(true,false)
			child:FindChild("Standby"):SetCheck(true) 
		end
	end
	self:RaidQueueShowClearButton()
end

function DKP:RaidQueueHide()
	for k,child in ipairs(self:MainItemListGetChildren()) do
		if not self:IsPlayerInQueue(nil,child:GetData()) then
			child:FindChild("Standby"):Show(false,false)
		end
	end
end

function DKP:RaidQueueShowClearButton()
	if #self.tItems.tQueuedPlayers > 0 then self.wndMain:FindChild("ClearQueue"):Show(true) else self.wndMain:FindChild("ClearQueue"):Show(false) end
end

-----------------------------------------------------------------------------------------------
-- CustomEvents
-----------------------------------------------------------------------------------------------

local tCreatedEvent = {}

function DKP:CEInit()
	self.wndCE = Apollo.LoadForm(self.xmlDoc,"CustomEvents",nil,self)
	
	--self.wndCE:SetSizingMaximum(692,700)
	--self.wndCE:SetSizingMinimum(692,414)
	
	self.wndCEL = Apollo.LoadForm(self.xmlDoc,"HandledEventsList",nil,self)
	self.wndCEL:Show(false,true)
	self.wndCE:Show(false,true)
	self.wndCE:FindChild("IfBoss"):Show(false,true)
	self.wndCE:FindChild("IfUnit"):Show(false,true)
	
	if self.tItems["settings"].CEEnable == nil then self.tItems["settings"].CEEnable = false end
	if self.tItems["settings"].CERaidOnly == nil then self.tItems["settings"].CERaidOnly = false end
	if self.tItems["settings"].CENotifyChat == nil then self.tItems["settings"].CENotifyChat = false end
	if self.tItems["settings"].CENotifyScreen == nil then self.tItems["settings"].CENotifyScreen = true end
	if self.tItems["settings"].CENotifyScreenTime == nil then self.tItems["settings"].CENotifyScreenTime = 5 end
	
	self.wndCE:FindChild("Enable"):SetCheck(self.tItems["settings"].CEEnable)
	self.wndCE:FindChild("RaidOnly"):SetCheck(self.tItems["settings"].CERaidOnly)
	self.wndCE:FindChild("Notify"):SetCheck(self.tItems["settings"].CENotifyChat)
	self.wndCE:FindChild("NotifyScreen"):SetCheck(self.tItems["settings"].CENotifyScreen)
	self.wndCE:FindChild("NotifyLength"):SetText(self.tItems["settings"].CENotifyScreenTime)
	self.wndCE:FindChild("Success"):SetOpacity(0)
	if self.tItems["settings"].CEEnable then Apollo.RegisterEventHandler("CombatLogDamage","CEOnUnitDamage", self) end
	
	self.wndCE:FindChild("ArrowArt"):SetRotation(270)
	
	if self.tItems["CE"] == nil then self.tItems["CE"] = {} end
end

function DKP:CEHideSuccess()
	self.wndCE:FindChild("Success"):SetOpacity(0)
end

function DKP:CEShow()
	if not self.wndCE:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndCE:Move(tCursor.x - 500, tCursor.y - 450, self.wndCE:GetWidth(), self.wndCE:GetHeight())
	end
	
	self.wndCE:Show(true,false)
	self.wndCE:ToFront()
	self:CEPopulate()
end

function DKP:CEHide(tContext)
	self.wndCE:Show(false,false)
end

function DKP:CEEnable()
	self.tItems["settings"].CEEnable = true
	Apollo.RegisterEventHandler("CombatLogDamage","CEOnUnitDamage", self)
end

function DKP:CEDisable()
	self.tItems["settings"].CEEnable = false
	Apollo.RemoveEventHandler("CombatLogDamage",self)
end

function DKP:CERaidOnlyEnable()
	self.tItems["settings"].CERaidOnly = true
end

function DKP:CERaidOnlyDisable()
	self.tItems["settings"].CERaidOnly = false
end

-- Dropdowns

function DKP:CEExpandRecipents()
	self.wndCE:FindChild("RecipentTypeSelection"):SetAnchorOffsets(210,87,418,192)
	self.wndCE:FindChild("RecipentTypeSelection"):SetText("")
	self.wndCE:FindChild("RecipentTypeSelection"):ToFront()
end

function DKP:CECollapseRecipents()
	self.wndCE:FindChild("RecipentTypeSelection"):SetAnchorOffsets(210,87,418,113)
	self.wndCE:FindChild("RecipentTypeSelection"):SetText(tCreatedEvent.rType == "RM" and "Raid Members" or "Raid Members + Queue")
end

function DKP:CEExpandUnits()
	self.wndCE:FindChild("UnitTypeSelection"):SetAnchorOffsets(121,47,246,143)
	self.wndCE:FindChild("UnitTypeSelection"):SetText("")
	self.wndCE:FindChild("UnitTypeSelection"):ToFront()
end

function DKP:CECollapseUnits()
	self.wndCE:FindChild("UnitTypeSelection"):SetAnchorOffsets(121,47,246,72)
	self.wndCE:FindChild("UnitTypeSelection"):SetText(tCreatedEvent.uType)
end

function DKP:CEExpandBosses()
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetAnchorOffsets(68,7,288,131)
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetText("")
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):ToFront()
	self.wndCE:FindChild("RecipentTypeSelection"):SetOpacity(0)
	self.wndCE:FindChild("RecipentTypeSelection"):SetStyle("IgnoreMouse", true)
end

function DKP:CECollapseBosses()
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetAnchorOffsets(69,7,288,29)
	if tCreatedEvent.bType then self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetText(tCreatedEvent.bType) end
	self.wndCE:FindChild("RecipentTypeSelection"):SetOpacity(1)
	self.wndCE:FindChild("RecipentTypeSelection"):SetStyle("IgnoreMouse", false)
end

function DKP:UnitTypeSelected(wndHandler,wndControl)
	tCreatedEvent.uType = wndControl:GetName()
	if wndControl:GetName() == "Unit" then 
		self.wndCE:FindChild("IfUnit"):Show(true)
		self.wndCE:FindChild("IfBoss"):Show(false)
	else
		self.wndCE:FindChild("IfUnit"):Show(false)
		self.wndCE:FindChild("IfBoss"):Show(true)
	end
	self.wndCE:FindChild("UnitTypeSelection"):SetCheck(false)
	self:CECollapseUnits()
end

function DKP:RecipentTypeSelected(wndHandler,wndControl)
	tCreatedEvent.rType = wndControl:GetName()
	self.wndCE:FindChild("RecipentTypeSelection"):SetCheck(false)
	self:CECollapseRecipents()
end

function DKP:BossItemSelected(wndHandler,wndControl)
	tCreatedEvent.bType = wndControl:GetText()
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetCheck(false)
	self:CECollapseBosses()
end

function DKP:CETriggerEvent(eID)
	local event = self.tItems["CE"][eID]
	if event then
		local raid = self:Bid2GetTargetsTable()
		table.insert(raid,GameLib.GetPlayerUnit():GetName())
		if event.uType == "Unit" then strMob = event.strUnit else strMob = event.bType end
		if event.rType == "RMQ" then
			for k,queued in ipairs(self.tItems.tQueuedPlayers) do
				if self.tItems[queued] then 
					local bFound = false
					for k,member in ipairs(raid) do if string.lower(member) == string.lower(self.tItems[queued].strName) then bFound = true break end end
					if not bFound then table.insert(raid,self.tItems[queued].strName) end
				end
			end
		end
		local tMembers = {}
		if self.tItems["settings"].bTrackUndo then
			for k,player in ipairs(raid) do
				local ID = self:GetPlayerByIDByName(player)
				if ID ~= -1 then
					table.insert(tMembers,self.tItems[ID])
				end
			end
			self:UndoAddActivity(string.format(ktUndoActions["cetrig"],strMob,eID),event.EP or event.GP or event.DKP,tMembers)
		end
			local strAwards = ""
			if event.EP then
				strAwards = strAwards .. event.EP .. "EP  "
			end			
			if event.GP then
				strAwards = strAwards .. event.GP .. "GP  "
			end			
			if event.DKP then
				strAwards = strAwards .. event.DKP .. "DKP "
			end
			
		if self.tItems["settings"].CENotifyScreen then
			self:NotificationStart(string.format("Award for %s , %s",strMob,strAwards),self.tItems["settings"].CENotifyScreenTime,5)
		end
		
		if self.tItems["settings"].CENotifyChat then
			ChatSystemLib.Command("/party " .. string.format("Award for %s , %s",strMob,strAwards))
		end
		
		for k,member in ipairs(raid) do
			local pID = self:GetPlayerByIDByName(member)
			if pID ~= -1 then
				if event.EP then
					self.tItems[pID].EP = self.tItems[pID].EP + event.EP
					self:DetailAddLog("Award for triggering event : "..eID.." (" .. strMob .. ")","{EP}",event.EP,pID)
				end
				if event.GP then
					self.tItems[pID].GP = self.tItems[pID].GP + event.GP
					self:DetailAddLog("Award for triggering event : "..eID.." (" .. strMob .. ")","{GP}",event.GP,pID)
				end
				if event.DKP then
					self.tItems[pID].net = self.tItems[pID].net + event.DKP
					self.tItems[pID].tot = self.tItems[pID].tot + event.DKP
					self:DetailAddLog("Award for triggering event : "..eID.." (" .. strMob .. ")","{DKP}",event.DKP,pID)
				end
			end
		end
		event.nTriggerCount = event.nTriggerCount + 1
		if self.tItems["settings"].tCETriggeredEvents == nil then self.tItems["settings"].tCETriggeredEvents = {} end
		table.insert(self.tItems["settings"].tCETriggeredEvents,1,{strEv = "(ID : ".. eID ..") (" .. strMob .. ")",strDate = self:ConvertDate(os.date("%x",os.time())) .. " " .. os.date("%X",os.time())})
		if #self.tItems["settings"].tCETriggeredEvents > 20 then table.remove(self.tItems["settings"].tCETriggeredEvents,20) end
		if self.wndCE:IsShown() then self:CEPopulate() end

	end
end

function DKP:CEPopulate()
	local grid = self.wndCE:FindChild("Grid")
	grid:DeleteAll()
	if self.tItems["settings"].tCETriggeredEvents == nil then self.tItems["settings"].tCETriggeredEvents = {} end
	for k,entry in ipairs(self.tItems["settings"].tCETriggeredEvents) do
		grid:AddRow(k)
		grid:SetCellData(k,1,entry.strEv)
		grid:SetCellData(k,2,entry.strDate)
	end
end

function DKP:CECreate()
	if tCreatedEvent.uType and tCreatedEvent.rType then
		if tCreatedEvent.uType == "Unit" and tCreatedEvent.strUnit or tCreatedEvent.uType == "Boss" and tCreatedEvent.bType then
			tCreatedEvent.tAwards = {}
			if self.wndCE:FindChild("EP"):IsChecked() then
				tCreatedEvent.EP = tonumber(self.wndCE:FindChild("ValueEP"):GetText())
			end			
			
			if self.wndCE:FindChild("GP"):IsChecked() then
				tCreatedEvent.GP = tonumber(self.wndCE:FindChild("ValueGP"):GetText())
			end			
			
			if self.wndCE:FindChild("DKP"):IsChecked() then
				tCreatedEvent.DKP = tonumber(self.wndCE:FindChild("ValueDKP"):GetText())
			end
			
			table.insert(self.tItems["CE"],{uType = tCreatedEvent.uType,bType = tCreatedEvent.bType,rType = tCreatedEvent.rType,EP = tCreatedEvent.EP,GP = tCreatedEvent.GP,DKP = tCreatedEvent.DKP,strUnit = tCreatedEvent.strUnit,nTriggerCount = 0})
			
			tCreatedEvent.EP = nil
			tCreatedEvent.GP = nil
			tCreatedEvent.DKP = nil
			if self.wndCEL:IsShown() then self:CELPopulate() end
			self.wndCE:FindChild("Success"):SetOpacity(1)
			self:delay(3,self.CEHideSuccess)
			Event_FireGenericEvent("CEEventCreated")
		end
	end
end

function DKP:CESetUnitName(wndHandler,wndControl,strText)
	tCreatedEvent.strUnit = strText
end

function DKP:CERemoveEvent(wndHandler,wndControl)
	if wndControl:GetParent():GetData() then
		table.remove(self.tItems["CE"],wndControl:GetParent():GetData())
		if self.wndCEL:IsShown() then self:CELPopulate() end
	end
end

function DKP:CENotifyEnable()
	self.tItems["settings"].CENotifyChat = true
end

function DKP:CENotifyDisable()
	self.tItems["settings"].CENotifyChat = false
end

function DKP:CENotifyScreenEnable()
	self.tItems["settings"].CENotifyScreen = true
end

function DKP:CENotifyScreenDisable()
	self.tItems["settings"].CENotifyScreen = false
end

function DKP:CESetNotificationTimer(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val > 0 then
		self.tItems["settings"].CENotifyScreenTime = val
	else
		wndControl:SetText(self.tItems["settings"].CENotifyScreenTime)
	end
end

function DKP:CELShow()
	self.wndCEL:Show(true,false)
	self.wndCEL:ToFront()
	self:CELPopulate()
end

function DKP:CELHide()
	self.wndCEL:Show(false,false)
end

function DKP:CELPopulate()
	self.wndCEL:FindChild("List"):DestroyChildren()
	for k,event in ipairs(self.tItems["CE"]) do
		
		local strMob
		if event.uType == "Unit" then 
			strMob = event.strUnit
		else
			strMob = event.bType
		end
		
		if self:string_starts(strMob,self.wndCEL:FindChild("Search"):GetText()) then
			local wnd = Apollo.LoadForm(self.xmlDoc,"CEEntry",self.wndCEL:FindChild("List"),self)
			if event.uType == "Unit" then 
				wnd:FindChild("UnitName"):SetText(event.strUnit)
			else
				wnd:FindChild("UnitName"):SetText(event.bType)
			end
			wnd:FindChild("Recipents"):SetText(event.rType == "RM" and "Raid Members" or "Raid Members + Queue")
			local strAwards = ""
			if event.EP then strAwards = strAwards .. " EP : " .. event.EP end
			if event.GP then strAwards = strAwards .. " GP : " .. event.GP end
			if event.DKP then strAwards = strAwards .. " DKP : " .. event.DKP end
			if strAwards == "" then strAwards = "None" end
			wnd:FindChild("Awards"):SetText(strAwards)
			wnd:FindChild("TriggerCount"):SetText(event.nTriggerCount .. " times.")
			wnd:FindChild("ID"):SetText(k)
			wnd:SetData(k)
		end
	end
	self.wndCEL:FindChild("List"):ArrangeChildrenTiles()
end

local tKilledBossesInSession = {
	tech1 = false,
	tech2 = false,
	tech3 = false,
	tech4 = false,
	techTriggered = false,
	
	born1 = false,
	born2 = false,
	born3 = false,
	born4 = false,
	born5 = false,
	bornTriggerred = false,

}

function DKP:CEOnUnitDamage(tArgs)
	if self.tItems["settings"].CERaidOnly and not GroupLib.InRaid() then return end
	if tArgs.bTargetKilled == false then return end
	if tArgs.unitTarget == nil then return end
	local tUnits = {}
	local tBosses = {}
	
	for k,event in ipairs(self.tItems["CE"]) do 
		if event.uType == "Unit" then table.insert(tUnits,{strUnit = event.strUnit,ID = k}) else table.insert(tBosses,{bType = event.bType,ID = k}) end
	end

	local name = tArgs.unitTarget:GetName()

	-- Counting Council Fights
	if name == "Phagetech Commander" then tKilledBossesInSession.tech1 = true end
	if name == "Phagetech Augmentor" then tKilledBossesInSession.tech2 = true end
	if name == "Phagetech Protector" then tKilledBossesInSession.tech3 = true end
	if name == "Phagetech Fabricator" then tKilledBossesInSession.tech4 = true end
	
	if name == "Ersoth Curseform" then tKilledBossesInSession.born1 = true end
	if name == "Fleshmonger Vratorg" then tKilledBossesInSession.born2 = true end
	if name == "Terex Blightweaver" then tKilledBossesInSession.born3 = true end
	if name == "Golgox the Lifecrusher" then tKilledBossesInSession.born4 = true  end
	if name == "Noxmind the Insidious" then tKilledBossesInSession.born5 = true end
		
		
	
	local bornCounter = 0
	if tKilledBossesInSession.born1 then bornCounter = bornCounter + 1 end 
	if tKilledBossesInSession.born2 then bornCounter = bornCounter + 1 end 
	if tKilledBossesInSession.born3 then bornCounter = bornCounter + 1 end 
	if tKilledBossesInSession.born4 then bornCounter = bornCounter + 1 end 
	if tKilledBossesInSession.born5 then bornCounter = bornCounter + 1 end 
	if #tUnits > 0 then
		for k,unit in ipairs(tUnits) do
			if string.lower(unit.strUnit) == string.lower(name) then
				self:CETriggerEvent(unit.ID)
				return
			end
		end
	end
	
	if #tBosses > 0 then
		for k,boss in ipairs(tBosses) do
			if boss.bType ~= "Phageborn Convergence" and boss.bType ~= "Phagetech Prototypes" then
				if string.lower(boss.bType) == string.lower(name) then
					self:CETriggerEvent(boss.ID)
					break
				end
			else
				if boss.bType == "Phageborn Convergence" and not tKilledBossesInSession.bornTriggerred then
					if bornCounter >= 4 then 
						tKilledBossesInSession.bornTriggerred = true
						self:CETriggerEvent(boss.ID)
						break
					end
				elseif boss.bType == "Phagetech Prototypes" and not tKilledBossesInSession.techTriggered then
					if tKilledBossesInSession.tech1 or tKilledBossesInSession.tech2 or tKilledBossesInSession.tech3 or tKilledBossesInSession.tech4 then
						tKilledBossesInSession.techTriggered = true
						self:CETriggerEvent(boss.ID)
						break
					end
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Invites
-----------------------------------------------------------------------------------------------
local tInvited = {}
function DKP:InvitesInit()
	self.wndInv = Apollo.LoadForm(self.xmlDoc,"InviteDialog",nil,self)
	self.wndInv:Show(false,true)
end

function DKP:InviteOpen(tIDs)
	for k,ID in ipairs(tIDs) do
		local found = false
		for j,inv in ipairs(tInvited) do
			if inv.ID == ID then found = true break end
		end
		if not found then table.insert(tInvited,{ID = ID,status = "P"}) end
	end
	self:InvitePopulate()
end

-- "P" = Pending -- "A" = Accepted 

function DKP:InvitePopulate(bOpen)
	if bOpen == nil then bOpen = true end
	self.wndInv:FindChild("ListInvited"):DestroyChildren()
	
	local nEsper = 0
	local nEngineer = 0
	local nWarrior = 0
	local nMedic = 0
	local nSpellslinger = 0
	local nStalker = 0
	
	local nDPS = 0
	local nHeal = 0
	local nTank = 0
	
	for k,inv in ipairs(tInvited) do
		if inv.status == "P" then
			local player = self.tItems[inv.ID]
			if player.class ~= nil then
				if player.class == "Esper" then
					nEsper = nEsper + 1
				elseif player.class == "Engineer" then
					nEngineer = nEngineer + 1
				elseif player.class == "Medic" then
					nMedic = nMedic + 1
				elseif player.class == "Warrior" then
					nWarrior = nWarrior + 1
				elseif player.class == "Stalker" then
					nStalker = nStalker + 1
				elseif player.class == "Spellslinger" then
					nSpellslinger = nSpellslinger + 1
				end
			end
			
			if player.role == "DPS" then nDPS = nDPS + 1
			elseif player.role == "Heal" then nHeal = nHeal + 1
			elseif player.role == "Tank" then nTank = nTank + 1
			end
			
			local wnd = Apollo.LoadForm(self.xmlDoc,"InviteEntry",self.wndInv:FindChild("ListInvited"),self)
			wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
			wnd:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[player.role])
			wnd:FindChild("CharacterName"):SetText(player.strName)
		end
	end
	
	self.wndInv:FindChild("TotalPending"):SetText(nEsper+nEngineer+nWarrior+nMedic+nSpellslinger+nStalker)
	self.wndInv:FindChild("PendingClasses"):FindChild("Esper"):SetText(nEsper)
	self.wndInv:FindChild("PendingClasses"):FindChild("Engineer"):SetText(nEngineer)
	self.wndInv:FindChild("PendingClasses"):FindChild("Warrior"):SetText(nWarrior)
	self.wndInv:FindChild("PendingClasses"):FindChild("Medic"):SetText(nMedic)
	self.wndInv:FindChild("PendingClasses"):FindChild("Spellslinger"):SetText(nSpellslinger)
	self.wndInv:FindChild("PendingClasses"):FindChild("Stalker"):SetText(nStalker)
	
	self.wndInv:FindChild("PendingRoles"):FindChild("DPS"):SetText(nDPS)
	self.wndInv:FindChild("PendingRoles"):FindChild("Heal"):SetText(nHeal)
	self.wndInv:FindChild("PendingRoles"):FindChild("Tank"):SetText(nTank)
	
	nEsper = 0
	nEngineer = 0
	nWarrior = 0
	nMedic = 0
	nSpellslinger = 0
	nStalker = 0
	
	nDPS = 0
	nHeal = 0
	nTank = 0
		
	for k,inv in ipairs(tInvited) do
		if inv.status == "A" then
			local player = self.tItems[inv.ID]
			if player.class ~= nil then
				if player.class == "Esper" then
					nEsper = nEsper + 1
				elseif player.class == "Engineer" then
					nEngineer = nEngineer + 1
				elseif player.class == "Medic" then
					nMedic = nMedic + 1
				elseif player.class == "Warrior" then
					nWarrior = nWarrior + 1
				elseif player.class == "Stalker" then
					nStalker = nStalker + 1
				elseif player.class == "Spellslinger" then
					nSpellslinger = nSpellslinger + 1
				end
			end
			
			
			if player.role == "DPS" then nDPS = nDPS + 1
			elseif player.role == "Heal" then nHeal = nHeal + 1
			elseif player.role == "Tank" then nTank = nTank + 1
			end
			
			
			local wnd = Apollo.LoadForm(self.xmlDoc,"InviteEntry",self.wndInv:FindChild("ListInvited"),self)
			wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
			wnd:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[player.role])
			wnd:FindChild("CharacterName"):SetText(player.strName)
			wnd:FindChild("Status"):SetSprite("achievements:sprAchievements_Icon_Complete")
		end
	end	
	
	
	self.wndInv:FindChild("TotalAccepted"):SetText(nEsper+nEngineer+nWarrior+nMedic+nSpellslinger+nStalker)
	self.wndInv:FindChild("AcceptedClasses"):FindChild("Esper"):SetText(nEsper)
	self.wndInv:FindChild("AcceptedClasses"):FindChild("Engineer"):SetText(nEngineer)
	self.wndInv:FindChild("AcceptedClasses"):FindChild("Warrior"):SetText(nWarrior)
	self.wndInv:FindChild("AcceptedClasses"):FindChild("Medic"):SetText(nMedic)
	self.wndInv:FindChild("AcceptedClasses"):FindChild("Spellslinger"):SetText(nSpellslinger)
	self.wndInv:FindChild("AcceptedClasses"):FindChild("Stalker"):SetText(nStalker)
	
	self.wndInv:FindChild("AcceptedRoles"):FindChild("DPS"):SetText(nDPS)
	self.wndInv:FindChild("AcceptedRoles"):FindChild("Heal"):SetText(nHeal)
	self.wndInv:FindChild("AcceptedRoles"):FindChild("Tank"):SetText(nTank)
		
	for k,inv in ipairs(tInvited) do
		if inv.status == "D" then
			local player = self.tItems[inv.ID]
			local wnd = Apollo.LoadForm(self.xmlDoc,"InviteEntry",self.wndInv:FindChild("ListInvited"),self)
			wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
			wnd:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[player.role])
			wnd:FindChild("CharacterName"):SetText(player.strName)
			wnd:FindChild("Status"):SetSprite("ClientSprites:LootCloseBox_Holo")
		end
	end
	
	if self.wndInv:FindChild("TotalAccepted"):GetText() == "0" then  self.wndInv:FindChild("TotalAccepted"):SetText("") end
	if self.wndInv:FindChild("TotalPending"):GetText() == "0" then  self.wndInv:FindChild("TotalPending"):SetText("") end
	
	self.wndInv:FindChild("ListInvited"):ArrangeChildrenVert()
	if bOpen then self.wndInv:Show(true,false) end
	
end

function DKP:InviteOnResult(strName,eResult)
	if self.tItems["settings"].bRIEnable and eResult == 2 then
		if self.tItems["settings"].strConfRem == "join" then
			for k , strConfirmed in ipairs(self.tItems["settings"].tConfirmed) do
				if strConfirmed == strName then
					table.remove(self.tItems["settings"].tConfirmed,k)
					break
				end
			end
		end
	end



	if bInviteSuspend and GroupLib.InGroup() then 
		bInviteSuspend = false
		GroupLib.ConvertToRaid()
		self:MassEditInviteContinue()
	end
	if eResult ~= GroupLib.Result.Accepted and eResult ~= GroupLib.Result.Declined and not self.tItems["settings"].bRemErrInv then return
	elseif eResult ~= GroupLib.Result.Accepted and eResult ~= GroupLib.Result.Declined and self.tItems["settings"].bRemErrInv then
		for k,inv in ipairs(tInvited) do
		local player = self.tItems[inv.ID]
		if string.lower(player.strName) == string.lower(strName) then
			table.remove(tInvited,k)
			break
		end
	end
	end
	for k,inv in ipairs(tInvited) do
		local player = self.tItems[inv.ID]
		if string.lower(player.strName) == string.lower(strName) then
			if eResult == GroupLib.Result.Accepted then inv.status = "A"
			elseif eResult == GroupLib.Result.Declined then inv.status = "D" end
			break
		end
	end
	self:InvitePopulate(false)
end

function DKP:InviteClearList()
	tInvited = {}
	self:InvitePopulate()
end

function DKP:InviteHide()
	self.wndInv:Show(false,false)
end

function DKP:InviteShow()
	self.wndInv:Show(true,false)
	self.wndInv:ToFront()
end

-----------------------------------------------------------------------------------------------
-- LootLogs
-----------------------------------------------------------------------------------------------
local ktSlots = 
{
	["Weapon"] = true,
	["Shield"] = true,
	["Head"] = true,
	["Shoulders"] = true,
	["Chest"] = true,
	["Hands"] = true,
	["Legs"] = true,
	["Attachment"] = true,
	["Gadget"] = true,
	["Implant"] = true,
	["Feet"] = true,
	["Support"] = true,
}

local ktClasses =
{
	["Medic"]       	= true,
	["Esper"]       	= true,
	["Warrior"]     	= true,
	["Stalker"]     	= true,
	["Engineer"]    	= true,
	["Spellslinger"]  	= true,
}
local ktTabsSettings = 
{
	["Slots"] =
	{
		bEnable = true,
		strRelation = "AND",
	},	
	["Classes"] =
	{
		bEnable = true,
		strRelation = "AND",
	},	
	["Quality"] =
	{
		bEnable = true,
		strRelation = "AND",
	},
}

function DKP:LLInit()
	self.wndLL = Apollo.LoadForm(self.xmlDoc,"LootLogs",nil,self)
	self.wndLLM = Apollo.LoadForm(self.xmlDoc,"LLMore",nil,self)
	self.wndLL:Show(false,true)
	self.wndLLM:Show(false,true)
	
	if self.tItems.wndLLLoc ~= nil and self.tItems.wndLLLoc.nOffsets[1] ~= 0 then 
		self.wndLL:MoveToLocation(WindowLocation.new(self.tItems.wndLLLoc))
		self.tItems.wndLLLoc = nil
	end
	
	if self.tItems["settings"].LL == nil then self.tItems["settings"].LL = {} end
	if self.tItems["settings"].LL.strGroup == nil then self.tItems["settings"].LL.strGroup = "GroupCategory" end
	--if self.tItems["settings"].LL.strGroup == "GroupName" then self.tItems["settings"].LL.strGroup = "GroupCategory" end
	self.wndLL:FindChild("Controls"):FindChild(self.tItems["settings"].LL.strGroup):SetCheck(true)
	
	if self.tItems["settings"].LL.tSlots == nil then self.tItems["settings"].LL.tSlots = {} end
	if self.tItems["settings"].LL.tClasses == nil then self.tItems["settings"].LL.tClasses = {} end
	if self.tItems["settings"].LL.tQual == nil then self.tItems["settings"].LL.tQual = {} end
	
	if self.tItems["settings"].LL.tSlots["Weapon"] == nil then self.tItems["settings"].LL.tSlots = ktSlots end
	if self.tItems["settings"].LL.tClasses["Esper"] == nil then self.tItems["settings"].LL.tClasses = ktClasses end
	if self.tItems["settings"].LL.tQual["Gray"] == nil then self.tItems["settings"].LL.tQual = ktQual end
	if self.tItems["settings"].LL.tTabsSettings == nil then self.tItems["settings"].LL.tTabsSettings = ktTabsSettings end
	
	if self.tItems["settings"].LL.bEquippable == nil then self.tItems["settings"].LL.bEquippable = false end
	if self.tItems["settings"].LL.nLevel == nil then self.tItems["settings"].LL.nLevel = 1 end
	if self.tItems["settings"].LL.nMaxRows == nil then self.tItems["settings"].LL.nMaxRows = 3 end
	if self.tItems["settings"].LL.nMaxItems == nil then self.tItems["settings"].LL.nMaxItems = 3 end
	if self.tItems["settings"].LL.nMaxDays == nil then self.tItems["settings"].LL.nMaxDays = 3 end
	
	if self.tItems["settings"].LL.strChatPrefix == nil then self.tItems["settings"].LL.strChatPrefix = "party" end
	if self.tItems["settings"].LL.nGP == nil then self.tItems["settings"].LL.nGP = 0 end
	
	self.wndLLM:FindChild("Only"):FindChild("Equip"):SetCheck(self.tItems["settings"].LL.bEquippable)
	self.wndLLM:FindChild("Only"):FindChild("MinLvl"):SetText(self.tItems["settings"].LL.nLevel)
	self.wndLLM:FindChild("Only"):FindChild("MinGP"):SetText(self.tItems["settings"].LL.nGP)
	
	for k,slot in pairs(self.tItems["settings"].LL.tSlots) do
		local wnd = self.wndLLM:FindChild("Only"):FindChild("SlotsTab"):FindChild(k)
		if wnd then
			wnd:SetCheck(slot)
		end
	end	
	for k,class in pairs(self.tItems["settings"].LL.tClasses) do
		local wnd = self.wndLLM:FindChild("Only"):FindChild("ClassesTab"):FindChild(k)
		if wnd then
			wnd:SetCheck(class)
		end
	end	
	for k,qual in pairs(self.tItems["settings"].LL.tQual) do
		local wnd = self.wndLLM:FindChild("Only"):FindChild("QualityTab"):FindChild(k)
		if wnd then
			wnd:SetCheck(qual)
		end
	end
	for k,tab in pairs(self.tItems["settings"].LL.tTabsSettings) do
		local wnd = self.wndLLM:FindChild("Settings"):FindChild("EnableTabs"):FindChild(k)
		if wnd then
			wnd:SetCheck(tab.bEnable)
		end
		wnd = self.wndLLM:FindChild("Settings"):FindChild("TabsRelations"):FindChild(k)
		if wnd then
			wnd:FindChild(tab.strRelation):SetCheck(true)
		end
	end

	self.wndLLM:FindChild("SettingsMisc"):FindChild("MaxRowsTitle"):SetText(string.format("Max rows per bubble. - %d",self.tItems["settings"].LL.nMaxRows))
	self.wndLLM:FindChild("SettingsMisc"):FindChild("MaxItemsTitle"):SetText(string.format("Max items per row. - %d",self.tItems["settings"].LL.nMaxItems))
	self.wndLLM:FindChild("SettingsMisc"):FindChild("MaxDaysTitle"):SetText(string.format("When grouping by day show items form last %s days:",self.tItems["settings"].LL.nMaxDays == 0 and "X" or tostring(self.tItems["settings"].LL.nMaxDays)))
	
	self.wndLLM:FindChild("SlotsTab"):AttachTab(self.wndLLM:FindChild("ClassesTab"),false)
	self.wndLLM:FindChild("SlotsTab"):AttachTab(self.wndLLM:FindChild("QualityTab"),false)
	self.wndLLM:FindChild("SlotsTab"):Lock(true)
	self.wndLLM:FindChild("ClassesTab"):Lock(true)
	self.wndLLM:FindChild("QualityTab"):Lock(true)
	self.wndLLM:FindChild("MaxItems"):SetValue(self.tItems["settings"].LL.nMaxItems)
	self.wndLLM:FindChild("MaxRows"):SetValue(self.tItems["settings"].LL.nMaxRows)
	self.wndLLM:FindChild("MaxDays"):SetValue(self.tItems["settings"].LL.nMaxDays)
	self.wndLLM:FindChild("ChannelPrefix"):SetText(self.tItems["settings"].LL.strChatPrefix)
	self.wndLL:SetSizingMinimum(785,493)
end

function DKP:LLMSetPrefix(wndHandler,wndControl,strText)
	self.tItems["settings"].LL.strChatPrefix = strText
end

function DKP:LLSetMinLevel(wndHandler,wndControl,strText)
	local value = tonumber(strText)
	if value and value > 0 then
		self.tItems["settings"].LL.nLevel = value
	else
		wndControl:SetText(self.tItems["settings"].LL.nLevel)
	end
end

function DKP:LLSetMinGP(wndHandler,wndControl,strText)
	local value = tonumber(strText)
	if value and value >= 0 then
		self.tItems["settings"].LL.nGP = value
	else
		wndControl:SetText(self.tItems["settings"].LL.nGP)
	end
end

function DKP:LLEquippableOnlyEnable()
	self.tItems["settings"].LL.bEquippable = true
end

function DKP:LLEquippableOnlyDisable()
	self.tItems["settings"].LL.bEquippable = false
end

function DKP:LLMShow()
	self.wndLLM:Show(true,false)
	self.wndLLM:ToFront()
	Event_FireGenericEvent("LLMoreOpen")
end

function DKP:LLMHide()
	self.wndLLM:Show(false,false)
end

function DKP:LLFilterAddClass(wndHandler,wndControl)
	self.tItems["settings"].LL.tClasses[wndControl:GetName()] = true
end

function DKP:LLFilterRemClass(wndHandler,wndControl)
	self.tItems["settings"].LL.tClasses[wndControl:GetName()] = false
end

function DKP:LLFilterAddSlot(wndHandler,wndControl)
	self.tItems["settings"].LL.tSlots[wndControl:GetName()] = true
end

function DKP:LLFilterRemSlot(wndHandler,wndControl)
	self.tItems["settings"].LL.tSlots[wndControl:GetName()] = false
end

function DKP:LLFilterAddQuality(wndHandler,wndControl)
	self.tItems["settings"].LL.tQual[wndControl:GetName()] = true
end

function DKP:LLFilterRemQuality(wndHandler,wndControl)
	self.tItems["settings"].LL.tQual[wndControl:GetName()] = false
end

function DKP:LLGroupModeChanged(wndHandler,wndControl)
	self.tItems["settings"].LL.strGroup = wndControl:GetName()
	self:LLPopuplate()
end

function DKP:LLFilterTabRelationChanged(wndHandler,wndControl)
	self.tItems["settings"].LL.tTabsSettings[wndControl:GetParent():GetName()].strRelation = wndControl:GetName()
end

function DKP:LLFilterEnableTab(wndHandler,wndControl)
	self.tItems["settings"].LL.tTabsSettings[wndControl:GetName()].bEnable = true
end

function DKP:LLFilterDisableTab(wndHandler,wndControl)
	self.tItems["settings"].LL.tTabsSettings[wndControl:GetName()].bEnable = false
end

function DKP:LLUpdateItemCost(strName,itemID,nGP)
	local ID = self:GetPlayerByIDByName(strName)
	if ID == -1 then return end
	for k , item in ipairs(self.tItems[ID].tLLogs) do
		if item.itemID == itemID then
			item.nGP = nGP
			break
		end
	end
end

function DKP:LLAddLog(strPlayer,strItem)
	if not self.tItems["settings"].bLootLogs then return end
	local ID = self:GetPlayerByIDByName(strPlayer)
	if ID ~= -1 and self.ItemDatabase[strItem] then
		local item = self.ItemDatabase[strItem].ID
		if item then
			if self.tItems[ID].tLLogs == nil then self.tItems[ID].tLLogs = {} end
			table.insert(self.tItems[ID].tLLogs,1,{itemID = self.ItemDatabase[strItem].ID,nDate = os.time(),nGP = 0})

			if #self.tItems[ID].tLLogs > 50 then table.remove(self.tItems[ID].tLLogs,51) end

		end
	end
	if self.wndLL:IsShown() then self:LLPopuplate() end
end

function DKP:LLRemLog(strPlayer,item)
	for k,entry in ipairs(self.tItems[self:GetPlayerByIDByName(strPlayer)].tLLogs) do
		if entry.itemID == item:GetItemId() then
			table.remove(self.tItems[self:GetPlayerByIDByName(strPlayer)].tLLogs,k)
			return entry.nGP
		end
	end
end

function DKP:LLOpen(tIDs,strMode)
	for k , ID in ipairs(tIDs) do
		if not self.tItems[ID] then table.remove(tIDs,k) end
	end
	self.wndLL:ToFront()
	self.wndLL:SetData({tIDs = tIDs,strMode = strMode})
	self.wndLL:Show(true,false)
	if #tIDs == 1 then
		self.wndLL:FindChild("Controls"):FindChild("Player"):SetText(self.tItems[tIDs[1]].strName)
		self.wndLL:FindChild("Controls"):FindChild("GroupName"):Show(false)
		if self.tItems["settings"].LL.strGroup == "GroupName" then self.tItems["settings"].LL.strGroup = "GroupCategory" end
	else
		self.wndLL:FindChild("Controls"):FindChild("Player"):SetText("Multiple Entries")
		local strTooltip = ""
		for k , ID in ipairs(tIDs) do strTooltip = strTooltip .. self.tItems[ID].strName .. "\n" end
		self.wndLL:FindChild("Controls"):FindChild("Player"):SetTooltip(strTooltip)
		self.wndLL:FindChild("Controls"):FindChild("GroupName"):Show(true)
		self.wndLL:FindChild("Controls"):FindChild("GroupDate"):Show(true)
	end
	self.wndLL:FindChild("Controls"):FindChild(self.tItems["settings"].LL.strGroup):SetCheck(true)
	self:LLPopuplate()
end

function DKP:LLOpenWhole()
	self.wndLL:Show(true,false)
	self.wndLL:SetData({strMode = "AllMode"})
	self.wndLL:FindChild("Controls"):FindChild("Player"):SetText("Whole Roster")
	self.wndLL:FindChild("Controls"):FindChild("GroupName"):Show(true)
	self.wndLL:FindChild("Controls"):FindChild("GroupDate"):Show(true)
	self.wndLL:ToFront()
	self:LLPopuplate()
end

function DKP:LLOpenML()
	self.wndLL:Show(true,false)
	self.wndLL:SetData({strMode = "ML"})
	self.wndLL:FindChild("Controls"):FindChild("Player"):SetText("Master Loot Entries")
	self.wndLL:FindChild("Controls"):FindChild("GroupName"):Show(false)
	self.wndLL:FindChild("Controls"):FindChild("GroupDate"):Show(false)
	self.wndLL:ToFront()
	self:LLPopuplate()
end

function DKP:LLOpenRaid(nStart,nFinish,title)
	self.wndLL:Show(true,false)
	self.wndLL:ToFront()
	self.wndLL:SetData({strMode = "Raid",nStart = nStart,nFinish = nFinish})
	self.wndLL:FindChild("Controls"):FindChild("Player"):SetText(title and title or "Raid Entries")
	self:LLPopuplate()
end

function DKP:LLClose()
	self.wndLL:Show(false,false)
end

function DKP:LLPrepareData()
	local tGrouppedItems = {}
	local tWinnersDictionary = {}
	if self.wndLL:GetData().strMode == "ML" then
		for j , entry in pairs(self.ItemDatabase) do
			local item = Item.GetDataFromId(entry.ID)
			if item and self:LLMeetsFilters(item,"ML","ML") then
				if tGrouppedItems[item:GetItemCategoryName()] == nil then tGrouppedItems[item:GetItemCategoryName()] = {} end
				table.insert(tGrouppedItems[item:GetItemCategoryName()],entry.ID)						
			end
		end
	else
		if self.wndLL:GetData().strMode ~= "AllMode" and self.wndLL:GetData().strMode ~= "Raid" then
			for k , ID in ipairs(self.wndLL:GetData().tIDs) do 
				if self.tItems[ID].tLLogs ~= nil then
					player = self.tItems[ID]
					tWinnersDictionary[self.tItems[ID].strName] = {}
					for k , entry in ipairs(self.tItems[ID].tLLogs) do
						if self.tItems["settings"].LL.strGroup == "GroupName" then
							tGrouppedItems[self.tItems[ID].strName] = {}
							for j , entry in ipairs(self.tItems[ID].tLLogs) do
								if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),self.tItems[ID],entry.nGP) then
									table.insert(tGrouppedItems[self.tItems[ID].strName],entry.itemID)
									table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = self.tItems[ID].strName})
								end
							end
							if #tGrouppedItems[self.tItems[ID].strName] == 0 then tGrouppedItems[self.tItems[ID].strName] = nil end	
						elseif self.tItems["settings"].LL.strGroup == "GroupCategory" then
							local item = Item.GetDataFromId(entry.itemID)
							if item and self:LLMeetsFilters(item,self.tItems[ID],entry.nGP) then
								if tGrouppedItems[item:GetItemCategoryName()] == nil then tGrouppedItems[item:GetItemCategoryName()] = {} end
								table.insert(tGrouppedItems[item:GetItemCategoryName()],entry.itemID)
								table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName,strHeader = item:GetItemCategoryName() == "" and "Miscellaneous" or item:GetItemCategoryName()})			
							end
						else -- Group Date
							local diff = os.date("*t",(os.time() - entry.nDate))
							diff = diff.day + (diff.month-1)*30
							if self.tItems["settings"].LL.nMaxDays == 0 or (diff <= self.tItems["settings"].LL.nMaxDays) then 
								local strDate = self:ConvertDate(os.date("%x",entry.nDate))
								if tGrouppedItems[strDate] == nil then tGrouppedItems[strDate] = {} end
								if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),self.tItems[ID],entry.nGP) then
									table.insert(tGrouppedItems[strDate],entry.itemID)
									table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName,strHeader = strDate})	
								end
							end
						end
					end
				end
			end
		else
			local nStart = self.wndLL:GetData().nStart
			local nFinish = self.wndLL:GetData().nFinish
			for k , player in ipairs(self.tItems) do
				if player.tLLogs then
					tWinnersDictionary[player.strName] = {}
					if self.tItems["settings"].LL.strGroup == "GroupName" then
						tGrouppedItems[player.strName] = {}
						for j , entry in ipairs(player.tLLogs) do
							if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),player,entry.nGP,{nStart = nStart,nFinish = nFinish,nTime = entry.nDate}) then
								table.insert(tGrouppedItems[player.strName],entry.itemID)
								table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName,strHeader = player.strName})
							end
						end
						if #tGrouppedItems[player.strName] == 0 then tGrouppedItems[player.strName] = nil end
					elseif self.tItems["settings"].LL.strGroup == "GroupCategory" then
						for j , entry in ipairs(player.tLLogs) do
							local item = Item.GetDataFromId(entry.itemID)
							if item and self:LLMeetsFilters(item,player,entry.nGP,{nStart = nStart,nFinish = nFinish,nTime = entry.nDate}) then
								if tGrouppedItems[item:GetItemCategoryName()] == nil then tGrouppedItems[item:GetItemCategoryName()] = {} end
								table.insert(tGrouppedItems[item:GetItemCategoryName()],entry.itemID)
								table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName,strHeader = item:GetItemCategoryName() == "" and "Miscellaneous" or item:GetItemCategoryName()})						
							end
						end
					else
						for j , entry in ipairs(player.tLLogs) do
							local diff = os.date("*t",(os.time() - entry.nDate))
							diff = diff.day + (diff.month-1)*30
							if self.tItems["settings"].LL.nMaxDays == 0 or diff <= self.tItems["settings"].LL.nMaxDays then 
								local strDate = self:ConvertDate(os.date("%x",entry.nDate))
								if tGrouppedItems[strDate] == nil then tGrouppedItems[strDate] = {} end
								if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),player,entry.nGP,{nStart = nStart,nFinish = nFinish,nTime = entry.nDate}) then
									table.insert(tGrouppedItems[strDate],entry.itemID)
									table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName,strHeader = strDate})						
								end
							end
						end
					end
				end
			end
		end
	end
	--if self.wndLL:GetData().tIDs and #self.wndLL:GetData().tIDs == 1 then tWinnersDictionary = nil end
	return tGrouppedItems , tWinnersDictionary
end

function DKP:LLMeetsFilters(item,player,nGP,tTimeWindow)
	if not item or not player then return false end
	-- Booleans setup
	if tTimeWindow and tTimeWindow.nTime and tTimeWindow.nFinish and tTimeWindow.nStart then
		if tTimeWindow.nTime > tTimeWindow.nFinish or tTimeWindow.nTime < tTimeWindow.nStart then return false end
	end
	local bMeetSlot
	if self.tItems["settings"].LL.tTabsSettings["Slots"].bEnable then
		bMeetSlot = false
	else
		bMeetSlot = true
	end
	
	local bMeetClass
	if self.tItems["settings"].LL.tTabsSettings["Classes"].bEnable then
		bMeetClass = false
	else
		bMeetClass = true
	end	
	
	local bMeetQual
	if self.tItems["settings"].LL.tTabsSettings["Quality"].bEnable then
		bMeetQual = false
	else
		bMeetQual = true
	end
	
	
	--Equippable
	if self.tItems["settings"].LL.bEquippable and not item:IsEquippable() and not string.find(item:GetName(),"Imprint") then return false end
	--Slots
	if not bMeetSlot then
		local strSlot
		if item:GetSlotName() == "" then
			strSlot = self:EPGPGetSlotStringByID(item:GetSlot())
		else
			strSlot = self:EPGPGetSlotStringByID(item:GetSlotName())
		end

		bMeetSlot = self.tItems["settings"].LL.tSlots[strSlot]
		
		if bMeetSlot == nil then bMeetSlot = false end
	end
	--Item Level
	if item:GetDetailedInfo().tPrimary.nEffectiveLevel < self.tItems["settings"].LL.nLevel then return false end
	--Gp cost
	if nGP ~= "ML" and tonumber(nGP) then
		if nGP < self.tItems["settings"].LL.nGP then return false end
	end
	--Classes
	if player ~= "ML" and not bMeetClass  then
		bMeetClass = self.tItems["settings"].LL.tClasses[player.class]

		
		if bMeetClass == nil then bMeetClass = false end
	end
	--Quality
	if not bMeetQual then
		local strQual = self:EPGPGetQualityStringByID(item:GetItemQuality())
		
		bMeetQual = self.tItems["settings"].LL.tQual[strQual]
		
		if bMeetQual == nil then bMeetQual = false end
	end
	--AND/OR
	
	local strSlotRelation = self.tItems["settings"].LL.tTabsSettings["Slots"].strRelation
	local strClassRelation = self.tItems["settings"].LL.tTabsSettings["Classes"].strRelation
	local strQualRelation = self.tItems["settings"].LL.tTabsSettings["Quality"].strRelation
	
	if strSlotRelation == "OR" and bMeetSlot then return true end
	if strClassRelation == "OR" and bMeetClass then return true end
	if strQualRelation == "OR" and bMeetQual then return true end
	
	if strSlotRelation == "AND" then
		if not bMeetSlot then return false end
	end
	if strClassRelation == "AND" then
		if not bMeetClass then return false end
	end
	if strQualRelation == "AND" then
		if not bMeetQual then return false end
	end
	
	if not bMeetClass and not bMeetSlot and not bMeetQual then return false end
	
	return true
end

function DKP:LLResize()
	self:RIRequestRearrange(self.wndLL:FindChild("List"))
end

function raidOpsSortCategories(a,b)
	return a < b
end

function DKP:LLSearch(wndHandler,wndControl,strText)
	for k , bubble in ipairs(self.wndLL:FindChild("List"):GetChildren()) do
		if not bubble:GetData().bPopulated then self:IBPopulate(bubble) end
		local bFoundEntries = false
		for k ,tile in ipairs(bubble:FindChild("ItemGrid"):GetChildren()) do
			if strText ~= "" and self:string_starts(tile:GetData():GetName(),strText) then 
				if not bubble:GetData().bExpanded then 
					self:IBExpand(nil,bubble:FindChild("Header"))
					bubble:GetData().bSearchOpen = true
				end
				bFoundEntries = true
				tile:FindChild("SearchFlash"):Show(true)
				tile:FindChild("ShadowOverlay"):Show(false)
			elseif strText ~= "" and not self:string_starts(tile:GetData():GetName(),strText) then
				tile:FindChild("SearchFlash"):Show(false) 
				tile:FindChild("ShadowOverlay"):Show(true)
			else
				tile:FindChild("SearchFlash"):Show(false) 
				tile:FindChild("ShadowOverlay"):Show(false)
			end
				
			if not bFoundEntries and bubble:GetData().bSearchOpen then 
				self:IBECollapse(nil,bubble:FindChild("Header"))
				bubble:GetData().bSearchOpen = false
			end
		
		end

	end
end

function DKP:LLSetMaxRows( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].LL.nMaxRows then
		self.tItems["settings"].LL.nMaxRows = math.floor(fNewValue)
	end
	self.wndLLM:FindChild("SettingsMisc"):FindChild("MaxRowsTitle"):SetText(string.format("Max rows per bubble. - %d",math.floor(fNewValue)))
end

function DKP:LLSetMaxItems( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].LL.nMaxItems then
		self.tItems["settings"].LL.nMaxItems = math.floor(fNewValue)
	end
	self.wndLLM:FindChild("SettingsMisc"):FindChild("MaxItemsTitle"):SetText(string.format("Max items per row. - %d",math.floor(fNewValue)))
end

function DKP:LLSetMaxDays( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].LL.nMaxDays then
		self.tItems["settings"].LL.nMaxDays = math.floor(fNewValue)
	end

	self.wndLLM:FindChild("SettingsMisc"):FindChild("MaxDaysTitle"):SetText(string.format("When grouping by day show items form last %s days:",math.floor(fNewValue) == 0 and "X" or tostring(math.floor(fNewValue))))
end



function DKP:LLPopuplate()
	local wndList = self.wndLL:FindChild("List")
	local tExpandedBubbles = {}
	for k , bubble in ipairs(wndList:GetChildren()) do
		if bubble:GetData().bExpanded then
			table.insert(tExpandedBubbles,bubble:GetData().strTitle)
		end
	end
	wndList:DestroyChildren()
	local tData , tWinnersDictionary = self:LLPrepareData()
	local categories = {}
	for cat , items in pairs(tData) do
		table.insert(categories,cat)
	end
	
	table.sort(categories,raidOpsSortCategories)
	
	for k , cat in pairs(categories) do
		local items = tData[cat]
		if #items > 0 then
			if cat == "" then cat = "Miscellaneous" end
			local wndBubble = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",wndList,self)
			wndBubble:SetData({bExpanded = false,bPopulated = false,bSearchOpen = false,nItems = self.tItems["settings"].LL.nMaxItems,nRows = self.tItems["settings"].LL.nMaxRows, strTitle = cat ,nWidthMod = 1,nHeightMod = 0,tCustomData = items,tItemTooltips = tWinnersDictionary})
			wndBubble:FindChild("Header"):FindChild("HeaderText"):SetText(cat)
			if self.wndLL:GetData().strMode == "ML" then
				self:IBAddTileClickHandler(wndBubble,"MAUpdateID")
			end
			if self.wndLL:GetData().strMode == "Reass" then
				self:IBAddTileClickHandler(wndBubble,"ReassUpdateItem")
			end
			for k , prevBubble in ipairs(tExpandedBubbles) do
				if prevBubble == cat then 
					self:IBExpand(nil,wndBubble:FindChild("Header")) 
					wndBubble:FindChild("Expand"):SetCheck(true)
					break 
				end
			end
		end
	end
	
	self:RIRequestRearrange(wndList)
end

function DKP:LLBubblesExpand()
	for k, bubble in ipairs(self.wndLL:FindChild("List"):GetChildren()) do
		if not bubble:GetData().bExpanded then
			self:IBExpand(nil,bubble:FindChild("Header"))
			bubble:FindChild("Expand"):SetCheck(true)
		end
	end
end

function DKP:LLBubblesCollapse()
	for k, bubble in ipairs(self.wndLL:FindChild("List"):GetChildren()) do
		if bubble:GetData().bExpanded then
			self:IBECollapse(nil,bubble:FindChild("Header"))
			bubble:FindChild("Expand"):SetCheck(false)
		end
	end
end

function DKP:LLExport()
	local strExport = ""
	for k , bubble in ipairs(self.wndLL:FindChild("List"):GetChildren()) do
		strExport = strExport .. bubble:FindChild("Header"):FindChild("HeaderText"):GetText() .. "\n"
		for j, itemID in ipairs(bubble:GetData().tCustomData) do
			local item = Item.GetDataFromId(itemID)
			if item then 
				strExport = strExport .. item:GetName() .. ";" .. item:GetItemId() .. ";" .. string.sub(self:EPGPGetItemCostByID(item:GetItemId()),32) .. "\n"
			end
		end
	end
	self:ExportShowPreloadedText(strExport)
end

-----------------------------------------------------------------------------------------------
--  DataFetching
-----------------------------------------------------------------------------------------------

function DKP:DFInit()
	self.wndDF = Apollo.LoadForm(self.xmlDoc,"DataFetching",nil,self)
	self.wndDF:Show(false,true)
	
	if self.tItems["settings"].DF == nil then self.tItems["settings"].DF = {} end
	if self.tItems["settings"].DF.bFetchRaid == nil then self.tItems["settings"].DF.bFetchRaid = false end
	if self.tItems["settings"].DF.bFetchTimed == nil then self.tItems["settings"].DF.bFetchTimed = false end
	if self.tItems["settings"].DF.bFetchOOC == nil then self.tItems["settings"].DF.bFetchOOC = true end
	if self.tItems["settings"].DF.strSource == nil then self.tItems["settings"].DF.strSource = "Fill with EXACT player name." end
	if self.tItems["settings"].DF.nPeriod == nil then self.tItems["settings"].DF.nPeriod = 5 end
	if self.tItems["settings"].DF.bSmart == nil then self.tItems["settings"].DF.bSmart = true end
	
	if self.tItems["settings"].DF.bSend == nil then self.tItems["settings"].DF.bSend = true end
	if self.tItems["settings"].DF.bSendRaid == nil then self.tItems["settings"].DF.bSendRaid = false end
	if self.tItems["settings"].DF.bSendOOC == nil then self.tItems["settings"].DF.bSendOOC = false end
	
	if self.tItems["settings"].DF.tLogs == nil then self.tItems["settings"].DF.tLogs = {} end
	
	self.wndDF:FindChild("FetchOnlyInRaid"):SetCheck(self.tItems["settings"].DF.bFetchRaid)
	self.wndDF:FindChild("FetchOnlyCombat"):SetCheck(self.tItems["settings"].DF.bFetchOOC)
	self.wndDF:FindChild("TimedFetchEnable"):SetCheck(self.tItems["settings"].DF.bFetchTimed)
	
	self.wndDF:FindChild("SendEnable"):SetCheck(self.tItems["settings"].DF.bSend)
	self.wndDF:FindChild("SendRaidOnly"):SetCheck(self.tItems["settings"].DF.bSendRaid)
	self.wndDF:FindChild("SendOutOfCombat"):SetCheck(self.tItems["settings"].DF.bSendOOC)
	self.wndDF:FindChild("SmartEncoding"):SetCheck(self.tItems["settings"].DF.bSmart)
	
	self.wndDF:FindChild("Source"):SetText(self.tItems["settings"].DF.strSource)
	self.wndDF:FindChild("Minutes"):SetText(self.tItems["settings"].DF.nPeriod)
	
	if self.tItems["settings"].DF.bFetchTimed then self:DFStartTimer() end
	
	self:DFJoinSyncChannel()
end

local nTicks = 0
function DKP:DFShow()
	self.wndDF:Show(true,false)
	self.wndDF:ToFront()
	self:DFPopulate()
end

function DKP:DFClose()
	self.wndDF:Show(false,false)
end

function DKP:DFFetchRaidEnable()
	self.tItems["settings"].DF.bFetchRaid = true
end

function DKP:DFFetchRaidDisable()
	self.tItems["settings"].DF.bFetchRaid = false
end

function DKP:DFFetchOOCEnable()
	self.tItems["settings"].DF.bFetchOOC = true
end

function DKP:DFFetchOOCDisable()
	self.tItems["settings"].DF.bFetchOOC = false
end

function DKP:DFTimedFetchEnable()
	self.tItems["settings"].DF.bFetchTimed = true
	self:DFStartTimer()
end

function DKP:DFTimedFetchDisable()
	self.tItems["settings"].DF.bFetchTimed = false
	self:DFStopTimer()
end

function DKP:DFSendEnable()
	self.tItems["settings"].DF.bSend = true
end

function DKP:DFSendDisable()
	self.tItems["settings"].DF.bSend = false
end

function DKP:DFSendRaidEnable()
	self.tItems["settings"].DF.bSendRaid = true
end

function DKP:DFSendRaidDisable()
	self.tItems["settings"].DF.bSendRaid = false
end

function DKP:DFSendOOCEnable()
	self.tItems["settings"].DF.bSendOOC = true
end

function DKP:DFSendOOCDisable()
	self.tItems["settings"].DF.bSendOOC = false
end

function DKP:DFSetSource(wndHandler,wndControl,strText)
	self.tItems["settings"].DF.strSource = strText
end

function DKP:DFSmartMode()
	self.tItems["settings"].DF.bSmart = true
end

function DKP:DFDumbMode()
	self.tItems["settings"].DF.bSmart = false
end

function DKP:DFSetPeriod(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val then
		if val > 0 then
			self.tItems["settings"].DF.nPeriod = math.floor(val)
			wndControl:SetText(self.tItems["settings"].DF.nPeriod)
			nTicks = 0
		else
			wndControl:SetText(self.tItems["settings"].DF.nPeriod)
		end
	else
		wndControl:SetText(self.tItems["settings"].DF.nPeriod)
	end
end

function DKP:DFPopulate()
	local grid = self.wndDF:FindChild("Grid")
	
	grid:DeleteAll()
	
	for k, entry in ipairs(self.tItems["settings"].DF.tLogs) do
		grid:AddRow(k)
		grid:SetCellData(k,1,entry.strRequester)
		grid:SetCellData(k,2,entry.strState)
		grid:SetCellData(k,3,entry.strTimestamp)
	end
end

function DKP:DFStartTimer()
	Apollo.RegisterTimerHandler(1,"DFTimerTick",self)
	self.DFTimer = ApolloTimer.Create(1, true, "DFTimerTick", self)
end

function DKP:DFStopTimer()
	Apollo.RemoveEventHandler("DFTimerTick",self)
	self.DFTimer:Stop()
	self.wndDF:FindChild("CountDown"):SetText("--:--:--")
	nTicks = 0
end

function DKP:DFTimerTick()
	nTicks = nTicks + 1
	if nTicks >= self.tItems["settings"].DF.nPeriod * 60 then
		nTicks = 0
		self:DFFetchDataTimed()
	end
	
	local nTimeLeft = self.tItems["settings"].DF.nPeriod * 60 - nTicks
	local diff =  os.date("*t",nTimeLeft)
	if diff ~= nil then
		self.wndDF:FindChild("CountDown"):SetText((diff.hour-1 <=9 and "0" or "" ) .. diff.hour-1 .. ":" .. (diff.min <=9 and "0" or "") .. diff.min .. ":".. (diff.sec <=9 and "0" or "") .. diff.sec)
	else
		self.wndDF:FindChild("CountDown"):SetText("--:--:--")
	end
end

-- Syncing
local tFetchers = {} -- heavy stuff
local connCounter = 0
function DKP:DFJoinSyncChannel()
	if self.uGuild then
		self.sChannel = ICCommLib.JoinChannel("RaidOpsSyncChannel",ICCommLib.CodeEnumICCommChannelType.Guild,self.uGuild)
		self.sChannel:SetReceivedMessageFunction("DFOnSyncMessage",self)
	elseif connCounter < 4 then
		connCounter = connCounter + 1
		self:delay(2,function (tContext)
			tContext:ImportFromGuild()
			tContext:DFJoinSyncChannel()
		end)
	end
end

function DKP:DFOnSyncMessage(channel, strMessage, idMessage)

	local tMsg = serpent.load(strMessage)
	Print(tMsg.type)
	if tMsg.type  then
		if tMsg.type == "SendMeData" then
			self.sChannel:SendPrivateMessage(tMsg.strSender,self:GetEncodedData(tMsg.strSender))
		elseif tMsg.type == "SendMeFullData" then
			tFetchers[tMsg.strSender] = nil
			self.sChannel:SendPrivateMessage(tMsg.strSender,self:GetEncodedData(tMsg.strSender))
		elseif tMsg.type == "EncodedDataFull" then
			self:ProccesEncodedData(tMsg.tData)		
		elseif tMsg.type == "EncodedDataSelected" then
			self:ProccesEncodedDataUpdate(tMsg.tData)
		elseif tMsg.type == "Data unavailable" then
			Print("Permission to data was denied , contact the person in charge")
		end
	end
end

function DKP:ProccesEncodedData(tData)
	
	if tData then
		for k, player in ipairs(self.tItems) do
			table.remove(self.tItems,1)
		end
		self.tItems["alts"] = tData["alts"] or {}
		for k,player in ipairs(tData) do
			if self:GetPlayerByIDByName(player.strName) == -1 then
				table.insert(self.tItems,player)
			else
				self.tItems[self:GetPlayerByIDByName(player.strName)] = player
			end
		end
		if tData.tRaids then
			self.tItems.tRaids = tData.tRaids
		end
	end
	Print("Data received and proccessed , full sync")
	
	self:RefreshMainItemList()
end

function DKP:ProccesEncodedDataUpdate(tData)
	if tData then
		self.tItems["alts"] = tData["alts"] or {}
		for alt , owner in pairs(tData["alts"]) do
			for k , player in ipairs(self.tItems) do
				if string.lower(player.strName) == alt then table.remove(self.tItems,k) break end 
			end
		end
		for k,player in ipairs(tData) do
			if self:GetPlayerByIDByName(player.strName) == -1 then
				table.insert(self.tItems,player)
			else
				local ID = self:GetPlayerByIDByName(player.strName)
				local tLogs = self.tItems[ID].logs
				self.tItems[ID] = player
				for k , entry in ipairs(player.logs) do
					table.insert(tLogs,1,entry)
				end
			end
		end
		if tData.tRaids then
			self.tItems.tRaids = tData.tRaids
		end
	end
	Print("Data received and proccessed , update")
	self:RefreshMainItemList()
end


local function ArePlayerTablesDifferent(p1,p2)
	if tonumber(p1.EP) ~= tonumber(p2.EP) then return true
	elseif p1.strName ~= p2.strName then return true
	elseif p1.GP ~= p2.GP then return true
	elseif #p1.logs ~= #p2.logs then	return true
	elseif p1.net ~= p2.net then return true
	elseif p1.tot ~= p2.tot then return true
	elseif #p1.alts ~= #p2.alts then return true
	else return false end
end

function DKP:GetEncodedData(strRequester)
	local tData = {}
	local myUnit = GameLib.GetPlayerUnit()
	if not self.tItems["settings"].DF.bSend or self.tItems["settings"].DF.bSendRaid and not self:IsPlayerInRaid(strRequester) or self.tItems["settings"].DF.bSendOOC and myUnit:IsInCombat() then
		tData.type = "Data unavailable"
		self:DFAddLog(strRequester,false)
	else
		tData.type = "EncodedDataFull"
		if not tFetchers[strRequester] or not self.tItems["settings"].DF.bSmart then
			local tPlayers = {}
			for k,player in ipairs(self.tItems) do
				table.insert(tPlayers,player)
				tPlayers[k].logs = {}
			end
			tData.tData = tPlayers

			if self.tItems["settings"].DF.bSmart then tFetchers[strRequester] = serpent.load(serpent.dump(tPlayers)) end
		elseif self.tItems["settings"].DF.bSmart then
			tData.type = "EncodedDataSelected"
			local tPlayers = {}
			for k , playerSource in ipairs(self.tItems) do
				local bFound = false
				for k ,playerSent in ipairs(tFetchers[strRequester]) do
					if playerSource.strName == playerSent.strName then
						bFound = true
						if ArePlayerTablesDifferent(playerSource,playerSent) then
							table.insert(tPlayers,playerSource)
							tPlayers[#tPlayers].logs = {}
							break
						end
					end
				end
				if not bFound then
					table.insert(tPlayers,playerSource)
				end
			end
			tPlayers["alts"] = self.tItems["alts"]
			local tPlayersSource = {}
			for k,player in ipairs(self.tItems) do
				table.insert(tPlayersSource,player)
			end
			tData.tData = tPlayers
			tFetchers[strRequester] = serpent.load(serpent.dump(tPlayersSource))
		end
		self:DFAddLog(strRequester,true)
	end
	tData.strSender = myUnit:GetName()
	tData.tRaids = self.tItems.tRaids
	return serpent.dump(tData)
end

function DKP:DFAddLog(strPlayer,bSucces)
	table.insert(self.tItems["settings"].DF.tLogs,1,{strRequester = strPlayer,strState = bSucces and "{Yes}" or "{No}",strTimestamp = self:ConvertDate(os.date("%x",os.time())) .. " " .. os.date("%X",os.time())})
	if #self.tItems["settings"].DF.tLogs > 20 then table.remove(self.tItems["settings"].DF.tLogs,21) end
	if self.wndDF:IsShown() then self:DFPopulate() end
end

function DKP:DFFetchDataTimed()
	local myUnit = GameLib.GetPlayerUnit()
	if self.tItems["settings"].DF.bFetchOOC and myUnit:IsInCombat() or self.tItems["settings"].DF.bFetchRaid and not GroupLib.InRaid() then return end
	if self.sChannel then self.sChannel:SendPrivateMessage(self.tItems["settings"].DF.strSource,serpent.dump({type = "SendMeData",strSender = GameLib.GetPlayerUnit():GetName()})) end
end

function DKP:DFFetchData()
	if self.sChannel then self.sChannel:SendPrivateMessage(self.tItems["settings"].DF.strSource,serpent.dump({type = "SendMeData",strSender = GameLib.GetPlayerUnit():GetName()})) end
end

function DKP:DFFetchFullData()
	if self.sChannel then self.sChannel:SendPrivateMessage(self.tItems["settings"].DF.strSource,serpent.dump({type = "SendMeFullData",strSender = GameLib.GetPlayerUnit():GetName()})) end
end
-----------------------------------------------------------------------------------------------
-- Loot Filtering
-----------------------------------------------------------------------------------------------

function DKP:FLInit()
	self.wndFL = Apollo.LoadForm(self.xmlDoc,"FilteredItems",nil,self)
	self.wndFL:Show(false,true)
	
	if self.tItems["settings"].strFilteredKeywords == nil then self.tItems["settings"].strFilteredKeywords = "" end
	
	self.wndFL:FindChild("Words"):SetText(self.tItems["settings"].strFilteredKeywords)

end

function DKP:FLSetFilterString(wndHandler,wndControl,strText)
	self.tItems["settings"].strFilteredKeywords = strText
end

function DKP:FLOpen()
	self.wndFL:Show(true,false)
	self.wndFL:FindChild("Words"):SetText(self.tItems["settings"].strFilteredKeywords)
	self.wndFL:ToFront()
end

function DKP:FLHide()
	self.wndFL:Show(false,false)
end

function DKP:FQInit()
	self.wndFQ = Apollo.LoadForm(self.xmlDoc,"FilterQual",nil,self)
	self.wndFQ:Show(false,true)
	
	if self.tItems["settings"].tFilterQual == nil then self.tItems["settings"].tFilterQual = ktQual end
	
	for k , wnd in ipairs(self.wndFQ:GetChildren()) do
		if self.tItems["settings"].tFilterQual[wnd:GetName()] then wnd:SetCheck(self.tItems["settings"].tFilterQual[wnd:GetName()]) end
	end
end

function DKP:FQShow()
	self.wndFQ:Show(true,false)
	self.wndFQ:ToFront()
end

function DKP:FQHide()
	self.wndFQ:Show(false,false)
end

function DKP:FQEnableQuality(wndHandler,wndControl)
	self.tItems["settings"].tFilterQual[wndControl:GetName()] = true
end

function DKP:FQDisableQuality(wndHandler,wndControl)
	self.tItems["settings"].tFilterQual[wndControl:GetName()] = false
end
-----------------------------------------------------------------------------------------------
-- Raid Invites
-----------------------------------------------------------------------------------------------
function DKP:RIInit()
	self.wndRI = Apollo.LoadForm(self.xmlDoc,"RaidInvites",nil,self)
	self.wndRI:Show(false,true)

	if self.tItems["settings"].bRIEnable == nil then self.tItems["settings"].bRIEnable = false end
	if self.tItems["settings"].bRIConfirmation == nil then self.tItems["settings"].bRIConfirmation = false end
	if self.tItems["settings"].strRIcmd == nil then self.tItems["settings"].strRIcmd = "raid" end
	if self.tItems["settings"].strConfRem == nil then self.tItems["settings"].strConfRem = "join" end
	if self.tItems["settings"].tConfirmed == nil then self.tItems["settings"].tConfirmed = {} end

	self.wndRI:FindChild("Enable"):SetCheck(self.tItems["settings"].bRIEnable)
	self.wndRI:FindChild("Conf"):SetCheck(self.tItems["settings"].bRIConfirmation)
	self.wndRI:FindChild(self.tItems["settings"].strConfRem):SetCheck(true)
	self.wndRI:FindChild("Command"):SetText(self.tItems["settings"].strRIcmd)
end



function DKP:RISetCmd(wndHandler,wndControl,strText)
	self.tItems["settings"].strRIcmd = strText
end

function DKP:RIProcessInviteRequest(strRequester)
	if self.tItems["settings"].bRIConfirmation then
		for k , strConfirmed in ipairs(self.tItems["settings"].tConfirmed) do
			if strConfirmed == strRequester then
				if self.tItems["settings"].strConfRem == "inv" then
					table.remove(self.tItems["settings"].tConfirmed,k)
				end
				if GroupLib.GetMemberCount() == 5 then GroupLib.ConvertToRaid() end
				local strRealm = GameLib.GetRealmName()
				local strMsg = "Raid time!"
				GroupLib.Invite(strRequester,strRealm,strMessage)
				break
			end
		end
	else
		if GroupLib.GetMemberCount() == 5 then GroupLib.ConvertToRaid() end
		local strRealm = GameLib.GetRealmName()
		local strMsg = "Raid time!"
		GroupLib.Invite(strRequester,strRealm,strMessage)
	end
end

function DKP:RIInvertConfirmation()
	for k , wnd in ipairs(selectedMembers) do
		local bFound = false
		local atID
		for k ,strConfirmed in ipairs(self.tItems["settings"].tConfirmed) do
			if strConfirmed == self.tItems[wnd:GetData()].strName then
				bFound = true
				atID = k
				break
			end
		end

		if bFound then
			table.remove(self.tItems["settings"].tConfirmed,atID)
		else
			table.insert(self.tItems["settings"].tConfirmed,self.tItems[wnd:GetData()].strName)
		end
	end
	self:RefreshMainItemList()
end

function DKP:RIOpen()
	self.wndRI:Show(true,false)
	self.wndRI:ToFront()
end

function DKP:RIHide()
	self.wndRI:Show(false,false)
end

function DKP:RIEnable()
	self.tItems["settings"].bRIEnable = true
	self.wndMain:FindChild("MassEditControls"):FindChild("Confirm"):Enable(true)
end

function DKP:RIDisable()
	self.tItems["settings"].bRIEnable = false
	self.wndMain:FindChild("MassEditControls"):FindChild("Confirm"):Enable(false)
end

function DKP:RIConfEnable()
	self.tItems["settings"].bRIConfirmation = true
end

function DKP:RIConfDisable()
	self.tItems["settings"].bRIConfirmation = false
end

function DKP:RIConfRemChanged(wndHandler,wndControl)
	self.tItems["settings"].strConfRem = wndControl:GetName()
end
-----------------------------------------------------------------------------------------------
-- Manual Award 
-----------------------------------------------------------------------------------------------
function DKP:MAInit()
	self.wndMA = Apollo.LoadForm(self.xmlDoc,"ManualAward",nil,self)
	self.wndMA:Show(false)

end

function DKP:MAOpenLL()
	self:LLOpenML()
end

function DKP:MAOpen(ID)
	if not self.wndMA:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndMA:Move(tCursor.x - 100, tCursor.y - 100, self.wndMA:GetWidth(), self.wndMA:GetHeight())
	end
	self.wndMA:Show(true,false)
	self.wndMA:ToFront()

	self.wndMA:FindChild("Name"):SetText(self.tItems[ID].strName)
	self.wndMA:FindChild("TickName"):Show(true)
	self:MACheckConditions()
end

function DKP:MAClose()
	self.wndMA:Show(false,false)
end

function DKP:MACheckName(wndHandler,wndControl,strText)
	if self:GetPlayerByIDByName(strText) ~= -1 then self.wndMA:FindChild("TickName"):Show(true) else self.wndMA:FindChild("TickName"):Show(false) end
	self:MACheckConditions()
end

function DKP:MACheckConditions()
	if self.wndMA:FindChild("TickName"):IsShown() and self.wndMA:FindChild("TickID"):IsShown() then
		self.wndMA:FindChild("Proceed"):Enable(true)
	else
		self.wndMA:FindChild("Proceed"):Enable(false)
	end
end

function DKP:MAUpdateID(wndHandler,wndControl)
	if not string.find(wndControl:GetName(),"Tile") then return end

	self.wndMA:FindChild("ID"):SetText(wndControl:GetData():GetItemId())
	Tooltip.GetItemTooltipForm(self, self.wndMA:FindChild("ID") , wndControl:GetData(), {bPrimary = true, bSelling = false})
	self.wndMA:FindChild("TickID"):Show(true)
	self:MACheckConditions()
end

function DKP:MAUpdateTooltip(wndHandler,wndControl,strText)
	if tonumber(strText) then
		local item = Item.GetDataFromId(tonumber(strText))
		if item then
			Tooltip.GetItemTooltipForm(self, self.wndMA:FindChild("ID") , item, {bPrimary = true, bSelling = false})
			self.wndMA:FindChild("TickID"):Show(true)
		else
			self.wndMA:FindChild("TickID"):Show(false)
		end
	else
		self.wndMA:FindChild("TickID"):Show(false)
	end
	self:MACheckConditions()
end

function DKP:MAProceed()
	local item = Item.GetDataFromId(tonumber(self.wndMA:FindChild("ID"):GetText()))
	self:OnLootedItem(item,true)
	if not self.tItems["settings"].bLLAfterPopUp then self:LLAddLog(self.wndMA:FindChild("Name"):GetText(),item:GetName()) end
	self:PopUpWindowOpen(self.wndMA:FindChild("Name"):GetText(),item:GetName())
	Event_FireGenericEvent("MAProceed")
end
-----------------------------------------------------------------------------------------------
-- Manual Award 
-----------------------------------------------------------------------------------------------
function DKP:RenameInit()
	self.wndRen = Apollo.LoadForm(self.xmlDoc,"RenameFloater",nil,self)
	self.wndRen:Show(false)
end

function DKP:RenameShow(ID)
	if not self.wndRen:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndRen:Move(tCursor.x - 100, tCursor.y - 100, self.wndRen:GetWidth(), self.wndRen:GetHeight())
	end
	self.wndRen:Show(true,false)
	self.wndRen:ToFront()

	self.wndRen:SetData(ID)
	self.wndRen:FindChild("Name"):SetText(self.tItems[ID].strName)
	self.wndRen:FindChild("Edited"):SetText(self.tItems[ID].strName)
	self:RenameCheck(self.tItems[ID].strName)
end

function DKP:RenameHide()
	self.wndRen:Show(false,false)
end

function DKP:RenameNameChanged(wndHandler,wndControl,strText)
	self:RenameCheck(strText)
end

function DKP:RenameCommit()
	local ID = self.wndRen:GetData()
	local strPrevName = self.tItems[ID].strName
	local strNewName = self.wndRen:FindChild("Name"):GetText()
	if self.tItems["Standby"][string.lower(strPrevName)] then
		self.tItems["Standby"][string.lower(strNewName)] = self.tItems["Standby"][string.lower(strPrevName)]
		self.tItems["Standby"][string.lower(strNewName)].strName = strNewName 
		self.tItems["Standby"][string.lower(strPrevName)] = nil
	end
	if self.wndStandby:IsShown() then self:StandbyListPopulate() end

	self.tItems[ID].strName = strNewName
	self:RefreshMainItemList()
	self:AltsBuildDictionary()
	self:RenameHide()
end

function DKP:RenameCheck(strName)
	if self:GetPlayerByIDByName(strName) ~= - 1 then self.wndRen:FindChild("Commit"):Enable(false) return end
	local counter = 0
	for word in string.gmatch(strName,"%S+") do
		counter = counter + 1
	end
	if counter == 2 then
		self.wndRen:FindChild("Commit"):Enable(true)
	else
		self.wndRen:FindChild("Commit"):Enable(false)
	end

end

function DKP:NotificationInit()
	self.wndNot = Apollo.LoadForm(self.xmlDoc,"Notification",nil,self)
	self.wndNot:Show(false)
	self.wndNot:SetOpacity(0)
	--self:NotificationStart("LOLOLOL",5)
end
local nCounter
local nTime
local nOpacity
local nOpacityTick
local nPeak

function DKP:NotificationStart(strMsg,nSecs,nPeakSec)
	if nSecs > nPeakSec then 
		nSecs = (nSecs * 10) - (nPeakSec*10)
		nPeakSec = nPeakSec * 2 
	else 
		nSecs = nSecs * 6
		nPeakSec = 0
	end
	local x,y = Apollo.GetScreenSize()
	local l,t,r,b = self.wndNot:GetAnchorOffsets()
	self.wndNot:Move( (x/2)-self.wndNot:GetWidth()/2, t, self.wndNot:GetWidth(), self.wndNot:GetHeight())
	self.wndNot:SetOpacity(0)
	self.wndNot:SetText(strMsg)
	Apollo.RegisterTimerHandler(.1,"NotificationTimer",self)
	nTime = nSecs
	nCounter = 0
	nOpacity = 0
	nPeak = nPeakSec
	nOpacityTick = 1/(nTime*2)
	self.NotificationTime = ApolloTimer.Create(.1, true, "NotificationTimer", self)
	self.wndNot:Show(true)
end

function DKP:NotificationTimer()
	if nCounter < nTime/2 then
		nOpacity = nOpacity + nOpacityTick 
	elseif nCounter == nTime/2 then
		if nPeak > 0 then
			nCounter = nCounter - .5
			nPeak = nPeak - .5
		end
	elseif nCounter > nTime/2 then
		nOpacity = nOpacity - nOpacityTick
	end
	self.wndNot:SetOpacity(nOpacity*2)
	nCounter = nCounter + 0.5
	if nCounter > nTime then 
		self.wndNot:Show(false)
		self.NotificationTime:Stop() 
	end
	self.wndNot:ToFront()
end
-----------------------------------------------------------------------------------------------
-- Item Reassign
-----------------------------------------------------------------------------------------------
function DKP:ReassInit()
	self.wndReass = Apollo.LoadForm(self.xmlDoc,"ItemReassign",nil,self)
	self.wndReass:Show(false)
end
local prevValidName
function DKP:ReassShow(strName , item)
	if not self.wndReass:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndReass:Move(tCursor.x - 100, tCursor.y - 100, self.wndReass:GetWidth(), self.wndReass:GetHeight())
	end

	self.wndReass:Show(true,false)
	self.wndReass:ToFront()
	if strName then
		prevValidName = string.sub(strName,1,#strName-2)
		self.wndReass:FindChild("GName"):SetText(prevValidName)
	end

	if item then
		local nGP
		self.wndReass:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
		self.wndReass:FindChild("ItemFrame"):FindChild("Icon"):SetSprite(item:GetIcon())
		for k , entry in ipairs(self.tItems[self:GetPlayerByIDByName(string.sub(strName,1,#strName-2))].tLLogs) do
			if entry.itemID == item:GetItemId() then
				nGP = entry.nGP
				break
			end
		end
		if nGP then
			self.wndReass:FindChild("GGP"):SetText(nGP)
			self.wndReass:FindChild("RGP"):SetText(nGP)
		else
			self.wndReass:FindChild("GGP"):SetText(string.sub(self:EPGPGetItemCostByID(item:GetItemId()),36))
			self.wndReass:FindChild("RGP"):SetText(string.sub(self:EPGPGetItemCostByID(item:GetItemId()),36))
		end
		Tooltip.GetItemTooltipForm(self,self.wndReass:FindChild("Icon"),item,{})
		self.wndReass:FindChild("TickGGP"):Show(true)
		self.wndReass:FindChild("TickRGP"):Show(true)
		self.wndReass:FindChild("ItemFrame"):Show(true)
		self.wndReass:SetData(item)
	else
		self.wndReass:FindChild("ItemFrame"):Show(false)
	end
	self.wndReass:FindChild("Proceed"):Enable(false)

	self.wndReass:FindChild("TickGName"):Show(true) 
	self.wndReass:FindChild("Choose"):Enable(true)

end

function DKP:ReassHide()
	self.wndReass:Show(false,false)
end

function DKP:ReassCheckConditions(wndHandler,wndControl,strText)
	local control = wndControl:GetName()
	local tickCount = 0
	if control == "GName" then
		if self:GetPlayerByIDByName(strText) ~= -1 then 
			self.wndReass:FindChild("TickGName"):Show(true) 
			self.wndReass:FindChild("Choose"):Enable(true)
			if string.lower(prevValidName) ~= string.lower(strText) then
				self.wndReass:FindChild("ItemFrame"):Show(false)
			else
				self.wndReass:FindChild("ItemFrame"):Show(true)
			end
			prevValidName = strText
		else
			self.wndReass:FindChild("TickGName"):Show(false) 
			self.wndReass:FindChild("Choose"):Enable(false)
			self.wndReass:FindChild("ItemFrame"):Show(false)
		end
	elseif control == "GGP" then
		if tonumber(strText) then self.wndReass:FindChild("TickGGP"):Show(true) else self.wndReass:FindChild("TickGGP"):Show(false) end
	elseif control == "RName" then
		if self:GetPlayerByIDByName(strText) ~= -1 then self.wndReass:FindChild("TickRName"):Show(true) else self.wndReass:FindChild("TickRName"):Show(false) end
	elseif control == "RGP" then 
		if tonumber(strText) then self.wndReass:FindChild("TickRGP"):Show(true) else self.wndReass:FindChild("TickRGP"):Show(false) end
	end

	for k , child in ipairs(self.wndReass:GetChildren()) do
		if string.find(child:GetName(),"Tick") and child:IsShown() then tickCount = tickCount + 1 end
	end

	if tickCount == 4 and self.wndReass:FindChild("ItemFrame"):IsShown() then self.wndReass:FindChild("Proceed"):Enable(true) else self.wndReass:FindChild("Proceed"):Enable(false) end
end

function DKP:ReassChooseItem()
	self:LLOpen({[1] = self:GetPlayerByIDByName(self.wndReass:FindChild("GName"):GetText())},"Reass")
end

function DKP:ReassUpdateItem(wndHandler,wndControl)
	if not string.find(wndControl:GetName(),"Tile") then return end
	local item = wndControl:GetData()
	if item then
		self.wndReass:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
		self.wndReass:FindChild("ItemFrame"):FindChild("Icon"):SetSprite(item:GetIcon())
		self.wndReass:FindChild("GGP"):SetText(string.sub(self:EPGPGetItemCostByID(item:GetItemId()),36))
		self.wndReass:FindChild("RGP"):SetText(string.sub(self:EPGPGetItemCostByID(item:GetItemId()),36))
		Tooltip.GetItemTooltipForm(self,self.wndReass:FindChild("Icon"),item,{})
		self.wndReass:FindChild("TickGGP"):Show(true)
		self.wndReass:FindChild("TickRGP"):Show(true)
		self.wndReass:FindChild("ItemFrame"):Show(true)
		self.wndReass:SetData(item)
		self.wndReass:ToFront()
	end

end

function DKP:ReassCommit()
	local GID = self:GetPlayerByIDByName(self.wndReass:FindChild("GName"):GetText())
	local RID = self:GetPlayerByIDByName(self.wndReass:FindChild("RName"):GetText())
	local GPsub = tonumber(self.wndReass:FindChild("GGP"):GetText())
	local GPadd = tonumber(self.wndReass:FindChild("RGP"):GetText())
	local item = self.wndReass:GetData()
	if GID and RID and GPadd and GPsub and item then
		self:UndoAddActivity(string.format(ktUndoActions["itreass"],item:GetName(),self.tItems[GID].strName,self.tItems[RID].strName),GPsub .. " / " .. GPadd,{[1] = self.tItems[GID],[2] = self.tItems[RID]})
		self.tItems[GID].GP = self.tItems[GID].GP - GPsub
		self.tItems[RID].GP = self.tItems[RID].GP + GPadd
		self:DetailAddLog("Removed item : "..item:GetName(),"{GP}",GPsub*-1,GID)
		self:DetailAddLog("Added item : "..item:GetName(),"{GP}",GPsub,RID)
		self:OnLootedItem(item,true)
		self:LLAddLog(self.tItems[RID].strName,item:GetName())
		self:LLRemLog(self.tItems[GID].strName,item)
		self:RefreshMainItemList()
	end
end
-----------------------------------------------------------------------------------------------
-- Web
-----------------------------------------------------------------------------------------------
function DKP:WebInit()
	self.wndWebInfo = Apollo.LoadForm(self.xmlDoc,"Website",nil,self)
	self.wndWebInfo:Show(false)

end

function DKP:WebShow()
	
	if not self.wndWebInfo:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndWebInfo:Move(tCursor.x - 100, tCursor.y - 100, self.wndWebInfo:GetWidth(), self.wndWebInfo:GetHeight())
	end
	self.wndWebInfo:Show(true,false)
	self.wndWebInfo:ToFront()
end

function DKP:WebClose()
	self.wndWebInfo:Show(false,false)
end
-----------------------------------------------------------------------------------------------
-- Support
-----------------------------------------------------------------------------------------------
function DKP:SupportInit()
	self.wndSup = Apollo.LoadForm(self.xmlDoc,"Support",nil,self)
	self.wndSup:Show(false)
	self.wndSup:FindChild("ButtonCopy"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, "github.com/Mordonus/RaidOps/issues")
end

function DKP:SupportShow()
	
	if not self.wndSup:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndSup:Move(tCursor.x - 100, tCursor.y - 100, self.wndSup:GetWidth(), self.wndSup:GetHeight())
	end
	self.wndSup:Show(true,false)
	self.wndSup:ToFront()
end

function DKP:SupportClose()
	self.wndSup:Show(false,false)
end
-----------------------------------------------------------------------------------------------
-- ClassOrder
-----------------------------------------------------------------------------------------------

function DKP:COInit()
	self.wndCO = Apollo.LoadForm(self.xmlDoc3,"ClassOrder",nil,self)
	self.wndCO:Show(false)

	if not self.tItems["settings"].tClassOrder then self.tItems["settings"].tClassOrder = ktClassOrderDefault end

	self:COPopulate()
end

function DKP:COShow()
	if not self.wndCO:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndCO:Move(tCursor.x - 100, tCursor.y - 100, self.wndCO:GetWidth(), self.wndCO:GetHeight())
	end
	self.wndCO:Show(true,false)
	self.wndCO:ToFront()

end

function DKP:COPopulate()
	self.wndCO:FindChild("List"):DestroyChildren()
	for k , class in ipairs(self.tItems["settings"].tClassOrder) do
		local wnd = Apollo.LoadForm(self.xmlDoc3,"ClassOrderTile",self.wndCO:FindChild("List"),self)
		wnd:SetSprite(ktStringToIcon[class])
		wnd:SetData(k)
	end
	self.wndCO:FindChild("List"):ArrangeChildrenVert()
end

function DKP:COTileShowHighliht(wndHandler,wndControl)
	wndHandler:FindChild("Highlight"):Show(true)
end

function DKP:COTileHideHighliht(wndHandler,wndControl)
	wndHandler:FindChild("Highlight"):Show(false)
end

-- Drag&Drop

function DKP:COTileStartDragDrop(wndHandler,wndControl)
	if wndHandler ~= wndControl or self.bClassOrderDragDrop then return end
	Apollo.BeginDragDrop(wndControl, "DKPClassOrderSwap", wndControl:GetSprite(), wndControl:GetData())
	self.bClassOrderDragDrop = true
end

function DKP:COTileQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndHandler:GetName() == "ClassOrderTile" then return Apollo.DragDropQueryResult.Accept else return Apollo.DragDropQueryResult.PassOn end
end

function DKP:COTileDropped(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndHandler ~= wndControl then return end
	-- Swap in order table

	local source = self.tItems["settings"].tClassOrder[wndSource:GetData()]
	local target = self.tItems["settings"].tClassOrder[wndControl:GetData()]

	self.tItems["settings"].tClassOrder[wndSource:GetData()] = target
	self.tItems["settings"].tClassOrder[wndControl:GetData()] = source

	self:COPopulate()
	self.bClassOrderDragDrop = false

	if self.tItems["settings"].GroupByClass then self:RefreshMainItemList() end
end

function DKP:COTileDragDropCancel()
	self.bClassOrderDragDrop = false
end
-----------------------------------------------------------------------------------------------
-- Decay Reminder
-----------------------------------------------------------------------------------------------
function DKP:DRInit()
	self.wndDR = Apollo.LoadForm(self.xmlDoc,"DecayReminder",nil,self)
	self.wndDR:Show(false)

	if self.tItems["settings"].bRemindDecay == nil then self.tItems["settings"].bRemindDecay = false end
	if not self.tItems["settings"].strRemindMessage then self.tItems["settings"].strRemindMessage = "It's time to decay!" end
	if not self.tItems["settings"].nRemindInterval then self.tItems["settings"].nRemindInterval = 7 end

	self.wndDR:FindChild("Enable"):SetCheck(self.tItems["settings"].bRemindDecay)
	self.wndDR:FindChild("Period"):SetText(self.tItems["settings"].nRemindInterval)
	self.wndDR:FindChild("Msg"):SetText(self.tItems["settings"].strRemindMessage)

	if self.tItems["settings"].bRemindDecay and os.time() > self.tItems["settings"].nRemindTime then
		self.wndReminderGlow = Apollo.LoadForm(self.xmlDoc3,"TutGlow",self.tItems["EPGP"].Enable == 1 and self.wndMain:FindChild("EPGPDecayShow") or self.wndMain:FindChild("DecayShow"),self)
		self:delay(2,function (tContext) tContext:NotificationStart(tContext.tItems["settings"].strRemindMessage,10,5) end)
	end
	self:DRUpdateReminderLabel()
end

function DKP:DRShow()
	if not self.wndDR:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndDR:Move(tCursor.x - 400, tCursor.y - 250, self.wndDR:GetWidth(), self.wndDR:GetHeight())
	end

	self.wndDR:Show(true,false)
	self.wndDR:ToFront()
end

function DKP:DRClose()
	self.wndDR:Show(false,false)
end

function DKP:DREnable()
	self.tItems["settings"].bRemindDecay = true
	self.tItems["settings"].nRemindTime = os.time() + (24 * 3600 * self.tItems["settings"].nRemindInterval)
	self:DRUpdateReminderLabel()
end

function DKP:DRDisable()
	self.tItems["settings"].bRemindDecay = false
	if self.wndReminderGlow then self.wndReminderGlow:Destroy() end
	self:DRUpdateReminderLabel()
end

function DKP:DRSetInterval(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val > 0 then
		self.tItems["settings"].nRemindInterval = val
		self.tItems["settings"].nRemindTime = os.time() + (24 * 3600 * self.tItems["settings"].nRemindInterval)
	else
		wndControl:SetText(self.tItems["settings"].nRemindInterval)
	end
	self:DRUpdateReminderLabel()
end

function DKP:DRUpdateReminderLabel()
	if not self.tItems["settings"].nRemindTime or not self.tItems["settings"].bRemindDecay then 
		self.wndMain:FindChild("ReminderLabel"):SetText("--Disabled--") 
		self.wndMain:FindChild("ReminderLabelDKP"):SetText("--Disabled--") 
	else
		self.wndMain:FindChild("ReminderLabel"):SetText(self:ConvertDate(os.date("%x",self.tItems["settings"].nRemindTime)) .. " " .. os.date("%X",self.tItems["settings"].nRemindTime))
		self.wndMain:FindChild("ReminderLabelDKP"):SetText(self:ConvertDate(os.date("%x",self.tItems["settings"].nRemindTime)) .. " " .. os.date("%X",self.tItems["settings"].nRemindTime))
	end
end

function DKP:DROnDecay()
	self.tItems["settings"].nRemindTime = os.time() + (24 * 3600 * self.tItems["settings"].nRemindInterval)
	if self.wndReminderGlow then self.wndReminderGlow:Destroy() end
	self:DRUpdateReminderLabel()
end
-----------------------------------------------------------------------------------------------
-- DKP Instance
-----------------------------------------------------------------------------------------------
local DKPInst = DKP:new()
DKPInst:Init()