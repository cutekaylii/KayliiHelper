local ADDON_NAME, module = ...
local defaults = {
    statsModuleEnabled = false,
    statsFontSize = 14,
    statsShowCrit = true,
    statsShowHaste = true,
    statsShowMastery = true,
    statsShowVersatility = true,
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copied = {}
    for key, child in pairs(value) do copied[Copy(key)] = Copy(child) end
    return copied
end

local function Initialize()
    _G.KayliiStatsDB = type(_G.KayliiStatsDB) == "table" and _G.KayliiStatsDB or {}
    _G.KayliiStatsCharacterDB = type(_G.KayliiStatsCharacterDB) == "table" and _G.KayliiStatsCharacterDB or {}
    module.db = _G.KayliiStatsDB
    module.characterDB = _G.KayliiStatsCharacterDB
    -- Never write to the legacy 1.x tables. Existing 2.x values win.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if (type(key) == "string" and key:sub(1, 5) == "stats") and module.db[key] == nil then module.db[key] = Copy(value) end
        end
    end
    for key, value in pairs(defaults) do
        if module.db[key] == nil then module.db[key] = Copy(value) end
    end
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("stats", {
            title = "My Stats", open = function() module:OpenWindow() end,
        })
    end
end

module.title = "My Stats"
module.pages = {
    { title = "Display", rows = {
        { "Enable My Stats", "statsModuleEnabled", "toggle", "SetStatsModuleEnabled" },
        { "Critical strike", "statsShowCrit", "toggle", "ApplyStatsSettings" },
        { "Haste", "statsShowHaste", "toggle", "ApplyStatsSettings" },
        { "Mastery", "statsShowMastery", "toggle", "ApplyStatsSettings" },
        { "Versatility", "statsShowVersatility", "toggle", "ApplyStatsSettings" },
        { "Show background", "statsShowBackground", "toggle", "ApplyStatsSettings" },
        { "Font size", "statsFontSize", "number", "ApplyStatsSettings" },
    } },
    { title = "Placement", rows = {
        { "Unlock position", "statsUnlocked", "toggle", "SetStatsUnlocked" },
        { "Only in combat", "statsOnlyInCombat", "toggle", "ApplyStatsSettings" },
        { "Only outside combat", "statsOnlyOutOfCombat", "toggle", "ApplyStatsSettings" },
        { "Only in instances", "statsOnlyInInstance", "toggle", "ApplyStatsSettings" },
        { "Reset position", "ResetStatsPosition", "action", "" },
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
        module:InitializeStatsModule()
    end
end)

SLASH_KAYLII_STATS1 = "/kaystats"
SlashCmdList["KAYLII_STATS"] = function() module:OpenWindow() end
