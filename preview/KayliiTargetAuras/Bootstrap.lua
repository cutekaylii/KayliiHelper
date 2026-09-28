local ADDON_NAME, module = ...
local defaults = {
    buffWhitelistModuleEnabled = true,
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copied = {}
    for key, child in pairs(value) do copied[Copy(key)] = Copy(child) end
    return copied
end

local function Initialize()
    _G.KayliiTargetAurasDB = type(_G.KayliiTargetAurasDB) == "table" and _G.KayliiTargetAurasDB or {}
    _G.KayliiTargetAurasCharacterDB = type(_G.KayliiTargetAurasCharacterDB) == "table" and _G.KayliiTargetAurasCharacterDB or {}
    module.db = _G.KayliiTargetAurasDB
    module.characterDB = _G.KayliiTargetAurasCharacterDB
    -- Never write to the legacy 1.x tables. Existing 2.x values win.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if ((type(key) == "string" and (key:match("^buff") or key:match("^debuff") or key:match("^onlyMy") or key:match("^useBuff") or key:match("^useDebuff") or key:match("^showBuff") or key:match("^showDebuff") or key:match("^hideBuff") or key:match("^hideDebuff") or key:match("^applyToFocus") or key:match("^iconSize") or key:match("^showImportantBoss") or key:match("^showLayoutPreview"))) or key == "buffs" or key == "debuffs") and module.db[key] == nil then module.db[key] = Copy(value) end
        end
    end
    for key, value in pairs(defaults) do
        if module.db[key] == nil then module.db[key] = Copy(value) end
    end
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("buff", {
            title = "Buff White List", open = function() module:OpenWindow() end,
        })
    end
end

module.title = "Buff White List"
module.pages = {
    { title = "Auras", rows = {
        { "Enable target auras", "buffWhitelistModuleEnabled", "toggle", "SetBuffWhitelistModuleEnabled" },
        { "Also show on focus", "applyToFocus", "toggle", "RebuildManagedContainers" },
        { "Show only my buffs", "onlyMyBuffs", "toggle", "RebuildManagedContainers" },
        { "Show only my debuffs", "onlyMyDebuffs", "toggle", "RebuildManagedContainers" },
        { "Use buff filter", "useBuffFilter", "toggle", "RebuildManagedContainers" },
        { "Use debuff filter", "useDebuffFilter", "toggle", "RebuildManagedContainers" },
        { "Important boss buffs", "showImportantBossBuffs", "toggle", "RebuildManagedContainers" },
    } },
    { title = "Layout", rows = {
        { "Icon size", "iconSize", "number", "RebuildManagedContainers" },
        { "Buff columns", "buffColumns", "number", "RebuildManagedContainers" },
        { "Buff rows", "buffRows", "number", "RebuildManagedContainers" },
        { "Debuff columns", "debuffColumns", "number", "RebuildManagedContainers" },
        { "Debuff rows", "debuffRows", "number", "RebuildManagedContainers" },
        { "Show duration", "showBuffDuration", "toggle", "RebuildManagedContainers" },
        { "Show stacks", "showBuffStacks", "toggle", "RebuildManagedContainers" },
    } },
    { title = "Spell lists", rows = {
        { "Buff whitelist", "buffs", "spells", "buff" },
        { "Debuff whitelist", "debuffs", "spells", "debuff" },
        { "Buff blacklist", "buffBlacklist", "blacklist", "buff" },
        { "Debuff blacklist", "debuffBlacklist", "blacklist", "debuff" },
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
        module:InitializeDB()
    end
end)

SLASH_KAYLII_BUFF1 = "/kaybuff"
SlashCmdList["KAYLII_BUFF"] = function() module:OpenWindow() end
