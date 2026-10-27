local ADDON_NAME, BW = ...

local ROOT_PANEL_NAME = "Kaylii Helper"
local BUFF_PANEL_NAME = "Buff White List"
local LUST_PANEL_NAME = "Lust Up"
local STATS_PANEL_NAME = "My Stats"
local SURVIVAL_PANEL_NAME = "Survival Helper"
local TALENT_PANEL_NAME = "Talent Loadout"
local RAID_SPEC_PANEL_NAME = "Raid Frame Spec"
local ROW_HEIGHT = 44

local helperWindow
local helperContent
local helperHomeButton
local helperBuffButton
local helperLustButton
local helperSidebar
local helperView = "home"

-- UI references for optional/new modules live in one table so the
-- Options.lua main chunk stays well below Lua's 200-local limit.
local moduleUI = {}

local settingsRootPanel
local settingsBuffPanel
local settingsLustPanel
local rootPanel
local panel
local lustPanel
local layoutPage
local auraPage
local textPage
local lustPage
local layoutTab
local auraTab
local textTab

local auraScroll
local scrollChild
local rows = {}
local auraListMode = "target"
local auraEditMode = "filter"
local targetAuras = {}

local focusCheck
local onlyMyBuffsCheck
local onlyMyDebuffsCheck
local useBuffFilterCheck
local useDebuffFilterCheck
local buffMinePlusWhitelistCheck
local debuffMinePlusWhitelistCheck
local buffSortButton
local debuffSortButton
local hideBuffTooltipsCheck
local hideDebuffTooltipsCheck

local showBuffDurationCheck
local buffDurationSizeBox
local buffDurationFontButton
local buffDurationColorButton
local buffDurationOutlineButton
local hideBuffLongDurationTextCheck
local buffLongDurationTextMinutesBox

local showBuffStacksCheck
local buffStackSizeBox
local buffStackFontButton
local buffStackColorButton
local buffStackOutlineButton

local showDebuffDurationCheck
local debuffDurationSizeBox
local debuffDurationFontButton
local debuffDurationColorButton
local debuffDurationOutlineButton
local hideDebuffLongDurationTextCheck
local debuffLongDurationTextMinutesBox

local showDebuffStacksCheck
local debuffStackSizeBox
local debuffStackFontButton
local debuffStackColorButton
local debuffStackOutlineButton

local hidePermanentBuffsCheck
local hidePermanentDebuffsCheck
local showImportantBossBuffsCheck
local showDebuffRedBorderCheck

local iconSizeSlider
local previewCheck

local lustUpEnabledCheck
local lustUpVoiceCheck
local lustUpBossPullVoiceCheck
local lustUpReadyVoiceBox
local lustUpBossPullVoiceBox
local lustUpOnlyInCombatCheck
local lustUpOnlyInInstanceCheck
local lustUpUnlockCheck
local lustUpModeButton
local lustUpSizeSlider
local lustUpCustomBox

local rootBuffEnabledCheck
local rootLustEnabledCheck
local buffPageEnabledCheck
local lustPageEnabledCheck
local buffXSlider
local buffYSlider
local debuffXSlider
local debuffYSlider

local buffColumnsBox
local buffRowsBox
local debuffColumnsBox
local debuffRowsBox

local targetText
local statusText
local targetAuraTab
local savedAuraTab
local editFilterButton
local editBlacklistButton
local listEditHelp
local addBox
local addBuffButton
local addDebuffButton

local mainView = "layout"

local function Label(parent, text, template)
    local fs = parent:CreateFontString(
        nil,
        "ARTWORK",
        template or "GameFontNormal"
    )

    fs:SetText(text)
    return fs
end


local THEME = {
    -- Lift the surfaces out of near-black while keeping Kaylii's navy/blue look.
    accent = { 0.03, 0.42, 1.00, 1 },
    accentHover = { 0.20, 0.59, 1.00, 1 },
    text = { 0.95, 0.97, 1.00, 1 },
    subtext = { 0.69, 0.78, 0.90, 1 },
    muted = { 0.47, 0.59, 0.73, 1 },
    panel = { 0.055, 0.105, 0.16, 1 },
    panelAlt = { 0.045, 0.09, 0.14, 1 },
    section = { 0.065, 0.12, 0.18, 1 },
    button = { 0.075, 0.135, 0.20, 1 },
    buttonHover = { 0.025, 0.34, 0.76, 1 },
    buttonActive = { 0.0, 0.40, 0.96, 1 },
    border = { 0.18, 0.27, 0.37, 1 },
    borderAccent = { 0.03, 0.39, 0.88, 1 },
}

local THEME_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

THEME.flatSectionBackdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

THEME.flatControlBackdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function SetFontColor(fs, color)
    if fs and color then
        fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
end

local function ApplyBackdrop(frame, bg, border, backdrop)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(backdrop or THEME_BACKDROP)
    bg = bg or THEME.section
    border = border or THEME.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function SetButtonFontColor(button, color)
    if not button or not button.GetFontString then return end
    local fs = button:GetFontString()
    if fs then fs:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
end

local function HideBlizzardButtonArtwork(button)
    local keep = {}

    if button.Swatch then
        keep[button.Swatch] = true
    end

    local known = {
        "Left", "Middle", "Right",
        "LeftDisabled", "MiddleDisabled", "RightDisabled",
        "Center", "Background", "Bg", "Border",
    }

    for _, key in ipairs(known) do
        local region = button[key]
        if region and region.Hide and not keep[region] then
            region:Hide()
        end
    end

    local regions = { button:GetRegions() }
    for _, region in ipairs(regions) do
        if region
            and region.GetObjectType
            and region:GetObjectType() == "Texture"
            and not keep[region] then

            region:SetAlpha(0)
        end
    end
end

local function SetButtonBorderColor(button, color)
    if not button or not button._khBorders then
        return
    end
    for _, edge in ipairs(button._khBorders) do
        edge:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end
end

local function ApplyButtonVisual(button, state)
    if not button or not button._khBg then
        return
    end

    local bg
    local border
    local textColor = THEME.text

    if state == "active" then
        bg = THEME.buttonActive
        border = THEME.accent
        textColor = THEME.text
    elseif state == "hover" then
        bg = THEME.buttonHover
        border = THEME.accentHover
        textColor = THEME.text
    elseif state == "disabled" then
        bg = { 0.055, 0.07, 0.10, 1 }
        border = THEME.border
        textColor = THEME.muted
    else
        bg = THEME.button
        border = THEME.border
    end

    if button._khNavStyle then
        if state == "active" then
            border = { THEME.accent[1], THEME.accent[2], THEME.accent[3], 0 }
        elseif state == "hover" then
            bg = { 0.12, 0.20, 0.30, 1 }
            border = { THEME.border[1], THEME.border[2], THEME.border[3], 0 }
        else
            bg = { 0, 0, 0, 0 }
            border = { THEME.border[1], THEME.border[2], THEME.border[3], 0 }
            if state == "normal" then textColor = THEME.subtext end
        end
    end

    button._khBg:SetVertexColor(bg[1], bg[2], bg[3], bg[4] or 1)
    SetButtonBorderColor(button, border)
    SetButtonFontColor(button, textColor)
end

local function SkinButton(button)
    if not button
        or button._khStyled
        or button._khNoSkin
        or button:GetObjectType() ~= "Button" then
        return
    end

    local w = button.GetWidth and button:GetWidth() or 0
    local h = button.GetHeight and button:GetHeight() or 0

    -- Keep tiny close/scroll/resize controls using Blizzard art.
    if w <= 26 and h <= 26 then
        return
    end

    HideBlizzardButtonArtwork(button)
    if button.SetNormalFontObject and GameFontHighlight then
        button:SetNormalFontObject(GameFontHighlight)
    end
    if button.SetHighlightFontObject and GameFontHighlight then
        button:SetHighlightFontObject(GameFontHighlight)
    end
    if button.SetDisabledFontObject and GameFontHighlight then
        button:SetDisabledFontObject(GameFontHighlight)
    end

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(1, 1, 1, 1)
    if bg.SetSnapToPixelGrid then bg:SetSnapToPixelGrid(true) end
    if bg.SetTexelSnappingBias then bg:SetTexelSnappingBias(0) end
    button._khBg = bg

    local top = button:CreateTexture(nil, "BORDER")
    top:SetColorTexture(1, 1, 1, 1)
    top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    local bottom = button:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(1, 1, 1, 1)
    bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    local left = button:CreateTexture(nil, "BORDER")
    left:SetColorTexture(1, 1, 1, 1)
    left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    local right = button:CreateTexture(nil, "BORDER")
    right:SetColorTexture(1, 1, 1, 1)
    right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    button._khBorders = { top, bottom, left, right }
    for _, edge in ipairs(button._khBorders) do
        if edge.SetSnapToPixelGrid then edge:SetSnapToPixelGrid(true) end
        if edge.SetTexelSnappingBias then edge:SetTexelSnappingBias(0) end
    end
    button._khStyled = true

    ApplyButtonVisual(
        button,
        button:IsEnabled() and "normal" or "disabled"
    )

    button:HookScript("OnEnter", function(self)
        if self:IsEnabled() and not self._khActive then
            ApplyButtonVisual(self, "hover")
        end
    end)

    button:HookScript("OnLeave", function(self)
        if self._khActive then
            ApplyButtonVisual(self, "active")
        elseif self:IsEnabled() then
            ApplyButtonVisual(self, "normal")
        else
            ApplyButtonVisual(self, "disabled")
        end
    end)

    button:HookScript("OnEnable", function(self)
        ApplyButtonVisual(
            self,
            self._khActive and "active" or "normal"
        )
    end)

    button:HookScript("OnDisable", function(self)
        ApplyButtonVisual(
            self,
            self._khActive and "active" or "disabled"
        )
    end)
end

local function SetButtonActiveState(button, active)
    if not button then
        return
    end

    if not button._khStyled then
        SkinButton(button)
    end

    button._khActive = active and true or false

    if button._khStyled then
        if active then
            ApplyButtonVisual(button, "active")
        elseif button:IsEnabled() then
            ApplyButtonVisual(button, "normal")
        else
            ApplyButtonVisual(button, "disabled")
        end
    end
end

local function SkinCheckbox(check, label, compact)
    if not check or check._khStyled then
        return
    end

    check:SetSize(compact and 22 or 38, compact and 22 or 20)

    local regions = { check:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType
            and region:GetObjectType() == "Texture" then

            region:SetTexture(nil)
            region:SetAlpha(0)
            region:Hide()
        end
    end

    check:SetNormalTexture("")
    check:SetPushedTexture("")
    check:SetHighlightTexture("")
    check:SetDisabledTexture("")

    local track
    local thumb
    local hover
    if compact then
        track = CreateFrame("Frame", nil, check, "BackdropTemplate")
        track:SetAllPoints(check)
        track:SetFrameLevel(check:GetFrameLevel())
        ApplyBackdrop(track, THEME.panelAlt, THEME.border)
        thumb = track:CreateTexture(nil, "OVERLAY")
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 4, -4)
        thumb:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -4, 4)
        thumb:SetColorTexture(THEME.accent[1], THEME.accent[2], THEME.accent[3], 0.95)
    else
        track = check:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints(check)
        track:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
        track:SetVertexColor(0.14, 0.20, 0.29, 1)
        thumb = check:CreateTexture(nil, "ARTWORK")
        thumb:SetSize(16, 16)
        thumb:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchKnob.tga")
    end
    hover = check:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(check)
    if compact then
        hover:SetColorTexture(THEME.accentHover[1], THEME.accentHover[2], THEME.accentHover[3], 0.10)
    else
        hover:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
        hover:SetVertexColor(THEME.accentHover[1], THEME.accentHover[2], THEME.accentHover[3], 0.12)
    end

    local function UpdateCheckboxVisual(self)
        local enabled = self.IsEnabled and self:IsEnabled()
        local checked = self:GetChecked()

        if compact then
            if checked then
                thumb:Show()
                track:SetBackdropBorderColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)
            else
                thumb:Hide()
                track:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4])
            end
        else
            if checked then track:SetVertexColor(0.0, 0.43, 1.0, 1)
            else track:SetVertexColor(0.14, 0.20, 0.29, 1) end
            thumb:ClearAllPoints()
            if checked then thumb:SetPoint("RIGHT", check, "RIGHT", -2, 0)
            else thumb:SetPoint("LEFT", check, "LEFT", 2, 0) end
        end

        if not enabled then
            track:SetAlpha(0.45)
            thumb:SetAlpha(0.45)
            if label then
                SetFontColor(label, THEME.muted)
            end
        else
            track:SetAlpha(1)
            thumb:SetAlpha(1)
            if label then
                SetFontColor(label, THEME.text)
            end
        end
    end

    if label then
        SetFontColor(label, THEME.text)
    end

    check:HookScript("OnClick", UpdateCheckboxVisual)
    check:HookScript("OnShow", UpdateCheckboxVisual)
    check:HookScript("OnEnable", UpdateCheckboxVisual)
    check:HookScript("OnDisable", UpdateCheckboxVisual)

    check:HookScript("OnEnter", function() hover:Show() end)
    check:HookScript("OnLeave", function(self) hover:Hide(); UpdateCheckboxVisual(self) end)

    check._khStyled = true
    check._khBox = track
    check._khFill = thumb
    check._khUpdateVisual = UpdateCheckboxVisual

    -- Blizzard's SetChecked() does not fire OnClick. Most of this options UI
    -- refreshes controls programmatically, so keep the custom visual in sync
    -- whenever code changes the checked state.
    local OriginalSetChecked = check.SetChecked

    check.SetChecked = function(self, value)
        OriginalSetChecked(self, value)
        UpdateCheckboxVisual(self)
    end

    UpdateCheckboxVisual(check)
end

local function SkinEditBox(box)
    if not box or box._khStyled then return end
    local boxTextures = {}
    for _, region in ipairs({ box:GetRegions() }) do
        if region and region.GetObjectType
            and region:GetObjectType() == "Texture" then
            region:Hide()
            table.insert(boxTextures, region)
        end
    end

    if box.SetBackdrop then
        ApplyBackdrop(
            box,
            { 0.07, 0.12, 0.18, 1 },
            THEME.border,
            THEME.flatControlBackdrop
        )
        -- SetBackdrop reuses BackdropTemplate regions, so show the freshly
        -- skinned background and border after removing the Blizzard artwork.
        for _, region in ipairs(boxTextures) do
            region:Show()
        end
    else
        local parent = box:GetParent()
        if parent then
            local back = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            back:SetAllPoints(box)
            back:EnableMouse(false)
            back:SetFrameStrata(box:GetFrameStrata())
            back:SetFrameLevel(math.max(parent:GetFrameLevel(), box:GetFrameLevel() - 1))
            ApplyBackdrop(back, { 0.07, 0.12, 0.18, 1 }, THEME.border)
            box:SetFrameLevel(back:GetFrameLevel() + 1)
            box._khSkinBackdrop = back
        end
    end
    box:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    if box.DisplayText then SetFontColor(box.DisplayText, THEME.text) end
    box._khStyled = true
end

local function SkinSlider(slider)
    if not slider or slider._khStyled then
        return
    end

    if slider.Text then
        SetFontColor(slider.Text, THEME.text)
    end
    if slider.Low then
        SetFontColor(slider.Low, THEME.muted)
    end
    if slider.High then
        SetFontColor(slider.High, THEME.muted)
    end
    if slider.ValueBox then
        SkinEditBox(slider.ValueBox)
    end

    -- OptionsSliderTemplate adds a NineSlice child frame. Its silver edge is
    -- not returned by slider:GetRegions(), so hide it separately.
    local nineSlice = slider.NineSlice
    if nineSlice then
        nineSlice:SetAlpha(0)
        nineSlice:Hide()
    end

    local regions = { slider:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType
            and region:GetObjectType() == "Texture" then

            region:SetTexture(nil)
            region:SetAlpha(0)
            region:Hide()
        end
    end

    -- Draw the custom rail directly on the slider. A lower-level child frame
    -- can leave the OptionsSliderTemplate's beveled rail visible above it.
    local trackLeft = slider:CreateTexture(nil, "BACKGROUND")
    trackLeft:SetSize(4, 8)
    trackLeft:SetPoint("LEFT", slider, "LEFT", 8, 0)
    trackLeft:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
    trackLeft:SetTexCoord(0, 0.25, 0, 1)
    trackLeft:SetVertexColor(0.18, 0.27, 0.38, 1)

    local trackRight = slider:CreateTexture(nil, "BACKGROUND")
    trackRight:SetSize(4, 8)
    trackRight:SetPoint("RIGHT", slider, "RIGHT", -8, 0)
    trackRight:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
    trackRight:SetTexCoord(0.75, 1, 0, 1)
    trackRight:SetVertexColor(0.18, 0.27, 0.38, 1)

    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("LEFT", trackLeft, "RIGHT", 0, 0)
    trackBg:SetPoint("RIGHT", trackRight, "LEFT", 0, 0)
    trackBg:SetHeight(8)
    trackBg:SetColorTexture(0.18, 0.27, 0.38, 1)

    local fillLeft = slider:CreateTexture(nil, "BACKGROUND")
    fillLeft:SetSize(4, 8)
    fillLeft:SetPoint("LEFT", trackLeft, "LEFT", 0, 0)
    fillLeft:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
    fillLeft:SetTexCoord(0, 0.25, 0, 1)
    fillLeft:SetVertexColor(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        1
    )

    local fill = slider:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("LEFT", fillLeft, "RIGHT", 0, 0)
    fill:SetWidth(0)
    fill:SetHeight(8)
    fill:SetColorTexture(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        1
    )

    local fillRight = slider:CreateTexture(nil, "BACKGROUND")
    fillRight:SetSize(4, 8)
    fillRight:SetPoint("LEFT", fill, "RIGHT", 0, 0)
    fillRight:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
    fillRight:SetTexCoord(0.75, 1, 0, 1)
    fillRight:SetVertexColor(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        1
    )
    fillLeft:Hide()
    fillRight:Hide()

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SliderThumb.tga")
        thumb:SetSize(20, 20)
        thumb:SetVertexColor(1, 1, 1, 1)
        thumb:Show()
    end

    local function UpdateSliderVisual(self, value)
        local minValue, maxValue = self:GetMinMaxValues()
        value = tonumber(value) or tonumber(self:GetValue()) or minValue or 0

        if not minValue or not maxValue or maxValue <= minValue then
            fill:SetWidth(0)
            fillLeft:Hide()
            fillRight:Hide()
            return
        end

        local ratio = (value - minValue) / (maxValue - minValue)
        if ratio < 0 then
            ratio = 0
        elseif ratio > 1 then
            ratio = 1
        end

        local usableWidth = math.max(0, (self:GetWidth() or 0) - 16)
        local fillWidth = math.floor((usableWidth * ratio) + 0.5)
        if fillWidth < 8 and ratio > 0 then
            fillWidth = 8
        end

        fill:SetWidth(math.max(0, fillWidth - 8))
        fillLeft:SetShown(fillWidth > 0)
        fillRight:SetShown(fillWidth > 0)
    end

    slider:HookScript("OnValueChanged", UpdateSliderVisual)
    slider:HookScript("OnShow", function(self)
        C_Timer.After(0, function()
            if self and self:IsShown() then
                UpdateSliderVisual(self)
            end
        end)
    end)
    slider:HookScript("OnSizeChanged", UpdateSliderVisual)
    slider:HookScript("OnEnable", function()
        trackLeft:SetAlpha(1)
        trackBg:SetAlpha(1)
        trackRight:SetAlpha(1)
        fillLeft:SetAlpha(1)
        fill:SetAlpha(1)
        fillRight:SetAlpha(1)
    end)
    slider:HookScript("OnDisable", function()
        trackLeft:SetAlpha(0.45)
        trackBg:SetAlpha(0.45)
        trackRight:SetAlpha(0.45)
        fillLeft:SetAlpha(0.45)
        fill:SetAlpha(0.45)
        fillRight:SetAlpha(0.45)
    end)

    slider._khStyled = true
    slider._khTrack = trackBg
    slider._khTrackBackground = trackBg
    slider._khFill = fill
    slider._khUpdateVisual = UpdateSliderVisual

    UpdateSliderVisual(slider)
end

-- Restyle only the visible scrollbar textures; keep the template's range,
-- hit areas, and placement unchanged.
moduleUI.SkinScrollFrame = function(scrollFrame)
    if not scrollFrame or scrollFrame._khScrollStyled then return end
    local bar = scrollFrame.ScrollBar
    if not bar or not bar.GetThumbTexture then return end

    local thumb = bar:GetThumbTexture()
    local regions = { bar:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region ~= thumb and region.GetObjectType
            and region:GetObjectType() == "Texture" then
            region:Hide()
        end
    end

    local rail = bar:CreateTexture(nil, "BACKGROUND")
    rail:SetPoint("TOP", bar, "TOP", 0, -14)
    rail:SetPoint("BOTTOM", bar, "BOTTOM", 0, 14)
    rail:SetWidth(6)
    rail:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
    rail:SetVertexColor(0.12, 0.19, 0.28, 1)

    if thumb then
        thumb:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\SwitchTrack.tga")
        thumb:SetVertexColor(0.30, 0.48, 0.68, 1)
    end

    local function HideButtonArtwork(frame)
        if not frame then return end
        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.GetObjectType
                and region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            HideButtonArtwork(child)
        end
    end

    local function SkinArrow(button, texturePath)
        if not button then return end
        button:SetNormalTexture("")
        button:SetPushedTexture("")
        button:SetDisabledTexture("")
        button:SetHighlightTexture("")
        HideButtonArtwork(button)
        local arrow = button:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(12, 12)
        arrow:SetPoint("CENTER", button, "CENTER", 0, 0)
        arrow:SetTexture(texturePath)
        arrow:SetVertexColor(0.70, 0.82, 0.96, 1)
        button._khScrollArrow = arrow
    end

    local upButton = bar.ScrollUpButton or scrollFrame.ScrollUpButton
    local downButton = bar.ScrollDownButton or scrollFrame.ScrollDownButton
    local candidates, seenButtons = {}, {}
    local function FindArrowButtons(frame)
        if not frame or not frame.GetChildren then return end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child.GetObjectType then
                local objectType = child:GetObjectType()
                if (objectType == "Button" or objectType == "CheckButton")
                    and not seenButtons[child] then
                    seenButtons[child] = true
                    table.insert(candidates, child)
                end
            end
            FindArrowButtons(child)
        end
    end
    FindArrowButtons(bar)
    table.sort(candidates, function(a, b)
        return (a:GetTop() or 0) > (b:GetTop() or 0)
    end)
    upButton = upButton or candidates[1]
    downButton = downButton or candidates[#candidates]
    if upButton == downButton then downButton = nil end
    SkinArrow(upButton, "Interface\\AddOns\\KayliiHelper\\Media\\ScrollArrowUp.tga")
    SkinArrow(downButton, "Interface\\AddOns\\KayliiHelper\\Media\\ScrollArrowDown.tga")

    scrollFrame._khScrollStyled = true
    scrollFrame._khScrollRail = rail
end

local function CreateFlatPanel(parent, x, y, width, height)
    local frame = CreateFrame(
        "Frame",
        nil,
        parent,
        "BackdropTemplate"
    )

    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    frame:EnableMouse(false)
    frame:SetFrameLevel(parent:GetFrameLevel())
    ApplyBackdrop(frame, THEME.section, THEME.border)

    return frame
end

local function CreateSection(parent, x, y, width, height, titleText, subtitleText)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    ApplyBackdrop(frame, THEME.section, THEME.border, THEME.flatSectionBackdrop)
    local title = Label(frame, titleText or "", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    SetFontColor(title, THEME.text)
    frame.Title = title
    if subtitleText and subtitleText ~= "" then
        local subtitle = Label(frame, subtitleText, "GameFontHighlightSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        subtitle:SetWidth(width - 32)
        subtitle:SetJustifyH("LEFT")
        SetFontColor(subtitle, THEME.subtext)
        frame.Subtitle = subtitle
    end
    return frame
end

local function StyleRows()
    for index, row in ipairs(rows) do
        if not row._khRowBg then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(row)
            row._khRowBg = bg

            local separator = row:CreateTexture(nil, "BORDER")
            separator:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 0)
            separator:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 0)
            separator:SetHeight(1)
            row._khRowSeparator = separator
        end
        local fill = index % 2 == 0 and THEME.panelAlt or THEME.section
        row._khRowBg:SetColorTexture(fill[1], fill[2], fill[3], 0.58)
        row._khRowSeparator:SetColorTexture(
            THEME.border[1], THEME.border[2], THEME.border[3], 0.62
        )
        if row.typeText then SetFontColor(row.typeText, THEME.accent) end
        if row.name then SetFontColor(row.name, THEME.text) end
        if row.idText then SetFontColor(row.idText, THEME.subtext) end
        if row.remove then SkinButton(row.remove) end
        if row.show then SkinCheckbox(row.show, nil, false) end
    end
end

local function StyleWindowPanels()
    if helperWindow then ApplyBackdrop(helperWindow, THEME.panel, THEME.border) end
    if helperContent then ApplyBackdrop(helperContent, THEME.panelAlt, THEME.border) end
end

local function SkinButtonTree(frame)
    if not frame or not frame.GetChildren then
        return
    end

    local children = { frame:GetChildren() }

    for _, child in ipairs(children) do
        if child.GetObjectType
            and child:GetObjectType() == "Button" then

            SkinButton(child)
        end

        SkinButtonTree(child)
    end
end


-- Lightweight themed dropdown used by modules that only need a small,
-- fixed list of choices.  Kept on moduleUI so this file does not add another
-- top-level local and run into WoW Lua's 200-local chunk limit.
moduleUI.CreateChoiceDropdown = function(parent, x, y, width, choices, onSelect)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 220, 28)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    SkinButton(button)

    local caption = button:GetFontString()
    if caption then
        caption:ClearAllPoints()
        caption:SetPoint("LEFT", button, "LEFT", 10, 0)
        caption:SetPoint("RIGHT", button, "RIGHT", -25, 0)
        caption:SetJustifyH("LEFT")
    end
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10)
    arrow:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    arrow:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\ScrollArrowDown.tga")
    arrow:SetVertexColor(THEME.subtext[1], THEME.subtext[2], THEME.subtext[3], 1)
    button._khDropdownArrow = arrow

    local menuWidth = math.max(width or 220, 260)
    local visibleRows = math.min(#choices, 12)
    local menuHeight = math.max(38, (visibleRows * 27) + 12)

    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(500)
    menu:SetClampedToScreen(true)
    menu:SetSize(menuWidth, menuHeight)
    ApplyBackdrop(menu, THEME.panelAlt, THEME.border)
    menu:Hide()

    local content
    local contentWidth
    if #choices > 12 then
        local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -6)
        scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -18, 6)
        moduleUI.SkinScrollFrame(scroll)

        content = CreateFrame("Frame", nil, scroll)
        contentWidth = menuWidth - 34
        content:SetSize(contentWidth, #choices * 27)
        scroll:SetScrollChild(content)
    else
        content = CreateFrame("Frame", nil, menu)
        content:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -6)
        contentWidth = menuWidth - 16
        content:SetSize(contentWidth, math.max(menuHeight - 12, #choices * 27))
    end

    button._khChoiceButtons = {}
    button._khChoices = choices
    button._khValue = nil
    button._khMenu = menu

    for index, choice in ipairs(choices) do
        local row = CreateFrame("Button", nil, content)
        row:SetSize(contentWidth, 26)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((index - 1) * 27))
        local hover = row:CreateTexture(nil, "BACKGROUND")
        hover:SetAllPoints(row)
        hover:SetColorTexture(0.12, 0.32, 0.58, 0.65)
        hover:Hide()

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", row, "LEFT", 12, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        label:SetJustifyH("LEFT")
        label:SetText(choice.label or tostring(choice.key))
        SetFontColor(label, THEME.text)

        row._khHover = hover
        row._khLabel = label
        row:SetScript("OnEnter", function(self)
            self._khHover:Show()
            SetFontColor(self._khLabel, THEME.text)
        end)
        row:SetScript("OnLeave", function(self)
            self._khHover:Hide()
            SetFontColor(self._khLabel, THEME.subtext)
        end)
        row:SetScript("OnClick", function()
            button:SetValue(choice.key)
            menu:Hide()
            if onSelect then
                onSelect(choice.key)
            end
        end)
        button._khChoiceButtons[index] = row
    end

    function button:SetValue(value)
        self._khValue = value
        local label = tostring(value or "")

        for _, choice in ipairs(self._khChoices or {}) do
            if choice.key == value then
                label = choice.label or label
                break
            end
        end

        self:SetText(label)
    end

    function button:GetValue()
        return self._khValue
    end

    button.SetDisplayValue = button.SetValue

    function button:SetEnabledState(enabled)
        self:SetEnabled(enabled and true or false)
        if not enabled then
            menu:Hide()
        end
    end

    button:SetScript("OnClick", function(self)
        if not self:IsEnabled() then return end

        if menu:IsShown() then
            menu:Hide()
            return
        end

        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        menu:Show()
        menu:Raise()
    end)

    button:HookScript("OnHide", function()
        menu:Hide()
    end)

    return button
end

moduleUI.ApplyModuleHeader = function(parent, title, description, enableCheck, status, iconPath)
    local iconBox = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    iconBox:SetSize(72, 72)
    iconBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -12)
    ApplyBackdrop(iconBox, THEME.panelAlt, THEME.border, THEME.flatSectionBackdrop)

    local icon = iconBox:CreateTexture(nil, "ARTWORK")
    icon:SetSize(54, 54)
    icon:SetPoint("CENTER", iconBox, "CENTER")
    icon:SetTexture(iconPath)
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetVertexColor(0.90, 0.95, 1, 1)

    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", iconBox, "TOPRIGHT", 16, -5)
    title:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -164, -21)
    title:SetJustifyH("LEFT")

    description:ClearAllPoints()
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -5)
    description:SetJustifyH("LEFT")

    if enableCheck then
        enableCheck:ClearAllPoints()
        enableCheck:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -28, -20)
        if enableCheck.Label then enableCheck.Label:Hide() end
    end

    if status then
        status:ClearAllPoints()
        status:SetPoint(
            "TOPRIGHT",
            enableCheck or parent,
            enableCheck and "BOTTOMRIGHT" or "TOPRIGHT",
            0,
            enableCheck and -5 or -36
        )
        status:SetWidth(132)
        status:SetJustifyH("RIGHT")
    end

    return iconBox
end

moduleUI.ShowProfileTransferDialog = function(mode)
    if not moduleUI.profileTransferDialog then
        local frame = CreateFrame(
            "Frame",
            "KayliiHelperProfileTransferDialog",
            UIParent,
            "BackdropTemplate"
        )
        frame:SetSize(700, 460)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(600)
        frame:SetClampedToScreen(true)
        frame:EnableMouse(true)
        ApplyBackdrop(frame, THEME.panel, THEME.borderAccent)

        local title = Label(frame, "Profile Transfer", "GameFontNormalHuge")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -18)
        SetFontColor(title, THEME.text)
        frame.Title = title

        local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        close:SetSize(30, 28)
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
        close:SetText("X")
        close:SetScript("OnClick", function() frame:Hide() end)
        SkinButton(close)

        local help = Label(frame, "", "GameFontHighlightSmall")
        help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        help:SetWidth(650)
        help:SetJustifyH("LEFT")
        SetFontColor(help, THEME.subtext)
        frame.Help = help

        local scroll = CreateFrame(
            "ScrollFrame",
            nil,
            frame,
            "UIPanelScrollFrameTemplate"
        )
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -82)
        scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 76)
        moduleUI.SkinScrollFrame(scroll)
        ApplyBackdrop(scroll, THEME.panelAlt, THEME.border)

        local editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(622)
        editBox:SetTextInsets(8, 8, 8, 8)
        editBox:SetJustifyH("LEFT")
        editBox:SetJustifyV("TOP")
        editBox:EnableMouse(true)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        editBox:SetScript("OnTextChanged", function(self)
            local height = math.max(292, (self:GetNumLines() or 1) * 16 + 20)
            self:SetHeight(height)
        end)
        scroll:SetScrollChild(editBox)
        frame.EditBox = editBox

        local status = Label(frame, "", "GameFontHighlightSmall")
        status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 52)
        status:SetWidth(450)
        status:SetJustifyH("LEFT")
        frame.Status = status

        local action = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        action:SetSize(142, 30)
        action:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 18)
        SkinButton(action)
        frame.Action = action

        local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        cancel:SetSize(92, 30)
        cancel:SetPoint("RIGHT", action, "LEFT", -8, 0)
        cancel:SetText("Close")
        cancel:SetScript("OnClick", function() frame:Hide() end)
        SkinButton(cancel)

        frame:SetScript("OnShow", function()
            frame:Raise()
        end)
        moduleUI.profileTransferDialog = frame
    end

    local frame = moduleUI.profileTransferDialog
    frame.Mode = mode == "import" and "import" or "export"
    frame.Status:SetText("")
    if frame.Mode == "export" then
        frame.Title:SetText("Export Profile")
        frame.Help:SetText(
            "Copy this opaque profile string. It contains shared settings and this character's saved settings."
        )
        local text, message = BW:ExportProfileString()
        frame.EditBox:SetText(text or "")
        frame.Action:SetText("Select all")
        frame.Action:SetScript("OnClick", function()
            frame.EditBox:SetFocus()
            frame.EditBox:HighlightText()
        end)
        if not text then
            frame.Status:SetText(tostring(message or "Profile export failed."))
            SetFontColor(frame.Status, { 1.00, 0.42, 0.42, 1 })
        end
        C_Timer.After(0, function()
            if frame:IsShown() then
                frame.EditBox:SetFocus()
                frame.EditBox:HighlightText()
            end
        end)
    else
        frame.Title:SetText("Import Profile")
        frame.Help:SetText(
            "Paste a Kaylii Helper profile string. A rollback copy of current settings is saved before import."
        )
        frame.EditBox:SetText("")
        frame.Action:SetText("Import & Reload")
        frame.Action:SetScript("OnClick", function()
            local ok, message = BW:ImportProfileString(frame.EditBox:GetText())
            frame.Status:SetText(tostring(message or ""))
            SetFontColor(
                frame.Status,
                ok and THEME.accent or { 1.00, 0.42, 0.42, 1 }
            )
            if ok and ReloadUI then
                ReloadUI()
            end
        end)
        C_Timer.After(0, function()
            if frame:IsShown() then frame.EditBox:SetFocus() end
        end)
    end
    frame:Show()
end

local function Checkbox(parent, text, x, y, callback)
    local check = CreateFrame(
        "CheckButton",
        nil,
        parent,
        "UICheckButtonTemplate"
    )

    check:SetSize(46, 22)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local label = Label(parent, text, "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 9, 0)
    SetFontColor(label, THEME.text)

    check:SetScript("OnClick", function(self)
        callback(self:GetChecked() and true or false)
    end)

    SkinCheckbox(check, label)
    check.Label = label
    return check
end

local VALUE_BOX_BACKDROP = THEME.flatControlBackdrop

local function CreateVisibleValueBox(parent, width)
    local box = CreateFrame(
        "EditBox",
        nil,
        parent,
        "BackdropTemplate"
    )

    box:SetSize(width or 56, 24)
    box:SetAutoFocus(false)
    box:SetFont(
        STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
        13,
        ""
    )
    box:SetTextColor(1, 1, 1, 1)
    box:SetJustifyH("CENTER")
    box:SetJustifyV("MIDDLE")
    box:SetTextInsets(4, 4, 0, 0)

    box:SetBackdrop(VALUE_BOX_BACKDROP)
    box:SetBackdropColor(0.07, 0.12, 0.18, 1)
    box:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)

    if parent.GetFrameStrata then
        box:SetFrameStrata(parent:GetFrameStrata())
    end

    if parent.GetFrameLevel then
        box:SetFrameLevel(parent:GetFrameLevel() + 10)
    end

    -- Some Settings-panel layouts can fail to visibly paint EditBox glyphs
    -- even though GetText() contains the correct value. Keep a dedicated
    -- FontString mirror for the idle state, then expose the real EditBox text
    -- only while the user is actively editing.
    local displayText = box:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )
    displayText:SetPoint("CENTER", box, "CENTER", 0, 0)
    displayText:SetJustifyH("CENTER")
    displayText:SetJustifyV("MIDDLE")
    displayText:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)
    displayText:SetDrawLayer("OVERLAY", 7)
    box.DisplayText = displayText

    box.SetRenderedValue = function(self, value)
        local text = tostring(value or "")
        self:SetText(text)
        self.DisplayText:SetText(text)

        if self:HasFocus() then
            self.DisplayText:Hide()
            self:SetTextColor(1, 1, 1, 1)
        else
            self.DisplayText:Show()
            -- Avoid double-rendering when the normal EditBox text happens
            -- to work; the mirror is the authoritative idle display.
            self:SetTextColor(1, 1, 1, 0)
        end
    end

    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)
        self.DisplayText:Hide()
        self:SetTextColor(1, 1, 1, 1)
        self:HighlightText()
    end)

    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)
        self.DisplayText:SetText(self:GetText() or "")
        self.DisplayText:Show()
        self:SetTextColor(1, 1, 1, 0)
    end)

    return box
end

local function Slider(
    parent,
    labelText,
    x,
    y,
    width,
    minimum,
    maximum,
    step,
    formatter,
    callback
)
    local slider = CreateFrame(
        "Slider",
        nil,
        parent,
        "OptionsSliderTemplate"
    )

    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(width)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    slider.Low:SetText(tostring(minimum))
    slider.High:SetText(tostring(maximum))

    -- Exact-value entry box beside the slider.
    local valueBox = CreateVisibleValueBox(parent, 56)

    valueBox:SetMaxLetters(7)
    valueBox:SetPoint("LEFT", slider, "RIGHT", 8, 0)

    slider.ValueBox = valueBox

    local function ClampAndRound(value)
        value = tonumber(value)

        if not value then
            value = tonumber(slider:GetValue()) or minimum
        end

        value = math.max(minimum, math.min(maximum, value))
        value = math.floor((value / step) + 0.5) * step

        return value
    end

    local function UpdateValueBox(value)
        valueBox._loadingValue = true
        valueBox:SetRenderedValue(value)
        valueBox:SetCursorPosition(0)
        valueBox:HighlightText(0, 0)
        valueBox:Show()
        valueBox._loadingValue = false
    end

    slider:SetScript("OnValueChanged", function(self, value)
        local rounded = ClampAndRound(value)

        self.Text:SetText(
            labelText .. ": " .. formatter(rounded)
        )

        if not valueBox:HasFocus() then
            UpdateValueBox(rounded)
        end

        if not self._settingValue then
            callback(rounded)
        end
    end)

    -- The slider's numeric range can be much larger than its on-screen
    -- pixel width, so dragging cannot physically hit every integer.
    -- Mouse wheel gives exact one-step adjustment; Shift-wheel moves 10 steps.
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, direction)
        local current = tonumber(self:GetValue()) or minimum
        local wheelStep = step

        if IsShiftKeyDown and IsShiftKeyDown() then
            wheelStep = step * 10
        end

        local nextValue
        if direction > 0 then
            nextValue = current + wheelStep
        else
            nextValue = current - wheelStep
        end

        self:SetValue(ClampAndRound(nextValue))
    end)

    local function CommitValueBox(self)
        if self._loadingValue then
            return
        end

        local value = ClampAndRound(self:GetText())
        slider:SetValue(value)
        UpdateValueBox(value)
    end

    valueBox:SetScript("OnEnterPressed", function(self)
        CommitValueBox(self)
        self:ClearFocus()
    end)

    valueBox:HookScript("OnEditFocusLost", function(self)
        CommitValueBox(self)
    end)

    valueBox:SetScript("OnEscapePressed", function(self)
        UpdateValueBox(ClampAndRound(slider:GetValue()))
        self:ClearFocus()
    end)

    slider.SetDisplayValue = function(self, value)
        value = ClampAndRound(value)

        self._settingValue = true
        self:SetValue(value)
        self.Text:SetText(
            labelText .. ": " .. formatter(value)
        )
        UpdateValueBox(value)
        self._settingValue = false
    end

    SkinSlider(slider)
    return slider
end

local function NumberBox(
    parent,
    labelText,
    x,
    y,
    minimum,
    maximum,
    callback
)
    local label = Label(parent, labelText, "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local box = CreateVisibleValueBox(parent, 56)
    box.Label = label

    box:SetNumeric(true)
    box:SetMaxLetters(5)
    box:SetPoint("LEFT", label, "RIGHT", 8, 0)

    local function ClampValue(value)
        value = tonumber(value) or minimum
        return math.max(minimum, math.min(maximum, value))
    end

    local function Commit(self)
        if self._loadingValue then
            return
        end

        local value = ClampValue(self:GetText())

        self._loadingValue = true
        self:SetRenderedValue(value)
        self:SetCursorPosition(0)
        self:HighlightText(0, 0)
        self:Show()
        self._loadingValue = false

        callback(value)
    end

    box.SetDisplayValue = function(self, value)
        value = ClampValue(value)

        self._loadingValue = true
        self:SetRenderedValue(value)
        self:SetCursorPosition(0)
        self:HighlightText(0, 0)
        self:Show()
        self._loadingValue = false
    end

    box:SetScript("OnEnterPressed", function(self)
        Commit(self)
        self:ClearFocus()
    end)

    box:HookScript("OnEditFocusLost", function(self)
        Commit(self)
    end)

    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    SkinEditBox(box)
    return box
end

local FONT_ORDER = {
    "FRIZ",
    "ARIAL",
    "MORPHEUS",
    "SKURRI",
}

local FONT_LABELS = {
    FRIZ = "Friz Quadrata",
    ARIAL = "Arial Narrow",
    MORPHEUS = "Morpheus",
    SKURRI = "Skurri",
}

local function FontCycleButton(
    parent,
    labelText,
    x,
    y,
    callback
)
    local label = Label(parent, labelText, "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local choices = {}
    for _, key in ipairs(FONT_ORDER) do
        choices[#choices + 1] = { key = key, label = FONT_LABELS[key] }
    end
    local button = moduleUI.CreateChoiceDropdown(
        parent,
        x,
        y - 4,
        150,
        choices,
        callback
    )
    button:ClearAllPoints()
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)
    button.SetDisplayValue = button.SetValue
    return button
end

local BUFF_SORT_ORDER = {
    "default",
    "defensive",
    "important",
    "expiration",
    "expirationReverse",
    "name",
}

local BUFF_SORT_LABELS = {
    default = "Blizzard Priority",
    defensive = "Big Defensives First",
    important = "Important First",
    expiration = "Soonest Expiration",
    expirationReverse = "Longest Expiration",
    name = "Name",
}

local DEBUFF_SORT_ORDER = {
    "unitframe",
    "default",
    "expiration",
    "expirationReverse",
    "name",
}

local DEBUFF_SORT_LABELS = {
    unitframe = "Unit-Frame Priority",
    default = "Blizzard Priority",
    expiration = "Soonest Expiration",
    expirationReverse = "Longest Expiration",
    name = "Name",
}

local LUST_UP_MODE_ORDER = {
    "ready",
    "always",
}

local LUST_UP_MODE_LABELS = {
    ready = "Ready only",
    always = "Always",
}

local LUST_UP_CHAT_ORDER = {
    "OFF",
    "SAY",
    "PARTY",
    "RAID",
    "INSTANCE_CHAT",
}

local LUST_UP_CHAT_LABELS = {
    OFF = "Off",
    SAY = "Say",
    PARTY = "Party",
    RAID = "Raid",
    INSTANCE_CHAT = "Instance",
}

local DISPLAY_ORIENTATION_ORDER = {
    "horizontal",
    "vertical",
}

local DISPLAY_ORIENTATION_LABELS = {
    horizontal = "Horizontal",
    vertical = "Vertical",
}

local function SortCycleButton(
    parent,
    labelText,
    x,
    y,
    width,
    order,
    labels,
    callback
)
    local label = Label(parent, labelText, "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local choices = {}
    for _, value in ipairs(order) do
        choices[#choices + 1] = {
            key = value,
            label = labels[value] or tostring(value),
        }
    end
    local button = moduleUI.CreateChoiceDropdown(
        parent,
        x,
        y - 4,
        width,
        choices,
        callback
    )
    button._khLabel = label
    button:ClearAllPoints()
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)
    button.SetDisplayValue = button.SetValue
    return button
end

local OUTLINE_ORDER = {
    "NONE",
    "OUTLINE",
    "THICKOUTLINE",
}

local OUTLINE_LABELS = {
    NONE = "None",
    OUTLINE = "Outline",
    THICKOUTLINE = "Thick",
}

local function OutlineCycleButton(
    parent,
    labelText,
    x,
    y,
    callback
)
    local label = Label(parent, labelText, "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local choices = {}
    for _, value in ipairs(OUTLINE_ORDER) do
        choices[#choices + 1] = {
            key = value,
            label = OUTLINE_LABELS[value],
        }
    end
    local button = moduleUI.CreateChoiceDropdown(
        parent,
        x,
        y - 4,
        90,
        choices,
        callback
    )
    button:ClearAllPoints()
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)
    button.SetDisplayValue = button.SetValue
    return button
end

local function ColorButton(
    parent,
    labelText,
    x,
    y,
    callback
)
    local label
    if labelText and labelText ~= "" then
        label = Label(parent, labelText, "GameFontHighlight")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end

    local button = CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
    )
    if label then
        button:SetSize(72, 24)
        button:SetPoint("LEFT", label, "RIGHT", 8, 0)
        button:SetText("Color")
    else
        button:SetSize(40, 24)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        button:SetText("")
    end

    local swatch = button:CreateTexture(nil, "OVERLAY")
    swatch._khKeep = true
    if label then
        swatch:SetSize(14, 14)
        swatch:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    else
        swatch:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
        swatch:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    end
    button.Swatch = swatch

    local function Normalize(color)
        if type(color) ~= "table" then
            return { 1, 1, 1, 1 }
        end

        return {
            tonumber(color[1]) or 1,
            tonumber(color[2]) or 1,
            tonumber(color[3]) or 1,
            tonumber(color[4]) or 1,
        }
    end

    button.SetDisplayValue = function(self, color)
        color = Normalize(color)
        self._color = color
        self.Swatch:SetColorTexture(
            color[1],
            color[2],
            color[3],
            1
        )
    end

    button:SetScript("OnClick", function(self)
        local original = Normalize(self._color)

        local function Apply()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local color = { r, g, b, 1 }
            self:SetDisplayValue(color)
            callback(color)
        end

        local function Cancel()
            self:SetDisplayValue(original)
            callback(original)
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = original[1],
            g = original[2],
            b = original[3],
            hasOpacity = false,
            swatchFunc = Apply,
            opacityFunc = Apply,
            cancelFunc = Cancel,
        })
    end)

    button:SetDisplayValue({ 1, 1, 1, 1 })
    SkinButton(button)
    return button
end

local function SpellInfoFor(spellID)
    local info = C_Spell.GetSpellInfo(spellID)

    if not info then
        return "Unknown spell", 134400
    end

    return info.name or "Unknown spell", info.iconID or 134400
end

local function ScanTarget()
    wipe(targetAuras)

    if not UnitExists("target") then
        return false, "No target selected."
    end

    local seen = {}
    local restricted = false

    local function IsSecret(value)
        return issecretvalue
            and issecretvalue(value)
            or false
    end

    local function ScanFilter(filter, kind)
        for index = 1, 100 do
            local aura = C_UnitAuras.GetAuraDataByIndex(
                "target",
                index,
                filter
            )

            if not aura then
                break
            end

            local spellID = aura.spellId

            if IsSecret(spellID) then
                restricted = true
                return
            end

            if spellID then
                local key =
                    kind .. ":" .. tostring(spellID)

                if not seen[key] then
                    seen[key] = true

                    local name, icon =
                        SpellInfoFor(spellID)

                    targetAuras[#targetAuras + 1] = {
                        kind = kind,
                        spellID = spellID,
                        name = name,
                        icon = icon,
                    }
                end
            end
        end
    end

    local ok = pcall(function()
        ScanFilter("HELPFUL", "buff")

        if not restricted then
            ScanFilter("HARMFUL", "debuff")
        end
    end)

    if not ok or restricted then
        wipe(targetAuras)

        return false,
            "WoW is restricting target aura inspection right now. Try again outside protected combat/encounter states."
    end

    table.sort(targetAuras, function(a, b)
        if a.kind ~= b.kind then
            return a.kind == "debuff"
        end

        local an = a.name or ""
        local bn = b.name or ""

        if an == bn then
            return a.spellID < b.spellID
        end

        return an < bn
    end)

    return true, string.format(
        "%d unique active buffs/debuffs found on the current target.",
        #targetAuras
    )
end

local UpdateAuraListWidth
local SetMainView

local function GetSavedRows()
    local result = {}

    for spellID, enabled in pairs(BW.db.debuffs) do
        spellID = tonumber(spellID)

        if spellID and enabled == true then
            local name, icon = SpellInfoFor(spellID)

            result[#result + 1] = {
                kind = "debuff",
                spellID = spellID,
                name = name,
                icon = icon,
                enabled = true,
            }
        end
    end

    for spellID, enabled in pairs(BW.db.buffs) do
        spellID = tonumber(spellID)

        if spellID and enabled == true then
            local name, icon = SpellInfoFor(spellID)

            result[#result + 1] = {
                kind = "buff",
                spellID = spellID,
                name = name,
                icon = icon,
                enabled = true,
            }
        end
    end

    table.sort(result, function(a, b)
        if a.kind ~= b.kind then
            return a.kind == "debuff"
        end

        if a.name == b.name then
            return a.spellID < b.spellID
        end

        return a.name < b.name
    end)

    return result
end

local function GetBlacklistRows()
    local result = {}

    for spellID, blocked in pairs(BW.db.debuffBlacklist or {}) do
        spellID = tonumber(spellID)

        if spellID and blocked then
            local name, icon = SpellInfoFor(spellID)

            result[#result + 1] = {
                kind = "debuff",
                spellID = spellID,
                name = name,
                icon = icon,
                enabled = true,
            }
        end
    end

    for spellID, blocked in pairs(BW.db.buffBlacklist or {}) do
        spellID = tonumber(spellID)

        if spellID and blocked then
            local name, icon = SpellInfoFor(spellID)

            result[#result + 1] = {
                kind = "buff",
                spellID = spellID,
                name = name,
                icon = icon,
                enabled = true,
            }
        end
    end

    table.sort(result, function(a, b)
        if a.kind ~= b.kind then
            return a.kind == "debuff"
        end

        if a.name == b.name then
            return a.spellID < b.spellID
        end

        return a.name < b.name
    end)

    return result
end

local function AcquireRow(index)
    if rows[index] then
        return rows[index]
    end

    local row = CreateFrame("Frame", nil, scrollChild)
    row:SetSize(610, ROW_HEIGHT)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", row, "LEFT", 10, 0)
    row.icon = icon

    local show = CreateFrame(
        "CheckButton",
        nil,
        row,
        "UICheckButtonTemplate"
    )

    show:SetSize(38, 20)
    row.show = show

    local typeText = Label(row, "", "GameFontDisableSmall")
    typeText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
    typeText:SetWidth(52)
    typeText:SetJustifyH("LEFT")
    row.typeText = typeText

    local name = Label(row, "", "GameFontNormal")
    name:SetPoint("LEFT", typeText, "RIGHT", 2, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -124, 3)
    name:SetJustifyH("LEFT")
    row.name = name

    local idText = Label(row, "", "GameFontDisableSmall")
    idText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 0, -3)
    idText:SetPoint("RIGHT", name, "RIGHT", 0, 0)
    idText:SetJustifyH("LEFT")
    row.idText = idText

    local remove = CreateFrame(
        "Button",
        nil,
        row,
        "UIPanelButtonTemplate"
    )

    remove:SetSize(72, 22)
    remove:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    remove:SetText("Remove")
    row.remove = remove

    rows[index] = row
    StyleRows()
    UpdateAuraListWidth()
    return row
end

local function RebuildRows()
    local data

    if auraListMode == "target" then
        data = targetAuras
    elseif auraEditMode == "blacklist" then
        data = GetBlacklistRows()
    else
        data = GetSavedRows()
    end

    for i, entry in ipairs(data) do
        local row = AcquireRow(i)
        local enabled

        if auraEditMode == "blacklist" then
            enabled = BW:IsBlacklisted(
                entry.kind,
                entry.spellID
            )
        else
            local list = entry.kind == "debuff"
                and BW.db.debuffs
                or BW.db.buffs

            enabled = list[entry.spellID] == true
        end

        row.icon:SetTexture(entry.icon or 134400)
        row.typeText:SetText(
            entry.kind == "debuff" and "DEBUFF" or "BUFF"
        )
        row.name:SetText(
            entry.name or ("Spell " .. entry.spellID)
        )

        if auraEditMode == "blacklist" then
            row.idText:SetText(
                "Never show • Spell ID: " .. entry.spellID
            )
        else
            row.idText:SetText(
                "Whitelisted • Spell ID: " .. entry.spellID
            )
        end

        row.show:SetChecked(enabled)

        row.show:SetScript("OnClick", function(button)
            if auraEditMode == "blacklist" then
                BW:SetBlacklisted(
                    entry.kind,
                    entry.spellID,
                    button:GetChecked() and true or false
                )
            else
                BW:SetSpellEnabled(
                    entry.kind,
                    entry.spellID,
                    button:GetChecked() and true or false
                )
            end
        end)

        if auraListMode == "saved" then
            row.show:ClearAllPoints()
            row.show:SetPoint("RIGHT", row, "RIGHT", -92, 0)
            row.remove:Show()

            row.remove:SetScript("OnClick", function()
                if auraEditMode == "blacklist" then
                    BW:RemoveBlacklistSpell(
                        entry.kind,
                        entry.spellID
                    )
                else
                    BW:RemoveSpell(
                        entry.kind,
                        entry.spellID
                    )
                end
            end)
        else
            row.show:ClearAllPoints()
            row.show:SetPoint("RIGHT", row, "RIGHT", -16, 0)
            row.remove:Hide()
        end

        row:ClearAllPoints()
        row:SetPoint(
            "TOPLEFT",
            scrollChild,
            "TOPLEFT",
            0,
            -((i - 1) * ROW_HEIGHT)
        )
        row:Show()
    end

    for i = #data + 1, #rows do
        rows[i]:Hide()
    end

    scrollChild:SetHeight(
        math.max(1, #data * ROW_HEIGHT)
    )

    StyleRows()
    UpdateAuraListWidth()
end

function BW:RefreshTargetAuras()
    if not panel then
        return
    end

    if UnitExists("target") then
        local targetName = UnitName("target")

        if issecretvalue
            and issecretvalue(targetName) then

            targetText:SetText(
                "Selected target: current target"
            )
        else
            targetText:SetText(
                "Selected target: "
                .. (targetName or "Target")
            )
        end
    else
        targetText:SetText("Selected target: none")
    end

    local _, message = ScanTarget()
    statusText:SetText(message)

    if auraListMode == "target" then
        RebuildRows()
    end
end


function BW:QueueTargetAuraRefresh()
    if not panel then
        return
    end

    self.targetAuraRefreshSerial =
        (self.targetAuraRefreshSerial or 0) + 1

    local serial = self.targetAuraRefreshSerial

    local function RefreshIfCurrent()
        -- Every target change / target aura refresh starts a new generation.
        -- This normal Lua integer invalidates older timers without comparing
        -- protected UnitGUID values.
        if serial ~= BW.targetAuraRefreshSerial then
            return
        end

        BW:RefreshTargetAuras()
    end

    RefreshIfCurrent()

    C_Timer.After(0.05, RefreshIfCurrent)
    C_Timer.After(0.15, RefreshIfCurrent)
    C_Timer.After(0.35, RefreshIfCurrent)
end

local function SetAuraListMode(mode)
    auraListMode = mode

    if auraScroll then
        auraScroll:SetVerticalScroll(0)
    end

    if mode == "target" then
        targetAuraTab:Disable()
        savedAuraTab:Enable()
        BW:QueueTargetAuraRefresh()
    else
        savedAuraTab:Disable()
        targetAuraTab:Enable()
        statusText:SetText(
            "Saved aura filters for the Blizzard Target Frame."
        )

        RebuildRows()

        C_Timer.After(0, function()
            if auraListMode ~= "saved" then
                return
            end

            if auraScroll then
                auraScroll:SetVerticalScroll(0)
            end

            RebuildRows()
        end)
    end
end

local function SetAuraEditMode(mode)
    auraEditMode = mode

    editFilterButton:SetEnabled(mode ~= "filter")
    editBlacklistButton:SetEnabled(mode ~= "blacklist")

    if mode == "blacklist" then
        listEditHelp:SetText(
            "BLACKLIST: checked = never show. This list is always applied, even when the normal buff/debuff spell filter is OFF."
        )

        savedAuraTab:SetText("Saved Blacklist")

        if addBuffButton then
            addBuffButton:SetText("Block buff")
            addDebuffButton:SetText("Block debuff")
        end
    else
        listEditHelp:SetText(
            "WHITELIST: checked = allowed by Whitelist Only and added to Mine + Whitelist from any caster. Blacklist overrides it. Mine + Whitelist keeps the PLAYER lane independent from whitelist capacity."
        )

        savedAuraTab:SetText("Saved Whitelist")

        if addBuffButton then
            addBuffButton:SetText("Whitelist buff")
            addDebuffButton:SetText("Whitelist debuff")
        end
    end

    if auraListMode == "target" then
        BW:RefreshTargetAuras()
    else
        if auraScroll then
            auraScroll:SetVerticalScroll(0)
        end

        RebuildRows()

        C_Timer.After(0, function()
            if auraListMode == "saved" then
                RebuildRows()
            end
        end)
    end
end

local function UpdateAnchorModeButtons()
    local mode = BW.db.debuffAnchorMode
    if moduleUI.debuffAnchorModeDropdown then
        moduleUI.debuffAnchorModeDropdown:SetValue(mode)
    end
end


local function UpdateDirectionButtons()
    if moduleUI.buffGrowHorizontalDropdown then
        moduleUI.buffGrowHorizontalDropdown:SetValue(
            BW.db.buffGrowLeft and "left" or "right"
        )
        moduleUI.buffGrowVerticalDropdown:SetValue(
            BW.db.buffGrowDown and "down" or "up"
        )
        moduleUI.debuffGrowHorizontalDropdown:SetValue(
            BW.db.debuffGrowLeft and "left" or "right"
        )
        moduleUI.debuffGrowVerticalDropdown:SetValue(
            BW.db.debuffGrowDown and "down" or "up"
        )
    end
end

local function SetAnchorMode(mode)
    BW.db.debuffAnchorMode = mode
    UpdateAnchorModeButtons()
    BW:RefreshPresentation()
end

UpdateAuraListWidth = function()
    if not auraScroll or not scrollChild then
        return
    end

    local width = math.max(
        360,
        math.floor((auraScroll:GetWidth() or 610) - 4)
    )

    scrollChild:SetWidth(width)

    for _, row in ipairs(rows) do
        row:SetWidth(width)

        if row.name then
            local trailingSpace = auraListMode == "saved" and 140 or 68
            local textWidth = math.max(120, width - 108 - trailingSpace)
            row.name:SetWidth(textWidth)
            row.idText:SetWidth(textWidth)
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.typeText, "RIGHT", 2, 0)
            row.name:SetPoint("RIGHT", row, "RIGHT", -trailingSpace, 3)
            row.idText:ClearAllPoints()
            row.idText:SetPoint("TOPLEFT", row.typeText, "BOTTOMLEFT", 0, -3)
            row.idText:SetPoint("RIGHT", row.name, "RIGHT", 0, 0)
        end
    end
end

local function SaveHelperWindowPosition()
    if not helperWindow or not BW.db then
        return
    end

    local x, y = helperWindow:GetCenter()
    local ux, uy = UIParent:GetCenter()

    if x and y and ux and uy then
        BW.db.helperWindowX = math.floor((x - ux) + 0.5)
        BW.db.helperWindowY = math.floor((y - uy) + 0.5)
    end

    -- A minimized helper window is only the title bar. Never let that
    -- temporary size replace the user's normal expanded window dimensions.
    if not helperWindow._khMinimized then
        BW.db.helperWindowWidth =
            math.floor((helperWindow:GetWidth() or 1100) + 0.5)

        BW.db.helperWindowHeight =
            math.floor((helperWindow:GetHeight() or 900) + 0.5)
    end
end

local function SetHelperWindowMinimized(minimized)
    if not helperWindow then
        return
    end

    minimized = minimized and true or false

    if minimized == helperWindow._khMinimized then
        return
    end

    if minimized then
        helperWindow._khExpandedWidth =
            helperWindow:GetWidth() or tonumber(BW.db and BW.db.helperWindowWidth) or 1100
        helperWindow._khExpandedHeight =
            helperWindow:GetHeight() or tonumber(BW.db and BW.db.helperWindowHeight) or 900
        helperWindow._khMinimized = true

        if helperSidebar then helperSidebar:Hide() end
        if helperContent then helperContent:Hide() end
        if moduleUI.helperResizeGrip then moduleUI.helperResizeGrip:Hide() end

        -- Temporarily relax the normal large-window resize bounds so the
        -- frame can collapse to the title bar even though the expanded UI has
        -- a much larger minimum size.
        if helperWindow.SetResizeBounds then
            helperWindow:SetResizeBounds(
                430,
                84,
                helperWindow._khMaxWidth or 2000,
                helperWindow._khMaxHeight or 1600
            )
        elseif helperWindow.SetMinResize then
            helperWindow:SetMinResize(430, 84)
        end

        helperWindow:SetResizable(false)
        helperWindow:SetSize(430, 84)

        if moduleUI.helperMinimizeText then
            moduleUI.helperMinimizeText:SetText("+")
        end
    else
        helperWindow._khMinimized = false
        helperWindow:SetResizable(true)

        if helperWindow.SetResizeBounds then
            helperWindow:SetResizeBounds(
                helperWindow._khMinWidth or 900,
                helperWindow._khMinHeight or 700,
                helperWindow._khMaxWidth or 2000,
                helperWindow._khMaxHeight or 1600
            )
        elseif helperWindow.SetMinResize then
            helperWindow:SetMinResize(
                helperWindow._khMinWidth or 900,
                helperWindow._khMinHeight or 700
            )
        end

        local width = helperWindow._khExpandedWidth
            or tonumber(BW.db and BW.db.helperWindowWidth)
            or 1100
        local height = helperWindow._khExpandedHeight
            or tonumber(BW.db and BW.db.helperWindowHeight)
            or 900

        helperWindow:SetSize(width, height)

        if helperSidebar then helperSidebar:Show() end
        if helperContent then helperContent:Show() end
        if moduleUI.helperResizeGrip then moduleUI.helperResizeGrip:Show() end

        if moduleUI.helperMinimizeText then
            moduleUI.helperMinimizeText:SetText("-")
        end

        UpdateAuraListWidth()
    end

    SaveHelperWindowPosition()
end

function BW:SetHelperWindowMinimized(minimized)
    SetHelperWindowMinimized(minimized)
end

-- Sidebar availability follows the home-page module switches.
-- Keep this helper on moduleUI to avoid another main-chunk local.
moduleUI.RefreshSidebarButtons = function()
    if not BW.db then return end
    local entries = {
        { helperHomeButton, "home", true },
        { helperBuffButton, "buff", BW.db.buffWhitelistModuleEnabled ~= false },
        { helperLustButton, "lust", BW.db.lustUpEnabled },
        { moduleUI.helperStatsButton, "stats", BW.db.statsModuleEnabled },
        { moduleUI.helperTalentButton, "talent", BW.db.talentLoadoutEnabled },
        { moduleUI.helperRaidSpecButton, "raidspec", BW.db.raidFrameSpecEnabled },
        { moduleUI.helperSurvivalButton, "survival", BW.db.survivalModuleEnabled },
    }
    for _, entry in ipairs(entries) do
        local button, view, enabled = entry[1], entry[2], entry[3]
        if button then
            local active = enabled and helperView == view
            button:SetEnabled(enabled and not active and true or false)
            SetButtonActiveState(button, active)
            button:SetAlpha(enabled and 1 or 0.4)
        end
    end
end

local function SetHelperView(view)
    helperView = view or "home"

    if rootPanel then
        rootPanel:SetShown(helperView == "home")
    end

    if panel then
        panel:SetShown(helperView == "buff")
    end

    if lustPanel then
        lustPanel:SetShown(helperView == "lust")
    end

    if moduleUI.statsPanel then
        moduleUI.statsPanel:SetShown(helperView == "stats")
    end

    if moduleUI.survivalPanel then
        moduleUI.survivalPanel:SetShown(helperView == "survival")
    end

    if moduleUI.talentPanel then
        moduleUI.talentPanel:SetShown(helperView == "talent")
    end

    if moduleUI.raidSpecPanel then
        moduleUI.raidSpecPanel:SetShown(helperView == "raidspec")
    end

    moduleUI.RefreshSidebarButtons()

    if helperView == "buff" then
        BW:RefreshOptions()
        SetMainView(mainView or "layout")

        if mainView == "layout"
            and BW.db
            and BW.db.buffWhitelistModuleEnabled ~= false then

            BW:RefreshLayoutPreview()
        end

    elseif helperView == "lust" then
        BW:RefreshLustUpOptions()

    elseif helperView == "stats" then
        BW:RefreshStatsOptions()

    elseif helperView == "survival" then
        BW:RefreshSurvivalOptions()

    elseif helperView == "talent" then
        BW:RefreshTalentLoadoutOptions()

    elseif helperView == "raidspec" then
        BW:RefreshRaidFrameSpecOptions()
    end

    StyleWindowPanels()
    StyleRows()
    UpdateAuraListWidth()
end

function BW:OpenHelperWindow(view)
    if not helperWindow then
        return
    end

    if view then
        SetHelperView(view)
    end

    helperWindow:Show()
    helperWindow:Raise()

    StyleWindowPanels()
    SkinButtonTree(helperWindow)
    UpdateAuraListWidth()
end

function BW:IsHelperWindowShown()
    return helperWindow
        and helperWindow:IsShown()
        and true
        or false
end

function BW:ToggleHelperWindow(view)
    if not helperWindow then
        return
    end

    if helperWindow:IsShown() then
        helperWindow:Hide()
        return
    end

    self:OpenHelperWindow(view or "home")
end

function BW:CloseHelperWindow()
    if helperWindow then
        helperWindow:Hide()
    end
end

local function BuildHelperWindow()
    helperWindow = CreateFrame(
        "Frame",
        "KayliiHelperConfigWindow",
        UIParent,
        "BackdropTemplate"
    )

    -- Keep a public reference for launcher modules while retaining the local
    -- reference used throughout this file.
    BW.helperWindow = helperWindow

    helperWindow:SetFrameStrata("DIALOG")
    helperWindow:SetClampedToScreen(true)
    helperWindow:SetMovable(true)
    helperWindow:SetResizable(true)
    helperWindow:EnableMouse(true)
    local roundedWindowBackdrop = {
        bgFile = THEME_BACKDROP.bgFile,
        edgeFile = THEME_BACKDROP.edgeFile,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }
    ApplyBackdrop(helperWindow, THEME.panel, THEME.border, roundedWindowBackdrop)

    local screenWidth = UIParent:GetWidth() or 1200
    local screenHeight = UIParent:GetHeight() or 900
    local maxWidth = math.max(900, screenWidth - 30)
    local maxHeight = math.max(700, screenHeight - 30)
    -- The configuration pages use an ~836px two-column content layout.
    -- With the 244px sidebar offset and outer padding, 1100px keeps the
    -- content cards inside the window at minimum size.
    -- Keep resizing enabled, but stop at a width that actually fits the UI.
    local minWidth = math.min(1100, maxWidth)

    -- Lust Up contains two top cards, live status, and lockout management.
    -- Keep resizing enabled, but stop at a height that actually fits the page.
    local minHeight = math.min(900, maxHeight)
    local width = math.max(minWidth, math.min(tonumber(BW.db.helperWindowWidth) or 1180, maxWidth))
    local height = math.max(minHeight, math.min(tonumber(BW.db.helperWindowHeight) or 900, maxHeight))
    helperWindow:SetSize(width, height)
    helperWindow._khMinWidth = minWidth
    helperWindow._khMinHeight = minHeight
    helperWindow._khExpandedMinHeight = minHeight
    helperWindow._khMaxWidth = maxWidth
    helperWindow._khMaxHeight = maxHeight

    if helperWindow.SetResizeBounds then
        helperWindow:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
    else
        if helperWindow.SetMinResize then helperWindow:SetMinResize(minWidth, minHeight) end
        if helperWindow.SetMaxResize then helperWindow:SetMaxResize(maxWidth, maxHeight) end
    end

    helperWindow:SetPoint("CENTER", UIParent, "CENTER", tonumber(BW.db.helperWindowX) or 0, tonumber(BW.db.helperWindowY) or 0)

    local titleBar = CreateFrame("Frame", nil, helperWindow, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", helperWindow, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", helperWindow, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(82)
    titleBar:EnableMouse(true)
    -- Keep the title area as one flat surface inside the window. Giving this
    -- frame its own border makes the Kaylii header look like a nested box.
    titleBar:SetBackdrop({ bgFile = THEME_BACKDROP.bgFile })
    titleBar:SetBackdropColor(THEME.panel[1], THEME.panel[2], THEME.panel[3], 1)
    titleBar:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then helperWindow:StartMoving() end end)
    titleBar:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then helperWindow:StopMovingOrSizing(); SaveHelperWindowPosition() end end)

    local logoButton = CreateFrame(
        "Button",
        nil,
        titleBar
    )

    -- Image button: never pass this through the generic text-button skin.
    logoButton._khNoSkin = true

    logoButton:SetSize(48, 48)
    logoButton:SetPoint(
        "LEFT",
        titleBar,
        "LEFT",
        18,
        1
    )

    local logo = logoButton:CreateTexture(
        nil,
        "ARTWORK",
        nil,
        7
    )
    logo:SetAllPoints(logoButton)
    logo:SetTexture(
        "Interface\\AddOns\\KayliiHelper\\Media\\KayliiIcon"
    )
    logo:SetTexCoord(0, 1, 0, 1)
    logo:SetVertexColor(1, 1, 1, 1)
    logo:SetAlpha(1)

    local logoHover = logoButton:CreateTexture(
        nil,
        "HIGHLIGHT"
    )
    logoHover:SetAllPoints(logoButton)
    logoHover:SetColorTexture(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        0.14
    )

    logoButton:SetScript("OnClick", function()
        SetHelperView("home")
    end)

    logoButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(
            self,
            "ANCHOR_RIGHT"
        )
        GameTooltip:AddLine(
            "Kaylii Helper",
            1,
            1,
            1
        )
        GameTooltip:AddLine(
            "Click to return to the main page.",
            0.75,
            0.80,
            0.90
        )
        GameTooltip:Show()
    end)

    logoButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local title = Label(
        titleBar,
        "Kaylii Helper",
        "GameFontNormalHuge"
    )
    title:SetPoint(
        "LEFT",
        logoButton,
        "RIGHT",
        14,
        2
    )
    SetFontColor(title, THEME.text)

    local subtitle = Label(
        titleBar,
        "Configurations",
        "GameFontHighlightSmall"
    )
    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -4
    )
    SetFontColor(subtitle, THEME.subtext)

    moduleUI.helperMinimizeButton = CreateFrame(
        "Button",
        nil,
        titleBar
    )
    moduleUI.helperMinimizeButton:SetSize(30, 30)
    moduleUI.helperMinimizeButton:SetPoint(
        "TOPRIGHT",
        titleBar,
        "TOPRIGHT",
        -50,
        -14
    )
    moduleUI.helperMinimizeText = moduleUI.helperMinimizeButton:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )
    moduleUI.helperMinimizeText:SetPoint(
        "CENTER",
        moduleUI.helperMinimizeButton,
        "CENTER",
        0,
        1
    )
    moduleUI.helperMinimizeText:SetText("-")
    moduleUI.helperMinimizeText:SetTextColor(
        THEME.text[1],
        THEME.text[2],
        THEME.text[3],
        1
    )

    moduleUI.helperMinimizeButton:SetScript("OnEnter", function(self)
        moduleUI.helperMinimizeText:SetTextColor(
            THEME.accentHover[1],
            THEME.accentHover[2],
            THEME.accentHover[3],
            1
        )

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(
            helperWindow._khMinimized and "Restore Kaylii Helper" or "Minimize Kaylii Helper",
            1,
            1,
            1
        )
        GameTooltip:AddLine(
            "Movers stay active while the options window is minimized.",
            0.75,
            0.80,
            0.90
        )
        GameTooltip:Show()
    end)

    moduleUI.helperMinimizeButton:SetScript("OnLeave", function(self)
        moduleUI.helperMinimizeText:SetTextColor(
            THEME.text[1],
            THEME.text[2],
            THEME.text[3],
            1
        )
        GameTooltip:Hide()
    end)

    moduleUI.helperMinimizeButton:SetScript("OnClick", function()
        SetHelperWindowMinimized(not helperWindow._khMinimized)
    end)

    local close = CreateFrame(
        "Button",
        nil,
        titleBar
    )
    close:SetSize(30, 30)
    close:SetPoint(
        "TOPRIGHT",
        titleBar,
        "TOPRIGHT",
        -14,
        -14
    )
    local closeText = close:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )
    closeText:SetPoint(
        "CENTER",
        close,
        "CENTER",
        0,
        1
    )
    closeText:SetText("X")
    closeText:SetTextColor(
        THEME.text[1],
        THEME.text[2],
        THEME.text[3],
        1
    )

    close:SetScript("OnEnter", function(self)
        closeText:SetTextColor(
            THEME.accentHover[1],
            THEME.accentHover[2],
            THEME.accentHover[3],
            1
        )
    end)

    close:SetScript("OnLeave", function(self)
        closeText:SetTextColor(
            THEME.text[1],
            THEME.text[2],
            THEME.text[3],
            1
        )
    end)

    close:SetScript("OnMouseDown", function()
        closeText:SetPoint(
            "CENTER",
            close,
            "CENTER",
            1,
            0
        )
    end)

    close:SetScript("OnMouseUp", function()
        closeText:SetPoint(
            "CENTER",
            close,
            "CENTER",
            0,
            1
        )
    end)

    close:SetScript("OnClick", function()
        helperWindow:Hide()
    end)

    helperSidebar = CreateFrame("Frame", nil, helperWindow, "BackdropTemplate")
    local sidebar = helperSidebar
    local sidebarWidth = 228
    sidebar:SetPoint("TOPLEFT", helperWindow, "TOPLEFT", 10, -83)
    sidebar:SetPoint("BOTTOMLEFT", helperWindow, "BOTTOMLEFT", 10, 10)
    sidebar:SetWidth(sidebarWidth)
    local sidebarTopLine = sidebar:CreateTexture(nil, "BORDER")
    sidebarTopLine:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, 0)
    sidebarTopLine:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
    sidebarTopLine:SetHeight(1)
    sidebarTopLine:SetColorTexture(THEME.border[1], THEME.border[2], THEME.border[3], 1)

    local function NavButton(text, y, view, iconPath)
        local button = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
        button:SetSize(sidebarWidth - 20, 34)
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, y)
        button:SetText(text)
        local buttonText = button:GetFontString()
        if buttonText then
            buttonText:ClearAllPoints()
            buttonText:SetPoint("LEFT", button, "LEFT", 40, 0)
            buttonText:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            buttonText:SetJustifyH("LEFT")
        end
        button:SetScript("OnClick", function() SetHelperView(view) end)
        button._khNavStyle = true
        SkinButton(button)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(19, 19)
        icon:SetPoint("LEFT", button, "LEFT", 12, 0)
        icon:SetTexture(iconPath)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetVertexColor(0.88, 0.94, 1.00, 1)
        return button
    end

    helperHomeButton = NavButton("Home", -16, "home", "Interface\\AddOns\\KayliiHelper\\Media\\NavHome.tga")
    helperBuffButton = NavButton("Buff White List", -56, "buff", "Interface\\AddOns\\KayliiHelper\\Media\\NavBuff.tga")
    helperLustButton = NavButton("Lust Up", -96, "lust", "Interface\\AddOns\\KayliiHelper\\Media\\NavLust.tga")
    moduleUI.helperStatsButton = NavButton("My Stats", -136, "stats", "Interface\\AddOns\\KayliiHelper\\Media\\NavStats.tga")
    moduleUI.helperTalentButton = NavButton("Talent Loadout", -176, "talent", "Interface\\AddOns\\KayliiHelper\\Media\\NavTalent.tga")
    moduleUI.helperRaidSpecButton = NavButton("Raid Frame Spec", -216, "raidspec", "Interface\\AddOns\\KayliiHelper\\Media\\NavRaid.tga")
    moduleUI.helperSurvivalButton = NavButton("Survival Helper", -256, "survival", "Interface\\AddOns\\KayliiHelper\\Media\\NavSurvival.tga")

    local openHelp = Label(
        sidebar,
        "Open: /kh  /kaylii\n"
        .. "/kayliihelper\n"
        .. "Modules: /bwl  /lustup\n"
        .. "/khstats  /khtalents\n"
        .. "/khraid  /khsurvival\n"
        .. "Recover minimap: /khminimap",
        "GameFontHighlightSmall"
    )
    openHelp:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 16, 36)
    openHelp:SetWidth(sidebarWidth - 32)
    openHelp:SetJustifyH("LEFT")
    SetFontColor(openHelp, THEME.subtext)

    local resizeHint = Label(sidebar, "Drag the lower-right corner to resize.", "GameFontDisableSmall")
    resizeHint:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 16, 16)
    resizeHint:SetWidth(sidebarWidth - 32)
    resizeHint:SetJustifyH("LEFT")
    SetFontColor(resizeHint, THEME.muted)

    helperContent = CreateFrame("Frame", nil, helperWindow, "BackdropTemplate")
    helperContent:SetPoint("TOPLEFT", helperWindow, "TOPLEFT", 10 + sidebarWidth + 6, -83)
    helperContent:SetPoint("BOTTOMRIGHT", helperWindow, "BOTTOMRIGHT", -10, 10)
    ApplyBackdrop(helperContent, THEME.panelAlt, THEME.border)

    moduleUI.helperResizeGrip = CreateFrame("Button", nil, helperWindow)
    local resizeGrip = moduleUI.helperResizeGrip
    resizeGrip:SetSize(24, 24)
    resizeGrip:SetPoint("BOTTOMRIGHT", helperWindow, "BOTTOMRIGHT", -5, 5)
    local gripTexture = resizeGrip:CreateTexture(nil, "ARTWORK")
    gripTexture:SetAllPoints(resizeGrip)
    gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then helperWindow:StartSizing("BOTTOMRIGHT") end end)
    resizeGrip:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then helperWindow:StopMovingOrSizing(); SaveHelperWindowPosition(); UpdateAuraListWidth() end end)

    helperWindow:SetScript("OnSizeChanged", function(self)
        if BW.db and not self._khMinimized then
            BW.db.helperWindowWidth = math.floor((self:GetWidth() or 1180) + 0.5)
            BW.db.helperWindowHeight = math.floor((self:GetHeight() or 900) + 0.5)
        end

        if not self._khMinimized then
            UpdateAuraListWidth()
        end
    end)

    helperWindow:SetScript("OnHide", function()
        SaveHelperWindowPosition()

        if BW.HideLayoutPreview then
            BW:HideLayoutPreview()
        end

        -- Movers/edit modes only exist while Kaylii Helper is open. Normal
        -- module displays remain active; only their draggable edit state ends.
        if BW.HideRaidFrameSpecMovers then
            BW:HideRaidFrameSpecMovers()
        end

        if BW.ResetRaidFrameSpecEditSpec then
            BW:ResetRaidFrameSpecEditSpec()
        end

        if BW.db then
            if BW.db.lustUpUnlocked
                and BW.SetLustUpUnlocked then

                BW:SetLustUpUnlocked(false)
            end

            if BW.db.statsUnlocked
                and BW.SetStatsUnlocked then

                BW:SetStatsUnlocked(false)
            end

            if BW.db.talentLoadoutUnlocked
                and BW.SetTalentLoadoutUnlocked then

                BW:SetTalentLoadoutUnlocked(false)
            end

            if BW.db.survivalUnlocked
                and BW.SetSurvivalUnlocked then

                BW:SetSurvivalUnlocked(false)
            end
        end
    end)

    if UISpecialFrames then table.insert(UISpecialFrames, "KayliiHelperConfigWindow") end
    helperWindow:Hide()
end

SetMainView = function(view)
    -- The main tab handler can be reached while options are still being
    -- assembled after a UI error. Keep that partial state from throwing more
    -- nil-page errors; FinalizeOptions selects the initial page once built.
    if not layoutPage or not auraPage or not textPage
        or not layoutTab or not auraTab or not textTab then
        mainView = view
        return
    end

    mainView = view

    layoutPage:Hide()
    auraPage:Hide()
    textPage:Hide()

    if view == "layout" then
        layoutPage:Show()
    elseif view == "auras" then
        auraPage:Show()
    elseif view == "text" then
        textPage:Show()
    end

    layoutTab:SetEnabled(view ~= "layout")
    auraTab:SetEnabled(view ~= "auras")
    textTab:SetEnabled(view ~= "text")

    SetButtonActiveState(layoutTab, view == "layout")
    SetButtonActiveState(auraTab, view == "auras")
    SetButtonActiveState(textTab, view == "text")

    if view == "layout" then
        if BW.db and buffColumnsBox then
            iconSizeSlider:SetDisplayValue(BW.db.iconSize or 18)
            buffXSlider:SetDisplayValue(BW.db.buffOffsetX or 0)
            buffYSlider:SetDisplayValue(BW.db.buffOffsetY or 29)
            debuffXSlider:SetDisplayValue(BW.db.debuffOffsetX or 0)
            debuffYSlider:SetDisplayValue(BW.db.debuffOffsetY or 0)

            buffColumnsBox:SetDisplayValue(BW.db.buffColumns or 5)
            buffRowsBox:SetDisplayValue(BW.db.buffRows or 1)
            debuffColumnsBox:SetDisplayValue(BW.db.debuffColumns or 5)
            debuffRowsBox:SetDisplayValue(BW.db.debuffRows or 1)
        end

        BW:RefreshLayoutPreview()

    elseif view == "auras" then
        BW:QueueTargetAuraRefresh()
    end
end

function BW:RefreshLustUpOptions()
    moduleUI.RefreshSidebarButtons()
    if not lustPage or not self.db then
        return
    end

    if lustPageEnabledCheck then
        lustPageEnabledCheck:SetChecked(
            self.db.lustUpEnabled and true or false
        )
    end

    if rootLustEnabledCheck then
        rootLustEnabledCheck:SetChecked(
            self.db.lustUpEnabled and true or false
        )
    end

    if lustPanel and lustPanel.moduleStatus then
        if not self.db.lustUpEnabled then
            lustPanel.moduleStatus:SetText(
                "|cffff5555Module disabled|r"
            )

        elseif self.db.lustUpRequireLustAbility
            and self.HasLustSource
            and not self:HasLustSource() then

            lustPanel.moduleStatus:SetText(
                self.db.lustUpAllowDrums
                and "|cffffcc55No Lust source|r"
                or "|cffffcc55No Lust ability|r"
            )

        else
            lustPanel.moduleStatus:SetText(
                "|cff4d9fffModule enabled|r"
            )
        end
    end

    lustUpVoiceCheck:SetChecked(
        self.db.lustUpVoiceEnabled and true or false
    )

    lustUpBossPullVoiceCheck:SetChecked(
        self.db.lustUpBossPullVoiceEnabled and true or false
    )

    if lustUpReadyVoiceBox then
        lustUpReadyVoiceBox:SetText(
            tostring(self.db.lustUpReadyVoiceText or "Lust up")
        )
    end

    if lustUpBossPullVoiceBox then
        lustUpBossPullVoiceBox:SetText(
            tostring(
                self.db.lustUpBossPullVoiceText
                or "Lust off cooldown"
            )
        )
    end

    lustUpOnlyInCombatCheck:SetChecked(
        self.db.lustUpOnlyInCombat and true or false
    )

    lustUpOnlyInInstanceCheck:SetChecked(
        self.db.lustUpOnlyInInstance and true or false
    )

    if moduleUI.lustShowDungeonsCheck then
        moduleUI.lustShowDungeonsCheck:SetChecked(
            self.db.lustUpShowInDungeons ~= false
        )
    end

    if moduleUI.lustShowRaidsCheck then
        moduleUI.lustShowRaidsCheck:SetChecked(
            self.db.lustUpShowInRaids ~= false
        )
    end

    if moduleUI.lustReadyAlphaSlider then
        moduleUI.lustReadyAlphaSlider:SetDisplayValue(
            tonumber(self.db.lustUpReadyAlpha) or 100
        )
    end

    if moduleUI.lustLockedAlphaSlider then
        moduleUI.lustLockedAlphaSlider:SetDisplayValue(
            tonumber(self.db.lustUpLockedAlpha) or 100
        )
    end

    if moduleUI.lustRequireAbilityCheck then
        moduleUI.lustRequireAbilityCheck:SetChecked(
            self.db.lustUpRequireLustAbility and true or false
        )
    end

    if moduleUI.lustAllowDrumsCheck then
        moduleUI.lustAllowDrumsCheck:SetChecked(
            self.db.lustUpAllowDrums and true or false
        )
    end

    if moduleUI.lustIndicatorClickableCheck then
        moduleUI.lustIndicatorClickableCheck:SetChecked(
            self.db.lustUpIndicatorClickable and true or false
        )
    end

    if moduleUI.lustReadyGlowCheck then
        moduleUI.lustReadyGlowCheck:SetChecked(
            self.db.lustUpReadyGlow and true or false
        )
    end

    if moduleUI.lustBuiltInDrumListText
        and self.GetBuiltInLustDrumListText then

        moduleUI.lustBuiltInDrumListText:SetText(
            self:GetBuiltInLustDrumListText()
        )
    end

    if moduleUI.lustCustomDrumListText
        and self.GetCustomLustDrumListText then

        moduleUI.lustCustomDrumListText:SetText(
            self:GetCustomLustDrumListText()
        )
        if moduleUI.RefreshLustCustomDrumListLayout then
            moduleUI.RefreshLustCustomDrumListLayout()
        end
    end

    lustUpUnlockCheck:SetChecked(
        self.db.lustUpUnlocked and true or false
    )

    lustUpModeButton:SetDisplayValue(
        self.db.lustUpDisplayMode or "ready"
    )

    if moduleUI.lustReadyChatButton then
        moduleUI.lustReadyChatButton:SetValue(
            self.db.lustUpReadyChatChannel or "OFF"
        )
    end

    lustUpSizeSlider:SetDisplayValue(
        tonumber(self.db.lustUpSize) or 48
    )

    if moduleUI.RefreshLustCustomLockoutList then
        moduleUI.RefreshLustCustomLockoutList()
    end
end

function BW:RefreshStatsOptions()
    moduleUI.RefreshSidebarButtons()
    if not moduleUI.statsPage or not self.db then
        return
    end

    if moduleUI.statsPageEnabledCheck then
        moduleUI.statsPageEnabledCheck:SetChecked(
            self.db.statsModuleEnabled and true or false
        )
    end

    if moduleUI.rootStatsEnabledCheck then
        moduleUI.rootStatsEnabledCheck:SetChecked(
            self.db.statsModuleEnabled and true or false
        )
    end

    if moduleUI.statsPanel and moduleUI.statsPanel.moduleStatus then
        moduleUI.statsPanel.moduleStatus:SetText(
            self.db.statsModuleEnabled
            and "|cff4d9fffEnabled|r"
            or "|cffff5555Disabled|r"
        )
    end

    moduleUI.statsUnlockCheck:SetChecked(
        self.db.statsUnlocked and true or false
    )

    moduleUI.statsShowCritCheck:SetChecked(
        self.db.statsShowCrit and true or false
    )
    moduleUI.statsShowHasteCheck:SetChecked(
        self.db.statsShowHaste and true or false
    )
    moduleUI.statsShowMasteryCheck:SetChecked(
        self.db.statsShowMastery and true or false
    )
    moduleUI.statsShowVersatilityCheck:SetChecked(
        self.db.statsShowVersatility and true or false
    )

    if moduleUI.statsCritColorButton then
        moduleUI.statsCritColorButton:SetDisplayValue(
            self.db.statsCritColor or { 1.00, 0.42, 0.35, 1 }
        )
    end
    if moduleUI.statsHasteColorButton then
        moduleUI.statsHasteColorButton:SetDisplayValue(
            self.db.statsHasteColor or { 0.35, 0.85, 0.45, 1 }
        )
    end
    if moduleUI.statsMasteryColorButton then
        moduleUI.statsMasteryColorButton:SetDisplayValue(
            self.db.statsMasteryColor or { 0.67, 0.48, 1.00, 1 }
        )
    end
    if moduleUI.statsVersatilityColorButton then
        moduleUI.statsVersatilityColorButton:SetDisplayValue(
            self.db.statsVersatilityColor or { 0.30, 0.72, 1.00, 1 }
        )
    end

    moduleUI.statsOnlyInCombatCheck:SetChecked(
        self.db.statsOnlyInCombat and true or false
    )
    moduleUI.statsOnlyOutOfCombatCheck:SetChecked(
        self.db.statsOnlyOutOfCombat and true or false
    )
    moduleUI.statsOnlyInInstanceCheck:SetChecked(
        self.db.statsOnlyInInstance and true or false
    )
    moduleUI.statsShowBackgroundCheck:SetChecked(
        self.db.statsShowBackground and true or false
    )

    moduleUI.statsFontSizeSlider:SetDisplayValue(
        tonumber(self.db.statsFontSize) or 14
    )

    moduleUI.statsOrientationButton:SetDisplayValue(
        self.db.statsOrientation or "horizontal"
    )

    local statsVertical = self.db.statsOrientation == "vertical"
    moduleUI.statsAlignButton:SetShown(not statsVertical)
    moduleUI.statsVerticalAlignButton:SetShown(statsVertical)
    moduleUI.statsAlignLabel:SetText(statsVertical and "Vertical alignment" or "Text alignment")
    moduleUI.statsAlignButton:SetDisplayValue(self.db.statsTextAlign or "center")
    moduleUI.statsVerticalAlignButton:SetDisplayValue(self.db.statsVerticalAlign or "middle")

    if moduleUI.statsPreviewText
        and self.SetStatsFontStringText then

        local align = tostring(
            self.db.statsTextAlign or "center"
        )

        if align ~= "left"
            and align ~= "right" then

            align = "center"
        end

        moduleUI.statsPreviewText:SetJustifyH(string.upper(align))
        moduleUI.statsPreviewText:SetJustifyV(
            statsVertical and string.upper(self.db.statsVerticalAlign or "middle") or "MIDDLE"
        )

        self:SetStatsFontStringText(
            moduleUI.statsPreviewText
        )
    end
end

function BW:RefreshSurvivalOptions()
    moduleUI.RefreshSidebarButtons()
    if not moduleUI.survivalPage or not self.db then
        return
    end

    if moduleUI.survivalPageEnabledCheck then
        moduleUI.survivalPageEnabledCheck:SetChecked(
            self.db.survivalModuleEnabled and true or false
        )
    end

    if moduleUI.rootSurvivalEnabledCheck then
        moduleUI.rootSurvivalEnabledCheck:SetChecked(
            self.db.survivalModuleEnabled and true or false
        )
    end

    if moduleUI.survivalPanel and moduleUI.survivalPanel.moduleStatus then
        moduleUI.survivalPanel.moduleStatus:SetText(
            self.db.survivalModuleEnabled
            and "|cff4d9fffModule enabled|r"
            or "|cffff5555Module disabled|r"
        )
    end

    -- Building the action rows queries spell/item metadata.  Keep that work
    -- completely out of PLAYER_LOGIN; populate it only while the Survival
    -- page is actually visible.
    if moduleUI.refreshSurvivalActionRows
        and moduleUI.survivalPanel
        and moduleUI.survivalPanel:IsVisible() then

        moduleUI.refreshSurvivalActionRows()
    end

    if moduleUI.survivalTriggerSlider then
        moduleUI.survivalTriggerSlider:SetDisplayValue(
            tonumber(self.db.survivalTriggerThreshold) or 30
        )
    end
    if moduleUI.survivalAlertTypeCheck then
        moduleUI.survivalAlertTypeCheck:SetChecked(
            self.db.survivalThresholdAlertType == "sound"
        )
    end

    if moduleUI.survivalSpeakActionNameCheck then
        moduleUI.survivalSpeakActionNameCheck:SetChecked(
            self.db.survivalSpeakActionName ~= false
        )
        moduleUI.survivalSpeakActionNameCheck:SetEnabled(
            self.db.survivalThresholdAlertType ~= "sound"
        )
    end

    if moduleUI.survivalTTSContinuousCheck then
        moduleUI.survivalTTSContinuousCheck:SetChecked(
            self.db.survivalTTSContinuous and true or false
        )
        moduleUI.survivalTTSContinuousCheck:SetEnabled(
            self.db.survivalThresholdAlertType ~= "sound"
        )
    end

    if moduleUI.survivalDeathSoundCheck then
        moduleUI.survivalDeathSoundCheck:SetChecked(
            self.db.survivalDeathSoundEnabled ~= false
        )
    end

    if moduleUI.survivalDeathSoundDropdown then
        moduleUI.survivalDeathSoundDropdown:SetValue(
            self.db.survivalDeathSound or "Quest Failed"
        )
        moduleUI.survivalDeathSoundDropdown:SetEnabledState(
            self.db.survivalDeathSoundEnabled ~= false
        )
    end

    if moduleUI.survivalDeathSoundTestButton then
        moduleUI.survivalDeathSoundTestButton:SetEnabled(
            self.db.survivalDeathSoundEnabled ~= false
        )
    end

    if moduleUI.survivalAlertSoundDropdown then
        moduleUI.survivalAlertSoundDropdown:SetValue(
            self.db.survivalAlertSound or "Air Horn"
        )
        moduleUI.survivalAlertSoundDropdown:SetEnabledState(
            self.db.survivalThresholdAlertType == "sound"
        )
    end
    if moduleUI.survivalAlertSoundTestButton then
        moduleUI.survivalAlertSoundTestButton:SetEnabled(
            self.db.survivalThresholdAlertType == "sound"
        )
    end

    if moduleUI.survivalTTSTextBox
        and not moduleUI.survivalTTSTextBox:HasFocus() then

        moduleUI.survivalTTSTextBox:SetText(
            tostring(self.db.survivalTTSText or "")
        )
    end

    if moduleUI.survivalUnlockCheck then
        moduleUI.survivalUnlockCheck:SetChecked(
            self.db.survivalUnlocked and true or false
        )
    end

    if moduleUI.survivalShowLabelCheck then
        moduleUI.survivalShowLabelCheck:SetChecked(
            self.db.survivalShowLabel ~= false
        )
    end

    if moduleUI.survivalShowAllReadyActionsCheck then
        moduleUI.survivalShowAllReadyActionsCheck:SetChecked(
            self.db.survivalShowAllReadyActions and true or false
        )
    end
    if moduleUI.survivalReadyActionsGrowthDropdown then
        moduleUI.survivalReadyActionsGrowthDropdown:SetValue(
            self.db.survivalReadyActionsGrowth or "right"
        )
        moduleUI.survivalReadyActionsGrowthDropdown:SetEnabledState(
            self.db.survivalShowAllReadyActions and true or false
        )
    end

    if moduleUI.survivalGlowCheck then
        moduleUI.survivalGlowCheck:SetChecked(
            self.db.survivalGlowEnabled ~= false
        )
    end

    if moduleUI.survivalOnlyCombatCheck then
        moduleUI.survivalOnlyCombatCheck:SetChecked(
            self.db.survivalOnlyInCombat and true or false
        )
    end

    if moduleUI.survivalOnlyInstanceCheck then
        moduleUI.survivalOnlyInstanceCheck:SetChecked(
            self.db.survivalOnlyInInstance and true or false
        )
    end

    if moduleUI.survivalIconSizeSlider then
        moduleUI.survivalIconSizeSlider:SetDisplayValue(
            tonumber(self.db.survivalIconSize) or 58
        )
    end

    if moduleUI.survivalDetectedText and self.GetSurvivalDetectedText then
        moduleUI.survivalDetectedText:SetText(
            self:GetSurvivalDetectedText()
        )
    end

    if moduleUI.survivalStatusText and self.GetSurvivalStatusText then
        moduleUI.survivalStatusText:SetText(
            self:GetSurvivalStatusText()
        )
    end
end

function BW:RefreshTalentLoadoutOptions()
    moduleUI.RefreshSidebarButtons()
    if not moduleUI.talentPage or not self.db then
        return
    end

    if moduleUI.talentPageEnabledCheck then
        moduleUI.talentPageEnabledCheck:SetChecked(
            self.db.talentLoadoutEnabled and true or false
        )
    end

    if moduleUI.rootTalentEnabledCheck then
        moduleUI.rootTalentEnabledCheck:SetChecked(
            self.db.talentLoadoutEnabled and true or false
        )
    end

    if moduleUI.talentPanel and moduleUI.talentPanel.moduleStatus then
        moduleUI.talentPanel.moduleStatus:SetText(
            self.db.talentLoadoutEnabled
            and "|cff4d9fffModule enabled|r"
            or "|cffff5555Module disabled|r"
        )
    end

    moduleUI.talentUnlockCheck:SetChecked(
        self.db.talentLoadoutUnlocked and true or false
    )

    moduleUI.talentShowSpecCheck:SetChecked(
        self.db.talentLoadoutShowSpec and true or false
    )
    moduleUI.talentShowNameCheck:SetChecked(
        self.db.talentLoadoutShowName and true or false
    )
    moduleUI.talentShowHeroCheck:SetChecked(
        self.db.talentLoadoutShowHero and true or false
    )
    moduleUI.talentShowBackgroundCheck:SetChecked(
        self.db.talentLoadoutShowBackground and true or false
    )

    moduleUI.talentFontSizeSlider:SetDisplayValue(
        tonumber(self.db.talentLoadoutFontSize) or 14
    )

    moduleUI.talentOrientationButton:SetDisplayValue(
        self.db.talentLoadoutOrientation or "vertical"
    )

    if moduleUI.talentPreviewText
        and self.GetTalentLoadoutDisplayText then

        moduleUI.talentPreviewText:SetText(
            self:GetTalentLoadoutDisplayText()
        )
    end
end

function BW:RefreshRaidFrameSpecOptions()
    moduleUI.RefreshSidebarButtons()
    if not self.db then return end

    local enabled = self.db.raidFrameSpecEnabled and true or false

    if moduleUI.raidSpecPageEnabledCheck then
        moduleUI.raidSpecPageEnabledCheck:SetChecked(enabled)
    end

    if moduleUI.rootRaidSpecEnabledCheck then
        moduleUI.rootRaidSpecEnabledCheck:SetChecked(enabled)
    end

    if moduleUI.raidSpecManageRaidCheck then
        moduleUI.raidSpecManageRaidCheck:SetChecked(
            self.db.raidFrameSpecManageRaid ~= false
        )
    end

    if moduleUI.raidSpecManagePartyCheck then
        moduleUI.raidSpecManagePartyCheck:SetChecked(
            self.db.raidFrameSpecManageParty ~= false
        )
    end

    local integrationOK, integrationText = false, "EllesmereUI Raid Frames is not loaded."
    if self.GetRaidFrameSpecIntegrationState then
        integrationOK, integrationText = self:GetRaidFrameSpecIntegrationState()
    end

    if moduleUI.raidSpecPanel and moduleUI.raidSpecPanel.moduleStatus then
        local status
        if not integrationOK then
            status = "|cffffcc55Ellesmere unavailable|r"
        elseif enabled then
            status = "|cff4d9fffModule enabled|r"
        else
            status = "|cffff5555Module disabled|r"
        end
        moduleUI.raidSpecPanel.moduleStatus:SetText(status)
    end

    if moduleUI.rootRaidSpecStatus then
        moduleUI.rootRaidSpecStatus:SetText(
            integrationOK and "|cff4d9fffEllesmere detected|r" or "|cffffcc55Ellesmere unavailable|r"
        )
    end

    if moduleUI.raidSpecIntegrationText then
        moduleUI.raidSpecIntegrationText:SetText(integrationText)
    end

    if moduleUI.raidSpecCurrentSpecText then
        local specID, specName

        if self.GetRaidFrameSpecCurrentSpec then
            specID, specName =
                self:GetRaidFrameSpecCurrentSpec()
        end

        moduleUI.raidSpecCurrentSpecText:SetText(
            specID
            and (
                tostring(specName)
                .. "  ("
                .. tostring(specID)
                .. ")"
            )
            or "No active specialization"
        )
    end

    if moduleUI.raidSpecSpecButtons
        and self.GetRaidFrameSpecEditSpec then

        local editSpecID =
            self:GetRaidFrameSpecEditSpec()

        for _, button in ipairs(
            moduleUI.raidSpecSpecButtons
        ) do
            SetButtonActiveState(
                button,
                button.specID == editSpecID
            )
        end
    end

    if moduleUI.raidSpecRaidPositionText and self.GetRaidFrameSpecCurrentRaidPositionText then
        moduleUI.raidSpecRaidPositionText:SetText(self:GetRaidFrameSpecCurrentRaidPositionText())
    end

    if moduleUI.raidSpecPartyPositionText and self.GetRaidFrameSpecCurrentPartyPositionText then
        moduleUI.raidSpecPartyPositionText:SetText(self:GetRaidFrameSpecCurrentPartyPositionText())
    end

    if moduleUI.raidSpecRaidLiveText and self.GetRaidFrameSpecLiveRaidContainerText then
        moduleUI.raidSpecRaidLiveText:SetText(self:GetRaidFrameSpecLiveRaidContainerText())
    end

    if moduleUI.raidSpecPartyLiveText and self.GetRaidFrameSpecLivePartyContainerText then
        moduleUI.raidSpecPartyLiveText:SetText(self:GetRaidFrameSpecLivePartyContainerText())
    end

    if moduleUI.raidSpecSavedListText and self.GetRaidFrameSpecSavedListText then
        moduleUI.raidSpecSavedListText:SetText(self:GetRaidFrameSpecSavedListText())
    end

    if moduleUI.raidSpecStatusText and self.GetRaidFrameSpecStatusText then
        moduleUI.raidSpecStatusText:SetText(self:GetRaidFrameSpecStatusText())
    end

    if moduleUI.raidSpecRaidMoverButton then
        moduleUI.raidSpecRaidMoverButton:SetText(
            self.IsRaidFrameSpecMoverShown and self:IsRaidFrameSpecMoverShown() and "Hide mover" or "Show mover"
        )
    end

    if moduleUI.raidSpecPartyMoverButton then
        moduleUI.raidSpecPartyMoverButton:SetText(
            self.IsPartyFrameSpecMoverShown and self:IsPartyFrameSpecMoverShown() and "Hide mover" or "Show mover"
        )
    end

    local raidCustomEnabled =
        self.GetRaidFrameSpecCustomEnabled
        and self:GetRaidFrameSpecCustomEnabled()
        or false

    local partyCustomEnabled =
        self.GetPartyFrameSpecCustomEnabled
        and self:GetPartyFrameSpecCustomEnabled()
        or false

    if moduleUI.raidSpecRaidCustomCheck then
        moduleUI.raidSpecRaidCustomCheck:SetChecked(raidCustomEnabled)
    end

    if moduleUI.raidSpecPartyCustomCheck then
        moduleUI.raidSpecPartyCustomCheck:SetChecked(partyCustomEnabled)
    end

    if moduleUI.raidSpecPartyOrientationButton then
        moduleUI.raidSpecPartyOrientationButton:SetDisplayValue(
            self.GetPartyFrameSpecOrientation
            and self:GetPartyFrameSpecOrientation()
            or "vertical"
        )
    end

    if moduleUI.raidSpecRaidOrientationButton then
        moduleUI.raidSpecRaidOrientationButton:SetDisplayValue(
            self.GetRaidFrameSpecOrientation
            and self:GetRaidFrameSpecOrientation()
            or "vertical"
        )
    end

    if moduleUI.raidSpecRaidScaleSlider then
        moduleUI.raidSpecRaidScaleSlider:SetDisplayValue(
            self.GetRaidFrameSpecScaleValue
            and self:GetRaidFrameSpecScaleValue()
            or 100
        )
    end

    if moduleUI.raidSpecPartyScaleSlider then
        moduleUI.raidSpecPartyScaleSlider:SetDisplayValue(
            self.GetPartyFrameSpecScaleValue
            and self:GetPartyFrameSpecScaleValue()
            or 100
        )
    end

    local function SetSpecControlEnabled(control, state)
        if not control then return end

        if state then
            if control.Enable then control:Enable() end
            control:SetAlpha(1)
        else
            if control.Disable then control:Disable() end
            control:SetAlpha(0.45)
        end

        if control.ValueBox then
            if control.EnableMouseWheel then
                control:EnableMouseWheel(state and true or false)
            end

            if state then
                if control.ValueBox.Enable then control.ValueBox:Enable() end
                control.ValueBox:SetAlpha(1)
            else
                if control.ValueBox.Disable then control.ValueBox:Disable() end
                control.ValueBox:SetAlpha(0.45)
            end
        end
    end

    SetSpecControlEnabled(moduleUI.raidSpecRaidOrientationButton, raidCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecRaidScaleSlider, raidCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecRaidMoverButton, raidCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecRaidSaveButton, raidCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecRaidApplyButton, raidCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecRaidClearButton, raidCustomEnabled)

    SetSpecControlEnabled(moduleUI.raidSpecPartyOrientationButton, partyCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecPartyScaleSlider, partyCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecPartyMoverButton, partyCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecPartySaveButton, partyCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecPartyApplyButton, partyCustomEnabled)
    SetSpecControlEnabled(moduleUI.raidSpecPartyClearButton, partyCustomEnabled)

end

function BW:RefreshModuleOptionStates()
    moduleUI.RefreshSidebarButtons()
    if rootBuffEnabledCheck then
        rootBuffEnabledCheck:SetChecked(
            self.db.buffWhitelistModuleEnabled ~= false
        )
    end

    if buffPageEnabledCheck then
        buffPageEnabledCheck:SetChecked(
            self.db.buffWhitelistModuleEnabled ~= false
        )
    end

    if rootLustEnabledCheck then
        rootLustEnabledCheck:SetChecked(
            self.db.lustUpEnabled and true or false
        )
    end

    if moduleUI.rootStatsEnabledCheck then
        moduleUI.rootStatsEnabledCheck:SetChecked(
            self.db.statsModuleEnabled and true or false
        )
    end

    if moduleUI.rootTalentEnabledCheck then
        moduleUI.rootTalentEnabledCheck:SetChecked(
            self.db.talentLoadoutEnabled and true or false
        )
    end

    if moduleUI.rootRaidSpecEnabledCheck then
        moduleUI.rootRaidSpecEnabledCheck:SetChecked(
            self.db.raidFrameSpecEnabled and true or false
        )
    end

    if moduleUI.rootSurvivalEnabledCheck then
        moduleUI.rootSurvivalEnabledCheck:SetChecked(
            self.db.survivalModuleEnabled and true or false
        )
    end

    if panel.moduleStatus then
        panel.moduleStatus:SetText(
            self.db.buffWhitelistModuleEnabled ~= false
            and "|cff4d9fffModule enabled|r"
            or "|cffff5555Module disabled|r"
        )
    end

    focusCheck:SetChecked(
        self.db.applyToFocus and true or false
    )
end

function BW:RefreshAuraFilterOptionStates()
    onlyMyBuffsCheck:SetChecked(
        self.db.onlyMyBuffs and true or false
    )

    onlyMyDebuffsCheck:SetChecked(
        self.db.onlyMyDebuffs and true or false
    )

    useBuffFilterCheck:SetChecked(
        self.db.useBuffFilter and true or false
    )

    useDebuffFilterCheck:SetChecked(
        self.db.useDebuffFilter and true or false
    )

    buffMinePlusWhitelistCheck:SetChecked(
        self.db.buffMinePlusWhitelist and true or false
    )

    debuffMinePlusWhitelistCheck:SetChecked(
        self.db.debuffMinePlusWhitelist and true or false
    )

    if self.db.buffMinePlusWhitelist then
        onlyMyBuffsCheck:SetChecked(true)
        onlyMyBuffsCheck:Disable()
        useBuffFilterCheck:Disable()
    else
        onlyMyBuffsCheck:Enable()
        useBuffFilterCheck:Enable()
    end

    if self.db.debuffMinePlusWhitelist then
        onlyMyDebuffsCheck:SetChecked(true)
        onlyMyDebuffsCheck:Disable()
        useDebuffFilterCheck:Disable()
    else
        onlyMyDebuffsCheck:Enable()
        useDebuffFilterCheck:Enable()
    end

    buffSortButton:SetDisplayValue(
        self.db.buffSortMode or "default"
    )

    debuffSortButton:SetDisplayValue(
        self.db.debuffSortMode or "unitframe"
    )

    hidePermanentBuffsCheck:SetChecked(
        self.db.hidePermanentBuffs and true or false
    )

    hidePermanentDebuffsCheck:SetChecked(
        self.db.hidePermanentDebuffs and true or false
    )

    showImportantBossBuffsCheck:SetChecked(
        self.db.showImportantBossBuffs and true or false
    )

    showDebuffRedBorderCheck:SetChecked(
        self.db.showDebuffRedBorder and true or false
    )

    if editFilterButton and editBlacklistButton then
        editFilterButton:SetEnabled(
            auraEditMode ~= "filter"
        )

        editBlacklistButton:SetEnabled(
            auraEditMode ~= "blacklist"
        )
    end

    if auraListMode == "target" then
        if self.QueueTargetAuraRefresh then
            self:QueueTargetAuraRefresh()
        else
            self:RefreshTargetAuras()
        end
    else
        RebuildRows()
    end
end

function BW:RefreshTextTooltipOptionStates()
    hideBuffTooltipsCheck:SetChecked(
        self.db.hideBuffTooltips and true or false
    )

    hideDebuffTooltipsCheck:SetChecked(
        self.db.hideDebuffTooltips and true or false
    )

    showBuffDurationCheck:SetChecked(
        self.db.showBuffDuration and true or false
    )

    buffDurationSizeBox:SetDisplayValue(
        tonumber(self.db.buffDurationSize) or 11
    )

    buffDurationFontButton:SetDisplayValue(
        self.db.buffDurationFont or "FRIZ"
    )

    buffDurationColorButton:SetDisplayValue(
        self.db.buffDurationColor or { 1, 1, 1, 1 }
    )

    buffDurationOutlineButton:SetDisplayValue(
        self.db.buffDurationOutline or "OUTLINE"
    )

    hideBuffLongDurationTextCheck:SetChecked(
        self.db.hideBuffLongDurationText and true or false
    )

    buffLongDurationTextMinutesBox:SetDisplayValue(
        tonumber(self.db.buffLongDurationTextMinutes) or 60
    )

    showBuffStacksCheck:SetChecked(
        self.db.showBuffStacks and true or false
    )

    buffStackSizeBox:SetDisplayValue(
        tonumber(self.db.buffStackSize) or 11
    )

    buffStackFontButton:SetDisplayValue(
        self.db.buffStackFont or "FRIZ"
    )

    buffStackColorButton:SetDisplayValue(
        self.db.buffStackColor or { 1, 1, 1, 1 }
    )

    buffStackOutlineButton:SetDisplayValue(
        self.db.buffStackOutline or "OUTLINE"
    )

    showDebuffDurationCheck:SetChecked(
        self.db.showDebuffDuration and true or false
    )

    debuffDurationSizeBox:SetDisplayValue(
        tonumber(self.db.debuffDurationSize) or 11
    )

    debuffDurationFontButton:SetDisplayValue(
        self.db.debuffDurationFont or "FRIZ"
    )

    debuffDurationColorButton:SetDisplayValue(
        self.db.debuffDurationColor or { 1, 1, 1, 1 }
    )

    debuffDurationOutlineButton:SetDisplayValue(
        self.db.debuffDurationOutline or "OUTLINE"
    )

    hideDebuffLongDurationTextCheck:SetChecked(
        self.db.hideDebuffLongDurationText and true or false
    )

    debuffLongDurationTextMinutesBox:SetDisplayValue(
        tonumber(self.db.debuffLongDurationTextMinutes) or 60
    )

    showDebuffStacksCheck:SetChecked(
        self.db.showDebuffStacks and true or false
    )

    debuffStackSizeBox:SetDisplayValue(
        tonumber(self.db.debuffStackSize) or 11
    )

    debuffStackFontButton:SetDisplayValue(
        self.db.debuffStackFont or "FRIZ"
    )

    debuffStackColorButton:SetDisplayValue(
        self.db.debuffStackColor or { 1, 1, 1, 1 }
    )

    debuffStackOutlineButton:SetDisplayValue(
        self.db.debuffStackOutline or "OUTLINE"
    )
end

function BW:RefreshLayoutOptionStates()
    previewCheck:SetChecked(self.db.showLayoutPreview and true or false)

    iconSizeSlider:SetDisplayValue(
        tonumber(self.db.iconSize) or 18
    )

    buffXSlider:SetDisplayValue(
        tonumber(self.db.buffOffsetX) or 0
    )

    buffYSlider:SetDisplayValue(
        tonumber(self.db.buffOffsetY) or 29
    )

    debuffXSlider:SetDisplayValue(
        tonumber(self.db.debuffOffsetX) or 0
    )

    debuffYSlider:SetDisplayValue(
        tonumber(self.db.debuffOffsetY) or 0
    )

    buffColumnsBox:SetDisplayValue(
        tonumber(self.db.buffColumns) or 5
    )

    buffRowsBox:SetDisplayValue(
        tonumber(self.db.buffRows) or 1
    )

    debuffColumnsBox:SetDisplayValue(
        tonumber(self.db.debuffColumns) or 5
    )

    debuffRowsBox:SetDisplayValue(
        tonumber(self.db.debuffRows) or 1
    )

    UpdateDirectionButtons()
    UpdateAnchorModeButtons()
end

function BW:RefreshMinimapButtonOptions()
    if not self.db then
        return
    end

    if moduleUI.minimapButtonCheck then
        moduleUI.minimapButtonCheck:SetChecked(
            self.db.minimapButtonShown ~= false
        )
    end
end

function BW:RefreshOptions()
    -- All refresh routines expect their controls to exist. During construction
    -- the panel shell is created before its three pages, so defer refreshes
    -- until those pages have finished building.
    if not panel or not self.db
        or not layoutPage or not auraPage or not textPage then
        return
    end

    self:RefreshModuleOptionStates()
    self:RefreshAuraFilterOptionStates()
    self:RefreshTextTooltipOptionStates()
    self:RefreshLayoutOptionStates()
    self:RefreshLustUpOptions()
    self:RefreshSurvivalOptions()
    self:RefreshRaidFrameSpecOptions()
    self:RefreshMinimapButtonOptions()
end

local function BuildRootPanel()
    rootPanel = CreateFrame("Frame", nil, helperContent)
    rootPanel:SetAllPoints(helperContent)

    local standaloneModuleSettings = {
        buff = { global = "KayliiTargetAurasModule", db = "KayliiTargetAurasDB", key = "buffWhitelistModuleEnabled", setter = "SetBuffWhitelistModuleEnabled" },
        lust = { global = "KayliiLustUpModule", db = "KayliiLustDB", key = "lustUpEnabled", apply = "ApplyLustUpSettings" },
        stats = { global = "KayliiStatsDisplayModule", db = "KayliiStatsDB", key = "statsModuleEnabled", setter = "SetStatsModuleEnabled" },
        talent = { global = "KayliiTalentLoadoutModule", db = "KayliiTalentDB", key = "talentLoadoutEnabled", setter = "SetTalentLoadoutEnabled" },
        raidspec = { global = "KayliiRaidFrameSpecModule", db = "KayliiRaidSpecDB", key = "raidFrameSpecEnabled", setter = "SetRaidFrameSpecEnabled" },
        survival = { global = "KayliiSurvivalHelperModule", db = "KayliiSurvivalDB", key = "survivalModuleEnabled", setter = "SetSurvivalModuleEnabled" },
    }

    local function SetStandaloneModuleEnabled(view, value, forceApply)
        local info = standaloneModuleSettings[view]
        if not info then return end

        value = value and true or false
        local standalone = _G[info.global]
        local db = standalone and standalone.db or _G[info.db]
        if type(db) ~= "table" then return end
        if db[info.key] == value and not forceApply then return end

        if standalone and info.setter and type(standalone[info.setter]) == "function" then
            standalone[info.setter](standalone, value)
        else
            db[info.key] = value
            if standalone and info.apply and type(standalone[info.apply]) == "function" then
                standalone[info.apply](standalone)
            end
        end
    end
    moduleUI.SetStandaloneModuleEnabled = SetStandaloneModuleEnabled

    -- The dashboard cards use a one-pixel edge instead of the shared
    -- tooltip-style frame, which gives them a flatter, quieter surface.
    local dashboardCardBackdrop = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    }

    local title = Label(rootPanel, "Your modules", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", rootPanel, "TOPLEFT", 20, -18)
    SetFontColor(title, THEME.text)

    moduleUI.rootModuleCountText = Label(
        rootPanel,
        "",
        "GameFontHighlight"
    )
    moduleUI.rootModuleCountText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    SetFontColor(moduleUI.rootModuleCountText, THEME.subtext)

    local exportProfile = CreateFrame(
        "Button",
        nil,
        rootPanel,
        "UIPanelButtonTemplate"
    )
    exportProfile:SetSize(112, 28)
    exportProfile:SetText("Export profile")
    exportProfile:SetScript("OnClick", function()
        moduleUI.ShowProfileTransferDialog("export")
    end)
    SkinButton(exportProfile)

    local importProfile = CreateFrame(
        "Button",
        nil,
        rootPanel,
        "UIPanelButtonTemplate"
    )
    importProfile:SetSize(112, 28)
    importProfile:SetPoint("TOPRIGHT", rootPanel, "TOPRIGHT", -18, -18)
    exportProfile:SetPoint("RIGHT", importProfile, "LEFT", -8, 0)
    importProfile:SetText("Import profile")
    importProfile:SetScript("OnClick", function()
        moduleUI.ShowProfileTransferDialog("import")
    end)
    SkinButton(importProfile)

    local moduleSettingsButtons = {}
    local moduleStateLabels = {}
    moduleUI.rootModuleSettingsButtons = moduleSettingsButtons

    local function NewCard()
        local card = CreateFrame("Frame", nil, rootPanel, "BackdropTemplate")
        ApplyBackdrop(card, THEME.section, THEME.border, dashboardCardBackdrop)
        return card
    end

    local function ModuleCard(titleText, description, iconPath, column, row, view, toggleCallback)
        local card = NewCard()
        local y = 88 + ((row - 1) * 136)
        if column == 1 then
            card:SetPoint("TOPLEFT", rootPanel, "TOPLEFT", 16, -y)
            card:SetPoint("TOPRIGHT", rootPanel, "TOP", -8, -y)
        else
            card:SetPoint("TOPLEFT", rootPanel, "TOP", 8, -y)
            card:SetPoint("TOPRIGHT", rootPanel, "TOPRIGHT", -16, -y)
        end
        card:SetHeight(124)

        local iconBox = CreateFrame("Frame", nil, card, "BackdropTemplate")
        iconBox:SetSize(76, 76)
        iconBox:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -16)
        ApplyBackdrop(iconBox, THEME.panelAlt, THEME.border, dashboardCardBackdrop)

        local icon = iconBox:CreateTexture(nil, "ARTWORK")
        icon:SetSize(58, 58)
        icon:SetPoint("CENTER", iconBox, "CENTER")
        icon:SetTexture(iconPath)
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetVertexColor(0.88, 0.94, 1, 1)

        local controlColumn = CreateFrame("Frame", nil, card)
        controlColumn:SetSize(112, 112)
        controlColumn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -17)

        local moduleTitle = Label(card, titleText, "GameFontHighlightLarge")
        moduleTitle:SetPoint("TOPLEFT", iconBox, "TOPRIGHT", 16, -5)
        moduleTitle:SetPoint("TOPRIGHT", controlColumn, "TOPLEFT", -12, -5)
        moduleTitle:SetJustifyH("LEFT")
        SetFontColor(moduleTitle, THEME.text)

        local installed = Label(card, "Installed", "GameFontHighlight")
        installed:SetPoint("TOPLEFT", moduleTitle, "BOTTOMLEFT", 0, -2)
        installed:SetPoint("TOPRIGHT", moduleTitle, "BOTTOMRIGHT", 0, -2)
        installed:SetJustifyH("LEFT")
        SetFontColor(installed, THEME.subtext)

        local details = Label(card, description, "GameFontHighlight")
        details:SetPoint("TOPLEFT", installed, "BOTTOMLEFT", 0, -6)
        details:SetPoint("TOPRIGHT", installed, "BOTTOMRIGHT", 0, -6)
        details:SetJustifyH("LEFT")
        SetFontColor(details, THEME.subtext)

        local toggle = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
        toggle:SetPoint("TOPRIGHT", controlColumn, "TOPRIGHT", 0, 0)
        toggle:SetScript("OnClick", function(self)
            toggleCallback(self:GetChecked() and true or false)
            if moduleUI.UpdateRootModuleDashboard then
                moduleUI.UpdateRootModuleDashboard()
            end
        end)
        SkinCheckbox(toggle)

        local state = Label(card, "Enabled", "GameFontHighlight")
        state:SetPoint("TOPRIGHT", toggle, "BOTTOMRIGHT", 0, -4)
        state:SetWidth(112)
        state:SetJustifyH("RIGHT")
        SetFontColor(state, THEME.subtext)

        local settings = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        settings:SetSize(112, 28)
        settings:SetPoint("TOP", controlColumn, "TOP", 0, -65)
        settings:SetText("Settings")
        settings:SetScript("OnClick", function()
            SetHelperView(view)
        end)
        SkinButton(settings)

        moduleSettingsButtons[view] = settings
        moduleStateLabels[view] = state
        return toggle, details
    end

    rootBuffEnabledCheck = ModuleCard(
        "Buff White List",
        "Choose which target and focus auras appear.",
        "Interface\\AddOns\\KayliiHelper\\Media\\NavBuff.tga",
        1, 1, "buff",
        function(value)
            if BW.SetBuffWhitelistModuleEnabled then
                BW:SetBuffWhitelistModuleEnabled(value)
            else
                BW.db.buffWhitelistModuleEnabled = value
            end
            SetStandaloneModuleEnabled("buff", value, true)
            BW:RefreshOptions()
        end
    )

    rootLustEnabledCheck = ModuleCard(
        "Lust Up",
        "Track lust readiness and configure alerts.",
        "Interface\\AddOns\\KayliiHelper\\Media\\NavLust.tga",
        2, 1, "lust",
        function(value)
            BW.db.lustUpEnabled = value
            if BW.ApplyLustUpSettings then BW:ApplyLustUpSettings() end
            SetStandaloneModuleEnabled("lust", value, true)
            BW:RefreshLustUpOptions()
            BW:RefreshOptions()
        end
    )

    moduleUI.rootStatsEnabledCheck = ModuleCard(
        "My Stats",
        "Display Crit, Haste, Mastery and Versatility.",
        "Interface\\AddOns\\KayliiHelper\\Media\\NavStats.tga",
        1, 2, "stats",
        function(value)
            if BW.SetStatsModuleEnabled then BW:SetStatsModuleEnabled(value) end
            SetStandaloneModuleEnabled("stats", value, true)
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.rootTalentEnabledCheck = ModuleCard(
        "Talent Loadout",
        "Display your spec, loadout and Hero Talent tree.",
        "Interface\\AddOns\\KayliiHelper\\Media\\NavTalent.tga",
        2, 2, "talent",
        function(value)
            if BW.SetTalentLoadoutEnabled then BW:SetTalentLoadoutEnabled(value) end
            SetStandaloneModuleEnabled("talent", value, true)
            BW:RefreshTalentLoadoutOptions()
        end
    )

    moduleUI.rootRaidSpecEnabledCheck, moduleUI.rootRaidSpecDescription = ModuleCard(
        "Raid Frame Spec",
        "Save raid and party frame positions per spec.",
        "Interface\\AddOns\\KayliiHelper\\Media\\NavRaid.tga",
        1, 3, "raidspec",
        function(value)
            if BW.SetRaidFrameSpecEnabled then BW:SetRaidFrameSpecEnabled(value) end
            SetStandaloneModuleEnabled("raidspec", value, true)
            BW:RefreshRaidFrameSpecOptions()
        end
    )

    moduleUI.rootRaidSpecStatus = Label(rootPanel, "", "GameFontDisableSmall")
    moduleUI.rootRaidSpecStatus:SetPoint(
        "BOTTOMLEFT",
        moduleUI.rootRaidSpecDescription,
        "BOTTOMLEFT",
        0,
        -2
    )
    moduleUI.rootRaidSpecStatus:SetWidth(220)
    moduleUI.rootRaidSpecStatus:SetJustifyH("LEFT")

    moduleUI.rootSurvivalEnabledCheck = ModuleCard(
        "Survival Helper",
        "Suggest defensives, Healthstones and potions.",
        "Interface\\AddOns\\KayliiHelper\\Media\\NavSurvival.tga",
        2, 3, "survival",
        function(value)
            if BW.SetSurvivalModuleEnabled then
                BW:SetSurvivalModuleEnabled(value)
            end
            SetStandaloneModuleEnabled("survival", value, true)
            BW:RefreshSurvivalOptions()
        end
    )

    moduleUI.UpdateRootModuleDashboard = function()
        if not BW.db or not moduleUI.rootModuleCountText then return end
        local states = {
            buff = BW.db.buffWhitelistModuleEnabled ~= false,
            lust = BW.db.lustUpEnabled and true or false,
            stats = BW.db.statsModuleEnabled and true or false,
            talent = BW.db.talentLoadoutEnabled and true or false,
            raidspec = BW.db.raidFrameSpecEnabled and true or false,
            survival = BW.db.survivalModuleEnabled and true or false,
        }
        local enabledCount = 0
        for view, enabled in pairs(states) do
            if enabled then enabledCount = enabledCount + 1 end
            if moduleStateLabels[view] then
                moduleStateLabels[view]:SetText(enabled and "Enabled" or "Disabled")
                SetFontColor(moduleStateLabels[view], enabled and THEME.subtext or THEME.muted)
            end
            if moduleSettingsButtons[view] then
                moduleSettingsButtons[view]:SetEnabled(enabled)
            end
        end
        moduleUI.rootModuleCountText:SetText(
            tostring(enabledCount) .. " enabled • 6 installed"
        )
    end

    local launcherCard = NewCard()
    launcherCard:SetPoint("TOPLEFT", rootPanel, "TOPLEFT", 16, -504)
    launcherCard:SetPoint("TOPRIGHT", rootPanel, "TOPRIGHT", -16, -504)
    launcherCard:SetHeight(76)

    local launcherTitle = Label(launcherCard, "Minimap Launcher", "GameFontNormalLarge")
    launcherTitle:SetPoint("TOPLEFT", launcherCard, "TOPLEFT", 18, -12)
    SetFontColor(launcherTitle, THEME.text)

    moduleUI.minimapButtonCheck = Checkbox(
        launcherCard,
        "Show Kaylii Helper minimap button",
        14,
        -40,
        function(value)
            if BW.SetMinimapButtonShown then
                BW:SetMinimapButtonShown(value)
            end
        end
    )

    local resetMinimap = CreateFrame("Button", nil, launcherCard, "UIPanelButtonTemplate")
    resetMinimap:SetSize(150, 28)
    resetMinimap:SetPoint("RIGHT", launcherCard, "RIGHT", -18, 0)
    resetMinimap:SetText("Reset minimap position")
    resetMinimap:SetScript("OnClick", function()
        if BW.ResetMinimapButtonPosition then
            BW:ResetMinimapButtonPosition()
        end
    end)
    SkinButton(resetMinimap)

    rootPanel:SetScript("OnShow", function()
        if not BW.db then
            return
        end

        rootBuffEnabledCheck:SetChecked(
            BW.db.buffWhitelistModuleEnabled ~= false
        )
        rootLustEnabledCheck:SetChecked(
            BW.db.lustUpEnabled and true or false
        )
        moduleUI.rootStatsEnabledCheck:SetChecked(
            BW.db.statsModuleEnabled and true or false
        )
        moduleUI.rootTalentEnabledCheck:SetChecked(
            BW.db.talentLoadoutEnabled and true or false
        )
        moduleUI.rootRaidSpecEnabledCheck:SetChecked(
            BW.db.raidFrameSpecEnabled and true or false
        )
        moduleUI.rootSurvivalEnabledCheck:SetChecked(
            BW.db.survivalModuleEnabled and true or false
        )

        -- Keep the standalone 2.0 module in step with the dashboard switch,
        -- including when the dashboard is opened after a previous toggle.
        SetStandaloneModuleEnabled("buff", BW.db.buffWhitelistModuleEnabled ~= false)
        SetStandaloneModuleEnabled("lust", BW.db.lustUpEnabled and true or false)
        SetStandaloneModuleEnabled("stats", BW.db.statsModuleEnabled and true or false)
        SetStandaloneModuleEnabled("talent", BW.db.talentLoadoutEnabled and true or false)
        SetStandaloneModuleEnabled("raidspec", BW.db.raidFrameSpecEnabled and true or false)
        SetStandaloneModuleEnabled("survival", BW.db.survivalModuleEnabled and true or false)

        BW:RefreshRaidFrameSpecOptions()
        BW:RefreshMinimapButtonOptions()
        moduleUI.UpdateRootModuleDashboard()
    end)
end

local function BuildPanelShell()
    panel = CreateFrame("Frame", nil, helperContent)
    panel:SetAllPoints(helperContent)

    local title = Label(
        panel,
        "Buff White List",
        "GameFontNormalLarge"
    )
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -18)
    SetFontColor(title, THEME.text)

    local moduleStatus = Label(
        panel,
        "",
        "GameFontDisableSmall"
    )
    moduleStatus:SetPoint(
        "TOPRIGHT",
        panel,
        "TOPRIGHT",
        -18,
        -22
    )
    moduleStatus:SetJustifyH("RIGHT")
    panel.moduleStatus = moduleStatus

    buffPageEnabledCheck = Checkbox(
        panel,
        "Enable Buff White List module",
        16,
        -68,
        function(value)
            if BW.SetBuffWhitelistModuleEnabled then
                BW:SetBuffWhitelistModuleEnabled(value)
            else
                BW.db.buffWhitelistModuleEnabled = value
            end

            BW:RefreshOptions()
        end
    )

    local desc = Label(
        panel,
        "Control target and focus auras.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)
    moduleUI.ApplyModuleHeader(
        panel, title, desc, buffPageEnabledCheck, moduleStatus,
        "Interface\\AddOns\\KayliiHelper\\Media\\NavBuff.tga"
    )
    local buffDependency = Label(panel, "Uses Blizzard default target / focus frames.", "GameFontHighlightSmall")
    buffDependency:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -2)
    SetFontColor(buffDependency, THEME.accentHover)

    layoutTab = CreateFrame(
        "Button",
        nil,
        panel,
        "UIPanelButtonTemplate"
    )
    layoutTab:SetSize(130, 28)
    layoutTab:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        16,
        -100
    )
    layoutTab:SetText("Layout")
    layoutTab:SetScript("OnClick", function()
        SetMainView("layout")
    end)

    auraTab = CreateFrame(
        "Button",
        nil,
        panel,
        "UIPanelButtonTemplate"
    )
    auraTab:SetSize(130, 28)
    auraTab:SetPoint("LEFT", layoutTab, "RIGHT", 8, 0)
    auraTab:SetText("Aura Filters")
    auraTab:SetScript("OnClick", function()
        SetMainView("auras")
    end)

    textTab = CreateFrame(
        "Button",
        nil,
        panel,
        "UIPanelButtonTemplate"
    )
    textTab:SetSize(150, 28)
    textTab:SetPoint("LEFT", auraTab, "RIGHT", 8, 0)
    textTab:SetText("Text & Tooltips")
    textTab:SetScript("OnClick", function()
        SetMainView("text")
    end)

    SkinButton(layoutTab)
    SkinButton(auraTab)
    SkinButton(textTab)
    StyleWindowPanels()
end

local function BuildLayoutPage()
    layoutPage = CreateFrame("Frame", nil, panel)
    layoutPage:Hide()
    layoutPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -132)
    layoutPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)

    local controlBar = CreateFrame("Frame", nil, layoutPage, "BackdropTemplate")
    controlBar:SetPoint("TOPLEFT", layoutPage, "TOPLEFT", 10, -8)
    controlBar:SetPoint("TOPRIGHT", layoutPage, "TOPRIGHT", -10, -8)
    controlBar:SetHeight(58)
    ApplyBackdrop(controlBar, THEME.section, THEME.border, THEME.flatSectionBackdrop)

    focusCheck = Checkbox(
        controlBar,
        "Apply to focus",
        0,
        0,
        function(value)
            BW.db.applyToFocus = value
            BW:SetupFocusFrame()
        end
    )
    previewCheck = Checkbox(
        controlBar,
        "Show draggable preview",
        0,
        0,
        function(value)
            BW.db.showLayoutPreview = value
            BW:RefreshLayoutPreview()
        end
    )
    local function PlaceToggle(check, left, right)
        check.Label:ClearAllPoints()
        check.Label:SetPoint("LEFT", controlBar, "LEFT", left, 0)
        check.Label:SetPoint("RIGHT", check, "LEFT", -8, 0)
        check.Label:SetJustifyH("LEFT")
        check:ClearAllPoints()
        check:SetPoint("RIGHT", controlBar, "LEFT", right, 0)
    end
    PlaceToggle(focusCheck, 16, 225)
    PlaceToggle(previewCheck, 250, 493)

    iconSizeSlider = Slider(
        controlBar,
        "Icon size",
        520,
        -9,
        194,
        12,
        36,
        1,
        function(value)
            return string.format("%d px", value)
        end,
        function(value)
            BW.db.iconSize = value
            BW:RefreshPresentation()
        end
    )

    local buffPanel = CreateSection(layoutPage, 10, -78, 400, 246, "Buff grid")
    buffPanel:ClearAllPoints()
    buffPanel:SetPoint("TOPLEFT", layoutPage, "TOPLEFT", 10, -78)
    buffPanel:SetPoint("TOPRIGHT", layoutPage, "TOP", -6, -78)
    buffPanel:SetHeight(270)

    local debuffPanel = CreateSection(layoutPage, 10, -78, 400, 246, "Debuff grid")
    debuffPanel:ClearAllPoints()
    debuffPanel:SetPoint("TOPLEFT", layoutPage, "TOP", 6, -78)
    debuffPanel:SetPoint("TOPRIGHT", layoutPage, "TOPRIGHT", -10, -78)
    debuffPanel:SetHeight(270)

    buffXSlider = NumberBox(
        buffPanel, "X offset", 16, -60, -300, 400,
        function(value)
            BW.db.buffOffsetX = value
            BW:RefreshPresentation()
        end
    )
    buffYSlider = NumberBox(
        buffPanel, "Y offset", 224, -60, -250, 300,
        function(value)
            BW.db.buffOffsetY = value
            BW:RefreshPresentation()
        end
    )
    buffColumnsBox = NumberBox(
        buffPanel, "Columns", 16, -106, 1, 10,
        function(value)
            BW.db.buffColumns = value
            BW:RefreshAllContainers()
        end
    )
    buffRowsBox = NumberBox(
        buffPanel, "Rows", 224, -106, 1, 10,
        function(value)
            BW.db.buffRows = value
            BW:RefreshAllContainers()
        end
    )

    local function AlignNumberPair(first, second, parent, y)
        first.Label:ClearAllPoints()
        first.Label:SetPoint("LEFT", parent, "TOPLEFT", 16, y)
        first:ClearAllPoints()
        first:SetSize(76, 24)
        first:SetPoint("RIGHT", parent, "TOP", -10, y)

        second.Label:ClearAllPoints()
        second.Label:SetPoint("LEFT", parent, "TOP", 8, y)
        second:ClearAllPoints()
        second:SetSize(76, 24)
        second:SetPoint("RIGHT", parent, "TOPRIGHT", -16, y)
    end
    AlignNumberPair(buffXSlider, buffYSlider, buffPanel, -64)
    AlignNumberPair(buffColumnsBox, buffRowsBox, buffPanel, -112)

    local buffHorizontal = Label(buffPanel, "Horizontal:", "GameFontHighlight")
    buffHorizontal:SetPoint("LEFT", buffPanel, "TOPLEFT", 16, -164)
    moduleUI.buffGrowHorizontalDropdown = moduleUI.CreateChoiceDropdown(
        buffPanel, 0, 0, 250,
        {
            { key = "left", label = "Left" },
            { key = "right", label = "Right" },
        },
        function(value)
            BW.db.buffGrowLeft = value == "left"
            UpdateDirectionButtons()
            BW:RefreshPresentation()
        end
    )
    moduleUI.buffGrowHorizontalDropdown:ClearAllPoints()
    moduleUI.buffGrowHorizontalDropdown:SetPoint("LEFT", buffHorizontal, "RIGHT", 8, 0)
    moduleUI.buffGrowHorizontalDropdown:SetPoint("RIGHT", buffPanel, "RIGHT", -16, -164)
    local buffVertical = Label(buffPanel, "Vertical:", "GameFontHighlight")
    buffVertical:SetPoint("LEFT", buffPanel, "TOPLEFT", 16, -211)
    moduleUI.buffGrowVerticalDropdown = moduleUI.CreateChoiceDropdown(
        buffPanel, 0, 0, 250,
        {
            { key = "up", label = "Up" },
            { key = "down", label = "Down" },
        },
        function(value)
            BW.db.buffGrowDown = value == "down"
            UpdateDirectionButtons()
            BW:RefreshPresentation()
        end
    )
    moduleUI.buffGrowVerticalDropdown:ClearAllPoints()
    moduleUI.buffGrowVerticalDropdown:SetPoint("LEFT", buffVertical, "RIGHT", 8, 0)
    moduleUI.buffGrowVerticalDropdown:SetPoint("RIGHT", buffPanel, "RIGHT", -16, -211)

    debuffXSlider = NumberBox(
        debuffPanel, "X offset", 16, -60, -300, 400,
        function(value)
            BW.db.debuffOffsetX = value
            BW:RefreshPresentation()
        end
    )
    debuffYSlider = NumberBox(
        debuffPanel, "Y offset", 224, -60, -250, 300,
        function(value)
            BW.db.debuffOffsetY = value
            BW:RefreshPresentation()
        end
    )
    debuffColumnsBox = NumberBox(
        debuffPanel, "Columns", 16, -106, 1, 10,
        function(value)
            BW.db.debuffColumns = value
            BW:RefreshAllContainers()
        end
    )
    debuffRowsBox = NumberBox(
        debuffPanel, "Rows", 224, -106, 1, 10,
        function(value)
            BW.db.debuffRows = value
            BW:RefreshAllContainers()
        end
    )

    AlignNumberPair(debuffXSlider, debuffYSlider, debuffPanel, -64)
    AlignNumberPair(debuffColumnsBox, debuffRowsBox, debuffPanel, -112)

    local debuffHorizontal = Label(debuffPanel, "Horizontal:", "GameFontHighlight")
    debuffHorizontal:SetPoint("LEFT", debuffPanel, "TOPLEFT", 16, -164)
    moduleUI.debuffGrowHorizontalDropdown = moduleUI.CreateChoiceDropdown(
        debuffPanel, 0, 0, 250,
        {
            { key = "left", label = "Left" },
            { key = "right", label = "Right" },
        },
        function(value)
            BW.db.debuffGrowLeft = value == "left"
            UpdateDirectionButtons()
            BW:RefreshPresentation()
        end
    )
    moduleUI.debuffGrowHorizontalDropdown:ClearAllPoints()
    moduleUI.debuffGrowHorizontalDropdown:SetPoint("LEFT", debuffHorizontal, "RIGHT", 8, 0)
    moduleUI.debuffGrowHorizontalDropdown:SetPoint("RIGHT", debuffPanel, "RIGHT", -16, -164)
    local debuffVertical = Label(debuffPanel, "Vertical:", "GameFontHighlight")
    debuffVertical:SetPoint("LEFT", debuffPanel, "TOPLEFT", 16, -211)
    moduleUI.debuffGrowVerticalDropdown = moduleUI.CreateChoiceDropdown(
        debuffPanel, 0, 0, 250,
        {
            { key = "up", label = "Up" },
            { key = "down", label = "Down" },
        },
        function(value)
            BW.db.debuffGrowDown = value == "down"
            UpdateDirectionButtons()
            BW:RefreshPresentation()
        end
    )
    moduleUI.debuffGrowVerticalDropdown:ClearAllPoints()
    moduleUI.debuffGrowVerticalDropdown:SetPoint("LEFT", debuffVertical, "RIGHT", 8, 0)
    moduleUI.debuffGrowVerticalDropdown:SetPoint("RIGHT", debuffPanel, "RIGHT", -16, -211)

    local anchorBar = CreateFrame("Frame", nil, layoutPage, "BackdropTemplate")
    anchorBar:SetPoint("TOPLEFT", layoutPage, "TOPLEFT", 10, -358)
    anchorBar:SetPoint("TOPRIGHT", layoutPage, "TOPRIGHT", -10, -358)
    anchorBar:SetHeight(48)
    ApplyBackdrop(anchorBar, THEME.section, THEME.border, THEME.flatSectionBackdrop)
    local anchorLabel = Label(anchorBar, "Debuff anchor", "GameFontHighlight")
    anchorLabel:SetPoint("LEFT", anchorBar, "LEFT", 16, 0)
    moduleUI.debuffAnchorModeDropdown = moduleUI.CreateChoiceDropdown(
        anchorBar, 0, 0, 230,
        {
            { key = "detached", label = "Detached" },
            { key = "aboveBuffs", label = "Above buffs" },
            { key = "belowBuffs", label = "Below buffs" },
        },
        SetAnchorMode
    )
    moduleUI.debuffAnchorModeDropdown:ClearAllPoints()
    moduleUI.debuffAnchorModeDropdown:SetPoint("LEFT", anchorLabel, "RIGHT", 12, 0)

    local resetLayout = CreateFrame("Button", nil, layoutPage, "UIPanelButtonTemplate")
    resetLayout:SetSize(120, 24)
    resetLayout:SetPoint("TOPLEFT", layoutPage, "TOPLEFT", 12, -418)
    resetLayout:SetText("Reset layout")
    resetLayout:SetScript("OnClick", function()
        BW.db.iconSize = 18
        BW.db.buffOffsetX = 0
        BW.db.buffOffsetY = 29
        BW.db.buffColumns = 5
        BW.db.buffRows = 1
        BW.db.buffGrowLeft = false
        BW.db.buffGrowDown = false
        BW.db.debuffAnchorMode = "belowBuffs"
        BW.db.debuffOffsetX = 0
        BW.db.debuffOffsetY = 0
        BW.db.debuffColumns = 5
        BW.db.debuffRows = 1
        BW.db.debuffGrowLeft = false
        BW.db.debuffGrowDown = false
        BW:RefreshAllContainers()
        BW:RefreshOptions()
    end)
    SkinButton(resetLayout)
end

local function BuildTextPage()
    textPage = CreateFrame("Frame", nil, panel)
    textPage:Hide()
    textPage:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        0,
        -132
    )
    textPage:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        0,
        0
    )

    local help = Label(
        textPage,
        "Duration text can be hidden at/above a chosen minute limit. Colors and outlines are independent for duration and stack text.",
        "GameFontDisableSmall"
    )
    help:SetPoint(
        "TOPLEFT",
        textPage,
        "TOPLEFT",
        16,
        -4
    )
    help:SetWidth(660)
    help:SetJustifyH("LEFT")

    --------------------------------------------------
    -- BUFF COLUMN
    --------------------------------------------------

    local buffTitle = Label(
        textPage,
        "BUFF TEXT",
        "GameFontNormalLarge"
    )
    buffTitle:SetPoint(
        "TOPLEFT",
        textPage,
        "TOPLEFT",
        16,
        -42
    )

    showBuffDurationCheck = Checkbox(
        textPage,
        "Show duration text",
        12,
        -76,
        function(value)
            BW.db.showBuffDuration = value
            BW:RebuildManagedContainers()
        end
    )

    buffDurationSizeBox = NumberBox(
        textPage,
        "Duration size",
        16,
        -116,
        6,
        32,
        function(value)
            BW.db.buffDurationSize = value
            BW:RebuildManagedContainers()
        end
    )

    buffDurationFontButton = FontCycleButton(
        textPage,
        "Duration font",
        16,
        -156,
        function(value)
            BW.db.buffDurationFont = value
            BW:RebuildManagedContainers()
        end
    )

    buffDurationColorButton = ColorButton(
        textPage,
        "Duration",
        16,
        -196,
        function(value)
            BW.db.buffDurationColor = value
            BW:RebuildManagedContainers()
        end
    )

    buffDurationOutlineButton = OutlineCycleButton(
        textPage,
        "Outline",
        160,
        -196,
        function(value)
            BW.db.buffDurationOutline = value
            BW:RebuildManagedContainers()
        end
    )

    hideBuffLongDurationTextCheck = Checkbox(
        textPage,
        "Hide text at/above limit",
        12,
        -236,
        function(value)
            BW.db.hideBuffLongDurationText = value
            BW:RebuildManagedContainers()
        end
    )

    buffLongDurationTextMinutesBox = NumberBox(
        textPage,
        "Limit minutes",
        16,
        -276,
        1,
        10080,
        function(value)
            BW.db.buffLongDurationTextMinutes = value
            BW:RebuildManagedContainers()
        end
    )

    showBuffStacksCheck = Checkbox(
        textPage,
        "Show stack count",
        12,
        -316,
        function(value)
            BW.db.showBuffStacks = value
            BW:RebuildManagedContainers()
        end
    )

    buffStackSizeBox = NumberBox(
        textPage,
        "Stack size",
        16,
        -356,
        6,
        32,
        function(value)
            BW.db.buffStackSize = value
            BW:RebuildManagedContainers()
        end
    )

    buffStackFontButton = FontCycleButton(
        textPage,
        "Stack font",
        16,
        -396,
        function(value)
            BW.db.buffStackFont = value
            BW:RebuildManagedContainers()
        end
    )

    buffStackColorButton = ColorButton(
        textPage,
        "Stack",
        16,
        -436,
        function(value)
            BW.db.buffStackColor = value
            BW:RebuildManagedContainers()
        end
    )

    buffStackOutlineButton = OutlineCycleButton(
        textPage,
        "Outline",
        160,
        -436,
        function(value)
            BW.db.buffStackOutline = value
            BW:RebuildManagedContainers()
        end
    )

    hideBuffTooltipsCheck = Checkbox(
        textPage,
        "Hide buff tooltips",
        12,
        -476,
        function(value)
            BW.db.hideBuffTooltips = value
            BW:RebuildManagedContainers()
        end
    )

    --------------------------------------------------
    -- DEBUFF COLUMN
    --------------------------------------------------

    local debuffTitle = Label(
        textPage,
        "DEBUFF TEXT",
        "GameFontNormalLarge"
    )
    debuffTitle:SetPoint(
        "TOPLEFT",
        textPage,
        "TOPLEFT",
        360,
        -42
    )

    showDebuffDurationCheck = Checkbox(
        textPage,
        "Show duration text",
        356,
        -76,
        function(value)
            BW.db.showDebuffDuration = value
            BW:RebuildManagedContainers()
        end
    )

    debuffDurationSizeBox = NumberBox(
        textPage,
        "Duration size",
        360,
        -116,
        6,
        32,
        function(value)
            BW.db.debuffDurationSize = value
            BW:RebuildManagedContainers()
        end
    )

    debuffDurationFontButton = FontCycleButton(
        textPage,
        "Duration font",
        360,
        -156,
        function(value)
            BW.db.debuffDurationFont = value
            BW:RebuildManagedContainers()
        end
    )

    debuffDurationColorButton = ColorButton(
        textPage,
        "Duration",
        360,
        -196,
        function(value)
            BW.db.debuffDurationColor = value
            BW:RebuildManagedContainers()
        end
    )

    debuffDurationOutlineButton = OutlineCycleButton(
        textPage,
        "Outline",
        504,
        -196,
        function(value)
            BW.db.debuffDurationOutline = value
            BW:RebuildManagedContainers()
        end
    )

    hideDebuffLongDurationTextCheck = Checkbox(
        textPage,
        "Hide text at/above limit",
        356,
        -236,
        function(value)
            BW.db.hideDebuffLongDurationText = value
            BW:RebuildManagedContainers()
        end
    )

    debuffLongDurationTextMinutesBox = NumberBox(
        textPage,
        "Limit minutes",
        360,
        -276,
        1,
        10080,
        function(value)
            BW.db.debuffLongDurationTextMinutes = value
            BW:RebuildManagedContainers()
        end
    )

    showDebuffStacksCheck = Checkbox(
        textPage,
        "Show stack count",
        356,
        -316,
        function(value)
            BW.db.showDebuffStacks = value
            BW:RebuildManagedContainers()
        end
    )

    debuffStackSizeBox = NumberBox(
        textPage,
        "Stack size",
        360,
        -356,
        6,
        32,
        function(value)
            BW.db.debuffStackSize = value
            BW:RebuildManagedContainers()
        end
    )

    debuffStackFontButton = FontCycleButton(
        textPage,
        "Stack font",
        360,
        -396,
        function(value)
            BW.db.debuffStackFont = value
            BW:RebuildManagedContainers()
        end
    )

    debuffStackColorButton = ColorButton(
        textPage,
        "Stack",
        360,
        -436,
        function(value)
            BW.db.debuffStackColor = value
            BW:RebuildManagedContainers()
        end
    )

    debuffStackOutlineButton = OutlineCycleButton(
        textPage,
        "Outline",
        504,
        -436,
        function(value)
            BW.db.debuffStackOutline = value
            BW:RebuildManagedContainers()
        end
    )

    hideDebuffTooltipsCheck = Checkbox(
        textPage,
        "Hide debuff tooltips",
        356,
        -476,
        function(value)
            BW.db.hideDebuffTooltips = value
            BW:RebuildManagedContainers()
        end
    )

    local resetText = CreateFrame(
        "Button",
        nil,
        textPage,
        "UIPanelButtonTemplate"
    )
    resetText:SetSize(120, 24)
    resetText:SetPoint(
        "TOPLEFT",
        textPage,
        "TOPLEFT",
        560,
        -508
    )
    resetText:SetText("Reset text")
    resetText:SetScript("OnClick", function()
        BW.db.showBuffDuration = true
        BW.db.buffDurationFont = "FRIZ"
        BW.db.buffDurationSize = 11
        BW.db.buffDurationColor = { 1, 1, 1, 1 }
        BW.db.buffDurationOutline = "NONE"
        BW.db.hideBuffLongDurationText = false
        BW.db.buffLongDurationTextMinutes = 60
        BW.db.showBuffStacks = true
        BW.db.buffStackFont = "FRIZ"
        BW.db.buffStackSize = 11
        BW.db.buffStackColor = { 1, 1, 1, 1 }
        BW.db.buffStackOutline = "OUTLINE"
        BW.db.hideBuffTooltips = true

        BW.db.showDebuffDuration = true
        BW.db.debuffDurationFont = "FRIZ"
        BW.db.debuffDurationSize = 11
        BW.db.debuffDurationColor = { 1, 1, 1, 1 }
        BW.db.debuffDurationOutline = "NONE"
        BW.db.hideDebuffLongDurationText = false
        BW.db.debuffLongDurationTextMinutes = 60
        BW.db.showDebuffStacks = true
        BW.db.debuffStackFont = "FRIZ"
        BW.db.debuffStackSize = 11
        BW.db.debuffStackColor = { 1, 1, 1, 1 }
        BW.db.debuffStackOutline = "OUTLINE"
        BW.db.hideDebuffTooltips = true

        BW:RebuildManagedContainers()
        BW:RefreshOptions()
    end)
end

local function BuildAuraPage()
    --------------------------------------------------
    -- AURA FILTER PAGE
    --------------------------------------------------

    auraPage = CreateFrame("Frame", nil, panel)
    auraPage:Hide()
    auraPage:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        0,
        -132
    )
    auraPage:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        0,
        0
    )

    --------------------------------------------------
    -- TOP FILTER PANELS
    --------------------------------------------------

    local buffPanel = CreateSection(
        auraPage,
        10,
        -8,
        350,
        252,
        "Buff Filters",
        "Helpful aura visibility and priority."
    )
    buffPanel:ClearAllPoints()
    buffPanel:SetPoint(
        "TOPLEFT",
        auraPage,
        "TOPLEFT",
        10,
        -8
    )
    buffPanel:SetPoint(
        "TOPRIGHT",
        auraPage,
        "TOP",
        -7,
        -8
    )
    buffPanel:SetHeight(252)

    local debuffPanel = CreateSection(
        auraPage,
        10,
        -8,
        350,
        252,
        "Debuff Filters",
        "Harmful aura visibility and priority."
    )
    debuffPanel:ClearAllPoints()
    debuffPanel:SetPoint(
        "TOPLEFT",
        auraPage,
        "TOP",
        7,
        -8
    )
    debuffPanel:SetPoint(
        "TOPRIGHT",
        auraPage,
        "TOPRIGHT",
        -10,
        -8
    )
    debuffPanel:SetHeight(252)

    useBuffFilterCheck = Checkbox(
        buffPanel,
        "Whitelist only",
        14,
        -52,
        function(value)
            BW.db.useBuffFilter = value
            BW:RebuildManagedContainers()
            BW:RefreshOptions()
        end
    )

    onlyMyBuffsCheck = Checkbox(
        buffPanel,
        "Only mine",
        14,
        -84,
        function(value)
            BW.db.onlyMyBuffs = value
            BW:RebuildManagedContainers()
        end
    )

    buffMinePlusWhitelistCheck = Checkbox(
        buffPanel,
        "Mine + whitelist",
        14,
        -116,
        function(value)
            BW.db.buffMinePlusWhitelist = value
            BW:RebuildManagedContainers()
            BW:RefreshOptions()
        end
    )

    hidePermanentBuffsCheck = Checkbox(
        buffPanel,
        "Hide permanent/infinite",
        14,
        -148,
        function(value)
            BW.db.hidePermanentBuffs = value
            BW:RebuildManagedContainers()
        end
    )

    showImportantBossBuffsCheck = Checkbox(
        buffPanel,
        "Always show boss/important",
        14,
        -180,
        function(value)
            BW.db.showImportantBossBuffs = value
            BW:RebuildManagedContainers()
        end
    )

    buffSortButton = SortCycleButton(
        buffPanel,
        "Order",
        18,
        -216,
        175,
        BUFF_SORT_ORDER,
        BUFF_SORT_LABELS,
        function(value)
            BW.db.buffSortMode = value
            BW:RefreshAllContainers()
        end
    )

    useDebuffFilterCheck = Checkbox(
        debuffPanel,
        "Whitelist only",
        14,
        -52,
        function(value)
            BW.db.useDebuffFilter = value
            BW:RebuildManagedContainers()
            BW:RefreshOptions()
        end
    )

    onlyMyDebuffsCheck = Checkbox(
        debuffPanel,
        "Only mine",
        14,
        -84,
        function(value)
            BW.db.onlyMyDebuffs = value
            BW:RebuildManagedContainers()
        end
    )

    debuffMinePlusWhitelistCheck = Checkbox(
        debuffPanel,
        "Mine + whitelist",
        14,
        -116,
        function(value)
            BW.db.debuffMinePlusWhitelist = value
            BW:RebuildManagedContainers()
            BW:RefreshOptions()
        end
    )

    hidePermanentDebuffsCheck = Checkbox(
        debuffPanel,
        "Hide permanent/infinite",
        14,
        -148,
        function(value)
            BW.db.hidePermanentDebuffs = value
            BW:RebuildManagedContainers()
        end
    )

    showDebuffRedBorderCheck = Checkbox(
        debuffPanel,
        "Red border on debuffs",
        14,
        -180,
        function(value)
            BW.db.showDebuffRedBorder = value
            BW:RebuildManagedContainers()
        end
    )

    debuffSortButton = SortCycleButton(
        debuffPanel,
        "Order",
        18,
        -216,
        175,
        DEBUFF_SORT_ORDER,
        DEBUFF_SORT_LABELS,
        function(value)
            BW.db.debuffSortMode = value
            BW:RefreshAllContainers()
        end
    )

    --------------------------------------------------
    -- AURA LIST PANEL
    --------------------------------------------------

    local listPanel = CreateSection(
        auraPage,
        10,
        -272,
        820,
        420,
        "Aura Lists",
        "Whitelist spells you want to keep, or blacklist spells you never want shown."
    )
    listPanel:ClearAllPoints()
    listPanel:SetPoint(
        "TOPLEFT",
        auraPage,
        "TOPLEFT",
        10,
        -272
    )
    listPanel:SetPoint(
        "BOTTOMRIGHT",
        auraPage,
        "BOTTOMRIGHT",
        -10,
        10
    )

    local editLabel = Label(
        listPanel,
        "Edit:",
        "GameFontHighlight"
    )
    editLabel:SetPoint(
        "TOPLEFT",
        listPanel,
        "TOPLEFT",
        16,
        -58
    )
    SetFontColor(editLabel, THEME.subtext)

    editFilterButton = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    editFilterButton:SetSize(110, 26)
    editFilterButton:SetPoint(
        "LEFT",
        editLabel,
        "RIGHT",
        8,
        0
    )
    editFilterButton:SetText("Whitelist")
    editFilterButton:SetScript("OnClick", function()
        SetAuraEditMode("filter")
    end)

    editBlacklistButton = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    editBlacklistButton:SetSize(110, 26)
    editBlacklistButton:SetPoint(
        "LEFT",
        editFilterButton,
        "RIGHT",
        8,
        0
    )
    editBlacklistButton:SetText("Blacklist")
    editBlacklistButton:SetScript("OnClick", function()
        SetAuraEditMode("blacklist")
    end)

    listEditHelp = Label(
        listPanel,
        "",
        "GameFontDisableSmall"
    )
    listEditHelp:SetPoint(
        "TOPLEFT",
        listPanel,
        "TOPLEFT",
        16,
        -91
    )
    listEditHelp:SetPoint(
        "TOPRIGHT",
        listPanel,
        "TOPRIGHT",
        -16,
        -91
    )
    listEditHelp:SetJustifyH("LEFT")
    SetFontColor(listEditHelp, THEME.subtext)

    targetText = Label(
        listPanel,
        "Selected target: none",
        "GameFontNormal"
    )
    targetText:SetPoint(
        "TOPLEFT",
        listPanel,
        "TOPLEFT",
        16,
        -121
    )

    local refresh = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    refresh:SetSize(118, 26)
    refresh:SetPoint(
        "LEFT",
        targetText,
        "RIGHT",
        12,
        0
    )
    refresh:SetText("Refresh target")
    refresh:SetScript("OnClick", function()
        if statusText then
            statusText:SetText("Refreshing target auras...")
        end

        BW:QueueTargetAuraRefresh()
    end)

    statusText = Label(
        listPanel,
        "",
        "GameFontDisableSmall"
    )
    statusText:SetPoint(
        "TOPLEFT",
        listPanel,
        "TOPLEFT",
        16,
        -151
    )
    statusText:SetPoint(
        "TOPRIGHT",
        listPanel,
        "TOPRIGHT",
        -16,
        -151
    )
    statusText:SetJustifyH("LEFT")
    SetFontColor(statusText, THEME.subtext)

    targetAuraTab = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    targetAuraTab:SetSize(120, 27)
    targetAuraTab:SetPoint(
        "TOPLEFT",
        listPanel,
        "TOPLEFT",
        16,
        -177
    )
    targetAuraTab:SetText("Target Auras")
    targetAuraTab:SetScript("OnClick", function()
        SetAuraListMode("target")
    end)

    savedAuraTab = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    savedAuraTab:SetSize(140, 27)
    savedAuraTab:SetPoint(
        "LEFT",
        targetAuraTab,
        "RIGHT",
        8,
        0
    )
    savedAuraTab:SetText("Saved Whitelist")
    savedAuraTab:SetScript("OnClick", function()
        SetAuraListMode("saved")
    end)

    --------------------------------------------------
    -- SCROLLING AURA LIST
    --------------------------------------------------

    auraScroll = CreateFrame(
        "ScrollFrame",
        nil,
        listPanel,
        "UIPanelScrollFrameTemplate"
    )
    auraScroll:SetPoint(
        "TOPLEFT",
        listPanel,
        "TOPLEFT",
        16,
        -214
    )
    auraScroll:SetPoint(
        "BOTTOMRIGHT",
        listPanel,
        "BOTTOMRIGHT",
        -36,
        62
    )
    moduleUI.SkinScrollFrame(auraScroll)

    local listBackground = CreateFrame(
        "Frame",
        nil,
        listPanel,
        "BackdropTemplate"
    )
    listBackground:SetPoint(
        "TOPLEFT",
        auraScroll,
        "TOPLEFT",
        -4,
        4
    )
    listBackground:SetPoint(
        "BOTTOMRIGHT",
        auraScroll,
        "BOTTOMRIGHT",
        4,
        -4
    )
    listBackground:SetFrameLevel(
        math.max(0, auraScroll:GetFrameLevel() - 1)
    )
    ApplyBackdrop(
        listBackground,
        THEME.section,
        THEME.border
    )

    scrollChild = CreateFrame("Frame", nil, auraScroll)
    scrollChild:SetSize(610, 1)
    auraScroll:SetScrollChild(scrollChild)

    auraScroll:SetScript("OnSizeChanged", function()
        UpdateAuraListWidth()
    end)

    --------------------------------------------------
    -- MANUAL ADD ROW
    --------------------------------------------------

    local addLabel = Label(
        listPanel,
        "Add spell:",
        "GameFontHighlight"
    )
    addLabel:SetPoint(
        "BOTTOMLEFT",
        listPanel,
        "BOTTOMLEFT",
        16,
        20
    )
    SetFontColor(addLabel, THEME.subtext)

    addBox = CreateFrame(
        "EditBox",
        nil,
        listPanel,
        "InputBoxTemplate"
    )
    addBox:SetSize(300, 26)
    addBox:SetAutoFocus(false)
    addBox:SetPoint(
        "LEFT",
        addLabel,
        "RIGHT",
        8,
        0
    )
    SkinEditBox(addBox)

    addBuffButton = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    addBuffButton:SetSize(120, 26)
    addBuffButton:SetPoint(
        "LEFT",
        addBox,
        "RIGHT",
        8,
        0
    )
    addBuffButton:SetText("Whitelist buff")
    addBuffButton:SetScript("OnClick", function()
        local ok

        if auraEditMode == "blacklist" then
            ok = BW:AddBlacklistSpell(
                "buff",
                addBox:GetText()
            )
        else
            ok = BW:AddSpell(
                "buff",
                addBox:GetText()
            )
        end

        if ok then
            addBox:SetText("")
        end
    end)

    addDebuffButton = CreateFrame(
        "Button",
        nil,
        listPanel,
        "UIPanelButtonTemplate"
    )
    addDebuffButton:SetSize(130, 26)
    addDebuffButton:SetPoint(
        "LEFT",
        addBuffButton,
        "RIGHT",
        8,
        0
    )
    addDebuffButton:SetText("Whitelist debuff")
    addDebuffButton:SetScript("OnClick", function()
        local ok

        if auraEditMode == "blacklist" then
            ok = BW:AddBlacklistSpell(
                "debuff",
                addBox:GetText()
            )
        else
            ok = BW:AddSpell(
                "debuff",
                addBox:GetText()
            )
        end

        if ok then
            addBox:SetText("")
        end
    end)

    SkinButton(editFilterButton)
    SkinButton(editBlacklistButton)
    SkinButton(refresh)
    SkinButton(targetAuraTab)
    SkinButton(savedAuraTab)
    SkinButton(addBuffButton)
    SkinButton(addDebuffButton)
end

local function BuildLustPage()
    --------------------------------------------------
    -- LUST UP PAGE
    --------------------------------------------------

    lustPanel = CreateFrame("Frame", nil, helperContent)
    lustPanel:SetAllPoints(helperContent)

    local title = Label(
        lustPanel,
        "Lust Up",
        "GameFontNormalHuge"
    )
    title:SetPoint("TOPLEFT", lustPanel, "TOPLEFT", 18, -18)
    SetFontColor(title, THEME.text)

    local moduleStatus = Label(
        lustPanel,
        "",
        "GameFontDisableSmall"
    )
    moduleStatus:SetPoint(
        "TOPRIGHT",
        lustPanel,
        "TOPRIGHT",
        -18,
        -22
    )
    moduleStatus:SetJustifyH("RIGHT")
    lustPanel.moduleStatus = moduleStatus

    local desc = Label(
        lustPanel,
        "Lust readiness indicator and voice notification.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)
    lustPageEnabledCheck = Checkbox(
        lustPanel,
        "Enable Lust Up module",
        18,
        -68,
        function(value)
            BW.db.lustUpEnabled = value

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end

            BW:RefreshLustUpOptions()
        end
    )
    moduleUI.ApplyModuleHeader(
        lustPanel, title, desc, lustPageEnabledCheck, moduleStatus,
        "Interface\\AddOns\\KayliiHelper\\Media\\NavLust.tga"
    )

    lustPage = CreateFrame("Frame", nil, lustPanel)
    lustPage:SetPoint("TOPLEFT", lustPanel, "TOPLEFT", 0, -96)
    lustPage:SetPoint("BOTTOMRIGHT", lustPanel, "BOTTOMRIGHT", 0, 0)

    moduleUI.lustTabs = {}
    moduleUI.lustTabPages = {}
    local lustTabNames = {
        { key = "general", label = "General", width = 144 },
        { key = "alerts", label = "Alerts", width = 126 },
        { key = "appearance", label = "Appearance", width = 150 },
        { key = "tracked", label = "Tracked Items", width = 168 },
    }
    local previousLustTab
    for _, tabInfo in ipairs(lustTabNames) do
        local tabKey = tabInfo.key
        local tab = CreateFrame("Button", nil, lustPage, "UIPanelButtonTemplate")
        tab:SetSize(tabInfo.width, 30)
        if previousLustTab then
            tab:SetPoint("LEFT", previousLustTab, "RIGHT", 4, 0)
        else
            tab:SetPoint("TOPLEFT", lustPage, "TOPLEFT", 14, -4)
        end
        tab:SetText(tabInfo.label)
        SkinButton(tab)
        moduleUI.lustTabs[tabKey] = tab
        previousLustTab = tab

        local page = CreateFrame("Frame", nil, lustPage)
        page:SetPoint("TOPLEFT", lustPage, "TOPLEFT", 0, -38)
        page:SetPoint("BOTTOMRIGHT", lustPage, "BOTTOMRIGHT", 0, 0)
        moduleUI.lustTabPages[tabKey] = page
        tab:SetScript("OnClick", function()
            moduleUI.lustCurrentTab = tabKey
            for key, tabPage in pairs(moduleUI.lustTabPages) do
                local selected = key == tabKey
                tabPage:SetShown(selected)
                SetButtonActiveState(moduleUI.lustTabs[key], selected)
            end
        end)
    end
    moduleUI.lustCurrentTab = moduleUI.lustCurrentTab or "general"
    for key, tabPage in pairs(moduleUI.lustTabPages) do
        local selected = key == moduleUI.lustCurrentTab
        tabPage:SetShown(selected)
        SetButtonActiveState(moduleUI.lustTabs[key], selected)
    end

    local generalPage = moduleUI.lustTabPages.general
    local alertsPage = moduleUI.lustTabPages.alerts
    local appearancePage = moduleUI.lustTabPages.appearance
    local trackedPage = moduleUI.lustTabPages.tracked

    --------------------------------------------------
    -- GENERAL AND ALERT SETTINGS
    --------------------------------------------------

    local visibilityCard = CreateSection(
        alertsPage,
        14,
        -8,
        394,
        350,
        "Voice alerts",
        "Speak when Lust lockouts end or a boss pull begins."
    )

    local indicatorCard = CreateSection(
        generalPage,
        14,
        -316,
        394,
        164,
        "Indicator",
        ""
    )

    local generalVisibilityCard = CreateSection(
        generalPage, 14, -8, 394, 174, "Visibility", ""
    )
    local sourcesCard = CreateSection(
        generalPage, 14, -190, 394, 118, "Sources", ""
    )
    local alertsChatCard = CreateSection(
        alertsPage, 424, -8, 394, 160, "Ready chat",
        "Choose where the ready message is sent."
    )
    local appearanceCard = CreateSection(
        appearancePage, 14, -8, 394, 168, "Indicator behavior",
        "Choose when the indicator is shown and reset its position."
    )
    local appearanceSliderCard = CreateSection(
        appearancePage, 424, -8, 394, 264, "Indicator appearance",
        "Adjust the size and opacity of the on-screen indicator."
    )
    local trackedDrumsCard = CreateSection(
        trackedPage, 424, -8, 394, 360, "Drum items",
        "Manage custom drum items used as Lust sources."
    )

    local function PlaceLustCheck(check, parent, y)
        check:SetParent(parent)
        check:ClearAllPoints()
        check:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, y)
        if check.Label then
            check.Label:SetParent(parent)
            check.Label:ClearAllPoints()
            check.Label:SetPoint("LEFT", parent, "TOPLEFT", 18, y - 11)
            check.Label:SetPoint("RIGHT", check, "LEFT", -12, 0)
            check.Label:SetJustifyH("LEFT")
            check.Label:SetJustifyV("MIDDLE")
        end
    end

    --------------------------------------------------
    -- VISIBILITY & ALERTS
    --------------------------------------------------

    local function CreateVoiceTextInput(parent, width, defaultText)
        local box = CreateFrame(
            "EditBox",
            nil,
            parent,
            "BackdropTemplate"
        )

        box:SetSize(width, 26)
        box:SetAutoFocus(false)
        box:SetMaxLetters(80)
        box:EnableMouse(true)
        box:EnableKeyboard(true)
        box:SetFontObject(GameFontHighlight)
        box:SetTextInsets(8, 8, 0, 0)
        box:SetJustifyH("LEFT")
        box:SetJustifyV("MIDDLE")
        box:SetFrameLevel(parent:GetFrameLevel() + 10)
        box:SetText(defaultText or "")

        SkinEditBox(box)

        box:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                local hadFocus = self:HasFocus()
                self:SetFocus()

                if not hadFocus then
                    self:HighlightText()
                end
            end
        end)

        box:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        return box
    end

    lustUpVoiceCheck = Checkbox(
        visibilityCard,
        'Voice when lockout ends',
        14,
        -64,
        function(value)
            BW.db.lustUpVoiceEnabled = value
        end
    )

    local readyTextLabel = Label(
        visibilityCard,
        "Lockout ended text (voice / chat)",
        "GameFontHighlightSmall"
    )
    readyTextLabel:SetPoint(
        "TOPLEFT",
        visibilityCard,
        "TOPLEFT",
        18,
        -98
    )
    SetFontColor(readyTextLabel, THEME.subtext)

    lustUpReadyVoiceBox = CreateVoiceTextInput(
        visibilityCard,
        236,
        tostring(BW.db.lustUpReadyVoiceText or "Lust up")
    )
    lustUpReadyVoiceBox:SetPoint(
        "TOPLEFT",
        visibilityCard,
        "TOPLEFT",
        18,
        -118
    )

    local testReadyVoice = CreateFrame(
        "Button",
        nil,
        visibilityCard,
        "UIPanelButtonTemplate"
    )
    testReadyVoice:SetSize(88, 26)
    testReadyVoice:SetPoint(
        "LEFT",
        lustUpReadyVoiceBox,
        "RIGHT",
        8,
        0
    )
    testReadyVoice:SetText("Test")
    testReadyVoice:SetScript("OnClick", function()
        local text = lustUpReadyVoiceBox:GetText() or ""

        if text == "" then
            text = "Lust up"
            lustUpReadyVoiceBox:SetText(text)
        end

        BW.db.lustUpReadyVoiceText = text

        if BW.SpeakLustUp then
            BW:SpeakLustUp(true)
        end
    end)
    SkinButton(testReadyVoice)

    lustUpReadyVoiceBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText() or ""

        if text == "" then
            text = "Lust up"
            self:SetText(text)
        end

        BW.db.lustUpReadyVoiceText = text
        self:ClearFocus()
    end)

    lustUpReadyVoiceBox:SetScript("OnEditFocusLost", function(self)
        local text = self:GetText() or ""

        if text == "" then
            text = "Lust up"
            self:SetText(text)
        end

        BW.db.lustUpReadyVoiceText = text
    end)

    lustUpBossPullVoiceCheck = Checkbox(
        visibilityCard,
        "Voice on boss pull if lust is ready",
        14,
        -158,
        function(value)
            BW.db.lustUpBossPullVoiceEnabled = value
        end
    )

    local bossTextLabel = Label(
        visibilityCard,
        "Boss pull text",
        "GameFontHighlightSmall"
    )
    bossTextLabel:SetPoint(
        "TOPLEFT",
        visibilityCard,
        "TOPLEFT",
        18,
        -192
    )
    SetFontColor(bossTextLabel, THEME.subtext)

    lustUpBossPullVoiceBox = CreateVoiceTextInput(
        visibilityCard,
        236,
        tostring(
            BW.db.lustUpBossPullVoiceText
            or "Lust off cooldown"
        )
    )
    lustUpBossPullVoiceBox:SetPoint(
        "TOPLEFT",
        visibilityCard,
        "TOPLEFT",
        18,
        -212
    )

    local testBossVoice = CreateFrame(
        "Button",
        nil,
        visibilityCard,
        "UIPanelButtonTemplate"
    )
    testBossVoice:SetSize(88, 26)
    testBossVoice:SetPoint(
        "LEFT",
        lustUpBossPullVoiceBox,
        "RIGHT",
        8,
        0
    )
    testBossVoice:SetText("Test")
    testBossVoice:SetScript("OnClick", function()
        local text = lustUpBossPullVoiceBox:GetText() or ""

        if text == "" then
            text = "Lust off cooldown"
            lustUpBossPullVoiceBox:SetText(text)
        end

        BW.db.lustUpBossPullVoiceText = text

        if BW.SpeakLustBossPull then
            BW:SpeakLustBossPull(true)
        end
    end)
    SkinButton(testBossVoice)

    lustUpBossPullVoiceBox:SetScript(
        "OnEnterPressed",
        function(self)
            local text = self:GetText() or ""

            if text == "" then
                text = "Lust off cooldown"
                self:SetText(text)
            end

            BW.db.lustUpBossPullVoiceText = text
            self:ClearFocus()
        end
    )

    lustUpBossPullVoiceBox:SetScript(
        "OnEditFocusLost",
        function(self)
            local text = self:GetText() or ""

            if text == "" then
                text = "Lust off cooldown"
                self:SetText(text)
            end

            BW.db.lustUpBossPullVoiceText = text
        end
    )

    lustUpOnlyInCombatCheck = Checkbox(
        visibilityCard,
        "Only show in combat",
        14,
        -254,
        function(value)
            BW.db.lustUpOnlyInCombat = value
            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    lustUpOnlyInInstanceCheck = Checkbox(
        visibilityCard,
        "Only show in instances",
        194,
        -254,
        function(value)
            BW.db.lustUpOnlyInInstance = value
            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    moduleUI.lustShowDungeonsCheck = Checkbox(
        visibilityCard,
        "Dungeons",
        14,
        -290,
        function(value)
            BW.db.lustUpShowInDungeons =
                value and true or false

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    moduleUI.lustShowRaidsCheck = Checkbox(
        visibilityCard,
        "Raids",
        194,
        -290,
        function(value)
            BW.db.lustUpShowInRaids =
                value and true or false

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    lustUpModeButton = SortCycleButton(
        visibilityCard,
        "Indicator mode",
        18,
        -324,
        92,
        LUST_UP_MODE_ORDER,
        LUST_UP_MODE_LABELS,
        function(value)
            BW.db.lustUpDisplayMode = value
            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    local lustChatLabel = Label(
        visibilityCard,
        "Text to",
        "GameFontHighlight"
    )
    lustChatLabel:SetPoint(
        "LEFT",
        lustUpModeButton,
        "RIGHT",
        10,
        0
    )
    SetFontColor(lustChatLabel, THEME.text)

    local lustChatChoices = {}
    for _, value in ipairs(LUST_UP_CHAT_ORDER) do
        lustChatChoices[#lustChatChoices + 1] = {
            key = value,
            label = LUST_UP_CHAT_LABELS[value] or value,
        }
    end

    moduleUI.lustReadyChatButton = moduleUI.CreateChoiceDropdown(
        visibilityCard,
        268,
        -324,
        108,
        lustChatChoices,
        function(value)
            BW.db.lustUpReadyChatChannel = value
        end
    )
    moduleUI.lustReadyChatButton:ClearAllPoints()
    moduleUI.lustReadyChatButton:SetPoint(
        "LEFT",
        lustChatLabel,
        "RIGHT",
        8,
        0
    )

    --------------------------------------------------
    -- INDICATOR
    --------------------------------------------------

    lustUpSizeSlider = Slider(
        indicatorCard,
        "Indicator size",
        18,
        -76,
        176,
        24,
        128,
        1,
        function(value)
            return string.format("%d px", value)
        end,
        function(value)
            BW.db.lustUpSize = value
            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )
    -- Keep the size slider on moduleUI because the appearance tab reparents
    -- it into the shared preview card below.
    moduleUI.lustUpSizeSlider = lustUpSizeSlider

    lustUpUnlockCheck = Checkbox(
        indicatorCard,
        "Unlock indicator to drag",
        14,
        -126,
        function(value)
            if BW.SetLustUpUnlocked then
                BW:SetLustUpUnlocked(value)
            end
        end
    )

    local resetPosition = CreateFrame(
        "Button",
        nil,
        indicatorCard,
        "UIPanelButtonTemplate"
    )
    resetPosition:SetSize(132, 28)
    resetPosition:SetPoint(
        "TOPLEFT",
        indicatorCard,
        "TOPLEFT",
        18,
        -172
    )
    resetPosition:SetText("Reset position")
    resetPosition:SetScript("OnClick", function()
        if BW.ResetLustUpPosition then
            BW:ResetLustUpPosition()
        end
    end)
    SkinButton(resetPosition)

    moduleUI.lustRequireAbilityCheck = Checkbox(
        indicatorCard,
        "Only run if I can provide Lust",
        14,
        -224,
        function(value)
            BW.db.lustUpRequireLustAbility = value

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end

            BW:RefreshLustUpOptions()
        end
    )

    moduleUI.lustAllowDrumsCheck = Checkbox(
        indicatorCard,
        "Allow usable drums in bags",
        14,
        -258,
        function(value)
            BW.db.lustUpAllowDrums = value

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end

            BW:RefreshLustUpOptions()
        end
    )

    moduleUI.lustIndicatorClickableCheck = Checkbox(
        indicatorCard,
        "Make indicator clickable",
        14,
        -310,
        function(value)
            if BW.SetLustUpIndicatorClickable then
                BW:SetLustUpIndicatorClickable(value)
            end
        end
    )

    moduleUI.lustReadyGlowCheck = Checkbox(
        indicatorCard,
        "Glow when Lust is ready",
        202,
        -310,
        function(value)
            BW.db.lustUpReadyGlow =
                value and true or false

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end

            BW:RefreshLustUpOptions()
        end
    )

    PlaceLustCheck(lustUpOnlyInCombatCheck, generalVisibilityCard, -48)
    PlaceLustCheck(lustUpOnlyInInstanceCheck, generalVisibilityCard, -80)
    PlaceLustCheck(moduleUI.lustShowDungeonsCheck, generalVisibilityCard, -112)
    PlaceLustCheck(moduleUI.lustShowRaidsCheck, generalVisibilityCard, -144)
    PlaceLustCheck(moduleUI.lustRequireAbilityCheck, sourcesCard, -52)
    PlaceLustCheck(moduleUI.lustAllowDrumsCheck, sourcesCard, -84)
    PlaceLustCheck(moduleUI.lustIndicatorClickableCheck, indicatorCard, -48)
    PlaceLustCheck(moduleUI.lustReadyGlowCheck, indicatorCard, -80)
    PlaceLustCheck(lustUpUnlockCheck, indicatorCard, -112)
    PlaceLustCheck(lustUpVoiceCheck, visibilityCard, -64)
    PlaceLustCheck(lustUpBossPullVoiceCheck, visibilityCard, -158)

    if lustUpModeButton._khLabel then
        lustUpModeButton._khLabel:SetParent(appearanceCard)
        lustUpModeButton._khLabel:ClearAllPoints()
        lustUpModeButton._khLabel:SetPoint("TOPLEFT", appearanceCard, "TOPLEFT", 18, -64)
        lustUpModeButton._khLabel:SetWidth(150)
        lustUpModeButton._khLabel:SetJustifyH("LEFT")
        lustUpModeButton:SetParent(appearanceCard)
        lustUpModeButton:SetSize(190, 28)
        lustUpModeButton:ClearAllPoints()
        lustUpModeButton:SetPoint("TOPRIGHT", appearanceCard, "TOPRIGHT", -18, -58)
    end

    lustChatLabel:SetParent(alertsChatCard)
    lustChatLabel:ClearAllPoints()
    lustChatLabel:SetPoint("TOPLEFT", alertsChatCard, "TOPLEFT", 18, -66)
    moduleUI.lustReadyChatButton:SetParent(alertsChatCard)
    moduleUI.lustReadyChatButton:SetSize(208, 28)
    moduleUI.lustReadyChatButton:ClearAllPoints()
    moduleUI.lustReadyChatButton:SetPoint("TOPRIGHT", alertsChatCard, "TOPRIGHT", -18, -60)

    resetPosition:SetParent(appearanceCard)
    resetPosition:ClearAllPoints()
    resetPosition:SetPoint("TOPLEFT", appearanceCard, "TOPLEFT", 18, -112)

    --------------------------------------------------
    -- INDICATOR APPEARANCE CONTROLS
    --------------------------------------------------

    moduleUI.lustUpSizeSlider:SetParent(appearanceSliderCard)
    moduleUI.lustUpSizeSlider.ValueBox:SetParent(appearanceSliderCard)

    moduleUI.lustReadyAlphaSlider = Slider(
        appearanceSliderCard,
        "Ready alpha",
        18,
        -104,
        150,
        10,
        100,
        5,
        function(value)
            return string.format("%d%%", value)
        end,
        function(value)
            BW.db.lustUpReadyAlpha = value

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    moduleUI.lustLockedAlphaSlider = Slider(
        appearanceSliderCard,
        "Locked alpha",
        18,
        -104,
        150,
        10,
        100,
        5,
        function(value)
            return string.format("%d%%", value)
        end,
        function(value)
            BW.db.lustUpLockedAlpha = value

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end
        end
    )

    local function PlaceLustAppearanceSlider(slider, labelText, labelY, sliderY)
        slider:ClearAllPoints()
        slider:SetPoint("TOPLEFT", appearanceSliderCard, "TOPLEFT", 18, sliderY)
        slider:SetWidth(290)
        slider.Text:Hide()
        slider.Low:Hide()
        slider.High:Hide()
        slider.ValueBox:ClearAllPoints()
        slider.ValueBox:SetSize(56, 24)
        slider.ValueBox:SetPoint("TOPRIGHT", appearanceSliderCard, "TOPRIGHT", -18, labelY)
        local caption = Label(appearanceSliderCard, labelText, "GameFontHighlight")
        caption:SetPoint("TOPLEFT", appearanceSliderCard, "TOPLEFT", 18, labelY)
        SetFontColor(caption, THEME.text)
    end

    PlaceLustAppearanceSlider(moduleUI.lustUpSizeSlider, "Size", -64, -88)
    PlaceLustAppearanceSlider(moduleUI.lustReadyAlphaSlider, "Ready opacity", -128, -152)
    PlaceLustAppearanceSlider(moduleUI.lustLockedAlphaSlider, "Locked opacity", -192, -216)

    --------------------------------------------------
    -- TRACKED LOCKOUTS
    --------------------------------------------------

    local trackingCard = CreateSection(
        trackedPage,
        14,
        -8,
        394,
        360,
        "Tracked Lust Lockouts",
        "Add only unlisted custom lockout Spell IDs."
    )

    local builtInTitle = Label(
        trackingCard,
        "Built-in lockouts",
        "GameFontNormal"
    )
    builtInTitle:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -76
    )
    SetFontColor(builtInTitle, THEME.text)

    local builtIn = Label(
        trackingCard,
        "Exhaustion — 57723, 390435\n"
        .. "Sated — 57724\n"
        .. "Temporal Displacement — 80354\n"
        .. "Insanity — 95809\n"
        .. "Fatigued — 160455, 264689",
        "GameFontHighlightSmall"
    )
    builtIn:SetPoint("TOPLEFT", builtInTitle, "BOTTOMLEFT", 0, -8)
    builtIn:SetWidth(350)
    builtIn:SetJustifyH("LEFT")
    SetFontColor(builtIn, THEME.subtext)

    local customTitle = Label(
        trackingCard,
        "Additional lockout Spell ID",
        "GameFontNormal"
    )
    customTitle:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -174
    )
    SetFontColor(customTitle, THEME.text)

    lustUpCustomBox = CreateVisibleValueBox(trackingCard, 184)
    lustUpCustomBox:SetMaxLetters(12)
    lustUpCustomBox:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -198
    )
    lustUpCustomBox:SetRenderedValue("")

    local addCustom = CreateFrame(
        "Button",
        nil,
        trackingCard,
        "UIPanelButtonTemplate"
    )
    addCustom:SetSize(82, 26)
    addCustom:SetPoint("LEFT", lustUpCustomBox, "RIGHT", 8, 0)
    addCustom:SetText("Add ID")
    addCustom:SetScript("OnClick", function()
        if BW.AddLustUpLockout
            and BW:AddLustUpLockout(lustUpCustomBox:GetText()) then

            lustUpCustomBox:SetRenderedValue("")
        end
    end)
    SkinButton(addCustom)

    local customListTitle = Label(
        trackingCard,
        "Custom lockouts",
        "GameFontHighlight"
    )
    customListTitle:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -230
    )
    SetFontColor(customListTitle, THEME.text)

    moduleUI.lustCustomLockoutScroll = CreateFrame(
        "ScrollFrame", nil, trackingCard, "UIPanelScrollFrameTemplate"
    )
    moduleUI.lustCustomLockoutScroll:SetPoint(
        "TOPLEFT", trackingCard, "TOPLEFT", 18, -254
    )
    moduleUI.lustCustomLockoutScroll:SetPoint(
        "BOTTOMRIGHT", trackingCard, "BOTTOMRIGHT", -30, 14
    )
    moduleUI.SkinScrollFrame(moduleUI.lustCustomLockoutScroll)

    moduleUI.lustCustomLockoutContent = CreateFrame(
        "Frame", nil, moduleUI.lustCustomLockoutScroll
    )
    moduleUI.lustCustomLockoutContent:SetSize(320, 1)
    moduleUI.lustCustomLockoutScroll:SetScrollChild(
        moduleUI.lustCustomLockoutContent
    )
    moduleUI.lustCustomLockoutRows = {}
    moduleUI.lustCustomLockoutEmptyText = Label(
        moduleUI.lustCustomLockoutContent,
        "None added.",
        "GameFontHighlightSmall"
    )
    moduleUI.lustCustomLockoutEmptyText:SetPoint(
        "TOPLEFT", moduleUI.lustCustomLockoutContent, "TOPLEFT", 4, -4
    )
    SetFontColor(moduleUI.lustCustomLockoutEmptyText, THEME.subtext)

    moduleUI.RefreshLustCustomLockoutList = function()
        local content = moduleUI.lustCustomLockoutContent
        local scroll = moduleUI.lustCustomLockoutScroll
        if not content or not scroll or not BW.db then return end

        local entries = {}
        for key, enabled in pairs(BW.db.lustUpCustomLockouts or {}) do
            local spellID = tonumber(key)
            if spellID and enabled then
                local name
                if C_Spell and C_Spell.GetSpellInfo then
                    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
                    if ok and type(info) == "table" then name = info.name end
                end
                if not name and GetSpellInfo then
                    name = GetSpellInfo(spellID)
                end
                entries[#entries + 1] = {
                    id = spellID,
                    name = name or ("Spell " .. spellID),
                }
            end
        end
        table.sort(entries, function(a, b)
            if a.name == b.name then return a.id < b.id end
            return a.name < b.name
        end)

        local rows = moduleUI.lustCustomLockoutRows
        for _, row in ipairs(rows) do row:Hide() end
        moduleUI.lustCustomLockoutEmptyText:SetShown(#entries == 0)
        content:SetWidth(math.max(scroll:GetWidth() - 16, 1))

        for index, entry in ipairs(entries) do
            local row = rows[index]
            if not row then
                row = CreateFrame("Frame", nil, content)
                row:SetHeight(24)
                row.label = Label(row, "", "GameFontHighlightSmall")
                row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -62, 0)
                row.label:SetJustifyH("LEFT")
                SetFontColor(row.label, THEME.text)
                row.remove = CreateFrame(
                    "Button", nil, row, "UIPanelButtonTemplate"
                )
                row.remove:SetSize(56, 22)
                row.remove:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                row.remove:SetText("Remove")
                SkinButton(row.remove)
                row.remove:SetScript("OnClick", function(button)
                    local parentRow = button:GetParent()
                    if parentRow.spellID and BW.RemoveLustUpLockout then
                        BW:RemoveLustUpLockout(parentRow.spellID)
                    end
                end)
                rows[index] = row
            end
            row.spellID = entry.id
            row.label:SetText(string.format("%s (%d)", entry.name, entry.id))
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((index - 1) * 26))
            row:SetWidth(content:GetWidth())
            row:Show()
        end

        content:SetHeight(math.max(#entries * 26, scroll:GetHeight()))
        scroll:UpdateScrollChildRect()
    end
    moduleUI.lustCustomLockoutScroll:SetScript("OnSizeChanged", function()
        if moduleUI.RefreshLustCustomLockoutList then
            moduleUI.RefreshLustCustomLockoutList()
        end
    end)

    --------------------------------------------------
    -- TRACKED DRUM ITEMS
    --------------------------------------------------

    moduleUI.lustBuiltInDrumTitle = Label(
        trackedDrumsCard, "Built-in drums", "GameFontNormal"
    )
    moduleUI.lustBuiltInDrumTitle:SetPoint(
        "TOPLEFT", trackedDrumsCard, "TOPLEFT", 18, -64
    )
    SetFontColor(moduleUI.lustBuiltInDrumTitle, THEME.text)

    moduleUI.lustBuiltInDrumListText = Label(
        trackedDrumsCard, "", "GameFontHighlightSmall"
    )
    moduleUI.lustBuiltInDrumListText:SetPoint(
        "TOPLEFT", moduleUI.lustBuiltInDrumTitle, "BOTTOMLEFT", 0, -7
    )
    moduleUI.lustBuiltInDrumListText:SetWidth(350)
    moduleUI.lustBuiltInDrumListText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.lustBuiltInDrumListText, THEME.subtext)

    moduleUI.lustCustomDrumTitle = Label(
        trackedDrumsCard, "Additional drum Item ID", "GameFontNormal"
    )
    moduleUI.lustCustomDrumTitle:SetPoint(
        "TOPLEFT", trackedDrumsCard, "TOPLEFT", 18, -150
    )
    SetFontColor(moduleUI.lustCustomDrumTitle, THEME.text)

    moduleUI.lustCustomDrumBox = CreateVisibleValueBox(trackedDrumsCard, 138)
    moduleUI.lustCustomDrumBox:SetMaxLetters(12)
    moduleUI.lustCustomDrumBox:SetPoint(
        "TOPLEFT", trackedDrumsCard, "TOPLEFT", 18, -176
    )
    moduleUI.lustCustomDrumBox:SetRenderedValue("")

    moduleUI.lustCustomDrumAddButton = CreateFrame(
        "Button", nil, trackedDrumsCard, "UIPanelButtonTemplate"
    )
    moduleUI.lustCustomDrumAddButton:SetSize(78, 26)
    moduleUI.lustCustomDrumAddButton:SetPoint(
        "LEFT", moduleUI.lustCustomDrumBox, "RIGHT", 7, 0
    )
    moduleUI.lustCustomDrumAddButton:SetText("Add ID")
    moduleUI.lustCustomDrumAddButton:SetScript("OnClick", function()
        if BW.AddLustUpDrumItem
            and BW:AddLustUpDrumItem(moduleUI.lustCustomDrumBox:GetText()) then
            moduleUI.lustCustomDrumBox:SetRenderedValue("")
        end
    end)
    SkinButton(moduleUI.lustCustomDrumAddButton)

    moduleUI.lustCustomDrumRemoveButton = CreateFrame(
        "Button", nil, trackedDrumsCard, "UIPanelButtonTemplate"
    )
    moduleUI.lustCustomDrumRemoveButton:SetSize(88, 26)
    moduleUI.lustCustomDrumRemoveButton:SetPoint(
        "LEFT", moduleUI.lustCustomDrumAddButton, "RIGHT", 6, 0
    )
    moduleUI.lustCustomDrumRemoveButton:SetText("Remove ID")
    moduleUI.lustCustomDrumRemoveButton:SetScript("OnClick", function()
        if BW.RemoveLustUpDrumItem
            and BW:RemoveLustUpDrumItem(moduleUI.lustCustomDrumBox:GetText()) then
            moduleUI.lustCustomDrumBox:SetRenderedValue("")
        end
    end)
    SkinButton(moduleUI.lustCustomDrumRemoveButton)

    moduleUI.lustCustomDrumListTitle = Label(
        trackedDrumsCard, "Custom drums", "GameFontNormal"
    )
    moduleUI.lustCustomDrumListTitle:SetPoint(
        "TOPLEFT", trackedDrumsCard, "TOPLEFT", 18, -214
    )
    SetFontColor(moduleUI.lustCustomDrumListTitle, THEME.text)

    moduleUI.lustCustomDrumScroll = CreateFrame(
        "ScrollFrame", nil, trackedDrumsCard, "UIPanelScrollFrameTemplate"
    )
    moduleUI.lustCustomDrumScroll:SetPoint(
        "TOPLEFT", trackedDrumsCard, "TOPLEFT", 18, -238
    )
    moduleUI.lustCustomDrumScroll:SetPoint(
        "BOTTOMRIGHT", trackedDrumsCard, "BOTTOMRIGHT", -30, 14
    )
    moduleUI.SkinScrollFrame(moduleUI.lustCustomDrumScroll)
    moduleUI.lustCustomDrumContent = CreateFrame(
        "Frame", nil, moduleUI.lustCustomDrumScroll
    )
    moduleUI.lustCustomDrumContent:SetSize(320, 1)
    moduleUI.lustCustomDrumScroll:SetScrollChild(
        moduleUI.lustCustomDrumContent
    )
    moduleUI.lustCustomDrumListText = Label(
        moduleUI.lustCustomDrumContent, "None added.", "GameFontHighlightSmall"
    )
    moduleUI.lustCustomDrumListText:SetPoint(
        "TOPLEFT", moduleUI.lustCustomDrumContent, "TOPLEFT", 4, -4
    )
    moduleUI.lustCustomDrumListText:SetWidth(304)
    moduleUI.lustCustomDrumListText:SetJustifyH("LEFT")
    moduleUI.lustCustomDrumListText:SetJustifyV("TOP")
    SetFontColor(moduleUI.lustCustomDrumListText, THEME.subtext)

    moduleUI.RefreshLustCustomDrumListLayout = function()
        local scroll = moduleUI.lustCustomDrumScroll
        local content = moduleUI.lustCustomDrumContent
        local list = moduleUI.lustCustomDrumListText
        if not scroll or not content or not list then return end
        local width = math.max(scroll:GetWidth() - 16, 1)
        content:SetWidth(width)
        list:SetWidth(math.max(width - 8, 1))
        content:SetHeight(math.max(list:GetStringHeight() + 8, scroll:GetHeight()))
        scroll:UpdateScrollChildRect()
    end
    moduleUI.lustCustomDrumScroll:SetScript("OnSizeChanged", function()
        if moduleUI.RefreshLustCustomDrumListLayout then
            moduleUI.RefreshLustCustomDrumListLayout()
        end
    end)
end


local function BuildStatsPage()
    moduleUI.statsPanel = CreateFrame("Frame", nil, helperContent)
    moduleUI.statsPanel:SetAllPoints(helperContent)

    local title = Label(
        moduleUI.statsPanel,
        "My Stats",
        "GameFontNormalHuge"
    )
    title:SetPoint("TOPLEFT", moduleUI.statsPanel, "TOPLEFT", 18, -18)
    SetFontColor(title, THEME.text)

    local moduleStatus = Label(
        moduleUI.statsPanel,
        "",
        "GameFontDisableSmall"
    )
    moduleUI.statsPanel.moduleStatus = moduleStatus

    local desc = Label(
        moduleUI.statsPanel,
        "Live secondary-stat display for your current character.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)

    moduleUI.statsPageEnabledCheck = Checkbox(
        moduleUI.statsPanel,
        "",
        18,
        -24,
        function(value)
            if BW.SetStatsModuleEnabled then
                BW:SetStatsModuleEnabled(value)
            end
            if moduleUI.SetStandaloneModuleEnabled then
                moduleUI.SetStandaloneModuleEnabled("stats", value, true)
            end
        end
    )
    moduleUI.statsPageEnabledCheck:ClearAllPoints()
    moduleUI.statsPageEnabledCheck:SetPoint(
        "TOPRIGHT",
        moduleUI.statsPanel,
        "TOPRIGHT",
        -24,
        -22
    )
    moduleUI.statsPageEnabledCheck.Label:Hide()
    moduleStatus:SetPoint("TOP", moduleUI.statsPageEnabledCheck, "BOTTOM", 0, -4)
    moduleStatus:SetWidth(90)
    moduleStatus:SetJustifyH("CENTER")

    moduleUI.ApplyModuleHeader(
        moduleUI.statsPanel, title, desc, moduleUI.statsPageEnabledCheck, moduleStatus,
        "Interface\\AddOns\\KayliiHelper\\Media\\NavStats.tga"
    )

    moduleUI.statsPage = CreateFrame("Frame", nil, moduleUI.statsPanel)
    moduleUI.statsPage:SetPoint("TOPLEFT", moduleUI.statsPanel, "TOPLEFT", 0, -96)
    moduleUI.statsPage:SetPoint("BOTTOMRIGHT", moduleUI.statsPanel, "BOTTOMRIGHT", 0, 0)

    local displayTab = CreateFrame("Button", nil, moduleUI.statsPage, "UIPanelButtonTemplate")
    displayTab:SetSize(132, 30)
    displayTab:SetPoint("TOPLEFT", moduleUI.statsPage, "TOPLEFT", 14, -4)
    displayTab:SetText("Display")
    SkinButton(displayTab)

    local visibilityTab = CreateFrame("Button", nil, moduleUI.statsPage, "UIPanelButtonTemplate")
    visibilityTab:SetSize(144, 30)
    visibilityTab:SetPoint("LEFT", displayTab, "RIGHT", 2, 0)
    visibilityTab:SetText("Visibility")
    SkinButton(visibilityTab)

    local displayContent = CreateFrame("Frame", nil, moduleUI.statsPage)
    displayContent:SetPoint("TOPLEFT", moduleUI.statsPage, "TOPLEFT", 0, -38)
    displayContent:SetPoint("BOTTOMRIGHT", moduleUI.statsPage, "BOTTOMRIGHT", 0, 0)

    local visibilityContent = CreateFrame("Frame", nil, moduleUI.statsPage)
    visibilityContent:SetPoint("TOPLEFT", moduleUI.statsPage, "TOPLEFT", 0, -38)
    visibilityContent:SetPoint("BOTTOMRIGHT", moduleUI.statsPage, "BOTTOMRIGHT", 0, 0)
    visibilityContent:Hide()

    local function SelectStatsTab(tab)
        local showDisplay = tab == "display"
        displayContent:SetShown(showDisplay)
        visibilityContent:SetShown(not showDisplay)
        SetButtonActiveState(displayTab, showDisplay)
        SetButtonActiveState(visibilityTab, not showDisplay)
    end

    displayTab:SetScript("OnClick", function() SelectStatsTab("display") end)
    visibilityTab:SetScript("OnClick", function() SelectStatsTab("visibility") end)
    SelectStatsTab("display")

    local displayCard = CreateSection(
        displayContent,
        14,
        -8,
        394,
        252,
        "Display",
        ""
    )

    moduleUI.statsFontSizeSlider = Slider(
        displayCard,
        "Font size",
        150,
        -42,
        160,
        10,
        28,
        1,
        function(value)
            return string.format("%d px", value)
        end,
        function(value)
            BW.db.statsFontSize = value
            BW:ApplyStatsSettings()
        end
    )
    moduleUI.statsFontSizeSlider.Text:Hide()
    moduleUI.statsFontSizeSlider.Low:Hide()
    moduleUI.statsFontSizeSlider.High:Hide()
    moduleUI.statsFontSizeLabel = Label(displayCard, "Font size", "GameFontHighlight")
    moduleUI.statsFontSizeLabel:SetPoint("LEFT", moduleUI.statsFontSizeSlider, "LEFT", -132, 0)
    SetFontColor(moduleUI.statsFontSizeLabel, THEME.text)

    moduleUI.statsOrientationButton = moduleUI.CreateChoiceDropdown(
        displayCard,
        150,
        -70,
        224,
        {
            { key = "horizontal", label = "Horizontal" },
            { key = "vertical", label = "Vertical" },
        },
        function(value)
            BW.db.statsOrientation = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )
    moduleUI.statsOrientationLabel = Label(displayCard, "Orientation", "GameFontHighlight")
    moduleUI.statsOrientationLabel:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -74)
    SetFontColor(moduleUI.statsOrientationLabel, THEME.text)

    moduleUI.statsAlignButton = moduleUI.CreateChoiceDropdown(
        displayCard,
        150,
        -104,
        224,
        {
            { key = "left", label = "Left" },
            { key = "center", label = "Center" },
            { key = "right", label = "Right" },
        },
        function(value)
            BW.db.statsTextAlign = value

            if BW.UpdateStatsDisplay then
                BW:UpdateStatsDisplay()
            end

            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )
    moduleUI.statsVerticalAlignButton = moduleUI.CreateChoiceDropdown(
        displayCard,
        150,
        -104,
        224,
        {
            { key = "top", label = "Top" },
            { key = "middle", label = "Middle" },
        },
        function(value)
            BW.db.statsVerticalAlign = value
            if BW.UpdateStatsDisplay then BW:UpdateStatsDisplay() end
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )
    moduleUI.statsAlignLabel = Label(displayCard, "Text alignment", "GameFontHighlight")
    moduleUI.statsAlignLabel:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -108)
    SetFontColor(moduleUI.statsAlignLabel, THEME.text)
    moduleUI.statsVerticalAlignButton:Hide()

    moduleUI.statsUnlockCheck = Checkbox(
        displayCard,
        "Unlock to move",
        336,
        -172,
        function(value)
            BW:SetStatsUnlocked(value)
        end
    )

    moduleUI.statsShowBackgroundCheck = Checkbox(
        displayCard,
        "Show background",
        336,
        -140,
        function(value)
            BW.db.statsShowBackground = value
            BW:ApplyStatsSettings()
        end
    )

    moduleUI.statsShowBackgroundCheck.Label:ClearAllPoints()
    moduleUI.statsShowBackgroundCheck.Label:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -144)
    moduleUI.statsShowBackgroundCheck.Label:SetJustifyH("LEFT")
    moduleUI.statsUnlockCheck.Label:ClearAllPoints()
    moduleUI.statsUnlockCheck.Label:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -176)
    moduleUI.statsUnlockCheck.Label:SetJustifyH("LEFT")

    local reset = CreateFrame(
        "Button",
        nil,
        displayCard,
        "UIPanelButtonTemplate"
    )
    reset:SetSize(124, 28)
    reset:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -208)
    reset:SetText("Reset position")
    reset:SetScript("OnClick", function()
        BW:ResetStatsPosition()
    end)
    SkinButton(reset)

    local statsCard = CreateSection(
        displayContent,
        424,
        -8,
        394,
        252,
        "Stats",
        ""
    )

    local visibilityCard = CreateSection(
        visibilityContent,
        14,
        -8,
        340,
        150,
        "Visibility",
        ""
    )

    moduleUI.statsOnlyInCombatCheck = Checkbox(
        visibilityCard,
        "Only show in combat",
        18,
        -50,
        function(value)
            BW.db.statsOnlyInCombat = value
            if value then BW.db.statsOnlyOutOfCombat = false end
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsOnlyOutOfCombatCheck = Checkbox(
        visibilityCard,
        "Only show out of combat",
        18,
        -82,
        function(value)
            BW.db.statsOnlyOutOfCombat = value
            if value then BW.db.statsOnlyInCombat = false end
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsOnlyInInstanceCheck = Checkbox(
        visibilityCard,
        "Only show in instances",
        18,
        -114,
        function(value)
            BW.db.statsOnlyInInstance = value
            BW:ApplyStatsSettings()
        end
    )

    local function AlignVisibilityToggle(check, y)
        check:ClearAllPoints()
        check:SetPoint("TOPRIGHT", visibilityCard, "TOPRIGHT", -18, y)
        check.Label:ClearAllPoints()
        check.Label:SetPoint("LEFT", visibilityCard, "TOPLEFT", 18, y - 11)
        check.Label:SetPoint("RIGHT", check, "LEFT", -12, 0)
        check.Label:SetJustifyH("LEFT")
    end

    AlignVisibilityToggle(moduleUI.statsOnlyInCombatCheck, -50)
    AlignVisibilityToggle(moduleUI.statsOnlyOutOfCombatCheck, -82)
    AlignVisibilityToggle(moduleUI.statsOnlyInInstanceCheck, -114)

    moduleUI.statsShowCritCheck = Checkbox(
        statsCard,
        "Critical Strike",
        14,
        -52,
        function(value)
            BW.db.statsShowCrit = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsShowHasteCheck = Checkbox(
        statsCard,
        "Haste",
        14,
        -88,
        function(value)
            BW.db.statsShowHaste = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsShowMasteryCheck = Checkbox(
        statsCard,
        "Mastery",
        14,
        -124,
        function(value)
            BW.db.statsShowMastery = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsShowVersatilityCheck = Checkbox(
        statsCard,
        "Versatility",
        14,
        -160,
        function(value)
            BW.db.statsShowVersatility = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    local function AlignStatToggle(check, y)
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", statsCard, "TOPLEFT", 282, y)
        check.Label:ClearAllPoints()
        check.Label:SetPoint("LEFT", statsCard, "TOPLEFT", 14, y - 11)
        check.Label:SetPoint("RIGHT", check, "LEFT", -12, 0)
        check.Label:SetJustifyH("LEFT")
    end

    AlignStatToggle(moduleUI.statsShowCritCheck, -52)
    AlignStatToggle(moduleUI.statsShowHasteCheck, -88)
    AlignStatToggle(moduleUI.statsShowMasteryCheck, -124)
    AlignStatToggle(moduleUI.statsShowVersatilityCheck, -160)

    moduleUI.statsCritColorButton = ColorButton(
        statsCard,
        nil,
        336,
        -52,
        function(color)
            BW.db.statsCritColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsHasteColorButton = ColorButton(
        statsCard,
        nil,
        336,
        -88,
        function(color)
            BW.db.statsHasteColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsMasteryColorButton = ColorButton(
        statsCard,
        nil,
        336,
        -124,
        function(color)
            BW.db.statsMasteryColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsVersatilityColorButton = ColorButton(
        statsCard,
        nil,
        336,
        -160,
        function(color)
            BW.db.statsVersatilityColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    local resetColors = CreateFrame(
        "Button",
        nil,
        statsCard,
        "UIPanelButtonTemplate"
    )
    resetColors:SetSize(124, 26)
    resetColors:SetPoint(
        "TOPLEFT",
        statsCard,
        "TOPLEFT",
        250,
        -198
    )
    resetColors:SetText("Reset colors")
    resetColors:SetScript("OnClick", function()
        BW.db.statsCritColor = { 1.00, 0.42, 0.35, 1 }
        BW.db.statsHasteColor = { 0.35, 0.85, 0.45, 1 }
        BW.db.statsMasteryColor = { 0.67, 0.48, 1.00, 1 }
        BW.db.statsVersatilityColor = { 0.30, 0.72, 1.00, 1 }
        BW:ApplyStatsSettings()
        BW:RefreshStatsOptions()
    end)
    SkinButton(resetColors)

    local previewCard = CreateSection(
        displayContent,
        14,
        -270,
        804,
        160,
        "Live preview",
        ""
    )

    local previewBox = CreateFrame("Frame", nil, previewCard, "BackdropTemplate")
    previewBox:SetPoint("TOPLEFT", previewCard, "TOPLEFT", 18, -54)
    previewBox:SetPoint("BOTTOMRIGHT", previewCard, "BOTTOMRIGHT", -18, 14)
    ApplyBackdrop(previewBox, THEME.panelAlt, THEME.border, THEME.flatSectionBackdrop)

    moduleUI.statsPreviewText = Label(
        previewBox,
        "",
        "GameFontNormal"
    )
    moduleUI.statsPreviewText:SetPoint("TOPLEFT", previewBox, "TOPLEFT", 8, -8)
    moduleUI.statsPreviewText:SetPoint("BOTTOMRIGHT", previewBox, "BOTTOMRIGHT", -8, 8)
    moduleUI.statsPreviewText:SetJustifyH("CENTER")
    SetFontColor(moduleUI.statsPreviewText, THEME.accent)
end

local function BuildSurvivalPage()
    moduleUI.survivalPanel = CreateFrame("Frame", nil, helperContent)
    moduleUI.survivalPanel:SetAllPoints(helperContent)

    local title = Label(
        moduleUI.survivalPanel,
        "Survival Helper",
        "GameFontNormalHuge"
    )
    title:SetPoint("TOPLEFT", moduleUI.survivalPanel, "TOPLEFT", 18, -18)
    SetFontColor(title, THEME.text)

    local moduleStatus = Label(
        moduleUI.survivalPanel,
        "",
        "GameFontDisableSmall"
    )
    moduleStatus:SetPoint(
        "TOPRIGHT",
        moduleUI.survivalPanel,
        "TOPRIGHT",
        -18,
        -22
    )
    moduleStatus:SetJustifyH("RIGHT")
    moduleUI.survivalPanel.moduleStatus = moduleStatus

    local desc = Label(
        moduleUI.survivalPanel,
        "One HP trigger, then the first enabled and READY action in your priority list wins.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)
    moduleUI.survivalPageEnabledCheck = Checkbox(
        moduleUI.survivalPanel,
        "Enable Survival Helper module",
        18,
        -68,
        function(value)
            if BW.SetSurvivalModuleEnabled then
                BW:SetSurvivalModuleEnabled(value)
            end
        end
    )
    moduleUI.ApplyModuleHeader(
        moduleUI.survivalPanel, title, desc, moduleUI.survivalPageEnabledCheck, moduleStatus,
        "Interface\\AddOns\\KayliiHelper\\Media\\NavSurvival.tga"
    )

    moduleUI.survivalPage = CreateFrame("Frame", nil, moduleUI.survivalPanel)
    moduleUI.survivalPage:SetPoint("TOPLEFT", moduleUI.survivalPanel, "TOPLEFT", 0, -96)
    moduleUI.survivalPage:SetPoint("BOTTOMRIGHT", moduleUI.survivalPanel, "BOTTOMRIGHT", 0, 0)

    moduleUI.survivalTabs = {}
    moduleUI.survivalTabPages = {}
    local survivalTabNames = {
        { key = "priority", label = "Priority & Trigger", width = 178 },
        { key = "alerts", label = "Alerts", width = 126 },
        { key = "appearance", label = "Appearance", width = 150 },
    }
    local previousSurvivalTab
    for index, tabInfo in ipairs(survivalTabNames) do
        local tabKey = tabInfo.key
        local tab = CreateFrame("Button", nil, moduleUI.survivalPage, "UIPanelButtonTemplate")
        tab:SetSize(tabInfo.width, 30)
        if not previousSurvivalTab then
            tab:SetPoint("TOPLEFT", moduleUI.survivalPage, "TOPLEFT", 14, -4)
        else
            tab:SetPoint("LEFT", previousSurvivalTab, "RIGHT", 4, 0)
        end
        tab:SetText(tabInfo.label)
        SkinButton(tab)
        moduleUI.survivalTabs[tabKey] = tab
        previousSurvivalTab = tab

        local page = CreateFrame("Frame", nil, moduleUI.survivalPage)
        page:SetPoint("TOPLEFT", moduleUI.survivalPage, "TOPLEFT", 0, -38)
        page:SetPoint("BOTTOMRIGHT", moduleUI.survivalPage, "BOTTOMRIGHT", 0, 0)
        moduleUI.survivalTabPages[tabInfo.key] = page
        tab:SetScript("OnClick", function()
            moduleUI.survivalCurrentTab = tabKey
            for key, tabPage in pairs(moduleUI.survivalTabPages) do
                tabPage:SetShown(key == tabKey)
                SetButtonActiveState(moduleUI.survivalTabs[key], key == tabKey)
            end
        end)
    end
    moduleUI.survivalCurrentTab = moduleUI.survivalCurrentTab or "priority"
    for key, tabPage in pairs(moduleUI.survivalTabPages) do
        local selected = key == moduleUI.survivalCurrentTab
        tabPage:SetShown(selected)
        SetButtonActiveState(moduleUI.survivalTabs[key], selected)
    end

    local priorityPage = moduleUI.survivalTabPages.priority
    local alertsPage = moduleUI.survivalTabPages.alerts
    local appearancePage = moduleUI.survivalTabPages.appearance

    local triggerCard = CreateSection(
        priorityPage, 424, -8, 394, 218, "Trigger conditions", "Show the first ready action at or below this health threshold."
    )
    local addCard = CreateSection(
        priorityPage, 424, -236, 394, 174, "Add spell or item",
        "Enter an ID or paste a spell/item link."
    )
    local alertCard = CreateSection(
        alertsPage, 14, -8, 394, 270, "Voice alerts", "Configure spoken warnings and their text."
    )
    local soundCard = CreateSection(
        alertsPage, 424, -8, 394, 270, "Sound alert", "Choose a sound to play when the HP trigger fires."
    )
    local appearanceCard = CreateSection(
        appearancePage, 14, -8, 394, 336, "On-screen display", "Adjust how the survival icon appears."
    )
    local appearancePreviewCard = CreateSection(
        appearancePage, 424, -8, 394, 336, "Preview", "The first configured action appears here."
    )

    local function AlignSurvivalToggle(check, parent, y)
        check:ClearAllPoints()
        check:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, y)
        if check.Label then
            check.Label:ClearAllPoints()
            check.Label:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y - 1)
            check.Label:SetWidth(math.max(120, parent:GetWidth() - 100))
            check.Label:SetJustifyH("LEFT")
            check.Label:SetJustifyV("MIDDLE")
        end
    end

    moduleUI.survivalAppearanceIcons = {}
    moduleUI.survivalAppearanceIcons[1] = appearancePreviewCard:CreateTexture(nil, "ARTWORK")
    moduleUI.survivalAppearanceIcons[1]:SetSize(58, 58)
    moduleUI.survivalAppearanceIcons[1]:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    moduleUI.survivalAppearanceIcons[1]:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    moduleUI.survivalAppearanceIcons[1]:SetPoint("CENTER", appearancePreviewCard, "CENTER", 0, 14)
    moduleUI.survivalAppearanceLabel = Label(appearancePreviewCard, "Action icon preview", "GameFontHighlight")
    moduleUI.survivalAppearanceLabel:SetPoint("TOP", moduleUI.survivalAppearanceIcons[1], "BOTTOM", 0, -8)
    moduleUI.survivalAppearanceLabel:SetJustifyH("CENTER")
    SetFontColor(moduleUI.survivalAppearanceLabel, THEME.subtext)
    moduleUI.survivalAppearanceGlowHost = CreateFrame("Frame", nil, appearancePreviewCard)
    moduleUI.survivalAppearanceGlowHost:SetSize(58, 58)
    moduleUI.survivalAppearanceGlowHost:SetFrameLevel(appearancePreviewCard:GetFrameLevel() + 3)

    local recommendationCard = CreateSection(
        priorityPage,
        14,
        -8,
        394,
        460,
        "Priority list",
        "Cooldown, unknown, or missing actions are skipped. Edit each TTS phrase below; it saves per character."
    )

    moduleUI.survivalActionRows = {}

    local actionScroll = CreateFrame(
        "ScrollFrame",
        nil,
        recommendationCard,
        "UIPanelScrollFrameTemplate"
    )
    actionScroll:SetPoint("TOPLEFT", recommendationCard, "TOPLEFT", 14, -72)
    actionScroll:SetPoint("BOTTOMRIGHT", recommendationCard, "BOTTOMRIGHT", -34, 22)
    moduleUI.SkinScrollFrame(actionScroll)

    local actionScrollChild = CreateFrame("Frame", nil, actionScroll)
    actionScrollChild:SetSize(338, 1)
    actionScroll:SetScrollChild(actionScrollChild)
    moduleUI.survivalActionScrollChild = actionScrollChild

    local function EnsureActionRow(index)
        local row = moduleUI.survivalActionRows[index]
        if row then return row end

        row = CreateFrame("Frame", nil, actionScrollChild, "BackdropTemplate")
        row:SetSize(338, 88)
        ApplyBackdrop(row, THEME.section, THEME.border, THEME.flatSectionBackdrop)
        row:SetPoint(
            "TOPLEFT",
            actionScrollChild,
            "TOPLEFT",
            0,
            -((index - 1) * 92)
        )

        row.enabled = Checkbox(
            row,
            "",
            0, -2,
            function(value)
                if row.actionKey and BW.SetSurvivalActionEnabled then
                    BW:SetSurvivalActionEnabled(row.actionKey, value)
                    BW:RefreshSurvivalOptions()
                end
            end
        )
        if row.enabled.Label then row.enabled.Label:Hide() end
        row.enabled:ClearAllPoints()
        row.enabled:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)

        row.orderText = Label(row, "", "GameFontNormalLarge")
        row.orderText:SetPoint("TOPLEFT", row, "TOPLEFT", 66, -10)
        row.orderText:SetSize(22, 24)
        row.orderText:SetJustifyH("CENTER")
        SetFontColor(row.orderText, THEME.text)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(36, 36)
        row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 94, -8)

        row.linkButton = CreateFrame("Button", nil, row)
        row.linkButton:SetSize(150, 22)
        row.linkButton:SetPoint("TOPLEFT", row, "TOPLEFT", 138, -9)
        row.linkButton._khNoSkin = true

        row.linkText = row.linkButton:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlight"
        )
        row.linkText:SetAllPoints(row.linkButton)
        row.linkText:SetJustifyH("LEFT")
        if row.linkText.SetWordWrap then
            row.linkText:SetWordWrap(false)
        end

        row.linkButton:SetScript("OnClick", function()
            if row.actionKey and BW.OpenSurvivalActionLink then
                BW:OpenSurvivalActionLink(row.actionKey)
            end
        end)

        row.status = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )
        row.status:SetPoint("TOPLEFT", row, "TOPLEFT", 138, -33)
        row.status:SetWidth(150)
        row.status:SetJustifyH("LEFT")

        row.up = CreateFrame("Button", nil, row, "BackdropTemplate")
        row.up:SetSize(26, 26)
        row.up:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -8)
        ApplyBackdrop(row.up, THEME.button, THEME.border, THEME.flatControlBackdrop)
        row.up.icon = row.up:CreateTexture(nil, "ARTWORK")
        row.up.icon:SetSize(16, 16)
        row.up.icon:SetPoint("CENTER")
        row.up.icon:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\ScrollArrowUp.tga")
        row.up:SetScript("OnClick", function()
            if row.actionKey and BW.MoveSurvivalAction then
                BW:MoveSurvivalAction(row.actionKey, "up")
                BW:RefreshSurvivalOptions()
            end
        end)
        row.up:SetScript("OnEnter", function(self) self:SetBackdropColor(THEME.buttonHover[1], THEME.buttonHover[2], THEME.buttonHover[3], 1) end)
        row.up:SetScript("OnLeave", function(self) self:SetBackdropColor(THEME.button[1], THEME.button[2], THEME.button[3], 1) end)
        row.up:HookScript("OnDisable", function(self) self:SetAlpha(0.42) end)
        row.up:HookScript("OnEnable", function(self) self:SetAlpha(1) end)

        row.down = CreateFrame("Button", nil, row, "BackdropTemplate")
        row.down:SetSize(26, 26)
        row.down:SetPoint("TOPLEFT", row, "TOPLEFT", 38, -8)
        ApplyBackdrop(row.down, THEME.button, THEME.border, THEME.flatControlBackdrop)
        row.down.icon = row.down:CreateTexture(nil, "ARTWORK")
        row.down.icon:SetSize(16, 16)
        row.down.icon:SetPoint("CENTER")
        row.down.icon:SetTexture("Interface\\AddOns\\KayliiHelper\\Media\\ScrollArrowDown.tga")
        row.down:SetScript("OnClick", function()
            if row.actionKey and BW.MoveSurvivalAction then
                BW:MoveSurvivalAction(row.actionKey, "down")
                BW:RefreshSurvivalOptions()
            end
        end)
        row.down:SetScript("OnEnter", function(self) self:SetBackdropColor(THEME.buttonHover[1], THEME.buttonHover[2], THEME.buttonHover[3], 1) end)
        row.down:SetScript("OnLeave", function(self) self:SetBackdropColor(THEME.button[1], THEME.button[2], THEME.button[3], 1) end)
        row.down:HookScript("OnDisable", function(self) self:SetAlpha(0.42) end)
        row.down:HookScript("OnEnable", function(self) self:SetAlpha(1) end)

        row.ttsLabel = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.ttsLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -61)
        row.ttsLabel:SetText("TTS")
        row.ttsLabel:SetTextColor(THEME.subtext[1], THEME.subtext[2], THEME.subtext[3], 1)

        row.ttsPhraseBox = CreateVisibleValueBox(row, 244)
        row.ttsPhraseBox:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -56)
        row.ttsPhraseBox:SetJustifyH("LEFT")
        row.ttsPhraseBox:SetTextInsets(5, 5, 0, 0)
        row.ttsPhraseBox:SetMaxLetters(96)
        row.ttsPhraseBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput and row.actionKey and BW.SetSurvivalTTSPhrase then
                BW:SetSurvivalTTSPhrase(row.actionKey, self:GetText())
            end
        end)
        row.ttsPhraseBox:SetScript("OnEnterPressed", function(self)
            if row.actionKey and BW.SetSurvivalTTSPhrase then
                BW:SetSurvivalTTSPhrase(row.actionKey, self:GetText())
            end
            self:ClearFocus()
        end)
        row.ttsPhraseBox:SetScript("OnEscapePressed", function(self)
            if row.actionKey and BW.GetSurvivalTTSPhrase then
                local defaultText = "Use " .. tostring(row.actionName or "")
                self:SetRenderedValue(BW:GetSurvivalTTSPhrase(row.actionKey, defaultText))
            end
            self:ClearFocus()
        end)
        row.ttsPhraseBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Per-character TTS phrase", 1, 1, 1)
            GameTooltip:AddLine("Edit the words spoken when this action is the first ready item.", THEME.subtext[1], THEME.subtext[2], THEME.subtext[3], true)
            GameTooltip:Show()
        end)
        row.ttsPhraseBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.remove = CreateFrame(
            "Button",
            nil,
            row,
            "UIPanelButtonTemplate"
        )
        row.remove:SetSize(28, 24)
        row.remove:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 5)
        row.remove:SetText("×")
        row.remove:SetScript("OnClick", function()
            if row.actionKey and BW.RemoveSurvivalAction then
                BW:RemoveSurvivalAction(row.actionKey)
                BW:RefreshSurvivalOptions()
            end
        end)
        SkinButton(row.remove)

        moduleUI.survivalActionRows[index] = row
        return row
    end

    local function UpdateSurvivalAppearancePreview(actions)
        local readyActions = {}
        for _, action in ipairs(actions) do
            if action.enabled and action.available and action.ready then
                readyActions[#readyActions + 1] = action
                if not BW.db.survivalShowAllReadyActions then break end
            end
        end

        local hasReadyAction = #readyActions > 0
        if not hasReadyAction then
            readyActions[1] = {
                name = "No action ready",
                icon = "Interface\\Icons\\INV_Misc_QuestionMark",
            }
        end

        local iconSize = math.max(32, math.min(100, tonumber(BW.db.survivalIconSize) or 58))
        local spacing = iconSize + 4
        local growth = tostring(BW.db.survivalReadyActionsGrowth or "right")
        if growth ~= "left" and growth ~= "right" and growth ~= "up" and growth ~= "down" then
            growth = "right"
        end
        local count = #readyActions
        local middleOffset = ((count - 1) * spacing) / 2
        local baseX = growth == "left" and middleOffset or 0
        local baseY = growth == "up" and (14 - middleOffset)
            or growth == "down" and (14 + middleOffset)
            or 14

        for index, action in ipairs(readyActions) do
            local icon = moduleUI.survivalAppearanceIcons[index]
            if not icon then
                icon = appearancePreviewCard:CreateTexture(nil, "ARTWORK")
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                moduleUI.survivalAppearanceIcons[index] = icon
            end
            icon:SetSize(iconSize, iconSize)
            icon:SetTexture(action.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            icon:ClearAllPoints()
            local offset = (index - 1) * spacing
            local x = growth == "right" and offset or growth == "left" and -offset or 0
            local y = growth == "up" and offset or growth == "down" and -offset or 0
            icon:SetPoint("CENTER", appearancePreviewCard, "CENTER", baseX + x, baseY + y)
            icon:Show()
        end
        for index = count + 1, #moduleUI.survivalAppearanceIcons do
            moduleUI.survivalAppearanceIcons[index]:Hide()
        end

        local firstIcon = moduleUI.survivalAppearanceIcons[1]
        moduleUI.survivalAppearanceLabel:ClearAllPoints()
        moduleUI.survivalAppearanceLabel:SetPoint("TOP", firstIcon, "BOTTOM", 0, -8)
        moduleUI.survivalAppearanceLabel:SetText(readyActions[1].name or "Action")
        moduleUI.survivalAppearanceLabel:SetShown(
            BW.db.survivalShowLabel ~= false or not hasReadyAction
        )

        local glowHost = moduleUI.survivalAppearanceGlowHost
        glowHost:ClearAllPoints()
        glowHost:SetPoint("CENTER", firstIcon, "CENTER", 0, 0)
        glowHost:SetSize(iconSize, iconSize)
        local manager = ActionButtonSpellAlertManager
        local shouldGlow = hasReadyAction and BW.db.survivalGlowEnabled ~= false and manager
        local sizeChanged = glowHost.survivalPreviewGlowSize ~= iconSize
        if glowHost.survivalGlowShown and manager and manager.HideAlert
            and (not shouldGlow or sizeChanged) then
            pcall(manager.HideAlert, manager, glowHost)
            glowHost.survivalGlowShown = false
        end
        if shouldGlow and manager.ShowAlert and not glowHost.survivalGlowShown then
            local ok = pcall(manager.ShowAlert, manager, glowHost, false)
            glowHost.survivalGlowShown = ok and true or false
            local alert = glowHost.SpellActivationAlert
            if ok and alert then
                alert:SetSize(iconSize * 1.4, iconSize * 1.4)
                alert:ClearAllPoints()
                alert:SetPoint("CENTER", glowHost, "CENTER", 0, 0)
            end
        end
        glowHost.survivalPreviewGlowSize = iconSize
    end

    moduleUI.refreshSurvivalActionRows = function()
        local actions = BW.GetSurvivalActions and BW:GetSurvivalActions() or {}
        UpdateSurvivalAppearancePreview(actions)

        for index, action in ipairs(actions) do
            local row = EnsureActionRow(index)
            row.actionKey = action.key
            row.actionType = action.actionType
            row.actionID = action.id
            row.actionName = action.name or ""
            row.enabled:SetChecked(action.enabled and true or false)
            row.orderText:SetText(tostring(index))
            row.icon:SetTexture(action.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.linkText:SetText(action.name or "Unknown action")
            local phrase = BW.GetSurvivalTTSPhrase
                and BW:GetSurvivalTTSPhrase(action.key, "Use " .. tostring(action.name or "action"))
                or ("Use " .. tostring(action.name or "action"))
            if not row.ttsPhraseBox:HasFocus() then
                row.ttsPhraseBox:SetRenderedValue(phrase)
            end
            row.status:SetText(action.status or "")
            row.up:SetEnabled(index > 1)
            row.down:SetEnabled(index < #actions)
            row.remove:SetShown(action.custom and true or false)
            row:Show()
        end

        for index = #actions + 1, #moduleUI.survivalActionRows do
            moduleUI.survivalActionRows[index]:Hide()
        end

        actionScrollChild:SetHeight(math.max(276, #actions * 92))
    end

    moduleUI.survivalAddActionTypeDropdown = moduleUI.CreateChoiceDropdown(
        addCard,
        18,
        -64,
        144,
        {
            { key = "spell", label = "Spell" },
            { key = "item", label = "Item" },
        },
        function(value)
            moduleUI.survivalAddActionType = value
        end
    )
    moduleUI.survivalAddActionTypeDropdown:SetValue(moduleUI.survivalAddActionType or "spell")

    moduleUI.survivalAddActionBox = CreateFrame(
        "EditBox",
        nil,
        addCard,
        "InputBoxTemplate"
    )
    moduleUI.survivalAddActionBox:SetSize(260, 28)
    moduleUI.survivalAddActionBox:SetAutoFocus(false)
    moduleUI.survivalAddActionBox:SetPoint("TOPLEFT", addCard, "TOPLEFT", 18, -100)
    moduleUI.survivalAddActionBox:SetMaxLetters(64)
    SkinEditBox(moduleUI.survivalAddActionBox)

    local function AddSurvivalAction()
        if not BW.AddSurvivalAction then return end

        local ok, message = BW:AddSurvivalAction(
            moduleUI.survivalAddActionTypeDropdown:GetValue() or "spell",
            moduleUI.survivalAddActionBox:GetText()
        )

        moduleUI.survivalAddActionStatus:SetText(message or "")
        SetFontColor(
            moduleUI.survivalAddActionStatus,
            ok and THEME.accent or { 1.00, 0.42, 0.42, 1 }
        )

        if ok then
            moduleUI.survivalAddActionBox:SetText("")
        end

        BW:RefreshSurvivalOptions()
    end

    moduleUI.survivalAddButton = CreateFrame(
        "Button",
        nil,
        addCard,
        "UIPanelButtonTemplate"
    )
    moduleUI.survivalAddButton:SetSize(88, 28)
    moduleUI.survivalAddButton:SetPoint("LEFT", moduleUI.survivalAddActionBox, "RIGHT", 8, 0)
    moduleUI.survivalAddButton:SetText("Add")
    moduleUI.survivalAddButton:SetScript("OnClick", function()
        AddSurvivalAction()
    end)
    moduleUI.survivalAddActionBox:SetScript("OnEnterPressed", function(self)
        AddSurvivalAction()
        self:ClearFocus()
    end)
    SkinButton(moduleUI.survivalAddButton)

    moduleUI.survivalAddActionStatus = Label(
        addCard,
        "",
        "GameFontDisableSmall"
    )
    moduleUI.survivalAddActionStatus:SetPoint("TOPLEFT", addCard, "TOPLEFT", 18, -132)
    moduleUI.survivalAddActionStatus:SetWidth(356)
    moduleUI.survivalAddActionStatus:SetJustifyH("LEFT")

    local displayCard = alertCard

    moduleUI.survivalTriggerSlider = Slider(
        triggerCard,
        "Trigger at HP",
        150,
        -68,
        162,
        5,
        95,
        1,
        function(value)
            return string.format("%d%%", value)
        end,
        function(value)
            if BW.SetSurvivalTriggerThreshold then
                BW:SetSurvivalTriggerThreshold(value)
            end
        end
    )
    moduleUI.survivalTriggerSlider.Text:Hide()
    moduleUI.survivalTriggerSlider.Low:Hide()
    moduleUI.survivalTriggerSlider.High:Hide()
    local triggerThresholdLabel = Label(triggerCard, "HP threshold", "GameFontHighlight")
    triggerThresholdLabel:SetPoint("RIGHT", moduleUI.survivalTriggerSlider, "LEFT", -12, 0)
    triggerThresholdLabel:SetWidth(120)
    triggerThresholdLabel:SetJustifyH("LEFT")
    SetFontColor(triggerThresholdLabel, THEME.text)

    moduleUI.survivalAlertTypeCheck = Checkbox(
        displayCard,
        "Use sound alert",
        18,
        -70,
        function(value)
            if BW.SetSurvivalThresholdAlertType then
                BW:SetSurvivalThresholdAlertType(value and "sound" or "tts")
            else
                BW.db.survivalThresholdAlertType = value and "sound" or "tts"
            end
            BW:RefreshSurvivalOptions()
        end
    )

    moduleUI.survivalTTSContinuousCheck = Checkbox(
        displayCard,
        "Repeat TTS while low HP",
        18,
        -108,
        function(value)
            if BW.SetSurvivalTTSContinuous then
                BW:SetSurvivalTTSContinuous(value)
            else
                BW.db.survivalTTSContinuous = value and true or false
            end
        end
    )

    moduleUI.survivalSpeakActionNameCheck = Checkbox(
        displayCard,
        "Speak action name",
        176,
        -108,
        function(value)
            BW.db.survivalSpeakActionName = value and true or false
        end
    )

    local ttsLabel = Label(
        displayCard,
        "TTS phrase",
        "GameFontHighlightSmall"
    )
    ttsLabel:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -166)
    SetFontColor(ttsLabel, THEME.subtext)

    moduleUI.survivalTTSTextBox = CreateFrame(
        "EditBox",
        nil,
        displayCard,
        "InputBoxTemplate"
    )
    moduleUI.survivalTTSTextBox:SetSize(250, 28)
    moduleUI.survivalTTSTextBox:SetAutoFocus(false)
    moduleUI.survivalTTSTextBox:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -186)
    SkinEditBox(moduleUI.survivalTTSTextBox)

    local function SaveTTSText()
        if BW.SetSurvivalTTSText then
            BW:SetSurvivalTTSText(moduleUI.survivalTTSTextBox:GetText())
        else
            BW.db.survivalTTSText = moduleUI.survivalTTSTextBox:GetText()
        end
    end

    moduleUI.survivalTTSTextBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            SaveTTSText()
        end
    end)
    moduleUI.survivalTTSTextBox:SetScript("OnEnterPressed", function(self)
        SaveTTSText()
        self:ClearFocus()
    end)
    moduleUI.survivalTTSTextBox:SetScript("OnEditFocusLost", SaveTTSText)
    moduleUI.survivalTTSTextBox:SetScript("OnEscapePressed", function(self)
        self:SetText(BW.db.survivalTTSText or "")
        self:ClearFocus()
    end)

    moduleUI.survivalTTSTestButton = CreateFrame(
        "Button",
        nil,
        displayCard,
        "UIPanelButtonTemplate"
    )
    moduleUI.survivalTTSTestButton:SetSize(92, 28)
    moduleUI.survivalTTSTestButton:SetPoint("LEFT", moduleUI.survivalTTSTextBox, "RIGHT", 8, 0)
    moduleUI.survivalTTSTestButton:SetText("Test voice")
    moduleUI.survivalTTSTestButton:SetScript("OnClick", function()
        SaveTTSText()
        local worked = BW.TestSurvivalTTS and BW:TestSurvivalTTS()
        moduleUI.survivalTTSStatus:SetText(worked and "TTS played" or "TTS unavailable")
        SetFontColor(
            moduleUI.survivalTTSStatus,
            worked and THEME.accent or { 1.00, 0.42, 0.42, 1 }
        )
    end)
    SkinButton(moduleUI.survivalTTSTestButton)

    moduleUI.survivalTTSStatus = Label(
        displayCard,
        "",
        "GameFontDisableSmall"
    )
    moduleUI.survivalTTSStatus:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -225)
    moduleUI.survivalTTSStatus:SetWidth(350)
    moduleUI.survivalTTSStatus:SetJustifyH("LEFT")

    local alertSoundLabel = Label(
        soundCard,
        "Alert sound",
        "GameFontHighlightSmall"
    )
    alertSoundLabel:SetPoint("TOPLEFT", soundCard, "TOPLEFT", 18, -62)
    SetFontColor(alertSoundLabel, THEME.subtext)

    moduleUI.survivalAlertSoundDropdown = moduleUI.CreateChoiceDropdown(
        soundCard,
        164,
        -60,
        208,
        BW.GetSurvivalAlertSoundChoices and BW:GetSurvivalAlertSoundChoices() or {
            { key = "off", label = "Off" },
        },
        function(value)
            if BW.SetSurvivalAlertSound then BW:SetSurvivalAlertSound(value) end
        end
    )

    moduleUI.survivalAlertSoundTestButton = CreateFrame(
        "Button", nil, soundCard, "UIPanelButtonTemplate"
    )
    moduleUI.survivalAlertSoundTestButton:SetSize(208, 28)
    moduleUI.survivalAlertSoundTestButton:SetPoint(
        "TOPLEFT", soundCard, "TOPLEFT", 164, -98
    )
    moduleUI.survivalAlertSoundTestButton:SetText("Test alert sound")
    moduleUI.survivalAlertSoundTestButton:SetScript("OnClick", function()
        local worked = BW.TestSurvivalAlertSound and BW:TestSurvivalAlertSound()
        if moduleUI.survivalAlertSoundStatus then
            moduleUI.survivalAlertSoundStatus:SetText(worked and "Alert sound played" or "Sound unavailable or set to Off")
            SetFontColor(moduleUI.survivalAlertSoundStatus, worked and THEME.accent or { 1.00, 0.42, 0.42, 1 })
        end
    end)
    SkinButton(moduleUI.survivalAlertSoundTestButton)
    moduleUI.survivalAlertSoundStatus = Label(
        soundCard,
        "",
        "GameFontDisableSmall"
    )
    moduleUI.survivalAlertSoundStatus:SetPoint("TOPLEFT", soundCard, "TOPLEFT", 164, -136)
    moduleUI.survivalAlertSoundStatus:SetWidth(208)
    moduleUI.survivalAlertSoundStatus:SetJustifyH("LEFT")

    moduleUI.survivalIconSizeSlider = Slider(
        appearanceCard,
        "Icon size",
        150,
        -72,
        162,
        32,
        100,
        1,
        function(value)
            return string.format("%d px", value)
        end,
        function(value)
            BW.db.survivalIconSize = value
            if moduleUI.refreshSurvivalActionRows then moduleUI.refreshSurvivalActionRows() end
            BW:ApplySurvivalSettings()
        end
    )
    moduleUI.survivalIconSizeSlider.Text:Hide()
    moduleUI.survivalIconSizeSlider.Low:Hide()
    moduleUI.survivalIconSizeSlider.High:Hide()
    local survivalIconSizeLabel = Label(appearanceCard, "Icon size", "GameFontHighlight")
    survivalIconSizeLabel:SetPoint("RIGHT", moduleUI.survivalIconSizeSlider, "LEFT", -12, 0)
    survivalIconSizeLabel:SetWidth(120)
    survivalIconSizeLabel:SetJustifyH("LEFT")
    SetFontColor(survivalIconSizeLabel, THEME.text)

    moduleUI.survivalUnlockCheck = Checkbox(
        appearanceCard,
        "Unlock display to drag",
        18,
        -116,
        function(value)
            if BW.SetSurvivalUnlocked then
                BW:SetSurvivalUnlocked(value)
            end
        end
    )

    moduleUI.survivalShowLabelCheck = Checkbox(
        appearanceCard,
        "Show action name",
        18,
        -148,
        function(value)
            BW.db.survivalShowLabel = value
            if moduleUI.refreshSurvivalActionRows then moduleUI.refreshSurvivalActionRows() end
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalShowAllReadyActionsCheck = Checkbox(
        appearanceCard,
        "Show all ready actions",
        18,
        -180,
        function(value)
            BW.db.survivalShowAllReadyActions = value and true or false
            if moduleUI.survivalReadyActionsGrowthDropdown then
                moduleUI.survivalReadyActionsGrowthDropdown:SetEnabledState(value)
            end
            if moduleUI.refreshSurvivalActionRows then moduleUI.refreshSurvivalActionRows() end
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalReadyActionsGrowthDropdown = moduleUI.CreateChoiceDropdown(
        appearanceCard,
        164,
        -212,
        208,
        {
            { key = "left", label = "Grow left" },
            { key = "right", label = "Grow right" },
            { key = "up", label = "Grow up" },
            { key = "down", label = "Grow down" },
        },
        function(value)
            BW.db.survivalReadyActionsGrowth = value
            if moduleUI.refreshSurvivalActionRows then moduleUI.refreshSurvivalActionRows() end
            BW:ApplySurvivalSettings()
        end
    )
    local growthLabel = Label(appearanceCard, "Ready action growth", "GameFontHighlight")
    growthLabel:SetPoint("LEFT", moduleUI.survivalReadyActionsGrowthDropdown, "LEFT", -146, 0)
    growthLabel:SetWidth(136)
    growthLabel:SetJustifyH("LEFT")
    SetFontColor(growthLabel, THEME.text)

    moduleUI.survivalOnlyCombatCheck = Checkbox(
        triggerCard,
        "Only show in combat",
        18,
        -106,
        function(value)
            BW.db.survivalOnlyInCombat = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalOnlyInstanceCheck = Checkbox(
        triggerCard,
        "Only show in instances",
        18,
        -138,
        function(value)
            BW.db.survivalOnlyInInstance = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalGlowCheck = Checkbox(
        appearanceCard,
        "Glow icon when active",
        18,
        -248,
        function(value)
            if BW.SetSurvivalGlowEnabled then
                BW:SetSurvivalGlowEnabled(value)
            else
                BW.db.survivalGlowEnabled = value and true or false
                BW:ApplySurvivalSettings()
            end
            if moduleUI.refreshSurvivalActionRows then moduleUI.refreshSurvivalActionRows() end
        end
    )

    moduleUI.survivalDeathSoundCard = CreateSection(
        priorityPage, 14, -480, 804, 110,
        "Group death sound", "Separate from Survival action alerts."
    )
    moduleUI.survivalDeathSoundCheck = Checkbox(
        moduleUI.survivalDeathSoundCard,
        "Enabled",
        0,
        0,
        function(value)
            if BW.SetSurvivalDeathSoundEnabled then
                BW:SetSurvivalDeathSoundEnabled(value)
            else
                BW.db.survivalDeathSoundEnabled = value and true or false
            end
        end
    )
    moduleUI.survivalDeathSoundCheck:ClearAllPoints()
    moduleUI.survivalDeathSoundCheck:SetPoint("TOPRIGHT", moduleUI.survivalDeathSoundCard, "TOPRIGHT", -18, -15)
    moduleUI.survivalDeathSoundCheck.Label:Hide()
    local deathSoundEnabledLabel = Label(moduleUI.survivalDeathSoundCard, "Enabled", "GameFontHighlightSmall")
    deathSoundEnabledLabel:SetPoint("TOP", moduleUI.survivalDeathSoundCheck, "BOTTOM", 0, -2)
    deathSoundEnabledLabel:SetJustifyH("CENTER")
    SetFontColor(deathSoundEnabledLabel, THEME.subtext)

    moduleUI.survivalDeathSoundDropdown = moduleUI.CreateChoiceDropdown(
        moduleUI.survivalDeathSoundCard,
        18,
        -58,
        210,
        BW.GetSurvivalDeathSoundChoices and BW:GetSurvivalDeathSoundChoices() or {
            { key = "Quest Failed", label = "Quest Failed" },
        },
        function(value)
            if BW.SetSurvivalDeathSound then
                BW:SetSurvivalDeathSound(value)
            else
                BW.db.survivalDeathSound = value
            end
        end
    )

    moduleUI.survivalDeathSoundTestButton = CreateFrame(
        "Button",
        nil,
        moduleUI.survivalDeathSoundCard,
        "UIPanelButtonTemplate"
    )
    moduleUI.survivalDeathSoundTestButton:SetSize(126, 28)
    moduleUI.survivalDeathSoundTestButton:SetPoint("LEFT", moduleUI.survivalDeathSoundDropdown, "RIGHT", 8, 0)
    moduleUI.survivalDeathSoundTestButton:SetText("Test")
    moduleUI.survivalDeathSoundTestButton:SetScript("OnClick", function()
        if BW.TestSurvivalDeathSound then
            BW:TestSurvivalDeathSound()
        end
    end)
    SkinButton(moduleUI.survivalDeathSoundTestButton)

    local reset = CreateFrame(
        "Button",
        nil,
        appearanceCard,
        "UIPanelButtonTemplate"
    )
    reset:SetSize(124, 28)
    reset:SetPoint("TOPLEFT", appearanceCard, "TOPLEFT", 18, -292)
    reset:SetText("Reset position")
    reset:SetScript("OnClick", function()
        if BW.ResetSurvivalPosition then
            BW:ResetSurvivalPosition()
        end
    end)
    SkinButton(reset)

    moduleUI.survivalStatusText = Label(
        triggerCard,
        "",
        "GameFontHighlightSmall"
    )
    moduleUI.survivalStatusText:SetPoint("TOPLEFT", triggerCard, "TOPLEFT", 18, -170)
    moduleUI.survivalStatusText:SetWidth(354)
    moduleUI.survivalStatusText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.survivalStatusText, THEME.accent)

    moduleUI.survivalDetectedText = Label(
        triggerCard,
        "",
        "GameFontHighlightSmall"
    )
    moduleUI.survivalDetectedText:SetPoint("TOPLEFT", triggerCard, "TOPLEFT", 18, -190)
    moduleUI.survivalDetectedText:SetWidth(354)
    moduleUI.survivalDetectedText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.survivalDetectedText, THEME.subtext)

    AlignSurvivalToggle(moduleUI.survivalAlertTypeCheck, alertCard, -66)
    AlignSurvivalToggle(moduleUI.survivalTTSContinuousCheck, alertCard, -100)
    AlignSurvivalToggle(moduleUI.survivalSpeakActionNameCheck, alertCard, -134)
    AlignSurvivalToggle(moduleUI.survivalOnlyCombatCheck, triggerCard, -106)
    AlignSurvivalToggle(moduleUI.survivalOnlyInstanceCheck, triggerCard, -138)
    AlignSurvivalToggle(moduleUI.survivalUnlockCheck, appearanceCard, -116)
    AlignSurvivalToggle(moduleUI.survivalShowLabelCheck, appearanceCard, -148)
    AlignSurvivalToggle(moduleUI.survivalShowAllReadyActionsCheck, appearanceCard, -180)
    AlignSurvivalToggle(moduleUI.survivalGlowCheck, appearanceCard, -248)

end

local function BuildTalentLoadoutPage()
    moduleUI.talentPanel = CreateFrame("Frame", nil, helperContent)
    moduleUI.talentPanel:SetAllPoints(helperContent)

    local title = Label(
        moduleUI.talentPanel,
        "Talent Loadout",
        "GameFontNormalHuge"
    )
    title:SetPoint("TOPLEFT", moduleUI.talentPanel, "TOPLEFT", 18, -18)
    SetFontColor(title, THEME.text)

    local moduleStatus = Label(
        moduleUI.talentPanel,
        "",
        "GameFontDisableSmall"
    )
    moduleStatus:SetPoint(
        "TOPRIGHT",
        moduleUI.talentPanel,
        "TOPRIGHT",
        -18,
        -22
    )
    moduleStatus:SetJustifyH("RIGHT")
    moduleUI.talentPanel.moduleStatus = moduleStatus

    local desc = Label(
        moduleUI.talentPanel,
        "Shows the name of your active saved talent build plus useful talent context.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)
    moduleUI.talentPageEnabledCheck = Checkbox(
        moduleUI.talentPanel,
        "Enable Talent Loadout module",
        18,
        -68,
        function(value)
            BW:SetTalentLoadoutEnabled(value)
        end
    )
    moduleUI.ApplyModuleHeader(
        moduleUI.talentPanel, title, desc, moduleUI.talentPageEnabledCheck, moduleStatus,
        "Interface\\AddOns\\KayliiHelper\\Media\\NavTalent.tga"
    )

    moduleUI.talentPage = CreateFrame("Frame", nil, moduleUI.talentPanel)
    moduleUI.talentPage:SetPoint("TOPLEFT", moduleUI.talentPanel, "TOPLEFT", 0, -96)
    moduleUI.talentPage:SetPoint("BOTTOMRIGHT", moduleUI.talentPanel, "BOTTOMRIGHT", 0, 0)

    local displayCard = CreateSection(
        moduleUI.talentPage,
        14,
        -4,
        394,
        292,
        "Display",
        "Move and format the on-screen talent loadout panel."
    )

    moduleUI.talentFontSizeSlider = Slider(
        displayCard,
        "Font size",
        18,
        -78,
        176,
        10,
        28,
        1,
        function(value)
            return string.format("%d px", value)
        end,
        function(value)
            BW.db.talentLoadoutFontSize = value
            BW:ApplyTalentLoadoutSettings()
        end
    )

    moduleUI.talentOrientationButton = SortCycleButton(
        displayCard,
        "Orientation",
        18,
        -124,
        152,
        DISPLAY_ORIENTATION_ORDER,
        DISPLAY_ORIENTATION_LABELS,
        function(value)
            BW.db.talentLoadoutOrientation = value
            BW:ApplyTalentLoadoutSettings()
            BW:RefreshTalentLoadoutOptions()
        end
    )

    moduleUI.talentUnlockCheck = Checkbox(
        displayCard,
        "Unlock display to drag",
        14,
        -168,
        function(value)
            BW:SetTalentLoadoutUnlocked(value)
        end
    )

    moduleUI.talentShowBackgroundCheck = Checkbox(
        displayCard,
        "Show background",
        14,
        -204,
        function(value)
            BW.db.talentLoadoutShowBackground = value
            BW:ApplyTalentLoadoutSettings()
        end
    )

    local reset = CreateFrame(
        "Button",
        nil,
        displayCard,
        "UIPanelButtonTemplate"
    )
    reset:SetSize(124, 28)
    reset:SetPoint(
        "TOPLEFT",
        displayCard,
        "TOPLEFT",
        18,
        -244
    )
    reset:SetText("Reset position")
    reset:SetScript("OnClick", function()
        BW:ResetTalentLoadoutPosition()
    end)
    SkinButton(reset)

    local contentCard = CreateSection(
        moduleUI.talentPage,
        424,
        -8,
        394,
        292,
        "Talent Details",
        "Choose the important parts of the active talent build to display."
    )

    moduleUI.talentShowSpecCheck = Checkbox(
        contentCard,
        "Specialization",
        14,
        -72,
        function(value)
            BW.db.talentLoadoutShowSpec = value
            BW:ApplyTalentLoadoutSettings()
            BW:RefreshTalentLoadoutOptions()
        end
    )

    moduleUI.talentShowNameCheck = Checkbox(
        contentCard,
        "Saved loadout name",
        14,
        -108,
        function(value)
            BW.db.talentLoadoutShowName = value
            BW:ApplyTalentLoadoutSettings()
            BW:RefreshTalentLoadoutOptions()
        end
    )

    moduleUI.talentShowHeroCheck = Checkbox(
        contentCard,
        "Active Hero Talent tree",
        14,
        -144,
        function(value)
            BW.db.talentLoadoutShowHero = value
            BW:ApplyTalentLoadoutSettings()
            BW:RefreshTalentLoadoutOptions()
        end
    )

    local previewLabel = Label(
        contentCard,
        "Current build",
        "GameFontHighlight"
    )
    previewLabel:SetPoint(
        "TOPLEFT",
        contentCard,
        "TOPLEFT",
        18,
        -194
    )
    SetFontColor(previewLabel, THEME.subtext)

    moduleUI.talentPreviewText = Label(
        contentCard,
        "",
        "GameFontNormal"
    )
    moduleUI.talentPreviewText:SetPoint(
        "TOPLEFT",
        previewLabel,
        "BOTTOMLEFT",
        0,
        -10
    )
    moduleUI.talentPreviewText:SetWidth(350)
    moduleUI.talentPreviewText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.talentPreviewText, THEME.accent)
end

local function BuildRaidFrameSpecPage()
    moduleUI.raidSpecPanel = CreateFrame("Frame", nil, helperContent)
    moduleUI.raidSpecPanel:SetAllPoints(helperContent)

    local title = Label(moduleUI.raidSpecPanel, "Raid / Party Frame Spec", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", moduleUI.raidSpecPanel, "TOPLEFT", 18, -18)
    SetFontColor(title, THEME.text)

    local moduleStatus = Label(moduleUI.raidSpecPanel, "", "GameFontDisableSmall")
    moduleStatus:SetPoint("TOPRIGHT", moduleUI.raidSpecPanel, "TOPRIGHT", -18, -22)
    moduleStatus:SetJustifyH("RIGHT")
    moduleUI.raidSpecPanel.moduleStatus = moduleStatus

    local desc = Label(
        moduleUI.raidSpecPanel,
        "Save raid and party frame positions per specialization.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)
    moduleUI.raidSpecPageEnabledCheck = Checkbox(
        moduleUI.raidSpecPanel,
        "Enable Raid Frame Spec module",
        18,
        -68,
        function(value)
            if BW.SetRaidFrameSpecEnabled then BW:SetRaidFrameSpecEnabled(value) end
        end
    )
    moduleUI.ApplyModuleHeader(
        moduleUI.raidSpecPanel, title, desc, moduleUI.raidSpecPageEnabledCheck, moduleStatus,
        "Interface\\AddOns\\KayliiHelper\\Media\\NavRaid.tga"
    )
    moduleUI.raidSpecRequirementText = Label(
        moduleUI.raidSpecPanel,
        "Requires Ellesmere Frames",
        "GameFontHighlightSmall"
    )
    moduleUI.raidSpecRequirementText:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -2)
    SetFontColor(moduleUI.raidSpecRequirementText, THEME.accentHover)

    moduleUI.raidSpecPage = CreateFrame("Frame", nil, moduleUI.raidSpecPanel)
    moduleUI.raidSpecPage:SetPoint("TOPLEFT", moduleUI.raidSpecPanel, "TOPLEFT", 0, -96)
    moduleUI.raidSpecPage:SetPoint("BOTTOMRIGHT", moduleUI.raidSpecPanel, "BOTTOMRIGHT", 0, 0)

    local manageCard = CreateSection(
        moduleUI.raidSpecPage,
        14, -4, 804, 126,
        "Managed Frames",
        "Choose which Ellesmere group-frame containers should automatically follow your specialization."
    )

    moduleUI.raidSpecManageRaidCheck = Checkbox(
        manageCard,
        "Raid frames",
        18, -62,
        function(value)
            if BW.SetRaidFrameSpecManageRaid then BW:SetRaidFrameSpecManageRaid(value) end
        end
    )

    moduleUI.raidSpecManagePartyCheck = Checkbox(
        manageCard,
        "Party / 5-man frames",
        180, -62,
        function(value)
            if BW.SetRaidFrameSpecManageParty then BW:SetRaidFrameSpecManageParty(value) end
        end
    )

    local specLabel = Label(manageCard, "Playing spec", "GameFontHighlightSmall")
    specLabel:SetPoint("TOPLEFT", manageCard, "TOPLEFT", 424, -56)
    SetFontColor(specLabel, THEME.subtext)

    moduleUI.raidSpecCurrentSpecText = Label(manageCard, "", "GameFontNormal")
    moduleUI.raidSpecCurrentSpecText:SetPoint("LEFT", specLabel, "RIGHT", 10, 0)
    SetFontColor(moduleUI.raidSpecCurrentSpecText, THEME.accent)

    local configureLabel = Label(
        manageCard,
        "Configure spec:",
        "GameFontHighlightSmall"
    )
    configureLabel:SetPoint(
        "TOPLEFT",
        manageCard,
        "TOPLEFT",
        18,
        -92
    )
    SetFontColor(configureLabel, THEME.subtext)

    moduleUI.raidSpecSpecButtons = {}

    local specCount =
        GetNumSpecializations
        and GetNumSpecializations()
        or 0

    for index = 1, specCount do
        local specID, specName =
            GetSpecializationInfo(index)

        if specID then
            local buttonSpecID =
                specID

            local button = CreateFrame(
                "Button",
                nil,
                manageCard,
                "UIPanelButtonTemplate"
            )
            button:SetSize(108, 24)
            button:SetPoint(
                "TOPLEFT",
                manageCard,
                "TOPLEFT",
                116 + ((index - 1) * 116),
                -84
            )
            button:SetText(
                specName
                or ("Spec " .. tostring(specID))
            )
            button.specID =
                buttonSpecID

            button:SetScript(
                "OnClick",
                function()
                    if BW.SetRaidFrameSpecEditSpec then
                        BW:SetRaidFrameSpecEditSpec(
                            buttonSpecID
                        )
                    end
                end
            )

            SkinButton(button)

            moduleUI.raidSpecSpecButtons[
                #moduleUI.raidSpecSpecButtons + 1
            ] = button
        end
    end

    local raidTab = CreateFrame("Button", nil, moduleUI.raidSpecPage, "UIPanelButtonTemplate")
    raidTab:SetSize(132, 28)
    raidTab:SetPoint("TOPLEFT", moduleUI.raidSpecPage, "TOPLEFT", 14, -150)
    raidTab:SetText("Raid")
    SkinButton(raidTab)
    moduleUI.raidSpecRaidTab = raidTab

    local partyTab = CreateFrame("Button", nil, moduleUI.raidSpecPage, "UIPanelButtonTemplate")
    partyTab:SetSize(164, 28)
    partyTab:SetPoint("LEFT", raidTab, "RIGHT", 8, 0)
    partyTab:SetText("Party / 5-Man")
    SkinButton(partyTab)
    moduleUI.raidSpecPartyTab = partyTab

    local raidCard = CreateSection(
        moduleUI.raidSpecPage,
        14, -190, 804, 318,
        "Raid Frames",
        "Per-spec Raid position, orientation, and scale override. Leave it off to use Ellesmere exactly as configured."
    )
    moduleUI.raidSpecRaidCard = raidCard

    moduleUI.raidSpecRaidPositionText = Label(raidCard, "", "GameFontHighlightSmall")
    moduleUI.raidSpecRaidPositionText:SetPoint("TOPLEFT", raidCard, "TOPLEFT", 18, -82)
    moduleUI.raidSpecRaidPositionText:SetWidth(760)
    moduleUI.raidSpecRaidPositionText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.raidSpecRaidPositionText, THEME.subtext)

    moduleUI.raidSpecRaidLiveText = Label(raidCard, "", "GameFontDisableSmall")
    moduleUI.raidSpecRaidLiveText:SetPoint("TOPLEFT", raidCard, "TOPLEFT", 18, -108)
    moduleUI.raidSpecRaidLiveText:SetWidth(760)
    moduleUI.raidSpecRaidLiveText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.raidSpecRaidLiveText, THEME.muted)

    moduleUI.raidSpecRaidCustomCheck = Checkbox(
        raidCard,
        "Enable custom Raid settings for this spec",
        18,
        -142,
        function(value)
            if BW.SetRaidFrameSpecCustomEnabled then
                BW:SetRaidFrameSpecCustomEnabled(value)
            end
        end
    )

    moduleUI.raidSpecRaidOrientationButton = SortCycleButton(
        raidCard,
        "Orientation",
        18,
        -194,
        154,
        {
            "vertical",
            "horizontal",
        },
        {
            vertical = "Vertical",
            horizontal = "Horizontal",
        },
        function(value)
            if BW.SetRaidFrameSpecOrientation then
                BW:SetRaidFrameSpecOrientation(value)
            end
        end
    )

    moduleUI.raidSpecRaidScaleSlider = Slider(
        raidCard,
        "Raid scale",
        330,
        -194,
        210,
        50,
        125,
        5,
        function(value)
            return string.format("%d%%", value)
        end,
        function(value)
            if BW.SetRaidFrameSpecScaleValue then
                BW:SetRaidFrameSpecScaleValue(value)
            end
        end
    )

    moduleUI.raidSpecRaidMoverButton = CreateFrame("Button", nil, raidCard, "UIPanelButtonTemplate")
    moduleUI.raidSpecRaidMoverButton:SetSize(104, 28)
    moduleUI.raidSpecRaidMoverButton:SetPoint("TOPLEFT", raidCard, "TOPLEFT", 18, -238)
    moduleUI.raidSpecRaidMoverButton:SetText("Show mover")
    moduleUI.raidSpecRaidMoverButton:SetScript("OnClick", function()
        if BW.ToggleRaidFrameSpecMover then BW:ToggleRaidFrameSpecMover() end
    end)
    SkinButton(moduleUI.raidSpecRaidMoverButton)

    local raidSave = CreateFrame("Button", nil, raidCard, "UIPanelButtonTemplate")
    raidSave:SetSize(146, 28)
    raidSave:SetPoint("LEFT", moduleUI.raidSpecRaidMoverButton, "RIGHT", 8, 0)
    raidSave:SetText("Save mover position")
    raidSave:SetScript("OnClick", function()
        if BW.SaveRaidFrameSpecMoverPosition then BW:SaveRaidFrameSpecMoverPosition() end
    end)
    SkinButton(raidSave)
    moduleUI.raidSpecRaidSaveButton = raidSave

    local raidApply = CreateFrame("Button", nil, raidCard, "UIPanelButtonTemplate")
    raidApply:SetSize(104, 28)
    raidApply:SetPoint("TOPLEFT", raidCard, "TOPLEFT", 18, -276)
    raidApply:SetText("Apply saved")
    raidApply:SetScript("OnClick", function()
        if BW.ApplyRaidFrameSpecPosition then
            local specID =
                BW.GetRaidFrameSpecEditSpec
                and BW:GetRaidFrameSpecEditSpec()

            BW:ApplyRaidFrameSpecPosition(specID, true)
        end
    end)
    SkinButton(raidApply)
    moduleUI.raidSpecRaidApplyButton = raidApply

    local raidClear = CreateFrame("Button", nil, raidCard, "UIPanelButtonTemplate")
    raidClear:SetSize(92, 28)
    raidClear:SetPoint("LEFT", raidApply, "RIGHT", 8, 0)
    raidClear:SetText("Clear position")
    raidClear:SetScript("OnClick", function()
        if BW.ClearCurrentRaidFrameSpecPosition then BW:ClearCurrentRaidFrameSpecPosition() end
    end)
    SkinButton(raidClear)
    moduleUI.raidSpecRaidClearButton = raidClear

    local partyCard = CreateSection(
        moduleUI.raidSpecPage,
        14, -190, 804, 318,
        "Party / 5-Man Frames",
        "Per-spec Party position, orientation, and scale override. Safe to configure while solo; live changes apply only in a party."
    )
    moduleUI.raidSpecPartyCard = partyCard

    moduleUI.raidSpecPartyPositionText = Label(partyCard, "", "GameFontHighlightSmall")
    moduleUI.raidSpecPartyPositionText:SetPoint("TOPLEFT", partyCard, "TOPLEFT", 18, -82)
    moduleUI.raidSpecPartyPositionText:SetWidth(760)
    moduleUI.raidSpecPartyPositionText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.raidSpecPartyPositionText, THEME.subtext)

    moduleUI.raidSpecPartyLiveText = Label(partyCard, "", "GameFontDisableSmall")
    moduleUI.raidSpecPartyLiveText:SetPoint("TOPLEFT", partyCard, "TOPLEFT", 18, -108)
    moduleUI.raidSpecPartyLiveText:SetWidth(760)
    moduleUI.raidSpecPartyLiveText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.raidSpecPartyLiveText, THEME.muted)

    moduleUI.raidSpecPartyCustomCheck = Checkbox(
        partyCard,
        "Enable custom Party settings for this spec",
        18,
        -142,
        function(value)
            if BW.SetPartyFrameSpecCustomEnabled then
                BW:SetPartyFrameSpecCustomEnabled(value)
            end
        end
    )

    moduleUI.raidSpecPartyOrientationButton = SortCycleButton(
        partyCard,
        "Orientation",
        18,
        -194,
        154,
        {
            "vertical",
            "horizontal",
        },
        {
            vertical = "Vertical",
            horizontal = "Horizontal",
        },
        function(value)
            if BW.SetPartyFrameSpecOrientation then
                BW:SetPartyFrameSpecOrientation(value)
            end
        end
    )

    moduleUI.raidSpecPartyScaleSlider = Slider(
        partyCard,
        "Party scale",
        330,
        -194,
        210,
        50,
        125,
        5,
        function(value)
            return string.format("%d%%", value)
        end,
        function(value)
            if BW.SetPartyFrameSpecScaleValue then
                BW:SetPartyFrameSpecScaleValue(value)
            end
        end
    )

    moduleUI.raidSpecPartyMoverButton = CreateFrame("Button", nil, partyCard, "UIPanelButtonTemplate")
    moduleUI.raidSpecPartyMoverButton:SetSize(104, 28)
    moduleUI.raidSpecPartyMoverButton:SetPoint("TOPLEFT", partyCard, "TOPLEFT", 18, -238)
    moduleUI.raidSpecPartyMoverButton:SetText("Show mover")
    moduleUI.raidSpecPartyMoverButton:SetScript("OnClick", function()
        if BW.TogglePartyFrameSpecMover then BW:TogglePartyFrameSpecMover() end
    end)
    SkinButton(moduleUI.raidSpecPartyMoverButton)

    local partySave = CreateFrame("Button", nil, partyCard, "UIPanelButtonTemplate")
    partySave:SetSize(146, 28)
    partySave:SetPoint("LEFT", moduleUI.raidSpecPartyMoverButton, "RIGHT", 8, 0)
    partySave:SetText("Save mover position")
    partySave:SetScript("OnClick", function()
        if BW.SavePartyFrameSpecMoverPosition then BW:SavePartyFrameSpecMoverPosition() end
    end)
    SkinButton(partySave)
    moduleUI.raidSpecPartySaveButton = partySave

    local partyApply = CreateFrame("Button", nil, partyCard, "UIPanelButtonTemplate")
    partyApply:SetSize(104, 28)
    partyApply:SetPoint("TOPLEFT", partyCard, "TOPLEFT", 18, -276)
    partyApply:SetText("Apply saved")
    partyApply:SetScript("OnClick", function()
        if BW.ApplyPartyFrameSpecPosition then
            local specID =
                BW.GetRaidFrameSpecEditSpec
                and BW:GetRaidFrameSpecEditSpec()

            BW:ApplyPartyFrameSpecPosition(specID, true)
        end
    end)
    SkinButton(partyApply)
    moduleUI.raidSpecPartyApplyButton = partyApply

    local partyClear = CreateFrame("Button", nil, partyCard, "UIPanelButtonTemplate")
    partyClear:SetSize(92, 28)
    partyClear:SetPoint("LEFT", partyApply, "RIGHT", 8, 0)
    partyClear:SetText("Clear position")
    partyClear:SetScript("OnClick", function()
        if BW.ClearCurrentPartyFrameSpecPosition then BW:ClearCurrentPartyFrameSpecPosition() end
    end)
    SkinButton(partyClear)
    moduleUI.raidSpecPartyClearButton = partyClear

    local function SetRaidSpecSubTab(view)
        view = view == "party" and "party" or "raid"
        moduleUI.raidSpecSubTab = view

        if view == "raid" then
            raidCard:Show()
            partyCard:Hide()
        else
            raidCard:Hide()
            partyCard:Show()
        end

        raidTab:SetEnabled(view ~= "raid")
        partyTab:SetEnabled(view ~= "party")
        SetButtonActiveState(raidTab, view == "raid")
        SetButtonActiveState(partyTab, view == "party")
    end

    moduleUI.SetRaidSpecSubTab = SetRaidSpecSubTab
    raidTab:SetScript("OnClick", function() SetRaidSpecSubTab("raid") end)
    partyTab:SetScript("OnClick", function() SetRaidSpecSubTab("party") end)
    SetRaidSpecSubTab("raid")

    local summaryCard = CreateSection(
        moduleUI.raidSpecPage,
        14, -526, 804, 142,
        "Saved Specializations",
        "The spec you are currently configuring is highlighted. Raid and Party overrides are summarized on one line."
    )

    moduleUI.raidSpecSavedListText = Label(summaryCard, "", "GameFontHighlightSmall")
    moduleUI.raidSpecSavedListText:SetPoint("TOPLEFT", summaryCard, "TOPLEFT", 18, -70)
    moduleUI.raidSpecSavedListText:SetWidth(760)
    moduleUI.raidSpecSavedListText:SetJustifyH("LEFT")
    moduleUI.raidSpecSavedListText:SetJustifyV("TOP")
    moduleUI.raidSpecSavedListText:SetSpacing(4)
    SetFontColor(moduleUI.raidSpecSavedListText, THEME.subtext)

end

moduleUI.settingsLauncherSuppressAutoOpen = false

local function ResetBlizzardSettingsSelection()
    -- Settings.OpenToCategory accepts no category and opens the normal
    -- Blizzard Settings landing/default view. Doing this before hiding the
    -- panel prevents Kaylii Helper from becoming the remembered category for
    -- the next time the player presses Escape -> Options.
    if Settings and Settings.OpenToCategory then
        local ok = pcall(Settings.OpenToCategory)
        if ok then
            return true
        end
    end

    if C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel then
        local ok = pcall(C_SettingsUtil.OpenSettingsPanel)
        if ok then
            return true
        end
    end

    return false
end

local function CloseBlizzardSettings()
    -- Kaylii Helper is a standalone UIParent window, so closing Blizzard's
    -- Settings panel does not close our configuration window.
    if SettingsPanel and SettingsPanel:IsShown() then
        moduleUI.settingsLauncherSuppressAutoOpen = true
        ResetBlizzardSettingsSelection()

        -- Let Blizzard commit the category change first, then close Settings.
        C_Timer.After(0, function()
            if SettingsPanel and SettingsPanel:IsShown() then
                if HideUIPanel then
                    HideUIPanel(SettingsPanel)
                else
                    SettingsPanel:Hide()
                end
            end

            C_Timer.After(0, function()
                moduleUI.settingsLauncherSuppressAutoOpen = false
            end)
        end)
        return
    end

    -- Legacy/fallback name for older client UI layouts.
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        moduleUI.settingsLauncherSuppressAutoOpen = true

        if HideUIPanel then
            HideUIPanel(InterfaceOptionsFrame)
        else
            InterfaceOptionsFrame:Hide()
        end

        C_Timer.After(0, function()
            moduleUI.settingsLauncherSuppressAutoOpen = false
        end)
    end
end

local function OpenFromBlizzardSettings(view)
    if moduleUI.settingsLauncherSuppressAutoOpen then
        return
    end

    if BW.OpenHelperWindow then
        BW:OpenHelperWindow(view)
    end

    -- Delay one frame so the standalone window is fully shown before the
    -- Blizzard Settings category is reset and the panel is hidden.
    C_Timer.After(0, CloseBlizzardSettings)
end

local function CreateSettingsLauncher(
    titleText,
    descriptionText,
    buttonText,
    view
)
    local frame = CreateFrame("Frame")
    frame:SetSize(720, 650)

    local title = Label(
        frame,
        titleText,
        "GameFontNormalHuge"
    )
    title:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        16,
        -16
    )

    local desc = Label(
        frame,
        descriptionText,
        "GameFontHighlight"
    )
    desc:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -12
    )
    desc:SetWidth(650)
    desc:SetJustifyH("LEFT")

    local open = CreateFrame(
        "Button",
        nil,
        frame,
        "UIPanelButtonTemplate"
    )
    open:SetSize(190, 30)
    open:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        16,
        -100
    )
    open:SetText(buttonText)
    open:SetScript("OnClick", function()
        OpenFromBlizzardSettings(view)
    end)

    local hint = Label(
        frame,
        "Kaylii Helper uses its own movable/resizable configuration window so lists and future modules are not constrained by the Blizzard Settings viewport.",
        "GameFontDisableSmall"
    )
    hint:SetPoint(
        "TOPLEFT",
        open,
        "BOTTOMLEFT",
        0,
        -14
    )
    hint:SetWidth(650)
    hint:SetJustifyH("LEFT")

    frame:SetScript("OnShow", function()
        if moduleUI.settingsLauncherSuppressAutoOpen then
            return
        end

        C_Timer.After(0, function()
            if frame:IsShown()
                and not moduleUI.settingsLauncherSuppressAutoOpen then

                OpenFromBlizzardSettings(view)
            end
        end)
    end)

    return frame
end

local function FinalizeOptions(self)
    settingsRootPanel = CreateSettingsLauncher(
        "Kaylii Helper",
        "Open the Kaylii Helper configuration window and choose a module.",
        "Open Kaylii Helper",
        "home"
    )

    settingsBuffPanel = CreateSettingsLauncher(
        "Buff White List",
        "Configure target/focus aura layout, whitelist, blacklist, sorting and text.",
        "Open Buff White List",
        "buff"
    )

    settingsLustPanel = CreateSettingsLauncher(
        "Lust Up",
        "Configure lust readiness tracking, indicator and voice notification.",
        "Open Lust Up",
        "lust"
    )

    moduleUI.settingsStatsPanel = CreateSettingsLauncher(
        "My Stats",
        "Configure the movable Crit, Haste, Mastery and Versatility display.",
        "Open My Stats",
        "stats"
    )

    moduleUI.settingsSurvivalPanel = CreateSettingsLauncher(
        "Survival Helper",
        "Configure HP-threshold suggestions for personals, Healthstones, and healing potions.",
        "Open Survival Helper",
        "survival"
    )

    moduleUI.settingsTalentPanel = CreateSettingsLauncher(
        "Talent Loadout",
        "Configure the active talent loadout name, specialization and Hero Talent display.",
        "Open Talent Loadout",
        "talent"
    )

    moduleUI.settingsRaidSpecPanel = CreateSettingsLauncher(
        "Raid Frame Spec",
        "Save and automatically apply Ellesmere Raid and Party / 5-man positions per specialization.",
        "Open Raid Frame Spec",
        "raidspec"
    )

    local rootCategory = Settings.RegisterCanvasLayoutCategory(
        settingsRootPanel,
        ROOT_PANEL_NAME
    )

    local buffCategory = Settings.RegisterCanvasLayoutSubcategory(
        rootCategory,
        settingsBuffPanel,
        BUFF_PANEL_NAME
    )

    local lustCategory = Settings.RegisterCanvasLayoutSubcategory(
        rootCategory,
        settingsLustPanel,
        LUST_PANEL_NAME
    )

    local statsCategory = Settings.RegisterCanvasLayoutSubcategory(
        rootCategory,
        moduleUI.settingsStatsPanel,
        STATS_PANEL_NAME
    )

    local survivalCategory = Settings.RegisterCanvasLayoutSubcategory(
        rootCategory,
        moduleUI.settingsSurvivalPanel,
        SURVIVAL_PANEL_NAME
    )

    local talentCategory = Settings.RegisterCanvasLayoutSubcategory(
        rootCategory,
        moduleUI.settingsTalentPanel,
        TALENT_PANEL_NAME
    )

    local raidSpecCategory = Settings.RegisterCanvasLayoutSubcategory(
        rootCategory,
        moduleUI.settingsRaidSpecPanel,
        RAID_SPEC_PANEL_NAME
    )

    Settings.RegisterAddOnCategory(rootCategory)

    if SettingsPanel and not self.settingsPanelOpenGuardHooked then
        self.settingsPanelOpenGuardHooked = true

        SettingsPanel:HookScript("OnShow", function()
            moduleUI.settingsLauncherSuppressAutoOpen = true

            C_Timer.After(0, function()
                moduleUI.settingsLauncherSuppressAutoOpen = false
            end)
        end)
    end

    self.settingsCategory = rootCategory
    self.buffWhitelistSettingsCategory = buffCategory
    self.lustUpSettingsCategory = lustCategory
    self.statsSettingsCategory = statsCategory
    self.survivalHelperSettingsCategory = survivalCategory
    self.talentLoadoutSettingsCategory = talentCategory
    self.raidFrameSpecSettingsCategory = raidSpecCategory

    panel:SetScript("OnShow", function()
        BW:RefreshOptions()

        local enabled =
            BW.db and BW.db.buffWhitelistModuleEnabled ~= false

        if panel.moduleStatus then
            panel.moduleStatus:SetText(
                enabled
                and "|cff4d9fffModule enabled|r"
                or "|cffff5555Module disabled|r"
            )
        end

        if enabled and mainView == "layout" then
            BW:RefreshLayoutPreview()
        elseif not enabled and BW.HideLayoutPreview then
            BW:HideLayoutPreview()
        end
    end)

    lustPanel:SetScript("OnShow", function()
        if BW.RefreshLustUpOptions then
            BW:RefreshLustUpOptions()
        end
    end)

    moduleUI.statsPanel:SetScript("OnShow", function()
        BW:RefreshStatsOptions()
    end)

    moduleUI.survivalPanel:SetScript("OnShow", function()
        BW:RefreshSurvivalOptions()
    end)

    moduleUI.talentPanel:SetScript("OnShow", function()
        BW:RefreshTalentLoadoutOptions()
    end)

    moduleUI.raidSpecPanel:SetScript("OnShow", function()
        BW:RefreshRaidFrameSpecOptions()
    end)

    SLASH_KAYLIIHELPER1 = "/kh"
    SLASH_KAYLIIHELPER2 = "/kaylii"
    SLASH_KAYLIIHELPER3 = "/kayliihelper"

    SlashCmdList.KAYLIIHELPER = function()
        BW:OpenHelperWindow("home")
    end

    SLASH_BUFFWHITELIST1 = "/bwl"
    SLASH_BUFFWHITELIST2 = "/buffwhitelist"

    SlashCmdList.BUFFWHITELIST = function()
        BW:OpenHelperWindow("buff")
    end

    SLASH_LUSTUP1 = "/lustup"

    SlashCmdList.LUSTUP = function()
        BW:OpenHelperWindow("lust")
    end

    SLASH_KAYLIISTATS1 = "/khstats"

    SlashCmdList.KAYLIISTATS = function()
        BW:OpenHelperWindow("stats")
    end

    SLASH_KAYLIISURVIVAL1 = "/khsurvival"
    SLASH_KAYLIISURVIVAL2 = "/khsurv"

    SlashCmdList.KAYLIISURVIVAL = function()
        BW:OpenHelperWindow("survival")
    end

    SLASH_KAYLIITALENTS1 = "/khtalents"

    SlashCmdList.KAYLIITALENTS = function()
        BW:OpenHelperWindow("talent")
    end

    SLASH_KAYLIIRAIDSPEC1 = "/khraid"
    SLASH_KAYLIIRAIDSPEC2 = "/khrf"

    SlashCmdList.KAYLIIRAIDSPEC = function()
        BW:OpenHelperWindow("raidspec")
    end

    SLASH_KAYLIIMINIMAP1 = "/khminimap"

    SlashCmdList.KAYLIIMINIMAP = function()
        if BW.RestoreMinimapButton then
            BW:RestoreMinimapButton()
        end
    end

    SetAuraListMode("target")
    SetAuraEditMode("filter")
    SetMainView("layout")
    SetHelperView("home")
    self:RefreshOptions()
    UpdateDirectionButtons()
    UpdateAuraListWidth()
end

function BW:CreateOptions()
    if panel then
        return
    end

    BuildHelperWindow()
    BuildRootPanel()
    BuildPanelShell()
    BuildLayoutPage()
    BuildTextPage()
    BuildAuraPage()
    BuildLustPage()
    BuildStatsPage()
    BuildSurvivalPage()
    BuildTalentLoadoutPage()
    BuildRaidFrameSpecPage()
    FinalizeOptions(self)
    StyleWindowPanels()
    SkinButtonTree(helperWindow)
    StyleRows()
end
