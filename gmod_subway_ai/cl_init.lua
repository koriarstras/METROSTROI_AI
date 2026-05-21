include("shared.lua")

--------------------------------------------------------------------------------
ENT.ClientPropsInitialized = false
ENT.AutoAnims = {}
ENT.AutoAnimNames = {}
ENT.ClientSounds = {}

--------------------------------------------------------------------------------
-- Apply the right visual prop set for this wagon. The data itself lives in
-- shared.lua (ENT.AIVisualProps) so init.lua / shared.lua / cl_init.lua all
-- have access to it — this matches the user's preference for visuals being
-- defined server-side rather than only on the client.
--------------------------------------------------------------------------------
function ENT:EnsureClientProps()
	if self.ClientPropsReady then return end
	if self:ApplyVisualProps() then
		self.ClientPropsReady = true
	end
end

--------------------------------------------------------------------------------
function ENT:Initialize()
	self.ClientProps = {}
	self.BaseClass.Initialize(self)
	self:EnsureClientProps()
	self:SetNW2VarProxy("TrainType", function() self:EnsureClientProps() end)
end

--------------------------------------------------------------------------------
function ENT:Think()
	self:EnsureClientProps()
	self.BaseClass.Think(self)

	-- Toggle the mask + matching headlight pair, AND flip head/red light visuals
	-- based on whether this 81-717 car is the FRONT or REAR of the consist.
	--   Front head → headlights visible, RedLights hidden
	--   Rear head  → RedLights visible, headlights hidden
	if self:GetNW2String("TrainType") == "81-717" then
		local mask = self:GetNW2Int("MaskType", 3)
		local isRear = self:GetNW2Bool("IsRearCar", false)
		if self._LastMaskType ~= mask or self._LastIsRear ~= isRear then
			self._LastMaskType = mask
			self._LastIsRear = isRear
			-- Mask visibility (only the matching variant is shown)
			self:ShowHide("mask22_mvm",     mask == 1)
			self:ShowHide("mask222_mvm_wp", mask == 2)
			self:ShowHide("mask222_mvm",    mask == 3)
			self:ShowHide("mask141_mvm",    mask == 4)
			-- Headlight model visibility: only on the FRONT car
			local headlight = not isRear
			self:ShowHide("Headlights22_1",  headlight and mask == 1)
			self:ShowHide("Headlights22_2",  headlight and mask == 1)
			self:ShowHide("Headlights222_1", headlight and (mask == 2 or mask == 3))
			self:ShowHide("Headlights222_2", headlight and (mask == 2 or mask == 3))
			self:ShowHide("Headlights141_1", headlight and mask == 4)
			self:ShowHide("Headlights141_2", headlight and mask == 4)
			-- Red marker lights: only on the REAR car
			self:ShowHide("RedLights", isRear)
		end
	end

	-- Door animation. The 81-717_doors_pos*.mdl models carry a "position"
	-- pose parameter (0 = closed, 1 = open); ENT:Animate drives that pose
	-- parameter internally, so the model's own rig slides the leaves apart.
	-- No SetPos, no ShowHide — just feed Animate the target each tick.
	-- Packed bools 21–24 = LEFT (+Y, k=1), 25–28 = RIGHT (−Y, k=0).
	for i = 0, 3 do
		for k = 0, 1 do
			local name    = "door"..i.."x"..k
			local boolIdx = (k == 1) and (21 + i) or (25 + i)
			local target  = self:GetPackedBool(boolIdx) and 1 or 0
			self:Animate(name, target, 0, 1, 0.9, 0)
		end
	end

	-- Brake-line release sounds (cheap atmosphere)
	local brakeLinedPdT = self:GetPackedRatio(9)
	local dT = self.DeltaTime
	self.BrakeLineRamp1 = self.BrakeLineRamp1 or 0
	if (brakeLinedPdT > -0.001)
	then self.BrakeLineRamp1 = self.BrakeLineRamp1 + 2.0*(0 - self.BrakeLineRamp1)*dT
	else self.BrakeLineRamp1 = self.BrakeLineRamp1 + 2.0*((-0.4*brakeLinedPdT) - self.BrakeLineRamp1)*dT
	end
	self:SetSoundState("release2", self.BrakeLineRamp1, 1.0)

	self.BrakeLineRamp2 = self.BrakeLineRamp2 or 0
	if (brakeLinedPdT < 0.001)
	then self.BrakeLineRamp2 = self.BrakeLineRamp2 + 2.0*(0 - self.BrakeLineRamp2)*dT
	else self.BrakeLineRamp2 = self.BrakeLineRamp2 + 2.0*(0.02*brakeLinedPdT - self.BrakeLineRamp2)*dT
	end
	self:SetSoundState("release3", self.BrakeLineRamp2, 1.0)

	-- ARS/ringer alert state
	local alertState = self:GetPackedBool(39)
	self.PreviousAlertState = self.PreviousAlertState or false
	if self.PreviousAlertState ~= alertState then
		self.PreviousAlertState = alertState
		if alertState then
			self:SetSoundState("ring", 0.20, 1)
		else
			self:SetSoundState("ring", 0, 0)
			self:PlayOnce("ring_end", "cabin", 0.45)
		end
	end

	-- DIP loop (background hum)
	self:SetSoundState("bpsn1", self:GetPackedBool(52) and 1 or 0, 1.0)
end

--------------------------------------------------------------------------------
-- DO NOT clear self.ClientProps here. The base class calls OnRemove(true)
-- whenever the train goes dormant (out of player PVS), which would otherwise
-- destroy our prop definitions and leave nothing to respawn from when the
-- train re-enters view. The base class's RemoveCSEnts handles ClientEnts
-- cleanup — we just delegate to it.
function ENT:OnRemove(temp)
	self.BaseClass.OnRemove(self, temp)
end
