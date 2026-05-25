AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--------------------------------------------------------------------------------
ENT.ClientProps = {}

local SPAWN_LIFT = Vector(0, 0, 140)
local WAGON_LEN_M = 18
local SIDE_LIGHT_TEXTURE = "models/metrostroi_signals/signal_sprite_002.vmt"
local ZERO_ANG = Angle(0, 0, 0)

-- Костыльный фикс сцепок. Если есть идеи лучше, то передейлай. 
-- Переопределяем здесь, чтобы не трогать Metrostroi.
function ENT:CreateCouple(pos, ang, forward, typ)
	local coupler = ents.Create("gmod_train_couple")
	coupler:SetPos(self:LocalToWorld(pos))
	coupler:SetAngles(self:GetAngles() + ang)
	coupler.CoupleType = typ
	coupler:Spawn()

	if self.GetPlayer and IsValid(self:GetPlayer()) then
		coupler:SetPlayer(self:GetPlayer())
	end
	if CPPI and IsValid(self:CPPIGetOwner()) then
		coupler:CPPISetOwner(self:CPPIGetOwner())
	end

	coupler:SetNW2Bool("IsForwardCoupler", forward)
	coupler:SetNW2Entity("TrainEntity", self)
	coupler.SpawnPos = pos
	coupler.SpawnAng = ang

	self.JointPositions = self.JointPositions or {}
	local index = 1
	local offset = coupler.CouplingPointOffset or Vector(0, 0, 0)
	local x = self:WorldToLocal(coupler:LocalToWorld(offset)).x
	for _, v in ipairs(self.JointPositions) do
		if v > pos.x then
			index = index + 1
		else
			break
		end
	end
	table.insert(self.JointPositions, index, x)

	if self.NoPhysics then
		coupler:SetParent(self)
	else
		constraint.AdvBallsocket(
			self, coupler,
			0, 0,
			pos, Vector(0, 0, 0),
			1, 1,
			-2, -2, -15,
			2, 2, 15,
			0.1, 0.1, 1,
			0, 1
		)
		if forward and IsValid(self.FrontBogey) then
			constraint.NoCollide(self.FrontBogey, coupler, 0, 0)
		elseif not forward and IsValid(self.RearBogey) then
			constraint.NoCollide(self.RearBogey, coupler, 0, 0)
		end
	end

	self.TrainEntities = self.TrainEntities or {}
	table.insert(self.TrainEntities, coupler)
	return coupler
end

local function sideLights()
	return {
		[14] = { "light", Vector(-50, 68, 54),  ZERO_ANG, Color(255, 0, 0),     brightness = 0.5, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[15] = { "light", Vector(4, 68, 54),    ZERO_ANG, Color(150, 255, 255), brightness = 0.6, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[16] = { "light", Vector(1, 68, 54),    ZERO_ANG, Color(0, 255, 0),     brightness = 0.5, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[17] = { "light", Vector(-2, 68, 54),   ZERO_ANG, Color(255, 255, 0),   brightness = 0.5, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[18] = { "light", Vector(-50, -69, 54), ZERO_ANG, Color(255, 0, 0),     brightness = 0.5, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[19] = { "light", Vector(5, -69, 54),   ZERO_ANG, Color(150, 255, 255), brightness = 0.6, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[20] = { "light", Vector(2, -69, 54),   ZERO_ANG, Color(0, 255, 0),     brightness = 0.5, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
		[21] = { "light", Vector(-1, -69, 54),  ZERO_ANG, Color(255, 255, 0),   brightness = 0.5, scale = 0.10, texture = SIDE_LIGHT_TEXTURE },
	}
end

function ENT:InitTrainModel()
	if self.TrainType == "81-717" then
		self:SetModel("models/metrostroi_train/81-717/81-717_mvm.mdl")
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
	elseif self.TrainType == "81-714" then
		self:SetModel("models/metrostroi_train/81-717/81-717_mvm_int.mdl")
	end
	self.BaseClass.Initialize(self)
	self:SetPos(self:GetPos() + SPAWN_LIFT)
end

function ENT:InitBogeys()
	self.JointPositions = self.JointPositions or {}
	self.TrainEntities = self.TrainEntities or {}

	if Metrostroi.BogeyOldMap then
		self.FrontBogey  = self:CreateBogey(Vector(317 - 5, 0, -84), Angle(0, 180, 0), true, "717")
		self.RearBogey   = self:CreateBogey(Vector(-317, 0, -84), Angle(0, 0, 0), false, "717")
		self.FrontCouple = self:CreateCouple(Vector(419.5, 0, -62), Angle(0, 0, 0), true, "717")
		self.RearCouple  = self:CreateCouple(Vector(-419.5 - 6.545, 0, -62), Angle(0, 180, 0), false, "717")
	else
		self.FrontBogey  = self:CreateBogey(Vector(317 - 11, 0, -80), Angle(0, 180, 0), true, "717")
		self.RearBogey   = self:CreateBogey(Vector(-317, 0, -80), Angle(0, 0, 0), false, "717")
		self.RearCouple  = self:CreateCouple(Vector(-421, 0, -66), Angle(0, 180, 0), false, "717")
		self.FrontCouple = self:CreateCouple(Vector(410 - 3, 0, -66), Angle(0, 0, 0), true, "717")
	end
end

function ENT:InitDriverSeat()
	if self.TrainType ~= "81-717" then return end
	self.DriverSeat = self:CreateSeat("driver", Vector(417, 0, -22.5))
	self.DriverSeat:SetColor(Color(0, 0, 0, 0))
	self.DriverSeat:SetRenderMode(RENDERMODE_TRANSALPHA)
end

function ENT:InitDoorPositions()
	self.LeftDoorPositions = {}
	self.RightDoorPositions = {}
	for i = 0, 3 do
		local x = 353.0 - 35 * 0.5 - 231 * i
		table.insert(self.LeftDoorPositions, Vector(x, 65, -1.8))
		table.insert(self.RightDoorPositions, Vector(x, -65, -1.8))
	end
end

function ENT:InitRouteDefaults()
	local route
	for k in pairs(Metrostroi.AIConfiguration or {}) do
		if not route then route = k end
	end

	self.Route = self.Route or route or "default"
	if not self.PathID then
		local cfg = route and Metrostroi.AIConfiguration and Metrostroi.AIConfiguration[route]
		self.PathID = cfg and cfg.Path or math.random(1, 2)
	end

	self.Position = self.Position or 100
	self.Velocity = 0
	self.RheostatPosition = 0
end

function ENT:InitLights()
	if self.TrainType == "81-717" then
		local lights = sideLights()
		lights[1]  = { "headlight", Vector(465, 0, -20), ZERO_ANG, Color(176, 161, 132), fov = 100 }
		lights[2]  = { "glow", Vector(460, 51, -23), ZERO_ANG, Color(255, 255, 255), brightness = 2 }
		lights[3]  = { "glow", Vector(460, -51, -23), ZERO_ANG, Color(255, 255, 255), brightness = 2 }
		lights[4]  = { "glow", Vector(460, -8, 55), ZERO_ANG, Color(255, 255, 255), brightness = 0.3 }
		lights[5]  = { "glow", Vector(460, -8, 55), ZERO_ANG, Color(255, 255, 255), brightness = 0.3 }
		lights[6]  = { "glow", Vector(460, 2, 55), ZERO_ANG, Color(255, 255, 255), brightness = 0.3 }
		lights[7]  = { "glow", Vector(460, 2, 55), ZERO_ANG, Color(255, 255, 255), brightness = 0.3 }
		lights[8]  = { "light", Vector(458, -45, 55), ZERO_ANG, Color(255, 0, 0), brightness = 10, scale = 1.0 }
		lights[9]  = { "light", Vector(458, 45, 55), ZERO_ANG, Color(255, 0, 0), brightness = 10, scale = 1.0 }
		lights[10] = { "dynamiclight", Vector(420, 0, 35), ZERO_ANG, Color(255, 255, 255), brightness = 0.1, distance = 550 }
		lights[12] = { "dynamiclight", Vector(0, 0, 5), ZERO_ANG, Color(255, 255, 255), brightness = 3, distance = 400 }
		self.Lights = lights
	elseif self.TrainType == "81-714" then
		local lights = sideLights()
		lights[12] = { "dynamiclight", Vector(0, 0, 5), ZERO_ANG, Color(255, 255, 255), brightness = 3, distance = 400 }
		self.Lights = lights
	end
end

function ENT:SpawnConsist()
	if self.TrainType ~= "81-717" or self.TrainHead then return end

	local numWagons = 5
	local minLength = math.huge
	for _, stationData in pairs(Metrostroi.Stations or {}) do
		for _, platformData in pairs(stationData) do
			local len = platformData.length
			if len and len > 0 and len < minLength then
				minLength = len
			end
		end
	end
	if minLength ~= math.huge then
		numWagons = math.max(3, math.min(8, math.floor(minLength / WAGON_LEN_M)))
	end

	self.NumWagons = numWagons
	print(Format("[AI] Spawning %d-wagon consist (shortest platform: %.1f m)",
		numWagons, minLength == math.huge and -1 or minLength))

	for i = 2, numWagons do
		local ent = ents.Create("gmod_subway_ai")
		ent.TrainType = (i == numWagons) and "81-717" or "81-714"
		ent.TrainIndex = i
		ent.TrainHead = self
		ent.Owner = self.Owner
		ent:Spawn()
		table.insert(self.TrainEntities, ent)
	end
end

function ENT:SyncNetworkState()
	self:SetNW2String("TrainType", self.TrainType)
	self:SetNW2Bool("IsRearCar", self.TrainHead ~= nil)
	self:SetNW2Float("PassengerCount", 0)

	self:SetNW2Int("MaskType", 3)
	self:SetNW2Int("LampType", 1)
	self:SetNW2Int("SeatType", 1)
	self:SetNW2Int("KVType", 1)
	self:SetNW2Bool("NewBortlamps", true)
	self:SetNW2String("Texture", "Def_717MSKBlue")
	self:SetNW2String("PassTexture", "Def_717MSKWhite")
	self:SetNW2String("CabTexture", "Def_HammeriteG")

	if not self.TrainHead and self.TrainType == "81-717" then
		self:SetPackedBool("Headlights1", true)
		self:SetPackedBool("Headlights2", true)
	end
end

function ENT:Initialize()
	self.SubwayTrain = { Type = "AI", Name = "" }
	self.TrainType = self.TrainType or "81-717"
	self:SetNW2String("TrainType", self.TrainType)

	-- Capture spawn pose before the vertical lift (used by track snap in Think)
	self.SpawnPos = self:GetPos()
	self.SpawnAngle = self:GetAngles()
	self.NoPhysics = true

	self:InitTrainModel()
	self:InitBogeys()
	self:InitDriverSeat()
	self:InitDoorPositions()
	self:InitRouteDefaults()
	self:InitLights()

	if CPPI and IsValid(self.Owner) then
		self:CPPISetOwner(self.Owner)
	end

	self:SpawnConsist()
	self:SyncNetworkState()
end

concommand.Add("metrostroi_ai_spawn", function(ply, _, args)
	if (ply:IsValid()) and (not ply:IsAdmin()) then return end

	local pathid = tonumber(args[2]) or 1
	local trainCounter = tonumber(args[1]) or 1
	local prevEnt
	timer.Create("metrostroi-ai-spawntimer-"..pathid,1.0,0,function()
		if prevEnt then
			if (pathid == 1) and (prevEnt.Position < 260) then
				return
			end
			if (pathid == 2) and (prevEnt.Position < 960) then
				return
			end
		end
		if trainCounter < 1 then return end

		local ent = ents.Create("gmod_subway_ai")
		ent.Position = 150
		ent.PathID = pathid
		ent:Spawn()
		prevEnt = ent
		trainCounter = trainCounter - 1
		print("Spawning AI trains (path "..pathid.."), left: "..trainCounter)
	end)
end)

concommand.Add("metrostroi_ai_clear", function(ply, _, args)
	if (ply:IsValid()) and (not ply:IsAdmin()) then return end
	for k,v in pairs(ents.FindByClass("gmod_subway_ai")) do
		SafeRemoveEntity(v)
		if args[1] then print("Removed one") return end
	end
	--timer.Create("metrostroi-ai-spawntimer",1.0,0,function()end)
end)

concommand.Add("metrostroi_ai_info", function(ply, _, args)
	if (ply:IsValid()) and (not ply:IsAdmin()) then return end
	for k,v in pairs(ents.FindByClass("gmod_subway_ai")) do
		if not v.TrainHead then
			print(Format("Train to [%03d][%02d] (%.0f m %.02f km/h, left %0.3f m)",
				v.TargetStation or 0,v.TargetPlatform or 0,v.Position,v.Speed,
				(v.PlatformEdgeX or 0) - v.Position))
		end
	end
end)




--------------------------------------------------------------------------------
-- Find the true "reverse" of the current path.
-- A reverse path starts near the current path's end AND ends near its start
-- (so on maps with 3+ branching paths we don't pick a spur off the same end).
--------------------------------------------------------------------------------
function ENT:FindReturnPath(currentPathID)
	local currentPath = Metrostroi.Paths[currentPathID]
	if not currentPath then return nil end
	local startNode = currentPath[1]
	local endNode = currentPath[#currentPath]
	if not (startNode and endNode) then return nil end

	local bestPathID, bestScore = nil, math.huge
	for pathID, otherPath in pairs(Metrostroi.Paths) do
		if pathID == currentPathID then continue end
		local fn = otherPath[1]
		local ln = otherPath[#otherPath]
		if not (fn and ln) then continue end
		-- Sum of "start↔end" and "end↔start" distances:
		-- a true reverse path scores low on BOTH; a side spur scores high on one.
		local score = fn.pos:Distance(endNode.pos) + ln.pos:Distance(startNode.pos)
		if score < bestScore then
			bestScore = score
			bestPathID = pathID
		end
	end
	return bestPathID
end

--------------------------------------------------------------------------------
-- Build list of station stop positions for the current path.
-- Primary source: Metrostroi.Stations (gmod_track_platform entities).
-- Enhancement: UPPS sensors with DistanceToOPV override platform positions
--              when they are present on the map.
--------------------------------------------------------------------------------
function ENT:BuildOPVStopList()
	self.OPVStops = {}
	self.OPVMinStopPos = nil
	self.StopTimer = nil
	self.DepartTimer = nil
	self.DoorCloseTimer = nil

	local path = Metrostroi.Paths[self.PathID]
	if not path then return end

	-- 1) Gather every UPPS sensor's OPV position on this path
	local opvPositions = {}
	for _, plate in pairs(ents.FindByClass("gmod_track_autodrive_plate")) do
		if not IsValid(plate) then continue end
		if not plate.UPPS then continue end
		if not plate.DistanceToOPV or plate.DistanceToOPV <= 0 then continue end
		local results = Metrostroi.GetPositionOnTrack(plate:GetPos(), angle_zero, { z_pad = 256 })
		for _, trackPos in ipairs(results) do
			if trackPos.path == path then
				table.insert(opvPositions, trackPos.x + plate.DistanceToOPV)
				break
			end
		end
	end

	-- 2) For each platform on this path, pick ONE stop:
	--    if an OPV sensor lies anywhere within the platform's track range, use it;
	--    otherwise fall back to the platform's far edge. Random ±0.5 m jitter
	--    so the train doesn't always stop in the exact same spot.
	local usedOPV = {}
	for _, stationData in pairs(Metrostroi.Stations or {}) do
		for _, platformData in pairs(stationData) do
			local node = platformData.node_end or platformData.node_start
			if node and node.path == path then
				local pStart = math.min(platformData.x_start, platformData.x_end)
				local pEnd   = math.max(platformData.x_start, platformData.x_end)
				local stopPos = nil
				for i, opvX in ipairs(opvPositions) do
					if not usedOPV[i] and opvX >= pStart - 30 and opvX <= pEnd + 30 then
						stopPos = opvX
						usedOPV[i] = true
						break
					end
				end
				stopPos = (stopPos or pEnd) + (math.random() - 0.5)
				table.insert(self.OPVStops, stopPos)
			end
		end
	end

	-- 3) Any OPV sensors not matched to a platform still become valid stops
	for i, opvX in ipairs(opvPositions) do
		if not usedOPV[i] then
			table.insert(self.OPVStops, opvX + (math.random() - 0.5))
		end
	end

	table.sort(self.OPVStops)
	print(Format("[AI] Path %d: %d station stop(s) found", self.PathID, #self.OPVStops))
end

--------------------------------------------------------------------------------
-- Derive an ARS speed limit (km/h) from the ALSCoil's frequency codes.
-- The coil exposes F1..F6 (ARS frequency flags) — the highest one present
-- sets the permitted speed. F1 = code 8 = fastest … F5 = code 0 = slowest.
-- AO is the absolute-stop code. Returns 0 when there is no ARS code at all
-- (uncovered track or a stop demand); DoAI then applies a cautious crawl.
--------------------------------------------------------------------------------
function ENT:GetARSCruiseSpeed()
	local c = self.ALSCoil
	if not c then return 0 end
	if c.AO then return 0 end
	if (c.F1 or 0) > 0 then return 80 end
	if (c.F2 or 0) > 0 then return 70 end
	if (c.F3 or 0) > 0 then return 60 end
	if (c.F4 or 0) > 0 then return 40 end
	if (c.F5 or 0) > 0 then return 20 end
	return 0
end

--------------------------------------------------------------------------------
-- Find the station's gmod_track_clock_interval (cached per-stop).
-- This is the wall clock that resets every time a train passes — we read it to
-- enforce the 1:30 service interval instead of using a fixed dwell.
--------------------------------------------------------------------------------
function ENT:FindStationClock()
	if self._CachedClockFor == self.PlatformEdgeX and IsValid(self._CachedClock) then
		return self._CachedClock
	end
	self._CachedClock = nil
	self._CachedClockFor = self.PlatformEdgeX
	local myPos = self:GetPos()
	local closest, closestDist = nil, math.huge
	for _, clock in pairs(ents.FindByClass("gmod_track_clock_interval")) do
		if not IsValid(clock) then continue end
		local d = clock:GetPos():Distance(myPos)
		if d < 600 and d < closestDist then -- platforms are well under 600 u from sign
			closest = clock
			closestDist = d
		end
	end
	self._CachedClock = closest
	return closest
end

--------------------------------------------------------------------------------
-- Returns the station clock's current reading in seconds (time since last
-- train passed). Nil if no clock is nearby or it has never been triggered.
--------------------------------------------------------------------------------
function ENT:GetStationInterval()
	local clock = self:FindStationClock()
	if not clock or not clock.GetIntervalResetTime then return nil end
	local resetTime = clock:GetIntervalResetTime()
	if not resetTime or resetTime == 0 then return nil end
	return Metrostroi.GetSyncTime() - (resetTime + (GetGlobalFloat("MetrostroiTY") or 0))
end

--------------------------------------------------------------------------------
-- Decide which doors to open. Returns "left" or "right" or nil.
--
-- CRITICAL: this replicates gmod_track_platform's OWN left_side computation
-- exactly — orientation of the train along the platform, then flipped by the
-- platform's InvertSides flag. If the AI opened a geometrically-correct side
-- that disagreed with the platform's left_side, the platform's
-- `doors_open` test would be false and NO passengers would board. Matching
-- the platform's logic guarantees the doors it expects are the doors we open.
--------------------------------------------------------------------------------
function ENT:DetectPlatformSide()
	local myPos = self:GetPos()
	local nearest, bestDist = nil, 1500
	for _, plat in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(plat) then continue end
		-- plat:GetPos() is often the brush origin (nowhere near the train),
		-- so use the platform's actual track extent PlatformStart→PlatformEnd.
		local pStart, pEnd = plat.PlatformStart, plat.PlatformEnd
		if not pStart or not pEnd then continue end
		local seg     = pEnd - pStart
		local segLen2 = seg:LengthSqr()
		local t = (segLen2 > 0) and math.Clamp((myPos - pStart):Dot(seg) / segLen2, 0, 1) or 0
		local d = (pStart + seg * t):Distance(myPos)
		if d < bestDist then
			bestDist = d
			nearest  = plat
		end
	end
	if not nearest then return nil end

	-- Same maths gmod_track_platform/init.lua runs to pick the door side.
	local pStart  = nearest.PlatformStart
	local pDir    = nearest.PlatformEnd - pStart
	local dirLen2 = pDir:LengthSqr()
	if dirLen2 <= 0 then return nil end
	local front  = self:LocalToWorld(Vector( 480, 0, 0))
	local back   = self:LocalToWorld(Vector(-480, 0, 0))
	local tFront = (front - pStart):Dot(pDir) / dirLen2
	local tBack  = (back  - pStart):Dot(pDir) / dirLen2
	local leftSide = tFront > tBack
	if nearest.InvertSides then leftSide = not leftSide end
	return leftSide and "left" or "right"
end

--------------------------------------------------------------------------------
-- Find distance to the nearest other train on the same path AHEAD of us.
-- Scans ALL spawned trains (AI consists AND player-driven cars) via the
-- Metrostroi.SpawnedTrains/TrainPositions registry so the AI brakes for both.
--------------------------------------------------------------------------------
function ENT:UpdateTrainAhead()
	self.TrainAheadDistance = nil
	if not self.PathID then return end
	local closest = nil

	local function consider(otherX, otherPathID)
		if not otherX or not otherPathID then return end
		if otherPathID ~= self.PathID then return end
		local dist = otherX - self.Position
		if dist > 0 and dist < 500 then
			if not closest or dist < closest then closest = dist end
		end
	end

	-- AI bot cars (every wagon of every AI consist) — direct & reliable.
	-- Our own followers are behind us so they yield a negative dist and
	-- are filtered out by the dist > 0 test.
	for _, other in ipairs(ents.FindByClass("gmod_subway_ai")) do
		if other ~= self and IsValid(other) then
			consider(other.Position, other.PathID)
		end
	end

	-- Player-driven trains — resolved through the position registry.
	for ent, tbl in pairs(Metrostroi.SpawnedTrains or {}) do
		if ent ~= self and IsValid(ent) and type(tbl) == "table"
		   and ent:GetClass() ~= "gmod_subway_ai" then
			local tp = Metrostroi.TrainPositions and Metrostroi.TrainPositions[ent]
			local entry = tp and tp[1]
			if entry then
				consider(entry.x, entry.path and entry.path.id)
			end
		end
	end

	self.TrainAheadDistance = closest
end

--------------------------------------------------------------------------------
-- Train driving AI
--------------------------------------------------------------------------------
function ENT:DoAI(dT)
	-- Rebuild OPV stop list when path or route changes
	if not self.OPVStops or self.OPVLastPathID ~= self.PathID or self.OPVLastRoute ~= self.Route then
		self.OPVLastPathID = self.PathID
		self.OPVLastRoute = self.Route
		self:BuildOPVStopList()
	end

	-- Find next OPV stop, skipping already-completed ones.
	-- The "stopPos > Position − 12" test (instead of "> Position") keeps a
	-- stop selected even when the train centre has rolled slightly PAST it —
	-- otherwise a 1 m overrun would make platformEdgeX jump to the NEXT
	-- station and the train would never dwell / open doors at the one it is
	-- physically standing at. A finished stop is excluded via OPVMinStopPos.
	local platformEdgeX = nil
	local minPos = self.OPVMinStopPos or -math.huge
	for _, stopPos in ipairs(self.OPVStops) do
		if stopPos > self.Position - 12 and stopPos > minPos then
			platformEdgeX = stopPos
			break
		end
	end
	self.PlatformEdgeX = platformEdgeX

	-- Speed limit from the ALS coil's ARS frequency codes.
	local speedLimit  = self:GetARSCruiseSpeed()
	local targetSpeed = speedLimit

	-- Default approach speed when all limits are zero
	if targetSpeed == 0 then targetSpeed = 20 end
	-- Slow through speed-40 limit zones
	if targetSpeed == 40 then targetSpeed = 20 end

	-- ---------------- Stuck-at-red-light escape ----------------
	-- A signal can be stuck red forever (broken route, never-clearing block,
	-- mis-set map signal). If we've sat still right at a red signal for a long
	-- time AND no train is actually detected ahead, treat the red as false and
	-- latch a one-time override: creep past it at restricted speed. The latch
	-- holds until we physically pass that signal, then normal behaviour
	-- resumes (so a genuine red further on still stops us).
	if self.RedLightDistance and self.RedLightDistance < 35
	   and self.Speed < 2 and not self.TrainAheadDistance then
		self.RedStuckTimer = (self.RedStuckTimer or 0) + dT
	else
		self.RedStuckTimer = 0
	end
	if (self.RedStuckTimer or 0) > 10 and not self.IgnoreRedUntil then
		self.IgnoreRedUntil = self.Position + (self.RedLightDistance or 0) + 25
	end
	if self.IgnoreRedUntil and self.Position > self.IgnoreRedUntil then
		self.IgnoreRedUntil = nil
	end
	local ignoreRed = self.IgnoreRedUntil ~= nil

	-- ---------------- Unified gradual deceleration ----------------
	-- Pick the closest reason to stop:
	--   • OPV / station platform edge
	--   • ARS red light (skipped while the stuck-red override is latched)
	--   • Another AI train ahead (rear of leading consist + 10 m safety)
	-- Apply the same approach curve to all three so we never slam into anything.
	local stopDist = nil
	if platformEdgeX and (platformEdgeX > self.Position) then
		stopDist = platformEdgeX - self.Position
	end
	if self.RedLightDistance and not ignoreRed then
		if not stopDist or self.RedLightDistance < stopDist then
			stopDist = self.RedLightDistance
		end
	end
	if self.TrainAheadDistance then
		local trainStop = self.TrainAheadDistance - 160 -- safety buffer behind other consist
		if not stopDist or trainStop < stopDist then
			stopDist = trainStop
		end
	end

	-- While creeping past a stuck red signal, hold a cautious restricted speed.
	if ignoreRed then
		targetSpeed = math.min(targetSpeed, 20)
	end

	-- Approach curve: ~150 m → 60 km/h, ~75 m → 35 km/h, ~0.5 m → 0 km/h
	if stopDist and stopDist < 180 then
		if stopDist <= 0 then
			targetSpeed = 0
		else
			local d = math.max(0, stopDist - 0.01)
			local approachSpeed = math.min(60, 1.32 * d ^ 0.776)
			targetSpeed = math.min(targetSpeed, approachSpeed)
		end
	end

	-- ---------------- Station dwell (only for OPV stops) ----------------
	-- StopTimer:   counts down from 10 once the train has fully stopped — doors
	--              open ~1 s in (handled by the Think door logic).
	-- DepartTimer: 15 s passenger exchange window after StopTimer ends.
	-- Total dwell ≈ 25 s. If the station's interval clock already reads
	-- ≥ 1:30 the train may leave as soon as the passenger window is done,
	-- but it never WAITS on the clock beyond the 25 s dwell.
	-- Don't run the dwell timer while the doors are in their closing phase.
	if platformEdgeX then
		-- Begin the station dwell when the train is stopped within 12 m of the
		-- OPV — measured as an ABSOLUTE distance so a slight overrun (train
		-- centre just past the OPV) still counts. The old 200 m window opened
		-- doors at red lights mid-line; a tight one-sided window missed the
		-- stop whenever the train overran by even 1 m. 12 m absolute is the
		-- balance: it always catches a real OPV stop but not a far-off red.
		local dX = math.abs(platformEdgeX - self.Position)
		if dX < 12 and self.Speed < 1 and not self.DoorCloseTimer then
			if not self.StopTimer then self.StopTimer = 10 end
			self.StopTimer = self.StopTimer - dT
			if self.StopTimer <= 0 then
				if not self.DepartTimer then self.DepartTimer = 15 end
				self.DepartTimer = self.DepartTimer - dT
			end
		end
	end

	-- Departure sequence:
	--   Phase 1 — dwell complete (≈25 s fixed dwell).
	--   Phase 2 — DOOR-CLOSING: clear StopTimer so the doors slide shut,
	--             hold the train at the platform for 3 s, THEN release it.
	--   This guarantees the doors are fully closed before the train moves.
	--   Overrunning the stop position always departs immediately.
	if platformEdgeX then
		if not self.DoorCloseTimer then
			-- Phase 1
			local passengerPhaseDone = self.StopTimer and self.StopTimer <= 0
			local readyToDepart = false
			if passengerPhaseDone then
				-- Departure rule:
				--   • If a working interval clock is present, it is a STRICT
				--     gate — the train waits until it reads ≥ 1:30 (90 s) and
				--     ignores the DepartTimer entirely. No early departures.
				--   • If there is no clock (GetStationInterval returns nil),
				--     fall back to the fixed ~25 s dwell (StopTimer 10 +
				--     DepartTimer 15).
				local interval = self:GetStationInterval()
				if interval then
					if interval >= 90 then
						readyToDepart = true
					end
				else
					if self.DepartTimer and self.DepartTimer <= 0 then
						readyToDepart = true
					end
				end
			end
			if readyToDepart then
				self.DoorCloseTimer = 3      -- begin closing the doors
				self.StopTimer = nil          -- StopTimer nil → doors slide shut
			end
		else
			-- Phase 2: doors closing, train still braked at the platform.
			self.DoorCloseTimer = self.DoorCloseTimer - dT
			if self.DoorCloseTimer <= 0 then
				self.OPVMinStopPos = platformEdgeX
				self.DoorCloseTimer = nil
				self.DepartTimer  = nil
				self._CachedClock = nil
			end
		end
		-- Overrun: depart immediately regardless of phase.
		if self.Position > platformEdgeX + 5 then
			self.OPVMinStopPos  = platformEdgeX
			self.StopTimer      = nil
			self.DepartTimer    = nil
			self.DoorCloseTimer = nil
			self._CachedClock   = nil
		end
	end

	-- Accelerate / brake to reach target speed
	if self.Speed > (targetSpeed - 2) then self.Accelerating = false end
	if self.Speed < (targetSpeed - 10) then self.Accelerating = true end
	if self.Speed > targetSpeed then self.Braking = true end
	if (self.Speed < (targetSpeed - 5)) and self.Braking then self.Braking = false end

	-- ARS overspeed alert. The ALSCoil is only a track-frequency pickup — it
	-- has no LVD/attention-pedal logic — so approximate the alert here:
	-- raise it when the train exceeds the ARS-permitted speed. Drives the
	-- warning ringer (packed bool 39).
	self.ARSAlert = (speedLimit > 0) and (self.Speed > speedLimit + 3) or false

	-- Pneumatic brakes.
	-- The OLD logic slammed the pneumatic brake on whenever Speed < 7 — this
	-- braked the train to a halt several metres SHORT of the OPV, after which
	-- it had to creep forward again (the "stop, then move a few metres" bug).
	-- New logic: the motor brake follows the approach curve the whole way in;
	-- the pneumatic brake only engages for the final ~6 m to a stop target
	-- (or as a parking brake when idle with nothing to approach). The train
	-- now coasts smoothly to its stop point in a single motion.
	self.Pneumo = false
	if not self.Accelerating then
		if stopDist and stopDist < 10 and self.Speed < 18 then
			self.Pneumo = true            -- final approach + hold at a stop target
		elseif (not stopDist) and self.Speed < 1 then
			self.Pneumo = true            -- parking brake when idle, no target
		end
	end

	self.TargetSpeed = targetSpeed
end



--------------------------------------------------------------------------------
-- Train physics
--------------------------------------------------------------------------------
function ENT:DoPhysics(dT)
	-- Slopes code
	local slopeAngle = self:GetAngles().p
	if slopeAngle > 180 then slopeAngle = slopeAngle-360 end
	local slopeFactor = math.min(8.0,math.max(-8.0,slopeAngle))/8.0

	-- Motor code
	local motorPower = 0
	if self.Accelerating then	motorPower = 1.0 end
	if self.Braking then		motorPower = -1.0 end
	
	local motorForce = 0
	if motorPower > 0 then motorForce = 1.25*motorPower end
	if motorPower < 0 then motorForce = -1.3*math.abs(motorPower) * math.max(-1.0,math.min(1.0,0.25*self.Velocity)) end

	-- Brake code
	local brakeForce = 0
	if self.Pneumo then
		brakeForce = -1.4*math.max(-1.0,math.min(1.0,3.0*self.Velocity))
		slopeFactor = slopeFactor*math.max(-1.0,math.min(1.0,3.0*self.Velocity))
	end
	self.PneumoForce = brakeForce

	-- Integrate position and velocity
	self.Acceleration = 0
		+motorForce
		+brakeForce
		-self.Velocity*0.0045
		+slopeFactor*1.52
	self.Velocity = self.Velocity + dT*self.Acceleration
	self.Position = self.Position + dT*self.Velocity
	--print(Format("%.2f/%.2f km/h  %.0f m  A-%s B-%s P-%s",
		--self.Speed,self.TargetSpeed,self.Position,
		--tostring(self.Accelerating),tostring(self.Braking),tostring(self.Pneumo)))

	-- Info
	self.MotorPower = motorPower
end

function ENT:ThinkUpdateDeltaTime()
	self.PrevTime = self.PrevTime or CurTime()
	self.DeltaTime = CurTime() - self.PrevTime
	self.PrevTime = CurTime()
	if self.DeltaTime > 0.1 then self.DeltaTime = 0.1 end
	if self.DeltaTime < 0 then self.DeltaTime = 0 end
end

function ENT:ThinkEnsureRoute()
	if self.Route and self.PathID then return end
	if self.InitializeAttempted then return end
	self.InitializeAttempted = true

	local route
	for k in pairs(Metrostroi.AIConfiguration or {}) do
		if not route then route = k end
	end
	local cfg = route and Metrostroi.AIConfiguration[route]
	if cfg then
		self.Route = route
		self.PathID = cfg.Path
	end
end

function ENT:ThinkSpawnSnap()
	if self.SpawnSnapped or self.TrainHead or not Metrostroi.GetPositionOnTrack then return end

	self._SnapTries = (self._SnapTries or 0) + 1
	local results = Metrostroi.GetPositionOnTrack(
		self.SpawnPos or self:GetPos(),
		self.SpawnAngle or self:GetAngles(),
		{ z_pad = 384, radius = 600 }
	)

	local best
	if results then
		for _, r in ipairs(results) do
			if r.path and r.path.id and r.forward then
				best = r
				break
			end
		end
		best = best or results[1]
	end

	if best and best.path and best.path.id then
		self.PathID = best.path.id
		self.Position = best.x
		self.Route = self.Route or "default"
		self.SpawnSnapped = true
	elseif self._SnapTries > 600 then
		self.SpawnSnapped = true
	end
end

function ENT:ThinkUpdateALSCoil(dT)
	if self.TrainHead or not self.ALSCoil then return end
	if self.ALSCoil.Enabled == 0 then self.ALSCoil.Enabled = 1 end
	self.ALSCoil_AccumT = (self.ALSCoil_AccumT or 0) + dT
	if self.ALSCoil_AccumT >= 0.1 then
		self.ALSCoil:Think(self.ALSCoil_AccumT)
		self.ALSCoil_AccumT = 0
	end
end

function ENT:ThinkResolvePath()
	if not self.PathID or not self.Route then return nil end
	local path = Metrostroi.Paths[self.PathID]
	if path then return path end
	for pid, p in pairs(Metrostroi.Paths or {}) do
		if p then
			self.PathID = pid
			return p
		end
	end
	return nil
end

function ENT:ThinkUpdateRoute(path)
	local config = Metrostroi.AIConfiguration[self.Route]
	if config and self.Position > config.EndPosition then
		self.Route = config.NextRoute
		config = Metrostroi.AIConfiguration[self.Route]
		if config then
			self.PathID = config.Path
			self.Position = config.SpawnPosition
		end
		self.Velocity = 0
		self.Schedule = nil
		self.NoStation = false
		return
	end

	if config or not path then return end
	local lastNode = path[#path]
	if not lastNode or self.Position <= lastNode.x then return end

	local numWagons = self.NumWagons or 5
	local consistOffset = numWagons * 18.35 + 30
	local returnPathID = self:FindReturnPath(self.PathID)
	if returnPathID and Metrostroi.Paths[returnPathID] then
		self.PathID = returnPathID
		local firstNode = Metrostroi.Paths[returnPathID][1]
		self.Position = (firstNode and firstNode.x or 0) + consistOffset
	else
		local firstNode = path[1]
		self.Position = (firstNode and firstNode.x or 0) + consistOffset
	end
	self.Velocity = 0
	self.OPVStops = nil
end

function ENT:ThinkDriveTrain(dT)
	if not self.TrainHead then
		self:DoAI(dT)
		self:DoPhysics(dT)
		return true
	end

	if not IsValid(self.TrainHead) then
		SafeRemoveEntity(self)
		return false
	end

	self.Route = self.TrainHead.Route
	self.PathID = self.TrainHead.PathID
	self.Position = self.TrainHead.Position - 18.39 * (self.TrainIndex - 1) - 0.13
	self.Velocity = self.TrainHead.Velocity
	self.MotorPower = self.TrainHead.MotorPower
	self.PneumoForce = self.TrainHead.PneumoForce
	return true
end

function ENT:ThinkUpdateLights()
	local interiorOn = (CurTime() % 60) > 0.1
	if self.TrainType == "81-717" then
		local isFront = self.TrainHead == nil
		for i = 1, 7 do self:SetLightPower(i, isFront) end
		self:SetLightPower(8, not isFront)
		self:SetLightPower(9, not isFront)
		self:SetLightPower(10, interiorOn)
		self:SetLightPower(12, interiorOn)
	elseif self.TrainType == "81-714" then
		self:SetLightPower(12, interiorOn)
	end
end

function ENT:ThinkUpdatePneumatics(dT)
	self.PneumaticPressure = self.PneumaticPressure or 0
	self.PneumaticPressure_dPdT = self.PneumaticPressure_dPdT or 0
	if self.Pneumo then
		self.PneumaticPressure_dPdT = 0.65 * (1.5 - self.PneumaticPressure)
	else
		self.PneumaticPressure_dPdT = 0.65 * (0.0 - self.PneumaticPressure)
	end
	self.PneumaticPressure = self.PneumaticPressure + self.PneumaticPressure_dPdT * dT
end

function ENT:ThinkUpdateDoors()
	-- Door state — only open the side facing the platform.
	-- The head determines the side; followers mirror it. NOTE: follower cars
	-- are rendered flipped 180° (bodyDir negated in the bogey code), so their
	-- local +Y/−Y are the OPPOSITE physical side from the head — the door
	-- bools must be SWAPPED when copied or the rear wagons open the wrong side.
	if self.TrainHead then
		self.LeftDoorsOpen  = self.TrainHead.RightDoorsOpen
		self.RightDoorsOpen = self.TrainHead.LeftDoorsOpen
	else
		-- Doors may only be open while the train is essentially stationary.
		-- The Speed < 3 guard is a hard safety net: even if a timer is left
		-- set, the doors are forced shut the instant the train is moving.
		local shouldOpen = self.StopTimer and (self.StopTimer < 9) and (self.Speed < 3)
		if shouldOpen then
			if self._PlatformSideFor ~= self.PlatformEdgeX then
				self._PlatformSideFor = self.PlatformEdgeX
				self._PlatformSide = self:DetectPlatformSide()
			end
			-- Fallback: if no platform was found within range (open-track stop
			-- or weird map layout), open BOTH sides so passengers/animation
			-- still work. Better to open both than to leave them stuck shut.
			if self._PlatformSide == nil then
				self.LeftDoorsOpen  = true
				self.RightDoorsOpen = true
			else
				self.LeftDoorsOpen  = (self._PlatformSide == "left")
				self.RightDoorsOpen = (self._PlatformSide == "right")
			end
		else
			self.LeftDoorsOpen  = false
			self.RightDoorsOpen = false
			self._PlatformSideFor = nil
		end
	end
	-- The platform passenger system reads *DoorsOpening to drive boarding /
	-- alighting. Mirror the open state onto these flags so passengers walk
	-- in and out of the AI train just like they do for player-driven trains.
	self.LeftDoorsOpening  = self.LeftDoorsOpen
	self.RightDoorsOpening = self.RightDoorsOpen
	-- SOSD = the train's "open platform screen doors" command. At horizontal-
	-- lift stations (platform screen doors), gmod_track_platform refuses to
	-- board passengers unless the train asserts SOSD — mirror it onto the
	-- door-open state so the AI works at those stations too.
	self.SOSD = self.LeftDoorsOpen or self.RightDoorsOpen
	if self.LeftDoorsOpen ~= self.PrevLeftDoorsOpen then
		self.PrevLeftDoorsOpen = self.LeftDoorsOpen
		if self.LeftDoorsOpen then
			-- Door open sequence: pneumatic valve clunk + the per-doorway
			-- "door_open_end" thump after the slide animation finishes.
			self:PlayOnce("vdol_on")
			for i = 0, 3 do self:PlayOnce("door"..i.."x1o", nil, 1, 0.5 + math.random()*0.4) end
		else
			self:PlayOnce("vdol_off")
			for i = 0, 3 do self:PlayOnce("door"..i.."x1c", nil, 1, 0.4 + math.random()*0.4) end
		end
	end
	if self.RightDoorsOpen ~= self.PrevRightDoorsOpen then
		self.PrevRightDoorsOpen = self.RightDoorsOpen
		if self.RightDoorsOpen then
			self:PlayOnce("vdor_on")
			for i = 0, 3 do self:PlayOnce("door"..i.."x0o", nil, 1, 0.5 + math.random()*0.4) end
		else
			self:PlayOnce("vdor_off")
			for i = 0, 3 do self:PlayOnce("door"..i.."x0c", nil, 1, 0.4 + math.random()*0.4) end
		end
	end
	self:SetPackedBool(21,self.LeftDoorsOpen)
	self:SetPackedBool(22,self.LeftDoorsOpen)
	self:SetPackedBool(23,self.LeftDoorsOpen)
	self:SetPackedBool(24,self.LeftDoorsOpen)
	self:SetPackedBool(25,self.RightDoorsOpen)
	self:SetPackedBool(26,self.RightDoorsOpen)
	self:SetPackedBool(27,self.RightDoorsOpen)
	self:SetPackedBool(28,self.RightDoorsOpen)
	self:SetPackedBool(52, 1)
	self:SetPackedBool(39, (self.ARSAlert and not self.TrainHead) or false)
end

function ENT:ThinkSyncBogeys()
	self.Speed = math.abs(self.Velocity / 0.277778)
	self.FrontBogey.Speed = self.Speed
	self.RearBogey.Speed = self.Speed
	self.FrontBogey.MotorPower = self.MotorPower
	self.RearBogey.MotorPower = self.MotorPower
	self.FrontBogey.BrakeCylinderPressure_dPdT = -self.PneumaticPressure_dPdT
	self.RearBogey.BrakeCylinderPressure_dPdT = -self.PneumaticPressure_dPdT
	local squeal = math.min(1, (3 * math.abs(self.PneumoForce or 0)) ^ 1)
	self.FrontBogey.BrakeSqueal = squeal
	self.RearBogey.BrakeSqueal = squeal
end

function ENT:ThinkUpdateTrackPose(path)
	-- Bogey articulation: body pose from front/rear truck samples.
	--
	-- Each car body sits on TWO bogey trucks. The bogeys independently follow
	-- the track; the body's position and yaw are derived from the line between
	-- them. On a curve this naturally makes the body cut the chord instead of
	-- jittering through a single track sample — the same physics real subway
	-- cars use.
	--
	-- Step 1: sample track at each bogey's track-x coordinate.
	-- Step 2: body position = midpoint of the two bogey sample points.
	-- Step 3: body angle   = direction from rear bogey → front bogey.
	-- Step 4: each bogey gets its own LOCAL angle so it points along the
	--         track tangent at ITS own sample — gives the trucks a visible
	--         yaw twist relative to the body on tight curves.
	local METERS_PER_HU = 0.01905
	local frontBogeyOffM = ((Metrostroi.BogeyOldMap and (317 - 5) or (317 - 11))) * METERS_PER_HU
	local rearBogeyOffM  = 317 * METERS_PER_HU

	local fX = self.Position + frontBogeyOffM
	local rX = self.Position - rearBogeyOffM
	local fPos, fDir, fNode = Metrostroi.GetTrackPosition(path, fX)
	local rPos, rDir, rNode = Metrostroi.GetTrackPosition(path, rX)
	local node = fNode or rNode

	if fPos and rPos then
		-- Body: midpoint of the two bogey sample points
		local bodyVec = fPos - rPos
		local bodyLen = bodyVec:Length()
		local bodyDir = (bodyLen > 0.001) and (bodyVec / bodyLen) or Vector(1, 0, 0)
		if self.TrainHead then bodyDir = -bodyDir end
		local bodyAng = bodyDir:Angle()

		-- Drop the body 4 units along its own up axis so it sits closer to
		-- the bogeys (visually "loaded" onto the trucks rather than floating).
		-- Using local-up makes this correct on slopes too.
		self:SetPos((fPos + rPos) * 0.5 - bodyAng:Up() * 4.5)
		self:SetAngles(bodyAng)

		-- Bogey local-yaw: rotate each truck to match its own track tangent
		-- in body-local space. Subtle on straights, visible on curves.
		-- Scale by 0.5 so the trucks don't visibly over-pivot under the body —
		-- real bogeys have limited yaw freedom on their kingpins.
		local BOGEY_YAW_SCALE = 0.9
		if fDir and IsValid(self.FrontBogey) then
			local fTrackDir = fDir
			if self.TrainHead then fTrackDir = -fTrackDir end
			local fLocal = self:WorldToLocalAngles(fTrackDir:Angle())
			self.FrontBogey:SetLocalAngles(Angle(0, fLocal.y * BOGEY_YAW_SCALE + 180, 0))
		end
		if rDir and IsValid(self.RearBogey) then
			local rTrackDir = rDir
			if self.TrainHead then rTrackDir = -rTrackDir end
			local rLocal = self:WorldToLocalAngles(rTrackDir:Angle())
			self.RearBogey:SetLocalAngles(Angle(0, rLocal.y * BOGEY_YAW_SCALE, 0))
		end
	else
		-- Fallback: single-point sample if either bogey is off the path
		-- (e.g. at the very ends of a track segment).
		local vec, dir = Metrostroi.GetTrackPosition(path, self.Position)
		if vec and dir then
			local _, dir2 = Metrostroi.GetTrackPosition(path, self.Position - 5)
			if dir2 then dir = dir2 end
			if self.TrainHead then dir = -dir end
			self:SetPos(vec)
			self:SetAngles(dir:Angle())
		end
	end

	return node
end

function ENT:ThinkUpdateSignals(node)
	self.RestrictionTimeout = self.RestrictionTimeout or 0
	if CurTime() - self.RestrictionTimeout <= 0.50 then return end
	self.RestrictionTimeout = CurTime()
	if not node or self.TrainHead then return end

	local nextARS = Metrostroi.GetARSJoint(node, self.Position, true)
	local sigX, blocked
	if nextARS and IsValid(nextARS) then
		sigX = (nextARS.TrackPosition and nextARS.TrackPosition.x) or nextARS.ARSOffset
		blocked = nextARS.Red or nextARS.Occupied
	end

	if self.ObeyedRedX then
		if self.Position > self.ObeyedRedX + 4 then
			self.ObeyedRedX = nil
		elseif sigX and math.abs(sigX - self.ObeyedRedX) < 10 and not blocked then
			self.ObeyedRedX = nil
		end
	end
	if not self.ObeyedRedX and blocked and sigX and sigX > self.Position + 12 then
		self.ObeyedRedX = sigX
	end

	self.RedLightDistance = nil
	if self.ObeyedRedX and (not self.PlatformEdgeX or self.ObeyedRedX < self.PlatformEdgeX) then
		local dX = self.ObeyedRedX - self.Position
		if dX < 400 then self.RedLightDistance = dX end
	end

	self:ThinkResetIntervalClocks()
end

function ENT:ThinkResetIntervalClocks()
	if self.TrainHead then return end
	for _, clock in pairs(ents.FindByClass("gmod_track_clock_interval")) do
		if IsValid(clock) and clock.NoInterval ~= 1 and not clock.IntervalReset then
			if clock:GetPos():Distance(self:GetPos()) < 160 then
				clock:SetIntervalResetTime(Metrostroi.GetSyncTime()
					- (GetGlobalFloat("MetrostroiTY") or 0) + Metrostroi.GetTimedT())
				clock.SensingTime = Metrostroi.GetSyncTime()
				clock.IntervalReset = true
			end
		end
	end
end

function ENT:Think()
	self:ThinkUpdateDeltaTime()
	self:ThinkEnsureRoute()
	self:ThinkSpawnSnap()
	self:NextThink(CurTime())

	local dT = self.DeltaTime
	self:ThinkUpdateALSCoil(dT)

	local path = self:ThinkResolvePath()
	if not path then return true end

	self:ThinkUpdateRoute(path)
	if not self:ThinkDriveTrain(dT) then return end

	self:ThinkUpdateLights()
	self:ThinkUpdatePneumatics(dT)
	self:ThinkUpdateDoors()
	self:ThinkSyncBogeys()

	local node = self:ThinkUpdateTrackPose(path)
	self:ThinkUpdateSignals(node)

	if not self.TrainHead then
		self:UpdateTrainAhead()
	end

	return true
end
