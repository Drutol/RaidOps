-----------------------------------------------------------------------------------------------
-- Client Lua Script for LH
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- LH Module Definition
-----------------------------------------------------------------------------------------------
local LH = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
 local ktClassToIcon =
{
	[GameLib.CodeEnumClass.Medic]       	= "BK3:UI_Icon_CharacterCreate_Class_Medic",
	[GameLib.CodeEnumClass.Esper]       	= "BK3:UI_Icon_CharacterCreate_Class_Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function LH:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function LH:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- LH OnLoad
-----------------------------------------------------------------------------------------------
function LH:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("RaidOpsLootHex.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- LH OnDocLoaded
-----------------------------------------------------------------------------------------------
function LH:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self:FilterInit()
		Apollo.RegisterSlashCommand("ropshex", "FilterShow", self)
		Apollo.RegisterEventHandler("MasterLootUpdate","ProcessMasterLoot",self)
	end
end


function LH:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end

	local tSave = {}
	tSave.settings = self.settings
	return tSave
end

function LH:OnRestore(eLevel,tSave)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.settings = tSave.settings
end
-----------------------------------------------------------------------------------------------
-- Item assignement
-----------------------------------------------------------------------------------------------
function LH:ProcessMasterLoot()
	local tLootPool = GameLib.GetMasterLoot()
	for k , entry in ipairs(tLootPool or {}) do
		local bSkip = false
		if entry.bIsMaster and self:FilterIsRandomed(entry.itemDrop) then
			local unit = self:ChooseRandomLooter(entry)
			GameLib.AssignMasterLoot(entry.nLootId,unit)
			self:LogAdd(entry,unit)
		end
	end
end

function LH:ChooseRandomLooter(entry)
	local looters = {}
	for k , playerUnit in pairs(entry.tLooters or {}) do
		table.insert(looters,playerUnit)
	end	
	return looters[math.random(#looters)]
end

-----------------------------------------------------------------------------------------------
-- Logging
-----------------------------------------------------------------------------------------------
local tLogs = {}
function LH:LogAdd(entry,unit)
	table.insert(tLogs,1,{item = entry.itemDrop,strRecipient = unit:GetName(),class = ktClassToIcon[unit:GetClassId()]})
	if #tLogs > 20 then table.remove(tLogs,21) end
	if self.wndFilter:IsShown() then self:LogPopulate() end
end

function LH:LogPopulate()
	local list = self.wndFilter:FindChild("LogList")
	list:DestroyChildren()
	for k , log in ipairs(tLogs) do
		local wnd = Apollo.LoadForm(self.xmlDoc,"SummaryEntry",nil,self)
		wnd:FindChild("ItemFrame"):SetSprite(self:GetSlotSpriteByQualityRectangle(log.item:GetItemQuality()))
		wnd:FindChild("ItemIcon"):SetSprite(log.item:GetIcon())
		wnd:FindChild("ItemName"):SetText(log.item:GetName())
		Tooltip.GetItemTooltipForm(self,wnd:FindChild("ItemIcon"),log.item,{})

		wnd:FindChild("PlayerName"):SetText(log.strRecipient)
		wnd:FindChild("ClassIcon"):SetSprite(log.class)
	end
	list:ArrangeChildrenVert()
end
-----------------------------------------------------------------------------------------------
-- Filtering
-----------------------------------------------------------------------------------------------

function LH:FilterInit()
	self.wndFilter = Apollo.LoadForm(self.xmlDoc,"Filters",nil,self)
	self.wndFilter:Show(false)

	-- Defaults
	if not self.settings then self.settings = {} end
	if not self.settings.tFilters then self.settings.tFilters = {} end
	if self.settings.tFilters.bSignsAuto == nil then self.settings.tFilters.bSignsAuto = false end	
	if self.settings.tFilters.bPatternsAuto == nil then self.settings.tFilters.bPatternsAuto = false end	
	if self.settings.tFilters.bSchemAuto == nil then self.settings.tFilters.bSchemAuto = false end		
	if self.settings.tFilters.bWhiteAuto == nil then self.settings.tFilters.bWhiteAuto = false end		
	if self.settings.tFilters.bGrayAuto == nil then self.settings.tFilters.bGrayAuto = false end		
	if self.settings.tFilters.bGreenAuto == nil then self.settings.tFilters.bGreenAuto = false end	
	if self.settings.tFilters.bBlueAuto == nil then self.settings.tFilters.bBlueAuto = false end

	-- Fill in

	self.wndFilter:FindChild("Sign"):SetCheck(self.settings.tFilters.bSignsAuto)	
	self.wndFilter:FindChild("Patt"):SetCheck(self.settings.tFilters.bPatternsAuto)	
	self.wndFilter:FindChild("Schem"):SetCheck(self.settings.tFilters.bSchemAuto)	
	self.wndFilter:FindChild("Gray"):SetCheck(self.settings.tFilters.bGrayAuto)	
	self.wndFilter:FindChild("White"):SetCheck(self.settings.tFilters.bWhiteAuto)
	self.wndFilter:FindChild("Green"):SetCheck(self.settings.tFilters.bGreenAuto)	
	self.wndFilter:FindChild("Blue"):SetCheck(self.settings.tFilters.bBlueAuto)

	-- Populate custom
	if not self.settings.tFilters.tCustom then self.settings.tFilters.tCustom = {} end

	self:FilterPopulate()
end

function LH:FilterShow() 
	self.wndFilter:Show(true,false)
	self.wndFilter:ToFront()
	self:LogPopulate()
	self:FilterPopulate()
end

function LH:FilterHide()
	self.wndFilter:Show(false,false)
end

local function containsWord(tWords,word)
	for k , strWord in ipairs(tWords) do
		if strWord == word then return true end
	end
	return false 
end

function LH:FilterIsAuto(item)
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

function LH:FilterPopulate()
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
function LH:FilterArrangeWords()
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

function LH:FilterAddCustom(wndHandler,wndControl,strText)
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

function LH:FilterRemoveCustom(wndHandler,wndControl)
	for k , tFilter in ipairs(self.settings.tFilters.tCustom) do
		if tFilter.strKeyword == wndControl:GetParent():GetName() then table.remove(self.settings.tFilters.tCustom,k) break end
	end
	self:FilterPopulate()
end

function LH:FilterEnablePreset(wndHandler,wndControl)
	if wndControl:GetName() == "Auto" then wndControl = wndControl:GetParent() end
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

function LH:FilterDisablePreset(wndHandler,wndControl)
	if wndControl:GetName() == "Auto" then wndControl = wndControl:GetParent() end
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
-- LH Instance
-----------------------------------------------------------------------------------------------
local LHInst = LH:new()
LHInst:Init()
