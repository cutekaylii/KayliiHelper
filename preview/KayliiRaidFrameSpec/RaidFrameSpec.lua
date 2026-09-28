local ADDON_NAME, BW = ...

--------------------------------------------------
-- RAID / PARTY FRAME SPEC
--
-- Companion integration for EllesmereUI Raid Frames.
-- Stores independent Raid and Party/5-man positions per specialization and
-- applies them as runtime overlays without replacing Ellesmere's saved positions.
--------------------------------------------------

local function CopyPosition(pos)
    if type(pos) ~= "table" or not pos.point then
        return nil
    end

    return {
        point = pos.point,
        relPoint = pos.relPoint or pos.point,
        x = tonumber(pos.x) or 0,
        y = tonumber(pos.y) or 0,
    }
end

local function Round(value)
    value = tonumber(value) or 0
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function GetCurrentSpec()
    if not GetSpecialization or not GetSpecializationInfo then
        return nil
    end

    local index = GetSpecialization()
    if not index then return nil end

    local specID, name, _, icon = GetSpecializationInfo(index)
    if not specID then return nil end

    if (not name or name == "") and GetSpecializationInfoByID then
        local _, byIDName, _, byIDIcon = GetSpecializationInfoByID(specID)
        name = byIDName or name
        icon = byIDIcon or icon
    end

    return specID, name or ("Spec " .. tostring(specID)), icon
end

local function GetSpecInfoByID(specID)
    if not specID then
        return nil
    end

    local count =
        GetNumSpecializations
        and GetNumSpecializations()
        or 0

    for index = 1, count do
        local id, name, _, icon =
            GetSpecializationInfo(index)

        if id == specID then
            return id,
                name or ("Spec " .. tostring(id)),
                icon
        end
    end

    if GetSpecializationInfoByID then
        local id, name, _, icon =
            GetSpecializationInfoByID(specID)

        if id then
            return id,
                name or ("Spec " .. tostring(id)),
                icon
        end
    end

    return specID,
        "Spec " .. tostring(specID)
end

local function GetEditSpec()
    local selected =
        BW.raidFrameSpecEditSpecID

    if selected then
        local specID, name, icon =
            GetSpecInfoByID(selected)

        if specID then
            return specID, name, icon
        end
    end

    return GetCurrentSpec()
end

local function GetEllesmereIntegration()
    local erf = _G.EllesmereUIRaidFrames
    local eui = _G.EllesmereUI
    local ns

    if eui and type(eui._ModuleNS) == "table" then
        ns = eui._ModuleNS.EllesmereUIRaidFrames

        if not ns and erf then
            for _, candidate in pairs(eui._ModuleNS) do
                if type(candidate) == "table" and candidate.ERF == erf then
                    ns = candidate
                    break
                end
            end
        end
    end

    local profile = erf and erf.db and erf.db.profile
    local raidFrame = _G.EllesmereUIRaidFrameContainer
    local partyFrame = ns and ns._partyContainerFrame

    return erf, ns, profile, raidFrame, eui, partyFrame
end

local function PositionKey(specID)
    return specID and tostring(specID) or nil
end

local function PositionTable(kind)
    if not BW.db then return nil end

    if kind == "party" then
        BW.db.partyFrameSpecPositions = BW.db.partyFrameSpecPositions or {}
        return BW.db.partyFrameSpecPositions
    end

    BW.db.raidFrameSpecPositions = BW.db.raidFrameSpecPositions or {}
    return BW.db.raidFrameSpecPositions
end

local function SavedPosition(kind, specID)
    local positions = PositionTable(kind)
    return positions and positions[PositionKey(specID)] or nil
end

local function PartyOrientationTable()
    if not BW.db then
        return nil
    end

    BW.db.partyFrameSpecOrientations =
        BW.db.partyFrameSpecOrientations or {}

    return BW.db.partyFrameSpecOrientations
end

local function PartyCustomEnabledTable()
    if not BW.db then
        return nil
    end

    BW.db.partyFrameSpecCustomEnabled =
        BW.db.partyFrameSpecCustomEnabled or {}

    return BW.db.partyFrameSpecCustomEnabled
end

local EnsurePartyCustomEnabledMigration

local function IsPartyCustomEnabled(specID)
    if not specID then
        return false
    end

    if EnsurePartyCustomEnabledMigration then
        EnsurePartyCustomEnabledMigration()
    end

    local enabled = PartyCustomEnabledTable()
    return enabled
        and enabled[PositionKey(specID)] == true
        or false
end

local function SavedPartyOrientation(specID)
    local orientations =
        PartyOrientationTable()

    local value =
        orientations
        and orientations[PositionKey(specID)]

    if value == "horizontal"
        or value == "vertical" then

        return value
    end

    return "default"
end

local function RaidOrientationTable()
    if not BW.db then
        return nil
    end

    BW.db.raidFrameSpecOrientations =
        BW.db.raidFrameSpecOrientations or {}

    return BW.db.raidFrameSpecOrientations
end

local function RaidGrowthIsVertical(value)
    return value == "UP" or value == "DOWN"
end

-- Raid orientation means the direction of the five players INSIDE each raid
-- group. Vertical = five players stacked, with groups laid across the other
-- axis. Horizontal = five players in a row, with groups stacked. Preserve
-- Ellesmere's native UP/DOWN and LEFT/RIGHT signs when swapping the axes.
local function RaidGrowthForMode(unitGrowth, groupGrowth, mode)
    unitGrowth = unitGrowth or "DOWN"
    groupGrowth = groupGrowth or "RIGHT"

    if mode ~= "vertical" and mode ~= "horizontal" then
        return unitGrowth, groupGrowth
    end

    local vertical
    if RaidGrowthIsVertical(unitGrowth) then
        vertical = unitGrowth
    elseif RaidGrowthIsVertical(groupGrowth) then
        vertical = groupGrowth
    else
        vertical = "DOWN"
    end

    local horizontal
    if not RaidGrowthIsVertical(unitGrowth) then
        horizontal = unitGrowth
    elseif not RaidGrowthIsVertical(groupGrowth) then
        horizontal = groupGrowth
    else
        horizontal = "RIGHT"
    end

    if mode == "horizontal" then
        return horizontal, vertical
    end

    return vertical, horizontal
end

local function NativeRaidOrientationValue()
    local _, ns, profile = GetEllesmereIntegration()
    if not profile then
        return "vertical"
    end

    local unitGrowth = profile.unitGrowth or "DOWN"
    local groupGrowth = profile.groupGrowth or "RIGHT"

    if ns
        and type(ns._RFResolveTierOverride) == "function"
        and type(ns._GetEffectiveRaidSize) == "function" then

        local ok, _, override = pcall(
            ns._RFResolveTierOverride,
            ns._GetEffectiveRaidSize()
        )

        if ok and override then
            unitGrowth = override.unitGrowth or unitGrowth
            groupGrowth = override.groupGrowth or groupGrowth
        end
    end

    if ns and type(ns._RFEffectiveGrowth) == "function" then
        local ok, u, g = pcall(
            ns._RFEffectiveGrowth,
            unitGrowth,
            groupGrowth,
            profile.mergeGroups
        )
        if ok then
            unitGrowth = u or unitGrowth
            groupGrowth = g or groupGrowth
        end
    end

    return RaidGrowthIsVertical(unitGrowth)
        and "vertical"
        or "horizontal"
end

local function RaidCustomEnabledTable()
    if not BW.db then
        return nil
    end

    BW.db.raidFrameSpecCustomEnabled =
        BW.db.raidFrameSpecCustomEnabled or {}

    return BW.db.raidFrameSpecCustomEnabled
end

local EnsureRaidCustomEnabledMigration
local EnsureRaidOrientationMigration

local function IsRaidCustomEnabled(specID)
    if not specID then
        return false
    end

    if EnsureRaidCustomEnabledMigration then
        EnsureRaidCustomEnabledMigration()
    end

    local enabled = RaidCustomEnabledTable()
    return enabled
        and enabled[PositionKey(specID)] == true
        or false
end

local function SavedRaidOrientation(specID)
    if EnsureRaidOrientationMigration then
        EnsureRaidOrientationMigration()
    end

    local orientations = RaidOrientationTable()
    local value = orientations and orientations[PositionKey(specID)]

    if value == "horizontal" or value == "vertical" then
        return value
    end

    return NativeRaidOrientationValue()
end

local function RaidGrowthForSpec(ns, profile, override, specID)
    local unitGrowth =
        (override and override.unitGrowth)
        or (profile and profile.unitGrowth)
        or "DOWN"

    local groupGrowth =
        (override and override.groupGrowth)
        or (profile and profile.groupGrowth)
        or "RIGHT"

    if specID and IsRaidCustomEnabled(specID) then
        unitGrowth, groupGrowth = RaidGrowthForMode(
            unitGrowth,
            groupGrowth,
            SavedRaidOrientation(specID)
        )
    end

    if ns
        and profile
        and type(ns._RFEffectiveGrowth) == "function" then

        local ok, u, g = pcall(
            ns._RFEffectiveGrowth,
            unitGrowth,
            groupGrowth,
            profile.mergeGroups
        )

        if ok then
            unitGrowth = u or unitGrowth
            groupGrowth = g or groupGrowth
        end
    end

    return unitGrowth, groupGrowth
end

local function RaidScaleEnabledTable()
    if not BW.db then
        return nil
    end

    BW.db.raidFrameSpecScaleEnabled =
        BW.db.raidFrameSpecScaleEnabled or {}

    return BW.db.raidFrameSpecScaleEnabled
end

local function RaidScaleValueTable()
    if not BW.db then
        return nil
    end

    BW.db.raidFrameSpecScaleValues =
        BW.db.raidFrameSpecScaleValues or {}

    return BW.db.raidFrameSpecScaleValues
end

EnsureRaidCustomEnabledMigration = function()
    if not BW.db
        or BW.db.raidFrameSpecCustomEnabledMigrated then

        return
    end

    local enabled = RaidCustomEnabledTable()
    local positions = BW.db.raidFrameSpecPositions or {}
    local legacyScaleEnabled = RaidScaleEnabledTable() or {}
    local scaleValues = RaidScaleValueTable() or {}
    local fallback = BW.db.raidFrameSpecEllesmereDefaults or {}
    local _, _, _, raidFrame = GetEllesmereIntegration()

    local nativeScale = tonumber(fallback.raidScale)
    if not nativeScale and raidFrame and raidFrame.GetScale then
        local ok, value = pcall(raidFrame.GetScale, raidFrame)
        if ok then nativeScale = tonumber(value) end
    end
    nativeScale = nativeScale or 1

    local keys = {}
    for key in pairs(positions) do keys[key] = true end
    for key, value in pairs(legacyScaleEnabled) do
        if value == true then keys[key] = true end
    end

    for key in pairs(keys) do
        enabled[key] = true
        if scaleValues[key] == nil then
            local percent = math.floor(((nativeScale * 100) / 5) + 0.5) * 5
            scaleValues[key] = math.max(50, math.min(125, percent))
        end
        legacyScaleEnabled[key] = true
    end

    BW.db.raidFrameSpecCustomEnabledMigrated = true
end

EnsureRaidOrientationMigration = function()
    if not BW.db
        or BW.db.raidFrameSpecOrientationMigrated then

        return
    end

    EnsureRaidCustomEnabledMigration()

    local enabled = RaidCustomEnabledTable() or {}
    local orientations = RaidOrientationTable() or {}
    local defaultValue = NativeRaidOrientationValue()

    for key, isEnabled in pairs(enabled) do
        if isEnabled == true
            and orientations[key] ~= "vertical"
            and orientations[key] ~= "horizontal" then

            orientations[key] = defaultValue
        end
    end

    BW.db.raidFrameSpecOrientationMigrated = true
end

local function RaidOrientationLabel(mode)
    if mode == "horizontal" then
        return "Horizontal"
    end

    if mode == "vertical" then
        return "Vertical"
    end

    return "Ellesmere default"
end

local function SavedRaidScale(specID)
    if not specID
        or not IsRaidCustomEnabled(specID) then

        return nil
    end

    local key = PositionKey(specID)
    local values = RaidScaleValueTable()
    local value = values and tonumber(values[key]) or 100

    return math.max(
        50,
        math.min(125, value or 100)
    )
end

local function RaidScaleLabel(specID)
    local value = SavedRaidScale(specID)

    if value then
        return string.format("%d%%", value)
    end

    return "Ellesmere scale"
end

local function PartyScaleEnabledTable()
    if not BW.db then
        return nil
    end

    BW.db.partyFrameSpecScaleEnabled =
        BW.db.partyFrameSpecScaleEnabled or {}

    return BW.db.partyFrameSpecScaleEnabled
end

local function PartyScaleValueTable()
    if not BW.db then
        return nil
    end

    BW.db.partyFrameSpecScaleValues =
        BW.db.partyFrameSpecScaleValues or {}

    return BW.db.partyFrameSpecScaleValues
end

EnsurePartyCustomEnabledMigration = function()
    if not BW.db
        or BW.db.partyFrameSpecCustomEnabledMigrated then

        return
    end

    local enabled = PartyCustomEnabledTable()
    local positions = BW.db.partyFrameSpecPositions or {}
    local orientations = PartyOrientationTable() or {}
    local legacyScaleEnabled = PartyScaleEnabledTable() or {}
    local scaleValues = PartyScaleValueTable() or {}
    local fallback = BW.db.raidFrameSpecEllesmereDefaults or {}
    local _, _, profile, _, _, partyFrame = GetEllesmereIntegration()
    local nativeHorizontal = fallback.partyHorizontal

    if nativeHorizontal == nil and profile then
        nativeHorizontal = profile.partyHorizontal == true
    end

    local nativeScale = tonumber(fallback.partyScale)
    if not nativeScale and partyFrame and partyFrame.GetScale then
        local ok, value = pcall(partyFrame.GetScale, partyFrame)
        if ok then nativeScale = tonumber(value) end
    end
    nativeScale = nativeScale or 1

    local keys = {}

    for key in pairs(positions) do keys[key] = true end
    for key, value in pairs(orientations) do
        if value == "horizontal" or value == "vertical" then
            keys[key] = true
        end
    end
    for key, value in pairs(legacyScaleEnabled) do
        if value == true then
            keys[key] = true
        end
    end

    for key in pairs(keys) do
        enabled[key] = true

        if orientations[key] ~= "horizontal"
            and orientations[key] ~= "vertical" then

            orientations[key] = nativeHorizontal == true
                and "horizontal"
                or "vertical"
        end

        if scaleValues[key] == nil then
            local percent = math.floor(((nativeScale * 100) / 5) + 0.5) * 5
            scaleValues[key] = math.max(50, math.min(125, percent))
        end
    end

    BW.db.partyFrameSpecCustomEnabledMigrated = true
end

local function SavedPartyScale(specID)
    if not specID
        or not IsPartyCustomEnabled(specID) then

        return nil
    end

    local key = PositionKey(specID)
    local values = PartyScaleValueTable()
    local value = values and tonumber(values[key]) or 100

    return math.max(
        50,
        math.min(125, value or 100)
    )
end

local function PartyScaleLabel(specID)
    local value = SavedPartyScale(specID)

    if value then
        return string.format("%d%%", value)
    end

    return "Ellesmere scale"
end

local function IsManaged(kind)
    if not BW.db then return false end
    if kind == "party" then
        return BW.db.raidFrameSpecManageParty ~= false
    end
    return BW.db.raidFrameSpecManageRaid ~= false
end

-- The Ellesmere party container can also be present while the player is solo.
-- Kaylii must never reposition/resize that live container outside a real party,
-- otherwise configuring a 5-man preset can move the user's solo frame. The fake
-- mover remains fully usable while solo; only live Party application is gated.
local function IsLivePartyContext()
    if type(IsInRaid) == "function" and IsInRaid() then
        return false
    end

    if type(IsInGroup) == "function" then
        return IsInGroup() and true or false
    end

    if type(GetNumGroupMembers) == "function" then
        return (tonumber(GetNumGroupMembers()) or 0) > 1
    end

    return false
end

local function ElementKey(kind)
    return kind == "party" and "RF_PartyFrames" or "RF_RaidFrames"
end

local function FallbackTable()
    if not BW.db then
        return nil
    end

    BW.db.raidFrameSpecEllesmereDefaults =
        BW.db.raidFrameSpecEllesmereDefaults or {}

    return BW.db.raidFrameSpecEllesmereDefaults
end

local function CaptureCurrentEllesmereBaseline(overwrite)
    if not BW.db then
        return false
    end

    local _, _, profile, raidFrame, _, partyFrame =
        GetEllesmereIntegration()

    if not profile then
        return false
    end

    local fallback = FallbackTable()
    if not fallback then
        return false
    end

    local raidPos = CopyPosition(profile.unlockPos)
    local partyPos = CopyPosition(profile.partyUnlockPos)

    if raidPos and (overwrite or not fallback.raid) then
        fallback.raid = CopyPosition(raidPos)
    end

    if partyPos and (overwrite or not fallback.party) then
        fallback.party = CopyPosition(partyPos)
    end

    if overwrite or fallback.partyHorizontal == nil then
        fallback.partyHorizontal =
            profile.partyHorizontal == true
    end

    if raidFrame and (overwrite or fallback.raidScale == nil) then
        local scale = raidFrame:GetScale()
        if scale and scale > 0 then
            fallback.raidScale = scale
        end
    end

    if fallback.raidScale == nil then
        fallback.raidScale = 1
    end

    if partyFrame and (overwrite or fallback.partyScale == nil) then
        local scale = partyFrame:GetScale()
        if scale and scale > 0 then
            fallback.partyScale = scale
        end
    end

    if fallback.partyScale == nil then
        fallback.partyScale = 1
    end

    return true
end

local function RepairEllesmereBaselineIfNeeded()
    if not BW.db then
        return false
    end

    if (tonumber(BW.db.raidFrameSpecBaselineVersion) or 0) >= 5 then
        return true
    end

    -- Migration v5 remains deliberately non-mutating. Older Kaylii builds could
    -- paint their per-spec coordinates into Ellesmere's live profile, so never
    -- force Ellesmere's spec layer/flush here. We only fill missing fallback
    -- fields, including the party container's native scale added in v5.
    CaptureCurrentEllesmereBaseline(false)

    BW.db.raidFrameSpecBaselineVersion = 5
    BW.raidFrameSpecBaselineRepairPending = nil

    return true
end

local function EllesmereDefaultPosition(kind)
    -- The live Ellesmere profile is the source of truth. Kaylii never writes
    -- its per-spec coordinates into these fields, so reading them gives us the
    -- exact location Ellesmere should return to when no Kaylii override applies.
    local _, _, profile = GetEllesmereIntegration()
    if profile then
        local native = kind == "party"
            and CopyPosition(profile.partyUnlockPos)
            or CopyPosition(profile.unlockPos)

        if native then
            return native
        end
    end

    -- Legacy fallback is read-only recovery data for profiles that have no
    -- current saved position at all. It is never written back into Ellesmere.
    local fallback = FallbackTable()
    return fallback and CopyPosition(fallback[kind]) or nil
end

local function IsElementAnchored(eui, kind)
    if not eui or not eui.IsUnlockAnchored then return false end

    local ok, anchored = pcall(eui.IsUnlockAnchored, ElementKey(kind))
    return ok and anchored and true or false
end

local function SetStatus(text)
    BW.raidFrameSpecStatus = text
    if BW.RefreshRaidFrameSpecOptions then
        BW:RefreshRaidFrameSpecOptions()
    end
end

local function SnapForFrame(frame, value)
    local eui = _G.EllesmereUI

    if eui and eui.PP and eui.PP.SnapForES and frame then
        local ok, snapped = pcall(eui.PP.SnapForES, value, frame:GetEffectiveScale())
        if ok and snapped then return snapped end
    end

    local _, ns = GetEllesmereIntegration()
    if ns and ns.PixelSnap then
        local ok, snapped = pcall(ns.PixelSnap, value)
        if ok and snapped then return snapped end
    end

    return Round(value)
end

local function RaidNativeFromVisualCenter(pos, specID)
    if not pos then return nil end

    local _, ns, profile, raidFrame = GetEllesmereIntegration()
    local x = tonumber(pos.x) or 0
    local y = tonumber(pos.y) or 0

    local usedCustomMath = false

    if specID
        and IsRaidCustomEnabled(specID)
        and ns
        and profile
        and type(ns._RFFootprint) == "function"
        and type(ns._RFCornerTerms) == "function" then

        local ok = pcall(function()
            local cs = tonumber(profile.cellSpacing) or 2
            local gs = tonumber(profile.groupSpacing) or 8

            local baseUG, baseGG =
                RaidGrowthForSpec(ns, profile, nil, specID)

            local baseW, baseH = ns._RFFootprint(
                profile.frameWidth or 72,
                profile.frameHeight or 46,
                baseUG,
                baseGG,
                cs,
                gs
            )

            local override
            if type(ns._RFResolveTierOverride) == "function" then
                local raidSize
                if type(ns._GetEffectiveRaidSize) == "function" then
                    raidSize = ns._GetEffectiveRaidSize()
                end
                local _, resolved = ns._RFResolveTierOverride(raidSize)
                override = resolved
            end

            if override then
                local tierUG, tierGG =
                    RaidGrowthForSpec(ns, profile, override, specID)

                local tierW, tierH = ns._RFFootprint(
                    override.width or profile.frameWidth or 72,
                    override.height or profile.frameHeight or 46,
                    tierUG,
                    tierGG,
                    cs,
                    gs
                )

                local cornerX, cornerY = ns._RFCornerTerms(
                    tierW,
                    tierH,
                    baseW,
                    baseH,
                    tierUG,
                    tierGG
                )

                x = x
                    - (override.offsetX or 0)
                    - (cornerX or 0)
                    - ((tierW - baseW) / 2)

                y = y
                    - (override.offsetY or 0)
                    - (cornerY or 0)
                    - ((baseH - tierH) / 2)
            end

            usedCustomMath = true
        end)

        if not ok then
            usedCustomMath = false
        end
    end

    if not usedCustomMath
        and ns
        and ns._RFRebaseSavedCenter then

        local ok, rebasedX, rebasedY = pcall(
            ns._RFRebaseSavedCenter,
            x,
            y
        )

        if ok then
            x = rebasedX or x
            y = rebasedY or y
        end
    end

    return {
        point = "CENTER",
        relPoint = "CENTER",
        x = SnapForFrame(raidFrame, x),
        y = SnapForFrame(raidFrame, y),
    }
end

local function PartyNativeFromVisualCenter(pos)
    if not pos then return nil end

    local _, _, _, _, _, partyFrame = GetEllesmereIntegration()
    return {
        point = "CENTER",
        relPoint = "CENTER",
        x = SnapForFrame(partyFrame, tonumber(pos.x) or 0),
        y = SnapForFrame(partyFrame, tonumber(pos.y) or 0),
    }
end

local function EnsureRaidNativeMigration()
    if not BW.db or BW.db.raidFrameSpecNativePositions then
        return true
    end

    local _, ns, profile = GetEllesmereIntegration()
    if not ns or not profile then return false end

    local positions = BW.db.raidFrameSpecPositions
    if type(positions) == "table" then
        for key, pos in pairs(positions) do
            if type(pos) == "table" then
                positions[key] = RaidNativeFromVisualCenter(pos)
            end
        end
    end

    BW.db.raidFrameSpecNativePositions = true
    return true
end

local function NativeSaveFromMover(kind, visualPos, specID)
    local _, _, profile = GetEllesmereIntegration()
    if not profile then return nil end

    -- Kaylii owns its per-spec positions. Normalizing a fake-mover position
    -- must never call Ellesmere's savePos callback: RF_RaidFrames/RF_PartyFrames
    -- savePos writes straight into db.profile.unlockPos/partyUnlockPos. Doing so
    -- replaces the user's Ellesmere location merely by saving a Kaylii preset.
    if kind == "raid" then
        return RaidNativeFromVisualCenter(visualPos, specID)
    end

    return PartyNativeFromVisualCenter(visualPos)
end

local function PrimeProfileForSpec(specID)
    -- Do not write Kaylii values directly into Ellesmere's live profile here.
    -- The native layout must be restored first, then Kaylii overlays are applied
    -- out of combat by ApplyManagedFrameSpecPositions.
    return specID ~= nil
end

local function RuntimeSnap(ns, value)
    value = tonumber(value) or 0

    if ns and type(ns.PixelSnap) == "function" then
        local ok, snapped = pcall(ns.PixelSnap, value)
        if ok and tonumber(snapped) then
            return snapped
        end
    end

    return Round(value)
end

local function ApplyRaidRuntimePosition(ns, profile, raidFrame, pos, specID)
    if not raidFrame or not pos then
        return false
    end

    -- Current Ellesmere raid frames use a base-footprint CENTER position plus
    -- growth-corner/tier offsets. Reproduce that math directly against the
    -- frame so Kaylii never has to put its coordinates in db.profile.unlockPos,
    -- even temporarily. Custom Raid orientation is folded into the footprint
    -- math here without changing Ellesmere's saved growth settings.
    local hasTierMath = ns
        and type(ns._RFPosTopLeft) == "function"
        and type(ns._RFFootprint) == "function"
        and type(ns._RFCornerTerms) == "function"
        and type(ns._RFEffectiveGrowth) == "function"

    if hasTierMath then
        local ok = pcall(function()
            local cs = RuntimeSnap(ns, profile.cellSpacing or 2)
            local gs = RuntimeSnap(ns, profile.groupSpacing or 8)

            local baseUG, baseGG =
                RaidGrowthForSpec(ns, profile, nil, specID)

            local baseW, baseH = ns._RFFootprint(
                profile.frameWidth or 72,
                profile.frameHeight or 46,
                baseUG,
                baseGG,
                cs,
                gs
            )

            local baseLeft, baseTop = ns._RFPosTopLeft(pos, baseW, baseH)
            if not baseLeft or not baseTop then
                error("raid base position unavailable")
            end

            local override
            if type(ns._RFResolveTierOverride) == "function" then
                local raidSize
                if type(ns._GetEffectiveRaidSize) == "function" then
                    raidSize = ns._GetEffectiveRaidSize()
                end
                local _, resolved = ns._RFResolveTierOverride(raidSize)
                override = resolved
            end

            local unitGrowth, groupGrowth =
                RaidGrowthForSpec(ns, profile, override, specID)

            local tierW, tierH = ns._RFFootprint(
                (override and override.width) or profile.frameWidth or 72,
                (override and override.height) or profile.frameHeight or 46,
                unitGrowth,
                groupGrowth,
                cs,
                gs
            )

            local cornerX, cornerY = ns._RFCornerTerms(
                tierW,
                tierH,
                baseW,
                baseH,
                unitGrowth,
                groupGrowth
            )

            local x = baseLeft + ((override and override.offsetX) or 0) + (cornerX or 0)
            local y = baseTop + ((override and override.offsetY) or 0) + (cornerY or 0)

            raidFrame:ClearAllPoints()
            raidFrame:SetPoint(
                "TOPLEFT",
                UIParent,
                "BOTTOMLEFT",
                RuntimeSnap(ns, x),
                RuntimeSnap(ns, y)
            )

            -- Ellesmere also keeps a hidden raid container sized to the active
            -- tier so unlock geometry is correct when the raid is not visible.
            if raidFrame.IsShown and not raidFrame:IsShown() then
                raidFrame:SetSize(tierW, tierH)
            end
        end)

        if ok then
            return true
        end
    end

    -- Compatibility fallback for older Ellesmere builds without tier helpers.
    local ok = pcall(function()
        raidFrame:ClearAllPoints()
        raidFrame:SetPoint(
            pos.point or "CENTER",
            UIParent,
            pos.relPoint or pos.point or "CENTER",
            tonumber(pos.x) or 0,
            tonumber(pos.y) or 0
        )
    end)

    return ok and true or false
end

local function NativeApplyPosition(kind, pos, specID)
    if not pos then return false, "missing" end

    local _, ns, profile, raidFrame, eui, partyFrame =
        GetEllesmereIntegration()

    if not profile then return false, "notloaded" end
    if IsElementAnchored(eui, kind) then return false, "anchored" end

    local runtimePos = CopyPosition(pos)
    if not runtimePos then return false, "missing" end

    local previousGuard = BW.raidFrameSpecApplyingRuntimePosition
    BW.raidFrameSpecApplyingRuntimePosition = true

    local applied

    if kind == "raid" then
        applied = ApplyRaidRuntimePosition(
            ns,
            profile,
            raidFrame,
            runtimePos,
            specID
        )
    elseif partyFrame then
        applied = pcall(function()
            partyFrame:ClearAllPoints()
            partyFrame:SetPoint(
                runtimePos.point or "CENTER",
                UIParent,
                runtimePos.relPoint or runtimePos.point or "CENTER",
                tonumber(runtimePos.x) or 0,
                tonumber(runtimePos.y) or 0
            )
        end)
    else
        applied = false
    end

    BW.raidFrameSpecApplyingRuntimePosition = previousGuard

    return applied and true or false,
        applied and nil or "applyfailed"
end

-- Kaylii party mover positions are stored in UIParent/screen coordinate space.
-- WoW applies a frame's scale to SetPoint offsets as well as its dimensions, so
-- feeding those visual offsets directly to a scaled party container makes the
-- real frames drift toward/away from UIParent center. Convert visual offsets to
-- the party container's current scaled coordinate space before SetPoint.
local function PartyVisualToRuntimePosition(pos)
    if not pos then return nil end

    local runtimePos = CopyPosition(pos)
    if not runtimePos then return nil end

    local _, _, _, _, _, partyFrame =
        GetEllesmereIntegration()

    if not partyFrame then
        return runtimePos
    end

    local frameScale
    local uiScale

    if partyFrame.GetEffectiveScale then
        local ok, value = pcall(
            partyFrame.GetEffectiveScale,
            partyFrame
        )
        if ok then frameScale = tonumber(value) end
    end

    if UIParent and UIParent.GetEffectiveScale then
        local ok, value = pcall(
            UIParent.GetEffectiveScale,
            UIParent
        )
        if ok then uiScale = tonumber(value) end
    end

    if frameScale
        and frameScale > 0
        and uiScale
        and uiScale > 0 then

        local factor = uiScale / frameScale
        runtimePos.x = (tonumber(runtimePos.x) or 0) * factor
        runtimePos.y = (tonumber(runtimePos.y) or 0) * factor
    end

    return runtimePos
end

-- Ellesmere's own partyUnlockPos is stored in the party frame's native
-- coordinate space at Ellesmere's native scale. Convert that baseline position
-- to visual/UIParent space before feeding it through PartyVisualToRuntimePosition.
-- This keeps "use Ellesmere position + custom orientation/scale" visually fixed.
local function EllesmerePartyVisualPosition()
    local pos = EllesmereDefaultPosition("party")
    if not pos then return nil end

    local visualPos = CopyPosition(pos)
    if not visualPos then return nil end

    local fallback = FallbackTable()
    local baseScale = fallback
        and tonumber(fallback.partyScale)
        or 1

    if not baseScale or baseScale <= 0 then
        baseScale = 1
    end

    visualPos.x = (tonumber(visualPos.x) or 0) * baseScale
    visualPos.y = (tonumber(visualPos.y) or 0) * baseScale

    return visualPos
end

local function NativeApplyPartyVisualPosition(pos)
    local runtimePos = PartyVisualToRuntimePosition(pos)
    if not runtimePos then
        return false, "missing"
    end

    return NativeApplyPosition(
        "party",
        runtimePos
    )
end

local function RestoreBaselineNonPositionState()
    local _, ns, profile, raidFrame, _, partyFrame =
        GetEllesmereIntegration()

    if not profile then
        return false
    end

    local fallback = FallbackTable()

    -- A custom Raid orientation changes the secure header layout at runtime.
    -- Reload from Ellesmere's untouched profile before restoring scale/position
    -- so disabling Kaylii or handing Raid back to Ellesmere restores its native
    -- Unit Growth / Group Growth immediately, not only after the next roster event.
    if ns and type(ns.ReloadFrames) == "function" then
        local previousGuard = BW.raidFrameSpecApplyingRaidOrientation
        BW.raidFrameSpecApplyingRaidOrientation = true
        pcall(ns.ReloadFrames)
        BW.raidFrameSpecApplyingRaidOrientation = previousGuard
    end

    if IsLivePartyContext()
        and fallback
        and fallback.partyHorizontal ~= nil then

        profile.partyHorizontal =
            fallback.partyHorizontal == true

        if ns and ns._ApplyPartyContainerGeometry then
            pcall(ns._ApplyPartyContainerGeometry)
        end

        if ns and ns._LayoutPartyFrames then
            pcall(ns._LayoutPartyFrames)
        end
    end

    if raidFrame then
        local baseScale =
            fallback
            and tonumber(fallback.raidScale)
            or 1

        pcall(
            raidFrame.SetScale,
            raidFrame,
            baseScale > 0 and baseScale or 1
        )
    end

    if IsLivePartyContext() and partyFrame then
        local baseScale =
            fallback
            and tonumber(fallback.partyScale)
            or 1

        pcall(
            partyFrame.SetScale,
            partyFrame,
            baseScale > 0 and baseScale or 1
        )
    end

    return true
end

local function RestoreEllesmereBaseState(specID)
    if InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecRestorePending = true
        return false
    end

    RepairEllesmereBaselineIfNeeded()

    -- Restore only from Ellesmere's OWN currently saved coordinates. This is a
    -- visual re-apply, not a save: NativeApplyPosition directly re-anchors the
    -- frames and never calls savePos/savePosition or writes unlockPos fields.
    local raidPos = EllesmereDefaultPosition("raid")
    local partyPos = EllesmereDefaultPosition("party")
    local previousSuppress = BW.raidFrameSpecSuppressSpecHook
    BW.raidFrameSpecSuppressSpecHook = true

    if raidPos then
        NativeApplyPosition("raid", raidPos)
    end

    if IsLivePartyContext() and partyPos then
        NativeApplyPosition("party", partyPos)
    end

    RestoreBaselineNonPositionState()

    BW.raidFrameSpecSuppressSpecHook = previousSuppress
    BW.raidFrameSpecRestorePending = nil

    return true
end

local function RefreshEllesmereFrames()
    local _, ns =
        GetEllesmereIntegration()

    if _G._ERF_RefreshAll then
        pcall(_G._ERF_RefreshAll)
        return
    end

    if ns then
        if ns._ApplyTierOffset then
            pcall(ns._ApplyTierOffset)
        end

        if IsLivePartyContext() then
            if ns._ApplyPartyContainerGeometry then
                pcall(ns._ApplyPartyContainerGeometry)
            end

            if ns._LayoutPartyFrames then
                pcall(ns._LayoutPartyFrames)
            end
        end
    end
end

local function ApplyRaidScale(specID)
    local _, _, _, raidFrame =
        GetEllesmereIntegration()

    if not raidFrame then
        return false, "notready", nil
    end

    if InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecPendingSpecID = specID
        return false, "combat", nil
    end

    local custom = SavedRaidScale(specID)
    local fallback = FallbackTable()
    local baseScale =
        fallback
        and tonumber(fallback.raidScale)
        or 1

    local scale = custom and (custom / 100) or baseScale

    local ok = pcall(
        raidFrame.SetScale,
        raidFrame,
        scale
    )

    return ok and true or false,
        ok and nil or "applyfailed",
        custom
end

local function ApplyPartyScale(specID)
    local custom = SavedPartyScale(specID)

    -- While solo, Party settings are configuration-only. Do not scale the
    -- live Ellesmere party container because it may be the frame the user sees
    -- as their solo frame. The saved value will be applied on party join.
    if not IsLivePartyContext() then
        return true, "deferred", custom
    end

    local _, _, _, _, _, partyFrame =
        GetEllesmereIntegration()

    if not partyFrame then
        return false, "notready", nil
    end

    if InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecPendingSpecID = specID
        return false, "combat", nil
    end

    local fallback = FallbackTable()
    local baseScale =
        fallback
        and tonumber(fallback.partyScale)
        or 1

    local scale = custom and (custom / 100) or baseScale

    local ok = pcall(
        partyFrame.SetScale,
        partyFrame,
        scale
    )

    return ok and true or false,
        ok and nil or "applyfailed",
        custom
end

local function GetRaidGeometry(ns, profile, frame, specID)
    if not profile then return 420, 220 end

    if ns and ns._RFFootprint then
        local cs = tonumber(profile.cellSpacing) or 2
        local gs = tonumber(profile.groupSpacing) or 8
        local override

        if ns._RFResolveTierOverride and ns._GetEffectiveRaidSize then
            local ok, _, resolved = pcall(ns._RFResolveTierOverride, ns._GetEffectiveRaidSize())
            if ok then override = resolved end
        end

        local fw = (override and override.width) or profile.frameWidth or 72
        local fh = (override and override.height) or profile.frameHeight or 46
        local unitGrowth, groupGrowth =
            RaidGrowthForSpec(
                ns,
                profile,
                override,
                specID
            )

        local ok, width, height = pcall(ns._RFFootprint, fw, fh, unitGrowth, groupGrowth, cs, gs)
        if ok and tonumber(width) and tonumber(height) and width > 0 and height > 0 then
            return width, height, override, unitGrowth, groupGrowth, cs, gs
        end
    end

    if frame and frame:GetWidth() > 1 and frame:GetHeight() > 1 then
        return frame:GetWidth(), frame:GetHeight()
    end

    return 420, 220
end

local function GetPartyGeometry(
    ns,
    profile,
    frame,
    specID
)
    if not profile then
        return 125, 308
    end

    -- Ellesmere's party container is exactly five single-unit frames laid out
    -- on one axis.  Do not derive this from the live container's aspect ratio:
    -- orientation changes the CONTAINER, never the dimensions of an individual
    -- party unit frame.
    --
    -- RF_PartyDims is Ellesmere's own source of truth for one party button:
    --   width, height, cellSpacing
    -- It is the same function Ellesmere uses when sizing each party button and
    -- when sizing its five-slot party container.
    local unitWidth, unitHeight, spacing

    if ns and type(ns.RF_PartyDims) == "function" then
        local ok, w, h, sp = pcall(ns.RF_PartyDims, profile)
        if ok and tonumber(w) and tonumber(h) and w > 0 and h > 0 then
            unitWidth = tonumber(w)
            unitHeight = tonumber(h)
            spacing = tonumber(sp) or 0
        end
    end

    -- Compatibility fallback for Ellesmere versions where RF_PartyDims is not
    -- exported.  partyFrameWidth/partyFrameHeight are the per-unit party size;
    -- they fall back to the raid unit size in older profiles.
    if not unitWidth or not unitHeight then
        unitWidth = tonumber(profile.partyFrameWidth)
            or tonumber(profile.frameWidth)
            or 125
        unitHeight = tonumber(profile.partyFrameHeight)
            or tonumber(profile.frameHeight)
            or 60
        spacing = tonumber(profile.cellSpacing) or 2
    end

    local mode = SavedPartyOrientation(specID)
    local horizontal

    if mode == "horizontal" then
        horizontal = true
    elseif mode == "vertical" then
        horizontal = false
    else
        horizontal = profile.partyHorizontal == true
    end

    if horizontal then
        return
            (unitWidth * 5) + (spacing * 4),
            unitHeight
    end

    return
        unitWidth,
        (unitHeight * 5) + (spacing * 4)
end

local function PositionRaidMoverFromSaved(
    mover,
    pos,
    specID
)
    local _, ns, profile, frame =
        GetEllesmereIntegration()

    local width,
        height,
        override,
        unitGrowth,
        groupGrowth,
        cs,
        gs =
        GetRaidGeometry(
            ns,
            profile,
            frame,
            specID
        )

    local customScale =
        SavedRaidScale(specID)

    local fallback = FallbackTable()
    local scale = customScale
        and (customScale / 100)
        or (
            fallback
            and tonumber(fallback.raidScale)
            or 1
        )

    mover._khRaidLogicalWidth = width
    mover._khRaidLogicalHeight = height
    mover._khRaidVisualScale = scale

    mover:SetSize(
        math.max(120, width * scale),
        math.max(60, height * scale)
    )
    mover:ClearAllPoints()

    if pos
        and ns
        and profile
        and ns._RFPosTopLeft
        and ns._RFFootprint
        and ns._RFCornerTerms then

        local baseUnit, baseGroup =
            RaidGrowthForSpec(
                ns,
                profile,
                nil,
                specID
            )

        local okBase,
            baseWidth,
            baseHeight =
            pcall(
                ns._RFFootprint,
                profile.frameWidth or 72,
                profile.frameHeight or 46,
                baseUnit,
                baseGroup,
                cs or (profile.cellSpacing or 2),
                gs or (profile.groupSpacing or 8)
            )

        if okBase and baseWidth and baseHeight then
            local okTL,
                baseLeft,
                baseTop =
                pcall(
                    ns._RFPosTopLeft,
                    pos,
                    baseWidth,
                    baseHeight
                )

            if okTL and baseLeft and baseTop then
                local cornerX, cornerY = 0, 0

                local okCorner, cx, cy = pcall(
                    ns._RFCornerTerms,
                    width,
                    height,
                    baseWidth,
                    baseHeight,
                    unitGrowth or baseUnit,
                    groupGrowth or baseGroup
                )

                if okCorner then
                    cornerX = cx or 0
                    cornerY = cy or 0
                end

                mover:SetPoint(
                    "TOPLEFT",
                    UIParent,
                    "BOTTOMLEFT",
                    baseLeft
                        + ((override and override.offsetX) or 0)
                        + cornerX,
                    baseTop
                        + ((override and override.offsetY) or 0)
                        + cornerY
                )

                return
            end
        end
    end

    if pos and pos.point then
        mover:SetPoint(
            pos.point,
            UIParent,
            pos.relPoint or pos.point,
            pos.x or 0,
            pos.y or 0
        )
    else
        mover:SetPoint(
            "CENTER",
            UIParent,
            "CENTER",
            0,
            0
        )
    end
end

local function PositionPartyMoverFromSaved(
    mover,
    pos,
    specID
)
    local _, ns, profile, _, _, partyFrame =
        GetEllesmereIntegration()

    local width, height =
        GetPartyGeometry(
            ns,
            profile,
            partyFrame,
            specID
        )

    -- Use the exact five-slot footprint. Scale the preview as a whole, just
    -- like Ellesmere's real party container, without changing the unit-frame
    -- aspect ratio or the 5-frame row/column geometry.
    local customScale = SavedPartyScale(specID)
    local fallback = FallbackTable()
    local scale = customScale
        and (customScale / 100)
        or (
            fallback
            and tonumber(fallback.partyScale)
            or 1
        )

    mover:SetSize(
        math.max(1, width * scale),
        math.max(1, height * scale)
    )
    mover:ClearAllPoints()

    if pos and pos.point then
        mover:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        mover:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function MoverField(kind)
    return kind == "party" and "partyFrameSpecMover" or "raidFrameSpecMover"
end

local function GetMover(kind)
    return BW[MoverField(kind)]
end

local function UpdateMoverText(kind)
    local mover = GetMover(kind)
    if not mover then return end

    local specID, specName =
        GetEditSpec()

    mover.title:SetText(
        (kind == "party" and "Ellesmere Party / 5-Man — " or "Ellesmere Raid Frames — ")
        .. tostring(specName or "Current Spec")
    )

    local x, y = mover:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and y and ux and uy then
        mover.coords:SetText(string.format(
            "Drag to position  •  X %d  Y %d\nSave Mover Position when finished",
            Round(x - ux), Round(y - uy)
        ))
    else
        mover.coords:SetText("Drag to position\nSave Mover Position when finished")
    end

    mover.specID = specID
end

local function CreateMover(kind)
    local existing = GetMover(kind)
    if existing then return existing end

    local globalName = kind == "party"
        and "KayliiHelperPartyFrameSpecMover"
        or "KayliiHelperRaidFrameSpecMover"

    local mover = CreateFrame("Frame", globalName, UIParent, "BackdropTemplate")
    mover.kind = kind
    mover:SetFrameStrata("FULLSCREEN_DIALOG")
    mover:SetFrameLevel(180)
    mover:SetClampedToScreen(true)
    mover:SetMovable(true)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    mover:SetBackdropColor(0.025, 0.055, 0.10, 0.70)
    mover:SetBackdropBorderColor(0.20, 0.62, 1.00, 1.00)

    local title = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mover, "TOP", 0, -14)
    title:SetWidth(420)
    title:SetJustifyH("CENTER")
    if title.SetWordWrap then title:SetWordWrap(true) end
    title:SetTextColor(0.30, 0.72, 1.00, 1)
    mover.title = title

    local coords = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    coords:SetPoint("TOP", title, "BOTTOM", 0, -10)
    coords:SetWidth(380)
    coords:SetJustifyH("CENTER")
    if coords.SetWordWrap then coords:SetWordWrap(true) end
    coords:SetTextColor(0.90, 0.94, 1.00, 1)
    mover.coords = coords

    local hint = mover:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", mover, "BOTTOM", 0, 12)
    hint:SetWidth(420)
    hint:SetJustifyH("CENTER")
    if hint.SetWordWrap then hint:SetWordWrap(true) end
    hint:SetText(kind == "party"
        and "Fake party mover only — the real 5-man frames are not being dragged"
        or "Fake raid mover only — the real raid frames are not being dragged")
    mover.hint = hint

    mover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        UpdateMoverText(kind)
        SetStatus((kind == "party" and "Party" or "Raid")
            .. " mover changed. Click Save Mover Position to store it for this spec.")
    end)

    mover:SetScript("OnShow", function()
        UpdateMoverText(kind)
        if BW.RefreshRaidFrameSpecOptions then BW:RefreshRaidFrameSpecOptions() end
    end)

    mover:SetScript("OnHide", function()
        if BW.RefreshRaidFrameSpecOptions then BW:RefreshRaidFrameSpecOptions() end
    end)

    mover:Hide()
    BW[MoverField(kind)] = mover
    return mover
end

local function MoverPositionForCurrentSpec(kind)
    local specID =
        GetEditSpec()

    local pos =
        SavedPosition(kind, specID)

    if pos then
        return CopyPosition(pos)
    end

    local fallback

    if kind == "party" then
        fallback = EllesmerePartyVisualPosition()
    else
        fallback = EllesmereDefaultPosition(kind)
    end

    if fallback then
        return fallback
    end

    return {
        point = "CENTER",
        relPoint = "CENTER",
        x = 0,
        y = 0,
    }
end

local function PositionMoverForCurrentSpec(kind)
    local mover = GetMover(kind)
    if not mover then return end

    local specID =
        GetEditSpec()

    local pos =
        MoverPositionForCurrentSpec(kind)

    if kind == "party" then
        PositionPartyMoverFromSaved(
            mover,
            pos,
            specID
        )
    else
        PositionRaidMoverFromSaved(
            mover,
            pos,
            specID
        )
    end
    UpdateMoverText(kind)
end

local function CaptureMoverPosition(kind)
    local mover = GetMover(kind)
    if not mover or not mover:IsShown() then return nil end

    local ux, uy = UIParent:GetCenter()
    if not ux or not uy then return nil end

    local x, y

    if kind == "raid"
        and mover._khRaidLogicalWidth
        and mover._khRaidLogicalHeight then

        local left = mover:GetLeft()
        local top = mover:GetTop()

        if left and top then
            x = left + (mover._khRaidLogicalWidth / 2)
            y = top - (mover._khRaidLogicalHeight / 2)
        end
    end

    if not x or not y then
        x, y = mover:GetCenter()
    end

    if not x or not y then return nil end

    return {
        point = "CENTER",
        relPoint = "CENTER",
        x = Round(x - ux),
        y = Round(y - uy),
    }
end

local function ShowMover(kind)
    local _, ns, profile, _, eui = GetEllesmereIntegration()
    if not profile or not ns then
        SetStatus("EllesmereUI Raid Frames must be loaded before the fake mover can be used.")
        return false
    end

    do
        local specID, specName = GetEditSpec()
        local customEnabled
        if kind == "party" then
            customEnabled = IsPartyCustomEnabled(specID)
        else
            customEnabled = IsRaidCustomEnabled(specID)
        end

        if not specID or not customEnabled then
            SetStatus(
                "Enable custom "
                .. (kind == "party" and "Party" or "Raid")
                .. " settings for "
                .. tostring(specName or "this spec")
                .. " before using the mover."
            )
            return false
        end
    end

    if IsElementAnchored(eui, kind) then
        SetStatus((kind == "party" and "Party" or "Raid")
            .. " frames are element-anchored in Ellesmere. Remove that anchor before using the spec mover.")
        return false
    end

    local otherKind = kind == "party" and "raid" or "party"
    local other = GetMover(otherKind)
    if other then other:Hide() end

    local mover = CreateMover(kind)
    PositionMoverForCurrentSpec(kind)
    mover:Show()
    mover:Raise()
    UpdateMoverText(kind)

    SetStatus((kind == "party" and "Party / 5-man" or "Raid")
        .. " fake mover shown. Drag it, then save the mover position.")
    return true
end

local function HideMover(kind)
    local mover = GetMover(kind)
    if mover then mover:Hide() end
    SetStatus((kind == "party" and "Party" or "Raid") .. " fake mover hidden.")
end

local function SaveMoverPosition(kind)
    if not BW.db then return false end

    EnsureRaidNativeMigration()

    local specID, specName =
        GetEditSpec()

    if not specID then
        SetStatus(
            "Could not determine the selected specialization."
        )
        return false
    end

    local customEnabled
    if kind == "party" then
        customEnabled = IsPartyCustomEnabled(specID)
    else
        customEnabled = IsRaidCustomEnabled(specID)
    end

    if not customEnabled then
        SetStatus(
            "Enable custom "
            .. (kind == "party" and "Party" or "Raid")
            .. " settings for "
            .. tostring(specName or "this spec")
            .. " before saving a mover position."
        )
        return false
    end

    local currentSpecID =
        GetCurrentSpec()

    local _, _, profile, _, eui = GetEllesmereIntegration()
    if not profile then
        SetStatus("EllesmereUI Raid Frames is not loaded.")
        return false
    end

    if IsElementAnchored(eui, kind) then
        SetStatus("Cannot save while Ellesmere " .. (kind == "party" and "party" or "raid") .. " frames are element-anchored.")
        return false
    end

    local visualPos = CaptureMoverPosition(kind)
    if not visualPos then
        SetStatus("Show the " .. (kind == "party" and "party" or "raid") .. " fake mover first, then drag it into position.")
        return false
    end

    local stored

    if specID == currentSpecID then
        stored =
            NativeSaveFromMover(
                kind,
                visualPos,
                specID
            )
    elseif kind == "raid" then
        stored =
            RaidNativeFromVisualCenter(
                visualPos,
                specID
            )
    else
        stored =
            PartyNativeFromVisualCenter(
                visualPos
            )
    end

    if not stored then
        SetStatus(
            "Could not normalize the selected mover position."
        )
        return false
    end

    local positions = PositionTable(kind)
    positions[PositionKey(specID)] = CopyPosition(stored)

    if kind == "raid" then
        BW.db.raidFrameSpecNativePositions = true
    end

    if specID == currentSpecID then
        if kind == "party" then
            if IsLivePartyContext() then
                ApplyPartyOrientation(
                    specID,
                    false
                )

                -- Apply the selected scale first, then translate the mover's
                -- UIParent-space coordinates into the scaled party frame's
                -- SetPoint coordinate space. This keeps the real frames centered
                -- exactly on the fake mover at every scale.
                ApplyPartyScale(specID)
                NativeApplyPartyVisualPosition(stored)
            end
        else
            NativeApplyPosition(
                kind,
                stored,
                specID
            )
        end
    end

    PositionMoverForCurrentSpec(kind)

    if specID == currentSpecID then
        if kind == "party" and not IsLivePartyContext() then
            SetStatus(
                "Saved party / 5-man position for "
                .. tostring(specName)
                .. ". It will apply when you join a party; the solo frame was not changed."
            )
        else
            SetStatus(
                "Saved and applied "
                .. (kind == "party" and "party / 5-man" or "raid")
                .. " position for "
                .. tostring(specName)
                .. "."
            )
        end
    else
        SetStatus(
            "Saved "
            .. (kind == "party" and "party / 5-man" or "raid")
            .. " position for "
            .. tostring(specName)
            .. ". It will apply automatically when you play that spec."
        )
    end

    return true
end

local function ClearSavedPosition(kind)
    if not BW.db then
        return false
    end

    local specID, specName =
        GetEditSpec()

    if not specID then
        return false
    end

    local currentSpecID =
        GetCurrentSpec()

    local positions =
        PositionTable(kind)

    positions[PositionKey(specID)] =
        nil

    if specID ~= currentSpecID then
        SetStatus(
            "Cleared saved "
            .. (kind == "party" and "party / 5-man" or "raid")
            .. " position for "
            .. tostring(specName)
            .. ". That spec will use Ellesmere default."
        )

    elseif InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecPendingSpecID =
            specID

        SetStatus(
            "Cleared saved "
            .. (kind == "party" and "party / 5-man" or "raid")
            .. " position for "
            .. tostring(specName)
            .. ". Ellesmere default will restore when combat ends."
        )
    else
        if BW.db.raidFrameSpecEnabled then
            if kind ~= "party" or IsLivePartyContext() then
                BW:QueueRaidFrameSpecApply()
            end

            SetStatus(
                "Cleared saved "
                .. (kind == "party" and "party / 5-man" or "raid")
                .. " position for "
                .. tostring(specName)
                .. (kind == "party" and not IsLivePartyContext()
                    and ". Ellesmere will be used when you join a party; the solo frame was not changed."
                    or ". Restoring Ellesmere default.")
            )
        else
            RestoreEllesmereBaseState(
                specID
            )

            SetStatus(
                "Cleared saved "
                .. (kind == "party" and "party / 5-man" or "raid")
                .. " position for "
                .. tostring(specName)
                .. ". Using Ellesmere default."
            )
        end
    end

    PositionMoverForCurrentSpec(kind)

    return true
end

local function ApplyRaidOrientation(specID)
    local mode =
        IsRaidCustomEnabled(specID)
        and SavedRaidOrientation(specID)
        or "default"

    if InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecPendingSpecID = specID
        return false, "combat", mode
    end

    local _, ns, profile = GetEllesmereIntegration()
    if not profile or not ns then
        return false, "notloaded", mode
    end

    local function ReloadRaidLayout()
        if type(ns.ReloadFrames) == "function" then
            ns.ReloadFrames()
            return
        end

        if type(ns._LayoutGroupsImpl) == "function" then
            ns._LayoutGroupsImpl()
            if type(ns._ApplyTierOffset) == "function" then
                ns._ApplyTierOffset()
            end
            return
        end

        error("Ellesmere raid layout function unavailable")
    end

    local previousGuard = BW.raidFrameSpecApplyingRaidOrientation
    BW.raidFrameSpecApplyingRaidOrientation = true

    local oldUnit = profile.unitGrowth
    local oldGroup = profile.groupGrowth

    local override
    if type(ns._RFResolveTierOverride) == "function" then
        local raidSize
        if type(ns._GetEffectiveRaidSize) == "function" then
            raidSize = ns._GetEffectiveRaidSize()
        end

        local ok, _, resolved = pcall(
            ns._RFResolveTierOverride,
            raidSize
        )
        if ok then override = resolved end
    end

    local oldOverrideUnit = override and override.unitGrowth
    local oldOverrideGroup = override and override.groupGrowth

    if mode == "vertical" or mode == "horizontal" then
        profile.unitGrowth, profile.groupGrowth = RaidGrowthForMode(
            oldUnit or "DOWN",
            oldGroup or "RIGHT",
            mode
        )

        if override then
            override.unitGrowth, override.groupGrowth = RaidGrowthForMode(
                oldOverrideUnit or oldUnit or "DOWN",
                oldOverrideGroup or oldGroup or "RIGHT",
                mode
            )
        end
    end

    local ok = pcall(ReloadRaidLayout)

    profile.unitGrowth = oldUnit
    profile.groupGrowth = oldGroup

    if override then
        override.unitGrowth = oldOverrideUnit
        override.groupGrowth = oldOverrideGroup
    end

    BW.raidFrameSpecApplyingRaidOrientation = previousGuard

    return ok and true or false,
        ok and nil or "applyfailed",
        mode
end

local function ApplyPartyOrientation(
    specID,
    defaultsPrepared
)
    local mode =
        IsPartyCustomEnabled(specID)
        and SavedPartyOrientation(specID)
        or "default"

    -- Allow the user to edit orientation while solo, but never rebuild the
    -- live party container until there is an actual party to display.
    if not IsLivePartyContext() then
        return true,
            "deferred",
            mode
    end

    local _, ns, profile =
        GetEllesmereIntegration()

    if not profile then
        return false,
            "notloaded",
            "default"
    end

    if mode == "default" then
        -- Restore only Ellesmere's native orientation here. A full baseline
        -- restore also repositions/resizes the secure party container and can
        -- race the per-spec position that is applied immediately afterwards.
        -- Position and scale are restored independently by ApplyKind and
        -- ApplyPartyScale, so there is no reason to move the container here.
        local fallback = FallbackTable()
        if fallback
            and fallback.partyHorizontal ~= nil then

            profile.partyHorizontal =
                fallback.partyHorizontal == true
        end

    elseif mode == "horizontal" then
        profile.partyHorizontal = true

    else
        profile.partyHorizontal = false
    end

    if ns and ns._ApplyPartyContainerGeometry then
        pcall(ns._ApplyPartyContainerGeometry)
    end

    if ns and ns._LayoutPartyFrames then
        pcall(ns._LayoutPartyFrames)
    end

    return true,
        nil,
        mode
end

local function PartyOrientationLabel(mode)
    if mode == "horizontal" then
        return "Horizontal"
    end

    if mode == "vertical" then
        return "Vertical"
    end

    return "Ellesmere default"
end

local function ApplyKind(
    kind,
    specID,
    manual,
    defaultsPrepared
)
    if not BW.db then
        return false, "nodatabase"
    end

    if not manual
        and not IsManaged(kind) then

        return false, "disabled"
    end

    EnsureRaidNativeMigration()

    local currentSpecID =
        GetCurrentSpec()

    specID =
        specID or currentSpecID

    if not specID then
        return false, "nospec"
    end

    local _, specName =
        GetSpecInfoByID(specID)

    if kind == "party" and not IsLivePartyContext() then
        return true,
            "deferred",
            specName
    end

    if InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecPendingSpecID =
            specID

        return false,
            "combat",
            specName
    end

    local _, _, profile, _, eui =
        GetEllesmereIntegration()

    if not profile then
        return false,
            "notloaded",
            specName
    end

    if IsElementAnchored(eui, kind) then
        return false,
            "anchored",
            specName
    end

    local pos

    if (kind == "party" and not IsPartyCustomEnabled(specID))
        or (kind == "raid" and not IsRaidCustomEnabled(specID)) then

        pos = nil
    else
        pos = SavedPosition(kind, specID)
    end

    if not pos then
        -- Even when the baseline was restored a moment ago, Ellesmere's
        -- geometry/layout callbacks can clear or rebuild the party container's
        -- anchor while changing orientation. Re-apply Ellesmere's own saved
        -- position AFTER those callbacks so an orientation-only override never
        -- drops the real party frame into UIParent center. For Party, convert
        -- Ellesmere's native-scale saved offset to visual space first so a
        -- Kaylii scale override does not move the baseline location.
        local fallback

        if kind == "party" then
            fallback = EllesmerePartyVisualPosition()
        else
            fallback = EllesmereDefaultPosition(kind)
        end

        if not fallback then
            return false,
                "nodefault",
                specName
        end

        local applied, reason

        if kind == "party" then
            applied, reason =
                NativeApplyPartyVisualPosition(
                    fallback
                )
        else
            applied, reason =
                NativeApplyPosition(
                    kind,
                    fallback,
                    specID
                )
        end

        if applied then
            return true,
                "default",
                specName
        end

        return false,
            reason or "applyfailed",
            specName
    end

    local applied, reason

    if kind == "party" then
        applied, reason =
            NativeApplyPartyVisualPosition(
                pos
            )
    else
        applied, reason =
            NativeApplyPosition(
                kind,
                pos,
                specID
            )
    end

    if applied then
        return true,
            nil,
            specName
    end

    return false,
        reason or "applyfailed",
        specName
end

-- Ellesmere's party header/container is secure and some geometry/layout passes
-- finish on the next frame. Reassert the CURRENT spec's runtime anchor after
-- those passes so an orientation change cannot leave the real frames at
-- Ellesmere's native location while Kaylii's mover remains at the saved one.
local function SchedulePartyRuntimeReanchor(specID)
    if not specID or not C_Timer or not C_Timer.After then return end
    if specID ~= GetCurrentSpec() then return end
    if not IsLivePartyContext() then return end

    BW.raidFrameSpecPartyAnchorSerial =
        (BW.raidFrameSpecPartyAnchorSerial or 0) + 1
    local serial = BW.raidFrameSpecPartyAnchorSerial

    local function Reanchor()
        if serial ~= BW.raidFrameSpecPartyAnchorSerial then return end
        if specID ~= GetCurrentSpec() then return end
        if not IsLivePartyContext() then return end
        if not BW.db
            or not BW.db.raidFrameSpecEnabled
            or not IsManaged("party") then
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            BW.raidFrameSpecPendingSpecID = specID
            return
        end

        -- Move using the current scale first, apply the requested scale, then
        -- re-anchor once more using scaled-coordinate compensation. SetScale
        -- also scales SetPoint offsets in WoW, so the final re-anchor is what
        -- keeps the real frame center identical to the mover center.
        ApplyKind(
            "party",
            specID,
            true,
            false
        )

        ApplyPartyScale(specID)

        ApplyKind(
            "party",
            specID,
            true,
            false
        )
    end

    C_Timer.After(0, Reanchor)
    C_Timer.After(0.05, Reanchor)
end

local function ResultText(kind, ok, reason)
    local label =
        kind == "party"
        and "Party"
        or "Raid"

    if reason == "default" then
        return label .. " Ellesmere default"
    end

    if reason == "deferred" then
        return label .. " saved — applies in party"
    end

    if ok then
        return label .. " applied"
    end

    if reason == "disabled" then
        return label .. " disabled"
    end

    if reason == "anchored" then
        return label .. " anchored"
    end

    if reason == "combat" then
        return label .. " queued"
    end

    if reason == "nodefault" then
        return label .. " default unavailable"
    end

    return label .. " unavailable"
end

function BW:GetRaidFrameSpecCurrentSpec()
    return GetCurrentSpec()
end

function BW:GetRaidFrameSpecEditSpec()
    return GetEditSpec()
end

function BW:SetRaidFrameSpecEditSpec(specID)
    local validID, specName =
        GetSpecInfoByID(specID)

    if not validID then
        return false
    end

    self.raidFrameSpecEditSpecID =
        validID

    self:SyncRaidFrameSpecMoversToCurrentSpec()

    SetStatus(
        "Editing settings for "
        .. tostring(specName)
        .. ". You do not need to change your active specialization."
    )

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end

    return true
end

function BW:ResetRaidFrameSpecEditSpec()
    self.raidFrameSpecEditSpecID =
        nil

    self:SyncRaidFrameSpecMoversToCurrentSpec()

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:GetRaidFrameSpecIntegrationState()
    local _, ns, profile, raidFrame, _, partyFrame = GetEllesmereIntegration()
    if not profile then
        return false, "EllesmereUI Raid Frames is not loaded."
    end
    if not ns and not raidFrame and not partyFrame then
        return false, "EllesmereUI Raid Frames is loaded, but its containers are not ready yet."
    end
    return true, "EllesmereUI Raid Frames detected. Raid and Party / 5-man positions are managed independently."
end

local function PositionText(kind)
    local specID, specName =
        GetEditSpec()

    local pos =
        SavedPosition(
            kind,
            specID
        )

    local label =
        kind == "party"
        and "Party"
        or "Raid"

    if (kind == "party" and not IsPartyCustomEnabled(specID))
        or (kind == "raid" and not IsRaidCustomEnabled(specID)) then

        return label
            .. " for "
            .. tostring(specName)
            .. ": Ellesmere default (custom disabled)"
    end

    if not pos then
        return label
            .. " for "
            .. tostring(specName)
            .. ": Ellesmere default"
    end

    return string.format(
        "%s for %s: saved   X %d   Y %d",
        label,
        tostring(specName),
        Round(pos.x),
        Round(pos.y)
    )
end

local function LiveContainerText(kind)
    local _, ns, _, raidFrame, _, partyFrame = GetEllesmereIntegration()
    local frame = kind == "party" and partyFrame or raidFrame
    if not frame then
        return (kind == "party" and "Party" or "Raid") .. " live container: not created"
    end

    local shown = frame:IsShown() and "shown" or "hidden"
    local x, y = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and y and ux and uy then
        return string.format(
            "%s live container: %s   center X %d   Y %d",
            kind == "party" and "Party" or "Raid",
            shown, Round(x - ux), Round(y - uy)
        )
    end

    return (kind == "party" and "Party" or "Raid") .. " live container: " .. shown
end

function BW:GetRaidFrameSpecCurrentRaidPositionText()
    return PositionText("raid")
end

function BW:GetRaidFrameSpecCurrentPartyPositionText()
    return PositionText("party")
end

function BW:GetRaidFrameSpecLiveRaidContainerText()
    return LiveContainerText("raid")
end

function BW:GetRaidFrameSpecLivePartyContainerText()
    return LiveContainerText("party")
end

-- Backward-compatible aliases used by earlier page builds.
function BW:GetRaidFrameSpecCurrentPositionText()
    return self:GetRaidFrameSpecCurrentRaidPositionText()
end

function BW:GetRaidFrameSpecLiveContainerText()
    return self:GetRaidFrameSpecLiveRaidContainerText()
end

function BW:GetRaidFrameSpecSavedListText()
    local lines = {}
    local count = GetNumSpecializations and GetNumSpecializations() or 0
    local editSpecID = select(1, GetEditSpec())

    for index = 1, count do
        local specID, name = GetSpecializationInfo(index)
        if specID then
            local raidEnabled = IsRaidCustomEnabled(specID)
            local partyEnabled = IsPartyCustomEnabled(specID)

            local raidText = "Raid: Ellesmere"
            if raidEnabled then
                local raidPos = SavedPosition("raid", specID)
                local raidOrientation = SavedRaidOrientation(specID)
                local raidScale = SavedRaidScale(specID)
                raidText = "Raid: On • "
                    .. (raidPos
                        and string.format("Pos %d,%d", Round(raidPos.x), Round(raidPos.y))
                        or "Default pos")
                    .. " • "
                    .. RaidOrientationLabel(raidOrientation)
                    .. " • Scale "
                    .. string.format("%d%%", raidScale or 100)
            end

            local partyText = "Party: Ellesmere"
            if partyEnabled then
                local partyPos = SavedPosition("party", specID)
                local orientation = SavedPartyOrientation(specID)
                local partyScale = SavedPartyScale(specID)
                partyText = "Party: On • "
                    .. (partyPos
                        and string.format("Pos %d,%d", Round(partyPos.x), Round(partyPos.y))
                        or "Default pos")
                    .. " • "
                    .. PartyOrientationLabel(orientation)
                    .. " • Scale "
                    .. string.format("%d%%", partyScale or 100)
            end

            local line =
                tostring(name or ("Spec " .. tostring(specID)))
                .. "  —  "
                .. raidText
                .. "  |  "
                .. partyText

            if specID == editSpecID then
                lines[#lines + 1] = "|cff59b7ff" .. line .. "|r"
            else
                lines[#lines + 1] = "|cff9aa7b8" .. line .. "|r"
            end
        end
    end

    return #lines > 0 and table.concat(lines, "\n") or "No specialization data available."
end

function BW:GetRaidFrameSpecStatusText()
    if not self.db then return "Status unavailable." end
    if self.raidFrameSpecStatus then return self.raidFrameSpecStatus end

    local ok, integrationText = self:GetRaidFrameSpecIntegrationState()
    if not ok then return integrationText end
    if not self.db.raidFrameSpecEnabled then return "Module disabled. Saved positions are kept." end

    local specID, specName = GetCurrentSpec()
    if not specID then return "No active specialization detected." end

    local parts = {}
    if IsManaged("raid") then
        if not IsRaidCustomEnabled(specID) then
            parts[#parts + 1] =
                "Raid Ellesmere default / Custom off"
        else
            local raidState =
                SavedPosition("raid", specID)
                and "Raid saved"
                or "Raid default position"

            parts[#parts + 1] =
                raidState
                .. " / "
                .. RaidOrientationLabel(
                    SavedRaidOrientation(specID)
                )
                .. " / "
                .. RaidScaleLabel(specID)
        end
    end
    if IsManaged("party") then
        if not IsPartyCustomEnabled(specID) then
            parts[#parts + 1] =
                "Party Ellesmere default / Custom off"
        else
            local partyState =
                SavedPosition("party", specID)
                and "Party saved"
                or "Party default position"

            parts[#parts + 1] =
                partyState
                .. " / "
                .. PartyOrientationLabel(
                    SavedPartyOrientation(specID)
                )
                .. " / "
                .. PartyScaleLabel(specID)
        end
    end

    return tostring(specName) .. " — " .. table.concat(parts, "  •  ")
end

function BW:IsRaidFrameSpecMoverShown()
    local mover = GetMover("raid")
    return mover and mover:IsShown() and true or false
end

function BW:IsPartyFrameSpecMoverShown()
    local mover = GetMover("party")
    return mover and mover:IsShown() and true or false
end

function BW:ShowRaidFrameSpecMover() return ShowMover("raid") end
function BW:HideRaidFrameSpecMover() return HideMover("raid") end
function BW:ToggleRaidFrameSpecMover()
    if self:IsRaidFrameSpecMoverShown() then return HideMover("raid") end
    return ShowMover("raid")
end

function BW:ShowPartyFrameSpecMover() return ShowMover("party") end
function BW:HidePartyFrameSpecMover() return HideMover("party") end

function BW:HideRaidFrameSpecMovers()
    local raidMover =
        GetMover("raid")

    local partyMover =
        GetMover("party")

    if raidMover then
        raidMover:Hide()
    end

    if partyMover then
        partyMover:Hide()
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end
function BW:TogglePartyFrameSpecMover()
    if self:IsPartyFrameSpecMoverShown() then return HideMover("party") end
    return ShowMover("party")
end

function BW:SyncRaidFrameSpecMoversToCurrentSpec()
    if self:IsRaidFrameSpecMoverShown() then PositionMoverForCurrentSpec("raid") end
    if self:IsPartyFrameSpecMoverShown() then PositionMoverForCurrentSpec("party") end
end

function BW:SyncRaidFrameSpecMoverToCurrentSpec()
    return self:SyncRaidFrameSpecMoversToCurrentSpec()
end

function BW:SaveRaidFrameSpecMoverPosition() return SaveMoverPosition("raid") end
function BW:SavePartyFrameSpecMoverPosition() return SaveMoverPosition("party") end
function BW:ClearCurrentRaidFrameSpecPosition() return ClearSavedPosition("raid") end
function BW:ClearCurrentPartyFrameSpecPosition() return ClearSavedPosition("party") end

function BW:GetRaidFrameSpecCustomEnabled()
    local specID = GetEditSpec()
    return specID and IsRaidCustomEnabled(specID) or false
end

local function DefaultRaidScalePercent()
    local fallback = FallbackTable()
    local scale = fallback and tonumber(fallback.raidScale)

    if not scale then
        local _, _, _, raidFrame = GetEllesmereIntegration()
        if raidFrame and raidFrame.GetScale then
            local ok, value = pcall(raidFrame.GetScale, raidFrame)
            if ok then scale = tonumber(value) end
        end
    end

    scale = scale or 1
    local percent = math.floor(((scale * 100) / 5) + 0.5) * 5
    return math.max(50, math.min(125, percent))
end

function BW:SetRaidFrameSpecCustomEnabled(value)
    if not self.db then return end

    EnsureRaidCustomEnabledMigration()

    local specID, specName = GetEditSpec()
    local currentSpecID = GetCurrentSpec()
    if not specID then return end

    local key = PositionKey(specID)
    local enabled = RaidCustomEnabledTable()
    local orientations = RaidOrientationTable()
    local scaleValues = RaidScaleValueTable()
    local legacyScaleEnabled = RaidScaleEnabledTable()

    if value then
        enabled[key] = true
        if orientations[key] ~= "horizontal"
            and orientations[key] ~= "vertical" then

            orientations[key] = NativeRaidOrientationValue()
        end
        if scaleValues[key] == nil then
            scaleValues[key] = DefaultRaidScalePercent()
        end
        legacyScaleEnabled[key] = true
    else
        enabled[key] = nil
        legacyScaleEnabled[key] = nil

        local mover = GetMover("raid")
        if mover then mover:Hide() end
    end

    if specID == currentSpecID
        and self.db.raidFrameSpecEnabled
        and self.db.raidFrameSpecManageRaid ~= false then

        self:ApplyManagedFrameSpecPositions(specID, "raid")
    else
        SetStatus(
            "Raid custom settings for "
            .. tostring(specName)
            .. (value and ": enabled." or ": disabled — using Ellesmere.")
            .. (
                specID ~= currentSpecID
                and " It will apply when you play that spec."
                or ""
            )
        )
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:GetRaidFrameSpecOrientation()
    local specID = GetEditSpec()
    return specID and SavedRaidOrientation(specID) or NativeRaidOrientationValue()
end

function BW:SetRaidFrameSpecOrientation(value)
    if not self.db then return end
    if value ~= "vertical" and value ~= "horizontal" then return end

    local specID, specName = GetEditSpec()
    local currentSpecID = GetCurrentSpec()
    if not specID then return end

    if not IsRaidCustomEnabled(specID) then
        SetStatus(
            "Enable custom Raid settings for "
            .. tostring(specName)
            .. " first."
        )
        return
    end

    local orientations = RaidOrientationTable()
    orientations[PositionKey(specID)] = value

    if self:IsRaidFrameSpecMoverShown() then
        PositionMoverForCurrentSpec("raid")
    end

    if specID == currentSpecID
        and self.db.raidFrameSpecEnabled
        and self.db.raidFrameSpecManageRaid ~= false then

        self:ApplyManagedFrameSpecPositions(
            specID,
            "raid"
        )
    else
        SetStatus(
            "Raid orientation for "
            .. tostring(specName)
            .. ": "
            .. RaidOrientationLabel(value)
            .. (
                specID ~= currentSpecID
                and " — applies when you play that spec."
                or ""
            )
        )
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:GetPartyFrameSpecCustomEnabled()
    local specID = GetEditSpec()
    return specID and IsPartyCustomEnabled(specID) or false
end

local function DefaultPartyOrientationValue()
    local fallback = FallbackTable()
    if fallback and fallback.partyHorizontal ~= nil then
        return fallback.partyHorizontal == true
            and "horizontal"
            or "vertical"
    end

    local _, _, profile = GetEllesmereIntegration()
    if profile then
        return profile.partyHorizontal == true
            and "horizontal"
            or "vertical"
    end

    return "vertical"
end

local function DefaultPartyScalePercent()
    local fallback = FallbackTable()
    local scale = fallback and tonumber(fallback.partyScale)

    if not scale then
        local _, _, _, _, _, partyFrame = GetEllesmereIntegration()
        if partyFrame and partyFrame.GetScale then
            local ok, value = pcall(partyFrame.GetScale, partyFrame)
            if ok then scale = tonumber(value) end
        end
    end

    scale = scale or 1
    local percent = math.floor(((scale * 100) / 5) + 0.5) * 5
    return math.max(50, math.min(125, percent))
end

function BW:SetPartyFrameSpecCustomEnabled(value)
    if not self.db then return end

    EnsurePartyCustomEnabledMigration()

    local specID, specName = GetEditSpec()
    local currentSpecID = GetCurrentSpec()
    if not specID then return end

    local key = PositionKey(specID)
    local enabled = PartyCustomEnabledTable()
    local orientations = PartyOrientationTable()
    local scaleValues = PartyScaleValueTable()
    local legacyScaleEnabled = PartyScaleEnabledTable()

    if value then
        enabled[key] = true

        if orientations[key] ~= "horizontal"
            and orientations[key] ~= "vertical" then

            orientations[key] = DefaultPartyOrientationValue()
        end

        if scaleValues[key] == nil then
            scaleValues[key] = DefaultPartyScalePercent()
        end

        -- Keep this legacy table coherent for users upgrading from builds
        -- where party scale had its own checkbox.
        legacyScaleEnabled[key] = true
    else
        enabled[key] = nil
        legacyScaleEnabled[key] = nil

        local mover = GetMover("party")
        if mover then mover:Hide() end
    end

    if specID == currentSpecID
        and self.db.raidFrameSpecEnabled
        and self.db.raidFrameSpecManageParty ~= false then

        self:ApplyManagedFrameSpecPositions(
            specID,
            "party"
        )
    else
        SetStatus(
            "Party custom settings for "
            .. tostring(specName)
            .. (value and ": enabled." or ": disabled — using Ellesmere.")
            .. (
                specID ~= currentSpecID
                and " It will apply when you play that spec."
                or ""
            )
        )
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:GetPartyFrameSpecOrientation()
    local specID = GetEditSpec()
    if not specID then
        return "vertical"
    end

    local value = SavedPartyOrientation(specID)
    if value == "horizontal" or value == "vertical" then
        return value
    end

    return DefaultPartyOrientationValue()
end

function BW:SetPartyFrameSpecOrientation(value)
    if not self.db then return end

    if value ~= "horizontal"
        and value ~= "vertical" then

        return
    end

    local specID, specName = GetEditSpec()
    local currentSpecID = GetCurrentSpec()
    if not specID then return end

    if not IsPartyCustomEnabled(specID) then
        SetStatus(
            "Enable custom Party settings for "
            .. tostring(specName)
            .. " first."
        )
        return
    end

    local orientations = PartyOrientationTable()
    orientations[PositionKey(specID)] = value

    if self:IsPartyFrameSpecMoverShown() then
        PositionMoverForCurrentSpec("party")
    end

    if specID == currentSpecID
        and self.db.raidFrameSpecEnabled
        and self.db.raidFrameSpecManageParty ~= false then

        self:ApplyManagedFrameSpecPositions(
            specID,
            "party"
        )
    else
        SetStatus(
            "Party orientation for "
            .. tostring(specName)
            .. ": "
            .. PartyOrientationLabel(value)
            .. "."
            .. (
                specID ~= currentSpecID
                and " It will apply when you play that spec."
                or ""
            )
        )
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:GetRaidFrameSpecScaleEnabled()
    return self:GetRaidFrameSpecCustomEnabled()
end

function BW:GetRaidFrameSpecScaleValue()
    local specID = GetEditSpec()
    local values = RaidScaleValueTable()
    local value = specID and values and tonumber(values[PositionKey(specID)])

    return math.max(
        50,
        math.min(125, value or 100)
    )
end

-- Backward-compatible API from builds where Raid scale had its own toggle.
-- The per-spec custom Raid switch owns orientation, scale, and optional saved position.
function BW:SetRaidFrameSpecScaleEnabled(value)
    return self:SetRaidFrameSpecCustomEnabled(value)
end

function BW:SetRaidFrameSpecScaleValue(value)
    if not self.db then return end

    local specID, specName = GetEditSpec()
    local currentSpecID = GetCurrentSpec()
    if not specID then return end

    if not IsRaidCustomEnabled(specID) then
        SetStatus(
            "Enable custom Raid settings for "
            .. tostring(specName)
            .. " first."
        )
        return
    end

    value = math.max(
        50,
        math.min(125, tonumber(value) or 100)
    )

    local values = RaidScaleValueTable()
    values[PositionKey(specID)] = value

    if self:IsRaidFrameSpecMoverShown() then
        PositionMoverForCurrentSpec("raid")
    end

    if specID == currentSpecID
        and self.db.raidFrameSpecEnabled
        and self.db.raidFrameSpecManageRaid ~= false then

        self:ApplyManagedFrameSpecPositions(
            specID,
            "raid"
        )
    else
        SetStatus(
            "Raid scale for "
            .. tostring(specName)
            .. ": "
            .. tostring(Round(value))
            .. "%"
            .. (
                specID ~= currentSpecID
                and " — applies when you play that spec."
                or ""
            )
        )
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:GetPartyFrameSpecScaleEnabled()
    return self:GetPartyFrameSpecCustomEnabled()
end

function BW:GetPartyFrameSpecScaleValue()
    local specID = GetEditSpec()
    local values = PartyScaleValueTable()
    local value = specID and values and tonumber(values[PositionKey(specID)])

    if value == nil and specID and IsPartyCustomEnabled(specID) then
        value = DefaultPartyScalePercent()
    end

    return math.max(
        50,
        math.min(125, value or 100)
    )
end

-- Backward-compatible API from builds where party scale had its own toggle.
-- The single per-spec custom Party switch now owns orientation, scale, and
-- optional saved position together.
function BW:SetPartyFrameSpecScaleEnabled(value)
    return self:SetPartyFrameSpecCustomEnabled(value)
end

function BW:SetPartyFrameSpecScaleValue(value)
    if not self.db then return end

    local specID, specName = GetEditSpec()
    local currentSpecID = GetCurrentSpec()
    if not specID then return end

    if not IsPartyCustomEnabled(specID) then
        SetStatus(
            "Enable custom Party settings for "
            .. tostring(specName)
            .. " first."
        )
        return
    end

    value = math.max(
        50,
        math.min(125, tonumber(value) or 100)
    )

    local values = PartyScaleValueTable()
    values[PositionKey(specID)] = value

    if self:IsPartyFrameSpecMoverShown() then
        PositionMoverForCurrentSpec("party")
    end

    if specID == currentSpecID
        and self.db.raidFrameSpecEnabled
        and self.db.raidFrameSpecManageParty ~= false then

        self:ApplyManagedFrameSpecPositions(
            specID,
            "party"
        )
    else
        SetStatus(
            "Party scale for "
            .. tostring(specName)
            .. ": "
            .. tostring(Round(value))
            .. "%"
            .. (
                specID ~= currentSpecID
                and " — applies when you play that spec."
                or ""
            )
        )
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:ApplyRaidFrameSpecPosition(
    specID,
    manual
)
    local currentSpecID = GetCurrentSpec()
    specID = specID or currentSpecID

    if not specID then
        return false
    end

    local _, specName = GetSpecInfoByID(specID)
    -- Normal spec applies are overlays, not full baseline restores. Each
    -- managed property below restores/applies its own native fallback so a
    -- secure layout rebuild cannot overwrite a saved position in between.
    local defaultsPrepared = false

    local orientationOK, _, orientationMode =
        ApplyRaidOrientation(specID)

    local ok, reason =
        ApplyKind(
            "raid",
            specID,
            manual,
            defaultsPrepared
        )

    local scaleOK, scaleReason, customScale =
        ApplyRaidScale(specID)

    if ok and orientationOK and scaleOK then
        SetStatus(
            "Raid for "
            .. tostring(specName)
            .. " — "
            .. ResultText("raid", ok, reason)
            .. " / "
            .. RaidOrientationLabel(orientationMode)
            .. " / "
            .. (
                customScale
                and string.format("Scale %d%%", customScale)
                or "Ellesmere scale"
            )
            .. "."
        )
    else
        SetStatus(
            "Raid position / orientation / scale unavailable or queued."
        )
    end

    return ok and orientationOK and scaleOK
end

function BW:ApplyPartyFrameSpecPosition(
    specID,
    manual
)
    local currentSpecID = GetCurrentSpec()
    specID = specID or currentSpecID

    if not specID then
        return false
    end

    local _, specName = GetSpecInfoByID(specID)

    if InCombatLockdown
        and InCombatLockdown() then

        self.raidFrameSpecPendingSpecID = specID
        SetStatus(
            "Party position / orientation queued for "
            .. tostring(specName or specID)
            .. " — it will apply when combat ends."
        )
        return false
    end

    -- Do not perform a full Ellesmere baseline restore before changing party
    -- orientation. It causes an extra secure-container rebuild at the native
    -- location and can race the saved Kaylii position.
    local defaultsPrepared = false

    local orientationOK, _, orientationMode =
        ApplyPartyOrientation(
            specID,
            defaultsPrepared
        )

    local ok, reason =
        ApplyKind(
            "party",
            specID,
            manual,
            defaultsPrepared
        )

    local scaleOK, _, customScale =
        ApplyPartyScale(specID)

    -- SetScale changes SetPoint offset distance. Re-apply the visual mover
    -- position after scaling so Party stays on the exact saved screen point.
    if scaleOK then
        local finalOK, finalReason =
            ApplyKind(
                "party",
                specID,
                manual,
                defaultsPrepared
            )

        if not finalOK then
            ok = false
            reason = finalReason
        end
    end

    if specID == currentSpecID then
        SchedulePartyRuntimeReanchor(specID)
    end

    if ok and orientationOK and scaleOK then
        SetStatus(
            "Party / 5-man for "
            .. tostring(specName or specID)
            .. " — "
            .. ResultText("party", ok, reason)
            .. " / "
            .. PartyOrientationLabel(orientationMode)
            .. " / "
            .. (
                customScale
                and string.format("Scale %d%%", customScale)
                or "Ellesmere scale"
            )
            .. "."
        )
    else
        SetStatus(
            "Party position / orientation / scale unavailable or queued."
        )
    end

    return ok and orientationOK and scaleOK
end

function BW:ApplyManagedFrameSpecPositions(
    specID,
    manual
)
    if not self.db then
        return false
    end

    local currentSpecID, currentSpecName =
        GetCurrentSpec()

    specID = specID or currentSpecID

    if not specID then
        return false
    end

    local _, specName =
        GetSpecInfoByID(specID)

    if InCombatLockdown
        and InCombatLockdown() then

        self.raidFrameSpecPendingSpecID = specID

        SetStatus(
            "Raid / party settings queued for "
            .. tostring(specName or specID)
            .. " — they will apply when combat ends."
        )

        return false
    end

    local automatic = not manual
    local doRaid =
        manual == "raid"
        or manual == true
        or (automatic and IsManaged("raid"))

    local doParty =
        manual == "party"
        or manual == true
        or (automatic and IsManaged("party"))

    -- Apply each managed property independently. A full baseline restore here
    -- performs an unnecessary party geometry pass at Ellesmere's native
    -- position before the custom orientation/position pass and can later win
    -- the secure-frame anchor race.
    local defaultsPrepared = false

    local results = {}
    local anyApplied = false

    if doRaid then
        local orientationOK, _, orientationMode =
            ApplyRaidOrientation(specID)

        local ok, reason = ApplyKind(
            "raid",
            specID,
            manual == true or manual == "raid",
            defaultsPrepared
        )

        local scaleOK, scaleReason, customScale =
            ApplyRaidScale(specID)

        local scaleText = customScale
            and string.format("Scale %d%%", customScale)
            or "Ellesmere scale"

        results[#results + 1] =
            ResultText("raid", ok, reason)
            .. " / "
            .. RaidOrientationLabel(orientationMode)
            .. " / "
            .. scaleText

        anyApplied =
            anyApplied
            or (ok and orientationOK and scaleOK)
    end

    if doParty then
        local orientationOK, _, orientationMode =
            ApplyPartyOrientation(
                specID,
                defaultsPrepared
            )

        local ok, reason = ApplyKind(
            "party",
            specID,
            manual == true or manual == "party",
            defaultsPrepared
        )

        local scaleOK, _, customScale =
            ApplyPartyScale(specID)

        -- Scaling changes SetPoint offset distance, so finish with a second
        -- position pass in the target scale's coordinate space.
        if scaleOK then
            local finalOK, finalReason =
                ApplyKind(
                    "party",
                    specID,
                    manual == true or manual == "party",
                    defaultsPrepared
                )

            if not finalOK then
                ok = false
                reason = finalReason
            end
        end

        if specID == currentSpecID then
            SchedulePartyRuntimeReanchor(specID)
        end

        local scaleText = customScale
            and string.format("Scale %d%%", customScale)
            or "Ellesmere scale"

        results[#results + 1] =
            ResultText("party", ok, reason)
            .. " / "
            .. PartyOrientationLabel(orientationMode)
            .. " / "
            .. scaleText

        anyApplied =
            anyApplied
            or (ok and orientationOK and scaleOK)
    end

    self.raidFrameSpecPendingSpecID = nil

    SetStatus(
        tostring(specName or currentSpecName or specID)
        .. " — "
        .. table.concat(results, "  •  ")
    )

    return anyApplied
end

function BW:QueueRaidFrameSpecApply()
    if not self.db or not self.db.raidFrameSpecEnabled then return end

    self.raidFrameSpecApplySerial = (self.raidFrameSpecApplySerial or 0) + 1
    local serial = self.raidFrameSpecApplySerial
    local specID = GetCurrentSpec()
    if not specID then return end

    local function ApplyIfCurrent()
        if serial ~= BW.raidFrameSpecApplySerial then return end
        local currentSpecID = GetCurrentSpec()
        if currentSpecID ~= specID then return end
        BW:ApplyManagedFrameSpecPositions(specID, false)
    end

    C_Timer.After(0.10, ApplyIfCurrent)
    C_Timer.After(0.60, ApplyIfCurrent)
end

function BW:SetRaidFrameSpecEnabled(value)
    if not self.db then return end

    self.db.raidFrameSpecEnabled =
        value and true or false

    if self.db.raidFrameSpecEnabled then
        RepairEllesmereBaselineIfNeeded()
        self:QueueRaidFrameSpecApply()
    else
        self.raidFrameSpecPendingSpecID = nil

        if InCombatLockdown
            and InCombatLockdown() then

            self.raidFrameSpecRestorePending = true
            SetStatus(
                "Raid Frame Spec disabled — Ellesmere layout will restore when combat ends."
            )
        else
            RestoreEllesmereBaseState(
                GetCurrentSpec()
            )
            RefreshEllesmereFrames()

            SetStatus(
                "Raid Frame Spec disabled — restored Ellesmere layout."
            )
        end
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:SetRaidFrameSpecManageRaid(value)
    if not self.db then return end

    self.db.raidFrameSpecManageRaid =
        value and true or false

    if self.db.raidFrameSpecEnabled then
        self:QueueRaidFrameSpecApply()
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

function BW:SetRaidFrameSpecManageParty(value)
    if not self.db then return end

    self.db.raidFrameSpecManageParty =
        value and true or false

    if self.db.raidFrameSpecEnabled then
        self:QueueRaidFrameSpecApply()
    end

    if self.RefreshRaidFrameSpecOptions then
        self:RefreshRaidFrameSpecOptions()
    end
end

local function ReapplyManagedRuntimePosition(kind)
    if BW.raidFrameSpecApplyingRuntimePosition
        or BW.raidFrameSpecApplyingRaidOrientation
        or BW.raidFrameSpecSuppressSpecHook then

        return
    end

    if not BW.db
        or not BW.db.raidFrameSpecEnabled
        or not IsManaged(kind) then

        return
    end

    local specID = GetCurrentSpec()
    if not specID then
        return
    end

    if kind == "party" and not IsLivePartyContext() then
        return
    end

    -- A managed container still needs a runtime anchor when only orientation
    -- or scale is overridden. If there is no Kaylii position for this spec,
    -- use Ellesmere's own live saved position as the runtime anchor. This also
    -- repairs the anchor after Ellesmere rebuilds party geometry.
    local customEnabled
    if kind == "party" then
        customEnabled = IsPartyCustomEnabled(specID)
    else
        customEnabled = IsRaidCustomEnabled(specID)
    end

    if InCombatLockdown
        and InCombatLockdown() then

        BW.raidFrameSpecPendingSpecID = specID
        return
    end

    if kind == "party" then
        -- Ellesmere geometry/layout hooks can run after Kaylii changes scale.
        -- Restore the target scale first, then anchor in the scaled coordinate
        -- space so the hook cannot pull the visual position toward center.
        ApplyPartyScale(specID)
        ApplyKind(
            "party",
            specID,
            true,
            false
        )
        return
    end

    local pos =
        customEnabled
        and SavedPosition(kind, specID)
        or EllesmereDefaultPosition(kind)

    if not pos then
        return
    end

    if customEnabled then
        ApplyRaidOrientation(specID)
    end

    NativeApplyPosition(kind, pos, specID)
    ApplyRaidScale(specID)
end

-- Leaving a party must also remove Kaylii's runtime Party overlay before
-- Ellesmere reuses the same container/frames in solo state. This restores only
-- Ellesmere's own saved Party baseline and never writes its saved position.
local function RestorePartyRuntimeForSolo()
    if IsLivePartyContext() then
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        BW.raidFrameSpecPartySoloRestorePending = true
        return false
    end

    local _, ns, profile, _, _, partyFrame =
        GetEllesmereIntegration()

    if not profile then
        return false
    end

    local fallback = FallbackTable()
    local previousSuppress = BW.raidFrameSpecSuppressSpecHook
    local previousGuard = BW.raidFrameSpecApplyingRuntimePosition
    BW.raidFrameSpecSuppressSpecHook = true
    BW.raidFrameSpecApplyingRuntimePosition = true

    if fallback and fallback.partyHorizontal ~= nil then
        profile.partyHorizontal = fallback.partyHorizontal == true
    end

    if partyFrame then
        local baseScale = fallback and tonumber(fallback.partyScale) or 1
        pcall(
            partyFrame.SetScale,
            partyFrame,
            baseScale and baseScale > 0 and baseScale or 1
        )
    end

    if ns and ns._ApplyPartyContainerGeometry then
        pcall(ns._ApplyPartyContainerGeometry)
    end

    if ns and ns._LayoutPartyFrames then
        pcall(ns._LayoutPartyFrames)
    end

    local partyPos = EllesmereDefaultPosition("party")
    if partyPos then
        NativeApplyPosition("party", partyPos)
    end

    BW.raidFrameSpecApplyingRuntimePosition = previousGuard
    BW.raidFrameSpecSuppressSpecHook = previousSuppress
    BW.raidFrameSpecPartySoloRestorePending = nil
    return true
end

local function InstallEllesmerePositionPostHooks()
    if type(hooksecurefunc) ~= "function" then
        return
    end

    local _, ns = GetEllesmereIntegration()
    if not ns then return end

    if not BW.raidFrameSpecRaidNativeHooked
        and type(ns._ApplyTierOffset) == "function" then

        local ok = pcall(
            hooksecurefunc,
            ns,
            "_ApplyTierOffset",
            function()
                ReapplyManagedRuntimePosition("raid")
            end
        )

        if ok then
            BW.raidFrameSpecRaidNativeHooked = true
        end
    end

    if not BW.raidFrameSpecPartyNativeHooked
        and type(ns._ApplyPartyContainerGeometry) == "function" then

        local ok = pcall(
            hooksecurefunc,
            ns,
            "_ApplyPartyContainerGeometry",
            function()
                ReapplyManagedRuntimePosition("party")
            end
        )

        if ok then
            BW.raidFrameSpecPartyNativeHooked = true
        end
    end

    if not BW.raidFrameSpecPartyLayoutHooked
        and type(ns._LayoutPartyFrames) == "function" then

        local ok = pcall(
            hooksecurefunc,
            ns,
            "_LayoutPartyFrames",
            function()
                ReapplyManagedRuntimePosition("party")
            end
        )

        if ok then
            BW.raidFrameSpecPartyLayoutHooked = true
        end
    end
end

local function InstallSpecOverridePostHook()
    if BW.raidFrameSpecOverrideHooked then return end

    local eui = _G.EllesmereUI
    if not eui or type(eui.SpecOverrides_ApplyUnlock) ~= "function" then return end

    hooksecurefunc(
        eui,
        "SpecOverrides_ApplyUnlock",
        function()
            if BW.raidFrameSpecSuppressSpecHook then
                return
            end

            if BW.db
                and BW.db.raidFrameSpecEnabled then

                local specID =
                    GetCurrentSpec()

                if InCombatLockdown
                    and InCombatLockdown() then

                    BW.raidFrameSpecPendingSpecID =
                        specID
                else
                    C_Timer.After(
                        0,
                        function()
                            BW:QueueRaidFrameSpecApply()
                        end
                    )
                end
            end
        end
    )

    BW.raidFrameSpecOverrideHooked = true
end

function BW:InitializeRaidFrameSpec()
    if self.raidFrameSpecInitialized then return end
    self.raidFrameSpecInitialized = true

    InstallSpecOverridePostHook()
    InstallEllesmerePositionPostHooks()

    local frame = CreateFrame("Frame")
    self.raidFrameSpecEventFrame = frame
    self.raidFrameSpecPartyContextActive = IsLivePartyContext()

    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("ADDON_LOADED")

    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            if arg1 and arg1 ~= "player" then return end

            BW.raidFrameSpecStatus = nil

            BW:QueueRaidFrameSpecApply()

            C_Timer.After(
                0,
                function()
                    BW:SyncRaidFrameSpecMoversToCurrentSpec()
                end
            )

        elseif event == "PLAYER_REGEN_DISABLED" then
            -- No profile writes on combat start. Ellesmere keeps its native
            -- baseline intact; Kaylii only reapplies after lockdown ends.

        elseif event == "PLAYER_REGEN_ENABLED" then
            if BW.raidFrameSpecBaselineRepairPending then
                RepairEllesmereBaselineIfNeeded()
            end

            if BW.raidFrameSpecPartySoloRestorePending
                and not IsLivePartyContext() then

                RestorePartyRuntimeForSolo()
            end

            if BW.raidFrameSpecRestorePending
                and not (BW.db and BW.db.raidFrameSpecEnabled) then

                RestoreEllesmereBaseState(
                    GetCurrentSpec()
                )
                RefreshEllesmereFrames()

                BW.raidFrameSpecRestorePending = nil

            else
                local pending = BW.raidFrameSpecPendingSpecID
                if pending then
                    BW:ApplyManagedFrameSpecPositions(pending, false)
                end
            end

        elseif event == "GROUP_ROSTER_UPDATE" then
            local wasParty = BW.raidFrameSpecPartyContextActive and true or false
            local inParty = IsLivePartyContext()
            BW.raidFrameSpecPartyContextActive = inParty

            if inParty and not wasParty then
                BW.raidFrameSpecPartySoloRestorePending = nil

                if BW.db
                    and BW.db.raidFrameSpecEnabled
                    and IsManaged("party") then

                    local specID = GetCurrentSpec()
                    if specID then
                        C_Timer.After(0.10, function()
                            if IsLivePartyContext()
                                and BW.db
                                and BW.db.raidFrameSpecEnabled
                                and IsManaged("party") then

                                BW:ApplyPartyFrameSpecPosition(specID, true)
                            end
                        end)
                    end
                end

            elseif wasParty and not inParty then
                RestorePartyRuntimeForSolo()
            end

        elseif event == "PLAYER_ENTERING_WORLD" then
            BW.raidFrameSpecStatus = nil

            local wasParty = BW.raidFrameSpecPartyContextActive and true or false
            local inParty = IsLivePartyContext()
            BW.raidFrameSpecPartyContextActive = inParty

            -- Zoning can update group state before GROUP_ROSTER_UPDATE fires.
            -- Detect the transition here too so a custom Party overlay can
            -- never leak into the solo frame after leaving a dungeon/group.
            if wasParty and not inParty then
                C_Timer.After(0, function()
                    if not IsLivePartyContext() then
                        RestorePartyRuntimeForSolo()
                    end
                end)
            end

            C_Timer.After(0.35, function()
                InstallEllesmerePositionPostHooks()
                RepairEllesmereBaselineIfNeeded()
            end)

            if BW.db and BW.db.raidFrameSpecEnabled then
                C_Timer.After(0.75, function() BW:QueueRaidFrameSpecApply() end)
            end

        elseif event == "ADDON_LOADED" and arg1 == "EllesmereUIRaidFrames" then
            BW.raidFrameSpecStatus = nil
            C_Timer.After(0, function()
                EnsureRaidNativeMigration()
                RepairEllesmereBaselineIfNeeded()
                InstallSpecOverridePostHook()
                InstallEllesmerePositionPostHooks()
            end)

            if BW.db and BW.db.raidFrameSpecEnabled then
                C_Timer.After(0.25, function() BW:QueueRaidFrameSpecApply() end)
            end
        end

        if BW.RefreshRaidFrameSpecOptions then BW:RefreshRaidFrameSpecOptions() end
    end)

    C_Timer.After(0.5, function()
        EnsureRaidNativeMigration()
        RepairEllesmereBaselineIfNeeded()
        InstallSpecOverridePostHook()
        InstallEllesmerePositionPostHooks()
    end)

    if self.db and self.db.raidFrameSpecEnabled then
        C_Timer.After(1.0, function() BW:QueueRaidFrameSpecApply() end)
    end
end
