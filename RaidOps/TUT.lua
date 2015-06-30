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
			[3] = "Mid"
		},
		text = 
		{
			[1] = "Thanks for trying out this addon!\n\nAs it's quite rich in features this tutorial will help you understand the basics.\n\nClosing this window will stop the tutorial , you can get back to it from settings window.",
			[2] = "Please note that these tutorials are not fool-proof .\nThat's not the point , try not to rush things and follow them.\n\nIf something goes wrong you can always restart them :).",
			[3] = "In order to open main roster window type /epgp"
		},
		events = 
		{
			[3] = "MainWindowShow",
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
			[1] = "\nWelcome to the settings window.Those don't represent all of the settings available , each module has it's own specific settings.\n\nGeneral settings are split into following groups:",
			[2] = "\nPlayer creation group , you can collect players from raid and filter them by nameplate affiliation. Right now I advise to use Guild Import",
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
			[7] = "Prof2",
		},
		text = 
		{
			[1] = "\nEach of this labels represent one column by default this one is EP one.",
			[2] = "\nThis label here while can store any data it is advised to use it for name property as it's the biggest one.",
			[3] = "\nLet's change this label to something else! Right click on it.",
			[4] = "\nSelect anything from this list , (Last item may fit here well)",
			[5] = "\nYou can left click on label in order to sort by this label, if grouping is enabled players will be sorted in groups , in order to change direction click again. Click it. ",
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
			[1] = "There's not much to this window alone , just type ID or select it from loot logs and continue.",
			[2] = "This button will open Loot Logs window with items dropped in this session , find the one you want and just click it.",
			[3] = "Type some random item ID and proceed. (eg. 39876)",
		},
		events = 
		{
			[3] = "MAProceed",
		},
		highlight = true,
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
			[7] = "GPOffspec",
			[8] = "Right",
		},
		text = 
		{
			[1] = "This is the window we wanted to get our hands on. As you can see you can just press 'Accept' and GP will be added to this player.",
			[2] = "This button will instantly award curent item to 'Guild bank'. It means that the log will appear in GB logs.",
			[3] = "This number shows how many items are in queue waiting to be assigned.",
			[4] = "Assign another item to different player via Manual Assign.",
			[5] = "As you can see this button is now active. When you press it this item will be forgotten - no GP charged. Press this button.",
			[6] = "The window has updated itself with new data. Look at this checkbox now.",
			[7] = "When pressed it will decrease the GP/DKP value by percentage set in settings window.",
			[8] = "When you are done simply press 'Accept'.",

		},
		events = 
		{
			[4] = "MAProceed",
			[5] = "PopUpSkip",
			[8] = "PopUpAccepted",
		},
		highlight = true,
	},

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
		end
		-- Determine Pos
		if currTut.anchor[nProgress] == "Mid" then
			local x,y = currTut.wnd:GetAnchorOffsets()
			self.wndTut:Move( x + currTut.wnd:GetWidth()/2 - self.wndTut:GetWidth()/2,  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
		elseif currTut.anchor[nProgress] == "Right" then
			local x,y = currTut.wnd:GetAnchorOffsets()
			self.wndTut:Move( x + currTut.wnd:GetWidth(),  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
		else
			currTut.targetControl = currTut.wnd:FindChild(currTut.anchor[nProgress])
			if currTut.window == "Settings" or currTut.window == "GI" or currTut.window == "PopUp" or currTut.window == "ManualAssign" or currTut.window == "Con" then
				local x,y = currTut.wnd:GetAnchorOffsets()
				self.wndTut:Move( x + currTut.wnd:GetWidth(),  y + currTut.wnd:GetHeight()/2 - self.wndTut:GetHeight()/2, self.wndTut:GetWidth(), self.wndTut:GetHeight())
			else
				local x,y = currTut.wnd:GetAnchorOffsets()
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

		if nProgress-1 >= 1 then
			self.wndTut:FindChild("Bck"):Show(true)
		else
			self.wndTut:FindChild("Bck"):Show(false)
		end

		--Set Text	
		self.wndTut:FindChild("TutText"):SetText(currTut.text[nProgress])
		self.wndTut:FindChild("TutTitle"):SetText(currTut.title)
	  	if currTut.highlight and currTut.targetControl then
			local wnd = Apollo.LoadForm(self.xmlDoc3,"TutGlow",currTut.targetControl,self)
			currTut.wndGlow = wnd
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
	self.tItems["settings"].nTutProgress = self.tItems["settings"].nTutProgress + 1

	self:TutStart()
end

function DKP:TutPrevTut()
	if currTut and currTut.wndGlow then currTut.wndGlow:Destroy() end
	self.tItems["settings"].nTutProgress = self.tItems["settings"].nTutProgress - 1
	self:TutStart()
end

function DKP:TutListInit()
	self.wndTutList = Apollo.LoadForm(self.xmlDoc3,"TutList",nil,self)
	self.wndTutList:Show(false)
	
	for k , tut in ipairs(ktTutIndex) do
		if k ~= 9 and k ~= 10 then 
			self.wndTutList:FindChild("Grid"):AddRow(k..".")
			self.wndTutList:FindChild("Grid"):SetCellData(k,1,tut.title)
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

function DKP:TutListOpenTut(wndHandler,wndCotrol,iRow,iCol)
	self.tItems["settings"].nTutProgress = iRow
	self:TutStart()
	self.wndTutList:Show(false,false)
end