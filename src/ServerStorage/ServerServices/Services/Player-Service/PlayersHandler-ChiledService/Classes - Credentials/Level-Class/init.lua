local LevelClass = {}
LevelClass.__index = LevelClass

export type LevelClassType = typeof(setmetatable({} :: {
	LevelNumber:number
}, LevelClass))


local Levels = require(script["LevelTable-Enum"])
local MUtilies = require(game.ReplicatedStorage.Utilities.ModuleUtils)
local MAX_LEVEL = 100
local DOUBLE_XP_DURATION = 1800 -- 30 minutes in seconds


function LevelClass.Init(player: Player, DATA)
	local self = setmetatable({}, LevelClass)
	
	self.Player = player
	
	self.LevelNumber = 0
	self.currentXpAmount = 0
	
	-- Checker if level not last level, and get next level xp required
	local nextLevelRequiredId
	if self.LevelNumber < MAX_LEVEL then
		nextLevelRequiredId = self.LevelNumber + 1
	else
		nextLevelRequiredId = 0
	end
	
	self.NextLevelXpRequired = Levels[nextLevelRequiredId]
	
	self.DoubleXp = false
	
	self.DoubleXpApplyedAmount = 0
	self.DoubleXpTimeLeft = 0
	
	self.Player:SetAttribute("Level", self.LevelNumber)
	self.Player:SetAttribute("CurentXP", self.currentXpAmount)
	self.Player:SetAttribute("NextLevelRequiredXP", self.NextLevelXpRequired)
	
	if self.DoubleXp then
		local TroveCleaner = MUtilies.Trove.new()
		self._DoubleXpCleaner = TroveCleaner -- store for later cleanup if needed

		local thread = task.spawn(function()
			while self.DoubleXp and self.DoubleXpTimeLeft > 0 do
				task.wait(1)
				self.DoubleXpTimeLeft -= 1
				self.Player:SetAttribute("DoubleXpTimeLeft", self.DoubleXpTimeLeft)

				if self.DoubleXpTimeLeft <= 0 then
					self.DoubleXpApplyedAmount -= 1

					if self.DoubleXpApplyedAmount > 0 then
						self.DoubleXpTimeLeft = DOUBLE_XP_DURATION
						self.Player:SetAttribute("DoubleXpHave", self.DoubleXpApplyedAmount)
						self.Player:SetAttribute("DoubleXpTimeLeft", self.DoubleXpTimeLeft)
					else
						self.DoubleXp = false
						self.DoubleXpTimeLeft = 0
						self.Player:SetAttribute("DoubleXp", self.DoubleXp)
						self.Player:SetAttribute("DoubleXpHave", self.DoubleXpApplyedAmount)
						self.Player:SetAttribute("DoubleXpTimeLeft", self.DoubleXpTimeLeft)

						-- clean task
						TroveCleaner:Clean()
						return
					end
				end
			end
		end)

		TroveCleaner:Add(thread)
	end

	return self
end

function LevelClass:AddXp(XpAmount: number)
	if self.NextLevelXpRequired == nil then return end -- already max level

	-- Add XP (apply double XP if enabled)
	self.currentXpAmount += self.DoubleXp and (XpAmount * 2) or XpAmount

	-- Check if level-up is possible
	if self.LevelNumber < MAX_LEVEL and self.currentXpAmount >= self.NextLevelXpRequired then
		self.LevelNumber += 1
		self.currentXpAmount -= self.NextLevelXpRequired

		if self.LevelNumber < MAX_LEVEL then
			self.NextLevelXpRequired = Levels[self.LevelNumber + 1]
		else
			self.NextLevelXpRequired = nil
			self.currentXpAmount = 0
		end
	end

	self.Player:SetAttribute("Level", self.LevelNumber)
	self.Player:SetAttribute("CurentXP", self.currentXpAmount)
	self.Player:SetAttribute("NextLevelRequiredXP", self.NextLevelXpRequired)
end

function LevelClass:AddDoubleXp()
	self.DoubleXpApplyedAmount += 1
	self.DoubleXpTimeLeft += DOUBLE_XP_DURATION
	
	if not self.DoubleXp then
		self.DoubleXp = true
	end
	
	self.Player:SetAttribute("DoubleXp", self.DoubleXp)
	self.Player:SetAttribute("DoubleXpHave", self.DoubleXpApplyedAmount)
	self.Player:SetAttribute("DoubleXpTimeLeft", self.DoubleXpTimeLeft)
end

function LevelClass:LevelUpAdmin(levelAmount: number)
	if self.LevelNumber >= MAX_LEVEL then return end

	-- Ramp the new level to not exceed MAX_LEVEL
	self.LevelNumber += levelAmount
	if self.LevelNumber > MAX_LEVEL then
		self.LevelNumber = MAX_LEVEL
	end

	self.CurentXpAmount = 0

	if self.LevelNumber < MAX_LEVEL then
		self.NextLevelXpRequired = Levels[self.LevelNumber + 1]
	else
		self.NextLevelXpRequired = nil
	end

	self.Player:SetAttribute("Level", self.LevelNumber)
	self.Player:SetAttribute("CurentXP", self.CurentXpAmount)
	self.Player:SetAttribute("NextLevelRequiredXP", self.NextLevelXpRequired)
end

return LevelClass
