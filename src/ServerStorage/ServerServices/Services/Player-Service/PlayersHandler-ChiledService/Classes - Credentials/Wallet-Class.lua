local WalletClass = {}
WalletClass.__index = WalletClass

export type WalletClassType = typeof(setmetatable({} :: {
	RocksAmount :number,
	LuminiteAmount :number
}, WalletClass))

local MAX_ROCKS = math.huge
local MAX_LUMINITE = 10000
local MIN_ROCKS = -100 -- allow debt down to -100 only

function WalletClass.Init(player: Player, DATA)
	local self = setmetatable({}, WalletClass)

	self.Player = player

	self.RocksAmount = DATA.Wallet.RocksAmount or 0 -- default game currency
	self.LuminiteAmount = DATA.Wallet.LuminiteAmount or 0 -- rare currency

	player:SetAttribute("RocksAmount", self.RocksAmount)
	player:SetAttribute("LuminiteAmount", self.LuminiteAmount)

	return self
end

-- Add Rocks
function WalletClass:AddRocks(amount: number)
	self.RocksAmount += math.abs(amount)
	self.RocksAmount = math.min(self.RocksAmount, MAX_ROCKS)
	self.Player:SetAttribute("RocksAmount", self.RocksAmount)
end

-- Deduct Rocks (allow -100 limit)
function WalletClass:DeductRocks(amount: number)
	self.RocksAmount -= math.abs(amount)
	self.RocksAmount = math.max(self.RocksAmount, MIN_ROCKS)
	self.Player:SetAttribute("RocksAmount", self.RocksAmount)
end

-- Add Luminite (clamped to max 10,000)
function WalletClass:AddLuminite(amount: number)
	self.LuminiteAmount += math.abs(amount)
	self.LuminiteAmount = math.min(self.LuminiteAmount, MAX_LUMINITE)
	self.Player:SetAttribute("LuminiteAmount", self.LuminiteAmount)
end

-- Deduct Luminite (can't go below 0)
function WalletClass:DeductLuminite(amount: number)
	self.LuminiteAmount -= math.abs(amount)
	self.LuminiteAmount = math.max(self.LuminiteAmount, 0)
	self.Player:SetAttribute("LuminiteAmount", self.LuminiteAmount)
end

-- Admin: Max out both currencies
function WalletClass:AdminSetMaxValues()
	self.RocksAmount = MAX_ROCKS
	self.LuminiteAmount = MAX_LUMINITE
	self.Player:SetAttribute("RocksAmount", self.RocksAmount)
	self.Player:SetAttribute("LuminiteAmount", self.LuminiteAmount)
end

-- Admin: Reset all currencies to 0
function WalletClass:AdminClearAll()
	self.RocksAmount = 0
	self.LuminiteAmount = 0
	self.Player:SetAttribute("RocksAmount", self.RocksAmount)
	self.Player:SetAttribute("LuminiteAmount", self.LuminiteAmount)
end

return WalletClass