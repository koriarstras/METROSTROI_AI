ENT.Type            = "anim"
ENT.Base            = "gmod_subway_base"

ENT.PrintName       = "AI train"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""
ENT.Category		= "Metrostroi (trains)"

ENT.Spawnable       = true
ENT.AdminSpawnable  = false

function ENT:PassengerCapacity()
	return 300
end

function ENT:GetStandingArea()
	return Vector(-450,-30,-45),Vector(380,30,-45)
end

function ENT:InitializeSystems()
	-- Load the ARS speed-control system only if this Metrostroi build actually
	-- registers it. On builds where "ALS_ARS" is absent, LoadSystem would
	-- ErrorNoHalt ("No system defined: ALS_ARS"); the AI is fully guarded for
	-- a nil self.ALS_ARS and just drives with default speed limits instead.
	if Metrostroi.Systems and Metrostroi.Systems["ALS_ARS"] then
		self:LoadSystem("ALS_ARS")
	end
end

--------------------------------------------------------------------------------
-- Sounds — same essentials the real 81-717_mvm uses. Defined in shared.lua so
-- the client picks them up via the base class's recurePrecache during init.
-- Keeps the bulky ELECTRIC/RELAY/PNM sound table out of the AI to save memory.
--------------------------------------------------------------------------------
function ENT:InitializeSounds()
	self.BaseClass.InitializeSounds(self)

	-- Rolling (speed-banded)
	self.SoundNames["rolling_5"]    = {loop=true, "subway_trains/common/junk/junk_background3.wav"}
	self.SoundNames["rolling_10"]   = {loop=true, "subway_trains/717/rolling/10_rolling.wav"}
	self.SoundNames["rolling_40"]   = {loop=true, "subway_trains/717/rolling/40_rolling.wav"}
	self.SoundNames["rolling_70"]   = {loop=true, "subway_trains/717/rolling/70_rolling.wav"}
	self.SoundNames["rolling_80"]   = {loop=true, "subway_trains/717/rolling/80_rolling.wav"}
	self.SoundPositions["rolling_5"]  = {480,1e12,Vector(0,0,0),0.05}
	self.SoundPositions["rolling_10"] = {480,1e12,Vector(0,0,0),0.1}
	self.SoundPositions["rolling_40"] = {480,1e12,Vector(0,0,0),0.55}
	self.SoundPositions["rolling_70"] = {480,1e12,Vector(0,0,0),0.60}
	self.SoundPositions["rolling_80"] = {480,1e12,Vector(0,0,0),0.75}
	self.SoundNames["rolling_32"]  = {loop=true, "subway_trains/717/rolling/rolling_32.wav"}
	self.SoundNames["rolling_68"]  = {loop=true, "subway_trains/717/rolling/rolling_68.wav"}
	self.SoundNames["rolling_75"]  = {loop=true, "subway_trains/717/rolling/rolling_75.wav"}
	self.SoundPositions["rolling_32"] = {480,1e12,Vector(0,0,0),0.2}
	self.SoundPositions["rolling_68"] = {480,1e12,Vector(0,0,0),0.4}
	self.SoundPositions["rolling_75"] = {480,1e12,Vector(0,0,0),0.8}
	self.SoundNames["rolling_low"]      = {loop=true, "subway_trains/717/rolling/rolling_outside_low.wav"}
	self.SoundNames["rolling_medium1"]  = {loop=true, "subway_trains/717/rolling/rolling_outside_medium1.wav"}
	self.SoundNames["rolling_medium2"]  = {loop=true, "subway_trains/717/rolling/rolling_outside_medium2.wav"}
	self.SoundNames["rolling_high2"]    = {loop=true, "subway_trains/717/rolling/rolling_outside_high2.wav"}
	self.SoundPositions["rolling_low"]     = {480,1e12,Vector(0,0,0),0.6}
	self.SoundPositions["rolling_medium1"] = {480,1e12,Vector(0,0,0),0.9}
	self.SoundPositions["rolling_medium2"] = {480,1e12,Vector(0,0,0),0.9}
	self.SoundPositions["rolling_high2"]   = {480,1e12,Vector(0,0,0),1.0}

	-- Door sounds (per-doorway open/close/roll)
	local function _GetDoorSndPos(i, k)
		return Vector(338.0 - 230.1*i + (1-k)*0.8, -65*(1-2*k), 0.761)
	end
	for i = 0, 3 do
		for k = 0, 1 do
			self.SoundNames["door"..i.."x"..k.."r"] = {loop=true, "subway_trains/common/door/door_roll.wav"}
			self.SoundPositions["door"..i.."x"..k.."r"] = {150,1e9,_GetDoorSndPos(i,k),0.11}
			self.SoundNames["door"..i.."x"..k.."o"] = {
				"subway_trains/common/door/door_open_end5.mp3",
				"subway_trains/common/door/door_open_end6.mp3",
				"subway_trains/common/door/door_open_end7.mp3",
			}
			self.SoundPositions["door"..i.."x"..k.."o"] = {350,1e9,_GetDoorSndPos(i,k),2}
			self.SoundNames["door"..i.."x"..k.."c"] = {
				"subway_trains/common/door/door_close_end.mp3",
				"subway_trains/common/door/door_close_end2.mp3",
				"subway_trains/common/door/door_close_end3.mp3",
				"subway_trains/common/door/door_close_end4.mp3",
				"subway_trains/common/door/door_close_end5.mp3",
			}
			self.SoundPositions["door"..i.."x"..k.."c"] = {400,1e9,_GetDoorSndPos(i,k),2}
		end
	end
	-- Pneumatic door valves
	self.SoundNames["vdol_on"]  = {"subway_trains/common/pneumatic/door_valve/VDO_on.mp3","subway_trains/common/pneumatic/door_valve/VDO2_on.mp3"}
	self.SoundNames["vdol_off"] = {"subway_trains/common/pneumatic/door_valve/VDO_off.mp3","subway_trains/common/pneumatic/door_valve/VDO2_off.mp3"}
	self.SoundPositions["vdol_on"]  = {300,1e9,Vector(-420, 45,-30),1}
	self.SoundPositions["vdol_off"] = {300,1e9,Vector(-420, 45,-30),0.4}
	self.SoundNames["vdor_on"]  = self.SoundNames["vdol_on"]
	self.SoundNames["vdor_off"] = self.SoundNames["vdol_off"]
	self.SoundPositions["vdor_on"]  = self.SoundPositions["vdol_on"]
	self.SoundPositions["vdor_off"] = self.SoundPositions["vdol_off"]
	self.SoundNames["vdz_on"]  = {"subway_trains/common/pneumatic/door_valve/VDZ_on.mp3","subway_trains/common/pneumatic/door_valve/VDZ2_on.mp3","subway_trains/common/pneumatic/door_valve/VDZ3_on.mp3"}
	self.SoundNames["vdz_off"] = {"subway_trains/common/pneumatic/door_valve/VDZ_off.mp3","subway_trains/common/pneumatic/door_valve/VDZ2_off.mp3","subway_trains/common/pneumatic/door_valve/VDZ3_off.mp3"}
	self.SoundPositions["vdz_on"]  = {60,1e9,Vector(-420, 45,-30),1}
	self.SoundPositions["vdz_off"] = {60,1e9,Vector(-420, 45,-30),0.4}

	-- Cab door & end-face (otsek)
	self.SoundNames["cab_door_open"]   = "subway_trains/common/door/cab/door_open.mp3"
	self.SoundNames["cab_door_close"]  = "subway_trains/common/door/cab/door_close.mp3"
	self.SoundNames["otsek_door_open"] = {"subway_trains/720/door/door_torec_open.mp3","subway_trains/720/door/door_torec_open2.mp3"}
	self.SoundNames["otsek_door_close"]= {"subway_trains/720/door/door_torec_close.mp3","subway_trains/720/door/door_torec_close2.mp3"}

	-- Horn
	self.SoundNames["horn"] = {loop=0.6, "subway_trains/common/pneumatic/horn/horn3_start.wav","subway_trains/common/pneumatic/horn/horn3_loop.wav","subway_trains/common/pneumatic/horn/horn3_end.wav"}
	self.SoundPositions["horn"] = {1100,1e9,Vector(450,0,-55),1}

	-- Departure ringer (the classic "соблюдайте интервал" alarm chime)
	self.SoundNames["ring_old"] = {loop=0.15, "subway_trains/717/ring/ringo_start.wav","subway_trains/717/ring/ringo_loop.wav","subway_trains/717/ring/ringo_end.mp3"}
	self.SoundPositions["ring_old"] = {60,1e9,Vector(459,6,10),0.35}
end

--------------------------------------------------------------------------------
-- Visual prop tables (defined in shared.lua so both server and client load
-- them — Garry's Mod listen-server setups mean the same process renders too).
-- Only the client actually instantiates these as CSEnts; the server keeps them
-- for reference and so init.lua can introspect them if needed.
--------------------------------------------------------------------------------
ENT.AIVisualProps = {
	["81-717"] = {
		-- Interior shell + cabin
		salon       = { model = "models/metrostroi_train/81-717/interior_mvm.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 2 },
		cabine_mvm  = { model = "models/metrostroi_train/81-717/cabine_mvm.mdl",  pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 2 },
		-- All mask variants (toggled by MaskType in cl_init.lua Think)
		mask22_mvm     = { model = "models/metrostroi_train/81-717/mask_22.mdl",   pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		mask222_mvm    = { model = "models/metrostroi_train/81-717/mask_222m.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		mask222_mvm_wp = { model = "models/metrostroi_train/81-717/mask_222.mdl",  pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		mask141_mvm    = { model = "models/metrostroi_train/81-717/mask_141.mdl",  pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		-- Headlights (one pair shown per mask)
		Headlights22_1  = { model = "models/metrostroi_train/81-717/lamps/headlights_22_group1.mdl",  pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		Headlights22_2  = { model = "models/metrostroi_train/81-717/lamps/headlights_22_group2.mdl",  pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		Headlights222_1 = { model = "models/metrostroi_train/81-717/lamps/headlights_222_group1.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		Headlights222_2 = { model = "models/metrostroi_train/81-717/lamps/headlights_222_group2.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		Headlights141_1 = { model = "models/metrostroi_train/81-717/lamps/headlights_141_group1.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		Headlights141_2 = { model = "models/metrostroi_train/81-717/lamps/headlights_141_group2.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), nohide = true },
		RedLights       = { model = "models/metrostroi_train/81-717/lamps/redlights.mdl",             pos = Vector(0,0,0), ang = Angle(0,0,0), color = Color(200,200,200), nohide = true },
		-- Interior body panels that cover under-seat / wall equipment.
		body_additional = { model = "models/metrostroi_train/81-717/717_body_additional.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 2 },
		-- Lamps / seating / handrails
		lamps1        = { model = "models/metrostroi_train/81-717/lamps_type1.mdl",   pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 1.5 },
		seats_new     = { model = "models/metrostroi_train/81-717/couch_new.mdl",     pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 1.5 },
		seats_new_cap = { model = "models/metrostroi_train/81-717/couch_new_cap.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), hideseat = 0.8 },
		handrails_new = { model = "models/metrostroi_train/81-717/handlers_new.mdl",  pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 1.5 },
		-- End-face + cab doors
		door_torec   = { model = "models/metrostroi_train/81-717/door_torec.mdl",  pos = Vector(-472.5, 15.75,-2.7),    ang = Angle(0,-90,0), hide = 2 },
		door_cab     = { model = "models/metrostroi_train/81-717/cab_door.mdl",    pos = Vector( 377.322, 28.267,-1.599), ang = Angle(0,-90,0), hide = 2 },
		door_cabine  = { model = "models/metrostroi_train/81-717/door_cabine.mdl", pos = Vector( 443.493, 65.111, 0.277), ang = Angle(0,-90,0), hide = 2 },
		-- Cab detail
		Lamp_RTM1    = { model = "models/metrostroi_train/81-717/rtmlamp.mdl",      pos = Vector(414.367,-32.450,6.717), ang = Angle(0,180,0), hide = 2 },
		-- Driver's pult (main control panel) + KV controller stick + ARS panel
		body_classic     = { model = "models/metrostroi_train/81-717/pult/body_classic.mdl",     pos = Vector(0,0,0), ang = Angle(0,0,0), color = Color(255,255,255), hide = 2.5 },
		pult_mvm_classic = { model = "models/metrostroi_train/81-717/pult/pult_mvm_classic.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), color = Color(255,255,255), hideseat = 0.8 },
		Controller       = { model = "models/metrostroi_train/81-717/kv_black.mdl",              pos = Vector(435.928, 16.1, -15.04), ang = Angle(0,-90,-32), hideseat = 0.2 },
		ars_mvm          = { model = "models/metrostroi_train/81-717/pult/ars_round.mdl",        pos = Vector(0,0,0), ang = Angle(0,0,0), hideseat = 0.8 },
		-- (16 sliding passenger door halves added below via _AddDoorHalves)
	},
	["81-714"] = {
		salon            = { model = "models/metrostroi_train/81-717/interior_mvm_int.mdl",    pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 2 },
		body_additional  = { model = "models/metrostroi_train/81-717/714_body_additional.mdl", pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 2 },
		lamps1           = { model = "models/metrostroi_train/81-717/lamps_type1_int.mdl",     pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 1.5 },
		seats_new        = { model = "models/metrostroi_train/81-717/couch_new_int.mdl",       pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 1.5 },
		handrails_new    = { model = "models/metrostroi_train/81-717/handlers_new_int.mdl",    pos = Vector(0,0,0), ang = Angle(0,0,0), hide = 2 },
		door_torec1      = { model = "models/metrostroi_train/81-717/door_torec.mdl", pos = Vector( 459.2,-15.9,-2.7),  ang = Angle(0, 89.5,0), hide = 2 },
		door_torec2      = { model = "models/metrostroi_train/81-717/door_torec.mdl", pos = Vector(-472.5, 15.75,-2.7), ang = Angle(0,-90,0),  hide = 2 },
		-- (16 sliding passenger door halves added below via _AddDoorHalves)
	},
}

-- 8 single-piece passenger doors — exactly the real 81-717_mvm setup.
-- doorIx1 (+Y side) uses door models pos1..4; doorIx0 (−Y side) uses pos4..1
-- so each doorway shows the correct mirrored leaf pair. These are rigid
-- single-mesh models, so the cl_init.lua Think HIDES a door when its packed
-- bool reports "open" (the doorway then reads as an open gap into the car).
local _DOOR_X = { 338.445, 108.324, -121.682, -351.531 }
local function _AddDoors(t)
	for i = 0, 3 do
		local x = _DOOR_X[i + 1]
		t["door"..i.."x1"] = {
			model = "models/metrostroi_train/81-717/81-717_doors_pos"..(i + 1)..".mdl",
			pos   = Vector(x,  65.164, 0.807),
			ang   = Angle(0, -90, 0),
			hide  = 2.0,
		}
		t["door"..i.."x0"] = {
			model = "models/metrostroi_train/81-717/81-717_doors_pos"..(4 - i)..".mdl",
			pos   = Vector(x, -65.164, 0.807),
			ang   = Angle(0,  90, 0),
			hide  = 2.0,
		}
	end
end
_AddDoors(ENT.AIVisualProps["81-717"])
_AddDoors(ENT.AIVisualProps["81-714"])

-- Copy the right prop set onto self.ClientProps for this instance.
function ENT:ApplyVisualProps()
	local t = self:GetNW2String("TrainType")
	if t == "" then return false end
	local src = self.AIVisualProps[t] or self.AIVisualProps["81-714"]
	self.ClientProps = {}
	for k,v in pairs(src) do self.ClientProps[k] = v end
	return true
end