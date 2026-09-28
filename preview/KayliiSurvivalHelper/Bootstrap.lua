local ADDON_NAME, module = ...

local defaults = {
    survivalModuleEnabled = false,
    survivalUnlocked = false,
    survivalIconSize = 58,
    survivalShowLabel = true,
    survivalShowAllReadyActions = false,
    survivalReadyActionsGrowth = "right",
    survivalGlowEnabled = true,
    survivalOnlyInCombat = true,
    survivalOnlyInInstance = false,
    survivalTriggerThreshold = 30,
    survivalTTSEnabled = true,
    survivalTTSContinuous = false,
    survivalTTSText = "Use a defensive",
    survivalSpeakActionName = true,
    survivalDeathSoundEnabled = true,
    survivalDeathSound = "raid_warning",
    survivalDeathSoundThrottleSeconds = 0.5,
    survivalPulseSoundEnabled = true,
    survivalPulseOriginalPercent = nil,
    survivalThresholdAlertType = "tts",
    survivalAlertSound = "Air Horn",
    survivalPersonalEnabled = true,
    survivalPersonalThreshold = 65,
    survivalPersonalSpellID = 0,
    survivalHealthstoneEnabled = true,
    survivalHealthstoneThreshold = 45,
    survivalPotionEnabled = true,
    survivalPotionThreshold = 30,
    survivalPotionItemID = 0,
    survivalActionSettings = {},
    survivalActionSettingsMigrated = false,
    survivalPriorityOrder = {},
    survivalPoint = "CENTER",
    survivalX = 0,
    survivalY = -80,
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[Copy(key)] = Copy(child) end
    return result
end

local function Initialize()
    KayliiSurvivalDB = type(KayliiSurvivalDB) == "table"
        and KayliiSurvivalDB or {}
    KayliiSurvivalCharacterDB =
        type(KayliiSurvivalCharacterDB) == "table"
        and KayliiSurvivalCharacterDB or {}

    -- The 1.x table is read only.  Existing 2.x settings always win so an
    -- old installation cannot overwrite changes made in the new module.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if type(key) == "string" and key:match("^survival")
                and KayliiSurvivalDB[key] == nil then
                KayliiSurvivalDB[key] = Copy(value)
            end
        end
    end
    if type(KayliiHelperCharacterDB) == "table" then
        for key, value in pairs(KayliiHelperCharacterDB) do
            if type(key) == "string" and key:match("^survival")
                and KayliiSurvivalCharacterDB[key] == nil then
                KayliiSurvivalCharacterDB[key] = Copy(value)
            end
        end
    end
    for key, value in pairs(defaults) do
        if KayliiSurvivalDB[key] == nil then
            KayliiSurvivalDB[key] = Copy(value)
        end
    end

    module.db = KayliiSurvivalDB
    module.characterDB = KayliiSurvivalCharacterDB
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("survival", {
            title = "Survival Helper",
            open = function() module:OpenWindow() end,
        })
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == ADDON_NAME then
        Initialize()
    elseif event == "PLAYER_LOGIN" then
        if not module.db then Initialize() end
        module:InitializeSurvivalHelper()
        module:CreateOptions()
    end
end)
