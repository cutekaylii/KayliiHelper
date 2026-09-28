local ADDON_NAME, BW = ...

local UPDATE_INTERVAL = 1.00

local function Clamp(value, low, high)
    value = tonumber(value) or low

    if value < low then
        return low
    elseif value > high then
        return high
    end

    return value
end

local function GetSpecInfo()
    local specIndex = GetSpecialization()

    if not specIndex then
        return nil, nil
    end

    local specID, name =
        GetSpecializationInfo(specIndex)

    return specID, name
end

local function GetConfigInfo(configID)
    if not configID
        or configID < 0
        or not C_Traits
        or not C_Traits.GetConfigInfo then

        return nil
    end

    local ok, configInfo = pcall(
        C_Traits.GetConfigInfo,
        configID
    )

    if not ok then
        return nil
    end

    return configInfo
end

local function GetActiveConfigID()
    if not C_ClassTalents
        or not C_ClassTalents.GetActiveConfigID then

        return nil
    end

    local ok, configID = pcall(
        C_ClassTalents.GetActiveConfigID
    )

    if not ok
        or not configID
        or configID < 0 then

        return nil
    end

    return configID
end

local function GetSelectedLoadoutName(
    specID,
    activeConfigID
)
    if C_ClassTalents
        and C_ClassTalents.GetStarterBuildActive then

        local starterOK, starterActive = pcall(
            C_ClassTalents.GetStarterBuildActive
        )

        if starterOK and starterActive then
            return "Starter Build", activeConfigID
        end
    end

    if specID
        and C_ClassTalents
        and C_ClassTalents.GetLastSelectedSavedConfigID then

        local savedOK, savedConfigID = pcall(
            C_ClassTalents.GetLastSelectedSavedConfigID,
            specID
        )

        if savedOK
            and savedConfigID
            and savedConfigID >= 0 then

            local savedInfo =
                GetConfigInfo(savedConfigID)

            if savedInfo
                and savedInfo.name
                and savedInfo.name ~= "" then

                return savedInfo.name, savedConfigID
            end
        end
    end

    -- Fallback for clients/states where the last-saved ID is not available.
    local activeInfo =
        GetConfigInfo(activeConfigID)

    if activeInfo
        and activeInfo.name
        and activeInfo.name ~= "" then

        return activeInfo.name, activeConfigID
    end

    return nil, activeConfigID
end

local function GetHeroTalentName(configID)
    if not configID
        or not C_ClassTalents
        or not C_ClassTalents.GetActiveHeroTalentSpec
        or not C_Traits
        or not C_Traits.GetSubTreeInfo then

        return nil
    end

    local heroOK, heroSpecID = pcall(
        C_ClassTalents.GetActiveHeroTalentSpec
    )

    if not heroOK or not heroSpecID then
        return nil
    end

    local infoOK, subTreeInfo = pcall(
        C_Traits.GetSubTreeInfo,
        configID,
        heroSpecID
    )

    if infoOK
        and subTreeInfo
        and subTreeInfo.name
        and subTreeInfo.name ~= "" then

        return subTreeInfo.name
    end

    return nil
end

function BW:GetTalentLoadoutData()
    local specID, specName = GetSpecInfo()
    local activeConfigID = GetActiveConfigID()

    local loadoutName, loadoutConfigID =
        GetSelectedLoadoutName(
            specID,
            activeConfigID
        )

    return {
        spec = specName,
        specID = specID,
        loadout = loadoutName,
        hero = GetHeroTalentName(
            activeConfigID or loadoutConfigID
        ),
        configID =
            activeConfigID
            or loadoutConfigID,
    }
end

function BW:GetTalentLoadoutDisplayText()
    if not self.db then
        return ""
    end

    local data = self:GetTalentLoadoutData()
    local parts = {}

    if self.db.talentLoadoutShowName then
        parts[#parts + 1] =
            data.loadout
            and ("Loadout: " .. data.loadout)
            or "Loadout: Unnamed / unavailable"
    end

    if self.db.talentLoadoutShowSpec then
        parts[#parts + 1] =
            data.spec
            and ("Spec: " .. data.spec)
            or "Spec: --"
    end

    if self.db.talentLoadoutShowHero then
        parts[#parts + 1] =
            data.hero
            and ("Hero: " .. data.hero)
            or "Hero: --"
    end

    if #parts == 0 then
        return "No talent details selected"
    end

    local separator =
        self.db.talentLoadoutOrientation == "horizontal"
        and "   •   "
        or "\n"

    return table.concat(parts, separator)
end

local function CreateTalentFrame()
    if BW.talentLoadoutFrame then
        return BW.talentLoadoutFrame
    end

    local frame = CreateFrame(
        "Frame",
        "KayliiHelperTalentLoadoutDisplay",
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
    frame:SetSize(280, 60)

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
    text:SetPoint("LEFT", frame, "LEFT", 11, 0)
    text:SetPoint("RIGHT", frame, "RIGHT", -11, 0)
    text:SetJustifyH("LEFT")
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
            and BW.db.talentLoadoutEnabled
            and BW.db.talentLoadoutUnlocked then

            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        if not BW.db then
            return
        end

        local left = self:GetLeft()
        local top = self:GetTop()
        local ux, uy = UIParent:GetCenter()

        if left and top and ux and uy then
            BW.db.talentLoadoutPoint = "TOPLEFT"
            BW.db.talentLoadoutX =
                math.floor((left - ux) + 0.5)
            BW.db.talentLoadoutY =
                math.floor((top - uy) + 0.5)
        end

        if BW.RefreshTalentLoadoutOptions then
            BW:RefreshTalentLoadoutOptions()
        end
    end)

    BW.talentLoadoutFrame = frame
    return frame
end

local function ApplyTalentPosition()
    local frame = CreateTalentFrame()
    local point =
        BW.db.talentLoadoutPoint or "CENTER"
    local x =
        tonumber(BW.db.talentLoadoutX) or 260
    local y =
        tonumber(BW.db.talentLoadoutY) or -220

    frame:ClearAllPoints()

    if point == "TOPLEFT" then
        frame:SetPoint(
            "TOPLEFT",
            UIParent,
            "CENTER",
            x,
            y
        )
    else
        -- Legacy center anchor. UpdateTalentLoadoutDisplay migrates this to
        -- TOPLEFT after it knows the final text-dependent frame dimensions.
        frame:SetPoint(
            point,
            UIParent,
            point,
            x,
            y
        )
    end
end

function BW:UpdateTalentLoadoutDisplay()
    if not self.db then
        return
    end

    local frame = CreateTalentFrame()

    if not self.db.talentLoadoutEnabled then
        frame:Hide()
        return
    end

    local fontSize = Clamp(
        self.db.talentLoadoutFontSize,
        10,
        28
    )

    frame.text:SetFont(
        STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        fontSize,
        "OUTLINE"
    )

    frame.text:SetText(
        self:GetTalentLoadoutDisplayText()
    )

    frame.text:SetTextColor(1, 1, 1, 1)

    local width = math.max(
        120,
        math.ceil(frame.text:GetStringWidth() + 22)
    )

    local height = math.max(
        38,
        math.ceil(frame.text:GetStringHeight() + 20)
    )

    frame:SetSize(width, height)

    if self.db.talentLoadoutPoint ~= "TOPLEFT" then
        local left = frame:GetLeft()
        local top = frame:GetTop()
        local ux, uy = UIParent:GetCenter()

        if left and top and ux and uy then
            self.db.talentLoadoutPoint = "TOPLEFT"
            self.db.talentLoadoutX =
                math.floor((left - ux) + 0.5)
            self.db.talentLoadoutY =
                math.floor((top - uy) + 0.5)

            frame:ClearAllPoints()
            frame:SetPoint(
                "TOPLEFT",
                UIParent,
                "CENTER",
                self.db.talentLoadoutX,
                self.db.talentLoadoutY
            )
        end
    end

    if self.db.talentLoadoutShowBackground then
        frame:SetBackdropColor(0.035, 0.055, 0.09, 0.88)
        frame:SetBackdropBorderColor(0.30, 0.62, 1.00, 0.95)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end

    frame:EnableMouse(
        self.db.talentLoadoutUnlocked and true or false
    )

    frame.moveText:SetShown(
        self.db.talentLoadoutUnlocked and true or false
    )

    frame:Show()
end

function BW:StartTalentLoadoutTicker()
    if self.talentLoadoutTicker then
        return
    end

    self.talentLoadoutTicker = C_Timer.NewTicker(
        UPDATE_INTERVAL,
        function()
            BW:UpdateTalentLoadoutDisplay()
        end
    )
end

function BW:StopTalentLoadoutTicker()
    if self.talentLoadoutTicker then
        self.talentLoadoutTicker:Cancel()
        self.talentLoadoutTicker = nil
    end
end

function BW:ApplyTalentLoadoutSettings()
    if not self.db then
        return
    end

    local frame = CreateTalentFrame()

    ApplyTalentPosition()

    if self.db.talentLoadoutEnabled then
        self:StartTalentLoadoutTicker()
        self:UpdateTalentLoadoutDisplay()
    else
        self:StopTalentLoadoutTicker()
        frame:Hide()
    end
end

function BW:SetTalentLoadoutEnabled(value)
    if not self.db then
        return
    end

    self.db.talentLoadoutEnabled = value and true or false
    self:ApplyTalentLoadoutSettings()

    if self.RefreshTalentLoadoutOptions then
        self:RefreshTalentLoadoutOptions()
    end
end

function BW:SetTalentLoadoutUnlocked(value)
    if not self.db then
        return
    end

    self.db.talentLoadoutUnlocked = value and true or false
    self:UpdateTalentLoadoutDisplay()
end

function BW:ResetTalentLoadoutPosition()
    if not self.db then
        return
    end

    self.db.talentLoadoutPoint = "CENTER"
    self.db.talentLoadoutX = 260
    self.db.talentLoadoutY = -220

    -- UpdateTalentLoadoutDisplay preserves this historical reset location,
    -- then migrates it to the stable TOPLEFT anchor.
    ApplyTalentPosition()
    self:UpdateTalentLoadoutDisplay()
end

local function EnsureTalentEvents()
    if BW.talentLoadoutEventFrame then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

    frame:SetScript("OnEvent", function()
        C_Timer.After(0, function()
            BW:UpdateTalentLoadoutDisplay()

            if BW.RefreshTalentLoadoutOptions then
                BW:RefreshTalentLoadoutOptions()
            end
        end)

        C_Timer.After(0.50, function()
            BW:UpdateTalentLoadoutDisplay()

            if BW.RefreshTalentLoadoutOptions then
                BW:RefreshTalentLoadoutOptions()
            end
        end)
    end)

    BW.talentLoadoutEventFrame = frame
end

function BW:InitializeTalentLoadout()
    EnsureTalentEvents()
    CreateTalentFrame()
    self:ApplyTalentLoadoutSettings()
end
