AddCSLuaFile()

SWEP.HoldType              = "ar2"

SWEP.PrintName          = "M4A1"
SWEP.Slot               = 2

SWEP.ViewModelFlip      = false
SWEP.ViewModelFOV       = 64

SWEP.Icon               = "vgui/ttt/icon_m16"
SWEP.IconLetter         = "w"

SWEP.Base                  = "weapon_tttbase"

SWEP.Kind                  = WEAPON_HEAVY
SWEP.WeaponID              = AMMO_M16

SWEP.Bullets = {
	Damage = 18,
	HullSize = 0,
	Num = 1,
	DamageDropoffRange = 600,
	DamageDropoffRangeMax = 3600,
	DamageMinimumPercent = 0.1,
	Spread = Vector(.02, .02, .02)
}

SWEP.Primary.Delay         = 0.1
SWEP.Primary.Recoil        = 1.6
SWEP.Primary.Automatic     = true
SWEP.Primary.Ammo          = "Pistol"
SWEP.Primary.ClipSize      = 20
SWEP.Primary.ClipMax       = 1000
SWEP.Primary.DefaultClip   = 20
SWEP.Primary.Sound         = Sound "Weapon_M4A1.Single"

SWEP.AutoSpawnable         = true
SWEP.Spawnable             = true
SWEP.AmmoEnt               = "item_ammo_pistol_ttt"

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.WorldModel            = "models/weapons/w_rif_m4a1.mdl"

SWEP.Ironsights = {
	Pos = Vector(-7.8, -9.2, 0.55),
	Angle = Vector(3.3, -2.7, -5),
	TimeTo = 0.25,
	TimeFrom = 0.15,
	SlowDown = 0.3
}

DEFINE_BASECLASS "weapon_tttbase"

function SWEP:DoZoom(state)
	if not (IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()) then return end
	if state then
		--self:GetOwner():SetFOV(35, 0.5)
	else
		--self:GetOwner():SetFOV(0, 0.2)
	end
end

function SWEP:OnDrop()
    BaseClass.OnDrop(self)
    self:SetZoom(false)
end