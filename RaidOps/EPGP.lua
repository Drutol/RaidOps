-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOps
-- Copyright (c) Piotr Szymczak 2015	 dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

local DKP = Apollo.GetAddon("RaidOps")
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

local DataScapeTokenIds =
{
	["Chest"] = 69892,
	["Legs"] = 69893,
	["Head"] = 69894,
	["Shoulders"] = 69895,
	["Hands"] = 69896,
	["Feet"] = 69897,
}

local GeneticTokenIds = 
{
	["Chest"] = 69814,
	["Legs"] = 69815,
	["Head"] = 69816,
	["Shoulders"] = 69817,
	["Hands"] = 69818,
	["Feet"] = 69819,
}

local ktUndoActions =
{
	["raep"] = "{Raid EP Award}",
	["ragp"] = "{Raid GP Award}",
	["epgpd"] = "{EP GP Decay}",
	["epd"] = "{EP Decay}",
	["gpd"] = "{GP Decay}",
}


-- constants from ETooltip
local kUIBody = "ff39b5d4"
local nItemIDSpacing = 4


function DKP:EPGPInit()
	self.wndEPGPSettings = Apollo.LoadForm(self.xmlDoc2,"RDKP/EPGP",nil,self)
	self.wndEPGPSettings:Show(false,true)
	self.GeminiLocale:TranslateWindow(self.Locale, self.wndEPGPSettings)
	if self.tItems["EPGP"] == nil or self.tItems["EPGP"].SlotValues == nil then
		self.tItems["EPGP"] = {}
		self.tItems["EPGP"].SlotValues = defaultSlotValues
		self.tItems["EPGP"].QualityValues = defaultQualityValues
		self.tItems["EPGP"].Enable = 1
		self.tItems["EPGP"].FormulaModifier = 0.5
		self.tItems["EPGP"].BaseGP = 1
		self.tItems["EPGP"].MinEP = 100
	end
	if self.tItems["EPGP"].bDecayEP == nil then self.tItems["EPGP"].bDecayEP = false end
	if self.tItems["EPGP"].bDecayGP == nil then self.tItems["EPGP"].bDecayGP = false end
	if self.tItems["EPGP"].nDecayValue == nil then self.tItems["EPGP"].nDecayValue = 25 end
	if self.tItems["EPGP"].bDecayRealGP == nil then self.tItems["EPGP"].bDecayRealGP = false end
	if self.tItems["EPGP"].bMinGP == nil then self.tItems["EPGP"].bMinGP = false end
	if self.tItems["EPGP"].bDecayPrec == nil then self.tItems["EPGP"].bDecayPrec = false end
	
	self.wndEPGPSettings:FindChild("DecayValue"):SetText(self.tItems["EPGP"].nDecayValue)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayValue"):SetText(self.tItems["EPGP"].nDecayValue)
	
	self.wndEPGPSettings:FindChild("DecayEP"):SetCheck(self.tItems["EPGP"].bDecayEP)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayEP"):SetCheck(self.tItems["EPGP"].bDecayEP)
	
	self.wndEPGPSettings:FindChild("DecayGP"):SetCheck(self.tItems["EPGP"].bDecayGP)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayGP"):SetCheck(self.tItems["EPGP"].bDecayGP)
	
	self.wndEPGPSettings:FindChild("DecayRealGP"):SetCheck(self.tItems["EPGP"].bDecayRealGP)
	self.wndEPGPSettings:FindChild("DecayPrecision"):SetCheck(self.tItems["EPGP"].bDecayPrec)
	
	self:EPGPFillInSettings()
	self:EPGPChangeUI()
	
	Apollo.RegisterEventHandler("ItemLink", "OnLootedItem", self)
	

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
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), item:GetName(), self.tItems[math.random(1,10)].strName))
end

function DKP:EPGPGetTokenItemID(strToken)
	if string.find(strToken,"Calculated") or string.find(strToken,"Algebraic") or string.find(strToken,"Logarithmic") then --DS
		if string.find(strToken,"Chestplate") then return DataScapeTokenIds["Chest"] 
		elseif string.find(strToken,"Greaves") then return DataScapeTokenIds["Legs"] 
		elseif string.find(strToken,"Helm") then return DataScapeTokenIds["Head"] 
		elseif string.find(strToken,"Pauldron") then return DataScapeTokenIds["Shoulders"] 
		elseif string.find(strToken,"Glove") then return DataScapeTokenIds["Hands"] 
		elseif string.find(strToken,"Boot") then return DataScapeTokenIds["Feet"] 
		end
	elseif string.find(strToken,"Xenological") or string.find(strToken,"Xenobiotic") or string.find(strToken,"Xenogenetic") then --GA
		if string.find(strToken,"Chestplate") then return GeneticTokenIds["Chest"] 
		elseif string.find(strToken,"Greaves") then return GeneticTokenIds["Legs"] 
		elseif string.find(strToken,"Helm") then return GeneticTokenIds["Head"] 
		elseif string.find(strToken,"Pauldron") then return GeneticTokenIds["Shoulders"] 
		elseif string.find(strToken,"Glove") then return GeneticTokenIds["Hands"] 
		elseif string.find(strToken,"Boot") then return GeneticTokenIds["Feet"] 
		end
	end
end

function DKP:EPGPDecayShow()
	self.wndMain:FindChild("EPGPDecay"):Show(true,false)
	
	self.wndMain:FindChild("Decay"):Show(false,false)
	self.wndMain:FindChild("DecayShow"):SetCheck(false)
end

function DKP:EPGPDecayHide()
	self.wndMain:FindChild("EPGPDecay"):Show(false,false)
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

function DKP:EPGPGetSlotSpriteByQualityRectangle(ID)
	if ID == 5 then return "BK3:UI_BK3_ItemQualityPurple"
	elseif ID == 6 then return "BK3:UI_BK3_ItemQualityOrange"
	elseif ID == 4 then return "BK3:UI_BK3_ItemQualityBlue"
	elseif ID == 3 then return "BK3:UI_BK3_ItemQualityGreen"
	elseif ID == 2 then return "BK3:UI_BK3_ItemQualityWhite"
	else return "BK3:UI_BK3_ItemQualityGrey"
	end
end

function DKP:EPGPGetItemCostByName(strItem)
	return math.ceil(self.ItemDatabase[strItem].Power/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(self.ItemDatabase[strItem].quality)] * self.tItems["EPGP"].FormulaModifier * self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(self.ItemDatabase[strItem].slot)])
end

function DKP:EPGPDecayEPEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].bDecayEP = true
	self.wndEPGPSettings:FindChild("DecayEP"):SetCheck(true)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayEP"):SetCheck(true)
end

function DKP:EPGPDecayEPDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].bDecayEP = false
	self.wndEPGPSettings:FindChild("DecayEP"):SetCheck(false)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayEP"):SetCheck(false)
end

function DKP:EPGPDecayPrecEnable()
	self.tItems["EPGP"].bDecayPrec = true
end

function DKP:EPGPDecayPrecDisable()
	self.tItems["EPGP"].bDecayPrec = false
end

function DKP:EPGPDecayGPEnable( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].bDecayGP = true
	self.wndEPGPSettings:FindChild("DecayGP"):SetCheck(true)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayGP"):SetCheck(true)
end

function DKP:EPGPDecayGPDisable( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].bDecayGP = false
	self.wndEPGPSettings:FindChild("DecayGP"):SetCheck(false)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayGP"):SetCheck(false)
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
		labelTypes:FindChild("RealGP"):Show(true,false)
		self.wndLabelOptions:FindChild("LabelTypes"):ArrangeChildrenVert()
		self.wndEPGPSettings:FindChild("DecayNow"):Enable(true)
		self.wndSettings:FindChild("ButtonShowGP"):Enable(true)
		
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
		labelTypes:FindChild("RealGP"):Show(false,false)
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
		self.wndSettings:FindChild("ButtonShowGP"):Enable(false)
		if self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then self:UnhookAll() end
		self:LabelUpdateList()
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
		if self.tItems["EPGP"].bMinGP and self.tItems[ID].GP < 1 then self.tItems[ID].GP = 1 end
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
		end
		if self.tItems["EPGP"].bMinGP and self.tItems[ID].GP < 1 then self.tItems[ID].GP = 1 end
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
		end
		if self.tItems["EPGP"].bMinGP and self.tItems[ID].GP < 1 then self.tItems[ID].GP = 1 end
	end
end


function DKP:EPGPAwardRaid(EP,GP)
	local tMembers = {}
	for i=1,GroupLib.GetMemberCount() do
		local member = GroupLib.GetGroupMember(i)
		if member ~= nil then
			local ID = self:GetPlayerByIDByName(member.strCharacterName)
			if ID ~= -1 then
				if self.tItems["settings"].bTrackUndo then table.insert(tMembers,self.tItems[ID]) end
				if EP ~= nil then
					self.tItems[ID].EP = self.tItems[ID].EP + EP
					if self.tItems[ID].EP < self.tItems["EPGP"].MinEP then
						self.tItems[ID].EP = self.tItems["EPGP"].MinEP
					end
				end
				if GP ~= nil then
					self.tItems[ID].GP = self.tItems[ID].GP + GP
				end
			end
		end
	end
	local strType
	if EP then strType = ktUndoActions["raep"] elseif GP then strType = ktUndoActions["ragp"] end
	if self.tItems["settings"].bTrackUndo and tMembers then self:UndoAddActivity(strType,EP or GP,tMembers) end
	self:ShowAll()
end

function DKP:EPGPCheckTresholds()
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil then
			if self.tItems[i].EP < self.tItems["EPGP"].MinEP then
				 self.tItems[i].EP = self.tItems["EPGP"].MinEP
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






function DKP:EPGPGetQualityStringByID(ID)
	if ID == 5 then return "Purple"
	elseif ID == 6 then return "Orange"
	elseif ID == 4 then return "Blue"
	elseif ID == 3 then return "Green"
	elseif ID == 2 then return "White"
	elseif ID == 1 then return "Gray"
	elseif ID == 7 then return "Pink"
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
	if self.tItems["settings"].bTrackUndo then
		local tMembers = {}
		for k,player in ipairs(self.tItems) do
			if self.tItems["Standby"][string.lower(player.strName)] == nil then
				table.insert(tMembers,player)
			end
		end
		local strType = ""
		if self.tItems["EPGP"].bDecayEP and self.tItems["EPGP"].bDecayGP then strType = ktUndoActions["epgpd"]
		elseif self.tItems["EPGP"].bDecayEP then strType = ktUndoActions["epd"]
		elseif self.tItems["EPGP"].bDecayGP then strType = ktUndoActions["gpd"]
		end
		self:UndoAddActivity(strType,self.tItems["EPGP"].nDecayValue.."%",tMembers) 
	end
	
	
	for i=1,table.maxn(self.tItems) do
		if self.tItems[i] ~= nil and self.tItems["Standby"][string.lower(self.tItems[i].strName)] == nil then
			if self.tItems["EPGP"].bDecayPrec then
				self.tItems[i].EP = tonumber(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[i].EP))
				self.tItems[i].GP = tonumber(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[i].GP))
			end
			
			if self.wndEPGPSettings:FindChild("DecayEP"):IsChecked() == true then
				local nPreEP = self.tItems[i].EP
				self.tItems[i].EP = self.tItems[i].EP * ((100 - self.tItems["EPGP"].nDecayValue)/100)	
				if self.tItems["settings"].logs == 1 then self:DetailAddLog(self.tItems["EPGP"].nDecayValue .. "% EP Decay","{Decay}",math.floor((nPreEP - self.tItems[i].EP)) * -1 ,i) end
			end
			if self.wndEPGPSettings:FindChild("DecayGP"):IsChecked() == true then
				local nPreGP = self.tItems[i].GP
				if self.tItems["EPGP"].bDecayRealGP then
					self.tItems[i].GP = (self.tItems[i].GP - self.tItems["EPGP"].BaseGP) * ((100 - self.tItems["EPGP"].nDecayValue)/100) + self.tItems["EPGP"].BaseGP
				else
					self.tItems[i].GP = self.tItems[i].GP * ((100 - self.tItems["EPGP"].nDecayValue)/100)
				end
				if self.tItems["settings"].logs == 1 then self:DetailAddLog(self.tItems["EPGP"].nDecayValue .. "% GP Decay","{Decay}",math.floor((nPreGP - self.tItems[i].GP)) * -1 ,i) end
			end
			if self.tItems["EPGP"].bMinGP and self.tItems[i].GP < 1 then self.tItems[i].GP = 1 end
		end
	end
	self:EPGPCheckTresholds()
	self:ShowAll()
end

function DKP:EPGPCheckDecayValue( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		local val = tonumber(strText)
		if val >= 1 and val <= 100 then
			self.tItems["EPGP"].nDecayValue = val
			self.wndEPGPSettings:FindChild("DecayValue"):SetText(val)
			self.wndMain:FindChild("EPGPDecay"):FindChild("DecayValue"):SetText(val)
		else
			wndControl:SetText(self.tItems["EPGP"].nDecayValue)
		end
	else
		wndControl:SetText(self.tItems["EPGP"].nDecayValue)
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
	if string.find(item:GetName(),"Imprint") then
		item = Item.GetDataFromId(self:EPGPGetTokenItemID(item:GetName()))
	end
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



function DKP:EPGPGetPRByName(strName)
	local ID = self:GetPlayerByIDByName(strName)
	if ID ~= -1 then
		if self.tItems[ID].GP ~= 0 then
			return string.format("%."..tostring(self.tItems["settings"].Precision).."f", self.tItems[ID].EP/(self.tItems[ID].GP))
		else
			return "0"
		end
	else return "0" end
end

function DKP:EPGPDecayRealGPEnable()
	self.tItems["EPGP"].bDecayRealGP = true
end

function DKP:EPGPDecayRealGPDisable()
	self.tItems["EPGP"].bDecayRealGP = false
end

function DKP:EPGPMinGPEnable()
	self.tItems["EPGP"].bMinGP = true
	for k ,player in ipairs(self.tItems) do if player.GP < 1 then player.GP = 1 end end
end

function DKP:EPGPMinDisable()
	self.tItems["EPGP"].bMinGP = false
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
	if not self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then
		self:RawHook(Apollo.GetAddon("ETooltip"),"AttachBelow")
	end
end

function DKP:EPGPUnHook( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].Tooltips = 0
	self:Unhook(Apollo.GetAddon("ETooltip"),"AttachBelow")
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