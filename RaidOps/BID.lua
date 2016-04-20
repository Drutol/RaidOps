-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOps
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

require "ICComm"

local Hook = Apollo.GetAddon("MasterLootDependency")
local DKP = Apollo.GetAddon("RaidOps")

local kcrNormalText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrSelectedText = ApolloColor.new("ChannelAdvice")

local knMemberModuleVersion = 1.94

local ktClassToIcon =
{
	[GameLib.CodeEnumClass.Medic]       	= "Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Esper]       	= "Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "Icon_Windows_UI_CRB_Spellslinger",
}

local ktStringToIcon = {}

local ktStringToIconOrig =
{
	["Medic"]       	= "Icon_Windows_UI_CRB_Medic",
	["Esper"]       	= "Icon_Windows_UI_CRB_Esper",
	["Warrior"]     	= "Icon_Windows_UI_CRB_Warrior",
	["Stalker"]     	= "Icon_Windows_UI_CRB_Stalker",
	["Engineer"]    	= "Icon_Windows_UI_CRB_Engineer",
	["Spellslinger"]  	= "Icon_Windows_UI_CRB_Spellslinger",
}

local ktStringToNewIconOrig =
{
	["Medic"]       	= "BK3:UI_Icon_CharacterCreate_Class_Medic",
	["Esper"]       	= "BK3:UI_Icon_CharacterCreate_Class_Esper",
	["Warrior"]     	= "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	["Stalker"]     	= "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	["Engineer"]    	= "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	["Spellslinger"]  	= "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
}


local ktOptionToIcon =
{
	["Opt1"] = "CM_Engineer:spr_CM_Engineer_BarEdgeGlow_InCombat2",
	["Opt2"] = "CM_Engineer:spr_CM_Engineer_BarEdgeGlow_InCombat1",
	["Opt4"] = "CM_Engineer:spr_CM_Engineer_BarEdgeGlow_OutOfCombat",
	["Opt3"] = "CM_Engineer:spr_CM_Engineer_BarEdgeGlow_InCombat1",
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

local defaultSlotValues =
{
	["Weapon"] = 300,
	["Shield"] = 200,
	["Head"] = 250,
	["Shoulders"] = 250,
	["Chest"] = 300,
	["Hands"] = 200,
	["Legs"] = 300,
	["Attachment"] = 200,
	["Gadget"] = 150,
	["Implant"] = 150,
	["Feet"] = 250,
	["Support"] = 150
}

local umplauteConversions =
{
	["ä"] = "ae",
	["ö"] = "oe",
	["ü"] = "ue",
	["ß"] = "ss",
	["Ü"] = "Ue",
	["Ö"] = "Oe",
	["Ä"] = "Ae",
	["Ú"] = "U",
	["ú"] = "u",
 }

local ktDefaultCommands =
{
	["Cmd1"] =
	{
		bEnable = true,
		strCmd = "bid",
	},
	["Cmd2"] =
	{
		bEnable = true,
		strCmd = "off",
	},
	["Cmd3"] =
	{
		bEnable = false,
		strCmd = "---",
	},
	["Cmd4"] =
	{
		bEnable = false,
		strCmd = "---",
	},
}

local ktDefaultBidModifiers =
{
	[1] = 100,
	[2] = 100,
	[3] = 100,
	[4] = 100,
}

local bInitialized = false
local timeout = 5
function DKP:BidBeginInit()
	if self.tItems["settings"].bColorIcons then ktStringToIcon = ktStringToNewIconOrig else ktStringToIcon = ktStringToIconOrig end
	Apollo.RegisterTimerHandler(1, "OnWait", self)
	self.wait_timer = ApolloTimer.Create(1, true, "OnWait", self)
end

function DKP:BidUpdateColorScheme()
	if self.tItems["settings"].bColorIcons then ktStringToIcon = ktStringToNewIconOrig else ktStringToIcon = ktStringToIconOrig end
end

local wait_counter = 0
function DKP:OnWait()
	if wait_counter == 1 then
		if bInitialized == false then
			self:BidCompleteInit()
		end
	else
		wait_counter = wait_counter + 1
	end
end

function DKP:BidCompleteInit()
	Hook = Apollo.GetAddon("MasterLootDependency") --or Apollo.GetAddon("RaidOpsLootHex")
	Apollo.RegisterEventHandler("MasterLootUpdate","BidUpdateItemDatabase", self)
	Apollo.RegisterEventHandler("ThrottledEvent","BidUpdateItemDatabase", self)

	if Hook == nil then
		self.wndMain:FindChild("CustomAuction"):Show(false)
		self.wndMain:FindChild("BidCustomStart"):Show(false)
		self.wndMain:FindChild("LabelAuction"):Show(false)
		Print("RaidOps - Could not find Dependency Master Loot Addon - All Bidding/ML Functionalities are now suspended.")
		self:DSInit()
		bInitialized = true
		self.wait_timer:Stop()
		return
	end

	bInitialized = true
	self.wait_timer:Stop()

	self:InitBid2()
	self:DSInit()

	Apollo.RegisterSlashCommand("chatbid", "BidOpen", self)
	if self.ItemDatabase == nil then
		self.ItemDatabase = {}
	end
	self:MLSettingsRestore()
	self.RegistredBidWinners = {}
	self.RegisteredWinnersByName = {}

	self.InsertedCountersList = {}
	self.SelectedLooterItem = nil
	self.SelectedMasterItem = nil

	if not Apollo.GetAddon("RaidOpsLootHex") then
		if self.tItems["settings"]["ML"].bStandardLayout then
			if self.tItems["settings"]["ML"].bDispBidding then
				self.wndInsertedMasterButton = Apollo.LoadForm(self.xmlDoc,"InsertNetworkBidding",Hook.wndMasterLoot:FindChild("Framing"),self)
				self.wndInsertedMasterButton1 = Apollo.LoadForm(self.xmlDoc,"InsertChatBidding",Hook.wndMasterLoot:FindChild("Framing"),self)
				self.wndInsertedMasterButton1:Enable(false)
				self.wndInsertedMasterButton:Enable(false)
				local l,t,r,b = Hook.wndMasterLoot:FindChild("Assignment"):GetAnchorOffsets()
				Hook.wndMasterLoot:FindChild("Assignment"):SetAnchorOffsets(l,t,r-225,b)
			end


		else
			Hook.wndMasterLoot:Destroy()
			Hook.wndMasterLoot = Apollo.LoadForm(self.xmlDoc2,"MasterLootWindowVertLayout",nil,Hook)
			Hook.wndMasterLoot:SetSizingMinimum(579,559)
			Hook.wndMasterLoot:MoveToLocation(Hook.locSavedMasterWindowLoc)
			Hook.wndMasterLoot_ItemList = Hook.wndMasterLoot:FindChild("ItemList")
			Hook.wndMasterLoot_LooterList = Hook.wndMasterLoot:FindChild("LooterList")
			if self.tItems["settings"]["ML"].bDispBidding then
				self.wndInsertedMasterButton = Apollo.LoadForm(self.xmlDoc2,"InsertChatBidButtonVert",Hook.wndMasterLoot:FindChild("Framing"),self)
				self.wndInsertedMasterButton1 = Apollo.LoadForm(self.xmlDoc2,"InsertNetworkBidButtonVert",Hook.wndMasterLoot:FindChild("Framing"),self)
				self.wndInsertedMasterButton:Enable(false)
				self.wndInsertedMasterButton1:Enable(false)
			end

		end

		Hook.wndMasterLoot:SetSizingMinimum(800, 310)
		Hook.wndMasterLoot:FindChild("MasterLoot_Window_Title"):SetAnchorOffsets(48,27,-350,63)
		--Asc/Desc
		if self.tItems["settings"].BidSortAsc == nil then self.tItems["settings"].BidSortAsc = 1 end
		if self.tItems["settings"].BidMLSorting == nil then self.tItems["settings"].BidMLSorting = 1 end


		self.wndInsertedControls = Apollo.LoadForm(self.xmlDoc2,"InsertMLControls",Hook.wndMasterLoot,self)
		if self.tItems["EPGP"].Enable == 0 then
			self.wndInsertedControls:FindChild("SortPR"):SetText("DKP")
		end

		if self.tItems["settings"].BidSortAsc == 1 then
			self.wndInsertedControls:FindChild("Window"):FindChild("Asc"):SetCheck(true)
		else
			self.wndInsertedControls:FindChild("Window"):FindChild("Desc"):SetCheck(true)
		end

	self.wndInsertedControls:FindChild("Window"):FindChild("Asc"):SetRotation(270)
	self.wndInsertedControls:FindChild("Window"):FindChild("Desc"):SetRotation(90)

		self.wndInsertedControls:FindChild("DispApplicable"):SetCheck(self.tItems["settings"]["ML"].bDisplayApplicable)
		if not self.tItems["settings"]["ML"].bSortByName then self.wndInsertedControls:FindChild("SortPR"):SetCheck(true) else self.wndInsertedControls:FindChild("SortName"):SetCheck(true) end

		self:HookToMasterLootDisp()
		self.PrevSelectedLooterItem = nil
	end


	self:BidUpdateItemDatabase()

	-- Proper Bidding window
	self.CurrentItemChatStr = nil
	self.wndBid = Apollo.LoadForm(self.xmlDoc2,"BiddingUI",nil,self)
	self.wndBid:Show(false,true)

	if self.tItems["settings"].BidMin == nil then self.tItems["settings"].BidMin = 0 end
	if self.tItems["settings"].BidCount == nil then self.tItems["settings"].BidCount = 5 end
	if self.tItems["settings"].BidOver == nil then self.tItems["settings"].BidOver = 10 end

	self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("FinalCount"):SetText(self.tItems["settings"].BidCount)
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("MinBid"):SetText(self.tItems["settings"].BidMin)
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("MinOverBid"):SetText(self.tItems["settings"].BidOver)

	if self.tItems["settings"].BidAllowOffspec == nil then self.tItems["settings"].BidAllowOffspec = 1 end
	if self.tItems["settings"].BidAllowOffspec == 1 then self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("AllowOffspec"):SetCheck(true) end

	if self.tItems["settings"].BidSpendOneMore == nil then self.tItems["settings"].BidSpendOneMore = 0 end
	if self.tItems["settings"].BidSpendOneMore == 1 then self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("OneMore"):SetCheck(true) end

	if self.tItems["settings"].BidRollModifier == nil then self.tItems["settings"].BidRollModifier = 5 end
	if self.tItems["settings"].BidEPGPOffspec == nil then self.tItems["settings"].BidEPGPOffspec = 5 end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("RollModifier"):SetText(self.tItems["settings"].BidRollModifier)
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("PRModifier"):SetText(self.tItems["settings"].BidEPGPOffspec)

	if self.tItems["settings"].strBidChannel == nil then self.tItems["settings"].strBidChannel = "/party " end
	if self.tItems["settings"].strBidChannel == "/party " then
		self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("PartyMode"):SetCheck(true)
	else
		self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("GuildMode"):SetCheck(true)
	end

	if self.tItems["settings"].bShortMsg == nil then self.tItems["settings"].bShortMsg = false end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("ShortMsg"):SetCheck(self.tItems["settings"].bShortMsg)

	if self.tItems["settings"].strBidMode == nil or self.tItems["settings"].strBidMode == "EPGP" then self.tItems["settings"].strBidMode = "ModeEPGP" end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild(self.tItems["settings"].strBidMode):SetCheck(true)

	if self.tItems["settings"].bWhisperRespond == nil then self.tItems["settings"].bWhisperRespond = true end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("WhisperResponse"):SetCheck(self.tItems["settings"].bWhisperRespond)

	if self.tItems["settings"].bAutoSelect == nil then self.tItems["settings"].bAutoSelect = false end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("AutoSelect"):SetCheck(self.tItems["settings"].bAutoSelect)

	if self.tItems["settings"].bAutoStart == nil then self.tItems["settings"].bAutoStart = false end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("AutoStart"):SetCheck(self.tItems["settings"].bAutoStart)

	if not self.tItems["settings"].tBidCategoryModifiers then self.tItems["settings"].tBidCategoryModifiers = ktDefaultBidModifiers end

	for k=1,4 do
		self.wndBid:FindChild("ControlsContainer"):FindChild("Cmd"..k):SetText(self.tItems["settings"].tBidCategoryModifiers[k])
	end
	self.GeminiLocale:TranslateWindow(self.Locale, self.wndBid)
	self:BidDisplayHelp()
	if not self.tItems["settings"].tBidCommands then self.tItems["settings"].tBidCommands = ktDefaultCommands end

	self:BidCheckConditions()
	local wndCmd = self.wndBid:FindChild("Commands")
	for k , tCommand in pairs(self.tItems["settings"].tBidCommands) do
		wndCmd:FindChild(k):SetText(tCommand.strCmd)
		wndCmd:FindChild(k):Enable(tCommand.bEnable)
		wndCmd:FindChild(k.."Enable"):SetCheck(tCommand.bEnable)
	end


	self.bIsBidding = false
	--Post Update To generate Labels for Main DKP window
	if self:LabelGetColumnNumberForValue("Item") ~= - 1 then self:LabelUpdateList() end

	--local test = Item.GetDataFromId(60434)
	---self:ExportShowPreloadedText(tohtml(test:GetDetailedInfo()))
	Apollo.RegisterEventHandler("ChatMessage","BidMessage",self)
	--self.tItems["settings"].strBidChannel = "/s "
	--Hook.wndMasterLoot:Show(false,false)
	if GameLib.GetPlayerUnit() then
		self.strMyName = GameLib.GetPlayerUnit():GetName()
	else
		self:delay(3, function(tContext) if GameLib.GetPlayerUnit() then tContext.strMyName = GameLib.GetPlayerUnit():GetName() end end ) -- I'm hoping that this delay will be sufficient
	end
	-- random winners
	self.tRandomWinners = {}

	-- GP on the tooltips
	if self.tItems["EPGP"].Tooltips == 1 then
		self.wndSettings:FindChild("ButtonShowGP"):SetCheck(true)
		self:EPGPHookToETooltip()
	end

	self:BQInit()

	--Hook.wndMasterLoot:Show(true,false)
	Hook:OnMasterLootUpdate(true)
	--RaidOps LootHex
  	Apollo.RegisterEventHandler("RaidOpsChatBidding","StartChatBiddingFromOtherSource", self)
  	Apollo.RegisterEventHandler("RaidOpsNetworkBidding","StartNetworkBiddingFromOtherSource", self)
end

function DKP:StartChatBiddingFromOtherSource(tLootEntry)
	self:OnLootedItem(tLootEntry.itemDrop,true)
	self:StartChatBidding(tLootEntry)
end

function DKP:StartNetworkBiddingFromOtherSource(tLootEntry)
	self:OnLootedItem(tLootEntry.itemDrop,true)
	self:BidSetUpWindow(tLootEntry)
end

function DKP:BidAutoSelectEnable()
	self.tItems["settings"].bAutoSelect = true
end

function DKP:BidAutoSelectDisable()
	self.tItems["settings"].bAutoSelect = false
end

function DKP:BidAutoStartEnable()
	self.tItems["settings"].bAutoStart = true
end

function DKP:BidAutoStartDisable()
	self.tItems["settings"].bAutoStart = false
end

function DKP:BidFireContextMenu(wndHandler,wndControl)
	if wndHandler ~= wndControl then return end
	if wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

function DKP:ReArr()
	 if self.tItems["settings"]["ML"].bArrTiles then
		Hook.wndMasterLoot_LooterList:ArrangeChildrenTiles()
	end

	if self.tItems["settings"]["ML"].bArrItemTiles then
		Hook.wndMasterLoot_ItemList:ArrangeChildrenTiles()
	end
end

function DKP:BidSelectedChannelChanged( wndHandler, wndControl, eMouseButton )
	if wndControl:GetText() == "   Party" then self.tItems["settings"].strBidChannel = "/party " end
	if wndControl:GetText() == "   Guild" then self.tItems["settings"].strBidChannel = "/guild " end
end

function DKP:BidMLSortByNameEnable()
	self.tItems["settings"]["ML"].bSortByName = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:BidMLSortByNameDisable()
	self.tItems["settings"]["ML"].bSortByName = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:BidWhsiperRespEnable()
	self.tItems["settings"].bWhisperRespond = true
end

function DKP:BidWhsiperRespDisable()
	self.tItems["settings"].bWhisperRespond = false
end

function DKP:BidShortMsgEnable()
	self.tItems["settings"].bShortMsg = true
end

function DKP:BidShortMsgDisable()
	self.tItems["settings"].bShortMsg = false
end


function DKP:BidCheckConditions()
	if self.bIsBidding then
		self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStart"):Enable(false)
		self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStop"):Enable(true)
		self.wndBid:FindChild("NextFromQueue"):Enable(false)
	else
		if self.BQ and #self.BQ > 0 then self.wndBid:FindChild("NextFromQueue"):Enable(true) else self.wndBid:FindChild("NextFromQueue"):Enable(false) end
		local bCommandEnabled = false
		for k,tCommand in pairs(self.tItems["settings"].tBidCommands) do
			if tCommand.bEnable then bCommandEnabled = true break end
		end
		if not bCommandEnabled and self.tItems["settings"].strBidMode == "ModeEPGP" or self.wndBid:FindChild("Header"):FindChild("HeaderItem"):GetText() == "Item:" then
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStart"):Enable(false)
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStop"):Enable(false)
		else
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStart"):Enable(true)
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStop"):Enable(false)
		end
	end
end

function DKP:BidSetSortAsc()
	self.tItems["settings"].BidSortAsc = 1
	Hook:OnMasterLootUpdate(true)
end

function DKP:BidSetSortDesc()
	self.tItems["settings"].BidSortAsc = 0
	Hook:OnMasterLootUpdate(true)
end

local prevLuckyChild
function DKP:BidRandomLooter()
	local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
	if #children > 0 then
		local luckyChild
		for k,child in ipairs(children) do
			if not child:IsEnabled() or child:FindChild("CharacterName"):GetText() == "Guild Bank" then table.remove(children,k) end
		end

		for k,child in pairs(children) do
			child:SetCheck(false)
		end

		luckyChild = children[math.random(#children)]
		prevLuckyChild = luckyChild:FindChild("CharacterName"):GetText()
		Hook.tMasterLootSelectedLooter = luckyChild:GetData()
		Hook.wndMasterLoot:FindChild("Assignment"):Enable(true)
		luckyChild:SetCheck(true)
	end
end

function DKP:MLLAssignItemAtRandom(wndHandler,wndControl)
	local tData =  wndControl:GetParent():GetData()
	if tData and tData.tLooters then
		local luckylooter = self:ChooseRandomLooter(tData)
		if luckylooter then
			self:BidAddPlayerToRandomSkip(luckylooter:GetName(),tData.itemDrop:GetItemId())
			GameLib.AssignMasterLoot(tData.nLootId,luckylooter)
		end
	end
end

function DKP:BidDistributeAllAtRandom()
	for k , item in ipairs(self.tSelectedItems) do
		local luckylooter = self:ChooseRandomLooter(item)
		self:BidAddPlayerToRandomSkip(luckylooter:GetName(),item.itemDrop:GetItemId())
		GameLib.AssignMasterLoot(item.nLootId,luckylooter)
	end
	self.tSelectedItems = {}
	Hook.tMasterLootSelectedItem = nil
	Hook.tMasterLootSelectedLooter = nil
	Hook:OnMasterLootUpdate(true)

end

function DKP:BidAddPlayerToRandomSkip(strName,itemID)
	table.insert(self.tRandomWinners,{strName = strName,item = itemID})
end

function DKP:ChooseRandomLooter(entry)
	local looters = {}
	for k , playerUnit in pairs(entry.tLooters or {}) do
		if type(playerUnit) == "userdata" then
			table.insert(looters,playerUnit)
		end
	end
	return looters[math.random(#looters)]
end

function DKP:BidUpdateItemDatabase()
	local curItemList = GameLib.GetMasterLoot()
	if self.ItemDatabase == nil then self.ItemDatabase = {} end
	if curItemList ~= nil then
		for idxNewItem, tCurNewItem in pairs(curItemList) do
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()] = {}
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()].ID= tCurNewItem.itemDrop:GetItemId()
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()].quality = tCurNewItem.itemDrop:GetItemQuality()
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()].strChat = tCurNewItem.itemDrop:GetChatLinkString()
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()].sprite = tCurNewItem.itemDrop:GetIcon()
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()].strItem = tCurNewItem.itemDrop:GetName()
			self.ItemDatabase[tCurNewItem.itemDrop:GetName()].Power = tCurNewItem.itemDrop:GetItemPower()
			if tCurNewItem.itemDrop:GetSlotName() ~= "" then
				self.ItemDatabase[tCurNewItem.itemDrop:GetName()].slot = tCurNewItem.itemDrop:GetSlotName()
			else
				self.ItemDatabase[tCurNewItem.itemDrop:GetName()].slot = tCurNewItem.itemDrop:GetSlot()
			end
			if tCurNewItem.itemDrop:GetItemCategoryName() == "Armor Token" then
				self.ItemDatabase[tCurNewItem.itemDrop:GetName()].slot = "Armor Token"
			end
		end
	end
end



function DKP:BidMLSortPlayers()
	Hook:OnMasterLootUpdate(true)
end

function DKP:BidLooterItemSelected(wndHandler,wndControl)
	self.SelectedLooterItem = wndControl:FindChild("ItemName"):GetText()
	self.wndInsertedLooterButton:Enable(true)
	if self.PrevSelectedLooterItem == nil then
		wndControl:FindChild("ItemName"):SetTextColor(kcrSelectedText)
		self.PrevSelectedLooterItem = wndControl:FindChild("ItemName")
	elseif self.PrevSelectedLooterItem ~= wndControl then
		self.PrevSelectedLooterItem:SetTextColor(kcrNormalText)
		wndControl:FindChild("ItemName"):SetTextColor(kcrSelectedText)
		self.PrevSelectedLooterItem = wndControl:FindChild("ItemName")
	end

end

function DKP:BidMasterItemSelected()
	local HookML = Apollo.GetAddon("MasterLootDependency")
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if HookML.tMasterLootSelectedItem and HookML.tMasterLootSelectedItem.itemDrop then
		DKPInstance.SelectedMasterItem = HookML.tMasterLootSelectedItem.itemDrop:GetName()
		if DKPInstance.wndInsertedMasterButton then DKPInstance.wndInsertedMasterButton:Enable(true) end
		if DKPInstance.wndInsertedMasterButton1 then DKPInstance.wndInsertedMasterButton1:Enable(true) end
	end
end

----------------------------
--Chat Bidding
------------------------------


function DKP:StartChatBidding(item)
	local strItem = type(item) == "table" and item.itemDrop:GetName() or self.SelectedMasterItem
	if self.bIsBidding == false then
		if self.ItemDatabase[strItem] ~= nil then
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("HeaderItem"):SetText(strItem)
			self.CurrentItemChatStr = self.ItemDatabase[strItem].strChat
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIcon"):SetSprite(self.ItemDatabase[strItem].sprite)
			local item = Item.GetDataFromId(self.ItemDatabase[strItem].ID)
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIconFrame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIconFrame"):SetData(item)
			Tooltip.GetItemTooltipForm(self, self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIcon") , item , {bPrimary = true, bSelling = false})
			self.bIsBiddingPrep = true
		end
		self.wndBid:SetData(item)
		self.wndBid:Show(true,false)
		self:BidCheckConditions()
		if self.tItems["settings"].bAutoStart then self:BidStart() end
		self.wndBid:FindChild("MainFrame"):FindChild("Frame"):FindChild("List"):DestroyChildren()
	else
		self.wndBid:Show(true,false)
	end
end

function DKP:BidSetUpWindow(tCustomData,wndControl,eMouseButton)
	local strItem
	if type(tCustomData) == "table" then strItem = tCustomData.itemDrop:GetName() else strItem = self.SelectedMasterItem end
	if self.ItemDatabase[strItem] then
		self:BidAddNewAuction(type(tCustomData) == "table" and tCustomData or self.ItemDatabase[strItem].ID,true)
	end
end

function DKP:BidStartCustom( wndHandler, wndControl, eMouseButton )
	self:StartChatBidding({strItem = self.wndMain:FindChild("CustomAuction"):GetText()})
end

function DKP:BidLinkItem()
	if self.CurrentItemChatStr ~= nil then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. self.CurrentItemChatStr)
	end
end

function DKP:BidEnableOffspec()
	self.tItems["settings"].BidAllowOffspec = 1
end

function DKP:BidDisableOffspec()
	self.tItems["settings"].BidAllowOffspec = 0
end


function DKP:BidSetMin( wndHandler, wndControl, strText )
	local val = tonumber(strText)
	if val then
		self.tItems["settings"].BidMin = val
	else
		wndControl:SetText(self.tItems["settings"].BidMin)
	end
end

function DKP:BitSetCountdown( wndHandler, wndControl, strText )
	local val = tonumber(strText)
	if val and val < 10 and val >= 0 then
		self.tItems["settings"].BidCount = val
	else
		wndControl:SetText(self.tItems["settings"].BidCount)
	end
end

function DKP:BidSetMode(wndHandler,wndControl)
	if self.bIsBidding then
		self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild(self.tItems["settings"].strBidMode):SetCheck(true)
		wndControl:SetCheck(false)
	else
		self.tItems["settings"].strBidMode = wndControl:GetName()
	end
	self:BidDisplayHelp()
end

function DKP:BidDisplayHelp()
	self.wndBid:FindChild("Commands"):Show(false)
	self.wndBid:FindChild("Roll"):Show(false)
	if self.tItems["settings"].strBidMode == "ModeEPGP" then self.wndBid:FindChild("Commands"):Show(true)
	elseif self.tItems["settings"].strBidMode == "ModePureRoll" or self.tItems["settings"].strBidMode == "ModeModifiedRoll" then self.wndBid:FindChild("Roll"):Show(true)
	end
end

function DKP:BidStart(strName)
	self.bIsBidding = true
	self.bIsBiddingPrep = false
	self.CurrentBidSession = nil
	self.CurrentBidSession = {}
	self.CurrentBidSession.Bidders = {}
	self.CurrentBidSession.strItem = self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("HeaderItem"):GetText()
	self:BidCheckConditions()
	self:BidUpdateBiddersList()
	self:BidEnableAssign()
	self.wndBid:FindChild("ButtonStart"):Enable(false)
	self.wndBid:FindChild("ButtonStop"):Enable(true)
	if self.tItems["settings"].strBidMode == "ModeOpenDKP" then
		if not self.tItems["settings"].bShortMsg then
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:DKPOpen"],self.CurrentItemChatStr,self.tItems["settings"].strBidChannel,tostring(self.tItems["settings"].BidMin)))
		else
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:short:DKPOpen"],self.CurrentItemChatStr,self.tItems["settings"].strBidChannel))
		end
	elseif self.tItems["settings"].strBidMode == "ModeHiddenDKP" then
		if not self.tItems["settings"].bShortMsg then
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel ..  string.format(self.Locale["#biddingStrings:DKPHidden"],self.CurrentItemChatStr,GameLib.GetPlayerUnit():GetName(),tostring(self.tItems["settings"].BidMin)))
		else
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel ..  string.format(self.Locale["#biddingStrings:short:DKPHidden"],self.CurrentItemChatStr,GameLib.GetPlayerUnit():GetName()))
		end
	elseif self.tItems["settings"].strBidMode == "ModePureRoll" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:roll"],self.CurrentItemChatStr))
	elseif self.tItems["settings"].strBidMode == "ModeModifiedRoll" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:modifiedRoll"],self.CurrentItemChatStr,tostring(self.tItems["settings"].BidRollModifier)))
	elseif self.tItems["settings"].strBidMode == "ModeEPGP" then
		local strCmds = ""
		for k=1 ,4 do
			local tCommand = self.tItems["settings"].tBidCommands["Cmd"..k]
			if tCommand.bEnable then strCmds = strCmds .. "!" .. tCommand.strCmd .. " or " end
		end
		strCmds = string.sub(strCmds,0,-5)
		if not self.tItems["settings"].bShortMsg then
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:EPGP"],self.CurrentItemChatStr,strCmds,self.tItems["settings"].strBidChannel))
		else
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel.. string.format(self.Locale["#biddingStrings:short:EPGP"],self.CurrentItemChatStr,strCmds))
		end
	end
end

function DKP:BidSetOffspecModifierForEPGP( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		value = tonumber(strText)
		if value >= 0 and value <=100 then
			self.tItems["settings"].BidEPGPOffspec = value
		else
			wndControl:SetText(self.tItems["settings"].BidEPGPOffspec)
		end
	else
		wndControl:SetText("")
	end
end

function DKP:BidMessage(channelCurrent, tMessage)
	if not self.bIsBidding then return end
	local strResult = -1
	local arg = {strMsg = tMessage.arMessageSegments[1].strText,strSender = tMessage.strSender}
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Party and self.tItems["settings"].strBidMode == "ModeOpenDKP" and self.tItems["settings"].strBidChannel == "/party " or  channelCurrent:GetType() == ChatSystemLib.ChatChannel_Guild and self.tItems["settings"].strBidMode == "ModeOpenDKP" and self.tItems["settings"].strBidChannel == "/guild " then
		strResult = self:BidProcessMessageDKP(arg)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper and  self.tItems["settings"].strBidMode == "ModeHiddenDKP"  then
		 strResult = self:BidProcessMessageDKP(arg)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_System and self.tItems["settings"].strBidMode == "ModePureRoll" then
		 strResult = self:BidProcessMessageRoll(arg)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_System and self.tItems["settings"].strBidMode == "ModeModifiedRoll" then
		 strResult = self:BidProcessMessageRoll(arg)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_Party and self.tItems["settings"].strBidMode == "ModeEPGP" and self.tItems["settings"].strBidChannel == "/party " or channelCurrent:GetType() == ChatSystemLib.ChatChannel_Guild and self.tItems["settings"].strBidMode == "ModeEPGP" and self.tItems["settings"].strBidChannel == "/guild " then
		strResult = self:BidProcessMessageEPGP(arg)
	end
	if strResult == -1 then return end
	if not self.tItems["settings"].bWhisperRespond then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. strResult)
	else
		ChatSystemLib.Command("/w " ..  tMessage.strSender .." " .. strResult)
	end
end

function DKP:BidProcessMessageEPGP(tData)
	local strReturn = -1
	local nOpt
	local ID = self:GetPlayerByIDByName(tData.strSender)
	if ID == -1 then return -1 end

	for k,tCommand in pairs(self.tItems["settings"].tBidCommands) do
		if tCommand.bEnable and "!"..tCommand.strCmd == tData.strMsg then
			nOpt = tonumber(string.sub(k,4))
			break
		end
	end

	if nOpt then
		local nBidderID
		for k , bidder in ipairs(self.CurrentBidSession.Bidders) do
			if tData.strSender == bidder.strName then
				nBidderID = k
				break
			end
		end

		if nBidderID then
			if self.CurrentBidSession.Bidders[nBidderID].nOpt ~= nOpt then
				self.CurrentBidSession.Bidders[nBidderID] = {strName = tData.strSender , nBid = self:EPGPGetPRByName(tData.strSender) , nOpt = nOpt }
				strReturn = string.format("Group changed (%.0f)",nOpt)
			else
				if self.CurrentBidSession.strSelected == self.CurrentBidSession.Bidders[nBidderID].strName then self.CurrentBidSession.strSelected = nil end
				table.remove(self.CurrentBidSession.Bidders,nBidderID)
				strReturn = "Removed bid"
			end
		else -- new
			table.insert(self.CurrentBidSession.Bidders,{strName = tData.strSender , nBid = self:EPGPGetPRByName(tData.strSender) , nOpt = nOpt })
			strReturn = string.format("Bid processed (group : %.0f)",nOpt)
		end

	end

	self:BidUpdateBiddersList()
	self:BidEnableAssign()
	return strReturn
end

function DKP:BidEnableAssign()
	if self.CurrentBidSession.strSelected and self.bIsBidding then
		self.wndBid:FindChild("Header"):FindChild("Assign"):Enable(true)
		self.wndBid:FindChild("Header"):FindChild("Select"):Enable(true)
	else
		self.wndBid:FindChild("Header"):FindChild("Assign"):Enable(true)
		self.wndBid:FindChild("Header"):FindChild("Select"):Enable(true)
	end
end

function DKP:BidProcessMessageRoll(tData)
	local strReturn = -1
	if not string.find(tData.strMsg,"rolls") and not string.find(tData.strMsg,"würfelt") then return -1 end
	local words = {}
	for word in string.gmatch(tData.strMsg,"%S+") do
		table.insert(words,word)
	end
	local strRoller = words[1] .. " " .. words[2]
	if #words < 5 then
		return strReturn
	end
	if words[5] ~= "(1-100)" then
		strReturn = strRoller.. " Wrong range"
		return strReturn
	end


		local ID = self:GetPlayerByIDByName(strRoller)
		if ID == -1 then return -1 end
		for k,bidder in ipairs(self.CurrentBidSession.Bidders) do
			if bidder.strName == strRoller then
				strReturn = strRoller.." Already Rolled"
				return strReturn
			end
		end

		local roll = tonumber(words[4])
		local newBidder = {}
		newBidder.nOpt = 3
		newBidder.strName = strRoller
		if self.tItems["settings"].strBidMode == "ModePureRoll" then
			newBidder.nBid = roll
		elseif self.tItems["settings"].strBidMode == "ModeModifiedRoll" then
			newBidder.nBid = roll + math.floor(math.abs(self.tItems[ID].EP) * (self.tItems["settings"].BidRollModifier/100))
			newBidder.mod = math.floor(math.abs(self.tItems[ID].EP) * (self.tItems["settings"].BidRollModifier/100))
			newBidder.nOpt = 3
		end
		newBidder.offspec = false

		table.insert(self.CurrentBidSession.Bidders,newBidder)
		strReturn = strRoller.." Processed"
	self:BidUpdateBiddersList()
	return strReturn
end


function DKP:BidSetRollModifier( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil and tonumber(strText) >=1 and tonumber(strText) <= 100 then
		self.tItems["settings"].BidRollModifier = tonumber(strText)
	else
		wndControl:SetText(self.tItems["settings"].BidRollModifier)
	end
end


function DKP:BidProcessMessageDKP(tData) -- strMsg , strSender
	local strReturn = -1
	local nBidderID
	local ID = self:GetPlayerByIDByName(tData.strSender)
	if ID == -1 then return -1 end
	for k , bidder in ipairs(self.CurrentBidSession.Bidders) do
		if tData.strSender == bidder.strName then
			nBidderID = k
			break
		end
	end
	if tonumber(tData.strMsg) and tonumber(tData.strMsg) > self.tItems["settings"].BidMin and tonumber(tData.strMsg) <= self.tItems[ID].net then
		if nBidderID and tonumber(tData.strMsg) > self.CurrentBidSession.Bidders[nBidderID].nBid then
			self.CurrentBidSession.Bidders[nBidderID].nBid = tonumber(tData.strMsg)
			strReturn = "Bid updated"
		else -- new
			table.insert(self.CurrentBidSession.Bidders,{strName = tData.strSender , nBid = tonumber(tData.strMsg) , nOpt = 3 })
			strReturn = "Bid processed"
		end
	elseif tData.strMsg == "!off" and nBidderID then
		self.CurrentBidSession.Bidders[nBidderID].nOpt = 4
		strReturn = "Offspec flag added"
	end

	self:BidUpdateBiddersList()
	self:BidEnableAssign()
	return strReturn
end

function DKP:BidExpandModes()
	local l,t,r,b = self.wndBid:GetAnchorOffsets()
	self.wndBid:SetAnchorOffsets(l,t,r+616,b)
end

function DKP:BidCollapseModes()
	local l,t,r,b = self.wndBid:GetAnchorOffsets()
	self.wndBid:SetAnchorOffsets(l,t,r-616,b)
end

function compare_easyDKP_bidders(a,b)
	return tonumber(a.nBid) > tonumber(b.nBid)
end

function DKP:BidUpdateBiddersList()
	local list = self.wndBid:FindChild("MainFrame"):FindChild("Frame"):FindChild("List")
	list:DestroyChildren()

	local tOpts = {}
	for k , tBidder in ipairs(self.CurrentBidSession.Bidders) do
		if not tOpts["Opt"..tBidder.nOpt] then tOpts["Opt"..tBidder.nOpt] = {} end
		table.insert(tOpts["Opt"..tBidder.nOpt],tBidder)
	end

	local tabs = {}
	table.insert(tabs,tOpts["Opt1"])
	table.insert(tabs,tOpts["Opt2"])
	table.insert(tabs,tOpts["Opt3"])
	table.insert(tabs,tOpts["Opt4"])

	for k , tOpters in ipairs(tabs) do
		table.sort(tOpters,compare_easyDKP_bidders)
		for k ,tBidder in ipairs(tOpters) do
			local ID = self:GetPlayerByIDByName(tBidder.strName)
			local wnd = Apollo.LoadForm(self.xmlDoc2,"CharacterButtonBidderResponse",list,self)
			wnd:FindChild("CharacterName"):SetText(tBidder.strName)
			wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
			wnd:FindChild("Choice"):SetSprite(ktOptionToIcon["Opt"..tBidder.nOpt])
			if tBidder.nOpt == 2 then wnd:FindChild("Choice"):SetBGColor("AddonWarning") end
			wnd:FindChild("PR"):SetText(tBidder.nBid)
			wnd:SetData(tBidder)
			wnd:RemoveEventHandler("ButtonCheck",self)
			wnd:AddEventHandler("ButtonCheck","BidSelectBidder",self)
			if self.CurrentBidSession.strSelected then
				if self.CurrentBidSession.strSelected == tBidder.strName then wnd:SetCheck(true) end
			end
		end
	end
	list:ArrangeChildrenTiles(100)
end

function DKP:BidInitCountdown()
	self.BidCounter = 0
	if self.tItems["settings"].BidCount > 0 then
		self.BidCountdown = ApolloTimer.Create(1,true,"BidPerformCountdown",self)
		Apollo.RegisterTimerHandler("BidPerformCountdown","BidPerformCountdown",self)
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. " [ChatBidding] " .. self.tItems["settings"].BidCount)
	else
		self:BidPerformCountdown()
	end
end

function DKP:BidSelectWinner(nOpt)
	local strWinner = ""
	if nOpt == 5 then return "" end
	local nBid = 0
	for k,tBidder in ipairs(self.CurrentBidSession.Bidders) do
		if tBidder.nOpt == nOpt then
			if tonumber(tBidder.nBid) > nBid then
				nBid = tonumber(tBidder.nBid)
				strWinner = tBidder.strName
			end
		end
	end
	if strWinner == "" then strWinner = self:BidSelectWinner(nOpt + 1) end
	return strWinner
end

function DKP:BidPerformCountdown()
	if not self.bIsBidding then
		if self.BidCountdown then self.BidCountdown:Stop() end
		Apollo.RemoveEventHandler("BidPerformCountdown",self)
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. " [ChatBidding] " .. "Bidding stopped")
		self.wndBid:FindChild("ButtonStop"):Enable(false)
		self.wndBid:FindChild("ButtonStart"):Enable(true)
		return
	end

	self.BidCounter = self.BidCounter + 1
	if self.BidCounter >= self.tItems["settings"].BidCount then
		if self.BidCountdown then self.BidCountdown:Stop() end
		Apollo.RemoveEventHandler("BidPerformCountdown",self)

		if self.tItems["settings"].bAutoSelect and not self.CurrentBidSession.strSelected then
			local strWinner= self:BidSelectWinner(1)
			if strWinner ~= "" then
				self.CurrentBidSession.strSelected = strWinner
				for k , bidder in ipairs(self.CurrentBidSession.Bidders or {}) do
					if bidder.strName == strWinner then
						self.CurrentBidSession.nSelectedOpt = bidder.nOpt
						break
					end
				end

				for k , wnd in ipairs(self.wndBid:FindChild("List"):GetChildren()) do
					if wnd:GetData().strName == strWinner then wnd:SetCheck(true) break end
				end
			end
		end

		if self.CurrentBidSession.strSelected then
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:AuctionEndWinner"],self.CurrentBidSession.strSelected))
		else
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. self.Locale["#biddingStrings:AuctionEnd"])
		end
		if self.tItems["settings"].bSkipBidders and self.tItems["settings"].strBidMode == "ModeEPGP" then
			table.insert(self.tPopUpExceptions,self.CurrentBidSession.strSelected)
		end
		self.bIsBidding = false
		self:BidCheckConditions()
		self:BQNext()
	else
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. " [ChatBidding] " .. tostring(self.tItems["settings"].BidCount - self.BidCounter) .. "...")
	end
end

function DKP:BidSelectBidder(wndHandler,wndControl)
	self.CurrentBidSession.strSelected  = wndControl:GetData().strName
	self.CurrentBidSession.nSelectedOpt = wndControl:GetData().nOpt
	self:BidEnableAssign()
end

function DKP:BidAssignItem(wndHandler,wndControl)
	local bMaster = true

	if type(self.wndBid:GetData()) == "table" and wndControl:GetName() == "Assign" then -- if item reference was passed
		if self.CurrentBidSession == nil or not self.CurrentBidSession.strSelected or not self.CurrentBidSession.nSelectedOpt then return end
		if self.bIsBidding then
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:AuctionEndEarly"],self.CurrentBidSession.strSelected))
			self.bIsBidding = false
			self:BidCheckConditions()
			if self.tItems["settings"].bSkipBidders and self.tItems["settings"].strBidMode == "ModeEPGP" then
				table.insert(self.tPopUpExceptions,self.CurrentBidSession.strSelected)
			end
		end

		local price = self:EPGPGetItemCostByID(self.wndBid:GetData().itemDrop:GetItemId(),true)
		if price and type(price) ~= "string" then
			price = (self.tItems["settings"].tBidCategoryModifiers[self.CurrentBidSession.nSelectedOpt] * price) / 100
			self.tPopUpItemGPvalues[self.wndBid:GetData().itemDrop:GetName()] = price
		end

		--Event_FireGenericEvent("RaidOpsLootHexAssignThisItem",self.wndBid:GetData().nLootId,self.CurrentBidSession.strSelected)

		for k , playerUnit in pairs(self.wndBid:GetData().tLooters) do
			if string.lower(playerUnit:GetName()) == string.lower(self.CurrentBidSession.strSelected) then
				GameLib.AssignMasterLoot(self.wndBid:GetData().nLootId,playerUnit)
				break
			end
		end

		self.wndBid:SetData(nil)
		return
	end

	if wndControl:GetName() == "AssignRandom" then
		--we need to select winner
		if not self.CurrentBidSession then self.CurrentBidSession = {} end
		local looters = {}

		self.CurrentBidSession.nSelectedOpt = 4
		self.CurrentBidSession.strItem = self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("HeaderItem"):GetText()
		if type(self.wndBid:GetData()) ~= "table" then
			if not Hook.tMasterLootSelectedItem then
				local children = Hook.wndMasterLoot_ItemList:GetChildren()

				for k,child in ipairs(children) do
					if self.CurrentBidSession.strItem == child:GetData().itemDrop:GetName() then
						Hook.tMasterLootSelectedItem = child:GetData()
						break
					end
				end
			end
			if not Hook.tMasterLootSelectedItem then return end
			for k , playerUnit in pairs(Hook.tMasterLootSelectedItem.tLooters or {}) do
				table.insert(looters,playerUnit)
			end
		else
			if not self.wndBid:GetData().tLooters then return end
			for k , playerUnit in pairs(self.wndBid:GetData().tLooters or {}) do
				table.insert(looters,playerUnit)
			end
			Event_FireGenericEvent("RaidOpsLootHexAssignThisItem",self.wndBid:GetData().nLootId,looters[math.random(#looters)]:GetName())
			return
		end

		self.CurrentBidSession.strSelected = looters[math.random(#looters)]:GetName()
		prevLuckyChild = self.CurrentBidSession.strSelected
		-- it flows further to standard assign method
	end

	if self.CurrentBidSession == nil or not self.CurrentBidSession.strSelected or not self.CurrentBidSession.nSelectedOpt then return end
	if bMaster then
		-- Update window
		for k,child in ipairs(Hook.wndMasterLoot_ItemList:GetChildren()) do
			if child:IsChecked() then Hook.tMasterLootSelectedItem = child:GetData() break end
		end
		Hook:OnMasterLootUpdate(true)

		local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
		local selectedOne
		local selectedItem
		if wndControl:GetText() == "Select" then
			for k,child in ipairs(children) do
				child:SetCheck(false)
			end
		end
		for k,child in ipairs(children) do
			if string.lower(child:FindChild("CharacterName"):GetText()) == string.lower(self.CurrentBidSession.strSelected) then
				selectedOne = child
				if wndControl:GetText() == "Select" then child:SetCheck(true) end
				break
			end
		end
		children = Hook.wndMasterLoot_ItemList:GetChildren()
		if not self.ItemDatabase[self.CurrentBidSession.strItem] then return end

		local item = Item.GetDataFromId(self.ItemDatabase[self.CurrentBidSession.strItem].ID)
		if wndControl:GetText() == "Select" then
			for k,child in ipairs(children) do
				child:SetCheck(false)
			end
		end
		for k,child in ipairs(children) do
			if item:GetName() == child:GetData().itemDrop:GetName() then
				selectedItem = child:GetData()
				if wndControl:GetText() == "Select" then child:SetCheck(true) end
				break
			end
		end

		if not selectedItem then
			Print("Item no longer available")
			self.bIsBidding = false
		end

		if not selectedOne or not selectedItem then return end
		if wndControl:GetText() == "Select" then Hook.wndMasterLoot:FindChild("Assignment"):Enable(true) end
		Hook.tMasterLootSelectedLooter = selectedOne:GetData()
		Hook.tMasterLootSelectedItem = selectedItem


		if wndControl:GetName() == "Assign" or wndControl:GetName() == "AssignRandom" then

			if self.bIsBidding then
				ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:AuctionEndEarly"],selectedOne:GetData():GetName()))
				self.bIsBidding = false
				self:BidCheckConditions()
				if self.tItems["settings"].bSkipBidders and self.tItems["settings"].strBidMode == "ModeEPGP" then
					table.insert(self.tPopUpExceptions,self.CurrentBidSession.strSelected)
				end
			end



			local price = self:EPGPGetItemCostByID(selectedItem.itemDrop:GetItemId(),true)
			if price and type(price) ~= "string" then
				price = (self.tItems["settings"].tBidCategoryModifiers[self.CurrentBidSession.nSelectedOpt] * price) / 100
				self.tPopUpItemGPvalues[selectedItem.itemDrop:GetName()] = price
			end
			Hook:OnAssignDown()
		end
	end
	self:BidEnableAssign()
	self.bIsBidding = false
end

function DKP:BidClose()
	self.wndBid:Show(false,false)
end

function DKP:BidOpen()
	if not self.bIsBidding then
		--self:StartChatBidding()
		--self.CurrentItemChatStr  = "{DSD}"
		self.wndBid:FindChild("ButtonStart"):Enable(false)
		self.wndBid:FindChild("ButtonStop"):Enable(false)
	end
	self.wndBid:Show(true,false)

end


function DKP:BidSetMinOver( wndHandler, wndControl, eMouseButton )
	local value = wndControl:GetParent():FindChild("Field"):GetText()
	if tonumber(value) == nil then
		wndControl:GetParent():FindChild("Field"):SetText(self.tItems["settings"].BidOver)
	else
		self.tItems["settings"].BidOver = math.abs(tonumber(value))
	end
	self:BidCheckConditions()
end

function DKP:BidEnableCommand(wndHandler,wndControl)
	self.tItems["settings"].tBidCommands[string.sub(wndControl:GetName(),0,4)].bEnable = true
	self.wndBid:FindChild("Commands"):FindChild(string.sub(wndControl:GetName(),0,4)):Enable(true)
	self:BidCheckConditions()
end

function DKP:BidDisableCommand(wndHandler,wndControl)
	self.tItems["settings"].tBidCommands[string.sub(wndControl:GetName(),0,4)].bEnable = false
	self.wndBid:FindChild("Commands"):FindChild(string.sub(wndControl:GetName(),0,4)):Enable(false)
	self:BidCheckConditions()
end

function DKP:BidSetCommand(wndHandler,wndControl,strText)
	if strText ~= "" then
		self.tItems["settings"].tBidCommands[wndControl:GetName()].strCmd = strText
	else
		self.tItems["settings"].tBidCommands[wndControl:GetName()].strCmd = "---"
		wndControl:SetText("---")
	end
end

function DKP:BidSetCommandModifier(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val >= 0 and val <= 100 then
		self.tItems["settings"].tBidCategoryModifiers[tonumber(string.sub(wndControl:GetName(),4,4))] = val
	else
		wndControl:SetText(self.tItems["settings"].tBidCategoryModifiers[tonumber(string.sub(wndControl:GetName(),4,4))])
	end
end


---------------------------------------------------------------------------------------------------
-- Network Bidding Functions
---------------------------------------------------------------------------------------------------

function DKP:InitBid2()
	self.wndBid2 = Apollo.LoadForm(self.xmlDoc2,"BiddingManagerv2",nil,self)
	self.wndBid2Settings = Apollo.LoadForm(self.xmlDoc2,"BiddingManagerSettings",nil,self)
	self.wndBid2Whitelist = Apollo.LoadForm(self.xmlDoc2,"WhiteList",nil,self)
	self.wndMLResponses = Apollo.LoadForm(self.xmlDoc2,"Responses",nil,self)

	self.wndBid2:Show(false,true)
	self.wndBid2Settings:Show(false,true)
	self.wndBid2Whitelist:Show(false,true)
	self.wndMLResponses:Show(false,true)

	self.wndBid2:SetSizingMinimum(1241,832)

	if self.tItems.wndNBLoc ~= nil and self.tItems.wndNBLoc.nOffsets[1] ~= 0 then
		self.wndBid2:MoveToLocation(WindowLocation.new(self.tItems.wndNBLoc))
		self.tItems.wndNBLoc = nil
	end


	self.wndBid2:FindChild("Auctions"):Lock(true)
	self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):Show(true,false)
	self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):FindChild("Status"):SetText("No Active Auctions")
	self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):FindChild("Button"):Show(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Stop"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Start"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Assign"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("RemoveAuction"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("ShowVotes"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Random"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Controls"):FindChild("Opt1"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Controls"):FindChild("Opt2"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Controls"):FindChild("Opt3"):Enable(false)
	self.wndBid2:FindChild("Auctions"):FindChild("Controls"):FindChild("Opt4"):Enable(false)

	self.tEquippedItems = {}

	if self.tItems["settings"]["Bid2"] == nil then
		self.tItems["settings"]["Bid2"] = {}
		self.tItems["settings"]["Bid2"].strChannel = "InputChannelName"
		self.tItems["settings"]["Bid2"].duration = 20
	end
	if self.tItems["settings"]["Bid2"].assignAction == nil then self.tItems["settings"]["Bid2"].assignAction = "select" end
	if self.tItems["settings"]["Bid2"].bWhitelist == nil then self.tItems["settings"]["Bid2"].bWhitelist = false end
	if self.tItems["settings"]["Bid2"].tWhitelisted == nil then self.tItems["settings"]["Bid2"].tWhitelisted = {} end
	if self.tItems["settings"]["Bid2"].bRegisterPass == nil then self.tItems["settings"]["Bid2"].bRegisterPass = false end
	if self.tItems["settings"]["Bid2"].bCloseOnAssign == nil then self.tItems["settings"]["Bid2"].bCloseOnAssign = false end
	if self.tItems["settings"]["Bid2"].bNotify == nil then self.tItems["settings"]["Bid2"].bNotify = false end

	self.ActiveAuctions = {}
	self:DSInit()
	self:Bid2RestoreSettings()

	if self.tItems["settings"].networking or self.tItems["settings"].DS.enable then
		self:BidJoinChannel()
	end
	self.OtherMLs = {}
	self:Bid2BroadcastMySuperiority()
	self:Bid2GetRandomML() -- start fetching auction chain
	self.MyChoices = self.tItems["MyChoices"]
	self.tItems["MyChoices"] = nil
	if self.MyChoices == nil then self.MyChoices = {} end
	self.MyVotes = self.tItems["MyVotes"]
	self.tItems["MyVotes"] = nil
	if self.MyVotes == nil then self.MyVotes = {} end

	self:BidCustomLabelRestore()
	self:BidCustomLabelsUpdate()

	self.wndMain:FindChild("ButtonNB"):Enable(true)
end

function DKP:Bid2ShowNetworkBidding()
	if not self.wndBid2 then return end
	self.wndBid2:Show(true,false)
	self.wndBid2:ToFront()
end

function DKP:MLSettingShow()
	self.wndMLSettings:Show(true,false)
	self.wndMLSettings:ToFront()
end

function DKP:Bid2FetchAuctions(strML)
	if self.channel then self.channel:SendPrivateMessage({[1] = strML},{"GimmeAuctions"}) end -- requesting auctions from the ML
	timeout = 5
	Apollo.RegisterTimerHandler(1,"AuctionsTimeout",self)
	self.timeoutAuctionsTimer = ApolloTimer.Create(1,true,"AuctionsTimeout",self)
end

function DKP:Bid2RestoreMyChoices(auction)
	 for k,choice in ipairs(self.MyChoices) do
		if auction.wnd:GetData() == choice.item then
			auction.wnd:FindChild("Controls"):FindChild(choice.option):SetCheck(true)
			break
		end
	end
end

function DKP:Bid2RearrBidders()
	for k,auction in ipairs(self.ActiveAuctions) do self:Bid2ArrangeResponses(auction) end
end

-- Networking
function DKP:SetChannelAndRecconect(wndHandler,wndControl,strText)
	if string.len(strText) <= 4 then
		wndControl:SetText(self.tItems["settings"]["Bid2"].strChannel)
		return
	end
	self.tItems["settings"]["Bid2"].strChannel = strText
	if self.wndBid2Settings then self.wndBid2Settings:FindChild("Channel"):FindChild("Value"):SetText(strText) end
	if self.wndMLSettings then self.wndMLSettings:FindChild("ChannelName"):SetText(strText) end
	self.wndDS:FindChild("Channel"):SetText(strText)
	self:BidJoinChannel()
end

local connCounter = 0
function DKP:BidJoinChannel()
	if self.uGuild then
		self.tItems["settings"]["Bid2"].strChannel = "ROPSGuildSpecific"
		self.channel = ICCommLib.JoinChannel(self.tItems["settings"]["Bid2"].strChannel,ICCommLib.CodeEnumICCommChannelType.Guild,self.uGuild)
		self.channel:SetReceivedMessageFunction("OnRaidResponse",self)
	elseif connCounter < 4 then
		connCounter = connCounter + 1
		self:delay(2,function (tContext)
			tContext:ImportFromGuild()
			tContext:BidJoinChannel()
		end)
	end
end

function DKP:Bid2PackAndSend(tData)
	if not tData.type then return end
	local myUnit = GameLib.GetPlayerUnit()
	if not myUnit then return end
	tData.strSender = myUnit:GetName()
	local strData = serpent.dump(tData)
	self.channel:SendMessage("ROPS" .. strData)
end

function DKP:Bid2PackAndSendPrivate(strTarget,tData)
	if not tData.type then return end
	local myUnit = GameLib.GetPlayerUnit()
	if not myUnit then return end
	tData.strSender = myUnit:GetName()
	local strData = serpent.dump(tData)
	self.channel:SendPrivateMessage(strTarget,"ROPS" .. strData)
end

function DKP:OnRaidResponse(channel, strMessage, idMessage)
	if string.sub(strMessage,1,4) ~= "ROPS" then return end
	local tMsg = serpent.load(string.sub(strMessage,5))
	if tMsg.strSender and tMsg.type then
		if tMsg.type == "Confirmation" then
			self:AddResponse(tMsg.strSender)
		elseif tMsg.type == "Choice" then
			self:BidRegisterChoice(tMsg.strSender,tMsg.option,tMsg.item,tMsg.itemCompare)
		elseif tMsg.type == "WantCostValues" then
			self:Bid2PackAndSendPrivate(tMsg.strSender,self:Bid2GetItemCostPackage(strSender))
		elseif tMsg.type == "ArUaML" then
			self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "IamML"})
		elseif tMsg.type == "MyVote" then
			self:Bid2RegisterVote(tMsg.who,tMsg.item,tMsg.strSender)
		elseif tMsg.type == "NewAuction" then
			self:BidAddNewAuction(tMsg.itemID,false,nil,tMsg.duration,true,tMsg.tLabels,tMsg.tLabelsState)
		elseif tMsg.type == "GimmeAuctions" then
			for k,auction in ipairs(self.ActiveAuctions) do
				if auction.bActive then
					self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "ActiveAuction" ,item = auction.wnd:GetData(),progress = auction.nTimeLeft,biddersCount = #auction.bidders,votersCount = #auction.votes,duration = self.tItems["settings"]["Bid2"].duration})
				end
			end
		elseif tMsg.type == "ActiveAuction" then
			self:Bid2RestoreFetchedAuctionFromID(tMsg.item,tMsg.progress,tMsg.biddersCount,tMsg.votersCount) -- we got an auction info
		elseif tMsg.type == "IamML" then -- searching for one at random and stockpile them in table
			if self.searchingML then -- waiting for one , else close -> restore from saved ones
				self.LastML = tMsg.strSender
				self:Bid2CloseTimeout()
				self.searchingML = false
			end
			self.OtherMLs[tMsg.strSender] = 1
			self:Bid2UpdateMLTooltip()
		elseif tMsg.type == "GimmeVotes" then
			for k,vote in ipairs(self.MyVotes) do
				if vote.item == tMsg.item then
					self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "MyVote",who = vote.who,item = vote.item})
					break
				end
			end
		elseif tMsg.type == "AuctionPaused" then
			self:Bid2OnAuctionPasused(tMsg.item)
		elseif tMsg.type == "AuctionResumed" then
			self:Bid2OnAuctionResumed(tMsg.item)
		elseif tMsg.type == "AuctionTimeUpdate" then
			for k,auction in ipairs(self.ActiveAuctions) do
				if auction.wnd:GetData() == tMsg.item then
					auction.bActive = false
					auction.nTimeLeft = tMsg.progress
					self:BidUpdateTabProgress(nil,auction.wnd)
					break
				end
			end
		elseif tMsg.type == "MyEquippedItem" then
			local item = Item.GetDataFromId(tMsg.item)
			self.tEquippedItems[tMsg.strSender] = {}
			self.tEquippedItems[tMsg.strSender][item:GetSlot()] = tMsg.item
			self:UpdatePlayerTileBar(tMsg.strSender,item)
		elseif tMsg.type =="SendMeThemStandings" then
			self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "EncodedStandings" , strData = self:DSGetEncodedStandings(tMsg.strSender)})
		elseif tMsg.type =="SendMeThemLogs" then
			self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "EncodedLogs" , strData = self:DSGetEncodedLogs(tMsg.strSender)})
		elseif tMsg.type == "WantConfirmation" then
			self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "Confirmation"})
		end
	end
end

function DKP:UpdatePlayerTileBar(strPlayer,item)
	if item == nil then return end
	local children = Hook.wndMasterLoot_LooterList:GetChildren()
	for k,child in ipairs(children) do
		if child:FindChild("CharacterName"):GetText() == strPlayer then
			if self.tItems["settings"]["ML"].bArrTiles and self.tItems["settings"]["ML"].bShowCurrItemTile then
				child:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
				child:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
				child:FindChild("ItemFrame"):Show(true)
				Tooltip.GetItemTooltipForm(self,child:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
			elseif not self.tItems["settings"]["ML"].bArrTiles then
				child:FindChild("CurrItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
				child:FindChild("CurrItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
				child:FindChild("CurrItemFrame"):Show(true)
				Tooltip.GetItemTooltipForm(self,child:FindChild("CurrItemFrame"),item, {bPrimary = true, bSelling = false})
			end
			break
		end
	end
end


function DKP:Bid2OnAuctionResumed(itemID)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			auction.bActive = true
			break
		end
	end
end

function DKP:Bid2OnAuctionPasused(itemID)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			auction.bActive = false
			break
		end
	end
end


function DKP:Bid2UpdateMLTooltip()
	for k,auction in ipairs(self.ActiveAuctions) do
		auction.wnd:FindChild("FoundAssistants"):SetTooltip("All clients declaring themselves as assistants:\n")
		for k,l in pairs(self.OtherMLs) do
			auction.wnd:FindChild("FoundAssistants"):SetTooltip(k.."\n")
		end
	end
end

function DKP:Bid2StartAuctionFetchTimeout()
	Apollo.RegisterTimerHandler(1,"AuctionsTimeout",self)
	self.timeoutAuctionsTimer = ApolloTimer.Create(1,true,"AuctionsTimeout",self)
end

function DKP:Bid2CloseTimeout()
	self.timeoutAuctionsTimer:Stop()
	Apollo.RemoveEventHandler("AuctionsTimeout",self)
end

function DKP:AuctionsTimeout()
	timeout = timeout - 1
	if timeout == 0 then
		self:AuctionFetchTimedOut()
	end
end

function DKP:AuctionFetchTimedOut()
	self.timeoutAuctionsTimer:Stop()
	Apollo.RemoveEventHandler("AuctionsTimeout",self)
	self.searchingML = false
	self.waitingForAuctions = false
	--Print("[Network Bidding] - Auction fetch timeout")
	--if self.tItems["Auctions"] and # self.tItems["Auctions"]>0 then Print("[Netorking Bidding] - Restoring from saved data") else Print("[Network Bidding] - Nothing to restore") end
	if self.tItems["Auctions"] then
		for k,auction in ipairs(self.tItems["Auctions"]) do
			self:BidAddNewAuction(auction.itemID,auction.bMaster,auction.progress)
			self.ActiveAuctions[#self.ActiveAuctions].bidders = auction.bidders
			self.ActiveAuctions[#self.ActiveAuctions].votes = auction.votes
			self:Bid2ArrangeResponses(self.ActiveAuctions[#self.ActiveAuctions])
			self:Bid2SendUpdateInfo(self.ActiveAuctions[#self.ActiveAuctions])
		end
	end
end

function DKP:Bid2SendUpdateInfo(auction)
	if self.channel then
		self:Bid2PackAndSend({type = "SendMeThemChoices",item = auction.wnd:GetData()})
		self:Bid2PackAndSend({type = "AuctionTimeUpdate",item = auction.wnd:GetData(),progress = auction.nTimeLeft})
	end
end


function DKP:Bid2RestoreFetchedAuctionFromID(itemID,progress,biddersCount,votersCount)
	if self.timeoutAuctionsTimer then self.timeoutAuctionsTimer:Stop() end
	Apollo.RemoveEventHandler("AuctionsTimeout",self)
	for k,auction in ipairs(self.tItems["Auctions"]) do -- going through saved ones
		if auction.itemID == itemID then -- checking whether it's the one
			if #auction.bidders == biddersCount and #auction.votes == votersCount then -- verification
				self:BidAddNewAuction(auction.itemID,auction.bMaster,auction.progress,self.tItems["settings"]["Bid2"].bRegisterPass) -- nothing happened just add
			else -- different
				self:Bid2RestoreAuctionFromNewInfo(auction.itemID,auction.progress,k) -- something happened we have to investigate
			end
		end
	end
end

function DKP:Bid2RestoreAuctionFromNewInfo(itemID,progress,index) -- aka there are bidders who made choices while server was offline
	local newTargets = self:Bid2GetNewTargetsTable(self.tItems["Auctions"][index].bidders)
	local newVoters = self:Bid2GetNewTargetsTableVotes(self.tItems["Auctions"][index].voters)
	if self.channel then
		self:Bid2PackAndSend({type = "SendMeThemChoices", item = itemID}) -- request for sending choice info once more
		self:Bid2PackAndSend({type = "GimmeVotes",item = itemID})
	end


	self:BidAddNewAuction(itemID,nil,progress,self.tItems["settings"]["Bid2"].bRegisterPass)
	self.ActiveAuctions[#self.ActiveAuctions].nTimeLeft = progress
	self.ActiveAuctions[#self.ActiveAuctions].nRemainingPlayers = #newTargets
	self.ActiveAuctions[#self.ActiveAuctions].wnd:FindChild("LoadingOverlay"):Show(true,false)
	self.ActiveAuctions[#self.ActiveAuctions].wnd:FindChild("LoadingOverlay"):FindChild("Status"):SetText("Fetching Data - waiting for: "..#newTargets.. " Players.")
	if #self.ActiveAuctions == 1 then
		self:Bid2AuctionTimerStart()
	end
end

function DKP:Bid2GetNewTargetsTable(tOldTarets) -- gives every person who isn;t in tOldTarets (bidders)
	local arr = self:Bid2GetTargetsTable()
	for k,player in ipairs(arr) do
		for l,oldPlayer in ipairs(tOldTarets) do
			if player == oldPlayer.strName then
				table.remove(arr,k)
				break
			end
		end
	end
	return arr
end

function DKP:Bid2GetNewTargetsTableVotes(tOldTarets) -- gives every ML who isn;t in tOldTarets (voters)
	local arr = {}
	for k,player in pairs(self.OtherMLs) do
		local found = false
		for l,oldPlayer in ipairs(tOldTarets) do
			if k == oldPlayer.assistant then
				found = true
				break
			end
		end
		if not found then table.insert(arr,k) end
	end
	return arr
end

function DKP:Bid2LoadingOverlayForceClose(wndHandler,wndControl)
	wndControl:GetParent():Show(false,false)
end

function DKP:Bid2GetRandomML()
	if self.channel then
		self.searchingML = true
		self:Bid2StartAuctionFetchTimeout()
		self:Bid2PackAndSend({type = "ArUaML"}) -- expecting to get (1) response
	end
end

function DKP:BidRegisterChoice(strSender,option,item,currItem)
	local ID = self:GetPlayerByIDByName(strSender)
	if ID == -1 then return end
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == item then
			local found = false
			local ofID
			for k,bidder in ipairs(auction.bidders) do
				if bidder.strName == strSender then
					found = true
					ofID = k
				end
			end
			if not found then
				table.insert(auction.bidders,{strName = strSender, option = option, currItem = currItem,pr = self:EPGPGetPRByName(strSender) , votes = 0})
				if auction.nRemainingPlayers and auction.nRemainingPlayers > 0 then
					auction.nRemainingPlayers = auction.nRemainingPlayers - 1
					wnd:FindChild("LoadingOverlay"):FindChild("Status"):SetText("Fetching Data waiting for: "..auction.nRemainingPlayers.. " Players.")
					if auction.nRemainingPlayers == 0 then auction.wnd:FindChild("LoadingOverlay"):Show(false,false) end
				end
			else -- found
				auction.bidders[ofID].option = option
			end
			self:Bid2ArrangeResponses(auction)
			break
		end
	end
end

function easyDKpsortBid2Bidders(a,b)
	return a.pr < b.pr
end

function easyDKpsortBid2BiddersLootCouncil(a,b)
	return a.votes < b.votes
end

function DKP:Bid2ArrangeResponses(auction)
	local needs = {}
	local greeds = {}
	local passes = {}
	local slights = {}

	for k,bidder in ipairs(auction.bidders) do
		if bidder.option == "Opt1" then
			table.insert(needs,bidder)
		elseif bidder.option == "Opt2" then
			table.insert(slights,bidder)
		elseif bidder.option == "Opt3" then
			table.insert(greeds,bidder)
		elseif bidder.option == "Opt4" then
			table.insert(passes,bidder)
		end
	end

	table.sort(needs,easyDKpsortBid2Bidders)
	table.sort(passes,easyDKpsortBid2Bidders)
	table.sort(slights,easyDKpsortBid2Bidders)
	table.sort(greeds,easyDKpsortBid2Bidders)
	auction.wnd:FindChild("ResponsesFrame"):FindChild("Responses"):DestroyChildren()
	for k,bidder in ipairs(needs) do
		local ID = self:GetPlayerByIDByName(bidder.strName)
		local wnd = Apollo.LoadForm(self.xmlDoc2,"CharacterButtonBidderResponse",auction.wnd:FindChild("Responses"),self)
		wnd:FindChild("CharacterName"):SetText(bidder.strName)
		wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
		wnd:FindChild("Choice"):SetSprite(ktOptionToIcon[bidder.option])
		wnd:FindChild("PR"):SetText(bidder.pr)
		wnd:SetData(bidder)
		if self.Bid2SelectedPlayerName then
			if self.Bid2SelectedPlayerName == bidder.strName then wnd:SetCheck(true) end
		end
		if bidder.votes > 0 then wnd:FindChild("Choice"):FindChild("Votes"):SetText(bidder.votes) end
	end

	for k,bidder in ipairs(slights) do
		local ID = self:GetPlayerByIDByName(bidder.strName)
		local wnd = Apollo.LoadForm(self.xmlDoc2,"CharacterButtonBidderResponse",auction.wnd:FindChild("Responses"),self)
		wnd:FindChild("CharacterName"):SetText(bidder.strName)
		wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
		wnd:FindChild("Choice"):SetSprite(ktOptionToIcon[bidder.option])
		wnd:FindChild("Choice"):SetBGColor("AddonWarning")
		wnd:FindChild("PR"):SetText(bidder.pr)
		wnd:SetData(bidder)
		if self.Bid2SelectedPlayerName then
			if self.Bid2SelectedPlayerName == bidder.strName then wnd:SetCheck(true) end
		end
		if bidder.votes > 0 then wnd:FindChild("Choice"):FindChild("Votes"):SetText(bidder.votes) end
	end

	for k,bidder in ipairs(greeds) do
		local ID = self:GetPlayerByIDByName(bidder.strName)
		local wnd = Apollo.LoadForm(self.xmlDoc2,"CharacterButtonBidderResponse",auction.wnd:FindChild("Responses"),self)
		wnd:FindChild("CharacterName"):SetText(bidder.strName)
		wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
		wnd:FindChild("Choice"):SetSprite(ktOptionToIcon[bidder.option])
		wnd:SetData(bidder)
		wnd:FindChild("PR"):SetText(bidder.pr)
		if self.Bid2SelectedPlayerName then
			if self.Bid2SelectedPlayerName == bidder.strName then wnd:SetCheck(true) end
		end
		if bidder.votes > 0 then wnd:FindChild("Choice"):FindChild("Votes"):SetText(bidder.votes) end
	end

	for k,bidder in ipairs(passes) do
		local ID = self:GetPlayerByIDByName(bidder.strName)
		local wnd = Apollo.LoadForm(self.xmlDoc2,"CharacterButtonBidderResponse",auction.wnd:FindChild("Responses"),self)
		wnd:FindChild("CharacterName"):SetText(bidder.strName)
		wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
		wnd:FindChild("Choice"):SetSprite(ktOptionToIcon[bidder.option])
		wnd:SetData(bidder)
		wnd:FindChild("PR"):SetText(bidder.pr)
		if self.Bid2SelectedPlayerName then
			if self.Bid2SelectedPlayerName == bidder.strName then wnd:SetCheck(true) end
		end
		if bidder.votes > 0 then wnd:FindChild("Choice"):FindChild("Votes"):SetText(bidder.votes) end
	end
	auction.wnd:FindChild("Responses"):ArrangeChildrenTiles()
end

function DKP:Bid2SendAuctionStartMessage(itemID)
	if self.channel then
		local msg = {}
		msg.type = "NewAuction"
		msg.itemID = itemID
		msg.cost = self:EPGPGetItemCostByID(itemID,true)
		msg.duration = self.tItems["settings"]["Bid2"].duration
		msg.pass = self.tItems["settings"]["Bid2"].bRegisterPass
		msg.tLabels = self.tItems["settings"]["Bid2"].tLabels
		msg.tLabelsState = self.tItems["settings"]["Bid2"].tLabelsState
		msg.ver = knMemberModuleVersion
		self:Bid2PackAndSend(msg)
		if self.tItems["settings"]["Bid2"].bNotify then ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. "  [Network Bidding] - Auction started for " .. Item.GetDataFromId(itemID):GetChatLinkString() .."!") end
	end
end

function DKP:Bid2SendStopMessage(itemID)
	if self.channel then
		local msg = {}
		msg.type = "AuctionPaused"
		msg.item = itemID
		self:Bid2PackAndSend(msg)
	end
end

function DKP:Bid2SendResumeMessage(itemID)
	if self.channel then
		local msg = {}
		msg.type = "AuctionResumed"
		msg.item = itemID
		self:Bid2PackAndSend(msg)
	end
end

function DKP:Bid2GetTargetsTable()
	if not self.strMyName then
		if GameLib.GetPlayerUnit() then
			self.strMyName = GameLib.GetPlayerUnit():GetName()
		end
		return {}
	end
	local targets = {}
	for k=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(k)
		if member.strCharacterName ~= self.strMyName then
			table.insert(targets,member.strCharacterName)
		end
	end
	return targets
end

--  Wnd Logic

function DKP:Bid2EnableLootCouncilMode(wndHandler,wndControl)
	self.tItems["settings"].bLootCouncil = true
end

function DKP:Bid2DisableLootCouncilMode(wndHandler,wndControl)
	self.tItems["settings"].bLootCouncil = false
end

function DKP:Bid2RemoveAuction(wndHandler,wndControl)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			table.remove(self.ActiveAuctions,k)
			auction.wnd:Detach()
			auction.wnd:Destroy()
			for l,choice in ipairs(self.MyChoices) do
				if choice.item == auction.wnd:GetData() then
					table.remove(self.MyChoices,l)
					break
				end
			end
			for l,vote in ipairs(self.MyVotes) do
				if vote.item == auction.wnd:GetData() then
					table.remove(self.MyVotes,l)
					break
				end
			end
			break
		end
	end
	if self.wndBid2:FindChild("Auctions") == nil and #self.ActiveAuctions == 0 then
		local wnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2:FindChild("Frame"),self)
		wnd:SetName("Auctions")
		self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):Show(true,false)
		self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):FindChild("Status"):SetText("No Active Auctions")
		self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):FindChild("Button"):Show(false)
		self.wndBid2:FindChild("Auctions"):FindChild("Stop"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("Start"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("Assign"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("RemoveAuction"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("ShowVotes"):Enable(false)
		self:BidCustomLabelsUpdate(false)
	elseif #self.ActiveAuctions > 0 then
		self.ActiveAuctions[1].wnd:SetName("Auctions")
	end
end

function DKP:Bid2AuctionTimerStart()
	Apollo.RegisterTimerHandler(1, "Bid2UpdateProgress", self)
	self.Bid2Timer = ApolloTimer.Create(1,true, "Bid2UpdateProgress", self)
end

function DKP:Bid2UpdateProgress()
	for k,auction in ipairs(self.ActiveAuctions) do

		if auction.bActive then

			auction.nTimeLeft = auction.nTimeLeft + 1
			auction.wnd:FindChild("TimeLeft"):SetProgress(auction.nTimeLeft,1)
			auction.wnd:FindChild("TimeLeft"):FindChild("Time"):SetText(auction.duration - auction.nTimeLeft .. " (s) ")
			if auction.nTimeLeft >= self.tItems["settings"]["Bid2"].duration then
				auction.bActive = false
				auction.wnd:FindChild("TimeLeft"):FindChild("Time"):SetText("Finish")
				auction.wnd:FindChild("RemoveAuction"):Enable(true)
				for l,child in ipairs(auction.wnd:FindChild("Controls"):GetChildren()) do child:Enable(false) end
			end
		end
	end
	if #self.ActiveAuctions == 0 then
		self.Bid2Timer:Stop()
		self.Bid2Timer = nil
		Apollo.RemoveEventHandler("Bid2UpdateProgress",self)
	end
end


function DKP:Bid2BroadcastMySuperiority()
	local msg = {}
	msg.type = "IamML"
	if self.channel then self:Bid2PackAndSend(msg) end
end


function DKP:BidAddNewAuction(itemID,bMaster,progress,nDuration,bReceived,tLabels,tLabelsState)
	local tData = itemID
	if type(itemID) == "table" then
		itemID = tData.itemDrop:GetItemId()
	end


	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then return end
	end


	if bReceived == nil then bReceived = false end
	if nDuration == nil then nDuration = self.tItems["settings"]["Bid2"].duration end
	local item = Item.GetDataFromId(itemID)
	if item then

		if progress == nil then progress = 0 end
		local targetWnd
		if #self.ActiveAuctions == 0 then
			if self.wndBid2:FindChild("Frame"):FindChild("Auctions") then
				targetWnd = self.wndBid2:FindChild("Frame"):FindChild("Auctions")
			else
				targetWnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2:FindChild("Frame"),self)
				targetWnd:SetName("Auctions")
			end
		else
			targetWnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2:FindChild("Frame"),self)
			self.wndBid2:FindChild("Frame"):FindChild("Auctions"):AttachTab(targetWnd,false)
			targetWnd:Lock(true)
		end
		if targetWnd:FindChild("LoadingOverlay"):IsShown() then
			targetWnd:FindChild("LoadingOverlay"):Show(false,false)
			targetWnd:FindChild("LoadingOverlay"):FindChild("Button"):Show(true,false)
			targetWnd:FindChild("Auctions"):FindChild("Stop"):Enable(true)
			targetWnd:FindChild("Auctions"):FindChild("Start"):Enable(true)
			targetWnd:FindChild("Auctions"):FindChild("Assign"):Enable(true)
			targetWnd:FindChild("Auctions"):FindChild("RemoveAuction"):Enable(true)
			targetWnd:FindChild("Auctions"):FindChild("ShowVotes"):Enable(true)
			targetWnd:FindChild("Auctions"):FindChild("Random"):Enable(true)
			self:BidCustomLabelsUpdate(true)
		end
		if bMaster == nil then
			if #Hook.wndMasterLoot_ItemList:GetChildren() == 0 then bMaster = false else bMaster = true end
		end
		targetWnd:FindChild("Frame"):FindChild("Icon"):SetSprite(item:GetIcon())
		targetWnd:FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
		targetWnd:FindChild("ItemName"):SetText(item:GetName())
		targetWnd:FindChild("ItemCost"):SetText(self:EPGPGetItemCostByID(itemID,true))
		targetWnd:SetData(itemID)
		targetWnd:SetText(item:GetName())
		targetWnd:FindChild("TimeLeft"):SetProgress(progress,1000)
		if nDuration then
			targetWnd:FindChild("TimeLeft"):SetMax(nDuration)
		else
			targetWnd:FindChild("TimeLeft"):SetMax(self.tItems["settings"]["Bid2"].duration)
		end
		if tLabels and tLabelsState then
			for k,strLabel in ipairs(tLabels) do
				targetWnd:FindChild("Controls"):FindChild("Opt"..k):SetText(strLabel)
			end
			for k,bLabel in ipairs(tLabelsState) do
				targetWnd:FindChild("Controls"):FindChild("Opt"..k):Enable(bLabel)
			end
		end
		targetWnd:FindChild("RemoveAuction"):Enable(true)
		if progress > 0 then targetWnd:FindChild("TimeLeft"):FindChild("Time"):SetText(self.tItems["settings"]["Bid2"].duration - progress .. "(s)") end
		if not bMaster then
			targetWnd:FindChild("Assign"):SetText("Vote")
			targetWnd:FindChild("Start"):Enable(false)
			targetWnd:FindChild("Stop"):Enable(false)
		end
		if self.tItems["settings"].bLootCouncil then targetWnd:FindChild("ItemCost"):Show(false,false) end
		Tooltip.GetItemTooltipForm(self,targetWnd:FindChild("Icon"),item,{bPrimary = true, bSelling = false})
		table.insert(self.ActiveAuctions,{wnd = targetWnd , bActive = bReceived , nTimeLeft = progress, bidders = {}, bMaster = bMaster, votes = {},bPass = bPass,duration = nDuration,nLootId = type(tData) == "table" and tData.nLootId or nil})
		self:Bid2RestoreMyChoices(self.ActiveAuctions[#self.ActiveAuctions])
		self:Bid2RestoreMyVotes(self.ActiveAuctions[#self.ActiveAuctions])
		self:Bid2UpdateMLTooltip()
		self.wndBid2:Show(true,false)
		if bReceived and self.Bid2Timer == nil then self:Bid2AuctionTimerStart() end
	end
end

function DKP:Bid2RestoreMyVotes(auction)
	 for k,vote in ipairs(self.MyVotes) do
		if auction.wnd:GetData() == vote.item then
			for l,wndBidder in ipairs(auction.wnd:FindChild("Responses"):GetChildren()) do
				if wndBidder:FindChild("CharacterName"):GetText() == vote.who then
					wndBidder:FindChild("GlowingThing"):Show(true,false)
					return
				end
			end
		end
	end
end

function DKP:Bid2AuctionStart(wndHandler, wndControl, eMouseButton)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			auction.bActive = true
			if auction.nTimeLeft == 0 then
				self:Bid2SendAuctionStartMessage(auction.wnd:GetData())
			else
				self:Bid2SendResumeMessage(auction.wnd:GetData())
			end
			auction.wnd:FindChild("RemoveAuction"):Enable(false)
			if self.Bid2Timer == nil then self:Bid2AuctionTimerStart() end
			break
		end
	end

end

function DKP:BID2ChoiceChanged(wndHandler,wndControl)
	for k,choice in ipairs(self.MyChoices) do
		if choice.item == wndControl:GetParent():GetParent():GetData() then table.remove(self.MyChoices,k) break end
	end
	local item = Item.GetDataFromId(wndControl:GetParent():GetParent():GetData())
	local itemComparee
	local bPass
	for k,auction in ipairs(self.ActiveAuctions) do if auction.wnd:GetData() == item:GetItemId() then bPass = auction.bPass break end end
	if item:IsEquippable() and item:GetEquippedItemForItemType() then itemComparee = item:GetEquippedItemForItemType():GetItemId() end
	self:BidRegisterChoice(GameLib.GetPlayerUnit():GetName(),wndControl:GetName(),wndControl:GetParent():GetParent():GetData(),itemComparee)
	table.insert(self.MyChoices,{item = item:GetItemId(),option = wndControl:GetName()})
	self:Bid2PackAndSend({type = "Choice" , option = wndControl:GetName(), item = wndControl:GetParent():GetParent():GetData(), itemCompare = itemComparee})
end

function DKP:BidUpdateTabProgress(wndHandler,wndControl)
	if self.ActiveAuctions then
		for k,auction in ipairs(self.ActiveAuctions) do
			if auction.wnd == wndControl then
				wndControl:FindChild("TimeLeft"):SetProgress(auction.nTimeLeft,100)
				break
			end
		end
	end
end

function DKP:Bid2StopAuction(wndHandler,wndControl)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			auction.bActive = false
			self:Bid2SendStopMessage(auction.wnd:GetData())
			auction.wnd:FindChild("RemoveAuction"):Enable(true)
			break
		end
	end
end

-- Helpers

function DKP:BidConvertToBid2()
	local strItem = self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()
	if self.ItemDatabase[strItem] then
		self:BidAddNewAuction(self.ItemDatabase[strItem].ID)
		self.wndBid2:Show(true,false)
		self.wndBid:Show(false,true)
	else
		Print("The item ID is not available")
	end
end

function DKP:Bid2GetItemCostPackage()
	local arr = {}
	arr.type = "CostValues"
	arr.SlotValues = self.tItems["EPGP"].SlotValues
	arr.QualityValues = self.tItems["EPGP"].QualityValues
	arr.CustomModifier = self.tItems["EPGP"].FormulaModifier
	return arr
end

function DKP:Bid2Close()
	self.wndBid2:Show(false,false)
end
-- Settings

function DKP:Bid2SetChannelName(wndH,wndC,strText)
	self.tItems["settings"]["Bid2"].strChannel = strText
	self.wndMLSettings:FindChild("ChannelName"):SetText(strText)
	self:BidJoinChannel()
end

function DKP:Bid2ShowSettings()
	self.wndBid2Settings:Show(true,false)
	self.wndBid2Settings:ToFront()
end

function DKP:Bid2CloseSettings()
	self.wndBid2Settings:Show(false,false)
end

function DKP:Bid2EnableOffspec()
	self.tItems["settings"]["Bid2"].bAllowOffspec = true
end

function DKP:Bid2DisableOffspec()
	self.tItems["settings"]["Bid2"].bAllowOffspec = false
end
function DKP:Bid2RestoreSettings()
	self.wndBid2Settings:FindChild("Time"):FindChild("Value"):SetText(self.tItems["settings"]["Bid2"].duration)
	self.wndBid2Settings:FindChild("Channel"):FindChild("Value"):SetText(self.tItems["settings"]["Bid2"].strChannel)
	self.wndBid2Settings:FindChild("AssignActionSelection"):FindChild(self.tItems["settings"]["Bid2"].assignAction):SetCheck(true)
	self.wndBid2Settings:FindChild("WhitelistOption"):FindChild("Button"):SetCheck(self.tItems["settings"]["Bid2"].bWhitelist)
	self.wndBid2Settings:FindChild("RegisterPass"):FindChild("Button"):SetCheck(self.tItems["settings"]["Bid2"].bRegisterPass)
	self.wndBid2Settings:FindChild("CloseOnAssign"):FindChild("Button"):SetCheck(self.tItems["settings"]["Bid2"].bCloseOnAssign)
	self.wndBid2Settings:FindChild("NotifyRaid"):FindChild("Button"):SetCheck(self.tItems["settings"]["Bid2"].bNotify)
end

function DKP:BidSetAuctionTime(wndHandler,wndControl,strText)
	if tonumber(strText) ~= nil then
		self.tItems["settings"]["Bid2"].duration = tonumber(strText)
	else
		wndControl:SetText(self.tItems["settings"]["Bid2"].duration)
	end
end

function DKP:BidAssignActionChanged(wndHandler,wndControl)
	self.tItems["settings"]["Bid2"].assignAction = wndControl:GetName()
end

function DKP:Bid2LooterSelected(wndHandler,wndControl)
	self:Bid2PopulatePlayerInfo(wndControl:GetData(),wndControl:GetParent():GetParent():GetParent():FindChild("Info"))
	self.Bid2SelectedPlayerName = wndControl:GetData().strName
	self.Bid2SelectedPlayerTile = wndControl
end

function DKP:Bid2PopulatePlayerInfo(bidder,container)
	container:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[self:GetPlayerByIDByName(bidder.strName)].class])
	container:FindChild("Name"):SetText(bidder.strName)
	container:FindChild("PR"):SetText(bidder.pr .. " PR")
	if bidder.currItem then
		local item = Item.GetDataFromId(bidder.currItem)
		container:FindChild("ItemFrameCompare"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
		container:FindChild("ItemFrameCompare"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
		Tooltip.GetItemTooltipForm(self, container:FindChild("ItemFrameCompare"):FindChild("ItemIcon") ,  item, {bPrimary = true, bSelling = false, itemCompare = Item.GetDataFromId(container:GetParent():GetData())})
	else
		container:FindChild("ItemFrameCompare"):SetSprite("CRB_Tooltips:sprTooltip_SquareFrame_Orange")
		container:FindChild("ItemFrameCompare"):FindChild("ItemIcon"):SetSprite("IconSprites:Icon_ItemArmorTrinket_Unidentified_Trinket_0009")
	end
	local ID = self:GetPlayerByIDByName(bidder.strName)
	if self.tItems["settings"]["Bid2"].tWinners and  self.tItems["settings"]["Bid2"].tWinners[bidder.strName] then
		local item = Item.GetDataFromId(self.tItems["settings"]["Bid2"].tWinners[bidder.strName])
		container:FindChild("ItemFrameLast"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
		container:FindChild("ItemFrameLast"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
		Tooltip.GetItemTooltipForm(self, container:FindChild("ItemFrameLast"):FindChild("ItemIcon") ,item , {bPrimary = true, bSelling = false})
	else
		for k,child in ipairs(container:FindChild("ItemFrameLast"):FindChild("ItemIcon"):GetChildren()) do
		end
		container:FindChild("ItemFrameLast"):SetSprite("CRB_Tooltips:sprTooltip_SquareFrame_Orange")
		container:FindChild("ItemFrameLast"):FindChild("ItemIcon"):SetSprite("IconSprites:Icon_ItemArmorTrinket_Unidentified_Trinket_0009")
	end

end

function DKP:Bid2ShowAuctionVotes(wndHandler,wndControl)
	wndControl:GetParent():FindChild("Votes1"):Show(true,false)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then self:Bid2PopulateAuctionVotes(auction) break end
	end
end

function DKP:Bid2HideAuctionVotes(wndHandler,wndControl)
	wndControl:GetParent():FindChild("Votes1"):Show(false,false)
end

function DKP:Bid2SelectRandomWinner(nOpt,bidders)
	if type(bidders) ~= "table" then return {} end
	if nOpt >= 5 then return {} end
	local strWinner = ""
	local tBidders = {}
	for k , tBidder in ipairs(bidders) do
		if tonumber(string.sub(tBidder.option,4)) == nOpt then
			table.insert(tBidders,tBidder.strName)
		end
	end
	if #tBidders == 0 then tBidders = self:Bid2SelectRandomWinner(nOpt + 1,bidders) end
	return tBidders
end

function DKP:Bid2SelectBidderAtRandom(wndHandler,wndControl)
	for k , auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			local tBidders = self:Bid2SelectRandomWinner(1,auction.bidders)

			if #tBidders == 0 then return end

			local luckyBidder = tBidders[math.random(#tBidders)]


			for k , child in ipairs(auction.wnd:FindChild("Responses"):GetChildren()) do
				if child:GetData().strName == luckyBidder then
					child:SetCheck(true)
					luckyBidder = child
				else
					child:SetCheck(false)
				end
			end

			self:Bid2PopulatePlayerInfo(luckyBidder:GetData(),luckyBidder:GetParent():GetParent():GetParent():FindChild("Info"))
			self.Bid2SelectedPlayerName = luckyBidder:GetData().strName
			self.Bid2SelectedPlayerTile = luckyBidder

			break
		end
	end
end

function DKP:Bid2PopulateAuctionVotes(auction)
	local grid = auction.wnd:FindChild("Votes1"):FindChild("Grid")

	grid:DeleteAll()

	for k,vote in ipairs(auction.votes) do
		grid:AddRow(k)
		grid:SetCellData(k,1,vote.assistant)
		grid:SetCellData(k,2,vote.who)
	end
end

function DKP:Bid2AddTestAuction()
	self:BidAddNewAuction(math.random(20000,40000),true)
	self.ActiveAuctions[#self.ActiveAuctions].wnd:FindChild("Assign"):Enable(false)
end

function DKP:Bid2RegisterVote(strName,itemID,strAssistant)
	local found = false
	local currAuction
	local ofID
	local previousWho

	if self.tItems["settings"]["Bid2"].bWhitelist and not self:Bid2IsPlayerOnWhitelist(strAssistant) then return end

	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			currAuction = auction
			break
		end
	end

	if currAuction then
		for k,vote in ipairs(currAuction.votes) do
			if string.lower(vote.assistant) == string.lower(strAssistant) then
				found = true
				ofID = k
				previousWho = vote.who
				break
			end
		end

		if currAuction and not found then
			for k,bidder in ipairs(currAuction.bidders) do
				if bidder.strName == strName then
					bidder.votes = bidder.votes + 1
					table.insert(currAuction.votes,{assistant = strAssistant,who = strName})
					break
				end
			end
		elseif currAuction and found and ofID then
			local tasks = 2
			for k,bidder in ipairs(currAuction.bidders) do
				if bidder.strName == strName then
					bidder.votes = bidder.votes + 1
					table.insert(currAuction.votes,{assistant = strAssistant,who = strName})
					tasks = tasks - 1
				end
				if bidder.strName == previousWho then
					bidder.votes = bidder.votes - 1
					table.remove(currAuction.votes,ofID)
					tasks = tasks - 1
				end
				if tasks == 0 then break end
			end
		end
		self:Bid2ArrangeResponses(currAuction)
	end
end

function DKP:Bid2AssignItem(wndHandler,wndControl)
	local bMaster = true

	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			bMaster = auction.bMaster
			if auction.nLootId and self.tItems["settings"]["Bid2"].assignAction == "assign" then
				local item = Item.GetDataFromId(wndControl:GetParent():GetData())
				self:Bid2PackAndSend({type = "ItemResults",item = item:GetItemId(),winner = self.Bid2SelectedPlayerName})
				if self.tItems["settings"]["Bid2"].tWinners == nil then self.tItems["settings"]["Bid2"].tWinners = {} end
				self.tItems["settings"]["Bid2"].tWinners[self.Bid2SelectedPlayerName] = item:GetItemId()

				Event_FireGenericEvent("RaidOpsLootHexAssignThisItem",auction.nLootId,self.Bid2SelectedPlayerName)
				return
			end
		end
	end


	if wndControl:GetText() == "Vote" then bMaster = false end

	if bMaster then
		for k,child in ipairs(Hook.wndMasterLoot_ItemList:GetChildren()) do
			if child:IsChecked() then Hook.tMasterLootSelectedItem = child:GetData() break end
		end
		Hook:OnMasterLootUpdate(true)

		local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
		local selectedOne
		local selectedItem
		if self.tItems["settings"]["Bid2"].assignAction == "select" then
			for k,child in ipairs(children) do
				child:SetCheck(false)
			end
		end
		for k,child in ipairs(children) do
			if string.lower(child:FindChild("CharacterName"):GetText()) == string.lower(self.Bid2SelectedPlayerName) then
				selectedOne = child
				if self.tItems["settings"]["Bid2"].assignAction == "select" then child:SetCheck(true) end
				break
			end
		end
		children = Hook.wndMasterLoot_ItemList:GetChildren()
		local item = Item.GetDataFromId(wndControl:GetParent():GetData())
		if self.tItems["settings"]["Bid2"].assignAction == "select" then
			for k,child in ipairs(children) do
				child:SetCheck(false)
			end
		end
		for k,child in ipairs(children) do
			if item:GetName() == child:GetData().itemDrop:GetName() then
				selectedItem = child:GetData()
				if self.tItems["settings"]["Bid2"].assignAction == "select" then child:SetCheck(true) end
				break
			end
		end
		if self.tItems["settings"]["Bid2"].assignAction == "select" then Hook.wndMasterLoot:FindChild("Assignment"):Enable(true) end

		if not selectedOne or not selectedItem then
			Print("Looter or item not available")
		end

		Hook.tMasterLootSelectedLooter = selectedOne:GetData()
		Hook.tMasterLootSelectedItem = selectedItem

		self:Bid2PackAndSend({type = "ItemResults",item = item:GetItemId(),winner = selectedOne:GetData():GetName()})
		if self.tItems["settings"]["Bid2"].tWinners == nil then self.tItems["settings"]["Bid2"].tWinners = {} end
		self.tItems["settings"]["Bid2"].tWinners[selectedOne:GetData():GetName()] = item:GetItemId()

		if self.tItems["settings"]["Bid2"].assignAction == "assign" then
			Hook:OnAssignDown()
			wndControl:Enable(false)
		end
	else
		if self.Bid2SelectedPlayerName and wndControl:GetParent():GetData() then
			self:Bid2PackAndSend({type = "MyVote" , who = self.Bid2SelectedPlayerName, item = wndControl:GetParent():GetData()})
			self:Bid2RegisterVote(self.Bid2SelectedPlayerName,wndControl:GetParent():GetData(),GameLib:GetPlayerUnit():GetName())
			table.insert(self.MyVotes,{item = wndControl:GetParent():GetData(),who = self.Bid2SelectedPlayerName})
		end
	end

end

function DKP:Bid2CloseResponses(wndHandler,wndControl)
	wndControl:GetParent():Show(false,false)
end

function DKP:Bid2EnableWhitelist()
	self.tItems["settings"]["Bid2"].bWhitelist = true
end

function DKP:Bid2DisableWhitelist()
	self.tItems["settings"]["Bid2"].bWhitelist = false
end

function DKP:Bid2NotifyEnable()
	self.tItems["settings"]["Bid2"].bNotify = true
end

function DKP:Bid2NotifyDisable()
	self.tItems["settings"]["Bid2"].bNotify = false
end

function DKP:Bid2ShowWhiteList()
	self.wndBid2Whitelist:Show(true,false)
	self:Bid2PopulateWhitelist()
	self.wndBid2Whitelist:ToFront()
end

function DKP:Bid2WhitelistClose()
	self.wndBid2Whitelist:Show(false,false)
end

function DKP:Bid2DisablePass()
	self.tItems["settings"]["Bid2"].bRegisterPass = false
end

function DKP:Bid2EnablePass()
	self.tItems["settings"]["Bid2"].bRegisterPass = true
end

function DKP:Bid2CloseOnAssignEnable()
	self.tItems["settings"]["Bid2"].bCloseOnAssign = true
end

function DKP:Bid2CloseOnAssignDisable()
	self.tItems["settings"]["Bid2"].bCloseOnAssign = false
end

function DKP:Bid2CloseOnAssign(strItem)
	if not self.ItemDatabase or not self.ItemDatabase[strItem] or not self.tItems["settings"]["Bid2"] or not self.tItems["settings"]["Bid2"].bCloseOnAssign then return end
	local itemID = self.ItemDatabase[strItem].ID

	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			table.remove(self.ActiveAuctions,k)
			auction.wnd:Detach()
			auction.wnd:Destroy()
			for l,choice in ipairs(self.MyChoices) do
				if choice.item == auction.wnd:GetData() then
					table.remove(self.MyChoices,l)
					break
				end
			end
			for l,vote in ipairs(self.MyVotes) do
				if vote.item == auction.wnd:GetData() then
					table.remove(self.MyVotes,l)
					break
				end
			end
			break
		end
	end

	if self.wndBid2:FindChild("Auctions") == nil and #self.ActiveAuctions == 0 then
		local wnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2:FindChild("Frame"),self)
		wnd:SetName("Auctions")
		self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):Show(true,false)
		self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):FindChild("Status"):SetText("No Active Auctions")
		self.wndBid2:FindChild("Auctions"):FindChild("LoadingOverlay"):FindChild("Button"):Show(false)
		self.wndBid2:FindChild("Auctions"):FindChild("Stop"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("Start"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("Assign"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("RemoveAuction"):Enable(false)
		self.wndBid2:FindChild("Auctions"):FindChild("ShowVotes"):Enable(false)
		self:BidCustomLabelsUpdate(false)
	elseif #self.ActiveAuctions > 0 then
		self.ActiveAuctions[1].wnd:SetName("Auctions")
	end
end


function DKP:Bid2AddWhitelistedName(wndHandler,wndControl,strText)
	table.insert(self.tItems["settings"]["Bid2"].tWhitelisted,strText)
	self:Bid2PopulateWhitelist()
end

function DKP:Bid2RemoveWhitelistedPlayer()
	if self.WhiteListedPlayer == nil then return end
	for k,player in ipairs(self.tItems["settings"]["Bid2"].tWhitelisted) do
		if string.lower(self.WhiteListedPlayer) == string.lower(player) then
			table.remove(self.tItems["settings"]["Bid2"].tWhitelisted,k)
			break
		end
	end
	self:Bid2PopulateWhitelist()
end

function DKP:Bid2WhiteListItemSelected(wndHandler,wndControl)
	self.WhiteListedPlayer = wndControl:FindChild("PlayerName"):GetText()
end

function DKP:Bid2PopulateWhitelist()
	self.wndBid2Whitelist:FindChild("Whitelisted"):DestroyChildren()
	for k,player in ipairs(self.tItems["settings"]["Bid2"].tWhitelisted) do
		local wnd = Apollo.LoadForm(self.xmlDoc2,"ItemWhitelisted",self.wndBid2Whitelist:FindChild("Whitelisted"),self)
		wnd:FindChild("PlayerName"):SetText(player)
	end
	self.wndBid2Whitelist:FindChild("Whitelisted"):ArrangeChildrenVert()
end

function DKP:Bid2IsPlayerOnWhitelist(strName)
	for k,player in ipairs(self.tItems["settings"]["Bid2"].tWhitelisted) do
		if string.lower(strName) == string.lower(player) then return true end
	end
	return false
end

function DKP:BidCharacterChecked(wndHandler,wndControl)
	if wndControl:FindChild("CharacterName"):GetText() == "Guild Bank" then self.bIsSelectedGuildBank = true else self.bIsSelectedGuildBank = false end
end

-------------- Hook to Carbine's ML addon

function DKP:HookToMasterLootDisp()
	if not self:IsHooked(Apollo.GetAddon("MasterLootDependency"),"RefreshMasterLootLooterList") then
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"RefreshMasterLootLooterList")
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"OnAssignDown")
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"RefreshMasterLootItemList")
		self:RawHook(Apollo.GetAddon("MasterLootDependency"),"OnLootAssigned")
		self:PostHook(Apollo.GetAddon("MasterLootDependency"),"OnItemCheck","BidMasterItemSelected")
		self:Hook(Apollo.GetAddon("MasterLootDependency"),"OnCharacterCheck","BidCharacterChecked")
	end
end

function DKP:OnAssignDown(luaCaller,wndHandler, wndControl, eMouseButton)

	if luaCaller.tMasterLootSelectedItem ~= nil and luaCaller.tMasterLootSelectedLooter ~= nil then
		local DKPInstance = Apollo.GetAddon("RaidOps")
		-- gotta save before it gets wiped out by event
		local SelectedLooter = luaCaller.tMasterLootSelectedLooter
		local SelectedItemLootId = luaCaller.tMasterLootSelectedItem.nLootId

		luaCaller.tMasterLootSelectedLooter = nil
		luaCaller.tMasterLootSelectedItem = nil
		if #DKPInstance.tSelectedItems > 1 then
			for k,item in ipairs(DKPInstance.tSelectedItems) do
				if prevLuckyChild and SelectedLooter:GetName() == prevLuckyChild then self:BidAddPlayerToRandomSkip(prevLuckyChild,item.itemDrop:GetItemId()) end
				GameLib.AssignMasterLoot(item.nLootId,SelectedLooter)
				DKPInstance:MLRegisterItemWinner()
			end
			DKPInstance.tSelectedItems = {}
		else
			if prevLuckyChild and SelectedLooter:GetName() == prevLuckyChild and luaCaller.tMasterLootSelectedItem then self:BidAddPlayerToRandomSkip(prevLuckyChild,luaCaller.tMasterLootSelectedItem.itemDrop:GetItemId()) end
			GameLib.AssignMasterLoot(SelectedItemLootId,SelectedLooter)
		end
	end
	-- wipe lucky winner to avoid pop-up oddities
	prevLuckyChild = nil
end

function DKP:OnLootAssigned(luaCaller,tLootInfo)
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if DKPInstance.bIsSelectedGuildBank and string.lower(tLootInfo.strPlayer) == string.lower(DKPInstance.tItems["settings"]["ML"].strGBManager) and Hook.bSelectedGuildBank then tLootInfo.strPlayer = "Guild Bank" end
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), tLootInfo.itemLoot:GetName(), tLootInfo.strPlayer))
end


function DKP:MLRegisterItemWinner()
	if Hook.tMasterLootSelectedLooter and Hook.tMasterLootSelectedItem then
		self.tItems["settings"]["ML"].tWinners[Hook.tMasterLootSelectedLooter:GetName()] = Hook.tMasterLootSelectedItem.itemDrop:GetItemId()
	end
end

function DKP:sortMasterLootEasyDKPasc(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if DKPInstance == nil then return end
	if not DKPInstance.tItems["settings"]["ML"].bSortByName then
		if DKPInstance.tItems["EPGP"].Enable == 1 then
			return DKPInstance:EPGPGetPRByName(a:FindChild("CharacterName"):GetText()) * (a:FindChild("CharacterName"):GetText() == "Guild Bank" and 1000000 or 1) > DKPInstance:EPGPGetPRByName(b:FindChild("CharacterName"):GetText()) * (b:FindChild("CharacterName"):GetText() == "Guild Bank" and 1000000 or 1)
		else
			local IDa = DKPInstance:GetPlayerByIDByName(a:FindChild("CharacterName"):GetText())
			local IDb = DKPInstance:GetPlayerByIDByName(b:FindChild("CharacterName"):GetText())
			if IDa ~= -1 and IDb ~= -1 then
				return DKPInstance.tItems[IDa].net * (a:FindChild("CharacterName"):GetText() == "Guild Bank" and 1000000 or 1) > DKPInstance.tItems[IDb].net * (b:FindChild("CharacterName"):GetText() == "Guild Bank" and 1000000 or 1)
			end
		end
	else -- name
		local nameA = a:FindChild("CharacterName"):GetText()
		local nameB = b:FindChild("CharacterName"):GetText()
		if nameA == "Guild Bank" then nameA = "ZZZZZZZZZZZZZZZZZZ" end
		if nameB == "Guild Bank" then nameB = "ZZZZZZZZZZZZZZZZZZ" end

		if not a:IsEnabled() then nameA = "AAAAAAAAAAAAAAAAAA" end
		if not b:IsEnabled() then nameB = "AAAAAAAAAAAAAAAAAA" end
		return nameA > nameB
	end
end

function sortMasterLootEasyDKPdesc(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if DKPInstance == nil then return end
	if not DKPInstance.tItems["settings"]["ML"].bSortByName then
		if DKPInstance.tItems["EPGP"].Enable == 1 then
			return DKPInstance:EPGPGetPRByName(a:FindChild("CharacterName"):GetText()) * (a:FindChild("CharacterName"):GetText() == "Guild Bank" and  0.0000001 or 1) < DKPInstance:EPGPGetPRByName(b:FindChild("CharacterName"):GetText()) * (b:FindChild("CharacterName"):GetText() == "Guild Bank" and  0.0000001 or 1)
		else
			local IDa = DKPInstance:GetPlayerByIDByName(a:FindChild("CharacterName"):GetText())
			local IDb = DKPInstance:GetPlayerByIDByName(b:FindChild("CharacterName"):GetText())
			if IDa ~= -1 and IDb ~= -1 then
				return DKPInstance.tItems[IDa].net * (a:FindChild("CharacterName"):GetText() == "Guild Bank" and  0.0000001 or 1) < DKPInstance.tItems[IDb].net * (b:FindChild("CharacterName"):GetText() == "Guild Bank" and  0.0000001 or 1)
			end
		end
	else -- name
		local nameA = a:FindChild("CharacterName"):GetText()
		local nameB = b:FindChild("CharacterName"):GetText()
		if nameA == "Guild Bank" then nameA = "AAAAAAAAAAAAAAAAAA" end
		if nameB == "Guild Bank" then nameB = "AAAAAAAAAAAAAAAAAA" end

		if not a:IsEnabled() then nameA = "ZZZZZZZZZZZZZZZ" end
		if not b:IsEnabled() then nameB = "ZZZZZZZZZZZZZZZ" end
		return nameA < nameB
	end
end

function sortLooters(a,b)
	if not a or not b then return true end
	local DKPInstance = Apollo.GetAddon("RaidOps")
	local nameA
	local nameB
	if type(a) == "number" then -- in order to make this less confusing we will lose some performance -- aka (I'm lazy)
		nameA = DKPInstance.tItems[a].strName -- a is valid ID as it was checked previously
	else
		nameA = a:GetName()
	end
	if type(b) == "number" then
		nameB = DKPInstance.tItems[b].strName
	else
		nameB = b:GetName()
	end

	if DKPInstance.tItems["settings"].BidSortAsc == 0 then
		if not DKPInstance.tItems["settings"]["ML"].bSortByName then
			if DKPInstance.tItems["EPGP"].Enable == 1 then
				return DKPInstance:EPGPGetPRByName(nameA) < DKPInstance:EPGPGetPRByName(nameB)
			else
				local IDa = DKPInstance:GetPlayerByIDByName(nameA)
				local IDb = DKPInstance:GetPlayerByIDByName(nameB)
				if IDa ~= -1 and IDb ~= -1 then
					return DKPInstance.tItems[IDa].net < DKPInstance.tItems[IDb].net
				end
			end
		else -- name
			return nameA < nameB
		end
	else -- asc
		if not DKPInstance.tItems["settings"]["ML"].bSortByName then
			if DKPInstance.tItems["EPGP"].Enable == 1 then
				return DKPInstance:EPGPGetPRByName(nameA) > DKPInstance:EPGPGetPRByName(nameB)
			else
				local IDa = DKPInstance:GetPlayerByIDByName(nameA)
				local IDb = DKPInstance:GetPlayerByIDByName(nameB)
				if IDa ~= -1 and IDb ~= -1 then
					return DKPInstance.tItems[IDa].net > DKPInstance.tItems[IDb].net
				end
			end
		else -- name
			return nameA > nameB
		end
	end
end

function DKP:SendRequestsForCurrItem(itemz)
	if self.channel then self:Bid2PackAndSend({type = "GimmeUrEquippedItem",item = itemz}) end
end

function DKP:BidAllowMultiSelection()
	self.tItems["settings"]["ML"].bAllowMulti = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:BidDisAllowMultiSelection()
	self.tItems["settings"]["ML"].bAllowMulti = false
	self.tSelectedItems = {}
	Hook:OnMasterLootUpdate(true)
end

function DKP:RefreshMasterLootLooterList(luaCaller,tMasterLootItemList)

	luaCaller.wndMasterLoot_LooterList:DestroyChildren()
	if luaCaller ~= Apollo.GetAddon("MasterLootDependency") then luaCaller = Apollo.GetAddon("MasterLootDependency") end
	local DKPInstance = Apollo.GetAddon("RaidOps")
	if luaCaller.tMasterLootSelectedItem ~= nil then
		for idx, tItem in pairs (tMasterLootItemList) do
			if tItem.nLootId == luaCaller.tMasterLootSelectedItem.nLootId then
				local bStillHaveLooter = false
				local tables = {}
				-- Creating Tables
				if DKPInstance.tItems["settings"]["ML"].bGroup then
					tables.esp = {}
					tables.war = {}
					tables.spe = {}
					tables.med = {}
					tables.sta = {}
					tables.eng = {}
					tables.bid = {}
				else
					tables.all = {}
				end

				-- Determining applicable classes
				local bWantEsp = true
				local bWantWar = true
				local bWantSpe = true
				local bWantMed = true
				local bWantSta = true
				local bWantEng = true

				if DKPInstance.tItems["settings"]["ML"].bDisplayApplicable then
					if string.find(tItem.itemDrop:GetName(),"Imprint") then
					    bWantEsp = false
					    bWantWar = false
					    bWantSpe = false
					    bWantMed = false
					    bWantSta = false
					    bWantEng = false

						local tDetails = tItem.itemDrop:GetDetailedInfo()
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
					else
						local strCategory = tItem.itemDrop:GetItemCategoryName()
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
				local tPlayerResources = tItem.tLooters
				local tPlayersExcluded = {}
				-- Include OOR ppls if needed
				if not self.tItems["settings"]["ML"].bExcludeOOR then
					if tItem.tLootersOutOfRange and next(tItem.tLootersOutOfRange) then
						for idx, strLooterOOR in pairs(tItem.tLootersOutOfRange) do
							local ID = self:GetPlayerByIDByName(strLooterOOR)
							if ID ~= -1 then
								table.insert(tPlayerResources,ID) -- this serves as flag too
							else
								tPlayersExcluded[strLooterOOR] = 1 -- if there no such player in db ... well ... no data
							end
						end
					end
				else
					tPlayersExcluded = tItem.tLootersOutOfRange
				end
				-- Grouping Players
				local unitGBManager
				for idx, unitLooter in pairs(tPlayerResources) do
					if(type(unitLooter) ~= "number") then
						if DKPInstance.tItems["settings"]["ML"].bShowGuildBank and string.lower(unitLooter:GetName()) == string.lower(DKPInstance.tItems["settings"]["ML"].strGBManager) then unitGBManager = unitLooter end
					end
					class = ""
					if DKPInstance.tItems["settings"]["ML"].bGroup then
						if(type(unitLooter) ~= "number") then
							class = ktClassToString[unitLooter:GetClassId()]
						else
							class = self.tItems[unitLooter].class
						end
						if class == "Esper" and bWantEsp then
							table.insert(tables.esp,unitLooter)
						elseif class == "Engineer" and bWantEng then
							table.insert(tables.eng,unitLooter)
						elseif class == "Medic" and bWantMed then
							table.insert(tables.med,unitLooter)
						elseif class == "Warrior" and bWantWar then
							table.insert(tables.war,unitLooter)
						elseif class == "Stalker" and bWantSta then
							table.insert(tables.sta,unitLooter)
						elseif class == "Spellslinger" and bWantSpe then
							table.insert(tables.spe,unitLooter)
						elseif self.CurrentBidSession and tItem.itemDrop:GetName() == self.CurrentBidSession.strItem  then
							for k , bidder in ipairs(self.CurrentBidSession.Bidders) do
								if bidder.strName == unitLooter:GetName() then
									table.insert(tables.bid,unitLooter)
									break
								end
							end
						end
					else
						if(type(unitLooter) ~= "number") then
							class = ktClassToString[unitLooter:GetClassId()]
						else
							class = self.tItems[unitLooter].class
						end
						if class == "Esper" and bWantEsp then
							table.insert(tables.all,unitLooter)
						elseif class == "Engineer" and bWantEng then
							table.insert(tables.all,unitLooter)
						elseif class == "Medic" and bWantMed then
							table.insert(tables.all,unitLooter)
						elseif class == "Warrior" and bWantWar then
							table.insert(tables.all,unitLooter)
						elseif class == "Stalker" and bWantSta then
							table.insert(tables.all,unitLooter)
						elseif class == "Spellslinger" and bWantSpe then
							table.insert(tables.all,unitLooter)
						elseif self.CurrentBidSession and tItem.itemDrop:GetName() == self.CurrentBidSession.strItem  then
							for k , bidder in ipairs(self.CurrentBidSession.Bidders) do
								if bidder.strName == unitLooter:GetName() then
									table.insert(tables.all,unitLooter)
									break
								end
							end
						end
					end
				end
				-- Sorting in groups
				for k , tab in pairs(tables) do
					table.sort(tab,sortLooters)
				end
				-- Requesting EquippedItems - (deprecated)
				--[[if DKPInstance.tItems["settings"]["ML"].bShowCurrItemBar or DKPInstance.tItems["settings"]["ML"].bShowCurrItemTile then
					if tItem.itemDrop:IsEquippable() then
						local myName = GameLib.GetPlayerUnit():GetName()
						if myName then
							DKPInstance:SendRequestsForCurrItem(tItem.itemDrop:GetItemId())
							self.tEquippedItems[myName] = {}
							--self.tEquippedItems[myName][tItem.itemDrop:GetEquippedItemForItemType():GetSlot()] = tItem.itemDrop:GetEquippedItemForItemType():GetItemId()
						end
					end
				end]]

				-- Guild Bank
				local wndGuildBank
				if DKPInstance.tItems["settings"]["ML"].bShowGuildBank and unitGBManager then
					if DKPInstance.tItems["settings"]["ML"].bArrTiles then
						wndGuildBank = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonTileClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
					else
						wndGuildBank = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonListClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
					end

					wndGuildBank:FindChild("CharacterName"):SetText("Guild Bank")
					wndGuildBank:FindChild("ClassIcon"):SetSprite("achievements:sprAchievements_Icon_Group")
					wndGuildBank:FindChild("CharacterLevel"):SetText("")
					wndGuildBank:SetTooltip(unitGBManager:GetName() .. " is behind this.")
					wndGuildBank:SetData({unit = unitGBManager}) -- it's a flag! notice it! (in dependency addon)
				end

				-- Finally Creating windows
				local added = {}
				local strName
				local strSprite
				for k,tab in pairs(tables) do
					for j,unitLooter in ipairs(tab) do
						local wndCurrentLooter

						if type(unitLooter) == "number" then -- if OOR
							strName = DKPInstance.tItems[unitLooter].strName
							strSprite = ktStringToIcon[DKPInstance.tItems[unitLooter].class]
						else --if normal
							strName = unitLooter:GetName()
							strSprite = ktClassToIcon[unitLooter:GetClassId()]
						end

						if not added[strName] then
							added[strName] = true
							if DKPInstance.tItems["settings"]["ML"].bArrTiles then
								if DKPInstance.tItems["settings"]["ML"].bShowClass or DKPInstance.tItems["settings"]["ML"].bShowLastItem then
									wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonTileClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
									wndCurrentLooter:FindChild("ClassIcon"):SetSprite(strSprite)
								else
									wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2,"CharacterButtonTile", luaCaller.wndMasterLoot_LooterList,luaCaller)
								end

								if DKPInstance:GetPlayerByIDByName(strName) ~= -1 then
									if DKPInstance.tItems["EPGP"].Enable == 1 then
										wndCurrentLooter:FindChild("CharacterLevel"):SetText(DKPInstance:EPGPGetPRByName(strName,true))
									else
										wndCurrentLooter:FindChild("CharacterLevel"):SetText(DKPInstance.tItems[DKPInstance:GetPlayerByIDByName(strName)].net)
									end
								else
									wndCurrentLooter:FindChild("CharacterLevel"):SetText(type(unitLooter) == "number" and "" or unitLooter:GetBasicStats().nLevel)
								end

								if DKPInstance.tItems["settings"]["ML"].bShowLastItemTile then
									if self.tItems["settings"]["ML"].tWinners[strName] then
										local item = Item.GetDataFromId(self.tItems["settings"]["ML"].tWinners[strName])
										wndCurrentLooter:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
										wndCurrentLooter:FindChild("ItemFrame"):Show(true,false)
										wndCurrentLooter:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
										Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
									end
								end

								if DKPInstance.tItems["settings"]["ML"].bShowCurrItemTile then -- Set Current Item
									if DKPInstance.tEquippedItems[strName] and DKPInstance.tEquippedItems[strName][tItem.itemDrop:GetSlot()] then
										local item = Item.GetDataFromId(DKPInstance.tEquippedItems[strName][tItem.itemDrop:GetSlot()])
										wndCurrentLooter:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
										wndCurrentLooter:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
										wndCurrentLooter:FindChild("ItemFrame"):Show(true,false)
										Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
									end
								end

							else -- List
								if DKPInstance.tItems["settings"]["ML"].bShowClass then
									wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonListClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
									wndCurrentLooter:FindChild("ClassIcon"):SetSprite(strSprite)
								else
									wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonList", luaCaller.wndMasterLoot_LooterList, luaCaller)
								end
								wndCurrentLooter:FindChild("CharacterLevel"):SetText(type(unitLooter) == "number" and "" or unitLooter:GetBasicStats().nLevel)
								if DKPInstance.tItems["settings"]["ML"].bShowLastItemBar then
									if self.tItems["settings"]["ML"].tWinners[strName] then
										local item = Item.GetDataFromId(self.tItems["settings"]["ML"].tWinners[strName])
										wndCurrentLooter:FindChild("LastItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
										wndCurrentLooter:FindChild("LastItemFrame"):Show(true)
										wndCurrentLooter:FindChild("LastItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
										Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("LastItemFrame"),item, {bPrimary = true, bSelling = false})
									end
								end
								if DKPInstance.tItems["settings"]["ML"].bShowCurrItemBar then
									if DKPInstance.tEquippedItems[strName] and DKPInstance.tEquippedItems[strName][tItem.itemDrop:GetSlot()] then
										local item = Item.GetDataFromId(DKPInstance.tEquippedItems[strName][tItem.itemDrop:GetSlot()])
										wndCurrentLooter:FindChild("CurrItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
										wndCurrentLooter:FindChild("CurrItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
										wndCurrentLooter:FindChild("CurrItemFrame"):Show(true)
										Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("CurrItemFrame"),item, {bPrimary = true, bSelling = false})
									end
								end
								local ID = DKPInstance:GetPlayerByIDByName(strName)
								if ID ~= -1 and DKPInstance.tItems["settings"]["ML"].bListIndicators then
									local wndCounter = Apollo.LoadForm(DKPInstance.xmlDoc,"InsertDKPIndicator",wndCurrentLooter,DKPInstance)
									if DKPInstance.tItems["EPGP"].Enable == 0 then wndCounter:SetText("DKP : ".. DKPInstance.tItems[ID].net)
									else wndCounter:SetText("PR : ".. DKPInstance:EPGPGetPRByName(DKPInstance.tItems[ID].strName)) end
								end
							end
							wndCurrentLooter:FindChild("CharacterName"):SetText(strName)

							wndCurrentLooter:SetData(unitLooter)

							if type(unitLooter) == "number" then
								wndCurrentLooter:Enable(false)
								wndCurrentLooter:FindChild("CharacterName"):SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), strName))
							end

							if luaCaller.tMasterLootSelectedLooter == unitLooter then
								wndCurrentLooter:SetCheck(true)
								bStillHaveLooter = true
							end
						end
					end
				end
				-- For for ended

				if not bStillHaveLooter then
					luaCaller.tMasterLootSelectedLooter = nil
				end

				-- get out of range people
				-- tLootersOutOfRange
				if tPlayersExcluded and next(tPlayersExcluded) then
					for idx, strLooterOOR in pairs(tPlayersExcluded) do
						local wndCurrentLooter = Apollo.LoadForm(luaCaller.xmlDoc, "CharacterButton", luaCaller.wndMasterLoot_LooterList, luaCaller)
						wndCurrentLooter:FindChild("CharacterName"):SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), strLooterOOR))
						wndCurrentLooter:FindChild("ClassIcon"):SetSprite("CRB_GroupFrame:sprGroup_Disconnected")
						wndCurrentLooter:Enable(false)
					end
				end
				Hook:BidMLSearch()

				if DKPInstance.tItems["settings"]["ML"].bArrTiles then
					luaCaller.wndMasterLoot_LooterList:ArrangeChildrenTiles()
				else
					luaCaller.wndMasterLoot_LooterList:ArrangeChildrenVert()
				end

			end
		end
	end
end

function DKP:BidAddItem(wndHandler,wndControl)
	table.insert(self.tSelectedItems,wndControl:GetParent():GetData())
end

function DKP:BidRemoveItem(wndHandler,wndControl)
	for k,item in ipairs(self.tSelectedItems) do
		if item == wndControl:GetParent():GetData() then table.remove(self.tSelectedItems,k) end
	end

end

function DKP:OnItemCheck(wndHandler,wndControl,eMouseButton)
	Hook:OnItemCheck(wndHandler,wndControl,eMouseButton)
end

function DKP:OnItemMouseButtonUp(wndHandler,wndControl,eMouseButton)
	Hook:OnItemMouseButtonUp(wndHandler,wndControl,eMouseButton)
end

function raidOpsSortItemList(a,b)
	a = a.itemDrop
	b = b.itemDrop
	if a:GetSlot() ~= b:GetSlot() and b:GetSlot() and a:GetSlot() then
		return a:GetSlot() < b:GetSlot()
	else
		return a:GetName() < b:GetName()
	end
end

function DKP:RefreshMasterLootItemList(luaCaller,tMasterLootItemList)

	luaCaller.wndMasterLoot_ItemList:DestroyChildren()
	local DKPInstance = Apollo.GetAddon("RaidOps")

	table.sort(tMasterLootItemList,raidOpsSortItemList)
	for idx, tItem in ipairs (tMasterLootItemList) do
		local wndCurrentItem

		if DKPInstance.tItems["settings"]["ML"].bArrItemTiles then
			wndCurrentItem = Apollo.LoadForm(DKPInstance.xmlDoc2,"ItemButtonTile",luaCaller.wndMasterLoot_ItemList, DKPInstance)
		else
			wndCurrentItem = Apollo.LoadForm(DKPInstance.xmlDoc2, "ItemButton", luaCaller.wndMasterLoot_ItemList, DKPInstance)
			wndCurrentItem:FindChild("ItemName"):SetText(tItem.itemDrop:GetName())
		end

		if DKPInstance.tItems["settings"]["ML"].bAllowMulti and DKPInstance.tSelectedItems then
			wndCurrentItem:FindChild("Multi"):Show(true)
			wndCurrentItem:FindChild("Multi"):AddEventHandler("ButtonCheck","BidAddItem",DKPInstance)
			wndCurrentItem:FindChild("Multi"):AddEventHandler("ButtonUncheck","BidRemoveItem",DKPInstance)
			for k,item in ipairs(DKPInstance.tSelectedItems) do
				if tItem.nLootId == item.nLootId then
					wndCurrentItem:FindChild("Multi"):SetCheck(true)
					break
				end
			end
		end

		wndCurrentItem:FindChild("ItemIcon"):SetSprite(tItem.itemDrop:GetIcon())

		wndCurrentItem:SetData(tItem)
		if luaCaller.tMasterLootSelectedItem ~= nil and (luaCaller.tMasterLootSelectedItem.nLootId == tItem.nLootId) then
			wndCurrentItem:SetCheck(true)
			luaCaller:RefreshMasterLootLooterList(tMasterLootItemList)
		end
		Tooltip.GetItemTooltipForm(luaCaller, wndCurrentItem , tItem.itemDrop, {bPrimary = true, bSelling = false, itemCompare = tItem.itemDrop:GetEquippedItemForItemType()})
	end
	if DKPInstance.tItems["settings"]["ML"].bArrItemTiles then
		luaCaller.wndMasterLoot_ItemList:ArrangeChildrenTiles(0)
	else
		luaCaller.wndMasterLoot_ItemList:ArrangeChildrenVert(0)
	end

end

-- ML Settings

function DKP:MLSettingsOpen()
	self.wndMLSettings:Show(true,false)
	self.wndMLSettings:ToFront()
end

function DKP:MLSettingsRestore()
	self.wndMLSettings = Apollo.LoadForm(self.xmlDoc2,"MLSettings",nil,self)
	self.wndMLSettings:Show(false,true)
	if self.tItems["settings"]["ML"] == nil then
		self.tItems["settings"]["ML"] = {}
		self.tItems["settings"]["ML"].bShowClass = true
		self.tItems["settings"]["ML"].bArrTiles = false
		self.tItems["settings"]["ML"].bShowValues = true
	end
	if self.tItems["settings"]["ML"].bArrItemTiles == nil then self.tItems["settings"]["ML"].bArrItemTiles = false end
	if self.tItems["settings"]["ML"].bStandardLayout == nil then self.tItems["settings"]["ML"].bStandardLayout = true end
	if self.tItems["settings"]["ML"].bListIndicators == nil then self.tItems["settings"]["ML"].bListIndicators = true end
	if self.tItems["settings"]["ML"].bGroup == nil then self.tItems["settings"]["ML"].bGroup = false end
	if self.tItems["settings"]["ML"].bDispBidding == nil then self.tItems["settings"]["ML"].bDispBidding = true end
	if self.tItems["settings"]["ML"].bShowLastItemBar == nil then self.tItems["settings"]["ML"].bShowLastItemBar = true end
	if self.tItems["settings"]["ML"].bShowLastItemTile == nil then self.tItems["settings"]["ML"].bShowLastItemTile = true end
	if self.tItems["settings"]["ML"].bShowCurrItemBar == nil then self.tItems["settings"]["ML"].bShowCurrItemBar = true end
	if self.tItems["settings"]["ML"].bShowCurrItemTile == nil then self.tItems["settings"]["ML"].bShowCurrItemTile = false end
	if self.tItems["settings"]["ML"].bAllowMulti == nil then self.tItems["settings"]["ML"].bAllowMulti = false end
	if self.tItems["settings"]["ML"].bShowGuildBank == nil then self.tItems["settings"]["ML"].bShowGuildBank = false end
	if self.tItems["settings"]["ML"].strGBManager == nil then self.tItems["settings"]["ML"].strGBManager = "" end
	if self.tItems["settings"]["ML"].bDisplayApplicable == nil then self.tItems["settings"]["ML"].bDisplayApplicable = false end
	if self.tItems["settings"]["ML"].bSortByName == nil then self.tItems["settings"]["ML"].bSortByName = false end
	if self.tItems["settings"]["ML"].bAppOnDemand == nil then self.tItems["settings"]["ML"].bAppOnDemand = false end
	if self.tItems["settings"]["ML"].bExcludeOOR == nil then self.tItems["settings"]["ML"].bExcludeOOR = true end
	if self.tItems["settings"]["ML"].tWinners == nil then self.tItems["settings"]["ML"].tWinners = {} end

	if self.tItems["settings"]["ML"].bShowClass then self.wndMLSettings:FindChild("ShowClass"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bStandardLayout then self.wndMLSettings:FindChild("Horiz"):SetCheck(true) else self.wndMLSettings:FindChild("Vert"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bArrItemTiles then self.wndMLSettings:FindChild("TilesLoot"):SetCheck(true) else self.wndMLSettings:FindChild("ListLoot"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bArrTiles then self.wndMLSettings:FindChild("Tiles"):SetCheck(true) else self.wndMLSettings:FindChild("List"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bListIndicators then self.wndMLSettings:FindChild("ShowIndicators"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bGroup then self.wndMLSettings:FindChild("GroupClass"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowLastItemBar then self.wndMLSettings:FindChild("ShowLastItemBar"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowLastItemTile then self.wndMLSettings:FindChild("ShowLastItemTile"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowCurrItemBar then self.wndMLSettings:FindChild("ShowCurrItemBar"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowCurrItemTile then self.wndMLSettings:FindChild("ShowCurrItemTile"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bAllowMulti then self.wndMLSettings:FindChild("AllowMultiItem"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bShowGuildBank then self.wndMLSettings:FindChild("ShowGuildBankEntry"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bDispBidding then self.wndMLSettings:FindChild("DispBiddingButtons"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bAppOnDemand then self.wndMLSettings:FindChild("DemandApp"):SetCheck(true) end
	if self.tItems["settings"]["ML"].bExcludeOOR then self.wndMLSettings:FindChild("ExcludeOOR"):SetCheck(true) end

	self.wndMLSettings:FindChild("GBManager"):SetText(self.tItems["settings"]["ML"].strGBManager)
end

function DKP:MLSettingsShowBiddingButtonEnable()
	self.tItems["settings"]["ML"].bDispBidding = true
end

function DKP:MLSettingsShowBiddingButtonDisable()
	self.tItems["settings"]["ML"].bDispBidding = false
end

function DKP:MLSettingsValueEnable()
	self.tItems["settings"]["ML"].bListIndicators = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsValueDisable()
	self.tItems["settings"]["ML"].bListIndicators = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsArrangeTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "Tiles" then self.tItems["settings"]["ML"].bArrTiles = true else self.tItems["settings"]["ML"].bArrTiles = false end
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowClassEnable()
	self.tItems["settings"]["ML"].bShowClass = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowClassDisable()
	self.tItems["settings"]["ML"].bShowClass = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsGroupEnable()
	self.tItems["settings"]["ML"].bGroup = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsGroupDisable()
	self.tItems["settings"]["ML"].bGroup = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSetDemandAppearEnable()
	self.tItems["settings"]["ML"].bAppOnDemand = true
end

function DKP:MLSetDemandAppearDisable()
	self.tItems["settings"]["ML"].bAppOnDemand = false
end

function DKP:MLSetExcludeOOREnable()
	self.tItems["settings"]["ML"].bExcludeOOR = true
end

function DKP:MLSetExcludeOORDisable()
	self.tItems["settings"]["ML"].bExcludeOOR = false
end

function DKP:MLSettingsShowCurrItemEnableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemBar = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowCurrItemDisableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemBar = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowCurrItemEnableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemTile = true
	self.tItems["settings"]["ML"].bShowLastItemTile = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowCurrItemDisableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowCurrItemTile = false
	Hook:OnMasterLootUpdate(true)
end
--
function DKP:MLSettingsShowLastItemEnableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemBar = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowLastItemDisableBar( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemBar = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowLastItemEnableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemTile = true
	self.tItems["settings"]["ML"].bShowCurrItemTile = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsShowLastItemDisableTile( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"]["ML"].bShowLastItemTile = false
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsDataTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "Values" then self.tItems["settings"]["ML"].bShowValues = true else self.tItems["settings"]["ML"].bShowValues = false end
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLSettingsClose()
	self.wndMLSettings:Show(false,false)
end

function DKP:MLSettingsLayoutTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "Horiz" then self.tItems["settings"]["ML"].bStandardLayout = true else self.tItems["settings"]["ML"].bStandardLayout = false end
end

function DKP:MLSettingsArrangeLootTypeChanged(wndHandler,wndControl)
	if wndControl:GetName() == "TilesLoot" then self.tItems["settings"]["ML"].bArrItemTiles = true else self.tItems["settings"]["ML"].bArrItemTiles = false end
	Hook:OnMasterLootUpdate(true)
end

function DKP:MLShowGuildBank()
	self.tItems["settings"]["ML"].bShowGuildBank = true
end

function DKP:MLShowGuildBankNot()
	self.tItems["settings"]["ML"].bShowGuildBank = false
end

function DKP:MLSetGBManager(wndHandler,wndControl,strText)
	self.tItems["settings"]["ML"].strGBManager = strText
end

function DKP:BidMLDisplayApplicableEnable()
	self.tItems["settings"]["ML"].bDisplayApplicable = true
	Hook:OnMasterLootUpdate(true)
end

function DKP:BidMLDisplayApplicableDisable()
	self.tItems["settings"]["ML"].bDisplayApplicable = false
	Hook:OnMasterLootUpdate(true)
end


--- ML Responses

function DKP:ResponsesClose( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end

function DKP:SendRequests( wndHandler, wndControl, eMouseButton )
	self.allResponses = ""
	self.wndMLResponses:FindChild("EditBox"):SetText(self.allResponses)
	self.wndMLResponses:Show(true,false)
	self.wndMLResponses:ToFront()
	if self.channel then
		self:Bid2PackAndSend({type = "WantConfirmation",ver = knMemberModuleVersion})
	end
end

function DKP:AddResponse(who)
	if self.allResponses == nil then self.allResponses = "" end
	self.allResponses = self.allResponses .. who .. "\n"
	self.wndMLResponses:FindChild("EditBox"):SetText(self.allResponses)
end

--- Customizable Labels

function DKP:BidCustomLabel1NameChanged(wndControl,wndHandler,strText)
	self.tItems["settings"]["Bid2"].tLabels[1] = strText
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel2NameChanged(wndControl,wndHandler,strText)
	self.tItems["settings"]["Bid2"].tLabels[2] = strText
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel3NameChanged(wndControl,wndHandler,strText)
	self.tItems["settings"]["Bid2"].tLabels[3] = strText
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabelsUpdate(bFirstOpened)
	if bFirstOpened == nil then bFirstOpened = false end
	for k,strLabel in ipairs(self.tItems["settings"]["Bid2"].tLabels) do
		self.wndBid2:FindChild("Legend"):FindChild("Label"..k):FindChild("Text"):SetText(strLabel)
	end
	if #self.ActiveAuctions > 0 then
		for k,auction in ipairs(self.ActiveAuctions) do
			for j,strLabel in ipairs(self.tItems["settings"]["Bid2"].tLabels) do
				auction.wnd:FindChild("Controls"):FindChild("Opt"..j):SetText(strLabel)
			end
			for j,bLabel in ipairs(self.tItems["settings"]["Bid2"].tLabelsState) do
				auction.wnd:FindChild("Controls"):FindChild("Opt"..j):Enable(bLabel)
			end
		end
	else
		for j,strLabel in ipairs(self.tItems["settings"]["Bid2"].tLabels) do
			self.wndBid2:FindChild("Auctions"):FindChild("Controls"):FindChild("Opt"..j):SetText(strLabel)
		end
		for j=1,4 do
			self.wndBid2:FindChild("Auctions"):FindChild("Controls"):FindChild("Opt"..j):Enable(bFirstOpened)
		end
	end
end

function DKP:BidCustomLabel1Enabled(wndControl,wndHandler)
	self.tItems["settings"]["Bid2"].tLabelsState[1] = true
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel1Disabled(wndControl,wndHandler)
	self.tItems["settings"]["Bid2"].tLabelsState[1] = false
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel2Enabled(wndControl,wndHandler)
	self.tItems["settings"]["Bid2"].tLabelsState[2] = true
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel2Disabled(wndControl,wndHandler)
	self.tItems["settings"]["Bid2"].tLabelsState[2] = false
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel3Enabled(wndControl,wndHandler)
	self.tItems["settings"]["Bid2"].tLabelsState[3] = true
	self:BidCustomLabelsUpdate()
end

function DKP:BidCustomLabel3Disabled(wndControl,wndHandler)
	self.tItems["settings"]["Bid2"].tLabelsState[3] = false
	self:BidCustomLabelsUpdate()
end


function DKP:BidCustomLabelRestore(wndControl,wndHandler)
	if self.tItems["settings"]["Bid2"].tLabels == nil then
		self.tItems["settings"]["Bid2"].tLabels =
		{
			[1] = "Need",
			[2] = "Slight Upgrade",
			[3] = "Greed",
		}
	end
	if self.tItems["settings"]["Bid2"].tLabelsState == nil then
		self.tItems["settings"]["Bid2"].tLabelsState =
		{
			[1] = true,
			[2] = true,
			[3] = true,
		}
	end
	for k,label in ipairs(self.tItems["settings"]["Bid2"].tLabels) do
		self.wndBid2Settings:FindChild("CustomLabels"):FindChild("Label"..k):SetText(label)
	end
	for k,labelState in ipairs(self.tItems["settings"]["Bid2"].tLabelsState) do
		self.wndBid2Settings:FindChild("CustomLabels"):FindChild("EnableLabel"..k):SetCheck(labelState)
	end
end

--- Bidding Queue

function DKP:BQInit()
	self.BQ = {}
end

function DKP:BQAddItem(wndHandler,wndControl)
	table.insert(self.BQ,wndControl:GetParent():GetData())

	if #self.BQ == 1 and not self.bIsBiddingPrep and not self.bIsBidding then
		Event_FireGenericEvent("RaidOpsChatBidding",self.BQ[1])
		self.BQ = {}
	end

	self:BQUpdateCounters()
end

function DKP:BQRemItem(wndHandler,wndControl)
	for k , bid in ipairs(self.BQ) do
		if bid.nLootId == wndControl:GetParent():GetData().nLootId then table.remove(self.BQ,k) end
	end

	self:BQUpdateCounters()
end

function DKP:BQUpdateCounters()
	if not self.BQ then return end

	local tIDsToRem = {}

	for j , bid in ipairs(self.BQ) do
		local bFound = false
		for k , child in ipairs(Hook.wndMLL:FindChild("Items"):GetChildren()) do
			if child:GetData().nLootId == bid.nLootId then bFound = true end
		end
		if not bFound then table.insert(tIDsToRem,j) end
	end

	for i=#tIDsToRem,1,-1 do
		table.remove(self.BQ,tIDsToRem[i])
	end

	for k , child in ipairs(Hook.wndMLL:FindChild("Items"):GetChildren()) do
		local bFound = false
		for j , bid in ipairs(self.BQ) do
			if bid.nLootId == child:GetData().nLootId then
				child:FindChild("BQCounter"):SetText(j)
				child:FindChild("ChatBidding"):SetCheck(true)
				bFound = true
			end
		end
		if not bFound then
			child:FindChild("BQCounter"):SetText("X")
			child:FindChild("ChatBidding"):SetCheck(false)
		end
		if self.wndBid:GetData() and self.wndBid:GetData().nLootId == child:GetData().nLootId then
			child:FindChild("NowBidding"):Show(true)
			child:FindChild("BQCounter"):SetText("")
		elseif not bFound then
			child:FindChild("BQCounter"):SetText("X")
			child:FindChild("NowBidding"):Show(false)
		end
	end

end

function DKP:BQNext()
	if #self.BQ > 0 then
		Event_FireGenericEvent("RaidOpsChatBidding",self.BQ[1])
		table.remove(self.BQ,1)
		self:BQUpdateCounters()
		self:BidCheckConditions()
	end
end
