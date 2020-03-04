AddCSLuaFile()

ENT.Type = "anim"

-- Override these values
ENT.AmmoType = "Pistol"
ENT.AmmoAmount = 1
ENT.AmmoMax = 10
ENT.AmmoEntMax = 1
ENT.Model = Model "models/items/boxsrounds.mdl"
ENT.IsAmmo = true


function ENT:RealInit() end -- bw compat

-- Some subclasses want to do stuff before/after initing (eg. setting color)
-- Using self.BaseClass gave weird problems, so stuff has been moved into a fn
-- Subclasses can easily call this whenever they want to
function ENT:Initialize()
	self:SetModel( self.Model )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_BBOX )

	self:SetCollisionGroup( COLLISION_GROUP_WEAPON)
	local b = 26
	self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

	if SERVER then
		self:SetTrigger(true)
	end

	self.tickRemoval = false

	self.AmmoEntMax = self.AmmoAmount

	if (SERVER) then
		self:PhysWake()
	end
end

-- Pseudo-clone of SDK's UTIL_ItemCanBeTouchedByPlayer
-- aims to prevent picking stuff up through fences and stuff
function ENT:PlayerCanPickup(ply)
	if ply == self:GetOwner() then return false end

	local result = hook.Call("TTTCanPickupAmmo", nil, ply, self)
	if result then
		return result
	end

	local ent = self
	local phys = ent:GetPhysicsObject()
	local spos = phys:IsValid() and phys:GetPos() or ent:OBBCenter()
	local epos = ply:GetShootPos() -- equiv to EyePos in SDK

	local tr = util.TraceLine({start=spos, endpos=epos, filter={ply, ent}, mask=MASK_SOLID})

	-- can pickup if trace was not stopped
	return tr.Fraction == 1.0
end

function ENT:CheckForWeapon(ply)
	if not self.CachedWeapons then
		-- create a cache of what weapon classes use this ammo
		local tbl = {}
		for k,v in pairs(weapons.GetList()) do
			v = baseclass.Get(v.ClassName)
			if v and v.AmmoEnt == self:GetClass() then
				table.insert(tbl, v.ClassName)
			end
		end

		self.CachedWeapons = tbl
	end

	-- Check if player has a weapon that we know needs us. This is called in
	-- Touch, which is called many a time, so we use the cache here to avoid
	-- looping through every weapon the player has to check their AmmoEnt.
	for _, w in pairs(self.CachedWeapons) do
		if ply:HasWeapon(w) then 
			return w
		end
	end
	return false
end

function ENT:Touch(ent)
	if (SERVER and self.tickRemoval ~= true) and ent:IsValid() and ent:IsPlayer() and self:CheckForWeapon(ent) and self:PlayerCanPickup(ent) then
		local ammo = ent:GetAmmoCount(self.AmmoType)
		-- need clipmax info and room for at least 1/4th
		if self.AmmoMax >= (ammo + math.ceil(self.AmmoAmount * 0.25)) then
			local given = self.AmmoAmount
			given = math.min(given, self.AmmoMax - ammo)
			ent:GiveAmmo(given, self.AmmoType)

			local newEntAmount = self.AmmoAmount - given
			self.AmmoAmount = newEntAmount
			
			if self.AmmoAmount <= 0 or math.ceil(self.AmmoEntMax * 0.25) > self.AmmoAmount then
				self.tickRemoval = true
				self:Remove()
			end
		end
	end
end