--!strict
--[[
	Types that can be utilized across any module for consistency and maintaining types in a single location.
]]

export type UniversalTimestamp = {
	Year: number,
	Month: number,
	Day: number,
	Hour: number,
	Minute: number,
	Second: number,
	Millisecond: number,
}

export type PlayerJoinData = {
	SourceGameId: number?,
	SourcePlaceId: number?,
	ReferredByPlayerId: number?,
	Members: { number }?, -- Players teleported alongside this player.
	TeleportData: any, -- teleportData specified in original teleport.
	LaunchData: string, -- Plain or JSON econded string containing launch data
	GameJoinContext: {
		JoinSource: Enum.JoinSource,
		ItemType: Enum.AvatarItemType?,
		AssetId: string?,
		OutfitId: string?,
		AssetType: Enum.AssetType?
	}
}

return {}