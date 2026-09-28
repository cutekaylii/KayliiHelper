local ADDON_NAME, module = ...
local defaults = {
    lustUpEnabled = true,
    lustUpCustomLockouts = {},
    lustUpCustomDrumItems = {},
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copied = {}
    for key, child in pairs(value) do copied[Copy(key)] = Copy(child) end
    return copied
end

local function Initialize()
    _G.KayliiLustDB = type(_G.KayliiLustDB) == "table" and _G.KayliiLustDB or {}
    _G.KayliiLustCharacterDB = type(_G.KayliiLustCharacterDB) == "table" and _G.KayliiLustCharacterDB or {}
    module.db = _G.KayliiLustDB
    module.characterDB = _G.KayliiLustCharacterDB
    -- Never write to the legacy 1.x tables. Existing 2.x values win.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if (type(key) == "string" and key:sub(1, 6) == "lustUp") and module.db[key] == nil then module.db[key] = Copy(value) end
        end
    end
    for key, value in pairs(defaults) do
        if module.db[key] == nil then module.db[key] = Copy(value) end
    end
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("lust", {
            title = "Lust Up", open = function() module:OpenWindow() end,
        })
    end
end

module.title = "Lust Up"
module.pages = {
    { title = "Readiness", rows = {
        { "Enable Lust Up", "lustUpEnabled", "toggle", "ApplyLustUpSettings" },
        { "Require a Lust ability", "lustUpRequireLustAbility", "toggle", "ApplyLustUpSettings" },
        { "Allow drums", "lustUpAllowDrums", "toggle", "ApplyLustUpSettings" },
        { "Show in dungeons", "lustUpShowInDungeons", "toggle", "ApplyLustUpSettings" },
        { "Show in raids", "lustUpShowInRaids", "toggle", "ApplyLustUpSettings" },
        { "Only in combat", "lustUpOnlyInCombat", "toggle", "ApplyLustUpSettings" },
        { "Only in instances", "lustUpOnlyInInstance", "toggle", "ApplyLustUpSettings" },
    } },
    { title = "Voice", rows = {
        { "Voice alerts", "lustUpVoiceEnabled", "toggle", "ApplyLustUpSettings" },
        { "Ready announcement", "lustUpReadyVoiceText", "text", "ApplyLustUpSettings" },
        { "Boss pull alert", "lustUpBossPullVoiceEnabled", "toggle", "ApplyLustUpSettings" },
        { "Boss pull text", "lustUpBossPullVoiceText", "text", "ApplyLustUpSettings" },
        { "Test ready speech", "SpeakLustUp", "action", "" },
    } },
    { title = "Appearance", rows = {
        { "Unlock indicator", "lustUpUnlocked", "toggle", "SetLustUpUnlocked" },
        { "Indicator size", "lustUpSize", "number", "ApplyLustUpSettings" },
        { "Clickable indicator", "lustUpIndicatorClickable", "toggle", "SetLustUpIndicatorClickable" },
        { "Glow when ready", "lustUpReadyGlow", "toggle", "ApplyLustUpSettings" },
        { "Reset position", "ResetLustUpPosition", "action", "" },
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
        module:InitializeLustUp()
    end
end)

SLASH_KAYLII_LUST1 = "/kaylust"
SlashCmdList["KAYLII_LUST"] = function() module:OpenWindow() end
