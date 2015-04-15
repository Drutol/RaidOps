-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2014 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

--MODULE
local DKP = Apollo.GetAddon("RaidOps")

local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrNormalText = ApolloColor.new("ChannelAdvice")



 --[[
 Player : 
 name -> str
 dkpMod -> int
 bLeft -> bool
 tClaimedLoot -> table
			name-> string
			dkp -> int
 ]]
local tAllRaidMembersInSession = {}
function DKP:RaidInit()
	
	--Tables
	self.tRaidListItems = {}
	self.tPlayersRaidItems = {}
	self.tLootItems = {}
	

	--Windows
	self.wndRaidSummary = Apollo.LoadForm(self.xmlDoc, "RaidSummary" , nil ,self)
	self.wndRaidSelection = Apollo.LoadForm(self.xmlDoc, "RaidSelect",nil , self)
	self.wndRaidTools = Apollo.LoadForm(self.xmlDoc,"RaidTools",nil,self)
	self.wndRaidGlobalStats = Apollo.LoadForm(self.xmlDoc,"RaidGlobalSummary",nil,self)
	self.wndRaidOptions = self.wndRaidSelection:FindChild("OptionsContainer")
	self.wndRaidTools:Show(false,true)
	self.wndRaidGlobalStats:Show(false,true)
	self.wndRaidSummary:Show(false,true)
	self.wndRaidSelection:Show(false,true)
	self.wndRaidOptions:Show(false,true)
	
	--ItemLists
	self.wndRaidList = self.wndRaidSelection:FindChild("RaidContainer"):FindChild("RaidSelectionList")
	self.wndRaidSummaryList = self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("RaidItems")

	
	--Settings
	if self.tItems["settings"].RaidMsg == nil  then self.tItems["settings"].RaidMsg = 1 end
	if self.tItems["settings"].RaidMsg == 1 then self.wndRaidOptions:FindChild("Button"):SetCheck(true)
	elseif self.tItems["settings"].RaidMsg == 0 then self.wndRaidOptions:FindChild("Button"):SetCheck(false) end
	
	if self.tItems["settings"].RaidTimer == nil  then self.tItems["settings"].RaidTimer = 10 end
	self.wndRaidOptions:FindChild("EditBox"):SetText(self.tItems["settings"].RaidTimer)
	
	if self.tItems["settings"].RaidItemTrack == nil then self.tItems["settings"].RaidItemTrack = 0 end
	if self.tItems["settings"].RaidItemTrack == 1 then self.wndRaidOptions:FindChild("Button1"):SetCheck(true)
	elseif self.tItems["settings"].RaidItemTrack == 0 then self.wndRaidOptions:FindChild("Button1"):SetCheck(false) end
	
	if self.tItems["settings"].RaidLeaveTimer == nil then self.tItems["settings"].RaidLeaveTimer = 300 end
	self.wndRaidOptions:FindChild("EditBox1"):SetText(self.tItems["settings"].RaidLeaveTimer)
	--if self.tItems["settings"].NewStartup == nil then self.tItems["settings"].RaidTools = nil end
	if self.tItems["settings"].RaidTools == nil then self.tItems["settings"].RaidTools = {l=0,t=4,r=269,b=288,opacityOn = 1,opacityOff = 0.5,show = 0 } end
	self.wndRaidTools:SetAnchorOffsets(self.tItems["settings"].RaidTools.l,self.tItems["settings"].RaidTools.t,self.tItems["settings"].RaidTools.r,self.tItems["settings"].RaidTools.b)
	self.wndRaidTools:FindChild("ButtonMassAdd"):Enable(false)
	self.wndRaidTools:FindChild("ButtonShowSummary"):Enable(false)
	self:RaidToolsDecreaseOpacity()
	if self.tItems["settings"].RaidTools.show == 1 then self.wndRaidTools:Show(true,false) end


	
	if self.tItems["settings"].RaidOfflineTimer == nil then self.tItems["settings"].RaidOfflineTimer = 3600 end
	self.wndRaidOptions:FindChild("EditBox2"):SetText(self.tItems["settings"].RaidOfflineTimer)
	
	
	--Resume
	self.bIsRaidSession = false
	if self.tItems["Raids"]["Save"] ~= nil then
		self:RaidResumeSession()
	end
	
	--Misc
	self:RaidPopulateLists("Raids")
	self.RaidPrevSelection = nil
	self:RaidGlobalStatsPushData()
	--table.insert(self.tItems["Raids"][2].tPlayers[1].tClaimedLoot,{name =  "Very Weapon" , dkp = 999})
end




function compare_easyDKP_date(a,b)
  return a > b
end

function compare_easyDKP_name(a,b)
  return a < b
end
local currentRaidID = nil 
function DKP:RaidPopulateLists(which) -- , Raids 
	local tableIDsOrder = {}
	
	
	if self.wndRaidSelection:FindChild("ButtonOrderByDate"):IsChecked() == true then
		for i=1,table.maxn(self.tItems["Raids"]) do
			if self.tItems["Raids"][i] ~= nil then
				table.insert(tableIDsOrder,self.tItems["Raids"][i].date.osDate)
			end
		end
		table.sort(tableIDsOrder,compare_easyDKP_date)
		for i=1, table.getn(tableIDsOrder) 	do
			for j=1,table.maxn(self.tItems["Raids"]) do
				if self.tItems["Raids"][j]~= nil and tableIDsOrder[i] == self.tItems["Raids"][j].date.osDate then 
					tableIDsOrder[i] = j 
					break
				end
			end
		end
		
	elseif self.wndRaidSelection:FindChild("ButtonOrderByName"):IsChecked() == true then
		for i=1,table.maxn(self.tItems["Raids"]) do
			if self.tItems["Raids"][i] ~= nil then
				table.insert(tableIDsOrder,self.tItems["Raids"][i].name)
			end
		end
		table.sort(tableIDsOrder,compare_easyDKP_name)
		for i=1, table.getn(tableIDsOrder) 	do
			for j=1,table.maxn(self.tItems["Raids"]) do
				if self.tItems["Raids"][j]~= nil and  tableIDsOrder[i] == self.tItems["Raids"][j].name then 
					tableIDsOrder[i] = j
					break
				end
			end
		end
		
	end
	
	
	
	if which == "Raids" then
		self:RaidPurgeItemTable(self.tRaidListItems)
		if self.tItems["Raids"] == nil  or table.maxn(self.tItems["Raids"]) < 1 then -- No Records
			self.tItems["Raids"] = {}
			local wnd = Apollo.LoadForm(self.xmlDoc, "RaidItem", self.wndRaidList, self)
			wnd:FindChild("RaidName"):SetText("No records")
			wnd:FindChild("Button"):Enable(false)
			wnd:FindChild("CurrentRaid"):Show(false,false)
			table.insert(self.tRaidListItems,wnd)
			self.wndRaidList:ArrangeChildrenVert()
		else 	
			for i=1,table.getn(tableIDsOrder) do -- Found Records
				local wnd = Apollo.LoadForm(self.xmlDoc, "RaidItem", self.wndRaidList, self)
				wnd:FindChild("RaidName"):SetText(self.tItems["Raids"][tableIDsOrder[i]].name) 
				wnd:FindChild("RaidDate"):SetText(self.tItems["Raids"][tableIDsOrder[i]].date.strDate)
				wnd:FindChild("CurrentRaid"):Show(false,false)
				if self.tItems["Raids"][tableIDsOrder[i]].Raid == "Datascape" then
					wnd:FindChild("GA"):Show(false,true)
					wnd:FindChild("DS"):Show(false,true)
				else	
					wnd:FindChild("GA"):Show(true,true)
					wnd:FindChild("DS"):Show(false,true)
				end
				wnd:FindChild("Progress"):SetText(#self.tItems["Raids"][tableIDsOrder[i]].tMisc.tBossKills.names)
				if self.bIsRaidSession == true and currentRaidID == tableIDsOrder[i] then 
					wnd:FindChild("Button"):Enable(false)
					wnd:FindChild("CurrentRaid"):Show(true,false)
				end
				
				table.insert(self.tRaidListItems,wnd)
				self.wndRaidList:ArrangeChildrenVert()
			end
		end
	end
end

function DKP:RaidRemoveEntry(wndHandler,wndControl,eMouseButton)
	local name = wndControl:GetParent():FindChild("RaidName"):GetText()
	local ID
	for i=1,table.maxn(self.tItems["Raids"]) do
		if currentRaidID == i then self.wndRaidSummary:Show(false,false) end
		if self.tItems["Raids"][i] ~= nil and self.tItems["Raids"][i].name == name then
			self.tItems["Raids"][i] = nil
			break
		end
		
	end
	self:RaidPopulateLists("Raids")
end

function DKP:RaidPurgeItemTable(tData)
	if tData ~= nil then
		for i=1,table.getn(tData) do
			tData[i]:Destroy()
		end
	end
end

function DKP:RaidShowMainWindow()
	self.wndMain:Show(false,false)
	self.wndRaidSelection:Show(true,false)
	self.wndRaidSelection:ToFront()
	self.wndRaidSelection:FindChild("ControlsContainer"):FindChild("ButtonOrderByDate"):SetCheck(false)
	self.wndRaidSelection:FindChild("ControlsContainer"):FindChild("ButtonOrderByName"):SetCheck(true)
	self:RaidPopulateLists("Raids")

	
end

function DKP:RaidSubmitSession()
	if currentRaidID ~= nil then
		self:RaidRunMiscSummaries(currentRaidID)
		self.tItems["Raids"][currentRaidID].tPlayers = tAllRaidMembersInSession
		
		for k,player in ipairs(tAllRaidMembersInSession) do
			local ID = self:GetPlayerByIDByName(player.name)
			if ID ~= -1 then
				if self.tItems[ID].raids then self.tItems[ID].raids = self.tItems[ID].raids + 1 else self.tItems[ID].raids = 1 end	
			end
		end
		if self:LabelGetColumnNumberForValue("Raids") ~= - 1 then self:LabelUpdateList() end
		tAllRaidMembersInSession = {}
		self.bIsRaidSession = false
		if self.RaidTimer ~= nil then
			self.RaidTimer:Stop()
		end
		self:RaidProcessLeftTimers()
		self.wndRaidSummary:Show(false,false)
		self:RaidShowMainWindow()
		Apollo.RemoveEventHandler("CombatLogDamage", self)
		currentRaidID = nil 
		self.tItems["Raids"]["Save"] = nil
		self.wndRaidTools:FindChild("ButtonMassAdd"):Enable(false)
		self.wndRaidTools:FindChild("ButtonShowSummary"):Enable(false)
		self.wndRaidTools:FindChild("RaidName"):FindChild("NameField"):SetText("----")
		self.wndRaidTools:FindChild("RaidDuration"):FindChild("NameField"):SetText("----")
		if self.tItems["settings"].Decay == 1 then self:Decay() end
	end
end

function DKP:RaidProcessLeftTimers()
	for i=1,#self.tItems["Raids"][currentRaidID].tPlayers do
		if self.tItems["Raids"][currentRaidID].tPlayers[i].bLeft ~= "!Left" and self.tItems["Raids"][currentRaidID].tPlayers[i].bLeft ~= "Left" then
			self.tItems["Raids"][currentRaidID].tPlayers[i].bLeft = "!Left"
		end
	end
end


function DKP:RaidResumeSession()
	self:BidUpdateItemDatabase()
	currentRaidID = self.tItems["Raids"]["Save"].ID
	self.bIsRaidSession = true
	tAllRaidMembersInSession = self.tItems["Raids"]["Save"].allPlayers
	self.tItems["Raids"][currentRaidID].tPlayers = self.tItems["Raids"]["Save"].tPlayers
	self.tItems["Raids"][currentRaidID].tMisc = self.tItems["Raids"][currentRaidID].tMisc
	self.tItems["Raids"][currentRaidID].date = self.tItems["Raids"]["Save"].date
	self.tItems["Raids"][currentRaidID].Raid = self.tItems["Raids"]["Save"].Raid
	self.tItems["Raids"][currentRaidID].RaidSure = self.tItems["Raids"]["Save"].RaidSure
	local diff = os.difftime(os.time()-self.tItems["Raids"][currentRaidID].date.resDate)

	self.tItems["Raids"][currentRaidID].name = self.tItems["Raids"]["Save"].name
	Apollo.RegisterEventHandler("CombatLogDamage","RaidOnUnitDestroyed", self)
	self.wndRaidSummary:Show(true,false)
	self:RaidUpdateSummary({name = self.tItems["Raids"][currentRaidID].name , date = { strDate = self.tItems["Raids"][currentRaidID].date.strDate}})

	self:RaidUpdateCurrentRaidSession(currentRaidID)
	self.tItems["Raids"][currentRaidID].misc = 1
	self.wndRaidTools:FindChild("ButtonMassAdd"):Enable(true)
	self.wndRaidTools:FindChild("ButtonShowSummary"):Enable(true)
	if diff >= self.tItems["settings"].RaidOfflineTimer then
		Print("You have been offline for more than specified time.Raid Session will be now submitted")
		self.wndRaidSummary:Show(false,true)
		self:RaidSubmitSession()
		return
	end
	self.RaidTimer = ApolloTimer.Create(self.tItems["settings"].RaidTimer,true,"RaidUpdateCurrentRaidSession",self)
	--Date check
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("Window1"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonPlayers"):SetCheck(true)
	self:RaidUpdateSummaryPlayerDetails()

	
	--Date Check
	--self.tItems["Raids"]["Save"] = nil
end

function DKP:RaidBackupSession()
	self.tItems["Raids"]["Save"] = {}
	self.tItems["Raids"]["Save"].allPlayers = tAllRaidMembersInSession
	self.tItems["Raids"]["Save"].tPlayers = self.tItems["Raids"][currentRaidID].tPlayers
	self.tItems["Raids"]["Save"].name = self.tItems["Raids"][currentRaidID].name
	self.tItems["Raids"]["Save"].date = self.tItems["Raids"][currentRaidID].date
	self.tItems["Raids"]["Save"].date.resDate = os.time()
	self.tItems["Raids"]["Save"].tMisc = self.tItems["Raids"][currentRaidID].tMisc
	self.tItems["Raids"]["Save"].ID = currentRaidID
	self.tItems["Raids"]["Save"].Raid = self.tItems["Raids"][currentRaidID].Raid
	self.tItems["Raids"]["Save"].RaidSure = self.tItems["Raids"][currentRaidID].RaidSure
end

local tBossItems = {}
function DKP:RaidOpenSummary(RaidName)
	if RaidName ~= nil then
		if RaidName == "New" then
			local curr_date = os.date("*t",os.time())
			local tData = {}
			tData.name = "SET NAME"..table.maxn(self.tItems["Raids"])
			tData.date ={}
			tData.date.strDate = tostring(curr_date.day) .."/".. tostring(curr_date.month) .."/".. tostring(curr_date.year)
			tData.date.osDate = os.time()
			tData.tPlayers = {}
			tData.tMisc = {}
			tData.Raid = self:RaidAssumeRaid()
			tData.RaidSure = false
			tData.tMisc.tBossKills = {}
			tData.tMisc.tBossKills.count = 0
			tData.tMisc.tBossKills.names = {}
			tData.tMisc.tBossKills.prototype1 = 0
			tData.tMisc.tBossKills.prototype2 = 0
			tData.tMisc.tBossKills.prototype3 = 0
			tData.tMisc.tBossKills.prototype4 = 0
			tData.tMisc.tBossKills.converCount = 0
			tData.tMisc.tBossKills.elementals = 0
			tData.tMisc.tBossKills.pairs = {}
			tData.misc = 0
			tData.FirstIteration = true
			table.insert(self.tItems["Raids"],tData)
			tAllRaidMembersInSession = {}
			currentRaidID = table.maxn(self.tItems["Raids"])
			self.RaidTimer = ApolloTimer.Create(self.tItems["settings"].RaidTimer, true, "RaidUpdateCurrentRaidSession", self)
			self.bIsRaidSession = true
			self:RaidUpdateSummary(tData)
			self.wndRaidSummary:Show(true,false)
			self.wndRaidSummary:ToFront()
			self:RaidUpdateCurrentRaidSession()
			self.wndRaidSummary:FindChild("ButtonSubmit"):Enable(true)
			self.wndRaidTools:FindChild("ButtonMassAdd"):Enable(true)
			self.wndRaidTools:FindChild("ButtonShowSummary"):Enable(true)
			--Handlers
			Apollo.RegisterEventHandler("CombatLogDamage","RaidOnUnitDestroyed", self)
		elseif RaidName == "No records" then return
		else
			currentRaidID = self:RaidGetRaidIdByName(RaidName)
			if currentRaidID == nil then 
				Print("Error processing raid")
				return 
			end
			local tData = {}
			tData.name = self.tItems["Raids"][currentRaidID].name
			tData.date = self.tItems["Raids"][currentRaidID].date
			tData.tPlayers = self.tItems["Raids"][currentRaidID].tPlayers
			tData.misc = 1 
			tData.len = self.tItems["Raids"][currentRaidID].tMisc.length
			tData.loot = self.tItems["Raids"][currentRaidID].tMisc.lootcount
			tData.players = self.tItems["Raids"][currentRaidID].tMisc.allPlayersCount
			self.wndRaidSummary:FindChild("ButtonPlayers"):SetCheck(true)
			self:RaidUpdateSummaryPlayerDetails()
			self:RaidUpdateSummary(tData)
			self.wndRaidSummary:Show(true,false)
			self.wndRaidSummary:FindChild("ButtonSubmit"):Enable(false)
			self:RaidPurgeItemTable(tBossItems)
			if self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count ~= nil and #self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names  then
				for i=1,#self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names do
					local wnd = Apollo.LoadForm(self.xmlDoc,"BossItem",self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("KilledBossesList"),self)
					wnd:FindChild("BossName"):SetText(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names[i])
					table.insert(tBossItems,wnd)
				end
				self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("KilledBossesList"):ArrangeChildrenVert()
			end
		end
		self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):Show(false,true)
		self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("Window1"):Show(false,true)
		
	end
end

function DKP:RaidGoHub()
	self.wndRaidSummary:Show(false,false)
	self.wndRaidGlobalStats:Show(false,false)
	self.wndRaidSelection:Show(false,false)
	self.wndHub:Show(true,false)
end

function DKP:RaidRegisterDkpManipulation(strName,modifier)
	if self.tItems["settings"].lowercase == 1 then
		strName = string.lower(strName)
	end
	for i=1,table.getn(tAllRaidMembersInSession) do
		if string.lower(tAllRaidMembersInSession[i].name) == string.lower(strName) then
			tAllRaidMembersInSession[i].dkpMod = tAllRaidMembersInSession[i].dkpMod + modifier
		end
	end
end

function DKP:RaidRegisterEPManipulation(strName,modifier)

	if self.tItems["settings"].lowercase == 1 then
		strName = string.lower(strName)
	end
	for i=1,table.getn(tAllRaidMembersInSession) do
		if string.lower(tAllRaidMembersInSession[i].name) == string.lower(strName) then
			tAllRaidMembersInSession[i].dkpMod = tAllRaidMembersInSession[i].dkpMod + modifier
		end
	end

end


function DKP:RaidRunMiscSummaries(RaidID)
	if self.tItems["Raids"][RaidID] ~= nil then
		if self.tItems["Raids"][RaidID].date.resDate == nil then
			self.tItems["Raids"][RaidID].tMisc.length = os.difftime(os.time() - self.tItems["Raids"][RaidID].date.osDate)
		else
			self.tItems["Raids"][RaidID].tMisc.length = os.difftime(self.tItems["Raids"][RaidID].date.resDate - self.tItems["Raids"][RaidID].date.osDate)
		end
		self.tItems["Raids"][RaidID].tMisc.lootcount = 0
		for i=1,table.getn(self.tItems["Raids"][RaidID].tPlayers) do
			if self.tItems["Raids"][RaidID].tPlayers[i].tClaimedLoot ~= nil then
				self.tItems["Raids"][RaidID].tMisc.lootcount = self.tItems["Raids"][RaidID].tMisc.lootcount + table.getn(self.tItems["Raids"][RaidID].tPlayers[i].tClaimedLoot)
			end
		end
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscRaid"):SetText(self.tItems["Raids"][currentRaidID].Raid)
		
		self.tItems["Raids"][RaidID].tMisc.allPlayersCount = table.getn(tAllRaidMembersInSession)
		self:RaidPurgeItemTable(tBossItems)
		if self.tItems["Raids"][RaidID].tMisc.tBossKills.count ~= nil and #self.tItems["Raids"][RaidID].tMisc.tBossKills.names  then
			for i=1,#self.tItems["Raids"][RaidID].tMisc.tBossKills.names do
				if self.tItems["Raids"][currentRaidID].Raid == "Datascape" then wnd:SetSprite("CRB_Tooltips:sprTooltip_Header_Orange") end
				local wnd = Apollo.LoadForm(self.xmlDoc,"BossItem",self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("KilledBossesList"),self)
				wnd:FindChild("BossName"):SetText(self.tItems["Raids"][RaidID].tMisc.tBossKills.names[i])
				table.insert(tBossItems,wnd)
			end
			self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("KilledBossesList"):ArrangeChildrenVert()
		end
		
	end
end

function DKP:RaidUpdateCurrentRaidSession() 

	if GroupLib.InRaid() == false then
		Print("You are not in raid , close session")
		return
	end
	
	
		if currentRaidID ~= nil then
			self:RaidBackupSession()
			local currentPlayers = {}
			for k=1,GroupLib.GetMemberCount(),1 do -- Getting Players List
				local unit_member = GroupLib.GetGroupMember(k)
				if unit_member ~= nil then
					if self.tItems["settings"].lowercase == 1 then 
						table.insert(currentPlayers,string.lower(unit_member.strCharacterName))
					else
						table.insert(currentPlayers,unit_member.strCharacterName)
					end
					local ID = self:GetPlayerByIDByName(unit_member.strCharacterName)
					if ID ~= -1 then self.tItems[ID].Hrs = self.tItems[ID].Hrs + (0.00027 * self.tItems["settings"].RaidTimer) end
				end
			end
		
		--[[if currentRaidID ~= nil then
		self:RaidBackupSession()
		local currentPlayers = {}
		for k=1,math.random(15, 20) do
			table.insert(currentPlayers,"Player"..tostring(k))
		end]]

		--Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), "SUMWEAPON", "Player"..tostring(math.random(2,14))))
		
		local LeftNames = {}
		local NewNames = {}
		local changedPlayersIDs = {}
		if #self.tItems["Raids"][currentRaidID].tPlayers >=1 then -- Comparing in search for changes
			
			for k=1,table.getn(currentPlayers) do
				local found = 0
				for i=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers) do
				
				
				if string.lower(currentPlayers[k]) == string.lower(self.tItems["Raids"][currentRaidID].tPlayers[i].name) then
					found = k
					break
				end
			
			
				end
				if found == 0 then 
				table.insert(NewNames,currentPlayers[k]) -- New
				end
				
			end
			
			for k=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers) do
				local found = 0
			
				for i=1,table.getn(currentPlayers)do
					if string.lower(currentPlayers[i]) == string.lower(self.tItems["Raids"][currentRaidID].tPlayers[k].name) then
						found = k
						break
					end
				end
				
				if found == 0 then 
				table.insert(LeftNames,self.tItems["Raids"][currentRaidID].tPlayers[k].name) -- Left
				end
			
			end
		elseif #self.tItems["Raids"][currentRaidID].tPlayers < 1 then -- Start up
			for i=1,table.getn(currentPlayers) do
				local add = true
				for j=1, table.getn(tAllRaidMembersInSession) do
					if string.lower(currentPlayers[i]) == string.lower(tAllRaidMembersInSession[j].name) then 
						add = false 
						break
					end
				end
				local Player = {}
				if add == true then
					Player.name = currentPlayers[i]
					Player.dkpMod = 0
					Player.bLeft = "!Left"
					Player.tClaimedLoot = {}
					Player.Deaths = 0
					table.insert(self.tItems["Raids"][currentRaidID].tPlayers,Player)
					table.insert(tAllRaidMembersInSession,Player)
				end
			end
		end
		
		--Merge new players
		self.tItems["Raids"][currentRaidID].tPlayers = {}
		for i=1,table.getn(currentPlayers) do
				local inserted = false
				for j=1,table.getn(tAllRaidMembersInSession) do
						if string.lower(tAllRaidMembersInSession[j].name) == string.lower(currentPlayers[i]) then -- Finding existing info
							table.insert(self.tItems["Raids"][currentRaidID].tPlayers,{name = currentPlayers[i] , dkpMod = tAllRaidMembersInSession[j].dkpMod , bLeft = tAllRaidMembersInSession[j].bLeft , tClaimedLoot = {} })
							inserted = true
							break
						end
				end
				if inserted == false then
						table.insert(self.tItems["Raids"][currentRaidID].tPlayers,{name = currentPlayers[i] , dkpMod = 0, bLeft = "!Left" , tClaimedLoot = {}}) --New
				end
		end
		

		
		-- Take certain actions
		if LeftNames ~= nil then
			for i=1,table.getn(tAllRaidMembersInSession) do
				local existingID
				for j=1,table.getn(LeftNames) do 
						if string.lower(tAllRaidMembersInSession[i].name) == string.lower(LeftNames[j]) then tAllRaidMembersInSession[i].bLeft = self.tItems["settings"].RaidLeaveTimer						end
				end
			end
		end
		if NewNames ~= nil then
			for i=1, table.getn(NewNames) do
				local add = true
				local Player = {}
				local ID
				for j=1, table.getn(tAllRaidMembersInSession) do
					if string.lower(NewNames[i]) == string.lower(tAllRaidMembersInSession[j].name) then 
						add = false 
						ID=j
						break
					end
				end
				if add == true then
					Player.name = NewNames[i]
					Player.dkpMod = 0
					Player.bLeft = "!Left"
					Player.tClaimedLoot = {}
					Player.Deaths = 0
					table.insert(tAllRaidMembersInSession,Player)
				else -- Reset Left Timer
					tAllRaidMembersInSession[ID].bLeft = "!Left" 
				end
			end
		end
		
		for i=1,table.getn(tAllRaidMembersInSession) do
			if tAllRaidMembersInSession[i].bLeft == nil then tAllRaidMembersInSession[i].bLeft = "!Left" end
			if tAllRaidMembersInSession[i].bLeft ~= "!Left" and tAllRaidMembersInSession[i].bLeft ~= "Left" then
				tAllRaidMembersInSession[i].bLeft = tAllRaidMembersInSession[i].bLeft - self.tItems["settings"].RaidTimer
				if tAllRaidMembersInSession[i].bLeft == 0 then tAllRaidMembersInSession[i].bLeft = "Left" end
			end
		
		end
		
		self:RaidRunMiscSummaries(currentRaidID)
		local diff = os.date("*t",self.tItems["Raids"][currentRaidID].tMisc.length)
		
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscLen"):SetText((diff.hour-1 <=9 and "0" or "" ) .. diff.hour-1 .. ":" .. (diff.min <=9 and "0" or "") .. diff.min .. ":".. (diff.sec <=9 and "0" or "") .. diff.sec)
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscLoot"):SetText(self.tItems["Raids"][currentRaidID].tMisc.lootcount)
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscPlayers"):SetText(self.tItems["Raids"][currentRaidID].tMisc.allPlayersCount)
		
		if self.wndRaidSummary:IsShown() == true then
			if self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):IsChecked() == true then 
				self:RaidUpdateSummaryLootDetails()
			elseif self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonPlayers"):IsChecked() == true then
				self:RaidUpdateSummaryPlayerDetails()
			end
		end
		if self.tItems["Raids"][currentRaidID].FirstIteration == true then
			self:RaidPostWelcomeMsg()
			self.tItems["Raids"][currentRaidID].FirstIteration = false
		end
		
		if self.wndRaidTools:IsShown() == true then self:RaidToolsUpdate() end
	end
end


function DKP:RaidPostWelcomeMsg()
	if currentRaidID == nil then return end
	if self.wndRaidOptions:FindChild("Button"):IsChecked() == false then return end
	local strToSend = " [EasyDKP] Raid Session has just started with " .. self.tItems["Raids"][currentRaidID].tMisc.allPlayersCount .. " players on board."
	ChatSystemLib.Command("/party" .. strToSend)
end


function DKP:RaidUpdateTimer( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil and tonumber(strText) >= 10 and tonumber(strText) <= 60 then
		self.tItems["settings"].RaidTimer = tonumber(strText)
		if self.bIsRaidSession == true then
			self.RaidTimer:Stop()
			self.RaidTimer = ApolloTimer.Create(self.tItems["settings"].RaidTimer, true, "RaidUpdateCurrentRaidSession", self)
		end
	else
		wndControl:SetText(self.tItems["settings"].RaidTimer)
	end
end

function DKP:RaidProccesNewPieceOfLoot(strItem,strLooter)
	if self.bIsRaidSession == false or tAllRaidMembersInSession == nil then return end
	if self.tItems["settings"].lowercase == 1 then strLooter = string.lower(strLooter) end
	for i=1,table.getn(tAllRaidMembersInSession) do
		if string.lower(tAllRaidMembersInSession[i].name) == string.lower(strLooter) then 
			local LootItem = {}
			LootItem.name = strItem
			LootItem.dkp = self.tItems["EPGP"].Enable == 1 and tonumber(string.sub(self:EPGPGetItemCostByID(self.ItemDatabase[string.sub(strItem,2)].ID),36)) or 0
			LootItem.ID = self.ItemDatabase[string.sub(strItem,2)].ID
			LootItem.currency = self.tItems["EPGP"].Enable == 1 and "GP" or "DKP"
			table.insert(tAllRaidMembersInSession[i].tClaimedLoot,LootItem) 
			self.tItems["Raids"][currentRaidID].tMisc.lootcount = self.tItems["Raids"][currentRaidID].tMisc.lootcount + 1
			break
		end
	end
end

function DKP:RaidAddCostInfo(strItem,strLooter,cost)
	if tAllRaidMembersInSession == nil or self.bIsRaidSession == false then return end
	if self.tItems["settings"].lowercase == 1 then strLooter = string.lower(strLooter) end
	for i=1,table.getn(tAllRaidMembersInSession) do
		if string.lower(tAllRaidMembersInSession[i].name) == string.lower(strLooter) then -- Found Player Profile
			for j=1,table.getn(tAllRaidMembersInSession[i].tClaimedLoot) do
				if tAllRaidMembersInSession[i].tClaimedLoot[j].name == strItem then -- Found Item in PlayerProfile
					tAllRaidMembersInSession[i].tClaimedLoot[j].dkp = cost
					tAllRaidMembersInSession[i].dkpMod = tAllRaidMembersInSession[i].dkpMod + cost
					break
				end
			end
		end
	end
end

function DKP:RaidUpdateSummary(tData)
	if tData == nil then
		tData = {}
		tData.name = self.tItems["Raids"][currentRaidID].name
		tData.date = self.tItems["Raids"][currentRaidID].date
		tData.len = self.tItems["Raids"][currentRaidID].tMisc.length
		tData.loot = self.tItems["Raids"][currentRaidID].tMisc.lootcount
		tData.players = self.tItems["Raids"][currentRaidID].tMisc.allPlayersCount
	end
	
	
	
	
	self.wndRaidSummary:FindChild("StatEditName"):SetText(tData.name)
	self.wndRaidSummary:FindChild("StatEditDate"):SetText(tData.date.strDate)

	if tData.misc == 1 then
		local diff = os.date("*t",tData.len)
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscLen"):SetText((diff.hour-1 <=9 and "0" or "" ) .. diff.hour-1 .. ":" .. (diff.min <=9 and "0" or "") .. diff.min .. ":".. (diff.sec <=9 and "0" or "") .. diff.sec)
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscLoot"):SetText(tData.loot)
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscPlayers"):SetText(tData.players)
		self.wndRaidSummary:FindChild("StatsContainer"):FindChild("MiscContainer"):FindChild("MiscRaid"):SetText(self.tItems["Raids"][currentRaidID].Raid)
	end

end



function DKP:RaidUpdateSummaryPlayerDetails()
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("Window1"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("PlayerLabels"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("LootLabels"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("OrderContainer"):Show(true,true)
	
	
	if self.bIsRaidSession == false then tAllRaidMembersInSession = self.tItems["Raids"][currentRaidID].tPlayers end
	for i=1,table.getn(self.tPlayersRaidItems) do
		self.tPlayersRaidItems[i]:Destroy()
	end
	for i=1,table.getn(self.tLootItems) do
		self.tLootItems[i]:Destroy()
	end
	
	
	if self.wndRaidSummary:FindChild("SortDeaths"):IsChecked() or self.wndRaidSummary:FindChild("SortEarned"):IsChecked() then
		local IDsOrder = {}
		if self.wndRaidSummary:FindChild("SortDeaths"):IsChecked() then
			
			for k,player in ipairs(tAllRaidMembersInSession) do
				table.insert(IDsOrder,{ID = k,value = player.Deaths})
			end
			table.sort(IDsOrder,compare_easyDKP)
			
			
		
		else
			for k,player in ipairs(tAllRaidMembersInSession) do
				table.insert(IDsOrder,{ID = k,value = player.dkpMod})
			end
			table.sort(IDsOrder,compare_easyDKP)
		
		end
		
		for i=1,table.getn(IDsOrder) do
			local wnd = Apollo.LoadForm(self.xmlDoc , "RaidPlayerItem" , self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("RaidItems") , self)
			wnd:FindChild("Name"):SetText(tAllRaidMembersInSession[IDsOrder[i].ID].name)
			wnd:FindChild("Mod"):SetText(tostring(tAllRaidMembersInSession[IDsOrder[i].ID].dkpMod))
			if tAllRaidMembersInSession[IDsOrder[i].ID].bLeft == "Left" then
				wnd:FindChild("Left"):Show(true,false)
			elseif tonumber(tAllRaidMembersInSession[IDsOrder[i].ID].bLeft) ~= nil then
				wnd:FindChild("Left"):SetText(tAllRaidMembersInSession[IDsOrder[i].ID].bLeft .. "(s)")
			else
				wnd:FindChild("Left"):Show(false,true)
			end
			wnd:FindChild("Deaths"):SetText(tAllRaidMembersInSession[IDsOrder[i].ID].Deaths)
			local strTooltip = "Loot:\n"
			if tAllRaidMembersInSession[IDsOrder[i].ID].tClaimedLoot ~= nil then
				for j=1,table.getn(tAllRaidMembersInSession[IDsOrder[i].ID].tClaimedLoot) do
					strTooltip = strTooltip .. tAllRaidMembersInSession[IDsOrder[i].ID].tClaimedLoot[j].name .. " - " .. (self.tItems["EPGP"].Enable == 1 and string.sub(self:EPGPGetItemCostByID(tAllRaidMembersInSession[IDsOrder[i].ID].tClaimedLoot[j].ID),32) .. " GP" or tostring(tAllRaidMembersInSession[IDsOrder[i].ID].tClaimedLoot[j].dkp)) .. "\n"
				end
			end
			if self.tItems["EPGP"].Enable == 1 then wnd:FindChild("Mod"):SetTooltip("Earned EP") end
			if strTooltip == "Loot:\n" then wnd:FindChild("Loot"):Show(false) end
			wnd:FindChild("Loot"):SetTooltip(strTooltip)
			table.insert(self.tPlayersRaidItems,wnd)
		end
	else
		for i=1,table.getn(tAllRaidMembersInSession) do
			local wnd = Apollo.LoadForm(self.xmlDoc , "RaidPlayerItem" , self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("RaidItems") , self)
			wnd:FindChild("Name"):SetText(tAllRaidMembersInSession[i].name)
			wnd:FindChild("Mod"):SetText(tostring(tAllRaidMembersInSession[i].dkpMod))
			if tAllRaidMembersInSession[i].bLeft == "Left" then
				wnd:FindChild("Left"):Show(true,false)
			elseif tonumber(tAllRaidMembersInSession[i].bLeft) ~= nil then
				wnd:FindChild("Left"):SetText(tAllRaidMembersInSession[i].bLeft .. "(s)")
			else
				wnd:FindChild("Left"):Show(false,true)
			end
			wnd:FindChild("Deaths"):SetText(tAllRaidMembersInSession[i].Deaths)
			local strTooltip = "Loot:\n"
			if tAllRaidMembersInSession[i].tClaimedLoot ~= nil then
				for j=1,table.getn(tAllRaidMembersInSession[i].tClaimedLoot) do
					strTooltip = strTooltip .. tAllRaidMembersInSession[i].tClaimedLoot[j].name .. " - " .. (self.tItems["EPGP"].Enable == 1 and string.sub(self:EPGPGetItemCostByID(tAllRaidMembersInSession[i].tClaimedLoot[j].ID),32) .. " GP" or tostring(tAllRaidMembersInSession[i].tClaimedLoot[j].dkp)) .. "\n"
				end
			end
			if self.tItems["EPGP"].Enable == 1 then wnd:FindChild("Mod"):SetTooltip("Earned EP") end
			if strTooltip == "Loot:\n" then wnd:FindChild("Loot"):Show(false) end
			wnd:FindChild("Loot"):SetTooltip(strTooltip)
			table.insert(self.tPlayersRaidItems,wnd)
		end
	end
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("RaidItems"):ArrangeChildrenVert()
	if self.bIsRaidSession == false then tAllRaidMembersInSession = {} end
end

function DKP:RaidUpdateSummaryLootDetails()
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("Window1"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("PlayerLabels"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("LootLabels"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("OrderContainer"):Show(false,true)
	
	
	if self.bIsRaidSession == false then tAllRaidMembersInSession = self.tItems["Raids"][currentRaidID].tPlayers end
	for i=1,table.getn(self.tPlayersRaidItems) do
		self.tPlayersRaidItems[i]:Destroy()
	end
	for i=1,table.getn(self.tLootItems) do
		self.tLootItems[i]:Destroy()
	end
	
	for i=1,table.getn(tAllRaidMembersInSession) do
		if tAllRaidMembersInSession[i].tClaimedLoot ~= nil then
			for j=1,table.getn(tAllRaidMembersInSession[i].tClaimedLoot) do
				if not self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):FindChild("Button"):IsChecked() or self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):FindChild("Button"):IsChecked() and string.find(tAllRaidMembersInSession[i].tClaimedLoot[j].name,"Gift") == nil and string.find(tAllRaidMembersInSession[i].tClaimedLoot[j].name,"Sign") == nil and string.find(tAllRaidMembersInSession[i].tClaimedLoot[j].name,"Pattern") == nil and string.find(tAllRaidMembersInSession[i].tClaimedLoot[j].name,"Module") == nil then
					local wnd = Apollo.LoadForm(self.xmlDoc, "RaidLootItem" , self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("RaidItems") , self)
					wnd:FindChild("Name"):SetText(tAllRaidMembersInSession[i].tClaimedLoot[j].name)
					wnd:FindChild("Looter"):SetText(tAllRaidMembersInSession[i].name)
					local itemID = tAllRaidMembersInSession[i].tClaimedLoot[j].ID
					
					if self.tItems["EPGP"].Enable == 1 and Item.GetDataFromId(itemID):IsEquippable()  then 
						wnd:FindChild("Cost"):SetText(string.sub(self:EPGPGetItemCostByID(itemID),32))
					else
						wnd:FindChild("Cost"):SetText("xxx")
					end
					wnd:FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(Item.GetDataFromId(itemID):GetItemQuality()))
					wnd:FindChild("ItemIcon"):SetSprite(Item.GetDataFromId(itemID):GetIcon())
					Tooltip.GetItemTooltipForm(self, wnd:FindChild("ItemIcon") , Item.GetDataFromId(itemID), {bPrimary = true, bSelling = false})
					
					if self.tItems["EPGP"].Enable == 0 then
							wnd:FindChild("Cost"):SetText(tAllRaidMembersInSession[i].tClaimedLoot[j].dkp)
					end
					table.insert(self.tLootItems,wnd)
				end
			end
		end
	end
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("RaidItems"):ArrangeChildrenVert()
	if self.bIsRaidSession == false then tAllRaidMembersInSession = {} end
end

function DKP:RaidFilteWordsDisable()
	if self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):IsChecked() then self:RaidSummaryListShowLoot() end
end

function DKP:RaidFilteWordsEnable()
	if self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):IsChecked() then self:RaidSummaryListShowLoot() end
end

function DKP:RaidStartNewSession( wndHandler, wndControl, eMouseButton )
	if GroupLib.InRaid() == false then
		Print("You cannot begin new session while not in raid")
		return
	end
	if self.bIsRaidSession == true then
		Print("Close previous session first") 
		return
	end
	self.wndRaidSelection:Show(false,false)
	self:RaidOpenSummary("New")
end

function DKP:RaidAssumeRaid()
	if GroupLib.GetMemberCount() > 20 then return "Datascape" 
	else return "Genetic Archives" end
end

function DKP:RaidOnUnitDestroyed(tArgs)
	
	if  tArgs.bTargetKilled== false then return end
	
	if tArgs.unitTarget:IsACharacter() then
		local ID 
		for k,player in ipairs(tAllRaidMembersInSession) do
			if player.name == tArgs.unitTarget:GetName() then
				ID = k
				break
			end
		end
		if ID ~= nil then
			tAllRaidMembersInSession[ID].Deaths = tAllRaidMembersInSession[ID].Deaths + 1
		end
		return
	end
	
	
	if self.tItems["Raids"][currentRaidID].RaidSure == false or self.tItems["Raids"][currentRaidID].RaidSure == true and self.tItems["Raids"][currentRaidID].Raid == "Genetic Archives"  then
	
		-- GA
		local name = tArgs.unitTarget:GetName()
		if name == "Phagetech Commander" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype1 = 1 end
		if name == "Phagetech Augmentor" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype2 = 1 end
		if name == "Phagetech Protector" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype3 = 1 end
		if name == "Phagetech Fabricator" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype4 = 1 end
		
		if self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype1 == 1 and self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype2 == 1 and self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype3 == 1 and self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype4 == 1 then
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,"Phagetech Prototypes")
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.prototype1 = 0
		end
		
		if name == "Ersoth Curseform" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount +1  end
		if name == "Fleshmonger Vratorg" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount +1 end
		if name == "Terax Blightweaver" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount +1 end
		if name == "Goldox Lifecrusher" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount +1 end
		if name == "Noxmind the Insidious" then self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount +1 end
		
		if  self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount >= 4 then
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,"Phageborn Convergence")
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.converCount = 0
		end
		
	
		
		if name == "Experiment X-89" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Genetic Archives"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Kuralak the Defiler" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Genetic Archives"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Phage Maw" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Genetic Archives"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Phageborn Convergence" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Genetic Archives"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Dreadphage Ohmna" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Genetic Archives"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		end
	end
		-- DS
	if self.tItems["Raids"][currentRaidID].RaidSure == false or self.tItems["Raids"][currentRaidID].RaidSure == true and self.tItems["Raids"][currentRaidID].Raid == "Datascape"  then
		
		if name == "Megalith" or name == "Hydroflux" or name == "Visceralus" or name == "Aileron" or name == "Pyrobane" or name == "Mnemesis" then
			if self.tItems["Raids"][currentRaidID].tMisc.tBossKills.pairs == nil then  self.tItems["Raids"][currentRaidID].tMisc.tBossKills.pairs = {} end
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.pairs,name)
		end
		
		if name == "Megalith" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals + 1
		elseif name == "Hydroflux" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals + 1
		elseif name == "Visceralus" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals + 1
		elseif name == "Aileron" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals + 1
		elseif name == "Pyrobane" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals + 1
		elseif name == "Mnemesis" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.elementals + 1
		end
		
		
		
		
		
		
		if name == "System Daemons" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Datascape"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Gloomclaw" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Datascape"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Maelstrom Authority" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Datascape"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		elseif name == "Avatus" then
			self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count +1
			table.insert(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names,name)
			self.tItems["Raids"][currentRaidID].Raid = "Datascape"
			self.tItems["Raids"][currentRaidID].RaidSure = true
		end
	end
end

local prevSelectionDate
local prevSelectionName
local prevSelectionTab
function DKP:RaidItemSelected( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY ) -- From Control "RaidItem"
	if wndHandler ~= wndControl then return end
	
	wndControl:FindChild("RaidName"):SetTextColor(kcrNormalText)
	wndControl:FindChild("RaidDate"):SetTextColor(kcrNormalText)
	
	if prevSelectionName ~= nil then
		prevSelectionName:SetTextColor(kcrSelectedText)
		prevSelectionDate:SetTextColor(kcrSelectedText)
	end
	if prevSelectionTab == wndControl and self.bIsRaidSession == false then
		self:RaidOpenSummary(wndControl:FindChild("RaidName"):GetText())
		self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonPlayers"):SetCheck(true)
		self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):SetCheck(false)
	elseif self.bIsRaidSession == true and wndControl:FindChild("RaidName"):GetText() == self.tItems["Raids"][currentRaidID].name then
		self.wndRaidSummary:Show(true,false)
		self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonPlayers"):SetCheck(true)
		self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):SetCheck(false)
	end
	
	
	prevSelectionDate = wndControl:FindChild("RaidDate")
	prevSelectionName = wndControl:FindChild("RaidName")
	prevSelectionTab = wndControl
end



function DKP:RaidCloseSummary( wndHandler, wndControl, eMouseButton )
	self.wndRaidSummary:Show(false,false)
end

function DKP:RaidSetRaidName( wndHandler, wndControl, strText )
	if strText == "" then
		wndControl:SetText("SET NAME"..currentRaidID+1)
		strText = "SET NAME"..currentRaidID+1
	end
	local found = false
	local ofID 
	for i=1,table.maxn(self.tItems["Raids"]) do
		if self.tItems["Raids"][i] ~= nil and self.tItems["Raids"][i].name == strText then
			found = true
			ofID = i
			break
		end
	end
	if found == false then
		self.tItems["Raids"][currentRaidID].name = strText
		self:RaidPopulateLists("Raids")
	else
		wndControl:SetText(self.tItems["Raids"][ofID].name)
	end
end

function DKP:RaidSetRaidDate( wndHandler, wndControl, strText )
	self.tItems["Raids"][currentRaidID].date.strDate = strText
	self:RaidPopulateLists("Raids")
end

function DKP:RaidSummaryListShowPlayers( wndHandler, wndControl, eMouseButton )
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("Window1"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("PlayerLabels"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("LootLabels"):Show(false,true)
	
	self:RaidUpdateSummaryPlayerDetails()
end

function DKP:RaidSummaryListShowLoot( wndHandler, wndControl, eMouseButton )
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("Window1"):Show(true,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("PlayerLabels"):Show(false,true)
	self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("LootLabels"):Show(true,true)
	self:RaidUpdateSummaryLootDetails()
end

function DKP:RaidExportTable( wndHandler, wndControl, eMouseButton )
	local exportStr = "<!DOCTYPE html><html><head><style>\ntable, th, td {    border: 1px solid black;    border-collapse: collapse;}th, td {    padding: 5px;}</style></head>\n<body>"
	local FormatedTable = {}
	if self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportTab"):IsChecked() == false then
		FormatedTable.Raid_Members = {}
		
		if self.bIsRaidSession == true then 
			local PlayersBackup = self.tItems["Raids"][currentRaidID].tPlayers
			self.tItems["Raids"][currentRaidID].tPlayers = tAllRaidMembersInSession
		end
		
		local players = {}
		for i=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers) do -- Formatting table
			
			players[self.tItems["Raids"][currentRaidID].tPlayers[i].name] = {}
			if self.tItems["EPGP"].Enable == 0 then
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Gained_DKP = self.tItems["Raids"][currentRaidID].tPlayers[i].dkpMod
			else
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Gained_EP = self.tItems["Raids"][currentRaidID].tPlayers[i].dkpMod
			end
			if self.tItems["Raids"][currentRaidID].tPlayers[i].bLeft == "Left" then
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Has_Player_Left = "Yes"
			else
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Has_Player_Left = "No"
			end
			players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Deaths = self.tItems["Raids"][currentRaidID].tPlayers[i].Deaths

				if table.getn(self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot) == 0 then players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Claimed_Loot = "Player has not claimed any loot"
				else
					
					players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Claimed_Loot = {}
					for j=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot) do
						local LootItem = {}
						LootItem.Name = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].name
						if self.tItems["EPGP"].Enable == 0 then
							LootItem.Cost = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].dkp
						else
							LootItem.Cost = string.sub(self:EPGPGetItemCostByID(self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID),32)
						end
						if self.tItems["settings"].forceCheck == 1 then
							if self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID ~= nil then
								LootItem.ID = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID
							else
								LootItem.ID = "--"
							end
						end
						table.insert(players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Claimed_Loot,LootItem)
					end
				end	

		end
		table.insert(FormatedTable.Raid_Members,players)
		if PlayersBackup~= nil then
			self.tItems["Raids"][currentRaidID].tPlayers = PlayersBackup
			PlayersBackup = nil 
		end
		
		FormatedTable.Stats = {}
		FormatedTable.Stats.Raid_Length_in_Seconds = self.tItems["Raids"][currentRaidID].tMisc.length
		FormatedTable.Stats.All_Players_Count = self.tItems["Raids"][currentRaidID].tMisc.allPlayersCount
		FormatedTable.Stats.Amount_Of_Items_Distributed = self.tItems["Raids"][currentRaidID].tMisc.lootcount
		
		FormatedTable.Stats.Killed_Bosses = {}
		for i=1,table.getn(self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names) do
			local BossKillEntry = {}
			BossKillEntry.Boss_Name = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.names[i]
			table.insert(FormatedTable.Stats.Killed_Bosses,BossKillEntry)
		end
		
		FormatedTable.Stats.Bosses_Killed_in_Total = self.tItems["Raids"][currentRaidID].tMisc.tBossKills.count
		
		
		
		exportStr = exportStr .. tohtml(FormatedTable)
	else
		if self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonPlayers"):IsChecked() == true then
			local players = {}
			for i=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers) do -- Formatting table
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name] = {}
				if self.tItems["EPGP"].Enable == 0 then
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Gained_DKP = self.tItems["Raids"][currentRaidID].tPlayers[i].dkpMod
			else
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Gained_EP = self.tItems["Raids"][currentRaidID].tPlayers[i].dkpMod
			end

				if self.tItems["Raids"][currentRaidID].tPlayers[i].bLeft == "Left" then
					players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Has_Player_Left = "Yes"
				else
					players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Has_Player_Left = "No"
				end
				players[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Deaths = self.tItems["Raids"][currentRaidID].tPlayers[i].Deaths
			end
			exportStr = exportStr .. tohtml(players)
		
		elseif self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ButtonLoot"):IsChecked() == true then
			if self.wndRaidSummary:FindChild("DetailsContainer"):FindChild("ExportCSV"):IsChecked() == false then
				local loot = {}
				for i=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers) do
					for j=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot) do
	
						loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name] = {}
						loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Item_Name = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].name
						
						if self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID ~= nil and self.tItems["settings"].forceCheck == 1 then
							loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name].ID = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID
						elseif self.tItems["settings"].forceCheck == 1 then
							loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name].ID = "--"
						end
					
					
						if self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].dkp == 0 then
							loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Cost = "Cost unknown"
						else
							loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Cost = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].dkp
						end
						if self.tItems["EPGP"].Enable == 1  then
							loot[self.tItems["Raids"][currentRaidID].tPlayers[i].name].Cost = string.sub(self:EPGPGetItemCostByID(self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID),32)
						end
					end	
				end
				exportStr = exportStr .. tohtml(loot)
			else
				local lootExportStr = ""
				local loot = {}
				for i=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers) do
					for j=1,table.getn(self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot) do
						local lootPiece = {}
						lootPiece.looter = self.tItems["Raids"][currentRaidID].tPlayers[i].name
						lootPiece.strItem = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].name
						lootPiece.dkp = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].dkp
						lootPiece.ID = self.tItems["Raids"][currentRaidID].tPlayers[i].tClaimedLoot[j].ID
						table.insert(loot,lootPiece)
					end
				end
				if self.tItems["settings"].forceCheck == 1 then
					for i=1,table.getn(loot) do
						lootExportStr = lootExportStr .. loot[i].looter .. ";" ..  loot[i].strItem .. ";" ..  (self.tItems["EPGP"].Enable == 0 and tostring(loot[i].dkp) or string.sub(self:EPGPGetItemCostByID(loot[i].ID),32)) .. " ; " .. loot[i].ID .. "\n"
					end
				else
					for i=1,table.getn(loot) do
						lootExportStr = lootExportStr .. loot[i].looter .. ";" ..  loot[i].strItem .. ";" ..  (self.tItems["EPGP"].Enable == 0 and tostring(loot[i].dkp) or string.sub(self:EPGPGetItemCostByID(loot[i].ID),32)) .. "\n"
					end
				end
				exportStr = lootExportStr
			
			
			end
		end
	end

	
	
	--[[local loot = {}

	
	local lootExportStr = "<table style=".."width:100%"..">\n<tr><th>" .. "Looter" .. "</th><th>" .. "Item" .. "</th><th>" .. "Cost" .. "</th></tr>\n"
	

	
	exportStr = exportStr .. lootExportStr
	
	exportStr = exportStr .. "\n</table>\n</body>\n</html>"]]
	self:ExportShowPreloadedText(exportStr)
	exportStr = nil
end

function DKP:RaidGetRaidIdByName(name)
	for i=1,table.maxn(self.tItems["Raids"]) do
		if self.tItems["Raids"][i] ~= nil and self.tItems["Raids"][i].name == name then 
			return i 
		end
	end
	
	return
end

function DKP:RaidCloseSelectionWindow( wndHandler, wndControl, eMouseButton )
	self.wndRaidSelection:Show(false,false)
end


function DKP:RaidSelectionRefresh( wndHandler, wndControl, eMouseButton )
	self:RaidPopulateLists("Raids")
end




function DKP:RaidShowOptions( wndHandler, wndControl, eMouseButton )
	self.wndRaidOptions:Show(true,false)
	local l,t,r,b = self.wndRaidSelection:GetAnchorOffsets()
	self.wndRaidSelection:SetAnchorOffsets(l,t,r+234,b)
end

function DKP:RaidHideOptions( wndHandler, wndControl, eMouseButton )
	self.wndRaidOptions:Show(false,false)
	local l,t,r,b = self.wndRaidSelection:GetAnchorOffsets()
	self.wndRaidSelection:SetAnchorOffsets(l,t,r-234,b)
end


function DKP:RaidUpdateLeaveTimer( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil  and tonumber(strText) >= 60 and tonumber(strText) <= 300 then
		self.tItems["settings"].RaidLeaveTimer = tonumber(strText)
		wndControl:SetText(self.tItems["settings"].RaidLeaveTimer)
	else
		wndControl:SetText(self.tItems["settings"].RaidLeaveTimer)
	end

end


function DKP:RaidUpdateOfflineTimer( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil  and tonumber(strText) >= 3600 and tonumber(strText) <= 10800 then
		self.tItems["settings"].RaidOfflineTimer = tonumber(strText)
		wndControl:SetText(self.tItems["settings"].RaidOfflineTimer)
	else
		wndControl:SetText(self.tItems["settings"].RaidOfflineTimer)
	end
end



---------------------------------------------------------------------------------------------------
-- RaidTools Functions
---------------------------------------------------------------------------------------------------

function DKP:RaidToolsMassAdd( wndHandler, wndControl, eMouseButton )
	
	if self.bIsRaidSession == true then
		if self.tItems["EPGP"].Enable == 1 then
			self:EPGPAwardRaid(self.tItems["settings"].dkp,nil)
		else
			-- DKP
			for k,player in ipairs(tAllRaidMembersInSession) do
				local ID = self:GetPlayerByIDByName(player.name)
				if ID ~= -1 then
					player.net = player.net + self.tItems["settings"].dkp
				end
			end
		
		end
		self:RaidToolsPostMassMessage()
	end
end

function DKP:RaidToolsShowSummary( wndHandler, wndControl, eMouseButton )
	self.wndRaidSummary:Show(true,false)
end

function DKP:RaidToolsUpdate()
	local formattedDate = os.date("*t",self.tItems["Raids"][currentRaidID].tMisc.length)
	self.wndRaidTools:FindChild("RaidName"):FindChild("NameField"):SetText(self.tItems["Raids"][currentRaidID].name)
	self.wndRaidTools:FindChild("RaidDuration"):FindChild("NameField"):SetText(formattedDate.hour-1 .. ":" .. formattedDate.min .. ":" .. formattedDate.sec)
end



function DKP:RaidToolsIncreaseOpacity( wndHandler, wndControl, x, y )
	self.wndRaidTools:SetOpacity(self.tItems["settings"].RaidTools.opacityOn)
end

function DKP:RaidToolsDecreaseOpacity( wndHandler, wndControl, x, y )
	self.wndRaidTools:SetOpacity(self.tItems["settings"].RaidTools.opacityOff)
end

function DKP:RaidToolsClose( wndHandler, wndControl, eMouseButton )
	self.wndRaidTools:Show(false,false)
	self.wndRaidSummary:FindChild("ButtonRaidTools"):SetCheck(false)
	self.wndRaidSelection:FindChild("ButtonRaidTools"):SetCheck(false)
end


function DKP:RaidToolsEnable( wndHandler, wndControl, eMouseButton )
	self.wndRaidTools:Show(true,false)
	self.wndRaidSummary:FindChild("ButtonRaidTools"):SetCheck(true)
	self.wndRaidSelection:FindChild("ButtonRaidTools"):SetCheck(true)
end

function DKP:RaidToolsDisable( wndHandler, wndControl, eMouseButton )
	self:RaidToolsClose()
end

function DKP:RaidToolsMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	local l,t,r,b = self.wndRaidTools:GetAnchorOffsets()
	self.tItems["settings"].RaidTools = {l=l,t=t,r=r,b=b,opacityOn = self.tItems["settings"].RaidTools.opacityOn,opacityOff = self.tItems["settings"].RaidTools.opacityOff,show = self.tItems["settings"].RaidTools.show }
end

function DKP:RaidToolsPostMassMessage()
	ChatSystemLib.Command("/party [EasyDKP] Every raid member has been granted with " .. self.tItems["settings"].dkp .. self.tItems[EPGP].Enable == 1 and "EP." or "GP.")
end

function DKP:RaidToolsStartSummary()
	if GroupLib.InRaid() == false then
		Print("You cannot begin new session while not in raid")
		return
	end
	if self.bIsRaidSession == true then
		Print("Close previous session first") 
		return
	end
	self:RaidOpenSummary("New")
end

function DKP:RaidToolsCloseSummary()
	self:RaidSubmitSession() 
end
---------------------------------------------------------------------------------------------------
-- RaidGlobalSummary Functions
---------------------------------------------------------------------------------------------------

function DKP:RaidGlobalStatsRunUpdate( wndHandler, wndControl, eMouseButton )
	
	if self.bIsRaidSession == true then
		Print("Cannot run statisctics while there's an active session")
		return
	end
	
	if self.tItems["Raids"]["GlobalStats"] == nil then -- First creation
		local stats = {}
		local raidIDs = {}
		stats.trackedRaids = {}
		for i=1,table.maxn(self.tItems["Raids"]) do
			if self.tItems["Raids"][i] ~= nil then
				table.insert(stats.trackedRaids,self.tItems["Raids"][i].date.osDate)
				table.insert(raidIDs,i)
			end
		end
	-- unique players
		local tempPlayers ={}
		local uniqueCounter = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				if tempPlayers[self.tItems["Raids"][raidIDs[i]].tPlayers[j].name] == nil then
					tempPlayers[self.tItems["Raids"][raidIDs[i]].tPlayers[j].name] = 0
					uniqueCounter = uniqueCounter + 1
				end
			end
		end
		stats.UniquePlayer = uniqueCounter
		stats.UniquePlayerList = tempPlayers
	-- left players
		uniqueCounter = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				if self.tItems["Raids"][raidIDs[i]].tPlayers[j].bLeft == "Left" then
					uniqueCounter = uniqueCounter + 1
				end
			end
		end
		stats.LeftPlayers = uniqueCounter
	-- player DKP spent most
		local highestCost = {}
		highestCost.name = ""
		highestCost.value = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				for k=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot) do
					if math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp) > highestCost.value then
						highestCost.name = self.tItems["Raids"][raidIDs[i]].tPlayers[j].name
						highestCost.value = math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp)
					end
				end
			end
		end
		stats.BiggestSpender = highestCost
	
	-- player items get most
		local mostItems = {}
		mostItems.name = ""
		mostItems.value = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				if #self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot > mostItems.value then
					mostItems.name = self.tItems["Raids"][raidIDs[i]].tPlayers[j].name
					mostItems.value = #self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot
				end
			end
		end
		stats.WellGeared = mostItems
	-- killed bossed
		local bossCounter = 0
		for i=1,table.getn(raidIDs) do
			bossCounter = bossCounter + #self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.names
		end
		stats.KilledBossesCount = bossCounter
	-- killed bosses by name
		local bosses = {}
		bosses["Exp"] = 0
		bosses["Kur"] = 0
		bosses["Maw"] = 0
		bosses["Proto"] = 0
		bosses["Con"] = 0
		bosses["Ohmna"] = 0
		--DS
		bosses["Daemons"] = 0
		bosses["Gloomclaw"] = 0
		bosses["Maelstrom"] = 0
		bosses["Avatus"] = 0
		bosses["Megalith"] = 0
		bosses["Visceralus"] = 0
		bosses["Aileron"] = 0
		bosses["Pyrobane"] = 0
		bosses["Mnemesis"] = 0
		bosses["Hydroflux"] = 0
		local bossesDS = 0
		local bossesGA = 0
		
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.names) do
				local name = self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.names[j]
				
				if name == "Experiment X-89" then
					bosses["Exp"] = bosses["Exp"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Kuralak the Defiler" then
					bosses["Kur"] = bosses["Kur"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Phage Maw" then
					bosses["Maw"] = bosses["Maw"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Phagetech Prototypes" then
					bosses["Proto"] = bosses["Proto"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Phageborn Convergence" then
					bosses["Con"] = bosses["Con"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Dreadphage Ohmna" then
					bosses["Ohmna"] = bosses["Ohmna"] + 1
					bossesGA = bossesGA + 1
				-- DS
				elseif name == "Avatus" then
					bosses["Avatus"] = bosses["Avatus"] + 1
					bossesDS = bossesDS + 1				
				elseif name == "System Daemons" then
					bosses["Daemons"] = bosses["Daemons"] + 1
					bossesDS = bossesDS + 1					
				elseif name == "Gloomclaw" then
					bosses["Gloomclaw"] = bosses["Gloomclaw"] + 1
					bossesDS = bossesDS + 1
				elseif name == "Maelstrom Authority" then
					bosses["Maelstrom"] = bosses["Maelstrom"] + 1	
					bossesDS = bossesDS + 1					
				end
				
			end	
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.pairs) do
				local name = self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.pairs[j]
					if name == "Megalith" then
						bosses["Megalith"] = bosses["Megalith"] + 1
						bossesDS = bossesDS + 1						
					elseif name == "Pyrobane" then
						bosses["Pyrobane"] = bosses["Pyrobane"] + 1
						bossesDS = bossesDS + 1
					elseif name == "Aileron" then
						bosses["Aileron"] = bosses["Aileron"] + 1	
						bossesDS = bossesDS + 1
					elseif name == "Mnemesis" then
						bosses["Mnemesis"] = bosses["Mnemesis"] + 1	
						bossesDS = bossesDS + 1
					elseif name == "Visceralus" then
						bosses["Visceralus"] = bosses["Visceralus"] + 1	
						bossesDS = bossesDS + 1
					elseif name == "Hydroflux" then
						bosses["Hydroflux"] = bosses["Hydroflux"] + 1
						bossesDS = bossesDS + 1
					end
			end

		
		end
		stats.KilledBossesByName = bosses
		stats.KilledBossesByNameGA = bossesGA
		stats.KilledBossesByNameDS = bossesDS
		
	-- dropped loot
		local lootCount = 0 
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				lootCount = lootCount + #self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot
			end
		end
		stats.DistributedLoot = lootCount

	-- total spent dkp
		local totalSpendings = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				for k=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot) do
					totalSpendings = totalSpendings + math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp)
				end
			end
		end
		stats.SpentDKP = totalSpendings
	
	-- total earned dkp
		local totalEarnedDKP = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				totalEarnedDKP = totalEarnedDKP + math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].dkpMod)
				for k=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot) do
					totalEarnedDKP = totalEarnedDKP + math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp)
				end
			end
		end
		stats.EarnedDKP = totalEarnedDKP
	
	-- tracked raids
		
		-----^^^^------
		--DONE ABOVE--
		-----^^^^------
	
	-- avg length
		local totalLength = 0
		for i=1,#raidIDs do
			totalLength = totalLength + self.tItems["Raids"][raidIDs[i]].tMisc.length
		end
		totalLength = math.floor(totalLength/#stats.trackedRaids)
		stats.AvgLength = totalLength
	-- longest length
		local longestTime = 0
		for i=1,#raidIDs do
			if self.tItems["Raids"][raidIDs[i]].tMisc.length > longestTime then longestTime = self.tItems["Raids"][raidIDs[i]].tMisc.length end
		end
		stats.LongestRaid = longestTime
	
		self.tItems["Raids"]["GlobalStats"] = stats
		self:RaidGlobalStatsPushData()
		return
	
	end	-- update based on previous------------------------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<-----------------------------------
	if self.tItems["Raids"]["GlobalStats"] ~= nil then
		local stats = {}
		local raidIDs = {}
		stats.trackedRaids = self.tItems["Raids"]["GlobalStats"].trackedRaids
		for i=1,table.maxn(self.tItems["Raids"]) do
			local found = false
			for j=1,table.getn(stats.trackedRaids) do
				if self.tItems["Raids"][i] ~= nil and self.tItems["Raids"][i].date.osDate == stats.trackedRaids[j] then 
					found = true
				end
			end
			if found == false and self.tItems["Raids"][i] ~= nil then
				table.insert(stats.trackedRaids,self.tItems["Raids"][i].date.osDate)
				table.insert(raidIDs,i)
			end	
		end
		
	
	-- unique players
		local tempPlayers = self.tItems["Raids"]["GlobalStats"].UniquePlayerList
		local uniqueCounter = self.tItems["Raids"]["GlobalStats"].UniquePlayer
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				if tempPlayers[self.tItems["Raids"][raidIDs[i]].tPlayers[j].name] == nil then
					tempPlayers[self.tItems["Raids"][raidIDs[i]].tPlayers[j].name] = 0
					uniqueCounter = uniqueCounter + 1
				end
			end
		end
		stats.UniquePlayer = uniqueCounter
		stats.UniquePlayerList = tempPlayers
	-- left players
		uniqueCounter = 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				if self.tItems["Raids"][raidIDs[i]].tPlayers[j].bLeft == "Left" then
					uniqueCounter = uniqueCounter + 1
				end
			end
		end
		stats.LeftPlayers = uniqueCounter
	-- player DKP spent most
		local highestCost = self.tItems["Raids"]["GlobalStats"].BiggestSpender
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				for k=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot) do
					if math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp) > highestCost.value then
						highestCost.name = self.tItems["Raids"][raidIDs[i]].tPlayers[j].name
						highestCost.value = self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp
					end
				end
			end
		end
		stats.BiggestSpender = highestCost
	
	-- player items get most
		local mostItems = self.tItems["Raids"]["GlobalStats"].WellGeared
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				if #self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot > mostItems.value then
					mostItems.name = self.tItems["Raids"][raidIDs[i]].tPlayers[j].name
					mostItems.value = #self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot
				end
			end
		end
		stats.WellGeared = mostItems
	-- killed bossed
		local bossCounter = self.tItems["Raids"]["GlobalStats"].KilledBossesCount
		for i=1,table.getn(raidIDs) do
			bossCounter = bossCounter + #self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.names
		end
		stats.KilledBossesCount = bossCounter
	-- killed bosses by name
		local bosses = self.tItems["Raids"]["GlobalStats"].KilledBossesByName
		if bosses["Daemons"] == nil then
			bosses["Daemons"] = 0
			bosses["Gloomclaw"] = 0
			bosses["Maelstrom"] = 0
			bosses["Avatus"] = 0
			bosses["Megalith"] = 0
			bosses["Visceralus"] = 0
			bosses["Aileron"] = 0
			bosses["Pyrobane"] = 0
			bosses["Mnemesis"] = 0
			bosses["Hydroflux"] = 0
		end
		local bossesGA = self.tItems["Raids"]["GlobalStats"].KilledBossesByNameGA or 0
		local bossesDS = self.tItems["Raids"]["GlobalStats"].KilledBossesByNameDS or 0
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.names) do
				local name = self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.names[j]
				
				if name == "Experiment X-89" then
					bosses["Exp"] = bosses["Exp"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Kuralak the Defiler" then
					bosses["Kur"] = bosses["Kur"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Phage Maw" then
					bosses["Maw"] = bosses["Maw"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Phagetech Prototypes" then
					bosses["Proto"] = bosses["Proto"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Phageborn Convergence" then
					bosses["Con"] = bosses["Con"] + 1
					bossesGA = bossesGA + 1
				elseif name == "Dreadphage Ohmna" then
					bosses["Ohmna"] = bosses["Ohmna"] + 1
					bossesGA = bossesGA + 1
				-- DS
				elseif name == "Avatus" then
					bosses["Avatus"] = bosses["Avatus"] + 1
					bossesDS = bossesDS + 1				
				elseif name == "System Daemons" then
					bosses["Daemons"] = bosses["Daemons"] + 1
					bossesDS = bossesDS + 1					
				elseif name == "Gloomclaw" then
					bosses["Gloomclaw"] = bosses["Gloomclaw"] + 1
					bossesDS = bossesDS + 1
				elseif name == "Maelstrom Authority" then
					bosses["Maelstrom"] = bosses["Maelstrom"] + 1	
					bossesDS = bossesDS + 1					
				end
				
			end	
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.pairs) do
				local name = self.tItems["Raids"][raidIDs[i]].tMisc.tBossKills.pairs[j]
					if name == "Megalith" then
						bosses["Megalith"] = bosses["Megalith"] + 1
						bossesDS = bossesDS + 1						
					elseif name == "Pyrobane" then
						bosses["Pyrobane"] = bosses["Pyrobane"] + 1
						bossesDS = bossesDS + 1
					elseif name == "Aileron" then
						bosses["Aileron"] = bosses["Aileron"] + 1	
						bossesDS = bossesDS + 1
					elseif name == "Mnemesis" then
						bosses["Mnemesis"] = bosses["Mnemesis"] + 1	
						bossesDS = bossesDS + 1
					elseif name == "Visceralus" then
						bosses["Visceralus"] = bosses["Visceralus"] + 1	
						bossesDS = bossesDS + 1
					elseif name == "Hydroflux" then
						bosses["Hydroflux"] = bosses["Hydroflux"] + 1
						bossesDS = bossesDS + 1
					end
			end

		
		end
		stats.KilledBossesByName = bosses
		stats.KilledBossesByNameGA = bossesGA
		stats.KilledBossesByNameDS = bossesDS
		
		
	-- dropped loot
		local lootCount = self.tItems["Raids"]["GlobalStats"].DistributedLoot
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				lootCount = lootCount + #self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot
			end
		end
		stats.DistributedLoot = lootCount

	-- total spent dkp
		local totalSpendings = self.tItems["Raids"]["GlobalStats"].SpentDKP
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				for k=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot) do
					totalSpendings = totalSpendings + math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].tClaimedLoot[k].dkp)
				end
			end
		end
		stats.SpentDKP = totalSpendings
	
	-- total earned dkp
		local totalEarnedDKP = self.tItems["Raids"]["GlobalStats"].EarnedDKP
		for i=1,table.getn(raidIDs) do
			for j=1,table.getn(self.tItems["Raids"][raidIDs[i]].tPlayers) do
				totalEarnedDKP = totalEarnedDKP + math.abs(self.tItems["Raids"][raidIDs[i]].tPlayers[j].dkpMod)
			end
		end
		stats.EarnedDKP = totalEarnedDKP
	
	-- tracked raids
		
		-----^^^^------
		--DONE ABOVE--
		-----^^^^------
	
	-- avg length	
		
		local avgLen = self.tItems["Raids"]["GlobalStats"].AvgLength * (#self.tItems["Raids"]["GlobalStats"].trackedRaids - #raidIDs)
		
		for i=1,#raidIDs do
			avgLen = avgLen + self.tItems["Raids"][raidIDs[i]].tMisc.length
		end
		avgLen = math.floor(avgLen/#self.tItems["Raids"]["GlobalStats"].trackedRaids)
		stats.AvgLength = avgLen
	-- longest length
		local longestTime = self.tItems["Raids"]["GlobalStats"].LongestRaid
		for i=1,#raidIDs do
			if self.tItems["Raids"][raidIDs[i]].tMisc.length > longestTime then longestTime = self.tItems["Raids"][raidIDs[i]].tMisc.length end
		end
		stats.LongestRaid = longestTime
	
		self.tItems["Raids"]["GlobalStats"] = stats
		self:RaidGlobalStatsPushData()
		
	end
end

function DKP:RaidGlobalStatsPushData()
	if self.tItems["Raids"]["GlobalStats"] == nil then return end
	local PlayerStats = self.wndRaidGlobalStats:FindChild("ContainerPlayerStats")
	local BossStats = self.wndRaidGlobalStats:FindChild("ContainerBossStats")
	local LootStats = self.wndRaidGlobalStats:FindChild("ContainerLootStats")
	local RaidStats = self.wndRaidGlobalStats:FindChild("ContainerRaidStats")
	
	---------------->>>>>PLayer Stats<<<<<---------------------
	PlayerStats:FindChild("ContainerPlayersTotal"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].UniquePlayer)
	PlayerStats:FindChild("ContainerPlayersLeftTotal"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].LeftPlayers)
	PlayerStats:FindChild("ContainerPlayerMostDKPSpent"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].BiggestSpender.name .. " : " .. self.tItems["Raids"]["GlobalStats"].BiggestSpender.value)
	PlayerStats:FindChild("ContainerPlayerWonMostLoot"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].WellGeared.name .. " : " .. self.tItems["Raids"]["GlobalStats"].WellGeared.value)
	---------------->>>>>PLayer Stats<<<<<---------------------
	
	---------------->>>>>Boss Stats<<<<<---------------------
	BossStats:FindChild("ContainerBossKillsTotal"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesCount)
	BossStats:FindChild("ContainerBossKillsTotalGA"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByNameGA)
	BossStats:FindChild("ContainerBossKillsTotalDS"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByNameDS)
	--GA
	BossStats:FindChild("ContainerBossKillsList"):FindChild("Experiment"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Exp"])
	BossStats:FindChild("ContainerBossKillsList"):FindChild("Kuralak"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Kur"])
	BossStats:FindChild("ContainerBossKillsList"):FindChild("Phage"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Maw"])
	BossStats:FindChild("ContainerBossKillsList"):FindChild("Phagetech"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Proto"])
	BossStats:FindChild("ContainerBossKillsList"):FindChild("Phageborn"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Con"])
	BossStats:FindChild("ContainerBossKillsList"):FindChild("Ohmna"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Ohmna"])
	--DS
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("System Daemons"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Daemons"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Gloomclaw"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Gloomclaw"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Maelstrom Authority"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Maelstrom"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Avatus"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Avatus"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Megalith"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Megalith"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Mnemesis"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Mnemesis"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Hydroflux"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Hydroflux"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Pyrobane"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Pyrobane"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Visceralus"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Visceralus"])
	BossStats:FindChild("ContainerBossKillsListDS"):FindChild("Aileron"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].KilledBossesByName["Aileron"])
	---------------->>>>>Boss Stats<<<<<---------------------
	
	---------------->>>>>Loot Stats<<<<<---------------------
	LootStats:FindChild("ContainerLootTotal"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].DistributedLoot)
	LootStats:FindChild("ContainerLootTotalDKPSpent"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].SpentDKP)
	LootStats:FindChild("ContainerLootTotalDKPEarned"):FindChild("Value"):SetText(self.tItems["Raids"]["GlobalStats"].EarnedDKP)
	---------------->>>>>Loot Stats<<<<<---------------------
	
	---------------->>>>>Raid Stats<<<<<---------------------
	RaidStats:FindChild("ContainerRaidTotal"):FindChild("Value"):SetText(#self.tItems["Raids"]["GlobalStats"].trackedRaids)
	local formattedDate = os.date("*t",self.tItems["Raids"]["GlobalStats"].AvgLength)
	if formattedDate ~= nil then RaidStats:FindChild("ContainerRaidAvgLength"):FindChild("Value"):SetText(formattedDate.hour-1 .. ":" .. formattedDate.min .. ":" .. formattedDate.sec)
	formattedDate = os.date("*t",self.tItems["Raids"]["GlobalStats"].LongestRaid)
	RaidStats:FindChild("ContainerRaidLongestRaid"):FindChild("Value"):SetText(formattedDate.hour-1 .. ":" .. formattedDate.min .. ":" .. formattedDate.sec) end
	---------------->>>>>Raid Stats<<<<<---------------------
	
	

end

function DKP:RaidGlobalStatsClose( wndHandler, wndControl, eMouseButton )
	self.wndRaidGlobalStats:Show(false,false)
end


function DKP:RaidGlobalStatsOpen( wndHandler, wndControl, eMouseButton )
	self.wndRaidGlobalStats:Show(true,false)
end



function DKP:RaidGlobalStatsReset( wndHandler, wndControl, eMouseButton )
	self.tItems["Raids"]["GlobalStats"] = nil 
	self.wndRaidGlobalStats:Destroy()
	self.wndRaidGlobalStats = Apollo.LoadForm(self.xmlDoc,"RaidGlobalSummary",nil,self)
end


------------------------------------------------------------------------------------------------------------------------



-- dontspamme_samlie@yahoo.com
-- Converts Lua table to HTML output in table.html file
function tohtml(x)
  return(tohtml_table(x,1))
end

-- Flattens a table to html output
function tohtml_table(x, table_level)
  local k, s,  tcolor
  local html_colors = {
    "#339900","#33CC00","#669900","#666600","#FF3300",
    "#FFCC00","#FFFF00","#CCFFCC","#CCCCFF","#CC66FF",
    "#339900","#33CC00","#669900","#666600","#FF3300",
    "#FFCC00","#FFFF00","#CCFFCC","#CCCCFF","#CC66FF"
  }
  local lineout = {}
  local tablefound = false
    if type(x) == "table" then
    s = ""
    k = 1
    local i, v = next(x)
    while i do
      if (type(v) == "table") then
        if (table_level<10) then
          lineout[k] =  "<b>" .. flat(i) .. "</b>".. tohtml_table(v, table_level + 1)   
        else
          lineout[k] = "<b>MAXIMUM LEVEL BREACHED</b>"
        end
        tablefound = true
      else
        lineout[k] = flat(i) .. " : " .. tohtml_table(v)
      end
      k = k + 1
      i, v = next(x, i)
    end

    for k,line in ipairs(lineout) do
      if (tablefound) then
        s = s .. "<tr><td>" .. line .. "</td></tr>\n"
      else
        s = s .. "<td>" .. line .. "</td>\n"
      end
    end
    if not (tablefound) then
      s = "<table border='1' bgcolor='#FFFFCC' cellpadding='5' cellspacing='0'>" ..
        "<tr>" .. s .. "</tr></table>\n"
    else
      tcolor = html_colors[table_level]
      s = "<table border='3' bgcolor='"..tcolor.."' cellpadding='10' cellspacing='0'>" ..
          s ..  "</table>\n"
    end

    return s 
  end
  if type(x) == "function" then
    return "FUNC"
  end
  if type(x) == "file" then
    return "FILE"
  end

  return tostring(x) 
end

-- Flattens a table to string
function flat(x)  
  return toflat(x,1)
end

-- Flattens a table to string
function toflat(x, tlevel)
  local s
  tlevel = tlevel + 1

  if type(x) == "table" then
    s = "{"
    local i, v = next(x)
    while i do
      if (tlevel < 15) then
        s = s .. i .. " : " .. toflat(v, tlevel) 
      else
        s = s .. i .. " : {#}" 
      end

      i, v = next(x, i)
      if i then
        s = s .. ", " 
      end
    end
    return s .. "}\n"
  end
  if type(x) == "function" then
    return "FUNC"
  end
  if type(x) == "file" then
    return "FILE"
  end

  return tostring(x) 
end
