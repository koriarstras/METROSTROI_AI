include("shared.lua")

ENT.ClientPropsInitialized = false
ENT.AutoAnims = {}
ENT.AutoAnimNames = {}
ENT.ClientSounds = {}

function ENT:EnsureClientProps()
	if self.ClientPropsReady then return end
	if self:ApplyVisualProps() then
		self.ClientPropsReady = true
	end
end

function ENT:Initialize()
	self.ClientProps = {}
	self.BaseClass.Initialize(self)
	self:EnsureClientProps()
	self:SetNW2VarProxy("TrainType", function()
		self:EnsureClientProps()
	end)
end

-- Mask + head/red lights for 81-717 (front vs rear of consist)
local MASK_NAMES = {
	[1] = "mask22_mvm",
	[2] = "mask222_mvm_wp",
	[3] = "mask222_mvm",
	[4] = "mask141_mvm",
}

function ENT:UpdateHeadVisuals()
	if self:GetNW2String("TrainType") ~= "81-717" then return end

	local mask = self:GetNW2Int("MaskType", 3)
	local isRear = self:GetNW2Bool("IsRearCar", false)
	if self._LastMaskType == mask and self._LastIsRear == isRear then return end

	self._LastMaskType = mask
	self._LastIsRear = isRear

	for maskId, propName in pairs(MASK_NAMES) do
		self:ShowHide(propName, mask == maskId)
	end

	local showHeadlights = not isRear
	self:ShowHide("Headlights22_1",  showHeadlights and mask == 1)
	self:ShowHide("Headlights22_2",  showHeadlights and mask == 1)
	self:ShowHide("Headlights222_1", showHeadlights and (mask == 2 or mask == 3))
	self:ShowHide("Headlights222_2", showHeadlights and (mask == 2 or mask == 3))
	self:ShowHide("Headlights141_1", showHeadlights and mask == 4)
	self:ShowHide("Headlights141_2", showHeadlights and mask == 4)
	self:ShowHide("RedLights", isRear)
end

-- Packed bools 21–24 = left (+Y), 25–28 = right (−Y)
function ENT:UpdatePassengerDoors()
	for i = 0, 3 do
		for k = 0, 1 do
			local name = "door" .. i .. "x" .. k
			local boolIdx = (k == 1) and (21 + i) or (25 + i)
			local target = self:GetPackedBool(boolIdx) and 1 or 0
			self:Animate(name, target, 0, 1, 0.9, 0)
		end
	end
end

function ENT:UpdateBrakeReleaseSounds()
	local brakeLinePdT = self:GetPackedRatio(9)
	local dT = self.DeltaTime

	self.BrakeLineRamp1 = self.BrakeLineRamp1 or 0
	if brakeLinePdT > -0.001 then
		self.BrakeLineRamp1 = self.BrakeLineRamp1 + 2.0 * (0 - self.BrakeLineRamp1) * dT
	else
		self.BrakeLineRamp1 = self.BrakeLineRamp1 + 2.0 * ((-0.4 * brakeLinePdT) - self.BrakeLineRamp1) * dT
	end
	self:SetSoundState("release2", self.BrakeLineRamp1, 1.0)

	self.BrakeLineRamp2 = self.BrakeLineRamp2 or 0
	if brakeLinePdT < 0.001 then
		self.BrakeLineRamp2 = self.BrakeLineRamp2 + 2.0 * (0 - self.BrakeLineRamp2) * dT
	else
		self.BrakeLineRamp2 = self.BrakeLineRamp2 + 2.0 * (0.02 * brakeLinePdT - self.BrakeLineRamp2) * dT
	end
	self:SetSoundState("release3", self.BrakeLineRamp2, 1.0)
end

function ENT:UpdateARSAlertSound()
	local alertState = self:GetPackedBool(39)
	self.PreviousAlertState = self.PreviousAlertState or false
	if self.PreviousAlertState == alertState then return end

	self.PreviousAlertState = alertState
	if alertState then
		self:SetSoundState("ring", 0.20, 1)
	else
		self:SetSoundState("ring", 0, 0)
		self:PlayOnce("ring_end", "cabin", 0.45)
	end
end

function ENT:Think()
	self:EnsureClientProps()
	self.BaseClass.Think(self)

	self:UpdateHeadVisuals()
	self:UpdatePassengerDoors()
	self:UpdateBrakeReleaseSounds()
	self:UpdateARSAlertSound()
	self:SetSoundState("bpsn1", self:GetPackedBool(52) and 1 or 0, 1.0)
end

-- Do not clear ClientProps on dormancy — base RemoveCSEnts handles ClientEnts.
function ENT:OnRemove(temp)
	self.BaseClass.OnRemove(self, temp)
end
