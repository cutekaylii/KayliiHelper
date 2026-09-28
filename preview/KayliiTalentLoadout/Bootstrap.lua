local ADDON_NAME, module = ...
local defaults = {
    talentLoadoutEnabled = false,
    talentLoadoutFontSize = 14,
    talentLoadoutShowSpec = true,
    talentLoadoutShowName = true,
    talentLoadoutShowHero = true,
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copied = {}
    for key, child in pairs(value) do copied[Copy(key)] = Copy(child) end
    return copied
end

local function Initialize()
    _G.KayliiTalentDB = type(_G.KayliiTalentDB) == "table" and _G.KayliiTalentDB or {}
    _G.KayliiTalentCharacterDB = type(_G.KayliiTalentCharacterDB) == "table" and _G.KayliiTalentCharacterDB or {}
    module.db = _G.KayliiTalentDB
    module.characterDB = _G.KayliiTalentCharacterDB
    -- Never write to the legacy 1.x tables. Existing 2.x values win.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if (type(key) == "string" and key:sub(1, 13) == "talentLoadout") and module.db[key] == nil then module.db[key] = Copy(value) end
        end
    end
    for key, value in pairs(defaults) do
        if module.db[key] == nil then module.db[key] = Copy(value) end
    end
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("talent", {
            title = "Talent Loadout", open = function() module:OpenWindow() end,
        })
    end
end

module.title = "Talent Loadout"
module.pages = {
    { title = "Display", rows = {
        { "Enable Talent Loadout", "talentLoadoutEnabled", "toggle", "SetTalentLoadoutEnabled" },
        { "Show specialization", "talentLoadoutShowSpec", "toggle", "ApplyTalentLoadoutSettings" },
        { "Show loadout name", "talentLoadoutShowName", "toggle", "ApplyTalentLoadoutSettings" },
        { "Show Hero Talent", "talentLoadoutShowHero", "toggle", "ApplyTalentLoadoutSettings" },
        { "Show background", "talentLoadoutShowBackground", "toggle", "ApplyTalentLoadoutSettings" },
        { "Font size", "talentLoadoutFontSize", "number", "ApplyTalentLoadoutSettings" },
    } },
    { title = "Placement", rows = {
        { "Unlock position", "talentLoadoutUnlocked", "toggle", "SetTalentLoadoutUnlocked" },
        { "Reset position", "ResetTalentLoadoutPosition", "action", "" },
    } },
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == ADDON_NAME then
        Initialize()
    elseif event == "PLAYER_LOGIN" then
        if not module.db then Initialize() end
        module:InitializeTalentLoadout()
    end
end)

SLASH_KAYLII_TALENT1 = "/kaytalent"
SlashCmdList["KAYLII_TALENT"] = function() module:OpenWindow() end
