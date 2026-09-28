local ADDON_NAME, BW = ...

--------------------------------------------------
-- LUST UP
--
-- Readiness is determined from the player's lust
-- lockout debuff, not from the source buff. This
-- means Heroism/Bloodlust/Time Warp/Evoker/Hunter/
-- drums all collapse into the same reliable state:
--
--   lockout present = not ready
--   lockout gone    = lust is available again
--------------------------------------------------

local POLL_INTERVAL = 0.25
local FALLBACK_LOCKOUT_SECONDS = 600

-- Blizzard has explicitly made these common lust lockouts non-secret.
-- Keep legacy IDs too so old/current hunter variants are covered.
local BUILTIN_LOCKOUTS = {
    [57723]  = "Exhaustion",
    [57724]  = "Sated",
    [80354]  = "Temporal Displacement",
    [95809]  = "Insanity",
    [160455] = "Fatigued",
    [264689] = "Fatigued",
    [390435] = "Exhaustion",
}

-- Actual player/pet abilities that provide a full Bloodlust effect.
-- Drums are intentionally excluded: this option is about whether the
-- character currently has a real Lust ability/button available.
local LUST_ABILITIES = {
    { spellID = 2825,   name = "Bloodlust" },
    { spellID = 32182,  name = "Heroism" },
    { spellID = 80353,  name = "Time Warp" },
    { spellID = 390386, name = "Fury of the Aspects" },
    { spellID = 466904, name = "Harrier's Cry" },
    { spellID = 264667, name = "Primal Rage", pet = true },
}

local BUILTIN_LUST_DRUMS = {
    {
        itemID = 244639,
        name = "Void-Touched Drums",
    },
    {
        itemID = 219905,
        name = "Thunderous Drums",
    },
}

local function GetBagItemCount(itemID)
    if not C_Item
        or not C_Item.GetItemCount then

        return 0
    end

    local ok, count = pcall(
        C_Item.GetItemCount,
        itemID,
        false,
        false,
        false,
        false
    )

    if not ok
        or type(count) ~= "number" then

        return 0
    end

    return count
end

local function CanUseItem(itemID)
    if C_Item
        and C_Item.IsUsableItem then

        local ok, usable = pcall(
            C_Item.IsUsableItem,
            itemID
        )

        if ok then
            return usable and true or false
        end
    end

    if C_PlayerInfo
        and C_PlayerInfo.CanUseItem then

        local ok, usable = pcall(
            C_PlayerInfo.CanUseItem,
            itemID
        )

        if ok then
            return usable and true or false
        end
    end

    return true
end

local function GetItemName(itemID, fallback)
    if C_Item
        and C_Item.GetItemNameByID then

        local ok, name = pcall(
            C_Item.GetItemNameByID,
            itemID
        )

        if ok and name and name ~= "" then
            return name
        end
    end

    if C_Item
        and C_Item.RequestLoadItemDataByID then

        pcall(
            C_Item.RequestLoadItemDataByID,
            itemID
        )
    end

    return fallback or ("Item " .. tostring(itemID))
end

local function IsBuiltInDrum(itemID)
    for _, entry in ipairs(BUILTIN_LUST_DRUMS) do
        if entry.itemID == itemID then
            return true
        end
    end

    return false
end

function BW:HasUsableLustDrums()
    for _, entry in ipairs(BUILTIN_LUST_DRUMS) do
        local count = GetBagItemCount(entry.itemID)

        if count > 0
            and CanUseItem(entry.itemID) then

            return true, entry.name, entry.itemID, count
        end
    end

    for itemID, enabled in pairs(
        self.db.lustUpCustomDrumItems or {}
    ) do
        itemID = tonumber(itemID)

        if enabled and itemID then
            local count = GetBagItemCount(itemID)

            if count > 0
                and CanUseItem(itemID) then

                return true,
                    GetItemName(itemID),
                    itemID,
                    count
            end
        end
    end

    return false, nil, nil, 0
end

function BW:HasLustSource()
    local hasAbility, abilityName, spellID =
        self:HasLustAbility()

    if hasAbility then
        return true,
            abilityName,
            "ability",
            spellID
    end

    if self.db
        and self.db.lustUpAllowDrums then

        local hasDrums, drumName, itemID, count =
            self:HasUsableLustDrums()

        if hasDrums then
            return true,
                drumName,
                "drums",
                itemID,
                count
        end
    end

    return false, nil, nil, nil
end

function BW:AddLustUpDrumItem(input)
    if not self.db then
        return false
    end

    local itemID = tonumber(input)

    if not itemID
        or itemID <= 0 then

        print(
            "|cffff5555Kaylii Helper - Lust Up:|r "
            .. "Enter a valid drum Item ID."
        )
        return false
    end

    itemID = math.floor(itemID)

    if IsBuiltInDrum(itemID) then
        print(
            "|cff4d9fffKaylii Helper - Lust Up:|r "
            .. "That drum is already included."
        )
        return false
    end

    self.db.lustUpCustomDrumItems =
        self.db.lustUpCustomDrumItems or {}

    self.db.lustUpCustomDrumItems[itemID] = true

    if C_Item
        and C_Item.RequestLoadItemDataByID then

        pcall(
            C_Item.RequestLoadItemDataByID,
            itemID
        )
    end

    self:ApplyLustUpSettings()

    if self.RefreshLustUpOptions then
        self:RefreshLustUpOptions()
    end

    return true
end

function BW:RemoveLustUpDrumItem(input)
    if not self.db
        or not self.db.lustUpCustomDrumItems then

        return false
    end

    local itemID = tonumber(input)

    if not itemID then
        return false
    end

    itemID = math.floor(itemID)

    if not self.db.lustUpCustomDrumItems[itemID] then
        return false
    end

    self.db.lustUpCustomDrumItems[itemID] = nil

    self:ApplyLustUpSettings()

    if self.RefreshLustUpOptions then
        self:RefreshLustUpOptions()
    end

    return true
end

local function DrumStatusText(itemID)
    local count = GetBagItemCount(itemID)

    if count <= 0 then
        return "not in bags"
    end

    if CanUseItem(itemID) then
        return "x" .. tostring(count) .. " • usable"
    end

    return "x" .. tostring(count) .. " • not usable"
end

function BW:GetBuiltInLustDrumListText()
    local lines = {}

    for _, entry in ipairs(BUILTIN_LUST_DRUMS) do
        lines[#lines + 1] = string.format(
            "%s (%d) — %s",
            entry.name,
            entry.itemID,
            DrumStatusText(entry.itemID)
        )
    end

    return table.concat(lines, "\n")
end

function BW:GetCustomLustDrumListText()
    local entries = {}

    for itemID, enabled in pairs(
        self.db.lustUpCustomDrumItems or {}
    ) do
        itemID = tonumber(itemID)

        if enabled and itemID then
            entries[#entries + 1] = {
                itemID = itemID,
                name = GetItemName(itemID),
            }
        end
    end

    table.sort(entries, function(a, b)
        return a.itemID < b.itemID
    end)

    if #entries == 0 then
        return "None added."
    end

    local lines = {}

    for _, entry in ipairs(entries) do
        lines[#lines + 1] = string.format(
            "%s (%d) — %s",
            entry.name,
            entry.itemID,
            DrumStatusText(entry.itemID)
        )
    end

    return table.concat(lines, "\n")
end

local function SafeSpellKnown(spellID, petSpell)
    if C_SpellBook
        and C_SpellBook.IsSpellKnown then

        local spellBank

        if petSpell
            and Enum
            and Enum.SpellBookSpellBank then

            spellBank = Enum.SpellBookSpellBank.Pet
        end

        local ok, known

        if spellBank ~= nil then
            ok, known = pcall(
                C_SpellBook.IsSpellKnown,
                spellID,
                spellBank
            )
        else
            ok, known = pcall(
                C_SpellBook.IsSpellKnown,
                spellID
            )
        end

        if ok and known then
            return true
        end
    end

    if not petSpell and IsPlayerSpell then
        local ok, known = pcall(
            IsPlayerSpell,
            spellID
        )

        if ok and known then
            return true
        end
    end

    if not petSpell and IsSpellKnown then
        local ok, known = pcall(
            IsSpellKnown,
            spellID
        )

        if ok and known then
            return true
        end
    end

    return false
end

function BW:HasLustAbility()
    for _, ability in ipairs(LUST_ABILITIES) do
        if SafeSpellKnown(
            ability.spellID,
            ability.pet
        ) then

            return true, ability.name, ability.spellID
        end

        if ability.pet
            and SafeSpellKnown(
                ability.spellID,
                false
            ) then

            return true, ability.name, ability.spellID
        end
    end

    return false, nil, nil
end

function BW:IsLustUpActive()
    if not self.db
        or not self.db.lustUpEnabled then

        return false
    end

    if not self.db.lustUpRequireLustAbility then
        return true
    end

    return self:HasLustSource()
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

local function GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end

    return BUILTIN_LOCKOUTS[spellID] or ("Spell " .. tostring(spellID))
end

local function GetSpellIcon(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.iconID then
            return info.iconID
        end
    end

    return "Interface\\Icons\\Spell_Nature_BloodLust"
end

local function GetItemIcon(itemID)
    if C_Item
        and C_Item.GetItemIconByID then

        local ok, icon = pcall(
            C_Item.GetItemIconByID,
            itemID
        )

        if ok and icon then
            return icon
        end
    end

    if C_Item
        and C_Item.RequestLoadItemDataByID then

        pcall(
            C_Item.RequestLoadItemDataByID,
            itemID
        )
    end

    return "Interface\\Icons\\INV_Misc_Drum_01"
end

local function SafePlayerAuraBySpellID(spellID)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then
        return nil
    end

    local ok, aura = pcall(
        C_UnitAuras.GetPlayerAuraBySpellID,
        spellID
    )

    if not ok or not aura then
        return nil
    end

    -- Custom IDs can become restricted in future patches. Field access is
    -- guarded so an invalid/secret custom ID cannot break the module.
    local fieldsOK, duration, expirationTime = pcall(function()
        return aura.duration, aura.expirationTime
    end)

    if not fieldsOK then
        return {
            spellID = spellID,
            duration = FALLBACK_LOCKOUT_SECONDS,
            expirationTime = nil,
        }
    end

    return {
        spellID = spellID,
        duration = tonumber(duration) or FALLBACK_LOCKOUT_SECONDS,
        expirationTime = tonumber(expirationTime),
    }
end

local function BuildTrackedLockouts()
    local result = {}

    for spellID, name in pairs(BUILTIN_LOCKOUTS) do
        result[spellID] = name
    end

    for spellID, enabled in pairs(BW.db.lustUpCustomLockouts or {}) do
        spellID = tonumber(spellID)

        if spellID and enabled then
            result[spellID] = GetSpellName(spellID)
        end
    end

    return result
end

local function CreateIndicator()
    if BW.lustUpFrame then
        return BW.lustUpFrame
    end

    local frame = CreateFrame(
        "Button",
        "KayliiHelperLustUpIndicator",
        UIParent,
        "BackdropTemplate"
    )

    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)

    frame:HookScript("OnHide", function(self)
        if self.readyGlowUsesManager
            and ActionButtonSpellAlertManager
            and ActionButtonSpellAlertManager.HideAlert then

            pcall(
                ActionButtonSpellAlertManager.HideAlert,
                ActionButtonSpellAlertManager,
                self
            )
        end

        self.readyGlowUsesManager = false
        self.readyGlowShown = false

        if self.readyGlowFallbackPulse
            and self.readyGlowFallbackPulse:IsPlaying() then

            self.readyGlowFallbackPulse:Stop()
        end

        if self.readyGlowFallback then
            self.readyGlowFallback:Hide()
        end
    end)
    frame:RegisterForDrag("LeftButton")

    frame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })

    local iconInset = 4

    local iconBG = frame:CreateTexture(nil, "BACKGROUND")
    iconBG:SetPoint("TOPLEFT", frame, "TOPLEFT", iconInset, -iconInset)
    iconBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -iconInset, iconInset)
    iconBG:SetColorTexture(0, 0, 0, 1)
    frame.iconBG = iconBG

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", iconInset, -iconInset)
    icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -iconInset, iconInset)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.icon = icon

    -- Current Retail routes action-button proc highlights through
    -- ActionButtonSpellAlertManager. Keep a Blizzard-atlas fallback that
    -- requires no inherited XML template, so glow support cannot break load.
    local readyGlowFallback = frame:CreateTexture(
        nil,
        "OVERLAY",
        nil,
        7
    )
    readyGlowFallback:SetAtlas(
        "UI-HUD-RotationHelper-ProcAltGlow"
    )
    readyGlowFallback:SetBlendMode("ADD")
    readyGlowFallback:SetPoint(
        "CENTER",
        frame,
        "CENTER",
        0,
        0
    )
    readyGlowFallback:SetSize(
        math.max(frame:GetWidth() + 8, 24),
        math.max(frame:GetHeight() + 8, 24)
    )
    readyGlowFallback:SetAlpha(0.85)
    readyGlowFallback:Hide()
    frame.readyGlowFallback = readyGlowFallback

    local readyGlowFallbackPulse =
        readyGlowFallback:CreateAnimationGroup()
    readyGlowFallbackPulse:SetLooping("BOUNCE")

    local fallbackAlpha =
        readyGlowFallbackPulse:CreateAnimation("Alpha")
    fallbackAlpha:SetFromAlpha(0.42)
    fallbackAlpha:SetToAlpha(1.00)
    fallbackAlpha:SetDuration(0.65)
    fallbackAlpha:SetSmoothing("IN_OUT")

    frame.readyGlowFallbackPulse =
        readyGlowFallbackPulse
    frame.readyGlowShown = false
    frame.readyGlowUsesManager = false

    local cooldown = CreateFrame(
        "Cooldown",
        nil,
        frame,
        "CooldownFrameTemplate"
    )
    cooldown:SetAllPoints(frame)
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetSwipeColor(0, 0, 0, 0.72)

    if cooldown.SetHideCountdownNumbers then
        cooldown:SetHideCountdownNumbers(false)
    end

    frame.cooldown = cooldown

    local status = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )
    status:SetPoint("BOTTOM", frame, "BOTTOM", 0, 3)
    status:SetJustifyH("CENTER")
    status:SetText("READY")
    status:SetTextColor(1, 1, 1, 1)
    frame.status = status

    local move = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )
    move:SetPoint("CENTER", frame, "CENTER", 0, 0)
    move:SetText("MOVE")
    move:SetTextColor(1, 0.82, 0, 1)
    move:Hide()
    frame.moveText = move

    frame:SetScript("OnDragStart", function(self)
        if BW.db
            and BW.db.lustUpEnabled
            and BW.db.lustUpUnlocked then

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
            BW.db.lustUpPoint = "CENTER"
            BW.db.lustUpX = math.floor((x - ux) + 0.5)
            BW.db.lustUpY = math.floor((y - uy) + 0.5)
        end

        if BW.RefreshLustUpActionButton then
            BW:RefreshLustUpActionButton()
        end

        if BW.RefreshLustUpOptions then
            BW:RefreshLustUpOptions()
        end
    end)

    BW.lustUpFrame = frame
    return frame
end

local function SetReadyGlow(frame, shown)
    if not frame then
        return
    end

    shown =
        shown
        and BW.db
        and BW.db.lustUpReadyGlow
        and true
        or false

    if shown then
        if frame.readyGlowShown then
            return
        end

        frame.readyGlowShown = true
        frame.readyGlowUsesManager = false

        if ActionButtonSpellAlertManager
            and ActionButtonSpellAlertManager.ShowAlert then

            local ok = pcall(
                ActionButtonSpellAlertManager.ShowAlert,
                ActionButtonSpellAlertManager,
                frame,
                false
            )

            if ok then
                frame.readyGlowUsesManager = true
                return
            end

            -- ShowAlert records the button before creating Blizzard's alert
            -- frame. If creation failed because of load order, clear that
            -- partial state before using the safe fallback.
            if ActionButtonSpellAlertManager.activeAlerts then
                ActionButtonSpellAlertManager.activeAlerts[frame] = nil
            end
        end

        if frame.readyGlowFallback then
            frame.readyGlowFallback:Show()

            if frame.readyGlowFallbackPulse
                and not frame.readyGlowFallbackPulse:IsPlaying() then

                frame.readyGlowFallbackPulse:Play()
            end
        end

    else
        if frame.readyGlowUsesManager
            and ActionButtonSpellAlertManager
            and ActionButtonSpellAlertManager.HideAlert then

            pcall(
                ActionButtonSpellAlertManager.HideAlert,
                ActionButtonSpellAlertManager,
                frame
            )
        end

        frame.readyGlowUsesManager = false
        frame.readyGlowShown = false

        if frame.readyGlowFallbackPulse
            and frame.readyGlowFallbackPulse:IsPlaying() then

            frame.readyGlowFallbackPulse:Stop()
        end

        if frame.readyGlowFallback then
            frame.readyGlowFallback:SetAlpha(0.80)
            frame.readyGlowFallback:Hide()
        end
    end
end

local function CreateLustActionButton()
    if BW.lustUpActionButton then
        return BW.lustUpActionButton
    end

    if InCombatLockdown
        and InCombatLockdown() then

        BW.lustUpActionNeedsRefresh = true
        return nil
    end

    -- This is deliberately a separate UIParent sibling rather than a child
    -- of the visual indicator. SecureActionButtonTemplate protection can
    -- propagate to parents/anchors, which would stop the indicator from
    -- freely updating its normal display during combat.
    local button = CreateFrame(
        "Button",
        "KayliiHelperLustActionButton",
        UIParent,
        "SecureActionButtonTemplate,SecureHandlerBaseTemplate"
    )

    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(100)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("useOnKeyDown", false)

    -- Once the player actually clicks the prepared Lust action, make the
    -- protected click layer disappear through secure code. This avoids a
    -- dead mouse zone while the 10-minute Lust lockout is active.
    if button.WrapScript then
        button:WrapScript(
            button,
            "PostClick",
            [[
                return nil, true
            ]],
            [[
                self:Hide()
            ]]
        )
    end

    button:Hide()

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(
            self,
            "ANCHOR_RIGHT"
        )

        GameTooltip:AddLine(
            "Kaylii Helper - Lust Up",
            1,
            1,
            1
        )

        if BW.lustUpLocked then
            GameTooltip:AddLine(
                "Lust is locked — clicks pass through.",
                0.72,
                0.78,
                0.88
            )

        elseif self._khActionReady
            and self._khActionName then

            local actionText =
                self._khActionType == "item"
                and ("Click to use " .. self._khActionName)
                or ("Click to cast " .. self._khActionName)

            GameTooltip:AddLine(
                actionText,
                0.30,
                0.70,
                1.00
            )

            if self._khActionType == "item" then
                GameTooltip:AddLine(
                    "Using configured Lust drums from your bags.",
                    0.72,
                    0.78,
                    0.88
                )
            end
        else
            GameTooltip:AddLine(
                "No usable Lust source is prepared.",
                1.00,
                0.72,
                0.25
            )
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    BW.lustUpActionButton = button
    return button
end

local function PositionLustActionButton(button)
    if not button
        or not BW.db then

        return
    end

    local point =
        BW.db.lustUpPoint
        or "CENTER"

    local x =
        tonumber(BW.db.lustUpX)
        or 0

    local y =
        tonumber(BW.db.lustUpY)
        or -160

    local size = Clamp(
        BW.db.lustUpSize,
        24,
        128
    )

    button:ClearAllPoints()
    button:SetPoint(
        point,
        UIParent,
        point,
        x,
        y
    )
    button:SetSize(size, size)
end

local function ClearLustAction(button)
    if not button then
        return
    end

    button:SetAttribute("type1", nil)
    button:SetAttribute("spell1", nil)
    button:SetAttribute("item1", nil)

    button._khActionReady = false
    button._khActionName = nil
    button._khActionType = nil
    button._khActionID = nil
end

local function LustInstanceVisibilityAllowed()
    if not BW.db then
        return false
    end

    local inInstance, instanceType =
        IsInInstance()

    -- IsInInstance is normally authoritative, but on some zone/encounter
    -- transitions the type can briefly be nil/none.  Fall back to the current
    -- instance metadata so dungeon/raid alert filtering does not flip during
    -- the exact moment an encounter starts.
    if (not instanceType or instanceType == "none")
        and GetInstanceInfo then

        local ok, _, fallbackType = pcall(GetInstanceInfo)

        if ok and fallbackType and fallbackType ~= "" then
            instanceType = fallbackType
        end
    end

    -- Dungeon/Raid switches are shared by the visual indicator and automatic
    -- voice alerts. Tracking itself is intentionally allowed to continue.
    if instanceType == "raid"
        and BW.db.lustUpShowInRaids == false then

        return false
    end

    if (
        instanceType == "party"
        or instanceType == "scenario"
    )
        and BW.db.lustUpShowInDungeons == false then

        return false
    end

    if BW.db.lustUpOnlyInInstance
        and not inInstance then

        return false
    end

    return true
end

local function RefreshLustActionVisibility(button)
    if not button
        or not BW.db then

        return
    end

    if InCombatLockdown
        and InCombatLockdown() then

        BW.lustUpActionNeedsRefresh = true
        return
    end

    if UnregisterStateDriver then
        pcall(
            UnregisterStateDriver,
            button,
            "visibility"
        )
    end

    local enabled =
        BW.db.lustUpEnabled
        and BW.db.lustUpIndicatorClickable
        and not BW.db.lustUpUnlocked
        and button._khActionReady
        and BW.lustUpLocked ~= true

    if not enabled then
        button:Hide()
        return
    end

    if not LustInstanceVisibilityAllowed() then
        button:Hide()
        return
    end

    if BW.db.lustUpOnlyInCombat
        and RegisterStateDriver then

        RegisterStateDriver(
            button,
            "visibility",
            "[combat] show; hide"
        )
    else
        button:Show()
    end
end

function BW:RefreshLustUpActionButton()
    if not self.db then
        return false
    end

    if InCombatLockdown
        and InCombatLockdown() then

        self.lustUpActionNeedsRefresh = true

        -- A secure action cannot be reassigned in combat. This must not
        -- affect the normal visual indicator; it will refresh after combat.
        return self:IsLustUpActionReady()
    end

    local button = CreateLustActionButton()

    if not button then
        return false
    end

    PositionLustActionButton(button)
    ClearLustAction(button)

    if not self.db.lustUpIndicatorClickable
        or not self.db.lustUpEnabled
        or self.db.lustUpUnlocked then

        RefreshLustActionVisibility(button)
        self.lustUpActionNeedsRefresh = false
        return true
    end

    local hasSource,
        sourceName,
        sourceType,
        sourceID =
        self:HasLustSource()

    if hasSource
        and sourceID then

        if sourceType == "ability" then
            button:SetAttribute(
                "type1",
                "spell"
            )
            button:SetAttribute(
                "spell1",
                tonumber(sourceID)
            )

        elseif sourceType == "drums" then
            button:SetAttribute(
                "type1",
                "item"
            )
            button:SetAttribute(
                "item1",
                "item:"
                    .. tostring(sourceID)
            )
        end

        button._khActionReady = true
        button._khActionName = sourceName
        button._khActionType =
            sourceType == "drums"
            and "item"
            or "spell"
        button._khActionID = sourceID
    end

    RefreshLustActionVisibility(button)

    self.lustUpActionNeedsRefresh = false
    return button._khActionReady
end

function BW:IsLustUpActionReady()
    local button = self.lustUpActionButton

    return self.db
        and self.db.lustUpIndicatorClickable
        and button
        and button._khActionReady
        and true
        or false
end

function BW:SetLustUpIndicatorClickable(value)
    if not self.db then
        return false
    end

    if InCombatLockdown
        and InCombatLockdown() then

        print(
            "|cffffcc55Kaylii Helper - Lust Up:|r "
            .. "Clickable mode can only be changed outside combat."
        )

        if self.RefreshLustUpOptions then
            self:RefreshLustUpOptions()
        end

        return false
    end

    self.db.lustUpIndicatorClickable =
        value and true or false

    self:RefreshLustUpActionButton()
    self:ApplyLustUpSettings()

    if self.RefreshLustUpOptions then
        self:RefreshLustUpOptions()
    end

    return true
end

local function ApplyIndicatorPosition()
    local frame = CreateIndicator()
    frame:ClearAllPoints()

    local point = BW.db.lustUpPoint or "CENTER"
    local x = tonumber(BW.db.lustUpX) or 0
    local y = tonumber(BW.db.lustUpY) or -160

    frame:SetPoint(point, UIParent, point, x, y)
end

local function ApplyIndicatorSize()
    local frame = CreateIndicator()
    local size = Clamp(BW.db.lustUpSize, 24, 128)

    BW.db.lustUpSize = size
    frame:SetSize(size, size)

    if frame.iconBG then
        frame.iconBG:ClearAllPoints()
        frame.iconBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        frame.iconBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    end

    if frame.icon then
        frame.icon:ClearAllPoints()
        frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    end

    if frame.readyGlowFallback then
        frame.readyGlowFallback:SetSize(
            math.max(size + 8, 24),
            math.max(size + 8, 24)
        )
    end

    local textSize = Clamp(math.floor(size * 0.20), 9, 18)

    frame.status:SetFont(
        STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        textSize,
        "OUTLINE"
    )

    frame.moveText:SetFont(
        STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        Clamp(math.floor(size * 0.24), 10, 22),
        "OUTLINE"
    )
end

local function ApplyIndicatorIcon()
    local frame = CreateIndicator()
    local actionButton = BW.lustUpActionButton

    if BW.db.lustUpIndicatorClickable
        and actionButton
        and actionButton._khActionReady
        and actionButton._khActionID then

        if actionButton._khActionType == "item" then
            frame.icon:SetTexture(
                GetItemIcon(
                    actionButton._khActionID
                )
            )
        else
            frame.icon:SetTexture(
                GetSpellIcon(
                    actionButton._khActionID
                )
            )
        end

        return
    end

    local spellID =
        tonumber(BW.db.lustUpIconSpellID)
        or 2825

    frame.icon:SetTexture(
        GetSpellIcon(spellID)
    )
end

local function SpeakWithWoWTTS(text, allowOverlap)
    text = tostring(text or "")
    if text == "" then
        return false
    end

    -- Prefer local TTS so the phrase is spoken using the player's selected
    -- WoW text-to-speech voice/rate/volume.
    if C_VoiceChat
        and C_VoiceChat.SpeakText
        and C_VoiceChat.GetTtsVoices then

        local voiceID

        if C_TTSSettings
            and C_TTSSettings.GetVoiceOptionID
            and Enum
            and Enum.TtsVoiceType then

            local ok, value = pcall(
                C_TTSSettings.GetVoiceOptionID,
                Enum.TtsVoiceType.Standard
            )

            if ok then
                voiceID = value
            end
        end

        if not voiceID then
            local ok, voices = pcall(C_VoiceChat.GetTtsVoices)

            if ok and type(voices) == "table" and voices[1] then
                voiceID = voices[1].voiceID
            end
        end

        if voiceID then
            local rate = 0
            local volume = 100

            if C_TTSSettings and C_TTSSettings.GetSpeechRate then
                local ok, value = pcall(C_TTSSettings.GetSpeechRate)
                if ok and tonumber(value) then
                    rate = tonumber(value)
                end
            end

            if C_TTSSettings and C_TTSSettings.GetSpeechVolume then
                local ok, value = pcall(C_TTSSettings.GetSpeechVolume)
                if ok and tonumber(value) then
                    volume = tonumber(value)
                end
            end

            local ok = pcall(
                C_VoiceChat.SpeakText,
                voiceID,
                text,
                rate,
                volume,
                allowOverlap and true or false
            )

            if ok then
                return true
            end
        end
    end

    -- Fallback for clients/configurations where the generic TTS path is not
    -- available but Combat Audio Alert speech is.
    if C_CombatAudioAlert
        and C_CombatAudioAlert.SpeakText
        and Enum
        and Enum.CombatAudioAlertCategory then

        local ok = pcall(
            C_CombatAudioAlert.SpeakText,
            text,
            Enum.CombatAudioAlertCategory.General,
            allowOverlap and true or false
        )

        if ok then
            return true
        end
    end

    return false
end

function BW:SpeakKayliiTTS(text, allowOverlap)
    return SpeakWithWoWTTS(text, allowOverlap)
end

function BW:SpeakLustUp(testOnly)
    if not self.db then
        return false
    end

    if not testOnly and not self.db.lustUpVoiceEnabled then
        return false
    end

    -- Test buttons intentionally bypass instance filters. Automatic alerts
    -- obey the same Dungeon/Raid/instance switches as the indicator.
    if not testOnly and not LustInstanceVisibilityAllowed() then
        return false
    end

    local phrase = tostring(
        self.db.lustUpReadyVoiceText or "Lust up"
    )

    if phrase == "" then
        phrase = "Lust up"
    end

    local worked = SpeakWithWoWTTS(phrase)

    if testOnly and not worked then
        print(
            "|cffff5555Buff Whitelist - Lust Up:|r "
            .. "No WoW text-to-speech voice was available."
        )
    end

    return worked
end

function BW:AnnounceLustUp()
    if not self.db or not LustInstanceVisibilityAllowed() then
        return false
    end

    local channel = tostring(
        self.db.lustUpReadyChatChannel or "OFF"
    ):upper()

    if channel == "OFF" then
        return false
    end

    if channel == "PARTY" then
        if not IsInGroup() or IsInRaid() then
            return false
        end
    elseif channel == "RAID" then
        if not IsInRaid() then
            return false
        end
    elseif channel == "INSTANCE_CHAT" then
        local instanceCategory = LE_PARTY_CATEGORY_INSTANCE or 2
        if not IsInGroup(instanceCategory) then
            return false
        end
    elseif channel ~= "SAY" then
        return false
    end

    local phrase = tostring(
        self.db.lustUpReadyVoiceText or "Lust up"
    )

    if phrase == "" then
        phrase = "Lust up"
    end

    if type(SendChatMessage) ~= "function" then
        return false
    end

    local ok = pcall(SendChatMessage, phrase, channel)
    return ok and true or false
end

function BW:SpeakLustBossPull(testOnly)
    if not self.db then
        return false
    end

    -- Boss-pull voice is independent from the normal lockout-ended voice.
    if not testOnly
        and not self.db.lustUpBossPullVoiceEnabled then

        return false
    end

    -- Test buttons intentionally bypass instance filters. Automatic alerts
    -- obey the same Dungeon/Raid/instance switches as the indicator.
    if not testOnly and not LustInstanceVisibilityAllowed() then
        return false
    end

    local phrase = tostring(
        self.db.lustUpBossPullVoiceText or "Lust off cooldown"
    )

    if phrase == "" then
        phrase = "Lust off cooldown"
    end

    local worked = SpeakWithWoWTTS(phrase)

    if testOnly and not worked then
        print(
            "|cffff5555Kaylii Helper - Lust Up:|r "
            .. "No WoW text-to-speech voice was available."
        )
    end

    return worked
end

local function BossUnitExists()
    for index = 1, 8 do
        if UnitExists("boss" .. index) then
            return true
        end
    end

    return false
end

function BW:MaybeAnnounceLustBossPull(forceEncounter)
    if not self.db
        or not self:IsLustUpActive()
        or not self.db.lustUpBossPullVoiceEnabled
        or self.lustBossPullHandled
        or not LustInstanceVisibilityAllowed() then

        return
    end

    -- ENCOUNTER_START is already authoritative. Other events must see an
    -- actual boss unit so normal trash combat never triggers the voice line.
    if not forceEncounter and not BossUnitExists() then
        return
    end

    -- Mark the pull handled even when lust is locked. Otherwise a lockout
    -- expiring during the same boss fight could incorrectly fire the pull line.
    self.lustBossPullHandled = true

    local locked = self:GetLustUpLockout()

    if not locked then
        self:SpeakLustBossPull(false)
    end
end

function BW:HandleLustUpEncounterStart()
    self:MaybeAnnounceLustBossPull(true)
end

local function ScheduleBossPullCheck()
    -- Boss unit tokens can populate slightly after combat starts. Check more
    -- than once without polling indefinitely.
    C_Timer.After(0.10, function()
        BW:MaybeAnnounceLustBossPull(false)
    end)

    C_Timer.After(0.50, function()
        BW:MaybeAnnounceLustBossPull(false)
    end)
end

local function EnsureLustUpEventFrame()
    if BW.lustUpEventFrame then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("PET_BAR_UPDATE")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("PLAYER_LEVEL_UP")

    frame:SetScript("OnEvent", function(_, event)
        if event == "ENCOUNTER_START" then
            BW.lustBossPullHandled = false

            C_Timer.After(0, function()
                BW:HandleLustUpEncounterStart()
            end)

        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            ScheduleBossPullCheck()

        elseif event == "PLAYER_REGEN_DISABLED" then
            -- Fallback for encounters where ENCOUNTER_START timing is odd.
            BW.lustBossPullHandled = false
            ScheduleBossPullCheck()

        elseif event == "ENCOUNTER_END" then
            BW.lustBossPullHandled = false

        elseif event == "PLAYER_REGEN_ENABLED" then
            BW.lustBossPullHandled = false

            C_Timer.After(0, function()
                BW:RefreshLustUpActionButton()
                BW:ApplyLustUpSettings()

                if BW.RefreshLustUpOptions then
                    BW:RefreshLustUpOptions()
                end
            end)

        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "ZONE_CHANGED_NEW_AREA"
            or event == "PLAYER_SPECIALIZATION_CHANGED"
            or event == "SPELLS_CHANGED"
            or event == "PET_BAR_UPDATE"
            or event == "UNIT_PET"
            or event == "BAG_UPDATE_DELAYED"
            or event == "PLAYER_LEVEL_UP" then

            C_Timer.After(0, function()
                BW:ApplyLustUpSettings()

                if BW.RefreshLustUpOptions then
                    BW:RefreshLustUpOptions()
                end
            end)

            C_Timer.After(0.50, function()
                BW:ApplyLustUpSettings()

                if BW.RefreshLustUpOptions then
                    BW:RefreshLustUpOptions()
                end
            end)
        end
    end)

    BW.lustUpEventFrame = frame
end

function BW:GetLustUpLockout()
    if not self.db then
        return false
    end

    local tracked = BuildTrackedLockouts()
    local best

    for spellID, name in pairs(tracked) do
        local aura = SafePlayerAuraBySpellID(spellID)

        if aura then
            local expiration = aura.expirationTime or 0

            if not best
                or expiration > (best.expirationTime or 0) then

                best = {
                    spellID = spellID,
                    name = name,
                    duration = aura.duration or FALLBACK_LOCKOUT_SECONDS,
                    expirationTime = aura.expirationTime,
                }
            end
        end
    end

    return best ~= nil, best
end

local function UpdateIndicatorState()
    local frame = CreateIndicator()
    local unlocked =
        BW.db
        and BW.db.lustUpUnlocked == true

    -- Unlock is an explicit positioning/edit mode. Always show the visual
    -- indicator while unlocked, even if this character has no Lust spell and
    -- no usable drums. Normal source requirements resume when it is locked.
    if not unlocked
        and not BW:IsLustUpActive() then

        SetReadyGlow(frame, false)
        frame:SetAlpha(1)
        frame:Hide()
        return
    end

    local locked = BW.lustUpLocked == true
    local mode = BW.db.lustUpDisplayMode or "ready"

    -- Instance filters are shared with automatic voice alerts. Tracking still
    -- continues in the background while the module itself is enabled.
    local passesCombat =
        (not BW.db.lustUpOnlyInCombat)
        or UnitAffectingCombat("player")

    local passesInstance =
        LustInstanceVisibilityAllowed()

    local passesVisibility =
        passesCombat and passesInstance

    -- Unlock mode intentionally bypasses the visibility filters so the user
    -- can always position the icon from the options screen.
    -- Clickable mode is a visual mode as well as an action mode.
    -- Do not make the normal indicator disappear just because WoW has not
    -- prepared the secure spell/item overlay yet. The secure button may be
    -- unavailable temporarily (for example after a reload in combat), but
    -- the visible Lust icon must remain stable.
    local clickableMode =
        BW.db.lustUpIndicatorClickable
        and not unlocked

    local shouldShow = unlocked
        or (
            passesVisibility
            and (
                clickableMode
                or mode == "always"
                or not locked
            )
        )

    frame:SetShown(shouldShow)

    if not shouldShow then
        SetReadyGlow(frame, false)
        return
    end

    frame:EnableMouse(unlocked)
    frame.moveText:SetShown(unlocked)

    if locked and not unlocked then
        SetReadyGlow(frame, false)

        frame:SetAlpha(
            Clamp(
                tonumber(BW.db.lustUpLockedAlpha) or 100,
                10,
                100
            ) / 100
        )

        frame.icon:SetDesaturated(true)
        frame.icon:SetVertexColor(0.52, 0.52, 0.52, 1)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        frame.status:SetText("LOCKED")

        local info = BW.lustUpLockoutInfo
        local duration = info and tonumber(info.duration)
        local expiration = info and tonumber(info.expirationTime)

        if duration and duration > 0 and expiration and expiration > 0 then
            local startTime = expiration - duration
            frame.cooldown:SetCooldown(startTime, duration)
            frame.cooldown:Show()
        else
            frame.cooldown:Hide()
        end
    else
        -- Unlocked mode is a positioning preview, so keep it fully visible.
        -- Otherwise use the user-configured ready alpha.
        if unlocked then
            frame:SetAlpha(1)
        else
            frame:SetAlpha(
                Clamp(
                    tonumber(BW.db.lustUpReadyAlpha) or 100,
                    10,
                    100
                ) / 100
            )
        end

        SetReadyGlow(frame, true)

        frame.icon:SetDesaturated(false)
        frame.icon:SetVertexColor(1, 1, 1, 1)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        frame.status:SetText("READY")
        frame.cooldown:Hide()
    end

    if unlocked then
        frame.status:Hide()
    else
        frame.status:Show()
    end
end

function BW:UpdateLustUpState()
    if not self:IsLustUpActive() then
        UpdateIndicatorState()
        return
    end

    local locked, info = self:GetLustUpLockout()
    local previous = self.lustUpLocked

    self.lustUpLocked = locked
    self.lustUpLockoutInfo = info

    if locked then
        self.lustUpSeenLockout = true
    elseif previous == true and self.lustUpSeenLockout then
        -- Transition from a real observed lockout to ready. This prevents
        -- "Lust up" from firing merely because the user logged in/reloaded
        -- while already ready.
        self:SpeakLustUp(false)
        self:AnnounceLustUp()
    end

    UpdateIndicatorState()

    if previous ~= locked then
        if InCombatLockdown
            and InCombatLockdown() then

            self.lustUpActionNeedsRefresh = true

        elseif self.RefreshLustUpActionButton then
            self:RefreshLustUpActionButton()
            ApplyIndicatorIcon()
        end

        if self.RefreshLustUpOptions then
            self:RefreshLustUpOptions()
        end
    end
end

function BW:StartLustUpTicker()
    if self.lustUpTicker then
        return
    end

    self.lustUpTicker = C_Timer.NewTicker(
        POLL_INTERVAL,
        function()
            BW:UpdateLustUpState()
        end
    )
end

function BW:StopLustUpTicker()
    if self.lustUpTicker then
        self.lustUpTicker:Cancel()
        self.lustUpTicker = nil
    end
end

function BW:ApplyLustUpSettings()
    if not self.db then
        return
    end

    local frame = CreateIndicator()

    ApplyIndicatorPosition()
    ApplyIndicatorSize()

    if self.RefreshLustUpActionButton then
        self:RefreshLustUpActionButton()
    end

    ApplyIndicatorIcon()

    if self:IsLustUpActive() then
        self:StartLustUpTicker()
        self:UpdateLustUpState()

    elseif self.db.lustUpUnlocked then
        -- Positioning preview only: do not run Lust tracking just because the
        -- indicator is unlocked, but do keep the icon visible and draggable.
        self:StopLustUpTicker()
        self.lustUpLocked = false
        self.lustUpLockoutInfo = nil
        UpdateIndicatorState()

    else
        self:StopLustUpTicker()
        SetReadyGlow(frame, false)
        frame:Hide()
    end
end

function BW:SetLustUpUnlocked(value)
    if not self.db then
        return
    end

    self.db.lustUpUnlocked =
        value and true or false

    if self.RefreshLustUpActionButton then
        self:RefreshLustUpActionButton()
    end

    -- Run the complete settings path. This guarantees unlock mode shows the
    -- positioning preview even when the normal Lust-source gate is inactive.
    self:ApplyLustUpSettings()
end

function BW:ResetLustUpPosition()
    if not self.db then
        return
    end

    self.db.lustUpPoint = "CENTER"
    self.db.lustUpX = 0
    self.db.lustUpY = -160

    ApplyIndicatorPosition()

    if self.RefreshLustUpActionButton then
        self:RefreshLustUpActionButton()
    end

    UpdateIndicatorState()
end

function BW:AddLustUpLockout(input)
    if not self.db then
        return false
    end

    local spellID =
        tonumber(input)
        or tonumber(tostring(input or ""):match("|Hspell:(%d+)"))
        or tonumber(tostring(input or ""):match("spell:(%d+)"))

    if not spellID then
        print(
            "|cffff5555Buff Whitelist - Lust Up:|r "
            .. "Enter a lockout debuff Spell ID."
        )
        return false
    end

    self.db.lustUpCustomLockouts[spellID] = true
    self:UpdateLustUpState()

    if self.RefreshLustUpOptions then
        self:RefreshLustUpOptions()
    end

    print(string.format(
        "|cff33ff99Buff Whitelist - Lust Up:|r tracking %s (%d).",
        GetSpellName(spellID),
        spellID
    ))

    return true
end

function BW:RemoveLustUpLockout(input)
    if not self.db then
        return false
    end

    local spellID =
        tonumber(input)
        or tonumber(tostring(input or ""):match("|Hspell:(%d+)"))
        or tonumber(tostring(input or ""):match("spell:(%d+)"))

    if not spellID then
        return false
    end

    self.db.lustUpCustomLockouts[spellID] = nil
    self:UpdateLustUpState()

    if self.RefreshLustUpOptions then
        self:RefreshLustUpOptions()
    end

    return true
end

function BW:GetLustUpCustomListText()
    if not self.db then
        return "None added."
    end

    local entries = {}

    for spellID, enabled in pairs(self.db.lustUpCustomLockouts or {}) do
        spellID = tonumber(spellID)

        if spellID and enabled then
            entries[#entries + 1] = {
                spellID = spellID,
                name = GetSpellName(spellID),
            }
        end
    end

    table.sort(entries, function(a, b)
        if a.name == b.name then
            return a.spellID < b.spellID
        end

        return a.name < b.name
    end)

    if #entries == 0 then
        return "None added."
    end

    local lines = {}

    for _, entry in ipairs(entries) do
        lines[#lines + 1] = string.format(
            "%s (%d)",
            entry.name,
            entry.spellID
        )
    end

    return table.concat(lines, "\n")
end

function BW:GetLustUpStatusText()
    if not self.db or not self.db.lustUpEnabled then
        return "Status: module disabled"
    end

    if self.db.lustUpRequireLustAbility then
        local hasSource, sourceName, sourceType =
            self:HasLustSource()

        if not hasSource then
            if self.db.lustUpAllowDrums then
                return "Status: inactive — no Lust ability or usable drums"
            end

            return "Status: inactive — no Lust ability available"
        end

        if sourceName
            and not self.lustUpLocked then

            local suffix =
                sourceType == "drums"
                and " in bags"
                or " available"

            return "Status: READY — "
                .. sourceName
                .. suffix
        end
    end

    if self.lustUpLocked then
        local info = self.lustUpLockoutInfo

        if info then
            return string.format(
                "Status: LOCKED — %s (%d)",
                info.name or "Lust lockout",
                info.spellID or 0
            )
        end

        return "Status: LOCKED"
    end

    return "Status: READY — lust can be used again"
end

function BW:InitializeLustUp()
    if self.lustUpInitialized then
        EnsureLustUpEventFrame()
        self:ApplyLustUpSettings()
        return
    end

    self.lustUpInitialized = true
    self.lustUpLocked = nil
    self.lustUpLockoutInfo = nil
    self.lustUpSeenLockout = false
    self.lustBossPullHandled = false

    CreateIndicator()
    EnsureLustUpEventFrame()
    self:ApplyLustUpSettings()
end
