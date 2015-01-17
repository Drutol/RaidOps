-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOpsMM
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- RaidOpsMM Module Definition
-----------------------------------------------------------------------------------------------
local RaidOpsMM = {} 
 
local kUIBody = "ff39b5d4"
local ktAuctionHeight = 106
local nItemIDSpacing = 4
 
 local defaultSlotValues = 
{
	["Weapon"] = 1,
	["Shield"] = 0.777,
	["Head"] = 1,
	["Shoulders"] = 0.777,
	["Chest"] = 1,
	["Hands"] = 0.777,
	["Legs"] = 1,
	["Attachment"] = 0.7,
	["Gadget"] = 0.55,
	["Implant"] = 0.7,
	["Feet"] = 0.777,
	["Support"] = 0.7
}

local defaultQualityValues =
{
	["White"] = 1,
	["Green"] = .5,
	["Blue"] = .33,
	["Purple"] = .15,
	["Orange"] = .1
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function RaidOpsMM:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function RaidOpsMM:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- RaidOpsMM OnLoad
-----------------------------------------------------------------------------------------------
function RaidOpsMM:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("RaidOpsMM.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- RaidOpsMM OnDocLoaded
-----------------------------------------------------------------------------------------------
function RaidOpsMM:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndSettings = Apollo.LoadForm(self.xmlDoc,"Settings",nil,self)
		self.wndAnchor = Apollo.LoadForm(self.xmlDoc,"Anchor",nil,self)
		self.wndLootList = Apollo.LoadForm(self.xmlDoc,"LootList",nil,self)
		self.wndCost = Apollo.LoadForm(self.xmlDoc,"ItemCostFormula",nil,self)

		Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)	
		self.wndSettings:Show(false, true)
		self.wndAnchor:Show(false, true)
		self.wndLootList:Show(false, true)
		self.wndCost:Show(false, true)
		
		self.wndLootList:MoveToLocation(self.wndAnchorloc)
		self.wndAnchor:MoveToLocation(self.wndAnchorloc)
		if self.settings == nil then
			self.settings = {}
			self.settings.strChannel = "SetYourChannelName"
			self.settings.enable = true
		end
		if self.settings.tooltips == nil then self.settings.tooltips = true end
		self.ActiveAuctions = {}
		self.MyChoices = {}
		if self.SlotValues == nil then self.SlotValues = defaultSlotValues end
		if self.QualityValues == nil then self.QualityValues = defaultQualityValues end
		if self.CustomModifier == nil then self.CustomModifier = .5 end
		if self.settings.resize == nil then self.settings.resize = true end
		if self.settings.bAutoClose == nil then self.settings.bAutoClose = false end
		if self.settings.tooltips == true then self:EPGPHookToETooltip() end
		if self.settings.bKeepOnTop == nil then self.settings.bKeepOnTop = true end
		if self.settings.enable then 
			self:JoinGuildChannel()
		end
		self:FillInCostFormula()
		self:RestoreSettings()
		local l,t,r,b = self.wndAnchor:GetAnchorOffsets()
		self.wndLootList:SetAnchorOffsets(l,t,r,self.ResizedWndBottom)
		--Sizing
		self.wndLootList:SetSizingMaximum(564,332)
		self.wndLootList:SetSizingMinimum(564,123)
		
		self.tMLs = {}
		Apollo.RegisterSlashCommand("ropsmm", "OnRaidOpsMMOn", self)
		Apollo.RegisterTimerHandler(1,"InitDelay",self)
		self.delayTimer = ApolloTimer.Create(1,true,"InitDelay",self)
	end
end
local delay = 2
function RaidOpsMM:InitDelay()
	delay = delay - 1
	if delay == 0 then 
		self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "ArUaML"})
		self.delayTimer:Stop()
		Apollo.RemoveEventHandler("InitDelay",self)
	end
end

-----------------------------------------------------------------------------------------------
-- RaidOpsMM Functions
-----------------------------------------------------------------------------------------------
function RaidOpsMM:ApplyMyPreviousChoices(forAuction)
	for l,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == forAuction then
			local option
			for k,choice in ipairs(self.MyChoices) do 
				if choice.item == forAuction then 
					option = choice.option
					break
				end 
			end
			if option then 
				auction.wnd:FindChild(option):SetCheck(true)
				auction.wnd:FindChild("GlowyThingy"):Show(false,false)
			end
			break
		end
	end
end


function RaidOpsMM:Bid2GetTargetsTable()
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

function RaidOpsMM:FetchActiveAuctions(strML)
	if self.channel then
		self.channel:SendPrivateMessage({[1] = strML},{type = "GimmeAuctions"})
	end
end

function RaidOpsMM:FetchOnlineML()
	if self.channel then self.channel:SendPrivateMessage(self:Bid2GetTargetsTable(),{type = "ArUaML"}) end
end

function RaidOpsMM:OnRaidOpsMMOn()
	self.wndSettings:Show(true,false)
	self.wndSettings:ToFront()
end



-----------------------------------------------------------------------------------------------
-- RaidOpsMMForm Functions
-----------------------------------------------------------------------------------------------

function RaidOpsMM:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	tSave = {}
	tSave.settings = self.settings
	tSave.loc = self.wndAnchor:GetLocation():ToTable()
	tSave.SlotValues = self.SlotValues
	tSave.QualityValues = self.QualityValues
	tSave.CustomModifier = self.CustomModifier
	tSave.MyChoices = self.MyChoices
	local l,t,r,b =  self.wndLootList:GetAnchorOffsets()
	tSave.ResizedWndBottom = b
	return tSave
end

function RaidOpsMM:OnRestore(eLevel, tData)	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.settings = tData.settings
	self.SlotValues = tData.SlotValues
	self.QualityValues = tData.QualityValues
	self.CustomModifier = tData.CustomModifier
	self.wndAnchorloc  = WindowLocation.new(tData.loc)
	self.ResizedWndBottom = tData.ResizedWndBottom
	self.MyChoices = tData.MyChoices
end

function RaidOpsMM:GetSlotSpriteByQuality(ID)
	if ID == 5 then return "CRB_Tooltips:sprTooltip_SquareFrame_Purple"
	elseif ID == 6 then return "CRB_Tooltips:sprTooltip_SquareFrame_Orange"
	elseif ID == 4 then return "CRB_Tooltips:sprTooltip_SquareFrame_Blue"
	elseif ID == 3 then return "CRB_Tooltips:sprTooltip_SquareFrame_Green"
	elseif ID == 2 then return "CRB_Tooltips:sprTooltip_SquareFrame_White"
	else return "CRB_Tooltips:sprTooltip_SquareFrame_DarkModded"
	end
end
---------------------------------------------------------------------------------------------------
-- Settings Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMM:EnableAddon( wndHandler, wndControl, eMouseButton )
	self.settings.enable = true
	self:JoinGuildChannel()
end

function RaidOpsMM:DisableAddon( wndHandler, wndControl, eMouseButton )
	self.settings.enable = false
	self.channel = nil
end

function RaidOpsMM:AnchorShow( wndHandler, wndControl, eMouseButton )
	self.wndAnchor:Show(true,false)
	self.wndAnchor:ToFront()
end

function RaidOpsMM:AnchorClose( wndHandler, wndControl, eMouseButton )
	self.wndAnchor:Show(false,false)
	self:SetLootListPos()
	self.wndSettings:FindChild("ShowAnchor"):SetCheck(false)
end

function RaidOpsMM:SetChannelName( wndHandler, wndControl, strText )
	self.settings.strChannel = strText
	self:JoinGuildChannel()
end

function RaidOpsMM:RestoreSettings()
	self.wndSettings:FindChild("ChannelName"):SetText(self.settings.strChannel)
	if self.settings.enable then self.wndSettings:FindChild("Enable"):SetCheck(true) end
	if self.settings.tooltip then self.wndSettings:FindChild("TooltipCost"):SetCheck(true) end
	if self.settings.resize then self.wndSettings:FindChild("AllowResize"):SetCheck(true) end
	if self.settings.bKeepOnTop then self.wndSettings:FindChild("KeepOnTop"):SetCheck(true) end
	if self.settings.bAutoClose then self.wndSettings:FindChild("AutoClose"):SetCheck(true) end
end
function RaidOpsMM:LootListOnTopEnable( wndHandler, wndControl, eMouseButton )
	self.settings.resize = true
	self.wndLootList:SetCanResize(true)
	self.wndLootList:FindChild("ResizeHandle"):Show(true,false)
end

function RaidOpsMM:LootListOnTopDisable( wndHandler, wndControl, eMouseButton )
	self.settings.resize = false
	self.wndLootList:SetCanResize(false)
	self.wndLootList:FindChild("ResizeHandle"):Show(false,false)
end
-------------------------------------

function RaidOpsMM:JoinGuildChannel()
	self.channel = ICCommLib.JoinChannel(self.settings.strChannel ,"OnReceivedRequest",self)
end

function RaidOpsMM:OnReceivedRequest(channel, tMsg, strSender)
	if tMsg then
		if tMsg.type then
			if tMsg.type == "WantConfirmation" then
				local msg = {}
				msg.type = "Confirmation"
				self.channel:SendPrivateMessage(self:GetMLsTable(),msg)
			elseif tMsg.type == "ItemsPackage" then
				for k,item in pairs(tMsg.items) do
					self:AddAuction(item.ID,item.GP,item.time,item.offspec)
				end
			elseif tMsg.type == "ItemResults" then
				self:RegisterAuctionWinner(tMsg.item,tMsg.winner)
			elseif tMsg.type == "CostValues" then
				self.QualityValues = tMsg.QualityValues or defaultQualityValues
				self.SlotValues = tMsg.SlotValues or defaultSlotValues
				self.CustomModifier = tMsg.CustomModifier or .5
				self:FillInCostFormula()
			elseif tMsg.type == "NewAuction" then
				self:AddAuction(tMsg.itemID,tMsg.cost,tMsg.duration,tMsg.bAllowOffspec,nil,tMsg.pass)
			elseif tMsg.type == "AuctionPaused" then
				self:OnAuctionPasused(tMsg.item)
			elseif tMsg.type == "AuctionResumed" then
				self:OnAuctionResumed(tMsg.item)
			elseif tMsg.type == "IamML" then
				self.tMLs[strSender] = 1
				self:UpdateMLsTooltip()
				if #self.tMLs == 1 then self:FetchActiveAuctions(strSender) end
			elseif tMsg.type == "ActiveAuction" then
				self:AddAuction(tMsg.item,0,tMsg.duration,true,tMsg.progress)
			elseif tMsg.type == "SendMeThemChoices" then
				for k,choice in ipairs(self.MyChoices) do if tMsg.item == choice.item then self.channel:SendPrivateMessage({[1] = strSender},{type = "Choice",item = choice.item,option = choice.option}) break end end
			elseif tMsg.type == "AuctionTimeUpdate" then
				self:OnAuctionPasused(tMsg.item)
				self:UpdateAuctionProgress(tMsg.item,tMsg.progress)
			elseif tMsg.type == "GimmeUrEquippedItem" then -- From RaidOpsML
				local forItem = Item.GetDataFromId(tMsg.item)
				if forItem and forItem:IsEquippable() then self.channel:SendPrivateMessage({[1] = strSender},{type = "MyEquippedItem",item = forItem:GetEquippedItemForItemType():GetItemId()}) end
			end
		end
	end
end

function RaidOpsMM:UpdateAuctionProgress(item,newProgress)
	for k,auction in ipairs(self.ActiveAuctions) do
		if item == auction.wnd:GetData() then
			auction.nTimeLeft = newProgress
			auction.wnd:SetProgress(newProgress,1000)
			auction.wnd:FindChild("TimeLeft"):SetText(auction.nDuration - auction.nTimeLeft)
		end
	end
end

function RaidOpsMM:UpdateMLsTooltip()
	local MLs = "Found Master Looters:\n"
	for k,ML in ipairs(self.tMLs) do MLs = MLs .. "\n" .. k	end
	self.wndLootList:FindChild("MLs"):SetTooltip(MLs)
end

function RaidOpsMM:GetMLsTable()
	local arr = {}
	for k,l in pairs(self.tMLs) do
		table.insert(arr,k)
	end
	return arr
end

function RaidOpsMM:GetRandomML()
	local strML
	local arr = {}
	for k,l in pairs(self.tMLs) do
		table.insert(arr,k)
	end
	if #arr > 0 then return arr[math.random(#arr)] or "" else return "" end
end

function RaidOpsMM:SetLootListPos()
	self.wndLootList:MoveToLocation(self.wndAnchor:GetLocation())
end
function RaidOpsMM:AddTestAuction( wndHandler, wndControl, eMouseButton )
	self:AddAuction(math.random(20000,40000),1000,30,true,nil,false)
end

function RaidOpsMM:EnableKeepOnTop( wndHandler, wndControl, eMouseButton )
	self.settings.bKeepOnTop = true
	self:ArrangeAuctions()
end

function RaidOpsMM:DisableKeepOnTop( wndHandler, wndControl, eMouseButton )
	self.settings.bKeepOnTop = false
end

function RaidOpsMM:AutoPassCloseEnable( wndHandler, wndControl, eMouseButton )
	self.settings.bAutoClose = true
end

function RaidOpsMM:AutoPassCloseDisable( wndHandler, wndControl, eMouseButton )
	self.settings.bAutoClose = false
end

function RaidOpsMM:CloseSettings( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false,false)
end

---------------------------------------------------------------------------------------------------
-- Auction Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMM:AddAuction(itemID,cost,duration,bOff,progress,pass)
	if progress == nil then progress = 0 end
	local item = Item.GetDataFromId(itemID)
	if item then
		local wndAuction = Apollo.LoadForm(self.xmlDoc,"Auction",self.wndLootList:FindChild("Auctions"),self)
		wndAuction:FindChild("Icon"):SetSprite(item:GetIcon())
		wndAuction:FindChild("Remove"):Enable(false)
		wndAuction:FindChild("Icon"):FindChild("Frame"):SetSprite(self:GetSlotSpriteByQuality(item:GetItemQuality()))
		if cost then wndAuction:FindChild("ItemCost"):SetText(cost .. " GP") else wndAuction:FindChild("ItemCost"):Show(false,false) end
		wndAuction:SetMax(duration)
		wndAuction:SetProgress(progress,100)
		if not bOff then wndAuction:FindChild("Greed"):Enable(false) end
		wndAuction:SetData(itemID)
		table.insert(self.ActiveAuctions,{wnd = wndAuction , bActive = true , nTimeLeft = progress, nDuration = duration, bPass = pass})
		if self.Timer == nil then self:AuctionTimerStart() end
		Tooltip.GetItemTooltipForm(self, wndAuction:FindChild("Icon") , item, {bPrimary = true, bSelling = false, itemCompare = item:GetEquippedItemForItemType()})
		self.wndLootList:Show(true,false)
		self:ArrangeAuctions()
		self.wndLootList:ToFront()
	end
end

function RaidOpsMM:ArrangeAuctions()
	if self.settings.resize and #self.ActiveAuctions <= 3 then
		local l,t,r,b = self.wndAnchor:GetAnchorOffsets()
		self.wndLootList:SetAnchorOffsets(l,t,r,b+((#self.ActiveAuctions-1)*ktAuctionHeight))
	else
		local l,t,r,b = self.wndAnchor:GetAnchorOffsets()
		self.wndLootList:SetAnchorOffsets(l,t,r,b+212)
	end
	if self.settings.bKeepOnTop then 
		self.wndLootList:FindChild("Auctions"):ArrangeChildrenVert(0,sortAuctionRaidOps) 
	else
		self.wndLootList:FindChild("Auctions"):ArrangeChildrenVert(0) 
	end
end

function sortAuctionRaidOps(a,b)
	return a:FindChild("GlowyThingy"):IsShown() 
end

function RaidOpsMM:OnAuctionResumed(itemID)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			auction.bActive = true
			break
		end
	end
end

function RaidOpsMM:OnAuctionPasused(itemID)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			auction.bActive = false
			break
		end
	end
end

function RaidOpsMM:ItemOptionSelected( wndHandler, wndControl, eMouseButton )
	if self.channel then
		local bPass
		for k,auction in ipairs(self.ActiveAuctions) do if auction.wnd == wndControl:GetParent() then bPass =  auction.bPass end end
		if not bPass and self.settings.bAutoClose and wndControl:GetName() == "pass" then
			self:RemoveAuction(wndControl:GetParent():GetData())
			return
		end
		if not bPass and wndControl:GetName() == "pass" then 
			wndControl:GetParent():FindChild("GlowyThingy"):Show(false,false)
			self:ArrangeAuctions()
			table.insert(self.MyChoices,{option = wndControl:GetName(),item = wndControl:GetParent():GetData()})
			wndControl:GetParent():FindChild("Remove"):Enable(true)
		else
			local msg = {}
			msg.type = "Choice"
			msg.option = wndControl:GetName()
			msg.item = wndControl:GetParent():GetData()
			local item =  Item.GetDataFromId(wndControl:GetParent():GetData())
			if item:IsEquippable() then msg.itemCompare = item:GetEquippedItemForItemType():GetItemId() end
			self.channel:SendPrivateMessage({[1] = self:GetRandomML()},msg)
			if msg.option == "pass" then 
				if self.settings.bAutoClose then 
					self:RemoveAuction(wndControl:GetParent():GetData())
					return
				end
				wndControl:GetParent():FindChild("Remove"):Enable(true) 
			else 
				wndControl:GetParent():FindChild("Remove"):Enable(false) 
			end
			wndControl:GetParent():FindChild("GlowyThingy"):Show(false,false)
			self:ArrangeAuctions()
			table.insert(self.MyChoices,{option = msg.option,item = item:GetItemId()})
		end
	end
end

function RaidOpsMM:RemoveAuctionDirect( wndHandler, wndControl, eMouseButton )
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd == wndControl:GetParent() then
			table.remove(self.ActiveAuctions,k)
			auction.wnd:Destroy()
			self:ArrangeAuctions()
			break
		end
	end
end

function RaidOpsMM:RemoveAuction(itemID)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			table.remove(self.ActiveAuctions,k)
			for l,choice in ipairs(self.MyChoices) do
				if choice.item == itemID then
					table.remove(self.MyChoices,l)
					break
				end
			end
			auction.wnd:Destroy()
			self:ArrangeAuctions()
			break
		end
	end

end

function RaidOpsMM:RegisterAuctionWinner(itemID,strWinner)
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == itemID then
			auction.wnd:FindChild("Remove"):Enable(true)
			auction.wnd:FindChild("TimeLeft"):SetText("Auction won by : " .. string.lower(strWinner) == string.lower(GameLib.GetPlayerUnit():GetName()) and "YOU!" or strWinner)
			auction.nTimeLeft = auction.duration
			auction.bActive = false
			auction.wnd:SetProgress(auction.nTimeLeft,1000)
		end
	end
end

-- Timing

function RaidOpsMM:AuctionTimerStart()
	Apollo.RegisterTimerHandler(1, "UpdateProgress", self)
	self.Timer = ApolloTimer.Create(1,true, "UpdateProgress", self)
end

function RaidOpsMM:UpdateProgress()
	for k,auction in ipairs(self.ActiveAuctions) do
		if auction.bActive then
			auction.nTimeLeft = auction.nTimeLeft + 1
			auction.wnd:SetProgress(auction.nTimeLeft,1)
			auction.wnd:FindChild("TimeLeft"):SetText(auction.nDuration - auction.nTimeLeft)
			if auction.nTimeLeft >= auction.nDuration then 
				auction.bActive = false
				auction.wnd:FindChild("TimeLeft"):SetText("Waiting for results")
				auction.wnd:FindChild("need"):Enable(false)
				auction.wnd:FindChild("greed"):Enable(false)
				auction.wnd:FindChild("pass"):Enable(false)
				auction.wnd:FindChild("slight"):Enable(false)
				auction.wnd:FindChild("Remove"):Enable(true)
				auction.wnd:FindChild("GlowyThingy"):Show(false,false)
			end
		end
	end
	if #self.ActiveAuctions == 0 then
		self.Timer:Stop()
		self.Timer = nil
		self.wndLootList:Show(false,false)
		Apollo.RemoveEventHandler("UpdateProgress",self)
	end
end

-------------------------------------------------------------------------- ItemCost

function RaidOpsMM:FetchItemCost(wndHandler,wndControl)
	if self.channel then
		local msg = {}
		msg.type = "WantCostValues"
		self.channel:SendMessage({[1] = wndControl:GetParent():FindChild("from"):GetText()},msg)
	end
end

function RaidOpsMM:FillInCostFormula()
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue"):FindChild("Field"):SetText(self.SlotValues["Weapon"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue1"):FindChild("Field"):SetText(self.SlotValues["Shield"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue2"):FindChild("Field"):SetText(self.SlotValues["Head"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue3"):FindChild("Field"):SetText(self.SlotValues["Shoulders"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue4"):FindChild("Field"):SetText(self.SlotValues["Chest"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue5"):FindChild("Field"):SetText(self.SlotValues["Hands"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue6"):FindChild("Field"):SetText(self.SlotValues["Legs"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue7"):FindChild("Field"):SetText(self.SlotValues["Feet"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue8"):FindChild("Field"):SetText(self.SlotValues["Attachment"])
	self.wndCost:FindChild("ItemCost"):FindChild("SlotValue9"):FindChild("Field"):SetText(self.SlotValues["Support"])
          self.wndCost:FindChild("ItemCost"):FindChild("SlotValue10"):FindChild("Field"):SetText(self.SlotValues["Gadget"])
          self.wndCost:FindChild("ItemCost"):FindChild("SlotValue11"):FindChild("Field"):SetText(self.SlotValues["Implant"])
	--Rest
	self.wndCost:FindChild("FormulaLabel"):FindChild("CustomModifier"):SetText(self.CustomModifier)
	self.wndCost:FindChild("PurpleQual"):FindChild("Field"):SetText(self.QualityValues["Purple"])
	self.wndCost:FindChild("OrangeQual"):FindChild("Field"):SetText(self.QualityValues["Orange"])
end

function RaidOpsMM:ShowItemCost()
	self.wndCost:Show(true,false)
	self.wndCost:ToFront()
end

function RaidOpsMM:ItemCostClose( wndHandler, wndControl, eMouseButton )
	self.wndCost:Show(false,false)
end

function RaidOpsMM:EPGPItemSlotValueChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.SlotValues[wndControl:GetParent():FindChild("Name"):GetText()] = tonumber(strText)
	else
		wndControl:SetText(self.SlotValues[wndControl:GetParent():FindChild("Name"):GetText()])
	end
end

function RaidOpsMM:EPGPItemQualityValueChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
			self.QualityValues["Purple"] = tonumber(strText)
		else
			self.QualityValues["Orange"] = tonumber(strText)
		end
	else
		if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
			wndControl:SetText(self.QualityValues["Purple"])
		else
			wndControl:SetText(self.QualityValues["Orange"])		
		end
	end
end




--Hooking
function RaidOpsMM:EPGPGetSlotStringByID(ID)
	if ID == "Primary Weapon" then return "Weapon"
	elseif ID == 7 then return "Attachment"
	elseif ID == "Shoulder" then return "Shoulders"
	elseif ID == "Chest" then return "Chest"
	elseif ID == "Feet" then return "Feet"
	elseif ID == "Gadget" then return "Gadget"
	elseif ID == "Hands" then return "Hands"
	elseif ID == "Head" then return "Head"
	elseif ID == "Augment" then return "Implant"
	elseif ID == "Legs" then return "Legs"
	elseif ID == "Shields" then return "Shield"
	elseif ID == 8  then return "Support"
	end
end

function RaidOpsMM:EPGPGetQualityStringByID(ID)
	if ID == 5 then return "Purple"
	elseif ID == 6 then return "Orange"
	elseif ID == 4 then return "Blue"
	elseif ID == 3 then return "Green"
	elseif ID == 2 then return "White"
	end
end

function RaidOpsMM:EPGPGetItemCostByID(itemID)
	local item = Item.GetDataFromId(itemID)
	if item ~= nil and item:IsEquippable() and item:GetItemQuality() <= 6 then
		local slot 
		if item:GetSlotName() ~= "" then
			slot = item:GetSlotName()
		else
			slot = item:GetSlot()
		end
		if self.SlotValues[self:EPGPGetSlotStringByID(slot)] == nil then return "" end
		return "                                GP: " .. math.ceil(item:GetItemPower()/self.QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())] * self.CustomModifier * self.SlotValues[self:EPGPGetSlotStringByID(slot)])
	else return "" end
end
 
function RaidOpsMM:EPGPHookToETooltip( wndHandler, wndControl, eMouseButton )
	if Apollo.GetAddon("ETooltip") == nil then
		self.settings.tooltips = false
		Print("Couldn't find EToolTip Addon")
		if wndControl ~= nil then wndControl:SetCheck(false) end
		return
	end
	if not Apollo.GetAddon("ETooltip").tSettings["bShowItemID"] then
		self.settings.tooltips = false
		Print("Enable option to Show item ID in EToolTip")
		if wndControl ~= nil then wndControl:SetCheck(false) end
		return
	end
	if Apollo.GetAddon("EasyDKP") then 
		Print("Master addon already installed")
		self.settings.tooltips = false
		if wndControl ~= nil then wndControl:SetCheck(false) end
		return
	end
	self.settings.tooltips = true
	--Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
	if not self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then
		self:RawHook(Apollo.GetAddon("ETooltip"),"AttachBelow")
	end
end

function RaidOpsMM:EPGPUnHook( wndHandler, wndControl, eMouseButton )
	self.settings.tooltips = false
	self:UnhookAll()
end


function RaidOpsMM:AttachBelow(luaCaller,strText, wndHeader)
	local words = {}
	for word in string.gmatch(strText,"%S+") do
	  	    table.insert(words,word)
	end
	-- Old but working
	--[[wndAML = Apollo.LoadForm(luaCaller.xmlDoc, "MLItemID", wndHeader, luaCaller)
	wndAML:SetAML(string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>",kUIBody, strText) ..  "<T Font=\"Nameplates\" TextColor=\"xkcdAmber\">".. self:EPGPGetItemCostByID(tonumber(words[3])).." </T>")
	local nWidth, nHeight = wndAML:SetHeightToContentHeight()
	nHeight = nHeight + 1
	wndAML:SetAnchorPoints(0,1,1,1)
	wndAML:SetAnchorOffsets(25, 3 - nHeight, 3, 0)]]
	-- From Update 1_31
	wndAML = Apollo.LoadForm(luaCaller.xmlDoc, "MLItemID", wndHeader, luaCaller)
	wndAML:SetAML(string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>",kUIBody, strText) ..  "<T Font=\"Nameplates\" TextColor=\"xkcdAmber\">".. self:EPGPGetItemCostByID(tonumber(words[3])).." </T>")
	local nWidth, nHeight = wndAML:SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = wndHeader:GetAnchorOffsets()
	--Set BGart to not strech to fit so we have extra space for the ItemID; not ideal
	local BGArt = wndHeader:FindChild("ItemTooltip_HeaderBG")
	local QBar = wndHeader:FindChild("ItemTooltip_HeaderBar")
	local nQLeft, nQTop, nQRight, nQBottom = QBar:GetAnchorOffsets()
	QBar:SetAnchorOffsets(nQLeft, nQTop - nItemIDSpacing, nQRight, nQBottom - nItemIDSpacing) -- move up with the rest
	BGArt:SetAnchorPoints(0,0,1,0) --set to no longer stretch to fit
	BGArt:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	wndHeader:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nItemIDSpacing) -- add space
	luaCaller:ArrangeChildrenVertAndResize(wndHeader:GetParent())
	--set itemID position
	wndAML:SetAnchorPoints(0,1,1,1)
	wndAML:SetAnchorOffsets(25, 2 - nHeight, 3, 0)



end
---------------------------------------------------------------------------------------------------
-- LootList Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMM:LootListToFront( wndHandler, wndControl )
	self.wndLootList:ToFront()
end

---------------------------------------------------------------------------------------------------
-- ItemCostFormula Functions
---------------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------
-- RaidOpsMM Instance
-----------------------------------------------------------------------------------------------
local RaidOpsMMInst = RaidOpsMM:new()
RaidOpsMMInst:Init()
