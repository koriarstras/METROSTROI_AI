ENT.Type            = "anim"
ENT.Base            = "gmod_subway_base"

ENT.PrintName       = "AI train"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""
ENT.Category        = "Metrostroi (trains)"

ENT.Spawnable       = true
ENT.AdminSpawnable  = false

function ENT:PassengerCapacity()
	return 300
end

function ENT:GetStandingArea()
	return Vector(-450, -30, -45), Vector(380, 30, -45)
end

function ENT:InitializeSystems()
	-- ALSCoil: ARS track-frequency pickup (F1–F6 → speed limit). Guarded so
	-- builds without the system still drive on defaults instead of erroring.
	if Metrostroi.Systems and Metrostroi.Systems["ALSCoil"] then
		self:LoadSystem("ALSCoil")
	end
end

--------------------------------------------------------------------------------
-- Sounds (shared so client precaches via base class recurePrecache)
--------------------------------------------------------------------------------

local ORIGIN = Vector(0, 0, 0)
local ROLLING_POS = { 480, 1e12, ORIGIN }

local function setLoopSound(ent, name, path, volume)
	ent.SoundNames[name] = { loop = true, path }
	ent.SoundPositions[name] = { ROLLING_POS[1], ROLLING_POS[2], ROLLING_POS[3], volume }
end

local function setPointSound(ent, name, sounds, dist, pos, volume)
	ent.SoundNames[name] = sounds
	ent.SoundPositions[name] = { dist, 1e9, pos, volume }
end

local function doorSoundPos(doorIndex, sideIndex)
	return Vector(338.0 - 230.1 * doorIndex + (1 - sideIndex) * 0.8, -65 * (1 - 2 * sideIndex), 0.761)
end

function ENT:InitializeSounds()
	self.BaseClass.InitializeSounds(self)

	local rolling = {
		{ "rolling_5",       "subway_trains/common/junk/junk_background3.wav",                    0.05 },
		{ "rolling_10",      "subway_trains/717/rolling/10_rolling.wav",                          0.10 },
		{ "rolling_40",      "subway_trains/717/rolling/40_rolling.wav",                          0.55 },
		{ "rolling_70",      "subway_trains/717/rolling/70_rolling.wav",                          0.60 },
		{ "rolling_80",      "subway_trains/717/rolling/80_rolling.wav",                          0.75 },
		{ "rolling_32",      "subway_trains/717/rolling/rolling_32.wav",                          0.20 },
		{ "rolling_68",      "subway_trains/717/rolling/rolling_68.wav",                          0.40 },
		{ "rolling_75",      "subway_trains/717/rolling/rolling_75.wav",                          0.80 },
		{ "rolling_low",     "subway_trains/717/rolling/rolling_outside_low.wav",                 0.60 },
		{ "rolling_medium1", "subway_trains/717/rolling/rolling_outside_medium1.wav",             0.90 },
		{ "rolling_medium2", "subway_trains/717/rolling/rolling_outside_medium2.wav",             0.90 },
		{ "rolling_high2",   "subway_trains/717/rolling/rolling_outside_high2.wav",               1.00 },
	}
	for _, row in ipairs(rolling) do
		setLoopSound(self, row[1], row[2], row[3])
	end

	for i = 0, 3 do
		for k = 0, 1 do
			local key = "door" .. i .. "x" .. k
			local pos = doorSoundPos(i, k)
			self.SoundNames[key .. "r"] = { loop = true, "subway_trains/common/door/door_roll.wav" }
			self.SoundPositions[key .. "r"] = { 150, 1e9, pos, 0.11 }
			self.SoundNames[key .. "o"] = {
				"subway_trains/common/door/door_open_end5.mp3",
				"subway_trains/common/door/door_open_end6.mp3",
				"subway_trains/common/door/door_open_end7.mp3",
			}
			self.SoundPositions[key .. "o"] = { 350, 1e9, pos, 2 }
			self.SoundNames[key .. "c"] = {
				"subway_trains/common/door/door_close_end.mp3",
				"subway_trains/common/door/door_close_end2.mp3",
				"subway_trains/common/door/door_close_end3.mp3",
				"subway_trains/common/door/door_close_end4.mp3",
				"subway_trains/common/door/door_close_end5.mp3",
			}
			self.SoundPositions[key .. "c"] = { 400, 1e9, pos, 2 }
		end
	end

	local valvePos = Vector(-420, 45, -30)
	self.SoundNames["vdol_on"]  = { "subway_trains/common/pneumatic/door_valve/VDO_on.mp3",  "subway_trains/common/pneumatic/door_valve/VDO2_on.mp3" }
	self.SoundNames["vdol_off"] = { "subway_trains/common/pneumatic/door_valve/VDO_off.mp3", "subway_trains/common/pneumatic/door_valve/VDO2_off.mp3" }
	self.SoundPositions["vdol_on"]  = { 300, 1e9, valvePos, 1 }
	self.SoundPositions["vdol_off"] = { 300, 1e9, valvePos, 0.4 }
	self.SoundNames["vdor_on"]  = self.SoundNames["vdol_on"]
	self.SoundNames["vdor_off"] = self.SoundNames["vdol_off"]
	self.SoundPositions["vdor_on"]  = self.SoundPositions["vdol_on"]
	self.SoundPositions["vdor_off"] = self.SoundPositions["vdol_off"]
	self.SoundNames["vdz_on"]  = {
		"subway_trains/common/pneumatic/door_valve/VDZ_on.mp3",
		"subway_trains/common/pneumatic/door_valve/VDZ2_on.mp3",
		"subway_trains/common/pneumatic/door_valve/VDZ3_on.mp3",
	}
	self.SoundNames["vdz_off"] = {
		"subway_trains/common/pneumatic/door_valve/VDZ_off.mp3",
		"subway_trains/common/pneumatic/door_valve/VDZ2_off.mp3",
		"subway_trains/common/pneumatic/door_valve/VDZ3_off.mp3",
	}
	self.SoundPositions["vdz_on"]  = { 60, 1e9, valvePos, 1 }
	self.SoundPositions["vdz_off"] = { 60, 1e9, valvePos, 0.4 }

	self.SoundNames["cab_door_open"]   = "subway_trains/common/door/cab/door_open.mp3"
	self.SoundNames["cab_door_close"]  = "subway_trains/common/door/cab/door_close.mp3"
	self.SoundNames["otsek_door_open"] = { "subway_trains/720/door/door_torec_open.mp3",  "subway_trains/720/door/door_torec_open2.mp3" }
	self.SoundNames["otsek_door_close"]= { "subway_trains/720/door/door_torec_close.mp3", "subway_trains/720/door/door_torec_close2.mp3" }

	setPointSound(self, "horn", {
		loop = 0.6,
		"subway_trains/common/pneumatic/horn/horn3_start.wav",
		"subway_trains/common/pneumatic/horn/horn3_loop.wav",
		"subway_trains/common/pneumatic/horn/horn3_end.wav",
	}, 1100, Vector(450, 0, -55), 1)

	self.SoundNames["ring_old"] = {
		loop = 0.15,
		"subway_trains/717/ring/ringo_start.wav",
		"subway_trains/717/ring/ringo_loop.wav",
		"subway_trains/717/ring/ringo_end.mp3",
	}
	self.SoundPositions["ring_old"] = { 60, 1e9, Vector(459, 6, 10), 0.35 }
end

--------------------------------------------------------------------------------
-- Visual prop tables (shared: server + client + listen-server)
--------------------------------------------------------------------------------

local ZERO_POS = Vector(0, 0, 0)
local ZERO_ANG = Angle(0, 0, 0)

local function prop(model, opts)
	opts = opts or {}
	return {
		model = model,
		pos   = opts.pos   or ZERO_POS,
		ang   = opts.ang   or ZERO_ANG,
		hide  = opts.hide,
		nohide = opts.nohide,
		hideseat = opts.hideseat,
		color = opts.color,
	}
end

ENT.AIVisualProps = {
	["81-717"] = {
		salon       = prop("models/metrostroi_train/81-717/interior_mvm.mdl", { hide = 2 }),
		cabine_mvm  = prop("models/metrostroi_train/81-717/cabine_mvm.mdl",  { hide = 2 }),
		mask22_mvm     = prop("models/metrostroi_train/81-717/mask_22.mdl",   { nohide = true }),
		mask222_mvm    = prop("models/metrostroi_train/81-717/mask_222m.mdl", { nohide = true }),
		mask222_mvm_wp = prop("models/metrostroi_train/81-717/mask_222.mdl",  { nohide = true }),
		mask141_mvm    = prop("models/metrostroi_train/81-717/mask_141.mdl",  { nohide = true }),
		Headlights22_1  = prop("models/metrostroi_train/81-717/lamps/headlights_22_group1.mdl",  { nohide = true }),
		Headlights22_2  = prop("models/metrostroi_train/81-717/lamps/headlights_22_group2.mdl",  { nohide = true }),
		Headlights222_1 = prop("models/metrostroi_train/81-717/lamps/headlights_222_group1.mdl", { nohide = true }),
		Headlights222_2 = prop("models/metrostroi_train/81-717/lamps/headlights_222_group2.mdl", { nohide = true }),
		Headlights141_1 = prop("models/metrostroi_train/81-717/lamps/headlights_141_group1.mdl", { nohide = true }),
		Headlights141_2 = prop("models/metrostroi_train/81-717/lamps/headlights_141_group2.mdl", { nohide = true }),
		RedLights       = prop("models/metrostroi_train/81-717/lamps/redlights.mdl", { nohide = true, color = Color(200, 200, 200) }),
		body_additional = prop("models/metrostroi_train/81-717/717_body_additional.mdl", { hide = 2 }),
		lamps1        = prop("models/metrostroi_train/81-717/lamps_type1.mdl",   { hide = 1.5 }),
		seats_new     = prop("models/metrostroi_train/81-717/couch_new.mdl",     { hide = 1.5 }),
		seats_new_cap = prop("models/metrostroi_train/81-717/couch_new_cap.mdl", { hideseat = 0.8 }),
		handrails_new = prop("models/metrostroi_train/81-717/handlers_new.mdl",  { hide = 1.5 }),
		door_torec   = prop("models/metrostroi_train/81-717/door_torec.mdl",  { pos = Vector(-472.5, 15.75, -2.7),    ang = Angle(0, -90, 0), hide = 2 }),
		door_cab     = prop("models/metrostroi_train/81-717/cab_door.mdl",    { pos = Vector(377.322, 28.267, -1.599), ang = Angle(0, -90, 0), hide = 2 }),
		door_cabine  = prop("models/metrostroi_train/81-717/door_cabine.mdl", { pos = Vector(443.493, 65.111, 0.277), ang = Angle(0, -90, 0), hide = 2 }),
		Lamp_RTM1    = prop("models/metrostroi_train/81-717/rtmlamp.mdl",      { pos = Vector(414.367, -32.450, 6.717), ang = Angle(0, 180, 0), hide = 2 }),
		body_classic     = prop("models/metrostroi_train/81-717/pult/body_classic.mdl",     { hide = 2.5, color = Color(255, 255, 255) }),
		pult_mvm_classic = prop("models/metrostroi_train/81-717/pult/pult_mvm_classic.mdl", { hideseat = 0.8, color = Color(255, 255, 255) }),
		Controller       = prop("models/metrostroi_train/81-717/kv_black.mdl",              { pos = Vector(435.928, 16.1, -15.04), ang = Angle(0, -90, -32), hideseat = 0.2 }),
		ars_mvm          = prop("models/metrostroi_train/81-717/pult/ars_round.mdl",        { hideseat = 0.8 }),
	},
	["81-714"] = {
		salon           = prop("models/metrostroi_train/81-717/interior_mvm_int.mdl",    { hide = 2 }),
		body_additional = prop("models/metrostroi_train/81-717/714_body_additional.mdl", { hide = 2 }),
		lamps1          = prop("models/metrostroi_train/81-717/lamps_type1_int.mdl",     { hide = 1.5 }),
		seats_new       = prop("models/metrostroi_train/81-717/couch_new_int.mdl",       { hide = 1.5 }),
		handrails_new   = prop("models/metrostroi_train/81-717/handlers_new_int.mdl",    { hide = 2 }),
		door_torec1     = prop("models/metrostroi_train/81-717/door_torec.mdl", { pos = Vector(459.2, -15.9, -2.7),  ang = Angle(0, 89.5, 0), hide = 2 }),
		door_torec2     = prop("models/metrostroi_train/81-717/door_torec.mdl", { pos = Vector(-472.5, 15.75, -2.7), ang = Angle(0, -90, 0),  hide = 2 }),
	},
}

-- 8 rigid passenger doors per wagon (mirrored leaves per side)
local DOOR_X = { 338.445, 108.324, -121.682, -351.531 }

local function addPassengerDoors(propTable)
	for i = 0, 3 do
		local x = DOOR_X[i + 1]
		propTable["door" .. i .. "x1"] = prop(
			"models/metrostroi_train/81-717/81-717_doors_pos" .. (i + 1) .. ".mdl",
			{ pos = Vector(x, 65.164, 0.807), ang = Angle(0, -90, 0), hide = 2.0 }
		)
		propTable["door" .. i .. "x0"] = prop(
			"models/metrostroi_train/81-717/81-717_doors_pos" .. (4 - i) .. ".mdl",
			{ pos = Vector(x, -65.164, 0.807), ang = Angle(0, 90, 0), hide = 2.0 }
		)
	end
end

addPassengerDoors(ENT.AIVisualProps["81-717"])
addPassengerDoors(ENT.AIVisualProps["81-714"])

function ENT:ApplyVisualProps()
	local trainType = self:GetNW2String("TrainType")
	if trainType == "" then return false end

	local src = self.AIVisualProps[trainType] or self.AIVisualProps["81-714"]
	self.ClientProps = {}
	for k, v in pairs(src) do
		self.ClientProps[k] = v
	end
	return true
end
