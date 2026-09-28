local ADDON_NAME, BW = ...

local UPDATE_INTERVAL = 0.50

local function Clamp(value, low, high)
    value = tonumber(value) or low

    if value < low then
        return low
    elseif value > high then
        return high
    end

    return value
end

local function ReadStat(getter)
    local ok, value = pcall(getter)

    if not ok then
        return nil
    end

    return value
end

local function GetCritValue()
    return ReadStat(GetCritChance)
end

local function GetHasteValue()
    return ReadStat(GetHaste)
end

local function GetMasteryValue()
    return ReadStat(GetMasteryEffect)
end

local function GetVersatilityValue()
    return ReadStat(function()
        local ratingIndex =
            CR_VERSATILITY_DAMAGE_DONE
            or 29

        return GetCombatRatingBonus(ratingIndex)
    end)
end

local function NormalizeColor(color, fallback)
    fallback = fallback or { 1, 1, 1, 1 }

    if type(color) ~= "table" then
        color = fallback
    end

    return {
        Clamp(color[1], 0, 1),
        Clamp(color[2], 0, 1),
        Clamp(color[3], 0, 1),
        Clamp(color[4] or 1, 0, 1),
    }
end

local function StatFormat(label, color, fallback)
    color = NormalizeColor(color, fallback)

    return string.format(
        "|cff%02x%02x%02x%s %%.1f%%%%|r",
        math.floor((color[1] * 255) + 0.5),
        math.floor((color[2] * 255) + 0.5),
        math.floor((color[3] * 255) + 0.5),
        label
    )
end

local function SetFourStatText(
    fontString,
    separator,
    showCrit,
    showHaste,
    showMastery,
    showVers,
    crit,
    haste,
    mastery,
    versatility
)
    -- Keep the stat values themselves completely opaque. In restricted
    -- content WoW can mark these as secret values, so they are passed only
    -- as direct SetFormattedText arguments and are never concatenated or
    -- inspected by Kaylii Helper.
    local critText = StatFormat(
        "Crit",
        BW.db and BW.db.statsCritColor,
        { 1.00, 0.42, 0.35, 1 }
    )
    local hasteText = StatFormat(
        "Haste",
        BW.db and BW.db.statsHasteColor,
        { 0.35, 0.85, 0.45, 1 }
    )
    local masteryText = StatFormat(
        "Mastery",
        BW.db and BW.db.statsMasteryColor,
        { 0.67, 0.48, 1.00, 1 }
    )
    local versText = StatFormat(
        "Vers",
        BW.db and BW.db.statsVersatilityColor,
        { 0.30, 0.72, 1.00, 1 }
    )

    if showCrit then
        if showHaste then
            if showMastery then
                if showVers then
                    fontString:SetFormattedText(
                        critText .. separator .. hasteText .. separator .. masteryText .. separator .. versText,
                        crit, haste, mastery, versatility
                    )
                else
                    fontString:SetFormattedText(
                        critText .. separator .. hasteText .. separator .. masteryText,
                        crit, haste, mastery
                    )
                end
            elseif showVers then
                fontString:SetFormattedText(
                    critText .. separator .. hasteText .. separator .. versText,
                    crit, haste, versatility
                )
            else
                fontString:SetFormattedText(
                    critText .. separator .. hasteText,
                    crit, haste
                )
            end
        elseif showMastery then
            if showVers then
                fontString:SetFormattedText(
                    critText .. separator .. masteryText .. separator .. versText,
                    crit, mastery, versatility
                )
            else
                fontString:SetFormattedText(
                    critText .. separator .. masteryText,
                    crit, mastery
                )
            end
        elseif showVers then
            fontString:SetFormattedText(
                critText .. separator .. versText,
                crit, versatility
            )
        else
            fontString:SetFormattedText(critText, crit)
        end

    elseif showHaste then
        if showMastery then
            if showVers then
                fontString:SetFormattedText(
                    hasteText .. separator .. masteryText .. separator .. versText,
                    haste, mastery, versatility
                )
            else
                fontString:SetFormattedText(
                    hasteText .. separator .. masteryText,
                    haste, mastery
                )
            end
        elseif showVers then
            fontString:SetFormattedText(
                hasteText .. separator .. versText,
                haste, versatility
            )
        else
            fontString:SetFormattedText(hasteText, haste)
        end

    elseif showMastery then
        if showVers then
            fontString:SetFormattedText(
                masteryText .. separator .. versText,
                mastery, versatility
            )
        else
            fontString:SetFormattedText(masteryText, mastery)
        end

    elseif showVers then
        fontString:SetFormattedText(versText, versatility)

    else
        fontString:SetText("No stats selected")
    end
end

function BW:SetStatsFontStringText(fontString)
    if not self.db or not fontString then
        return 0
    end

    local showCrit =
        self.db.statsShowCrit and true or false
    local showHaste =
        self.db.statsShowHaste and true or false
    local showMastery =
        self.db.statsShowMastery and true or false
    local showVers =
        self.db.statsShowVersatility and true or false

    local count = 0

    if showCrit then
        count = count + 1
    end
    if showHaste then
        count = count + 1
    end
    if showMastery then
        count = count + 1
    end
    if showVers then
        count = count + 1
    end

    local separator =
        self.db.statsOrientation == "vertical"
        and "\n"
        or "   "

    local crit = GetCritValue()
    local haste = GetHasteValue()
    local mastery = GetMasteryValue()
    local versatility = GetVersatilityValue()

    SetFourStatText(
        fontString,
        separator,
        showCrit,
        showHaste,
        showMastery,
        showVers,
        crit,
        haste,
        mastery,
        versatility
    )

    return count
end

local function StatsVisibilityAllowed()
    if not BW.db or not BW.db.statsModuleEnabled then
        return false
    end

    if BW.db.statsUnlocked then
        return true
    end

    local inCombat =
        UnitAffectingCombat("player") and true or false

    if BW.db.statsOnlyInCombat
        and not inCombat then

        return false
    end

    if BW.db.statsOnlyOutOfCombat
        and inCombat then

        return false
    end

    if BW.db.statsOnlyInInstance then
        local inInstance = IsInInstance()

        if not inInstance then
            return false
        end
    end

    return true
end

local function CreateStatsFrame()
    if BW.statsFrame then
        return BW.statsFrame
    end

    local frame = CreateFrame(
        "Frame",
        "KayliiHelperStatsDisplay",
        UIParent,
        "BackdropTemplate"
    )

    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    if frame.SetClampRectInsets then
        frame:SetClampRectInsets(10, -10, -10, 10)
    end

    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetSize(260, 38)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    local text = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    frame.text = text

    local moveText = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    moveText:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    moveText:SetText("MOVE")
    moveText:SetTextColor(0.30, 0.62, 1.00, 1)
    moveText:Hide()
    frame.moveText = moveText

    frame:SetScript("OnDragStart", function(self)
        if BW.db
            and BW.db.statsModuleEnabled
            and BW.db.statsUnlocked then

            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        if not BW.db then
            return
        end

        local x, y = self:GetCenter()
        local ux, uy = UIParent:GetCenter()

        if x and y and ux and uy then
            BW.db.statsPoint = "CENTER"
            BW.db.statsX = math.floor((x - ux) + 0.5)
            BW.db.statsY = math.floor((y - uy) + 0.5)
        end

        if BW.RefreshStatsOptions then
            BW:RefreshStatsOptions()
        end
    end)

    BW.statsFrame = frame
    return frame
end

local function ApplyStatsPosition()
    local frame = CreateStatsFrame()

    frame:ClearAllPoints()
    frame:SetPoint(
        BW.db.statsPoint or "CENTER",
        UIParent,
        BW.db.statsPoint or "CENTER",
        tonumber(BW.db.statsX) or 0,
        tonumber(BW.db.statsY) or -220
    )
end

function BW:UpdateStatsDisplay()
    if not self.db then
        return
    end

    local frame = CreateStatsFrame()

    if not StatsVisibilityAllowed() then
        frame:Hide()
        return
    end

    local fontSize = Clamp(self.db.statsFontSize, 10, 28)

    frame.text:SetFont(
        STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        fontSize,
        "OUTLINE"
    )

    local statCount =
        self:SetStatsFontStringText(frame.text)

    frame.text:SetTextColor(1, 1, 1, 1)

    local vertical =
        self.db.statsOrientation == "vertical"

    local width
    local height

    if vertical then
        width = 220
        height = math.max(
            34,
            (math.max(statCount, 1) * (fontSize + 3)) + 18
        )
    else
        width = math.max(
            120,
            (math.max(statCount, 1) * 118) + 20
        )
        height = math.max(
            34,
            fontSize + 20
        )
    end

    frame:SetSize(width, height)

    local align = tostring(
        self.db.statsTextAlign or "center"
    )

    if align ~= "left"
        and align ~= "right" then

        align = "center"
    end

    frame.text:ClearAllPoints()
    frame.text:SetPoint(
        "LEFT",
        frame,
        "LEFT",
        11,
        0
    )
    frame.text:SetPoint(
        "RIGHT",
        frame,
        "RIGHT",
        -11,
        0
    )
    frame.text:SetJustifyH(string.upper(align))
    frame.text:SetJustifyV("MIDDLE")

    if self.db.statsShowBackground then
        frame:SetBackdropColor(0.035, 0.055, 0.09, 0.88)
        frame:SetBackdropBorderColor(0.30, 0.62, 1.00, 0.95)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end

    frame:EnableMouse(self.db.statsUnlocked and true or false)
    frame.moveText:SetShown(self.db.statsUnlocked and true or false)
    frame:Show()
end

function BW:StartStatsTicker()
    if self.statsTicker then
        return
    end

    self.statsTicker = C_Timer.NewTicker(
        UPDATE_INTERVAL,
        function()
            BW:UpdateStatsDisplay()
        end
    )
end

function BW:StopStatsTicker()
    if self.statsTicker then
        self.statsTicker:Cancel()
        self.statsTicker = nil
    end
end

function BW:ApplyStatsSettings()
    if not self.db then
        return
    end

    local frame = CreateStatsFrame()

    ApplyStatsPosition()

    if self.db.statsModuleEnabled then
        self:StartStatsTicker()
        self:UpdateStatsDisplay()
    else
        self:StopStatsTicker()
        frame:Hide()
    end
end

function BW:SetStatsModuleEnabled(value)
    if not self.db then
        return
    end

    self.db.statsModuleEnabled = value and true or false
    self:ApplyStatsSettings()

    if self.RefreshStatsOptions then
        self:RefreshStatsOptions()
    end
end

function BW:SetStatsUnlocked(value)
    if not self.db then
        return
    end

    self.db.statsUnlocked = value and true or false
    self:UpdateStatsDisplay()
end

function BW:ResetStatsPosition()
    if not self.db then
        return
    end

    self.db.statsPoint = "CENTER"
    self.db.statsX = 0
    self.db.statsY = -220

    ApplyStatsPosition()
    self:UpdateStatsDisplay()
end

local function EnsureStatsEvents()
    if BW.statsEventFrame then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("COMBAT_RATING_UPDATE")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("UNIT_AURA")

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA"
            and unit ~= "player" then

            return
        end

        BW:UpdateStatsDisplay()

        if BW.RefreshStatsOptions then
            BW:RefreshStatsOptions()
        end
    end)

    BW.statsEventFrame = frame
end

function BW:InitializeStatsModule()
    EnsureStatsEvents()
    CreateStatsFrame()
    self:ApplyStatsSettings()
end
