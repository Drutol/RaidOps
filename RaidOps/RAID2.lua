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
	wndBubble:GetData().nWidthMod = nWidth - 30
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

				wndTile:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(tItemPiece:GetItemQuality()))
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

function DKP:RSInit()
	self.wndRS = Apollo.LoadForm(self.xmlDoc3,"RaidSessions",nil,self)
	self.wndRS:Show(false)
end

function DKP:RSShow(bCrediting,tWho)
	self.wndRS:Show(true,false)
	self.wndRS:ToFront()
	self:RSPopulate(type(bCrediting) == "boolean" and bCrediting or nil,tWho)
end

function DKP:RSHide()
	self.wndRS:Show(false,false)
end

function DKP:RSPopulate(bCrediting,tWho)
	local list = self.wndRS:FindChild("SessionsList")
	list:DestroyChildren()
	for k , raid in ipairs(self.tItems.tRaids or {}) do
		local wnd = Apollo.LoadForm(self.xmlDoc3,"SessionEntry",list,self)
		wnd:FindChild("Date"):SetText(self:ConvertDate(os.date("%x",raid.finishTime)))
		wnd:FindChild("Date"):SetTooltip(os.date("%X",raid.finishTime-raid.length) .. " - " ..  os.date("%X",raid.finishTime))
		if raid.raidType == RAID_GA then 
			wnd:FindChild("Type"):SetText("GA")
			wnd:FindChild("Type"):SetTextColor("xkcdLightishPurple")
		elseif raid.raidType == RAID_DS then 
			wnd:FindChild("Type"):SetText("DS")
		elseif raid.raidType == RAID_Y then 
			wnd:FindChild("Type"):SetText("Y-83")
			wnd:FindChild("Type"):SetTextColor("xkcdLighterPurple")
		end

		if raid.name then wnd:FindChild("SessionName"):SetText(raid.name) else
			raid.name = "Raid Session #"..k
			wnd:FindChild("SessionName"):SetText(raid.name)
		end

		if bCrediting then Apollo.LoadForm(self.xmlDoc3,"TutGlow",wnd:FindChild("ButtonShowAttendees"),self) end

		wnd:SetData({raid = raid,id = k})

	end
	self.wndRS:SetData({bCrediting = bCrediting,tWho = tWho})
	if bCrediting then self.wndRS:FindChild("TitleSessions"):SetText("Choose raid:") else self.wndRS:FindChild("TitleSessions"):SetText("Saved Sessions:") end
	list:ArrangeChildrenVert()
end

function DKP:RSSetRaidName(wndHandler,wndControl,strText)
	if #strText < 20 then
		self.tItems.tRaids[wndControl:GetParent():GetParent():GetData().id].name = strText
	else
		wndControl:SetText(self.tItems.tRaids[wndControl:GetParent():GetParent():GetData().id].name)
		wndControl:SetSel(#wndControl:GetText(),#wndControl:GetText())
	end
end

function DKP:RSShowAttendees(wndHandler,wndControl)
	local raid = wndControl:GetParent():GetData().raid
	local tIDs = {}

	if self.wndRS:GetData().bCrediting then
		for k ,id in ipairs(self.wndRS:GetData().tWho) do
			local player = self.tItems[id]
			local bFound = false
			for j , att in ipairs(player.tAtt or {}) do
				if att.nTime == raid.finishTime then bFound = true break end
			end
			if not self.tItems[id].tAtt then self.tItems[id].tAtt = {} end
			if not bFound then table.insert(self.tItems[id].tAtt,{raidType = raid.raidType,nSecs = raid.length,nTime = raid.finishTime}) end
		end

		for k, child in ipairs(self.wndRS:FindChild("SessionsList"):GetChildren()) do child:FindChild("TutGlow"):Destroy() end
	end

	for k , player in ipairs(self.tItems) do
		for j , att in ipairs(player.tAtt or {}) do
			if att.nTime == raid.finishTime then table.insert(tIDs,k) break end
		end
	end



	self:AddFilterRule(tIDs,wndControl:GetParent():GetData().id)
end

function DKP:RSShowLoot(wndHandler,wndControl)
	local tData = wndControl:GetParent():GetData().raid
	self:LLOpenRaid(tData.finishTime-tData.length,tData.finishTime,tData.name)
end

function DKP:RSIsRaidZone(id)
	if id == 105 or id == 104 or id == 110 or id == 109 or id == 111 or id == 117 or id == 119 or id == 118 or id == 115 or id == 120 or id == 116 --DS
	or id == 148 or id == 149 -- GA
	or id == 475 -- Y-83
	then return true else return false end
end

function DKP:AttGetRaidType()
	local id = GameLib.GetCurrentZoneMap().id
	if id == 148 or id == 149 then return RAID_GA
	elseif id == 105 or id == 104 or id == 110 or id == 109 or id == 111 or id == 117 or id == 119 or id == 118 or id == 115 or id == 120 or id == 116 then return RAID_DS
	elseif id == 475 then return RAID_Y
	else return 0 end
end

function DKP:AttInit()
	self.wndSessionPopUp = Apollo.LoadForm(self.xmlDoc3,"AttendancePopup",nil,self)
	self.wndSessionToolbar = Apollo.LoadForm(self.xmlDoc3,"SessionToolbar",nil,self)
	self.wndSessionPopUp:Show(false)
	self.wndSessionToolbar:Show(false)
	Apollo.RegisterEventHandler("ChangeWorld", "AttZoneChanged", self)
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
	if not self.tItems["settings"].nMinTime then self.tItems["settings"].nMinTime = 5 end
	if not self.tItems["settings"].strResetType then self.tItems["settings"].strResetType = "E" end
	if self.tItems["settings"].bAttRaidQueue == nil then self.tItems["settings"].bAttRaidQueue = true end
	if self.tItems["settings"].bAttStartTA == nil then self.tItems["settings"].bAttStartTA = false end

	self.wndAttSettings:FindChild("AllowPopUp"):SetCheck(self.tItems["settings"].bAttAllowPopUp)
	self.wndAttSettings:FindChild("Min"):SetText(self.tItems["settings"].nTimePer)
	self.wndAttSettings:FindChild("Reset"):SetText(self.tItems["settings"].nReset)
	self.wndAttSettings:FindChild(self.tItems["settings"].strResetType == "D" and "D" or "E"):SetCheck(true)
	self.wndAttSettings:FindChild("MinTime"):SetText(self.tItems["settings"].nMinTime)
	self.wndAttSettings:FindChild("AttRaidQueue"):SetCheck(self.tItems["settings"].bAttRaidQueue)
	self.wndAttSettings:FindChild("AttStartTA"):SetCheck(self.tItems["settings"].bAttStartTA)



	self:AttRestore(self.tItems.raidSession)
	self.tItems.raidSession = nil 
	self:AttUpdateToolbar()
	self:AttCheckReset()
	self:AttCheckZone()
end

function DKP:AttZoneChanged()
	self:delay(5,function(tContext) tContext:AttCheckZone() end)
end

function DKP:AttCheckZone()	
	local tMap = GameLib.GetCurrentZoneMap()
	if tMap and self:RSIsRaidZone(tMap.id) then
		
		nRaidType = self:AttGetRaidType()

		if nRaidSessionStatus == SESSION_STOP then
			self:AttInvokePopUp("Would you like to start raid session?","Yes","No") 
		end
	elseif nRaidSessionStatus == SESSION_PAUSE or nRaidSessionStatus == SESSION_RUN then
		if nRaidSessionStatus == SESSION_RUN then nRaidSessionStatus = SESSION_PAUSE self:AttPause() end 
		self:AttInvokePopUp("What do you want to do with current session?","Resume","End")
	end
end

function DKP:AttUpdatePlayers(nTime)
	local currentPlayers = self:Bid2GetTargetsTable()
	if self.tItems["settings"].bAttRaidQueue then
		for k , player in ipairs(self.tItems.tQueuedPlayers or {}) do
			table.insert(currentPlayers,self.tItems[player].strName)
		end
	end
	table.insert(currentPlayers,GameLib.GetPlayerUnit():GetName())
	-- Alts
	for k , player in ipairs(currentPlayers) do
		if self.tItems["alts"][string.lower(player)] and self.tItems[self.tItems["alts"][string.lower(player)]] then
			currentPlayers[k] = self.tItems[self.tItems["alts"][string.lower(player)]].strName
		end
	end


	for k , player in ipairs(currentPlayers) do
		local bFound = false 
		for j , attendee in ipairs(tPlayersInSession) do
				if attendee.strName == player then 
				attendee.nSecs = attendee.nSecs + nTime 
				bFound = true 
			end
		end
		if not bFound then
			table.insert(tPlayersInSession,{strName = player,nSecs = nTime})
		end
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

function DKP:AttRemoveRaid(wndHandler,wndControl)
	local raid = wndControl:GetParent():GetData().raid
	for k , player in ipairs(self.tItems) do 
		for j , att in ipairs(player.tAtt or {}) do
			if att.nTime == raid.finishTime then table.remove(player.tAtt,j) end
		end
	end
	table.remove(self.tItems.tRaids,wndControl:GetParent():GetData().id)
	self:RSPopulate()
end

function DKP:AttPopUpEnable()
	self.tItems["settings"].bAttAllowPopUp = true
end

function DKP:AttPopUpDisable()
	self.tItems["settings"].bAttAllowPopUp = false
end

function DKP:AttRaidQueueEnable()
	self.tItems["settings"].bAttRaidQueue = true
end

function DKP:AttRaidQueueDisable()
	self.tItems["settings"].bAttRaidQueue = false
end

function DKP:AttStartTAEnable()
	self.tItems["settings"].bAttStartTA = true
end

function DKP:AttStartTADisable()
	self.tItems["settings"].bAttStartTA = false
end

function DKP:AttSetMinTime(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val > 0 then
		self.tItems["settings"].nMinTime = val
	else
		wndControl:SetText(self.tItems["settings"].nMinTime)
	end
end

function DKP:AttSettingsShow()
	self.wndAttSettings:Show(true,false)
	self.wndAttSettings:ToFront()
end

function DKP:AttSettingsHide()
	self.wndAttSettings:Show(false,false)
end

function DKP:AttSetMiniumTime(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val >= 0 and val <= 100 then
		self.tItems["settings"].nTimePer = val
	else
		wndControl:SetText(self.tItems["settings"].nTimePer)
	end
end

function DKP:AttCheckReset()
	if self.tItems["settings"].strResetType == "D" then
		for k , player in ipairs(self.tItems) do
			for j , entry in ipairs(player.tAtt or {}) do
				local diff = os.date("*t",os.time()-entry.nTime)
				if diff.day > self.tItems["settings"].nReset then
					table.remove(self.tItems[k].tAtt,k)
				end
			end
		end
		for k , raid in ipairs(self.tItems.tRaids or {}) do
			local diff = os.date("*t",os.time()-raid.finishTime)
			if diff.day > self.tItems["settings"].nReset then
				table.remove(self.tItems.tRaids,k)
			end
		end
	else
		if self.tItems.tRaids and #self.tItems.tRaids > self.tItems["settings"].nReset then
			for k , raid in ipairs(self.tItems.tRaids or {}) do
				if k > self.tItems["settings"].nReset then
					if raid then
						for i , player in ipairs(self.tItems) do
							for l , entry in ipairs(player.tAtt or {}) do
								if entry.nTime == raid.finishTime then table.remove(player.tAtt,l) end
							end
						end
						table.remove(self.tItems.tRaids,k)
					end
				end
			end
		end
	end

	local tAvailableTimes = {}
	for k , raid in ipairs(self.tItems.tRaids or {}) do
		table.insert(tAvailableTimes,raid.finishTime)
	end
	for k , player in ipairs(self.tItems) do
		for i , tAtt in ipairs(player.tAtt or {}) do
			local bFound = false
			for p , availableTime in ipairs(tAvailableTimes) do
				if availableTime == tAtt.nTime then bFound = true break end
			end
			if not bFound then
				table.remove(self.tItems[k].tAtt,i)
			end
		end
	end
	for k , player in ipairs(self.tItems) do
		for i , tAtt in ipairs(player.tAtt or {}) do
			local counter = 0
			for j , tAttCh in ipairs(player.tAtt or {}) do
				if tAtt.nTime == tAttCh.nTime then counter = counter + 1 end
				if tAtt.nTime == tAttCh.nTime and counter > 1 then table.remove(self.tItems[k].tAtt,i) end
			end
		end
	end
	self:RefreshMainItemList()

end

function DKP:AttInvokePopUp(strQ,strOk,strNo)
	if not self.tItems["settings"].bAttAllowPopUp then return end
	self.wndSessionPopUp:FindChild("Q"):SetText(strQ)
	self.wndSessionPopUp:FindChild("OK"):SetText(strOk)
	self.wndSessionPopUp:FindChild("NOPE"):SetText(strNo)

	self.wndSessionPopUp:ToFront()

	local x,y = Apollo.GetScreenSize()
	local l,t,r,b = self.wndSessionPopUp:GetAnchorOffsets()
	self.wndSessionPopUp:Move( (x/2)-self.wndSessionPopUp:GetWidth()/2, t, self.wndSessionPopUp:GetWidth(), self.wndSessionPopUp:GetHeight())

	self.wndSessionPopUp:Show(true,false)
end

function DKP:AttToggleToolbar()
	self.wndSessionToolbar:Show(not self.wndSessionToolbar:IsShown())
	self:AttUpdateToolbar()
end

function DKP:AttOnAccept(wndHandler,wndControl)
	if nRaidSessionStatus == SESSION_RUN then
		self:AttPause()
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
		--
	end
	self.wndSessionPopUp:Show(false,false)
end

function DKP:AttPopUpClose()
	self.wndSessionPopUp:Show(false,false)
end

function DKP:AttStart()
	if self:RSIsRaidZone(GameLib.GetCurrentZoneMap().id) then
		local players = self:Bid2GetTargetsTable()
		if self.tItems["settings"].bAttRaidQueue then
			for k , player in ipairs(self.tItems.tQueuedPlayers or {}) do
				table.insert(players,self.tItems[player].strName)
			end
		end
		table.insert(players,GameLib.GetPlayerUnit():GetName())
		for k ,player in ipairs(players) do
			players[k] = {strName = player,nSecs = 0}
		end

		-- Alts
		for k , player in ipairs(players) do
			if self.tItems["alts"][string.lower(player.strName)] and self.tItems[self.tItems["alts"][string.lower(player.strName)]] then
				players[k].strName = self.tItems[self.tItems["alts"][string.lower(player)]].strName
			end
		end
		
		tPlayersInSession = players
		nRaidSessionStatus = SESSION_RUN
		nRaidTime = 0

		if self.tItems["settings"].bAttStartTA then self:TimeAwardStart() end

		self.wndSessionToolbar:Show(true,false)

		self.raidTimer = ApolloTimer.Create(30, true, "AttAddTime", self)	
		self.raidPreciseTimer = ApolloTimer.Create(1, true, "AttCheckTime", self)
	else
		self:NotificationStart("You are not in raid zone",3,2)
	end
end

function DKP:AttPause()
	if self.raidTimer then
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
end

function DKP:AttResume()
	nRaidSessionStatus = SESSION_RUN
	self.wndSessionToolbar:Show(true,false)
	self.raidTimer = ApolloTimer.Create(30, true, "AttAddTime", self)
	self.raidPreciseTimer = ApolloTimer.Create(1, true, "AttCheckTime", self)
end

function DKP:AttAddTime()
	self:AttUpdatePlayers(30)
	nRaidTime = nRaidTime + 30
	nTimeFromLastUpdate = 0
end

function DKP:AttCheckTime()
	nTimeFromLastUpdate = nTimeFromLastUpdate + 1
	self:AttUpdateToolbar()
end

function DKP:AttEndSession()
	nRaidTime = nRaidTime + nTimeFromLastUpdate
	if  nRaidTime < self.tItems["settings"].nMinTime * 60  then 
		nRaidSessionStatus = SESSION_STOP
		if self.raidTimer then
			self.raidTimer:Stop()
		end
		if self.raidPreciseTimer then
			self.raidPreciseTimer:Stop()
		end
		self:AttUpdateToolbar()
		self.wndSessionToolbar:FindChild("Timer"):SetText("00:00:00")
		return 
	end
	for k,player in ipairs(tPlayersInSession) do
		player.nSecs = player.nSecs + nTimeFromLastUpdate
	end
	nTimeFromLastUpdate = 0

	if not nRaidType then
		nRaidType = self:AttGetRaidType()
	end

	local time = os.time()

	for k,player in ipairs(tPlayersInSession) do
		if (player.nSecs * 100) / nRaidTime >= self.tItems["settings"].nTimePer then
			local ID = self:GetPlayerByIDByName(player.strName)
			if ID ~= -1 then
				if not self.tItems[ID].tAtt then self.tItems[ID].tAtt = {} end
				table.insert(self.tItems[ID].tAtt,{raidType = nRaidType,nSecs = player.nSecs,nTime = time})
			end
		end
	end

	if self.tItems["settings"].bAttStartTA then self:TimeAwardStop() end

	nRaidSessionStatus = SESSION_STOP
	if self.raidTimer then
		self.raidTimer:Stop()	
	end
	if self.raidPreciseTimer then
		self.raidPreciseTimer:Stop()
	end
	self:AttUpdateToolbar()
	self.wndSessionToolbar:FindChild("Timer"):SetText("00:00:00")
	if not self.tItems.tRaids then self.tItems.tRaids = {} end

	table.insert(self.tItems.tRaids,1,{raidType = nRaidType,finishTime = time,length = nRaidTime})
	self:AttCheckReset()
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
	if self:RSIsRaidZone(GameLib.GetCurrentZoneMap().id) then
		self.raidTimer = ApolloTimer.Create(30, true, "AttAddTime", self)
		self.raidPreciseTimer = ApolloTimer.Create(1, true, "AttCheckTime", self)
	elseif nRaidSessionStatus == SESSION_RUN then
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
			self.wndSessionToolbar:FindChild("Stop"):Enable(true)
			self.wndSessionToolbar:FindChild("PauseResume"):Enable(true)
		elseif nRaidSessionStatus == SESSION_RUN then
			self.wndSessionToolbar:FindChild("PauseResume"):SetText("Pause")

		end

		if nRaidSessionStatus == SESSION_STOP then
			self.wndSessionToolbar:FindChild("Stop"):Enable(false)
			self.wndSessionToolbar:FindChild("Start"):Enable(true)
			self.wndSessionToolbar:FindChild("Running"):Show(false)
			self.wndSessionToolbar:FindChild("PauseResume"):Enable(false)
		elseif nRaidSessionStatus == SESSION_RUN then
			self.wndSessionToolbar:FindChild("Start"):Enable(false)
			self.wndSessionToolbar:FindChild("Stop"):Enable(true)
			self.wndSessionToolbar:FindChild("Running"):Show(true)
			self.wndSessionToolbar:FindChild("PauseResume"):Enable(true)
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


--------------------------------------------------------------------------
-- Groups
--------------------------------------------------------------------------
local ktDefaultGroup =
{
	strName = "EPGP - GA",
	tIDs = {},
	tAllow = 
	{
		DKP = true,
		EPGP = true,
	},
	bExpand = true
}


function DKP:GroupInit()
	self.wndGroupGUI = Apollo.LoadForm(self.xmlDoc3,"Groups",nil,self)
	self.wndGroupGUI:Show(false)

	if self.tItems["settings"].bEnableGroups == nil then self.tItems["settings"].bEnableGroups = false end
	if not self.tItems["settings"].Groups then 
		self.tItems["settings"].Groups = {} 
		table.insert(self.tItems["settings"].Groups,ktDefaultGroup)
	end

	self.wndGroupGUI:FindChild("Enable"):SetCheck(self.tItems["settings"].bEnableGroups)
	self:GroupGUIPopulate()
end

function DKP:GroupGUIShow()
	self.wndGroupGUI:Show(true,false)
end

function DKP:GroupGUIHide()
	self.wndGroupGUI:Show(false,false)
end

function DKP:GroupEnable()
	self.tItems["settings"].bEnableGroups = true
end

function DKP:GroupDisable()
	self.tItems["settings"].bEnableGroups = false
end

function DKP:GroupExpand(wndHandler,wndControl)
	self.tItems["settings"].Groups[wndControl:GetParent():GetData()].bExpand = true
	self:RefreshMainItemList()
end

function DKP:GroupCollapse(wndHandler,wndControl)
	self.tItems["settings"].Groups[wndControl:GetParent():GetData()].bExpand = false
	self:RefreshMainItemList()
end

function DKP:GroupGUIPopulate()
	self.wndGroupGUI:FindChild("List"):DestroyChildren()
	for k , group in ipairs( self.tItems["settings"].Groups) do
		local wnd = Apollo.LoadForm(self.xmlDoc3,"GroupEntry",self.wndGroupGUI:FindChild("List"),self)
		wnd:FindChild("Name"):SetText(group.strName)
		wnd:FindChild("Name"):Enable(false)
		wnd:FindChild("Down"):SetRotation(180)
		wnd:SetData(k)
	end
	local wnd = Apollo.LoadForm(self.xmlDoc3,"GroupEntry",self.wndGroupGUI:FindChild("List"),self)
	wnd:FindChild("Name"):SetText("Input new group name")
	wnd:FindChild("Up"):Show(false)
	wnd:FindChild("Down"):Show(false)
	wnd:FindChild("Rem"):Show(false)

	self:GroupArrangeGroups()
end

function DKP:GroupAdd(wndHandler,wndControl,strText)
	table.insert(self.tItems["settings"].Groups,{strName = strText,tIDs = {},bExpand = true})
	self:GroupGUIPopulate()
end

function DKP:GroupRem(wndHandler,wndControl)
	table.remove(self.tItems["settings"].Groups,wndControl:GetParent():GetData())
	self:GroupGUIPopulate()
end

local prevWord
function DKP:GroupArrangeGroups()
	local list = self.wndGroupGUI:FindChild("List")
	local children = list:GetChildren()
	for k , child in ipairs(children) do
		child:SetAnchorOffsets(0,0,child:GetWidth(),child:GetHeight())
	end
	for k , child in ipairs(children) do
		if k > 1 then
			local l,t,r,b = prevWord:GetAnchorOffsets()
			child:SetAnchorOffsets(0,b-50,child:GetWidth(),b+child:GetHeight()-50)
		end
		prevWord = child
	end
end

function DKP:GroupIsPlayerInAny(ofID)
	for k , group in ipairs(self.tItems["settings"].Groups) do
		for j , id in ipairs(group.tIDs) do
			if id == ofID then return true end
		end
	end
	return false
end

--------------------------------------------------------------------------
-- Group Dialog
--------------------------------------------------------------------------

function DKP:GroupDialogInit()
	self.wndGroupDialog = Apollo.LoadForm(self.xmlDoc3,'PlayerGroupDialog',nil,self)
	self.wndGroupDialog:Show(false)
end

function DKP:GroupDialogShow()

	if not self.wndGroupDialog:IsShown() then 
		self.wndGroupDialog:SetAnchorOffsets(6,15,238,249)
		local tCursor = Apollo.GetMouse()
		self.wndGroupDialog:Move(tCursor.x - 100, tCursor.y - 100, self.wndGroupDialog:GetWidth(), self.wndGroupDialog:GetHeight())
		
	end

	self.wndGroupDialog:SetData(self.wndContext:GetData())
	self:GroupDialogPopulate(self.wndContext:GetData())
end

function DKP:GroupDialogHide()

end

local knDialogEntryHeight = 26

function DKP:GroupDialogPopulate(forID)
	local tActive = {}
	local tAvailable = {}

	for k , group in ipairs(self.tItems["settings"].Groups) do
		local bFound = false
		for j , id in ipairs(group.tIDs) do
			if id == forID then bFound = true break end
		end
		if bFound then
			table.insert(tActive,k)
		else
			table.insert(tAvailable,k)
		end
	end

	self.wndGroupDialog:FindChild("Active"):FindChild("List"):DestroyChildren()
	for k , activeGroup in ipairs(tActive) do
		local wnd = Apollo.LoadForm(self.xmlDoc3,"PlayerGroupDialogEntry",self.wndGroupDialog:FindChild("Active"):FindChild("List"),self)
		wnd:SetText(self.tItems["settings"].Groups[activeGroup].strName)
		wnd:SetData(activeGroup)
	end	

	self.wndGroupDialog:FindChild("Available"):FindChild("List"):DestroyChildren()
	for k , availableGroup in ipairs(tAvailable) do
		local wnd = Apollo.LoadForm(self.xmlDoc3,"PlayerGroupDialogEntry",self.wndGroupDialog:FindChild("Available"):FindChild("List"),self)
		wnd:SetText(self.tItems["settings"].Groups[availableGroup].strName)
		wnd:SetData(availableGroup)
	end

	
	if not self.wndGroupDialog:IsShown() then
		local l,t,r,b = self.wndGroupDialog:GetAnchorOffsets()
		self.wndGroupDialog:SetAnchorOffsets(l,t,r,b+(#tAvailable+#tActive)*knDialogEntryHeight)
	end
	self.wndGroupDialog:FindChild("Active"):FindChild("List"):ArrangeChildrenVert()
	self.wndGroupDialog:FindChild("Available"):FindChild("List"):ArrangeChildrenVert()

	self.wndGroupDialog:Show(true,false)
	self.wndGroupDialog:ToFront()
	
end

function DKP:GroupDialogSwitchGroup(wndHandler,wndControl)
	if wndControl:GetParent():GetParent():GetName() == "Active" then
		for k , id in ipairs(self.tItems["settings"].Groups[wndControl:GetData()].tIDs) do
			if id == self.wndGroupDialog:GetData() then
				table.remove(self.tItems["settings"].Groups[wndControl:GetData()].tIDs,k)
				break
			end
		end
	else
		table.insert(self.tItems["settings"].Groups[wndControl:GetData()].tIDs,self.wndGroupDialog:GetData())
	end
	self:GroupDialogPopulate(self.wndGroupDialog:GetData())
end

-- Group Drag&Drop

function DKP:GroupQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndControl:GetName() == "ListItemGroupBar" then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.PassOn
end

function DKP:GroupOnDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData) --iData is an origin
	if iData > #self.tItems["settings"].Groups and self.tItems["settings"].Groups[iData] then --remove if to ungroupped
		for k , id in ipairs(self.tItems["settings"].Groups[iData].tIDs) do
			if id == wndSource:GetData().id then table.remove(self.tItems["settings"].Groups[iData].tIDs,k) break end
		end
	end
	
	if self.tItems["settings"].Groups[wndControl:GetData()] then
		local bFound = false
		for k , id in ipairs(self.tItems["settings"].Groups[wndControl:GetData()].tIDs) do
			if id == wndSource:GetData().id then bFound = true break end
		end
		if not bFound then table.insert(self.tItems["settings"].Groups[wndControl:GetData()].tIDs,wndSource:GetData().id) end
	end
	self:RefreshMainItemList()
end

function DKP:GroupStartDragDrop(wndHandler,wndControl,eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end
	if wndControl:GetName() ~= "ListItem" then 
		wndControl = wndControl:GetParent()
		if not wndControl or wndControl:GetName() ~= "ListItem" then return end
	end
	if true then
		Apollo.BeginDragDrop(wndControl, "RaidOpsGroupTransfer", wndControl:FindChild("ClassIconBigger"):GetSprite(), wndControl:GetData().nGroupId)
	end
end

-- Group Data Sets

function DKP:DataSetsInit()
	if not self.tItems["settings"].strActiveGroup then self.tItems["settings"].strActiveGroup = "Def" end

	if not self.tItems.tDataSets then 
		self.tItems.tDataSets = {} 
		if not self.tItems.tDataSets["Def"] then self.tItems.tDataSets["Def"] = {} end
		for k , player in ipairs(self.tItems) do
			if not self.tItems.tDataSets["Def"][player.strName] then
				self.tItems.tDataSets["Def"][player.strName] = {EP = player.EP,GP = player.GP,net = player.net,tot = player.tot}
			end
		end
	end
	for k , group in ipairs(self.tItems["settings"].Groups) do
		if not self.tItems.tDataSets[group.strName] then 
			self.tItems.tDataSets[group.strName] = {}
		end
		
		for k , id in ipairs(group.tIDs) do
			if self.tItems[id] and not self.tItems.tDataSets[group.strName][self.tItems[id].strName] then
				self.tItems.tDataSets[group.strName][self.tItems[id].strName] = {EP = self.tItems[id].EP,GP = self.tItems[id].GP,net = self.tItems[id].net,tot = self.tItems[id].tot}
			end
		end

	end
end

function DKP:GetDataSetForGroupPlayer(strGroup,strPlayer)
	if strGroup == "Ungrouped" then strGroup = "Def" end
	if self.tItems.tDataSets[strGroup] then 
		if not self.tItems.tDataSets[strGroup][strPlayer] then --if no data set then create one
			local id = self:GetPlayerByIDByName(strPlayer)
			self.tItems.tDataSets[strGroup][self.tItems[id].strName] = {EP = self.tItems[id].EP,GP = self.tItems[id].GP,net = self.tItems[id].net,tot = self.tItems[id].tot}
		end
		return self.tItems.tDataSets[strGroup][strPlayer]
	end
end

function DKP:CommitDataSetGroupPlayer(strGroup,strPlayer,playerId)
	if strGroup == "Ungrouped" then strGroup = "Def" end
	if self.tItems.tDataSets and self.tItems.tDataSets[strGroup] and self.tItems.tDataSets[strGroup][strPlayer] then
		self.tItems.tDataSets[strGroup][strPlayer] = {EP = self.tItems[playerId].EP,GP = self.tItems[playerId].GP,net = self.tItems[playerId].net,tot = self.tItems[playerId].tot}
	end
end

-- Active group

function DKP:ActiveGroupSwitch(wndHandler,wndControl)
	--swap active data and saved data
	local nGroupId = wndControl:GetParent():GetData() -- new
	local strGroupName = self.tItems["settings"].Groups[nGroupId].strName --new

	local strOldGroupName  -- origin
	local nOldGroupId -- origin

	for k , group in ipairs(self.tItems["settings"].Groups) do
		if group.strName == self.tItems["settings"].strActiveGroup then
			strOldGroupName = group.strName
			nOldGroupId = k
			break
		end
	end




	for k , id in ipairs(self.tItems["settings"].Groups[nOldGroupId].tIDs) do
		self:CommitDataSetGroupPlayer(strOldGroupName,self.tItems[id].strName,id)
	end	

	for k , id in ipairs(self.tItems["settings"].Groups[nGroupId].tIDs) do
		local newDataSet = self:GetDataSetForGroupPlayer(strGroupName,self.tItems[id].strName)
		self.tItems[id].EP = newDataSet.EP
		self.tItems[id].GP = newDataSet.GP
		self.tItems[id].net = newDataSet.net
		self.tItems[id].tot = newDataSet.tot
	end


	-- and change active group
	local strGroup 
	if self.tItems["settings"].Groups[nGroupId] then
		strGroup = self.tItems["settings"].Groups[nGroupId].strName
	else
		strGroup = "Def"
	end
	self.tItems["settings"].strActiveGroup = strGroup
	self:RefreshMainItemList()
end












--------------------------------------------------------------------------
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