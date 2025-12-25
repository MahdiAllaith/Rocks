--!strict
local GlobalTypes = require("./GlobalTypes")

local _Screen3D = require(script._Screen3D)

local _Promise = require(script._Promise)
local _Scheduler = require(script._Scheduler)
local _Signal = require(script._Signal)
local _Trove = require(script._Trove)
local _Octree = require(script._Octree)
local _Timer = require(script._Timer)
local _Shake = require(script._Shake)
local _FastCastRedux = require(script._FastCastRedux)
local _PartCache = require(script._PartCache)
local _Cache = require(script._Cache)
local _Spring = require(script._Spring)
local _SpringUtils = require(script._SpringUtils)
local _DuckTypeUtils = require(script._DuckTypeUtils)
local _Proxy = require(script._Proxy)
local _Binder = require(script._Binder)
local _Logger = require(script._Logger)
local _Quaternion = require(script._Quaternion)
local _QuaternionSpring = require(script._QuaternionSpring)
local _TypedBindable = require(script._TypedBindable)
local _TypedRemote = require(script._TypedRemote)
local _AdjustmentPool = require(script._AdjustmentPool)
local _PredicateManager = require(script._PredicateManager)
local _TimeKeeper = require(script._TimeKeeper)
local _CallbackManager = require(script._CallbackManager)
local _CollisionParticles = require(script._CollisionParticles)
local _Pathfinder = require(script._Pathfinder)
local _Batcher = require(script._Batcher)
local _Bezier = require(script._Bezier)
local _DataCatalog = require(script._DataCatalog)
local _RandomRotator = require(script._RandomRotator)
local _Respawner = require(script._Respawner)
local _Packet = require(script._Packet)
export type Packet<A... = (), B... = ()> = _Packet.Packet<A..., B...>

local _Lottery = require(script._Lottery)
export type Lottery = _Lottery.Lottery
export type LotteryTicket = _Lottery.LotteryTicket

local _Zone = require(script._Zone)
export type LessSimpleZone<U, T...> = _Zone.LessSimpleZone<U, T...>
export type Zone = _Zone.Zone

export type ZoneQueryOptions = _Zone.QueryOptions
export type ZoneBox = _Zone.Box


local _Future = require(script._Future) -- replacement for promises
export type Future<T...> = _Future.Future<T...>

local _RateLimiter = require(script._RateLimiter)
export type RateLimiter = _RateLimiter.RateLimiter

export type PromiseAny = _Promise.PromiseAny
export type Promise<T...> = _Promise.Promise<T...>

export type SchedulerType = _Scheduler.SchedulerType

-- Func is the function passed to :Once() or :Connect(). ReturnVals is the data returned from :Wait() or passed to :Fire()
-- The args in Func should match ReturnVals!
export type SignalType<Func, ReturnVals...> = _Signal.SignalType<Func, ReturnVals...>
-- If you don't want to bother defining argument names:
export type Signal<ReturnVals...> = _Signal.Signal<ReturnVals...>
export type GenericSignal = _Signal.GenericSignal
export type SignalConnection = _Signal.SignalConnection

export type TroveType = _Trove.TroveType

export type OctreeType = _Octree.OctreeType
export type OctreeNodeType = _Octree.OctreeNodeType

export type TimerType = _Timer.TimerType

export type ShakeType = _Shake.ShakeType
export type ShakeProperties = _Shake.ShakeProperties

export type PartCache = _PartCache.PartCache

export type CacheType = _Cache.CacheType

type nlerpable = _Spring.nlerpable
export type Spring<T = nlerpable> = _Spring.Spring<T>

export type Proxy<T = { [any]: any }> = _Proxy.Proxy<T>

export type Binder = _Binder.Binder

export type LoggerType = _Logger.LoggerType

export type Quaternion = _Quaternion.Quaternion
export type QuaternionSpring = _QuaternionSpring.QuaternionSpring

-- Typed Remotes & Bindables
export type RE<Server..., Client...> = _TypedRemote.Event<Server...,  Client...>
export type RF<Send..., Receive...> = _TypedRemote.Function<Send..., Receive...>
export type BE<Send...> = _TypedBindable.Event<Send...>
export type BF<Send..., Receive...> = _TypedBindable.Function<Send..., Receive...>

export type AdjustmentPool = _AdjustmentPool.AdjustmentPool
export type AcceptedPoolValues = _AdjustmentPool.AcceptedValues

export type PredicateManager = _PredicateManager.PredicateManager
export type CallbackManager = _CallbackManager.CallbackManager

export type TimeKeeper = _TimeKeeper.TimeKeeper
export type UniversalTimestamp = GlobalTypes.UniversalTimestamp

export type PathfinderInstance = _Pathfinder.PathfinderInstance

export type Batcher = _Batcher.Batcher

export type BezierCurve = _Bezier.BezierCurve

export type DataCatalog<T> = _DataCatalog.DataCatalog<T>

export type RandomRotator = _RandomRotator.RandomRotator
export type RotationConfig = _RandomRotator.RotationConfig

export type Respawner = _Respawner.Respawner

local _DynamicOctree = require(script._DynamicOctree)
export type DynamicOctree = _DynamicOctree.DynamicOctree

export type Screen3D = _Screen3D.screenGenType

return {
	Screen3D = _Screen3D,
	Promise = _Promise,
	Scheduler = _Scheduler,
	Signal = _Signal,
	Trove = _Trove,
	ZoneModule = _Zone,
	Octree = _Octree,
	Timer = _Timer,
	Shake = _Shake,
	FastCast = _FastCastRedux,
	PartCache = _PartCache,
	Cache = _Cache,
	Spring = _Spring,
	SpringUtils = _SpringUtils,
	DuckTypeUtils = _DuckTypeUtils,
	Proxy = _Proxy,
	Binder = _Binder,
	Logger = _Logger,
	Quaternion = _Quaternion,
	QuaternionSpring = _QuaternionSpring,
	TypedRemote = _TypedRemote,
	TypedBindable = _TypedBindable,
	PredicateManager = _PredicateManager,
	CallbackManager = _CallbackManager,
	TimeKeeper = _TimeKeeper,
	AdjustmentPool = _AdjustmentPool,
	Pathfinder = _Pathfinder,
	Batcher = _Batcher,
	CollisionParticles = _CollisionParticles,
	Bezier = _Bezier,
	DataCatalog = _DataCatalog,
	RandomRotator = _RandomRotator,
	Respawner = _Respawner,
	Packet = _Packet,
	Lottery = _Lottery,
	Future = _Future,
	RateLimiter = _RateLimiter,
	DynamicOctree = _DynamicOctree
}