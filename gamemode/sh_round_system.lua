local ttt_postround_dm = CreateConVar("ttt_postround_dm", "0", FCVAR_REPLICATED, "Postround DM enable")

function ttt.GetRoleColor(role)
	role = ttt.roles[role]
	if (role) then
		if (role.Color) then
			return role.Color
		end

		local team = ttt.teams[role.Team]

		if (team and team.Color) then
			role.Color = team.Color
			return team.Color
		end
		role.Color = color_unknown
	end
	return color_unknown
end

function GM:OnRoundStateChange(old, new)
	local str = string.format("Round state was %s and is now %s", ttt.Enums.RoundState[old] or "nil", ttt.Enums.RoundState[new])
	if (CLIENT) then
		chat.AddText(str)
	else
		print(str)
	end
	if (new == ttt.ROUNDSTATE_PREPARING) then
		local list = {}
		hook.Run("TTTAddPermanentEntities", list)
		game.CleanUpMap(false, list)
	end
end

function GM:PlayerShouldTakeDamage(ply, atk)
	if (IsValid(atk) and atk:IsPlayer()) then
		local state = ttt.GetRoundState()
		return state == ttt.ROUNDSTATE_ACTIVE or ttt_postround_dm:GetBool() and state == ttt.ROUNDSTATE_ENDED
	end
end

hook.Add("TTTPrepareNetworkingVariables", "RoundState", function(vars)
	table.insert(vars, {
		Name = "RoundState",
		Type = "Int",
		Enums = {
			Ended = 0,
			Preparing = 1,
			Active = 2,
			Waiting = 3
		},
		Default = 3
	})
	table.insert(vars, {
		Name = "RoundTime",
		Type = "Float",
		Default = 0
	})
	table.insert(vars, {
		Name = "WinCond",
		Type = "Int",
		Enums = {
			TimeLimit = 0
		},
		Default = 0
	})
end)


hook.Add("TTTGetHiddenPlayerVariables", "RoundState", function(vars)
	table.insert(vars, {
		Name = "Role",
		Type = "String",
		Default = "Spectator",
		Enums = {}
	})
end)