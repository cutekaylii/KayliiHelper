local ADDON_NAME, BW = ...

local BUFF_GROUP = "BuffWhitelist_Buffs"
local DEBUFF_GROUP = "BuffWhitelist_Debuffs"
local BUFF_EXTRA_GROUP = "BuffWhitelist_BuffWhitelistExtras"
local DEBUFF_EXTRA_GROUP = "BuffWhitelist_DebuffWhitelistExtras"
local BUFF_BOSS_GROUP = "BuffWhitelist_BossBuffs"
local BUFF_IMPORTANT_GROUP = "BuffWhitelist_ImportantBuffs"

local BASE_ICON_SIZE = 18
local ICON_SPACING = 2
local TARGET_BASE_X = 45
local DEFAULT_Y = 6
local ATTACH_GAP = 4
local MAX_AURAS = 40
local DEBUFF_BORDER_OUTSET = 1

BW.containers = BW.containers or {}
BW.previewHolders = BW.previewHolders or {}
BW.previewFrames = BW.previewFrames or {
    buff = {},
    debuff = {},
}

local defaults = {
    buffWhitelistModuleEnabled = true,

    helperWindowWidth = 1100,
    helperWindowHeight = 900,
    helperWindowX = 0,
    helperWindowY = 0,
    applyToFocus = false,
    onlyMyBuffs = false,
    onlyMyDebuffs = false,

    useBuffFilter = true,
    useDebuffFilter = true,

    -- Show all of my auras, plus enabled Filter List spells from any caster.
    buffMinePlusWhitelist = false,
    debuffMinePlusWhitelist = false,

    buffSortMode = "default",
    debuffSortMode = "unitframe",

    -- Keep encounter-critical enemy buffs visible even when the normal
    -- buff lane is Mine Only / Whitelist Only / Mine + Whitelist.
    showImportantBossBuffs = true,

    iconSize = 18,
    showLayoutPreview = false,

    hideBuffTooltips = true,
    hideDebuffTooltips = true,

    showBuffDuration = true,
    buffDurationFont = "FRIZ",
    buffDurationSize = 11,
    buffDurationColor = { 1, 1, 1, 1 },
    buffDurationOutline = "NONE",
    hideBuffLongDurationText = false,
    buffLongDurationTextMinutes = 60,

    showBuffStacks = true,
    buffStackFont = "FRIZ",
    buffStackSize = 11,
    buffStackColor = { 1, 1, 1, 1 },
    buffStackOutline = "OUTLINE",

    showDebuffDuration = true,
    debuffDurationFont = "FRIZ",
    debuffDurationSize = 11,
    debuffDurationColor = { 1, 1, 1, 1 },
    debuffDurationOutline = "NONE",
    hideDebuffLongDurationText = false,
    debuffLongDurationTextMinutes = 60,

    showDebuffStacks = true,
    debuffStackFont = "FRIZ",
    debuffStackSize = 11,
    debuffStackColor = { 1, 1, 1, 1 },
    debuffStackOutline = "OUTLINE",

    hidePermanentBuffs = false,
    hidePermanentDebuffs = false,

    showDebuffRedBorder = false,

    -- Lust Up module.
    lustUpEnabled = true,
    lustUpVoiceEnabled = true,
    lustUpBossPullVoiceEnabled = true,
    lustUpReadyVoiceText = "Lust up",
    lustUpReadyChatChannel = "OFF",
    lustUpBossPullVoiceText = "Lust off cooldown",
    lustUpDisplayMode = "ready",
    lustUpOnlyInCombat = false,
    lustUpOnlyInInstance = false,
    lustUpShowInDungeons = true,
    lustUpShowInRaids = true,
    lustUpReadyAlpha = 100,
    lustUpLockedAlpha = 100,
    lustUpRequireLustAbility = false,
    lustUpAllowDrums = false,
    lustUpIndicatorClickable = false,
    lustUpReadyGlow = false,
    lustUpUnlocked = false,
    lustUpSize = 48,
    lustUpPoint = "CENTER",
    lustUpX = 0,
    lustUpY = -160,
    lustUpIconSpellID = 2825,
    lustUpCustomLockouts = {},
    lustUpCustomDrumItems = {},

    -- My Stats module.
    statsModuleEnabled = false,
    statsUnlocked = false,
    statsFontSize = 14,
    statsOrientation = "horizontal",
    statsTextAlign = "center",
    statsShowCrit = true,
    statsShowHaste = true,
    statsShowMastery = true,
    statsShowVersatility = true,
    statsCritColor = { 1.00, 0.42, 0.35, 1 },
    statsHasteColor = { 0.35, 0.85, 0.45, 1 },
    statsMasteryColor = { 0.67, 0.48, 1.00, 1 },
    statsVersatilityColor = { 0.30, 0.72, 1.00, 1 },
    statsOnlyInCombat = false,
    statsOnlyOutOfCombat = false,
    statsOnlyInInstance = false,
    statsShowBackground = true,
    statsPoint = "CENTER",
    statsX = 0,
    statsY = -220,

    -- Survival Helper module.
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

    -- Talent Loadout module.
    talentLoadoutEnabled = false,
    talentLoadoutUnlocked = false,
    talentLoadoutFontSize = 14,
    talentLoadoutOrientation = "vertical",
    talentLoadoutShowSpec = true,
    talentLoadoutShowName = true,
    talentLoadoutShowHero = true,
    talentLoadoutShowBackground = true,
    talentLoadoutPoint = "CENTER",
    talentLoadoutX = 260,
    talentLoadoutY = -220,

    -- Raid Frame Spec module (EllesmereUI Raid Frames companion).
    raidFrameSpecEnabled = false,
    raidFrameSpecManageRaid = true,
    raidFrameSpecManageParty = true,
    raidFrameSpecPositions = {},
    partyFrameSpecPositions = {},
    partyFrameSpecOrientations = {},
    partyFrameSpecCustomEnabled = {},
    partyFrameSpecCustomEnabledMigrated = false,
    raidFrameSpecScaleEnabled = {},
    raidFrameSpecScaleValues = {},
    partyFrameSpecScaleEnabled = {},
    partyFrameSpecScaleValues = {},
    raidFrameSpecNativePositions = false,
    raidFrameSpecEllesmereDefaults = {},
    raidFrameSpecBaselineVersion = 0,


    -- Global minimap launcher.
    minimapButtonShown = true,
    minimapButtonAngle = 225,

    buffOffsetX = 0,
    buffOffsetY = 29,
    buffColumns = 5,
    buffRows = 1,
    buffGrowLeft = false,
    buffGrowDown = false,

    -- Detached = its own TargetFrame anchor.
    -- aboveBuffs / belowBuffs = attached to the buff grid.
    debuffAnchorMode = "belowBuffs",
    debuffOffsetX = 0,
    debuffOffsetY = 0,
    debuffColumns = 5,
    debuffRows = 1,
    debuffGrowLeft = false,
    debuffGrowDown = false,

    buffs = {},
    debuffs = {},

    -- Always-hide lists. These are applied whether the normal spell filter
    -- is enabled or disabled.
    buffBlacklist = {},
    debuffBlacklist = {},
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                CopyDefaults(value, target[key])
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            CopyDefaults(value, target[key])
        end
    end
end

local function Clamp(value, low, high)
    value = tonumber(value) or low

    if value < low then
        return low
    elseif value > high then
        return high
    end

    return value
end

local function MigrateLayout(db)
    local oldIconSize = Clamp(db.iconSize or 18, 12, 36)
    local oldX = tonumber(db.offsetX) or 0
    local oldY = tonumber(db.offsetY) or DEFAULT_Y
    local oldGap = oldIconSize + 5

    if db.buffOffsetX == nil then
        db.buffOffsetX = oldX
    end

    if db.buffOffsetY == nil then
        if db.debuffsOnTop then
            db.buffOffsetY = oldY
        else
            db.buffOffsetY = oldY + oldGap
        end
    end

    if db.debuffOffsetX == nil then
        db.debuffOffsetX = 0
    end

    if db.debuffOffsetY == nil then
        db.debuffOffsetY = 0
    end

    if db.debuffAnchorMode == nil then
        db.debuffAnchorMode = db.debuffsOnTop and "aboveBuffs" or "belowBuffs"
    end

    if db.buffColumns == nil then
        db.buffColumns = math.max(1, math.min(10, tonumber(db.maxBuffs) or 5))
    end

    if db.buffRows == nil then
        db.buffRows = 1
    end

    if db.debuffColumns == nil then
        db.debuffColumns = math.max(1, math.min(10, tonumber(db.maxDebuffs) or 5))
    end

    if db.debuffRows == nil then
        db.debuffRows = 1
    end

    if db.buffGrowLeft == nil then
        db.buffGrowLeft = db.buffsGrowLeft and true or false
    end

    if db.debuffGrowLeft == nil then
        db.debuffGrowLeft = db.debuffsGrowLeft and true or false
    end

    if db.buffGrowDown == nil then
        db.buffGrowDown = false
    end

    if db.debuffGrowDown == nil then
        db.debuffGrowDown = false
    end
end

function BW:InitializeDB()
    KayliiHelperDB = KayliiHelperDB or BuffWhitelistDB or {}
BuffWhitelistDB = KayliiHelperDB
    KayliiHelperCharacterDB = KayliiHelperCharacterDB or {}
    self.characterDB = KayliiHelperCharacterDB

    if KayliiHelperDB.spells and not KayliiHelperDB.buffs then
        KayliiHelperDB.buffs = KayliiHelperDB.spells
    end

    if C_CVar and C_CVar.SetCVar then
        if KayliiHelperDB.hideBlizzardBuffs == true then
            C_CVar.SetCVar("raidFramesDisplayBuffs", "1")
        end

        if KayliiHelperDB.hideBlizzardDebuffs == true then
            C_CVar.SetCVar("raidFramesDisplayDebuffs", "1")
        end
    end

    MigrateLayout(BuffWhitelistDB)
    CopyDefaults(defaults, BuffWhitelistDB)

    -- Previous builds stored hidden filtered debuffs as `false` in the
    -- debuff table. Preserve that intent by copying those entries into the
    -- new always-active blacklist.
    local legacyDisabledDebuffs = {}

    for spellID, enabled in pairs(KayliiHelperDB.debuffs or {}) do
        if enabled == false then
            KayliiHelperDB.debuffBlacklist[spellID] = true
            legacyDisabledDebuffs[#legacyDisabledDebuffs + 1] = spellID
        end
    end

    -- The whitelist now stores only enabled entries. Disabled/false entries
    -- belonged to the old pre-blacklist model and are removed after migration.
    for _, spellID in ipairs(legacyDisabledDebuffs) do
        KayliiHelperDB.debuffs[spellID] = nil
    end

    -- Remove obsolete layout keys after migration.
    KayliiHelperDB.hideBlizzardBuffs = nil
    KayliiHelperDB.hideBlizzardDebuffs = nil
    KayliiHelperDB.spells = nil
    KayliiHelperDB.offsetX = nil
    KayliiHelperDB.offsetY = nil
    KayliiHelperDB.debuffsOnTop = nil
    KayliiHelperDB.buffsGrowLeft = nil
    KayliiHelperDB.debuffsGrowLeft = nil
    KayliiHelperDB.maxBuffs = nil
    KayliiHelperDB.maxDebuffs = nil

    self.db = KayliiHelperDB
end

local function GetEnabledSpellMap(source)
    local result = {}
    local count = 0

    for spellID, enabled in pairs(source or {}) do
        spellID = tonumber(spellID)

        if spellID and enabled then
            result[spellID] = true
            count = count + 1
        end
    end

    if count == 0 then
        result[0] = true
    end

    return result
end

local function GetRealEnabledSpellMap(source)
    local result = {}
    local count = 0

    for spellID, enabled in pairs(source or {}) do
        spellID = tonumber(spellID)

        if spellID and enabled then
            result[spellID] = true
            count = count + 1
        end
    end

    return result, count
end

local function GetDisabledSpellMap(source)
    local result = {}

    for spellID, enabled in pairs(source or {}) do
        spellID = tonumber(spellID)

        if spellID and enabled == false then
            result[spellID] = true
        end
    end

    return result
end


local function GetBlacklistMap(source)
    local result = {}

    for spellID, blocked in pairs(source or {}) do
        spellID = tonumber(spellID)

        if spellID and blocked then
            result[spellID] = true
        end
    end

    return result
end

local function MergeSpellMaps(first, second)
    local result = {}

    for spellID in pairs(first or {}) do
        result[spellID] = true
    end

    for spellID in pairs(second or {}) do
        result[spellID] = true
    end

    return result
end

function BW:GetAuraFilter(kind)
    if kind == "buff" then
        local filter

        if self.db.buffMinePlusWhitelist then
            filter = "HELPFUL|PLAYER"
        else
            filter = self.db.onlyMyBuffs
                and "HELPFUL|PLAYER"
                or "HELPFUL"
        end

        -- IMPORTANT buffs are handled by a dedicated high-priority lane.
        -- Excluding them here prevents duplicate icons.
        if self.db.showImportantBossBuffs then
            filter = filter .. "|!IMPORTANT"
        end

        return filter
    end

    if self.db.debuffMinePlusWhitelist then
        return "HARMFUL|PLAYER"
    end

    -- Whitelist-only debuffs can come from any caster. "Only mine" narrows
    -- that same whitelist to the PLAYER lane.
    return self.db.onlyMyDebuffs
        and "HARMFUL|PLAYER"
        or "HARMFUL"
end

local function GetAuraSort(kind)
    if kind == "buff" then
        local mode = BW.db.buffSortMode or "default"

        if mode == "defensive" then
            return AuraContainerSortMethod.BigDefensive,
                AuraContainerSortDirection.Normal
        elseif mode == "important" then
            return AuraContainerSortMethod.ImportantOnly,
                AuraContainerSortDirection.Normal
        elseif mode == "expiration" then
            return AuraContainerSortMethod.Expiration,
                AuraContainerSortDirection.Normal
        elseif mode == "expirationReverse" then
            return AuraContainerSortMethod.Expiration,
                AuraContainerSortDirection.Reverse
        elseif mode == "name" then
            return AuraContainerSortMethod.Name,
                AuraContainerSortDirection.Normal
        end

        return AuraContainerSortMethod.Default,
            AuraContainerSortDirection.Normal
    end

    local mode = BW.db.debuffSortMode or "unitframe"

    if mode == "default" then
        return AuraContainerSortMethod.Default,
            AuraContainerSortDirection.Normal
    elseif mode == "expiration" then
        return AuraContainerSortMethod.Expiration,
            AuraContainerSortDirection.Normal
    elseif mode == "expirationReverse" then
        return AuraContainerSortMethod.Expiration,
            AuraContainerSortDirection.Reverse
    elseif mode == "name" then
        return AuraContainerSortMethod.Name,
            AuraContainerSortDirection.Normal
    end

    return AuraContainerSortMethod.UnitFrameDebuff,
        AuraContainerSortDirection.Normal
end

local FONT_PATHS = {
    FRIZ = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    ARIAL = "Fonts\\ARIALN.TTF",
    MORPHEUS = "Fonts\\MORPHEUS.TTF",
    SKURRI = "Fonts\\SKURRI.TTF",
}

local function GetFontPath(key)
    return FONT_PATHS[key] or FONT_PATHS.FRIZ
end

local function GetTextScaleCompensation()
    local iconScale =
        Clamp(BW.db.iconSize, 12, 36) / BASE_ICON_SIZE

    if iconScale <= 0 then
        return 1
    end

    return 1 / iconScale
end

local function SafeColor(color)
    if type(color) ~= "table" then
        return 1, 1, 1, 1
    end

    return
        tonumber(color[1]) or 1,
        tonumber(color[2]) or 1,
        tonumber(color[3]) or 1,
        tonumber(color[4]) or 1
end

local function GetFontFlags(value)
    if value == "NONE" then
        return ""
    elseif value == "THICKOUTLINE" then
        return "THICKOUTLINE"
    end

    return "OUTLINE"
end

local function CreateDurationFormatter(hideLongDuration, limitMinutes)
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter then
        return nil
    end

    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    local rules = {}

    local limitSeconds
    if hideLongDuration then
        limitSeconds = Clamp(limitMinutes, 1, 10080) * 60

        rules[#rules + 1] = {
            threshold = limitSeconds,
            format = "",
        }
    else
        limitSeconds = math.huge
    end

    if 86400 < limitSeconds then
        rules[#rules + 1] = {
            threshold = 86400,
            format = "%dd",
            components = {
                {
                    div = 86400,
                    rounding = Enum.NumericRuleFormatRounding.Down,
                },
            },
        }
    end

    if 3600 < limitSeconds then
        rules[#rules + 1] = {
            threshold = 3600,
            format = "%dh",
            components = {
                {
                    div = 3600,
                    rounding = Enum.NumericRuleFormatRounding.Down,
                },
            },
        }
    end

    if 60 < limitSeconds then
        rules[#rules + 1] = {
            threshold = 60,
            format = "%dm",
            components = {
                {
                    div = 60,
                    rounding = Enum.NumericRuleFormatRounding.Down,
                },
            },
        }
    end

    -- Seconds intentionally have NO "s" suffix.
    rules[#rules + 1] = {
        threshold = 0.001,
        format = "%d",
        step = 1,
        rounding = Enum.NumericRuleFormatRounding.Up,
    }

    rules[#rules + 1] = {
        threshold = 0,
        format = "",
    }

    formatter:SetBreakpoints(rules)
    return formatter
end

local function GetTextStyle(kind)
    if kind == "buff" then
        return {
            showDuration = BW.db.showBuffDuration,
            durationFont = GetFontPath(BW.db.buffDurationFont),
            durationSize = Clamp(BW.db.buffDurationSize, 6, 32),
            durationColor = BW.db.buffDurationColor,
            durationOutline = GetFontFlags(BW.db.buffDurationOutline),

            hideLongDurationText = BW.db.hideBuffLongDurationText,
            longDurationTextMinutes =
                Clamp(BW.db.buffLongDurationTextMinutes, 1, 10080),

            showStacks = BW.db.showBuffStacks,
            stackFont = GetFontPath(BW.db.buffStackFont),
            stackSize = Clamp(BW.db.buffStackSize, 6, 32),
            stackColor = BW.db.buffStackColor,
            stackOutline = GetFontFlags(BW.db.buffStackOutline),

            hideTooltip = BW.db.hideBuffTooltips,
        }
    end

    return {
        showDuration = BW.db.showDebuffDuration,
        durationFont = GetFontPath(BW.db.debuffDurationFont),
        durationSize = Clamp(BW.db.debuffDurationSize, 6, 32),
        durationColor = BW.db.debuffDurationColor,
        durationOutline = GetFontFlags(BW.db.debuffDurationOutline),

        hideLongDurationText = BW.db.hideDebuffLongDurationText,
        longDurationTextMinutes =
            Clamp(BW.db.debuffLongDurationTextMinutes, 1, 10080),

        showStacks = BW.db.showDebuffStacks,
        stackFont = GetFontPath(BW.db.debuffStackFont),
        stackSize = Clamp(BW.db.debuffStackSize, 6, 32),
        stackColor = BW.db.debuffStackColor,
        stackOutline = GetFontFlags(BW.db.debuffStackOutline),

        hideTooltip = BW.db.hideDebuffTooltips,
    }
end

local function AddDebuffRedBorder(button, cooldown)
    local borderFrame = CreateFrame("Frame", nil, button)
    borderFrame:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    borderFrame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    borderFrame:SetFrameStrata(button:GetFrameStrata())

    local baseLevel = button:GetFrameLevel() or 1
    if cooldown and cooldown.GetFrameLevel then
        baseLevel = math.max(
            baseLevel,
            cooldown:GetFrameLevel() or baseLevel
        )
    end

    borderFrame:SetFrameLevel(baseLevel + 8)
    borderFrame:EnableMouse(false)

    local thickness = 2

    local top = borderFrame:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(1, 0.03, 0.03, 1)
    top:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, 0)
    top:SetHeight(thickness)

    local bottom = borderFrame:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(1, 0.03, 0.03, 1)
    bottom:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(thickness)

    local left = borderFrame:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(1, 0.03, 0.03, 1)
    left:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", 0, 0)
    left:SetWidth(thickness)

    local right = borderFrame:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(1, 0.03, 0.03, 1)
    right:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(thickness)

    button.DebuffRedBorder = borderFrame
end

local function InitializeAuraButton(button, kind)
    button:SetSize(BASE_ICON_SIZE, BASE_ICON_SIZE)

    local style = GetTextStyle(kind)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    button.Icon = icon
    button:SetIcon(icon)

    -- Keep the cooldown sweep, but use AuraButton:SetDurationText for the
    -- visible timer so font and size are fully under addon control.
    local cooldown = CreateFrame(
        "Cooldown",
        nil,
        button,
        "CooldownFrameTemplate"
    )
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(true)

    -- Desired aura feel:
    -- start with the icon fully visible, then let a dark swipe FILL IN
    -- as the aura is consumed.
    if cooldown.SetDrawSwipe then
        cooldown:SetDrawSwipe(true)
    end
    if cooldown.SetSwipeColor then
        cooldown:SetSwipeColor(0, 0, 0, 0.72)
    end
    if cooldown.SetReverse then
        cooldown:SetReverse(true)
    end

    button.Cooldown = cooldown
    button:SetDurationCooldown(cooldown)

    if kind == "debuff" and BW.db.showDebuffRedBorder then
        AddDebuffRedBorder(button, cooldown)
    end

    local textOverlay = CreateFrame("Frame", nil, button)
    textOverlay:SetAllPoints()
    textOverlay:SetFrameStrata(button:GetFrameStrata())
    textOverlay:SetFrameLevel(cooldown:GetFrameLevel() + 10)
    button.TextOverlay = textOverlay

    if style.showDuration then
        local duration = textOverlay:CreateFontString(
            nil,
            "OVERLAY"
        )
        duration:SetPoint("TOP", textOverlay, "TOP", 0, -1)
        duration:SetWidth(BASE_ICON_SIZE + 8)
        duration:SetHeight(BASE_ICON_SIZE / 2)
        duration:SetJustifyH("CENTER")
        duration:SetJustifyV("MIDDLE")
        duration:SetDrawLayer("OVERLAY", 15)
        if duration.SetMaxLines then
            duration:SetMaxLines(1)
        end
        if duration.SetNonSpaceWrap then
            duration:SetNonSpaceWrap(false)
        end
        if duration.SetWordWrap then
            duration:SetWordWrap(false)
        end

        local textCompensation = GetTextScaleCompensation()

        duration:SetFont(
            style.durationFont,
            style.durationSize * textCompensation,
            style.durationOutline
        )

        button.DurationText = duration

        local durationOptions = {}
        durationOptions.textFormatter =
            CreateDurationFormatter(
                style.hideLongDurationText,
                style.longDurationTextMinutes
            )

        button:SetDurationText(duration, durationOptions)

        -- FontString does not support OnTextChanged in WoW. Keep duration
        -- styling static and taint-safe instead of attaching an invalid script.
        local r, g, b, a = SafeColor(style.durationColor)
        duration:SetTextColor(r, g, b, a)

        if style.durationOutline == "" then
            duration:SetShadowColor(0, 0, 0, 0.85)
            duration:SetShadowOffset(1, -1)
        else
            duration:SetShadowColor(0, 0, 0, 0)
            duration:SetShadowOffset(0, 0)
        end
    end

    if style.showStacks then
        local count = textOverlay:CreateFontString(
            nil,
            "OVERLAY"
        )
        count:SetPoint(
            "BOTTOMRIGHT",
            textOverlay,
            "BOTTOMRIGHT",
            1,
            0
        )
        count:SetJustifyH("RIGHT")
        count:SetJustifyV("BOTTOM")
        count:SetDrawLayer("OVERLAY", 15)
        count:SetShadowColor(0, 0, 0, 1)
        count:SetShadowOffset(1, -1)
        local textCompensation = GetTextScaleCompensation()

        count:SetFont(
            style.stackFont,
            style.stackSize * textCompensation,
            style.stackOutline
        )

        local r, g, b, a = SafeColor(style.stackColor)
        count:SetTextColor(r, g, b, a)

        button.Count = count
        button:SetApplicationCount(count, {})
    end

    -- Retail 12.1 AuraButton tooltips are automatic. Blizzard's supported
    -- switch for suppressing them is mouse-motion input on the AuraButton.
    button:SetMouseMotionEnabled(not style.hideTooltip)
    button:SetMouseClickEnabled(false)

    if not style.hideTooltip then
        button:SetTooltipAnchorPoint("ANCHOR_RIGHT")
    end
end

local function InitializeBuffAuraButton(button)
    InitializeAuraButton(button, "buff")
end

local function InitializeDebuffAuraButton(button)
    InitializeAuraButton(button, "debuff")
end

local function HideBuiltInAuraButtons(frame)
    if not frame or not frame.GetName then
        return
    end

    local name = frame:GetName()
    if not name then
        return
    end

    frame.maxBuffs = 0
    frame.maxDebuffs = 0

    for i = 1, 32 do
        local button = _G[name .. "Buff" .. i]
        if button then
            button:Hide()
        end
    end

    for i = 1, 16 do
        local button = _G[name .. "Debuff" .. i]
        if button then
            button:Hide()
        end
    end
end

function BW:IsManagedFrame(frame)
    if frame == TargetFrame then
        return true
    end

    return self.db
        and self.db.applyToFocus
        and FocusFrame
        and frame == FocusFrame
end

local function GetFlowAnchorPoint(growLeft, growDown)
    local vertical = growDown and "TOP" or "BOTTOM"
    local horizontal = growLeft and "RIGHT" or "LEFT"
    return vertical .. horizontal
end

local function GetKindConfig(kind)
    local isBuff = kind == "buff"

    local columns = Clamp(
        isBuff and BW.db.buffColumns or BW.db.debuffColumns,
        1,
        10
    )

    local rows = Clamp(
        isBuff and BW.db.buffRows or BW.db.debuffRows,
        1,
        10
    )

    local growLeft = isBuff
        and (BW.db.buffGrowLeft and true or false)
        or (BW.db.debuffGrowLeft and true or false)

    local growDown = isBuff
        and (BW.db.buffGrowDown and true or false)
        or (BW.db.debuffGrowDown and true or false)

    local capacity = math.min(MAX_AURAS, columns * rows)

    local minePlusWhitelist = isBuff
        and BW.db.buffMinePlusWhitelist
        or BW.db.debuffMinePlusWhitelist

    local blacklist = GetBlacklistMap(
        isBuff
            and BW.db.buffBlacklist
            or BW.db.debuffBlacklist
    )

    local whitelist, whitelistCount = GetRealEnabledSpellMap(
        isBuff and BW.db.buffs or BW.db.debuffs
    )

    -- Blacklist always wins. Remove blacklisted IDs from the whitelist map
    -- before calculating Mine + Whitelist slot reservation.
    for spellID in pairs(blacklist) do
        if whitelist[spellID] then
            whitelist[spellID] = nil
            whitelistCount = math.max(0, whitelistCount - 1)
        end
    end

    local candidateFilters = {}
    local extraCandidateFilters
    local mainMaxCount = capacity
    local extraMaxCount = 0

    if minePlusWhitelist then
        -- Secure OR model:
        --   lane 1 = all PLAYER auras
        --   lane 2 = explicit whitelist IDs from any caster
        --
        -- Whitelist IDs are excluded from lane 1 so the same aura cannot
        -- appear twice when it was cast by the player.
        candidateFilters.excludeSpellIDs =
            MergeSpellMaps(blacklist, whitelist)

        if whitelistCount > 0 then
            -- Explicit whitelist entries bypass the hide-permanent/infinite
            -- toggle by design. Blacklist is still applied below and wins.
            extraCandidateFilters = {
                includeSpellIDs = whitelist,
            }

            if next(blacklist) then
                extraCandidateFilters.excludeSpellIDs = blacklist
            end

            -- Mine + Whitelist is an additive union of two secure groups.
            -- Do NOT reserve the PLAYER group's slots from the number of
            -- configured whitelist IDs: inactive whitelist entries would
            -- otherwise steal capacity and can reduce the mine lane to zero.
            --
            -- Keep the PLAYER lane at the full configured capacity. The
            -- whitelist lane is capped by both its ID count and grid capacity.
            -- This mirrors the practical 12.1 multi-group model used by other
            -- unit-frame implementations: caps are per AuraGroup, not a
            -- dynamically shared total across the union.
            extraMaxCount = math.min(whitelistCount, capacity)
            mainMaxCount = capacity
        end

    elseif isBuff then
        if BW.db.useBuffFilter then
            candidateFilters.includeSpellIDs =
                GetEnabledSpellMap(BW.db.buffs)
        end

        if next(blacklist) then
            candidateFilters.excludeSpellIDs = blacklist
        end

    else
        -- Debuff Filter List is now a true whitelist, matching buffs.
        if BW.db.useDebuffFilter then
            candidateFilters.includeSpellIDs =
                GetEnabledSpellMap(BW.db.debuffs)
        end

        if next(blacklist) then
            candidateFilters.excludeSpellIDs = blacklist
        end
    end

    local hidePermanent
    if isBuff then
        hidePermanent = BW.db.hidePermanentBuffs
    else
        hidePermanent = BW.db.hidePermanentDebuffs
    end

    local whitelistOnly
    if isBuff then
        whitelistOnly = BW.db.useBuffFilter
    else
        whitelistOnly = BW.db.useDebuffFilter
    end

    if hidePermanent then
        if minePlusWhitelist then
            -- Only the broad PLAYER lane is filtered for permanent/infinite
            -- auras. The explicit whitelist lane intentionally bypasses this
            -- toggle so whitelisted long/permanent auras always remain visible.
            candidateFilters.maxDuration = math.huge

        elseif whitelistOnly then
            -- A true whitelist is explicit user intent. Do not add the
            -- permanent/infinite duration filter to this group.
            candidateFilters.maxDuration = nil

        else
            -- Show-All / Only-Mine modes obey the permanent/infinite toggle.
            candidateFilters.maxDuration = math.huge

            -- Explicitly whitelisted auras are an exception to the hide rule,
            -- even when the normal spell filter is currently off. Put them in
            -- a separate secure lane without maxDuration and remove them from
            -- the broad lane to prevent duplicates.
            if whitelistCount > 0 then
                candidateFilters.excludeSpellIDs =
                    MergeSpellMaps(
                        candidateFilters.excludeSpellIDs or {},
                        whitelist
                    )

                extraCandidateFilters = {
                    includeSpellIDs = whitelist,
                }

                if next(blacklist) then
                    extraCandidateFilters.excludeSpellIDs = blacklist
                end

                extraMaxCount = math.min(whitelistCount, capacity)
                mainMaxCount = capacity
            end
        end
    end

    -- Defensive guarantee: the explicit whitelist lane must never inherit the
    -- permanent/infinite duration restriction.
    if extraCandidateFilters then
        extraCandidateFilters.maxDuration = nil
    end

    local showImportantBossBuffs =
        isBuff and BW.db.showImportantBossBuffs

    if showImportantBossBuffs then
        -- Boss buffs get their own group. Remove them from every normal buff
        -- lane so a boss+whitelisted/player aura cannot render twice.
        candidateFilters.isBossAura = false

        if extraCandidateFilters then
            extraCandidateFilters.isBossAura = false
        end
    end

    local sortMethod, sortDirection = GetAuraSort(kind)

    return {
        groupKey = isBuff and BUFF_GROUP or DEBUFF_GROUP,
        extraGroupKey = isBuff
            and BUFF_EXTRA_GROUP
            or DEBUFF_EXTRA_GROUP,

        columns = columns,
        rows = rows,
        maxCount = mainMaxCount,
        totalCapacity = capacity,
        growLeft = growLeft,
        growDown = growDown,
        xDirection = growLeft and -1 or 1,
        yDirection = growDown and -1 or 1,
        flowAnchor = GetFlowAnchorPoint(growLeft, growDown),

        candidateFilters = candidateFilters,
        extraCandidateFilters = extraCandidateFilters,
        extraMaxCount = extraMaxCount,
        extraFilterString = isBuff
            and (
                BW.db.showImportantBossBuffs
                and "HELPFUL|!IMPORTANT"
                or "HELPFUL"
            )
            or "HARMFUL",

        showImportantBossBuffs = showImportantBossBuffs,
        bossGroupKey = BUFF_BOSS_GROUP,
        importantGroupKey = BUFF_IMPORTANT_GROUP,
        bossFilterString = "HELPFUL|INCLUDE_NAME_PLATE_ONLY",
        importantFilterString =
            "HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY",
        bossCandidateFilters = {
            isBossAura = true,
        },
        importantCandidateFilters = {
            -- Boss+Important belongs to the boss lane, so it only renders once.
            isBossAura = false,
        },

        sortMethod = sortMethod,
        sortDirection = sortDirection,
    }
end

local function GetLogicalGridSize(config)
    local width = (config.columns * BASE_ICON_SIZE)
        + ((config.columns - 1) * ICON_SPACING)

    local height = (config.rows * BASE_ICON_SIZE)
        + ((config.rows - 1) * ICON_SPACING)

    return math.max(BASE_ICON_SIZE, width), math.max(BASE_ICON_SIZE, height)
end


local function GetDetachedOffsets(kind)
    if kind == "buff" then
        return
            Clamp(BW.db.buffOffsetX, -300, 400),
            Clamp(BW.db.buffOffsetY, -250, 300)
    end

    return
        Clamp(BW.db.debuffOffsetX, -300, 400),
        Clamp(BW.db.debuffOffsetY, -250, 300)
end

local function AnchorGrid(frame, kind, gridFrame, buffGrid)
    local config = GetKindConfig(kind)
    gridFrame:ClearAllPoints()

    if kind == "debuff"
        and BW.db.debuffAnchorMode ~= "detached"
        and buffGrid then

        local relativeX = Clamp(BW.db.debuffOffsetX, -300, 400)
        local relativeY = Clamp(BW.db.debuffOffsetY, -250, 300)

        local leftPoint = config.growLeft and "RIGHT" or "LEFT"

        -- The optional red debuff border extends one logical pixel outside
        -- the debuff button. Add that to the attachment gap so the LIVE
        -- debuff border cannot overlap the buff grid. AnchorGrid is also
        -- used by the preview, so both stay pixel-matched.
        local collisionPadding = 0
        if BW.db.showDebuffRedBorder then
            collisionPadding = DEBUFF_BORDER_OUTSET
        end

        local attachGap = ATTACH_GAP + collisionPadding

        if BW.db.debuffAnchorMode == "aboveBuffs" then
            gridFrame:SetPoint(
                "BOTTOM" .. leftPoint,
                buffGrid,
                "TOP" .. leftPoint,
                relativeX,
                attachGap + relativeY
            )
        else
            gridFrame:SetPoint(
                "TOP" .. leftPoint,
                buffGrid,
                "BOTTOM" .. leftPoint,
                relativeX,
                -attachGap + relativeY
            )
        end

        return
    end

    local offsetX, offsetY = GetDetachedOffsets(kind)

    gridFrame:SetPoint(
        config.flowAnchor,
        frame,
        "TOPLEFT",
        TARGET_BASE_X + offsetX,
        offsetY
    )
end

function BW:ApplyContainerPresentation(frame, kind, container)
    if not frame or not container or not self.db then
        return
    end

    local config = GetKindConfig(kind)
    local logicalWidth, logicalHeight = GetLogicalGridSize(config)
    local scale = Clamp(self.db.iconSize, 12, 36) / BASE_ICON_SIZE

    container:SetScale(scale)
    container:SetSize(logicalWidth, logicalHeight)

    container:SetFlowLayoutAnchorPoint(config.flowAnchor)
    container:SetFlowLayoutGrowthDirection(
        config.xDirection,
        config.yDirection
    )

    if container.SetFlowLayoutAxis
        and AnchorUtil
        and AnchorUtil.FlowLayoutAxis
        and AnchorUtil.FlowLayoutAxis.Horizontal then
        container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
    end

    container:SetFlowLayoutMaximumLineSize(logicalWidth)

    local mainLayoutIndex = 1

    if kind == "buff" and config.showImportantBossBuffs then
        container:SetAuraGroupLayout(config.bossGroupKey, {
            elementWidth = BASE_ICON_SIZE,
            elementHeight = BASE_ICON_SIZE,
            elementSpacing = ICON_SPACING,
            lineSpacing = ICON_SPACING,
            layoutIndex = 1,
        })

        container:SetAuraGroupLayout(config.importantGroupKey, {
            elementWidth = BASE_ICON_SIZE,
            elementHeight = BASE_ICON_SIZE,
            elementSpacing = ICON_SPACING,
            lineSpacing = ICON_SPACING,
            layoutIndex = 2,
        })

        mainLayoutIndex = 3
    end

    container:SetAuraGroupLayout(config.groupKey, {
        elementWidth = BASE_ICON_SIZE,
        elementHeight = BASE_ICON_SIZE,
        elementSpacing = ICON_SPACING,
        lineSpacing = ICON_SPACING,
        layoutIndex = mainLayoutIndex,
    })

    if config.extraCandidateFilters then
        container:SetAuraGroupLayout(config.extraGroupKey, {
            elementWidth = BASE_ICON_SIZE,
            elementHeight = BASE_ICON_SIZE,
            elementSpacing = ICON_SPACING,
            lineSpacing = ICON_SPACING,
            layoutIndex = mainLayoutIndex + 1,
        })
    end

    local buffContainer
    if kind == "debuff"
        and self.containers[frame]
        and self.containers[frame].buff then
        buffContainer = self.containers[frame].buff
    end

    AnchorGrid(frame, kind, container, buffContainer)
end

function BW:ConfigureContainer(kind, container)
    if not container or not self.db then
        return
    end

    local config = GetKindConfig(kind)

    container:SetAuraGroupFilterString(
        config.groupKey,
        self:GetAuraFilter(kind)
    )

    container:SetAuraGroupCandidateFilters(
        config.groupKey,
        config.candidateFilters
    )

    container:SetAuraGroupMaxFrameCount(
        config.groupKey,
        config.maxCount
    )

    container:SetAuraGroupSortMethod(
        config.groupKey,
        config.sortMethod,
        config.sortDirection
    )

    if kind == "buff" and config.showImportantBossBuffs then
        container:SetAuraGroupFilterString(
            config.bossGroupKey,
            config.bossFilterString
        )
        container:SetAuraGroupCandidateFilters(
            config.bossGroupKey,
            config.bossCandidateFilters
        )
        container:SetAuraGroupMaxFrameCount(
            config.bossGroupKey,
            config.totalCapacity
        )
        container:SetAuraGroupSortMethod(
            config.bossGroupKey,
            AuraContainerSortMethod.Default,
            AuraContainerSortDirection.Normal
        )

        container:SetAuraGroupFilterString(
            config.importantGroupKey,
            config.importantFilterString
        )
        container:SetAuraGroupCandidateFilters(
            config.importantGroupKey,
            config.importantCandidateFilters
        )
        container:SetAuraGroupMaxFrameCount(
            config.importantGroupKey,
            config.totalCapacity
        )
        container:SetAuraGroupSortMethod(
            config.importantGroupKey,
            AuraContainerSortMethod.ImportantOnly,
            AuraContainerSortDirection.Normal
        )
    end

    if config.extraCandidateFilters then
        container:SetAuraGroupFilterString(
            config.extraGroupKey,
            config.extraFilterString
        )

        container:SetAuraGroupCandidateFilters(
            config.extraGroupKey,
            config.extraCandidateFilters
        )

        container:SetAuraGroupMaxFrameCount(
            config.extraGroupKey,
            config.extraMaxCount
        )

        container:SetAuraGroupSortMethod(
            config.extraGroupKey,
            config.sortMethod,
            config.sortDirection
        )
    end

    container:UpdateAllAuras()
end

function BW:CreateGroupContainer(frame, unit, kind)
    if not frame or not unit then
        return nil
    end

    self.containers[frame] = self.containers[frame] or {}

    if self.containers[frame][kind] then
        return self.containers[frame][kind]
    end

    local config = GetKindConfig(kind)

    local container = CreateFrame(
        "AuraContainer",
        nil,
        frame,
        "CustomAuraContainerTemplate"
    )

    container:SetSize(1, 1)

    if container.SetFlowLayoutAxis
        and AnchorUtil
        and AnchorUtil.FlowLayoutAxis
        and AnchorUtil.FlowLayoutAxis.Horizontal then
        container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
    end

    if kind == "buff" and config.showImportantBossBuffs then
        container:AddAuraGroup(
            config.bossGroupKey,
            config.bossFilterString,
            {
                maxFrameCount = config.totalCapacity,
                candidateFilters = config.bossCandidateFilters,
                initializeFrame = InitializeBuffAuraButton,
                layout = {
                    elementWidth = BASE_ICON_SIZE,
                    elementHeight = BASE_ICON_SIZE,
                    elementSpacing = ICON_SPACING,
                    lineSpacing = ICON_SPACING,
                    layoutIndex = 1,
                },
                sortMethod = AuraContainerSortMethod.Default,
                sortDirection = AuraContainerSortDirection.Normal,
            }
        )

        container:AddAuraGroup(
            config.importantGroupKey,
            config.importantFilterString,
            {
                maxFrameCount = config.totalCapacity,
                candidateFilters = config.importantCandidateFilters,
                initializeFrame = InitializeBuffAuraButton,
                layout = {
                    elementWidth = BASE_ICON_SIZE,
                    elementHeight = BASE_ICON_SIZE,
                    elementSpacing = ICON_SPACING,
                    lineSpacing = ICON_SPACING,
                    layoutIndex = 2,
                },
                sortMethod = AuraContainerSortMethod.ImportantOnly,
                sortDirection = AuraContainerSortDirection.Normal,
            }
        )
    end

    local mainLayoutIndex =
        (kind == "buff" and config.showImportantBossBuffs)
        and 3
        or 1

    container:AddAuraGroup(
        config.groupKey,
        self:GetAuraFilter(kind),
        {
            maxFrameCount = config.maxCount,
            candidateFilters = config.candidateFilters,
            initializeFrame = kind == "buff"
                and InitializeBuffAuraButton
                or InitializeDebuffAuraButton,
            layout = {
                elementWidth = BASE_ICON_SIZE,
                elementHeight = BASE_ICON_SIZE,
                elementSpacing = ICON_SPACING,
                lineSpacing = ICON_SPACING,
                layoutIndex = mainLayoutIndex,
            },
            sortMethod = config.sortMethod,
            sortDirection = config.sortDirection,
        }
    )

    if config.extraCandidateFilters then
        container:AddAuraGroup(
            config.extraGroupKey,
            config.extraFilterString,
            {
                maxFrameCount = config.extraMaxCount,
                candidateFilters = config.extraCandidateFilters,
                initializeFrame = kind == "buff"
                    and InitializeBuffAuraButton
                    or InitializeDebuffAuraButton,
                layout = {
                    elementWidth = BASE_ICON_SIZE,
                    elementHeight = BASE_ICON_SIZE,
                    elementSpacing = ICON_SPACING,
                    lineSpacing = ICON_SPACING,
                    layoutIndex = mainLayoutIndex + 1,
                },
                sortMethod = config.sortMethod,
                sortDirection = config.sortDirection,
            }
        )
    end

    container:SetUnit(unit)
    container:Show()

    self.containers[frame][kind] = container

    self:ApplyContainerPresentation(frame, kind, container)
    self:ConfigureContainer(kind, container)

    return container
end

local function ApplyFramePresentation(frame)
    local set = BW.containers[frame]
    if not set then
        return
    end

    -- Buffs first because an attached debuff grid anchors to the buff grid.
    if set.buff and set.buff:IsShown() then
        BW:ApplyContainerPresentation(frame, "buff", set.buff)
    end

    if set.debuff and set.debuff:IsShown() then
        BW:ApplyContainerPresentation(frame, "debuff", set.debuff)
    end
end

local function ConfigureFrame(frame)
    local set = BW.containers[frame]
    if not set then
        return
    end

    if set.buff and set.buff:IsShown() then
        BW:ConfigureContainer("buff", set.buff)
    end

    if set.debuff and set.debuff:IsShown() then
        BW:ConfigureContainer("debuff", set.debuff)
    end
end

function BW:SetupTargetFrame()
    if not self:IsBuffWhitelistEnabled() then
        return
    end

    if not TargetFrame then
        return
    end

    HideBuiltInAuraButtons(TargetFrame)

    local buffContainer = self:CreateGroupContainer(
        TargetFrame,
        "target",
        "buff"
    )

    local debuffContainer = self:CreateGroupContainer(
        TargetFrame,
        "target",
        "debuff"
    )

    if buffContainer then
        buffContainer:SetUnit("target")
        buffContainer:Show()
    end

    if debuffContainer then
        debuffContainer:SetUnit("target")
        debuffContainer:Show()
    end

    ApplyFramePresentation(TargetFrame)
    ConfigureFrame(TargetFrame)
    self:RefreshLayoutPreview()
end

function BW:SetupFocusFrame()
    if not self:IsBuffWhitelistEnabled() then
        return
    end

    if not FocusFrame then
        return
    end

    self.containers[FocusFrame] = self.containers[FocusFrame] or {}

    if self.db.applyToFocus then
        HideBuiltInAuraButtons(FocusFrame)

        local buffContainer = self:CreateGroupContainer(
            FocusFrame,
            "focus",
            "buff"
        )

        local debuffContainer = self:CreateGroupContainer(
            FocusFrame,
            "focus",
            "debuff"
        )

        if buffContainer then
            buffContainer:SetUnit("focus")
            buffContainer:Show()
        end

        if debuffContainer then
            debuffContainer:SetUnit("focus")
            debuffContainer:Show()
        end

        ApplyFramePresentation(FocusFrame)
        ConfigureFrame(FocusFrame)
    else
        for _, container in pairs(self.containers[FocusFrame]) do
            container:Hide()
        end
    end
end

function BW:RetireContainers(frame)
    local set = self.containers[frame]
    if not set then
        return
    end

    for _, container in pairs(set) do
        pcall(function()
            container:SetUnit("none")
        end)
        container:Hide()
    end

    self.containers[frame] = nil
end

function BW:RebuildManagedContainers()
    if not self:IsBuffWhitelistEnabled() then
        return
    end

    if InCombatLockdown() then
        self.pendingRebuild = true
        return
    end

    self.pendingRebuild = false

    if TargetFrame then
        self:RetireContainers(TargetFrame)
    end

    if FocusFrame then
        self:RetireContainers(FocusFrame)
    end

    self:SetupTargetFrame()
    self:SetupFocusFrame()
end

function BW:RefreshAllContainers()
    if not self:IsBuffWhitelistEnabled() then
        return
    end

    self:SetupTargetFrame()
    self:SetupFocusFrame()

    if TargetFrame then
        ApplyFramePresentation(TargetFrame)
        ConfigureFrame(TargetFrame)
    end

    if FocusFrame and self.db.applyToFocus then
        ApplyFramePresentation(FocusFrame)
        ConfigureFrame(FocusFrame)
    end

    self:RefreshLayoutPreview()
end

function BW:RefreshPresentation()
    if TargetFrame then
        ApplyFramePresentation(TargetFrame)
    end

    if FocusFrame and self.db.applyToFocus then
        ApplyFramePresentation(FocusFrame)
    end

    self:RefreshLayoutPreview()
end

local function CreatePreviewHolder(kind)
    local holder = CreateFrame("Frame", nil, TargetFrame)
    holder:SetFrameStrata("HIGH")
    holder:SetFrameLevel((TargetFrame:GetFrameLevel() or 1) + 19)
    holder:SetMovable(true)
    holder:EnableMouse(true)
    holder:RegisterForDrag("LeftButton")

    holder:SetScript("OnDragStart", function(self)
        if not BW.db or not BW.db.showLayoutPreview then
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale() or 1

        self._khDragStartX = cursorX / uiScale
        self._khDragStartY = cursorY / uiScale
        self._khDragOffsetX = kind == "buff"
            and (tonumber(BW.db.buffOffsetX) or 0)
            or (tonumber(BW.db.debuffOffsetX) or 0)
        self._khDragOffsetY = kind == "buff"
            and (tonumber(BW.db.buffOffsetY) or 29)
            or (tonumber(BW.db.debuffOffsetY) or 0)

        local effectiveScale = self:GetEffectiveScale() or uiScale
        self._khDragVisualScale = effectiveScale / uiScale
        if not self._khDragVisualScale or self._khDragVisualScale <= 0 then
            self._khDragVisualScale = 1
        end

        self:StartMoving()
    end)

    holder:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        if not BW.db
            or not self._khDragStartX
            or not self._khDragStartY then

            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale() or 1
        local currentX = cursorX / uiScale
        local currentY = cursorY / uiScale
        local visualScale = self._khDragVisualScale or 1

        local deltaX = (currentX - self._khDragStartX) / visualScale
        local deltaY = (currentY - self._khDragStartY) / visualScale
        local newX = math.floor((self._khDragOffsetX + deltaX) + 0.5)
        local newY = math.floor((self._khDragOffsetY + deltaY) + 0.5)

        newX = Clamp(newX, -300, 400)
        newY = Clamp(newY, -250, 300)

        if kind == "buff" then
            BW.db.buffOffsetX = newX
            BW.db.buffOffsetY = newY
        else
            BW.db.debuffOffsetX = newX
            BW.db.debuffOffsetY = newY
        end

        self._khDragStartX = nil
        self._khDragStartY = nil
        self._khDragOffsetX = nil
        self._khDragOffsetY = nil
        self._khDragVisualScale = nil

        BW:RefreshPresentation()

        if BW.RefreshLayoutOptionStates then
            BW:RefreshLayoutOptionStates()
        end
    end)

    BW.previewHolders[kind] = holder
    return holder
end

local function UpdatePreviewCellVisual(kind, frame)
    frame.bg:ClearAllPoints()
    frame.bg:SetAllPoints(frame)

    if frame.borderTop then
        if kind == "debuff" and BW.db.showDebuffRedBorder then
            frame.borderTop:Show()
            frame.borderBottom:Show()
            frame.borderLeft:Show()
            frame.borderRight:Show()
        else
            frame.borderTop:Hide()
            frame.borderBottom:Hide()
            frame.borderLeft:Hide()
            frame.borderRight:Hide()
        end
    end
end

local function CreatePreviewFrame(kind, index, holder)
    local frame = CreateFrame("Frame", nil, holder)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel((TargetFrame:GetFrameLevel() or 1) + 20)

    local bg = frame:CreateTexture(nil, "BACKGROUND")

    if kind == "buff" then
        bg:SetColorTexture(0.10, 0.55, 0.85, 0.52)
    else
        bg:SetColorTexture(0.80, 0.20, 0.20, 0.52)
    end

    frame.bg = bg

    -- Mirror the optional live debuff border in the preview. The slot itself
    -- stays 18x18; only the visible border extends outside it.
    if kind == "debuff" then
        local thickness = 2

        local top = frame:CreateTexture(nil, "OVERLAY")
        top:SetColorTexture(1, 0.03, 0.03, 1)
        top:SetHeight(thickness)

        local bottom = frame:CreateTexture(nil, "OVERLAY")
        bottom:SetColorTexture(1, 0.03, 0.03, 1)
        bottom:SetHeight(thickness)

        local left = frame:CreateTexture(nil, "OVERLAY")
        left:SetColorTexture(1, 0.03, 0.03, 1)
        left:SetWidth(thickness)

        local right = frame:CreateTexture(nil, "OVERLAY")
        right:SetColorTexture(1, 0.03, 0.03, 1)
        right:SetWidth(thickness)

        top:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            -DEBUFF_BORDER_OUTSET,
            DEBUFF_BORDER_OUTSET
        )
        top:SetPoint(
            "TOPRIGHT",
            frame,
            "TOPRIGHT",
            DEBUFF_BORDER_OUTSET,
            DEBUFF_BORDER_OUTSET
        )

        bottom:SetPoint(
            "BOTTOMLEFT",
            frame,
            "BOTTOMLEFT",
            -DEBUFF_BORDER_OUTSET,
            -DEBUFF_BORDER_OUTSET
        )
        bottom:SetPoint(
            "BOTTOMRIGHT",
            frame,
            "BOTTOMRIGHT",
            DEBUFF_BORDER_OUTSET,
            -DEBUFF_BORDER_OUTSET
        )

        left:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            -DEBUFF_BORDER_OUTSET,
            DEBUFF_BORDER_OUTSET
        )
        left:SetPoint(
            "BOTTOMLEFT",
            frame,
            "BOTTOMLEFT",
            -DEBUFF_BORDER_OUTSET,
            -DEBUFF_BORDER_OUTSET
        )

        right:SetPoint(
            "TOPRIGHT",
            frame,
            "TOPRIGHT",
            DEBUFF_BORDER_OUTSET,
            DEBUFF_BORDER_OUTSET
        )
        right:SetPoint(
            "BOTTOMRIGHT",
            frame,
            "BOTTOMRIGHT",
            DEBUFF_BORDER_OUTSET,
            -DEBUFF_BORDER_OUTSET
        )

        frame.borderTop = top
        frame.borderBottom = bottom
        frame.borderLeft = left
        frame.borderRight = right
    end

    local text = frame:CreateFontString(
        nil,
        "OVERLAY"
    )
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetSize(BASE_ICON_SIZE - 2, BASE_ICON_SIZE - 2)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetFont(
        STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        9,
        "OUTLINE"
    )
    text:SetShadowColor(0, 0, 0, 0)

    if text.SetWordWrap then
        text:SetWordWrap(false)
    end

    if text.SetNonSpaceWrap then
        text:SetNonSpaceWrap(false)
    end

    text:SetText((kind == "buff" and "B" or "D") .. tostring(index))

    frame.text = text
    UpdatePreviewCellVisual(kind, frame)
    frame:Hide()

    return frame
end

local function LayoutPreviewKind(kind)
    local config = GetKindConfig(kind)
    local holder = BW.previewHolders[kind] or CreatePreviewHolder(kind)

    -- IMPORTANT: mirror the live AuraContainer exactly.
    -- The live container always uses an 18px logical icon, 2px logical
    -- spacing, then scales the WHOLE container to the configured icon size.
    -- The old preview independently scaled icon sizes and spacing, which
    -- accumulates coordinate drift across rows and columns.
    local logicalWidth, logicalHeight = GetLogicalGridSize(config)
    local scale = Clamp(BW.db.iconSize, 12, 36) / BASE_ICON_SIZE

    holder:SetScale(scale)
    holder:SetSize(logicalWidth, logicalHeight)
    holder:ClearAllPoints()

    local buffHolder = BW.previewHolders.buff
    AnchorGrid(TargetFrame, kind, holder, buffHolder)

    local logicalStep = BASE_ICON_SIZE + ICON_SPACING

    for i = 1, config.maxCount do
        local preview = BW.previewFrames[kind][i]

        if not preview then
            preview = CreatePreviewFrame(kind, i, holder)
            BW.previewFrames[kind][i] = preview
        end

        preview:SetParent(holder)
        preview:ClearAllPoints()

        -- Keep preview cells at the same logical dimensions as real aura
        -- buttons. Holder scaling produces the final on-screen size.
        preview:SetSize(BASE_ICON_SIZE, BASE_ICON_SIZE)
        UpdatePreviewCellVisual(kind, preview)

        local zero = i - 1
        local column = zero % config.columns
        local row = math.floor(zero / config.columns)

        preview:SetPoint(
            config.flowAnchor,
            holder,
            config.flowAnchor,
            column * logicalStep * config.xDirection,
            row * logicalStep * config.yDirection
        )

        preview.text:SetText(
            (kind == "buff" and "B" or "D") .. tostring(i)
        )

        preview:SetShown(BW.db.showLayoutPreview and true or false)
    end

    for i = config.maxCount + 1, #BW.previewFrames[kind] do
        BW.previewFrames[kind][i]:Hide()
    end

    holder:EnableMouse(BW.db.showLayoutPreview and true or false)
    holder:SetShown(BW.db.showLayoutPreview and true or false)
end

function BW:RefreshLayoutPreview()
    if not TargetFrame or not self.db then
        return
    end

    -- Buff preview first so attached debuffs can anchor to it.
    LayoutPreviewKind("buff")
    LayoutPreviewKind("debuff")
end

function BW:IsBlacklisted(kind, spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return false
    end

    local list = kind == "debuff"
        and self.db.debuffBlacklist
        or self.db.buffBlacklist

    return list[spellID] == true
end

function BW:SetBlacklisted(kind, spellID, blocked)
    spellID = tonumber(spellID)
    if not spellID then
        return
    end

    local list = kind == "debuff"
        and self.db.debuffBlacklist
        or self.db.buffBlacklist

    if blocked then
        list[spellID] = true
    else
        list[spellID] = nil
    end

    self:RebuildManagedContainers()

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function BW:AddBlacklistSpell(kind, input)
    local spellID, info = self:ResolveSpell(input)

    if not spellID then
        print("|cffff5555Buff Whitelist:|r Could not find that spell.")
        return false
    end

    local list = kind == "debuff"
        and self.db.debuffBlacklist
        or self.db.buffBlacklist

    list[spellID] = true
    self:RebuildManagedContainers()

    if self.RefreshOptions then
        self:RefreshOptions()
    end

    print(string.format(
        "|cffff6666Buff Whitelist:|r blacklisted %s (%d) as a %s.",
        info.name or "Spell",
        spellID,
        kind
    ))

    return true
end

function BW:RemoveBlacklistSpell(kind, spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return
    end

    local list = kind == "debuff"
        and self.db.debuffBlacklist
        or self.db.buffBlacklist

    list[spellID] = nil
    self:RebuildManagedContainers()

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function BW:ResolveSpell(input)
    input = strtrim(tostring(input or ""))

    if input == "" then
        return nil
    end

    local spellID =
        tonumber(input)
        or tonumber(input:match("|Hspell:(%d+)"))
        or tonumber(input:match("spell:(%d+)"))

    local info

    if spellID then
        info = C_Spell.GetSpellInfo(spellID)
    else
        info = C_Spell.GetSpellInfo(input)
    end

    if not info then
        return nil
    end

    return info.spellID, info
end

function BW:SetSpellEnabled(kind, spellID, enabled)
    spellID = tonumber(spellID)

    if not spellID then
        return
    end

    local list = kind == "debuff" and self.db.debuffs or self.db.buffs

    if enabled then
        list[spellID] = true
    else
        list[spellID] = nil
    end

    self:RebuildManagedContainers()

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function BW:AddSpell(kind, input)
    local spellID, info = self:ResolveSpell(input)

    if not spellID then
        print("|cffff5555Buff Whitelist:|r Could not find that spell.")
        return false
    end

    local list = kind == "debuff" and self.db.debuffs or self.db.buffs
    list[spellID] = true

    self:RebuildManagedContainers()

    if self.RefreshOptions then
        self:RefreshOptions()
    end

    print(string.format(
        "|cff33ff99Buff Whitelist:|r added %s (%d) as a %s.",
        info.name or "Spell",
        spellID,
        kind
    ))

    return true
end

function BW:RemoveSpell(kind, spellID)
    spellID = tonumber(spellID)

    if not spellID then
        return
    end

    local list = kind == "debuff" and self.db.debuffs or self.db.buffs
    list[spellID] = nil

    self:RebuildManagedContainers()

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

local function RebindFrame(frame, unit)
    local set = BW.containers[frame]
    if not set then
        return
    end

    for kind, container in pairs(set) do
        container:SetUnit("none")
        container:SetUnit(unit)
        BW:ConfigureContainer(kind, container)
    end

    ApplyFramePresentation(frame)
end


--------------------------------------------------
-- MODULE LIFECYCLE
--------------------------------------------------

function BW:IsBuffWhitelistEnabled()
    return self.db
        and self.db.buffWhitelistModuleEnabled ~= false
end

function BW:EnableBuffWhitelistModule()
    if not self.db then
        return
    end

    self.db.buffWhitelistModuleEnabled = true

    if self.SetupTargetFrame then
        self:SetupTargetFrame()
    end

    if self.db.applyToFocus and self.SetupFocusFrame then
        self:SetupFocusFrame()
    end

    if self.RebuildManagedContainers then
        self:RebuildManagedContainers()
    end

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function BW:DisableBuffWhitelistModule()
    if not self.db then
        return
    end

    self.db.buffWhitelistModuleEnabled = false

    -- Hide/remove our custom containers and previews immediately.
    if self.targetBuffContainer then
        self.targetBuffContainer:Hide()
    end

    if self.targetDebuffContainer then
        self.targetDebuffContainer:Hide()
    end

    if self.focusBuffContainer then
        self.focusBuffContainer:Hide()
    end

    if self.focusDebuffContainer then
        self.focusDebuffContainer:Hide()
    end

    if self.HideLayoutPreview then
        self:HideLayoutPreview()
    end

    -- Restore Blizzard's native aura widgets if our setup code had hidden them.
    if TargetFrame then
        if TargetFrame.buffFrame then
            TargetFrame.buffFrame:Show()
        end
        if TargetFrame.debuffFrame then
            TargetFrame.debuffFrame:Show()
        end
    end

    if FocusFrame then
        if FocusFrame.buffFrame then
            FocusFrame.buffFrame:Show()
        end
        if FocusFrame.debuffFrame then
            FocusFrame.debuffFrame:Show()
        end
    end

    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function BW:SetBuffWhitelistModuleEnabled(value)
    if value then
        self:EnableBuffWhitelistModule()
    else
        self:DisableBuffWhitelistModule()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        BW:InitializeDB()

    elseif event == "PLAYER_LOGIN" then
        if not BW.db then
            BW:InitializeDB()
        end

        if TargetFrame_UpdateAuras then
            hooksecurefunc("TargetFrame_UpdateAuras", function(frame)
                if BW:IsBuffWhitelistEnabled()
                    and BW:IsManagedFrame(frame) then

                    HideBuiltInAuraButtons(frame)
                end
            end)
        end

        if BW:IsBuffWhitelistEnabled() then
            BW:SetupTargetFrame()
            BW:SetupFocusFrame()
        end

        if BW.InitializeLustUp then
            BW:InitializeLustUp()
        end

        if BW.InitializeStatsModule then
            BW:InitializeStatsModule()
        end

        if BW.InitializeSurvivalHelper then
            BW:InitializeSurvivalHelper()
        end

        if BW.InitializeTalentLoadout then
            BW:InitializeTalentLoadout()
        end

        if BW.InitializeRaidFrameSpec then
            BW:InitializeRaidFrameSpec()
        end

        if BW.InitializeMinimapButton then
            BW:InitializeMinimapButton()
        end

        if BW.CreateOptions then
            BW:CreateOptions()
        end

        BW:RefreshLayoutPreview()

        print("|cff33ff99Kaylii Helper 1.19.29 loaded.|r Type |cffffffff/bwl|r for BuffWhitelist or |cffffffff/lustup|r for Lust Up.")

    elseif event == "PLAYER_TARGET_CHANGED" then
        if BW:IsBuffWhitelistEnabled() and TargetFrame then
            RebindFrame(TargetFrame, "target")
        end

        BW:RefreshLayoutPreview()

        if BW.QueueTargetAuraRefresh then
            BW:QueueTargetAuraRefresh()
        elseif BW.RefreshTargetAuras then
            BW:RefreshTargetAuras()
        end

    elseif event == "UNIT_AURA" and arg1 == "target" then
        if BW.QueueTargetAuraRefresh then
            BW:QueueTargetAuraRefresh()
        end

    elseif event == "PLAYER_FOCUS_CHANGED" then
        if BW.db and BW.db.applyToFocus and FocusFrame then
            RebindFrame(FocusFrame, "focus")
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if BW.pendingRebuild then
            BW:RebuildManagedContainers()
        end
    end
end)
