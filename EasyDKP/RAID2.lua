-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

--MODULE
local DKP = Apollo.GetAddon("EasyDKP")

--Constants

-- ItemBubbleCosntants

local knBubbleDefWidth = 250
local knBubbleDefHeight = 43

local knBubbleMaxWidth = 400
local knBubbleMaxHeight = 210

local knItemTileWidth = 65
 
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

function DKP:IBExpand(wndHandler,wndControl)
	self:IBPopulate(wndControl:GetParent())
	wndControl:GetParent():GetData().bExpanded = true
	self:IBEResize(wndControl:GetParent())
	self:RIRequestRearrange(wndControl:GetParent():GetParent())
	
end

function DKP:IBECollapse(wndHandler,wndControl)
	wndControl:GetParent():GetData().bExpanded = false
	self:IBEResize(wndControl:GetParent())
	self:RIRequestRearrange(wndControl:GetParent():GetParent())
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

	if wndBubble:GetData().bPopulated then return end -- Buuble is already filled -> no need to do this again

	local tLoot = self:RIRequestLootForBubble(wndBubble:GetData())
	local wndBubbleGrid = wndBubble:FindChild("ItemGridFrame"):FindChild("ItemGrid")
	
	local nUniqueLoot = 0
	
	local tIDCounter = {}
	
	for k,nItemID in ipairs(tLoot) do
		if tIDCounter[nItemID] == nil then
			tIDCounter[nItemID] = true
			nUniqueLoot = nUniqueLoot +1
		end
	end
	
	if nUniqueLoot > 2 then -- splitting to 2 rows
		local nWidth = (#tLoot * knItemTileWidth) / 4 -- 2 rows = 1/2 width
		wndBubble:GetData().nWidthMod = nWidth
		wndBubble:GetData().nHeightMod = knBubbleMaxHeight
	else
		wndBubble:GetData().nHeightMod = knBubbleMaxHeight/1.5
	end
	
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

function DKP:RIRequestRearrange(wndList)
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
			
			if newR >= wndList:GetWidth() then -- New Row
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
	local l,t,r,b = tRows[#tRows].wnd:GetAnchorOffsets()
	wndList:SetVScrollInfo(b,100,100)
end