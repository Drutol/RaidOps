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
	if self.settings.bLightMode then self:MLLPopulateItems() end
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
function MasterLoot:gracefullyResize(wnd,tTargets)
	for k , resize in ipairs(tResizes) do
		if resize.wnd:GetName() == wnd:GetName() then table.remove(tResizes,k) end
	end
	table.insert(tResizes,{wnd = wnd,tTargets = tTargets})
	if not bResizeRunning then
		Apollo.RegisterTimerHandler(.002,"GracefulResize",self)
		self.resizeTimer = ApolloTimer.Create(.002,true,"GracefulResize",self)
		bResizeRunning = true
	end
end

function MasterLoot:GracefulResize()
	for k , resize in ipairs(tResizes) do
		local l,t,r,b = resize.wnd:GetAnchorOffsets()
		if resize.tTargets.l then
			if l > resize.tTargets.l then
				l = l-1
			elseif l < resize.tTargets.l then
				l = l+1
			end		
		end
		
		if resize.tTargets.t then
			if t > resize.tTargets.t then
				t = t-1
			elseif t < resize.tTargets.t then
				t = t+1
			end		
		end

		if resize.tTargets.r then
			if r > resize.tTargets.r then
				r = r-1
			elseif r < resize.tTargets.r then
				r = r+1
			end	
		end

		if resize.tTargets.b then
			if b > resize.tTargets.b then
				b = b-1
			elseif b < resize.tTargets.b then
				b = b+1
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

function MasterLoot:MLLightInit()
	self.wndMLL = Apollo.LoadForm(self.xmlDoc,"MasterLootLight",nil,self)

	if not self.settings then self.settings = {} end
	if self.settings.bLightMode == nil then self.settings.bLightMode = false end
	
	self.MLDummy = getDummyML(5)

	self:MLLPopulateItems()
end

function MasterLoot:MLLPopulateItems(bResize)
	self.wndMLL:FindChild("Items"):DestroyChildren()
	local tML = self.MLDummy
	for k , lootEntry in ipairs(tML) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"LightItem",self.wndMLL:FindChild("Items"),self)
		wnd:FindChild("Qual"):SetBGColor(ktQualColors[lootEntry.itemDrop:GetItemQuality()])
		wnd:FindChild("ItemName"):SetText(lootEntry.itemDrop:GetName())
		wnd:FindChild("ItemIcon"):SetSprite(lootEntry.itemDrop:GetIcon())
		Tooltip.GetItemTooltipForm(self,wnd,lootEntry.itemDrop,{bPrimary = true})
		wnd:SetData(lootEntry)
	end
	Apollo.GetAddon("RaidOps"):BQUpdateCounters()
	self.wndMLL:FindChild("Items"):ArrangeChildrenVert() 
	if bResize then 
		self:gracefullyResize(self.wndMLL:FindChild("ItemsFrame"),{b=self.wndMLL:GetHeight()-100})
		local l,t,r,b = self.wndMLL:FindChild("RecipientsFrame"):GetAnchorOffsets()
		self:gracefullyResize(self.wndMLL:FindChild("RecipientsFrame"),{t=b})
	end
end

function MasterLoot:MLLSelectItem(wndHandler,wndControl)
	for k , child in ipairs(self.wndMLL:FindChild("Items"):GetChildren()) do
		if child ~= wndControl then child:Show(false) end
	end
	self:gracefullyResize(wndControl,{t=5,b=wndControl:GetHeight()+5})
	self:gracefullyResize(self.wndMLL:FindChild("ItemsFrame"),{b=200})
	self:gracefullyResize(self.wndMLL:FindChild("RecipientsFrame"),{t=220})
	self:MLLPopulateRecipients(wndControl:GetData())
end

function MasterLoot:MLLDeselectItem(wndHandler,wndControl)
	self:MLLPopulateItems(true)
end

function MasterLoot:MLLPopulateRecipients(lootEntry)
	self.wndMLL:FindChild("Recipients"):DestroyChildren()
	for k , looter in pairs(lootEntry.tLooters) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"LightRecipient",self.wndMLL:FindChild("Recipients"),self)
		wnd:FindChild("CharacterName"):SetText(looter:GetName())
		wnd:FindChild("ClassIcon"):SetSprite(ktClassToIcon[looter:GetClassId()])
		wnd:SetData(looter)
	end
end

function MasterLoot:MLLEnable()
	self.settings.bLightMode = true
	self:OnMasterLootUpdate(true)
end

function MasterLoot:MLLDisable()
	self.settings.bLightMode = false
	self:OnMasterLootUpdate()
end

-- Different stuffs

function MasterLoot:BidMLSearch(wndHandler,wndControl,strText)
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