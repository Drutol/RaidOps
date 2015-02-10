-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------
 
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
local ktStringToIcon =
{
	["Medic"]       	= "Icon_Windows_UI_CRB_Medic",
	["Esper"]       	= "Icon_Windows_UI_CRB_Esper",
	["Warrior"]     	= "Icon_Windows_UI_CRB_Warrior",
	["Stalker"]     	= "Icon_Windows_UI_CRB_Stalker",
	["Engineer"]    	= "Icon_Windows_UI_CRB_Engineer",
	["Spellslinger"]  	= "Icon_Windows_UI_CRB_Spellslinger",
}
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
	self.SyncChannel = nil
	self.PrivateSyncChannel = nil
	server = nil
	client = nil
	detailedEntryID = 0
	self.detailItemList = nil
	self.tAlts = {}
	self.tLogs = {}
	purge_database = 0
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- DKP OnLoad
-----------------------------------------------------------------------------------------------
function DKP:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("DKP.xml")
	self.xmlDoc2 = XmlDoc.CreateFromFile("DKP2.xml")
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
		Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
		self.wndItemList = self.wndMain:FindChild("ItemList")
		self.wndMain:Show(false, true)
		self.wndSettings:Show(false , true)
		self.wndExport:Show(false , true)
		self.wndPopUp:Show(false, true)
		self.wndStandby:Show(false,true)
		self.wndMain:FindChild("MassEditControls"):Show(false,true)
		Apollo.RegisterSlashCommand("dkp", "OnDKPOn", self)
		Apollo.RegisterSlashCommand("sum", "RaidShowMainWindow", self)
		Apollo.RegisterSlashCommand("dkpbid", "BidOpen", self)
		Apollo.RegisterSlashCommand("rops", "HubShow", self)
		Apollo.RegisterSlashCommand("ropsml", "MLSettingShow", self)
		Apollo.RegisterTimerHandler(10, "OnTimer", self)
		Apollo.RegisterTimerHandler(10, "RaidUpdateCurrentRaidSession", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		
		--Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		--Apollo.RegisterEventHandler("LootedItem", "OnLootedItem", self)

		
		self.timer = ApolloTimer.Create(10, true, "OnTimer", self)


		local setButton = self.wndMain:FindChild("ButtonSet")
		local addButton = self.wndMain:FindChild("ButtonAdd")
		local subtractButton = self.wndMain:FindChild("ButtonSubtract")
		setButton:Enable(false)
		addButton:Enable(false)
		subtractButton:Enable(false)
		if self.tItems["alts"] == nil then self.tItems["alts"] = {} end
		if self.tItems["settings"] == nil then
			self.tItems["settings"] = {}
			self.tItems["settings"].whisp = 1
			self.tItems["settings"].logs =1
			self.tItems["settings"].guildname = nil
			self.tItems["settings"].dkp = 200 -- mass add
			self.tItems["settings"].default_dkp = 500
			self.tItems["settings"].collect_new = 1
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
			self.tItems["settings"].LabelOptions[2]= "Net"
			self.tItems["settings"].LabelOptions[3] = "Tot"
			self.tItems["settings"].LabelOptions[4] = "Nil"
			self.tItems["settings"].LabelOptions[5] = "Nil"
		end
		if self.tItems["settings"].LabelSortOrder == nil then self.tItems["settings"].LabelSortOrder = "asc" end
		if self.tItems["settings"].Precision == nil then self.tItems["settings"].Precision = 1 end
		if self.tItems["settings"].CheckAffiliation == nil then self.tItems["settings"].CheckAffiliation = 0 end
		if self.tItems["settings"].GroupByClass == nil then  self.tItems["settings"].GroupByClass = false end
		if self.tItems["settings"].FilterEquippable == nil then self.tItems["settings"].FilterEquippable = false end
		if self.tItems["settings"].FilterWords == nil then self.tItems["settings"].FilterWords = false end
		if self.tItems["settings"].networking == nil then self.tItems["settings"].networking = true end
		if self.tItems["Standby"] == nil then self.tItems["Standby"] = {} end

		self.wndLabelOptions = self.wndMain:FindChild("LabelOptions")
		self.wndTimeAward = self.wndMain:FindChild("TimeAward")
		self.wndLabelOptions:Show(false,true)
		self.wndTimeAward:Show(false,true)
		self.MassEdit = false
		self:TimeAwardRestore()
		self:EPGPInit()
		self:RaidOpsInit()
		self:ConInit()
		self:AltsInit()
		self:LogsInit()
		self:GIInit()
		self:CloseBigPOPUP()

		-- Alts cleanup onetime
		
		if self.tItems.newUpdateAltCleanup == nil then
			for k,player in ipairs(self.tItems) do
				player.alts = {}
				player.logs = {}
			end
			self.tItems["alts"] = {}
			self.tItems.newUpdateAltCleanup = "DONE"
		end
		
		
		-- Inits
		self.SortedLabel = nil
		self:LabelUpdateList() --<<<< With Show ALL
		self:UpdateItemCount()
		self:RaidInit()
		self:TradeInit()
		self.wndMain:FindChild("Decay"):Show(false)
		self:DecayRestore()
		self:ControlsUpdateQuickAddButtons()
		
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
		local lol = self:OnSave()
	end
end
local tGuildRoster
local uGuild
local tAcceptedRanks = {}
function DKP:CloseBigPOPUP()
	self.wndMain:FindChild("BIGPOPUP"):Show(false,true)
end

function DKP:GIInit()
	self.wndGuildImport = Apollo.LoadForm(self.xmlDoc,"GuildImport",nil,self)
	self.wndGuildImport:Show(false,true)
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
	for k,member in ipairs(tGuildRoster) do
		if self:GIIsGoodRank(member.nRank) and member.nLevel >= tonumber(self.wndGuildImport:FindChild("MinLevel"):GetText()) and self:GetPlayerByIDByName(member.strName) == -1 then 
			self:OnUnitCreated(member.strName,true,true)
			self:RegisterPlayerClass(self:GetPlayerByIDByName(member.strName),member.strClass)
		end
	end
	self:RefreshMainItemList()
	self:GIUpdateCount()
	
end

function DKP:GIUpdateCount()
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
	self:GIPopulateRanks()
	--[[for k,player in ipairs(tRoster) do
		if self:GetPlayerByIDByName(player.strName) == -1 then
			self:OnUnitCreated(player.strName,true,true)
			self:RegisterPlayerClass(self:GetPlayerByIDByName(player.strName),player.strClass)
		end
	end
	self:RefreshMainItemList()]]
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
	local existingID
	
	local isNew=true
	if self.tItems == nil then isNew = true end
	if table.maxn(self.tItems) > 0 then
		for il=1,table.maxn(self.tItems),1 do
			if self.tItems[il] ~= nil then
				if string.lower(self.tItems[il].strName) == string.lower(strName) then
					isNew=false
					existingID = il
				end
			end
		end
	end
	
	
	if isNew == false then
			local i = {}
			i = self.tItems[existingID]
			i.strName = self.tItems[existingID].strName
			if altName ~= nil then
				i.alt = altName
			end
			if self.tItems[existingID].tot == nil then self.tItems[existingID].tot = self.tItems[existingID].net end
			if self.tItems[existingID].listed == 1 then
				self:UpdateItem(i)
			end
			if self.tItems[existingID].listed == 0 then
				self.tItems[existingID].listed = 1
			end
	elseif isNew == true and self.tItems["settings"].CheckAffiliation == 0 or isNew == true and self.tItems["settings"].CheckAffiliation == 1 and isStr == nil or isNew == true and isStr and self.wndMain:FindChild("Controls"):FindChild("EditBoxPlayerName"):GetText() ~= "Input New Entry Name" then
		local newPlayer = {}
		newPlayer.strName = strName
		newPlayer.net = self.tItems["settings"].default_dkp
		newPlayer.tot = self.tItems["settings"].default_dkp
		newPlayer.Hrs = 0
		newPlayer.EP = self.tItems["EPGP"].MinEP
		newPlayer.GP = self.tItems["EPGP"].BaseGP
		newPlayer.alts = {}
		newPlayer.logs = {}
		if self.tItems["settings"].TradeEnable == 1 then
			newPlayer.TradeCap = self.tItems["settings"].TradeCap
		end
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

	if self.wndSelectedListItem ~=nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText()
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			local value = tonumber(self.wndMain:FindChild("Controls"):FindChild("EditBox1"):GetText())
			if self.tItems["EPGP"].Enable == 0 then	
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
				-- if cycling ~= true then
					-- self:ResetCommentBoxFull()
					-- self:ResetDKPInputBoxFull()
					-- self:ResetInputAndComment()
				-- end
				self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifierTot)
			else
					local ID = self:GetPlayerByIDByName(strName)
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
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("EP"))):SetText(self.tItems[ID].EP)
					end
					if self:LabelGetColumnNumberForValue("GP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(self.tItems[ID].GP)
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
	local count = #self.wndItemList:GetChildren()
	if count == 0 then
		self.wndMain:FindChild("CurrentlyListedAmount"):SetText("-")
	else
		self.wndMain:FindChild("CurrentlyListedAmount"):SetText(tostring(count))
	end
end


function DKP:OnListItemSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self.wndSelectedListItem = wndControl
end

function DKP:OnListItemDeselected()
	self.wndSelectedListItem = nil
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
			
			--Raid Settings
			if self.wndRaidOptions:FindChild("Button"):IsChecked() == true then
				self.tItems["settings"].RaidMsg = 1
			else
				self.tItems["settings"].RaidMsg = 0
			end
			if self.wndRaidOptions:FindChild("Button1"):IsChecked() == true then
				self.tItems["settings"].RaidItemTrack = 1
			else
				self.tItems["settings"].RaidItemTrack = 0
			end
			if self.wndRaidTools:IsShown() == true then
				self.tItems["settings"].RaidTools.show = 1
			else
				self.tItems["settings"].RaidTools.show = 0
			end
			
			
			-- Bid Resume
			
			if self.wndBid ~= nil and self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("GlobalOptions"):FindChild("OneMore"):IsChecked() == true then
				self.tItems["settings"].BidSpendOneMore = 1
			else
				self.tItems["settings"].BidSpendOneMore = 0
			end
			
			-- Time award awards
			
			self.tItems["AwardTimer"].EP = self.wndTimeAward:FindChild("Settings"):FindChild("EP"):IsChecked()
			self.tItems["AwardTimer"].GP = self.wndTimeAward:FindChild("Settings"):FindChild("GP"):IsChecked()
			self.tItems["AwardTimer"].DKP = self.wndTimeAward:FindChild("Settings"):FindChild("DKP"):IsChecked()
			
			
			for k=1,table.maxn(self.tItems) do
				if self.tItems[k] ~= nil then
					tSave[k] = {}
					tSave[k].strName = self.tItems[k].strName
					tSave[k].net = self.tItems[k].net
					tSave[k].tot = self.tItems[k].tot
					tSave[k].Hrs = self.tItems[k].Hrs
					tSave[k].TradeCap = self.tItems[k].TradeCap
					tSave[k].EP = self.tItems[k].EP
					tSave[k].GP = self.tItems[k].GP
					tSave[k].class = self.tItems[k].class
					tSave[k].alts = self.tItems[k].alts
					tSave[k].logs = self.tItems[k].logs
				end
			end
			if self.tItems["alts"] ~= nil then
				tSave["alts"]=self.tItems["alts"]
			end
			
			tSave["settings"] = self.tItems["settings"]
			tSave["Raids"] = self.tItems["Raids"]
			tSave["trades"] = self.tItems["trades"]
			if self.tItems["EPGP"].ForceItemSave == 1 then
				self.tItems["EPGP"].Loot = self.ItemDatabase
			end
			tSave["EPGP"] = self.tItems["EPGP"]
			tSave["Standby"] = self.tItems["Standby"]
			tSave["AwardTimer"] = self.tItems["AwardTimer"]
			tSave["Hub"] = self.tItems["Hub"]
			tSave["BidSlots"] = self.tItems["BidSlots"]
			tSave["Auctions"] = {}
			tSave["MyChoices"] = self.MyChoices
			tSave["MyVotes"] = self.MyVotes
			tSave.wndMainLoc = self.wndMain:GetLocation():ToTable()
			tSave.newUpdateAltCleanup = self.tItems.newUpdateAltCleanup
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
			local ID = self:GetPlayerByIDByName(strName)
			if ID ~= -1  then
				if self.tItems["EPGP"].Enable == 0 then
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
							Print(self.tItems["EPGP"].Enable)
							Print("Nothing added , check EP or GP in the controls box")
						end
					end					
					if self:LabelGetColumnNumberForValue("EP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("EP"))):SetText(self.tItems[ID].EP)
					end
					if self:LabelGetColumnNumberForValue("GP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(self.tItems[ID].GP)
					end
					if self:LabelGetColumnNumberForValue("PR") ~= -1 then
						if self.tItems[ID].GP ~= 0 then 
							self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f",self.tItems[ID].EP/self.tItems[ID].GP))
						else
							self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("PR"))):SetText("0")
						end
					end	
				end
				
				-- if cycling ~= true then
					-- self:ResetCommentBoxFull()
					-- self:ResetDKPInputBoxFull()
					-- self:ResetInputAndComment()
				-- end
				
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
			if ID ~= -1 then
				if self.tItems["EPGP"].Enable == 0 then
					local modifier = self.tItems[ID].net
					self.tItems[ID].net = self.tItems[ID].net - value
					modifier = self.tItems[ID].net - modifier
					if self:LabelGetColumnNumberForValue("Net") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Net"))):SetText(self.tItems[ID].net)
					end
					
					self:DetailAddLog(comment,modifier,ID)
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifier)
				else
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
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("EP"))):SetText(self.tItems[ID].EP)
					end
					if self:LabelGetColumnNumberForValue("GP") ~= -1 then
						self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(self.tItems[ID].GP)
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
			for i=1,GroupLib.GetMemberCount() do
				local player = GroupLib.GetGroupMember(i)
				local ID = self:GetPlayerByIDByName(player.strCharacterName)
				
				if ID ~= -1 then
					self.tItems[ID].net = self.tItems[ID].net + tonumber(self.tItems["settings"].dkp)
					self.tItems[ID].tot = self.tItems[ID].tot + tonumber(self.tItems["settings"].dkp)
					
					self:DetailAddLog(comment,"{DKP}",tostring(self.tItems["settings"].dkp),ID)
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,self.tItems["settings"].dkp)
				end
			end
		else
			self:EPGPAwardRaid(self.tItems["settings"].dkp,self.tItems["settings"].dkp)
		end
				
		self:ShowAll()
		
		-- self:ResetInputAndComment()
		-- self:ResetCommentBoxFull()
		-- self:ResetDKPInputBoxFull()
		self:EnableActionButtons()
end

function DKP:OnChatMessage(channelCurrent, tMessage)
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Loot then 
			local itemStr = ""
			local strName = ""
			local strTextLoot = ""
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextLoot = strTextLoot .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
			for word in string.gmatch(strTextLoot,"%S+") do
				if self.tItems["settings"].FilterWords then 
					if word == "Gift" or word == "Sign" or word == "Pattern" then return end
				end
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
			strName = string.sub(strName,2)
			if self.tItems["settings"].FilterEquippable and self.ItemDatabase[string.sub(itemStr,2)] then
				local item = Item.GetDataFromId(self.ItemDatabase[string.sub(itemStr,2)].ID)
				if not item:IsEquippable() then return end
			end
			if strName ~= "" and itemStr ~= "" then
				if self.tItems["settings"].PopupEnable == 1 then self:PopUpWindowOpen(strName:sub(1, #strName - 1),itemStr) end
				if self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == false then self:RaidProccesNewPieceOfLoot(itemStr,strName:sub(1,#strName-1)) end
				self:HubRegisterLoot(strName:sub(1, #strName - 1),string.sub(itemStr,2))
			end
	end
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper then
		if self.tItems["settings"].TradeEnable == 1 then 
			local strTextTrade = ""
			local senderStr = tMessage.strSender
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextTrade = strTextTrade .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
			for word in string.gmatch(strTextTrade,"%S+") do
				table.insert(words,word)
			end
			if #words < 6 --[[or (words[2] .. " " .. words[3]) ~= tMessage.strSender]] then return end
			if words[1] == "!trade" then
				self:TradeProcessMessage(words,senderStr)
			end
		end
	end
	if self.tItems["settings"].whisp == 1 then
		if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper then
			local senderStr = tMessage.strSender
			if self.tItems["settings"].lowercase == 1 then senderStr = string.lower(senderStr) end
			
			--if senderStr == GameLib.GetPlayerUnit():GetName() then
			--	return
			--end
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
			elseif strMessage == "!cap" then
				local ID
				for i=1,table.maxn(self.tItems) do
					if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(senderStr) then
						ID=i
						break	
					end
				end
				
				if ID ~= nil then
					ChatSystemLib.Command("/w " .. senderStr .. " Your current cap is : " ..self.tItems[ID].TradeCap)
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

function DKP:EnableActionButtons( wndHandler, wndControl, strText )
	local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
	local wndInputBox = self.wndMain:FindChild("Controls"):FindChild("EditBox1")
	local strDKP = wndInputBox:GetText()
	strText = wndCommentBox:GetText()
	if strDKP ~= "Input Value" and strText ~= "Comment" and self.wndSelectedListItem~=nil or strDKP ~= "Input Value" and strText ~= "Comment" and self.MassEdit == true then
		local setButton = self.wndMain:FindChild("ButtonSet")
		local addButton = self.wndMain:FindChild("ButtonAdd")
		local subtractButton = self.wndMain:FindChild("ButtonSubtract")

		setButton:Enable(true)
		addButton:Enable(true)
		subtractButton:Enable(true)
	end
	if strDKP == "Input Value" or strDKP == "" then
		self:ResetInputAndComment()
	end
	if strText == "Comment" or strText == "" then
		self:ResetInputAndComment()
	end
	if strText == "" then
		local wndInputBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
		wndInputBox:SetText("Comment")	
	end
	if strText ~= "Comment" then
		self.wndMain:FindChild("Add100DKP"):Enable(true)
	end
end

function DKP:ResetInputAndComment()
	self.wndMain:FindChild("Controls"):FindChild("ButtonSet"):Enable(false)
	self.wndMain:FindChild("Controls"):FindChild("ButtonAdd"):Enable(false)
	self.wndMain:FindChild("Controls"):FindChild("ButtonSubtract"):Enable(false)
end

function DKP:ResetCommentBox( wndHandler, wndControl, strText )
	if strText == "" then
		self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comment")
	end
end

function DKP:ResetCommentBoxFull( wndHandler, wndControl, strText )
	local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
	if self.tItems["settings"].logs == 1 then
		wndCommentBox:SetText("Comment")
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
	self.wndSettings:FindChild("EditBoxQuickAdd"):SetText(self.tItems["settings"].dkp)
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
		self.wndTimeAward:FindChild("CountDown"):SetText("Disabled")
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
	local raidMembers =  {}
	for i=1,GroupLib.GetMemberCount() do
		local unit_member = GroupLib.GetGroupMember(i)
			raidMembers[string.lower(unit_member.strCharacterName)] = 1
	end
	local children = self.wndItemList:GetChildren()
	for k,child in ipairs(children) do
		if raidMembers[string.lower(child:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText())] == 1 then
			child:SetCheck(true)
			table.insert(selectedMembers,child)
		end
	end
end

function DKP:MassEditDeselect( wndHandler, wndControl, eMouseButton )
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(false)
	end
	selectedMembers = {}
end

function DKP:MassEditSelectAll( wndHandler, wndControl, eMouseButton )
	local children = self.wndItemList:GetChildren()
	for k,child in ipairs(children) do
		table.insert(selectedMembers,child)
		child:SetCheck(true)
	end
end

function DKP:MassEditRemove( wndHandler, wndControl, eMouseButton )
	for k,wnd in ipairs(selectedMembers) do 
		if wnd:GetData() and self.tItems[wnd:GetData()] then
			for k,alt in ipairs(self.tItems[wnd:GetData()].alts) do self.tItems["alts"][string.lower(alt)] = nil end
			table.remove(self.tItems,self:GetPlayerByIDByName(wnd:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText()))
		end
	end
	self:RefreshMainItemList()
end

function DKP:MassEditModify(what) -- "Add" "Sub" "Set" 
	--we're gonna just change self.wndSelectedListItem and call the specific function
	if what == "Add" then
		for i,wnd in ipairs(selectedMembers) do
			--Print(wnd:FindChild("Stat1"):GetText())
			self.wndSelectedListItem = wnd
			self:AddDKP(true) -- information to function not to cause stack overflow
		end
	elseif what == "Sub" then
		for i,wnd in ipairs(selectedMembers) do
			self.wndSelectedListItem = wnd
			self:SubtractDKP(true) 
		end
	elseif what == "Set" then
		for i,wnd in ipairs(selectedMembers) do
			self.wndSelectedListItem = wnd
			self:SetDKP(true) 
		end
	end
end
function DKP:MassEditItemSelected( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	table.insert(selectedMembers,wndControl)
end

function DKP:MassEditItemDeselected( wndHandler, wndControl, eMouseButton)
	for i,wnd in ipairs(selectedMembers) do
		if wnd == wndControl then 
			table.remove(selectedMembers,i) 
			break
		end
	end
end

function DKP:RefreshMainItemList()
	if self.tItems["settings"].GroupByClass then self:RefreshMainItemListAndGroupByClass() return end
	local selectedPlayer = ""
	if self:LabelGetColumnNumberForValue("Name") > 0 then
		if self.MassEdit then
			selectedPlayer = {}
			for k,player in ipairs(selectedMembers) do
				--for k,wnd in ipairs(player:GetChildren()) do Print(wnd:GetName()) end
				table.insert(selectedPlayer,player:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
			end
		elseif self.wndSelectedListItem then
			selectedPlayer = self.wndSelectedListItem:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText()
		end
	end
	selectedMembers = {}
	self.wndSelectedListItem = nil
	self.wndItemList:DestroyChildren()
	local nameLabel = self:LabelGetColumnNumberForValue("Name")
	for k,player in ipairs(self.tItems) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
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
	self.wndItemList:ArrangeChildrenVert(0,easyDKPSortPlayerbyLabel)
	self:UpdateItemCount()
end

function DKP:IsPlayerInRaid(strPlayer)
	--Print(strPlayer)
	local raid = self:Bid2GetTargetsTable()
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
	
	if k and k == 1 or  bAddedClass == false then playerItem.wnd:FindChild("NewClass"):Show(true,false) end
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
				if self.tItems["settings"]["Bid2"].tWinners then
					local item = Item.GetDataFromId(self.tItems["settings"]["Bid2"].tWinners[playerItem.strName])
					if item then
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
						playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(item:GetName())
						Tooltip.GetItemTooltipForm(self,playerItem.wnd:FindChild("Stat"..tostring(i)), item  ,{bPrimary = true, bSelling = false})
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
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.EP)
			elseif self.tItems["settings"].LabelOptions[i] == "GP" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.GP)
			elseif self.tItems["settings"].LabelOptions[i] == "PR" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(self:EPGPGetPRByName(playerItem.strName))
			end
		end
		if self.SortedLabel and i == self.SortedLabel then playerItem.wnd:FindChild("Stat"..i):SetTextColor("ChannelAdvice") else playerItem.wnd:FindChild("Stat"..i):SetTextColor("white") end
	end
	if playerItem.class then playerItem.wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[playerItem.class]) else playerItem.wnd:FindChild("ClassIcon"):Show(false,false) end
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
	if value == "Name" then return "Name of Player."
	elseif value == "Net" then return "Current value of player's DKP."
	elseif value == "Tot" then return "Value of DKP that has been earned since account creation."
	elseif value == "Spent" then return "Value of DKP player has spent."
	elseif value == "Hrs" then return "How much time has this player spent Raiding.This is automatically tracked during raid session or optionally you can track it in Timed Awards module."
	elseif value == "Priority" then return "Value calculated by dividing the Tot value by the Spent Value.AKA Relational DKP."
	elseif value == "EP" then return "Value of player's Effort Points."
	elseif value == "GP" then return "Value of player's Gear Points."
	elseif value == "PR" then return "Value calculated by dividing the EP value by GP value"
	elseif value == "Raids" then return "Value of player's attended raids"
	elseif value == "Item" then return "Last item received.Recoreded via bidding (chat and network)"
	end
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
	
	for k,player in ipairs(self.tItems) do
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
	table.sort(esp,easyDKPSortPlayerbyLabelNotWnd)
	table.sort(eng,easyDKPSortPlayerbyLabelNotWnd)
	table.sort(med,easyDKPSortPlayerbyLabelNotWnd)
	table.sort(war,easyDKPSortPlayerbyLabelNotWnd)
	table.sort(sta,easyDKPSortPlayerbyLabelNotWnd)
	table.sort(spe,easyDKPSortPlayerbyLabelNotWnd)
	table.sort(unknown,easyDKPSortPlayerbyLabelNotWnd)
	
	local addedM = false
	local addedEs = false
	local addedEn = false
	local addedW = false
	local addedS = false
	local addedSt = false
	local addedU = false
	
	for k,player in ipairs(esp) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedEs)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedEs = true
			end
		end
	end	
	for k,player in ipairs(eng) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedEn)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedEn = true
			end
		end
	end	
	for k,player in ipairs(med) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedM)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedM = true
			end
		end
	end	
	for k,player in ipairs(war) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedW)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedW = true
			end
		end
	end	
	for k,player in ipairs(sta) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedSt)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedSt = true
			end
		end
	end	
	for k,player in ipairs(spe) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedS)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedS = true
			end
		end
	end
	for k,player in ipairs(unknown) do
		if self.SearchString and self.SearchString ~= "" and self:string_starts(player.strName,self.SearchString) or self.SearchString == nil or self.SearchString == "" then
			if not self.wndMain:FindChild("RaidOnly"):IsChecked() or self.wndMain:FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if not self.MassEdit then
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
				else
					player.wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
				end
				self:UpdateItem(player,k,addedU)
				player.wnd:SetData(self:GetPlayerByIDByName(player.strName))
				addedU = true
			end
		end
	end
	if self:LabelGetColumnNumberForValue("Name") > 0 then
		for k,child in ipairs(self.wndItemList:GetChildren()) do
			if not self.MassEdit then
				if self.tItems[child:GetData()].strName == selectedPlayer then
					self.wndSelectedListItem = child
					child:SetCheck(true)	
				end
			else
				local found = false
				
				for k,prevPlayer in ipairs(selectedPlayer) do
					if prevPlayer ==  self.tItems[child:GetData()].strName then
						found = true
						break
					end
				end
				if found then
					table.insert(selectedMembers,child)
					child:SetCheck(true)
				end
			end
		end
	end
	
	
	self.wndItemList:ArrangeChildrenVert()
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

function DKP:SettingsWhisperEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].whisp = 1
end

function DKP:SettingsLogsDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].logs = 0
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):SetText("Comments Disabled")
	self.wndMain:FindChild("Controls"):FindChild("EditBox"):Enable(false)
end

function DKP:SettingsWhisperDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].whisp = 0
end

function DKP:SettingsSetQuickDKP( wndHandler, wndControl, eMouseButton )
	local value = self.wndSettings:FindChild("EditBoxQuickAdd"):GetText()
	self.tItems["settings"].dkp = tonumber(value)
	
	self:ControlsUpdateQuickAddButtons()
end

function DKP:SettingsSetGuildname( wndHandler, wndControl, eMouseButton )
	local strName = self.wndSettings:FindChild("EditBoxGuldName"):GetText()
	self.tItems["settings"].guildname = strName
end

function DKP:SettingsCheckDKPSpelling( wndHandler, wndControl, strText)
	if strText == "" then
		wndControl:SetText("Input Quick DKP")
	end
end

function DKP:SettingsCheckGuildSpelling( wndHandler, wndControl, strText )
	if strText == "" then
		wndControl:SetText("! Enter your Guild's name !")
	end
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
	--GUILDNAME
	if self.tItems["settings"].guildname ~= nil then
		local wndGuild = self.wndSettings:FindChild("EditBoxGuldName"):SetText(self.tItems["settings"].guildname)
		--self.wndMain:FindChild("Title"):SetText("EasyDKP - "..self.tItems["settings"].guildname)
	end
	--MASS ADD
          self.wndSettings:FindChild("EditBoxQuickAdd"):SetText(tostring(self.tItems["settings"].dkp))
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
	
	--Networking
	self.wndSettings:FindChild("ButtonSettingsEnableNetworking"):SetCheck(self.tItems["settings"].networking)
	self.wndSettings:FindChild("ButtonSettingsEquip"):SetCheck(self.tItems["settings"].FilterEquippable)
	self.wndSettings:FindChild("ButtonSettingsFilter"):SetCheck(self.tItems["settings"].FilterWords)
	
	--Slider
	self.wndSettings:FindChild("Precision"):SetValue(self.tItems["settings"].Precision)
	
	--Affiliation
	if self.tItems["settings"].CheckAffiliation == 1 then self.wndSettings:FindChild("ButtonSettingsNameplatreAffiliation"):SetCheck(true) end
end

function DKP:SettingsEnablePlayerCollection( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].collect_new = 1
end

function DKP:SettingsDisablePlayerCollection( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].collect_new = 0
end

function DKP:SettingsSetDefDKP( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].default_dkp = tonumber(self.wndSettings:FindChild("EditBoxDefaultDKP"):GetText())
end

function DKP:SettingsPurgeDatabaseOn( wndHandler, wndControl, eMouseButton )
		purge_database = 1
end

function DKP:SettingsPurgeDatabaseOff()
		purge_database = 0
end

function DKP:SettingsEnableSync( wndHandler, wndControl, eMouseButton )
	self.sChannel = ICCommLib.JoinChannel("RaidOpsSyncChannel","OnSyncMessage",self)
end

function DKP:SettingsDisableSync( wndHandler, wndControl, eMouseButton )
	self.sChannel = nil
end

function DKP:OnSyncMessage(channel, tMsg, strSender)
	if tMsg.type then
		if tMsg.type == "SendMeData" then
			self.sChannel:SendPrivateMessage({[1] = strSender},{type = "EncodedData",strData = self:GetEncodedData()})
		elseif tMsg.type == "EncodedData" then
			self:ProccesEncodedData(tMsg.strData)
		end
	end
end

function DKP:ProccesEncodedData(strData)
	local tData = serpent.load(Base64.Decode(strData))
	
	if tData then
		for k,player in ipairs(tData) do
			if self:GetPlayerByIDByName(player.strName) == -1 then
				table.insert(self.tItems,player)
			else
				self.tItems[self:GetPlayerByIDByName(player.strName)] = player
			end
		end
	end
	Print("Data received and proccessed")
	
	self:RefreshMainItemList()
	

end

function DKP:GetEncodedData()
	local tData = {}
	
	for k,player in ipairs(self.tItems) do
		table.insert(tData,player)
	end
	
	return Base64.Encode(serpent.dump(tData))
end

function DKP:SettingsFetchData()
	if self.sChannel then self.sChannel:SendPrivateMessage({[1] = self.wndSettings:FindChild("EditBoxFetchedName"):GetText()},{type = "SendMeData"}) end
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




function DKP:SettingsSetPrecision( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].Precision then
		self.tItems["settings"].Precision = math.floor(fNewValue)
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
		self.wndExport:FindChild("ExportBox"):SetText(Base64.Encode(serpent.dump(self.tItems)))
	elseif self.wndExport:FindChild("ButtonImport"):IsChecked() then
		newImportedDatabaseGlobal = serpent.load(Base64.Decode(self.wndExport:FindChild("ExportBox"):GetText()))
		if type(newImportedDatabaseGlobal) ~= "table" or newImportedDatabaseGlobal["settings"] == nil then newImportedDatabaseGlobal = nil
		else ChatSystemLib.Command("/reloadui") end
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
					if string.find(logs.comment,"EP") ~= nil and string.find(logs.comment,"GP") ~= nil then 
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

function DKP:PopUpCheckDKPSpelling( wndHandler, wndControl, strText )
	if strText == "" then
		wndControl:SetText("X")
	end
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
		else
			self.wndPopUp:FindChild("LabelCurrency"):SetText("DKP.")
		end
		CurrentPopUpID = PopUpItemQueue[1].ID
		if self.RegistredBidWinners[string.sub(PopUpItemQueue[1].strItem,2)] ~= nil then
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(self.RegistredBidWinners[string.sub(PopUpItemQueue[1].strItem,2)].cost)
		end
		table.remove(PopUpItemQueue,1)
	end
	self:PopUpUpdateQueueLength()
end

function DKP:PopUpWindowOpen(strName,strItem)
	if self.tItems["settings"].PopupEnable == 0 then return end
	local ID_popup = nil
	for i=1, table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(strName) then
			ID_popup = i
			break
		end
	end
	if ID_popup == nil then 
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
			else
				self.wndPopUp:FindChild("LabelCurrency"):SetText("DKP.")
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
		else
			self.wndPopUp:FindChild("LabelCurrency"):SetText("DKP.")
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
	if strText == nil then 
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
		if self.tItem["settings"].DS.logs then self:DSAddLog(strRequester,"Fail") end
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
	if self.tItem["settings"].DS.logs then
		self:DSAddLog(strRequester,"Succes")
	end
	
	return Base64.Encode(serpent.dump(tStandings))
end

function DKP:DSGetEncodedLogs(strRequester)
	if self.tItems["settings"].DS.shareLogs then
		local ID = self:GetPlayerByIDByName(strRequester)
		
		if ID ~= -1 then
			if self.tItems["settings"].DS.logs then self:DSAddLog(strRequester,"Logs") end
			return Base64.Encode(serpent.dump(self.tItems[ID].logs))
		end
	end
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


function DKP:ConShow(wndHandler,wndControl,eMouseButton)
	if wndControl ~= wndHandler then return end
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and self:LabelGetColumnNumberForValue("Name") > 0 then 
		local tCursor = Apollo.GetMouse()
		self.wndContext:Move(tCursor.x, tCursor.y, self.wndContext:GetWidth(), self.wndContext:GetHeight())
		self.wndContext:Show(true,false)
		local ID = self:GetPlayerByIDByName(wndControl:FindChild("Stat"..self:LabelGetColumnNumberForValue("Name")):GetText())
		self.wndContext:SetData(ID) -- PlayerID
		self.wndContext:ToFront()
		if self.tItems["Standby"][string.lower(self.tItems[ID].strName)] ~= nil then self.wndContext:FindChild("Standby"):SetCheck(true) else self.wndContext:FindChild("Standby"):SetCheck(false) end
		wndControl:FindChild("OnContext"):Show(true,false)
	end
end

function DKP:ConAlts()
	self:AltsShow()
end

function DKP:ConLogs()
	self:LogsShow()
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
	for k,alt in ipairs(self.tItems[self.wndContext:GetData()].alts) do self.tItems["alts"][string.lower(alt)] = nil end
	table.remove(self.tItems,self.wndContext:GetData())
	self.wndContext:Close()
	wndControl:Show(false,false)
	self:RefreshMainItemList()
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
	self.wndAlts:Show(false,true)
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
end

function DKP:LogsShow()
	if not self.wndLogs:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndLogs:Move(tCursor.x - 100, tCursor.y - 100, self.wndLogs:GetWidth(), self.wndLogs:GetHeight())
	end
	
	self.wndContext:Close()
	self.wndLogs:Show(true,false)
	self.wndLogs:ToFront()
	
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

function DKP:DetailAddLog(strComment,strType,strModifier,ID)
	table.insert(self.tItems[ID].logs,1,{strComment = strComment,strType = strType, strModifier = strModifier,strTimestamp = os.date("%x",os.time()) .. "  " .. os.date("%X",os.time())})
	if self.wndLogs:GetData() == ID then self:LogsPopulate() end
	if #self.tItems[ID].logs > 20 then table.remove(self.tItems[ID].logs,20) end
end

function DKP:LogsClose()
	self.wndLogs:Show(false,false)
end




-----------------------------------------------------------------------------------------------
-- DKP Instance
-----------------------------------------------------------------------------------------------
local DKPInst = DKP:new()
DKPInst:Init()