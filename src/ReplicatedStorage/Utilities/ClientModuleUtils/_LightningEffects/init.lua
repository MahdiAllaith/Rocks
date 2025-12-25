--!strict

local LightningBolt = require(script._LightningBolt)
local LightningExplosion = require(script._LightningExplosion)
local LightningSparks = require(script._LightningSparks)

export type LightningBolt = LightningBolt.LightningBolt
export type LightningExplosion = LightningExplosion.LightningExplosion
export type LightningSparks = LightningSparks.LightningSparks

return {
	LightningBolt = LightningBolt,
	LightningExplosion = LightningExplosion,
	LightningSparks = LightningSparks
}