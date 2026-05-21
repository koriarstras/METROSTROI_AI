AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--------------------------------------------------------------------------------
ENT.ClientProps = {}

function ENT:Initialize()
	-- Defined train information
	self.SubwayTrain = {
		Type = "AI",
		Name = "",
	}
	if not self.TrainType then self.TrainType = "81-717" end
	-- Set model and initialize
	self.NoPhysics = true
	if self.TrainType == "81-717" 
	then self.MaskType = 10
    self.LampType = 1
    self:SetModel("models/metrostroi_train/81-717/81-717_mvm.mdl")
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self.BaseClass.Initialize(self)
    self:SetPos(self:GetPos() + Vector(0,0,140)) end
	if self.TrainType == "81-714" 
	then self:SetModel("models/metrostroi_train/81-717/81-717_mvm_int.mdl")
    self.BaseClass.Initialize(self)
    self:SetPos(self:GetPos() + Vector(0,0,140)) end
	self.BaseClass.Initialize(self)

	-- Create bogeys
    if Metrostroi.BogeyOldMap then
        self.FrontBogey = self:CreateBogey(Vector( 317-5,0,-84),Angle(0,180,0),true,"717")
        self.RearBogey  = self:CreateBogey(Vector(-317+0,0,-84),Angle(0,0,0),false,"717")
        self.FrontCouple = self:CreateCouple(Vector( 419.5,0,-62),Angle(0,0,0),true,"717")
        self.RearCouple  = self:CreateCouple(Vector(-419.5-6.545,0,-62),Angle(0,180,0),false,"717")
    else
        self.FrontBogey = self:CreateBogey(Vector( 317-11,0,-80),Angle(0,180,0),true,"717")
        self.RearBogey  = self:CreateBogey(Vector(-317+0,0,-80),Angle(0,0,0),false,"717")
        self.RearCouple  = self:CreateCouple(Vector(-421,0,-66),Angle(0,180,0),false,"717")
        self.FrontCouple = self:CreateCouple(Vector( 410-3,0,-66),Angle(0,0,0),true,"717")
    end

	-- Seats
	if self.TrainType == "81-717" then 
		self.DriverSeat = self:CreateSeat("driver",Vector(417,0,-22.5))
		 self.DriverSeat:SetColor(Color(0,0,0,0))
		 self.DriverSeat:SetRenderMode(RENDERMODE_TRANSALPHA)
		--self.InstructorsSeat = self:CreateSeat("instructor",Vector(410,35,-28))
		--self.ExtraSeat = self:CreateSeat("instructor",Vector(410,-35,-28))
	end
	--[[
	for i=1,1 do --17
		local pos = Vector(280-(i-1)*30-math.floor((i-1)/5)*80,-47,-32)
		local p1 = self:CreateSeat("passenger",pos,Angle(0,90,0))
		pos.y = -pos.y
		local p2 = self:CreateSeat("passenger",pos,Angle(0,270,0))
	end]]

	-- Setup door positions
	self.LeftDoorPositions = {}
	self.RightDoorPositions = {}
	for i=0,3 do
		table.insert(self.LeftDoorPositions,Vector(353.0 - 35*0.5 - 231*i,65,-1.8))
		table.insert(self.RightDoorPositions,Vector(353.0 - 35*0.5 - 231*i,-65,-1.8))
	end
	
		-- Find SOME sort of route
    local route
    for k,v in pairs(Metrostroi.AIConfiguration or {}) do
        if not route then route = k end
    end

    -- Initial setup - use defaults if no config exists
    if not self.Route then self.Route = route or "default" end
    if (not self.PathID) then
        if route and Metrostroi.AIConfiguration and Metrostroi.AIConfiguration[route] then
            self.PathID = Metrostroi.AIConfiguration[route].Path
        else
            self.PathID = math.random(1,2)  -- Default path
        end
    end

    self.Position = self.Position or 100
    self.Velocity = 0
    self.RheostatPosition = 0

	-- Lights
	if self.TrainType == "81-717" then 
		self.Lights = {
			-- Head
			[1] = { "headlight",		Vector(465,0,-20), Angle(0,0,0), Color(176,161,132), fov = 100 },
			[2] = { "glow",				Vector(460, 51,-23), Angle(0,0,0), Color(255,255,255), brightness = 2 },
			[3] = { "glow",				Vector(460,-51,-23), Angle(0,0,0), Color(255,255,255), brightness = 2 },
			[4] = { "glow",				Vector(460,-8, 55), Angle(0,0,0), Color(255,255,255), brightness = 0.3 },
			[5] = { "glow",				Vector(460,-8, 55), Angle(0,0,0), Color(255,255,255), brightness = 0.3 },
			[6] = { "glow",				Vector(460, 2, 55), Angle(0,0,0), Color(255,255,255), brightness = 0.3 },
			[7] = { "glow",				Vector(460, 2, 55), Angle(0,0,0), Color(255,255,255), brightness = 0.3 },
				
			-- Reverse
			[8] = { "light",			Vector(458,-45, 55), Angle(0,0,0), Color(255,0,0),     brightness = 10, scale = 1.0 },
			[9] = { "light",			Vector(458, 45, 55), Angle(0,0,0), Color(255,0,0),     brightness = 10, scale = 1.0 },
				
			-- Cabin
			[10] = { "dynamiclight",	Vector( 420, 0, 35), Angle(0,0,0), Color(255,255,255), brightness = 0.1, distance = 550 },
				
			-- Interior
			[12] = { "dynamiclight",	Vector(   0, 0, 5), Angle(0,0,0), Color(255,255,255), brightness = 3, distance = 400 },
				
			-- Side lights
			[14] = { "light",			Vector(-50, 68, 54), Angle(0,0,0), Color(255,0,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[15] = { "light",			Vector(4,   68, 54), Angle(0,0,0), Color(150,255,255), brightness = 0.6, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[16] = { "light",			Vector(1,   68, 54), Angle(0,0,0), Color(0,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[17] = { "light",			Vector(-2,  68, 54), Angle(0,0,0), Color(255,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
				
			[18] = { "light",			Vector(-50, -69, 54), Angle(0,0,0), Color(255,0,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[19] = { "light",			Vector(5,   -69, 54), Angle(0,0,0), Color(150,255,255), brightness = 0.6, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[20] = { "light",			Vector(2,   -69, 54), Angle(0,0,0), Color(0,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[21] = { "light",			Vector(-1,  -69, 54), Angle(0,0,0), Color(255,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
		}
	end
	if self.TrainType == "81-714" then
		self.Lights = {
			-- Interior
			[12] = { "dynamiclight",	Vector(   0, 0, 5), Angle(0,0,0), Color(255,255,255), brightness = 3, distance = 400 },
				
			-- Side lights
			[14] = { "light",			Vector(-50, 68, 54), Angle(0,0,0), Color(255,0,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[15] = { "light",			Vector(4,   68, 54), Angle(0,0,0), Color(150,255,255), brightness = 0.6, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[16] = { "light",			Vector(1,   68, 54), Angle(0,0,0), Color(0,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[17] = { "light",			Vector(-2,  68, 54), Angle(0,0,0), Color(255,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
				
			[18] = { "light",			Vector(-50, -69, 54), Angle(0,0,0), Color(255,0,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[19] = { "light",			Vector(5,   -69, 54), Angle(0,0,0), Color(150,255,255), brightness = 0.6, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[20] = { "light",			Vector(2,   -69, 54), Angle(0,0,0), Color(0,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
			[21] = { "light",			Vector(-1,  -69, 54), Angle(0,0,0), Color(255,255,0), brightness = 0.5, scale = 0.10, texture = "models/metrostroi_signals/signal_sprite_002.vmt" },
		}	
	end

	-- Prop-protection related
	if CPPI and IsValid(self.Owner) then
		self:CPPISetOwner(self.Owner)
	end
	-- Spawn a dummy consist (auto-detect wagon count from shortest platform)
	if (self.TrainType == "81-717") and (not self.TrainHead) then
		local WAGON_LEN = 18
		local numWagons = 5
		local minLength = math.huge
		for _, stationData in pairs(Metrostroi.Stations or {}) do
			for _, platformData in pairs(stationData) do
				if platformData.length and platformData.length > 0 then
					if platformData.length < minLength then
						minLength = platformData.length
					end
				end
			end
		end
		if minLength ~= math.huge then
			numWagons = math.floor(minLength / WAGON_LEN)
			numWagons = math.max(3, math.min(8, numWagons))
		end
		self.NumWagons = numWagons
		print(Format("[AI] Spawning %d-wagon consist (shortest platform: %.1f m)", numWagons, minLength == math.huge and -1 or minLength))

		for i=2,numWagons do
			local ent = ents.Create("gmod_subway_ai")
			if i == numWagons
			then ent.TrainType = "81-717"
			else ent.TrainType = "81-714"
			end
			ent.TrainIndex = i
			ent.TrainHead = self
			ent.Owner = self.Owner
			ent:Spawn()
			table.insert(self.TrainEntities,ent)
		end
	end
	--self:Remove()
	-- Type
	self:SetNW2String("TrainType",self.TrainType)
	-- Tell the client whether this car is the REAR head of the consist
	-- (red lights on, headlights off) vs. the FRONT head (vice versa).
	-- Middle 81-714 cars don't have these props so the flag is harmless.
	self:SetNW2Bool("IsRearCar", self.TrainHead ~= nil)

	-- Start empty — passengers board at stations and alight further down the
	-- line. The platform's boarding system drives this NW2Float from here on
	-- via train:BoardPassengers().
	self:SetNW2Float("PassengerCount", 0)

	-- Network visual configuration to clients.
	-- MaskType=3 → mask222_mvm (the standard M-logo face shown in the reference image).
	-- LampType=1 → first lamp variant.
	-- Texture names match the default 81-717 skins so the prop materials look right.
	self:SetNW2Int("MaskType", 3)
	self:SetNW2Int("LampType", 1)
	self:SetNW2Int("SeatType", 1)
	self:SetNW2Int("KVType", 1)
	self:SetNW2Bool("NewBortlamps", true)
	self:SetNW2String("Texture",    "Def_717MSKBlue")
	self:SetNW2String("PassTexture","Def_717MSKWhite")
	self:SetNW2String("CabTexture", "Def_HammeriteG")
	-- Headlights packed bools: front head only, rear head off
	if self.TrainHead == nil and self.TrainType == "81-717" then
		self:SetPackedBool("Headlights1", true)
		self:SetPackedBool("Headlights2", true)
	end
end

--[[concommand.Add("metrostroi_ai_spawn", function(ply, _, args)
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
end)]]--

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

	-- Get speed limit from ALS_ARS. The system can be absent (failed to load,
	-- or a Metrostroi build without it) — fall back to safe defaults so the
	-- AI still drives instead of erroring.
	local ars = self.ALS_ARS
	local speedLimit = ars and ars.SpeedLimit or 0
	local nextLimit  = ars and ars.NextLimit  or 0
	local targetSpeed = nextLimit
	if nextLimit == 0 then targetSpeed = speedLimit end

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

	-- ARS attention pedal
	if ars then
		ars.AttentionPedal = ars.LVD and true or false
		if speedLimit == 0 then ars.AttentionPedal = true end
	end

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

function ENT:Think()
	 -- Basic think loop
    self.PrevTime = self.PrevTime or CurTime()
    self.DeltaTime = (CurTime() - self.PrevTime)
    self.PrevTime = CurTime()
    -- Clamp the timestep. On a server-frame hitch DeltaTime can spike to a
    -- large value; integrating physics with that makes the train lurch a long
    -- way in one frame (a visible teleport/stutter). Capping it means a hitch
    -- just slows the train slightly for that frame instead of jumping it.
    if self.DeltaTime > 0.1 then self.DeltaTime = 0.1 end
    if self.DeltaTime < 0  then self.DeltaTime = 0   end
    
    -- Initialize route/path on first think if not set
    if (not self.Route or not self.PathID) and not self.InitializeAttempted then
        self.InitializeAttempted = true
        local route
        for k,v in pairs(Metrostroi.AIConfiguration) do
            if not route then route = k end
        end
        if route and Metrostroi.AIConfiguration[route] then
            self.Route = route
            self.PathID = Metrostroi.AIConfiguration[route].Path
        end
    end

    -- Snap to whatever track the train was actually SPAWNED on. Without this
    -- the AI just forces PathID = random(1,2) + Position = 100, which on
    -- depot / branch maps (e.g. crossline_n4a) drops it onto a random short
    -- siding or off the rails entirely ("spawns in weird places, won't go to
    -- the track"). GetPositionOnTrack finds the nearest path + offset to the
    -- spawn point so the train starts exactly where it was placed.
    -- Retried each tick until it succeeds, since the rail network may not be
    -- built yet on the very first think (and given up on after ~10 s).
    if not self.SpawnSnapped and not self.TrainHead and Metrostroi.GetPositionOnTrack then
        self._SnapTries = (self._SnapTries or 0) + 1
        local results = Metrostroi.GetPositionOnTrack(self:GetPos(), self:GetAngles(),
            { z_pad = 384, radius = 600 })
        local best = results and results[1]
        if best and best.path and best.path.id then
            self.PathID       = best.path.id
            self.Position     = best.x
            self.Route        = self.Route or "default"
            self.SpawnSnapped = true
        elseif self._SnapTries > 600 then
            self.SpawnSnapped = true   -- give up: spawned nowhere near a track
        end
    end
    
    
	--self:RecvPackedData()
	-- Run every tick so position interpolation is smooth (was 0.10 = 10Hz jitter)
	self:NextThink(CurTime())

	local dT = self.DeltaTime

	-- Heavy ALS/ARS simulation only at 10 Hz - decisions don't need to be faster
	if (self.TrainType == "81-717") and (not self.TrainHead) and self.ALS_ARS then
		self.ALS_ARS_AccumT = (self.ALS_ARS_AccumT or 0) + dT
		if self.ALS_ARS_AccumT >= 0.1 then
			self.ALS_ARS:Think(self.ALS_ARS_AccumT, 1)
			self.ALS_ARS_AccumT = 0
		end
	end

	 	-- Select path
    if (not self.PathID) or (not self.Route) then return true end
    local path = Metrostroi.Paths[self.PathID]
    -- The PathID may point to a path that does not exist on this map, or the
    -- rail network may not be built yet. Without this guard every downstream
    -- GetTrackPosition(path, ...) call indexes a nil path and errors.
    if not path then
        -- Try to fall back to any valid path so the train can still run.
        for pid, p in pairs(Metrostroi.Paths or {}) do
            if p then self.PathID = pid; path = p; break end
        end
        if not path then return true end
    end
    local config = Metrostroi.AIConfiguration[self.Route]
    
    -- If config doesn't exist, skip route switching
    if config and (self.Position > config.EndPosition) then
        self.Route = config.NextRoute
        config = Metrostroi.AIConfiguration[self.Route]
        if config then
            self.PathID = config.Path
            self.Position = config.SpawnPosition
        end
        self.Velocity = 0
        self.Schedule = nil
        self.NoStation = false
    elseif not config and path then
        -- No AIConfiguration: auto-reverse when train reaches the physical end of the track
        local lastNode = path[#path]
        if lastNode and self.Position > lastNode.x then
            -- Spawn far enough into the new path so all wagons fit on track
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
    end
	--self.Velocity = 0

	----------------------------------------------------------------------------
	-- If needed, update train physics and AI
	if not self.TrainHead then
		self:DoAI(dT)
		self:DoPhysics(dT)
	else
		if not IsValid(self.TrainHead) then
			SafeRemoveEntity(self)
			return
		end

		self.Route = self.TrainHead.Route
		self.PathID = self.TrainHead.PathID
		-- 18.35 m car-to-car spacing, plus a 1 m offset for the whole tail so
		-- the head(717)→car-2 gap matches the 714↔714 gaps — the cab car sits
		-- slightly differently and otherwise looks ~1 m too close to car 2.
		self.Position = self.TrainHead.Position - 18.39*(self.TrainIndex-1) - .13
		self.Velocity = self.TrainHead.Velocity
		self.MotorPower = self.TrainHead.MotorPower
		self.PneumoForce = self.TrainHead.PneumoForce
	end


	----------------------------------------------------------------------------	
	-- Lighting
	if self.TrainType == "81-717" then
		self:SetLightPower(1, self.TrainHead == nil)
		self:SetLightPower(2, self.TrainHead == nil)
		self:SetLightPower(3, self.TrainHead == nil)
		self:SetLightPower(4, self.TrainHead == nil)
		self:SetLightPower(5, self.TrainHead == nil)
		self:SetLightPower(6, self.TrainHead == nil)
		self:SetLightPower(7, self.TrainHead == nil)
		self:SetLightPower(8, self.TrainHead ~= nil)
		self:SetLightPower(9, self.TrainHead ~= nil)
		self:SetLightPower(10, (CurTime() % 60) > 0.1)
		self:SetLightPower(12, (CurTime() % 60) > 0.1)
	end
	if self.TrainType == "81-714" then
		self:SetLightPower(12, (CurTime() % 60) > 0.1)
	end
	-- Pneumatic brakes
	self.PneumaticPressure = self.PneumaticPressure or 0
	self.PneumaticPressure_dPdT = self.PneumaticPressure_dPdT or 0
	if self.Pneumo 
	then self.PneumaticPressure_dPdT = 0.65*(1.5 - self.PneumaticPressure)
	else self.PneumaticPressure_dPdT = 0.65*(0.0 - self.PneumaticPressure)
	end
	self.PneumaticPressure = self.PneumaticPressure + self.PneumaticPressure_dPdT*dT

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
	self:SetPackedBool(52,1)
	self:SetPackedBool(39,(self.ALS_ARS and self.ALS_ARS.LVD) and (not self.TrainHead) or false)
	
	-- Update state of all objects and sounds
	self.Speed = math.abs(self.Velocity/0.277778)
	self.FrontBogey.Speed = self.Speed
	self.RearBogey.Speed = self.Speed
	self.FrontBogey.MotorPower = self.MotorPower
	self.RearBogey.MotorPower = self.MotorPower
	self.FrontBogey.BrakeCylinderPressure_dPdT = -self.PneumaticPressure_dPdT
	self.RearBogey.BrakeCylinderPressure_dPdT = -self.PneumaticPressure_dPdT
	self.FrontBogey.BrakeSqueal = math.min(1,(3*math.abs(self.PneumoForce or 0))^1)
	self.RearBogey.BrakeSqueal = math.min(1,(3*math.abs(self.PneumoForce or 0))^1)
	

	----------------------------------------------------------------------------
	-- Update train position — proper bogey articulation.
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
	----------------------------------------------------------------------------
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

	-- Signal-aspect check at 2 Hz. A signal halts the train when it is showing
	-- a stop aspect (.Red) or its block is occupied (.Occupied) — the latter
	-- is computed by the route logic's IsTrackOccupied(), which detects EVERY
	-- train on the section (AI bots, player trains, anything). This is proper
	-- block signalling: the AI stops at the red, and the moment the train
	-- ahead clears the block the signal opens and the AI proceeds.
	self.RestrictionTimeout = self.RestrictionTimeout or 0
	if (CurTime() - self.RestrictionTimeout) > 0.50 then
		self.RestrictionTimeout = CurTime()
		if node and (not self.TrainHead) then
			local nextARS = Metrostroi.GetARSJoint(node, self.Position, true)
			local sigX, blocked
			if nextARS and IsValid(nextARS) then
				sigX    = (nextARS.TrackPosition and nextARS.TrackPosition.x) or nextARS.ARSOffset
				blocked = nextARS.Red or nextARS.Occupied
			end

			-- Latched-red logic. The AI commits to ONE red signal at a time:
			--  • Release the latch once we have rolled past the signal, or
			--    once it is no longer reporting blocked (the block cleared).
			--  • Latch a NEW red only if it is far enough ahead (> 12 m) to
			--    actually brake for. This is the key fix for "train passes a
			--    light, the light turns red behind it, train brakes": a signal
			--    that goes red only after we have already reached it is never
			--    within the 12 m window, so it is never latched or obeyed.
			if self.ObeyedRedX then
				if self.Position > self.ObeyedRedX + 4 then
					-- Definitely rolled past the signal → release.
					self.ObeyedRedX = nil
				elseif sigX and math.abs(sigX - self.ObeyedRedX) < 10 and not blocked then
					-- We got a fresh reading for THAT signal and it is no
					-- longer blocked → the block cleared → release.
					self.ObeyedRedX = nil
				end
				-- Otherwise (GetARSJoint returned nil, or a different signal)
				-- keep the latch — never drop a red on an uncertain reading.
			end
			if not self.ObeyedRedX and blocked and sigX and sigX > self.Position + 12 then
				self.ObeyedRedX = sigX
			end

			self.RedLightDistance = nil
			if self.ObeyedRedX and ((not self.PlatformEdgeX) or (self.ObeyedRedX < self.PlatformEdgeX)) then
				local dX = self.ObeyedRedX - self.Position
				if dX < 400 then self.RedLightDistance = dX end
			end
		end

		-- Reset any interval clock we're passing. The clock's own train
		-- sensing relies on a downward trace, which misses the AI body
		-- (NoPhysics) — so on maps where the clock has no linked signal it
		-- never counts. Triggering it directly here makes the 1:30 interval
		-- display work on every map.
		if not self.TrainHead then
			for _, clock in pairs(ents.FindByClass("gmod_track_clock_interval")) do
				if IsValid(clock) and clock.NoInterval ~= 1 and not clock.IntervalReset then
					if clock:GetPos():Distance(self:GetPos()) < 160 then
						clock:SetIntervalResetTime(Metrostroi.GetSyncTime()
							- (GetGlobalFloat("MetrostroiTY") or 0) + Metrostroi.GetTimedT())
						clock.SensingTime   = Metrostroi.GetSyncTime()
						clock.IntervalReset = true
					end
				end
			end
		end
	end

	-- Train-ahead check EVERY tick (cheap, must react fast at 60+ km/h)
	if not self.TrainHead then
		self:UpdateTrainAhead()
	end


--	self:SendPackedData()
	return true
end
