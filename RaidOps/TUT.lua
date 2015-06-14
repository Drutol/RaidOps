-----------------------------------------------------------------------------------------------
-- Client Lua Script for RaidOps
-- Copyright (c) Piotr Szymczak 2015 	dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------

local DKP = Apollo.GetAddon("RaidOps")

local ktTutIndex = 
{
	[1] = 
	{
		title = "Welcome to RaidOps",
		window = "Main",
		anchor = 
		{
			[1] = "Mid",
			[2] = "Mid",
		},
		text = 
		{
			[1] = "Thanks for trying out this addon!\n\nAs it's quite rich in features this tutorial will help you understand the basics.\n\nClosing this window will stop the tutorial , you can get back to it from settings window.",
			[2] = "In order to open main roster window type /epgp",
		},
		events = 
		{
			[1] = nil,
			[2] = "MainWindowShow",
		},
		highlight = false,
	},
	[2]	=
	{
		title = "Overview",
		window = "Main",
		anchor = 
		{
			[1] = "Mid",
			[2] = "ButtonShowSettings",
			[3] = "LabelBar",
			[4] = "Prof1",
			[5] = "RaidQueue",
			[6] = "EditBox1",
			[7] = "MassEdit",
			[8] = "ShowDPS",
			[9] = "Undo",
			[10] = "ALButton",
			[11] = "ButtonGBL",
			[12] = "ButtonCE",
			[13] = "ButtonLL",
			[14] = "ToggleToolbar",
			[15] = "ShowRS",
			[16] = "CurrentlyListedAmount",
			[17] = "OnlineOnly",
			[18] = "RaidOnly",

		},
		text = 
		{
			[1] = "\nThis is main window of the whole addon , here you will find buttons leading deeper.",
			[2] = "\nThis button here leads to settings window. Particular controls are highlighted with white glow.",
			[3] = "\nThis section allows you to set-up columns (labels) , enable sorting , change profiles and add players to Raid Queue.\n\nIn order to set label right click on it and select what you want.\nLeft click will sort roster by selected label , click again to change order.",
			[4] = "\nThis button and button on the right change label profile - you can have 2 different sets of labels. \n\nBy default the first one is EPGP one and the sencond one shows attendance. \n\nProfiles are saved automatically as you change labels.",
			[5] = "\nBy enabling this checkbox you will be able to add players to Raid Queue.\nEach player's bar will have this checkbox which upon checking will add this player to queue .\nRaid queue allows you to fool the addon that those players are in raid too.",
			[6] = "\nForces display of player's whose names begin with typed phrase.",
			[7] = "\nSwitches to 'Mass Edit' mode . You will be provided with additional set of selection tools + some actions. Any modifications will apply to all selected players.",
			[8] = "\nThis and other two buttons on the right filter's display depending on player's set role. (DPS - HEAL - TANK)",
			[9] = "\nThis button will revert last action , let it be item award , EPGP manipulation , player removal...",
			[10] = "\nLeads to window that will show list of all action you can undo/redo with details.",
			[11] = "\nOpens Guild Bank logs - they are added when you assign something to guild bank in Master Loot window.",
			[12] = "\nOpens Custom Events window where you can specify how much EP/GP/DKP will be assigned on boss's or unit's death.",
			[13] = "\nOpen Loot Logs where you can extensively filter and review loot - whole roster.",
			[14] = "\nIf you wish to track attendance you have to start Raid Session , this toolbar may prove helpful.",
			[15] = "\nShows all saved Raid Sessions with ability to display only attendees or loot awarded during this session.",
			[16] = "\nThis counter displays count of all players currently displayed above.",
			[17] = "\nPress this to show only online players in the roster window.",
			[18] = "\nPress this to show people in raid + Raid Queue",
		},
		events = 
		{

		},
		highlight = true,
	},
	[3] = 
	{
		title = "Settings Overview",
		window = "Settings",
		anchor = 
		{
			[1] = "Mid",
			[2] = "CatCreat",
			[3] = "CatPopUp",
			[4] = "CatDisp",
			[5] = "CatLogs",
			[6] = "CatLoot",
			[7] = "CatMisc",
			[8] = "ButtonSettingsEPGP",
			[9] = "TrackUndo",
			[10] = "ButtonShowLoot",
			[11] = "ButtonSettingsDataFetch",
			[12] = "ButtonSettingsDataFetch1",
			[13] = "ButtonShowLoot1",
			[14] = "ButtonShowStandby",
			[15] = "ButtonSettingsExport",
			[16] = "RaidInv",
		},
		text = 
		{
			[1] = "\nWelcome to the settings window.Those don't represent all of the settings available each module has it's own specific settings.\n\nGeneral settings are split into following groups:",
			[2] = "\nPlayer creation group , you can collect players from raid and filter them by nameplate affilition. Right now I advize to use Guild Import",
			[3] = "\nPopUp group , whenever you assign stuff this window may appear depending on filters and can be customized with those settings.",
			[4] = "\nDisplay group , a bit of cosmetic customization.",
			[5] = "\nLogs group , a few settings for Undo logs , standard logs and loot logs.",
			[6] = "\nLoot filtering, this is the main gate for loot to be registred in addon , if they do not meet those filter they are ignored.",
			[7] = "\nMiscalleanous settings which do not fit in other categories.",
			[8] = "\nLeads to EPGP settings where you can adjust GP formula , set decay options and specify minimum EP and base GP.\n\n If you want to use DKP the option for it is there.",
			[9] = "\nEnables Undo tracking , if logs are not appearing this may be the issue.",
			[10] = "\nData sharing, you can share data with players who use member module.",
			[11] = "\nData sync, you can sync database with your raid assistants directly , instead of passing over import strings.",
			[12] = "\nAttendance, a few settigns concerning attendance tracking and raid sessions.",
			[13] = "\nGuild Import,place where you want to start . Allows to create roster based on guild's roster.",
			[14] = "\nStandby list , list of players who will be ommited during decay.",
			[15] = "\nExport (and Import), you have a few options to export data with two importable formats - JSON for raidops.net  and Base64 encoded string only for addon.",
			[16] = "\nRaid invites , this module allow you to specify command that when written in guild channel or whispered to you will invite sender to raid.",
		},
		events = 
		{

		},
		highlight = true,
		func = function (tContext)
			tContext.wndSettings:Show(true,false)
			tContext.wndSettings:ToFront()
		end
	},
	[4] = 
	{
		title = "First steps",
		window = "GI",
		anchor = 
		{
			[1] = "Right",
			[2] = "Button1",
			[3] = "Button",
		},
		text = 
		{
			[1] = "\nYou need to import some players first , select ranks and specify minimum level .",
			[2] = "\nThis button will refresh guild roster's data.",
			[3] = "\nNow press import",
		},
		events =
		{
			[1] = "GIRankSelect",
			[2] = nil,
			[3] = "GIImport",
		},
		highlight = true,
		func = function(tContext)
			tContext.wndGuildImport:Show(true,false)
			tContext.wndGuildImport:ToFront()
		end
	},
	[5] =
	{
		title = "Modifications",
		window = "Main",
		anchor = 
		{
			[1] = "ItemList",
			[2] = "Controls",
			[3] = "Controls:EditBox",
			[4] = "GroupByClass",
			[5] = "Mid",
			[6] = "Controls:EditBox1",
			[7] = "Controls:EditBox",
		},
		text = 
		{
			[1] = "\nNow all added players are visible here.",
			[2] = "\nThis section here allows you to manipulate EP/GP/DKP and enable grouping.",
			[3] = "\nWhenever you want to modify something you need to input comment (if enabled) , note that you can enable 'Generate Comments Automatically' in setting window to add generic coments.",
			[4] = "\nThis button allows you to group your players , the checkbox on this button allows to group in token groups. Enable gropuing.",
			[5] = "\nNow players are groupped , let's add something to one of them! Click on player bar.",
			[6] = "\nNow select EP/GP and type something in the 'Input value' box.",
			[7] = "\nNow write a comment and press one of the buttons (Add/Sub/Set) below.",
		},
		events = 
		{
			[4] = "GroupByClassEnabled",
			[5] = "PlayerEntrySelected",
			[6] = "TypedInputValue",
			[7] = "ModifiedSomething",
		},
		highlight = true,
		func = function(tContext)
			tContext.wndMain:Show(true,false)
			tContext.wndMain:ToFront()
		end
	},
	[6] =
	{
		title = "Labels",
		window = "Main",
		anchor = 
		{
			[1] = "Label2",
			[2] = "Label1",
			[3] = "Label5",
			[4] = "Right",
			[5] = "Label1",
			[6] = "ResizeHandle",
		},
		text = 
		{
			[1] = "\nEach of this labels represent one column by default this one is EP one.",
			[2] = "\nThis label here while can store any data it is advised to use it for name property as it's the biggest one.",
			[3] = "\nLet's change this label to something else! Right click on it.",
			[4] = "\nSelect anything from this list , (Last item may fit here well)",
			[5] = "\nYou can left click on label in order to sort by this label, if grouping is enabled players will be sorted in groups , in order to change direction click again. Click it. ",
			[6] = "\nYou can have up to 9 labels , to show them grab the corner of the window and resize it.",
		},
		events = 
		{
			[3] = "LabelSelectionOpen",
			[4] = "LabelChanged",
			[5] = "LabelSorted",
			[6] = "MresResized",
		},
		highlight = true,
		func = function(tContext)
			tContext.wndMain:Show(true,false)
			tContext.wndMain:ToFront()
		end
	}


}

-- Tutorial functions in general
local currTut
local addedHandlers = {}
function DKP:TutInit()
	self.wndTut = Apollo.LoadForm(self.xmlDoc3,"Tutorial",nil,self)
	self.wndTut:Show(false)

	if not self.tItems["settings"].nTutProgress then 
		
		
	end
	self.tItems["settings"].nTutProgress = 6
	self:TutStart()
end

function DKP:TutFwd()
	if currTut.events[currTut.nProgress] then Apollo.RemoveEventHandler(currTut.events[currTut.nProgress],self) end
	if currTut.wndGlow then currTut.wndGlow:Destroy() end
	if currTut.nProgress == #currTut.text then
		self.tItems["settings"].nTutProgress = self.tItems["settings"].nTutProgress + 1
		self:TutStart()
	else
		self:TutStart(nil,currTut.nProgress+1)
	end
end

function DKP:TutBck()
	if currTut.wndGlow then currTut.wndGlow:Destroy() end
	self:TutStart(nil,currTut.nProgress-1)
end

function DKP:TutClose()

end

function DKP:TutStart(nTut,nProgress)
	if not nTut then nTut = self.tItems["settings"].nTutProgress end
	if not nProgress then nProgress = 1 end
	currTut = ktTutIndex[nTut]
	Print(nTut)
	if currTut then
		currTut.nProgress = nProgress
		-- Determine window
		if currTut.window == "Main" then currTut.wnd = self.wndMain 
		elseif currTut.window == "Settings" then currTut.wnd = self.wndSettings 
		elseif currTut.window == "GI" then currTut.wnd = self.wndGuildImport 
		end
		-- Determine Pos
		if currTut.anchor[nProgress] == "Mid" then
			local x,y = currTut.wnd:GetPos()
			self.wndTut:Move( x + currTut.wnd:GetWidth()/2 - self.wndTut:GetWidth()/2,  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
		elseif currTut.anchor[nProgress] == "Right" then
			local x,y = currTut.wnd:GetPos()
			self.wndTut:Move( x + currTut.wnd:GetWidth(),  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
		else
			currTut.targetControl = currTut.wnd:FindChild(currTut.anchor[nProgress])
			if currTut.window == "Settings" or currTut.window == "GI" then
				local x,y = currTut.wnd:GetPos()
				self.wndTut:Move( x + currTut.wnd:GetWidth(),  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
			else
				local x,y = currTut.wnd:GetPos()
				self.wndTut:Move( x + currTut.wnd:GetWidth()/2 - self.wndTut:GetWidth()/2,  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
			end
		end
		-- Handlers

		if currTut.events[nProgress] then
			Apollo.RegisterEventHandler(currTut.events[nProgress],"TutFwd",self)
			self.wndTut:FindChild("Fwd"):Show(false)
		else
			self.wndTut:FindChild("Fwd"):Show(true)
		end
		--Set Text	
		self.wndTut:FindChild("TutText"):SetText(currTut.text[nProgress])
		self.wndTut:FindChild("TutTitle"):SetText(currTut.title)
		--[[if currTut.nProgress < #currTut.text or currTut.continue == "Fwd" or not currTut.events[currTut.nProgress] then self.wndTut:FindChild("Fwd"):Show(true) else self.wndTut:FindChild("Fwd"):Show(false) end
		if currTut.nProgress > 1 and #currTut.text >= currTut.nProgress then self.wndTut:FindChild("Bck"):Show(true) else self.wndTut:FindChild("Bck"):Show(false) end

		-- Handlers
		if currTut.continue == "Click" and currTut.targetControl then
			if not currTut.highlight then currTut.targetControl:AddEventHandler("MouseButtonDown","TutProceedClick",self) end
		elseif currTut.continue == "actionShow" then
			currTut.wnd:AddEventHandler("WindowShow","TutProceedShow",self)
		end]]
	  	if currTut.highlight and currTut.targetControl then
			local wnd = Apollo.LoadForm(self.xmlDoc3,"TutGlow",currTut.targetControl,self)
			currTut.wndGlow = wnd
		end
		if currTut.func then currTut.func(self) end
		self.wndTut:Show(true)
		self.wndTut:ToFront()
	end
end

function DKP:TutProceedClick(wndHandler,wndControl)
	if currTut.continue ~= "Click" or currTut.nProgress ~= #currTut.text then return end
	if wndHandler ~= wndControl then return end
	local glow = wndControl:FindChild("TutGlow")
	if glow then glow:Destroy() end

	self.tItems["settings"].nTutProgress = self.tItems["settings"].nTutProgress + 1
	self:TutStart()
end

function DKP:TutProceedShow(wndHandler,wndControl)
	if currTut.continue ~= "actionShow" or currTut.nProgress ~= #currTut.text then return end
	
	wndHandler:RemoveEventHandler("WindowShow",self)
	
	self.tItems["settings"].nTutProgress = self.tItems["settings"].nTutProgress + 1
	self:TutStart()
end

function DKP:TutFront()
	self.wndTut:ToFront()
end