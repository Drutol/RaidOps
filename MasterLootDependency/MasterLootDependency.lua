-----------------------------------------------------------------------------------------------
-- Client Lua Script for Masterloot
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
--dsfdsfsd
require "Window"
require "Apollo"
require "GroupLib"
require "Item"
require "GameLib"

local MasterLoot = {}

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

function MasterLoot:new(o)

	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function MasterLoot:Init()
	if Apollo.GetAddon("RaidOpsLootHex") then return end
	Apollo.RegisterAddon(self)
end

function MasterLoot:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MasterLootDependency.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MasterLoot:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	self:MLLightInit()
	Apollo.RegisterEventHandler("WindowManagementReady", 		"OnWindowManagementReady", self)

	Apollo.RegisterEventHandler("MasterLootUpdate",				"OnMasterLootUpdate", self)
	Apollo.RegisterEventHandler("LootAssigned",					"OnLootAssigned", self)

	Apollo.RegisterEventHandler("Group_Updated", 				"OnGroupUpdated", self)
	Apollo.RegisterEventHandler("Group_Left",					"OnGroup_Left", self) -- When you leave the group

	Apollo.RegisterEventHandler("GenericEvent_ToggleGroupBag", 	"OnToggleGroupBag", self)

	-- Master Looter Window
	self.wndMasterLoot = Apollo.LoadForm(self.xmlDoc, "MasterLootWindow", nil, self)
	self.wndMasterLoot:SetSizingMinimum(550, 310)
	if self.locSavedMasterWindowLoc then
		self.wndMasterLoot:MoveToLocation(self.locSavedMasterWindowLoc)
	end
	self.wndMasterLoot_ItemList = self.wndMasterLoot:FindChild("ItemList")
	self.wndMasterLoot_LooterList = self.wndMasterLoot:FindChild("LooterList")
	self.wndMasterLoot:Show(false)

	-- Looter Window
	self.wndLooter = Apollo.LoadForm(self.xmlDoc, "LooterWindow", nil, self)
	if self.locSavedLooterWindowLoc then
		self.wndLooter:MoveToLocation(self.locSavedLooterWindowLoc)
	end
	self.wndLooter_ItemList = self.wndLooter:FindChild("ItemList")
	self.wndLooter:Show(false)

	self.tOld_MasterLootList = {}

	-- Master Looter Global Vars
	self.tMasterLootSelectedItem = nil
	self.tMasterLootSelectedLooter = nil


end



function MasterLoot:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMasterLoot, strName = Apollo.GetString("Group_MasterLoot"), nSaveVersion = 1 })
end

function MasterLoot:OnToggleGroupBag()
	self:OnMasterLootUpdate(true) -- true makes it force open if we have items
end

----------------------------

function MasterLoot:OnMasterLootUpdate(bForceOpen)
	if self.settings.bLightMode then self:MLLPopulateItems() return end
	local tMasterLoot = GameLib.GetMasterLoot()

	local tMasterLootItemList = {}
	local tLooterItemList = {}

	local bWeHaveLoot = false
	local bWeHaveNewLoot = false
	local bLootWasRemoved = false
	local bLootersChanged = false



	-- Go through NEW items
	for idxNewItem, tCurNewItem in pairs(tMasterLoot) do

		bWeHaveLoot = true

		-- Break items out into MasterLooter and Looter lists (which UI displays them)
		if tCurNewItem.bIsMaster then
			table.insert(tMasterLootItemList, tCurNewItem)
		else
			table.insert(tLooterItemList, tCurNewItem)
		end

		-- Search through last MasterLootList to see if we got NEW items
		local bFoundItem = false
		for idxOldItem, tCurOldItem in pairs (self.tOld_MasterLootList) do
			if tCurNewItem.nLootId == tCurOldItem.nLootId then -- persistant item

				bFoundItem = true

				local bNewLooter = false
				local bLostLooter = false

				for idxNewLooter, unitNewLooter in pairs (tCurNewItem.tLooters) do
					local bFoundLooter = false
					for idxOldLooter, unitOldLooter in pairs (tCurOldItem.tLooters) do
						if unitNewLooter == unitOldLooter then
							bFoundLooter = true
							break
						end
					end
					if not bFoundLooter then
						bNewLooter = true
						break
					end
				end

				if not bNewLooter then
					for idxOldLooter, unitOldLooter in pairs (tCurOldItem.tLooters) do
						local bFoundLooter = false
						for idxNewLooter, unitNewLooter in pairs (tCurNewItem.tLooters) do
							if unitOldLooter == unitNewLooter then
								bFoundLooter = true
								break
							end
						end
						if not bFoundLooter then
							bLostLooter = true
							break
						end
					end
				end

				if bNewLooter or bLostLooter then
					bLootersChanged = true
					break
				end

			end
		end

		if not bFoundItem then
			bWeHaveNewLoot = true
		end

	end

	-- Go through OLD items
	for idxOldItem, tCurOldItem in pairs (self.tOld_MasterLootList) do
		-- Search through new list to see if we LOST any items
		local bFound = false
		for idxNewItem, tCurNewItem in pairs(tMasterLoot) do

			if tCurNewItem.nLootId == tCurOldItem.nLootId then -- persistant item
				bFound = true
				break
			end

		end
		if not bFound then
			bLootWasRemoved = true
			break
		end
	end

	self.tOld_MasterLootList = tMasterLoot

	if bForceOpen == true and bWeHaveLoot then -- pop window if closed, update open windows
		if next(tMasterLootItemList) then
			self.wndMasterLoot:Show(true)
			self:RefreshMasterLootItemList(tMasterLootItemList)
			self:RefreshMasterLootLooterList(tMasterLootItemList)
		end
		if next(tLooterItemList) then
			self.wndLooter:Show(true)
			self:RefreshLooterItemList(tLooterItemList)
		end

	elseif bWeHaveLoot then
		if bWeHaveNewLoot then -- pop window if closed, update open windows
			if next(tMasterLootItemList) then
				self.wndMasterLoot:Show(true)
				self:RefreshMasterLootItemList(tMasterLootItemList)
				self:RefreshMasterLootLooterList(tMasterLootItemList)
			end
			if next(tLooterItemList) then
				self.wndLooter:Show(true)
				self:RefreshLooterItemList(tLooterItemList)
			end
		elseif bLootWasRemoved or bLootersChanged then  -- update open windows
			if self.wndMasterLoot:IsShown() and next(tMasterLootItemList) then
				self:RefreshMasterLootItemList(tMasterLootItemList)
				self:RefreshMasterLootLooterList(tMasterLootItemList)
			end
			if self.wndLooter:IsShown() and next(tLooterItemList) then
				self:RefreshLooterItemList(tLooterItemList)
			end
		end
	else
		-- close any open windows
		if self.wndMasterLoot:IsShown() then
			self.locSavedMasterWindowLoc = self.wndMasterLoot:GetLocation()
			self.tMasterLootSelectedItem = nil
			self.tMasterLootSelectedLooter = nil
			self.wndMasterLoot_ItemList:DestroyChildren()
			self.wndMasterLoot_LooterList:DestroyChildren()
			self.wndMasterLoot:Show(false)
		end
		if self.wndLooter:IsShown() then
			self.locSavedLooterWindowLoc = self.wndLooter:GetLocation()
			self.wndLooter_ItemList:DestroyChildren()
			self.wndLooter:Show(false)
		end
	end

	if self.tMasterLootSelectedItem ~= nil and self.tMasterLootSelectedLooter ~= nil then
		self.wndMasterLoot:FindChild("Assignment"):Enable(true)
	else
		self.wndMasterLoot:FindChild("Assignment"):Enable(false)
	end
end

function MasterLoot:RefreshMasterLootItemList(tMasterLootItemList)

	self.wndMasterLoot_ItemList:DestroyChildren()

	for idx, tItem in ipairs (tMasterLootItemList) do
		local wndCurrentItem = Apollo.LoadForm(self.xmlDoc, "ItemButton", self.wndMasterLoot_ItemList, self)
		wndCurrentItem:FindChild("ItemIcon"):SetSprite(tItem.itemDrop:GetIcon())
		wndCurrentItem:FindChild("ItemName"):SetText(tItem.itemDrop:GetName())
		wndCurrentItem:SetData(tItem)
		if self.tMasterLootSelectedItem ~= nil and (self.tMasterLootSelectedItem.nLootId == tItem.nLootId) then
			wndCurrentItem:SetCheck(true)
			self:RefreshMasterLootLooterList(tMasterLootItemList)
		end
		--Tooltip.GetItemTooltipForm(self, wndCurrentItem , tItem.itemDrop, {bPrimary = true, bSelling = false, itemCompare = tItem.itemDrop:GetEquippedItemForItemType()})
	end

	self.wndMasterLoot_ItemList:ArrangeChildrenVert(0)

end

function MasterLoot:RefreshMasterLootLooterList(tMasterLootItemList)

	self.wndMasterLoot_LooterList:DestroyChildren()

	if self.tMasterLootSelectedItem ~= nil then
		for idx, tItem in pairs (tMasterLootItemList) do
			if tItem.nLootId == self.tMasterLootSelectedItem.nLootId then
				local bStillHaveLooter = false
				for idx, unitLooter in pairs(tItem.tLooters) do
					local wndCurrentLooter = Apollo.LoadForm(self.xmlDoc, "CharacterButton", self.wndMasterLoot_LooterList, self)
					wndCurrentLooter:FindChild("CharacterName"):SetText(unitLooter:GetName())
					wndCurrentLooter:FindChild("CharacterLevel"):SetText(unitLooter:GetBasicStats().nLevel)
					wndCurrentLooter:FindChild("ClassIcon"):SetSprite(ktClassToIcon[unitLooter:GetClassId()])
					wndCurrentLooter:SetData(unitLooter)
					if self.tMasterLootSelectedLooter == unitLooter then
						wndCurrentLooter:SetCheck(true)
						bStillHaveLooter = true
					end
				end

				if not bStillHaveLooter then
					self.tMasterLootSelectedLooter = nil
				end

				-- get out of range people
				-- tLootersOutOfRange
				if tItem.tLootersOutOfRange and next(tItem.tLootersOutOfRange) then
					for idx, strLooterOOR in pairs(tItem.tLootersOutOfRange) do
						local wndCurrentLooter = Apollo.LoadForm(self.xmlDoc, "CharacterButton", self.wndMasterLoot_LooterList, self)
						wndCurrentLooter:FindChild("CharacterName"):SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), strLooterOOR))
						wndCurrentLooter:FindChild("ClassIcon"):SetSprite("CRB_GroupFrame:sprGroup_Disconnected")
						wndCurrentLooter:Enable(false)
					end
				end
				self.wndMasterLoot_LooterList:ArrangeChildrenVert(0, function(a,b) return a:FindChild("CharacterName"):GetText() < b:FindChild("CharacterName"):GetText() end)
			end
		end
	end
end

function MasterLoot:RefreshLooterItemList(tLooterItemList)

	self.wndLooter_ItemList:DestroyChildren()

	for idx, tItem in pairs (tLooterItemList) do
		local wndCurrentItem = Apollo.LoadForm(self.xmlDoc, "LooterItemButton", self.wndLooter_ItemList, self)
		wndCurrentItem:FindChild("ItemIcon"):SetSprite(tItem.itemDrop:GetIcon())
		wndCurrentItem:FindChild("ItemName"):SetText(tItem.itemDrop:GetName())
		wndCurrentItem:SetData(tItem)
		Tooltip.GetItemTooltipForm(self, wndCurrentItem , tItem.itemDrop, {bPrimary = true, bSelling = false, itemCompare = tItem.itemDrop:GetEquippedItemForItemType()})
	end

	self.wndLooter_ItemList:ArrangeChildrenVert(0)

end

----------------------------

function MasterLoot:OnGroupUpdated()
	if GroupLib.AmILeader() then
		if self.wndLooter:IsShown() then
			self:OnCloseLooterWindow()
			self:OnMasterLootUpdate(true)
		end
	else
		if self.wndMasterLoot:IsShown() then
			self:OnCloseMasterWindow()
			self:OnMasterLootUpdate(true)
		end
	end
end

function MasterLoot:OnGroup_Left()
	if self.wndMasterLoot:IsShown() then
		self:OnCloseMasterWindow()
		--self:OnMasterLootUpdate(true)
	end
end

----------------------------

function MasterLoot:OnItemMouseButtonUp(wndHandler, wndControl, eMouseButton) -- Both LooterItemButton and ItemButton
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		local tItemInfo = wndHandler:GetData()
		if tItemInfo and tItemInfo.itemDrop then
			Event_FireGenericEvent("GenericEvent_ContextMenuItem", tItemInfo.itemDrop)
		end
	end
end

function MasterLoot:OnItemCheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		local tItemInfo = wndHandler:GetData()
		if tItemInfo and tItemInfo.bIsMaster then
			self.tMasterLootSelectedItem = tItemInfo
			self.tMasterLootSelectedLooter = nil
			self:OnMasterLootUpdate(true)
		end
	end
end

function MasterLoot:OnItemUncheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		self.tMasterLootSelectedItem = nil
		self.tMasterLootSelectedLooter = nil
		self:OnMasterLootUpdate(true)
	end
end
----------------------------

function MasterLoot:OnCharacterMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		local unitPlayer = wndControl:GetData() -- Potentially nil
		local strPlayer = wndHandler:FindChild("CharacterName"):GetText()
		if unitPlayer then
			Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", wndHandler, strPlayer, unitPlayer)
		else
			Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, strPlayer)
		end
	end
end

function MasterLoot:OnCharacterCheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		self.tMasterLootSelectedLooter = wndControl:GetData()
		if self.tMasterLootSelectedItem ~= nil then
			self.wndMasterLoot:FindChild("Assignment"):Enable(true)
		else
			self.wndMasterLoot:FindChild("Assignment"):Enable(false)
		end
	end
end

----------------------------

function MasterLoot:OnCharacterUncheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		self.tMasterLootSelectedLooter = nil
		self.wndMasterLoot:FindChild("Assignment"):Enable(false)
	end
end

----------------------------

function MasterLoot:OnAssignDown(wndHandler, wndControl, eMouseButton)

	if self.tMasterLootSelectedItem ~= nil and self.tMasterLootSelectedLooter ~= nil then

		-- gotta save before it gets wiped out by event
		local SelectedLooter = self.tMasterLootSelectedLooter
		local SelectedItemLootId = self.tMasterLootSelectedItem.nLootId

		self.tMasterLootSelectedLooter = nil
		self.tMasterLootSelectedItem = nil

		GameLib.AssignMasterLoot(SelectedItemLootId , SelectedLooter)

	end

end

----------------------------

function MasterLoot:OnCloseMasterWindow()
	self.locSavedMasterWindowLoc = self.wndMasterLoot:GetLocation()
	self.wndMasterLoot_ItemList:DestroyChildren()
	self.wndMasterLoot_LooterList:DestroyChildren()
	self.tMasterLootSelectedItem = nil
	self.tMasterLootSelectedLooter = nil
	self.wndMasterLoot:Show(false)
end

------------------------------------

function MasterLoot:OnCloseLooterWindow()
	self.locSavedLooterWindowLoc = self.wndLooter:GetLocation()
	self.wndLooter_ItemList:DestroyChildren()
	self.wndLooter:Show(false)
end

----------------------------

function MasterLoot:OnLootAssigned(objItem, strLooter)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), objItem:GetName(), strLooter))
end

local knSaveVersion = 1

function MasterLoot:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local locWindowMasterLoot = self.wndMasterLoot and self.wndMasterLoot:GetLocation() or self.locSavedMasterWindowLoc
	local locWindowLooter = self.wndLooter and self.wndLooter:GetLocation() or self.locSavedLooterWindowLoc

	local tSave =
	{
		tWindowMasterLocation = locWindowMasterLoot and locWindowMasterLoot:ToTable() or nil,
		tWindowLooterLocation = locWindowLooter and locWindowLooter:ToTable() or nil,
		nSaveVersion = knSaveVersion,
	}

	tSave.settings = self.settings

	return tSave
end

function MasterLoot:OnRestore(eType, tSavedData)
	if tSavedData and tSavedData.nSaveVersion == knSaveVersion then

		if tSavedData.tWindowMasterLocation then
			self.locSavedMasterWindowLoc = WindowLocation.new(tSavedData.tWindowMasterLocation)
		end

		if tSavedData.tWindowLooterLocation then
			self.locSavedLooterWindowLoc = WindowLocation.new(tSavedData.tWindowLooterLocation )
		end

		local bShowWindow = #GameLib.GetMasterLoot() > 0
		if self.wndGroupBag and bShowWindow then
			self.wndGroupBag:Show(bShowWindow)
			self:RedrawMasterLootWindow()
		end

		self.settings = tSavedData.settings

	end
end

local MasterLoot_Singleton = MasterLoot:new()
MasterLoot_Singleton:Init()

-- Master Loot light
local ktQualColors = 
{
	[1] = "ItemQuality_Inferior",
	[2] = "ItemQuality_Average",
	[3] = "ItemQuality_Good",
	[4] = "ItemQuality_Excellent",
	[5] = "ItemQuality_Superb",
	[6] = "ItemQuality_Legendary",
	[7] = "ItemQuality_Artifact",
}

local ktKeys = 
{
	[81] = "Q",
	[87] = "W",
	[69] = "E",
	[82] = "R",
	[84] = "T",
	[89] = "Y",
	[85] = "U",
	[73] = "I",
	[79] = "O",
	[80] = "P",
	
	[65] = "A",
	[83] = "S",
	[68] = "D",
	[70] = "F",
	[71] = "G",
	[72] = "H",
	[74] = "J",
	[75] = "K",
	[76] = "L",
	
	[90] = "Z",
	[88] = "X",
	[67] = "C",
	[86] = "V",
	[66] = "B",
	[78] = "N",
	[77] = "M",
}

local function getDummyML(nCount)
	tDummy = {}
	while nCount ~= 0 do
		local id = math.random(1,60000)
		local item = Item.GetDataFromId(id)
		if item then
			table.insert(tDummy,{nLootId = math.random(1,100000),itemDrop = item,tLooters = {[math.random(100)] = GameLib.GetPlayerUnit()}})
			nCount = nCount - 1
		end	
	end
	return tDummy
end

local tResizes = {}
local bResizeRunning = false
function MasterLoot:gracefullyResize(wnd,tTargets,bQuick)
	for k , resize in ipairs(tResizes) do
		if resize.wnd:GetName() == wnd:GetName() then table.remove(tResizes,k) end
	end
	if bQuick then
		if tTargets.l then
			if tTargets.l - math.floor(tTargets.l/2)*2 ~= 0 then tTargets.l = tTargets.l +1 end
		end		
		if tTargets.t then
			if tTargets.t - math.floor(tTargets.t/2)*2 ~= 0 then tTargets.t = tTargets.t +1 end
		end		
		if tTargets.r then
			if tTargets.r - math.floor(tTargets.r/2)*2 ~= 0 then tTargets.r = tTargets.r +1 end
		end		
		if tTargets.b then
			if tTargets.b - math.floor(tTargets.b/2)*2 ~= 0 then tTargets.b = tTargets.b +1 end
		end
	end
	table.insert(tResizes,{wnd = wnd,tTargets = tTargets,bQuick = bQuick})
	if not bResizeRunning then
		Apollo.RegisterTimerHandler(.002,"GracefulResize",self)
		self.resizeTimer = ApolloTimer.Create(.002,true,"GracefulResize",self)
		bResizeRunning = true
	end
end

function MasterLoot:MLLClose()
	self.wndMLL:Show(false,false)
end

function MasterLoot:GracefulResize()
	for k , resize in ipairs(tResizes) do
		local l,t,r,b = resize.wnd:GetAnchorOffsets()
		local nSpeed = resize.bQuick and 2 or 1
		if resize.tTargets.l then
			if l > resize.tTargets.l then
				l = l-nSpeed
			elseif l < resize.tTargets.l then
				l = l+nSpeed
			end		
		end
		
		if resize.tTargets.t then
			if t > resize.tTargets.t then
				t = t-nSpeed
			elseif t < resize.tTargets.t then
				t = t+nSpeed
			end		
		end

		if resize.tTargets.r then
			if r > resize.tTargets.r then
				r = r-nSpeed
			elseif r < resize.tTargets.r then
				r = r+nSpeed
			end	
		end

		if resize.tTargets.b then
			if b > resize.tTargets.b then
				b = b-nSpeed
			elseif b < resize.tTargets.b then
				b = b+nSpeed
			end
		end	
		resize.wnd:SetAnchorOffsets(l,t,r,b)
		if l == (resize.tTargets.l or l) and r == (resize.tTargets.r or r) and b == (resize.tTargets.b or b) and t == (resize.tTargets.t or t) then table.remove(tResizes,k) end
	end

	if #tResizes == 0 then
		bResizeRunning = false 
		self.resizeTimer:Stop()
	end
end
local nTargetHeight
function MasterLoot:MLLightInit()
	self.wndMLL = Apollo.LoadForm(self.xmlDoc,"MasterLootLight",nil,self)
	self.wndMLL:Show(false)
	Apollo.RegisterEventHandler("SystemKeyDown", "MLLKeyDown", self)
	if not self.settings then self.settings = {} end
	if self.settings.bLightMode == nil then self.settings.bLightMode = false end
	
	self.MLDummy = getDummyML(10)
 	nTargetHeight = self.wndMLL:GetHeight()+40
	self:MLLPopulateItems()
end

local ktSlotOrder = 
{
	[16] = 1,
	[15] = 2,
	[2] = 3,
	[3] = 4,
	[0] = 5,
	[5] = 6,
	[1] = 7,
	[7] = 8,
	[11] = 9,
	[10] = 10,
	[4] = 11,
	[8] = 12
}
local function sort_loot_slot( c,d )
	local s1 = c.itemDrop:GetSlot()
	local s2 = d.itemDrop:GetSlot()
	return s1 == s2 and c.itemDrop:GetName() < d.itemDrop:GetName() or ktSlotOrder[s1] < ktSlotOrder[s2]
end

local function sort_loot(tML)
	local tReturn = {}
	local tRandomJunk = {}
	local tItems = {}
	for k , item in ipairs(tML) do
		if item.itemDrop:IsEquippable() then table.insert(tItems,item) else table.insert(tRandomJunk,item) end
	end

	table.sort(tRandomJunk,function (a,b) return a.itemDrop:GetName() < b.itemDrop:GetName() end)
	tReturn = tRandomJunk
	table.sort(tItems,function(a,b)
		local q1 = a.itemDrop:GetItemQuality()
		local q2 = b.itemDrop:GetItemQuality()
		return q1 == q2 and sort_loot_slot(a,b) or q1 > q2
		end)
	for k , item in ipairs(tItems) do table.insert(tReturn,item) end
	return tReturn
end

local bItemSelected = false
function MasterLoot:MLLPopulateItems(bResize)
	if #GameLib.GetMasterLoot() > 0 then self.wndMLL:Show(true,false) end

	if bItemSelected then return end

	self.wndMLL:FindChild("Items"):DestroyChildren()
	local tML = sort_loot(GameLib.GetMasterLoot())

	for k , lootEntry in ipairs(tML) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"LightItem",self.wndMLL:FindChild("Items"),self)
		wnd:FindChild("Qual"):SetBGColor(ktQualColors[lootEntry.itemDrop:GetItemQuality()])
		wnd:FindChild("ItemName"):SetText(lootEntry.itemDrop:GetName())
		wnd:FindChild("ItemIcon"):SetSprite(lootEntry.itemDrop:GetIcon())
		Tooltip.GetItemTooltipForm(self,wnd,lootEntry.itemDrop,{bPrimary = true})
		wnd:SetData(lootEntry)
	end
	if Apollo.GetAddon("RaidOps") then Apollo.GetAddon("RaidOps"):BQUpdateCounters() end
	self.wndMLL:FindChild("Items"):ArrangeChildrenVert() 
	if bResize then 
		self:gracefullyResize(self.wndMLL:FindChild("ItemsFrame"),{b=self.wndMLL:GetHeight()-100})
		local l,t,r,b = self.wndMLL:FindChild("RecipientsFrame"):GetAnchorOffsets()
		self:gracefullyResize(self.wndMLL:FindChild("RecipientsFrame"),{t=b})
	end
end

function MasterLoot:MLLSelectItem(wndHandler,wndControl)
	bItemSelected = true
	for k , child in ipairs(self.wndMLL:FindChild("Items"):GetChildren()) do
		if child ~= wndControl then child:Show(false) end
	end
	self:gracefullyResize(wndControl,{t=3,b=wndControl:GetHeight()+3},true)
	self:gracefullyResize(self.wndMLL:FindChild("ItemsFrame"),{b=190})
	self:gracefullyResize(self.wndMLL:FindChild("RecipientsFrame"),{t=200})
	self:MLLPopulateRecipients(wndControl:GetData())
	self.nSelectedItem = wndControl:GetData().nLootId
	
end

function MasterLoot:MLLDeselectItem(wndHandler,wndControl)
	bItemSelected = false
	self:MLLPopulateItems(true)
	self:MLLRecipientDeselected()
	self.nSelectedItem = nil
end

function MasterLoot:MLLGetSuggestestedLooters(tLooters,item)
	local tS = {}
	local tR = {}

	local bWantEsp = true
    local bWantWar = true
    local bWantSpe = true
    local bWantMed = true
    local bWantSta = true
    local bWantEng = true

	if string.find(item:GetName(),"Prägung") or string.find(item:GetName(),"Imprint") or item:IsEquippable() then

		
		local tDetails = item:GetDetailedInfo()
		if tDetails.tPrimary.arClassRequirement then

		    bWantEsp = false
		    bWantWar = false
		    bWantSpe = false
		    bWantMed = false
		    bWantSta = false
		    bWantEng = false

			for k , class in ipairs(tDetails.tPrimary.arClassRequirement.arClasses) do
				if class == 1 then bWantWar = true
				elseif class == 2 then bWantEng = true
				elseif class == 3 then bWantEsp = true
				elseif class == 4 then bWantMed = true
				elseif class == 5 then bWantSta = true
				elseif class == 7 then bWantSpe = true
				end
			end
		else
			local strCategory = item:GetItemCategoryName()
			if strCategory ~= "" then
				if string.find(strCategory,"Light") then
					bWantEng = false
					bWantWar = false
					bWantSta = false
					bWantMed = false
				elseif string.find(strCategory,"Medium") then
					bWantEng = false
					bWantWar = false
					bWantSpe = false
					bWantEsp = false
				elseif string.find(strCategory,"Heavy") then
					bWantEsp = false
					bWantSpe = false
					bWantSta = false
					bWantMed = false
				end
				
				if string.find(strCategory,"Psyblade") or string.find(strCategory,"Heavy Gun") or string.find(strCategory,"Pistols") or string.find(strCategory,"Claws") or string.find(strCategory,"Greatsword") or string.find(strCategory,"Resonators") then 
					bWantEsp = false
					bWantWar = false
					bWantSpe = false
					bWantMed = false
					bWantSta = false
					bWantEng = false
				end 
				
				if string.find(strCategory,"Psyblade") then bWantEsp = true
				elseif string.find(strCategory,"Heavy Gun") then bWantEng = true
				elseif string.find(strCategory,"Pistols") then bWantSpe = true
				elseif string.find(strCategory,"Claws") then bWantSta = true
				elseif string.find(strCategory,"Greatsword") then bWantWar = true
				elseif string.find(strCategory,"Resonators") then bWantMed = true
				end
			end
		end 
	end

	for k , looter in pairs(tLooters) do
		if bWantEsp and ktClassToString[looter:GetClassId()] == "Esper"  then
			table.insert(tS,looter)
		elseif bWantEng and ktClassToString[looter:GetClassId()] == "Engineer"  then
			table.insert(tS,looter)
		elseif bWantMed and ktClassToString[looter:GetClassId()] == "Medic"  then
			table.insert(tS,looter)
		elseif bWantWar and ktClassToString[looter:GetClassId()] == "Warrior"  then
			table.insert(tS,looter)
		elseif bWantSta and ktClassToString[looter:GetClassId()] == "Stalker"  then
			table.insert(tS,looter)
		elseif bWantSpe and ktClassToString[looter:GetClassId()] == "Spellslinger"  then
			table.insert(tS,looter)
		else
			table.insert(tR,looter)
		end
	end

	return tS , tR
end

function MasterLoot:MLLPopulateRecipients(lootEntry)
	self.wndMLL:FindChild("Recipients"):DestroyChildren()

	local tLootersSuggested , tLootersRest = self:MLLGetSuggestestedLooters(lootEntry.tLooters,lootEntry.itemDrop)
	table.sort(tLootersSuggested,function (a,b)
		return a:GetName() < b:GetName()
	end)	
	table.sort(tLootersRest,function (a,b)
		return a:GetName() < b:GetName()
	end)
	for k , looter in ipairs(tLootersRest) do table.insert(tLootersSuggested,looter) end

	for k , looter in pairs(tLootersSuggested) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"LightRecipient",self.wndMLL:FindChild("Recipients"),self)
		wnd:FindChild("CharacterName"):SetText(looter:GetName())
		wnd:FindChild("ClassIcon"):SetSprite(ktClassToIcon[looter:GetClassId()])
		wnd:SetData(looter)
	end
	self:MLLArrangeRecipients()
end

function MasterLoot:MLLEnable()
	self.settings.bLightMode = true
	self.wndMasterLoot:Show(false,false)
	self:OnMasterLootUpdate(true)
end

function MasterLoot:MLLDisable()
	self.settings.bLightMode = false
	self.wndMLL:Show(false,false)
	self:OnMasterLootUpdate()
end

function MasterLoot:MLLRecipientSelected(wndHandler,wndControl)
	self:gracefullyResize(self.wndMLL:FindChild("Assign"),{t=561})
	self:gracefullyResize(self.wndMLL,{b=nTargetHeight})
	self.wndMLL:FindChild("Assign"):SetText("Assign")
	bRecipientSelected = true
	self.unitSelected = wndControl:GetData()
end

function MasterLoot:MLLRecipientDeselected(wndHandler,wndControl)
	self:gracefullyResize(self.wndMLL:FindChild("Assign"),{t=622})
	self:gracefullyResize(self.wndMLL,{b=nTargetHeight-40})
	self.wndMLL:FindChild("Assign"):SetText("")
	self.unitSelected = nil
end

function MasterLoot:MLLKeyDown(nKey)
	if self.wndMLL:IsShown() and bItemSelected then
		local l,t,r,b 
		local strKey = ktKeys[nKey]
		if not strKey then return end
		for k , child in ipairs(self.wndMLL:FindChild("Recipients"):GetChildren()) do
			local strName = child:FindChild("CharacterName"):GetText()
			if string.lower(string.sub(strName,1,1)) == string.lower(strKey) then
				l,t,r,b = child:GetAnchorOffsets()
				break
			end
		end
		if t then
			self.wndMLL:FindChild("Recipients"):SetVScrollPos(t)
		end
	end
end



function MasterLoot:MLLAssign()
	if self.nSelectedItem and self.unitSelected then
		GameLib.AssignMasterLoot(self.nSelectedItem,self.unitSelected)
		bItemSelected = false
		self:MLLPopulateItems(true)
		self:MLLRecipientDeselected()
	end
end

function MasterLoot:MLLAssignItemAtRandom(wndHandler,wndControl)
	local tData =  wndControl:GetParent():GetData()
	if tData and tData.tLooters then
		local luckylooter = self:ChooseRandomLooter(tData)
		if luckylooter then
			Apollo.GetAddon("RaidOps"):BidAddPlayerToRandomSkip(luckylooter:GetName())
			GameLib.AssignMasterLoot(tData.nLootId,luckylooter)
		end
	end
end
-- Different stuffs

function MasterLoot:ChooseRandomLooter(entry)
	local looters = {}
	for k , playerUnit in pairs(entry.tLooters or {}) do
		table.insert(looters,playerUnit)
	end	
	return looters[math.random(#looters)]
end

local prevChild
function MasterLoot:MLLArrangeRecipients()
	local list = self.wndMLL:FindChild("Recipients")
	local children = list:GetChildren()
	for k , child in ipairs(children) do
		child:SetAnchorOffsets(-4,0,child:GetWidth()+-4,child:GetHeight())
	end
	for k , child in ipairs(children) do
		if k > 1 then
			local l,t,r,b = prevChild:GetAnchorOffsets()
			child:SetAnchorOffsets(-4,b-10,child:GetWidth()+-4,b+child:GetHeight()-10)
		end
		prevChild = child
	end
end

function MasterLoot:BidMLSearch(wndHandler,wndControl,strText)
	strText = self.wndMasterLoot:FindChild("SearchBox"):GetText()
	local Rops = Apollo.GetAddon("RaidOps")
	if strText ~= "Search..." then
		local children = self.wndMasterLoot:FindChild("LooterList"):GetChildren()
		
		for k,child in ipairs(children) do
			child:Show(true,true)
		end
		
		for k,child in ipairs(children) do
			if not Rops:string_starts(child:FindChild("CharacterName"):GetText(),strText) then child:Show(false,true) end
		end
		
		if wndControl ~= nil and wndControl:GetText() == "" then wndControl:SetText("Search...") end
		
		if Rops.tItems["settings"]["ML"].bArrTiles then
			self.wndMasterLoot_LooterList:ArrangeChildrenTiles()
		else
			self.wndMasterLoot_LooterList:ArrangeChildrenVert()
		end
	end
end

function MasterLoot:BQAddItem(wndH,wndC)
	Apollo.GetAddon("RaidOps"):BQAddItem(wndH,wndC)
end

function MasterLoot:BQRemItem(wndH,wndC)
	Apollo.GetAddon("RaidOps"):BQRemItem(wndH,wndC)
end

