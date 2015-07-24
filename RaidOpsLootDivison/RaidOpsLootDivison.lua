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

local knRecipientHorzSpacing = 6
local knRecipientVertSpacing = 20

local knRecipientTileWidth = 52
local knRecipientTileHeight = 52

local knRecipientEntryWidth = 221
local knRecipientEntryHeight = 86

local knPoolHeight = 150

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

local ktClassOrderDefault = 
{
	[1] = "Esper",
	[2] = "Spellslinger",
	[3] = "Medic",
	[4] = "Stalker",
	[5] = "Warrior",
	[6] = "Engineer",
}

local ktSizingPairs = 
{
	["Exp2"] =
	{
		x = 1215,
		y = 741,
	},
	["Exp1"] =
	{
		x = 1215,
		y = 572,
	},
	["Exp0"] =
	{
		x = 1215 ,
		y = 410,
	},
	["Max"] =
	{
		x = 1939,
		y = 1078,
	}


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
		Apollo.RegisterEventHandler("LootAssigned","OnLootAssigned", self)
		Apollo.RegisterEventHandler("GenericEvent_ToggleGroupBag","OnToggleGroupBag", self)
		Apollo.RegisterEventHandler("RaidOpsLootHexAssignThisItem","AssignItemOrderFromOtherSource", self)

		Apollo.RegisterSlashCommand("ropshex", "SetOpen", self)
		Apollo.RegisterSlashCommand("ropshexf", "FilterShow", self)


		self.wndMasterLoot = Apollo.LoadForm(self.xmlDoc,"MasterLootWindow",nil,self)
		self.wndMasterLootLooter = Apollo.LoadForm(self.xmlDoc,"LooterForm",nil,self)
		self.wndReminder = Apollo.LoadForm(self.xmlDoc,"LootReminder",nil,self)

		self.wndReminder:Show(false)
		self.wndMasterLoot:Show(false)
		self.wndMasterLootLooter:Show(false)

		self.wndLooterList = self.wndMasterLoot:FindChild("PlayerPool"):FindChild("RecipientsList")
		self.wndRandomList = self.wndMasterLoot:FindChild("RandomPool"):FindChild("List")
		self.wndLootList = self.wndMasterLoot:FindChild("ItemPool"):FindChild("List")

		self.wndMasterLoot:FindChild("Pools"):ArrangeChildrenVert()

		--for result , id in pairs(Apollo.DragDropQueryResult) do
		--	Print(result .. " " .. id)
		--end
		self:RestoreSettings()
		self:FilterInit()
		self:SummaryInit()
		self:SettingsInit()
		self.tRandomPool = {}
		self.tPlayerPool = {}
		--for k=1 , 20 do 
		--	Apollo.LoadForm(self.xmlDoc,"RecipientEntry",self.wndLooterList,self)
		--end
		self:CreateRecipients()
		self:DrawRecipients()
		self:EnableActionSlotButtons()
		--Debug
		--local wnd = Apollo.LoadForm(self.xmlDoc,"BubbleItemTile",self.wndLootList,self)
		--wnd:SetData({itemDrop = Item.GetDataFromId(45323),nLootId = 24})
		self:CreateLootTable()


		self.wndMasterLoot:SetSizingMaximum(ktSizingPairs["Max"].x,ktSizingPairs["Max"].y)
		if self.settings and self.settings.bRPExpand then 
			self.wndMasterLoot:FindChild("RandomPool"):FindChild("Expand"):Show(false)
			self:ExpandRandomPool() 
		end
		if self.settings and self.settings.bLPExpand then 
			self.wndMasterLoot:FindChild("ItemPool"):FindChild("Expand"):Show(false)
			self:ExpandLootPool() 
		end
		self:FigureSizing()
		self:ChangeItemArrangeType()
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
	tSave.wndLoc = self.wndMasterLoot:GetLocation():ToTable()
	tSave.wndRemLoc = self.wndReminder:GetLocation():ToTable()
	return tSave
end

function ML:OnRestore(eLevel,tSave)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.settings = tSave.settings
	self.wndMasterLootLoc = tSave.wndLoc
	self.wndReminderLoc = tSave.wndRemLoc
end

-----------------------------------------------------------------------------------------------
-- ML Functions
-----------------------------------------------------------------------------------------------
local tCachedItems = {}

local function string_starts(String,Start)
	return string.sub(string.lower(String),1,string.len(Start))==string.lower(Start)
end

function ML:CreateLootTable()
	local tLootPool = GameLib.GetMasterLoot()
	--table.insert(tLootPool,{itemDrop = Item.GetDataFromId(45323),nLootId = 24,bIsMaster = true})
	--table.insert(tLootPool,{itemDrop = Item.GetDataFromId(34556),nLootId = 25,bIsMaster = false})
	--table.insert(tLootPool,{itemDrop = Item.GetDataFromId(60407),nLootId = 26,bIsMaster = true})
	--Clear old stuff
	for k , tCache in pairs(tCachedItems or {}) do
		local bFound = false
		for j , entry in ipairs(tLootPool or {}) do
			if entry.nLootId == k then bFound = true break end
		end
		if not bFound then 
			if tCachedItems[k].wnd then tCachedItems[k].wnd:Destroy() end
			tCachedItems[k] = nil 
			for j , recipient in ipairs(self.tRecipients) do
				if tCache.strRecipient == recipient.strName then
					self:RemoveLootFromRecipient(k,recipient)
				end	
			end
		end
	end

	--Add new
	for k , entry in ipairs(tLootPool or {}) do
		if not tCachedItems[entry.nLootId] then
			local cache = {}
			cache.lootEntry = entry
			cache.currentLocation = 1
			local bSkip = false
			if entry.bIsMaster then
				if self:FilterIsRandomed(entry.itemDrop) then
					if not self:FilterIsAuto(entry.itemDrop) then
						cache.destination = 2 -- RandomPool
					else
						GameLib.AssignMasterLoot(entry.nLootId,self:ChooseRandomLooter(entry))
						bSkip = true
					end
				else
					cache.destination = 1 -- LootPool
				end
			else
				cache.destination = 5 -- Looter List
			end
			if not bSkip then tCachedItems[entry.nLootId] = cache end
		end
	end
	self:DrawItems()
	self:FigureShow()
	self:SummaryOpen(true)
	--self.wndMasterLoot:Show(true)
end

function ML:ChooseRandomLooter(entry)
	local looters = {}
	for k , playerUnit in pairs(entry.tLooters or {}) do
		table.insert(looters,playerUnit)
	end	
	return looters[math.random(#looters)]
end

function ML.sortItemsInPool(a,b)
	if a:GetData().itemDrop:GetSlot() == nil then return false end
	if b:GetData().itemDrop:GetSlot() == nil then return true end
	local s1 = a:GetData().itemDrop:GetSlot()
	local s2 = b:GetData().itemDrop:GetSlot()
	if s1 ~= s2 then return s1 < s2 else return ML.sortItemsInPoolByName(a,b) end
end

function ML.sortItemsInPoolByName(a,b)
	return a:GetData().itemDrop:GetName() < b:GetData().itemDrop:GetName()
end

function ML:DrawItems(bForceRedraw)
	for nLootId , entry in pairs(tCachedItems) do
		if not entry.wnd or entry.currentLocation ~= entry.destination or bForceRedraw then
			tCachedItems[nLootId].currentLocation = entry.destination
			if entry.wnd then entry.wnd:Destroy() end
			local wndTarget = entry.destination == 1 and self.wndLootList or (entry.destination == 4 and self.wndMasterLoot:FindChild("ActionSlot") or self.wndRandomList)
			if self.settings.bArrList and entry.destination ~= 4 then wndTarget = self.wndMasterLoot:FindChild("ItemPoolList"):FindChild("List") end
			if entry.destination == 1 or entry.destination == 2 or entry.destination == 4 then
				if self.settings.bArrList and entry.destination ~= 4 then
					tCachedItems[nLootId].wnd = Apollo.LoadForm(self.xmlDoc,"LooterFormEntry",wndTarget,self)
					entry.wnd:FindChild("ItemName"):SetText(entry.lootEntry.itemDrop:GetName())
					entry.wnd:SetName("BubbleItemTile")
				else
					tCachedItems[nLootId].wnd = Apollo.LoadForm(self.xmlDoc,"BubbleItemTile",wndTarget,self)
				end
				if entry.destination == 2 and self.settings.bArrList then entry.wnd:FindChild("Random"):SetCheck(true) end
				entry.wnd:FindChild("ItemFrame"):SetSprite(self:GetSlotSpriteByQuality(entry.lootEntry.itemDrop:GetItemQuality()))
				entry.wnd:FindChild("ItemIcon"):SetSprite(entry.lootEntry.itemDrop:GetIcon())
				entry.wnd:SetData(entry.lootEntry)
				if entry.destination ~= 4 then if self.settings.bArrList then self:ArrangeTiles(wndTarget,true,ML.sortItemsInPool) else wndTarget:ArrangeChildrenTiles() end end
				Tooltip.GetItemTooltipForm(self,entry.wnd, entry.lootEntry.itemDrop  ,{bPrimary = true, bSelling = false})
				
			elseif entry.destination == 5 then
				wndTarget = self.wndMasterLootLooter:FindChild("List")
				tCachedItems[nLootId].wnd = Apollo.LoadForm(self.xmlDoc,"LooterFormEntry",wndTarget,self)
				entry.wnd:FindChild("ItemFrame"):SetSprite(self:GetSlotSpriteByQuality(entry.lootEntry.itemDrop:GetItemQuality()))
				entry.wnd:FindChild("ItemIcon"):SetSprite(entry.lootEntry.itemDrop:GetIcon())
				Tooltip.GetItemTooltipForm(self,entry.wnd, entry.lootEntry.itemDrop  ,{bPrimary = true, bSelling = false})
				entry.wnd:FindChild("ItemName"):SetText(entry.lootEntry.itemDrop:GetName())
				entry.wnd:FindChild("Random"):Show(false)
				entry.wnd:SetData(entry)
				wndTarget:ArrangeChildrenVert()
			end
			
		end
	end
end

function ML:ShowMainWnd()
	self.wndMasterLoot:Show(true,false)
end

function ML:CreateRecipients()
	local targets = {}
	
	--[[local rops = Apollo.GetAddon("RaidOps")
	for k,player in ipairs(rops.tItems) do
		if k > 20  then break end
		if player.strName ~= "Guild Bank" then 
			table.insert(targets,{strName = player.strName})
		end
	end]]

	for k=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(k)
		local strRole = ""
		
		if member.bDPS then strRole = "DPS"
		elseif member.bHeal then strRole = "Heal"
		elseif member.bTank then strRole = "Tank"
		end

		if not Apollo.GetAddon("RaidOps") or not self.settings.bRopsIntegration then -- TODOm
			table.insert(targets,{strName = member.strCharacterName,role = strRole,class = ktClassToString[member.eClassId],tItemsAssigned = {},tItemsToBeAssigned = {}})
		else
			table.insert(targets,{strName = member.strCharacterName})
		end
	end

	if Apollo.GetAddon("RaidOps") and self.settings.bRopsIntegration then
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


	for k , target in ipairs(targets) do
		if not target.class then
			for k=1,GroupLib.GetMemberCount() do
				local member = GroupLib.GetGroupMember(k)
				if member.strCharacterName == target.strName then
					targets[k] = {strName = member.strCharacterName,role = strRole,class = ktClassToString[member.eClassId],tItemsAssigned = {},tItemsToBeAssigned = {}}
				end
			end
		end
	end

	self.tRecipients = targets
end

function ML:RecreateRecipients()
	-- map items to [name] = {item table}
	local tSavedItems = {}
	for k , recipient in ipairs(self.tRecipients) do
		tSavedItems[recipient.strName] = recipient.tItemsToBeAssigned
	end
	-- flush everyone down the drain
	self.tRecipients = {}
	-- and start from scratch
	self:CreateRecipients()
	-- assign stuff back
	for k , recipient in ipairs(self.tRecipients) do
		recipient.tItemsToBeAssigned = tSavedItems[recipient.strName] or {}
	end
	-- and draw them like nothing has happend
	self:DrawRecipients()
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
	local tRecipient = {}
	if not Apollo.GetAddon("RaidOps") or not self.settings.bRopsIntegration then
		tRecipient = {strName = tMember.strCharacterName,role = strRole,class = ktClassToString[tMember.eClassId],tItemsAssigned = {},tItemsToBeAssigned = {}}
	else
		tRecipient = {strName = tMember.strCharacterName}
	end
	if Apollo.GetAddon("RaidOps") and self.settings.bRopsIntegration then
		local EPGPHook =  Apollo.GetAddon("RaidOps")
		local ID = EPGPHook:GetPlayerByIDByName(tRecipient.strName)
		if ID ~= -1 then 
			tRecipient.role = EPGPHook.tItems[ID].role
			tRecipient.offrole = EPGPHook.tItems[ID].offrole
			tRecipient.class = EPGPHook.tItems[ID].class

			tRecipient.ID = ID 
			tRecipient.PR = EPGPHook:EPGPGetPRByID(ID)
			tRecipient.tItemsToBeAssigned = {}
			tRecipient.tItemsAssigned = {}
		end
	end
	table.insert(self.tRecipients,tRecipient)
end

function ML:DrawRecipients()
	self.wndLooterList:DestroyChildren()
	for k , recipient in ipairs(self.tRecipients) do
		recipient.wnd = nil
	end
	if self.settings.bGroup then
		if self.settings.currSort == "SortPR" then
			table.sort(self.tRecipients,ML.sortByClassPR)
		else
			table.sort(self.tRecipients,ML.sortByClassName)
		end
	else
		if self.settings.currSort == "SortPR" then
			table.sort(self.tRecipients,ML.sortByValue)
		else
			table.sort(self.tRecipients,ML.sortByName)
		end
	end
	
	for k , recipient in ipairs(self.tRecipients) do
		if not recipient.wnd then
			recipient.wnd = Apollo.LoadForm(self.xmlDoc,"RecipientEntry",self.wndLooterList,self)
			self:UpdateRecipientWnd(recipient,true)
		end
	end

	self:ArrangeTiles(self.wndLooterList,true)
end

function ML:UpdateRecipientWnd(tRecipient,bSuppressArr)
	if not tRecipient then return end

	tRecipient.wnd:FindChild("ClassIcon"):SetSprite(ktStringToNewIconOrig[tRecipient.class])
	tRecipient.wnd:FindChild("RoleIcon"):SetSprite(ktRoleStringToIcon[tRecipient.role])
	tRecipient.wnd:FindChild("PlayerName"):SetText(tRecipient.strName)
	if tRecipient.offrole then
		tRecipient.wnd:FindChild("OffRoleIcon"):SetSprite(ktRoleStringToIcon[tRecipient.offrole])
	else
		tRecipient.wnd:FindChild("OffRoleIcon"):Show(false)
	end
	
	tRecipient.wnd:FindChild("HookValue"):SetText(tRecipient.PR)
	if not tRecipient.tItemsToBeAssigned then tRecipient.tItemsToBeAssigned = {} end
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

function ML:FigureShow(bForce)
	local bML = false
	local bLooter = false
	
	if  true--[[#GameLib.GetMasterLoot() > 0]] then
		for k , entry in pairs(tCachedItems) do
			if entry.lootEntry.bIsMaster then bML = true
			else bLooter = true end
			if bML and bLooter then break end
		end

		if self.settings.bOOCAppear then
			local myUnit = GameLib.GetPlayerUnit()
			local bInCombat = myUnit and myUnit:IsInCombat() or false
			if bForce then
				bInCombat = false
			end
			if bInCombat then
				bML = false
				bLooter = false
				if self.settings.bReminder then
					self.wndReminder:Show(true,false)
				end
			end
		end
	end
	if not self.wndMasterLoot:IsShown() or #GameLib.GetMasterLoot() == 0 then
		self.wndMasterLoot:Show(bML,false)
	end
	if not self.wndMasterLoot:IsShown() or #GameLib.GetMasterLoot() == 0 then
		self.wndMasterLootLooter:Show(bLooter,false)
	end
	if #GameLib.GetMasterLoot() == 0 then
		self.wndReminder:Show(false,false)
		self.wndSummary:Show(false,false)
	end
	self:EnableActionSlotButtons()
end

function ML:HideMLWindow(wndHandler)
	self.wndMasterLoot:Show(false,false)
end

function ML:HideMLLooter(wndHandler)
	self.wndMasterLootLooter:Show(false,false)
end

function ML:ResetLootAssignment()
	for k , entry in pairs(tCachedItems) do
		if entry.lootEntry.bIsMaster then
			if self:FilterIsRandomed(entry.lootEntry.itemDrop) then
				entry.destination = 2
			else
				entry.destination = 1
			end
			if entry.strRecipient then
				for j , recipient in ipairs(self.tRecipients) do
					if recipient.strName == entry.strRecipient then
						self:RemoveLootFromRecipient(k,recipient)
						break
					end
				end
			end
		end
	end
	self:DrawItems()
end

function ML:FigureSizing()
	local bRPoolExpanded
	local bLPoolExpanded
	
	if self.settings.bArrList then
		self.wndMasterLoot:SetSizingMinimum(ktSizingPairs["Exp1"].x,ktSizingPairs["Exp1"].y)
	end

	if not self.settings.bArrList then
		if self.wndMasterLoot:FindChild("RandomPool"):GetData() then
			 bRPoolExpanded = self.wndMasterLoot:FindChild("RandomPool"):GetData().bExpanded
		else
			bRPoolExpanded = false
		end
		if self.wndMasterLoot:FindChild("ItemPool"):GetData() then
			bLPoolExpanded = self.wndMasterLoot:FindChild("ItemPool"):GetData().bExpanded
		else
			bLPoolExpanded = false
		end

		if bRPoolExpanded and bLPoolExpanded then 
			self.wndMasterLoot:SetSizingMinimum(ktSizingPairs["Exp2"].x,ktSizingPairs["Exp2"].y)
			local l,t,r,b = self.wndMasterLoot:GetAnchorOffsets()
			if b < ktSizingPairs["Exp2"].y then self.wndMasterLoot:SetAnchorOffsets(l,t,r,ktSizingPairs["Exp2"].y+80) end
		elseif bRPoolExpanded or bLPoolExpanded then
			self.wndMasterLoot:SetSizingMinimum(ktSizingPairs["Exp1"].x,ktSizingPairs["Exp1"].y)
		else
			self.wndMasterLoot:SetSizingMinimum(ktSizingPairs["Exp0"].x,ktSizingPairs["Exp0"].y)
		end
	end

	if self.wndMasterLootLoc ~= nil and self.wndMasterLootLoc.nOffsets[1] ~= 0 then 
		self.wndMasterLoot:MoveToLocation(WindowLocation.new(self.wndMasterLootLoc))
		self.wndMasterLootLoc = nil
	end	
	if self.wndReminderLoc ~= nil and self.wndReminderLoc.nOffsets[1] ~= 0 then 
		self.wndReminder:MoveToLocation(WindowLocation.new(self.wndReminderLoc))
		self.wndReminderLoc = nil
	end
end

function ML.sortByClassPR(a,b)
	local c1 = ktClassStringToId[a.class] + (ML.tClassWeight[a.class] or 0)
	local c2 = ktClassStringToId[b.class] + (ML.tClassWeight[b.class] or 0)
	return c1 == c2 and ML.sortByValue(a,b) or c1 < c2 
end

function ML.sortByClassName(a,b)
	if not ktClassStringToId[a.class] or not ML.tClassWeight[a.class] or not ktClassStringToId[b.class] or not ML.tClassWeight[b.class] then return ML.sortByName(a,b) end
	local c1 = ktClassStringToId[a.class] + ML.tClassWeight[a.class]
	local c2 = ktClassStringToId[b.class] + ML.tClassWeight[b.class]
	if c1 and c2 then return c1 == c2 and ML.sortByName(a,b) or c1 < c2 else return ML.sortByName(a,b) end
end

function ML.sortByValue(a,b)
	local pr1 = a.PR
	local pr2 = b.PR
	if pr1 and pr2 then return pr1 == pr2 and ML.sortByName(a,b) or pr1 > pr2 else return ML.sortByName(a,b) end
end

function ML.sortByName(a,b)
	return a.strName < b.strName
end

function ML:SortingTypeChanged(wndHandler,wndControl)
	self.settings.currSort = wndControl:GetName()
	self:DrawRecipients()
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
	self.wndMasterLoot:FindChild("ItemPool"):FindChild("Expand"):SetCheck(true)
	self:FigureSizing()
end

function ML:ExpandRandomPool()
	if not nPrevRandomCount or nPrevRandomCount ~= self.tRandomPool then
		nPrevRandomCount = #self.tRandomPool
		local nHeight = self:GetExpandValue(nPrevRandomCount,self.wndRandomList:GetWidth())
		self.wndMasterLoot:FindChild("RandomPool"):SetData({nHeight = nHeight,bExpanded = false})
	end
	self:ToggleResize(self.wndMasterLoot:FindChild("RandomPool"))
	self.wndMasterLoot:FindChild("RandomPool"):FindChild("Expand"):SetCheck(true)
	self:FigureSizing()
end

function ML:CollapseLootPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("ItemPool"))
	self:FigureSizing()
end

function ML:CollapseRandomPool()
	self:ToggleResize(self.wndMasterLoot:FindChild("RandomPool"))
	self:FigureSizing()
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
	if tc - t <= wnd:GetHeight() + 50 then
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
			if self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile") then
				table.insert(tChildren,self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile"))
			end
			for k ,wnd in ipairs(self.wndMasterLoot:FindChild("ItemPoolList"):FindChild("List"):GetChildren()) do
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
			for k ,wnd in ipairs(self.wndMasterLoot:FindChild("ItemPoolList"):FindChild("List"):GetChildren()) do
				table.insert(tChildren,wnd)
			end
			if self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile") then
				table.insert(tChildren,self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile"))
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

function ML:TriggerChatBidding()
	Event_FireGenericEvent("RaidOpsChatBidding",self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile"):GetData())
end

function ML:TriggerNetworkBidding()
	Event_FireGenericEvent("RaidOpsNetworkBidding",self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile"):GetData())
end

function ML:ChangeSearchType(wndHandler,wndControl)
	self.settings.strSearchType = wndControl:GetName()
	self:Search(nil,nil,self.wndMasterLoot:FindChild("Search"):GetText())
end

function ML:WindowResized()
	self:ArrangeTiles(self.wndLooterList)
end


local tPrevOffsets = {}
function ML:ArrangeTiles(wndList,bForce,sortFunc)
	if tPrevOffsets[wndList] and not bForce then
		if tPrevOffsets[wndList] == wndList:GetWidth() + wndList:GetHeight() then return end
		tPrevOffsets[wndList] = wndList:GetWidth() + wndList:GetHeight()
	else
		tPrevOffsets[wndList] = wndList:GetWidth() + wndList:GetHeight()
	end
	
	local prevChild
	local highestInRow = {}
	local tRows = {}
	for k,child in ipairs(wndList:GetChildren()) do
		child:SetAnchorOffsets(knRecipientHorzSpacing,0,child:GetWidth()+knRecipientHorzSpacing,child:GetHeight())
	end
	local counter = 0
	local children = wndList:GetChildren()
	if sortFunc then
		table.sort(children,sortFunc)
	end
	for k,child in ipairs(children) do
		if child:IsShown() and not self.settings.bKeepPositions or self.settings.bKeepPositions then 
			counter = counter + 1
			if counter > 1 then
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
end


-----------------------------------------------------------------------------------------------
-- Drag&Drop
-----------------------------------------------------------------------------------------------

function ML:MoveItemToRandomPool(wndHandler,wndControl)
	local nLootId = wndControl:GetParent():GetData().nLootId
	tCachedItems[nLootId].destination = 2
	self:DrawItems()
end

function ML:MoveItemToLootPool(wndHandler,wndControl)
	local nLootId = wndControl:GetParent():GetData().nLootId
	tCachedItems[nLootId].destination = 1
	self:DrawItems()
end

function ML:OnDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	local tData = wndSource:GetName() == "BubbleItemTile" and wndSource:GetData() or wndSource:GetData().lootEntry

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
	elseif wndHandler:GetName() == "ItemPool" or wndHandler:GetName() == "ItemPoolList" then
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
	elseif wndHandler:GetName() == "ActionSlot" then
		tCachedItems[tData.nLootId].destination = 4
	end

	for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
		wnd:FindChild("NonApp"):Show(false)
		wnd:Show(true)
	end
	if self.settings.bHideInapp then self:ArrangeTiles(self.wndLooterList,true) end
	self:DrawItems(true)
	self:EnableActionSlotButtons()
	self:Search(nil,nil,self.wndMasterLoot:FindChild("Search"):GetText())
end

function ML:DragDropCancel()
	for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
		wnd:FindChild("NonApp"):Show(false)
		wnd:Show(true)
	end
	if self.settings.bHideInapp then self:ArrangeTiles(self.wndLooterList,true) end
end

function ML:OnQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndHandler:GetName() == "Settings" then return  Apollo.DragDropQueryResult.Cancel end 
	if wndSource:GetName() == "ClassOrderTile" then return  Apollo.DragDropQueryResult.Cancel end
	if wndHandler:GetName() == "PlayerItemTile" then wndHandler = wndHandler:GetParent():GetParent() end
	if string.find(wndHandler:GetName(),"Pool") or wndHandler:GetName() == "RecipientEntry" or wndControl:GetName() == "ActionSlot" and not self.wndMasterLoot:FindChild("ActionSlot"):FindChild("BubbleItemTile") then
		if wndHandler:GetName() == "RecipientEntry" then
			if self:IsRecipientApplicable(wndHandler,wndSource) then 
				wndHandler:FindChild("NonApp"):Show(false)
				wndHandler:FindChild("Highlight"):Show(true)
				return Apollo.DragDropQueryResult.Accept		
			else 
				wndHandler:FindChild("NonApp"):Show(true)
				wndHandler:FindChild("Highlight"):Show(false)
				return Apollo.DragDropQueryResult.PassOn 
			end
		else
			wndHandler:FindChild("Highlight"):Show(true)
			return Apollo.DragDropQueryResult.Accept
		end
		
	else
		return Apollo.DragDropQueryResult.PassOn
	end
end

function ML:HideHighligt(wndHandler,wndControl)
	wndHandler:FindChild("Highlight"):Show(false)
end

function ML:OnTileMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl or not wndControl:GetData() then return end
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		if wndControl:GetName() == "BubbleItemTile" then
			Apollo.BeginDragDrop(wndControl, "MLLootTransfer", wndControl:GetData().itemDrop:GetIcon(), wndControl:GetData().nLootId)
		elseif wndControl:GetName() == "PlayerItemTile" and wndControl:GetData() then
			Apollo.BeginDragDrop(wndControl, "MLLootTransfer", wndControl:GetData().lootEntry.itemDrop:GetIcon(), wndControl:GetData().lootEntry.nLootId)
		end

		for k , wnd in ipairs(self.wndLooterList:GetChildren()) do
			if not self.settings.bHideInapp then
				wnd:FindChild("NonApp"):Show(not self:IsRecipientApplicable(wnd,wndControl))
			else
				wnd:Show(self:IsRecipientApplicable(wnd,wndControl))
			end
		end
		if self.settings.bHideInapp then
			self:ArrangeTiles(self.wndLooterList,true)
		end
		
		if wndHandler:GetName() == "RecipientEntry" then wndHandler:FindChild("NonApp"):Show(false) end
	else
		local nLootId 
		if wndControl:GetName() == "BubbleItemTile" then
			nLootId = wndControl:GetData().nLootId
		elseif wndControl:GetName() == "PlayerItemTile" and wndControl:GetData() then
			nLootId = wndControl:GetData().lootEntry.nLootId
		end

		if tCachedItems[nLootId] then
			for k , recipient in ipairs(self.tRecipients) do
				if recipient.strName == tCachedItems[nLootId].strRecipient then
					tCachedItems[nLootId].strRecipient = nil
					for j , item in ipairs(recipient.tItemsToBeAssigned) do
						if item == nLootId then table.remove(recipient.tItemsToBeAssigned,j) self:UpdateRecipientWnd(recipient) break end
					end
				end
			end

			tCachedItems[nLootId].destination = 1
		end

		self:DrawItems()
	end
end

function ML:EnableActionSlotButtons()
	if #self.wndMasterLoot:FindChild("ActionSlot"):GetChildren() > 1 then
		self.wndMasterLoot:FindChild("CB"):Enable(true)
		self.wndMasterLoot:FindChild("NB"):Enable(true)
		self.wndMasterLoot:FindChild("BiddingGlow"):Show(true)
		self.wndMasterLoot:FindChild("BiddingGlow1"):Show(true)
	else		
		self.wndMasterLoot:FindChild("BiddingGlow1"):Show(false)
		self.wndMasterLoot:FindChild("BiddingGlow"):Show(false)
		self.wndMasterLoot:FindChild("CB"):Enable(false)
		self.wndMasterLoot:FindChild("NB"):Enable(false)
	end
end

function ML:IsRecipientApplicable(wndTarget,wndSource)
	if not wndTarget or not wndSource then return end
	local tData = wndSource:GetName() == "BubbleItemTile" and wndSource:GetData() or wndSource:GetData().lootEntry

	local bCanLoot
	local bInRange = true
	for k , playerUnit in pairs(tCachedItems[tData.nLootId].lootEntry.tLooters or {}) do
		if wndTarget:GetData().strName == playerUnit:GetName() then bCanLoot = true break end
	end	
	for k , playerUnit in pairs(tCachedItems[tData.nLootId].lootEntry.tLootersOutOfRange or {}) do
		if wndTarget:GetData().strName == playerUnit then bInRange = false break end
	end
	
	if wndTarget:GetData().strName == "Cpt Bicard" then return true end
	--bInRange = true
	--bCanLoot = true
	if bInRange and bCanLoot then 
		if self.settings.bClassFilter then 
			return self:IsClassApplicable(tData,wndTarget:GetData()) 
		else 
			return true 
		end 
	else 
		return false 
	end
end

function ML:IsClassApplicable(tData,tRecipient)
	local bWantEsp = true
	local bWantWar = true
	local bWantSpe = true
	local bWantMed = true
	local bWantSta = true
	local bWantEng = true
	
	if string.find(tData.itemDrop:GetName(),"Imprint") then
	    bWantEsp = false
	    bWantWar = false
	    bWantSpe = false
	    bWantMed = false
	    bWantSta = false
	    bWantEng = false
		
		local tDetails = tData.itemDrop:GetDetailedInfo()
		if tDetails.tPrimary.arClassRequirement then
			for k , class in ipairs(tDetails.tPrimary.arClassRequirement.arClasses) do
				if class == 1 then bWantWar = true
				elseif class == 2 then bWantEng = true
				elseif class == 3 then bWantEsp = true
				elseif class == 4 then bWantMed = true
				elseif class == 5 then bWantSta = true
				elseif class == 7 then bWantSpe = true
				end
			end
		end
	elseif tData.itemDrop:IsEquippable() then
		local strCategory = tData.itemDrop:GetItemCategoryName()
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

	if tRecipient.class == "Esper" then return bWantEsp
	elseif tRecipient.class == "Stalker" then return bWantSta 
	elseif tRecipient.class == "Medic" then return bWantMed
	elseif tRecipient.class == "Warrior" then return bWantWar
	elseif tRecipient.class == "Spellslinger" then return bWantSpe
	elseif tRecipient.class == "Engineer" then return bWantEng
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
-- Filtering
-----------------------------------------------------------------------------------------------

function ML:FilterInit()
	self.wndFilter = Apollo.LoadForm(self.xmlDoc,"Filters",nil,self)
	self.wndFilter:Show(false)

	-- Defaults

	if not self.settings.tFilters then self.settings.tFilters = {} end
	if self.settings.tFilters.bSigns == nil then self.settings.tFilters.bSigns = false end
	if self.settings.tFilters.bSignsAuto == nil then self.settings.tFilters.bSignsAuto = false end	
	
	if self.settings.tFilters.bPatterns == nil then self.settings.tFilters.bPatterns = false end
	if self.settings.tFilters.bPatternsAuto == nil then self.settings.tFilters.bPatternsAuto = false end	

	if self.settings.tFilters.bSchem == nil then self.settings.tFilters.bSchem = false end
	if self.settings.tFilters.bSchemAuto == nil then self.settings.tFilters.bSchemAuto = false end	
	
	if self.settings.tFilters.bWhite == nil then self.settings.tFilters.bWhite = false end
	if self.settings.tFilters.bWhiteAuto == nil then self.settings.tFilters.bWhiteAuto = false end	
	
	if self.settings.tFilters.bGray == nil then self.settings.tFilters.bGray = false end
	if self.settings.tFilters.bGrayAuto == nil then self.settings.tFilters.bGrayAuto = false end	
	
	if self.settings.tFilters.bGreen == nil then self.settings.tFilters.bGreen = false end
	if self.settings.tFilters.bGreenAuto == nil then self.settings.tFilters.bGreenAuto = false end	

	if self.settings.tFilters.bBlue == nil then self.settings.tFilters.bBlue = false end
	if self.settings.tFilters.bBlueAuto == nil then self.settings.tFilters.bBlueAuto = false end

	-- Fill in

	self.wndFilter:FindChild("Sign"):SetCheck(self.settings.tFilters.bSigns)
	self.wndFilter:FindChild("Sign"):FindChild("Auto"):SetCheck(self.settings.tFilters.bSignsAuto)
	
	self.wndFilter:FindChild("Patt"):SetCheck(self.settings.tFilters.bPatterns)
	self.wndFilter:FindChild("Patt"):FindChild("Auto"):SetCheck(self.settings.tFilters.bPatternsAuto)
	
	self.wndFilter:FindChild("Schem"):SetCheck(self.settings.tFilters.bSchem)
	self.wndFilter:FindChild("Schem"):FindChild("Auto"):SetCheck(self.settings.tFilters.bSchemAuto)
	
	self.wndFilter:FindChild("Gray"):SetCheck(self.settings.tFilters.bGray)
	self.wndFilter:FindChild("Gray"):FindChild("Auto"):SetCheck(self.settings.tFilters.bGrayAuto)
	
	self.wndFilter:FindChild("White"):SetCheck(self.settings.tFilters.bWhite)
	self.wndFilter:FindChild("White"):FindChild("Auto"):SetCheck(self.settings.tFilters.bWhiteAuto)
	
	self.wndFilter:FindChild("Green"):SetCheck(self.settings.tFilters.bGreen)
	self.wndFilter:FindChild("Green"):FindChild("Auto"):SetCheck(self.settings.tFilters.bGreenAuto)
	
	self.wndFilter:FindChild("Blue"):SetCheck(self.settings.tFilters.bBlue)
	self.wndFilter:FindChild("Blue"):FindChild("Auto"):SetCheck(self.settings.tFilters.bBlueAuto)

	-- Populate custom
	if not self.settings.tFilters.tCustom then self.settings.tFilters.tCustom = {} end

	self:FilterPopulate()
end

function ML:FilterShow() 
	self.wndFilter:Show(true,false)
	self.wndFilter:ToFront()

	self:FilterPopulate()
end

function ML:FilterHide()
	self.wndFilter:Show(false,false)
end

local function containsWord(tWords,word)
	for k , strWord in ipairs(tWords) do
		if strWord == word then return true end
	end
	return false 
end

function ML:FilterIsRandomed(item)
	local  words = {}
	for word in string.gmatch(item:GetName(),"%S+") do
		table.insert(words,word)
	end
	if self.settings.tFilters.bSigns and containsWord(words,"Sign") then return true end
	if self.settings.tFilters.bPatterns and containsWord(words,"Pattern") then return true end
	if self.settings.tFilters.bSchem and containsWord(words,"Schematic") then return true end
	if self.settings.tFilters.bWhite and item:GetItemQuality() == 2 then return true end
	if self.settings.tFilters.bGray and item:GetItemQuality() == 1 then return true end
	if self.settings.tFilters.bGreen and item:GetItemQuality() == 3 then return true end
	if self.settings.tFilters.bBlue and item:GetItemQuality() == 4 then return true end

	for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
		if containsWord(words,tFilter.strKeyword) then return true end
	end

	return false
end

function ML:FilterIsAuto(item)
	local  words = {}
	for word in string.gmatch(item:GetName(),"%S+") do
		table.insert(words,word)
	end
	if self.settings.tFilters.bSignsAuto and containsWord(words,"Sign") then return true end
	if self.settings.tFilters.bPatternsAuto and containsWord(words,"Pattern") then return true end
	if self.settings.tFilters.bSchemAuto and containsWord(words,"Schematic") then return true end
	if self.settings.tFilters.bGrayAuto and item:GetItemQuality() == 1 then return true end
	if self.settings.tFilters.bWhiteAuto and item:GetItemQuality() == 2 then return true end
	if self.settings.tFilters.bGreenAuto and item:GetItemQuality() == 3 then return true end
	if self.settings.tFilters.bBlueAuto and item:GetItemQuality() == 4 then return true end

	for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
		if tFilter.bAuto and containsWord(words,tFilter.strKeyword) then return true end
	end

	return false
end

function ML:FilterPopulate()
	self.wndFilter:FindChild("List"):DestroyChildren()
	for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"FilterKeywordEntry",self.wndFilter:FindChild("List"),self)
		wnd:FindChild("Keyword"):SetText(tFilter.strKeyword)
		wnd:FindChild("Keyword"):Enable(false)
		wnd:FindChild("Auto"):SetCheck(tFilter.bAuto)
		wnd:SetName(tFilter.strKeyword)
	end
	local wnd = Apollo.LoadForm(self.xmlDoc,"FilterKeywordEntry",self.wndFilter:FindChild("List"),self)
	wnd:FindChild("Keyword"):SetText("Type new keyword here.")
	wnd:FindChild("Auto"):Show(false)
	wnd:FindChild("Rem"):Show(false)
	self:FilterArrangeWords()
end

local prevWord
function ML:FilterArrangeWords()
	local list = self.wndFilter:FindChild("List")
	local children = list:GetChildren()
	for k , child in ipairs(children) do
		child:SetAnchorOffsets(5,0,child:GetWidth()+5,child:GetHeight())
	end
	for k , child in ipairs(children) do
		if k > 1 then
			local l,t,r,b = prevWord:GetAnchorOffsets()
			child:SetAnchorOffsets(5,b-50,child:GetWidth()+5,b+child:GetHeight()-50)
		end
		prevWord = child
	end
end

function ML:FilterAddCustom(wndHandler,wndControl,strText)
	if strText and strText ~= "" then
		local  words = {}
		for word in string.gmatch(strText,"%S+") do
			table.insert(words,word)
		end
		if #words > 1 then return end
		for k , tFilter in ipairs(self.settings.tFilters.tCustom) do if string.lower(tFilter.strKeyword) == string.lower(strText) then return end end
		wndControl:SetText("")
		table.insert(self.settings.tFilters.tCustom,{strKeyword = strText,bAuto = false})
		self:FilterPopulate()
	end
end

function ML:FilterRemoveCustom(wndHandler,wndControl)
	for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
		if tFilter.strKeyword == wndControl:GetParent():GetName() then table.remove(self.settings.tFilters.tCustom,k) break end
	end
	self:FilterPopulate()
end

function ML:FilterEnablePreset(wndHandler,wndControl)
	if wndControl:GetName() == "Sign" then self.settings.tFilters.bSigns = true
	elseif wndControl:GetName() == "Patt" then self.settings.tFilters.bPatterns = true
	elseif wndControl:GetName() == "Schem" then self.settings.tFilters.bSchem = true
	elseif wndControl:GetName() == "Gray" then self.settings.tFilters.bGray = true
	elseif wndControl:GetName() == "White" then self.settings.tFilters.bWhite = true
	elseif wndControl:GetName() == "Green" then self.settings.tFilters.bGreen = true
	elseif wndControl:GetName() == "Blue" then self.settings.tFilters.bBlue = true
	end
end

function ML:FilterDisablePreset(wndHandler,wndControl)
	if wndControl:GetName() == "Sign" then self.settings.tFilters.bSigns = false
	elseif wndControl:GetName() == "Patt" then self.settings.tFilters.bPatterns = false
	elseif wndControl:GetName() == "Schem" then self.settings.tFilters.bSchem = false
	elseif wndControl:GetName() == "Gray" then self.settings.tFilters.bGray = false
	elseif wndControl:GetName() == "White" then self.settings.tFilters.bWhite = false
	elseif wndControl:GetName() == "Green" then self.settings.tFilters.bGreen = false
	elseif wndControl:GetName() == "Blue" then self.settings.tFilters.bBlue = false
	end
end

function ML:FilterRegisterAutoRandom(wndHandler,wndControl)
	wndControl = wndControl:GetParent()
	if wndControl:GetName() == "Sign" then self.settings.tFilters.bSignsAuto = true
	elseif wndControl:GetName() == "Patt" then self.settings.tFilters.bPatternsAuto = true
	elseif wndControl:GetName() == "Schem" then self.settings.tFilters.bSchemAuto = true
	elseif wndControl:GetName() == "Gray" then self.settings.tFilters.bGrayAuto = true
	elseif wndControl:GetName() == "White" then self.settings.tFilters.bWhiteAuto = true
	elseif wndControl:GetName() == "Green" then self.settings.tFilters.bGreenAuto = true
	elseif wndControl:GetName() == "Blue" then self.settings.tFilters.bBlueAuto = true
	else
		for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
			if tFilter.strKeyword == wndControl:GetName() then tFilter.bAuto = true break end
		end
	end
end

function ML:FilterDeregisterAutoRandom(wndHandler,wndControl)
	wndControl = wndControl:GetParent()
	if wndControl:GetName() == "Sign" then self.settings.tFilters.bSignsAuto = false
	elseif wndControl:GetName() == "Patt" then self.settings.tFilters.bPatternsAuto = false
	elseif wndControl:GetName() == "Schem" then self.settings.tFilters.bSchemAuto = false
	elseif wndControl:GetName() == "Gray" then self.settings.tFilters.bGrayAuto = false
	elseif wndControl:GetName() == "White" then self.settings.tFilters.bWhiteAuto = false
	elseif wndControl:GetName() == "Green" then self.settings.tFilters.bGreenAuto = false
	elseif wndControl:GetName() == "Blue" then self.settings.tFilters.bBlueAuto = false
	else
		for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
			if tFilter.strKeyword == wndControl:GetName() then tFilter.bAuto = false break end
		end
	end
end
-----------------------------------------------------------------------------------------------
-- Summary
-----------------------------------------------------------------------------------------------


function ML:SummaryInit()
	self.wndSummary = Apollo.LoadForm(self.xmlDoc,"Summary",nil,self)
	self.wndSummary:Show(false)
end

function ML:SummaryHide()
	self.wndSummary:Show(false,false)
end

function ML:SummaryOpen(bRefresh)


	if not self.settings.bSummary and not bRefresh then
		self:AssignMasterLootWithoutSummary()
		return
	end

	if bRefresh == true then
		if not self.wndSummary:IsShown() then return end
	end
	local list = self.wndSummary:FindChild("List")
	list:DestroyChildren()
	for j ,entry in pairs(tCachedItems) do
		if entry.strRecipient then
			local wnd = Apollo.LoadForm(self.xmlDoc,"SummaryEntry",list,self)
			wnd:FindChild("ItemFrame"):SetSprite(self:GetSlotSpriteByQualityRectangle(entry.lootEntry.itemDrop:GetItemQuality()))
			wnd:FindChild("ItemIcon"):SetSprite(entry.lootEntry.itemDrop:GetIcon())
			wnd:FindChild("ItemName"):SetText(entry.lootEntry.itemDrop:GetName())
			Tooltip.GetItemTooltipForm(self,wnd:FindChild("ItemIcon"),entry.lootEntry.itemDrop,{})

			local player
			for k , recipient in ipairs(self.tRecipients) do
				if recipient.strName == entry.strRecipient then player = recipient break end
			end

			wnd:FindChild("PlayerName"):SetText(entry.strRecipient)
			wnd:FindChild("ClassIcon"):SetSprite(ktStringToNewIconOrig[player.class])
			local unit
			for k , playerUnit in ipairs(entry.lootEntry.tLooters or {}) do
				if playerUnit:GetName() == entry.strRecipient then
					unit = playerUnit
					break
				end
			end
			if not unit then 
				wnd:Destroy()
			else
				wnd:SetData({nLootId = j,unit = unit,tRecipient = player})
			end		
		end
	end
	list:ArrangeChildrenVert()
	for k , entry in pairs(tCachedItems) do
		if entry.currentLocation == 2 then
			GameLib.AssignMasterLoot(k,self:ChooseRandomLooter(entry.lootEntry))
		end
	end		
	if #list:GetChildren() > 0 then self.wndSummary:Show(true,false) else self.wndSummary:Show(false,false) end
	self.wndSummary:ToFront()
end

function ML:SummaryEntryAssign(wndHandler,wndControl)
	GameLib.AssignMasterLoot(wndControl:GetParent():GetData().nLootId,wndControl:GetParent():GetData().unit)
	self:RemoveLootFromRecipient(wndControl:GetParent():GetData().nLootId,wndControl:GetParent():GetData().tRecipient)
	self:DrawRecipients()
	self:SummaryOpen()
end

function ML:SummaryEntryRemove(wndHandler,wndControl)
	local nLootId = wndControl:GetParent():GetData().nLootId

	for k , recipient in ipairs(self.tRecipients) do
		if recipient.strName == tCachedItems[nLootId].strRecipient then
			tCachedItems[nLootId].strRecipient = nil
			for j , item in ipairs(recipient.tItemsToBeAssigned) do
				if item == nLootId then table.remove(recipient.tItemsToBeAssigned,j) self:UpdateRecipientWnd(recipient) break end
			end
		end
	end
	tCachedItems[nLootId].destination = 1
	self:DrawItems()
	self:SummaryOpen()
end

function ML:SummaryAssignAll()
	for k , child in ipairs(self.wndSummary:FindChild("List"):GetChildren()) do
		GameLib.AssignMasterLoot(child:GetData().nLootId,child:GetData().unit)
		self:RemoveLootFromRecipient(child:GetData().nLootId,child:GetData().tRecipient)
	end
	for k , entry in pairs(tCachedItems) do
		if entry.currentLocation == 2 then
			GameLib.AssignMasterLoot(k,self:ChooseRandomLooter(entry.lootEntry))
		end
	end		
	self:SummaryOpen()
end

function ML:AssignMasterLootWithoutSummary()
	for j ,entry in pairs(tCachedItems) do
		if entry.strRecipient then

			local player
			for k , recipient in ipairs(self.tRecipients) do
				if recipient.strName == entry.strRecipient then player = recipient break end
			end

			local unit
			for k , playerUnit in ipairs(entry.lootEntry.tLooters or {}) do
				if playerUnit:GetName() == entry.strRecipient then
					unit = playerUnit
					break
				end
			end
			if unit then
				GameLib.AssignMasterLoot(j,unit)
				self:RemoveLootFromRecipient(j,player)
			end
		end
	end
	for k , entry in pairs(tCachedItems) do
		if entry.currentLocation == 2 then
			GameLib.AssignMasterLoot(k,self:ChooseRandomLooter(entry.lootEntry))
		end
	end		
end

function ML:AssignItemOrderFromOtherSource(nLootId,strRecipient)
	if not tCachedItems[nLootId] then return end
	for k , playerUnit in ipairs(tCachedItems[nLootId].lootEntry.tLooters) do
		if string.lower(playerUnit:GetName()) == string.lower(strRecipient) then
			GameLib.AssignMasterLoot(nLootId,playerUnit)
			break
		end
	end
end

function ML:RemoveLootFromRecipient(nLootId,tRecipient)
	for j , item in ipairs(tRecipient.tItemsToBeAssigned) do
		if item == nLootId then table.remove(tRecipient.tItemsToBeAssigned,j) self:UpdateRecipientWnd(tRecipient) break end
	end
end
-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
function ML:SettingsInit()
	self.wndSet = Apollo.LoadForm(self.xmlDoc,"Settings",nil,self)
	self.wndSet:Show(false)

	if not self.settings.currSort then self.settings.currSort = "SortAlph" end
	self.wndSet:FindChild(self.settings.currSort):SetCheck(true)

	if self.settings.bRPExpand == nil then self.settings.bRPExpand = false end
	if self.settings.bLPExpand == nil then self.settings.bLPExpand = true end
	if self.settings.bOOCAppear == nil then self.settings.bOOCAppear = true end
	if self.settings.bReminder == nil then self.settings.bReminder = true end
	if self.settings.bSummary == nil then self.settings.bRPExpand = true end
	if self.settings.bRopsIntegration == nil then self.settings.bRopsIntegration = false end
	if self.settings.bGroup == nil then self.settings.bGroup = true end
	if self.settings.bHideInapp == nil then self.settings.bHideInapp = false end
	if self.settings.bClassFilter == nil then self.settings.bClassFilter = false end
	if self.settings.bKeepPositions == nil then self.settings.bKeepPositions = false end

	if not self.settings.tClassOrder then self.settings.tClassOrder = ktClassOrderDefault end
	local counter = 0
	for k , item in ipairs(self.settings.tClassOrder) do counter = counter + 1 end
	if counter < 6 then self.settings.tClassOrder = ktClassOrderDefault end
	self:SetClassOrderPopulate()
	self.wndSet:FindChild("Container"):FindChild("RPE"):SetCheck(self.settings.bRPExpand)
	self.wndSet:FindChild("LPE"):SetCheck(self.settings.bLPExpand)
	self.wndSet:FindChild("OOCApp"):SetCheck(self.settings.bOOCAppear)
	self.wndSet:FindChild("Reminder"):SetCheck(self.settings.bReminder)
	self.wndSet:FindChild("Summary"):SetCheck(self.settings.bSummary)
	self.wndSet:FindChild("RopsInt"):SetCheck(self.settings.bRopsIntegration)
	self.wndSet:FindChild("SortPR"):Enable(self.settings.bRopsIntegration)
	self.wndSet:FindChild("Group"):SetCheck(self.settings.bGroup)
	self.wndSet:FindChild("HideInapp"):SetCheck(self.settings.bHideInapp)
	self.wndSet:FindChild("ClassFilter"):SetCheck(self.settings.bClassFilter)
	self.wndSet:FindChild("KeepPosition"):SetCheck(self.settings.bKeepPositions)
	self.wndSet:FindChild("ArrangeList"):SetCheck(self.settings.bArrList)

	--Class Weight
	self:SetBuildClassWeightTable()

end

function ML:SetBuildClassWeightTable()
	ML.tClassWeight = {}
	for k , class in ipairs(self.settings.tClassOrder) do
		ML.tClassWeight[class] = k*10
	end	
end

function ML:SetOpen() 
	self.wndSet:Show(true,false)
	self.wndSet:ToFront()
end

function ML:SetHide()
	self.wndSet:Show(false,false)
end

function ML:SetRPExpandEnable()
	self.settings.bRPExpand = true
	if self.wndMasterLoot:FindChild("RandomPool"):GetData() and not self.wndMasterLoot:FindChild("RandomPool"):GetData().bExpanded and not self.settings.bArrList then self:ExpandRandomPool() end
	self.wndMasterLoot:FindChild("RandomPool"):FindChild("Expand"):Show(false)
end

function ML:SetRPExpandDisable()
	self.settings.bRPExpand = false
	self.wndMasterLoot:FindChild("RandomPool"):FindChild("Expand"):Show(true)
end

function ML:SetLPExpandEnable()
	self.settings.bLPExpand = true
	if self.wndMasterLoot:FindChild("ItemPool"):GetData() and not self.wndMasterLoot:FindChild("ItemPool"):GetData().bExpanded then self:ExpandLootPool() end
	self.wndMasterLoot:FindChild("ItemPool"):FindChild("Expand"):Show(false)
end

function ML:SetLPExpandDisable()
	self.settings.bLPExpand = false
	self.wndMasterLoot:FindChild("ItemPool"):FindChild("Expand"):Show(true)
end

function ML:SetOOCAppearEnable()
	self.settings.bOOCAppear = true
end

function ML:SetOOCAppearDisable()
	self.settings.bOOCAppear = false
end

function ML:SetReminderEnable()
	self.settings.bReminder = true
end

function ML:SetReminderDisable()
	self.settings.bReminder = false
end

function ML:SetSummaryEnable()
	self.settings.bSummary = true
end

function ML:SetSummaryDisable()
	self.settings.bSummary = false
end

function ML:SetClassFilterEnable()
	self.settings.bClassFilter = true
end

function ML:SetClassFilterDisable()
	self.settings.bClassFilter = false
end

function ML:SetRaidOpsIntegrationEnable()
	self.settings.bRopsIntegration = true
	self.wndSet:FindChild("SortPR"):Enable(true)
	self:RecreateRecipients()
end

function ML:SetRaidOpsIntegrationDisable()
	self.settings.bRopsIntegration = false
	self.wndSet:FindChild("SortPR"):Enable(false)
	self.settings.currSort = "SortAlph"
	self.wndSet:FindChild("SortAlph"):SetCheck(true)
	self.wndSet:FindChild("SortPR"):SetCheck(false)
	self:RecreateRecipients()
end

function ML:SetHideInappPlayersEnable()
	self.settings.bHideInapp = true
end

function ML:SetHideInappPlayersDisable()
	self.settings.bHideInapp = false
end

function ML:SetGroupEnable()
	self.settings.bGroup = true
	self:DrawRecipients()
end

function ML:SetGroupDisable()
	self.settings.bGroup = false
	self:DrawRecipients()
end

function ML:SetKeppRecipientsPostionsEnable()
	self.settings.bKeepPositions = true
end

function ML:SetKeppRecipientsPostionsDisable()
	self.settings.bKeepPositions = false
end

function ML:SetArrListEnable()
	self.settings.bArrList = true
	self:ChangeItemArrangeType()
end

function ML:SetArrListDisable()
	self.settings.bArrList = false
	self:ChangeItemArrangeType()
end

function ML:ChangeItemArrangeType()
	if self.settings.bArrList == true then
		self.wndMasterLoot:FindChild("Pools"):Show(false)
		self.wndMasterLoot:FindChild("ItemPoolList"):Show(true)
	else
		self.wndMasterLoot:FindChild("Pools"):Show(true)
		self.wndMasterLoot:FindChild("ItemPoolList"):Show(false)
	end
	self:DrawItems(true)
	self:FigureSizing()
end
-----------------------------------------------------------------------------------------------
-- Drag&Drop - Settings Class Order
-----------------------------------------------------------------------------------------------
function ML:SetClassOrderPopulate()
	self.wndSet:FindChild("ClassOrder"):FindChild("List"):DestroyChildren()
	for k , class in ipairs(self.settings.tClassOrder) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"ClassOrderTile",self.wndSet:FindChild("ClassOrder"):FindChild("List"),self)
		wnd:SetSprite(ktStringToNewIconOrig[class])
		wnd:SetData(k)
	end
	self.wndSet:FindChild("ClassOrder"):FindChild("List"):ArrangeChildrenHorz()
end

function ML:SetOrderTileShowHighliht(wndHandler,wndControl)
	wndHandler:FindChild("Highlight"):Show(true)
end

function ML:SetOrderTileHideHighliht(wndHandler,wndControl)
	wndHandler:FindChild("Highlight"):Show(false)
end

-- Drag&Drop

function ML:SetOrderTileStartDragDrop(wndHandler,wndControl)
	if wndHandler ~= wndControl or self.bClassOrderDragDrop then return end
	Apollo.BeginDragDrop(wndControl, "MLClassOrderSwap", wndControl:GetSprite(), wndControl:GetData())
	self.bClassOrderDragDrop = true
end

function ML:SetOrderTileQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndHandler:GetName() == "ClassOrderTile" then return Apollo.DragDropQueryResult.Accept else return Apollo.DragDropQueryResult.PassOn end
end

function ML:SetOrderTileDropped(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if wndHandler ~= wndControl then return end
	-- Swap in order table

	local source = self.settings.tClassOrder[wndSource:GetData()]
	local target = self.settings.tClassOrder[wndControl:GetData()]

	self.settings.tClassOrder[wndSource:GetData()] = target
	self.settings.tClassOrder[wndControl:GetData()] = source

	self:SetClassOrderPopulate()
	self.bClassOrderDragDrop = false

	self:SetBuildClassWeightTable()
	self:DrawRecipients()
end

function ML:SetOrderTileDragDropCancel()
	self.bClassOrderDragDrop = false
end

-----------------------------------------------------------------------------------------------
-- Generic ML stuff and comaptibilty 
-----------------------------------------------------------------------------------------------
function ML:OnLootAssigned(objItem, strLooter)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), objItem:GetName(), strLooter))
end

function ML:OnToggleGroupBag()
	self:FigureShow(true) -- if there's something it will be opened regardless of combat state
end
-----------------------------------------------------------------------------------------------
-- ML Instance
-----------------------------------------------------------------------------------------------
local MLInst = ML:new()
MLInst:Init()
