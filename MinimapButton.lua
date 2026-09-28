local ADDON_NAME, BW = ...

local ICON_PATH =
    "Interface\\AddOns\\KayliiHelper\\Media\\KayliiIcon"

local BUTTON_RADIUS = 80

local hiddenHolder

local function GetHiddenHolder()
    if hiddenHolder then
        return hiddenHolder
    end

    hiddenHolder = CreateFrame(
        "Frame",
        "KayliiHelperMinimapHiddenHolder",
        UIParent
    )
    hiddenHolder:SetSize(1, 1)
    hiddenHolder:SetPoint(
        "TOPLEFT",
        UIParent,
        "TOPLEFT",
        -1000,
        1000
    )
    hiddenHolder:Hide()

    return hiddenHolder
end

local function ClampAngle(angle)
    angle = tonumber(angle) or 225

    while angle < 0 do
        angle = angle + 360
    end

    while angle >= 360 do
        angle = angle - 360
    end

    return angle
end

local function ApplyButtonPosition()
    if not BW.minimapButton
        or not BW.db then

        return
    end

    local angle = math.rad(
        ClampAngle(BW.db.minimapButtonAngle)
    )

    local x = math.cos(angle) * BUTTON_RADIUS
    local y = math.sin(angle) * BUTTON_RADIUS

    BW.minimapButton:ClearAllPoints()
    BW.minimapButton:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        x,
        y
    )
end

local function UpdateButtonVisibility()
    if not BW.db then
        return
    end

    local button =
        BW.minimapButton
        or _G.KayliiHelperMinimapButton

    if BW.db.minimapButtonShown == false then
        if button then
            button:Hide()
            button:EnableMouse(false)
            button:SetAlpha(0)

            if button:GetParent() ~= GetHiddenHolder() then
                button:SetParent(
                    GetHiddenHolder()
                )
            end
        end

        return
    end

    if not button then
        return
    end

    if button:GetParent() ~= Minimap then
        button:SetParent(Minimap)
    end

    button:SetAlpha(1)
    button:EnableMouse(true)
    ApplyButtonPosition()
    button:Show()
end

local function UpdateAngleFromCursor()
    if not BW.db then
        return
    end

    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()

    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local centerX, centerY = Minimap:GetCenter()

    if not centerX or not centerY then
        return
    end

    local dx = cursorX - centerX
    local dy = cursorY - centerY

    local angle = math.deg(math.atan2(dy, dx))

    BW.db.minimapButtonAngle = ClampAngle(angle)
    ApplyButtonPosition()
end

local function CreateMinimapButton()
    if BW.minimapButton then
        return BW.minimapButton
    end

    local button = CreateFrame(
        "Button",
        "KayliiHelperMinimapButton",
        Minimap
    )

    button:SetSize(34, 34)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(
        (Minimap:GetFrameLevel() or 0) + 8
    )

    button:RegisterForClicks(
        "LeftButtonUp",
        "RightButtonUp"
    )
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    button:EnableMouse(true)

    local border = button:CreateTexture(
        nil,
        "BACKGROUND"
    )
    border:SetPoint("CENTER", button, "CENTER", 0, 0)
    border:SetSize(36, 36)
    border:SetTexture(
        "Interface\\Minimap\\MiniMap-TrackingBorder"
    )
    button.border = border

    local icon = button:CreateTexture(
        nil,
        "ARTWORK",
        nil,
        7
    )
    icon:SetPoint(
        "TOPLEFT",
        button,
        "TOPLEFT",
        5,
        -5
    )
    icon:SetPoint(
        "BOTTOMRIGHT",
        button,
        "BOTTOMRIGHT",
        -5,
        5
    )
    icon:SetTexture(ICON_PATH)
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetVertexColor(1, 1, 1, 1)
    icon:SetAlpha(1)
    button.icon = icon

    local highlight = button:CreateTexture(
        nil,
        "HIGHLIGHT"
    )
    highlight:SetAllPoints(icon)
    highlight:SetColorTexture(
        0.30,
        0.62,
        1.00,
        0.20
    )
    button.highlight = highlight

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if BW.ToggleHelperWindow then
                BW:ToggleHelperWindow("home")

            elseif BW.OpenHelperWindow then
                BW:OpenHelperWindow("home")
            end

        elseif mouseButton == "RightButton" then
            if BW.OpenHelperWindow then
                BW:OpenHelperWindow("home")
            end
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript(
            "OnUpdate",
            UpdateAngleFromCursor
        )
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateAngleFromCursor()

        if BW.RefreshMinimapButtonOptions then
            BW:RefreshMinimapButtonOptions()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(
            self,
            "ANCHOR_LEFT"
        )
        GameTooltip:AddLine(
            "Kaylii Helper",
            1,
            1,
            1
        )
        GameTooltip:AddLine(
            "Left-click: Open / close",
            0.75,
            0.80,
            0.90
        )
        GameTooltip:AddLine(
            "Drag: Move around minimap",
            0.75,
            0.80,
            0.90
        )
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:HookScript("OnShow", function(self)
        if BW.db
            and BW.db.minimapButtonShown == false then

            self:Hide()
            self:EnableMouse(false)
            self:SetAlpha(0)

            if self:GetParent() ~= GetHiddenHolder() then
                self:SetParent(
                    GetHiddenHolder()
                )
            end
        end
    end)

    BW.minimapButton = button
    return button
end

function BW:RefreshMinimapButton()
    if not self.db then
        return
    end

    if self.db.minimapButtonShown == false then
        UpdateButtonVisibility()
        return
    end

    CreateMinimapButton()
    UpdateButtonVisibility()
end

function BW:ApplyMinimapButtonVisibility()
    if not self.db then
        return
    end

    if self.db.minimapButtonShown ~= false then
        CreateMinimapButton()
    end

    UpdateButtonVisibility()
end

function BW:SetMinimapButtonShown(value)
    if not self.db then
        return
    end

    self.db.minimapButtonShown =
        value and true or false

    self:ApplyMinimapButtonVisibility()

    C_Timer.After(0, function()
        if BW.db
            and BW.ApplyMinimapButtonVisibility then

            BW:ApplyMinimapButtonVisibility()
        end
    end)

    C_Timer.After(0.10, function()
        if BW.db
            and BW.ApplyMinimapButtonVisibility then

            BW:ApplyMinimapButtonVisibility()
        end
    end)

    if self.RefreshMinimapButtonOptions then
        self:RefreshMinimapButtonOptions()
    end
end

function BW:ResetMinimapButtonPosition()
    if not self.db then
        return
    end

    self.db.minimapButtonAngle = 225

    if self.db.minimapButtonShown ~= false then
        self:RefreshMinimapButton()
    else
        UpdateButtonVisibility()
    end

    if self.RefreshMinimapButtonOptions then
        self:RefreshMinimapButtonOptions()
    end
end

function BW:RestoreMinimapButton()
    if not self.db then
        return
    end

    self.db.minimapButtonShown = true
    self.db.minimapButtonAngle = 225

    CreateMinimapButton()
    UpdateButtonVisibility()

    if self.minimapButton and self.minimapButton.icon then
        self.minimapButton.icon:SetTexture(ICON_PATH)
        self.minimapButton.icon:SetVertexColor(1, 1, 1, 1)
        self.minimapButton.icon:SetAlpha(1)
    end

    if self.RefreshMinimapButtonOptions then
        self:RefreshMinimapButtonOptions()
    end
end

function BW:InitializeMinimapButton()
    if not self.db then
        return
    end

    if self.db.minimapButtonShown == false then
        if not self.minimapButton
            and _G.KayliiHelperMinimapButton then

            self.minimapButton =
                _G.KayliiHelperMinimapButton
        end

        UpdateButtonVisibility()
        return
    end

    self:RefreshMinimapButton()
end
