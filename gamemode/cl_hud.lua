DEFINE_BASECLASS "gamemode_base"

local DrawTextShadowed = hud.DrawTextShadowed

local health_full = Color(58, 180, 80)
local health_ok = Color(240, 255, 0)
local health_dead = Color(255, 51, 0)

local function ColorLerp(col_from, col_mid, col_to, amt)
	if (amt > 0.5) then
		col_from = col_mid
		amt = (amt - 0.5) * 2
	else
		col_to = col_mid
		amt = amt * 2
	end

	local fr, fg, fb = col_from.r, col_from.g, col_from.b
	local tr, tg, tb = col_to.r, col_to.g, col_to.b

	return fr + (tr - fr) * amt, fg + (tg - fg) * amt, fb + (tb - fb) * amt
end

function ttt.GetHUDTarget()
	local ply = LocalPlayer()
	if (ply.GetObserverMode and ply:GetObserverMode() == OBS_MODE_IN_EYE) then
		return ply:GetObserverTarget()
	end
	return ply
end

white_text = Color(230, 230, 230, 255)

local LastTarget, LastTime

function GM:HUDDrawTargetID()
	local ent = ttt.GetHUDTarget()
	local tr = ent:GetEyeTrace()

	ent = tr.Entity

	if (not IsValid(ent)) then
		return
	end

	local text = "n/a"
	local extra
	local color = white_text

	local target

	if (ent:IsPlayer()) then
		if (ent.HasDisguiser and ent:HasDisguiser()) then return end

		text = ent:Nick()
	elseif (ent:GetNW2Bool("IsPlayerBody", false)) then
		local state = ent.HiddenState
		if (not IsValid(state)) then
			text = "Unidentified Body"
		else
			local own = ent.HiddenState
			color = ttt.roles[ent.HiddenState:GetRole()].Color
			if (ent.HiddenState:GetIdentified()) then
				text = own:GetNick() .. "'s Identified Body"
			else
				text = own:GetNick() .. "'s Unidentified Body"
			end
		end
	else
		return
	end

	if (LastTarget ~= ent or LastTime and LastTime < CurTime() - 1) then
		LastTarget = ent
		LastTime = CurTime()
		net.Start "ttt_player_target"
			net.WriteEntity(ent)
		net.SendToServer()
		LocalPlayer():SetTarget(ent)
		timer.Create("EliminateTarget", 3, 1, function()
			LocalPlayer():SetTarget(nil)
		end)
	end

	surface.SetFont "TargetIDSmall"
	surface.SetTextColor(color_black)

	local x, y = ScrW() / 2, ScrH() / 2

	y = y + math.max(50, ScrH() / 20)

	local tw, th = surface.GetTextSize(text)

	hud.DrawTextOutlined(text, color, color_black, x - tw / 2, y, 1)


	if (IsValid(ent) and ent:IsPlayer()) then

		local state = ent.HiddenState

		if (IsValid(state) and not state:IsDormant()) then
			y = y + th + 4
			local role = ent:GetRoleData()
			local col = role.Color
			local txt = role.Name

			tw, th = surface.GetTextSize(txt)

			hud.DrawTextOutlined(txt, col, color_black, x - tw / 2, y, 1)
		end

		local health, maxhealth = ent:Health(), ent:GetMaxHealth()

		local scrw = ScrW()

		local hppct = health / maxhealth
		local wid = math.max(40, math.min(scrw / 45, 100))
		local hpw = math.ceil(wid * hppct)
		y = y + th + 4

		local r, g, b = ColorLerp(health_dead, health_ok, health_full, hppct)
		local a = 230
		th = math.ceil(th / 2)
		surface.SetDrawColor(r, g, b, a)
		surface.DrawRect(x - wid / 2, y, hpw, th)
		surface.SetDrawColor(0, 0, 0, a)
		surface.DrawRect(x - wid / 2 + hpw, y, wid - hpw, th)

		surface.SetDrawColor(200, 200, 200, 255)
		surface.DrawOutlinedRect(x - wid / 2 - 1, y - 1, wid + 2, th + 2)
	end
end

function GM:HUDPaintBackground()
	hook.Run "TTTDrawDamagePosition"
end

function GM:HUDPaint()
	hook.Run "HUDDrawTargetID"
	hook.Run "TTTDrawHitmarkers"

	local targ = ttt.GetHUDTarget()
	if (targ ~= LocalPlayer()) then
		-- https://github.com/Facepunch/garrysmod-issues/issues/3936
		local wep = targ:GetActiveWeapon()
		if (IsValid(wep)) then
			wep:DoDrawCrosshair(ScrW() / 2, ScrH() / 2)
		end
	end
end

function GM:PlayerPostThink()
	if (not IsFirstTimePredicted()) then
		return
	end

	local targ = ttt.GetHUDTarget()

	if (targ ~= LocalPlayer()) then
		local wep = targ:GetActiveWeapon()
		if (IsValid(wep)) then
			wep:CalcAllUnpredicted()
		end
	end
end


local hide = {
	CHudHealth = true,
	CHudDamageIndicator = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true
}

function GM:HUDShouldDraw(name)
	if (hide[name]) then
		return false
	end
	
	return true
end

--[[
	
	self:SetSize(ScrW() * 0.22, ScrH() * 0.04)
	self:SetCurve(math.Round(ScrH() * 0.0025) * 2)
	self:SetPos(ScrW() * 0.05, ScrH() - ScrH() * 0.1)
]]

local default = [[
{
	"main": {
		"ttt_spectator": {
			"pos": [0.5, 0.1, 0],
			"size": [0.22, 0.04],
			"curve": 0.005,
			"visible": true,
			"bg_color": [11, 12, 11, 200],
			"outline_color": [230, 230, 230],
			"color": [154, 153, 153]
		},
		"ttt_health": {
			"pos": [0.12, 0.9, 1],
			"size": [0.22, 0.04],
			"visible": true,
			"curve": 0.005,
			"bg_color": [11, 12, 11, 200],
			"color": [59, 171, 91],
			"outline_color": [230, 230, 230]
		},
		"ttt_time": {
			"pos": [0.12, 0.95, 1],
			"size": [0.22, 0.04],
			"visible": true,
			"curve": 0.005,
			"bg_color": [11, 12, 11, 200],
			"outline_color": [230, 230, 230]
		},
		"ttt_ammo": {
			"size": [0.15, 0.25],
			"pos": [0.9, 0.9],
			"visible": true,
			"curve": 0.005,
			"bg_color": [0, 0, 0, 0]
		}
	},
	"extra": [
	]
}
]]

local json

local s, e = pcall(function()
	json = util.JSONToTable(file.Read("tttrw_hud.json", "DATA") or default)
end)

if (not s or not json or not json.main) then
	warn("%s", not json and "json ded" or not json.main and "no main" or e)
	return
end

ttt.HUDElements = ttt.HUDElements or {}

for item, ele in pairs(ttt.HUDElements) do
	if (IsValid(ele)) then
		ele:Remove()
	end
end

local function IsCustomizable(ele)
	local base = baseclass.Get(ele)
	local good = false
	while (base) do
		if (base.AcceptInput) then
			good = true
			break
		end
		base = baseclass.Get(base.Base)
		if (not base or not base.Base) then
			break
		end
	end

	return good
end

for ele, data in pairs(json.main) do
	if (not data.visible) then
		continue
	end

	if (not IsCustomizable(ele)) then
		continue
	end

	ttt.HUDElements[ele] = GetHUDPanel():Add(ele)

	for key, value in pairs(data) do
		ttt.HUDElements[ele]:AcceptInput(key, value)
	end
end

if (not json.extra) then
	return
end

for id, data in ipairs(json.extra) do
	if (not data.type or not IsCustomizable(data.type)) then
		continue
	end

	local p = GetHUDPanel():Add(data.type)

	ttt.HUDElements[id] = p

	for key, value in pairs(data) do
		p:AcceptInput(key, value)
	end
end
