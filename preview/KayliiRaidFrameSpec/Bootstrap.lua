local ADDON_NAME, module = ...
local defaults = {
    partyFrameSpecCustomEnabled = {},
    partyFrameSpecCustomEnabledMigrated = false,
    partyFrameSpecOrientations = {},
    partyFrameSpecPositions = {},
    partyFrameSpecScaleEnabled = {},
    partyFrameSpecScaleValues = {},
    raidFrameSpecBaselineVersion = 0,
    raidFrameSpecEllesmereDefaults = {},
    raidFrameSpecEnabled = false,
    raidFrameSpecManageParty = true,
    raidFrameSpecManageRaid = true,
    raidFrameSpecNativePositions = false,
    raidFrameSpecPositions = {},
    raidFrameSpecScaleEnabled = {},
    raidFrameSpecScaleValues = {},
}


local function Copy(value)
    if type(value) ~= "table" then return value end
    local copied = {}
    for key, child in pairs(value) do copied[Copy(key)] = Copy(child) end
    return copied
end

local function Initialize()
    _G.KayliiRaidSpecDB = type(_G.KayliiRaidSpecDB) == "table" and _G.KayliiRaidSpecDB or {}
    _G.KayliiRaidSpecCharacterDB = type(_G.KayliiRaidSpecCharacterDB) == "table" and _G.KayliiRaidSpecCharacterDB or {}
    module.db = _G.KayliiRaidSpecDB
    module.characterDB = _G.KayliiRaidSpecCharacterDB
    -- Never write to the legacy 1.x tables. Existing 2.x values win.
    if type(KayliiHelperDB) == "table" then
        for key, value in pairs(KayliiHelperDB) do
            if ((type(key) == "string" and (key:match("^raidFrameSpec") or key:match("^partyFrameSpec")))) and module.db[key] == nil then module.db[key] = Copy(value) end
        end
    end
    for key, value in pairs(defaults) do
        if module.db[key] == nil then module.db[key] = Copy(value) end
    end
    if _G.KayliiHelper2 and _G.KayliiHelper2.RegisterModule then
        _G.KayliiHelper2:RegisterModule("raidspec", {
            title = "Raid Frame Spec", open = function() module:OpenWindow() end,
        })
    end
end

module.title = "Raid Frame Spec"
module.pages = {
    { title = "Raid & party", rows = {
        { "Enable per-spec layouts", "raidFrameSpecEnabled", "toggle", "SetRaidFrameSpecEnabled" },
        { "Manage raid frames", "raidFrameSpecManageRaid", "toggle", "QueueRaidFrameSpecApply" },
        { "Manage party frames", "raidFrameSpecManageParty", "toggle", "QueueRaidFrameSpecApply" },
        { "Show raid mover", "ShowRaidFrameSpecMover", "action", "" },
        { "Save raid position", "SaveRaidFrameSpecMoverPosition", "action", "" },
        { "Show party mover", "ShowPartyFrameSpecMover", "action", "" },
        { "Save party position", "SavePartyFrameSpecMoverPosition", "action", "" },
    } },
    { title = "Saved specs", rows = {
        { "Apply current spec", "QueueRaidFrameSpecApply", "action", "" },
        { "Hide movers", "HideRaidFrameSpecMovers", "action", "" },
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
        module:InitializeRaidFrameSpec()
    end
end)

SLASH_KAYLII_RAIDSPEC1 = "/kayraidspec"
SlashCmdList["KAYLII_RAIDSPEC"] = function() module:OpenWindow() end
