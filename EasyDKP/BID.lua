-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2014 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

local Hook = Apollo.GetAddon("MasterLoot")
local DKP = Apollo.GetAddon("EasyDKP")

local kcrNormalText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrSelectedText = ApolloColor.new("ChannelAdvice")

local bInitialized = false
function DKP:BidBeginInit()
	Apollo.RegisterTimerHandler(1, "OnWait", self)
	self.wait_timer = ApolloTimer.Create(1, true, "OnWait", self)
end
local wait_counter = 0
function DKP:OnWait()
	if wait_counter == 1 then 
		if bInitialized == false then
			self:BidCompleteInit() 
		else
			self:BidInsertChildren()
		end
	else 
		wait_counter = wait_counter + 1 
	end
end

function DKP:BidCompleteInit()
	wait_counter = 0
	self.wait_timer:Stop()
	bInitialized = true
	
	--Hook.wndLooter:Show(true,false)
	--Hook.wndMasterLoot:Show(true,false)
	Apollo.RegisterEventHandler("MasterLootUpdate","BidUpdateItemDatabase", self)
	if self.ItemDatabase == nil then
		self.ItemDatabase = {}
	end
	self.RegistredBidWinners = {}
	self.RegisteredWinnersByName = {}
	self.InsertedIndicators = {}
	self.ActiveIndicators = {}
	self.InsertedCountersList = {}
	self.SelectedLooterItem = nil
	self.SelectedMasterItem = nil
	self.wndInsertedLooterButton = Apollo.LoadForm(self.xmlDoc,"InsertLooterBid",Hook.wndLooter,self)
	self.wndInsertedLooterButton:Enable(false)
	self.wndInsertedMasterButton = Apollo.LoadForm(self.xmlDoc,"InsertMasterBid",Hook.wndMasterLoot,self)
	self.wndInsertedMasterButton:Enable(false)
	
	self.PrevSelectedLooterItem = nil
	self.CurrentItemChatStr = nil
	
	-- Anchors stuff
	
	if self.tItems["settings"].BidAnchorInsertion == nil then
		Hook.wndLooter:SetAnchorPoints(0,0,0,0)
		local l,t,r,b = Hook.wndLooter:GetAnchorOffsets()
		Hook.wndLooter:SetAnchorOffsets(l,t,r,b+30)
		self.tItems["settings"].BidAnchorInsertion = 1
	end
	local l,t,r,b = Hook.wndMasterLoot:FindChild("Assignment"):GetAnchorOffsets()
	self.wndInsertedMasterButton:SetAnchorPoints(0.5,1,1,1)
	Hook.wndMasterLoot:FindChild("Assignment"):SetAnchorOffsets(l,t,r,b-22)
	
	
	-- Proper Bidding window
	
	self.wndBid = Apollo.LoadForm(self.xmlDoc2,"BiddingUI",nil,self)
	self.wndBid:Show(false,true)
	
	self.wndBiddersList = self.wndBid:FindChild("MainFrame"):FindChild("BiddersList")
	
	
	if self.tItems["settings"].BidMin ~= nil then self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("MinimumBidContainer"):FindChild("Field"):SetText(self.tItems["settings"].BidMin) end
	if self.tItems["settings"].BidCount ~= nil then self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("FinalCountDownTimer"):FindChild("Field"):SetText(self.tItems["settings"].BidCount) end
	if self.tItems["settings"].BidOver ~= nil then self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("MinimumOverBid"):FindChild("Field"):SetText(self.tItems["settings"].BidOver) end
	if self.tItems["settings"].BidAllowOffspec ~= nil and self.tItems["settings"].BidAllowOffspec == 1 then self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("AllowOffspec"):SetCheck(true) end
	if self.tItems["settings"].BidSpendOneMore == nil then self.tItems["settings"].BidSpendOneMore = 0 end
	if self.tItems["settings"].BidSpendOneMore == 1 then self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("GlobalOptions"):FindChild("OneMore"):SetCheck(true) end
	if self.tItems["settings"].BidRollModifier == nil then self.tItems["settings"].BidRollModifier = 5 end
	self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Roll"):FindChild("EditBox"):SetText(self.tItems["settings"].BidRollModifier)
	
	self.ChannelPrefix = "/party "
	self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("GlobalOptions"):FindChild("PartyMode"):SetCheck(true)
	
	
	self:BidCheckConditions()
	
	self.bIsBidding = false

	
	--Tests
	--[[Apollo.LoadForm(Hook.xmlDoc,"LooterItemButton",Hook.wndLooter_ItemList,self)
	local lol3 = Apollo.LoadForm(Hook.xmlDoc,"LooterItemButton",Hook.wndLooter_ItemList,self)
	lol3:FindChild("ItemName"):SetText("BiggerWeapun")
	local lol = Apollo.LoadForm(Hook.xmlDoc,"CharacterButton",Hook.wndMasterLoot_LooterList,self)
	lol:FindChild("CharacterName"):SetText("Drutol Windchaser")
	Apollo.LoadForm(Hook.xmlDoc,"CharacterButton",Hook.wndMasterLoot_LooterList,self)
	
	local lol1 = Apollo.LoadForm(Hook.xmlDoc,"ItemButton",Hook.wndMasterLoot_ItemList,self)
	lol1:FindChild("ItemName"):SetText("Galactium Chunk")
	Hook.wndLooter_ItemList:ArrangeChildrenVert()
	Hook.wndMasterLoot_LooterList:ArrangeChildrenVert()
	Hook.wndMasterLoot_ItemList:ArrangeChildrenVert()]]
	
	-- Resume
	
	if self.tItems["BidRes"] ~= nil then self:BidResumeSession() end
	
	self:BidInsertChildren()
end

function DKP:BidResumeSession()

end

function DKP:BidSelectedChannelChanged( wndHandler, wndControl, eMouseButton )
	Print(wndControl:GetText())
	if wndControl:GetText() == "   Party" then self.ChannelPrefix = "/party " end
	if wndControl:GetText() == "   Guild" then self.ChannelPrefix = "/guild " end
	Print(self.ChannelPrefix)
end

--[[function DKP:BidSelectedChannelCheck( wndHandler, wndControl, eMouseButton )
	if wndControl:GetParent():FindChild("GuildMode"):IsChecked() == false and wndControl:GetParent():FindChild("PartyMode"):IsChecked() == false then
		wndControl:GetParent():FindChild("PartyMode"):SetCheck(true)
		self.ChannelPrefix = "/party "
	end
end]]


function DKP:BidCheckConditions()
	if self.tItems["settings"].BidMin ~= nil and self.tItems["settings"].BidCount ~= nil and self.bIsBidding == false and self.tItems["settings"].BidOver ~= nil then
		self.wndBid:FindChild("ControlsContainer"):FindChild("ButtonStart"):Enable(true)
		self.wndBid:FindChild("ControlsContainer"):FindChild("ButtonStop"):Enable(false)
	else
		self.wndBid:FindChild("ControlsContainer"):FindChild("ButtonStart"):Enable(false)
		self.wndBid:FindChild("ControlsContainer"):FindChild("ButtonStop"):Enable(false)
	end
	
	if self.bIsBidding == true then
		self.wndBid:FindChild("ControlsContainer"):FindChild("ButtonStop"):Enable(true)
		self.wndBid:FindChild("ControlsContainer"):FindChild("ButtonStart"):Enable(false)
	end
	
	
end

function DKP:BidUpdateItemDatabase()
	local curItemList = GameLib.GetMasterLoot()
	if curItemList ~= nil then
		for i=1,table.getn(curItemList) do
			self.ItemDatabase[curItemList[i]:GetName()] = {}
			self.ItemDatabase[curItemList[i]:GetName()].ID= curItemList[i]:GetItemId()
			self.ItemDatabase[curItemList[i]:GetName()].quality = curItemList[i]:GetItemQuality()
			self.ItemDatabase[curItemList[i]:GetName()].strChat = curItemList[i]:GetChatLinkString()
			self.ItemDatabase[curItemList[i]:GetName()].sprite = curItemList[i]:GetIcon()
			self.ItemDatabase[curItemList[i]:GetName()].strItem = curItemList[i]:GetName()
			self.ItemDatabase[curItemList[i]:GetName()].Power = curItemList[i]:GetItemPower()
			if curItemList[i]:GetSlotName() ~= "" then
				self.ItemDatabase[curItemList[i]:GetName()].slot = curItemList[i]:GetSlotName()
			else
				self.ItemDatabase[curItemList[i]:GetName()].slot = curItemList[i]:GetSlot()
			end
		end
	end
	
	self.wait_timer = ApolloTimer.Create(1, true, "OnWait", self)
end

function DKP:BidInsertChildren()
	self.wait_timer:Stop()
	wait_counter = 0 
	if #self.InsertedCountersList ~= #Hook.wndMasterLoot_LooterList:GetChildren() then 
		self.InsertedCountersList = {} 
		self.InsertedIndicators ={}
		self.ActiveIndicators = {}
	end
	
	local looterChildren = Hook.wndLooter_ItemList:GetChildren()
	for i=1,#looterChildren do
			looterChildren[i]:AddEventHandler("MouseButtonUp", "BidLooterItemSelected", self)
	end
	
	local masterChildren = Hook.wndMasterLoot_LooterList:GetChildren()
	for i=1,#masterChildren do
		local strName = masterChildren[i]:FindChild("CharacterName"):GetText()
		local ID = self:GetPlayerByIDByName(strName)
		if ID ~= -1 then
			local wndCounter = Apollo.LoadForm(self.xmlDoc,"InsertDKPIndicator",masterChildren[i],self)
			masterChildren[i]:AddEventHandler("ButtonCheck", "BidMasterPlayerSelected", self)
			masterChildren[i]:AddEventHandler("ButtonUncheck", "BidMasterPlayerUnSelected", self)
			wndCounter:SetText("DKP : ".. self.tItems[ID].net)
			wndCounter:FindChild("Indicator"):Show(false,true)
			self.InsertedCountersList[strName] = wndCounter
		end
	end
	
	local masterLootChildren = Hook.wndMasterLoot_ItemList:GetChildren()
	
	for i=1,#masterLootChildren do
		masterLootChildren[i]:AddEventHandler("ButtonCheck", "BidMasterItemSelected", self)
		masterLootChildren[i]:AddEventHandler("ButtonUncheck", "BidMasterItemUnSelected", self)
		local indi = Apollo.LoadForm(self.xmlDoc,"InsertItemIndicator",masterLootChildren[i],self)
		indi:Show(false,true)
		self.InsertedIndicators[masterLootChildren[i]:FindChild("ItemName"):GetText()] = indi
	end
	
	self.wndInsertedLooterButton:Enable(false)
	self.SelectedLooterItem = nil
end

function DKP:BidMasterPlayerSelected(wndHandler,wndControl)
	self:BidMatchIndicatorsByPlayer(wndControl:FindChild("CharacterName"):GetText())
end

function DKP:BidMasterPlayerUnSelected(wndHandler,wndControl)
	self:BidResetIndicators()
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

function DKP:BidMasterItemSelected(wndHandler,wndControl)
	self.SelectedMasterItem = wndControl:FindChild("ItemName"):GetText()
	self.wndInsertedMasterButton:Enable(true)
	self:BidMatchIndicatorsByItem(self.SelectedMasterItem)
end

function DKP:BidMasterItemUnSelected(wndHandler,wndControl)
	self.SelectedMasterItem = nil
	self.wndInsertedMasterButton:Enable(false)
	self:BidResetIndicators()
end

function DKP:BidSetUpWindow(tCustomData)
	if self.bIsBidding == false then
		if tCustomData.strItem == nil then
			if Hook.wndMasterLoot:IsShown() == false then
				self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):SetText(self.SelectedLooterItem)
				if self.ItemDatabase[self.SelectedLooterItem] ~= nil then
					self.CurrentItemChatStr = self.ItemDatabase[self.SelectedLooterItem].strChat
					self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("ItemIcon"):SetSprite(self.ItemDatabase[self.SelectedLooterItem].sprite)
				end
			else
				self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):SetText(self.SelectedMasterItem)
				if self.ItemDatabase[self.SelectedMasterItem] ~= nil then
					self.CurrentItemChatStr = self.ItemDatabase[self.SelectedMasterItem].strChat
					self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("ItemIcon"):SetSprite(self.ItemDatabase[self.SelectedMasterItem].sprite)
				end
			end
		else
			self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):SetText(tCustomData.strItem)
			self.CurrentItemChatStr = nil
		end
		if self.CurrentItemChatStr == nil then self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("ButtonLink"):Enable(false)
		else self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("ButtonLink"):Enable(true) end
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Standard"):FindChild("BoxOpen"):SetCheck(true)
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Standard"):FindChild("BoxHidden"):SetCheck(false)
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Roll"):FindChild("PureRoll"):SetCheck(false)
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Roll"):FindChild("ModifiedRoll"):SetCheck(false)
		
		self.wndBid:Show(true,false)
		self:BidCheckConditions()
	else
		self.wndBid:Show(true,false)
	end
end

function DKP:BidStartCustom( wndHandler, wndControl, eMouseButton )
	local over = wndControl:GetParent():FindChild("CustomAuction"):GetText()
	self:BidSetUpWindow({strItem = over})
end

function DKP:BidLinkItem()
	if self.CurrentItemChatStr ~= nil then
		ChatSystemLib.Command(self.ChannelPrefix .. self.CurrentItemChatStr)
	end
end


function DKP:BidSetMin( wndHandler, wndControl, eMouseButton )
	if tonumber(self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("MinimumBidContainer"):FindChild("Field"):GetText()) == nil then
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("MinimumBidContainer"):FindChild("Field"):SetText("Minimum Bid")
		self.tItems["settings"].BidMin = nil
	else
		self.tItems["settings"].BidMin = math.abs(tonumber(self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("MinimumBidContainer"):FindChild("Field"):GetText()))	
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("MinimumBidContainer"):FindChild("Field"):SetText(self.tItems["settings"].BidMin)
	end
	self:BidCheckConditions()
end

function DKP:BitSetCountdown( wndHandler, wndControl, eMouseButton )
	if tonumber(self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("FinalCountDownTimer"):FindChild("Field"):GetText()) == nil then
		self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("FinalCountDownTimer"):FindChild("Field"):SetText("Final Countdown")
	else
		local value = math.abs(tonumber(self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("FinalCountDownTimer"):FindChild("Field"):GetText()))
		if value >= 1 and value <= 6 then
			self.tItems["settings"].BidCount = value
			self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("FinalCountDownTimer"):FindChild("Field"):SetText(self.tItems["settings"].BidCount)
		else
			self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("FinalCountDownTimer"):FindChild("Field"):SetText("Final Countdown")
			self.tItems["settings"].BidCount = nil
		end
	end
	self:BidCheckConditions()
end

function DKP:BidStart(strName)
	self.mode = nil
	if self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Standard1"):FindChild("BoxHidden"):IsChecked() == true then self.mode = "hidden" 
	elseif self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Standard"):FindChild("BoxOpen"):IsChecked() == true  then  self.mode = "open"
	elseif self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Roll"):FindChild("PureRoll"):IsChecked() == true then self.mode = "pure"
	elseif self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("Roll"):FindChild("ModifiedRoll"):IsChecked() == true then self.mode = "modified"
	elseif self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("EPGP"):FindChild("BoxOpen"):IsChecked() == true then self.mode = "EPGP" end

	Print(self.mode)
	if self.mode ~= nil then
		Print("LOL")
		if self.CurrentBidSession == nil then
			self.CurrentBidSession = {} 
			self.CurrentBidSession.HighestBidEver = {}
			self.CurrentBidSession.HighestBidEver.value = 0
			self.CurrentBidSession.HighestBidEver.name = ""
			self.CurrentBidSession.Bidders = {}
			self.CurrentBidSession.strItem = self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()
			self.CurrentBidSession.HighestOffBid = {}
			self.CurrentBidSession.HighestOffBid.name = "" 
			self.CurrentBidSession.HighestOffBid.value = 0
		end


		Apollo.RegisterEventHandler("ChatMessage","BidMessage",self)
		self.bIsBidding = true
		self:BidCheckConditions()
		self.bAllowOffspec = self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("AllowOffspec"):IsChecked()
		
		
		if self.mode == "open" then
				if self.CurrentItemChatStr == nil then	
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP] Bidding is now starting in open open mode.You are bidding for " .. self.CurrentBidSession.strItem .. " , if you want to participate write the amount of DKP you want to spend on this item in /party channel.Minimum bid is : " .. self.tItems["settings"].BidMin .. " and the final count down timer is set to : " .. self.tItems["settings"].BidCount .. ".Good Luck!")
				else
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP]Bidding is now starting in open open mode.You are bidding for " .. self.CurrentItemChatStr .. " , if you want to participate write the amount of DKP you want to spend in this item in /party channel.Minimum bid is : " .. self.tItems["settings"].BidMin .. " and the final count down timer is set to : " .. self.tItems["settings"].BidCount .. ".Good Luck!")
				end
				if self.bAllowOffspec == true then 
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP] Note: Offspec bidding is enabled , in order to switch to offspec mode write '!off' in current channel.After you change your mode you cannot change it again") 
				end
		elseif self.mode == "hidden" then
				if self.CurrentItemChatStr == nil then	
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP] Bidding is now starting in hidden mode.You are bidding for " .. self.CurrentBidSession.strItem .. " , if you want to participate whisper the amout of dkp to : " .. GameLib:GetPlayerUnit():GetName() ..".Minimum bid is : " .. self.tItems["settings"].BidMin .. " and the final count down timer is set to : " .. self.tItems["settings"].BidCount .. ".Good Luck!")
				else
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP] Bidding is now starting in hidden mode.You are bidding for " .. self.CurrentItemChatStr .. " , if you want to participate whisper the amout of dkp to : " .. GameLib:GetPlayerUnit():GetName() ..".Minimum bid is : " .. self.tItems["settings"].BidMin .. " and the final count down timer is set to : " .. self.tItems["settings"].BidCount .. ".Good Luck!")
				end
				if self.bAllowOffspec == true then 
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP] Note: Offspec bidding is enabled , in order to switch to offspec mode write '!off' to person in charge of bidding.After you change your mode you cannot change it again") 
				end
		elseif self.mode == "pure" then
				if self.CurrentItemChatStr == nil then
					ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] Type /roll in order to participate in an auction for item " .. self.CurrentBidSession.strItem ..".")
				else
					ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] Type /roll in order to participate in an auction for item " .. self.CurrentItemChatStr ..".")
				end
		elseif self.mode == "modified" then
				if self.CurrentItemChatStr == nil then
					ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] Type /roll in order to participate in an auction for item " .. self.CurrentBidSession.strItem ..".This is modified roll : ".. self.tItems["settings"].BidRollModifier .. "% of your DKP will be added to roll and the whole value will be subtracted from your account.")
				else
					ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] Type /roll in order to participate in an auction for item " .. self.CurrentItemChatStr ..".This is modified roll : ".. self.tItems["settings"].BidRollModifier .. "% of your DKP will be added to roll and the whole value will be subtracted from your account.")
				end
		elseif self.mode == "EPGP" then
				if self.CurrentItemChatStr == nil then
					ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] If you want to participate in an auction for item " .. self.CurrentBidSession.strItem .." write !want in /party channel , for offspec write !off ; offspec PR is decreased by " .. self.tItems["settings"].BidEPGPOffspec .. ".")
				else
					ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] If you want to participate in an auction for item" .. self.CurrentItemChatStr .." write !want in /party channel.")
				end
				if self.bAllowOffspec == true then 
					ChatSystemLib.Command(self.ChannelPrefix ..  " [EasyDKP] Note: Offspec bidding is enabled ,  for offspec write !off ; offspec PR is decreased by " .. self.tItems["settings"].BidEPGPOffspec .. ".")
				end
		end
	end
end

function DKP:BidSetOffspecModifierForEPGP( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		value = tonumber(strText)
		if value >= 1 and value <=100 then
			self.tItems["settings"].BidEPGPOffspec = value
		else
			wndControl:SetText(self.tItems["settings"].BidEPGPOffspec)
		end
	else
		wndControl:SetText("")
	end
end

function DKP:BidMessage(channelCurrent, tMessage)
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Party and self.mode == "open" and self.ChannelPrefix == "/party " or  channelCurrent:GetType() == ChatSystemLib.ChatChannel_Guild and self.mode == "open" and self.ChannelPrefix == "/guild " then
		local strResult = self:BidProcessMessageDKP({strMsg = tMessage.arMessageSegments[1].strText,strSender = tMessage.strSender})
		if strResult == -1 then return end
		ChatSystemLib.Command(self.ChannelPrefix .. strResult)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper and self.mode == "hidden" then
		local strResult = self:BidProcessMessageDKP({strMsg = tMessage.arMessageSegments[1].strText,strSender = tMessage.strSender})
		if strResult == -1 then return end
		ChatSystemLib.Command("/w " .. tMessage.strSender .. " " .. strResult)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_System and self.mode == "pure" then
		local strResult = self:BidProcessMessageRoll({strMsg = tMessage.arMessageSegments[1].strText,strSender = tMessage.strSender})
		ChatSystemLib.Command(self.ChannelPrefix .. strResult)
	elseif channelCurrent:GetType() == ChatSystemLib.ChatChannel_System and self.mode == "modified" then
		local strResult = self:BidProcessMessageRoll({strMsg = tMessage.arMessageSegments[1].strText,strSender = tMessage.strSender})
		ChatSystemLib.Command(self.ChannelPrefix .. strResult)
	end
end

function DKP:BidProcessMessageEPGP(tData)
	local strReturn = ""
	
	
	


	return strReturn
end

function DKP:BidProcessMessageRoll(tData)
	local strReturn = ""
	
	local words = {}
	for word in string.gmatch(tData.strMsg,"%S+") do
		table.insert(words,word)
	end
	
	if #words < 5 then 
		strReturn = "Critical Error"
		return strReturn
	end
	if words[5] ~= "(1-100)" then
		strReturn = "Wrong Range"
		return strReturn
	end
	
	
		local strRoller = words[1] .. " " .. words[2]
		local ID = self:GetPlayerByIDByName(strRoller)
		for i=1,table.getn(self.CurrentBidSession.Bidders) do
			if self.CurrentBidSession.Bidders[i].strName == strRoller then
				strReturn = "Already Rolled"
				return strReturn
			end
		end
		local roll = tonumber(words[4])
		local newBidder = {}
		newBidder.strName = strRoller
		if self.mode == "pure" then
			newBidder.HighestBid = roll
		elseif self.mode == "modified" then
			newBidder.HighestBid = roll + math.floor(math.abs(self.tItems[ID].net) * (self.tItems["settings"].BidRollModifier/100))
			newBidder.mod = (math.floor(math.abs(self.tItems[ID].net) * (self.tItems["settings"].BidRollModifier/100)))
		end
		newBidder.offspec = false
		if newBidder.HighestBid > self.CurrentBidSession.HighestBidEver.value then
			self.CurrentBidSession.HighestBidEver.value = newBidder.HighestBid
			self.CurrentBidSession.HighestBidEver.name = newBidder.strName
		end
		
		table.insert(self.CurrentBidSession.Bidders,newBidder)
		strReturn = "Succes"
	self:BidUpdateBiddersList()
	self:BidUpdateStats()
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

	
	if tonumber(tData.strMsg) == nil and tData.strMsg ~= "!off" then return -1 end
	
	
	local nBidderID = 0
	
	for i=1,#self.CurrentBidSession.Bidders do
		if self.CurrentBidSession.Bidders[i].strName == tData.strSender then
			nBidderID = i
			break
		end
	end
	
	if nBidderID == 0 then
		local newBidder = {}
		newBidder.HighestBid = 0
		newBidder.strName = tData.strSender
		newBidder.offspec= false
		
		if tonumber(tData.strMsg) == nil and tData.strMsg == "!off" then
			if self.bAllowOffspec == true then
				newBidder.offspec = true
				strReturn = "Offspec mode"
			else
				strReturn = "Offspec is not allowed"
			end
		else
			local modifier = tonumber(tData.strMsg) - self.CurrentBidSession.HighestBidEver.value
			if modifier > self.tItems["settings"].BidOver and tonumber(tData.strMsg) > self.tItems["settings"].BidMin then 
				newBidder.HighestBid = tonumber(tData.strMsg)
				if newBidder.HighestBid > self.CurrentBidSession.HighestBidEver.value then
					self.CurrentBidSession.HighestBidEver.value = newBidder.HighestBid
					self.CurrentBidSession.HighestBidEver.name = newBidder.strName
				end
					strReturn = "Bid processed"
			else
				if self.mode == "open" then
					strReturn = "Failure - too small difference"
				elseif self.mode == "hidden" then
					strReturn = "Bid processed"
				end
			end
		end
		table.insert(self.CurrentBidSession.Bidders,newBidder)	
	else
		
		if tonumber(tData.strMsg) == nil and tData.strMsg == "!off" then
			if self.bAllowOffspec == true then
				if self.CurrentBidSession.Bidders[nBidderID].offspec == false then -- Prevent multiple conversions
					if self.CurrentBidSession.HighestBidEver.name == self.CurrentBidSession.Bidders[nBidderID].strName then
						--Search for 2nd highest
						local highest ={}
						highest.name = ""
						highest.value = 0
						for i=1,table.getn(self.CurrentBidSession.Bidders) do
							if self.CurrentBidSession.Bidders[i].HighestBid > highest.value and i ~= nBidderID then
								highest.name = self.CurrentBidSession.Bidders[i].strName
								highest.value = self.CurrentBidSession.Bidders[i].HighestBid
							end
						end
						self.CurrentBidSession.HighestBidEver = highest
					end
					-- Determine whether previous bid is higher than highest bid in offspec
					if self.CurrentBidSession.HighestOffBid.value < self.CurrentBidSession.Bidders[nBidderID].HighestBid then
						self.CurrentBidSession.HighestOffBid.name = self.CurrentBidSession.Bidders[nBidderID].strName
						self.CurrentBidSession.HighestOffBid.value = self.CurrentBidSession.Bidders[nBidderID].HighestBid
					end
				end
				self.CurrentBidSession.Bidders[nBidderID].offspec = true
				strReturn = "Offspec mode"
				
			else
				strReturn = "Offspec is not allowed"
			end
		else
			if self.CurrentBidSession.Bidders[nBidderID].offspec == false then
				local value = tonumber(tData.strMsg)
				
				if value < self.CurrentBidSession.Bidders[nBidderID].HighestBid then
					strReturn = "Failure - smaller than previous bid"
				else
					local modifier = value - self.CurrentBidSession.HighestBidEver.value
					if  modifier > self.tItems["settings"].BidOver and tonumber(tData.strMsg) > self.tItems["settings"].BidMin then
						self.CurrentBidSession.Bidders[nBidderID].HighestBid = value
						strReturn = "Bid processed"
						if value > self.CurrentBidSession.HighestBidEver.value then
							self.CurrentBidSession.HighestBidEver.value = self.CurrentBidSession.Bidders[nBidderID].HighestBid
							self.CurrentBidSession.HighestBidEver.name = self.CurrentBidSession.Bidders[nBidderID].strName
							strReturn = "Bid processed"
						end
					else	
						if self.mode == "open" then
							strReturn = "Failure - too small difference"
						elseif self.mode == "hidden" then
							strReturn = "Bid processed"
						end
					end
				end
			else -- offspec == true
				local value = tonumber(tData.strMsg)
				if value < self.CurrentBidSession.Bidders[nBidderID].HighestBid then
					strReturn = "Failure - smaller than previous bid"
				else
					local modifier = value - self.CurrentBidSession.HighestOffBid.value
					if  modifier > self.tItems["settings"].BidOver and tonumber(tData.strMsg) > self.tItems["settings"].BidMin then
						self.CurrentBidSession.Bidders[nBidderID].HighestBid = value
						strReturn = "Bid processed"
						if value > self.CurrentBidSession.HighestOffBid.value then
							self.CurrentBidSession.HighestOffBid.value = self.CurrentBidSession.Bidders[nBidderID].HighestBid
							self.CurrentBidSession.HighestOffBid.name = self.CurrentBidSession.Bidders[nBidderID].strName
							strReturn = "Bid processed"
						end
					else	
						if self.mode == "open" then
							strReturn = "Failure - too small difference"
						elseif self.mode == "hidden" then
							strReturn = "Bid processed"
						end
					end
				end
			end
		end
	end
	self:BidUpdateBiddersList()
	self:BidUpdateStats()
	return strReturn
end

function DKP:BidUpdateStats()
	self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("Stats"):FindChild("Name"):SetText(self.CurrentBidSession.HighestBidEver.name)
	self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("Stats"):FindChild("Bid"):SetText(self.CurrentBidSession.HighestBidEver.value)

	if self.CurrentBidSession.HighestOffBid.name == "" then return end
	self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("Stats"):FindChild("Name1"):SetText(self.CurrentBidSession.HighestOffBid.name)
	self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("Stats"):FindChild("Bid1"):SetText(self.CurrentBidSession.HighestOffBid.value)
end

function compare_easyDKP_bidders(a,b)
  return a.value > b.value
end

function DKP:BidUpdateBiddersList()
	self.wndBiddersList:DestroyChildren()
	
	local tIDsOrder = {}
	for i=1,#self.CurrentBidSession.Bidders do
		local k = {}
		k.name = self.CurrentBidSession.Bidders[i].strName
		k.value = self.CurrentBidSession.Bidders[i].HighestBid
		if self.CurrentBidSession.Bidders[i].offspec == true then
			k.value = k.value - 10000
		end
		table.insert(tIDsOrder,k)
	end
	table.sort(tIDsOrder,compare_easyDKP_bidders)
	for i=1,#tIDsOrder do
		for j=1,#self.CurrentBidSession.Bidders do
			if tIDsOrder[i].name == self.CurrentBidSession.Bidders[j].strName then
				tIDsOrder[i] = j
				break
			end
		end
	end
	
	
	for i=1,#tIDsOrder do
		local wnd = Apollo.LoadForm(self.xmlDoc,"BidderItem",self.wndBiddersList,self)
		wnd:FindChild("Name"):SetText(self.CurrentBidSession.Bidders[tIDsOrder[i]].strName)
		wnd:FindChild("Bid"):SetText(self.CurrentBidSession.Bidders[tIDsOrder[i]].HighestBid)
		 if self.CurrentBidSession.Bidders[tIDsOrder[i]].offspec == true then
			wnd:FindChild("Off"):SetText("Offspec")
		 end
		 if self.mode == "modified" then
			wnd:FindChild("Off"):SetText("Modifier: " .. self.CurrentBidSession.Bidders[tIDsOrder[i]].mod)
		 end
	end
	tIDsOrder = {}
	self.wndBiddersList:ArrangeChildrenVert()
end

function DKP:BidInitCountdown()
	self.BidCounter = 0
	self.BidCountdown = ApolloTimer.Create(1,true,"BidPerformCountdown",self)
	Apollo.RegisterTimerHandler("BidPerformCountdown","BidPerformCountdown",self)
	ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] " .. self.tItems["settings"].BidCount)
end

function DKP:BidPerformCountdown()
	self.BidCounter = self.BidCounter + 1
	if self.BidCounter == self.tItems["settings"].BidCount then
		self.BidCountdown:Stop()
		
		-- Check for Spend one more
		
		 if self.wndBid:FindChild("ControlsContainer"):FindChild("OptionsContainer"):FindChild("ModeOptions"):FindChild("GlobalOptions"):FindChild("OneMore"):IsChecked() == true then 
			local value = 0
			for i=1,table.getn(self.CurrentBidSession.Bidders) do
				if self.CurrentBidSession.Bidders[i].HighestBid > value and i ~= self:GetPlayerByIDByName(self.CurrentBidSession.HighestBidEver.name) then
					value = self.CurrentBidSession.Bidders[i].HighestBid
				end
			end
			if value ~= 0 then
				self.CurrentBidSession.HighestBidEver.value = value + 1
			end
		 end
		
		
		if self.CurrentBidSession.HighestBidEver.name ~= "" then
			ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] Bidding has ended, and the winner is...")
			ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] " .. self.CurrentBidSession.HighestBidEver.name .. " for " .. self.CurrentBidSession.HighestBidEver.value .. "DKP")
			self.RegistredBidWinners[self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()] = {}
			self.RegistredBidWinners[self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()].strName = self.CurrentBidSession.HighestBidEver.name
			self.RegistredBidWinners[self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()].cost = self.CurrentBidSession.HighestBidEver.value
			self.RegisteredWinnersByName[self.CurrentBidSession.HighestBidEver.name] = self.CurrentBidSession.strItem
			if Hook.wndMasterLoot:IsShown() == true then self:BidMatchIndicatorsByItem(self.CurrentBidSession.strItem) end
		elseif self.CurrentBidSession.HighestOffBid.name ~= "" then
			ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] Bidding has ended, and the winner is... (offspec)")
			ChatSystemLib.Command(self.ChannelPrefix .. self.CurrentBidSession.HighestOffBid.name .. " for " .. self.CurrentBidSession.HighestOffBid.value .. "DKP")
			self.RegistredBidWinners[self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()] = {}
			self.RegistredBidWinners[self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()].strName = self.CurrentBidSession.HighestOffBid.name
			self.RegistredBidWinners[self.wndBid:FindChild("ControlsContainer"):FindChild("ItemInfoContainer"):FindChild("HeaderItem"):GetText()].cost = self.CurrentBidSession.HighestOffBid.value
			self.RegisteredWinnersByName[self.CurrentBidSession.HighestBidEver.name] = self.CurrentBidSession.strItem
			if Hook.wndMasterLoot:IsShown() == true then self:BidMatchIndicatorsByItem(self.CurrentBidSession.strItem) end
		else
			ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] No bids were processed")
		end

			self.bIsBidding = false

			self:BidCheckConditions()
			--self:PopUpWindowOpen(self.CurrentBidSession.HighestBidEver.name,self.CurrentBidSession.strItem)
			self.CurrentBidSession = nil
			self.wndBiddersList:DestroyChildren()
			Apollo.RemoveEventHandler("ChatMessage",self)
	else
		ChatSystemLib.Command(self.ChannelPrefix .. " [EasyDKP] " .. tostring(self.tItems["settings"].BidCount - self.BidCounter) .. "...")
	end
end

function DKP:BidMatchIndicatorsByPlayer(strName)
	if self.RegisteredWinnersByName[strName] == nil or self.InsertedIndicators[self.RegisteredWinnersByName[strName]] == nil then return end
	self.InsertedIndicators[self.RegisteredWinnersByName[strName]]:Show(true,false)
	table.insert(self.ActiveIndicators,self.InsertedIndicators[self.RegisteredWinnersByName[strName]])
end

function DKP:BidMatchIndicatorsByItem(strItem)
	if self.RegistredBidWinners[strItem] == nil or self.InsertedCountersList[self.RegistredBidWinners[strItem].strName] == nil then return end
	self.InsertedCountersList[self.RegistredBidWinners[strItem].strName]:FindChild("Indicator"):Show(true,false)
	table.insert(self.ActiveIndicators,self.InsertedCountersList[self.RegistredBidWinners[strItem].strName]:FindChild("Indicator"))
end

function DKP:BidResetIndicators()
	for i=1,#self.ActiveIndicators do
		self.ActiveIndicators[i]:Show(false,false)
	end
	self.ActiveIndicators = {}
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
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and string.lower(self.tItems[i].strName) == string.lower(strName) then return i end
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
