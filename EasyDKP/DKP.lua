-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2014 	dogier140@poczta.fm.
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
	counter = 1
	showing_raid = 1
	working_on_itmes = 0
	searching = 0
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
		self.wndDetail = Apollo.LoadForm(self.xmlDoc, "MemberDetails" , nil , self)
		self.wndSettings = Apollo.LoadForm(self.xmlDoc, "Settings" , nil , self)
		self.wndExport = Apollo.LoadForm(self.xmlDoc, "Export" , nil , self)
		self.wndPopUp = Apollo.LoadForm(self.xmlDoc, "MasterLootPopUp" , nil ,self)
		self.wndStandby = Apollo.LoadForm(self.xmlDoc2, "StandbyList" , nil , self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
		self.wndItemList = self.wndMain:FindChild("ItemList")
		self.wndMain:Show(false, true)
		self.wndDetail:Show(false , true)
		self.wndSettings:Show(false , true)
		self.wndExport:Show(false , true)
		self.wndPopUp:Show(false, true)
		self.wndStandby:Show(false,true)
		self.wndMain:FindChild("MassEditControls"):Show(false,true)
		Apollo.RegisterSlashCommand("dkp", "OnDKPOn", self)
		Apollo.RegisterSlashCommand("sum", "RaidShowMainWindow", self)
		Apollo.RegisterSlashCommand("dkpbid", "BidOpen", self)
		Apollo.RegisterTimerHandler(10, "OnTimer", self)
		Apollo.RegisterTimerHandler(10, "RaidUpdateCurrentRaidSession", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		
		--Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		--Apollo.RegisterEventHandler("LootedItem", "OnLootedItem", self)

		
		Apollo.RegisterEventHandler("Group_Remove","ForceRefresh", self)	
		self.timer = ApolloTimer.Create(10, true, "OnTimer", self)


		local setButton = self.wndMain:FindChild("ButtonSet")
		local addButton = self.wndMain:FindChild("ButtonAdd")
		local subtractButton = self.wndMain:FindChild("ButtonSubtract")
		local quickAddButton = self.wndMain:FindChild("Add100DKP")
		setButton:Enable(false)
		addButton:Enable(false)
		subtractButton:Enable(false)
		quickAddButton:Enable(false)
		
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
		if self.tItems["settings"].Precision == nil then self.tItems["settings"].Precision = 1 end
		if self.tItems["settings"].CheckAffiliation == nil then self.tItems["settings"].CheckAffiliation = 0 end
		if self.tItems["Standby"] == nil then self.tItems["Standby"] = {} end
		self.wndLabelOptions = self.wndMain:FindChild("LabelOptions")
		self.wndTimeAward = self.wndMain:FindChild("TimeAward")
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):Show(false,true)
		self.wndLabelOptions:Show(false,true)
		self.wndTimeAward:Show(false,true)
		self.MassEdit = false
		self:TimeAwardRestore()
		self:HelloImHome()
		self:EPGPInit()
		
		self:CloseBigPOPUP()
		Print(self.tItems["settings"].guildname)
		if self.tItems["settings"].NewStartup == nil then
			self.wndMain:FindChild("BIGPOPUP"):Show(true,false)
			self.tItems["settings"].NewStartup = "DONE"
		end


		
		
		
		-- Inits
		self:SettingsRestore()
		self:LabelUpdateList() --<<<< With Show ALL
		self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):SetCheck(false)
		self.wndSettings:FindChild("EditBoxFetchedName"):Enable(false)
		self.wndSettings:FindChild("ButtonSettingsFetchData"):Enable(false)
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
		end
		if self.tItems["settings"].RaidTools.show == 1 then self:RaidToolsEnable() end
	end
end

function DKP:CloseBigPOPUP()
	self.wndMain:FindChild("BIGPOPUP"):Show(false,true)
end

function DKP:OnUnitCreated(unit,isStr)
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

		local altName = nil
		if self.tItems["alts"] ~= nil then
			if self.tItems["alts"][strName] ~= nil then
				altName = strName
				strName = self.tItems[self.tItems["alts"][strName]].strName	
			end
		end
		
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
				i.name = self.tItems[existingID].strName
				if altName ~= nil then
					i.alt = altName
				end
				if self.tItems[existingID].tot == nil then self.tItems[existingID].tot = self.tItems[existingID].net end
				if self.tItems[existingID].listed == 1 then
					self:UpdateItem(i)
				end
				if self.tItems[existingID].listed == 0 then
					self:AddItem(i,existingID)
					self.tItems[existingID].listed = 1
				end
		elseif isNew == true and self.tItems["settings"].CheckAffiliation == 0 or isNew == true and self.tItems["settings"].CheckAffiliation == 1 and isStr == nil then
			if counter == 0 then counter = 1 end
			self.tItems[counter] = {}
			self.tItems[counter].strName = strName
			local i = {}
			i.name = strName
			i.net = tostring(self.tItems["settings"].default_dkp)
			i.tot = tostring(self.tItems["settings"].default_dkp)
			self.tItems[counter].net = i.net
			self.tItems[counter].tot = i.tot
			self.tItems[counter].listed = 0
			self.tItems[counter].Hrs = 0
			self.tItems[counter].EP = self.tItems["EPGP"].MinEP
			self.tItems[counter].GP = self.tItems["EPGP"].BaseGP
			if self.tItems["settings"].TradeEnable == 1 then
				self.tItems[counter].TradeCap = self.tItems["settings"].TradeCap
			end
			counter = counter + 1
			if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == false and isStr ~= nil then
				self.tItems[counter-1].listed = 1
				self:AddItem(i,counter-1)
			elseif isStr == nil then
				self.tItems[counter-1].listed = 1
				self:AddItem(i,counter-1)
			end
		end
		self:UpdateItemCount()
end



function DKP:OnTimer()
	if self.tItems["settings"].collect_new == 1 then
		for k=1,GroupLib.GetMemberCount(),1 do
		local unit_member = GroupLib.GetGroupMember(k)
			if unit_member ~= nil then
					self:OnUnitCreated(unit_member.strCharacterName,true)
			end
		if self.tItems["settings"].CheckAffiliation == 1 then
			local member = GroupLib.GetUnitForGroupMember(k)
				if member ~= nil and member:GetGuildName() ~= nil  then
					if self:GetPlayerByIDByName(member:GetName()) == -1 and string.lower(member:GetGuildName()) == string.lower(self.tItems["settings"].guildname) then
						self:OnUnitCreated(member)
					end
				end
			
			end
		end
	end
end
-----------------------------------------------------------------------------------------------
-- DKP Functions
-----------------------------------------------------------------------------------------------
function DKP:OnDKPOn()
	self.wndMain:Invoke()
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
				self:DetailAddLog(comment,modifierTot,ID)
				if cycling ~= true then
					self:ResetCommentBoxFull()
					self:ResetDKPInputBoxFull()
					self:ResetInputAndComment()
				end
				self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifierTot)
			else
					local ID = self:GetPlayerByIDByName(strName)
					local modEP = self.tItems[ID].EP
					local modGP = self.tItems[ID].GP
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() == true then
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPSet(strName,value,value)
							self:DetailAddLog(comment.. " {EP}",self.tItems[ID].EP - modEP,ID)
							self:DetailAddLog(comment.. " {GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPSet(strName,value,nil)
							self:DetailAddLog(comment.. " {EP}",self.tItems[ID].EP - modEP,ID)
						end
					else 
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPSet(strName,nil,value)
							self:DetailAddLog(comment.. " {GP}",self.tItems[ID].GP - modGP,ID)
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
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and self.tItems[i].listed == 1 then
				self.tItems[i].wnd:Destroy()
			end
		end
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and DKP:string_starts(self.tItems[i].strName,strText) == true and self.tItems[i].listed == 1 then
				local k = {}
				k.name = self.tItems[i].strName
				k.net = self.tItems[i].net
				k.tot = self.tItems[i].tot
				self:AddItem(k,i)
			end
		end
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and self.tItems[i].wnd == nil then
				self.tItems[i].listed = 0
			end
		end
		self.wndItemList:ArrangeChildrenVert()	
	else
		local wndInputBox = self.wndMain:FindChild("EditBox1")
		wndInputBox:SetText("Search")
		
		if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == true then
			self:ShowRaid()
		else
			self:ShowAll()
		end
	end
end
function DKP:string_starts(String,Start)
   return string.sub(string.lower(String),1,string.len(Start))==string.lower(Start)
end

function DKP:ResetSearchBox()
		local wndInputBox = self.wndMain:FindChild("EditBox1")
		wndInputBox:SetText("Search")
end

-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------


function DKP:DestroyItemList()
	for idx,wnd in ipairs(self.tItems) do
		wnd:Destroy()
	end

	self.wndSelectedListItem = nil
end

function DKP:AddItem(i,ID)
	local wnd = nil
	if not self.MassEdit then
		wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
	else
		wnd = Apollo.LoadForm(self.xmlDoc, "ListItemButton", self.wndItemList, self)
	end
	i.wnd = wnd
	self.tItems[ID].wnd = i.wnd
	self:UpdateItem(i)
	self.wndItemList:ArrangeChildrenVert()
end
function DKP:UpdateItemCount()
	local count = 0 
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then 
			if self.tItems[i].listed ~= nil then
				if self.tItems[i].listed == 1 then 
					count = count + 1
				end
			end
		end
	end
	if count == 0 then
		self.wndMain:FindChild("CurrentlyListedAmount"):SetText("-")
	else
		self.wndMain:FindChild("CurrentlyListedAmount"):SetText(tostring(count))
	end
end
function DKP:UpdateItem(playerItem)
	if playerItem.wnd == nil then return end
	for i=1,5 do
		if self.tItems["settings"].LabelOptions[i] ~= "Nil" then
			if self.tItems["settings"].LabelOptions[i] == "Name" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.name)
			elseif self.tItems["settings"].LabelOptions[i] == "Net" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.net)
			elseif self.tItems["settings"].LabelOptions[i] == "Tot" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(playerItem.tot)
			elseif self.tItems["settings"].LabelOptions[i] == "Hrs" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(self.tItems[self:GetPlayerByIDByName(playerItem.name)].Hrs)
			elseif self.tItems["settings"].LabelOptions[i] == "Spent" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(tonumber(playerItem.tot)-tonumber(playerItem.net))
			elseif self.tItems["settings"].LabelOptions[i] == "Priority" then
				if tonumber(playerItem.tot)-tonumber(playerItem.net) ~= 0 then
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f",tonumber(playerItem.tot)/(tonumber(playerItem.tot)-tonumber(playerItem.net))))
				else
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText("0")
				end
			elseif self.tItems["settings"].LabelOptions[i] == "EP" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(self.tItems[self:GetPlayerByIDByName(playerItem.name)].EP)
			elseif self.tItems["settings"].LabelOptions[i] == "GP" then
				playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(self.tItems[self:GetPlayerByIDByName(playerItem.name)].GP)
			elseif self.tItems["settings"].LabelOptions[i] == "PR" then
				if  self.tItems[self:GetPlayerByIDByName(playerItem.name)].GP ~= 0 then
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText(string.format("%."..tostring(self.tItems["settings"].Precision).."f", tonumber( self.tItems[self:GetPlayerByIDByName(playerItem.name)].EP / self.tItems[self:GetPlayerByIDByName(playerItem.name)].GP)))
				else
					playerItem.wnd:FindChild("Stat"..tostring(i)):SetText("0")
				end
			end
		end
	end
	if playerItem.alt ~=nil then
		playerItem.wnd:FindChild("AltNote"):SetTooltip("Playing as : " .. i.alt)
	else
		playerItem.wnd:FindChild("AltNote"):Show(false,false)
	end
end
function DKP:OnListItemSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	if self.wndSelectedListItem ~= nil and self.wndSelectedListItem ~= wndControl then
		local children = self.wndSelectedListItem:GetChildren()
		for k,child in ipairs(children) do
			child:SetTextColor(kcrNormalText)
		end
	end
	if self.wndSelectedListItem ~= nil and self.wndSelectedListItem == wndControl then
		self:OnDetailsClose()
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			self:DetailShow(wndControl:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText())
		else
			Print("Name Label is Required")
		end
	else
		local children  = wndControl:GetChildren()
		for k,child in ipairs(children) do
			child:SetTextColor(kcrSelectedText)
		end
		self.wndSelectedListItem = wndControl
	
	end
end

function DKP:OnSave(eLevel)
	   	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end


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
					tSave[k].listed = 0
					tSave[k].Hrs = self.tItems[k].Hrs
					tSave[k].TradeCap = self.tItems[k].TradeCap
					tSave[k].EP = self.tItems[k].EP
					tSave[k].GP = self.tItems[k].GP
					if self.tItems[k].alts ~= nil then
						tSave[k].alts = {}
						local skip_counter = 0 
						for j=1,table.getn(self.tItems[k].alts) do
							if self.tItems[k].alts[j].strName ~= -1 then
								tSave[k].alts[j - skip_counter] = {}
								tSave[k].alts[j - skip_counter].strName = self.tItems[k].alts[j].strName
								tSave[k].alts[j - skip_counter].altsTablePos = self.tItems[k].alts[j].altsTablePos
							else
								skip_counter = skip_counter + 1
							end
						end
					end
					if self.tItems[k].logs ~= nil then
						tSave[k].logs = {}
						for j=1,table.getn(self.tItems[k].logs) do
							tSave[k].logs[j] = {}
							tSave[k].logs[j].comment = self.tItems[k].logs[j].comment
							tSave[k].logs[j].modifier = self.tItems[k].logs[j].modifier
						end
					end
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
		
		counter=table.maxn(self.tItems)+1
		if tData["alts"] == nil then
			self.tItems["alts"] = {}
		end
 end


function DKP:ShowAll()
		selectedMembers = {}
		self:ResetSearchBox()
		self:ShowRaid()
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and self.tItems[i].listed == 0 then
				self.tItems[i].listed = 1
				local k = {}
				k.name = self.tItems[i].strName
				k.net = self.tItems[i].net
				k.tot = self.tItems[i].tot
				self:AddItem(k,i)
			end
		end
		self.wndItemList:ArrangeChildrenVert()
		self:UpdateItemCount()
		self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):SetCheck(false)
		self.wndSelectedListItem = nil
end
function DKP:ForceRefresh()
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and self.tItems[i].listed == 1 then
			self.tItems[i].wnd:Destroy()
			self.tItems[i].listed = 0
		end
	end
	self.wndItemList:ArrangeChildrenVert()
	self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):SetCheck(true)
end

function DKP:ShowRaid()
		self:ResetSearchBox()
		working_on_itmes = 1
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and self.tItems[i].listed == 1 then
				self.tItems[i].wnd:Destroy()
				self.tItems[i].listed = 0
			end
		end
		self:OnTimer()
		self.wndItemList:ArrangeChildrenVert()
		self:UpdateItemCount()
end

function DKP:AddDKP(cycling) -- Mass Edit check
	if self.MassEdit == true and cycling ~= true then
		self:MassEditModify("Add")
		return
	end
	
	if self.wndSelectedListItem ~=nil then
		if self:LabelGetColumnNumberForValue("Name") ~= -1 then
			local strName = self.wndSelectedListItem:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText()
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
					
					comment = comment .. "{DKP}"
					self:DetailAddLog(comment,modifier,ID)
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,modifier)
				else
					local modEP = self.tItems[ID].EP
					local modGP = self.tItems[ID].GP
					comment = comment .. "{EPGP}"	
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() == true then
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPAdd(strName,value,value)
							self:DetailAddLog(comment.. " {EP}",self.tItems[ID].EP - modEP,ID)
							self:DetailAddLog(comment.. " {GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPAdd(strName,value,nil)
							self:DetailAddLog(comment.. " {EP}",self.tItems[ID].EP - modEP,ID)
						end
					else 
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPAdd(strName,nil,value)
							self:DetailAddLog(comment.. " {GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPAdd(strName,nil,nil)
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
				
				if cycling ~= true then
					self:ResetCommentBoxFull()
					self:ResetDKPInputBoxFull()
					self:ResetInputAndComment()
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
					comment = comment .. "{EPGP}"	
					if self.wndMain:FindChild("Controls"):FindChild("ButtonEP"):IsChecked() == true then
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPSubtract(strName,value,value)
							self:DetailAddLog(comment.. " {EP}",self.tItems[ID].EP - modEP,ID)
							self:DetailAddLog(comment.. " {GP}",self.tItems[ID].GP - modGP,ID)
						else
							self:EPGPSubtract(strName,value,nil)
							self:DetailAddLog(comment.. " {EP}",self.tItems[ID].EP - modEP,ID)
						end
					else 
						if self.wndMain:FindChild("Controls"):FindChild("ButtonGP"):IsChecked() == true then
							self:EPGPSubtract(strName,nil,value)
							self:DetailAddLog(comment.. " {GP}",self.tItems[ID].GP - modGP,ID)
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
			
			
				if cycling ~= true then
					self:ResetCommentBoxFull()
					self:ResetDKPInputBoxFull()
					self:ResetInputAndComment()
				end
		else
			Print("Name Label is required")
		end
	else
		Print("You haven't selected any player")
	end
end

function DKP:Add100DKP()
	if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == true then
		if self.tItems["EPGP"].Enable == 0 then
			local comment = self.wndMain:FindChild("Controls"):FindChild("EditBox"):GetText()
			for i=1,GroupLib.GetMemberCount() do
				local player = GroupLib.GetGroupMember(i)
				local ID = self:GetPlayerByIDByName(player.strCharacterName)
				if ID ~= -1 then
					self.tItems[ID].net = self.tItems[ID].net + tonumber(self.tItems["settings"].dkp)
					self.tItems[ID].tot = self.tItems[ID].tot + tonumber(self.tItems["settings"].dkp)
					
					self:DetailAddLog(comment,tostring(self.tItems["settings"].dkp),ID)
					self:RaidRegisterDkpManipulation(self.tItems[ID].strName,self.tItems["settings"].dkp)
				end
			end
		else
			self:EPGPAwardRaid(self.tItems["settings"].dkp,self.tItems["settings"].dkp)
		end
				
		self:ShowAll()
		self:ResetInputAndComment()
		self:ResetCommentBoxFull()
		self:ResetDKPInputBoxFull()
		self:EnableActionButtons()
	end
end
function DKP:OnChatMessage(channelCurrent, tMessage)
	if GroupLib.InRaid() == true then
		if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Loot then 
			local itemStr = ""
			local strName = ""
			local strTextLoot = ""
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextLoot = strTextLoot .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
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
					strName = strName .. words[i]
				end
			end
			if strName ~= "" and itemStr ~= "" then
				if self.tItems["settings"].PopupEnable == 1 then self:PopUpWindowOpen(strName:sub(1, #strName - 1),itemStr) end
				if self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == false then self:RaidProccesNewPieceOfLoot(itemStr,strName:sub(1,#strName-1)) end
			end
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
			elseif strMessage=="!dkpl1" then
				local ID
				for i=1,table.maxn(self.tItems) do
					if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(senderStr) then
						ID=i
						break	
					end
				end
				if ID == nil then 
				   	local strToSend = "/w " .. senderStr .." You don't have an account yet.You will get one once you join your first raid"
					ChatSystemLib.Command( strToSend )
					return
				end
				if self.tItems[ID].logs == nil then
					local strToSend = "/w " .. senderStr .. " No logs to show this time"
					ChatSystemLib.Command( strToSend )
				elseif table.getn(self.tItems[ID].logs) > 5 then 
					for j=1,5 do
						local strToSend = "/w " .. senderStr .. " Log: " .. self.tItems[ID].logs[j].comment .. " Mod: " .. self.tItems[ID].logs[j].modifier
						ChatSystemLib.Command( strToSend )
					end
				elseif table.getn(self.tItems[ID].logs) < 5 then 
					for j=1,table.getn(self.tItems[ID].logs) do
						local strToSend = "/w " .. senderStr .. " Log: " .. self.tItems[ID].logs[j].comment .. " Mod: " .. self.tItems[ID].logs[j].modifier
						ChatSystemLib.Command( strToSend )
					end
				end
			elseif strMessage=="!dkpl2" then
				local ID
				for i=1,table.maxn(self.tItems) do
					if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(senderStr) then
						ID=i
						break	
					end
				end
				if ID == nil then 
				   	local strToSend = "/w " .. senderStr .." You don't have an account yet.You will get one once you join your first raid"
					ChatSystemLib.Command( strToSend )
					return
				end
				if self.tItems[ID].logs == nil then
					local strToSend = "/w " .. senderStr .." No logs to show this time"
					ChatSystemLib.Command( strToSend )
				elseif table.getn(self.tItems[ID].logs) > 5 then 
					for j=6,table.getn(self.tItems[ID].logs) do
						local strToSend = "/w " .. senderStr .. " Log: " .. self.tItems[ID].logs[j].comment .. " Mod: " .. self.tItems[ID].logs[j].modifier
						ChatSystemLib.Command( strToSend )
					end
				else
					local strToSend = "/w " .. senderStr .." There's no 2'nd page of logs , use !dkpl1 instead"
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
				local ID = self:GetPlayerByIDByName(senderStr)
				if ID ~= -1 then
					if self.tItems[ID].GP ~= 0 then
						ChatSystemLib.Command("/w " .. senderStr .. " Your current PR is : " .. tostring(string.format("%."..tostring(self.tItems["settings"].Precision).."f", self.tItems[ID].EP / self.tItems[ID].GP)))
					else
						ChatSystemLib.Command("/w " .. senderStr .. " Your current PR is : 0")
					end
				end
			elseif strMessage == "!top5" then
				if self.tItems["EPGP"].Enable == 1 then 
					local sortedIDs = {}
					for i=1,table.maxn(self.tItems) do
						if self.tItems[i] ~= nil then
							if self.tItems[i].GP ~= 0 then
								table.insert(sortedIDs,{ID = i,value = (self.tItems[i].EP/self.tItems[i].GP)})
							else
								table.insert(sortedIDs,{ID = i,value = 0})
							end
						end
					end
					table.sort(sortedIDs,compare_easyDKP)
					for k , entry in ipairs(sortedIDs) do
						if k > 5 then break end
						if self.tItems[entry.ID].GP ~= 0 then
							ChatSystemLib.Command("/w " .. senderStr .. " " .. k ..". " .. self.tItems[entry.ID].strName .. "   PR:   " .. string.format("%."..tostring(self.tItems["settings"].Precision).."f", self.tItems[entry.ID].EP / self.tItems[entry.ID].GP))
						else
							ChatSystemLib.Command("/w " .. senderStr .. " " .. k ..". " .. self.tItems[entry.ID].strName .. "   PR:    0" )
						end
					end
				else
					local sortedIDs = {}
					for i=1,table.maxn(self.tItems) do
						if self.tItems[i] ~= nil then
								table.insert(sortedIDs,{ID = i,value = self.tItems[i].net})
						end
					end
					table.sort(sortedIDs,compare_easyDKP)
					for k , entry in ipairs(sortedIDs) do
						if k > 5 then break end
						ChatSystemLib.Command("/w " .. senderStr .. " " .. k ..". " .. self.tItems[entry.ID].strName .. "   PR:   " .. string.format("%."..tostring(self.tItems["settings"].Precision).."f", self.tItems[entry.ID].EP / self.tItems[entry.ID].GP))
						
					end
				end
				
			
			end
		end
	end
end


function DKP:CPrint(string)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, string, "")
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

function DKP:Sort( wndHandler, wndControl, eMouseButton )
	local previously_listed = {}
	local previously_listed_index = 1
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and self.tItems[i].listed == 1 then
			self.tItems[i].wnd:Destroy()
			self.tItems[i].listed = 0
			previously_listed[previously_listed_index] = {}
			previously_listed[previously_listed_index].index = i
			if wndControl:GetText() == "Sort by Priority" then
				if self:LabelGetColumnNumberForValue("PR") ~= -1 and self.tItems["EPGP"].Enable == 1 then
					if self.tItems[i].GP ~= 0 then
						previously_listed[previously_listed_index].value = tonumber(string.format("%."..tostring(self.tItems["settings"].Precision).."f",self.tItems[i].EP/self.tItems[i].GP))
					else
						previously_listed[previously_listed_index].value = 0
					end
				else
					if tonumber(self.tItems[i].tot)-tonumber(self.tItems[i].net) ~= 0 then
						previously_listed[previously_listed_index].value = tonumber(string.format("%."..tostring(self.tItems["settings"].Precision).."f",tonumber(self.tItems[i].tot)/(tonumber(self.tItems[i].tot)-tonumber(self.tItems[i].net))))
					else
						previously_listed[previously_listed_index].value = 0
					end
				end
			elseif wndControl:GetText() == "Sort by DKP" then
				previously_listed[previously_listed_index].value = tonumber(self.tItems[i].net)
			end
			previously_listed_index = previously_listed_index + 1
		end
	end
	table.sort(previously_listed,compare_easyDKP)
	for i=1,table.getn(previously_listed) do
		local k = {}
		k.name = self.tItems[previously_listed[i].index].strName
		k.net = self.tItems[previously_listed[i].index].net
		k.tot = self.tItems[previously_listed[i].index].tot
		self.tItems[previously_listed[i].index].listed = 1
		self:AddItem(k,previously_listed[i].index)
	end
	self.wndMain:FindChild("EditBox1"):SetText("Search")
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
		local quickAddButton = self.wndMain:FindChild("Add100DKP")
		setButton:Enable(true)
		addButton:Enable(true)
		subtractButton:Enable(true)
		if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == true then
			quickAddButton:Enable(true)
		end
	end
	if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == false then
		self.wndMain:FindChild("Add100DKP"):Enable(false)
	end
	if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == true and strText ~= "Comment" then
		self.wndMain:FindChild("Add100DKP"):Enable(true)
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
	if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == true and strText ~= "Comment" then
		self.wndMain:FindChild("Add100DKP"):Enable(true)
	end
end

function DKP:ResetInputAndComment()
	local setButton = self.wndMain:FindChild("Controls"):FindChild("ButtonSet")
	local addButton = self.wndMain:FindChild("Controls"):FindChild("ButtonAdd")
	local subtractButton = self.wndMain:FindChild("Controls"):FindChild("ButtonSubtract")
	local quickAddButton = self.wndMain:FindChild("Controls"):FindChild("Add100DKP")
	setButton:Enable(false)
	addButton:Enable(false)
	subtractButton:Enable(false)
	quickAddButton:Enable(false)
end

function DKP:ResetCommentBox( wndHandler, wndControl, strText )
	if strText == "" then
		local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox")
		wndCommentBox:SetText("Comment")
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
		local wndCommentBox = self.wndMain:FindChild("Controls"):FindChild("EditBox1")
		wndCommentBox:SetText("Input Value")
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
	self:ShowAll()
	self.wndMain:FindChild("MassEditControls"):Show(true,true)
	self:EnableActionButtons()
end

function DKP:MassEditDisable( wndHandler, wndControl, eMouseButton )
	self.wndSelectedListItem = nil
	self.MassEdit = false
	self:ShowAll()
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
	local removedIDs = {}
	for k,wnd in ipairs(selectedMembers) do 
		local ID = self:GetPlayerByIDByName(wnd:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("Name"))):GetText())
		if ID ~= -1 then
			self.tItems[ID].wnd:Destroy()
			self.tItems[ID] = nil
			table.insert(removedIDs,k)
		end
	end
	for k,ID in ipairs(removedIDs) do
		table.remove(selectedMembers,ID)
	end
	self:ShowAll()
	for k,wnd in ipairs(selectedMembers) do
		wnd:SetCheck(true)
	end
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
			if self.tItems["settings"].LabelOptions[i] == wndControl:GetText() then
				 self.tItems["settings"].LabelOptions[i] = "Nil"
			end
		end
		self.tItems["settings"].LabelOptions[self.CurrentlyEditedLabel] = wndControl:GetText()
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
	end
	-- Reload List
	self:ShowAll()
	-- Check for priority sorting
	self:LabelUpdateSortingOptions()
	-- Remove prev item selected
	self.wndSelectedListItem = nil 

end

function DKP:LabelAddTooltipByValue(value)
	if value == "Name" then return "Name of Player."
	elseif value == "Net" then return "Current value of player's DKP."
	elseif value == "Tot" then return "Value of DKP that has been earned since account creation."
	elseif value == "Spent" then return "Value of DKP player has spent."
	elseif value == "Hrs" then return "How much time has this player spent Raiding.Only tracked during Rais Session"
	elseif value == "Priority" then return "Value calculated by dividing the Tot value by the Spent Value.AKA Relational DKP."
	elseif value == "EP" then return "Value of player Effort Points."
	elseif value == "GP" then return "Value of player Gear Points."
	elseif value == "PR" then return "Value calculated by dividing the EP value by GP value"
	end
end


function DKP:LabelUpdateSortingOptions()
	local bIsPriority = false
	local bIsDKP = false
	for i=1,5 do
		if self.tItems["settings"].LabelOptions[i] == "Priority" or self.tItems["settings"].LabelOptions[i] == "PR" then
			bIsPriority = true
		end
		if  self.tItems["settings"].LabelOptions[i] == "Net" then
			bIsDKP = true
		end
	end

	
	if bIsPriority == true and bIsDKP == true then
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):Show(true,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSort"):Show(true,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):SetAnchorOffsets(100,395,190,433)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSort"):SetAnchorOffsets(16,395,106,433)
	elseif bIsPriority == true and bIsDKP == false then
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):Show(true,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSort"):Show(false,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):SetAnchorOffsets(16,395,190,433)
	elseif bIsPriority == false and bIsDKP == true then
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):Show(false,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSort"):Show(true,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSort"):SetAnchorOffsets(16,395,190,433)
	elseif bIsDKP == false and bIsPriority == false then
		self.wndMain:FindChild("Controls"):FindChild("ButtonSortPriority"):Show(false,false)
		self.wndMain:FindChild("Controls"):FindChild("ButtonSort"):Show(false,false)
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

function DKP:DecayShowExtension( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("DecayExt"):Show(true,false)
	local l,t,r,b = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(l,t,r+155,b)
end

function DKP:DecayHideExtension( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("DecayExt"):Show(true,false)
	local l,t,r,b = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(l,t,r-155,b)
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
					self:DetailAddLog("Decay",math.floor(self.tItems[i].net * ((100 -self.tItems["settings"].DecayVal) / 100)) - modifier ,i)
					self.tItems[i].net = math.floor(self.tItems[i].net * ((100 -self.tItems["settings"].DecayVal) / 100))
				elseif tonumber(self.tItems[i].net) < 0 and tonumber(self.tItems[i].net) >= tonumber(self.tItems["settings"].DecayTreshold) then
					local val = math.abs(tonumber(self.tItems[i].net))
					local modifier = val
					val = math.floor(val * ((100  + self.tItems["settings"].DecayVal) / 100))
					modifier = val - modifier
					self.tItems[i].net = val * -1
					self:DetailAddLog("Decay",modifier,i)
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
	self.wndMain:FindChild("DecayExt"):FindChild("EditBox"):SetText(self.tItems["settings"].DecayTreshold)
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
	
	self.wndMain:FindChild("DecayExt"):Show(false,true)
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
	if self.wndMain:FindChild("DecayExt"):IsShown() == true then
		self.wndMain:FindChild("DecayExt"):Show(false,false)
		self.wndMain:FindChild("Decay"):FindChild("DecExt"):SetCheck(false)
		local l,t,r,b = self.wndMain:GetAnchorOffsets()
		self.wndMain:SetAnchorOffsets(l,t,r-155,b)
	end
end
---------------------------------------------------------------------------------------------------
-- MemberDetails Functions
---------------------------------------------------------------------------------------------------
function DKP:OnDetailsClose()
	for i=1,table.getn(self.tAlts) do
		self.tAlts[i]:Destroy()
	end
		self.tAlts = nil
		self.tAlts = {}
	for i=1,table.getn(self.tLogs) do
		self.tLogs[i]:Destroy()
	end
		self.tLogs = nil
		self.tLogs = {}
	self.wndDetail:Close()
end

function DKP:DetailShow(strToFind)
	self.wndDetail:Show(true,false)
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if string.lower(self.tItems[i].strName) == string.lower(strToFind) then
				detailedEntryID = i
				break
			end
		end
	end
	if detailedEntryID == nil or detailedEntryID == 0 then
		return
	end
	local wndTitle = self.wndDetail:FindChild("Title")
	wndTitle:SetText("Detailed View : " .. self.tItems[detailedEntryID].strName)
	self.detailItemList = self.wndDetail:FindChild("DetailsList")
	local DoomButton = self.wndDetail:FindChild("ButtonOfDOOM")
	local ButtonConvertConf = self.wndDetail:FindChild("ButtonConvertToAltConf")
	DoomButton:Show(false,false)
	ButtonConvertConf:Show(false,false)
	self.wndDetail:FindChild("BoxAltNameInput"):Show(false,false)
	self.wndDetail:FindChild("ButtonAddAlt"):Show(false,false)
	self.wndDetail:FindChild("ButtonDeleteAlt"):Show(false,false)
	self:DetailShowLogs()
	self.wndDetail:FindChild("ButtonShowAlts"):SetCheck(true)
	self.wndDetail:FindChild("ButtonShowLogs"):SetCheck(false)
	self.wndDetail:FindChild("BoxEditName"):SetText(self.tItems[detailedEntryID].strName)
	if self.tItems["Standby"][string.lower(self.tItems[detailedEntryID].strName)] ~= nil then self.wndDetail:FindChild("Standby"):SetCheck(true) end
end

function DKP:DetailDeleteEntryStart( wndHandler, wndControl, eMouseButton )
	local DoomButton = self.wndDetail:FindChild("ButtonOfDOOM")
	if not DoomButton:IsShown() then 
		DoomButton:Show(true,false)
	else
		DoomButton:Show(false,false)
	end
	
end

function DKP:DetailShowLogs( wndHandler, wndControl, eMouseButton )
	self.wndDetail:FindChild("BoxAltNameInput"):Show(false,false)
	self.wndDetail:FindChild("ButtonAddAlt"):Show(false,false)
	self.wndDetail:FindChild("ButtonDeleteAlt"):Show(false,false)
	for i=1,table.getn(self.tLogs) do
		self.tLogs[i]:Destroy()
	end
		self.tLogs = nil
		self.tLogs = {}
	for i=1,table.getn(self.tAlts) do
		self.tAlts[i]:Destroy()
	end
		self.tAlts = nil
		self.tAlts = {}
	if self.tItems[detailedEntryID].logs == nil then
		local wnd = Apollo.LoadForm(self.xmlDoc, "LogItem", self.detailItemList, self)
		wnd:SetText("NO RECORDS")
		if self.tLogs == nil then
			self.tLogs[1] = wnd
		else
			self.tLogs[table.getn(self.tLogs)+1] = wnd
		end
	else
		for i=1,table.getn(self.tItems[detailedEntryID].logs) do
			local wnd = Apollo.LoadForm(self.xmlDoc, "LogItem", self.detailItemList, self)
			local comment = self.tItems[detailedEntryID].logs[i].comment
			local modifier = self.tItems[detailedEntryID].logs[i].modifier
			wnd:FindChild("Comment"):SetText(comment)
			wnd:FindChild("Modifier"):SetText(modifier)
			if self.tLogs == nil then
				self.tLogs[1] = wnd
			else
				self.tLogs[table.getn(self.tLogs)+1] = wnd
			end
		end
	end
	self.detailItemList:ArrangeChildrenVert()
end

function DKP:DetailShowAlts( wndHandler, wndControl, eMouseButton )
	self.wndDetail:FindChild("BoxAltNameInput"):Show(true,false)
	self.wndDetail:FindChild("ButtonAddAlt"):Show(true,false)
	self.wndDetail:FindChild("ButtonDeleteAlt"):Show(true,false)
	for i=1,table.getn(self.tAlts) do
		self.tAlts[i]:Destroy()
	end
		self.tAlts = nil
		self.tAlts = {}
	for i=1,table.getn(self.tLogs) do
		self.tLogs[i]:Destroy()
	end
		self.tLogs = nil
		self.tLogs = {}
	if self.tItems[detailedEntryID].alts == nil then
		local wnd = Apollo.LoadForm(self.xmlDoc, "AltItem", self.detailItemList, self)
		wnd:SetText("NO RECORDS")
		if self.tAlts == nil then
			self.tAlts[1] = wnd
		else
			self.tAlts[table.getn(self.tAlts)+1] = wnd
		end
	else
		for i=1,table.getn(self.tItems[detailedEntryID].alts) do
			if self.tItems[detailedEntryID].alts[i].strName ~= -1 then
				local wnd = Apollo.LoadForm(self.xmlDoc, "AltItem", self.detailItemList, self)
				wnd:SetText(self.tItems[detailedEntryID].alts[i].strName)
				if self.tAlts == nil then
					self.tAlts[1] = wnd
				else
					self.tAlts[table.getn(self.tAlts)+1] = wnd
				end
			end
		end
	end
	self.detailItemList:ArrangeChildrenVert()
end

function DKP:DetailConvertEntryToAlt( wndHandler, wndControl, eMouseButton )
	local DoomButton = self.wndDetail:FindChild("ButtonConvertToAltConf")
	if not DoomButton:IsShown() then 
		DoomButton:Show(true,false)
	else
		DoomButton:Show(false,false)
	end	

end

function DKP:DetailAddAltByName(wndHandler, wndControl, eMouseButton,name,holder_ID )
	local wndNameInputBox = self.wndDetail:FindChild("BoxAltNameInput")
	local strName = wndNameInputBox:GetText()	

	if self.tItems["settings"].lowercase == 1 then strName = string.lower(strName) end
	
	if strName ~= "Input Name" then
		wndNameInputBox:SetText("Input Name")
		for i=1,table.maxn(self.tItems) do
			if string.lower(self.tItems[i].strName) == string.lower(strName) then
				Print("Player already exists in database, convert or delete this entry")
				return
			end
		end
		
		if self.tItems[detailedEntryID].alts == nil then
			self.tItems[detailedEntryID].alts = {}
			self.tItems[detailedEntryID].alts[1] = {}
			self.tItems[detailedEntryID].alts[1].strName = strName
			self.tItems[detailedEntryID].alts[1].altsTablePos = table.getn(self.tItems["alts"])+1
			self.tItems["alts"][strName] = detailedEntryID 
		else
			for i=1,table.getn(self.tItems[detailedEntryID].alts) do
				if string.lower(self.tItems[detailedEntryID].alts[i].strName) == string.lower(strName) then
					Print("Alt with the same name already exist, check your spelling")
					return
				end
			end
			self.tItems[detailedEntryID].alts[table.getn(self.tItems[detailedEntryID].alts)+1] = {}
			self.tItems[detailedEntryID].alts[table.getn(self.tItems[detailedEntryID].alts)].strName = strName
			self.tItems[detailedEntryID].alts[table.getn(self.tItems[detailedEntryID].alts)].altsTablePos = table.getn(self.tItems["alts"])+1
			
			self.tItems["alts"][strName] = detailedEntryID
			end
		end
		self:DetailShowAlts()
		
end
function DKP:DetailAddAltByNameA(name,holder_ID )
	local strName = name
	detailedEntryID = holder_ID

	if strName ~= "Input Name" then
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(strName) then
				Print("Player already exists in database, convert or delete this entry")
				return
			end
		end
		
		if self.tItems[detailedEntryID].alts == nil then
			self.tItems[detailedEntryID].alts = {}
			self.tItems[detailedEntryID].alts[1] = {}
			self.tItems[detailedEntryID].alts[1].strName = strName
			self.tItems[detailedEntryID].alts[1].altsTablePos = table.getn(self.tItems["alts"])+1
			self.tItems["alts"][strName] = detailedEntryID 
		else
			for i=1,table.getn(self.tItems[detailedEntryID].alts) do
				if string.lower(self.tItems[detailedEntryID].alts[i].strName) == string.lower(strName) then
					Print("Alt with the same name already exist, check your spelling")
					return
				end
			end
			self.tItems[detailedEntryID].alts[table.getn(self.tItems[detailedEntryID].alts)+1] = {}
			self.tItems[detailedEntryID].alts[table.getn(self.tItems[detailedEntryID].alts)].strName = strName
			self.tItems[detailedEntryID].alts[table.getn(self.tItems[detailedEntryID].alts)].altsTablePos = table.getn(self.tItems["alts"])+1
			
			self.tItems["alts"][strName] = detailedEntryID
			end
		end
		if name == nil then
			self:DetailShowAlts()
		end
		
end

function DKP:DetailDeleteAltByName( wndHandler, wndControl, eMouseButton )
	local wndNameInputBox = self.wndDetail:FindChild("BoxAltNameInput")
	local strName = wndNameInputBox:GetText()
	if strName ~= "Input Name" then
			wndNameInputBox:SetText("Input Name")
		if self.tItems["alts"][strName] ~= nil and self.tItems["alts"][strName] ~= -1 then
			local ID = self.tItems["alts"][strName]
			local alts_ID = nil
			for i=1,table.getn(self.tItems[ID].alts) do
				if string.lower(self.tItems[ID].alts[i].strName) == string.lower(strName) then
					alts_ID = i
					break
				end
			end
			if alts_ID ~= nil then
				self.tItems[ID].alts[alts_ID].strName = -1
				self.tItems["alts"][strName] = nil
			else
				Print("No such an entry , check your spelling")
			end
		end
		self:DetailShowAlts()
	end
end
	
function DKP:DetailDeleteEntryFinish( wndHandler, wndControl, eMouseButton )
	self.tItems[detailedEntryID].wnd:Destroy()
	self.tItems[detailedEntryID] = nil
	self:OnDetailsClose()
	if self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):IsChecked() == true then
		self:ForceRefresh()
	else
		self:ShowAll()
	end
	self.wndSelectedListItem = nil
end

function DKP:DetailConvertToAltConfirmed( wndHandler, wndControl, eMouseButton )
	local holderName = self.wndDetail:FindChild("BoxAltOwnerNameInput"):GetText()
	local playerExists = 0
	local holderID
	if holderName ~= nil then
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(holderName) then
				playerExists = 1
				holderID = i
				break
			end
		end
	end
	
	if playerExists == 1 then
		local saveID = detailedEntryID
		local name = self.tItems[detailedEntryID].strName
		self:DetailDeleteEntryFinish()
		self:DetailAddAltByNameA(name,holderID)
		detailedEntryID = saveID
	else
		Print("No specified player in database")
	end
end

function DKP:DetailAddLog(comment,modifier,ID)
	if self.tItems["settings"].logs == 1 then
		if self.tItems[ID].logs == nil then
			self.tItems[ID].logs = {}
			local i = {}
			if self.tItems["settings"].forceCheck == 1 and self.ItemDatabase ~= nil and self.ItemDatabase[comment] ~= nil and self.ItemDatabase[comment].ID ~= nil then comment = comment .. "  {" ..self.ItemDatabase[comment].ID .. "}" end
			i.comment = comment
			if tonumber(modifier) < 0 then
				i.modifier = tostring(modifier)
			elseif tonumber(modifier) > 0 then
				i.modifier = "+" .. tostring(modifier)
			end
			table.insert(self.tItems[ID].logs,1,i)
		else
			local i = {}
			i.comment = comment
			if tonumber(modifier) < 0 then
				i.modifier = tostring(modifier)
			elseif tonumber(modifier) > 0 then
				i.modifier = "+" .. tostring(modifier)
			end
			table.insert(self.tItems[ID].logs,1,i)
			if table.getn(self.tItems[ID].logs) > 10 then 
				table.remove(self.tItems[ID].logs)
			end
		end
	end
end

function DKP:DetailChangeName( wndHandler, wndControl, strText )
	local found = false
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and self.tItems[i].strName == strText then 
			found = true 
			break
		end
	end

	if found == false then
		self.tItems[detailedEntryID].strName = strText
		self.tItems[detailedEntryID].wnd:FindChild("PlayerName"):SetText(strText)
		self.wndDetail:FindChild("Title"):SetText("Detailed View : " .. self.tItems[detailedEntryID].strName)
	else
		wndControl:SetText(self.tItems[detailedEntryID].strName)
	end
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

function DKP:HelloImHome()
	-- self.SpyChannel = ICCommLib.JoinChannel( "EasyDKPShareChannel","OnNothing",self)
	-- self.SpyChannel:SendMessage({name = GameLib.GetPlayerUnit():GetName() or "unknown"})
	-- self.SyncChannel = nil 
end

function DKP:OnNothing(channel, tMsg, strSender)
	--Print(tMsg.name)
end

function DKP:SettingsSetQuickDKP( wndHandler, wndControl, eMouseButton )
	local value = self.wndSettings:FindChild("EditBoxQuickAdd"):GetText()
	self.tItems["settings"].dkp = tonumber(value)
	
	self:ControlsUpdateQuickAddButtons()
end

function DKP:SettingsSetGuildname( wndHandler, wndControl, eMouseButton )
	local strName = self.wndSettings:FindChild("EditBoxGuldName"):GetText()
	self.tItems["settings"].guildname = strName
	
	--local wndTitle = self.wndMain:FindChild("Title"):SetText("EasyDKP - " .. strName)
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
	self.wndMain:FindChild("Controls"):FindChild("ButtonShowCurrentRaid"):SetCheck(true)
	if self.tItems["removed"] ~= nil then removed = self.tItems["removed"] end
	
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
	self.SyncChannel = ICCommLib.JoinChannel( "EasyDKPFetchChannel","OnChannelNameFetchResponse",self)
	self.wndSettings:FindChild("EditBoxFetchedName"):Enable(true)
	self.wndSettings:FindChild("ButtonSettingsFetchData"):Enable(true)
end

function DKP:SettingsDisableSync( wndHandler, wndControl, eMouseButton )
	self.SyncChannel = nil
	self.PrivateSyncChannel = nil
	server = nil
	client = nil
	self.wndSettings:FindChild("EditBoxFetchedName"):Enable(false)
	self.wndSettings:FindChild("ButtonSettingsFetchData"):Enable(false)
end
function DKP:OnChannelNameFetchResponse(channel, tMsg, strSender)
	if tMsg.type == "FetchName" then
		Print("RecvN")
		if tMsg.fetchedName == GameLib.GetPlayerUnit():GetName() then
			local MSG = {}
			MSG.type = "FetchNameResponse"
			MSG.val = true
			self.PrivateSyncChannel = ICCommLib.JoinChannel( "EasyDKPSync","OnChannelReadyToExchange",self)
			self.SyncChannel:SendMessage(MSG)
			server = true
			client = false
		end
	end
	if tMsg.type == "FetchNameResponse" then
		Print("RecvR")
		if tMsg.val == true then
			self.PrivateSyncChannel = ICCommLib.JoinChannel( "EasyDKPSync","OnChannelReadyToExchange",self)
			local MSG = {}
			MSG.type = "ReadyToSync"
			MSG.val = true
			self.PrivateSyncChannel:SendMessage(MSG)
			client = true
			server = false
		end
	end
end

function DKP:OnChannelReadyToExchange(channel, tMsg, strSender)
	if client == true then
		Print("data received")
		if tMsg.type == "SyncedData" then
			local prev_settings = self.tItems["settings"]
			for i=1,table.maxn(self.tItems) do
				self.tItems[i].wnd:Destroy()
				self.tItems[i].wnd = nil
			end
			self.tItems = tMsg
			self.tItems["settings"] = prev_settings
			self.tItems.type = nil
			self.PrivateSyncChannel = nil
			self:ForceRefresh()
			self:ShowAll()
			counter = table.getn(self.tItems)+1
		end
	end
	if server == true then
		Print("sending data")
		if tMsg.type == "ReadyToSync" then
			if tMsg.val == true then
				self.tItems.type = "SyncedData"
				local MSG = self.tItems
				for i=1,table.maxn(self.tItems) do 
					MSG[i].wnd = nil
					MSG[i].listed = 0
				end
				MSG["settings"] = nil
				self.PrivateSyncChannel:SendMessage(MSG)
				self.PrivateSyncChannel = nil
			end
		end
	end
end
function DKP:SettingsFetchData( wndHandler, wndControl, eMouseButton )
	local fetchedNameStr = self.wndSettings:FindChild("EditBoxFetchedName"):GetText()
	local MSG = {}
	MSG.type = "FetchName"
	MSG.fetchedName = fetchedNameStr
	local succes = self.SyncChannel:SendMessage(MSG)
	if succes == true then 
		Print("succes")
	end
	if succes == false then
		Print("failure")
	end
	Print("If "..fetchedNameStr.." is found the data will be Synced")
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

function DKP:SettingsEnableFilter( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].CheckAffiliation = 1
end

function DKP:SettingsDisableFilter( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].CheckAffiliation = 0
end

function DKP:SettingsSetPrecision( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) ~= self.tItems["settings"].Precision then
		self.tItems["settings"].Precision = math.floor(fNewValue)
		self:ShowAll()
	end
end

---------------------------------------------------------------------------------------------------
-- Export Functions
---------------------------------------------------------------------------------------------------

function DKP:ExportExport( wndHandler, wndControl, eMouseButton )
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
			if #formatedTable[self.tItems[i].strName]["Logs"] < 1 then formatedTable[self.tItems[i].strName]["Logs"] = nil end
		end
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
			end
			if #formatedTable[self.tItems[i].strName]["Logs"] < 1 then formatedTable[self.tItems[i].strName]["Logs"] = nil end
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
	if self.wndPopUp:FindChild("EditBoxDKP"):GetText() == "X" then return end
	local newDKP
	local modifier
	if self.tItems["EPGP"].Enable == 0 then
		modifier = tonumber(self.tItems[CurrentPopUpID].net)
		newDKP = tostring(tonumber(self.tItems[CurrentPopUpID].net)-math.abs(tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())))
		if self.tItems[CurrentPopUpID].listed == 1 then
			self.tItems[CurrentPopUpID].wnd:FindChild("Net"):SetText(newDKP)
		end
		modifier = tostring(tonumber(newDKP) - modifier)
		self.tItems[CurrentPopUpID].net = newDKP
		self:DetailAddLog(self.wndPopUp:FindChild("LabelItem"):GetText(),modifier,CurrentPopUpID)
	else
		self:EPGPSubtract(self.tItems[CurrentPopUpID].strName,nil,tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText()))
		if self:LabelGetColumnNumberForValue("GP") ~= -1 and self.tItems[CurrentPopUpID].wnd ~= nil then
			self.tItems[CurrentPopUpID].wnd:FindChild("Stat"..tostring(self:LabelGetColumnNumberForValue("GP"))):SetText(self.tItems[CurrentPopUpID].GP)
		end
		self:DetailAddLog(self.wndPopUp:FindChild("LabelItem"):GetText(),tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())*-1,CurrentPopUpID)
	end
	if self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == false then
		self:RaidAddCostInfo(PopUpItemQueue[1].strItem,PopUpItemQueue[1].strName,tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())*-1)
	elseif self.bIsRaidSession == true and self.wndRaidOptions:FindChild("Button1"):IsChecked() == true then 
		self:RaidProccesNewPieceOfLoot(PopUpItemQueue[1].strItem,PopUpItemQueue[1].strName)
		self:RaidAddCostInfo(PopUpItemQueue[1].strItem,PopUpItemQueue[1].strName,tonumber(self.wndPopUp:FindChild("EditBoxDKP"):GetText())*-1)
	end
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
		if self.tItems["EPGP"].Enable == 1 then
			self.wndPopUp:FindChild("Currency"):SetText("GP")
			if self.ItemDatabase[PopUpItemQueue[i].strItem] ~= nil then
				self.wndPopUp:FindChild("EditBoxDKP"):SetText(EPGPGetItemCostByName(PopUpItemQueue[1].strItem))
			end
		else
			self.wndPopUp:FindChild("Currency"):SetText("DKP")
		end
		CurrentPopUpID = PopUpItemQueue[1].ID
		if self.RegistredBidWinners[PopUpItemQueue[1].strItem].cost ~= nil then
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(self.RegistredBidWinners[PopUpItemQueue[1].strItem].cost)
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
		table.insert(PopUpItemQueue,1,item)
		if CurrentPopUpID == nil then --First Iteration
			self.wndPopUp:FindChild("LabelName"):SetText(strName)
			self.wndPopUp:FindChild("LabelItem"):SetText(strItem)
			CurrentPopUpID = ID_popup
		end
		if self.RegistredBidWinners[PopUpItemQueue[1].strItem].cost ~= nil  then
			self.wndPopUp:FindChild("EditBoxDKP"):SetText(self.RegistredBidWinners[PopUpItemQueue[1].strItem].cost)
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
	if detailedEntryID ~= 0 and detailedEntryID ~= nil  then
		if detailedEntryID == self:GetPlayerByIDByName(strText) then self.wndDetail:FindChild("Standby"):SetCheck(true) end
	end
end

function DKP:StandbyListRemove( wndHandler, wndControl, eMouseButton )
	for k,item in ipairs(selectedStandby) do
		self.tItems["Standby"][string.lower(item)] = nil
	end
	self:StandbyListPopulate()
	if detailedEntryID ~= 0 and detailedEntryID ~= nil then
		if self.tItems["Standby"][string.lower(self.tItems[detailedEntryID].strName)] == nil then self.wndDetail:FindChild("Standby"):SetCheck(false) end
	end
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
-- DKP Instance
-----------------------------------------------------------------------------------------------
local DKPInst = DKP:new()
DKPInst:Init()