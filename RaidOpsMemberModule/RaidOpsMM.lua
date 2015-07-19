-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOpsMM
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ICComm"

local Major, Minor, Patch, Suffix = 1, 16, 0, 0
 
-----------------------------------------------------------------------------------------------
-- RaidOpsMM Module Definition
-----------------------------------------------------------------------------------------------
local RaidOpsMM = {} 
 
local knVersion = 1.94
 
local kUIBody = "ff39b5d4"
local ktAuctionHeight = 119
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


local ktStringToIcon =
{
	["Medic"]       	= "Icon_Windows_UI_CRB_Medic",
	["Esper"]       	= "Icon_Windows_UI_CRB_Esper",
	["Warrior"]     	= "Icon_Windows_UI_CRB_Warrior",
	["Stalker"]     	= "Icon_Windows_UI_CRB_Stalker",
	["Engineer"]    	= "Icon_Windows_UI_CRB_Engineer",
	["Spellslinger"]  	= "Icon_Windows_UI_CRB_Spellslinger",
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

-- Localization stuff
local ktLocales = {
	[1] = "enUS",
	[2] = "deDE",
	[3] = "frFR",
	[4] = "koKR",
}

local function GetLocale()
	local strCancel = Apollo.GetString(1)
	
	-- German
	if strCancel == "Abbrechen" then 
		return ktLocales[2]
	end
	
	-- French
	if strCancel == "Annuler" then
		return ktLocales[3]
	end
	
	-- Other
	return ktLocales[1]
end
local strLocale = GetLocale()
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
		self.wndStandings = Apollo.LoadForm(self.xmlDoc,"StandingsMain",nil,self)
		self.wndLogs = Apollo.LoadForm(self.xmlDoc,"Logs",nil,self)

		Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)	
		self.wndSettings:Show(false, true)
		self.wndAnchor:Show(false, true)
		self.wndLootList:Show(false, true)
		self.wndCost:Show(false, true)
		self.wndStandings:Show(false, true)
		self.wndLogs:Show(false,true)
		
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
		if self.tItems == nil then self.tItems = {} end
		if self.SlotValues == nil then self.SlotValues = defaultSlotValues end
		if self.QualityValues == nil then self.QualityValues = defaultQualityValues end
		if self.CustomModifier == nil then self.CustomModifier = .5 end
		if self.settings.resize == nil then self.settings.resize = true end
		if self.settings.bAutoClose == nil then self.settings.bAutoClose = false end
		if self.settings.bKeepOnTop == nil then self.settings.bKeepOnTop = true end
		if self.settings.nReportedVersion == nil then self.settings.nReportedVersion = knVersion end
		if self.settings.bDisplayApplicable == nil then self.settings.bDisplayApplicable = false end
		if self.settings.bOthers == nil then self.settings.bOthers = true end
		if self.settings.bCloseAssign == nil then self.settings.bCloseAssign = true end
		
		if self.settings.bCloseAssign then 	Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self) end
		
		if self.settings.nReportedVersion > knVersion then Print("[RaidOpsMM]Addon is outdated and therefore errors may arise, please update.Newest reported version is: "..self.settings.nReportedVersion) end
		
		if self.settings.enable then 
			self:JoinGuildChannel()
		end
		self:FillInCostFormula()
		self:RestoreSettings()
		local l,t,r,b = self.wndAnchor:GetAnchorOffsets()
		if self.ResizedWndBottom then self.wndLootList:SetAnchorOffsets(l,t,r,self.ResizedWndBottom) end
		--Sizing
		self.wndLootList:SetSizingMaximum(564,349)
		self.wndLootList:SetSizingMinimum(564,140)
		
		self.tMLs = {}
		Apollo.RegisterSlashCommand("ropsmm", "OnRaidOpsMMOn", self)
		Apollo.RegisterSlashCommand("ropsmms", "StandingsShow", self)
		Apollo.RegisterTimerHandler(1,"InitDelay",self)
		self.delayTimer = ApolloTimer.Create(1,true,"InitDelay",self)
		
		self.searchString = ""
		self.settings.SortOrder = "desc"
		self.wndStandings:FindChild("Standings"):FindChild("Label1"):SetData("desc")
		self.wndStandings:FindChild("Standings"):FindChild("Label2"):SetData("desc")
		self.wndStandings:FindChild("Standings"):FindChild("Label3"):SetData("desc")
		self.wndStandings:FindChild("Standings"):FindChild("Label4"):SetData("desc")		
		
		self.wndStandings:FindChild("Standings"):FindChild("Label1"):FindChild("SortIndicator"):Show(false)
		self.wndStandings:FindChild("Standings"):FindChild("Label2"):FindChild("SortIndicator"):Show(false)
		self.wndStandings:FindChild("Standings"):FindChild("Label3"):FindChild("SortIndicator"):Show(false)
		self.wndStandings:FindChild("Standings"):FindChild("Label4"):FindChild("SortIndicator"):Show(false)

		
		if self.settings.lastFetch == nil then self.settings.lastFetch = 0 end
		if self.settings.strSource == nil then self.settings.strSource = "Type something here!" end
		self.wndStandings:FindChild("Source"):SetText(self.settings.strSource)
		if self.group then self.wndStandings:FindChild("Controls"):FindChild("Group"):SetCheck(self.group) end
		
		--self:LogsFetched("ZG8gbG9jYWwgXz17e3N0ck1vZGlmaWVyPS0xMjAsc3RyQ29tbWVudD0idGVzdDYiLHN0clR5cGU9IntFUH0iLHN0clRpbWVzdGFtcD0iMi85LzIwMTUgIDEwOjA3OjE4IEFNIn0se3N0ck1vZGlmaWVyPS0xMDAsc3RyQ29tbWVudD0idGVzdDYiLHN0clR5cGU9IntHUH0iLHN0clRpbWVzdGFtcD0iMi85LzIwMTUgIDEwOjA3OjA4IEFNIn0se3N0ck1vZGlmaWVyPTEwMCxzdHJDb21tZW50PSJ0ZXN0NiIsc3RyVHlwZT0ie0dQfSIsc3RyVGltZXN0YW1wPSIyLzkvMjAxNSAgMTA6MDY6NTggQU0ifSx7c3RyTW9kaWZpZXI9MTAwLHN0ckNvbW1lbnQ9InRlc3QyIixzdHJUeXBlPSJ7R1B9IixzdHJUaW1lc3RhbXA9IjIvOS8yMDE1ICAxMDowNjo1NSBBTSJ9LHtzdHJNb2RpZmllcj0xMDAsc3RyQ29tbWVudD0idGVzdDEiLHN0clR5cGU9IntFUH0iLHN0clRpbWVzdGFtcD0iMi85LzIwMTUgIDEwOjA2OjUxIEFNIn19O3JldHVybiBfO2VuZA==")
		
		--
		if self.tLogs == nil then self.tLogs = {} end
	end
end
local delay = 2
function RaidOpsMM:InitDelay()
	delay = delay - 1
	if delay == 0 then 
		self:Bid2PackAndSend({type = "ArUaML"})
		self.delayTimer:Stop()
		if self.settings.tooltips == true then self:EPGPHookToETooltip() self.wndSettings:FindChild("TooltipCost"):SetCheck(true) end
		Event_FireGenericEvent("OneVersion_ReportAddonInfo", "RaidOpsMM", Major, Minor, Patch)
		Apollo.RemoveEventHandler("InitDelay",self)
	end
end

function RaidOpsMM:PurgeData()
	self.tItems = {}
	self:RefreshStandings()
end

function RaidOpsMM:LoadExample()
	self:StandingsFetched("ZG8gbG9jYWwgXz17WyJOZWVyYSBaeW5uIl09e1BSPSIyLjUiLGNsYXNzPSJNZWRpYyIsR1A9NjAxLEVQPTE1MDB9LFsiTG9yZCBCcmFwcGluZ3RvbiJdPXtQUj0iMS4wIixjbGFzcz0iRW5naW5lZXIiLEdQPTYwMSxFUD02MDB9LFsiTWlyYWxpcyB2YW5IZWFsc2luZyJdPXtQUj0iMTYwMC4wIixjbGFzcz0iTWVkaWMiLEdQPTEsRVA9MTYwMH0sRVBHUD0xLFsiTXVnYWJlIFNjcnVic2xhcHBlciJdPXtQUj0iMzAwLjAiLGNsYXNzPSJTcGVsbHNsaW5nZXIiLEdQPTEsRVA9MzAwfSxbIlJ1bmRvIFRyZWVmb2NrZXIiXT17UFI9IjExMDAuMCIsY2xhc3M9IkVzcGVyIixHUD0xLEVQPTExMDB9LFsiQW5oaSBCdWdlYXJlZCJdPXtQUj0iODAwLjAiLGNsYXNzPSJTdGFsa2VyIixHUD0xLEVQPTgwMH0sWyJNZWVrbyBCcmlhcnRob3JuIl09e1BSPSI2MDAuMCIsY2xhc3M9IkVzcGVyIixHUD0xLEVQPTYwMH0sWyJTb2thaWkgU2hpbmRhZ2VtdSJdPXtQUj0iMTQwMC4wIixjbGFzcz0iRW5naW5lZXIiLEdQPTEsRVA9MTQwMH0sWyJzZXJPbiB6ZXJPIl09e1BSPSI4MDAuMCIsY2xhc3M9Ik1lZGljIixHUD0xLEVQPTgwMH0sWyJWZW5vbXVzIEthbWFpIl09e1BSPSIxMDAuMCIsY2xhc3M9IkVzcGVyIixHUD0xLEVQPTEwMH0sWyJEcnV0b2wgV2luZGNoYXNlciJdPXtQUj0iMTAwLjAiLGNsYXNzPSJFc3BlciIsR1A9MSxFUD0xMDB9LFsiT3ggc3RhbGtlciJdPXtQUj0iOTAwLjAiLGNsYXNzPSJTdGFsa2VyIixHUD0xLEVQPTkwMH0sWyJQcmluY2UgVmVnZXRhIl09e1BSPSI4MDAuMCIsY2xhc3M9Ik1lZGljIixHUD0xLEVQPTgwMH0sWyJUYXVubmlzIEJ1YmJsZXMiXT17UFI9IjMwMC4wIixjbGFzcz0iRXNwZXIiLEdQPTEsRVA9MzAwfSxbIkVtYmVyIEJlYXJzIl09e1BSPSI4MDAuMCIsY2xhc3M9IlNwZWxsc2xpbmdlciIsR1A9MSxFUD04MDB9LFsiTWFsbGllIEdhbGVzdGFyIl09e1BSPSIxMDAuMCIsY2xhc3M9IlN0YWxrZXIiLEdQPTEsRVA9MTAwfSxbIlNhdmlvdXIgQW5nZWwiXT17UFI9IjEwMC4wIixjbGFzcz0iU3BlbGxzbGluZ2VyIixHUD0xLEVQPTEwMH0sWyJoYWVkdWx1cyBlbmdpbmVlciJdPXtQUj0iMS4yIixjbGFzcz0iRW5naW5lZXIiLEdQPTEyMDEsRVA9MTQwMH0sWyJBbG9uYSBNYXJvIl09e1BSPSIxMDAuMCIsY2xhc3M9Ik1lZGljIixHUD0xLEVQPTEwMH0sWyJEcmFhZ3Jlb3YgRmFydGJlbmRlciJdPXtQUj0iMTQwMC4wIixjbGFzcz0iTWVkaWMiLEdQPTEsRVA9MTQwMH19O3JldHVybiBfO2VuZA==")
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

---------------
-- Delay
---------------
local tDelayActions = {}
local bDelayRunning = false
function RaidOpsMM:delay(nSecs,func,args)

	table.insert(tDelayActions,{func = func , delay = nSecs , args = args})
	if not bDelayRunning then
		Apollo.RegisterTimerHandler(1,"DelayTimer",self)
		self.delayTimer = ApolloTimer.Create(1,true,"DelayTimer",self)
		bDelayRunning = true

	end
	return #tDelayActions
end

function RaidOpsMM:DelayTimer()
	for k , event in ipairs(tDelayActions) do
		event.delay = event.delay - 1
		if event.delay == 0 then

			event.func(self)
			table.remove(tDelayActions,k)
		end
	end

	if #tDelayActions == 0 then 
		self.delayTimer:Stop() 
		bDelayRunning = false
	end
end

function RaidOpsMM:OnChatMessage(channelCurrent, tMessage)
	if not self.settings.bCloseAssign then return end
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Loot then 
		if strLocale == "enUS" then
			local itemStr = ""
			local strName = ""
			local strTextLoot = ""
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextLoot = strTextLoot .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
			local bFound = false 
			for word in string.gmatch(strTextLoot,"%S+") do
				table.insert(words,word)
			end
			
			if words[1] ~= "The"  then return end
	
			local collectingItem = true
			for i=5 , table.getn(words) do
				if words[i] == "to" then collectingItem = false end
				if collectingItem == true then
					itemStr = itemStr .." ".. words[i]
				elseif words[i] ~= "to" then
					strName = strName .. " " .. words[i]
				end
			end
			
			local strItem = string.sub(itemStr,2)
			
			for k ,auction in ipairs(self.ActiveAuctions) do
				if auction.strItem == strItem then
					self:RemoveAuction(auction.wnd:GetData(),true)
				end
			end		
		elseif strLocale == "deDE" then
			local strItem = ""
			local strName = ""
			local strTextLoot = ""
			for i=1, table.getn(tMessage.arMessageSegments) do
				strTextLoot = strTextLoot .. tMessage.arMessageSegments[i].strText
			end
			local words = {}
			local bFound = false
			for word in string.gmatch(strTextLoot,"%S+") do
				table.insert(words,word)
			end
			 if words[1] ~= "Der" then return end
			 strName = words[#words - 2] .. " " .. words[#words - 1]
			 for k=4,#words - 3 do
				strItem = strItem .. " " .. words[k]
			 end
			 
		         	 strItem = string.sub(strItem,2)
			 
			for k ,auction in ipairs(self.ActiveAuctions) do
				if auction.strItem == strItem then
					self:RemoveAuction(auction.wnd:GetData(),true)
				end
			end
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
		self:Bid2PackAndSendPrivate(strML,{type = "GimmeAuctions"})
	end
end

function RaidOpsMM:FetchOnlineML()
	if self.channel then self:Bid2PackAndSend({type = "ArUaML"}) end
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
	tSave.tItems = self.tItems
	tSave.settings = self.settings
	tSave.loc = self.wndAnchor:GetLocation():ToTable()
	tSave.SlotValues = self.SlotValues
	tSave.QualityValues = self.QualityValues
	tSave.CustomModifier = self.CustomModifier
	tSave.MyChoices = self.MyChoices
	tSave.Group = self.wndStandings:FindChild("Controls"):FindChild("Group"):IsChecked()
	tSave.tLogs = self.tLogs
	local l,t,r,b =  self.wndLootList:GetAnchorOffsets()
	tSave.ResizedWndBottom = b
	return tSave
end

function RaidOpsMM:OnRestore(eLevel, tData)	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.tItems = tData.tItems
	self.settings = tData.settings
	self.SlotValues = tData.SlotValues
	self.QualityValues = tData.QualityValues
	self.CustomModifier = tData.CustomModifier
	self.wndAnchorloc  = WindowLocation.new(tData.loc)
	self.ResizedWndBottom = tData.ResizedWndBottom
	self.MyChoices = tData.MyChoices
	self.group = tData.Group
	self.tLogs = tData.tLogs
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
	if string.len(strText) <= 4 then 
		wndControl:SetText(self.settings.strChannel) 
		return 
	end
	self.settings.strChannel = strText
	self:JoinGuildChannel()
end

function RaidOpsMM:RestoreSettings()
	self.wndSettings:FindChild("DispApplicable"):SetCheck(self.settings.bDisplayApplicable)
	self.wndSettings:FindChild("AutoCloseDistributed"):SetCheck(self.settings.bCloseAssign)
	if self.settings.enable then self.wndSettings:FindChild("Enable"):SetCheck(true) end
	if self.settings.tooltip then self.wndSettings:FindChild("TooltipCost"):SetCheck(true) end
	if self.settings.resize then self.wndSettings:FindChild("AllowResize"):SetCheck(true) end
	if self.settings.bKeepOnTop then self.wndSettings:FindChild("KeepOnTop"):SetCheck(true) end
	if self.settings.bAutoClose then self.wndSettings:FindChild("AutoClose"):SetCheck(true) end
	self.wndSettings:FindChild("ShowOthers"):SetCheck(self.settings.bOthers)
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
	local guilds = GuildLib.GetGuilds() or {}
	for k,guild in ipairs(guilds) do 
		if guild:GetType() == GuildLib.GuildType_Guild then
			self.uGuild = guild
			break
		end
	end
	if self.uGuild then
		self.settings.strChannel = "ROPSGuildSpecific"
		self.channel = ICCommLib.JoinChannel(self.settings.strChannel,ICCommLib.CodeEnumICCommChannelType.Guild,self.uGuild)
		self.channel:SetReceivedMessageFunction("OnReceivedRequest",self)
	end
end

function RaidOpsMM:Bid2PackAndSend(tData)
	if not tData.type then return end
	tData.strSender = GameLib.GetPlayerUnit():GetName()
	local strData = serpent.dump(tData)
	if self.channel then self.channel:SendMessage("ROPS" .. strData) end
end

function RaidOpsMM:Bid2PackAndSendPrivate(strTarget,tData)
	if not tData.type then return end
	tData.strSender = GameLib.GetPlayerUnit():GetName()
	local strData = serpent.dump(tData)
	if self.channel then self.channel:SendPrivateMessage(strTarget,"ROPS" .. strData) end
	
end
function RaidOpsMM:OnReceivedRequest(channel, strMessage, idMessage)
	if string.sub(strMessage, 1, 4)  ~= "ROPS" then return end
	local tMsg = serpent.load(string.sub(strMessage,5))
	
	if tMsg then
		if tMsg.ver then 
			self.settings.nReportedVersion = tMsg.ver
			if self.settings.nReportedVersion > knVersion then Print("[RaidOpsMM]Addon is outdated and therefore errors may arise, please update.Newest reported version is: "..self.settings.nReportedVersion) end
		end
		if tMsg.type and tMsg.strSender then
			if tMsg.type == "WantConfirmation" then
				local msg = {}
				msg.type = "Confirmation"
				self:Bid2PackAndSend(msg)
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
				self:AddAuction(tMsg.itemID,tMsg.cost,tMsg.duration,nil,tMsg.pass,tMsg.tLabels,tMsg.tLabelsState)
			elseif tMsg.type == "AuctionPaused" then
				self:OnAuctionPasused(tMsg.item)
			elseif tMsg.type == "AuctionResumed" then
				self:OnAuctionResumed(tMsg.item)
			elseif tMsg.type == "IamML" then
				self.tMLs[tMsg.strSender] = 1
				self:UpdateMLsTooltip()
				if #self.tMLs == 1 then self:FetchActiveAuctions(tMsg.strSender) end
			elseif tMsg.type == "ActiveAuction" then
				self:AddAuction(tMsg.item,0,tMsg.duration,true,tMsg.progress)
			elseif tMsg.type == "SendMeThemChoices" then
				for k,choice in ipairs(self.MyChoices) do if tMsg.item == choice.item then self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "Choice",item = choice.item,option = choice.option}) break end end
			elseif tMsg.type == "AuctionTimeUpdate" then
				self:OnAuctionPasused(tMsg.item)
				self:UpdateAuctionProgress(tMsg.item,tMsg.progress)
			elseif tMsg.type == "GimmeUrEquippedItem" then -- From RaidOpsML
				local forItem = Item.GetDataFromId(tMsg.item)
				if forItem and forItem:IsEquippable() and forItem:GetEquippedItemForItemType() then self:Bid2PackAndSendPrivate(tMsg.strSender,{type = "MyEquippedItem",item = forItem:GetEquippedItemForItemType():GetItemId()}) end
			elseif tMsg.type == "EncodedStandings" then
				self:StandingsFetched(tMsg.strData)			
			elseif tMsg.type == "EncodedLogs" then
				self:LogsFetched(tMsg.strData)
			elseif tMsg.type == "Choice" then
				self:RegisterMemberChoice(tMsg.strSender,tMsg.option,tMsg.item)
			end
		end
	end
end

function RaidOpsMM:RegisterMemberChoice(strBidder,option,item)
	if not self.settings.bOthers then return end
	for k , auction in ipairs(self.ActiveAuctions) do
		if auction.wnd:GetData() == item then
			if auction.others == nil then auction.others = {} end
			if auction.others[option] == nil then auction.others[option] = {} end
			
			for k , others in pairs(auction.others) do
				for j, other in ipairs(others) do
					if other == strBidder then table.remove(others,j) break end
				end
			end			
			
			table.insert(auction.others[option],strBidder)
			self:UpdateOthers(auction)
			break
		end
	end
end

function RaidOpsMM:UpdateOthers(auction)
	if auction.others == nil then 
		auction.others = {}
		for k=1,4 do
			if self.settings.bOthers then
				auction.wnd:FindChild("OthersOpt"..k):SetText("")
				auction.wnd:FindChild("OthersOpt"..k):SetTooltip("Nobody chose this option yet.") 
			else
				auction.wnd:FindChild("OthersOpt"..k):Show(false)
			end
		end
		return
	end
	for k , others in pairs(auction.others) do
		auction.wnd:FindChild("Others"..k):SetText(#others > 0 and #others or "")
		strTooltip = #others > 0 and "Other players who chose this option:\n" or "Nobody chose this option yet."
		for j, other in ipairs(others) do
			strTooltip = strTooltip .. other .. "\n"
		end
		auction.wnd:FindChild("Others"..k):SetTooltip(strTooltip)
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
	local rItem = math.random(1,60000)
	self:AddAuction(rItem,1000,30,nil,false,{[1] = "Test1" , [2] = "Test2" , [3] = "Test3"},{[1] = true , [2] = true , [3] = true})
	for k=1,math.random(20) do
		self:RegisterMemberChoice("Player"..math.random(20),"Opt"..math.random(1,4),rItem)
	end
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

function RaidOpsMM:DisplayApplicableEnable()
	self.settings.bDisplayApplicable = true
end

function RaidOpsMM:DisplayApplicableDisable()
	self.settings.bDisplayApplicable = false
end

function RaidOpsMM:ShowOthersEnable()
	self.settings.bOthers = true
end	

function RaidOpsMM:ShowOthersDisable()
	self.settings.bOthers = false
end

function RaidOpsMM:CloseAssignEnable()
	self.settings.bCloseAssign = true
	Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
end	

function RaidOpsMM:CloseAssignDisable()
	self.settings.bCloseAssign = false
end
---------------------------------------------------------------------------------------------------
-- Auction Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMM:AddAuction(itemID,cost,duration,progress,pass,tLabels,tLabelState)
	if progress == nil then progress = 0 end
	local item = Item.GetDataFromId(itemID)
	
	if self.settings.bDisplayApplicable and item then
		local myClass = GameLib.GetPlayerUnit():GetClassId()
		 if myClass then
			local strCategory = item:GetItemCategoryName()
			local strClass = ktClassToString[myClass]
			if string.find(strCategory,"Light") and strClass == "Esper" or string.find(strCategory,"Light") and strClass == "Spellslinger" then
			elseif  string.find(strCategory,"Medium") and strClass == "Stalker" or string.find(strCategory,"Medium") and strClass == "Medic" then
			elseif  string.find(strCategory,"Heavy") and strClass == "Warrior" or string.find(strCategory,"Heavy") and strClass == "Engineer" then
			elseif not string.find(strCategory,"Heavy") and not string.find(strCategory,"Medium") and not string.find(strCategory,"Light") then
			else item = nil end
			if item then
				if string.find(strCategory,"Psyblade") and strClass ~= "Esper" or string.find(strCategory,"Heavy Gun") and strClass ~= "Engineer" or string.find(strCategory,"Pistols") and strClass ~= "Spellslinger" or string.find(strCategory,"Claws") and strClass ~= "Stalker" or string.find(strCategory,"Greatsword") and strClass ~= "Warrior" or string.find(strCategory,"Resonators") and strClass ~= "Medic" then item = nil end 
			end
		end 
	end


	if item then
		local wndAuction = Apollo.LoadForm(self.xmlDoc,"Auction",self.wndLootList:FindChild("Auctions"),self)
		wndAuction:FindChild("Frame"):SetSprite(self:GetSlotSpriteByQuality(item:GetItemQuality()))
		wndAuction:FindChild("Remove"):Enable(false)
		wndAuction:FindChild("Frame"):FindChild("Icon"):SetSprite(item:GetIcon())
		
		for k,strLabel in ipairs(tLabels) do
			wndAuction:FindChild("Opt"..k):SetText(strLabel)
		end		
		for k,bLabel in ipairs(tLabelState) do
			wndAuction:FindChild("Opt"..k):Enable(bLabel)
		end
		if cost then wndAuction:FindChild("ItemCost"):SetText(cost .. " GP") else wndAuction:FindChild("ItemCost"):Show(false,false) end
		wndAuction:SetMax(duration)
		wndAuction:SetProgress(progress,100)
		wndAuction:SetData(itemID)
		table.insert(self.ActiveAuctions,{wnd = wndAuction , bActive = true , nTimeLeft = progress, nDuration = duration, bPass = pass , strItem = item:GetName()})
		if self.Timer == nil then self:AuctionTimerStart() end
		Tooltip.GetItemTooltipForm(self, wndAuction:FindChild("Icon") , item, {bPrimary = true, bSelling = false, itemCompare = item:GetEquippedItemForItemType()})
		self.wndLootList:Show(true,false)
		self:ArrangeAuctions()
		self:UpdateOthers(self.ActiveAuctions[#self.ActiveAuctions])
		self.wndLootList:ToFront()
	end
end

function RaidOpsMM:ArrangeAuctions()
	if self.settings.resize and #self.ActiveAuctions < 3 then
		local l,t,r,b = self.wndAnchor:GetAnchorOffsets()
		self.wndLootList:SetAnchorOffsets(l,t,r,b+((#self.ActiveAuctions-1)*ktAuctionHeight)+10)
	else
		local l,t,r,b = self.wndAnchor:GetAnchorOffsets()
		self.wndLootList:SetAnchorOffsets(l,t,r,b+(ktAuctionHeight-2)*2)
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
		for k,choice in ipairs(self.MyChoices) do if choice.item == wndControl:GetParent():GetData() and choice.option == "Opt4" then bPass = true break end end
		if not bPass and self.settings.bAutoClose and wndControl:GetName() == "Opt4" then
			self:RemoveAuction(wndControl:GetParent():GetData())
			return
		end
		if not bPass and wndControl:GetName() == "Opt4" then 
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
			if item:GetEquippedItemForItemType() then msg.itemCompare = item:GetEquippedItemForItemType():GetItemId() end
			self:Bid2PackAndSend(msg)
			if msg.option == "Opt4" then 
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

function RaidOpsMM:RemoveAuction(itemID,bMany)
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
			if not bMany then break end
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
				auction.wnd:FindChild("Opt1"):Enable(false)
				auction.wnd:FindChild("Opt2"):Enable(false)
				auction.wnd:FindChild("Opt3"):Enable(false)
				auction.wnd:FindChild("Opt4"):Enable(false)
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


local originalTootltipFunction
function RaidOpsMM:HookToTooltip()
	-- Based on EToolTip implementation
	if self.originalTootltipFunction then return end
	aAddon = Apollo.GetAddon("ToolTips")
	self.originalTootltipFunction = Tooltip.GetItemTooltipForm
    local origCreateCallNames = aAddon.CreateCallNames
    if not origCreateCallNames then return end
    aAddon.CreateCallNames = function(luaCaller)
        origCreateCallNames(luaCaller) 
        originalTootltipFunction = Tooltip.GetItemTooltipForm
        Tooltip.GetItemTooltipForm  = function (luaCaller, wndControl, item, bStuff, nCount)
        	return self.EnhanceItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
        end
    end
    aAddon.CreateCallNames()
    
end
 
function RaidOpsMM:EPGPHookToETooltip( wndHandler, wndControl, eMouseButton )
	if Apollo.GetAddon("RaidOps") then 
		Print("Master addon already installed")
		self.settings.tooltips = false
		if wndControl ~= nil then wndControl:SetCheck(false) end
		return
	end
	if not Apollo.GetAddon("ETooltip") then
		self.settings.tooltips = true
		
		self:HookToTooltip()
	else
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
		self.settings.tooltips = true
		--Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
		if not self:IsHooked(Apollo.GetAddon("ETooltip"),"AttachBelow") then
			self:RawHook(Apollo.GetAddon("ETooltip"),"AttachBelow")
		end
	end
end

function RaidOpsMM:EnhanceItemTooltip(wndControl,item,tOpt,nCount)
    local this = Apollo.GetAddon("RaidOpsMM")
    wndControl:SetTooltipDoc(nil)
    local wndTooltip, wndTooltipComp = this.originalTootltipFunction(self, wndControl, item, tOpt, nCount)
    local wndTarget
   	if wndTooltip then wndTarget = wndTooltip:FindChild("SeparatorDiagonal") and wndTooltip:FindChild("SeparatorDiagonal") or wndTooltip:FindChild("SeparatorSmallLine") end
    if wndTooltip and wndTarget and item and item:IsEquippable() then
    	local val = this:EPGPGetItemCostByID(item:GetItemId(),true)
    	wndTarget:SetText(val ~= "" and (val .. " GP") or "")
    	wndTarget:SetTextColor("xkcdAmber")
    	wndTarget:SetFont("Nameplates")
    	if wndTarget:GetName() == "SeparatorSmallLine" then 
    		wndTarget:SetSprite("CRB_Tooltips:sprTooltip_HorzDividerDiagonal") 
    		local l,t,r,b = wndTarget:GetAnchorOffsets()
    		wndTarget:SetAnchorOffsets(l,t+3,r,b-1)
    	end
    	wndTarget:SetTextFlags("DT_VCENTER", true)
    	wndTarget:SetTextFlags("DT_CENTER", true)
    end
    if wndTooltipComp then wndTarget = wndTooltipComp:FindChild("SeparatorDiagonal") and wndTooltipComp:FindChild("SeparatorDiagonal") or wndTooltipComp:FindChild("SeparatorSmallLine") end
    if wndTooltipComp and wndTarget and tOpt.itemCompare and tOpt.itemCompare:IsEquippable() then
    	local val = this:EPGPGetItemCostByID(tOpt.itemCompare:GetItemId(),true)
    	wndTarget:SetText(val ~= "" and (val .. " GP") or "")
    	wndTarget:SetTextColor("xkcdAmber")
    	wndTarget:SetFont("Nameplates")
    	if wndTarget:GetName() == "SeparatorSmallLine" then 
    		wndTarget:SetSprite("CRB_Tooltips:sprTooltip_HorzDividerDiagonal") 
    		local l,t,r,b = wndTarget:GetAnchorOffsets()
    		wndTarget:SetAnchorOffsets(l,t+3,r,b-1)
    	end
    	wndTarget:SetTextFlags("DT_VCENTER", true)
    	wndTarget:SetTextFlags("DT_CENTER", true)
    end
    if wndTooltip and string.find(item:GetName(),"Imprint") then
    	local wndBox = wndTooltip:FindChild("ItemTooltip_BasicStats_TopLeft")
    	wndBox:SetAML("<P Font=\"CRB_InterfaceSmall\" TextColor=\" ff39b5d4\">"..string.format("<T TextColor=\"%s\">%s</T>", kUIBody, String_GetWeaselString(Apollo.GetString("Tooltips_ItemLevel"), item:GetDetailedInfo().tPrimary.nEffectiveLevel)) ..  "<T Font=\"Nameplates\" TextColor=\"xkcdAmber\">  ".. self:EPGPGetItemCostByID(item:GetItemId(),true).. " GP".." </T>".."</P>")
    end   


    return wndTooltip , wndTooltipComp
end

function RaidOpsMM:EPGPUnHook( wndHandler, wndControl, eMouseButton )
	self.settings.tooltips = false
	self:Unhook(Apollo.GetAddon("ETooltip"),"AttachBelow")
	if originalTootltipFunction then
		Tooltip.GetItemTooltipForm = self.originalTootltipFunction
		self.originalTootltipFunction = nil
	end
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



---------------------------------------------------------------------------------------------------
-- Standings Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMM:StandingsSetDataProvider( wndHandler, wndControl, strText )
	self.settings.strSource = strText
end

function RaidOpsMM:StandingsFetch( wndHandler, wndControl, eMouseButton )
	if self.channel then self:Bid2PackAndSendPrivate(self.settings.strSource,{type = "SendMeThemStandings"}) end
end

function RaidOpsMM:LogsFetch()
	if self.channel then self:Bid2PackAndSendPrivate(self.settings.strSource,{type = "SendMeThemLogs"}) end
end

function RaidOpsMM:LogsShow()
	if not self.wndLogs:IsShown() then 
		local tCursor = Apollo.GetMouse()
		self.wndLogs:Move(tCursor.x - 100, tCursor.y - 100, self.wndLogs:GetWidth(), self.wndLogs:GetHeight())
	end
	
	self.wndLogs:Show(true,false)
	self.wndLogs:ToFront()
	
	self:LogsPopulate()
end

function RaidOpsMM:LogsFetched(strData)
	local tData = self:DecodeData(strData)
	if tData then
		self.tLogs = tData
	end
	self:LogsPopulate()
end

function RaidOpsMM:LogsPopulate()
	local grid = self.wndLogs:FindChild("Grid")
	grid:DeleteAll()
	for k,entry in ipairs(self.tLogs) do
		grid:AddRow(k..".")
		grid:SetCellData(k,1,entry.strComment)
		grid:SetCellData(k,3,entry.strType)
		grid:SetCellData(k,2,entry.strModifier)
		grid:SetCellData(k,4,entry.strTimestamp)
	end
end

function RaidOpsMM:LogsClose()
	self.wndLogs:Show(false,false)
end

function RaidOpsMM:StandingsFetched(strData)
	local tData = self:DecodeData(strData)
	if tData then
		for k,player in pairs (tData) do
			self.tItems[k] = player
		end
		self.settings.lastFetch = os.time()
		self:RefreshStandings()
	end

end

function RaidOpsMM:DecodeData(strData)
	if strData ~= "Only Raid Members can fetch data" then
		return serpent.load(Base64.Decode(strData))
	end
end

function RaidOpsMM:string_starts(String,Start)
	return string.sub(string.lower(String),1,string.len(Start))==string.lower(Start)
end

function RaidOpsMM:RefreshStandings()
	if self.wndStandings:FindChild("Controls"):FindChild("Group"):IsChecked() then self:RefreshStandingsAndGroup() return end
	
	self.wndStandings:FindChild("Standings"):FindChild("List"):DestroyChildren()
	if self.tItems["EPGP"] and self.tItems["EPGP"] == 1 then
		self.wndStandings:FindChild("Standings"):FindChild("Label2"):SetText("EP")
		self.wndStandings:FindChild("Standings"):FindChild("Label3"):SetText("GP")
		self.wndStandings:FindChild("Standings"):FindChild("Label4"):SetText("PR")
		for k,player in pairs(self.tItems) do
			if k ~= "EPGP" and self:string_starts(k,self.searchString) then
				if not self.wndStandings:FindChild("Controls"):FindChild("RaidOnly"):IsChecked() or self.wndStandings:FindChild("Controls"):FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(k) then
					local wnd = Apollo.LoadForm(self.xmlDoc,"ListItem",self.wndStandings:FindChild("Standings"):FindChild("List"),self)
					wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
					wnd:FindChild("Stat1"):SetText(k)
					wnd:FindChild("Stat2"):SetText(player.EP)
					wnd:FindChild("Stat3"):SetText(player.GP)
					wnd:FindChild("Stat4"):SetText(player.PR)
				end
			end
		end
	elseif self.tItems["EPGP"] then
		self.wndStandings:FindChild("Standings"):FindChild("Label2"):SetText("Net")
		self.wndStandings:FindChild("Standings"):FindChild("Label3"):SetText("Tot")
		self.wndStandings:FindChild("Standings"):FindChild("Label4"):Show(false,false)
		for k,player in pairs(self.tItems) do
			if k ~= "EPGP" and self:string_starts(k,self.searchString) then
				if not self.wndStandings:FindChild("Controls"):FindChild("RaidOnly"):IsChecked() or self.wndStandings:FindChild("Controls"):FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(k) then
					local wnd = Apollo.LoadForm(self.xmlDoc,"ListItem",self.wndStandings:FindChild("Standings"):FindChild("List"),self)
					wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
					wnd:FindChild("Stat1"):SetText(k)
					wnd:FindChild("Stat2"):SetText(player.net)
					wnd:FindChild("Stat3"):SetText(player.tot)
				end
			end
		end
	end
	
	self.wndStandings:FindChild("Standings"):FindChild("List"):ArrangeChildrenVert(0,raidOpsMMsortPlayerswithWnds)
	self:HighlightRow()
	self:CalculateLastFetch()
end

function RaidOpsMM:RefreshStandingsAndGroup()
	local esp = {}
	local war = {}
	local spe = {}
	local med = {}
	local sta = {}
	local eng = {}
	local unknown = {}
	
	self.wndStandings:FindChild("Standings"):FindChild("List"):DestroyChildren()
	
	for k,player in pairs(self.tItems) do
		if k ~= "EPGP" then 
			player.strName = k
			if player.class ~= nil then
				if player.class == "Esper" then
					table.insert(esp,player)
				elseif player.class == "Engineer" then
					table.insert(eng,player)
				elseif player.class == "Medic" then
					table.insert(med,player)
				elseif player.class == "Warrior" then
					table.insert(war,player)
				elseif player.class == "Stalker" then
					table.insert(sta,player)
				elseif player.class == "Spellslinger" then
					table.insert(spe,player)
				end
			else
				table.insert(unknown,player)
			end
		end
	end
	local tables = {
		[1] = esp,
		[2] = eng,
		[3] = med,
		[4] = war,
		[5] = sta,
		[6] = spe,
		[7] = unknown,
	}
	
	if self.tItems["EPGP"] == 1 then self.epgpmode = true else self.epgpmode = false end
	
	for k,tab in ipairs(tables) do
		table.sort(tab,raidOpsMMsortPlayers)
	end
	
	if self.tItems["EPGP"] and self.tItems["EPGP"] == 1 then
		self.wndStandings:FindChild("Standings"):FindChild("Label2"):SetText("EP")
		self.wndStandings:FindChild("Standings"):FindChild("Label3"):SetText("GP")
		self.wndStandings:FindChild("Standings"):FindChild("Label4"):SetText("PR")
	else
		self.wndStandings:FindChild("Standings"):FindChild("Label2"):SetText("Net")
		self.wndStandings:FindChild("Standings"):FindChild("Label3"):SetText("Tot")
		self.wndStandings:FindChild("Standings"):FindChild("Label4"):Show(false,false)
	end
	
	

	
	for j,tab in ipairs(tables) do
		local added = false
		for k,player in ipairs(tab) do
			if not self.wndStandings:FindChild("Controls"):FindChild("RaidOnly"):IsChecked() or self.wndStandings:FindChild("Controls"):FindChild("RaidOnly"):IsChecked() and self:IsPlayerInRaid(player.strName) then
				if self.tItems["EPGP"] and self.tItems["EPGP"] == 1 then
					if self:string_starts(player.strName,self.searchString) then
						local wnd = Apollo.LoadForm(self.xmlDoc,"ListItem",self.wndStandings:FindChild("Standings"):FindChild("List"),self)
						wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
						wnd:FindChild("Stat1"):SetText(player.strName)
						wnd:FindChild("Stat2"):SetText(player.EP)
						wnd:FindChild("Stat3"):SetText(player.GP)
						wnd:FindChild("Stat4"):SetText(player.PR)
						if k == 1 or #tab == 1 or not added then wnd:FindChild("NewClass"):Show(true) end
						added = true
						
					end
				elseif self.tItems["EPGP"] then
					if self:string_starts(player.strName,self.searchString) then
						local wnd = Apollo.LoadForm(self.xmlDoc,"ListItem",self.wndStandings:FindChild("Standings"):FindChild("List"),self)
						wnd:FindChild("ClassIcon"):SetSprite(ktStringToIcon[player.class])
						wnd:FindChild("Stat1"):SetText(player.strName)
						wnd:FindChild("Stat2"):SetText(player.net)
						wnd:FindChild("Stat3"):SetText(player.tot)
						if k == 1 or #tab == 1 or not added then wnd:FindChild("NewClass"):Show(true) end
						added = true
					end
				end
			end
		end	
	end
	
	self.wndStandings:FindChild("Standings"):FindChild("List"):ArrangeChildrenVert(0)
	self:HighlightRow()
	self:CalculateLastFetch()
end

function RaidOpsMM:IsPlayerInRaid(strPlayer)
	local raid = self:Bid2GetTargetsTable()
	table.insert(raid,GameLib.GetPlayerUnit():GetName())
	for k,player in ipairs(raid) do
		if strPlayer == player then return true end
	end
	return false
end

function RaidOpsMM:CalculateLastFetch()
	local wndFetchDays = self.wndStandings:FindChild("Controls"):FindChild("FetchDaysSince")
	local wndFetchDate = self.wndStandings:FindChild("Controls"):FindChild("FetchDate")
	
	if self.settings.lastFetch == 0 then 
		wndFetchDays:SetText("--") 
		wndFetchDate:SetText("--")
		return
	end
	local diff = os.time() - self.settings.lastFetch
	local tDate = os.date("*t",diff)
	wndFetchDays:SetText("Last update : " .. tDate.day - 1 .. " days ago.") 
	wndFetchDate:SetText(os.date("%x",self.settings.lastFetch).."  " .. os.date("%X",self.settings.lastFetch))

end

function RaidOpsMM:LabelSwapSortIndicator(wnd)
	if wnd:GetData() == "asc" then 
		wnd:FindChild("SortIndicator"):SetSprite("CRB_PlayerPathSprites:sprPP_SciSpawnArrowDown")
		wnd:SetData("desc")
		self.settings.SortOrder = "desc"
	else
		wnd:FindChild("SortIndicator"):SetSprite("CRB_PlayerPathSprites:sprPP_SciSpawnArrowUp")
		wnd:SetData("asc")
		self.settings.SortOrder = "asc"
	end
end

function raidOpsMMsortPlayerswithWnds(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOpsMM")
	if DKPInstance and DKPInstance.SortedLabel then
		local label = "Stat"..DKPInstance.SortedLabel
		if a:FindChild(label) and b:FindChild(label) then
			if DKPInstance.settings.SortOrder == "asc" then
				if label ~= "Stat1" then
					return tonumber(a:FindChild(label):GetText()) > tonumber(b:FindChild(label):GetText())
				else
					return a:FindChild(label):GetText() > b:FindChild(label):GetText()
				end
			else
				if label ~= "Stat1" then
					return tonumber(a:FindChild(label):GetText()) < tonumber(b:FindChild(label):GetText())
				else
					return a:FindChild(label):GetText() < b:FindChild(label):GetText()
				end
			end
		end
	end
end

function raidOpsMMsortPlayers(a,b)
	local DKPInstance = Apollo.GetAddon("RaidOpsMM")
	if DKPInstance.SortedLabel then
		local label = "Stat"..DKPInstance.SortedLabel
		if DKPInstance.settings.SortOrder == "asc" then
			if label == "Stat1" then return a.strName > b.strName end
			if DKPInstance.epgpmode then
				if label == "Stat2" then return a.EP > b.EP end
				if label == "Stat3" then return a.GP > b.GP end
				if label == "Stat4" then return tonumber(a.PR) > tonumber(b.PR) end
			else
				if label == "Stat2" then return a.net > b.net end
				if label == "Stat3" then return a.tot > b.tot end
			end
		else
			if label == "Stat1" then return a.strName < b.strName end
			if DKPInstance.epgpmode then
				if label == "Stat2" then return a.EP < b.EP end
				if label == "Stat3" then return a.GP < b.GP end
				if label == "Stat4" then return tonumber(a.PR) < tonumber(b.PR) end
			else
				if label == "Stat2" then return a.net < b.net end
				if label == "Stat3" then return a.tot < b.tot end
			end
		end
	end
end

function RaidOpsMM:LabelSort(wndHandler,wndControl,eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right and string.find(wndControl:GetName(),"Label") then 
		self.SortedLabel = string.sub(wndControl:GetName(),6)
		self:LabelSwapSortIndicator(wndControl)
		if not self.wndStandings:FindChild("Controls"):FindChild("Group"):IsChecked() then
			self.wndStandings:FindChild("Standings"):FindChild("List"):ArrangeChildrenVert(0,raidOpsMMsortPlayerswithWnds)
			self:HighlightRow()
		else
			self:RefreshStandings()
		end
	else
		self.SortedLabel = nil
		self:RefreshStandings()
	end
	
	self:HideSortIndicators()
end

function RaidOpsMM:HideSortIndicators()
	self.wndStandings:FindChild("Standings"):FindChild("Label1"):FindChild("SortIndicator"):Show(false)
	self.wndStandings:FindChild("Standings"):FindChild("Label2"):FindChild("SortIndicator"):Show(false)
	self.wndStandings:FindChild("Standings"):FindChild("Label3"):FindChild("SortIndicator"):Show(false)
	self.wndStandings:FindChild("Standings"):FindChild("Label4"):FindChild("SortIndicator"):Show(false)
	
	if self.SortedLabel then self.wndStandings:FindChild("Standings"):FindChild("Label"..self.SortedLabel):FindChild("SortIndicator"):Show(true) end
end

function RaidOpsMM:StandingsShow()
	self.wndStandings:Show(true,false)
	self.wndStandings:ToFront()
	self:RefreshStandings()
end	

function RaidOpsMM:HighlightRow()
	for k,child in ipairs(self.wndStandings:FindChild("Standings"):FindChild("List"):GetChildren()) do
		for j=1,4 do
			child:FindChild("Stat"..j):SetTextColor("white")
		end
		if self.SortedLabel then child:FindChild("Stat"..self.SortedLabel):SetTextColor("ChannelAdvice") end
	end

end

---------------------------------------------------------------------------------------------------
-- StandingsMain Functions
---------------------------------------------------------------------------------------------------

function RaidOpsMM:Search( wndHandler, wndControl, strText )
	self.searchString = strText 
	self:RefreshStandings()
end

function RaidOpsMM:StandingsClose( wndHandler, wndControl, eMouseButton )
	self.wndStandings:Show(false,false)
end

---------------------------------------------------------------------------------------------------
-- ListItem Functions
---------------------------------------------------------------------------------------------------
local selectedItems = {}
function RaidOpsMM:SelectItem( wndHandler, wndControl)
	table.insert(selectedItems,wndControl:FindChild("Stat1"):GetText())
end

function RaidOpsMM:DeselectItem( wndHandler, wndControl, eMouseButton )
	for k,item in ipairs(selectedItems) do
		if item == wndControl:FindChild("Stat1"):GetText() then table.remove(selectedItems,k) return end
	end
end

function RaidOpsMM:RemoveSelected()
	for k,item in ipairs(selectedItems) do
		self.tItems[item] = nil 
	end
	self:RefreshStandings()
	selectedItems = {}
end

-----------------------------------------------------------------------------------------------
-- RaidOpsMM Instance
-----------------------------------------------------------------------------------------------
local RaidOpsMMInst = RaidOpsMM:new()
RaidOpsMMInst:Init()
