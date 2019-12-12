resource.AddSingleFile "resource/fonts/Lato-Regular.ttf"
resource.AddSingleFile "resource/fonts/Lato-Semibold.ttf"

include "sh_files.lua"

util.AddNetworkString "tttrw_console_print"

function PLAYER:ConsolePrint(text)
	net.Start "tttrw_console_print"
		net.WriteString(text)
	net.Send(self)
end

function GM:PlayerUse(ply, ent)
	return ply:Alive()
end

function GM:EntityTakeDamage(targ, dmg)
	if (dmg:GetDamage() > 0 and dmg:GetDamageType() == DMG_BULLET) then
		targ.RestoreVelocity = targ:GetVelocity()
	end
	self:CreateHitmarkers(targ, dmg)
	self:Karma_EntityTakeDamage(targ, dmg)

	if (targ:IsPlayer() and hook.Run("PlayerShouldTakeDamage", targ, dmg:GetAttacker())) then
		self:PlayerTakeDamage(targ, dmg:GetInflictor(), dmg:GetAttacker(), dmg:GetDamage(), dmg)
	end
end

function GM:SetupMove(ply, mv)

	if (ply.RestoreVelocity) then
		print(ply, ply.RestoreVelocity)
		mv:SetVelocity(ply.RestoreVelocity)
		ply.RestoreVelocity = nil
	end
end

function GM:Drown(ply)
	if (ply:WaterLevel() == 3) then
		if ply:IsOnFire() then
			ply:Extinguish()
		end

		if ply.drowning then
			if ply.drowning < CurTime() then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(15)
				dmginfo:SetDamageType(DMG_DROWN)
				dmginfo:SetAttacker(game.GetWorld())
				dmginfo:SetInflictor(game.GetWorld())
				dmginfo:SetDamageForce(Vector(0,0,1))

				ply:TakeDamageInfo(dmginfo)

				-- have started drowning properly
				ply.drowning = CurTime() + 1
			end
		else
			-- will start drowning soon
			ply.drowning = CurTime() + 8
		end
	else
		ply.drowning = nil
	end
end

function GM:PlayerShouldTaunt()
	return false
end

function GM:PlayerTakeDamage(targ, wpn, atk, dmg, dmginfo)
	self:DamageLogs_PlayerTakeDamage(targ, dmginfo)
	local flt = targ:GetHealthFloat()
	flt = flt - (dmg % 1)
	if (flt < 0) then
		flt = flt + 1
		dmginfo:SetDamage(dmginfo:GetDamage() + 1)
	end

	targ:SetHealthFloat(flt)
end

function GM:TTTPrepareRound()
	self:SpawnMapEntities()
	self:DamageLogs_TTTPrepareRound()
end

function GM:TTTEndRound()
	self:DamageLogs_TTTEndRound()
	self:MapVote_TTTEndRound()
	self:Karma_TTTEndRound()
end

local tttrw_door_speedup = CreateConVar("tttrw_door_speed_mult", 1, FCVAR_NONE, "How much faster doors are (2 = double, 0.5 = half)")

local block = {
	func_button = true,
	trigger_push = true
}
function GM:EntityKeyValue(ent, key, value)
	if (not block[ent:GetClass()] and key:lower() == "speed") then
		return value / 66 / engine.TickInterval() * tttrw_door_speedup:GetFloat()
	end
end

function GM:CreateDNAData(owner)
	local e = ents.Create "ttt_dna_info"
	e:SetDNAOwner(owner)

	return e
end

local ttt_dna_max_time = CreateConVar("ttt_dna_max_time", "120", FCVAR_REPLICATED)
local ttt_dna_max_distance = CreateConVar("ttt_dna_max_distance", "830", FCVAR_REPLICATED)

function GM:PlayerRagdollCreated(ply, rag, atk)
	if (not IsValid(atk) or atk == ply) then
		return
	end

	local e = self:CreateDNAData(atk)
	e:SetExpireTime(CurTime() + Lerp(math.Clamp(atk:GetPos():Distance(ply:GetPos()) / ttt_dna_max_distance:GetFloat(), 0, 1), ttt_dna_max_time:GetFloat(), 0))
	e:SetParent(rag)
	e:Spawn()

	local body_dna = ents.Create "ttt_body_info_dna"
	body_dna:SetDNAEntity(e)
	body_dna:SetParent(rag.HiddenState)
	body_dna:Spawn()

	rag.HiddenState:SetCredits(ply:GetCredits())
	ply:SetCredits(0)
end

function GM:PlayerDeathSound()
	return true
end

function GM:DoPlayerDeath(ply, atk, dmg)
	ttt.CreatePlayerRagdoll(ply, atk, dmg)

	self:Karma_DoPlayerDeath(ply, atk, dmg)

	if (IsValid(atk) and atk:IsPlayer()) then
		table.insert(atk.Killed, ply)
	end

	for _, wep in pairs(ply:GetWeapons()) do
		ply:SetActiveWeapon(wep)
		self:DropCurrentWeapon(ply)
	end
end