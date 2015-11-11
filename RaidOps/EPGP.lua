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
	["Orange"] = .1,
	["Pink"] = .05
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
	if self.tItems["EPGP"].bMinGPThres == nil then self.tItems["EPGP"].bMinGPThres = false end
	if self.tItems["EPGP"].QualityValuesAbove == nil then self.tItems["EPGP"].QualityValuesAbove = defaultQualityValues end
	if self.tItems["EPGP"].SlotValuesAbove == nil then self.tItems["EPGP"].SlotValuesAbove = defaultSlotValues end
	if self.tItems["EPGP"].FormulaModifierAbove == nil then self.tItems["EPGP"].FormulaModifierAbove = 0.5 end
	if self.tItems["EPGP"].nItemPowerThresholdValue == nil then self.tItems["EPGP"].nItemPowerThresholdValue = 0 end
	if self.tItems["EPGP"].bUseItemLevelForGPCalc == nil then self.tItems["EPGP"].bUseItemLevelForGPCalc = false end
	if self.tItems["EPGP"].bStaticGPCalc == nil then self.tItems["EPGP"].bStaticGPCalc = false end
	if self.tItems["EPGP"].bCalcForUnequippable == nil then self.tItems["EPGP"].bCalcForUnequippable = false end
	if self.tItems["EPGP"].nUnequippableSlotValue == nil then self.tItems["EPGP"].nUnequippableSlotValue = 1 end
	
	if not self.tItems["EPGP"].QualityValuesAbove["Pink"] then  self.tItems["EPGP"].QualityValuesAbove["Pink"] = defaultQualityValues["Pink"] end
	if not self.tItems["EPGP"].QualityValues["Pink"] then  self.tItems["EPGP"].QualityValues["Pink"] = defaultQualityValues["Pink"] end
	self.wndEPGPSettings:FindChild("DecayValue"):SetText(self.tItems["EPGP"].nDecayValue)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayValue"):SetText(self.tItems["EPGP"].nDecayValue)
	
	self.wndEPGPSettings:FindChild("DecayEP"):SetCheck(self.tItems["EPGP"].bDecayEP)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayEP"):SetCheck(self.tItems["EPGP"].bDecayEP)
	
	self.wndEPGPSettings:FindChild("DecayGP"):SetCheck(self.tItems["EPGP"].bDecayGP)
	self.wndMain:FindChild("EPGPDecay"):FindChild("DecayGP"):SetCheck(self.tItems["EPGP"].bDecayGP)
	
	self.wndEPGPSettings:FindChild("DecayRealGP"):SetCheck(self.tItems["EPGP"].bDecayRealGP)
	self.wndEPGPSettings:FindChild("DecayPrecision"):SetCheck(self.tItems["EPGP"].bDecayPrec)

	self.wndEPGPSettings:FindChild("GPMinimum1"):SetCheck(self.tItems["EPGP"].bMinGP)
	self.wndEPGPSettings:FindChild("GPDecayThreshold"):SetCheck(self.tItems["EPGP"].bMinGPThres)

	self.wndEPGPSettings:FindChild("ItemLevelForGPCalc"):SetCheck(self.tItems["EPGP"].bUseItemLevelForGPCalc)
	self.wndEPGPSettings:FindChild("StaticGPCalc"):SetCheck(self.tItems["EPGP"].bStaticGPCalc)

	self.wndEPGPSettings:FindChild("CalcForUneq"):SetCheck(self.tItems["EPGP"].bCalcForUnequippable)
	self.wndEPGPSettings:FindChild("SlotValueUneq"):FindChild("Field"):SetText(self.tItems["EPGP"].nUnequippableSlotValue)
	
	self:EPGPFillInSettings()
	self:EPGPChangeUI()
	
	--Apollo.RegisterEventHandler("ItemLink", "OnLootedItem", self)
	

end

function DKP:EPGPItemLevelGPCalcEnable()
	self.tItems["EPGP"].bUseItemLevelForGPCalc = true
	self.tItems["EPGP"].bStaticGPCalc = false
	self:EPGPAdjustFormulaDisplay()
end

function DKP:EPGPItemLevelGPCalcDisable()
	self.tItems["EPGP"].bUseItemLevelForGPCalc = false
	self:EPGPAdjustFormulaDisplay()
end

function DKP:EPGPStaticGPCalcEnable()
	self.tItems["EPGP"].bUseItemLevelForGPCalc = false
	self.tItems["EPGP"].bStaticGPCalc = true
	self:EPGPAdjustFormulaDisplay()
end

function DKP:EPGPStaticGPCalcDisable()
	self.tItems["EPGP"].bStaticGPCalc = false
	self:EPGPAdjustFormulaDisplay()
end

function DKP:EPGPCalcUneqEnable()
	self.tItems["EPGP"].bCalcForUnequippable = true
end

function DKP:EPGPCalcUneqDisable()
	self.tItems["EPGP"].bCalcForUnequippable = false
end

function DKP:EPGPItemSlotValueUneqChanged(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val then
		self.tItems["EPGP"].nUnequippableSlotValue = val
	else
		wndControl:SetText(self.tItems["EPGP"].nUnequippableSlotValue)
	end
end

function DKP:EPGPSetPowerThreshold(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val and val > 0 then
		self.tItems["EPGP"].nItemPowerThresholdValue = val
	else
		self.tItems["EPGP"].nItemPowerThresholdValue = 0
		wndControl:SetText("--")
	end

	if self.tItems["EPGP"].nItemPowerThresholdValue == 0 then
		self.wndEPGPSettings:FindChild("ItemCostAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("OrangeQualAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("PurpleQualAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("PinkQualAbove"):SetOpacity(0.5)
	else
		self.wndEPGPSettings:FindChild("ItemCostAbove"):SetOpacity(1)
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):SetOpacity(1)
		self.wndEPGPSettings:FindChild("OrangeQualAbove"):SetOpacity(1)
		self.wndEPGPSettings:FindChild("PurpleQualAbove"):SetOpacity(1)
		self.wndEPGPSettings:FindChild("PinkQualAbove"):SetOpacity(1)
	end
end

function DKP:OnLootedItem(item,bSuspend)
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
	if not bSuspend then Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), item:GetName(),self.tItems[math.random(1,10)].strName)) end
end

function DKP:EPGPGetTokenItemID(strToken)
	if string.find(strToken,self.Locale["#Calculated"]) or string.find(strToken,self.Locale["#Algebraic"]) or string.find(strToken,self.Locale["#Logarithmic"]) then --DS
		if string.find(strToken,self.Locale["#Chestplate"]) then return DataScapeTokenIds["Chest"] 
		elseif string.find(strToken,self.Locale["#Greaves"]) then return DataScapeTokenIds["Legs"] 
		elseif string.find(strToken,self.Locale["#Helm"]) then return DataScapeTokenIds["Head"] 
		elseif string.find(strToken,self.Locale["#Pauldron"]) then return DataScapeTokenIds["Shoulders"] 
		elseif string.find(strToken,self.Locale["#Glove"]) then return DataScapeTokenIds["Hands"] 
		elseif string.find(strToken,self.Locale["#Boot"]) then return DataScapeTokenIds["Feet"] 
		end
	elseif string.find(strToken,self.Locale["#Xenological"]) or string.find(strToken,self.Locale["#Xenobiotic"]) or string.find(strToken,self.Locale["#Xenogenetic"]) then --GA
		if string.find(strToken,self.Locale["#Chestplate"]) then return GeneticTokenIds["Chest"] 
		elseif string.find(strToken,self.Locale["#Greaves"]) then return GeneticTokenIds["Legs"] 
		elseif string.find(strToken,self.Locale["#Helm"]) then return GeneticTokenIds["Head"] 
		elseif string.find(strToken,self.Locale["#Pauldron"]) then return GeneticTokenIds["Shoulders"] 
		elseif string.find(strToken,self.Locale["#Glove"]) then return GeneticTokenIds["Hands"] 
		elseif string.find(strToken,self.Locale["#Boot"]) then return GeneticTokenIds["Feet"] 
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
	self:EPGPFillInSettingsBelow()
	self:EPGPFillInSettingsAbove()
	if self.tItems["EPGP"].Enable == 1 then self.wndEPGPSettings:FindChild("Enable"):SetCheck(true) end
	if self.tItems["EPGP"].Tooltips == 1 then
		self.wndSettings:FindChild("ButtonShowGP"):SetCheck(true)
		self:EPGPHookToETooltip()
	end
	if self.tItems["EPGP"].nItemPowerThresholdValue == 0 then
		self.wndEPGPSettings:FindChild("ItemCostAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("OrangeQualAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("PurpleQualAbove"):SetOpacity(0.5)
		self.wndEPGPSettings:FindChild("PinkQualAbove"):SetOpacity(0.5)
	end

	self.wndEPGPSettings:FindChild("White"):SetText(self.tItems["EPGP"].QualityValues["White"])
	self.wndEPGPSettings:FindChild("Green"):SetText(self.tItems["EPGP"].QualityValues["Green"])
	self.wndEPGPSettings:FindChild("Blue"):SetText(self.tItems["EPGP"].QualityValues["Blue"])

	self.wndEPGPSettings:FindChild("PowerLevelThreshold"):SetText(self.tItems["EPGP"].nItemPowerThresholdValue == 0 and "--" or self.tItems["EPGP"].nItemPowerThresholdValue)
end

function DKP:EPGPFillInSettingsBelow()
	--Slots
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Weapon"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue1"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Shield"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue2"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Head"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue3"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Shoulders"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue4"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Chest"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue5"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Hands"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue6"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Legs"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue7"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Feet"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue8"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Attachment"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue9"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Support"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue10"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Gadget"])
	self.wndEPGPSettings:FindChild("ItemCostBelow"):FindChild("SlotValue11"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValues["Implant"])
	--Rest
	self.wndEPGPSettings:FindChild("FormulaLabelBelow"):FindChild("CustomModifier"):SetText(self.tItems["EPGP"].FormulaModifier)
	self.wndEPGPSettings:FindChild("PurpleQualBelow"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValues["Purple"])
	self.wndEPGPSettings:FindChild("OrangeQualBelow"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValues["Orange"])
	self.wndEPGPSettings:FindChild("PinkQualBelow"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValues["Pink"])
	self.wndEPGPSettings:FindChild("MinEP"):SetText(self.tItems["EPGP"].MinEP)
	self.wndEPGPSettings:FindChild("BaseGP"):SetText(self.tItems["EPGP"].BaseGP)	
end

function DKP:EPGPFillInSettingsAbove()
	--Slots
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Weapon"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue1"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Shield"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue2"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Head"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue3"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Shoulders"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue4"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Chest"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue5"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Hands"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue6"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Legs"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue7"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Feet"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue8"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Attachment"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue9"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Support"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue10"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Gadget"])
	self.wndEPGPSettings:FindChild("ItemCostAbove"):FindChild("SlotValue11"):FindChild("Field"):SetText(self.tItems["EPGP"].SlotValuesAbove["Implant"])
	--Rest
	self.wndEPGPSettings:FindChild("FormulaLabelAbove"):FindChild("CustomModifier"):SetText(self.tItems["EPGP"].FormulaModifierAbove)
	self.wndEPGPSettings:FindChild("PurpleQualAbove"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValuesAbove["Purple"])
	self.wndEPGPSettings:FindChild("OrangeQualAbove"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValuesAbove["Orange"])
	self.wndEPGPSettings:FindChild("PinkQualAbove"):FindChild("Field"):SetText(self.tItems["EPGP"].QualityValuesAbove["Pink"])
	self.wndEPGPSettings:FindChild("MinEP"):SetText(self.tItems["EPGP"].MinEP)
	self.wndEPGPSettings:FindChild("BaseGP"):SetText(self.tItems["EPGP"].BaseGP)
end

function DKP:EPGPGetSlotValueByString(strSlot)
	return self.tItems["EPGP"].SlotValues[strSlot]
end

function DKP:EPGPGetSlotStringByID(ID)
	if ID == 16 then return "Weapon"
	elseif ID == 7 then return "Attachment"
	elseif ID == 3 then return "Shoulders"
	elseif ID == 0 then return "Chest"
	elseif ID == 4 then return "Feet"
	elseif ID == 11 then return "Gadget"
	elseif ID == 5 then return "Hands"
	elseif ID == 2 then return "Head"
	elseif ID == 10 then return "Implant"
	elseif ID == 1 then return "Legs"
	elseif ID == 15 then return "Shield"
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

--deprecated
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
		self.wndEPGPSettings:FindChild("DecayNow"):Enable(true)
		self.wndSettings:FindChild("ButtonShowGP"):Enable(true)
	else
		--Main Controls
		local controls = self.wndMain:FindChild("Controls")
		controls:FindChild("EditBox1"):SetText("Input Value") --input
		controls:FindChild("EditBox"):SetAnchorOffsets(25,67,187,146)  -- comment
		controls:FindChild("ButtonEP"):Show(false,false)
		controls:FindChild("ButtonGP"):Show(false,false)
		self.wndEPGPSettings:FindChild("DecayNow"):Enable(false)
		self.wndSettings:FindChild("ButtonShowGP"):Enable(false)
		if self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then self:Unhook(Apollo.GetAddon("ETooltip"),"AttachBelow") end
	end

	self:EPGPAdjustFormulaDisplay()

end

function DKP:EPGPAdjustFormulaDisplay()
	if self.tItems["EPGP"].bUseItemLevelForGPCalc then
		self.wndEPGPSettings:FindChild("FormulaLabelBelow"):SetText(self.Locale["#wndEPGPSettings:ItemCost:FormulaAlt"])
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):SetText(self.Locale["#wndEPGPSettings:ItemCost:FormulaAlt"])
		self.wndEPGPSettings:FindChild("FormulaLabelBelow"):FindChild("CustomModifier"):SetAnchorOffsets(279,3,334,36)
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):FindChild("CustomModifier"):SetAnchorOffsets(279,3,334,36)
	elseif self.tItems["EPGP"].bStaticGPCalc then
		self.wndEPGPSettings:FindChild("FormulaLabelBelow"):SetText(self.Locale["#wndEPGPSettings:ItemCost:FormulaStatic"])
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):SetText(self.Locale["#wndEPGPSettings:ItemCost:FormulaStatic"])
		self.wndEPGPSettings:FindChild("FormulaLabelBelow"):FindChild("CustomModifier"):SetAnchorOffsets(363,3,418,36)
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):FindChild("CustomModifier"):SetAnchorOffsets(363,3,418,36)
	else
		self.wndEPGPSettings:FindChild("FormulaLabelBelow"):SetText(self.Locale["#wndEPGPSettings:ItemCost:Formula"])
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):SetText(self.Locale["#wndEPGPSettings:ItemCost:Formula"])
		self.wndEPGPSettings:FindChild("FormulaLabelBelow"):FindChild("CustomModifier"):SetAnchorOffsets(279,3,334,36)
		self.wndEPGPSettings:FindChild("FormulaLabelAbove"):FindChild("CustomModifier"):SetAnchorOffsets(279,3,334,36)
	end
end

function DKP:EPGPReset()
	self.tItems["EPGP"].SlotValues = defaultSlotValues
	self.tItems["EPGP"].QualityValues = defaultQualityValues
	self.tItems["EPGP"].FormulaModifier = 0.5
	self:ShowAll()
	self:EPGPFillInSettings()
end

function DKP:EPGPAdd(strName,EP,GP)
	EP = tonumber(EP) or 0
	GP = tonumber(GP) or 0
	local ID = self:GetPlayerByIDByName(strName)
	if ID ~= -1 then
		if EP ~= nil then
			self.tItems[ID].EP = self.tItems[ID].EP + EP
		end
		if GP ~= nil then
			self.tItems[ID].nAwardedGP = self.tItems[ID].nAwardedGP + GP
		end
		if self.tItems["EPGP"].bMinGP and self.tItems[ID].GP < 1 then 
			self.tItems[ID].nAwardedGP = 1
		elseif self.tItems["EPGP"].bMinGPThres and self.tItems[ID].GP < self.tItems[ID].nBaseGP then 
			self.tItems[ID].nAwardedGP = self.tItems[ID].nBaseGP
		end
	end

end

function DKP:EPGPSubtract(strName,EP,GP)
	EP = tonumber(EP) or 0
	GP = tonumber(GP) or 0
	local ID = self:GetPlayerByIDByName(strName)
	if ID ~= -1 then
		if EP ~= nil then
			self.tItems[ID].EP = self.tItems[ID].EP - EP
			if self.tItems[ID].EP < self.tItems["EPGP"].MinEP then
				self.tItems[ID].EP = self.tItems["EPGP"].MinEP
			end
		end
		if GP ~= nil then
			self.tItems[ID].nAwardedGP = self.tItems[ID].nAwardedGP - GP
		end
		if self.tItems["EPGP"].bMinGP and self.tItems[ID].GP < 1 then 
			self.tItems[ID].nAwardedGP = 1
		elseif self.tItems["EPGP"].bMinGPThres and self.tItems[ID].GP < self.tItems[ID].nBaseGP then 
			self.tItems[ID].nAwardedGP = self.tItems[ID].nBaseGP
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
			self.tItems[ID].nAwardedGP = GP - self.tItems[ID].nBaseGP
		end
		if self.tItems["EPGP"].bMinGP and self.tItems[ID].GP < 1 then 
			self.tItems[ID].nAwardedGP = 1
		elseif self.tItems["EPGP"].bMinGPThres and self.tItems[ID].GP < self.tItems[ID].nBaseGP then 
			self.tItems[ID].nAwardedGP = self.tItems[ID].nBaseGP
		end
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
					self.tItems[ID].nAwardedGP = self.tItems[ID].nAwardedGP + GP
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
	for k , player in ipairs(self.tItems) do
		if player.EP < self.tItems["EPGP"].MinEP then
			 player.EP = self.tItems["EPGP"].MinEP
		end
		
		if self.tItems["EPGP"].bMinGP and player.GP < 1 then 
			player.nAwardedGP = 1
		end
		if self.tItems["EPGP"].bMinGPThres and player.GP < player.nBaseGP then 
			player.nAwardedGP = 0
		end
	end
end
---------------------------------------------------------------------------------------------------
-- CostList Functions
---------------------------------------------------------------------------------------------------


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
				self.tItems[i].nAwardedGP = tonumber(string.format("%."..tostring(self.tItems["settings"].PrecisionEPGP).."f",self.tItems[i].nAwardedGP))
			end
			
			if self.wndEPGPSettings:FindChild("DecayEP"):IsChecked() == true then
				local nPreEP = self.tItems[i].EP
				self.tItems[i].EP = self.tItems[i].EP * ((100 - self.tItems["EPGP"].nDecayValue)/100)	
				if self.tItems["settings"].logs == 1 then self:DetailAddLog(self.tItems["EPGP"].nDecayValue .. "% EP Decay","{Decay}",math.floor((nPreEP - self.tItems[i].EP)) * -1 ,i) end
			end
			if self.wndEPGPSettings:FindChild("DecayGP"):IsChecked() == true then
				local nPreGP = self.tItems[i].GP
				if self.tItems["EPGP"].bDecayRealGP then 
					self.tItems[i].nAwardedGP = self.tItems[i].nAwardedGP * ((100 - self.tItems["EPGP"].nDecayValue)/100)
				else
					self.tItems[i].nAwardedGP =  (self.tItems[i].GP * ((100 - self.tItems["EPGP"].nDecayValue)/100)) - self.tItems[i].nBaseGP
				end
				if self.tItems["settings"].logs == 1 then self:DetailAddLog(self.tItems["EPGP"].nDecayValue .. "% GP Decay","{Decay}",math.floor((nPreGP - self.tItems[i].GP)) * -1 ,i) end
			end
		end
	end
	self:DROnDecay()
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
		if wndControl:GetParent():GetName() == "FormulaLabelBelow" then
			self.tItems["EPGP"].FormulaModifier = tonumber(strText)
		else
			self.tItems["EPGP"].FormulaModifierAbove = tonumber(strText)
		end
	else
		if wndControl:GetParent():GetName() == "FormulaLabelBelow" then
			wndControl:SetText(self.tItems["EPGP"].FormulaModifier)
		else
			wndControl:SetText(self.tItems["EPGP"].FormulaModifierAbove)
		end
	end
end

function DKP:EPGPItemSlotValueChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		if wndControl:GetParent():GetParent():GetName() == "ItemCostAbove" then
			self.tItems["EPGP"].SlotValuesAbove[wndControl:GetParent():FindChild("Name"):GetText()] = tonumber(strText)
		else
			self.tItems["EPGP"].SlotValues[wndControl:GetParent():FindChild("Name"):GetText()] = tonumber(strText)
		end
	else
		if wndControl:GetParent():GetParent():GetName() == "ItemCostAbove" then
			wndControl:SetText(self.tItems["EPGP"].SlotValuesAbove[wndControl:GetParent():FindChild("Name"):GetText()])
		else
			wndControl:SetText(self.tItems["EPGP"].SlotValues[wndControl:GetParent():FindChild("Name"):GetText()])
		end
	end
end

function DKP:EPGPShow( wndHandler, wndControl, eMouseButton )
	self.wndEPGPSettings:Show(true,false)
	self.wndEPGPSettings:ToFront()
end


function DKP:EPGPItemQualityValueChanged( wndHandler, wndControl, strText )
	if tonumber(strText) ~= nil then
		if string.find(wndControl:GetParent():GetName(),"Below") then	
			if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
				self.tItems["EPGP"].QualityValues["Purple"] = tonumber(strText)
			else
				self.tItems["EPGP"].QualityValues["Orange"] = tonumber(strText)
			end
		else
			if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
				self.tItems["EPGP"].QualityValuesAbove["Purple"] = tonumber(strText)
			else
				self.tItems["EPGP"].QualityValuesAbove["Orange"] = tonumber(strText)
			end
		end
	else
		if string.find(wndControl:GetParent():GetName(),"Below") then	
			if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
				wndControl:SetText(self.tItems["EPGP"].QualityValues["Purple"])
			else
				wndControl:SetText(self.tItems["EPGP"].QualityValues["Orange"])		
			end
		else
			if wndControl:GetParent():FindChild("Name"):GetText() == "Purple Quality" then
				wndControl:SetText(self.tItems["EPGP"].QualityValuesAbove["Purple"])
			else
				wndControl:SetText(self.tItems["EPGP"].QualityValuesAbove["Orange"])		
			end
		end
	end
end

function DKP:EPGPPinkItemQualityValueChanged(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val then
		if string.find(wndControl:GetParent():GetName(),"Below") then
			self.tItems["EPGP"].QualityValues["Pink"] = val
		else
			self.tItems["EPGP"].QualityValuesAbove["Pink"] = val
		end	
	else
		if string.find(wndControl:GetParent():GetName(),"Below") then
			wndControl:SetText(self.tItems["EPGP"].QualityValues["Pink"])
		else
			wndControl:SetText(self.tItems["EPGP"].QualityValuesAbove["Pink"])
		end
	end
end

function DKP:EPGPLesserQualityChanged(wndHandler,wndControl,strText)
	local val = tonumber(strText)
	if val then
		self.tItems["EPGP"].QualityValues[wndControl:GetName()] = val
		self.tItems["EPGP"].QualityValuesAbove[wndControl:GetName()] = val
	else
		wndControl:SetText(self.tItems["EPGP"].QualityValues[wndControl:GetName()])
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

function DKP:EPGPGetItemCostByID(itemID,bCut)
	if not bCut then bCut = false end
	local item = Item.GetDataFromId(itemID)
	if string.find(item:GetName(),self.Locale["#Imprint"]) then
		item = Item.GetDataFromId(self:EPGPGetTokenItemID(item:GetName()))
	end
	if item and item:GetItemQuality() > 1 then
		if item:IsEquippable() then
			local slot 
			slot = item:GetSlot()
			if self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)] == nil then return "" end
			
			if (item:GetDetailedInfo().tPrimary.nEffectiveLevel or 0) <= self.tItems["EPGP"].nItemPowerThresholdValue or self.tItems["EPGP"].nItemPowerThresholdValue == 0 then
				if not self.tItems["EPGP"].bStaticGPCalc then
					if not bCut then 
						return "                                GP: " .. math.ceil((self.tItems["EPGP"].bUseItemLevelForGPCalc and item:GetDetailedInfo().tPrimary.nEffectiveLevel or item:GetItemPower())/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())] * self.tItems["EPGP"].FormulaModifier * self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)])
					else return math.ceil((self.tItems["EPGP"].bUseItemLevelForGPCalc and item:GetDetailedInfo().tPrimary.nEffectiveLevel or item:GetItemPower())/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())] * self.tItems["EPGP"].FormulaModifier * self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)]) end
				else -- static
					if not bCut then 
						return "                                GP: " .. math.ceil((self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)]/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())]) * self.tItems["EPGP"].FormulaModifier)
					else return math.ceil((self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)]/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())]) * self.tItems["EPGP"].FormulaModifier) end
				end
			else
				if not self.tItems["EPGP"].bStaticGPCalc then
					if not bCut then 
					return "                                GP: " .. math.ceil((self.tItems["EPGP"].bUseItemLevelForGPCalc and item:GetDetailedInfo().tPrimary.nEffectiveLevel or item:GetItemPower())/self.tItems["EPGP"].QualityValuesAbove[self:EPGPGetQualityStringByID(item:GetItemQuality())] * self.tItems["EPGP"].FormulaModifierAbove * self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)])
					else return math.ceil((self.tItems["EPGP"].bUseItemLevelForGPCalc and item:GetDetailedInfo().tPrimary.nEffectiveLevel or item:GetItemPower())/self.tItems["EPGP"].QualityValuesAbove[self:EPGPGetQualityStringByID(item:GetItemQuality())] * self.tItems["EPGP"].FormulaModifierAbove * self.tItems["EPGP"].SlotValuesAbove[self:EPGPGetSlotStringByID(slot)]) end
				else -- static
					if not bCut then 
						return "                                GP: " .. math.ceil((self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)]/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())]) * self.tItems["EPGP"].FormulaModifier)
					else return math.ceil((self.tItems["EPGP"].SlotValues[self:EPGPGetSlotStringByID(slot)]/self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())]) * self.tItems["EPGP"].FormulaModifier) end
				end
			end
		elseif self.tItems["EPGP"].bCalcForUnequippable then
			return math.ceil((self.tItems["EPGP"].nUnequippableSlotValue /self.tItems["EPGP"].QualityValues[self:EPGPGetQualityStringByID(item:GetItemQuality())]) * self.tItems["EPGP"].FormulaModifier) 
		else
			return 
		end
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

function DKP:EPGPGetPRByValues(nEP,nGP)
	if nGP ~= 0 then
		return tonumber(string.format("%."..tostring(self.tItems["settings"].Precision).."f", nEP/nGP))
	else
		return 0
	end
end

function DKP:EPGPGetPRByID(ID)
	if not self.tItems[ID] then return 0 end
	if ID ~= -1 then
		if self.tItems[ID].GP ~= 0 then
			return string.format("%."..tostring(self.tItems["settings"].Precision).."f", self.tItems[ID].EP/(self.tItems[ID].nAwardedGP + self.tItems[ID].nBaseGP))
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
	self:EPGPGPBaseThresDisable()
	for k ,player in ipairs(self.tItems) do if player.GP < 1 then player.nAwardedGP = 1 end end
end

function DKP:EPGPMinDisable()
	self.tItems["EPGP"].bMinGP = false
	self.wndEPGPSettings:FindChild("GPMinimum1"):SetCheck(false)
end

function DKP:EPGPGPBaseThresEnable()
	self.tItems["EPGP"].bMinGPThres = true
	self:EPGPMinDisable()
	for k ,player in ipairs(self.tItems) do if player.GP < player.nBaseGP then player.nAwardedGP = player.nBaseGP end end
end

function DKP:EPGPGPBaseThresDisable()
	self.tItems["EPGP"].bMinGPThres = false
	self.wndEPGPSettings:FindChild("GPDecayThreshold"):SetCheck(false)
end

-- Hook Part
local failCounter = 0
function DKP:HookToTooltip(tContext)
	-- Based on EToolTip implementation
	if tContext.originalTootltipFunction then return end
	aAddon = Apollo.GetAddon("ToolTips")
	if not aAddon and failCounter < 10 then
		failCounter = failCounter + 1
		self:delay(1,function(tContext) tContext:HookToTooltip(tContext) end)
		return
	elseif failCounter >= 10 then
		Print("Failed to hook to toltips addon.This should never occur unless you have addon that replaces tooltips.Notify me about that on github or curse :)")
		return
	end
	self.bPostInit = true
	tContext.originalTootltipFunction = Tooltip.GetItemTooltipForm
    local origCreateCallNames = aAddon.CreateCallNames
    if not origCreateCallNames then return end
    aAddon.CreateCallNames = function(luaCaller)
        origCreateCallNames(luaCaller) 
        tContext.originalTootltipFunction = Tooltip.GetItemTooltipForm
        Tooltip.GetItemTooltipForm  = function (luaCaller, wndControl, item, bStuff, nCount)
        	return tContext.EnhanceItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
        end
    end
    aAddon.CreateCallNames()
end

function DKP:EPGPHookToETooltip( wndHandler, wndControl, eMouseButton )
	if not Apollo.GetAddon("ETooltip") then
		self.tItems["EPGP"].Tooltips = 1
		self:delay(1,function(tContext) tContext:HookToTooltip(tContext) end)
	else
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
end

function DKP:EPGPUnHook( wndHandler, wndControl, eMouseButton )
	self.tItems["EPGP"].Tooltips = 0
	self:Unhook(Apollo.GetAddon("ETooltip"),"AttachBelow")
	if self.originalTootltipFunction then
		Tooltip.GetItemTooltipForm = self.originalTootltipFunction
		self.originalTootltipFunction = nil
	end
end

function DKP:EnhanceItemTooltip(wndControl,item,tOpt,nCount)
    local this = Apollo.GetAddon("RaidOps")
    wndControl:SetTooltipDoc(nil)
    local wndTooltip, wndTooltipComp = this.originalTootltipFunction(self, wndControl, item, tOpt, nCount)
    local wndTarget
   	if wndTooltip then wndTarget = wndTooltip:FindChild("SeparatorDiagonal") and wndTooltip:FindChild("SeparatorDiagonal") or wndTooltip:FindChild("SeparatorSmallLine") end
    if wndTooltip and item and item:GetItemQuality() > 1 then
    	local val = this:EPGPGetItemCostByID(item:GetItemId(),true)
    	if val and item:IsEquippable() and wndTarget then
	    	wndTarget:SetText(val ~= "" and (val .. " GP") or "")
	    	wndTarget:SetTextColor("xkcdAmber")
	    	wndTarget:SetFont("Nameplates")
	    	wndTarget:SetTextFlags("DT_VCENTER", true)
	    	wndTarget:SetTextFlags("DT_CENTER", true)
	    	if wndTarget:GetName() == "SeparatorSmallLine" then 
	    		wndTarget:SetSprite("CRB_Tooltips:sprTooltip_HorzDividerDiagonal") 
	    		local l,t,r,b = wndTarget:GetAnchorOffsets()
	    		wndTarget:SetAnchorOffsets(l,t+3,r,b-1)
	    	end
	    elseif val then
		    local wndBox = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "ItemBasicStatsLine", wndTooltip:FindChild("ItemTooltip_BasicStatsBox"))
	    	if wndBox then
	    		wndBox:SetAML("<P Font=\"Nameplates\" TextColor=\"xkcdAmber\"> ".. val .. " GP".." </P>")
	    		wndBox:SetTextFlags("DT_RIGHT",true)
	    		wndBox:SetHeightToContentHeight()
	    		wndBox:SetAnchorOffsets(130,0,0,wndBox:GetHeight())
	    	end
	    end
    end
    if wndTooltipComp then wndTarget = wndTooltipComp:FindChild("SeparatorDiagonal") and wndTooltipComp:FindChild("SeparatorDiagonal") or wndTooltipComp:FindChild("SeparatorSmallLine") end
    if wndTooltipComp and wndTarget and tOpt.itemCompare and tOpt.itemCompare:IsEquippable() then
    	local val = this:EPGPGetItemCostByID(tOpt.itemCompare:GetItemId(),true)
    	wndTarget:SetText(val ~= "" and (val .. " GP") or "")
    	wndTarget:SetTextColor("xkcdAmber")
    	wndTarget:SetFont("Nameplates")
    	wndTarget:SetTextFlags("DT_VCENTER", true)
    	wndTarget:SetTextFlags("DT_CENTER", true)
    	if wndTarget:GetName() == "SeparatorSmallLine" then 
    		wndTarget:SetSprite("CRB_Tooltips:sprTooltip_HorzDividerDiagonal") 
    		local l,t,r,b = wndTarget:GetAnchorOffsets()
    		wndTarget:SetAnchorOffsets(l,t+3,r,b-1)
    	end
    end
    if wndTooltip and string.find(item:GetName(),this.Locale["#Imprint"]) then -- gotta insert and arrange stuff
    	--local wndBox = wndTooltip:FindChild("SimpleRowSmallML")
    	local nGP = this:EPGPGetItemCostByID(item:GetItemId(),true)
    	if nGP == "" then return end -- cause there are imprints that are not GA/DS ones ... drop 6
    	local wndBox = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "ItemBasicStatsLine", wndTooltip:FindChild("ItemTooltip_BasicStatsBox"))
    	if wndBox then
    		wndBox:SetAML("<P Font=\"Nameplates\" TextColor=\"xkcdAmber\"> ".. nGP .. " GP".." </P>")
    		wndBox:SetTextFlags("DT_RIGHT",true)
    		wndBox:SetHeightToContentHeight()
    		wndBox:SetAnchorOffsets(130,0,0,wndBox:GetHeight())
    	end
    end   


    return wndTooltip , wndTooltipComp
end

function printAllStuff(wnd)
	if #wnd:GetChildren() > 0 then
		for k , child in ipairs(wnd:GetChildren()) do
			Print(child:GetName() .. " " .. child:GetText() .. "   parent: " .. wnd:GetName())
			printAllStuff(child)
		end
	end
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