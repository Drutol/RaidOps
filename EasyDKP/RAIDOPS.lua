-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2014	 dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------
local DKP = Apollo.GetAddon("EasyDKP")
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
local wndListedNews = {}

function DKP:RaidOpsInit()
	self:AttendanceInit()
	self:HubInit()
	self:LootListInit()
	self:HubSettingsInit()
end

function DKP:HubInit()
	if self.tItems["Hub"] == nil then self.tItems["Hub"] = {} end
	self.wndHub = Apollo.LoadForm(self.xmlDoc2,"RaidOpsHub",nil,self)
	self.wndNews = self.wndHub:FindChild("News")
	self.wndHub:Show(false,true)
	
end



function DKP:HubPopulateInfo()
	-- TopDKP
	local top3Breakdown = self:HubGetTop3Stats()
	local wndTop = self.wndHub:FindChild("Top3")
	local index = 1
	for k,entry in ipairs(top3Breakdown) do
		wndTop:FindChild(tostring(index)):SetText(entry.strName .. "  -  " .. entry.value)
		index = index + 1
	end
	--Classes
	local classBreakdown = self:HubGetClassStats()
	local wndClasses = self.wndHub:FindChild("ClassBreakdown")
	index = 1
	for k,class in ipairs(classBreakdown) do
		wndClasses:FindChild(tostring(index)):FindChild("Icon"):SetSprite(ktStringToIcon[class.key])
		wndClasses:FindChild(tostring(index)):FindChild("Window"):SetText(class.key .. " : " .. class.value)
		index = index + 1
	end
	--Item news
	self:HubPopulateNews()
end

function compare_easyDKPRaidOps(a,b)
  return a.value > b.value
end

function DKP:HubGetClassStats()
	local stats = {}
	stats["Engineer"] = 0
	stats["Esper"] = 0
	stats["Medic"] = 0
	stats["Warrior"] = 0
	stats["Stalker"] = 0
	stats["Spellslinger"] = 0
	for i=0,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if self.tItems[i].class ~= nil then
				if self.tItems[i].class == "Esper" then
					stats["Esper"] =stats["Esper"] + 1
				elseif self.tItems[i].class == "Engineer" then
					stats["Engineer"] = stats["Engineer"] + 1
				elseif self.tItems[i].class == "Medic" then
					stats["Medic"] = stats["Medic"] + 1
				elseif self.tItems[i].class == "Warrior" then
					stats["Warrior"] = stats["Warrior"] + 1
				elseif self.tItems[i].class == "Stalker" then
					stats["Stalker"] = stats["Stalker"] + 1
				elseif self.tItems[i].class == "Spellslinger" then
					stats["Spellslinger"] = stats["Spellslinger"] + 1
				end
			end
		end
	end
	local array = {}
	for key, value in pairs(stats) do
		array[#array + 1] = {key = key, value = value}
	end
	table.sort(array,compare_easyDKPRaidOps)
	return array
end

function DKP:HubGetTop3Stats()
	local arr = {}
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i]~= nil then
			if self.tItems["EPGP"].Enable == 1 then
				table.insert(arr,{strName = self.tItems[i].strName, value = tonumber(self:EPGPGetPRByName(self.tItems[i].strName))})
			else
				table.insert(arr,{strName = self.tItems[i].strName, value = tonumber(self.tItems[i].net)})
			end
		end
	end
	table.sort(arr,compare_easyDKPRaidOps)
	local retarr = {}
	for k,entry in ipairs(arr) do
		table.insert(retarr,entry)
		if k == 3 then break end
	end
	return retarr
end

function DKP:HubPopulateNews()
	local newsItemCount = 5
	self.wndNews:DestroyChildren()
	self.wndListedNews = {}
	local counter = 0
	if self.tItems["Hub"]["News"] == nil then self.tItems["Hub"]["News"] = {} end
	for k,news in ipairs(self.tItems["Hub"]["News"]) do
		local wnd = Apollo.LoadForm(self.xmlDoc2,"NewsItem",self.wndNews,self)
		local item = Item.GetDataFromId(news.itemID)
		Tooltip.GetItemTooltipForm(self, wnd:FindChild("ItemIcon") , item , {bPrimary = true, bSelling = false})
		wnd:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
		wnd:FindChild("ItemIcon"):SetSprite(item:GetIcon())
		wnd:FindChild("Recipent"):SetText(news.looter)
		table.insert(self.wndListedNews,wnd)
		counter = counter + 1
		if counter >= self.tItems["settings"].HubNewsCount then break end
	end
	self.wndNews:ArrangeChildrenVert(0)
end

function DKP:HubShow()
	self.wndRaidSummary:Show(false,false)
	self.wndRaidSelection:Show(false,false)
	self.wndMain:Show(false,false)
	self.wndHub:Show(true,false)
	self:HubPopulateInfo()
end

function DKP:HubClose()
	self.wndHub:Show(false,false)
end

function DKP:HubRefresh()
	self:HubPopulateInfo()
end

function DKP:HubRegisterLoot(strName,strItem)
	if self.ItemDatabase[strItem] ~= nil then
		if self.tItems["Hub"]["News"] == nil then self.tItems["Hub"]["News"] = {} end
		table.insert(self.tItems["Hub"]["News"],{looter = strName , itemID = self.ItemDatabase[strItem].ID})
		if #self.tItems["Hub"]["News"] > 5 then table.remove(self.tItems["Hub"]["News"],1) end
	end
end

function DKP:HubDispatch(wndHandler,wndControl)
	self.wndHub:Show(false,false)
	if wndControl:GetName() == "DKP" then
		self.wndMain:Show(true,false)
	elseif wndControl:GetName() == "Raid" then
		self:RaidShowMainWindow()
	elseif wndControl:GetName() == "Att" then
		self.wndAttendance:Show(true,false)
		self:AttendancePopulate()
	elseif wndControl:GetName() == "LootList" then
		self:LootListShow()
	elseif wndControl:GetName() == "NetworkBidding" then
		self.wndBid2:Show(true,false)
		self.wndBid2:ToFront()
	end
end

function DKP:HubOpenOptions()
	
end

-- Attendance

function DKP:AttendanceInit()
	self.wndAttendance = Apollo.LoadForm(self.xmlDoc2,"AttendanceGrid",nil,self)
	self.wndAttendance:Show(false,true)
	self.wndAttendance:FindChild("Grid"):AddEventHandler("GridSelChange","UpdatePlayerAttendance",self)

end

function DKP:AttendanceShow()
	self.wndAttendance:Show(true,false)
end

function DKP:AttendanceGoHub()
	self.wndAttendance:Show(false,false)
	self.wndHub:Show(true,false)
end

function DKP:AttendanceClose()
	self.wndAttendance:Show(false,false)
end

local ktNextAttendance = {
	["Left"] = "!Left",
	["!Left"] = "NotAtAll",
	["NotAtAll"] = "Left",
}

function DKP:UpdatePlayerAttendance(wndHandler,wndCotrol,iRow,iCol)
	local cellData = self.wndAttendance:FindChild("Grid"):GetCellData(iRow,iCol)
	local grid = self.wndAttendance:FindChild("Grid")
	if cellData then
		local player = self.tItems["Raids"][cellData.raid].tPlayers[cellData.inRaidID]
		self.tItems["Raids"][cellData.raid].tPlayers[cellData.inRaidID].bLeft = ktNextAttendance[player.bLeft]
		player.bLeft = ktNextAttendance[player.bLeft]
		cellData.left = player.bLeft
		if player.bLeft == "Left" then
			grid:SetCellData(iRow, iCol,"","ClientSprites:LootCloseBox_Holo",cellData)
			grid:SetCellImageColor(iRow, iCol,"white") 
		elseif player.bLeft == "!Left" then
			grid:SetCellData(iRow, iCol,"","achievements:sprAchievements_Icon_Complete",cellData)
			grid:SetCellImageColor(iRow, iCol,"white") 
		elseif player.bLeft == "NotAtAll" then
			grid:SetCellData(iRow, iCol,"","ClientSprites:LootCloseBox_Holo",cellData)
			grid:SetCellImageColor(iRow, iCol,"xkcdApple") 
		end
	end
end

function DKP:AttendancePopulate()
	local grid = self.wndAttendance:FindChild("Grid")
	grid:DeleteAll()
	local addedPlayers= {}
	--[[for i=0,table.maxn(self.tItems) do -- Adding rows
		if self.tItems[i] ~= nil and self:string_starts(self.tItems[i].strName, self.wndAttendance:FindChild("Search"):GetText() ~= "Search" and self.wndAttendance:FindChild("Search"):GetText() or self.tItems[i].strName) then
			grid:AddRow(self.tItems[i].strName)
		end
	end]]
	local skippedIDs = 0
	local rowCount = 1
	for k=0,table.maxn(self.tItems["Raids"]) do -- adding cell data
		if self.tItems["Raids"][k] ~= nil then
			if self.AttendanceExpectedRaid == nil or self.AttendanceExpectedRaid == self.tItems["Raids"][k].Raid then
				if self.tItems["settings"].HubCallRaidBy == "Date" then grid:SetColumnText(k+1," "..self.tItems["Raids"][k].date.strDate) else grid:SetColumnText(k+1," "..self.tItems["Raids"][k].name) end
				for i=0,table.maxn(self.tItems) do 
					if self.tItems[i] ~= nil then
						if addedPlayers[self.tItems[i].strName] == nil then
							if self:string_starts(self.tItems[i].strName, self.wndAttendance:FindChild("Search"):GetText() ~= "Search" and self.wndAttendance:FindChild("Search"):GetText() or self.tItems[i].strName) then
								grid:AddRow(self.tItems[i].strName)
								addedPlayers[self.tItems[i].strName] = rowCount
								rowCount = rowCount + 1
							end
						end
						for j=1,#self.tItems["Raids"][k].tPlayers do
							if addedPlayers[self.tItems[i].strName] ~= nil and string.lower(self.tItems[i].strName) == string.lower(self.tItems["Raids"][k].tPlayers[j].name) and self:string_starts(self.tItems[i].strName, self.wndAttendance:FindChild("Search"):GetText() ~= "Search" and self.wndAttendance:FindChild("Search"):GetText() or self.tItems[i].strName) then
								if self.tItems["Raids"][k].tPlayers[j].bLeft == "Left" then
									grid:SetCellData(addedPlayers[self.tItems[i].strName], k+1,"","ClientSprites:LootCloseBox_Holo",{strName = self.tItems[i].strName,raid = k,inRaidID = j, left = "Left"})
								elseif self.tItems["Raids"][k].tPlayers[j].bLeft == "!Left" then
									grid:SetCellData(addedPlayers[self.tItems[i].strName], k+1,"","achievements:sprAchievements_Icon_Complete",{strName = self.tItems[i].strName,raid = k,inRaidID = j, left = "!Left"})
								elseif self.tItems["Raids"][k].tPlayers[j].bLeft == "NotAtAll" then
									grid:SetCellData(addedPlayers[self.tItems[i].strName], k+1,"","ClientSprites:LootCloseBox_Holo",{strName = self.tItems[i].strName,raid = k,inRaidID = j, left = "NotAtAll"})
									grid:SetCellImageColor(addedPlayers[self.tItems[i].strName], k+1,"xkcdApple") 
								end
								break
							elseif j == #self.tItems["Raids"][k].tPlayers and addedPlayers[self.tItems[i].strName] ~= nil then 
								grid:SetCellData(addedPlayers[self.tItems[i].strName], k+1,"","ClientSprites:LootCloseBox_Holo",{strName = self.tItems[i].strName,raid = k,inRaidID = j, left = "NotAtAll"})
								grid:SetCellImageColor(addedPlayers[self.tItems[i].strName], k+1,"xkcdApple") 
							end
						end
					else
						skippedIDs = skippedIDs + 1
					end
				end
			end
			skippedIDs = 0
		end
	end

end

function DKP:AttendanceSearch(wndHandler, wndControl, strText)
	self:AttendancePopulate()
end

function DKP:AttendanceTypeFilterChanged(wndHandler,wndControl)
	if wndControl:GetName() == "GA" then
		self.AttendanceExpectedRaid = "Genetic Archives"
	else
		self.AttendanceExpectedRaid = "Datascape"
	end
	self:AttendancePopulate()
end

function DKP:AttendanceFilterDisabled()
	self.AttendanceExpectedRaid = nil
end

----------------- LootList

function DKP:LootListInit()
	self.wndLootList = Apollo.LoadForm(self.xmlDoc2,"ItemList",nil,self)
	self.wndLootList:Show(false,true)
	self.wndIconList = Apollo.LoadForm(self.xmlDoc2,"TabIconView",self.wndLootList,self)
	self.wndListList = self.wndLootList:FindChild("TabWindow")
	self.wndLootList:FindChild("TabWindow"):AttachTab(self.wndIconList,true)
	self.wndIconList:Lock(true)
	self.wndListList:Lock(true)
	self:LootListIconWindowPopulate()
	self:LootListListWindowPopulate()
end

function DKP:LootListShow()
	self.wndLootList:Show(true,false)
	self:LootListIconWindowPopulate()
	self:LootListListWindowPopulate()
end

function DKP:LootListIconWindowPopulate()
	local icons = self.wndIconList:FindChild("IconWindow")
	icons:DestroyChildren()
	local counter = 0
	local inserted = {}
	for k=table.maxn(self.tItems["Raids"]),1,-1 do
		if self.tItems["Raids"][k] ~= nil then							
			for i=1,#self.tItems["Raids"][k].tPlayers do
				for j=1,#self.tItems["Raids"][k].tPlayers[i].tClaimedLoot do
					local item = Item.GetDataFromId(self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].ID)
					if inserted[self.tItems["Raids"][k].tPlayers[i].name..item:GetName()] == nil or self.tItems["settings"].HubRemDup == 0 then
						local wnd = Apollo.LoadForm(self.xmlDoc2,"ItemIcon",icons,self)
						wnd:FindChild("Icon"):SetSprite(item:GetIcon())
						wnd:FindChild("Icon"):FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
						wnd:FindChild("Recipent"):SetText(self.tItems["Raids"][k].tPlayers[i].name)
						wnd:SetData({itemData = item , raidData = k , cost = self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].dkp, currency = self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].currency})
						Tooltip.GetItemTooltipForm(self, wnd:FindChild("Icon") , item , {bPrimary = true, bSelling = false})
						counter = counter + 1
						if counter >= self.tItems["settings"].HubItemCount then
							icons:ArrangeChildrenTiles(0)
							return
						end
						inserted[self.tItems["Raids"][k].tPlayers[i].name..item:GetName()] = 1
					end
				end
			end
		end
	end
	icons:ArrangeChildrenTiles(0)
end

function DKP:LootListShowIconInfo(wndHandler,wndControl)
	local details = self.wndIconList:FindChild("Details")
	local wndData = wndControl:GetData()
	self.wndIconList:FindChild("ItemInfo"):FindChild("Icon"):SetSprite(wndData.itemData:GetIcon())
	Tooltip.GetItemTooltipForm(self,self.wndIconList:FindChild("ItemInfo"):FindChild("Icon"), wndData.itemData,self)
	self.wndIconList:FindChild("ItemInfo"):FindChild("Icon"):FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(wndData.itemData:GetItemQuality()))
	self.wndIconList:FindChild("ItemInfo"):FindChild("Item"):SetText(wndData.itemData:GetName())
	self.wndIconList:FindChild("ItemInfo"):FindChild("Drops"):FindChild("Count"):SetText(self:LootListGetCountForItem(wndData.itemData:GetName()))
	details:FindChild("Looter"):SetText(wndControl:FindChild("Recipent"):GetText())
	details:FindChild("Date"):SetText(self.tItems["Raids"][wndData.raidData].date.strDate)
	details:FindChild("Cost"):SetText(wndData.cost .. " " .. wndData.currency)
end

function DKP:LootListGetCountForItem(strItem)
	local counter = 0
	for k=table.maxn(self.tItems["Raids"]),1,-1 do
		if self.tItems["Raids"][k] ~= nil then							
			for i=1,#self.tItems["Raids"][k].tPlayers do
				for j=1,#self.tItems["Raids"][k].tPlayers[i].tClaimedLoot do
					if string.lower(string.sub(self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].name,2)) == string.lower(strItem) then counter = counter + 1 end
				end
			end
		end
	end
	return counter
end

function DKP:LootListListWindowPopulate()
	local list = self.wndListList:FindChild("List")
	list:DestroyChildren()
	local counter = 0
	local inserted = {}
	for k=table.maxn(self.tItems["Raids"]),1,-1 do
		if self.tItems["Raids"][k] ~= nil then							
			for i=1,#self.tItems["Raids"][k].tPlayers do
				for j=1,#self.tItems["Raids"][k].tPlayers[i].tClaimedLoot do
					local item = Item.GetDataFromId(self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].ID)
					if inserted[self.tItems["Raids"][k].tPlayers[i].name..item:GetName()] == nil or self.tItems["settings"].HubRemDup == 0 then
						local wnd = Apollo.LoadForm(self.xmlDoc2,"ListItem",list,self)
						
						wnd:FindChild("Icon"):SetSprite(item:GetIcon())
						wnd:FindChild("Icon"):FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
						wnd:FindChild("Looter"):SetText(self.tItems["Raids"][k].tPlayers[i].name)
						wnd:FindChild("Date"):SetText(self.tItems["Raids"][k].date.strDate)
						wnd:FindChild("Cost"):SetText(self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].dkp .. " " .. self.tItems["Raids"][k].tPlayers[i].tClaimedLoot[j].currency)
						Tooltip.GetItemTooltipForm(self,wnd:FindChild("Icon"),item,{bPrimary = true, bSelling = false})
						counter = counter + 1
						if counter >= self.tItems["settings"].HubItemCount then
							list:ArrangeChildrenTiles(0)
							return
						end
						inserted[self.tItems["Raids"][k].tPlayers[i].name..item:GetName()] = 1
					end
				end
			end
		end
	end
	list:ArrangeChildrenVert(0)
end

function DKP:ItemListClose()
	self.wndLootList:Show(false,false)
end

function DKP:LootListBackToHub()
	self.wndLootList:Show(false,false)
	self.wndHub:Show(true,false)
end
--- Settings
function DKP:HubSettingsInit()
	self.wndHubSettings = Apollo.LoadForm(self.xmlDoc2,"HubSettings",nil,self)
	self.wndHubSettings:Show(false,true)
	self:HubSettingsRestore()
end

function DKP:HubSettingsRestore()
	if self.tItems["settings"].HubAutoSession == nil then self.tItems["settings"].HubAutoSession = 0 end
	if self.tItems["settings"].HubAutoSession == 1 then 
		self.wndHubSettings:FindChild("OptionAutoSession"):FindChild("Value"):SetCheck(true)
		Apollo.RegisterEventHandler("Group_Join","HubCheckForAutoSession",self)
	end
	if self.tItems["settings"].HubNewsCount == nil then self.tItems["settings"].HubNewsCount = 5 end
	self.wndHubSettings:FindChild("OptionItemNewsCount"):FindChild("Value"):SetText(self.tItems["settings"].HubNewsCount)
	if self.tItems["settings"].HubItemCount == nil then self.tItems["settings"].HubItemCount = 20 end
	self.wndHubSettings:FindChild("OptionLootItemCount"):FindChild("Value"):SetText(self.tItems["settings"].HubItemCount)
	if self.tItems["settings"].HubCallRaidBy == nil then self.tItems["settings"].HubCallRaidBy = "Date" end
	if self.tItems["settings"].HubCallRaidBy == "Date" then self.wndHubSettings:FindChild("OptionRaidNaming"):FindChild("Date"):SetCheck(true) end
	if self.tItems["settings"].HubCallRaidBy == "Name" then self.wndHubSettings:FindChild("OptionRaidNaming"):FindChild("Name"):SetCheck(true) end
	if self.tItems["settings"].HubRemDup == nil then self.tItems["settings"].HubRemDup = 1 end
	if self.tItems["settings"].HubRemDup == 1 then self.wndHubSettings:FindChild("OptionRemDup"):FindChild("Value"):SetCheck(true) end
	
	self.wndHubSettings:FindChild("SlashCommands"):SetTooltip(" /dkp - For main DKP window \n /sum - For Raid Summaries \n /rops - For RaidOps windo \n")

	
end

function DKP:HubSettingsClose()
	self.wndHubSettings:Show(false,false)
end

function DKP:HubSettingsShow()
	self.wndHubSettings:Show(true,false)
	self.wndHubSettings:ToFront()
end

function DKP:HubSettingsRaidNamingChanged(wndHandler,wndControl)
	self.tItems["settings"].HubCallRaidBy = wndControl:GetName()
end
function DKP:HubSettingsAutoSessionEnable()
	Apollo.RegisterEventHandler("Group_Join","HubCheckForAutoSession",self)
	self.tItems["settings"].HubAutoSession = 1
	if GroupLib.InRaid() and not self.bIsRaidSession then self:RaidOpenSummary("New") end
end

function DKP:HubSettingsAutoSessionDisable()
	Apollo.RemoveEventHandler("Group_Join", self)
	self.tItems["settings"].HubAutoSession = 0
end

function DKP:HubCheckForAutoSession()
	if GroupLib.InRaid() and not self.bIsRaidSession then self:RaidOpenSummary("New") end
end

function DKP:HubSettingsRemDupEnable()
	self.tItems["settings"].HubRemDup = 1
end

function DKP:HubSettingsRemDupDisable()
	self.tItems["settings"].HubRemDup = 0
end

function DKP:HubSettingsSetNewsCount(wndHandler,wndControl,strText)
	if tonumber(strText) then
		local value = tonumber(strText)
		if value > 0 and value <= 50 then
			self.tItems["settings"].HubNewsCount = value
		else
			wndControl:SetText("5")
			self.tItems["settings"].HubNewsCount = 5
		end
	else
		wndControl:SetText("5")
		self.tItems["settings"].HubNewsCount = 5
	end
end

function DKP:HubSettingsSetLootCount(wndHandler,wndControl,strText)
	if tonumber(strText) then
		local value = tonumber(strText)
		if value > 0 and value <= 50 then
			self.tItems["settings"].HubNewsCount = value
		else
			wndControl:SetText("20")
			self.tItems["settings"].HubNewsCount = 20
		end
	else
		wndControl:SetText("20")
		self.tItems["settings"].HubNewsCount = 20
	end
end