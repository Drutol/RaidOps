-----------------------------------------------------------------------------------------------
-- Client Lua Script for EasyDKP
-- Copyright (c) Piotr Szymczak 2014	 dogier140@poczta.fm.
-----------------------------------------------------------------------------------------------


local DKP = Apollo.GetAddon("EasyDKP")

function DKP:RaidOpsInit()
	self:AttendanceInit()
	self:HubInit()
end

function DKP:HubInit()
	self.wndHub = Apollo.LoadForm(self.xmlDoc2,"RaidOpsHub",nil,self)

end

function DKP:HubPopulateInfo()
	-- TopDKP
		
	--Classes
	
	--Item news
	
end

function compare_easyDKPRaidOps(a,b)
  return a > b
end

function DKP:GetDataSet(plot)
	if plot == "Classes" then
		local stats = {}
		stats.engi = 0
		stats.esp = 0
		stats.med = 0
		stats.war = 0
		stats.stal = 0
		stats.spel = 0
		for i=0,table.maxn(self.tItems) do
			if self.tItems[i] ~= nil then
				if self.tItems[i].class ~= nil then
					if self.tItems[i].class == "Esper" then
						stats.esp = stats.esp + 1
					elseif self.tItems[i].class == "Engineer" then
						stats.engi = stats.engi + 1
					elseif self.tItems[i].class == "Medic" then
						stats.med = stats.med + 1
					elseif self.tItems[i].class == "Warrior" then
						stats.war = stats.war + 1
					elseif self.tItems[i].class == "Stalker" then
						stats.stal = stats.stal + 1
					elseif self.tItems[i].class == "Spellslinger" then
						stats.spel = stats.spel + 1
					end
				end
			end
		end
		table.sort(stats,compare_easyDKPRaidOps)
		return stats
	elseif plot == "Top3" then
		return {100,200,300}
	end
end

function DKP:AttendanceInit()
	self.wndAttendance = Apollo.LoadForm(self.xmlDoc2,"AttendanceGrid",nil,self)
	self:AttendancePopulate()
end

function DKP:AttendanceShow()

end

function DKP:AttendancePopulate()
	local grid = self.wndAttendance:FindChild("Grid")
	grid:SetColumnText(7,"LOL")
	
	for i=0,table.maxn(self.tItems) do -- Adding rows
		if self.tItems[i] ~= nil then
			grid:AddRow(self.tItems[i].strName)
		end
	end
	local skippedIDs = 0
	for k=0,table.maxn(self.tItems["Raids"]) do -- adding cell data
		if self.tItems["Raids"][k] ~= nil then
			grid:SetColumnText(k+1,self.tItems["Raids"][k].date.strDate)
			for i=0,table.maxn(self.tItems) do 
				if self.tItems[i] ~= nil then
					for j=1,#self.tItems["Raids"][k].tPlayers do
						if string.lower(self.tItems[i].strName) == string.lower(self.tItems["Raids"][k].tPlayers[j].name) then
							if self.tItems["Raids"][k].tPlayers[j].bLeft == "Left" then
								grid:SetCellData(i+1-skippedIDs, k+1,"","ClientSprites:LootCloseBox_Holo","f")
							else
								grid:SetCellData(i+1-skippedIDs, k+1,"","achievements:sprAchievements_Icon_Complete","t")
							end
							break
						elseif j == #self.tItems["Raids"][k].tPlayers then 
							grid:SetCellData(i+1-skippedIDs, k+1,"","ClientSprites:LootCloseBox_Holo","f")
							grid:SetCellImageColor(i+1-skippedIDs, k+1,"xkcdApple") 
						end
					end
				else
					skippedIDs = skippedIDs + 1
				end
			end
			skippedIDs = 0
		end
	end

end