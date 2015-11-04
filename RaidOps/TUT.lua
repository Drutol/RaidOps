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
		window = "None",
		anchor = 
		{
			[1] = "Mid",
			[2] = "Mid"
		},
		text = 
		{
			[1] = [===[
			Welcome! Thank you for checking out this addon!

			In order to get you accustomed with the basics I've created this tutorial.Addon is big enough to justify this :).

			First things first:

			1. I care about users so do not hesitate to create issues on github.You can find more info in settings window under "Support" button.
			2. This tutorial is not foolproof so don't play against the rules.
			3. You can progress by pressing blue arror pointing right ('J' is the hotkey for this button) , or taking certain actions.
			4. You can access tutorial index via settings window.

			Enjoy!
			]===],
			[2] = "In order to open main roster window type /epgp"
		},
		events = 
		{
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
			[8] = "OnlineOnly",
			[9] = "RaidOnly",
			[10] = "ShowDPS",
			[11] = "Undo",
			[12] = "ALButton",
			[13] = "ButtonLL",
			[14] = "ButtonCE",	
			[15] = "ToggleToolbar",
			[16] = "ShowRS",
			[17] = "CurrentlyListedAmount",


		},
		text = 
		{
			[1] = "\nThis is main window of the whole addon , here you will find buttons leading deeper.",
			[2] = "\nThis button here leads to settings window.",
			[3] = "\nThis section allows you to set-up columns (labels) , enable sorting , change profiles and add players to Raid Queue.\n\nIn order to set label right click on it and select what you want.\nLeft click will sort roster by selected label , click again to change order.",
			[4] = "\nThis button as well as button on the right change label profile - you can have 2 different sets of labels. \n\nBy default the first one is EPGP one and the sencond one shows attendance. \n\nProfiles are saved automatically as you change labels.",
			[5] = "\nBy enabling this checkbox you will be able to add players to Raid Queue.\n\nEach player's bar will have this checkbox which upon checking will add this player to queue .\n\nRaid queue makes addon include them into current raid members tables.",
			[6] = "\nForces display of player's whose names begin with typed phrase.",
			[7] = "\nSwitches to 'Mass Edit' mode . You will be provided with additional set of selection tools + some actions.\n\n Any modifications will apply to all selected players.",
			[8] = "\nPress this to show only online players in the roster window.",
			[9] = "\nPress this to show people in raid + Raid Queue",
			[10] = "\nThis and other two buttons on the right filter's display depending on player's set role. (DPS - HEAL - TANK)",
			[11] = "\nThis button will revert last action , let it be item award , EPGP manipulation , player removal , decay etc.",
			[12] = "\nLeads to window that will show list of all action you can undo/redo with details.",
			[14] = "\nOpens Custom Events window where you can specify how much EP/GP/DKP will be assigned on boss's or unit's death.",
			[13] = "\nOpen Loot Logs where you can extensively filter and review loot - whole roster.",
			[15] = "\nIf you wish to track attendance you have to start Raid Session , this toolbar may prove helpful.",
			[16] = "\nShows all saved Raid Sessions with ability to display only attendees or loot awarded during this session.",
			[17] = "\nThis counter displays count of all players currently displayed above.",

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
			[1] = "\nWelcome to the settings window.\n\nThese are the most basic settings affecting addon's behaviour in general.\n\n There are also buttons leading to smaller submodules.",
			[2] = "\nPlayer creation group , you can collect players from raid and filter them by nameplate affiliation.",
			[3] = "\nPopUp group , whenever you assign stuff this window may appear depending on filters and can be customized with those settings.",
			[4] = "\nDisplay group , a bit of cosmetic customization.",
			[5] = "\nLogs group , a few settings for Undo logs , standard logs and loot logs.",
			[6] = "\nLoot filtering, this is the main gate for items to be registred by addon.\n\n If item doesn't meet said requirements it's ignored by all modules.",
			[7] = "\nMiscalleanous settings which do not fit in other categories.",
			[8] = "\nLeads to EPGP settings where you can adjust GP formula , set decay options and specify minimum EP and base GP.\n\n If you want to use DKP the option for it is there.",
			[9] = "\nEnables Recent Activity log , which allows you to undo or redo actions.",
			[10] = "\nData sharing, you can share data with players who use Member Module addon.",
			[11] = "\nData sync, you can sync database with your raid assistants directly , instead of passing over import strings.",
			[12] = "\nAttendance, a few settigns concerning attendance tracking and raid sessions.",
			[13] = "\nGuild Import,place where you want to start . Allows to create roster based on guild's roster.",
			[14] = "\nStandby list , list of players who will be ommited during decay.",
			[15] = "\nExport and Import window , allows to create importable databases in text form and import them.\n\n You can also export data into CSV and HTML formats.",
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
			[2] = "Button",
		},
		text = 
		{
			[1] = "\nYou need to import some players first , select ranks and specify minimum level.\n\nIf you see checkboxes Rank1..10 press 'Get Data' button in the top left corner.",
			[2] = "\nNow press import.",
		},
		events =
		{
			[1] = "GIRankSelect",
			[2] = "GIImport",
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
			[5] = "ListItem",
			[6] = "Controls:EditBox1",
			[7] = "Controls:EditBox",
		},
		text = 
		{
			[1] = "\nNow all added players are visible here.",
			[2] = "\nThis section here allows you to manipulate EP/GP/DKP and enable grouping.",
			[3] = "\nWhenever you want to modify something you need to input comment (if enabled) , note that you can enable 'Generate Comments Automatically' in setting window to add generic coments.",
			[4] = "\nThis button allows you to group your players , the checkbox on this button allows to group in token groups.\n\n Enable gropuing (press it).",
			[5] = "\nNow players are groupped , let's add something to one of them!\n\n Click on player's bar.",
			[6] = "\nNow select EP or GP and type number in the 'Input value' box.",
			[7] = "\nNow write a comment if you want and press one of the buttons Add , Subtract or Set.",
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
			[7] = "Prof2",
		},
		text = 
		{
			[1] = "\nEach of this labels represent one column, by default this one is EP one.",
			[2] = "\nThis label here can store any data it is advised to use it for name property as it has the biggest field.",
			[3] = "\nLet's change this label to something else! Right click on it.",
			[4] = "\nSelect anything from this list , (Last item may fit here well)",
			[5] = "\nYou can left click on label in order to sort by this label, if grouping is enabled players will be sorted in groups, in order to change direction click again.\n\n Click it. ",
			[6] = "\nYou can have up to 9 labels , to show them grab the corner of the window and resize it.",
			[7] = "\nBy clicking on this , another set of labels will be loaded. Those sets are saved whenever you change label."
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
	},
	[7] = 
	{
		title = "Context menu",
		window = "Con",
		anchor = 
		{
			[1] = "Mid",
			[2] = "Mid",
		},
		text = 
		{
			[1] = "Before we get any further , let's take a look at context menu. Right click on any of players' bar.",
			[2] = "This widnow allows to perform user specific tasks.\n\n While they are self-explanatory I will return to alts later on.",
		},
		events = 
		{
			[1] = "ContextMenuOpen",
		},
		highlight = false,
		func = function(tContext)
			tContext.wndContext:Show(tContext.wndContext:GetData() and true or false)
			tContext.wndContext:ToFront()
		end
	},
	[8] = 
	{
		title = "Item assignment",
		window = "Main",
		anchor = 
		{
			[1] = "Right",
			[2] = "Right",
			[3] = "Right",
			[4] = "Right",
		},
		text = 
		{
			[1] = "\nWhenever you assign something you will be prompted to confirm assignment with GP/DKP value.",
			[2] = "\nLet's force this window to appear , we are going to use manual award. It works exactly in the same way as you would experience it during raid.",
			[3] = "\nRight click on player's entry.",
			[4] = "\nAnd now press 'Item Award' button.",
		},
		events = 
		{
			[3] = "ContextMenuOpen",
			[4] = "ManualAssignOpen",
		},
		highlight = false,
	},
	[9] = 
	{
		title = "Manual assign",
		window = "ManualAssign",
		anchor = 
		{
			[1] = "Right",
			[2] = "Button1",
			[3] = "Right",
		},
		text = 
		{
			[1] = "There's not much to this window alone , just type ID or select it from loot logs.",
			[2] = "This button will open Loot Logs window with Master Loot items that dropped during this session, you can click one of them to fill in the ID field.\n\n We don't have any items saved so it's empty now.",
			[3] = "Type some random item ID and proceed. (eg. 60417)",
		},
		events = 
		{
			[3] = "MAProceed",
		},
		highlight = true,
		bCantGOTO = true
	},
	[10] = 
	{
		title = "PopUp window",
		window = "PopUp",
		anchor = 
		{
			[1] = "Right",
			[2] = "Button",
			[3] = "QueueLength",
			[4] = "Right",
			[5] = "ButtonSkip",
			[6] = "GPOffspec",
			[7] = "Right",
		},
		text = 
		{
			[1] = "This is the window we wanted to get our hands on. Don't press accept just yet.",
			[2] = "This button will instantly award curent item to 'Guild bank'. It means that the log will appear in Guild Bank logs.",
			[3] = "This number shows how many items are in queue waiting to be assigned.",
			[4] = "Assign another item to different player via Manual Assign.\n\n Repeat steps from previous tutorial.\n 1.Right click on player entry\n2.Press 'Item award button'\n3.Fill in ID field and press proceed button.",
			[5] = "As you can see this button is now active. When you press it current item will be forgotten (no GP charged) and next item from queue loaded. Press this button.",
			[6] = "Look at this checkbox now.\n\n When pressed it will decrease the GP/DKP value by percentage set in settings window, by default it's set to 25%.",
			[7] = "When you are done simply press 'Accept'.\n\n Press Accept",

		},
		events = 
		{
			[4] = "MAProceed",
			[5] = "PopUpSkip",
			[7] = "PopUpAccepted",
		},
		highlight = true,
		bCantGOTO = true
	},
	[11] = 
	{
		title = "Loot Logs",
		window = "LL",
		anchor = 
		{
			[1] = "List",
			[2] = "Right",
			[3] = "Right",
			[4] = "More",
		},
		text = 
		{
			[1] = "In this window you will be able to review your loot. This module works on the 'bubble' concept , if you have added loot previously you shold see one in the highlighted container.",
			[2] = "Each bubble contains different set of items based on how you chose them to be groupped. (Day,category,recipient)",
			[3] = "Loot logs can operate in different scopes:\n1.Whole roster\n2.Selected players\n3.Single players\n4.Raid loot\n5.Master Loot entries",
			[4] = "This button leads to item filtering. Press it."
		},
		events = 
		{
			[4] = "LLMoreOpen",
		},
		func = function(tContext)
			tContext.wndLL:Show(true,false)
			tContext.wndLL:ToFront()
		end,
		highlight = true,
	},
	[12] = 
	{
		title = "Loot Logs - Filters and settings",
		window = "LLM",
		anchor = 
		{
			[1] = "Mid",
			[2] = "Only",
			[3] = "Settings",
			[4] = "SettingsMisc",
		},
		text = 
		{
			[1] = "You can extensively filter what you want to see.",
			[2] = "This section allows you to specify what item type and rarity you want to see. Minimum iLvl , GP cost and equippability.",
			[3] = "Here you can change tabs'(slot,class,quality) relations. If disabled it won't be taken to consideration , if its relation is 'OR' then item will be shown regardless of other tabs.",
			[4] = "Some sliders to customize bubbles.\nIn order to report item you need to right click on item tile in bubble and choose it from menu"
		},
		events = 
		{
		
		},
		func = function(tContext)
			tContext.wndLLM:Show(true,false)
			tContext.wndLLM:ToFront()
		end,
		highlight = true,
	},
	[13] = 
	{
		title = "Timed awards",
		window = "TA",
		anchor = 
		{
			[1] = "Mid",
			[2] = "Mid",
		},
		text = 
		{
			[1] = "This window allows you to schedule EP/GP/DKP awards.",
			[2] = "There's not much to it. Just input award value and timer interval (remember to press enter).When timer is running spinning circle will appear around button showind this window.",
		},
		events = 
		{
			
		},
		func = function(tContext)
			tContext.wndMain:Show(true,false)
			tContext.wndTimeAward:Show(true,false)
			tContext.wndMain:ToFront()
			tContext.wndMain:FindChild("ShowTimedAwards"):SetCheck(true)
		end,
		highlight = true,
	},
	[14] = 
	{
		title = "Custom Events",
		window = "CE",
		anchor = 
		{
			[1] = "Right",
			[2] = "MainFrame",
			[3] = "Right",
			[4] = "Right",
			[5] = "Grid",
			[6] = "Settings",
			[7] = "HandledEvents",
		},
		text = 
		{
			[1] = "This 'Custom Events' window enables you to specify rewards for raid members when boss or unit dies.",
			[2] = "In order to create event look at this window.",
			[3] = "You are creating this event simply by filling in the statement. Depending on what dies (unit/boss) you are presented with input box for unit's name , let it be miniboss or player or dropdown button with bosses in GA/DS.",
			[4] = "Create an event. If everything goes well message will appear.",
			[5] = "Great! When your newly created event triggers it will be listed here.",
			[6] = "Some settings for you to check out.",
			[7] = "If you want to check your events or remove them press this button.",
		},
		events = 
		{
			[4] = "CEEventCreated",	
		},
		func = function(tContext)
			tContext.wndCE:Show(true,false)
			tContext.wndCE:ToFront()
		end,
		highlight = true,
	}

}

-- Tutorial functions in general
local currTut
local addedHandlers = {}
function DKP:TutInit()

	self.wndTut = Apollo.LoadForm(self.xmlDoc3,"Tutorial",nil,self)
	self.wndTut:Show(false)

	if not self.tItems["settings"].nTutProgress then 
		self.tItems["settings"].nTutProgress = 1
		if not self.bPostPurge then
			self:TutStart()
		end
	end

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
	if not ktTutIndex[self.tItems["settings"].nTutProgress] then self.wndTut:Show(false) end
end

function DKP:TutBck()
	if currTut.events[currTut.nProgress] then Apollo.RemoveEventHandler(currTut.events[currTut.nProgress],self) end
	if currTut.wndGlow then currTut.wndGlow:Destroy() end
	self:TutStart(nil,currTut.nProgress-1)
end

function DKP:TutCanGoto(nTut)
	if nTut == 9 or nTut == 10 then return false else return true end
end

local function GetAbsolutePos(wnd)
	local x ,y = wnd:GetPos()
	while wnd:GetParent() do
		wnd = wnd:GetParent()
		local nx , ny = wnd:GetPos()
		x = x + nx
		y = y + ny
	end
	return x , y
end

function DKP:TutStart(nTut,nProgress)
	if not nTut then nTut = self.tItems["settings"].nTutProgress end
	if not nProgress then nProgress = 1 end
	currTut = ktTutIndex[nTut]
	if not ktTutIndex[nTut+1] and self:TutCanGoto(nTut+1) then self.wndTut:FindChild("Next"):Enable(false) else self.wndTut:FindChild("Next"):Enable(true) end
	if not ktTutIndex[nTut-1] and self:TutCanGoto(nTut-1) then self.wndTut:FindChild("Prev"):Enable(false) else self.wndTut:FindChild("Prev"):Enable(true) end
	if currTut then
		currTut.nProgress = nProgress
		-- Determine window
		if currTut.window == "Main" then currTut.wnd = self.wndMain 
		elseif currTut.window == "Settings" then currTut.wnd = self.wndSettings 
		elseif currTut.window == "GI" then currTut.wnd = self.wndGuildImport 
		elseif currTut.window == "ManualAssign" then currTut.wnd = self.wndMA 
		elseif currTut.window == "PopUp" then currTut.wnd = self.wndPopUp 
		elseif currTut.window == "Con" then currTut.wnd = self.wndContext  
		elseif currTut.window == "LL" then currTut.wnd = self.wndLL  
		elseif currTut.window == "TA" then currTut.wnd = self.wndMain  
		elseif currTut.window == "CE" then currTut.wnd = self.wndCE  
		elseif currTut.window == "LLM" then currTut.wnd = self.wndLLM  
		end
		-- Determine Pos
		if currTut.window == "None" then
			local x,y = Apollo.GetScreenSize()
			self.wndTut:Move( (x/2)-self.wndTut:GetWidth()/2, y/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
		else
			currTut.targetControl = currTut.wnd:FindChild(currTut.anchor[nProgress])
			if currTut.anchor[nProgress] == "Mid" then
				local x,y = currTut.wnd:GetAnchorOffsets()
				self.wndTut:Move( x + currTut.wnd:GetWidth()/2 - self.wndTut:GetWidth()/2,  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
			elseif currTut.anchor[nProgress] == "Right" then
				local x,y = currTut.wnd:GetAnchorOffsets()
				self.wndTut:Move( x + currTut.wnd:GetWidth(),  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
			else
				local x,y = GetAbsolutePos(currTut.targetControl)
				local yf = y - (self.wndTut:GetHeight() - currTut.targetControl:GetHeight())/2
				if self.wndTut:GetHeight() >= currTut.targetControl:GetHeight() then
					self.wndTut:Move( x + currTut.targetControl:GetWidth() ,  yf, self.wndTut:GetWidth(), self.wndTut:GetHeight())
				else
					self.wndTut:Move( x + currTut.targetControl:GetWidth() ,  yf , self.wndTut:GetWidth(), self.wndTut:GetHeight())
				end

				local fx , fy = self.wndTut:GetPos() -- check if is visible
				local mx,my = Apollo.GetScreenSize()
				if fx < 0 then
					fx = 0 
				end
				if fy < 0 then
					fy = 0
				end
				if fx + self.wndTut:GetWidth() > mx then
					fx = mx - self.wndTut:GetWidth()
				end
				if fy + self.wndTut:GetHeight() > my then
					fy = my - self.wndTut:GetHeight()
				end
				self.wndTut:Move(fx,fy, self.wndTut:GetWidth(),self.wndTut:GetHeight())
			end

		end
		-- Handlers

		if currTut.events[nProgress] then
			Apollo.RegisterEventHandler(currTut.events[nProgress],"TutFwd",self)
			self.wndTut:FindChild("Fwd"):Show(false)
		else
			self.wndTut:FindChild("Fwd"):Show(true)
		end

		if nProgress-1 >= 1 then
			self.wndTut:FindChild("Bck"):Show(true)
		else
			self.wndTut:FindChild("Bck"):Show(false)
		end

		--Set Text	
		
		self.wndTut:FindChild("TutTitle"):SetText(currTut.title)
		self.wndTut:FindChild("TutText"):SetText(currTut.text[nProgress])
		self.wndTut:FindChild("TutText"):SetVScrollInfo(self.wndTut:FindChild("TutText"):GetVScrollRange()*5,100,100)
	  	if currTut.highlight and currTut.targetControl then
			local wnd = Apollo.LoadForm(self.xmlDoc3,"TutGlow",currTut.targetControl,self)
			currTut.wndGlow = wnd
			wnd:SetOpacity(.5)
		end
		if currTut.func then currTut.func(self) end
		self.wndTut:Show(true)
		self.wndTut:ToFront()

	end
end



function DKP:TutFront()
	self.wndTut:ToFront()
end

function DKP:TutStop()
	self.wndTut:Show(false,false)
	if currTut and currTut.wndGlow then currTut.wndGlow:Destroy() end
end

function DKP:TutNextTut()
	if currTut and currTut.wndGlow then currTut.wndGlow:Destroy() end
	local bFound = false
	local counter = self.tItems["settings"].nTutProgress
	while not bFound do
		counter = counter + 1
		if not ktTutIndex[counter].bCantGOTO then bFound = true end

	end
	self.tItems["settings"].nTutProgress = counter

	self:TutStart()
end

function DKP:TutPrevTut()
	if currTut and currTut.wndGlow then currTut.wndGlow:Destroy() end
	local bFound = false
	local counter = self.tItems["settings"].nTutProgress
	while not bFound do
		counter = counter - 1
		if not ktTutIndex[counter].bCantGOTO then bFound = true end
	end
	self.tItems["settings"].nTutProgress = counter
	self:TutStart()
end

function DKP:TutListInit()
	self.wndTutList = Apollo.LoadForm(self.xmlDoc3,"TutList",nil,self)
	self.wndTutList:Show(false)
	
	for k , tut in ipairs(ktTutIndex) do
		if not tut.bCantGOTO then 
			self.wndTutList:FindChild("Grid"):AddRow(tut.title)
			self.wndTutList:FindChild("Grid"):SetCellText(k,1,tut.title)
		end
	end

	self.wndTutList:FindChild("Grid"):AddEventHandler("GridSelChange","TutListOpenTut",self)
end

function DKP:TutListShow()
	self.wndTutList:Show(true,false)
	self.wndTutList:ToFront()
end

function DKP:TutListHide()
	self.wndTutList:Show(false,false)
end

function DKP:TutListOpenTut(wndHandler,wndControl,iRow,iCol)
	local strTut = wndControl:GetCellText(iRow,iCol)
	for k , tut in ipairs(ktTutIndex) do
		if tut.title == strTut then self.tItems["settings"].nTutProgress = k break end
	end
	
	self:TutStart()
	self.wndTutList:Show(false,false)
end