local PlayerDataClass = {}
PlayerDataClass.__index = PlayerDataClass

export type Transaction = {
	Time: number,
	Item: string,
	Amount: number,
	Cost: number
}

export type PlayerDataClassType = typeof(setmetatable({} :: {
	CaughtCheatingAttempts: number,
	IsBanned: boolean,
	TotalRobuxSpent: number,
	Transactions: {Transaction},
}, PlayerDataClass))

-- Init
function PlayerDataClass.Init(player: Player, DATA)
	local self = setmetatable({}, PlayerDataClass)

	self.Player = player

	self.CaughtCheatingAttempts = 0
	self.IsBanned = false

	self.TotalRobuxSpent = 0
	self.Transactions = {}

	return self
end

-- Cheating tracker
function PlayerDataClass:ReportCheating()
	self.CaughtCheatingAttempts += 1
	if self.CaughtCheatingAttempts >= 3 then -- Example threshold
		self.IsBanned = true
		return true
	end
	
	return false
end

function PlayerDataClass:ResetCheatingAttempts()
	self.CaughtCheatingAttempts = 0
end

function PlayerDataClass:UnbanPlayer()
	if self.IsBanned then
		self.IsBanned = false
	end
end

-- Transactions
function PlayerDataClass:AddTransaction(item: string, amount: number, cost: number)
	local transaction = {
		Time = os.time(),
		Item = item,
		Amount = amount,
		Cost = cost
	}

	table.insert(self.Transactions, transaction)
	self.TotalRobuxSpent += cost
end

function PlayerDataClass:ClearTransactions()
	self.Transactions = {}
	self.TotalRobuxSpent = 0
end

return PlayerDataClass
