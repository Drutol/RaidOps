-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2014	 dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

local DKP = Apollo.GetAddon("EasyDKP")
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

-- constants from ETooltip
local kUIBody = "ff39b5d4"
local nItemIDSpacing = 4


function DKP:EPGPInit()
	self.wndEPGPSettings = Apollo.LoadForm(self.xmlDoc2,"RDKP/EPGP",nil,self)
	self.wndEPGPItems = Apollo.LoadForm(self.xmlDoc2,"CostList",nil,self)
	self.wndEPGPSettings:Show(false,true)
	self.wndEPGPItems:Show(false,true)
	if self.tItems["EPGP"] == nil then
		self.tItems["EPGP"] = {}
		self.tItems["EPGP"].SlotValues = defaultSlotValues
		self.tItems["EPGP"].QualityValues = defaultQualityValues
		self.tItems["EPGP"].Enabled = 0
		self.tItems["EPGP"].FormulaModifier = 0.5
		self.tItems["EPGP"].BaseGP = 1
		self.tItems["EPGP"].MinEP = 100
	end
	self:EPGPFillInSettings()
	self:EPGPAddValuesToMembers()
	self:EPGPChangeUI()
	
	--Apollo.RegisterEventHandler("ItemLink", "OnLootedItem", self)
	

end

function DKP:OnLootedItem(item)
			self.ItemDatabase[item:GetName()] = {}
			self.ItemDatabase[item:GetName()].ID = item:GetItemId()
			self.ItemDatabase[item:GetName()].quality = item:GetItemQuality()
			self.ItemDatabase[item:GetName()].strChat = item:GetChatLinkString()
			self.ItemDatabase[item:GetName()].sprite = item:GetIcon()
			self.ItemDatabase[item:GetName()].strItem = item:GetName()
			self.ItemDatabase[item:GetName()].Power = item:GetItemPower()
			if item:GetSlotName() ~= "" then
				self.ItemDatabase[item:GetName()].slot = item:GetSlotName()
			else
				self.ItemDatabase[item:GetName()].slot = item:GetSlot()
			end
			--if item:GetSlotName() == nil then self.ItemDatabase[item:GetName()] = nil end
			Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), item:GetName(), "Player"..tostring(math.random(2,14))))
end

function DKP:EPGPRestore()
	

end

function DKP:EPGPFillInSettings()
	--Slots
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Weapon"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue1"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Shield"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue2"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Head"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue3"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Shoulders"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue4"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Chest"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue5"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Hands"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue6"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Legs"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue7"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Feet"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue8"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Attachment"])
	self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue9"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Support"])
          self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue10"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Gadget"])
          self.wndEPGPSettings:FindChild("ItemCost"):FindChild("SlotValue11"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Implant"])
	--Rest
	self.wndEPGPSettings:FindChild("FormulaLabel"):FindChild("CustomModifier"):SetText(self.tItems["EPGP"].FormulaModifier)
	self.wndEPGPSettings:FindChild("PurpleQual"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValues["Purple"])
	self.wndEPGPSettings:FindChild("OrangeQual"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValues["Orange"])
	self.wndEPGPSettings:FindChild("MinEP"):SetText(self.tItems["EPGP"].MinEP)
	self.wndEPGPSettings:FindChild("BaseGP"):SetText(self.tItems["EPGP"].BaseGP)
	if self.tItems["EPGP"].Enable == 1 then self.wndEPGPSettings:FindChild("Enable"):SetCheck(true) end
	if self.tItems["EPGP"].ForceItemSave == 1 then self.wndEPGPItems:FindChild("ButtonForceSave"):SetCheck(true) end
	if self.tItems["EPGP"].Tooltips == 1 then
		self.wndSettings:FindChild("ButtonShowGP"):SetCheck(true)
		self:EPGPHookToETooltip()
	end
	
end

function DKP:EPGPGetSlotValueByString(strSlot)
	return self.tItems["EPGP"].SlotValues[strSlot]
end

function DKP:EPGPGetSlotStringByID(ID)
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

function DKP:EPGPGetSlotSpriteByQuality(ID)
	if ID == 5 then return "CRB_Tooltips:sprTooltip_SquareFrame_Purple"
	elseif ID == 6 then return "CRB_Tooltips:sprTooltip_SquareFrame_Orange"
	elseif ID == 4 then return "CRB_Tooltips:sprTooltip_SquareFrame_Blue"
	elseif ID == 3 then return "CRB_Tooltips:sprTooltip_SquareFrame_Green"
	elseif ID == 2 then return "CRB_Tooltips:sprTooltip_SquareFrame_White"
	else return "CRB_Tooltips:sprTooltip_SquareFrame_DarkModded"
	end
end

function DKP:EPGPGetItemCostByName(strItem)
	return math.ceil(self.ItemDatabase[strItem].Power/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(self.ItemDatabase[strItem].quality)] * self.tItems["EPGP"].FormulaModifier * self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(self.ItemDatabase[strItem].slot)])
end

function DKP:EPGPEnableEPChange( wndHandler, wndControl, eMouseButton )
end

function DKP:EPGPDisableGPChange( wndHandler, wndControl, eMouseButton )
end

function DKP:EPGPDisableEPChange( wndHandler, wndControl, eMouseButton )
end

function DKP:EPGPEnableGPChange( wndHandler, wndControl, eMouseButton )
end

function DKP:EPGPChangeUI()
	if self.tItems["EPGP"].Enable == 1 then
		--Main Controls
		local controls = self.wndMain:FindChild("Controls")
		controls:FindChild("EditBox1"):SetText("Input Value") --input
		controls:FindChild("EditBox"):SetAnchorOffsets(25,98,187,144)  -- comment
		controls:FindChild("ButtonEP"):Show(true,false)
		controls:FindChild("ButtonGP"):Show(true,false)
		--Labels
		local labelTypes = self.wndMain:FindChild("LabelOptions"):FindChild("LabelTypes")
		labelTypes:FindChild("EP"):Show(true,false)
		labelTypes:FindChild("GP"):Show(true,false)
		labelTypes:FindChild("PR"):Show(true,false)
		self.wndLabelOptions:FindChild("LabelTypes"):ArrangeChildrenVert()
		self.wndEPGPSettings:FindChild("DecayNow"):Enable(true)
		self.wndMain:FindChild("Title"):SetText("EasyEPGP")
		self.wndSettings:FindChild("ButtonShowGP"):Enable(true)
		if self.tItems["EPGP"].Tooltips == 1 then
			self.wndSettings:FindChild("ButtonShowGP"):SetCheck(true)
			self:EPGPHookToETooltip()
		end
		
	else
		--Main Controls
		local controls = self.wndMain:FindChild("Controls")
		controls:FindChild("EditBox1"):SetText("Input Value") --input
		controls:FindChild("EditBox"):SetAnchorOffsets(25,67,187,146)  -- comment
		controls:FindChild("ButtonEP"):Show(false,false)
		controls:FindChild("ButtonGP"):Show(false,false)
		--Labels
		local labelTypes = self.wndMain:FindChild("LabelOptions"):FindChild("LabelTypes")
		labelTypes:FindChild("EP"):Show(false,false)
		labelTypes:FindChild("GP"):Show(false,false)
		labelTypes:FindChild("PR"):Show(false,false)
		if self:LabelGetColumnNumberForValue("EP") ~= -1 then
			self.tItems["settings"].LabelOptions[self:LabelGetColumnNumberForValue("EP")] = "Nil"
		end
		if self:LabelGetColumnNumberForValue("GP") ~= -1 then
			self.tItems["settings"].LabelOptions[self:LabelGetColumnNumberForValue("GP")] = "Nil"
		end
		if self:LabelGetColumnNumberForValue("PR") ~= -1 then
			self.tItems["settings"].LabelOptions[self:LabelGetColumnNumberForValue("PR")] = "Nil"
		end
		self.wndEPGPSettings:FindChild("DecayNow"):Enable(false)
		self.wndMain:FindChild("Title"):SetText("EasyDKP")
		self.wndSettings:FindChild("ButtonShowGP"):Enable(false)
		if self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then self:UnhookAll() end
		self:LabelUpdateList()
	end
end

function DKP:EPGPAddValuesToMembers()
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if self.tItems[i].EP == nil then self.tItems[i].EP = self.tItems["EPGP"].MinEP end
			if self.tItems[i].GP ==nil then self.tItems[i].GP = self.tItems["EPGP"].BaseGP end
		end
	end
end

function DKP:EPGPReset()
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			self.tItems[i].EP = self.tItems["EPGP"].MinEP
			self.tItems[i].GP = self.tItems["EPGP"].BaseGP
		end
	end
	self.tItems["EPGP"].SlotValues = defaultSlotValues
	self.tItems["EPGP"].QualityValues = defaultQualityValues
	self.tItems["EPGP"].FormulaModifier = 0.5
	self:ShowAll()
	self:EPGPFillInSettings()
end

function DKP:EPGPAdd(strName,EP,GP)
	local ID = self:GetPlayerByIDByName(strName)
	if ID ~= -1 then
		if EP ~= nil then
			self.tItems[ID].EP = self.tItems[ID].EP + EP
			self:RaidRegisterEPManipulation(strName,EP)
		end
		if GP ~= nil then
			self.tItems[ID].GP = self.tItems[ID].GP + GP
		end
	end

end

function DKP:EPGPSubtract(strName,EP,GP)
	local ID = self:GetPlayerByIDByName(strName)
	if ID ~= -1 then
		if EP ~= nil then
			self.tItems[ID].EP = self.tItems[ID].EP - EP
			if self.tItems[ID].EP < self.tItems["EPGP"].MinEP then
				self.tItems[ID].EP = self.tItems["EPGP"].MinEP
			end
			self:RaidRegisterEPManipulation(strName,EP)
		end
		if GP ~= nil then
			self.tItems[ID].GP = self.tItems[ID].GP - GP
			if self.tItems[ID].GP < self.tItems["EPGP"].BaseGP then
				self.tItems[ID].GP = self.tItems["EPGP"].BaseGP
			end
		end
	end

end

function DKP:EPGPSet(strName,EP,GP)
	local ID = self:GetPlayerByIDByName(strName)
	if ID ~= -1 then
		if EP ~= nil then
			self.tItems[ID].EP = EP
			if self.tItems[ID].EP < self.tItems["EPGP"].MinEP then
				self.tItems[ID].EP = self.tItems["EPGP"].MinEP
			end
		end
		if GP ~= nil then
			self.tItems[ID].GP = GP
			if self.tItems[ID].GP < self.tItems["EPGP"].BaseGP then
				self.tItems[ID].GP = self.tItems["EPGP"].BaseGP
			end
		end
	end
end


function DKP:EPGPAwardRaid(EP,GP)
	for i=1,GroupLib.GetMembersCount() do
		local member = GroupLib.GetGroupMember(i)
		if member ~= nil then
			local ID = self:GetPlayerByIDByName(member.strCharacterName)
			if ID ~= -1 then
				if EP ~= nil then
					self.tItems[ID].EP = self.tItems[ID].EP + EP
					if self.tItems[ID].EP < self.tItems["EPGP"].MinEP then
						self.tItems[ID].EP = self.tItems["EPGP"].MinEP
					end
				end
				if GP ~= nil then
					self.tItems[ID].GP = self.tItems[ID].GP + GP
					if self.tItems[ID].GP < self.tItems["EPGP"].BaseGP then
						self.tItems[ID].GP = self.tItems["EPGP"].BaseGP
					end
				end
			end
		end
	end
	self:ShowAll()
end

function DKP:EPGPCheckTresholds()
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if self.tItems[i].EP < self.tItems["EPGP"].MinEP then
				 self.tItems[i].EP = self.tItems["EPGP"].MinEP
			end
			if self.tItems[i].GP < self.tItems["EPGP"].BaseGP then
				 self.tItems[i].GP = self.tItems["EPGP"].BaseGP
			end
		end
	end


end
---------------------------------------------------------------------------------------------------
-- CostList Functions
---------------------------------------------------------------------------------------------------


function DKP:EPGPStartListeningForItem( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].ForceItemSave = 1
end

function DKP:EPGPStopListeningForItem( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].ForceItemSave = 0
end

local selectedItems ={}
function DKP:EPGPCostListClose( wndHandler, wndControl, eMouseButton )
	self.wndEPGPItems:Show(false,false)
end

function DKP:EPGPCostListShow( wndHandler, wndControl, eMouseButton )
	self.wndEPGPItems:Show(true,false)
	self:EPGPCostListPopulate()
	self.wndEPGPItems:ToFront()
end

function DKP:EPGPAddItemtoQueue( wndHandler, wndControl, eMouseButton )
	table.insert(selectedItems,wndControl)
	if #selectedItems >= 6 then
		selectedItems[1]:SetCheck(false)
		table.remove(selectedItems,1)
	end
end

function DKP:EPGPRemoveITemFromQueue( wndHandler, wndControl, eMouseButton )
	for i=1,#selectedItems do
		if selectedItems[i] == wndControl then
			table.remove(selectedItems,i)
			break
		end
	end
end


function DKP:EPGPPostToChannel( wndHandler, wndControl, eMouseButton )
	for k,item in ipairs(selectedItems) do
		ChatSystemLib.Command(self.AnnouncePrefix .. self.ItemDatabase[item:FindChild("ItemName"):GetText()].strChat .. "  GP: " .. item:FindChild("Cost"):GetText()) 
	end
	self:EPGPDeselectAll()
end

function DKP:EPGPRemoveSelected( wndHandler, wndControl, eMouseButton )
	for k,item in ipairs(selectedItems) do
		self.ItemDatabase[item:FindChild("ItemName"):GetText()] = nil
		item:Destroy()
	end
	self:EPGPCostListPopulate()
	
end

function DKP:EPGPDeselectAll()
	for k,item in ipairs(selectedItems) do
		item:SetCheck(false)
	end
	selectedItems = {}
end

function DKP:EPGPCostListPopulate()
	selectedItems = {}
	if self.ItemDatabase == nil then 
		return 
	end
	self.wndEPGPItems:FindChild("ItemList"):DestroyChildren()
	for k,item in pairs(self.ItemDatabase) do
		local wnd = Apollo.LoadForm(self.xmlDoc2,"ItemCost",self.wndEPGPItems:FindChild("ItemList"),self)
		wnd:FindChild("ItemIcon"):SetSprite(item.sprite)
		wnd:FindChild("ItemName"):SetText(item.strItem)
		Tooltip.GetItemTooltipForm(self, wnd:FindChild("ItemIcon") , Item.GetDataFromId(item.ID), {bPrimary = true, bSelling = false})
		
		if item.quality == 6 then
			wnd:FindChild("ItemFrame"):SetSprite("CRB_Tooltips:sprTooltip_SquareFrame_Orange")
		elseif item.quality == 5 then
			wnd:FindChild("ItemFrame"):SetSprite("CRB_Tooltips:sprTooltip_SquareFrame_Purple")
		end
		wnd:FindChild("Cost"):SetText(self:EPGPGetItemCostByName(item.strItem))
	end
	self.wndEPGPItems:FindChild("ItemList"):ArrangeChildrenVert()
end

function DKP:EPGPGetQualityStringByID(ID)
	if ID == 5 then return "Purple"
	elseif ID == 6 then return "Orange"
	elseif ID == 4 then return "Blue"
	elseif ID == 3 then return "Green"
	elseif ID == 2 then return "White"
	end
end


---------------------------------------------------------------------------------------------------
-- RDKP/EPGP Functions
---------------------------------------------------------------------------------------------------

function DKP:EPGPEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].Enable = 1
	self:EPGPChangeUI()
end

function DKP:EPGPDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].Enable = 0
	self:EPGPChangeUI()
end

function DKP:EPGPDecay( wndHandler, wndControl, eMouseButton )
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and self.tItems["Standby"][string.lower(self.tItems[i].strName)] == nil then
			if self.wndEPGPSettings:FindChild("DecayEP"):IsChecked() == true then
				self.tItems[i].EP = self.tItems[i].EP * ((100 - tonumber(self.wndEPGPSettings:FindChild("DecayValue"):GetText()))/100)
			end
			if self.wndEPGPSettings:FindChild("DecayGP"):IsChecked() == true then
				self.tItems[i].GP = self.tItems[i].GP * ((100 - tonumber(self.wndEPGPSettings:FindChild("DecayValue"):GetText()))/100)
			end
		end
	end
	self:EPGPCheckTresholds()
	self:ShowAll()
end

function DKP:EPGPCheckDecayValue( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		local val = tonumber(strText)
		if val >= 1 and val <= 100 then
			
		else
			wndControl:SetText("")
		end
	else
		wndControl:SetText("")
	end
end

function DKP:EPGPClose( wndHandler, wndControl, eMouseButton )
	self.wndEPGPSettings:Show(false,false)
end

function DKP:EPGPSetCustomModifier( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["EPGP"].FormulaModifier = tonumber(strText)
	else
		wndControl:SetText(self.tItems["EPGP"].FormulaModifier)
	end
end

function DKP:EPGPItemSlotValueChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["EPGP"].SlotValues[wndControl:GetParent():FindChild("Name"):GetText()] = tonumber(strText)
	else
		wndControl:SetText(self.tItems["EPGP"].SlotValues[wndControl:GetParent():FindChild("Name"):GetText()])
	end
end

function DKP:EPGPShow( wndHandler, wndControl, eMouseButton )
	self.wndEPGPSettings:Show(true,false)
	self.wndEPGPSettings:ToFront()
end


function DKP:EPGPItemQualityValueChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
			self.tItems["EPGP"].QualityValues["Purple"] = tonumber(strText)
		else
			self.tItems["EPGP"].QualityValues["Orange"] = tonumber(strText)
		end
	else
		if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
			wndControl:SetText(self.tItems["EPGP"].QualityValues["Purple"])
		else
			wndControl:SetText(self.tItems["EPGP"].QualityValues["Orange"])		
		end
	end
end


function DKP:EPGPSetMinEP( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["EPGP"].MinEP = tonumber(strText)
		self:EPGPCheckTresholds()
	else
		wndControl:SetText(self.tItems["EPGP"].MinEP)
	end
end

function DKP:EPGPSetBaseGP( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		self.tItems["EPGP"].BaseGP = tonumber(strText)
		self:EPGPCheckTresholds()
	else
		wndControl:SetText(self.tItems["EPGP"].BaseGP)
	end
end

function DKP:EPGPGetItemCostByID(itemID)
	local item = Item.GetDataFromId(itemID)
	if item ~= nil and item:IsEquippable() and item:GetItemQuality() <= 6 then
		local slot 
		if item:GetSlotName() ~= "" then
			slot = item:GetSlotName()
		else
			slot = item:GetSlot()
		end
		if self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)] == nil then return "" end
		return "                                GP: " .. math.ceil(item:GetItemPower()/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())] * self.tItems["EPGP"].FormulaModifier * self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)])
	else return "" end
end


function DKP:EPGPCostListChannelChanged( wndHandler, wndControl, eMouseButton )
	if wndControl:GetText() == "   /guild" then
		self.AnnouncePrefix = "/guild " 
	else
		self.AnnouncePrefix = "/party " 
	end 
end

function DKP:EPGPCostListCheckChannel( wndHandler, wndControl, eMouseButton )
	if not wndControl:GetParent():FindChild("ChannelParty1"):IsChecked() and not wndControl:GetParent():FindChild("ChannelParty"):IsChecked() then
		self.AnnouncePrefix = "/party "
		self.wndEPGPItems:FindChild("ChannelParty"):SetCheck(true)
	end
end




-- Hook Part


function DKP:EPGPHookToETooltip( wndHandler, wndControl, eMouseButton )
	if Apollo.GetAddon("ETooltip") == nil then
		self.tItems["EPGP"].Tooltips = 0
		Print("Couldn't find EToolTip Addon")
		if wndControl ~= nil then wndControl:SetCheck(false) end
		return
	end
	if not Apollo.GetAddon("ETooltip").tSettings["bShowItemID"] then
		self.tItems["EPGP"].Tooltips = 0
		Print("Enable option to Show item ID in EToolTip")
		if wndControl ~= nil then wndControl:SetCheck(false) end
		return
	end
	self.tItems["EPGP"].Tooltips = 1
	--Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
	if not self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then
		self:RawHook(Apollo.GetAddon("ETooltip"),"AttachBelow")
	end
end

function DKP:EPGPUnHook( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].Tooltips = 0
	self:UnhookAll()
end


function DKP:AttachBelow(luaCaller,strText, wndHeader)
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