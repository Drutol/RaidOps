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
local bRaidSession = false
function DKP:RSIsSession()
	return bRaidSession
end

function DKP:RSInit()
	self.wndRS = Apollo.LoadForm(self.xmlDoc3,"RaidSessions",nil,self)
	Apollo.RegisterEventHandler("ChangeWorld", "RSCheckZone", self)
end

function DKP:RSIsRaidZone()
	return true -- TODO
end

function DKP:RSCheckZone()
	if not bRaidSession then
		if self:RSIsRaidZone(ZONEZONE) then -- TODO
			local players = self:Bid2GetTargetsTable()
			table.insert(players,GameLib.GetPlayerUnit():GetName())
			for k , player in ipairs(players) do
				local tContents = player
				player = {}
				player.id = self:GetPlayerByIDByName(tContents.strName)
				player.tContents = tContents
			end
			self.CurrentRaidSession = RaidSummarySession.create(ZONE,players)
		end 
	end
end