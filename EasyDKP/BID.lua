-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

local Hook = Apollo.GetAddon("MasterLoot")
local DKP = Apollo.GetAddon("EasyDKP")

local kcrNormalText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrSelectedText = ApolloColor.new("ChannelAdvice")

local knMemberModuleVersion = 1.91

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

local umplauteConversions = {
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
	Apollo.RegisterEventHandler("MasterLootUpdate","BidUpdateItemDatabase", self)
	if Hook == nil then 
		self.wndMain:FindChild("CustomAuction"):Show(false)
		self.wndMain:FindChild("BidCustomStart"):Show(false)
		self.wndMain:FindChild("LabelAuction"):Show(false)
		self.wndHub:FindChild("NetworkBidding"):Enable(false)
		self.wndHub:FindChild("NetworkBidding"):SetTextColor("vdarkgray")
		Print("RaidOps - Could not find default Master Loot Addon - All Bidding/ML Functionalities are now suspended.")
		self:DSInit()
		return
	end
	

	bInitialized = true
	self.wait_timer:Stop()
	self:InitBid2()
	self:DSInit()
	
	if self.ItemDatabase == nil then
		self.ItemDatabase = {}
	end
	self:MLSettingsRestore()
	self.RegistredBidWinners = {}
	self.RegisteredWinnersByName = {}

	self.InsertedCountersList = {}
	self.SelectedLooterItem = nil
	self.SelectedMasterItem = nil

	if self.tItems["settings"]["ML"].bStandardLayout then
		self.wndInsertedSearch = Apollo.LoadForm(self.xmlDoc2,"InsertSearchBox",Hook.wndMasterLoot,self)
		self.wndInsertedMasterButton = Apollo.LoadForm(self.xmlDoc,"InsertMasterBid",Hook.wndMasterLoot,self)
		self.wndInsertedMasterButton:Enable(false)
		Hook.wndMasterLoot:FindChild("MasterLoot_LooterAssign_Header"):SetAnchorOffsets(5,84,-131,128)
		local l,t,r,b = Hook.wndMasterLoot:FindChild("Assignment"):GetAnchorOffsets()
		Hook.wndMasterLoot:FindChild("Assignment"):SetAnchorOffsets(l,t,r-225,b)

	else
		Hook.wndMasterLoot:Destroy()
		Hook.wndMasterLoot = Apollo.LoadForm(self.xmlDoc2,"MasterLootWindowVertLayout",nil,Hook)
		Hook.wndMasterLoot:SetSizingMinimum(579,559)
		Hook.wndMasterLoot:MoveToLocation(Hook.locSavedMasterWindowLoc)
		Hook.wndMasterLoot_ItemList = Hook.wndMasterLoot:FindChild("ItemList")
		Hook.wndMasterLoot_LooterList = Hook.wndMasterLoot:FindChild("LooterList")
		self.wndInsertedSearch = Apollo.LoadForm(self.xmlDoc2,"InsertSearchBox",Hook.wndMasterLoot,self)
		self.wndInsertedMasterButton = Apollo.LoadForm(self.xmlDoc2,"InsertBidButtonVert",Hook.wndMasterLoot,self)
		self.wndInsertedMasterButton:Enable(false)
		Hook.wndMasterLoot:FindChild("MasterLoot_LooterAssign_Header"):SetAnchorOffsets(37,238,-128,282)
		self.wndInsertedSearch:SetAnchorOffsets(-122,238,-40,282)
	end
	Hook.wndMasterLoot:SetSizingMinimum(800, 310)
	self.wndSlotValues = Apollo.LoadForm(self.xmlDoc2,"ItemValues",nil,self)
	self.wndSlotValues:Show(false,true)
	Hook.wndMasterLoot:FindChild("MasterLoot_Window_Title"):SetAnchorOffsets(48,27,-325,63)
	--Asc/Desc
	if self.tItems["settings"].BidSortAsc == nil then self.tItems["settings"].BidSortAsc = 1 end
	if self.tItems["settings"].BidMLSorting == nil then self.tItems["settings"].BidMLSorting = 1 end
	
	
	self.wndInsertedControls = Apollo.LoadForm(self.xmlDoc2,"InsertMLControls",Hook.wndMasterLoot,self)
	
	self.wndInsertedControls:FindChild("Window"):FindChild("Random"):Enable(false)
	
	if self.tItems["settings"].BidSortAsc == 1 then 
		self.wndInsertedControls:FindChild("Window"):FindChild("Asc"):SetCheck(true) 
	else 
		self.wndInsertedControls:FindChild("Window"):FindChild("Desc"):SetCheck(true) 
	end
	
	self.wndInsertedControls:FindChild("DispApplicable"):SetCheck(self.tItems["settings"]["ML"].bDisplayApplicable)
	if not self.tItems["settings"]["ML"].bSortByName then self.wndInsertedControls:FindChild("SortPR"):SetCheck(true) else self.wndInsertedControls:FindChild("SortName"):SetCheck(true) end

	self:HookToMasterLootDisp()
	self.PrevSelectedLooterItem = nil
	
	
	
	
	if self.tItems["BidSlots"] == nil then self.tItems["BidSlots"] = defaultSlotValues end
	self:BidFillInSlotValues()
	--BidValues
	if self.tItems["BidSlots"].Enable == 1 then self.wndSettings:FindChild("ButtonSettingsForceBidMinValues"):SetCheck(true) end

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
	
	if self.tItems["settings"].strBidMode == nil or self.tItems["settings"].strBidMode == "EPGP" then self.tItems["settings"].strBidMode = "ModeEPGP" end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild(self.tItems["settings"].strBidMode):SetCheck(true)
	
	if self.tItems["settings"].bWhisperRespond == nil then self.tItems["settings"].bWhisperRespond = true end
	self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild("WhisperResponse"):SetCheck(self.tItems["settings"].bWhisperRespond)
	
	self:BidCheckConditions()
	
	self.wndBid:FindChild("Grid"):AddEventHandler("GridSelChange","BidSelectWinner",self)
	
	self.GeminiLocale:TranslateWindow(self.Locale, self.wndBid)
	
	self.bIsBidding = false
	--Post Update To generate Labels for Main DKP window
	if self:LabelGetColumnNumberForValue("Item") ~= - 1 then self:LabelUpdateList() end
	
	--local test = Item.GetDataFromId(60434)
	---self:ExportShowPreloadedText(tohtml(test:GetDetailedInfo()))
	Apollo.RegisterEventHandler("ChatMessage","BidMessage",self)
	--self.tItems["settings"].strBidChannel = "/s "
	Hook.wndMasterLoot:Show(false,false)
end


function DKP:BidFillInSlotValues()
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Weapon"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue1"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Shield"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue2"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Head"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue3"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Shoulders"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue4"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Chest"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue5"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Hands"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue6"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Legs"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue7"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Feet"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue8"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Attachment"])
	self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue9"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Support"])
          self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue10"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Gadget"])
          self.wndSlotValues:FindChild("ItemCost"):FindChild("SlotValue11"):FindChild("Field"):SetText(self.tItems["BidSlots"]["Implant"])
end

function DKP:BidFixedPriceChanged(wndHandler,wndControl,strText)
	if tonumber(strText) ~= nil then
		self.tItems["BidSlots"][wndControl:GetParent():FindChild("Name"):GetText()] = tonumber(strText)
	else
		wndControl:SetText(self.tItems["BidSlots"][wndControl:GetParent():FindChild("Name"):GetText()])
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

function DKP:BidFixedMinShow()
	self.wndSlotValues:Show(true,false)
	self.wndSlotValues:ToFront()
end

function DKP:BidFixedMinClose()
	self.wndSlotValues:Show(false,false)
end

function DKP:BidSelectedChannelChanged( wndHandler, wndControl, eMouseButton )
	if wndControl:GetText() == "   Party" then self.tItems["settings"].strBidChannel = "/party " end
	if wndControl:GetText() == "   Guild" then self.tItems["settings"].strBidChannel = "/guild " end
end

--[[function DKP:BidSelectedChannelCheck( wndHandler, wndControl, eMouseButton )
	if wndControl:GetParent():FindChild("GuildMode"):IsChecked() == false and wndControl:GetParent():FindChild("PartyMode"):IsChecked() == false then
		wndControl:GetParent():FindChild("PartyMode"):SetCheck(true)
		self.tItems["settings"].strBidChannel = "/party "
	end
end]]

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


function DKP:BidCheckConditions()
	if self.bIsBidding then
		self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStart"):Enable(false)
		self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStop"):Enable(true)
	else
		self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStart"):Enable(true)
		self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonStop"):Enable(false)
	end
end

function DKP:BidSetSortAsc()
	self.tItems["settings"].BidSortAsc = 1
	self:BidMLSortPlayers()
end

function DKP:BidSetSortDesc()
	self.tItems["settings"].BidSortAsc = 0
	self:BidMLSortPlayers()
end

local prevLuckyChild
function DKP:BidRandomLooter()
	local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
	
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

function DKP:BidMLSearch(wndHandler,wndControl)
	if self.wndInsertedSearch:GetText() ~= "Search..." then
		local children = Hook.wndMasterLoot:FindChild("LooterList"):GetChildren()
		
		for k,child in ipairs(children) do
			child:Show(true,true)
		end
		
		for k,child in ipairs(children) do
			if not self:string_starts(child:FindChild("CharacterName"):GetText(),self.wndInsertedSearch:GetText()) then child:Show(false,true) end
		end
		
		if wndControl ~= nil and wndControl:GetText() == "" then wndControl:SetText("Search...") end
		
		if self.tItems["settings"]["ML"].bArrTiles then
			Hook.wndMasterLoot_LooterList:ArrangeChildrenTiles()
		else
			Hook.wndMasterLoot_LooterList:ArrangeChildrenVert()
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
	local HookML = Apollo.GetAddon("MasterLoot")
	local DKPInstance = Apollo.GetAddon("EasyDKP")
	if HookML.tMasterLootSelectedItem and HookML.tMasterLootSelectedItem.itemDrop then
		DKPInstance.SelectedMasterItem = HookML.tMasterLootSelectedItem.itemDrop:GetName()
		DKPInstance.wndInsertedMasterButton:Enable(true)
		DKPInstance.wndInsertedControls:FindChild("Window"):FindChild("Random"):Enable(true)
	end
end

function DKP:StartChatBidding(tCustomData)
	if self.bIsBidding == false then
		self.wndBid:FindChild("Grid"):DeleteAll()
		if tCustomData == nil then
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("HeaderItem"):SetText(self.SelectedMasterItem)
			if self.ItemDatabase[self.SelectedMasterItem] ~= nil then
				self.CurrentItemChatStr = self.ItemDatabase[self.SelectedMasterItem].strChat
				self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIcon"):SetSprite(self.ItemDatabase[self.SelectedMasterItem].sprite)
				local item = Item.GetDataFromId(self.ItemDatabase[self.SelectedMasterItem].ID)
				self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIconFrame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
				Tooltip.GetItemTooltipForm(self, self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ItemIcon") , item , {bPrimary = true, bSelling = false})
			end
		else
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("HeaderItem"):SetText(tCustomData.strItem)
			self.CurrentItemChatStr = nil
		end
		
		if self.CurrentItemChatStr == nil then 
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonLink"):Enable(false)
		else 
			self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("ButtonLink"):Enable(true) 
		end
		self.wndBid:Show(true,false)
		self:BidCheckConditions()
		self:BidUpdateLastWinner()
	else
		self.wndBid:Show(true,false)
	end
end

function DKP:BidSetUpWindow(tCustomData,wndControl,eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self:StartChatBidding()
	else
		self:BidAddNewAuction(self.ItemDatabase[self.SelectedMasterItem].ID)
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

function DKP:BitSetCountdown( wndHandler, wndControl, eMouseButton )
	local val = tonumber(strText)
	if val and val < 10 and val > 0 then
		self.tItems["settings"].BidMin = val
	else
		wndControl:SetText(self.tItems["settings"].BidMin) 
	end
end

function DKP:BidSetMode(wndHandler,wndControl)
	if self.bIsBidding then 
		self.wndBid:FindChild("ControlsContainer"):FindChild("Modes"):FindChild(self.tItems["settings"].strBidMode):SetCheck(true)
		wndControl:SetCheck(false)
	else
		self.tItems["settings"].strBidMode = wndControl:GetName()
	end
end

function DKP:BidStart(strName)
	self.CurrentBidSession = nil
	self.CurrentBidSession = {}
	self.CurrentBidSession.Bidders = {}
	self.CurrentBidSession.strItem = self.wndBid:FindChild("ControlsContainer"):FindChild("Header"):FindChild("HeaderItem"):GetText()
	--self.CurrentItemChatStr = "{Link}"
	self.bIsBidding = true
	self:BidCheckConditions()
	self:BidUpdateBiddersList()
	self:BidUpdateLastWinner()
	Print(#self.CurrentBidSession.Bidders)
	if self.tItems["settings"].strBidMode == "ModeOpenDKP" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:DKPOpen"],self.CurrentItemChatStr,self.tItems["settings"].strBidChannel,tostring(self.tItems["settings"].BidMin)))
	elseif self.tItems["settings"].strBidMode == "ModeHiddenDKP" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel ..  string.format(self.Locale["#biddingStrings:DKPHidden"],self.CurrentItemChatStr,GameLib.GetPlayerUnit():GetName(),tostring(self.tItems["settings"].BidMin)))
	elseif self.tItems["settings"].strBidMode == "ModePureRoll" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:roll"],self.CurrentItemChatStr))
	elseif self.tItems["settings"].strBidMode == "ModeModifiedRoll" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:modifiedRoll"],self.CurrentItemChatStr,tostring(self.tItems["settings"].BidRollModifier)))
	elseif self.tItems["settings"].strBidMode == "ModeEPGP" then
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:EPGP"],self.CurrentItemChatStr,self.tItems["settings"].strBidChannel))
		if self.tItems["settings"].BidAllowOffspec == 1 then 
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:EPGPoffspec"],tostring(self.tItems["settings"].BidEPGPOffspec)))
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
	
	if tData.strMsg == "!off" and self.tItems["settings"].BidAllowOffspec == 1 or tData.strMsg == "!bid" then
		local ID = self:GetPlayerByIDByName(tData.strSender)
		if ID ~= -1 then
			local bAlreadyBid = false
			local bidID
			for k,bidder in ipairs(self.CurrentBidSession.Bidders) do
				if tData.strSender == bidder.strName then
					bAlreadyBid = true
					bidID = k
					break
				end
			end
			
			if not bAlreadyBid then
				local newBidder = {}
				newBidder.nBid = (tData.strMsg == "!off" and tonumber(self:EPGPGetPRByName(tData.strSender)) * ((100-self.tItems["settings"].BidEPGPOffspec)/100) or tonumber(self:EPGPGetPRByName(tData.strSender)))
				newBidder.strName = tData.strSender
				newBidder.offspec = (tData.strMsg == "!off" and true or false)
				table.insert(self.CurrentBidSession.Bidders,newBidder)
				strReturn = "Processed"
			elseif bidID and not self.CurrentBidSession.Bidders[bidID].offspec and tData.strMsg == "!off" then
				self.CurrentBidSession.Bidders[bidID].offspec = true
				self.CurrentBidSession.Bidders[bidID].nBid = tonumber(self:EPGPGetPRByName(tData.strSender)) * ((100-self.tItems["settings"].BidEPGPOffspec)/100)
				strReturn = "Processed"
			elseif bidID and tData.strMsg ~= "!off" then
				strReturn = "Bid removed"	
				self.CurrentBidSession.Bidders[bidID] = nil
				if self.CurrentBidSession.nSelected == bidID then self.CurrentBidSession.nSelected = nil end
			elseif self.CurrentBidSession.Bidders[bidID].offspec and tData.strMsg == "!off" then
				strReturn = "Offspec flag removed"
				self.CurrentBidSession.Bidders[bidID].offspec = false
				self.CurrentBidSession.Bidders[bidID].nBid = tonumber(self:EPGPGetPRByName(tData.strSender))
			end
			self:BidUpdateBiddersList()
		end
	end
	
	return strReturn
end

function DKP:BidProcessMessageRoll(tData)
	local strReturn = -1
	
	local words = {}
	for word in string.gmatch(tData.strMsg,"%S+") do
		table.insert(words,word)
	end
	
	if #words < 5 then 
		return strReturn
	end
	if words[5] ~= "(1-100)" then
		strReturn = strRoller.. " Wrong range"
		return strReturn
	end
	
	
		local strRoller = words[1] .. " " .. words[2]
		local ID = self:GetPlayerByIDByName(strRoller)
		for k,bidder in ipairs(self.CurrentBidSession.Bidders) do
			if bidder.strName == strRoller then
				strReturn = strRoller.." Already Rolled"
				return strReturn
			end
		end
		
		local roll = tonumber(words[4])
		local newBidder = {}
		newBidder.strName = strRoller
		if self.tItems["settings"].strBidMode == "ModePureRoll" then
			newBidder.nBid = roll
		elseif self.tItems["settings"].strBidMode == "ModeModifiedRoll" then
			newBidder.nBid = roll + math.floor(math.abs(self.tItems[ID].EP) * (self.tItems["settings"].BidRollModifier/100))
			newBidder.mod = math.floor(math.abs(self.tItems[ID].EP) * (self.tItems["settings"].BidRollModifier/100))
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
	local strReturn
	
	if self.CurrentBidSession.HighestBidEver == nil then
		self.CurrentBidSession.HighestBidEver = {}
		self.CurrentBidSession.HighestBidEver.value = 0
		self.CurrentBidSession.HighestBidEver.strName = ""
	end

	
	if tonumber(tData.strMsg) == nil and tData.strMsg ~= "!off" then return -1 end
	
	
	local nBidderID = 0
	
	for k,bidder in ipairs(self.CurrentBidSession.Bidders) do
		if bidder.strName == tData.strSender then
			nBidderID = k
			break
		end
	end
	
	if nBidderID == 0 then
		local newBidder = {}
		newBidder.HighestBid = 0
		newBidder.strName = tData.strSender
		newBidder.offspec= false
		
		if tonumber(tData.strMsg) == nil and tData.strMsg == "!off" then
			if self.tItems["settings"].BidAllowOffspec == 1 then
				newBidder.offspec = true
				strReturn = "Offspec mode"
			else
				strReturn = "Offspec is not allowed"
			end
		else
			if self:GetPlayerByIDByName(tData.strSender) ~= - 1 and tonumber(tData.strMsg) > tonumber(self.tItems[self:GetPlayerByIDByName(tData.strSender)].net) then return "You don't have enough DKP." end
			
			local modifier = tonumber(tData.strMsg) - self.CurrentBidSession.HighestBidEver.value
			if modifier > self.tItems["settings"].BidOver and tonumber(tData.strMsg) > self.tItems["settings"].BidMin then 
				newBidder.nBid = tonumber(tData.strMsg)
				if newBidder.nBid > self.CurrentBidSession.HighestBidEver.value then
					self.CurrentBidSession.HighestBidEver.value = newBidder.nBid
					self.CurrentBidSession.HighestBidEver.name = newBidder.strName
				end
					strReturn = "Bid processed"
			else
				if tonumber(tData.strMsg) < self.tItems["settings"].BidMin then
					strReturn = "Failure - Minimum Bid value hasn't been reached"
				else
					strReturn = "Failure - too small difference"
				end
			end
		end
		table.insert(self.CurrentBidSession.Bidders,newBidder)	
	else
		if tonumber(tData.strMsg) == nil and tData.strMsg == "!off" then
			if self.tItems["settings"].BidAllowOffspec == 1 then
				self.CurrentBidSession.Bidders[nBidderID].offspec = true
				strReturn = "Offspec mode"
			else
				strReturn = "Offspec is not allowed"
			end
		else
			if self:GetPlayerByIDByName(tData.strSender) ~= - 1 and tonumber(tData.strMsg) > tonumber(self.tItems[self:GetPlayerByIDByName(tData.strSender)].net) then return "You don't have enough DKP." end
			
			local modifier = tonumber(tData.strMsg) - self.CurrentBidSession.HighestBidEver.value
			if modifier > self.tItems["settings"].BidOver and tonumber(tData.strMsg) > self.tItems["settings"].BidMin and self.CurrentBidSession.Bidders[nBidderID].nBid < tonumber(tData.strMsg) then 
				self.CurrentBidSession.Bidders[nBidderID].nBid = tonumber(tData.strMsg)
				if self.CurrentBidSession.Bidders[nBidderID].nBid > self.CurrentBidSession.HighestBidEver.value then
					self.CurrentBidSession.HighestBidEver.value = self.CurrentBidSession.Bidders[nBidderID].nBid
					self.CurrentBidSession.HighestBidEver.name = self.CurrentBidSession.Bidders[nBidderID].strName
				end
					strReturn = "Bid processed"
			else
				if tonumber(tData.strMsg) < self.tItems["settings"].BidMin then
					strReturn = "Failure - Minimum Bid value hasn't been reached"
				else
					strReturn = "Failure - too small difference"
				end
			end
		end
	end
	self:BidUpdateBiddersList()
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
  return a.value > b.value
end

function DKP:BidUpdateBiddersList()
	if not self.bIsBidding then return end
	local grid = self.wndBid:FindChild("MainFrame"):FindChild("Grid")
	grid:DeleteAll()
	
	for k,bidder in ipairs(self.CurrentBidSession.Bidders) do
		grid:AddRow(k)
		grid:SetCellData(k,1,bidder.strName,"",k)
		grid:SetCellData(k,2,bidder.nBid,"",k)
		if self.tItems["settings"].strBidMode ~= "ModeModifiedRoll" then
			grid:SetCellData(k,3,bidder.offspec and "Offspec" or "","",k)
		else
			grid:SetCellData(k,3,"Modifier " .. bidder.mod,"",k)
		end
		if self.CurrentBidSession.nSelected and self.CurrentBidSession.nSelected == k then
			grid:SetCellData(k,1,"--> " .. bidder.strName .. " <--","",k)
		end
		
	end
	
	grid:SetSortColumn(2)
end

function DKP:BidInitCountdown()
	self.BidCounter = 0
	self.BidCountdown = ApolloTimer.Create(1,true,"BidPerformCountdown",self)
	Apollo.RegisterTimerHandler("BidPerformCountdown","BidPerformCountdown",self)
	ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. " [ChatBidding] " .. self.tItems["settings"].BidCount)
end

function DKP:BidPerformCountdown()
	self.BidCounter = self.BidCounter + 1
	if self.BidCounter == self.tItems["settings"].BidCount then
		self.BidCountdown:Stop()
		Apollo.RemoveEventHandler("BidPerformCountdown",self)
		
		if self.CurrentBidSession.nSelected then
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:AuctionEndWinner"],self.CurrentBidSession.Bidders[self.CurrentBidSession.nSelected].strName))
		else
			ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. self.Locale["#biddingStrings:AuctionEnd"])
		end
		self.CurrentBidSession = {}
		self.bIsBidding = false
		self:BidCheckConditions()
	else
		ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. " [ChatBidding] " .. tostring(self.tItems["settings"].BidCount - self.BidCounter) .. "...")
	end
end

function DKP:BidSelectWinner(wndHandler,wndControl,iRow,iCol)
	if self.CurrentBidSession.nSelected and self.CurrentBidSession.nSelected == self.wndBid:FindChild("Grid"):GetCellData(iRow,iCol) then self.CurrentBidSession.nSelected = nil else
	self.CurrentBidSession.nSelected = self.wndBid:FindChild("Grid"):GetCellData(iRow,iCol) end
	self:BidUpdateBiddersList()
end

function DKP:BidAssignItem(wndHandler,wndControl)
	local bMaster = true
	
	if not self.CurrentBidSession or not self.CurrentBidSession.nSelected then return end
	
	if bMaster then
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
			if string.lower(child:FindChild("CharacterName"):GetText()) == string.lower(self.CurrentBidSession.Bidders[self.CurrentBidSession.nSelected].strName) then
				selectedOne = child
				if wndControl:GetText() == "Select" then child:SetCheck(true) end
				break
			end
		end
		children = Hook.wndMasterLoot_ItemList:GetChildren()
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
		if not selectedOne or not selectedItem then return end
		if wndControl:GetText() == "Select" then Hook.wndMasterLoot:FindChild("Assignment"):Enable(true) end
		Hook.tMasterLootSelectedLooter = selectedOne:GetData()
		Hook.tMasterLootSelectedItem = selectedItem
		
		 
		if wndControl:GetText() == "Assign" then 
			if self.bIsBidding then 
				ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. string.format(self.Locale["#biddingStrings:AuctionEndEarly"],selectedOne:GetData():GetName()))
				self.bIsBidding = false
				self:BidCheckConditions()
			end
			Hook:OnAssignDown() 
		end
		
		self.tItems["settings"].tLastChatWinner = {}
		self.tItems["settings"].tLastChatWinner.nItem = selectedItem.itemDrop:GetItemId()
		self.tItems["settings"].tLastChatWinner.strWinner = selectedOne:GetData():GetName()
		self:BidUpdateLastWinner()
	end
end

function DKP:BidUpdateLastWinner()
	if self.tItems["settings"].tLastChatWinner == nil or #self.tItems["settings"].tLastChatWinner > 1 then return end
	local wnd = self.wndBid:FindChild("ControlsContainer"):FindChild("LastWinner")
	wnd:FindChild("LastWinnerStr"):SetText(self.tItems["settings"].tLastChatWinner.strWinner)
	
	local item = Item.GetDataFromId(self.tItems["settings"].tLastChatWinner.nItem)
	if not item then return end
	wnd:FindChild("ItemIcon"):SetSprite(item:GetIcon())
	wnd:FindChild("ItemIconFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
	wnd:FindChild("Item"):SetText(item:GetName())
	Tooltip.GetItemTooltipForm(self, wnd:FindChild("ItemIcon") , item , {bPrimary = true, bSelling = false})
end

function DKP:BidClose()
	self.wndBid:Show(false,false)
	if self.bIsBidding == true then
		Print("In order to show this window again type /dkpbid")
	end
end

function DKP:BidOpen()
	if self.bIsBidding == true then
		self.wndBid:Show(true,false)
	else
		Print("You can enable this window only during bidding")
	end
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


function DKP:GetPlayerByIDByName(strName)

	local strPlayer = ""
	for uchar in string.gfind(strName, "([%z\1-\127\194-\244][\128-\191]*)") do
		if umplauteConversions[uchar] then uchar = umplauteConversions[uchar] end
		strPlayer = strPlayer .. uchar
	end
	strName = strPlayer
	
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(strName) then return i end
	end
	
	for j,alt in pairs(self.tItems["alts"]) do
		if string.lower(strName) == string.lower(j) then return self.tItems["alts"][j] end
	end

	
	return -1
end



---------------------------------------------------------------------------------------------------
-- TradingUI Functions
---------------------------------------------------------------------------------------------------

function DKP:TradeInit()
	self.wndTrade = Apollo.LoadForm(self.xmlDoc,"TradingUI",nil,self)
	self.wndTrade:Show(false,true)
	self:TradeRestore()
	if self.tItems["trades"] == nil then
		self.tItems["trades"] = {}
	end
	self.wndTrades = {}
	self.wndTradeList = self.wndTrade:FindChild("MainFrame"):FindChild("TransactionList")
	--self.wndTradeList:SetSizingMinimum(920, 369)
	--self.wndTradeList:SetSizingMaximum(920, 500)
end

function DKP:TradeRestore()
	if self.tItems["settings"].TradePeriod == nil then
		self.tItems["settings"].TradePeriod = "w"
	end
	
	if self.tItems["settings"].TradeEnable == nil then
		self.tItems["settings"].TradeEnable = 0
	end
	if self.tItems["settings"].TradeCap ~= nil then
		self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("Cap"):SetText(self.tItems["settings"].TradeCap)
	end
	
		if self.tItems["settings"].TradePeriod == "w" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Weekly"):SetCheck(true)
		elseif self.tItems["settings"].TradePeriod == "m" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Monthly"):SetCheck(true)
		elseif self.tItems["settings"].TradePeriod == "d" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Daily"):SetCheck(true)
		elseif self.tItems["settings"].TradePeriod == "n" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Never"):SetCheck(true)
		end
	
	if self.tItems["settings"].TradeMasterConf == nil then self.tItems["settings"].TradeMasterConf = 1 end 
	if self.tItems["settings"].TradeMasterConf == 1 then
		self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("Second"):SetCheck(true)
	end	
	
	if self.tItems["settings"].ConnectedCap == nil then self.tItems["settings"].ConnectedCap = 1 end 
	if self.tItems["settings"].ConnectedCap == 1 then
		self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("Connect"):SetCheck(true)
	end	
	
	if self.tItems["settings"].TradeEnable == 1 then
		self.wndTrade:FindChild("ControlsContainer"):FindChild("Enable"):SetCheck(true)
	end
	self:TradeUpdateTimer()
	self:TradeUpdateHelp()
end

function DKP:TradeCapPeriodResetChanged( wndHandler, wndControl, eMouseButton )
	if wndControl:GetText() == "Weekly" then
		self.tItems["settings"].TradePeriod = "w"
	elseif wndControl:GetText() == "Monthly" then
		self.tItems["settings"].TradePeriod = "m"
	elseif wndControl:GetText() == "Daily" then
		self.tItems["settings"].TradePeriod = "d"
	elseif wndControl:GetText() == "Never" then
		self.tItems["settings"].TradePeriod = "n"
	end
	self:TradeUpdateTimer()
end

function DKP:TradeCheckPeriod( wndHandler, wndControl, eMouseButton )
	if self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Daily"):IsChecked() == false and self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Weekly"):IsChecked() == false and self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Monthly"):IsChecked() == false and self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Never"):IsChecked() == false then
		if self.tItems["settings"].TradePeriod == "w" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Weekly"):SetCheck(true)
		elseif self.tItems["settings"].TradePeriod == "m" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Monthly"):SetCheck(true)
		elseif self.tItems["settings"].TradePeriod == "d" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Daily"):SetCheck(true)
		elseif self.tItems["settings"].TradePeriod == "n" then
			self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("ResetPeriod"):FindChild("Never"):SetCheck(true)
		end
	end
	self:TradeUpdateTimer()
end

function DKP:TradeEnable( wndHandler, wndControl, eMouseButton )
	if self.tItems["settings"].TradeCap ~= nil then
		self.tItems["settings"].TradeEnable = 1
		self:TradeApplyCap()
		self:TradeUpdateTimer()
	else
		wndControl:SetCheck(false)
		Print("Set Cap value first")
	end
end

function DKP:TradeDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].TradeEnable = 0
	self:TradeRemoveCap()
	self:TradeUpdateTimer()
end

function DKP:TradeResetCap( wndHandler, wndControl, eMouseButton )
	self:TradeApplyCap()
end

function DKP:TradeClose( wndHandler, wndControl, eMouseButton )
	self.wndTrade:Show(false,false)
end


function DKP:TradeShow( wndHandler, wndControl, eMouseButton )
	self.wndTrade:Show(true,false)
	self:TradePopulateTrades()
	self.wndTrade:ToFront()
end


function DKP:TradeChangeCapValue( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["settings"].TradeCap = math.abs(tonumber(strText))
	elseif strText == "INF" then
		self.tItems["settings"].TradeCap = "inf"
		self:TradeRemoveCap()
	else
		wndControl:SetText("Cap")
		self.tItems["settings"].TradeCap = nil
	end
end

function DKP:TradeApplyCap()
	if self.tItems["settings"].TradeEnable == 1 and self.tItems["settings"].TradeCap ~= nil and self.tItems["settings"].TradeCap ~= "inf" then
		for i=1,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil then
				self.tItems[i].TradeCap = self.tItems["settings"].TradeCap
			end
		end
	end
end

function DKP:TradeRemoveCap()
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i]~=nil then
			self.tItems[i].TradeCap = nil
		end
	end
end

function DKP:TradeUpdateTimer()
	if self.tItems["settings"].TradeEnable == 1 and self.tItems["settings"].TradePeriod ~= "n" then 
		if self.tItems["settings"].TradeStart == nil and self.tItems["settings"].TradePeriod ~= "n" then
			self.tItems["settings"].TradeStart = os.time()
		end
		
		local diff = os.difftime(os.time() - self.tItems["settings"].TradeStart)
		diff = os.date("*t",diff)
		if self.tItems["settings"].TradePeriod == "w" then
			if diff.day >= 6 and diff.day < 7 then
				self.TradeTimerVar = ApolloTimer.Create(60, true, "TradeTimer", self)
				Apollo.RegisterTimerHandler(60, "TradeTimer", self)
			elseif diff.day >= 7 then
				self:TradeApplyCap()
				self.tItems["settings"].TradeStart = nil
				self:TradeUpdateTimer()
			end
		elseif self.tItems["settings"].TradePeriod == "m" then
			if diff.day >= 29 and diff.day < 30 then
				self.TradeTimerVar = ApolloTimer.Create(60, true, "TradeTimer", self)
				Apollo.RegisterTimerHandler(60, "TradeTimer", self)
			elseif diff.day >= 30 then
				self:TradeApplyCap()
				self.tItems["settings"].TradeStart = nil
				self:TradeUpdateTimer()
			end
		elseif self.tItems["settings"].TradePeriod == "d" then
			if diff.day >= 1 and diff.day < 2 then	
				self.TradeTimerVar = ApolloTimer.Create(60, true, "TradeTimer", self)
				Apollo.RegisterTimerHandler(60, "TradeTimer", self)
			elseif diff.day >= 2 then
				self:TradeApplyCap()
				self.tItems["settings"].TradeStart = nil
				self:TradeUpdateTimer()
			end
		end
	else
		if self.TradeTimerVar ~= nil then
			self.TradeTimerVar:Stop()
		end
	end
	self:TradeUpdateHelp()
end

function DKP:TradeUpdateHelp()
	local tooltip = "Next Cap Reset"
	
	if self.tItems["settings"].TradeEnable == 1 and self.tItems["settings"].TradeStart ~= nil and self.tItems["settings"].TradeCap ~= nil then
		local diff = os.difftime(os.time() - self.tItems["settings"].TradeStart)
		diff = os.date("*t",diff)
		local daysLeft
		if self.tItems["settings"].TradePeriod == "w" then
			if diff.day == 6 then
				tooltip = tooltip .. " in " .. tostring(24 - diff.hour) .. "Hours."
			else
				daysLeft = 7 - diff.day
				tooltip = tooltip .. " in " .. daysLeft .. "days."
			end
		elseif self.tItems["settings"].TradePeriod == "m" then
			if diff.day == 29 then
				tooltip = tooltip .. " in " .. tostring(24 - diff.hour) .. "Hours"
			else
				daysLeft = 30 - diff.day
				tooltip = tooltip .. " in " .. daysLeft .. "days."
			end
		elseif self.tItems["settings"].TradePeriod == "n" then
			tooltip = "Never"
		elseif self.tItems["settings"].TradePeriod == "d" then
				tooltip = tooltip .. " in " .. tostring(24 - diff.hour) .. "Hours"
		end
	else
		tooltip = "Disabled"
	end
	
	
	self.wndTrade:FindChild("ControlsContainer"):FindChild("Settings"):FindChild("Help"):SetTooltip(tooltip)
end

function DKP:TradeTimer()
	local diff = os.difftime(os.time() - self.tItems["settings"].TradeStart)
		diff = os.date("*t",diff)
	if self.tItems["settings"].TradePeriod == "w" then
		if diff.day >= 7 then
			self:Decay()
			self.tItems["settings"].TradeStart = nil
			self:TradeUpdateTimer()
			self.TradeTimerVar:Stop()
		end
	elseif self.tItems["settings"].TradePeriod == "m" then
		if diff.day >= 30 then
			self:Decay()
			self.tItems["settings"].TradeStart = nil
			self:TradeUpdateTimer()
			self.TradeTimerVar:Stop()
		end	
	elseif self.tItems["settings"].TradePeriod == "d" then
		if diff.day >= 2 then
			self:Decay()
			self.tItems["settings"].TradeStart = nil
			self:TradeUpdateTimer()
			self.TradeTimerVar:Stop()
		end	
	end
end

function DKP:TradeProcessMessage(tWords,strSender) -- [1] - !trade - [2]-- From - [3] -- from [4]-to [5]-to  [6] -Amount ||  Decline/Accept
	if #tWords < 6 then return end
	
	if tonumber(tWords[6]) ~= nil then
		local fullSender = tWords[2] .. " " .. tWords[3]
		local fullRecipent = tWords[4] .. " " .. tWords[5]
		local fromID = self:GetPlayerByIDByName(fullSender)
		local toID = self:GetPlayerByIDByName(fullRecipent)
		if fromID == -1 or toID == -1 then return end
		if string.lower(fullSender) ~= string.lower(strSender) then return end
		local strResult = self:TradeRegisterNewTrade(fromID,toID,tonumber(tWords[6]))
		
		if strResult == "Trade Submitted" then
			ChatSystemLib.Command("/w " .. self.tItems[fromID].strName .. " Trade Submitted")
			ChatSystemLib.Command("/w " .. self.tItems[toID].strName .. " You have new pending trade")
		else
			ChatSystemLib.Command("/w " .. self.tItems[fromID].strName .. " " .. strResult)
		end
	elseif string.lower(tWords[6]) == "accept" then
		--match request with specific trade
		local fullSender = tWords[2] .. " " .. tWords[3]
		local fullRecipent = tWords[4] .. " " .. tWords[5]
		local reqID = nil

		-- authentication
		if string.lower(fullRecipent) ~= string.lower(strSender) then return end
		
		for i=1,table.maxn(self.tItems["trades"]) do
			if self.tItems["trades"][i] ~= nil then
				if string.lower(self.tItems["trades"][i].strSender) == string.lower(fullSender) and string.lower(self.tItems["trades"][i].strRecipent) == string.lower(fullRecipent) then
					if self.tItems["trades"][i].status.recipent == "Pending" then
						reqID = i
						break
					end
				end
			end
		end
		

		
		if reqID ~= nil then
			self.tItems["trades"][reqID].status.recipent = "OK"
			self:TradeCheckTrade(reqID)
			ChatSystemLib.Command("/w " .. fullSender .. " Your Trade has been accepted by recipent")
			ChatSystemLib.Command("/w " .. fullRecipent .. " You have accepted this trade")
			if self.wndTrade:IsShown() == true then
				self:TradePopulateTrades()
			end
		else
			ChatSystemLib.Command("/w " .. fullRecipent .. " Cannot find trade you want to accept")
		end
	
	elseif string.lower(tWords[6]) == "decline" then
		--match request with specific trade
		local fullSender = tWords[2] .. " " .. tWords[3]
		local fullRecipent = tWords[4] .. " " .. tWords[5]
		local reqID = nil
		
		if string.lower(fullRecipent) ~= string.lower(strSender) then return end
		
		for i=1,table.maxn(self.tItems["trades"]) do
			if self.tItems["trades"][i] ~= nil then
				if string.lower(self.tItems["trades"][i].strSender) == string.lower(fullSender) and string.lower(self.tItems["trades"][i].strRecipent) == string.lower(fullRecipent) then
					if self.tItems["trades"][i].status.recipent == "Pending" then
						reqID = i
						break
					end
				end
			end
		end
		if reqID ~= nil then
			self.tItems["trades"][reqID].status.recipent = "Rejected"
			self:TradeCheckTrade(reqID)
			ChatSystemLib.Command("/w " .. fullSender .. " Your Trade has been rejected by recipent")
			ChatSystemLib.Command("/w " .. fullRecipent .. " You have rejected this trade")
			if self.wndTrade:IsShown() == true then
				self:TradePopulateTrades()
			end
		else
			ChatSystemLib.Command("/w " .. fullRecipent .. " Cannot find trade you want to reject")
		end
	end
	self:TradePopulateTrades()

end

function DKP:TradeCheckTrade(ofID)
	if self.tItems["trades"][ofID].done == nil then
		if self.tItems["trades"][ofID].status.recipent == "OK" and self.tItems["trades"][ofID].status.master == "OK" or self.tItems["trades"][ofID].status.recipent == "OK" and self.tItems["trades"][ofID].masterConf == 0 then
			self.tItems["trades"][ofID].done = true
			self:Trade(ofID)
		elseif self.tItems["trades"][ofID].status.recipent == "Rejected" or self.tItems["trades"][ofID].status.master == "Rejected" then
			self.tItems["trades"][ofID].done = false
			ChatSystemLib.Command("/w " .. self.tItems["trades"][ofID].strSender .. " Your Trade has been rejected")
			if self.tItems["trades"][ofID].status.recipent == "OK" then
				ChatSystemLib.Command("/w " .. self.tItems["trades"][ofID].strRecipent .. " Your Trade has been rejected")
			end	
		end
	end
	
end

function DKP:Trade(ofID)
	local fromID = self:GetPlayerByIDByName(self.tItems["trades"][ofID].strSender)
	local toID = self:GetPlayerByIDByName(self.tItems["trades"][ofID].strRecipent)
	
	self.tItems[fromID].net = self.tItems[fromID].net - self.tItems["trades"][ofID].value
	self.tItems[fromID].tot = self.tItems[fromID].tot - self.tItems["trades"][ofID].value
	self.tItems[fromID].TradeCap = self.tItems[fromID].TradeCap - self.tItems["trades"][ofID].value
	self.tItems[toID].net = self.tItems[toID].net + self.tItems["trades"][ofID].value
	self.tItems[toID].tot = self.tItems[toID].tot + self.tItems["trades"][ofID].value
	if self.tItems["settings"].ConnectedCap == 1 then
		self.tItems[toID].TradeCap = self.tItems[toID].TradeCap - self.tItems["trades"][ofID].value
	end
	
	ChatSystemLib.Command("/w " .. self.tItems["trades"][ofID].strSender .. "Your trade has been completed")
	ChatSystemLib.Command("/w " .. self.tItems["trades"][ofID].strRecipent .. "Your trade has been completed")

end

function DKP:TradeRegisterNewTrade(fromID,toID,value)
	local strReturn = ""
	
	if self.tItems[fromID] ~= nil and self.tItems[toID] ~= nil then
		-- check cap
		if self.tItems["settings"].TradeCap ~= "inf" then
			local modifier = self.tItems[fromID].TradeCap - value
			if modifier < 0 then
				strReturn = "Your have already used your cap"
				return strReturn
			end
		end
		-- check whether sender has DKP at allowed
		modifier = self.tItems[fromID].net - value
		if modifier < 0 then 
			strReturn = "You don't have enough DKP"
			return strReturn
		end
		-- if enabled check whether recipent have enough cap
		
		if self.tItems["settings"].ConnectedCap == 1 and self.tItems["settings"].TradeCap ~= "inf" then
			modifier = self.tItems[toID].TradeCap - value
			if modifier < 0 then
				strReturn = "Recipent's cap is too low"
				return strReturn
			end
		end
		-- search whether there's another trade with this player
		local isAnotherTrade = false
		for i=1,table.maxn(self.tItems["trades"]) do
			if self.tItems["trades"][i] ~= nil then
				if self.tItems["trades"][i].strSender == self.tItems[fromID].strName and self.tItems["trades"][i].strRecipent == self.tItems[i].strName then
					if self.tItems["trades"][i].status.recipent == "Pending" or  self.tItems["trades"][i].status.master == "Pending" then
						isAnotherTrade = true
						break
					end
				end
			end
		end
		
		if isAnotherTrade == true then
			strReturn = "You already have pending trade with this player"
			return strReturn
		end
		
		
		-- Passed
		local trade = {}
		trade.strSender = self.tItems[fromID].strName
		trade.strRecipent = self.tItems[toID].strName
		local tradeDate = os.date("*t",os.time())
		trade.tradeDate = tradeDate.day .. "/" .. tradeDate.month .. "/" .. tradeDate.year
		trade.status = {}
		trade.status.recipent = "Pending"
		trade.value = value
		trade.masterConf = self.tItems["settings"].TradeMasterConf
		if self.tItems["settings"].TradeMasterConf == 1 then
			trade.status.master = "Pending"
		else
			trade.status.master = "OK"
		end
		
		table.insert(self.tItems["trades"],trade)
		
		strReturn = "Trade Submitted"
		
	else
		strReturn = "Critical Error"
	end
	

	return strReturn
end

function DKP:TradePopulateTrades()
	if self.wndTrade:IsShown() == false then return end
	for i=1,#self.wndTrades do
		self.wndTrades[i]:Destroy()
	end
	self.wndTrades ={}
	local pendingTrades = {}
	local completedTrades = {}
	local rejectedTrades = {}
	for i=1,table.maxn(self.tItems["trades"]) do
		if self.tItems["trades"][i] ~= nil then
			if self.tItems["trades"][i].status.recipent == "Pending" and self.tItems["trades"][i].status.master == "Pending" then
				table.insert(pendingTrades,i)
			elseif self.tItems["trades"][i].status.recipent == "Pending" and self.tItems["trades"][i].status.master == "OK" then
				table.insert(pendingTrades,i)
			elseif self.tItems["trades"][i].status.recipent == "OK" and self.tItems["trades"][i].status.master == "Pending" then
				table.insert(pendingTrades,i)
			elseif self.tItems["trades"][i].status.recipent == "OK" and self.tItems["trades"][i].status.master == "OK" or self.tItems["trades"][i].status.recipent == "OK" and self.tItems["trades"][i].masterConf == 0 then
				table.insert(completedTrades,i)		
			elseif self.tItems["trades"][i].status.recipent == "Rejected" or self.tItems["trades"][i].status.master == "Rejected" then
				table.insert(rejectedTrades,i)
			end
		end
	end
	local wndSep3 = Apollo.LoadForm(self.xmlDoc,"TradeSeparator",self.wndTradeList,self)
	wndSep3:FindChild("Msg"):SetText("Pending Trades")
	table.insert(self.wndTrades,wndSep3)
	for i=1,#pendingTrades do
		local wnd = Apollo.LoadForm(self.xmlDoc,"TradeItem",self.wndTradeList,self)
		wnd:FindChild("Sender"):SetText(self.tItems["trades"][pendingTrades[i]].strSender)
		wnd:FindChild("Recipent"):SetText(self.tItems["trades"][pendingTrades[i]].strRecipent)
		wnd:FindChild("Value"):SetText(self.tItems["trades"][pendingTrades[i]].value)
		wnd:FindChild("Rem"):Show(false,true)
		if self.tItems["trades"][pendingTrades[i]].status.recipent == "OK" then
			wnd:FindChild("RecipentAccept"):SetSprite("BK3:btnMetal_CheckboxPressed") 
		end
		if self.tItems["trades"][pendingTrades[i]].status.master == "OK" then
			wnd:FindChild("MasterAccept"):SetSprite("BK3:btnMetal_CheckboxPressed") -- TODO
		end
		if self.tItems["trades"][pendingTrades[i]].masterConf == 0 then
			wnd:FindChild("MasterAccept"):Show(false,true)
			wnd:FindChild("AcceptButton"):Show(false,true)
			wnd:FindChild("DeclineButton"):Show(false,true)
			wnd:FindChild("Rem"):Show(true,true)
		end
		wnd:FindChild("Date"):SetText(self.tItems["trades"][pendingTrades[i]].tradeDate)
		table.insert(self.wndTrades,wnd)
	end
	local wndSep1 = Apollo.LoadForm(self.xmlDoc,"TradeSeparator",self.wndTradeList,self)
	wndSep1:FindChild("Msg"):SetText("Completed Trades")
	table.insert(self.wndTrades,wndSep1)
	for i=1,#completedTrades do
		local wnd = Apollo.LoadForm(self.xmlDoc,"TradeItem",self.wndTradeList,self)
		wnd:FindChild("Sender"):SetText(self.tItems["trades"][completedTrades[i]].strSender)
		wnd:FindChild("Recipent"):SetText(self.tItems["trades"][completedTrades[i]].strRecipent)
		wnd:FindChild("Date"):SetText(self.tItems["trades"][completedTrades[i]].tradeDate)
		wnd:FindChild("Value"):SetText(self.tItems["trades"][completedTrades[i]].value)
		if self.tItems["trades"][completedTrades[i]].masterConf == 1 then
			wnd:FindChild("MasterAccept"):SetSprite("BK3:btnMetal_CheckboxPressed")
		else
			wnd:FindChild("MasterAccept"):Show(false,true)
		end
		wnd:FindChild("RecipentAccept"):SetSprite("BK3:btnMetal_CheckboxPressed") 		
		wnd:FindChild("AcceptButton"):Show(false,true)
		wnd:FindChild("DeclineButton"):Show(false,true)
		table.insert(self.wndTrades,wnd)
	end
	local wndSep2 = Apollo.LoadForm(self.xmlDoc,"TradeSeparator",self.wndTradeList,self)
	wndSep2:FindChild("Msg"):SetText("Rejected Trades")
	table.insert(self.wndTrades,wndSep2)
	for i=1,#rejectedTrades do
		local wnd = Apollo.LoadForm(self.xmlDoc,"TradeItem",self.wndTradeList,self)
		wnd:FindChild("Sender"):SetText(self.tItems["trades"][rejectedTrades[i]].strSender)
		wnd:FindChild("Recipent"):SetText(self.tItems["trades"][rejectedTrades[i]].strRecipent)
		wnd:FindChild("Date"):SetText(self.tItems["trades"][rejectedTrades[i]].tradeDate)
		wnd:FindChild("Value"):SetText(self.tItems["trades"][rejectedTrades[i]].value)
		wnd:FindChild("AcceptButton"):Show(false,true)
		wnd:FindChild("DeclineButton"):Show(false,true)
		wnd:FindChild("RecipentAccept"):SetSprite("BK3:btnHolo_ClearNormal")
		wnd:FindChild("MasterAccept"):SetSprite("BK3:btnHolo_ClearNormal")
		if self.tItems["trades"][rejectedTrades[i]].status.recipent == "OK" then
			wnd:FindChild("RecipentAccept"):SetSprite("BK3:btnMetal_CheckboxPressed") 
		elseif self.tItems["trades"][rejectedTrades[i]].status.recipent == "Pending" then
			wnd:FindChild("RecipentAccept"):SetSprite("BK3:btnMetal_CheckboxNormal") 
		end
		if self.tItems["trades"][rejectedTrades[i]].masterConf == 1 then
			if self.tItems["trades"][rejectedTrades[i]].status.master == "OK" then
				wnd:FindChild("MasterAccept"):SetSprite("BK3:btnMetal_CheckboxPressed")
				wnd:FindChild("MasterAccept"):Show(true,false)-- TODO
			end
		else
			wnd:FindChild("MasterAccept"):Show(false,true)
		end
		table.insert(self.wndTrades,wnd)
	end
	self.wndTradeList:ArrangeChildrenVert()

end

function DKP:TradeConnectCap( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].ConnectedCap = 1
end

function DKP:TradeDisconnectCap( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].ConnectedCap = 0
end

function DKP:TradeEnableMasterAccept( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].TradeMasterConf = 1
end

function DKP:TradeDisableMasterAccept( wndHandler, wndControl, eMouseButton )
	self.tItems["settings"].TradeMasterConf = 0
end


function DKP:TradeMasterAccept( wndHandler, wndControl, eMouseButton )
	local value
	local sender
	local recipent
	
	value = tonumber(wndControl:GetParent():FindChild("Value"):GetText())
	sender = wndControl:GetParent():FindChild("Sender"):GetText()
	recipent = wndControl:GetParent():FindChild("Recipent"):GetText()
	
	local tradeID
	
	for i=1,table.maxn(self.tItems["trades"]) do
		if self.tItems["trades"][i] ~= nil then
			if self.tItems["trades"][i].strRecipent == recipent and self.tItems["trades"][i].strSender == sender and self.tItems["trades"][i].value == value and  self.tItems["trades"][i].status.master == "Pending"  then
				tradeID = i
				break
			end
		end
	end
	if tradeID ~= nil  then
		if wndControl:GetText() == "Ok" then
			self.tItems["trades"][tradeID].status.master = "OK"
		else
			self.tItems["trades"][tradeID].status.master = "Rejected"
		end
		self:TradeCheckTrade(tradeID)
		self:TradePopulateTrades()
	end

end

function DKP:TradeRemove( wndHandler, wndControl, eMouseButton )
	local value
	local sender
	local recipent

	
	value = tonumber(wndControl:GetParent():FindChild("Value"):GetText())
	sender = wndControl:GetParent():FindChild("Sender"):GetText()
	recipent = wndControl:GetParent():FindChild("Recipent"):GetText()
	
	
	local tradeID
	
	for i=1,table.maxn(self.tItems["trades"]) do
		if self.tItems["trades"][i] ~= nil then
			if self.tItems["trades"][i].strRecipent == recipent and self.tItems["trades"][i].strSender == sender and self.tItems["trades"][i].value == value then
				tradeID = i
				break
			end
		end
	end
	if tradeID ~= nil  then
		self.tItems["trades"][tradeID] = nil
		self:TradePopulateTrades()
	end
end

-- Bidding v2

function DKP:InitBid2()
	self.wndBid2 = Apollo.LoadForm(self.xmlDoc2,"BiddingManagerv2",nil,self)
	self.wndBid2Settings = Apollo.LoadForm(self.xmlDoc2,"BiddingManagerSettings",nil,self)
	self.wndBid2Responses = Apollo.LoadForm(self.xmlDoc2,"BiddingCheckResponses",nil,self)
	self.wndBid2Whitelist = Apollo.LoadForm(self.xmlDoc2,"WhiteList",nil,self)
	self.wndMLResponses = Apollo.LoadForm(self.xmlDoc2,"Responses",nil,self)
	
	self.wndBid2:Show(false,true)
	self.wndBid2Settings:Show(false,true)
	self.wndBid2Responses:Show(false,true)
	self.wndBid2Whitelist:Show(false,true)
	self.wndMLResponses:Show(false,true)
	
	self.wndBid2:SetSizingMinimum(1017,627)
	
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
	--Print("[Network Bidding] - Restoring Auctions")
end

function DKP:Bid2ShowNetworkBidding()
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

-- Netorking
function DKP:SetChannelAndRecconect(wndHandler,wndControl,strText)
	self.tItems["settings"]["Bid2"].strChannel = strText
	self.wndBid2Settings:FindChild("Channel"):FindChild("Value"):SetText(strText)
	self.wndMLSettings:FindChild("ChannelName"):SetText(strText)
	self.wndDS:FindChild("Channel"):SetText(strText)
	self:BidJoinChannel()
end

function DKP:BidJoinChannel()
	self.channel = nil
	self.channel = ICCommLib.JoinChannel(self.tItems["settings"]["Bid2"].strChannel,"OnRaidResponse",self)
end

function DKP:OnRaidResponse(channel, tMsg, strSender)
	if tMsg then
		if tMsg.type == "Confirmation" then
			self:BidRegisterCheckResponse(strSender)
			self:AddResponse(strSender)
		elseif tMsg.type == "Choice" then
			self:BidRegisterChoice(strSender,tMsg.option,tMsg.item,tMsg.itemCompare)
		elseif tMsg.type == "WantCostValues" then
			self.channel:SendPrivateMessage({[1] = strSender},self:Bid2GetItemCostPackage(strSender))
		elseif tMsg.type == "ArUaML" then
			self.channel:SendPrivateMessage({[1] = strSender},{type = "IamML"})
		elseif tMsg.type == "MyVote" then
			self:Bid2RegisterVote(tMsg.who,tMsg.item,strSender)
		elseif tMsg.type == "NewAuction" then
			self:BidAddNewAuction(tMsg.itemID,false,nil,tMsg.duration,true,tMsg.tLabels,tMsg.tLabelsState)
		elseif tMsg.type == "GimmeAuctions" then
			for k,auction in ipairs(self.ActiveAuctions) do
				if auction.bActive then self.channel:SendPrivateMessage({[1] = strSender},{type = "ActiveAuction" ,item = auction.wnd:GetData(),progress = auction.nTimeLeft,biddersCount = #auction.bidders,votersCount = #auction.votes,duration = self.tItems["settings"]["Bid2"].duration}) end
			end
		elseif tMsg.type == "ActiveAuction" then
			self:Bid2RestoreFetchedAuctionFromID(tMsg.item,tMsg.progress,tMsg.biddersCount,tMsg.votersCount) -- we got an auction info
		elseif tMsg.type == "IamML" then -- searching for one at random and stockpile them in table
			if self.searchingML then -- waiting for one , else close -> restore from saved ones
				self.LastML = strSender
				self:Bid2CloseTimeout()
				self.searchingML = false
			end
			self.OtherMLs[strSender] = 1
			self:Bid2UpdateMLTooltip()
		elseif tMsg.type == "GimmeVotes" then
			for k,vote in ipairs(self.MyVotes) do
				if vote.item == tMsg.item then
					self.channel:SendPrivateMessage({[1] = strSender},{type = "MyVote",who = vote.who,item = vote.item})
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
			self.tEquippedItems[strSender] = {}
			self.tEquippedItems[strSender][item:GetSlot()] = tMsg.item
			self:UpdatePlayerTileBar(strSender,item)
		elseif tMsg.type =="SendMeThemStandings" then
			self.channel:SendPrivateMessage({[1] = strSender},{type = "EncodedStandings" , strData = self:DSGetEncodedStandings(strSender)})
		elseif tMsg.type =="SendMeThemLogs" then
			self.channel:SendPrivateMessage({[1] = strSender},{type = "EncodedLogs" , strData = self:DSGetEncodedLogs(strSender)})
		elseif tMsg.type == "WantConfirmation" then
			self.channel:SendPrivateMessage({[1] = strSender},{type = "Confirmation"})
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
		self.channel:SendPrivateMessage(self:Bid2GetNewTargetsTable(auction.bidders),{type = "SendMeThemChoices",item = auction.wnd:GetData()})
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "AuctionTimeUpdate",item = auction.wnd:GetData(),progress = auction.nTimeLeft})
	end
end

function DKP:BidRegisterCheckResponse(strPlayer)
	self.wndBid2Responses:FindChild("List"):SetText(self.wndBid2Responses:FindChild("List"):GetText() .. "\n" .. strPlayer)
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
		self.channel:SendPrivateMessage(newTargets,{type = "SendMeThemChoices", item = itemID}) -- request for sending choice info once more
		self.channel:SendPrivateMessage(newVoters,{type = "GimmeVotes",item = itemID})
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
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "ArUaML"}) -- expecting to get (1) response
	end
end

function DKP:BidReqestConfirmation()
	self.wndBid2Responses:Show(true,false)
	self.wndBid2Responses:ToFront()
	self.wndBid2Responses:FindChild("List"):SetText("")
	local msg = {}
	msg.type = "WantConfirmation"
	self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),msg)
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
	
	auction.wnd:FindChild("Responses"):DestroyChildren()
	for k,bidder in ipairs(needs) do
		local ID = self:GetPlayerByIDByName(bidder.strName)
		local wnd = Apollo.LoadForm(self.xmlDoc2,"CharacterButtonBidderResponse",auction.wnd:FindChild("Responses"),self)
		wnd:FindChild("CharacterName"):SetText(bidder.strName)
		wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[self.tItems[ID].class])
		wnd:FindChild("Choice"):SetSprite(ktOptionToIcon[bidder.option])
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
		msg.cost = string.sub(self:EPGPGetItemCostByID(itemID),36)
		msg.duration = self.tItems["settings"]["Bid2"].duration
		msg.pass = self.tItems["settings"]["Bid2"].bRegisterPass
		msg.tLabels = self.tItems["settings"]["Bid2"].tLabels
		msg.tLabelsState = self.tItems["settings"]["Bid2"].tLabelsState
		msg.ver = knMemberModuleVersion
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),msg)
		if self.tItems["settings"]["Bid2"].bNotify then ChatSystemLib.Command(self.tItems["settings"].strBidChannel .. "  [Network Bidding] - Auction started for " .. Item.GetDataFromId(itemID):GetChatLinkString() .."!") end
	end
end

function DKP:Bid2SendStopMessage(itemID)
	if self.channel then
		local msg = {}
		msg.type = "AuctionPaused"
		msg.item = itemID
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),msg)
	end
end

function DKP:Bid2SendResumeMessage(itemID)
	if self.channel then
		local msg = {}
		msg.type = "AuctionResumed"
		msg.item = itemID
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),msg)
	end
end

function DKP:Bid2GetTargetsTable()
	local targets = {}
	local myName = GameLib.GetPlayerUnit():GetName()
	for k=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(k)
		if member.strCharacterName ~= myName then
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
		local wnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2,self)
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
	else
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
	if self.channel then self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),msg) end
end


function DKP:BidAddNewAuction(itemID,bMaster,progress,nDuration,bReceived,tLabels,tLabelsState)
	
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
			if self.wndBid2:FindChild("Auctions") then
				targetWnd = self.wndBid2:FindChild("Auctions")
			else
				targetWnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2,self)
				targetWnd:SetName("Auctions")
			end
		else
			targetWnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2,self)
			self.wndBid2:FindChild("Auctions"):AttachTab(targetWnd,false)
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
			self:BidCustomLabelsUpdate(true)
		end
		if bMaster == nil then 
				if #Hook.wndMasterLoot_ItemList:GetChildren() == 0 then bMaster = false else bMaster = true end
		end
		targetWnd:FindChild("Icon"):SetSprite(item:GetIcon())
		targetWnd:FindChild("Icon"):FindChild("Frame"):SetSprite(self:EPGPGetSlotSpriteByQuality(item:GetItemQuality()))
		targetWnd:FindChild("ItemName"):SetText(item:GetName())
		targetWnd:FindChild("ItemCost"):SetText(string.sub(self:EPGPGetItemCostByID(itemID),32))
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
		table.insert(self.ActiveAuctions,{wnd = targetWnd , bActive = bReceived , nTimeLeft = progress, bidders = {}, bMaster = bMaster, votes = {},bPass = bPass,duration = nDuration})
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
	if item:IsEquippable() then itemComparee = item:GetEquippedItemForItemType():GetItemId() end
	self:BidRegisterChoice(GameLib.GetPlayerUnit():GetName(),wndControl:GetName(),wndControl:GetParent():GetParent():GetData(),itemComparee)
	table.insert(self.MyChoices,{item = item:GetItemId(),option = wndControl:GetName()})
	self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "Choice" , option = wndControl:GetName(), item = wndControl:GetParent():GetParent():GetData(), itemCompare = itemComparee})
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

function DKP:BidCloseResponses()
	self.wndBid2Responses:Show(false,false)
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
	self:Bid2PopulatePlayerInfo(wndControl:GetData(),wndControl:GetParent():GetParent():FindChild("Info"))
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

function DKP:Bid2SelectBidderAtRandom(wndHandler,wndControl)
	for k , auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			local tBidders = {}
			local highestOpt = 4
			for k,bidder in ipairs(auction.bidders) do
				if tonumber(string.sub(bidder.option,4)) < highestOpt then
					tBidders = {}
					table.insert(tBidders,bidder.strName)
					highestOpt = tonumber(string.sub(bidder.option,3))
				else
					table.insert(tBidders,bidder.strName)
				end
			end
			
			local luckyBidder = tBidders[math.random(#tBidders)]
			
			for k , child in ipairs(auction.wnd:FindChild("Responses"):GetChildren()) do
				if child:GetData().strName == luckyBidder then
					child:SetCheck(true)
					luckyBidder = child
				else
					child:SetCheck(false)
				end
			end
			
			self:Bid2PopulatePlayerInfo(luckyBidder:GetData(),luckyBidder:GetParent():GetParent():FindChild("Info"))
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
		if auction.wnd == wndHandler then
			bMaster = auction.bMaster
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
		Hook.tMasterLootSelectedLooter = selectedOne:GetData()
		Hook.tMasterLootSelectedItem = selectedItem
		
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "ItemResults",item = item:GetItemId(),winner = selectedOne:GetData():GetName()})
		if self.tItems["settings"]["Bid2"].tWinners == nil then self.tItems["settings"]["Bid2"].tWinners = {} end
		self.tItems["settings"]["Bid2"].tWinners[selectedOne:GetData():GetName()] = item:GetItemId()
		 
		if self.tItems["settings"]["Bid2"].assignAction == "assign" then 
			Hook:OnAssignDown() 
			wndControl:Enable(false)
		end
	else
		if self.Bid2SelectedPlayerName and wndControl:GetParent():GetData() then 
			self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "MyVote" , who = self.Bid2SelectedPlayerName, item = wndControl:GetParent():GetData()})
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
	if not self.ItemDatabase[strItem] or not self.tItems["settings"]["Bid2"].bCloseOnAssign then return end
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
		local wnd = Apollo.LoadForm(self.xmlDoc2,"AuctionItem",self.wndBid2,self)
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
	else
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
	if not self:IsHooked(Apollo.GetAddon("MasterLoot"),"RefreshMasterLootLooterList") then
		self:RawHook(Apollo.GetAddon("MasterLoot"),"RefreshMasterLootLooterList")
		self:RawHook(Apollo.GetAddon("MasterLoot"),"OnAssignDown")
		self:RawHook(Apollo.GetAddon("MasterLoot"),"RefreshMasterLootItemList")
		self:RawHook(Apollo.GetAddon("MasterLoot"),"OnLootAssigned")
		self:PostHook(Apollo.GetAddon("MasterLoot"),"OnItemCheck","BidMasterItemSelected")
		self:Hook(Apollo.GetAddon("MasterLoot"),"OnCharacterCheck","BidCharacterChecked")
	end
end

function DKP:OnAssignDown(luaCaller,wndHandler, wndControl, eMouseButton)

	if luaCaller.tMasterLootSelectedItem ~= nil and luaCaller.tMasterLootSelectedLooter ~= nil then
		local DKPInstance = Apollo.GetAddon("EasyDKP")
		-- gotta save before it gets wiped out by event
		local SelectedLooter = luaCaller.tMasterLootSelectedLooter
		local SelectedItemLootId = luaCaller.tMasterLootSelectedItem.nLootId

		if SelectedLooter:GetName() == prevLuckyChild then self.strRandomWinner  = prevLuckyChild end
		
		luaCaller.tMasterLootSelectedLooter = nil
		luaCaller.tMasterLootSelectedItem = nil
		if #DKPInstance.tSelectedItems > 1 then
			for k,item in ipairs(DKPInstance.tSelectedItems) do
				GameLib.AssignMasterLoot(item,SelectedLooter)
				DKPInstance:MLRegisterItemWinner()
			end
			DKPInstance.tSelectedItems = {}
		else
			GameLib.AssignMasterLoot(SelectedItemLootId,SelectedLooter)
		end
		

	end

end

function DKP:OnLootAssigned(luaCaller,objItem, strLooter)
	local DKPInstance = Apollo.GetAddon("EasyDKP")
	if DKPInstance.bIsSelectedGuildBank and string.lower(strLooter) == string.lower(DKPInstance.tItems["settings"]["ML"].strGBManager) then strLooter = "Guild Bank" end
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), objItem:GetName(), strLooter))
end


function DKP:MLRegisterItemWinner()
	if Hook.tMasterLootSelectedLooter and Hook.tMasterLootSelectedItem then
		self.tItems["settings"]["ML"].tWinners[Hook.tMasterLootSelectedLooter:GetName()] = Hook.tMasterLootSelectedItem.itemDrop:GetItemId()
	end
end

function sortMasterLootEasyDKPasc(a,b)
	local DKPInstance = Apollo.GetAddon("EasyDKP")
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
	local DKPInstance = Apollo.GetAddon("EasyDKP")
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

function sortMasterLootEasyDKPNonWnd(a,b)
	local DKPInstance = Apollo.GetAddon("EasyDKP")
	if DKPInstance.tItems["settings"].BidSortAsc == 0 then
		if not DKPInstance.tItems["settings"]["ML"].bSortByName then
			if DKPInstance.tItems["EPGP"].Enable == 1 then
				return DKPInstance:EPGPGetPRByName(a:GetName()) < DKPInstance:EPGPGetPRByName(b:GetName()) 
			else
				local IDa = DKPInstance:GetPlayerByIDByName(a:GetName())
				local IDb = DKPInstance:GetPlayerByIDByName(b:GetName())
				if IDa ~= -1 and IDb ~= -1 then
					return DKPInstance.tItems[IDa].net < DKPInstance.tItems[IDb].net
				end
			end
		else -- name
			return a:GetName() < b:GetName()
		end
	else -- asc
		if not DKPInstance.tItems["settings"]["ML"].bSortByName then
			if DKPInstance.tItems["EPGP"].Enable == 1 then
				return DKPInstance:EPGPGetPRByName(a:GetName()) > DKPInstance:EPGPGetPRByName(b:GetName()) 
			else
				local IDa = DKPInstance:GetPlayerByIDByName(a:GetName())
				local IDb = DKPInstance:GetPlayerByIDByName(b:GetName())
				if IDa ~= -1 and IDb ~= -1 then
					return DKPInstance.tItems[IDa].net > DKPInstance.tItems[IDb].net
				end
			end
		else -- name
			return a:GetName() > b:GetName()
		end
	end
end

function DKP:SendRequestsForCurrItem(itemz)
	if self.channel then self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "GimmeUrEquippedItem",item = itemz}) end
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
	if luaCaller ~= Apollo.GetAddon("MasterLoot") then luaCaller = Apollo.GetAddon("MasterLoot") end
	local DKPInstance = Apollo.GetAddon("EasyDKP")
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
						local bWantEsp = true
						local bWantWar = true
						local bWantSpe = true
						local bWantMed = true
						local bWantSta = true
						local bWantEng = true
						
						local tDetails = tItem.itemDrop:GetDetailedInfo()
						if tDetails.arClassRequirement then
							for k , class in ipairs(tDetails.arClassRequirement.arClasses) do
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
				
				
				-- Grouping Players
				local unitGBManager
				for idx, unitLooter in pairs(tItem.tLooters) do
					--Print(unitLooter:GetName())
					if DKPInstance.tItems["settings"]["ML"].bShowGuildBank and string.lower(unitLooter:GetName()) == string.lower(DKPInstance.tItems["settings"]["ML"].strGBManager) then unitGBManager = unitLooter end
					if DKPInstance.tItems["settings"]["ML"].bGroup then
						class = ktClassToString[unitLooter:GetClassId()]
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
						end
					else
						class = ktClassToString[unitLooter:GetClassId()]
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
						end
					end	
				end
				-- Sorting in groups
				for k,tab in pairs(tables) do
					table.sort(tab,sortMasterLootEasyDKPNonWnd)
				end
				-- Requesting EquippedItems
				if DKPInstance.tItems["settings"]["ML"].bShowCurrItemBar or DKPInstance.tItems["settings"]["ML"].bShowCurrItemTile then
					if tItem.itemDrop:IsEquippable() then
						local myName = GameLib.GetPlayerUnit():GetName()
						if myName then
							DKPInstance:SendRequestsForCurrItem(tItem.itemDrop:GetItemId())
							self.tEquippedItems[myName] = {}
							self.tEquippedItems[myName][tItem.itemDrop:GetEquippedItemForItemType():GetSlot()] = tItem.itemDrop:GetEquippedItemForItemType():GetItemId()
						end
					end
				end
			
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
					wndGuildBank:SetData(unitGBManager)
				end

				-- Finally Creating windows

				for k,tab in pairs(tables) do
					for j,unitLooter in ipairs(tab) do
						local wndCurrentLooter
						local strName = unitLooter:GetName()
						if DKPInstance.tItems["settings"]["ML"].bArrTiles then
							if DKPInstance.tItems["settings"]["ML"].bShowClass or DKPInstance.tItems["settings"]["ML"].bShowLastItem then
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonTileClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
								wndCurrentLooter:FindChild("ClassIcon"):SetSprite(ktClassToIcon[unitLooter:GetClassId()])
							else
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2,"CharacterButtonTile", luaCaller.wndMasterLoot_LooterList,luaCaller)
							end
							
							if DKPInstance.tItems["settings"]["ML"].bShowValues then
								if DKPInstance.tItems["EPGP"].Enable == 1 then 
									wndCurrentLooter:FindChild("CharacterLevel"):SetText("PR: " .. DKPInstance:EPGPGetPRByName(unitLooter:GetName()))
								else
									wndCurrentLooter:FindChild("CharacterLevel"):SetText("DKP: " .. DKPInstance.tItems[DKPInstance:GetPlayerByIDByName(unitLooter:GetName())].net)
								end
							end
								
							wndCurrentLooter:FindChild("CharacterLevel"):SetText(unitLooter:GetBasicStats().nLevel)
							
							if DKPInstance.tItems["settings"]["ML"].bShowLastItemTile then
								if self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()] then
									local item = Item.GetDataFromId(self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()])
									wndCurrentLooter:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									wndCurrentLooter:FindChild("ItemFrame"):Show(true,false)
									wndCurrentLooter:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							end
							
							if DKPInstance.tItems["settings"]["ML"].bShowCurrItemTile then -- Set Current Item
								if DKPInstance.tEquippedItems[unitLooter:GetName()] and DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()] then							
									local item = Item.GetDataFromId(DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()])
									wndCurrentLooter:FindChild("ItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									wndCurrentLooter:FindChild("ItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									wndCurrentLooter:FindChild("ItemFrame"):Show(true,false)
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("ItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							end	
							
						else -- List
							if DKPInstance.tItems["settings"]["ML"].bShowClass then
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonListClass", luaCaller.wndMasterLoot_LooterList, luaCaller)
								wndCurrentLooter:FindChild("ClassIcon"):SetSprite(ktClassToIcon[unitLooter:GetClassId()])
							else
								wndCurrentLooter = Apollo.LoadForm(DKPInstance.xmlDoc2, "CharacterButtonList", luaCaller.wndMasterLoot_LooterList, luaCaller)
							end
							wndCurrentLooter:FindChild("CharacterLevel"):SetText(unitLooter:GetBasicStats().nLevel)
							if DKPInstance.tItems["settings"]["ML"].bShowLastItemBar then
								if self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()] then
									local item = Item.GetDataFromId(self.tItems["settings"]["ML"].tWinners[unitLooter:GetName()])
									wndCurrentLooter:FindChild("LastItemFrame"):SetSprite(self:EPGPGetSlotSpriteByQualityRectangle(item:GetItemQuality()))
									wndCurrentLooter:FindChild("LastItemFrame"):Show(true)
									wndCurrentLooter:FindChild("LastItemFrame"):FindChild("ItemIcon"):SetSprite(item:GetIcon())
									Tooltip.GetItemTooltipForm(self,wndCurrentLooter:FindChild("LastItemFrame"),item, {bPrimary = true, bSelling = false})
								end
							end
							if DKPInstance.tItems["settings"]["ML"].bShowCurrItemBar then
								if DKPInstance.tEquippedItems[unitLooter:GetName()] and DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()] then
									local item = Item.GetDataFromId(DKPInstance.tEquippedItems[unitLooter:GetName()][tItem.itemDrop:GetSlot()])
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
								wndCounter:FindChild("Indicator"):Show(false,true)
							end
						end
						wndCurrentLooter:FindChild("CharacterName"):SetText(unitLooter:GetName())
						
						wndCurrentLooter:SetData(unitLooter)
						
						
						if luaCaller.tMasterLootSelectedLooter == unitLooter then
							wndCurrentLooter:SetCheck(true)
							bStillHaveLooter = true
						end
					end
				end
				-- For for ended

				

				
				if not bStillHaveLooter then
					luaCaller.tMasterLootSelectedLooter = nil
				end

				-- get out of range people
				-- tLootersOutOfRange
				if tItem.tLootersOutOfRange and next(tItem.tLootersOutOfRange) then
					for idx, strLooterOOR in pairs(tItem.tLootersOutOfRange) do
						local wndCurrentLooter = Apollo.LoadForm(luaCaller.xmlDoc, "CharacterButton", luaCaller.wndMasterLoot_LooterList, luaCaller)
						wndCurrentLooter:FindChild("CharacterName"):SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), strLooterOOR))
						wndCurrentLooter:FindChild("ClassIcon"):SetSprite("CRB_GroupFrame:sprGroup_Disconnected")
						wndCurrentLooter:Enable(false)
					end
				end
				DKPInstance:BidMLSearch()
				
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
	table.insert(self.tSelectedItems,wndControl:GetParent():GetData().nLootId)
end

function DKP:BidRemoveItem(wndHandler,wndControl)
	for k,item in ipairs(self.tSelectedItems) do
		if item == wndControl:GetParent():GetData().nLootId then table.remove(self.tSelectedItems,k) end
	end
	
end

function DKP:OnItemCheck(wndHandler,wndControl,eMouseButton)
	Hook:OnItemCheck(wndHandler,wndControl,eMouseButton)
end

function DKP:OnItemMouseButtonUp(wndHandler,wndControl,eMouseButton)
	Hook:OnItemMouseButtonUp(wndHandler,wndControl,eMouseButton)
end

function DKP:RefreshMasterLootItemList(luaCaller,tMasterLootItemList)

	luaCaller.wndMasterLoot_ItemList:DestroyChildren()
	local DKPInstance = Apollo.GetAddon("EasyDKP")

	
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
				if tItem.nLootId == item then 
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
		self.tItems["settings"]["ML"].bArrTiles = true
		self.tItems["settings"]["ML"].bShowValues = true
	end
	if self.tItems["settings"]["ML"].bArrItemTiles == nil then self.tItems["settings"]["ML"].bArrItemTiles = true end
	if self.tItems["settings"]["ML"].bStandardLayout == nil then self.tItems["settings"]["ML"].bStandardLayout = true end
	if self.tItems["settings"]["ML"].bListIndicators == nil then self.tItems["settings"]["ML"].bListIndicators = true end
	if self.tItems["settings"]["ML"].bGroup == nil then self.tItems["settings"]["ML"].bGroup = false end
	if self.tItems["settings"]["ML"].bShowLastItemBar == nil then self.tItems["settings"]["ML"].bShowLastItemBar = true end
	if self.tItems["settings"]["ML"].bShowLastItemTile == nil then self.tItems["settings"]["ML"].bShowLastItemTile = false end	
	if self.tItems["settings"]["ML"].bShowCurrItemBar == nil then self.tItems["settings"]["ML"].bShowCurrItemBar = true end
	if self.tItems["settings"]["ML"].bShowCurrItemTile == nil then self.tItems["settings"]["ML"].bShowCurrItemTile = false end
	if self.tItems["settings"]["ML"].bAllowMulti == nil then self.tItems["settings"]["ML"].bAllowMulti = false end
	if self.tItems["settings"]["ML"].bShowGuildBank == nil then self.tItems["settings"]["ML"].bShowGuildBank = false end
	if self.tItems["settings"]["ML"].strGBManager == nil then self.tItems["settings"]["ML"].strGBManager = "" end
	if self.tItems["settings"]["ML"].bDisplayApplicable == nil then self.tItems["settings"]["ML"].bDisplayApplicable = false end
	if self.tItems["settings"]["ML"].bSortByName == nil then self.tItems["settings"]["ML"].bSortByName = false end
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
	
	self.wndMLSettings:FindChild("GBManager"):SetText(self.tItems["settings"]["ML"].strGBManager)
	self.wndMLSettings:FindChild("ChannelName"):SetText(self.tItems["settings"]["Bid2"].strChannel)
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
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "WantConfirmation",ver = knMemberModuleVersion})
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

function DKP:lll(wndControl,wndHandler)

end

