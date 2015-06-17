-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOps LootDivison
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


require "Window"
 
-----------------------------------------------------------------------------------------------
-- ML Module Definition
-----------------------------------------------------------------------------------------------
local ML = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knItemTileWidth = 76
local knItemTileHeight = 76

local knItemTileHorzSpacing = 8
local knItemTileVertSpacing = 8
 
local knBubbleDefWidth = 250
local knBubbleDefHeight = 43

local knRecipientHorzSpacing = 10
local knRecipientVertSpacing = 20

local knRecipientTileWidth = 52
local knRecipientTileHeight = 52

local knRecipientEntryWidth = 221
local knRecipientEntryHeight = 86

local ktStringToNewIconOrig =
{
	["Medic"]       	= "BK3:UI_Icon_CharacterCreate_Class_Medic",
	["Esper"]       	= "BK3:UI_Icon_CharacterCreate_Class_Esper",
	["Warrior"]     	= "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	["Stalker"]     	= "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	["Engineer"]    	= "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	["Spellslinger"]  	= "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
}

local ktRoleStringToIcon =
{
	["DPS"] = "IconSprites:Icon_Windows_UI_CRB_Attribute_BruteForce",
	["Heal"] = "IconSprites:Icon_Windows_UI_CRB_Attribute_Health",
	["Tank"] = "IconSprites:Icon_Windows_UI_CRB_Attribute_Shield",
	["None"] = "",
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

local ktClassStringToId =
{
	["Medic"]   		= GameLib.CodeEnumClass.Medic,
    ["Esper"]			= GameLib.CodeEnumClass.Warrior,
	["Warrior"]			= GameLib.CodeEnumClass.Esper,
	["Stalker"]			= GameLib.CodeEnumClass.Stalker,
	["Engineer"]		= GameLib.CodeEnumClass.Engineer,
	["Spellslinger"]	= GameLib.CodeEnumClass.Spellslinger,
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ML:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function ML:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ML OnLoad
-----------------------------------------------------------------------------------------------
function ML:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("RaidOpsLootDivison.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ML OnDocLoaded
-----------------------------------------------------------------------------------------------
function ML:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		Apollo.RegisterEventHandler("MasterLootUpdate","CreateLootTable",self)
		Apollo.RegisterEventHandler("Group_Updated", "UpdateRecipients", self)


		self.wndMasterLoot = Apollo.LoadForm(self.xmlDoc,"MasterLootWindow",nil,self)


		--self.wndMasterLoot:Show(false)

		self.wndLooterList = self.wndMasterLoot:FindChild("PlayerPool"):FindChild("RecipientsList")
		self.wndRandomList = self.wndMasterLoot:FindChild("RandomPool"):FindChild("List")
		self.wndLootList = self.wndMasterLoot:FindChild("ItemPool"):FindChild("List")

		self.wndMasterLoot:FindChild("Pools"):ArrangeChildrenVert()

		--for result , id in pairs(Apollo.DragDropQueryResult) do
		--	Print(result .. " " .. id)
		--end
		self:RestoreSettings()
		self.tRandomPool = {}
		self.tPlayerPool = {}
		--for k=1 , 20 do 
		--	Apollo.LoadForm(self.xmlDoc,"RecipientEntry",self.wndLooterList,self)
		--end
		self:CreateRecipients()
		self:DrawRecipients()
		self:ArrangeTiles(self.wndLooterList)
		--Debug
		--local wnd = Apollo.LoadForm(self.xmlDoc,"BubbleItemTile",self.wndLootList,self)
		--wnd:SetData({itemDrop = Item.GetDataFromId(45323),nLootId = 24})
		self:CreateLootTable()
	end
end

function ML:RestoreSettings()
	if not self.settings then self.settings = {} end
	if not self.settings.strSearchType then self.settings.strSearchType = "Player" end
	self.wndMasterLoot:FindChild("Controls"):FindChild(self.settings.strSearchType):SetCheck(true)
end

function ML:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end

	local tSave = {}
	tSave.settings = self.settings
end

function ML:OnRestore(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.settings = tSave.settings
end

-----------------------------------------------------------------------------------------------
-- ML Functions
-----------------------------------------------------------------------------------------------
local tCachedItems = {}

local function string_starts(String,Start)
	return string.sub(string.lower(String),1,string.len(Start))==string.lower(Start)
end

function ML:CacheRecipients()

end

function ML:CreateLootTable()
	local tLootPool = GameLib.GetMasterLoot()
	table.insert(tLootPool,{itemDrop = Item.GetDataFromId(45323),nLootId = 24})
	table.insert(tLootPool,{itemDrop = Item.GetDataFromId(34556),nLootId = 25})
	for k , entry in ipairs(tLootPool or {}) do
		if not tCachedItems[entry.nLootId] then
			local cache = {}
			cache.lootEntry = entry
			cache.currentLocation = 1
			cache.destination = 1
			tCachedItems[entry.nLootId] = cache
		end
	end
	self:DrawItems()
end

function ML:DrawItems()
	for nLootId , entry in pairs(tCachedItems) do
		if not entry.wnd or entry.currentLocation ~= entry.destination then
			if entry.wnd then entry.wnd:Destroy() end
			local wndTarget = entry.destination == 1 and self.wndLootList or self.wndRandomList
			if entry.destination == 1 or entry.destination == 2 then
				entry.wnd = Apollo.LoadForm(self.xmlDoc,"BubbleItemTile",wndTarget,self)
				entry.wnd:FindChild("ItemFrame"):SetSprite(self:GetSlotSpriteByQuality(entry.lootEntry.itemDrop:GetItemQuality()))
				entry.wnd:FindChild("ItemIcon"):SetSprite(entry.lootEntry.itemDrop:GetIcon())
				wndTarget:ArrangeChildrenHorz()
				entry.wnd:SetData(entry.lootEntry)
			end
				entry.currentLocation = entry.destination
		end
	end
end

function ML:CreateRecipients()
	local targets = {}
	
	local rops = Apollo.GetAddon("RaidOps")
	for k,player in ipairs(rops.tItems) do
		if k > 20  then break end
		if player.strName ~= "Guild Bank" then 
			table.insert(targets,{strName = player.strName})
		end
	end

	for k=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(k)
		local strRole = ""
		
		if member.bDPS then strRole = "DPS"
		elseif member.bHeal then strRole = "Heal"
		elseif member.bTank then strRole = "Tank"
		end

		if not Apollo.GetAddon("RaidOps") then
			table.insert(targets,{strName = member.strCharacterName,role = strRole,class = ktClassToString[member.eClassId],tItemsAssigned = {},tItemsToBeAssigned = {}})
		else
			table.insert(targets,{strName = member.strCharacterName})
		end
	end

	if Apollo.GetAddon("RaidOps") then
		local EPGPHook =  Apollo.GetAddon("RaidOps")
		for k , player in ipairs(targets) do
			local ID = EPGPHook:GetPlayerByIDByName(player.strName)
			if ID ~= -1 then 
				player.role = EPGPHook.tItems[ID].role
				player.offrole = EPGPHook.tItems[ID].offrole
				player.class = EPGPHook.tItems[ID].class

				player.ID = ID 
				player.PR = EPGPHook:EPGPGetPRByID(ID)
				player.tItemsToBeAssigned = {}
				player.tItemsAssigned = {}
				targets[k] = player
			end
		end
	end

	self.tRecipients = targets
end

function ML:UpdateRecipients()
	local members = {}
	for k=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(k)
		table.insert(members,member)
	end

	-- Process new recipients
	for j , member in ipairs(members) do
		local bFound = false
		for k , recipient in ipairs(self.tRecipients) do
			if recipient.strName == member.strCharacterName then
				bFound = true
				break
			end
		end

		if not bFound then
			self:AddRecipient(member)
		end
	end
	-- Process old recipients
	for k , recipient in ipairs(self.tRecipients) do
		local bFound = false
			for j , member in ipairs(members) do
			if recipient.strName == member.strCharacterName then
				bFound = true
				break
			end
		end

		if not bFound then
			table.remove(self.tRecipients,k)
		end
	end
end

function ML:AddRecipient(tMember)
	local tRecipient
	if not Apollo.GetAddon("RaidOps") then
		table.insert(tRecipient,{strName = member.strCharacterName,role = strRole,class = ktClassToString[member.eClassId],tItemsAssigned = {},tItemsToBeAssigned = {}})
	else
		table.insert(tRecipient,{strName = member.strCharacterName})
	end
	if Apollo.GetAddon("RaidOps") then
		local EPGPHook =  Apollo.GetAddon("RaidOps")
		local ID = EPGPHook:GetPlayerByIDByName(tRecipient.strName)
		if ID ~= -1 then 
			player.role = EPGPHook.tItems[ID].role
			player.offrole = EPGPHook.tItems[ID].offrole
			player.class = EPGPHook.tItems[ID].class

			player.ID = ID 
			player.PR = EPGPHook:EPGPGetPRByID(ID)
			player.tItemsToBeAssigned = {}
			player.tItemsAssigned = {}
		end
	end
end

function ML:DrawRecipients()
	self.wndLooterList:DestroyChildren()
	table.sort(self.tRecipients,ML.sortByClass)
	for k , recipient in ipairs(self.tRecipients) do
		if not recipient.wnd then
			recipient.wnd = Apollo.LoadForm(self.xmlDoc,"RecipientEntry",self.wndLooterList,self)
			self:UpdateRecipientWnd(recipient,true)
		end
	end
end

function ML:UpdateRecipientWnd(tRecipient,bSuppressArr)
	if not tRecipient then return end

	tRecipient.wnd:FindChild("ClassIcon"):SetSprite(ktStringToNewIconOrig[tRecipient.class])
	tRecipient.wnd:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[tRecipient.role])
	tRecipient.wnd:FindChild("PlayerName"):SetText(tRecipient.strName)
	if tRecipient.offrole then
		tRecipient.wnd:FindChild("OffRoleIcon"):SetSprite(ktRoleStringToIcon[tRecipient.offrole])
	end
	
	tRecipient.wnd:FindChild("HookValue"):SetText(tRecipient.PR)

	if tRecipient.wnd:FindChild("ItemsContainer"):GetData() ~= #tRecipient.tItemsToBeAssigned then
		tRecipient.wnd:FindChild("ItemsContainer"):DestroyChildren()

		if #tRecipient.tItemsToBeAssigned > 1 then
			local l,t,r,b = tRecipient.wnd:GetAnchorOffsets()
			tRecipient.wnd:SetAnchorOffsets(l,t,l+knRecipientEntryWidth+knRecipientTileWidth*(#tRecipient.tItemsToBeAssigned-1)+10,b)
			if not bSuppressArr then self:ArrangeTiles(self.wndLooterList,true) end
		elseif #tRecipient.tItemsToBeAssigned <= 1 then
			local l,t,r,b = tRecipient.wnd:GetAnchorOffsets()
			tRecipient.wnd:SetAnchorOffsets(l,t,l+knRecipientEntryWidth+10,b)
			if not bSuppressArr then self:ArrangeTiles(self.wndLooterList,true) end
		end

		for k , item in ipairs(tRecipient.tItemsToBeAssigned) do
			local wnd = Apollo.LoadForm(self.xmlDoc,"PlayerItemTile",tRecipient.wnd:FindChild("ItemsContainer"),self)
			wnd:FindChild("Icon"):SetSprite(tCachedItems[item].lootEntry.itemDrop:GetIcon())
			wnd:FindChild("Frame"):SetSprite(self:GetSlotSpriteByQualityRectangle(tCachedItems[item].lootEntry.itemDrop:GetItemQuality()))
			Tooltip.GetItemTooltipForm(self,wnd, tCachedItems[item].lootEntry.itemDrop  ,{bPrimary = true, bSelling = false})
			wnd:SetData(tCachedItems[item])
		end

		if #tRecipient.tItemsToBeAssigned == 0 then
			local wnd = Apollo.LoadForm(self.xmlDoc,"PlayerItemTile",tRecipient.wnd:FindChild("ItemsContainer"),self)
			wnd:FindChild("Icon"):SetSprite("Contracts:sprContracts_Type03")
		end



		tRecipient.wnd:FindChild("ItemsContainer"):SetData(#tRecipient.tItemsToBeAssigned)

		tRecipient.wnd:FindChild("ItemsContainer"):ArrangeChildrenHorz()

	end

	tRecipient.wnd:SetData(tRecipient)
end

function ML.sortByClass(a,b)
	local c1 = ktClassStringToId[a.class]
	local c2 = ktClassStringToId[b.class]
	return c1 == c2 and ML.sortByValue(a,b) or c1 < c2 
end

function ML.sortByValue(a,b)
	local pr1 = a.PR
	local pr2 = b.PR
	return pr1 == pr2 and ML.sortByName(a.strName,b.strName) or pr1 > pr2
end

function ML.sortByName(a,b)
	return a < b
end





-----------------------------------------------------------------------------------------------
-- MLForm Functions
-----------------------------------------------------------------------------------------------
local nPrevLootCount
local nPrevRandomCount
function ML:ExpandLootPool()
	if not nPrevLootCount or nPrevLootCount ~= #tCachedItems then
		nPrevLootCount = #tCachedItems
		local nHeight = self:GetExpandValue(nPrevLootCount,self.wndLootList:GetWidth())
		self.wndMasterLoot:FindChild("ItemPool"):SetData({nHeight = nHeight,bExpanded = false})
	end
	self:ToggleResize(self.wndMasterLoot:FindChild("ItemPool"))
end

function ML:ExpandRandomPool()
	if not nPrevRandomCount or nPrevRandomCount ~= self.tRandomPool then
		nPrevRandomCount = #self.tRandomPool
		local nHeight = self:GetExpandValue(nPrevRandomCount,self.wndRandomList:GetWidth())
		self.wndMasterLoot:FindChild("RandomPool"):SetData({nHeight = nHeight,bExpanded = false})
	end
	self:ToggleResize(self.wndMasterLoot:FindChild("RandomPool"))
end

function ML:CollapseLootPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("ItemPool"))
end

function ML:CollapseRandomPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("RandomPool"))
end

function ML:ToggleResize(wnd)
	local l,t,r,b = wnd:GetAnchorOffsets()
	wnd:GetData().bExpanded = not wnd:GetData().bExpanded
	if wnd:GetData().bExpanded then
		wnd:SetAnchorOffsets(l,t,r,b+wnd:GetData().nHeight)
	else
		wnd:SetAnchorOffsets(l,t,r,b-wnd:GetData().nHeight)
	end
	self.wndMasterLoot:FindChild("Pools"):ArrangeChildrenVert()
	local lc , tc = self.wndMasterLoot:FindChild("Controls"):GetPos()
	l,t = self.wndMasterLoot:FindChild("RandomPool"):GetAnchorOffsets()
	Print(tc - t)
	if tc - t <= wnd:GetHeight() then
		l,t,r,b = self.wndMasterLoot:GetAnchorOffsets()
		self.wndMasterLoot:SetAnchorOffsets(l,t,r,(wnd:GetData().bExpanded and b+wnd:GetData().nHeight or b-wnd:GetData().nHeight))
	end
	
end
local prevSearch
function ML:Search( wndHandler, wndControl, strText )
	if prevSearch then
		if prevSearch == "Player" then
			for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
				wnd:FindChild("ShadowOverlay"):Show(false)
				wnd:FindChild("SearchFlash"):Show(false)
			end
		else
			local tChildren = {}
			for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
				for j , itemChild in ipairs(wnd:FindChild("ItemsContainer"):GetChildren()) do
					table.insert(tChildren,itemChild)
				end
			end
			for k ,wnd in ipairs(self.wndLootList:GetChildren()) do
				table.insert(tChildren,wnd)
			end			
			for k ,wnd in ipairs(self.wndRandomList:GetChildren()) do
				table.insert(tChildren,wnd)
			end
			
			for k , wnd in ipairs(tChildren) do
				wnd:FindChild("ShadowOverlayItem"):Show(false)
				wnd:FindChild("SearchFlashItem"):Show(false)
			end
		end
	end


	if strText and #strText > 0 then
		if self.settings.strSearchType == "Player" then
			for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
				if string_starts(wnd:GetData().strName,strText) then
					wnd:FindChild("ShadowOverlay"):Show(false)
					wnd:FindChild("SearchFlash"):Show(true)
				else
					wnd:FindChild("ShadowOverlay"):Show(true)
					wnd:FindChild("SearchFlash"):Show(false)
				end 
			end

		else
			local tChildren = {}
			for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
				for j , itemChild in ipairs(wnd:FindChild("ItemsContainer"):GetChildren()) do
					table.insert(tChildren,itemChild)
				end
			end
			for k ,wnd in ipairs(self.wndLootList:GetChildren()) do
				table.insert(tChildren,wnd)
			end			
			for k ,wnd in ipairs(self.wndRandomList:GetChildren()) do
				table.insert(tChildren,wnd)
			end
			
			for k , wnd in ipairs(tChildren) do
				if wnd:GetData() then
					local tData = wnd:GetName() == "BubbleItemTile" and wnd:GetData() or wnd:GetData().lootEntry
					if string_starts(tData.itemDrop:GetName(),strText) then
						wnd:FindChild("ShadowOverlayItem"):Show(false)
						wnd:FindChild("SearchFlashItem"):Show(true)
					else
						wnd:FindChild("ShadowOverlayItem"):Show(true)
						wnd:FindChild("SearchFlashItem"):Show(false)
					end 
				end
			end
		end
	end
	prevSearch = self.settings.strSearchType
end

function ML:ChangeSearchType(wndHandler,wndControl)
	self.settings.strSearchType = wndControl:GetName()
	self:Search(nil,nil,self.wndMasterLoot:FindChild("Search"):GetText())
end


local tPrevOffsets = {}
function ML:ArrangeTiles(wndList,bForce)
	if tPrevOffsets[wndList] and not bForce then
		if tPrevOffsets[wndList] == wndList:GetAnchorOffsets() then return end
		tPrevOffsets[wndList] = wndList:GetAnchorOffsets()
	else
		tPrevOffsets[wndList] = wndList:GetAnchorOffsets()
	end
	
	local prevChild
	local highestInRow = {}
	local tRows = {}
	for k,child in ipairs(wndList:GetChildren()) do
		child:SetAnchorOffsets(knRecipientHorzSpacing,0,child:GetWidth()+knRecipientHorzSpacing,child:GetHeight())
	end
	
	for k,child in ipairs(wndList:GetChildren()) do
		if k > 1 then
			local prevL,prevT,prevR,prevB = prevChild:GetAnchorOffsets()
			local newL,newT,newR,newB = child:GetAnchorOffsets()
			local prevRow = #tRows
			-- Add next to prev
			newL = prevR + knRecipientHorzSpacing
			newR = newL + child:GetWidth()
			newT = prevT
			newB = prevT + child:GetHeight()
			
			local bNewRow = false
			
			if newR >= wndList:GetWidth() then --or child:GetData().bForceNewRow then -- New Row
				bNewRow = true
				newL = knRecipientHorzSpacing
				newR = newL + child:GetWidth()

				-- Move under highestInRow
				local highL,highT,highR,highB = tRows[prevRow].wnd:GetAnchorOffsets()
				
				newT = highB + knRecipientVertSpacing
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


-----------------------------------------------------------------------------------------------
-- Drag&Drop
-----------------------------------------------------------------------------------------------

function ML:OnDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	local tData = wndSource:GetName() == "BubbleItemTile" and wndSource:GetData() or wndSource:GetData().lootEntry
	Print(tCachedItems[tData.nLootId].currentLocation)
	if tCachedItems[tData.nLootId].currentLocation == 3 then
		for k , recipient in ipairs(self.tRecipients) do
			if recipient.strName == tCachedItems[tData.nLootId].strRecipient then
				for j , item in ipairs(recipient.tItemsToBeAssigned) do
					if item == tData.nLootId then  table.remove(recipient.tItemsToBeAssigned,j) self:UpdateRecipientWnd(recipient)end
				end
			end
		end
	end
	if wndHandler:GetName() == "RandomPool" then
		tCachedItems[tData.nLootId].destination = 2
	elseif wndHandler:GetName() == "ItemPool" then
		tCachedItems[tData.nLootId].destination = 1
	elseif wndHandler:GetName() == "RecipientEntry" then	
		tCachedItems[tData.nLootId].destination = 3
		tCachedItems[tData.nLootId].strRecipient = wndHandler:GetData().strName
		for k , player in ipairs(self.tRecipients) do
			if player.strName == wndHandler:GetData().strName then
				table.insert(player.tItemsToBeAssigned,tData.nLootId)
				self:UpdateRecipientWnd(player)
				break
			end
		end

	end

	self:DrawItems()
	self:Search(nil,nil,self.wndMasterLoot:FindChild("Search"):GetText())
end

function ML:OnQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndHandler:GetName() == "PlayerItemTile" then wndHandler = wndHandler:GetParent():GetParent() end
	if string.find(wndHandler:GetName(),"Pool") or wndHandler:GetName() == "RecipientEntry" then
		wndHandler:FindChild("Highlight"):Show(true)
		return Apollo.DragDropQueryResult.Accept
	else
		return Apollo.DragDropQueryResult.PassOn
	end
end

function ML:HideHighligt(wndHandler,wndControl)
	wndHandler:FindChild("Highlight"):Show(false)
end

function ML:OnQueryBeginDragDrop(wndHandler, wndControl, nX, nY)
end

function ML:OnTileMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	if wndControl:GetName() == "BubbleItemTile" then
		Apollo.BeginDragDrop(wndControl, "MLLootTransfer", wndControl:GetData().itemDrop:GetIcon(), wndControl:GetData().nLootId)
	elseif wndControl:GetName() == "PlayerItemTile" and wndControl:GetData() then
		Apollo.BeginDragDrop(wndControl, "MLLootTransfer", wndControl:GetData().lootEntry.itemDrop:GetIcon(), wndControl:GetData().lootEntry.nLootId)
	end
end
-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function ML:GetSlotSpriteByQuality(ID)
	if ID == 5 then return "CRB_Tooltips:sprTooltip_SquareFrame_Purple"
	elseif ID == 6 then return "CRB_Tooltips:sprTooltip_SquareFrame_Orange"
	elseif ID == 4 then return "CRB_Tooltips:sprTooltip_SquareFrame_Blue"
	elseif ID == 3 then return "CRB_Tooltips:sprTooltip_SquareFrame_Green"
	elseif ID == 2 then return "CRB_Tooltips:sprTooltip_SquareFrame_White"
	else return "CRB_Tooltips:sprTooltip_SquareFrame_DarkModded"
	end
end

function ML:GetExpandValue(nItems,nWidth)
	local nHeight = 76
	local nRows = 1

	local itemsPerRow = nWidth / (knItemTileWidth+knItemTileHorzSpacing) 
	if itemsPerRow < nItems then nRows = 1 else nRows = 2 end


	nHeight = nHeight + (knItemTileHeight+knItemTileVertSpacing)*(nRows-1)	


	return nHeight
end

function ML:GetSlotSpriteByQualityRectangle(ID)
	if ID == 5 then return "BK3:UI_BK3_ItemQualityPurple"
	elseif ID == 6 then return "BK3:UI_BK3_ItemQualityOrange"
	elseif ID == 4 then return "BK3:UI_BK3_ItemQualityBlue"
	elseif ID == 3 then return "BK3:UI_BK3_ItemQualityGreen"
	elseif ID == 2 then return "BK3:UI_BK3_ItemQualityWhite"
	else return "BK3:UI_BK3_ItemQualityGrey"
	end
end


-----------------------------------------------------------------------------------------------
-- ML Instance
-----------------------------------------------------------------------------------------------
local MLInst = ML:new()
MLInst:Init()
