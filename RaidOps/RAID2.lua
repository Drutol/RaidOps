-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOps
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

--MODULE
local DKP = Apollo.GetAddon("RaidOps")

--Constants

-- ItemBubbleCosntants

local knBubbleDefWidth = 250
local knBubbleDefHeight = 43

local knBubbleMaxWidth = 600
local knBubbleMaxHeight = 210

local knItemTileWidth = 76
local knItemTileHeight = 76
local knItemTileHorzSpacing = 8
local knItemTileVertSpacing = 8
local knItemTilePerRow = 3
local knItemTileRows = 3
 
local knBubbleHorzSpacing = 3
local knBubbleVertSpacing = 3

--

local ktItemCategories = {
	[1] = "Weapon",
	[2] = "Light Armor",
	[3] = "Medium Armor",
	[4] = "Heavy Armor",
}
local RAID_GA = 0
local RAID_DS = 1
local RAID_Y = 2

local SESSION_RUN = 0
local SESSION_PAUSE = 1
local SESSION_STOP = 2


----
--Item Bubble
----

function raidOpsSortBubble(a,b)
	if a:GetData():GetSlot() == nil then return false end
	if b:GetData():GetSlot() == nil then return true end
	return a:GetData():GetSlot() < b:GetData():GetSlot()
end

function DKP:IBDebugInit()
	--self.wndIBD = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",nil,self)
	--self.wndIBD:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 0,nHeightMod = 0})

	
	self.wndInventory = Apollo.LoadForm(self.xmlDoc3,"InventoryItemType",nil,self)
	
	self.wndIBD1 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD1:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD2 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD2:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD3 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD3:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD4 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD4:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD5 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD5:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD6 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD6:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD7 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD7:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})
	self.wndIBD8 = Apollo.LoadForm(self.xmlDoc3,"InventoryItemBubble",self.wndInventory:FindChild("List"),self)
	self.wndIBD8:SetData({bExpanded = false,bPopulated = false,strPlayer = "Drutol Windchaser",eItemCategory = "Weapon",nWidthMod = 1,nHeightMod = 0})

	self:RIRequestRearrange(self.wndInventory:FindChild("List"))
	
end

function DKP:RSDebugInit()
	self.wndRS = Apollo.LoadForm(self.xmlDoc3,"RaidSelection",nil,self)
	local wndDS = Apollo.LoadForm(self.xmlDoc3,"RaidCategoryDS",self.wndRS,self)
	self.wndRS:FindChild("RaidCategoryGA"):AttachTab(wndDS,false)
end

function DKP:IBInit()
	self.wndIBMenu = Apollo.LoadForm(self.xmlDoc3,"TileMenu",nil,self)
	self.wndIBMenu:Show(false)
end

function DKP:IBExpand(wndHandler,wndControl)
	self:IBPopulate(wndControl:GetParent())
	wndControl:GetParent():GetData().bExpanded = true
	self:IBEResize(wndControl:GetParent())
	self:RIRequestRearrange(wndControl:GetParent():GetParent())
	wndControl:GetParent():FindChild("Expand"):SetCheck(true)
	wndControl:GetParent():GetData().bSearchOpen = false
end


function DKP:IBECollapse(wndHandler,wndControl)
	wndControl:GetParent():GetData().bExpanded = false
	self:IBEResize(wndControl:GetParent())
	self:RIRequestRearrange(wndControl:GetParent():GetParent())
	wndControl:GetParent():FindChild("Expand"):SetCheck(false)
end

function DKP:IBEResize(wndBubble)
	local l,t,r,b = wndBubble:GetAnchorOffsets()
	if wndBubble:GetData().bExpanded then
		wndBubble:SetAnchorOffsets(l,t,r+wndBubble:GetData().nWidthMod,b+wndBubble:GetData().nHeightMod)
	else
		wndBubble:SetAnchorOffsets(l,t,l+knBubbleDefWidth,t+knBubbleDefHeight)
	end
	wndBubble:FindChild("ItemGridFrame"):FindChild("ItemGrid"):ArrangeChildrenTiles(0,raidOpsSortBubble)

end

function DKP:IBPopulate(wndBubble)

	if wndBubble:GetData().bPopulated then return end -- Bubble is already filled -> no need to do this again

	local tLoot
	if wndBubble:GetData().tCustomData == nil then
		tLoot = self:RIRequestLootForBubble(wndBubble:GetData())
	else
		tLoot = wndBubble:GetData().tCustomData
	end
	local wndBubbleGrid = wndBubble:FindChild("ItemGridFrame"):FindChild("ItemGrid")
	
	local nUniqueLoot = 0
	
	local tIDCounter = {}
	
	for k,nItemID in ipairs(tLoot) do
		if tIDCounter[nItemID] == nil then
			tIDCounter[nItemID] = true
			nUniqueLoot = nUniqueLoot + 1
		end
	end

	if wndBubble:GetData().clickFunc then
		wndBubble:AddEventHandler("MouseButtonUp",wndBubble:GetData().clickFunc,self)
	end
	
	if wndBubble:GetData().nItems == nil then wndBubble:GetData().nItems = knItemTilePerRow end
	if wndBubble:GetData().nRows == nil then wndBubble:GetData().nRows = knItemTileRows end
	
	--Print(wndBubble:GetData().nRows)
	
	local nWidth = 0
	local nHeight = 120
	local bAddingWidth = true
	local nRows = 1
	for k=2,nUniqueLoot do
		if k >= wndBubble:GetData().nItems then 
			bAddingWidth = false
		end

		if bAddingWidth then 
			nWidth = nWidth + knItemTileWidth + knItemTileHorzSpacing 
		end

		if not bAddingWidth and k%(wndBubble:GetData().nItems) == 0 then 
			if nRows >= wndBubble:GetData().nRows then break end
			nRows = nRows + 1
			nHeight = nHeight + knItemTileHeight + knItemTileVertSpacing	
		end
	end
	wndBubble:GetData().nWidthMod = nWidth
	wndBubble:GetData().nHeightMod =  nHeight
	tIDCounter = {}
	
	for k,nItemID in ipairs(tLoot) do
		local tItemPiece = Item.GetDataFromId(nItemID)
		if tItemPiece then
			if tIDCounter[tItemPiece:GetName()] then
				tIDCounter[tItemPiece:GetName()].nCount = tIDCounter[tItemPiece:GetName()].nCount + 1
				tIDCounter[tItemPiece:GetName()].wnd:FindChild("Count"):SetText("x"..tIDCounter[tItemPiece:GetName()].nCount)
			else
				local wndTile = Apollo.LoadForm(self.xmlDoc3,"BubbleItemTile",wndBubbleGrid,self)
				tIDCounter[tItemPiece:GetName()] = {nCount = 1,wnd = wndTile}
				local ID = tItemPiece:GetItemId()
				local strTooltip = ""
				for k , tooltip in ipairs(wndBubble:GetData().tItemTooltips or {}) do
					if ID == tooltip.ID and not string.find(strTooltip,tooltip.strInfo) and tooltip.strHeader == wndBubble:FindChild("HeaderText"):GetText() then
						strTooltip = strTooltip .. tooltip.strInfo .. " \n"
					end
				end
				if wndBubble:GetData().clickFunc then
					wndTile:AddEventHandler("MouseButtonUp",wndBubble:GetData().clickFunc,self)
				end
				if strTooltip ~= "" then
					wndTile:FindChild("Tooltip"):SetTooltip(strTooltip)
					wndTile:FindChild("Tooltip"):SetData(strTooltip)
					wndTile:FindChild("Tooltip"):Show(true)
				end

				wndTile:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQuality(tItemPiece:GetItemQuality()))
				wndTile:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(tItemPiece:GetIcon())
				if tIDCounter[tItemPiece:GetName()] and tIDCounter[tItemPiece:GetName()].nCount > 1 then
					wndTile:FindChild("Count"):SetText("x"..tIDCounter[tItemPiece:GetName()].nCount)
				end
				wndTile:SetData(tItemPiece)
				Tooltip.GetItemTooltipForm(self,wndTile:FindChild("ItemFrame"):FindChild("ItemIcon"),tItemPiece,{bPrimary = true, bSelling = false})
			end
		end
	end
	wndBubble:GetData().bPopulated = true
end

function DKP:IBPostContents(wndHandler,wndControl)
	self:IBPopulate(wndControl:GetParent())
	local wndBubble = wndControl:GetParent()
	local strItems = ""
	for k , child in ipairs(wndBubble:FindChild("ItemGrid"):GetChildren()) do
		strItems = strItems .. child:GetData():GetChatLinkString()
	end
	ChatSystemLib.Command("/" .. self.tItems["settings"].LL.strChatPrefix .. " " .. wndBubble:FindChild("HeaderText"):GetText())
	ChatSystemLib.Command("/" .. self.tItems["settings"].LL.strChatPrefix .. " " .. strItems)
end

function DKP:IBTileMenuShow(wndHandler,wndControl,eMouseButton)
	if wndControl:GetName() ~= "BubbleItemTile" or eMouseButton ~= GameLib.CodeEnumInputMouse.Right then return end

	local counter = 0
	for word in string.gmatch((wndControl:FindChild("Tooltip"):GetData() or ""),"%S+") do
		counter = counter + 1
	end


	if self.tItems["settings"].LL.strGroup ~= "GroupName" and counter ~= 2  then
		self.wndIBMenu:FindChild("Reass"):Enable(false)
		self.wndIBMenu:FindChild("Rem"):Enable(false)
	else
		self.wndIBMenu:FindChild("Reass"):Enable(true)
		self.wndIBMenu:FindChild("Rem"):Enable(true)
	end
	
	if not self.wndIBMenu:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndIBMenu:Move(tCursor.x - 100, tCursor.y - 100, self.wndIBMenu:GetWidth(), self.wndIBMenu:GetHeight())
	end
	self.wndIBMenu:Show(true,false)
	self.wndIBMenu:ToFront()
	self.wndIBMenu:SetData(wndControl)
end

function DKP:IBTileMenuPost()
	self:IBPostItem(self.wndIBMenu:GetData())
end

function DKP:IBTileMenuReassign()
	local wndControl = self.wndIBMenu:GetData()
	self:ReassShow(wndControl:FindChild("Tooltip"):GetData(),wndControl:GetData())
end

function DKP:IBTileMenuRemove(wndHandler,wndControl)
	wndControl:FindChild("Confirm"):Show(not wndControl:FindChild("Confirm"):IsShown())
end

function DKP:IBTileMenuRemoveConfirm(wndHandler,wndControl)
	wndControl:Show(false)
	local wndControl = self.wndIBMenu:GetData()
	local strName = string.sub(wndControl:FindChild("Tooltip"):GetData(),1,#wndControl:FindChild("Tooltip"):GetData()-2)
	local nGP = tonumber(self:LLRemLog(strName,wndControl:GetData()))
	self:UndoAddActivity(string.format("Removed %s from %s",wndControl:GetData():GetName(),strName),nGP*-1,{[1] = self.tItems[self:GetPlayerByIDByName(strName)]})
	self.tItems[self:GetPlayerByIDByName(strName)].GP = self.tItems[self:GetPlayerByIDByName(strName)].GP - nGP
	self:DetailAddLog("Removed : " .. wndControl:GetData():GetName(),"{GP}",nGP*-1,self:GetPlayerByIDByName(strName))
	self:RefreshMainItemList()
	self:LLPopuplate()
	self.wndIBMenu:Show(false,false)
	
end

function DKP:IBPostItem(wndControl)
	ChatSystemLib.Command("/" .. self.tItems["settings"].LL.strChatPrefix .. " Item :" .. wndControl:GetData():GetChatLinkString())
	ChatSystemLib.Command("/" .. self.tItems["settings"].LL.strChatPrefix .. " Count :" .. wndControl:FindChild("Count"):GetText())
	ChatSystemLib.Command("/" .. self.tItems["settings"].LL.strChatPrefix .. " Winners :" .. wndControl:FindChild("Tooltip"):GetData() or "")
end

----
--Raid Inventory
----

function DKP:RIRequestLootForBubble(tBubbleData)
	local tDebug = {}
	for k=1,math.random(1,10) do
		table.insert(tDebug,math.random(1,60000))
	end
	return tDebug
end

local tPrevOffsets = {}
function DKP:RIRequestRearrange(wndList)
	if tPrevOffsets[wndList] then
		if tPrevOffsets[wndList] == wndList:GetAnchorOffsets() then return end
		tPrevOffsets[wndList] = wndList:GetAnchorOffsets()
	else
		tPrevOffsets[wndList] = wndList:GetAnchorOffsets()
	end
	
	local prevChild
	local highestInRow = {}
	local tRows = {}
	for k,child in ipairs(wndList:GetChildren()) do
		child:SetAnchorOffsets(0,0,child:GetWidth(),child:GetHeight())
	end
	
	for k,child in ipairs(wndList:GetChildren()) do
		if k > 1 then
			local prevL,prevT,prevR,prevB = prevChild:GetAnchorOffsets()
			local newL,newT,newR,newB = child:GetAnchorOffsets()
			
			local prevRow = #tRows
			-- Add next to prev
			newL = prevR + knBubbleHorzSpacing
			newR = newL + child:GetWidth()
			newT = prevT
			newB = prevT + child:GetHeight()
			
			
			local bNewRow = false
			
			if newR >= wndList:GetWidth() or child:GetData().bForceNewRow then -- New Row
				bNewRow = true
				
				newL = knBubbleHorzSpacing
				newR = newL + child:GetWidth()

				-- Move under highestInRow
				local highL,highT,highR,highB = tRows[prevRow].wnd:GetAnchorOffsets()
				
				newT = highB + knBubbleVertSpacing
				newB = newT + child:GetHeight()
			end
			
		
			
			if child:GetHeight() > tRows[prevRow].nHeight then
				tRows[prevRow] = {wnd = child , nHeight = child:GetHeight()}
			end
			
	
			child:SetAnchorOffsets(newL,newT,newR,newB)
			prevChild = child
			if bNewRow then 
				table.insert(tRows,{wnd = child , nHeight = child:GetHeight()})		
			end
		else
			prevChild = child
			table.insert(tRows,{wnd = child , nHeight = child:GetHeight()})
		end
	end
end

function DKP:IBAddTileClickHandler(wndBubble,func)
	if wndBubble:GetData().bPopulated then
		for k , tile in ipairs(wndBubble:FindChild("ItemGrid"):GetChildren()) do
			tile:AddEventHandler("MouseButtonUp",func,self)
		end
	else
		wndBubble:GetData().clickFunc = func
	end
end

---------------------------------------------------------------------------------
--Raid Sessions(summaries) Defs
---------------------------------------------------------------------------------
local ktManipulationEvents = 
{
	-->> {nAmount = ?}
	[1] = "Gained EP",
	[2] = "Lost EP",
	[3] = "Gained GP",
	[4] = "Lost GP",
	--<<
}
local ktRaidEvents =
{
	[1] = "Session started.", -- {nCount = ?}
	[2] = "Player joined.", -- {nID = ?}
	[3] = "Player left.", -- {nID = ?}
	[4] = "Boss encounter started.", -- {strBoss = ?}
	[5] = "Boss encounter finished.", -- {strBoss = ?}
	[6] = "Session ended.", -- {nCount = ?}
}
---------------------------------------------------------------------------------
--Raid Sessions(summaries) Session and Player class
---------------------------------------------------------------------------------
RaidSummarySession = {}
RaidSummarySession.__index = RaidSummarySession

RaidSummaryPlayer = {}
RaidSummaryPlayer.__index = RaidSummaryPlayer

function RaidSummaryPlayer.create(nID,tPlayer)
	local player = {}
	setmetatable(player,RaidSummaryPlayer) 
	player.ID = nID
	player.starting = {}
	player.starting.EP = tPlayer.EP
	player.starting.GP = tPlayer.GP
	player.starting.Hrs = tPlayer.Hrs
	player.nStart = os.time()

	player.tTimeline = {}
	return player
end

function RaidSummaryPlayer.CreateFromTable(tData)
	local player = {}
	setmetatable(player,RaidSummaryPlayer) 
	player.ID = tData.ID
	player.starting = {}
	player.starting.EP = tData.starting.EP
	player.starting.GP = tData.starting.GP
	player.starting.Hrs = tData.starting.Hrs
	player.nStart = tData.nStart

	player.tTimeline = {}
	return player
end

function RaidSummaryPlayer:RegisterEPManipulation(nAmount)
	table.insert(self.tTimeline,{eventID = nAmount >= 0 and 1 or 2})
end

function RaidSummaryPlayer:RegisterGPManipulation(nAmount)
	table.insert(self.tTimeline,{eventID = nAmount >= 0 and 3 or 4})
end

function RaidSummaryPlayer:End()
	self.nEnd = os.time()
end

function RaidSummaryPlayer:to_t()
	local table = {}
	table.ID = self.ID
	table.starting = {}
	table.starting.EP = self.EP
	table.starting.GP = self.GP
	table.starting.Hrs = self.Hrs
	table.nStart = self.nStart
	return table()
end


function RaidSummarySession.create(nZone,tInitialPlayers)
   local session = {}            
   setmetatable(session,RaidSummarySession) 
   session.nZone = nZone    
   session.tPlayers = {}
   for k , player in ipairs(tInitialPlayers) do
   		table.insert(session.tPlayers,RaidSummaryPlayer.create(player.id,player.tContents))
   end
   session.nStart = os.time()

   -- Init
   session:RegisterEvent(1,{nCount = #tInitialPlayers})
   return session
end

function RaidSummarySession.resume(tData)
   local session = {}            
   setmetatable(session,RaidSummarySession) 
   session.nZone = tData.nZone    
   session.tPlayers = {}
   for k , player in ipairs(tData.tPlayers) do
   		table.insert(session.tPlayers,RaidSummaryPlayer.CreateFromTable(player))
   end
   session.nStart = tData.nStart

   return session
end

function RaidSummarySession:PlayerJoined(tPlayer)
	table.insert(self.tPlayers,RaidSummaryPlayer.create(tPlayer.id,tPlayer.tContents))
	self:RegisterEvent(2,{nID = tPlayer.id})
end

function RaidSummarySession:PlayerLeft(nID)
	for k , player in ipairs(self.tPlayers) do
		if player.ID == tPlayer.id then
			player.nEnd = os.time()
		end
	end
	self:RegisterEvent(3,{nID = nID})
end

function RaidSummarySession:RegisterEvent(eID,tArgs)
	-- Check if args are passed correctly
	if eID == 1 or eID == 6 then
		if not tArgs.nCount  then return end
	elseif eID == 2 or eID == 3 then
		if not tArgs.nID then return end
	elseif eID == 4 or eID == 5 then
		if not tArgs.strBoss then return end
	end
	-- insert event to timeline
	table.insert(self.tTimeline,{eID = eID,tArgs = tArgs,nTime = os.time()})
end

function RaidSummarySession:GetPlayerByID(nID)
	for k , player in ipairs(self.tPlayers) do 
		if player.ID == nID then return player end
	end
end

function RaidSummarySession:GetSaveState()
	local tSave = {}
	tSave.nZone = self.nZone
	tSave.nTime = self.nTime
	tSave.tPlayers = {}
	for k , player in ipairs(self.tPlayers) do
		table.insert(tSave.tPlayers,player:to_t())
	end
	return tSave
end

function RaidSummarySession:End(tSample)
	self.nEnd = os.time()
	-- Prepare final table
	local tExport = {}
	-- DO stuff
	return tExport
end
---------------------------------------------------------------------------------
--Raid Sessions(summaries) 
---------------------------------------------------------------------------------
local nRaidTime = 0
local tPlayersInSession = {}
local nRaidType = nil
local nRaidSessionStatus = 2
local nTimeFromLastUpdate = 0


function DKP:RSIsSession()
	return bRaidSession
end

function DKP:RSInit()
	self.wndRS = Apollo.LoadForm(self.xmlDoc3,"RaidSessions",nil,self)
	Apollo.RegisterEventHandler("ChangeWorld", "RSCheckZone", self)
	

end

function DKP:RSIsRaidZone(id)
	if id == 105 or id == 148 or id == 149 then return true else return false end
end

function DKP:RSCheckZone()
	if not bRaidSession then
		local tMap = GameLib.GetCurrentZoneMap()
		if self:RSIsRaidZone(tMap.id) then
			local players = self:Bid2GetTargetsTable()
			table.insert(players,GameLib.GetPlayerUnit():GetName())
			for k ,player in ipairs(players) do
				player.nSecs = 0
			end

		end
		--[[if self:RSIsRaidZone(ZONEZONE) then -- TODO
			local players = self:Bid2GetTargetsTable()
			table.insert(players,GameLib.GetPlayerUnit():GetName())
			for k , player in ipairs(players) do
				local tContents = player
				player = {}
				player.id = self:GetPlayerByIDByName(tContents.strName)
				player.tContents = tContents
			end
			self.CurrentRaidSession = RaidSummarySession.create(ZONE,players)
		end]] 
	end
end

function DKP:AttInit()
	self.wndSessionPopUp = Apollo.LoadForm(self.xmlDoc3,"AttendancePopup",nil,self)
	self.wndSessionToolbar = Apollo.LoadForm(self.xmlDoc3,"SessionToolbar",nil,self)
	self.wndSessionPopUp:Show(false)
	self.wndSessionToolbar:Show(false)
	Apollo.RegisterEventHandler("ChangeWorld", "AttCheckZone", self)
	Apollo.RegisterTimerHandler(30,"AttAddTime",self)
	Apollo.RegisterTimerHandler(1,"AttCheckTime",self)



	if self.tItems.wndSessionToolbarLoc ~= nil and self.tItems.wndSessionToolbarLoc.nOffsets[1] ~= 0 then 
		self.wndSessionToolbar:MoveToLocation(WindowLocation.new(self.tItems.wndSessionToolbarLoc))
		self.tItems.wndSessionToolbarLoc = nil
	end

	nRaidSessionStatus = SESSION_STOP


	self.wndAttSettings = Apollo.LoadForm(self.xmlDoc3,"AttSettings",nil,self)
	self.wndAttSettings:Show(false)


	if self.tItems["settings"].bAttAllowPopUp == nil then self.tItems["settings"].bAttAllowPopUp = true end
	if not self.tItems["settings"].nTimePer then self.tItems["settings"].nTimePer = 75 end
	if not self.tItems["settings"].nReset then self.tItems["settings"].nReset = 14 end
	if not self.tItems["settings"].strResetType then self.tItems["settings"].strResetType = "D" end

	self.wndAttSettings:FindChild("AllowPopUp"):SetCheck(self.tItems["settings"].bAttAllowPopUp)
	self.wndAttSettings:FindChild("Min"):SetText(self.tItems["settings"].nTimePer)
	self.wndAttSettings:FindChild("Reset"):SetText(self.tItems["settings"].nReset)
	self.wndAttSettings:FindChild(self.tItems["settings"].strResetType == "D" and "D" or "E")



	self:AttRestore(self.tItems.raidSession)
	self.tItems.raidSession = nil 
	self:AttUpdateToolbar()
	self:AttCheckReset()
	self:AttCheckZone()
end

function DKP:AttCheckZone(lol)
	--local tMap = GameLib.GetCurrentZoneMap()
	local tMap = {id = lol}
	if self:RSIsRaidZone(tMap.id) then
		
		if tMap.id == 148 or tMap.id == 149 then nRaidType = RAID_GA
		elseif tMap.id == 105 then nRaidType = RAID_DS
		elseif tMap.id == 9999 then nRaidType = RAID_Y
		end

		if nRaidSessionStatus == SESSION_STOP then
			self:AttInvokePopUp("Would you like to start raid session?","Yes","No") 
		elseif nRaidSessionStatus == SESSION_PAUSE then
			self:AttInvokePopUp("Would you like to resume raid session?","Yes","No") 
		end
	elseif nRaidSessionStatus == SESSION_PAUSE or nRaidSessionStatus == SESSION_RUN then
		if nRaidSessionStatus == SESSION_RUN then nRaidSessionStatus = SESSION_PAUSE self:AttPause() end 
		self:AttInvokePopUp("What do you want to do with current session?","Resume","End")
	end
end

function DKP:AttSettingsSetResetType(wndHandler,wndControl)
	self.tItems["settings"].strResetType = wndControl:GetName()
	self:AttCheckReset()
end

function DKP:AttSetResetValue(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val > 0 then
		self.tItems["settings"].nReset = val
		self:AttCheckReset()
	else
		wndControl:SetText(self.tItems["settings"].nReset)
	end
end

function DKP:AttPopUpEnable()
	self.tItems["settings"].bAttAllowPopUp = true
end

function DKP:AttPopUpDisable()
	self.tItems["settings"].bAttAllowPopUp = false
end

function DKP:AttSettingsShow()
	self.wndAttSettings:Show(true,false)
end

function DKP:AttCheckReset()
	if self.tItems["settings"].strResetType == "D" then
		for k , player in ipairs(self.tItems) do
			for j , entry in ipairs(player.tAtt or {}) do
				local diff = os.date("*t",os.time()-entry.nTime)
				if diff.days > self.tItems["settings"].nReset then
					table.remove(player.tAtt,k)
				end
			end
		end
		for k , raid in ipairs(self.tItems.tRaids or {}) do
			local diff = os.date("*t",os.time()-raid.finishTime)
			if diff.days > self.tItems["settings"].nReset then
				table.remove(player.tAtt,k)
			end
		end
	else
		if #self.tItems.tRaids > self.tItems["settings"].nReset then
			for j = self.tItems["settings"].nReset,#self.tItems.tRaids or 0 do
				local raid = self.tItems.tRaids[j]
				if raid then
					for i , player in ipairs(self.tItems) do
						for l , entry in ipairs(player.tAtt or {}) do
							if entry.nTime == raid.finishTime then table.remove(player.tAtt,l) break end
						end
					end
					table.remove(self.tItems.tRaids,self.tItems["settings"].nReset)
				end
			end
		end
	end
	self:RefreshMainItemList()
end

function DKP:AttInvokePopUp(strQ,strOk,strNo)
	self.wndSessionPopUp:FindChild("Q"):SetText(strQ)
	self.wndSessionPopUp:FindChild("OK"):SetText(strOk)
	self.wndSessionPopUp:FindChild("NOPE"):SetText(strNo)


	local x,y = Apollo.GetScreenSize()
	local l,t,r,b = self.wndSessionPopUp:GetAnchorOffsets()
	self.wndSessionPopUp:Move( (x/2)-self.wndSessionPopUp:GetWidth()/2, t, self.wndSessionPopUp:GetWidth(), self.wndSessionPopUp:GetHeight())

	self.wndSessionPopUp:Show(true,false)
end

function DKP:AttToggleToolbar()
	self.wndSessionToolbar:Show(not self.wndSessionToolbar:IsShown())
end

function DKP:AttOnAccept(wndHandler,wndControl)
	if nRaidSessionStatus == SESSION_RUN then
		self:AttEndSession()
	elseif nRaidSessionStatus == SESSION_PAUSE then
		self:AttResume()
	elseif nRaidSessionStatus == SESSION_STOP then
		self:AttStart()
	end
	self.wndSessionPopUp:Show(false,false)
end

function DKP:AttOnReject(wndHandler,wndControl)
	if nRaidSessionStatus == SESSION_RUN then
		self:AttEndSession()
	elseif nRaidSessionStatus == SESSION_PAUSE then
		self:AttEndSession()
	elseif nRaidSessionStatus == SESSION_STOP then
		self:AttStart()
	end
	self.wndSessionPopUp:Show(false,false)
end

function DKP:AttPopUpClose()
	self.wndSessionPopUp:Show(false,false)
end

function DKP:AttStart()
	if self:RSIsRaidZone(GameLib.GetCurrentZoneMap().id) then
		local players = self:Bid2GetTargetsTable()
		for k=1,10 do
			table.insert(players,self.tItems[math.random(1,40)].strName)
		end
		table.insert(players,GameLib.GetPlayerUnit():GetName())
		for k ,player in ipairs(players) do
			players[k] = {strName = player,nSecs = 0}
		end
		
		tPlayersInSession = players
		nRaidSessionStatus = SESSION_RUN
		nRaidTime = 0

		self.wndSessionToolbar:Show(true,false)

		self.raidTimer = ApolloTimer.Create(30, true, "AttAddTime", self)	
		self.raidPreciseTimer = ApolloTimer.Create(1, true, "AttCheckTime", self)
	else
		self:NotificationStart("You are not in raid zone",3,2)
	end
end

function DKP:AttPause()
	nRaidSessionStatus = SESSION_PAUSE
	for k,player in ipairs(tPlayersInSession) do
		player.nSecs = player.nSecs + nTimeFromLastUpdate
	end
	nRaidTime = nRaidTime + nTimeFromLastUpdate
	nTimeFromLastUpdate = 0

	self.raidTimer:Stop()
	self.raidPreciseTimer:Stop()
	self:AttUpdateToolbar()
end

function DKP:AttResume()
	nRaidSessionStatus = SESSION_RUN
	self.raidTimer = ApolloTimer.Create(30, true, "AttAddTime", self)
	self.raidPreciseTimer = ApolloTimer.Create(1, true, "AttCheckTime", self)
end

function DKP:AttAddTime()
	for k,player in ipairs(tPlayersInSession) do
		player.nSecs = player.nSecs + 30
	end
	nRaidTime = nRaidTime + 30
	nTimeFromLastUpdate = 0
end

function DKP:AttCheckTime()
	nTimeFromLastUpdate = nTimeFromLastUpdate + 1
	self:AttUpdateToolbar()
end

function DKP:AttEndSession()
	nRaidTime = nRaidTime + nTimeFromLastUpdate
	for k,player in ipairs(tPlayersInSession) do
		player.nSecs = player.nSecs + nTimeFromLastUpdate
	end
	nTimeFromLastUpdate = 0

	local time = os.time()

	for k,player in ipairs(tPlayersInSession) do
		
		Print((player.nSecs * 100) / nRaidTime)
		if (player.nSecs * 100) / nRaidTime > 75 then
			local ID = self:GetPlayerByIDByName(player.strName)
			if ID ~= -1 then
				if not self.tItems[ID].tAtt then self.tItems[ID].tAtt = {} end
				table.insert(self.tItems[ID].tAtt,{raidType = nRaidType,nSecs = player.nSecs,nTime = time})
			end
		end
	end

	nRaidSessionStatus = SESSION_STOP
	self.raidTimer:Stop()
	self.raidPreciseTimer:Stop()
	self:AttUpdateToolbar()
	if not self.tItems.tRaids then self.tItems.tRaids = {} end

	table.insert(self.tItems.tRaids,{raidType = nRaidType,finishTime = time,length = nRaidTime})
end

function DKP:AttGetSavePackage()
	if nRaidSessionStatus == SESSION_RUN or nRaidSessionStatus == SESSION_PAUSE then 
		local pkg = {}
		pkg.players = tPlayersInSession
		pkg.nRaidTime = nRaidTime + nTimeFromLastUpdate
		pkg.nRaidType = nRaidType
		pkg.nRaidSessionStatus = nRaidSessionStatus
		pkg.time = os.time()
		return pkg
	end
end

function DKP:AttRestore(pkg)
	if not pkg then return end
	local timeDiff = os.time() - pkg.time
	

	tPlayersInSession = pkg.players
	nRaidType = pkg.nRaidType
	nRaidTime = pkg.nRaidTime 
	nRaidSessionStatus = pkg.nRaidSessionStatus

	for k,player in ipairs(tPlayersInSession) do
		player.nSecs = player.nSecs + timeDiff
		nRaidTime = nRaidTime + timeDiff
	end
	if self:RSIsRaidZone(148--[[GameLib.GetCurrentZoneMap().id]]) then
		--self:NotificationStart("Raid Session resumed , time difference : " .. timeDiff,10,5)
		
		self.raidTimer = ApolloTimer.Create(30, true, "AttAddTime", self)
		self.raidPreciseTimer = ApolloTimer.Create(1, true, "AttCheckTime", self)
	else
		self:AttInvokePopUp("What do you want to do with current session?","Pause","End")
	end
end

function DKP:AttUpdateToolbar()
	if self.wndSessionToolbar:IsShown() then
		self.wndSessionToolbar:FindChild("Running"):Show(nRaidSessionStatus == SESSION_RUN and true or false)
		local diff = os.date("*t",nRaidTime+nTimeFromLastUpdate)
		self.wndSessionToolbar:FindChild("Timer"):SetText((diff.hour-1 <=9 and "0" or "" ) .. (diff.hour-1 < 0 and "0" or diff.hour-1) .. ":" .. (diff.min <=9 and "0" or "") .. diff.min .. ":".. (diff.sec <=9 and "0" or "") .. diff.sec)
		
		if nRaidSessionStatus == SESSION_PAUSE then
			self.wndSessionToolbar:FindChild("PauseResume"):SetText("Resume")
		elseif nRaidSessionStatus == SESSION_RUN then
			self.wndSessionToolbar:FindChild("PauseResume"):SetText("Pause")
		end

		if nRaidSessionStatus == SESSION_STOP then
			self.wndSessionToolbar:FindChild("Stop"):Enable(false)
			self.wndSessionToolbar:FindChild("Start"):Enable(true)
			self.wndSessionToolbar:FindChild("Running"):Show(false)
		elseif nRaidSessionStatus == SESSION_RUN then
			self.wndSessionToolbar:FindChild("Start"):Enable(false)
			self.wndSessionToolbar:FindChild("Stop"):Enable(true)
			self.wndSessionToolbar:FindChild("Running"):Show(true)
		end

	end
end

function DKP:AttPauseResume()
	if nRaidSessionStatus == SESSION_PAUSE then
		self:AttResume()
	elseif nRaidSessionStatus == SESSION_RUN then
		self:AttPause()
	end
end