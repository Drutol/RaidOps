-----------------------------------------------------------------------------------------------
-- Client Lua Script for ML
-- Copyright (c) NCsoft. All rights reserved
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


		self.wndMasterLoot = Apollo.LoadForm(self.xmlDoc,"MasterLootWindow",nil,self)


		--self.wndMasterLoot:Show(false)

		self.wndLooterList = self.wndMasterLoot:FindChild("PlayerPool"):FindChild("List")
		self.wndRandomList = self.wndMasterLoot:FindChild("RandomPool"):FindChild("List")
		self.wndLootList = self.wndMasterLoot:FindChild("ItemPool"):FindChild("List")

		for result , id in pairs(Apollo.DragDropQueryResult) do
			Print(result .. " " .. id)
		end

		--Debug
		Apollo.LoadForm(self.xmlDoc,"BubbleItemTile",self.wndLootList,self)
	end
end

-----------------------------------------------------------------------------------------------
-- ML Functions
-----------------------------------------------------------------------------------------------
local tCachedItems = {}

function ML:CacheRecipients()

end

function ML:CreateLootTable()
	local tLootPool = GameLib.GetMasterLoot()
	for k , entry in ipairs(tLootPool or {}) do
		if not tCachedItems[entry.nLootId] then
			local cache = {}
			cache.lootEntry = entry
			cache.location = 1
			cache.wndCreate = function(tContext,wndParent)
				if self.wnd then self.wnd:Destroy() end
				if self.location == 1 or self.location == 2 then
					self.wnd = Apollo.LoadForm(tContext.xmlDoc,"BubbleItemTile",wndParent,tContext)
					wnd:FindChild("ItemFrame"):SetSprite(tContext:GetSlotSpriteByQuality(self.lootEntry.itemDrop:GetItemQuality()))
					wnd:FindChild("ItemIcon"):SetSprite(self.lootEntry.itemDrop:GetIcon())
				else
					self.wnd = Apollo.LoadForm(tContext.xmlDoc,"PlayerItemTile",wndParent,tContext)
					self.wnd:FindChild("Icon"):SetSprite(self.lootEntry.itemDrop:GetIcon())
				end

			end
			tCachedItems[entry.nLootId] = cache
		end
	end
end





-----------------------------------------------------------------------------------------------
-- MLForm Functions
-----------------------------------------------------------------------------------------------
local nPrevLootCount

function ML:ExpandLootPool()
	if not nPrevLootCount or nPrevLootCount ~= #tCachedItems then
		nPrevLootCount = #tCachedItems
		local nHeight = self:GetExpandValue(nPrevLootCount,self.wndLootList:GetWidth())
		self.wndMasterLoot:FindChild("ItemPool"):SetData({nHeight = nHeight,bExpanded = false})
	end
	self:ToggleResize(self.wndMasterLoot:FindChild("ItemPool"))
end

function ML:ExpandRandomPool()

end

function ML:ExpandPlayerPool()

end

function ML:CollapseLootPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("ItemPool"))
end

function ML:CollapseRandomPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("RandomPool"))
end

function ML:CollapsePlayerPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("LooterPool"))
end

function ML:PopulateLoot()

end

function ML:PopulateRandom()

end

function ML:PopulateRecipients()

end

function ML:ToggleResize(wnd)
	local l,t,r,b = wnd:GetAnchorOffsets()
	wnd:GetData().bExpanded = not wnd:GetData().bExpanded
	if wnd:GetData().bExpanded then
		Print("Ex")
		wnd:SetAnchorOffsets(l,t,r,b+wnd:GetData().nHeight)
	else
		Print("Col")
		wnd:SetAnchorOffsets(l,t,r,b-wnd:GetData().nHeight)
	end

	l,t,r,b = self.wndMasterLoot:GetAnchorOffsets()
	self.wndMasterLoot:SetAnchorOffsets(l,t,r,(wnd:GetData().bExpanded and b+wnd:GetData().nHeight or b-wnd:GetData().nHeight))
end

-----------------------------------------------------------------------------------------------
-- Drag&Drop
-----------------------------------------------------------------------------------------------
--[[function ML:GetContainerInRange(x,y)
	local x0 , y0 = self.wndLootList:GetPos()
	local x1 , y1
	x1 = x0 + self.wndLootList:GetWidth()
	y1 = y0 + self.wndLootList:GetHeight()

	if x > x0 and x < x1 and y > y0 and y < y1 then return self.wndLootList end	
	
	x0 , y0 = self.wndRandomList:GetPos()
	x1 = x0 + self.wndRandomList:GetWidth()
	y1 = y0 + self.wndRandomList:GetHeight()

	if x > x0 and x < x1 and y > y0 and y < y1 then return self.wndRandomList end

	x0 , y0 = self.wndLooterList:GetPos()
	x1 = x0 + self.wndLooterList:GetWidth()
	y1 = y0 + self.wndLooterList:GetHeight()

	if x > x0 and x < x1 and y > y0 and y < y1 then 
		for k,wnd in ipairs(self.wndLooterList:GetChildren()) do
			x0 , y0 = wnd:GetPos()
			x1 = x0 + wnd:GetWidth()
			y2 = y0 + wnd:GetHeight()

			if x > x0 and x < x1 and y > y0 and y < y1 then return wnd end
		end
	end

end]]


function ML:OnDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	GroupLib.SwapOrder(wndHandler:GetData().groupMember.nMemberIdx, wndSource:GetData().groupMember.nMemberIdx)
end

function ML:OnQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	Print(wndControl:GetName() .. " : " .. wndHandler:GetName() .. " : " .. wndSource:GetName())
	local wnd = self:GetContainerInRange(nX,nY)
	if wnd then Print(wnd:GetParent():GetParent():GetName()) end
	return Apollo.DragDropQueryResult.PassOn
end

function ML:OnQueryBeginDragDrop(wndHandler, wndControl, nX, nY)
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


---------------------------------------------------------------------------------------------------
-- BubbleItemTile Functions
---------------------------------------------------------------------------------------------------

function ML:OnTileMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	Apollo.BeginDragDrop(wndControl, "LOLOLOTransfer", "CRB_Tooltips:sprTooltip_SquareFrame_DarkModded", 35652)
end

-----------------------------------------------------------------------------------------------
-- ML Instance
-----------------------------------------------------------------------------------------------
local MLInst = ML:new()
MLInst:Init()
