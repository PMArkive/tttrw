DEFINE_BASECLASS "gamemode_base"

function GM:PlayerSetModel(ply)
	ply:SetModel "models/player/phoenix.mdl"

	ply:SetColor(color_white)

	hook.Run("TTTPlayerSetColor", ply)
end

function GM:PlayerLoadout(ply)
	-- can provide weapons here
	BaseClass.PlayerLoadout(self, ply)

	-- check if they need any spawning weapons that weren't provided
	local wpns = ply:GetWeapons()

	local slots = {}

	for _, wep in pairs(wpns) do
		slots[wep.Slot] = true
	end

	if (not slots[1]) then
		for k,v in pairs(weapons.GetList()) do
			if (v.AutoSpawnable) then
				ply:Give(v.ClassName)
			end
		end
	end
end

function GM:PlayerDeathThink(ply)
	return false
end