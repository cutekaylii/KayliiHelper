local ADDON_NAME, module = ...
local defaults = {
    applyToFocus = false,
    buffBlacklist = {},
    buffColumns = 5,
    buffDurationColor = { 1, 1, 1, 1 },
    buffDurationFont = "FRIZ",
    buffDurationOutline = "NONE",
    buffDurationSize = 11,
    buffGrowDown = false,
    buffGrowLeft = false,
    buffLongDurationTextMinutes = 60,
    buffMinePlusWhitelist = false,
    buffOffsetX = 0,
    buffOffsetY = 29,
    buffRows = 1,
    buffSortMode = "default",
    buffStackColor = { 1, 1, 1, 1 },
    buffStackFont = "FRIZ",
    buffStackOutline = "OUTLINE",
    buffStackSize = 11,
    buffWhitelistModuleEnabled = true,
    buffs = {},
    debuffAnchorMode = "belowBuffs",
    debuffBlacklist = {},
    debuffColumns = 5,
    debuffDurationColor = { 1, 1, 1, 1 },
    debuffDurationFont = "FRIZ",
    debuffDurationOutline = "NONE",
    debuffDurationSize = 11,
    debuffGrowDown = false,
    debuffGrowLeft = false,
    debuffLongDurationTextMinutes = 60,
    debuffMinePlusWhitelist = false,
    debuffOffsetX = 0,
    debuffOffsetY = 0,
    debuffRows = 1,
    debuffSortMode = "unitframe",
    debuffStackColor = { 1, 1, 1, 1 },
    debuffStackFont = "FRIZ",
    debuffStackOutline = "OUTLINE",
    debuffStackSize = 11,
    debuffs = {},
    hideBuffLongDurationText = false,
    hideBuffTooltips = true,
    hideDebuffLongDurationText = false,
    hideDebuffTooltips = true,
    hidePermanentBuffs = false,
    hidePermanentDebuffs = false,
    iconSize = 18,
    onlyMyBuffs = false,
    onlyMyDebuffs = false,
    showBuffDuration = true,
    showBuffStacks = true,
    showDebuffDuration = true,
    showDebuffRedBorder = false,
    showDebuffStacks = true,
    showImportantBossBuffs = true,
    showLayoutPreview = false,
    useBuffFilter = true,
    useDebuffFilter = true,
}
local migrationKeys = {
    applyToFocus = true,
    buffBlacklist = true,
    buffColumns = true,
    buffDurationColor = true,
    buffDurationFont = true,
    buffDurationOutline = true,
    buffDurationSize = true,
    buffGrowDown = true,
    buffGrowLeft = true,
    buffLongDurationTextMinutes = true,
    buffMinePlusWhitelist = true,
    buffOffsetX = true,
    buffOffsetY = true,
    buffRows = true,
    buffSortMode = true,
    buffStackColor = true,
    buffStackFont = true,
    buffStackOutline = true,
    buffStackSize = true,
    buffWhitelistModuleEnabled = true,
    buffs = true,
    debuffAnchorMode = true,
    debuffBlacklist = true,
    debuffColumns = true,
    debuffDurationColor = true,
    debuffDurationFont = true,
    debuffDurationOutline = true,
    debuffDurationSize = true,
    debuffGrowDown = true,
    debuffGrowLeft = true,
    debuffLongDurationTextMinutes = true,
    debuffMinePlusWhitelist = true,
    debuffOffsetX = true,
    debuffOffsetY = true,
    debuffRows = true,
    debuffSortMode = true,
    debuffStackColor = true,
    debuffStackFont = true,
    debuffStackOutline = true,
    debuffStackSize = true,
    debuffs = true,
    hideBuffLongDurationText = true,
    hideBuffTooltips = true,
    hideDebuffLongDurationText = true,
    hideDebuffTooltips = true,
    hidePermanentBuffs = true,
    hidePermanentDebuffs = true,
    iconSize = true,
    onlyMyBuffs = true,
    onlyMyDebuffs = true,
    showBuffDuration = true,
    showBuffStacks = true,
    showDebuffDuration = true,
    showDebuffRedBorder = true,
    showDebuffStacks = true,
    showImportantBossBuffs = true,
    showLayoutPreview = true,
    useBuffFilter = true,
    useDebuffFilter = true,
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
            if (type(key) == "string" and migrationKeys[key] == true) and module.db[key] == nil then module.db[key] = Copy(value) end
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
