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
end

function DKP:HubInit()
	if self.tItems["Hub"] == nil then self.tItems["Hub"] = {} end
	self.wndHub = Apollo.LoadForm(self.xmlDoc2,"RaidOpsHub",nil,self)
	self.wndNews = self.wndHub:FindChild("News")
	self:HubPopulateInfo()
	

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
			table.insert(arr,{strName = self.tItems[i].strName, value = self.tItems["EPGP"].Enable == 1 and self:EPGPGetPRByName(self.tItems[i].strName) or tonumber(self.tItems[i].net)})
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
	
	if self.tItems["Hub"]["News"] == nil then self.tItems["Hub"]["News"] = {} end
	for k,news in ipairs(self.tItems["Hub"]["News"]) do
		local wnd = Apollo.LoadForm(self.xmlDoc2,"NewsItem",self.wndNews,self)
		local item = Item.GetDataFromId(news.itemID)
		Tooltip.GetItemTooltipForm(self, wnd:FindChild("ItemIcon") , item , {bPrimary = true, bSelling = false})
		wnd:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
		wnd:FindChild("ItemIcon"):SetSprite(item:GetIcon())
		wnd:FindChild("Recipent"):SetText(news.looter)
		
		table.insert(self.wndListedNews,wnd)
	end
	self.wndNews:ArrangeChildrenVert(0)
end

function DKP:HubRefresh()
	self:HubPopulateInfo()
end

function DKP:HubRegisterLoot(strName,strItem)
	Print("Try")
	if self.ItemDatabase[strItem] ~= nil then
		Print("Pass")
		if self.tItems["Hub"]["News"] == nil then self.tItems["Hub"]["News"] = {} end
		table.insert(self.tItems["Hub"]["News"],{looter = strName , itemID = self.ItemDatabase[strItem].ID})
		if #self.tItems["Hub"]["News"] > 5 then table.remove(self.tItems["Hub"]["News"],1) end
	end
end

function DKP:AttendanceInit()
	self.wndAttendance = Apollo.LoadForm(self.xmlDoc2,"AttendanceGrid",nil,self)
	self:AttendancePopulate()
end

function DKP:AttendanceShow()

end

function DKP:AttendancePopulate()
	local grid = self.wndAttendance:FindChild("Grid")
	grid:DeleteAll()
	for i=0,table.maxn(self.tItems) do -- Adding rows
		if self.tItems[i] ~= nil then
			grid:AddRow(self.tItems[i].strName)
		end
	end
	local skippedIDs = 0
	for k=0,table.maxn(self.tItems["Raids"]) do -- adding cell data
		if self.tItems["Raids"][k] ~= nil then
			grid:SetColumnText(k+1," "..self.tItems["Raids"][k].date.strDate)
			for i=0,table.maxn(self.tItems) do 
				if self.tItems[i] ~= nil then
					for j=1,#self.tItems["Raids"][k].tPlayers do
						if string.lower(self.tItems[i].strName) == string.lower(self.tItems["Raids"][k].tPlayers[j].name) then
							if self.tItems["Raids"][k].tPlayers[j].bLeft == "Left" then
								grid:SetCellData(i+1-skippedIDs, k+1,"","ClientSprites:LootCloseBox_Holo","f")
							else
								grid:SetCellData(i+1-skippedIDs, k+1,"","achievements:sprAchievements_Icon_Complete","t")
							end
							break
						elseif j == #self.tItems["Raids"][k].tPlayers then 
							grid:SetCellData(i+1-skippedIDs, k+1,"","ClientSprites:LootCloseBox_Holo","f")
							grid:SetCellImageColor(i+1-skippedIDs, k+1,"xkcdApple") 
						end
					end
				else
					skippedIDs = skippedIDs + 1
				end
			end
			skippedIDs = 0
		end
	end

end

function DKP:AttendanceSearch(wndHandler, wndControl, strText)
	local grid = self.wndAttendance:FindChild("Grid")
	if strText ~= "Search" and strText ~= "" then
		self:AttendancePopulate()
		local remRows = {}
		for k=1,grid:GetRowCount() do
			if not self:string_starts(grid:GetCellText(k,1),strText)  then
				Print(grid:GetCellText(k,1) .. " " .. strText)
				table.insert(remRows,k)
			end
		end
		for l,row in ipairs(remRows) do
			grid:DeleteRow(row)
		end
	else
		self:AttendancePopulate()
	end

end