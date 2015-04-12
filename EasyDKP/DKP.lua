-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------
 

require "Apollo"
require "Window"

-----------------------------------------------------------------------------------------------
-- DKP Module Definition
-----------------------------------------------------------------------------------------------
local DKP = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrNormalText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloNormal")
 
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

local ktUndoActions = 
{
	--Players
	["addp"] = "{Added Player}",
	["addmp"] = "{Added Many Players}",
	["remp"] = "{Removed Player}",
	["mremp"] = "{Removed Multiple Players}",
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

-- Changelog
local strChangelog = 
[===[
---RaidOps version 2.0 revision 147 Beta Release Candidate 2---
{xx/04/2015}
Item label will now work properly , getting its info from Loot Logs.
Added option to automatically create simple comments.
Fixed issue with Logs window resizing.

---RaidOps version 2.0 revision 146 Beta ---
{10/04/2015}

Fixed Chat bidding's final countdown value setting.
Fixed bug that prevented from assigning items after chat bidding auction's end.
Adjusted size of Recent Activity columns.
Possible fix for disappearing class icons.
Fixed issues with Mass Edit while displaying color icons.
Separated mainspec and offspec bids in Chat bidding.
Added option to display much shorter messages in Chat bidding.
Added option to request full DB sync instead of an update.
Fixed an issue with alts and data sync.
Added option to notify raid about triggering of custom event.
Now Decay will add personal logs.
Personal logs window is a bit bigger now.


---RaidOps version 2.0 revision 145 Beta ---
{08/04/2015}

Changed visual representation of Network Bidding window. [Final UI]
Colored icons in roster window are now bigger.
Added /chatbid command for chat bidding window.
Fixed error when addon would try to close non-existant Network Bidding auction.
From now on Network Bidding button in both Hub and and Main window will enable upon Network Bidding's init.
Added item level filter to item filtering.
Added item quality filter to item filtering.
Fixed error on Convergence fight.
Comments will be no longer filled in Recent Activity on Custom Event trigger.
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
		-- "UnitOrPackageName",
	}
	self.tItems = {}
	self.tItems["purged"] = nil
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
		self.Locale = self.GeminiLocale:GetLocale("EasyDKP", true)
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
		self.wndSettings:FindChild("FixUmlauts"):SetTooltip(self.Locale["#wndSettings:Tooltips:FixNames"])
		self.wndSettings:FindChild("ButtonShowStandby"):SetTooltip(self.Locale["#wndSettings:Tooltips:Standby"])
		self.wndSettings:FindChild("FilterKeywordsButton"):SetTooltip(self.Locale["#wndSettings:Tooltips:FilterKey"])
		self.wndSettings:FindChild("ButtonSettingsPurge"):SetTooltip(self.Locale["#wndSettings:Tooltips:Purge"])
		--
		
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		if self.wndMainLoc ~= nil then 
			if self.tItems.wndMainLoc and self.tItems.wndMainLoc.nOffsets[1] ~= 0 then --and self.wndMainLoc.nOffsets[2] ~= 0 and self.wndMainLoc.nOffsets[3] ~= 0 and self.wndMainLoc.nOffsets[4] ~= 0 then
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
		self.wndMain:FindChild("MassEditControls"):Show(false,true)
		Apollo.RegisterSlashCommand("dkp", "OnDKPOn", self)
		Apollo.RegisterSlashCommand("sum", "RaidShowMainWindow", self)
		Apollo.RegisterSlashCommand("rops", "HubShow", self)
		Apollo.RegisterSlashCommand("ropsml", "MLSettingShow", self)
		Apollo.RegisterSlashCommand("nb", "Bid2ShowNetworkBidding", self)
		Apollo.RegisterSlashCommand("att", "AttendanceShow", self)
		Apollo.RegisterSlashCommand("chatbid", "BidOpen", self)
		--Apollo.RegisterSlashCommand("dbgf", "DebugFetch", self)
		Apollo.RegisterTimerHandler(10, "OnTimer", self)
		Apollo.RegisterTimerHandler(10, "RaidUpdateCurrentRaidSession", self)
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
		if self.tItems["Raids"] == nil then self.tItems["Raids"] = {} end
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
		if self.tItems["settings"].CheckAffiliation == nil then self.tItems["settings"].CheckAffiliation = 0 end
		if self.tItems["settings"].GroupByClass == nil then  self.tItems["settings"].GroupByClass = false end
		if self.tItems["settings"].FilterEquippable == nil then self.tItems["settings"].FilterEquippable = false end
		if self.tItems["settings"].FilterWords == nil then self.tItems["settings"].FilterWords = false end
		if self.tItems["settings"].networking == nil then self.tItems["settings"].networking = true end
		if self.tItems["settings"].bTrackUndo == nil then self.tItems["settings"].bTrackUndo = false end
		if self.tItems["settings"].nPopUpGPRed == nil then self.tItems["settings"].nPopUpGPRed = 25 end
		if self.tItems["settings"].bColorIcons == nil then self.tItems["settings"].bColorIcons = false end
		if self.tItems["settings"].bDisplayRoles == nil then self.tItems["settings"].bDisplayRoles = false end
		if self.tItems["settings"].bSaveUndo == nil then self.tItems["settings"].bSaveUndo = false end
		if self.tItems["settings"].bSkipGB == nil then self.tItems["settings"].bSkipGB = false end
		if self.tItems["settings"].bRemErrInv == nil then self.tItems["settings"].bRemErrInv = true end
		if self.tItems["settings"].bDisplayCounter == nil then self.tItems["settings"].bDisplayCounter = false end
		if self.tItems["settings"].bCountSelected == nil then self.tItems["settings"].bCountSelected = false end
		if self.tItems["settings"].bTrackTimedAwardUndo == nil then self.tItems["settings"].bTrackTimedAwardUndo = false end
		if self.tItems["settings"].bLootLogs == nil then self.tItems["settings"].bLootLogs = true end
		if self.tItems["settings"].bAutoLog == nil then self.tItems["settings"].bAutoLog = true end
		if self.tItems["settings"].strLootFiltering == nil then self.tItems["settings"].strLootFiltering = "Nil" end
		if self.tItems["settings"].bPopUpRandomSkip == nil then self.tItems["settings"].bPopUpRandomSkip = false end
		if self.tItems["settings"].nMinIlvl == nil then self.tItems["settings"].nMinIlvl = 1 end
		if self.tItems["Standby"] == nil then self.tItems["Standby"] = {} end
		if self.tItems.tQueuedPlayers == nil then self.tItems.tQueuedPlayers = {} end
		self.wndLabelOptions = self.wndMain:FindChild("LabelOptions")
		self.wndTimeAward = self.wndMain:FindChild("TimeAward")
		self.wndLabelOptions:Show(false,true)
		self.wndTimeAward:Show(false,true)
		self.MassEdit = false
		-- Inits
		self:TimeAwardRestore()
		self:EPGPInit()
		self:RaidOpsInit()
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
		self:RaidInit()
		self:FQInit()
		-- Colors
	
		if self.tItems["settings"].bColorIcons then ktStringToIcon = ktStringToNewIconOrig else ktStringToIcon = ktStringToIconOrig end
		
		self.wndMain:FindChild("ShowDPS"):SetCheck(true)
		self.wndMain:FindChild("ShowHeal"):SetCheck(true)
		self.wndMain:FindChild("ShowTank"):SetCheck(true)
		
		-- Bidding
		
		self.tSelectedItems = {}
		self.bAwardingOnePlayer = false
		
		
		self.SortedLabel = nil
		self:LabelUpdateList() --<<<< With Show ALL
		self:UpdateItemCount()
		self:RaidInit()
		self.wndMain:FindChild("Decay"):Show(false)
		self:DecayRestore()
		self:ControlsUpdateQuickAddButtons()
		self:EnableActionButtons()
		self.wndChangelog:FindChild("Log"):SetText(strChangelog)
		
		if self.tItems["settings"].BidEnable == 1 then self:BidBeginInit()
		else
			self.wndMain:FindChild("CustomAuction"):Show(false)
			self.wndMain:FindChild("BidCustomStart"):Show(false)
			self.wndMain:FindChild("LabelAuction"):Show(false)
			self.wndHub:FindChild("NetworkBidding"):Show(false)
			self:DSInit()
		end
		if self.tItems["settings"].RaidTools.show == 1 then self:RaidToolsEnable() end
		self:SettingsRestore()
		
		if self:GetPlayerByIDByName("Guild Bank") == -1 then
			self:OnUnitCreated("Guild Bank",true)
		end
		self.wndMain:FindChild("ButtonNB"):Enable(false)
		self.wndHub:FindChild("NetworkBidding"):Enable(false)
		
	end
end

function DKP:DebugFetch()
	self:ExportShowPreloadedText(tohtml(self:GetEncodedData("Drutol Windchaser")))
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

function DKP:UndoAddActivity(strType,strMod,tMembers,bRemoval)
	if not self.tItems["settings"].bTrackUndo then return end
	local tMembersNames = {}
	local strComment = ""
	if bRemoval == true or bRemoval == false then strComment = "--" 
	elseif self:string_starts(strType,"Award for") then  strComment = "--" 
	elseif strType == ktUndoActions["addmp"] then  strComment = "--" 
	elseif strType == ktUndoActions["remp"] then  strComment = "--" 
	elseif strType == ktUndoActions["mremp"] then  strComment = "--" 
	elseif self.tItems["settings"].logs == 1 then 
		strComment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
		if strComment == "Comment" or strComment == "Comments Disabled"  then strComment = "--" end
	end
	for k,player in ipairs(tMembers) do table.insert(tMembersNames,player.strName) end
	table.sort(tMembersNames,raidOpsSortCategories)
	table.insert(tUndoActions,1,{tAffectedNames = tMembersNames,strType = strType,strMod = strMod,nAffected = #tMembers,strData = serpent.dump(tMembers),bRemove = bRemoval,strTimestamp = os.date("%x",os.time()) .. " " .. os.date("%X",os.time()),strComment = strComment})
	if #tUndoActions > 15 then table.remove(tUndoActions,16) end
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

function DKP:Undo()
	if #tUndoActions > 0 then
		local tMembersToRevert = serpent.load(tUndoActions[1].strData)
		
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
		
		if tMembersToRevert then
			for k,revertee in ipairs(tMembersToRevert) do
				if tUndoActions[1].bRemove == nil then
					for k,player in ipairs(self.tItems) do
						if player.strName == revertee.strName then -- modifications 
							self.tItems[k] = revertee
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
local uGuild
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
	if uGuild then
		local tRanks = uGuild:GetRanks()
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
	self:UndoAddActivity(#tMembers == 1 and ktUndoActions["addp"] or ktUndoActions["addmp"],"--",tMembers,false)
	self:RefreshMainItemList()
	self:GIUpdateCount()
	
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
			uGuild = guild
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
				if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
					comment = "Set EP"
				elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
					comment = "Set GP"
				end
			end
			if self.tItems["EPGP"].Enable == 0 then	
				if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(ktUndoActions["setdkp"],value,{[1] = self.tItems[ID]}) end
				self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(value)
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
					wndTot:SetText(tostring(currentTot))
				end
				self:DetailAddLog(comment,"{DKP}",modifierTot,ID)
				self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifierTot)
			else
				local ID = self:GetPlayerByIDByName(strName)
				if cycling ~= true and self.tItems["settings"].bTrackUndo then 	
					self:UndoAddActivity(self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() and ktUndoActions["setgp"] or ktUndoActions["setep"],value,{[1] = self.tItems[ID]}) 
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
		count = #self.wndItemList:GetChildren()
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
				tSave[k].Hrs = player.Hrs
				tSave[k].TradeCap = player.TradeCap
				tSave[k].EP = player.EP
				tSave[k].GP = player.GP
				tSave[k].class = player.class
				tSave[k].alts = player.alts
				tSave[k].logs = player.logs
				tSave[k].role = player.role
				tSave[k].offrole = player.offrole
				tSave[k].tLLogs = player.tLLogs
			end
			if self.tItems["alts"] ~= nil then
				tSave["alts"]=self.tItems["alts"]
			end
			
			tSave["settings"] = self.tItems["settings"]
			tSave["Raids"] = self.tItems["Raids"]
			tSave["trades"] = self.tItems["trades"]
			tSave["EPGP"] = self.tItems["EPGP"]
			tSave["Standby"] = self.tItems["Standby"]
			tSave["AwardTimer"] = self.tItems["AwardTimer"]
			tSave["Hub"] = self.tItems["Hub"]
			tSave["BidSlots"] = self.tItems["BidSlots"]
			tSave["Auctions"] = {}
			tSave["MyChoices"] = self.MyChoices
			tSave["MyVotes"] = self.MyVotes
			tSave["CE"] = self.tItems["CE"]
			if self.tItems["settings"].bSaveUndo then tSave["ALogs"] = tUndoActions end
			tSave.wndMainLoc = self.wndMain:GetLocation():ToTable()
			tSave.wndPopUpLoc = self.wndPopUp:GetLocation():ToTable()
			tSave.wndLLLoc = self.wndLL:GetLocation():ToTable()
			if self.wndBid2 then
				tSave.wndNBLoc = self.wndBid2:GetLocation():ToTable()
			end
			tSave.newUpdateAltCleanup = self.tItems.newUpdateAltCleanup
			tSave.tQueuedPlayers = self.tItems.tQueuedPlayers
			for k,auction in ipairs(self.ActiveAuctions) do
				if auction.bActive or auction.nTimeLeft > 0 then table.insert(tSave["Auctions"],{itemID = auction.wnd:GetData(),bidders = auction.bidders,votes = auction.votes,bMaster = auction.bMaster,progress = auction.nTimeLeft}) end
			end
		else
			tSave["purged"] = "purged"
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
		self.wndMainLoc = WindowLocation.new(tData.wndMainLoc)
		
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
	
	if self.wndSelectedListItem ~=nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText()
			local value = tonumber(self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText())
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
				if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
					comment = "Add EP"
				elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
					comment = "Add GP"
				end
			end
			local ID = self:GetPlayerByIDByName(strName)
			if ID ~= -1  then
				if self.tItems["EPGP"].Enable == 0 then
				         	if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(ktUndoActions["adddkp"],value,{[1] = self.tItems[ID]})  end
   				          local modifier = self.tItems[ID].net
					self.tItems[ID].net = self.tItems[ID].net + value
					self.tItems[ID].tot = self.tItems[ID].tot + value
					modifier = self.tItems[ID].net - modifier
					if self:LabelGetColumnNumberForValue("Net") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(self.tItems[ID].net)
					end
					if self:LabelGetColumnNumberForValue("Tot") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Tot"))):SetText(self.tItems[ID].tot)
					end
					
					self:DetailAddLog(comment,"{DKP}",modifier,ID)
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifier)
				else
					if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() and ktUndoActions["addgp"] or ktUndoActions["addep"],value,{[1] = self.tItems[ID]})  end
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
	
	if self.wndSelectedListItem ~=nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText()
			local value = tonumber(self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText())
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			local ID = self:GetPlayerByIDByName(strName)
			if comment == "Comment - Auto" and self.tItems["settings"].bAutoLog then 
				if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() then
					comment = "Subtract EP"
				elseif self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() then
					comment = "Subtract GP"
				end
			end
			if ID ~= -1 then
				if self.tItems["EPGP"].Enable == 0 then
					if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(ktUndoActions["subdkp"],value,{[1] = self.tItems[ID]}) end
					local modifier = self.tItems[ID].net
					self.tItems[ID].net = self.tItems[ID].net - value
					modifier = self.tItems[ID].net - modifier
					if self:LabelGetColumnNumberForValue("Net") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(self.tItems[ID].net)
					end
					
					self:DetailAddLog(comment,"{DKP}",modifier,ID)
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifier)
				else
					if cycling ~= true and self.tItems["settings"].bTrackUndo then self:UndoAddActivity(self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() and ktUndoActions["subgp"] or ktUndoActions["subep"],value,{[1] = self.tItems[ID]})  end
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
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,self.tItems["settings"].dkp)
				end
			end
			self:ShowAll()
			if self.tItems["settings"].bTrackUndo and tMembers then self:UndoAddActivity(ktUndoActions["raward"],self.tItems["settings"].dkp,tMembers) end
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
			
			if words[1] ~= "The"  then return end
	
			local collectingItem = true
			for i=5 , table.getn(words) do
				if words[i] == "to" then collectingItem = false end
				if collectingItem == true then
					itemStr = itemStr .." ".. words[i]
				elseif words[i] ~= "to" then
					strName = strName .. " " .. words[i]
				end
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
			
			
			
			
			self:Bid2CloseOnAssign(string.sub(itemStr,2))
			strName = string.sub(strName,2)
			self:LLAddLog(strName:sub(1, #strName - 1),string.sub(itemStr,2))

			if strName ~= "" and itemStr ~= "" then
				if self.tItems["settings"].PopupEnable == 1 then self:PopUpWindowOpen(strName:sub(1, #strName - 1),string.sub(itemStr,2)) end
				if self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == false then self:RaidProccesNewPieceOfLoot(itemStr,strName:sub(1,#strName-1)) end
				self:HubRegisterLoot(strName:sub(1, #strName - 1),string.sub(itemStr,2))
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
			 self:HubRegisterLoot(strName,strItem)
			 self:Bid2CloseOnAssign(strItem)
			 self:LLAddLog(strName,strItem)
		end
	end
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_NPCSay and GroupLib.InRaid() then
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
	end
	if self.tItems["settings"].whisp == 1 then
		if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper then
			local senderStr = tMessage.strSender
			if self.tItems["settings"].lowercase == 1 then senderStr = string.lower(senderStr) end

			if self.tItems["settings"].lowercase == 1 and senderStr == string.lower(GameLib.GetPlayerUnit():GetName()) then return end
			
			
			
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
	
	if val and strComment ~= "Comment" and self.wndSelectedListItem or val and strText ~= "Comment" and #selectedMembers > 0 and self.MassEdit then
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
	if strName ~= "Input New Entry Name" then
		self:OnUnitCreated(strName,true)
		self.wndMain:FindChild("Controls"):FindChild("EditBoxPlayerName"):SetText("Input New Entry Name")
		self:UndoAddActivity(ktUndoActions["addp"],"--",{[1] = self.tItems[self:GetPlayerByIDByName(strName)]},false)
	end
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

function DKP:TimeAwardStart( wndHandler, wndControl, eMouseButton )
	if self.tItems["AwardTimer"].running == 0 then
		if self.tItems["AwardTimer"].amount ~= nil and self.tItems["AwardTimer"].period ~= nil then
			Apollo.RegisterTimerHandler(1, "TimeAwardTimer", self)
			self.AwardTimer = ApolloTimer.Create(1, true, "TimeAwardTimer", self)
			self.NextAward = self.tItems["AwardTimer"].period
			self.tItems["AwardTimer"].running = 1
		end
	end
	self:TimeAwardRefresh()
end

function DKP:TimeAwardRefresh()
	if self.tItems["AwardTimer"].running == 1 then
		self.wndTimeAward:FindChild("StateFrame"):FindChild("State"):SetSprite("achievements:sprAchievements_Icon_Complete")
		local diff =  os.date("*t",self.NextAward)
		if diff ~= nil then
			self.wndTimeAward:FindChild("CountDown"):SetText((diff.hour-1 <=9 and "0" or "" ) .. diff.hour-1 .. ":" .. (diff.min <=9 and "0" or "") .. diff.min .. ":".. (diff.sec <=9 and "0" or "") .. diff.sec)
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
		self.NextAward = self.tItems["settings"].period
		self.tItems["AwardTimer"].running = 0
		self:TimeAwardStart()
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
	
	if self.tItems["AwardTimer"].Hrs == 1 then
		self.wndTimeAward:FindChild("Options"):FindChild("HRS"):SetCheck(true)
	end
	
	if self.tItems["AwardTimer"].Notify == 1 then
		self.wndTimeAward:FindChild("Options"):FindChild("Notify"):SetCheck(true)
	end
	
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
	if self.tItems["AwardTimer"].Hrs == 1 then
		for i=1,GroupLib.GetMemberCount() do
			local member = GroupLib.GetGroupMember(i)
			if self.tItems["AwardTimer"].Hrs == 1 then
				local ID = self:GetPlayerByIDByName(member.strCharacterName)
				if ID ~= -1 then self.tItems[ID].Hrs = self.tItems[ID].Hrs + 0.00027 end
			end
		end
	end
end

function DKP:TimeAwardAward()
	local raidMembers =  {}
	for i=1,GroupLib.GetMemberCount() do
		local unit_member = GroupLib.GetGroupMember(i)
		table.insert(raidMembers,unit_member.strCharacterName)
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
			end
			
			if self.wndTimeAward:FindChild("Settings"):FindChild("GP"):IsChecked() then
				self.tItems[ID].GP = self.tItems[ID].GP + self.tItems["AwardTimer"].amount
			end
			
			if self.wndTimeAward:FindChild("Settings"):FindChild("DKP"):IsChecked() then
				self.tItems[ID].net = self.tItems[ID].net + self.tItems["AwardTimer"].amount
				self.tItems[ID].tot = self.tItems[ID].tot + self.tItems["AwardTimer"].amount
			end
		end
	end
	
	self:ShowAll()
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

function DKP:TimeAwardEnableHRS( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].Hrs = 1
end

function DKP:TimeAwardDisableHRS( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].Hrs = 0
end

function DKP:TimeAwardEnableNotification( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].Notify = 1
end

function DKP:TimeAwardDisableNotification( wndHandler, wndControl, eMouseButton )
	self.tItems["AwardTimer"].Notify = 0
end

function DKP:TimeAwardPostNotification()
	ChatSystemLib.Command("/party [EasyDKP] Timed awards have been granted")
end
---------------------------------------------------------------------------------------------------
-- Mass Edit
---------------------------------------------------------------------------------------------------

function DKP:MassEditEnable( wndHandler, wndControl, eMouseButton )
	self.wndSelectedListItem = nil
	selectedMembers = {}
	self.MassEdit = true
	self:RefreshMainItemList()
	self.wndMain:FindChild("MassEditControls"):Show(true,true)
	self:EnableActionButtons()
end

function DKP:MassEditDisable( wndHandler, wndControl, eMouseButton )
	self.wndSelectedListItem = nil
	self.MassEdit = false
	self:RefreshMainItemList()
	self.wndMain:FindChild("MassEditControls"):Show(false,true)
	self:EnableActionButtons()
end

function DKP:MassEditSelectRaid( wndHandler, wndControl, eMouseButton )
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	selectedMembers = {}
	local children = self.wndItemList:GetChildren()
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
	local children = self.wndItemList:GetChildren()
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

function DKP:MassEditSelectAll( wndHandler, wndControl, eMouseButton )
	selectedMembers = {}
	local children = self.wndItemList:GetChildren()
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
			for k,alt in ipairs(self.tItems[ID].alts) do self.tItems["alts"][string.lower(alt)] = nil end
			table.remove(self.tItems,ID)
		end
	end
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
		
		if tMembers then self:UndoAddActivity(strType,self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText(),tMembers) end 
		
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
		
		if tMembers then self:UndoAddActivity(strType,self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText(),tMembers) end 
		
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
		
		if tMembers then self:UndoAddActivity(strType,self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText(),tMembers) end 
		
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
end

function DKP:MassEditItemDeselected( wndHandler, wndControl, eMouseButton)
	for i,wnd in ipairs(selectedMembers) do
		if wnd == wndControl then 
			table.remove(selectedMembers,i) 
			break
		end
	end
	self:UpdateItemCount()
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


function DKP:RefreshMainItemList()
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
	for k,player in ipairs(self.tItems) do
		if player.strName ~= "Guild Bank" then
			if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
				if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInQueue(player.strName) then
					if not self.wndMain:FindChild("OnlineOnly"):IsChecked() or self.wndMain:FindChild("OnlineOnly"):IsChecked() and self:IsPlayerOnline(tOnlineMembers,player.strName) then
						if self:IsPlayerRoleDesired(player.role) then	
							if not self.MassEdit then
								player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
							else
								player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
							end
							
							-- Cheking for alt
							
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
							player.wnd:SetData(k)
						end
					end
				end
			end
		end
	end
	self:RaidQueueShow()
	self.wndItemList:ArrangeChildrenVert(0,easyDKPSortPlayerbyLabel)
	if self.tItems["settings"].bDisplayCounter then
		for k,child in ipairs(self.wndItemList:GetChildren()) do
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
	if self.tItems["settings"].GroupByClass then
		if k and k == 1 or bAddedClass == false then playerItem.wnd:FindChild("NewClass"):Show(true,false) end
	end
	for i=1,5 do
		if self.tItems["settings"].LabelOptions[i] ~= "Nil" then
			if self.tItems["settings"].LabelOptions[i] == "Name" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.strName)
			elseif self.tItems["settings"].LabelOptions[i] == "Net" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.net)
			elseif self.tItems["settings"].LabelOptions[i] == "Tot" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.tot)
			elseif self.tItems["settings"].LabelOptions[i] == "Raids" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.raids or "0")
			elseif self.tItems["settings"].LabelOptions[i] == "Item" then
				if playerItem.tLLogs then
					local item = Item.GetDataFromId(playerItem.tLLogs[1].itemID)
					if item then
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
						Apollo.LoadForm(self.xmlDoc,"LoadIconToStat",playerItem.wnd:FindChild("Stat"..tostring(i)),self)
						playerItem.wnd:FindChild("Stat"..tostring(i)):FindChild("LoadIconToStat"):SetSprite(item:GetIcon())
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetText("")
						local l,t,r,b = playerItem.wnd:FindChild("Stat"..tostring(i)):GetAnchorOffsets()
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetAnchorOffsets(l+32.5,t,r-32.5,b)
						Tooltip.GetItemTooltipForm(self,playerItem.wnd:FindChild("Stat"..tostring(i)):FindChild("LoadIconToStat"), item  ,{bPrimary = true, bSelling = false})
					end
				end
			elseif self.tItems["settings"].LabelOptions[i] == "Hrs" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%.4f",playerItem.Hrs))
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
end

---------------------------------------------------------------------------------------------------
-- Label Setting
---------------------------------------------------------------------------------------------------

function DKP:LabelNumberChanged(wndHandler, wndControl, eMouseButton)
		self.CurrentlyEditedLabel = tonumber(wndControl:GetText())
		self:LabelTypeButtonsCheck(self.tItems["settings"].LabelOptions[tonumber(wndControl:GetText())])
end

function DKP:LabelCheckNumber( wndHandler, wndControl, eMouseButton )
	local parent = wndControl:GetParent()
	if parent:FindChild("Button1"):IsChecked() == false and parent:FindChild("Button2"):IsChecked() == false and parent:FindChild("Button3"):IsChecked() == false and parent:FindChild("Button4"):IsChecked() == false and parent:FindChild("Button5"):IsChecked() == false then
		self.CurrentlyEditedLabel = nil
		self:LabelTypeButtonsUncheckAll()
	end
end

function DKP:LabelCheckType( wndHandler, wndControl, eMouseButton )
	local parent = wndControl:GetParent()
	if parent:FindChild("Name"):IsChecked() == false and parent:FindChild("Net"):IsChecked() == false and parent:FindChild("Tot"):IsChecked() == false and parent:FindChild("Hrs"):IsChecked() == false and parent:FindChild("Spent"):IsChecked() == false and parent:FindChild("Priority"):IsChecked() == false then
		if self.CurrentlyEditedLabel ~= nil then
			self.tItems["settings"].LabelOptions[self.CurrentlyEditedLabel] = "Nil"
			
		end
	end
	self:LabelUpdateList()
end


function DKP:LabelTypeChanged( wndHandler, wndControl, eMouseButton )
	
	if self.CurrentlyEditedLabel ~= nil then
		for i=1,5 do
			if self.tItems["settings"].LabelOptions[i] == wndControl:GetName() then
				 self.tItems["settings"].LabelOptions[i] = "Nil"
			end
		end
		self.tItems["settings"].LabelOptions[self.CurrentlyEditedLabel] = wndControl:GetName()
	end
	self:LabelUpdateList()
end

function DKP:LabelUpdateList() 
	-- Label Bar first
	local wndLabelBar = self.wndMain:FindChild("LabelBar")
	for i=1,5 do 
		if self.tItems["settings"].LabelOptions[i] ~= "Nil" then
			wndLabelBar:FindChild("Label"..tostring(i)):Show(true,false)
			wndLabelBar:FindChild("Label"..tostring(i)):SetText(self.tItems["settings"].LabelOptions[i])
			wndLabelBar:FindChild("Label"..tostring(i)):SetTooltip(self:LabelAddTooltipByValue(self.tItems["settings"].LabelOptions[i]))
		else
			wndLabelBar:FindChild("Label"..tostring(i)):Show(false)
		end
		
		if self.SortedLabel and self.SortedLabel == i then
			wndLabelBar:FindChild("Label"..tostring(i)):FindChild("SortIndicator"):Show(true)
		end
	end
	-- Check for priority sorting
	self:RefreshMainItemList()
	-- Remove prev item selected
	self.wndSelectedListItem = nil 

end

function DKP:LabelAddTooltipByValue(value)
	return self.Locale["#LabelTooltips:"..value]
end

function DKP:LabelTypeButtonsCheck(which)
	self:LabelTypeButtonsUncheckAll()
	if which ~= "Nil" then
		self.wndLabelOptions:FindChild("LabelTypes"):FindChild(which):SetCheck(true)
	end
end

function DKP:LabelTypeButtonsUncheckAll()
	 local boxes = self.wndLabelOptions:FindChild("LabelTypes"):GetChildren()
	 for i, box in ipairs(boxes) do
		box:SetCheck(false)
	end

end

function DKP:LabelOptionsShow()
	self.wndLabelOptions:Show(true)
end

function DKP:LabelOptionsHide()
	self.wndLabelOptions:Show(false)
end

function DKP:LabelGetColumnNumberForValue(value)
	for i=1,5 do
		if self.tItems["settings"].LabelOptions[i] == value then return i end
	end
	return -1
end

function easyDKPSortPlayerbyLabel(a,b)
	local DKPInstance = Apollo.GetAddon("EasyDKP")
	if DKPInstance.SortedLabel then
		local sortBy = DKPInstance.tItems["settings"].LabelOptions[DKPInstance.SortedLabel]
		local label = "Stat"..DKPInstance.SortedLabel
		if a:FindChild(label) and b:FindChild(label) then
			if DKPInstance.tItems["settings"].LabelSortOrder == "asc" then
				if sortBy ~= "Name" then
					return tonumber(a:FindChild(label):GetText()) > tonumber(b:FindChild(label):GetText())
				else
					return a:FindChild(label):GetText() > b:FindChild(label):GetText()
				end
			else
				if sortBy ~= "Name" then
					return tonumber(a:FindChild(label):GetText()) < tonumber(b:FindChild(label):GetText())
				else
					return a:FindChild(label):GetText() < b:FindChild(label):GetText()
				end
			end
		end
	end
end

function easyDKPSortPlayerbyLabelNotWnd(a,b)
	local DKPInstance = Apollo.GetAddon("EasyDKP")
	if DKPInstance.SortedLabel then
		local sortBy = DKPInstance.tItems["settings"].LabelOptions[DKPInstance.SortedLabel]
		local label = "Stat"..DKPInstance.SortedLabel
		if DKPInstance.tItems["settings"].LabelSortOrder == "asc" then
			if sortBy == "Name" then return a.strName > b.strName 
			elseif sortBy == "Net" then return tonumber(a.net) > tonumber(b.net)
			elseif sortBy == "Tot" then return tonumber(a.tot) > tonumber(b.tot) 
			elseif sortBy == "Spent" then return tonumber(a.tot) - tonumber(a.net) > tonumber(b.tot) - tonumber(b.net)
			elseif sortBy == "Hrs" then return a.Hrs > b.Hrs
			elseif sortBy == "Priority" then 
				if tonumber(a.tot)-tonumber(a.net) == 0 then return b end
				if tonumber(b.tot)-tonumber(b.net) == 0 then return a end
				local pra = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(a.tot)/(tonumber(a.tot)-tonumber(a.net))))
				local prb = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(b.tot)/(tonumber(b.tot)-tonumber(b.net))))
				return pra > prb
			elseif sortBy == "EP" then return a.EP > b.EP
			elseif sortBy == "GP" then return a.GP > b.GP
			elseif sortBy == "PR" then return  tonumber(DKPInstance:EPGPGetPRByName(a.strName)) > tonumber(DKPInstance:EPGPGetPRByName(b.strName))
			end
		else
			if sortBy == "Name" then return a.strName < b.strName 
			elseif sortBy == "Net" then return tonumber(a.net) < tonumber(b.net)
			elseif sortBy == "Tot" then return tonumber(a.tot) < tonumber(b.tot) 
			elseif sortBy == "Spent" then return tonumber(a.tot) - tonumber(a.net) < tonumber(b.tot) - tonumber(b.net)
			elseif sortBy == "Hrs" then return a.Hrs < b.Hrs
			elseif sortBy == "Priority" then 
				if tonumber(a.tot)-tonumber(a.net) == 0 then return b end
				if tonumber(b.tot)-tonumber(b.net) == 0 then return a end
				local pra = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(a.tot)/(tonumber(a.tot)-tonumber(a.net))))
				local prb = tonumber(string.format("%."..tostring(DKPInstance.tItems["settings"].Precision).."f",tonumber(b.tot)/(tonumber(b.tot)-tonumber(b.net))))
				return pra < prb
			elseif sortBy == "EP" then return a.EP < b.EP
			elseif sortBy == "GP" then return a.GP < b.GP
			elseif sortBy == "PR" then return  tonumber(DKPInstance:EPGPGetPRByName(a.strName)) < tonumber(DKPInstance:EPGPGetPRByName(b.strName))
			end
		end
	end
end

function DKP:RefreshMainItemListAndGroupByClass()
	local selectedPlayer = ""
	if self:LabelGetColumnNumberForValue("Name") > 0 then
		if self.MassEdit then
			selectedPlayer = {}
			for k,player in ipairs(selectedMembers) do
				table.insert(selectedPlayer,player:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
			end
		elseif self.wndSelectedListItem then
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
		for k,player in ipairs(self.tItems) do
			if player.strName ~= "Guild Bank" then
				if player.class ~= nil then
					if player.class == "Esper" then
						table.insert(esp,player)
					elseif player.class == "Engineer" then
						table.insert(eng,player)
					elseif player.class == "Medic" then
						table.insert(med,player)
					elseif player.class == "Warrior" then
						table.insert(war,player)
					elseif player.class == "Stalker" then
						table.insert(sta,player)
					elseif player.class == "Spellslinger" then
						table.insert(spe,player)
					end
				else
					table.insert(unknown,player)
				end
			end
		end
	else
		for k,player in ipairs(self.tItems) do
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
	
	self:RaidQueueShow()
	self.wndItemList:ArrangeChildrenVert()
	self.wndItemList:SetVScrollPos(self.nHScroll)
	self:UpdateItemCount()
end

function DKP:LabelSort(wndHandler,wndControl,eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then 
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
		self.SortedLabel = nil
		self:RefreshMainItemList()
	end
	if self.tItems["settings"].bDisplayCounter and not self.tItems["settings"].GroupByClass then
		for k,child in ipairs(self.wndItemList:GetChildren()) do
			child:FindChild("Counter"):Show(true)
			child:FindChild("Counter"):SetText(k..".")
		end
	end
	self:LabelHideIndicators()
end

function DKP:LabelUpdateColorHighlight()
	if self.SortedLabel then
		local label = "Stat"..self.SortedLabel
		for k,child in ipairs(self.wndItemList:GetChildren()) do	
			for j,stat in ipairs(child:GetChildren()) do
				if stat:GetName() == label then stat:SetTextColor("ChannelAdvice") else stat:SetTextColor("white") end
			end
		end
	end

end
function DKP:LabelHideIndicators()
	local wndLabelBar = self.wndMain:FindChild("LabelBar")
	for i=1,5 do
		if i ~= self.SortedLabel then
			wndLabelBar:FindChild("Label"..i):FindChild("SortIndicator"):Show(false,false)
		else
			wndLabelBar:FindChild("Label"..i):FindChild("SortIndicator"):Show(true,false)
		end
	end

end

function DKP:LabelIsSortable(strLabel) 
	if strLabel == "Item" then return false else return true end
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
function DKP:DecayCheckPeriod( wndHandler, wndControl, eMouseButton )
	if self.wndMain:FindChild("Decay"):FindChild("Raidly"):IsChecked() == false and self.wndMain:FindChild("Decay"):FindChild("Monthly"):IsChecked() == false and self.wndMain:FindChild("Decay"):FindChild("Weekly"):IsChecked()==false then
		if self.tItems["settings"].DecayPeriod == "w" then
			self.wndMain:FindChild("Decay"):FindChild("Weekly"):SetCheck(true)
		elseif self.tItems["settings"].DecayPeriod == "m" then
			self.wndMain:FindChild("Decay"):FindChild("Monthly"):SetCheck(true)
		elseif self.tItems["settings"].DecayPeriod == "r" then
			self.wndMain:FindChild("Decay"):FindChild("Raidly"):SetCheck(true)
		end
	end
end

function DKP:DecayChangeValue( wndHandler, wndControl, strText )
	if strText == "" or tonumber(strText) == nil then
		wndControl:SetText("Value")
		self.tItems["settings"].DecayVal = nil 
	elseif tonumber(strText) ~= nil then
		local num = tonumber(strText)
		if num >= 1 and num <= 100 then
			self.tItems["settings"].DecayVal = tonumber(strText)
		else
			wndControl:SetText("Value")
			self.tItems["settings"].DecayVal = nil
		end
	end
	self:DecayCheckConditions()
end

function DKP:DecayEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].Decay = 1
	self:DecayUpdateTimer()
	self:DecayUpdateHelp()
	self:DecayCheckConditions()

end

function DKP:DecayDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].Decay = 0
	self:DecayUpdateTimer()
	self:DecayUpdateHelp()
	self:DecayCheckConditions()
	
end

function DKP:DecayPeriodChanged( wndHandler, wndControl, eMouseButton )
	if wndControl:GetText() == "Weekly" then
		self.tItems["settings"].DecayPeriod = "w"
	elseif wndControl:GetText() == "Monthly" then
		self.tItems["settings"].DecayPeriod = "m"
	elseif wndControl:GetText() == "After Raid" then
		self.tItems["settings"].DecayPeriod = "r"
	end
	
	if self.wndMain:FindChild("Decay"):FindChild("Raidly"):IsChecked() == false and self.wndMain:FindChild("Decay"):FindChild("Monthly"):IsChecked() == false and self.wndMain:FindChild("Decay"):FindChild("Weekly"):IsChecked()==false then
		if self.tItems["settings"].DecayPeriod == "w" then
			self.wndMain:FindChild("Decay"):FindChild("Weekly"):SetCheck(true)
		elseif self.tItems["settings"].DecayPeriod == "m" then
			self.wndMain:FindChild("Decay"):FindChild("Monthly"):SetCheck(true)
		elseif self.tItems["settings"].DecayPeriod == "r" then
			self.wndMain:FindChild("Decay"):FindChild("Raidly"):SetCheck(true)
		end
	end
	self:DecayUpdateTimer()
	self:DecayUpdateHelp()
end

function DKP:Decay( wndHandler, wndControl, eMouseButton )
	if self.tItems["settings"].Decay == 1 and self.tItems["settings"].DecayVal ~= nil  then
		for i=1 , table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and self.tItems["Standby"][string.lower(self.tItems[i].strName)] == nil  then
				if tonumber(self.tItems[i].net) > 0 and math.abs(tonumber(self.tItems[i].net)) >= tonumber(self.tItems["settings"].DecayTreshold) then
					local modifier = self.tItems[i].net
					self:DetailAddLog("Decay","--",math.floor(self.tItems[i].net * ((100 -self.tItems["settings"].DecayVal) / 100)) - modifier ,i)
					self.tItems[i].net = math.floor(self.tItems[i].net * ((100 -self.tItems["settings"].DecayVal) / 100))
				elseif tonumber(self.tItems[i].net) < 0 and tonumber(self.tItems[i].net) >= tonumber(self.tItems["settings"].DecayTreshold) then
					local val = math.abs(tonumber(self.tItems[i].net))
					local modifier = val
					val = math.floor(val * ((100  + self.tItems["settings"].DecayVal) / 100))
					modifier = val - modifier
					self.tItems[i].net = val * -1
					self:DetailAddLog("Decay","--",modifier,i)
				end
			end
		end
	end
	self:ShowAll()
end

function DKP:DecayAddStandby( wndHandler, wndControl, eMouseButton )
	self:StandbyListAdd(nil,nil,self.tItems[detailedEntryID].strName)
end

function DKP:DecayRemoveStandby( wndHandler, wndControl, eMouseButton )
	self.tItems["Standby"][string.lower(self.tItems[detailedEntryID].strName)] = nil 
end

function DKP:DecayRestore()
	if self.tItems["settings"].DecayPeriod == nil then
		self.tItems["settings"].DecayPeriod = "w"
	end
	
	
	
	if self.tItems["settings"].Decay == nil then
		self.tItems["settings"].Decay = 0
	end
	if self.tItems["settings"].DecayVal ~= nil then
		self.wndMain:FindChild("Decay"):FindChild("DecayValue"):SetText(self.tItems["settings"].DecayVal)
	end
	
	if self.tItems["settings"].DecayTreshold == nil then self.tItems["settings"].DecayTreshold = 0 end
	self.wndMain:FindChild("Decay"):FindChild("DecayExt"):FindChild("EditBox"):SetText(self.tItems["settings"].DecayTreshold)
	if self.tItems["settings"].DecayPeriod == "w" then
		self.wndMain:FindChild("Decay"):FindChild("Weekly"):SetCheck(true)
	elseif self.tItems["settings"].DecayPeriod == "m" then
		self.wndMain:FindChild("Decay"):FindChild("Monthly"):SetCheck(true)
	elseif self.tItems["settings"].DecayPeriod == "r" then
		self.wndMain:FindChild("Decay"):FindChild("Raidly"):SetCheck(true)
	end
	if self.tItems["settings"].Decay == 1 then
		self.wndMain:FindChild("Decay"):FindChild("Enable"):SetCheck(true)
	end
	
	self:DecayUpdateTimer()
	self:DecayUpdateHelp()
	self:DecayCheckConditions()
end

function DKP:DecayUpdateHelp()
	local tooltip = "Next Decay"
	
	if self.tItems["settings"].Decay == 1 and self.tItems["settings"].DecayStart ~= nil and self.tItems["settings"].DecayVal ~= nil then
		local diff = os.difftime(os.time() - self.tItems["settings"].DecayStart)
		diff = os.date("*t",diff)
		local daysLeft
		if self.tItems["settings"].DecayPeriod == "w" then
			if diff.day == 6 then
				tooltip = tooltip .. " in " .. tostring(24 - diff.hour) .. "Hours."
			else
				daysLeft = 7 - diff.day
				tooltip = tooltip .. " in " .. daysLeft .. "days."
			end
		elseif self.tItems["settings"].DecayPeriod == "m" then
			if diff.day == 29 then
				tooltip = tooltip .. " in " .. tostring(24 - diff.hour) .. "Hours"
			else
				daysLeft = 30 - diff.day
				tooltip = tooltip .. " in " .. daysLeft .. "days."
			end
		elseif self.tItems["settings"].DecayPeriod == "r" then
			tooltip = tooltip .. " on next closed Session" 
		end
	else
		tooltip = "Disabled"
	end
	
	
	self.wndMain:FindChild("Decay"):FindChild("Help"):SetTooltip(tooltip)
end

function DKP:DecayCheckConditions()
	if self.tItems["settings"].Decay == 1 and self.tItems["settings"].DecayVal ~= nil then
		self.wndMain:FindChild("Decay"):FindChild("Now"):Enable(true)
		self.wndMain:FindChild("Decay"):FindChild("Raidly"):Enable(true)
		self.wndMain:FindChild("Decay"):FindChild("Weekly"):Enable(true)
		self.wndMain:FindChild("Decay"):FindChild("Monthly"):Enable(true)
	else
		self.wndMain:FindChild("Decay"):FindChild("Now"):Enable(false)
		self.wndMain:FindChild("Decay"):FindChild("Raidly"):Enable(false)
		self.wndMain:FindChild("Decay"):FindChild("Weekly"):Enable(false)
		self.wndMain:FindChild("Decay"):FindChild("Monthly"):Enable(false)
	end
end

function DKP:DecayUpdateTimer()
	if self.tItems["settings"].Decay == 1 and self.tItems["settings"].DecayVal ~= nil  then
		if self.tItems["settings"].DecayStart == nil then
			self.tItems["settings"].DecayStart = os.time()
		end
			local diff = os.difftime(os.time() - self.tItems["settings"].DecayStart)
			diff = os.date("*t",diff)
			if self.tItems["settings"].DecayPeriod == "w" then
				if diff.day >= 6 and diff.day < 7 then
					self.DecayTimerVar = ApolloTimer.Create(60, true, "DecayTimer", self)
					Apollo.RegisterTimerHandler(60, "DecayTimer", self)
				elseif diff.day >= 7 then
					self:Decay()
					self.tItems["settings"].DecayStart = nil
					self:DecayUpdateTimer()
				end
			elseif self.tItems["settings"].DecayPeriod == "m" then
				if diff.day >= 29 and diff.day < 31 then
					self.DecayTimerVar  = ApolloTimer.Create(60, true, "DecayTimer", self)
					Apollo.RegisterTimerHandler(60, "DecayTimer", self)
				elseif diff.day >= 30 then
					self:Decay()
					self.tItems["settings"].DecayStart = nil
					self:DecayUpdateTimer()
				end
			end
	else
		if self.DecayTimerVar ~= nil then
			self.DecayTimerVar:Stop() 
		end
	end
	self:DecayUpdateHelp()
end

function DKP:DecaySetTreshold( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["settings"].DecayTreshold = math.abs(tonumber(strText))
	else
		wndControl:SetText(self.tItems["settings"].DecayTreshold)
	end
end

function DKP:DecayTimer()

	local diff = os.difftime(os.time() - self.tItems["settings"].DecayStart)
		diff = os.date("*t",diff)
	if self.tItems["settings"].DecayPeriod == "w" then
		if diff.day >= 7 then
			self:Decay()
			self.tItems["settings"].DecayStart = nil
			self:DecayUpdateTimer()
			self.DecayTimerVar:Stop()
		end
	elseif self.tItems["settings"].DecayPeriod == "m" then
		if diff.day >= 30 then
			self:Decay()
			self.tItems["settings"].DecayStart = nil
			self:DecayUpdateTimer()
			self.DecayTimerVar:Stop()
		end	
	end
end

function DKP:DecayShow( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("Decay"):Show(true,false)
	
	self.wndMain:FindChild("EPGPDecayShow"):SetCheck(false)
	self.wndMain:FindChild("EPGPDecay"):Show(false)
end

function DKP:DecayHide( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("Decay"):Show(false,false)
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
	
	--GroupByClass
	self.wndMain:FindChild("Controls"):FindChild("GroupByClass"):SetCheck(self.tItems["settings"].GroupByClass)
	-- PopUp reduction
	self.wndSettings:FindChild("PopUPGPRed"):FindChild("EditBox"):SetText(self.tItems["settings"].nPopUpGPRed)
	-- Undo
	self.wndSettings:FindChild("TrackUndo"):SetCheck(self.tItems["settings"].bTrackUndo)
	
	--Networking
	self.wndSettings:FindChild("ButtonSettingsEnableNetworking"):SetCheck(self.tItems["settings"].networking)
	self.wndSettings:FindChild("ButtonSettingsEquip"):SetCheck(self.tItems["settings"].FilterEquippable)
	
	--Slider
	self.wndSettings:FindChild("Precision"):SetValue(self.tItems["settings"].Precision)
	self.wndSettings:FindChild("PrecisionEPGP"):SetValue(self.tItems["settings"].PrecisionEPGP)
	
	--Affiliation
	if self.tItems["settings"].CheckAffiliation == 1 then self.wndSettings:FindChild("ButtonSettingsNameplatreAffiliation"):SetCheck(true) end

	if self.tItems["settings"].bTrackUndo then self.wndSettings:FindChild("TrackUndo"):SetCheck(true) end
	
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
	self.wndSettings:FindChild("MinLvl"):SetText(self.tItems["settings"].nMinIlvl)
	if self.tItems["settings"].strLootFiltering ~= "Nil" then self.wndSettings:FindChild(self.tItems["settings"].strLootFiltering):SetCheck(true) end
	self.wndSettings:FindChild("SlashCommands"):SetTooltip(" /dkp - For main DKP window \n" ..
									 " /rops - For RaidOps Hub window \n" ..
									 " /ropsml - For Master Looter Settings window \n" ..
									 " /nb - For Network Bidding window \n" ..
									 " /chatbid - For Chat Bidding window \n" ..
									 " Old modules - waiting for rewrite \n" ..
									 " /sum - For Raid Summaries \n" ..
									 " /att - For Attendance \n")
									 
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

function DKP:SettingsEnableNetworking()
	self.tItems["settings"].networking = 1
	self:BidJoinChannel()
end

function DKP:SettingsDisableNetworking()
	self.tItems["settings"].networking = 0
	self.channel = nil
end

function DKP:SettingGroupByClassOn()
	self.tItems["settings"].GroupByClass = true
	self:RefreshMainItemList()
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
	end
end

function DKP:SettingsSetPrecisionEPGP( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].PrecisionEPGP then
		self.tItems["settings"].PrecisionEPGP = math.floor(fNewValue)
		self:ShowAll()
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

function DKP:ExportExport( wndHandler, wndControl, eMouseButton )
	if not self.wndExport:FindChild("List"):IsChecked() then
		if self.wndExport:FindChild("EPGP"):IsChecked() then
			if self.wndExport:FindChild("ButtonExportCSV"):IsChecked() then
				self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsCSVEPGP())
			elseif  self.wndExport:FindChild("ButtonExportHTML"):IsChecked() then
				self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsHTMLEPGP())
			elseif  self.wndExport:FindChild("ButtonExportFromattedHTML"):IsChecked() then
				self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsFormattedHTMLEPGP())
			end
		elseif self.wndExport:FindChild("DKP"):IsChecked() then
			if self.wndExport:FindChild("ButtonExportCSV"):IsChecked() then
				self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsCSVDKP())
			elseif  self.wndExport:FindChild("ButtonExportHTML"):IsChecked() then
				self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsHTMLDKP())
			elseif  self.wndExport:FindChild("ButtonExportFromattedHTML"):IsChecked() then
				self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsFormattedHTMLDKP())
			end
		end
	else
		if self.wndExport:FindChild("ButtonExportCSV"):IsChecked() then
			self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsCSVList())
		elseif  self.wndExport:FindChild("ButtonExportHTML"):IsChecked() then
			self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsHTMLList())
		elseif  self.wndExport:FindChild("ButtonExportFromattedHTML"):IsChecked() then
			self.wndExport:FindChild("ExportBox"):SetText(self:ExportAsFormattedHTMLList())
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
			tPlayer.EP = player.EP
			tPlayer.GP = player.GP
			tPlayer.class = player.class
			tPlayer.alts = player.alts
			tPlayer.role = player.role
			tPlayer.offrole = player.offrole
			tPlayer.tLLogs = player.tLLogs
			table.insert(exportTables.tPlayers,tPlayer)
		end
		exportTables.tSettings = self.tItems["settings"]
		exportTables.tEPGP = self.tItems["EPGP"]
		exportTables.tStandby = self.tItems["Standby"]
		exportTables.tCE = self.tItems["CE"]
		


		self.wndExport:FindChild("ExportBox"):SetText(Base64.Encode(serpent.dump(exportTables)))
	elseif self.wndExport:FindChild("ButtonImport"):IsChecked() then
		local tImportedTables = serpent.load(Base64.Decode(self.wndExport:FindChild("ExportBox"):GetText()))
			if tImportedTables and tImportedTables.tPlayers and tImportedTables.tSettings and tImportedTables.tStandby and tImportedTables.tCE then
			for k,player in ipairs(self.tItems) do
				self.tItems[k] = nil
			end
			for k,player in ipairs(tImportedTables.tPlayers) do
				table.insert(self.tItems,player)
			end
			for k,player in ipairs(self.tItems) do
				self.tItems[k].logs = {}
			end
			self.tItems["settings"] = tImportedTables.tSettings
			self.tItems["EPGP"] = tImportedTables.tEPGP
			self.tItems["Standby"] = tImportedTables.tStandby
			self.tItems["CE"] = tImportedTables.tCE
			
			ChatSystemLib.Command("/reloadui")
		else
			Print("Error processing database")
		end
	end
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
	for k=1,5 do
		if self.tItems["settings"].LabelOptions[k] then
			strCSV = strCSV .. self.tItems["settings"].LabelOptions[k] .. ";"
		end
	end
	strCSV = strCSV .. "\n"
	for k,child in ipairs(self.wndItemList:GetChildren()) do
		for j=1,5 do
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
	for k,child in ipairs(self.wndItemList:GetChildren()) do
		for j=1,5 do
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
	for k,child in ipairs(self.wndItemList:GetChildren()) do
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
local CurrentPopUpID = nil
local PopUpItemQueue = {} 

function DKP:PopUpAccept( wndHandler, wndControl, eMouseButton )
	if self.wndPopUp:FindChild("EditBoxDKP"):GetText() == "X" or self.wndPopUp:FindChild("EditBoxDKP"):GetText() == "" then return end
	local newDKP
	local modifier
	if self.tItems["EPGP"].Enable == 0 then
		modifier = tonumber(self.tItems[CurrentPopUpID].net)
		newDKP = tostring(tonumber(self.tItems[CurrentPopUpID].net)-math.abs(tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())))
		if self.tItems[CurrentPopUpID].listed == 1 and self:LabelGetColumnNumberForValue("Net") ~= -1 then
			self.tItems[CurrentPopUpID].wnd:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(newDKP)
		end
		modifier = tostring(tonumber(newDKP) - modifier)
		self.tItems[CurrentPopUpID].net = newDKP
		self:DetailAddLog(self.wndPopUp:FindChild("LabelItem"):GetText(),"{DKP}",modifier,CurrentPopUpID)
	else
		self:EPGPAdd(self.tItems[CurrentPopUpID].strName,nil,tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText()))
		if self:LabelGetColumnNumberForValue("GP") ~= -1 and self.tItems[CurrentPopUpID].wnd ~= nil then
			self.tItems[CurrentPopUpID].wnd:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(self.tItems[CurrentPopUpID].GP)
		end
		if self:LabelGetColumnNumberForValue("PR") ~= -1 then
			if self.tItems[CurrentPopUpID].GP ~= 0 then 
				self.tItems[CurrentPopUpID].wnd:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f",self.tItems[CurrentPopUpID].EP/self.tItems[CurrentPopUpID].GP))
			else
				self.tItems[CurrentPopUpID].wnd:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText("0")
			end
		end	
		self:DetailAddLog(self.wndPopUp:FindChild("LabelItem"):GetText(),"{GP}",tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText()),CurrentPopUpID)
	end
	if self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == false and self.tItems["EPGP"].Enable == 0 then
		self:RaidAddCostInfo(PopUpItemQueue[1].strItem,PopUpItemQueue[1].strName,tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())*-1)
	elseif self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == true then 
		self:RaidProccesNewPieceOfLoot(PopUpItemQueue[1].strItem,PopUpItemQueue[1].strName)
		if self.tItems["EPGP"].Enable == 0 then self:RaidAddCostInfo(PopUpItemQueue[1].strItem,PopUpItemQueue[1].strName,tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())*-1) end
	end
	self:RefreshMainItemList()
	self:PopUpWindowClose()
	self:PopUpUpdateQueueLength()
end

function DKP:PopUpAwardGuildBank()
	if self:GetPlayerByIDByName("Guild Bank") ~= -1 then self:DetailAddLog(PopUpItemQueue[1].strItem,"{Com}","-",self:GetPlayerByIDByName("Guild Bank")) end
	self:PopUpWindowClose()
	self:PopUpUpdateQueueLength()
end

function DKP:PopUpCheckDKPSpelling( wndHandler, wndControl, strText )
	if strText == "" then
		wndControl:SetText("X")
	end
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
				value = string.sub(self:EPGPGetItemCostByID(PopUpItemQueue[1].itemID),36)
			end
		end
	end
	if value then self.wndPopUp:FindChild("EditBoxDKP"):SetText(value) end
end

function DKP:PopUpWindowClose( wndHandler, wndControl )
	if PopUpItemQueue ~= nil and #PopUpItemQueue <= 1 then
		ID_popup = nil
		self.wndPopUp:Show(false,false)
		self.wndPopUp:FindChild("EditBoxDKP"):SetText("X")
		CurrentPopUpID = nil
		PopUpItemQueue = {}
	else
		ID_popup = PopUpItemQueue[1].ID
		self.wndPopUp:FindChild("EditBoxDKP"):SetText("X")
		self.wndPopUp:FindChild("LabelName"):SetText(PopUpItemQueue[1].strName)
		self.wndPopUp:FindChild("LabelItem"):SetText(PopUpItemQueue[1].strItem)
		self.wndPopUp:FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(Item.GetDataFromId(PopUpItemQueue[1].itemID):GetItemQuality()))
		self.wndPopUp:FindChild("ItemIcon"):SetSprite(Item.GetDataFromId(PopUpItemQueue[1].itemID):GetIcon())
		Tooltip.GetItemTooltipForm(self, self.wndPopUp:FindChild("ItemIcon") , Item.GetDataFromId(PopUpItemQueue[1].itemID), {bPrimary = true, bSelling = false})
		if self.tItems["EPGP"].Enable == 1 then
			self.wndPopUp:FindChild("LabelCurrency"):SetText("GP.")
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(string.sub(self:EPGPGetItemCostByID(PopUpItemQueue[1].itemID),36))
			self.wndPopUp:FindChild("GPOffspec"):Show(true)
			self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
		else
			self.wndPopUp:FindChild("LabelCurrency"):SetText("DKP.")
			self.wndPopUp:FindChild("GPOffspec"):Show(false)
			self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
		end
		CurrentPopUpID = PopUpItemQueue[1].ID
		if self.RegistredBidWinners[string.sub(PopUpItemQueue[1].strItem,2)] ~= nil then
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(self.RegistredBidWinners[string.sub(PopUpItemQueue[1].strItem,2)].cost)
		end
		table.remove(PopUpItemQueue,1)
	end
	self:PopUpUpdateQueueLength()
end

function DKP:PopUpWindowOpen(strNameOrig,strItem)
	if self.tItems["settings"].PopupEnable == 0 then return end
	
	local strName = ""
	
	for uchar in string.gfind(strNameOrig, "([%z\1-\127\194-\244][\128-\191]*)") do
		if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
		strName = strName .. uchar
	end
	
	if self.tItems["settings"].bPopUpRandomSkip and self.strRandomWinner and strName == self.strRandomWinner then return end
	
	if self:GetPlayerByIDByName("Guild Bank") ~= -1 and strName == "Guild Bank" and self.tItems["settings"].bSkipGB then 
		self:DetailAddLog(strItem,"{Com}","-",self:GetPlayerByIDByName("Guild Bank")) 
		return
	end
	local ID_popup = nil
	for i=1, table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(strName) then
			ID_popup = i
			break
		end
	end
	if ID_popup == nil or not self.ItemDatabase[strItem] then 
		Print ("Error processing PopUp window")
		return
	else
		local item = {}
		item.strName = strName
		item.strItem = strItem
		item.ID = ID_popup
		if self.ItemDatabase[string.sub(strItem,2)] then
			item.itemID = self.ItemDatabase[string.sub(strItem,2)].ID
		else
			item.itemID = self.ItemDatabase[strItem].ID
		end
		table.insert(PopUpItemQueue,1,item)
		if CurrentPopUpID == nil then --First Iteration
			self.wndPopUp:FindChild("LabelName"):SetText(strName)
			self.wndPopUp:FindChild("LabelItem"):SetText(strItem)
			self.wndPopUp:FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(Item.GetDataFromId(PopUpItemQueue[1].itemID):GetItemQuality()))
			self.wndPopUp:FindChild("ItemIcon"):SetSprite(Item.GetDataFromId(PopUpItemQueue[1].itemID):GetIcon())
			Tooltip.GetItemTooltipForm(self, self.wndPopUp:FindChild("ItemIcon") , Item.GetDataFromId(PopUpItemQueue[1].itemID), {bPrimary = true, bSelling = false})
			if self.tItems["EPGP"].Enable == 1 then
				self.wndPopUp:FindChild("LabelCurrency"):SetText("GP.")
				self.wndPopUp:FindChild("EditBoxDKP"):SetText(string.sub(self:EPGPGetItemCostByID(PopUpItemQueue[1].itemID),36))
				self.wndPopUp:FindChild("GPOffspec"):Show(true)
				self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
			else
				self.wndPopUp:FindChild("LabelCurrency"):SetText("DKP.")
				self.wndPopUp:FindChild("GPOffspec"):Show(false)
				self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
			end
			CurrentPopUpID = ID_popup
		end
		if self.RegistredBidWinners[string.sub(strItem,2)] ~= nil and self.tItems["EPGP"].Enable == 0 then
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(self.RegistredBidWinners[string.sub(strItem,2)].cost)
		end
		self.wndPopUp:Show(true,false)
		if #PopUpItemQueue > 1 then self.wndPopUp:FindChild("ButtonSkip"):Enable(true) else self.wndPopUp:FindChild("ButtonSkip"):Enable(false) end
		self:PopUpUpdateQueueLength()
	end
end


function DKP:PopUpForceClose( wndHandler, wndControl, eMouseButton )
	ID_popup = nil
	self.wndPopUp:Show(false,false)
	self.wndPopUp:FindChild("EditBoxDKP"):SetText("X")
	PopUpItemQueue = {}
	CurrentPopUpID = nil
end

function DKP:PopUpSkip( wndHandler, wndControl, eMouseButton )
		ID_popup = PopUpItemQueue[1].ID
		self.wndPopUp:FindChild("LabelName"):SetText(PopUpItemQueue[1].strName)
		self.wndPopUp:FindChild("LabelItem"):SetText(PopUpItemQueue[1].strItem)
		if self.tItems["EPGP"].Enable == 1 then
			self.wndPopUp:FindChild("LabelCurrency"):SetText("GP.")
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(string.sub(self:EPGPGetItemCostByID(PopUpItemQueue[1].itemID),36))
			self.wndPopUp:FindChild("GPOffspec"):Show(true)
			self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
		else
			self.wndPopUp:FindChild("LabelCurrency"):SetText("DKP.")
			self.wndPopUp:FindChild("GPOffspec"):Show(false)
			self.wndPopUp:FindChild("GPOffspec"):SetCheck(false)
		end
		self.wndPopUp:FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(Item.GetDataFromId(PopUpItemQueue[1].itemID):GetItemQuality()))
		self.wndPopUp:FindChild("ItemIcon"):SetSprite(Item.GetDataFromId(PopUpItemQueue[1].itemID):GetIcon())
		Tooltip.GetItemTooltipForm(self, self.wndPopUp:FindChild("ItemIcon") , Item.GetDataFromId(PopUpItemQueue[1].itemID), {bPrimary = true, bSelling = false})
		CurrentPopUpID = PopUpItemQueue[1].ID
		table.remove(PopUpItemQueue,1)
		if #PopUpItemQueue <= 1  then wndControl:Enable(false) end
	    self:PopUpUpdateQueueLength()
end

function DKP:PopUpUpdateQueueLength()
		if PopUpItemQueue ~= nil then self.wndPopUp:FindChild("QueueLength"):SetText(tostring(#PopUpItemQueue-1)) end
end

---------------------------------------------------------------------------------------------------
-- StandbyList Functions
---------------------------------------------------------------------------------------------------
local selectedStandby = {}

function DKP:StandbyListAdd( wndHandler, wndControl, strText )
	if self:GetPlayerByIDByName(strText) ~= -1 then
		self.tItems["Standby"][string.lower(strText)] = {}
		self.tItems["Standby"][string.lower(strText)].strName = strText
		local currDate = os.date("*t",os.time())
		self.tItems["Standby"][string.lower(strText)].strDate = tostring(currDate.day .. "/" .. currDate.month .. "/" .. currDate.year)
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
	
	self.wndDS:FindChild("Channel"):SetText(self.tItems["settings"]["Bid2"].strChannel)
	
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
			Print()
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

function DKP:ConLootLogs()
	self:LLOpen({[1] = self.wndContext:GetData()})
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
	self:StandbyListRemove(nil,nil,nil,self.tItems[self.wndContext:GetData()].strName)
	self:UndoAddActivity(ktUndoActions["remp"],"--",{[1] = self.tItems[self.wndContext:GetData()]},true)
	for k,alt in ipairs(self.tItems[self.wndContext:GetData()].alts) do self.tItems["alts"][string.lower(alt)] = nil end
	table.remove(self.tItems,self.wndContext:GetData())
	self.wndContext:Close()
	self.wndSelectedListItem = nil
	wndControl:Show(false,false)
	self:RefreshMainItemList()
	self:RaidQueueClear()
end

function DKP:ConRemoveContextIndicator()
	if self:LabelGetColumnNumberForValue("Name")  > 0 and self.tItems[self.wndContext:GetData()] then
		local name = self.tItems[self.wndContext:GetData()].strName
		local label = "Stat"..self:LabelGetColumnNumberForValue("Name")
		for k,child in ipairs(self.wndItemList:GetChildren()) do
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
	
	self.tItems[self.wndAlts:GetData()].net =  self.tItems[self.wndAlts:GetData()].net + mergedPlayer.net
	self.tItems[self.wndAlts:GetData()].tot =  self.tItems[self.wndAlts:GetData()].tot + mergedPlayer.tot
	self.tItems[self.wndAlts:GetData()].EP =  self.tItems[self.wndAlts:GetData()].EP + mergedPlayer.EP
	self.tItems[self.wndAlts:GetData()].GP =  self.tItems[self.wndAlts:GetData()].GP + mergedPlayer.GP
	self.tItems[self.wndAlts:GetData()].Hrs =  self.tItems[self.wndAlts:GetData()].Hrs + mergedPlayer.Hrs
	
	local recipent = self.tItems[self.wndAlts:GetData()].strName
	
	table.remove(self.tItems,self:GetPlayerByIDByName(self.wndAlts:FindChild("NewAltBox"):GetText()))
	
	for k,player in ipairs(self.tItems) do if player.strName == recipent then self.wndAlts:SetData(k) end end
	
	table.insert(self.tItems[self.wndAlts:GetData()].alts,self.wndAlts:FindChild("NewAltBox"):GetText())
	
	self.tItems["alts"][string.lower(self.wndAlts:FindChild("NewAltBox"):GetText())] = self.wndAlts:GetData()
	self.wndAlts:FindChild("NewAltBox"):SetText("")
	
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

function DKP:AltsDictionaryHide()
	self.wndAltsDict:Show(false,false)
end

function DKP:AltsAddConvert()
	local recipent = self.tItems[self.wndAlts:GetData()].strName
	
	table.remove(self.tItems,self:GetPlayerByIDByName(self.wndAlts:FindChild("NewAltBox"):GetText()))
	
	for k,player in ipairs(self.tItems) do if player.strName == recipent then self.wndAlts:SetData(k) end end
	
	table.insert(self.tItems[self.wndAlts:GetData()].alts,self.wndAlts:FindChild("NewAltBox"):GetText())
	
	self.tItems["alts"][string.lower(self.wndAlts:FindChild("NewAltBox"):GetText())] = self.wndAlts:GetData()
	self.wndAlts:FindChild("NewAltBox"):SetText("")
	
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
	self.wndLogs:SetSizingMinimum(648,329)
	self.wndLogs:SetSizingMaximum(648,550)
end

function DKP:LogsExport()
	strExport = ""
	for k,entry in ipairs(self.tItems[self.wndLogs:GetData()].logs) do
		strExport = strExport .. entry.strComment .. ";" .. entry.strType .. ";" .. entry.strModifier .. ";" .. entry.strTimestamp .. "\n"
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
		grid:SetCellData(k,3,entry.strType)
		grid:SetCellData(k,2,entry.strModifier)
		grid:SetCellData(k,4,entry.strTimestamp)
	end
end

function DKP:DetailAddLog(strCommentPre,strType,strModifier,ID)
	if self.tItems["settings"].logs == 1 then
		local strComment = ""
		for uchar in string.gfind(strCommentPre, "([%z\1-\127\194-\244][\128-\191]*)") do
			if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
			strComment = strComment .. uchar
		end
	
		table.insert(self.tItems[ID].logs,1,{strComment = strComment,strType = strType, strModifier = strModifier,strTimestamp = os.date("%x",os.time()) .. "  " .. os.date("%X",os.time())})
		if self.wndLogs:GetData() == ID then self:LogsPopulate() end
		if #self.tItems[ID].logs > 20 then table.remove(self.tItems[ID].logs,20) end
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
		if self.tItems[player].strName == strPlayer then return true end
	end
	return false
end

function DKP:RaidQueueClear()
	self.tItems.tQueuedPlayers = {}
	for k,child in ipairs(self.wndItemList:GetChildren()) do
		child:FindChild("Standby"):SetCheck(false)
	end
	if self.wndMain:FindChild("RaidOnly"):IsChecked() then self:RefreshMainItemList() end
	self:RaidQueueShow()
end

function DKP:RaidQueueShow()
	for k,child in ipairs(self.wndItemList:GetChildren()) do
		if self.wndMain:FindChild("RaidQueue"):IsChecked() then child:FindChild("Standby"):Show(true,false) else child:FindChild("Standby"):Show(false,false) end
		if self:IsPlayerInQueue(nil,child:GetData()) then 
			child:FindChild("Standby"):Show(true,false)
			child:FindChild("Standby"):SetCheck(true) 
		end
	end
	self:RaidQueueShowClearButton()
end

function DKP:RaidQueueHide()
	for k,child in ipairs(self.wndItemList:GetChildren()) do
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
	
	self.wndCE:SetSizingMaximum(692,700)
	self.wndCE:SetSizingMinimum(692,414)
	
	self.wndCEL = Apollo.LoadForm(self.xmlDoc,"HandledEventsList",nil,self)
	self.wndCEL:Show(false,true)
	self.wndCE:Show(false,true)
	self.wndCE:FindChild("IfBoss"):Show(false,true)
	self.wndCE:FindChild("IfUnit"):Show(false,true)
	
	if self.tItems["settings"].CEEnable == nil then self.tItems["settings"].CEEnable = false end
	if self.tItems["settings"].CERaidOnly == nil then self.tItems["settings"].CERaidOnly = false end
	if self.tItems["settings"].CENotify == nil then self.tItems["settings"].CENotify = false end
	
	self.wndCE:FindChild("Enable"):SetCheck(self.tItems["settings"].CEEnable)
	self.wndCE:FindChild("RaidOnly"):SetCheck(self.tItems["settings"].CERaidOnly)
	self.wndCE:FindChild("Notify"):SetCheck(self.tItems["settings"].CENotify)
	
	if self.tItems["settings"].CEEnable then Apollo.RegisterEventHandler("CombatLogDamage","CEOnUnitDamage", self) end
	
	
	if self.tItems["CE"] == nil then self.tItems["CE"] = {} end
end

function DKP:CENotifyEnable()
	self.tItems["settings"].CENotify = true
end

function DKP:CENotifyDisable()
	self.tItems["settings"].CENotify = false
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

function DKP:CEHide()
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
	self.wndCE:FindChild("RecipentTypeSelection"):SetAnchorOffsets(138,118,346,232)
	self.wndCE:FindChild("RecipentTypeSelection"):SetText("")
	self.wndCE:FindChild("RecipentTypeSelection"):ToFront()
end

function DKP:CECollapseRecipents()
	self.wndCE:FindChild("RecipentTypeSelection"):SetAnchorOffsets(138,118,346,145)
	self.wndCE:FindChild("RecipentTypeSelection"):SetText(tCreatedEvent.rType == "RM" and "Raid Members" or "Raid Members + Queue")
end

function DKP:CEExpandUnits()
	self.wndCE:FindChild("UnitTypeSelection"):SetAnchorOffsets(119,71,244,167)
	self.wndCE:FindChild("UnitTypeSelection"):SetText("")
	self.wndCE:FindChild("UnitTypeSelection"):ToFront()
end

function DKP:CECollapseUnits()
	self.wndCE:FindChild("UnitTypeSelection"):SetAnchorOffsets(119,71,244,97)
	self.wndCE:FindChild("UnitTypeSelection"):SetText(tCreatedEvent.uType)
end

function DKP:CEExpandBosses()
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetAnchorOffsets(68,7,288,131)
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetText("")
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):ToFront()
end

function DKP:CECollapseBosses()
	self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetAnchorOffsets(69,7,288,29)
	if tCreatedEvent.bType then self.wndCE:FindChild("IfBoss"):FindChild("BossItemSelection"):SetText(tCreatedEvent.bType) end
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
		if self.tItems["settings"].CENotify then
			local strAwards = ""
			if event.EP then
				strAwards = strAwards .. event.EP .. "EP  ,"
			end			
			if event.GP then
				strAwards = strAwards .. event.GP .. "GP  ,"
			end			
			if event.DKP then
				strAwards = strAwards .. event.DKP .. "DKP"
			end
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
		table.insert(self.tItems["settings"].tCETriggeredEvents,1,{strEv = "(ID : ".. eID ..") (" .. strMob .. ")",strDate = os.date("%x",os.time()) .. " " .. os.date("%X",os.time())})
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
	if  tArgs.bTargetKilled== false then return end
	if tArgs.unitTarget == nil then return end
	local tUnits = {}
	local tBosses = {}
	
	for k,event in ipairs(self.tItems["CE"]) do 
		if event.uType == "Unit" then table.insert(tUnits,{strUnit = event.strUnit,ID = k}) else table.insert(tBosses,{bType = event.bType,ID = k}) end
	end

	local name =tArgs.unitTarget:GetName()
	
	
	-- Counting Council Fights
	if name == "Phagetech Commander" then tKilledBossesInSession.tech1 = true end
	if name == "Phagetech Augmentor" then tKilledBossesInSession.tech2 = true end
	if name == "Phagetech Protector" then tKilledBossesInSession.tech3 = true end
	if name == "Phagetech Fabricator" then tKilledBossesInSession.tech4 = true end
	
	if name == "Ersoth Curseform" then tKilledBossesInSession.born1 = true end
	if name == "Fleshmonger Vratorg" then tKilledBossesInSession.born2 = true end
	if name == "Terax Blightweaver" then tKilledBossesInSession.born3 = true end
	if name == "Goldox Lifecrusher" then tKilledBossesInSession.born4 = true  end
	if name == "Noxmind the Insidious" then tKilledBossesInSession.born5 =true end
		
	
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
	if self.tItems["settings"].LL.strGroup == "GroupName" then self.tItems["settings"].LL.strGroup = "GroupCategory" end
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
	
	self.wndLLM:FindChild("Only"):FindChild("Equip"):SetCheck(self.tItems["settings"].LL.bEquippable)
	self.wndLLM:FindChild("Only"):FindChild("MinLvl"):SetText(self.tItems["settings"].LL.nLevel)
	
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
	
	self.wndLLM:FindChild("SlotsTab"):AttachTab(self.wndLLM:FindChild("ClassesTab"),false)
	self.wndLLM:FindChild("SlotsTab"):AttachTab(self.wndLLM:FindChild("QualityTab"),false)
	self.wndLLM:FindChild("SlotsTab"):Lock(true)
	self.wndLLM:FindChild("ClassesTab"):Lock(true)
	self.wndLLM:FindChild("QualityTab"):Lock(true)
	self.wndLLM:FindChild("MaxItems"):SetValue(self.tItems["settings"].LL.nMaxItems)
	self.wndLLM:FindChild("MaxRows"):SetValue(self.tItems["settings"].LL.nMaxRows)
	self.wndLL:SetSizingMinimum(768,493)
end

function DKP:LLSetMinLevel(wndHandler,wndControl,strText)
	local value = tonumber(strText)
	if value and value > 0 then
		self.tItems["settings"].LL.nLevel = value
	else
		wndControl:SetText(self.tItems["settings"].LL.nLevel)
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



function DKP:LLAddLog(strPlayer,strItem)
	if not self.tItems["settings"].bLootLogs then return end
	local ID = self:GetPlayerByIDByName(strPlayer)
	if ID ~= -1 and self.ItemDatabase[strItem] then
		local item = self.ItemDatabase[strItem].ID
		if item then
			if self.tItems[ID].tLLogs == nil then self.tItems[ID].tLLogs = {} end
			table.insert(self.tItems[ID].tLLogs,1,{itemID = self.ItemDatabase[strItem].ID,nDate = os.time()})
			if #self.tItems[ID].tLLogs > 50 then table.remove(self.tItems[ID].tLLogs,51) end

		end
	end
	if self.wndLL:IsShown() then self:LLPopuplate() end
end

function DKP:LLOpen(tIDs)
	for k , ID in ipairs(tIDs) do
		if not self.tItems[ID] then table.remove(tIDs) end
	end
	
	self.wndLL:SetData(tIDs)
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
	end
	self.wndLL:FindChild("Controls"):FindChild(self.tItems["settings"].LL.strGroup):SetCheck(true)
	self:LLPopuplate()
end

function DKP:LLOpenWhole()
	self.wndLL:Show(true,false)
	self.wndLL:SetData("AllMode")
	self.wndLL:FindChild("Controls"):FindChild("Player"):SetText("Whole Roster")
	self.wndLL:FindChild("Controls"):FindChild("GroupName"):Show(true)
	self:LLPopuplate()
end

function DKP:LLClose()
	self.wndLL:Show(false,false)
end

function DKP:LLPrepareData()
	local tGrouppedItems = {}
	local tWinnersDictionary = {}
	if self.wndLL:GetData() ~= "AllMode" then
		for k , ID in ipairs(self.wndLL:GetData()) do 
			if self.tItems[ID].tLLogs ~= nil then
				tWinnersDictionary[self.tItems[ID].strName] = {}
				for k , entry in ipairs(self.tItems[ID].tLLogs) do
					if self.tItems["settings"].LL.strGroup == "GroupName" then
						tGrouppedItems[self.tItems[ID].strName] = {}
						for j , entry in ipairs(self.tItems[ID].tLLogs) do
							if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),self.tItems[ID]) then
								table.insert(tGrouppedItems[self.tItems[ID].strName],entry.itemID)
								table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = self.tItems[ID].strName})
							end
						end
						if #tGrouppedItems[self.tItems[ID].strName] == 0 then tGrouppedItems[self.tItems[ID].strName] = nil end	
					elseif self.tItems["settings"].LL.strGroup == "GroupCategory" then
						local item = Item.GetDataFromId(entry.itemID)
						if item and self:LLMeetsFilters(item,self.tItems[ID]) then
							if tGrouppedItems[item:GetItemCategoryName()] == nil then tGrouppedItems[item:GetItemCategoryName()] = {} end
							table.insert(tGrouppedItems[item:GetItemCategoryName()],entry.itemID)			
						end
					else -- Group Date
						local strDate = os.date("%x",entry.nDate)
						if tGrouppedItems[strDate] == nil then tGrouppedItems[strDate] = {} end
						if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),self.tItems[ID]) then
							table.insert(tGrouppedItems[strDate],entry.itemID)	
						end
					end
				end
			end
		end
	else
		for k , player in ipairs(self.tItems) do
			if player.tLLogs then
				tWinnersDictionary[player.strName] = {}
				if self.tItems["settings"].LL.strGroup == "GroupName" then
					tGrouppedItems[player.strName] = {}
					for j , entry in ipairs(player.tLLogs) do
						if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),player) then
							table.insert(tGrouppedItems[player.strName],entry.itemID)
							table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName})
						end
					end
					if #tGrouppedItems[player.strName] == 0 then tGrouppedItems[player.strName] = nil end
				elseif self.tItems["settings"].LL.strGroup == "GroupCategory" then
					for j , entry in ipairs(player.tLLogs) do
						local item = Item.GetDataFromId(entry.itemID)
						if item and self:LLMeetsFilters(item,player) then
							if tGrouppedItems[item:GetItemCategoryName()] == nil then tGrouppedItems[item:GetItemCategoryName()] = {} end
							table.insert(tGrouppedItems[item:GetItemCategoryName()],entry.itemID)
							table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName})						
						end
					end
				else
					for j , entry in ipairs(player.tLLogs) do
						local strDate = os.date("%x",entry.nDate)
						if tGrouppedItems[strDate] == nil then tGrouppedItems[strDate] = {} end
						if self:LLMeetsFilters(Item.GetDataFromId(entry.itemID),player) then
							table.insert(tGrouppedItems[strDate],entry.itemID)
							table.insert(tWinnersDictionary,{ID = entry.itemID,strInfo = player.strName})						
						end
					end
				end
			end
		end
	
	end
	if #self.wndLL:GetData() == 1 then tWinnersDictionary = nil end
	return tGrouppedItems , tWinnersDictionary
end

function DKP:LLMeetsFilters(item,player)
	if not item or not player then return false end
	-- Booleans setup
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
	if self.tItems["settings"].LL.bEquippable and not item:IsEquippable() then return false end
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
	--Classes
	if not bMeetClass then
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
end

function DKP:LLSetMaxItems( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].LL.nMaxItems then
		self.tItems["settings"].LL.nMaxItems = math.floor(fNewValue)
	end
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
function DKP:DFJoinSyncChannel( wndHandler, wndControl, eMouseButton )
	self.sChannel = ICCommLib.JoinChannel("RaidOpsSyncChannel","DFOnSyncMessage",self)
end

function DKP:DFOnSyncMessage(channel, tMsg, strSender)
	if tMsg.type then
		if tMsg.type == "SendMeData" then
			self.sChannel:SendPrivateMessage({[1] = strSender},self:GetEncodedData(strSender))
		elseif tMsg.type == "SendMeFullData" then
			tFetchers[strSender] = nil 
			self.sChannel:SendPrivateMessage({[1] = strSender},self:GetEncodedData(strSender))
		elseif tMsg.type == "EncodedDataFull" then
			self:ProccesEncodedData(tMsg.strData)		
			elseif tMsg.type == "EncodedDataSelected" then
			self:ProccesEncodedDataUpdate(tMsg.strData)
		elseif tMsg.type == "Data unavailable" then
			Print("Permission to data was denied , contact the person in charge")
		end
	end
end

function DKP:ProccesEncodedData(strData)
	local tData = serpent.load(Base64.Decode(strData))
	
	if tData then
		for k, player in ipairs(self.tItems) do
			table.remove(self.tItems,k)
		end
		self.tItems["alts"] = tData["alts"] or {}
		for k,player in ipairs(tData) do
			if self:GetPlayerByIDByName(player.strName) == -1 then
				table.insert(self.tItems,player)
			else
				self.tItems[self:GetPlayerByIDByName(player.strName)] = player
			end
		end
	end
	Print("Data received and proccessed , full sync")
	
	self:RefreshMainItemList()
end

function DKP:ProccesEncodedDataUpdate(strData)
	local tData = serpent.load(Base64.Decode(strData))
	
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
			end
			tData.strData = Base64.Encode(serpent.dump(tPlayers))
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
							local tLogs = {}
							for k=1 , #playerSource.logs - #playerSent.logs do
								table.insert(tLogs,playerSource.logs[k])
							end
							table.insert(tPlayers,playerSource)
							tPlayers[#tPlayers].logs = tLogs
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
			tData.strData = Base64.Encode(serpent.dump(tPlayers))
			tFetchers[strRequester] = serpent.load(serpent.dump(tPlayersSource))
		end
		self:DFAddLog(strRequester,true)
	end
	return tData
end

function DKP:DFAddLog(strPlayer,bSucces)
	table.insert(self.tItems["settings"].DF.tLogs,1,{strRequester = strPlayer,strState = bSucces and "{Yes}" or "{No}",strTimestamp = os.date("%x",os.time()) .. " " .. os.date("%X",os.time())})
	if #self.tItems["settings"].DF.tLogs > 20 then table.remove(self.tItems["settings"].DF.tLogs,21) end
	if self.wndDF:IsShown() then self:DFPopulate() end
end

function DKP:DFFetchDataTimed()
	local myUnit = GameLib.GetPlayerUnit()
	if self.tItems["settings"].DF.bFetchOOC and myUnit:IsInCombat() or self.tItems["settings"].DF.bFetchRaid and not GroupLib.InRaid() then return end
	if self.sChannel then self.sChannel:SendPrivateMessage({[1] = self.tItems["settings"].DF.strSource},{type = "SendMeData"}) end
end

function DKP:DFFetchData()
	if self.sChannel then self.sChannel:SendPrivateMessage({[1] = self.tItems["settings"].DF.strSource},{type = "SendMeData"}) end
end

function DKP:DFFetchFullData()
	if self.sChannel then self.sChannel:SendPrivateMessage({[1] = self.tItems["settings"].DF.strSource},{type = "SendMeFullData"}) end
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
-- DKP Instance
-----------------------------------------------------------------------------------------------
local DKPInst = DKP:new()
DKPInst:Init()