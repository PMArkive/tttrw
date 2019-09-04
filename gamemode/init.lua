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
	self:CreateHitmarkers(targ, dmg)
	self:DamageLogs_EntityTakeDamage(targ, dmg)
end

function GM:TTTPrepareRound()
	self:SpawnMapEntities()
	self:DamageLogs_TTTPrepareRound()
end

function GM:TTTEndRound()
	self:DamageLogs_TTTEndRound()
	self:MapVote_TTTEndRound()
end

local tttrw_door_speedup = CreateConVar("tttrw_door_speed_mult", 1, FCVAR_NONE, "How much faster doors are (2 = double, 0.5 = half)")

function GM:EntityKeyValue(ent, key, value)
	if (key:lower() == "speed") then
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
end