function GM:SetupTTTCompatibleEntities()
    for _, ent in pairs(weapons.GetList()) do
        if (ent.ClassName:find "_ttt_") then
            scripted_ents.Register({
                Base = "ttt_zm_replacement"
            }, ent.ClassName:gsub("_ttt_", "_zm_"))
        end
    end
end