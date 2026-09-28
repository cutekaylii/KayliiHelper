local ADDON_NAME, BW = ...

local ROOT_PANEL_NAME = "Kaylii Helper"
local BUFF_PANEL_NAME = "Buff White List"
local LUST_PANEL_NAME = "Lust Up"
local STATS_PANEL_NAME = "My Stats"
local SURVIVAL_PANEL_NAME = "Survival Helper"
local TALENT_PANEL_NAME = "Talent Loadout"
local RAID_SPEC_PANEL_NAME = "Raid Frame Spec"
local ROW_HEIGHT = 38

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

local previewCheck
local iconSizeSlider

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
local lustUpStatusText
local lustUpCustomListText
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

local buffGrowLeftButton
local buffGrowRightButton
local buffGrowUpButton
local buffGrowDownButton

local debuffGrowLeftButton
local debuffGrowRightButton
local debuffGrowUpButton
local debuffGrowDownButton

local detachedButton
local aboveButton
local belowButton

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
    -- Kaylii blue theme.
    accent = { 0.20, 0.58, 1.00, 1 },
    accentHover = { 0.32, 0.68, 1.00, 1 },
    text = { 0.96, 0.98, 1.00, 1 },
    subtext = { 0.72, 0.79, 0.88, 1 },
    muted = { 0.47, 0.55, 0.66, 1 },
    panel = { 0.035, 0.055, 0.085, 0.98 },
    panelAlt = { 0.055, 0.075, 0.115, 0.98 },
    section = { 0.07, 0.095, 0.145, 0.95 },
    button = { 0.065, 0.105, 0.175, 0.98 },
    buttonHover = { 0.08, 0.18, 0.32, 0.98 },
    buttonActive = { 0.055, 0.22, 0.44, 0.99 },
    border = { 0.14, 0.23, 0.35, 1 },
    borderAccent = { 0.10, 0.38, 0.82, 1 },
}

local THEME_BACKDROP = {
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

local function ApplyBackdrop(frame, bg, border)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop(THEME_BACKDROP)
    bg = bg or THEME.section
    border = border or THEME.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
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
        edge:SetColorTexture(
            color[1],
            color[2],
            color[3],
            color[4] or 1
        )
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
        bg = { 0.055, 0.07, 0.10, 0.86 }
        border = THEME.border
        textColor = THEME.muted
    else
        bg = THEME.button
        border = THEME.border
    end

    button._khBg:SetColorTexture(
        bg[1], bg[2], bg[3], bg[4] or 1
    )
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
    bg:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button._khBg = bg

    local top = button:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    top:SetHeight(1)

    local bottom = button:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)

    local left = button:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)

    local right = button:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)

    button._khBorders = { top, bottom, left, right }
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

local function SkinCheckbox(check, label)
    if not check or check._khStyled then
        return
    end

    check:SetSize(22, 22)

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

    local box = CreateFrame("Frame", nil, check, "BackdropTemplate")
    box:SetAllPoints(check)
    box:SetFrameLevel(check:GetFrameLevel())
    ApplyBackdrop(box, { 0.05, 0.07, 0.10, 0.98 }, THEME.border)

    local hover = box:CreateTexture(nil, "ARTWORK")
    hover:SetAllPoints(box)
    hover:SetColorTexture(
        THEME.accentHover[1],
        THEME.accentHover[2],
        THEME.accentHover[3],
        0.10
    )
    hover:Hide()

    local fill = box:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
    fill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 4)
    fill:SetColorTexture(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        0.95
    )

    local gloss = box:CreateTexture(nil, "OVERLAY")
    gloss:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    gloss:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
    gloss:SetHeight(5)
    gloss:SetColorTexture(1, 1, 1, 0.16)

    local function UpdateCheckboxVisual(self)
        local enabled = self.IsEnabled and self:IsEnabled()
        local checked = self:GetChecked()

        if checked then
            fill:Show()
            gloss:Show()
            box:SetBackdropBorderColor(
                THEME.accent[1],
                THEME.accent[2],
                THEME.accent[3],
                1
            )
        else
            fill:Hide()
            gloss:Hide()
            box:SetBackdropBorderColor(
                THEME.border[1],
                THEME.border[2],
                THEME.border[3],
                THEME.border[4]
            )
        end

        if not enabled then
            box:SetAlpha(0.45)
            if label then
                SetFontColor(label, THEME.muted)
            end
        else
            box:SetAlpha(1)
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

    check:HookScript("OnEnter", function(self)
        hover:Show()

        if not self:GetChecked() then
            box:SetBackdropBorderColor(
                THEME.accentHover[1],
                THEME.accentHover[2],
                THEME.accentHover[3],
                0.95
            )
        end
    end)

    check:HookScript("OnLeave", function(self)
        hover:Hide()
        UpdateCheckboxVisual(self)
    end)

    check._khStyled = true
    check._khBox = box
    check._khFill = fill
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
    ApplyBackdrop(box, { 0.05, 0.07, 0.10, 0.98 }, THEME.border)
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

    local regions = { slider:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType
            and region:GetObjectType() == "Texture" then

            local name = region.GetTexture and region:GetTexture()
            if type(name) == "string" then
                region:SetTexture(nil)
                region:SetAlpha(0)
                region:Hide()
            end
        end
    end

    local track = CreateFrame("Frame", nil, slider, "BackdropTemplate")
    track:SetFrameLevel(slider:GetFrameLevel() - 1)
    track:SetPoint("LEFT", slider, "LEFT", 8, -1)
    track:SetPoint("RIGHT", slider, "RIGHT", -8, -1)
    track:SetHeight(8)
    ApplyBackdrop(track, { 0.045, 0.075, 0.13, 1 }, THEME.border)

    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 1, 1)
    fill:SetWidth(0)
    fill:SetColorTexture(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        0.85
    )

    local fillGloss = track:CreateTexture(nil, "OVERLAY")
    fillGloss:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
    fillGloss:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
    fillGloss:SetHeight(3)
    fillGloss:SetColorTexture(1, 1, 1, 0.16)

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
        thumb:SetSize(12, 18)
        thumb:SetVertexColor(
            THEME.accentHover[1],
            THEME.accentHover[2],
            THEME.accentHover[3],
            1
        )
    end

    local function UpdateSliderVisual(self, value)
        local minValue, maxValue = self:GetMinMaxValues()
        value = tonumber(value) or tonumber(self:GetValue()) or minValue or 0

        if not minValue or not maxValue or maxValue <= minValue then
            fill:SetWidth(0)
            return
        end

        local ratio = (value - minValue) / (maxValue - minValue)
        if ratio < 0 then
            ratio = 0
        elseif ratio > 1 then
            ratio = 1
        end

        local usableWidth = math.max(0, track:GetWidth() - 2)
        local fillWidth = math.floor((usableWidth * ratio) + 0.5)
        if fillWidth < 2 and ratio > 0 then
            fillWidth = 2
        end

        fill:SetWidth(fillWidth)
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
        track:SetAlpha(1)
    end)
    slider:HookScript("OnDisable", function()
        track:SetAlpha(0.45)
    end)

    slider._khStyled = true
    slider._khTrack = track
    slider._khFill = fill
    slider._khUpdateVisual = UpdateSliderVisual

    UpdateSliderVisual(slider)
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

    local accent = frame:CreateTexture(nil, "BACKGROUND")
    accent:SetColorTexture(
        THEME.accent[1],
        THEME.accent[2],
        THEME.accent[3],
        0.65
    )
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    accent:SetHeight(1)

    return frame
end

local function CreateSection(parent, x, y, width, height, titleText, subtitleText)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    ApplyBackdrop(frame, THEME.section, THEME.border)
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetColorTexture(THEME.accent[1], THEME.accent[2], THEME.accent[3], 0.85)
    line:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    line:SetHeight(1)
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
            local bg = CreateFrame("Frame", nil, row, "BackdropTemplate")
            bg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            bg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, -1)
            bg:SetFrameLevel(row:GetFrameLevel() - 1)
            ApplyBackdrop(bg, index % 2 == 0 and { 0.08, 0.10, 0.14, 0.92 } or { 0.06, 0.08, 0.11, 0.92 }, THEME.border)
            row._khRowBg = bg
        end
        if row.typeText then SetFontColor(row.typeText, THEME.accent) end
        if row.name then SetFontColor(row.name, THEME.text) end
        if row.idText then SetFontColor(row.idText, THEME.subtext) end
        if row.remove then SkinButton(row.remove) end
        if row.show then SkinCheckbox(row.show) end
    end
end

local function StyleWindowPanels()
    if helperWindow then ApplyBackdrop(helperWindow, THEME.panel, THEME.borderAccent) end
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

    local menuWidth = math.max(width or 220, 260)
    local visibleRows = math.min(#choices, 12)
    local menuHeight = math.max(36, (visibleRows * 27) + 10)

    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(500)
    menu:SetClampedToScreen(true)
    menu:SetSize(menuWidth, menuHeight)
    ApplyBackdrop(menu, THEME.panelAlt, THEME.borderAccent)
    menu:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -28, 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(menuWidth - 36, math.max(menuHeight - 8, (#choices * 27) + 4))
    scroll:SetScrollChild(content)

    button._khChoiceButtons = {}
    button._khChoices = choices
    button._khValue = nil
    button._khMenu = menu

    for index, choice in ipairs(choices) do
        local row = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        row:SetSize(menuWidth - 40, 24)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((index - 1) * 27))
        row:SetText(choice.label or tostring(choice.key))
        row:SetScript("OnClick", function()
            button:SetValue(choice.key)
            menu:Hide()
            if onSelect then
                onSelect(choice.key)
            end
        end)
        SkinButton(row)
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

        self:SetText(label .. "  v")
    end

    function button:GetValue()
        return self._khValue
    end

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

local function Checkbox(parent, text, x, y, callback)
    local check = CreateFrame(
        "CheckButton",
        nil,
        parent,
        "UICheckButtonTemplate"
    )

    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local label = Label(parent, text, "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    SetFontColor(label, THEME.text)

    check:SetScript("OnClick", function(self)
        callback(self:GetChecked() and true or false)
    end)

    SkinCheckbox(check, label)
    check.Label = label
    return check
end

local VALUE_BOX_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

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
    box:SetBackdropColor(0.05, 0.07, 0.10, 0.98)
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

    local button = CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
    )
    button:SetSize(150, 24)
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)

    button._fontKey = "FRIZ"

    local function SetDisplay(key)
        if not FONT_LABELS[key] then
            key = "FRIZ"
        end

        button._fontKey = key
        button:SetText(FONT_LABELS[key])
    end

    button.SetDisplayValue = function(self, key)
        SetDisplay(key)
    end

    button:SetScript("OnClick", function(self)
        local currentIndex = 1

        for i, key in ipairs(FONT_ORDER) do
            if key == self._fontKey then
                currentIndex = i
                break
            end
        end

        local nextIndex = currentIndex + 1
        if nextIndex > #FONT_ORDER then
            nextIndex = 1
        end

        local key = FONT_ORDER[nextIndex]
        SetDisplay(key)
        callback(key)
    end)

    SkinButton(button)
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

    local button = CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
    )
    button:SetSize(width, 24)
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)

    button._value = order[1]

    button.SetDisplayValue = function(self, value)
        if not labels[value] then
            value = order[1]
        end

        self._value = value
        self:SetText(labels[value])
    end

    button:SetScript("OnClick", function(self)
        local current = 1

        for index, value in ipairs(order) do
            if value == self._value then
                current = index
                break
            end
        end

        local nextIndex = current + 1
        if nextIndex > #order then
            nextIndex = 1
        end

        local value = order[nextIndex]
        self:SetDisplayValue(value)
        callback(value)
    end)

    SkinButton(button)
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

    local button = CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
    )
    button:SetSize(90, 24)
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)
    button._value = "OUTLINE"

    button.SetDisplayValue = function(self, value)
        if not OUTLINE_LABELS[value] then
            value = "OUTLINE"
        end

        self._value = value
        self:SetText(OUTLINE_LABELS[value])
    end

    button:SetScript("OnClick", function(self)
        local current = 1

        for i, value in ipairs(OUTLINE_ORDER) do
            if value == self._value then
                current = i
                break
            end
        end

        current = current + 1
        if current > #OUTLINE_ORDER then
            current = 1
        end

        local value = OUTLINE_ORDER[current]
        self:SetDisplayValue(value)
        callback(value)
    end)

    SkinButton(button)
    return button
end

local function ColorButton(
    parent,
    labelText,
    x,
    y,
    callback
)
    local label = Label(parent, labelText, "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local button = CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
    )
    button:SetSize(72, 24)
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)
    button:SetText("Color")

    local swatch = button:CreateTexture(nil, "OVERLAY")
    swatch._khKeep = true
    swatch:SetSize(14, 14)
    swatch:SetPoint("RIGHT", button, "RIGHT", -6, 0)
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
    icon:SetSize(30, 30)
    icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon = icon

    local show = CreateFrame(
        "CheckButton",
        nil,
        row,
        "UICheckButtonTemplate"
    )

    show:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    row.show = show

    local typeText = Label(row, "", "GameFontDisableSmall")
    typeText:SetPoint("LEFT", show, "RIGHT", 3, 9)
    typeText:SetWidth(62)
    typeText:SetJustifyH("LEFT")
    row.typeText = typeText

    local name = Label(row, "", "GameFontNormal")
    name:SetPoint("LEFT", typeText, "RIGHT", 2, 0)
    name:SetWidth(300)
    name:SetJustifyH("LEFT")
    row.name = name

    local idText = Label(row, "", "GameFontDisableSmall")
    idText:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
    idText:SetWidth(300)
    idText:SetJustifyH("LEFT")
    row.idText = idText

    local remove = CreateFrame(
        "Button",
        nil,
        row,
        "UIPanelButtonTemplate"
    )

    remove:SetSize(72, 22)
    remove:SetPoint("RIGHT", row, "RIGHT", -6, 0)
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

    detachedButton:SetEnabled(mode ~= "detached")
    aboveButton:SetEnabled(mode ~= "aboveBuffs")
    belowButton:SetEnabled(mode ~= "belowBuffs")
end


local function UpdateDirectionButtons()
    -- Disabled button = currently selected direction.
    buffGrowLeftButton:SetEnabled(not BW.db.buffGrowLeft)
    buffGrowRightButton:SetEnabled(BW.db.buffGrowLeft)

    buffGrowUpButton:SetEnabled(BW.db.buffGrowDown)
    buffGrowDownButton:SetEnabled(not BW.db.buffGrowDown)

    debuffGrowLeftButton:SetEnabled(not BW.db.debuffGrowLeft)
    debuffGrowRightButton:SetEnabled(BW.db.debuffGrowLeft)

    debuffGrowUpButton:SetEnabled(BW.db.debuffGrowDown)
    debuffGrowDownButton:SetEnabled(not BW.db.debuffGrowDown)
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
            local textWidth = math.max(220, width - 245)
            row.name:SetWidth(textWidth)
            row.idText:SetWidth(textWidth)
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
    ApplyBackdrop(helperWindow, THEME.panel, THEME.borderAccent)

    local screenWidth = UIParent:GetWidth() or 1200
    local screenHeight = UIParent:GetHeight() or 900
    local maxWidth = math.max(900, screenWidth - 30)
    local maxHeight = math.max(700, screenHeight - 30)
    -- The configuration pages use an ~836px two-column content layout.
    -- With the 216px sidebar offset and outer padding, 1020px allowed the
    -- content cards to extend beyond the right edge at minimum size.
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
    ApplyBackdrop(titleBar, { 0.05, 0.07, 0.09, 0.98 }, THEME.border)
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

    local accent = titleBar:CreateTexture(nil, "BORDER")
    accent:SetColorTexture(THEME.accent[1], THEME.accent[2], THEME.accent[3], 0.85)
    accent:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 18, 0)
    accent:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -18, 0)
    accent:SetHeight(1)

    moduleUI.helperMinimizeButton = CreateFrame(
        "Button",
        nil,
        titleBar,
        "BackdropTemplate"
    )
    moduleUI.helperMinimizeButton:SetSize(30, 30)
    moduleUI.helperMinimizeButton:SetPoint(
        "TOPRIGHT",
        titleBar,
        "TOPRIGHT",
        -50,
        -14
    )
    ApplyBackdrop(
        moduleUI.helperMinimizeButton,
        { 0.045, 0.065, 0.095, 0.98 },
        THEME.border
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
        self:SetBackdropColor(
            THEME.buttonHover[1],
            THEME.buttonHover[2],
            THEME.buttonHover[3],
            THEME.buttonHover[4] or 1
        )
        self:SetBackdropBorderColor(
            THEME.accent[1],
            THEME.accent[2],
            THEME.accent[3],
            1
        )
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
        self:SetBackdropColor(0.045, 0.065, 0.095, 0.98)
        self:SetBackdropBorderColor(
            THEME.border[1],
            THEME.border[2],
            THEME.border[3],
            THEME.border[4] or 1
        )
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
        titleBar,
        "BackdropTemplate"
    )
    close:SetSize(30, 30)
    close:SetPoint(
        "TOPRIGHT",
        titleBar,
        "TOPRIGHT",
        -14,
        -14
    )
    ApplyBackdrop(
        close,
        { 0.045, 0.065, 0.095, 0.98 },
        THEME.border
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
        self:SetBackdropColor(
            THEME.buttonHover[1],
            THEME.buttonHover[2],
            THEME.buttonHover[3],
            THEME.buttonHover[4] or 1
        )
        self:SetBackdropBorderColor(
            THEME.accent[1],
            THEME.accent[2],
            THEME.accent[3],
            1
        )
        closeText:SetTextColor(
            THEME.accentHover[1],
            THEME.accentHover[2],
            THEME.accentHover[3],
            1
        )
    end)

    close:SetScript("OnLeave", function(self)
        self:SetBackdropColor(
            0.045,
            0.065,
            0.095,
            0.98
        )
        self:SetBackdropBorderColor(
            THEME.border[1],
            THEME.border[2],
            THEME.border[3],
            THEME.border[4] or 1
        )
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
    sidebar:SetPoint("TOPLEFT", helperWindow, "TOPLEFT", 14, -96)
    sidebar:SetPoint("BOTTOMLEFT", helperWindow, "BOTTOMLEFT", 14, 14)
    sidebar:SetWidth(188)
    ApplyBackdrop(sidebar, { 0.07, 0.09, 0.12, 0.98 }, THEME.border)

    local modulesLabel = Label(sidebar, "MODULES", "GameFontDisableSmall")
    modulesLabel:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 16, -16)
    SetFontColor(modulesLabel, THEME.muted)

    local function NavButton(text, y, view)
        local button = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
        button:SetSize(156, 34)
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 16, y)
        button:SetText(text)
        button:SetScript("OnClick", function() SetHelperView(view) end)
        SkinButton(button)
        return button
    end

    helperHomeButton = NavButton("Kaylii Helper", -44, "home")
    helperBuffButton = NavButton("Buff White List", -84, "buff")
    helperLustButton = NavButton("Lust Up", -124, "lust")
    moduleUI.helperStatsButton = NavButton("My Stats", -164, "stats")
    moduleUI.helperTalentButton = NavButton("Talent Loadout", -204, "talent")
    moduleUI.helperRaidSpecButton = NavButton("Raid Frame Spec", -244, "raidspec")
    moduleUI.helperSurvivalButton = NavButton("Survival Helper", -284, "survival")

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
    openHelp:SetWidth(150)
    openHelp:SetJustifyH("LEFT")
    SetFontColor(openHelp, THEME.subtext)

    local resizeHint = Label(sidebar, "Drag the lower-right corner to resize.", "GameFontDisableSmall")
    resizeHint:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 16, 16)
    resizeHint:SetWidth(150)
    resizeHint:SetJustifyH("LEFT")
    SetFontColor(resizeHint, THEME.muted)

    helperContent = CreateFrame("Frame", nil, helperWindow, "BackdropTemplate")
    helperContent:SetPoint("TOPLEFT", helperWindow, "TOPLEFT", 216, -96)
    helperContent:SetPoint("BOTTOMRIGHT", helperWindow, "BOTTOMRIGHT", -16, 16)
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

    if lustUpStatusText and self.GetLustUpStatusText then
        lustUpStatusText:SetText(
            self:GetLustUpStatusText()
        )
    end

    if lustUpCustomListText and self.GetLustUpCustomListText then
        lustUpCustomListText:SetText(
            self:GetLustUpCustomListText()
        )
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
            and "|cff4d9fffModule enabled|r"
            or "|cffff5555Module disabled|r"
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

    moduleUI.statsAlignButton:SetDisplayValue(
        self.db.statsTextAlign or "center"
    )

    if moduleUI.statsPreviewText
        and self.SetStatsFontStringText then

        local align = tostring(
            self.db.statsTextAlign or "center"
        )

        if align ~= "left"
            and align ~= "right" then

            align = "center"
        end

        moduleUI.statsPreviewText:SetJustifyH(
            string.upper(align)
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
    previewCheck:SetChecked(
        self.db.showLayoutPreview and true or false
    )

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
    if not panel or not self.db then
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

    CreateFlatPanel(rootPanel, 16, -16, 820, 112)
    CreateFlatPanel(rootPanel, 16, -146, 400, 174)
    CreateFlatPanel(rootPanel, 432, -146, 404, 174)
    CreateFlatPanel(rootPanel, 16, -338, 400, 174)
    CreateFlatPanel(rootPanel, 432, -338, 404, 174)
    CreateFlatPanel(rootPanel, 16, -530, 400, 112)
    CreateFlatPanel(rootPanel, 432, -530, 404, 112)

    local title = Label(
        rootPanel,
        "Kaylii Helper",
        "GameFontNormalHuge"
    )
    title:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -28
    )
    SetFontColor(title, THEME.text)

    local desc = Label(
        rootPanel,
        "Enable or disable each helper module independently. Module settings stay saved while a module is disabled.",
        "GameFontHighlight"
    )
    desc:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -10
    )
    desc:SetWidth(780)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)

    local buffTitle = Label(
        rootPanel,
        "Buff White List",
        "GameFontNormalLarge"
    )
    buffTitle:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -168
    )
    SetFontColor(buffTitle, THEME.text)

    rootBuffEnabledCheck = Checkbox(
        rootPanel,
        "Enable Buff White List module",
        34,
        -198,
        function(value)
            if BW.SetBuffWhitelistModuleEnabled then
                BW:SetBuffWhitelistModuleEnabled(value)
            else
                BW.db.buffWhitelistModuleEnabled = value
            end

            BW:RefreshOptions()
        end
    )

    local buffDesc = Label(
        rootPanel,
        "Custom Blizzard target/focus aura grids, whitelist/blacklist filters, sorting and text controls.",
        "GameFontHighlightSmall"
    )
    buffDesc:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -234
    )
    buffDesc:SetWidth(360)
    buffDesc:SetJustifyH("LEFT")
    SetFontColor(buffDesc, THEME.subtext)

    local lustTitle = Label(
        rootPanel,
        "Lust Up",
        "GameFontNormalLarge"
    )
    lustTitle:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        450,
        -168
    )
    SetFontColor(lustTitle, THEME.text)

    rootLustEnabledCheck = Checkbox(
        rootPanel,
        "Enable Lust Up module",
        450,
        -198,
        function(value)
            BW.db.lustUpEnabled = value

            if BW.ApplyLustUpSettings then
                BW:ApplyLustUpSettings()
            end

            BW:RefreshLustUpOptions()
            BW:RefreshOptions()
        end
    )

    local lustDesc = Label(
        rootPanel,
        "Tracks lust readiness, shows a movable indicator, and provides customizable voice alerts.",
        "GameFontHighlightSmall"
    )
    lustDesc:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        450,
        -234
    )
    lustDesc:SetWidth(360)
    lustDesc:SetJustifyH("LEFT")
    SetFontColor(lustDesc, THEME.subtext)

    local statsTitle = Label(
        rootPanel,
        "My Stats",
        "GameFontNormalLarge"
    )
    statsTitle:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -360
    )
    SetFontColor(statsTitle, THEME.text)

    moduleUI.rootStatsEnabledCheck = Checkbox(
        rootPanel,
        "Enable My Stats module",
        34,
        -390,
        function(value)
            if BW.SetStatsModuleEnabled then
                BW:SetStatsModuleEnabled(value)
            end

            BW:RefreshStatsOptions()
        end
    )

    local statsDesc = Label(
        rootPanel,
        "Movable live display for Crit, Haste, Mastery and Versatility.",
        "GameFontHighlightSmall"
    )
    statsDesc:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -426
    )
    statsDesc:SetWidth(360)
    statsDesc:SetJustifyH("LEFT")
    SetFontColor(statsDesc, THEME.subtext)

    local talentTitle = Label(
        rootPanel,
        "Talent Loadout",
        "GameFontNormalLarge"
    )
    talentTitle:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        450,
        -360
    )
    SetFontColor(talentTitle, THEME.text)

    moduleUI.rootTalentEnabledCheck = Checkbox(
        rootPanel,
        "Enable Talent Loadout module",
        450,
        -390,
        function(value)
            if BW.SetTalentLoadoutEnabled then
                BW:SetTalentLoadoutEnabled(value)
            end

            BW:RefreshTalentLoadoutOptions()
        end
    )

    local talentDesc = Label(
        rootPanel,
        "Shows your current specialization, saved talent loadout name, and active Hero Talent tree.",
        "GameFontHighlightSmall"
    )
    talentDesc:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        450,
        -426
    )
    talentDesc:SetWidth(360)
    talentDesc:SetJustifyH("LEFT")
    SetFontColor(talentDesc, THEME.subtext)

    local raidSpecTitle = Label(
        rootPanel,
        "Raid Frame Spec",
        "GameFontNormalLarge"
    )
    raidSpecTitle:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -550
    )
    SetFontColor(raidSpecTitle, THEME.text)

    moduleUI.rootRaidSpecEnabledCheck = Checkbox(
        rootPanel,
        "Enable Raid Frame Spec module",
        34,
        -580,
        function(value)
            if BW.SetRaidFrameSpecEnabled then
                BW:SetRaidFrameSpecEnabled(value)
            end

            BW:RefreshRaidFrameSpecOptions()
        end
    )

    local raidSpecDesc = Label(
        rootPanel,
        "Automatically applies saved Ellesmere Raid and Party / 5-man positions for each specialization.",
        "GameFontHighlightSmall"
    )
    raidSpecDesc:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        34,
        -616
    )
    raidSpecDesc:SetWidth(360)
    raidSpecDesc:SetJustifyH("LEFT")
    SetFontColor(raidSpecDesc, THEME.subtext)

    moduleUI.rootRaidSpecStatus = Label(
        rootPanel,
        "",
        "GameFontDisableSmall"
    )
    moduleUI.rootRaidSpecStatus:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        244,
        -554
    )
    moduleUI.rootRaidSpecStatus:SetWidth(150)
    moduleUI.rootRaidSpecStatus:SetJustifyH("RIGHT")

    local survivalTitle = Label(
        rootPanel,
        "Survival Helper",
        "GameFontNormalLarge"
    )
    survivalTitle:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        450,
        -550
    )
    SetFontColor(survivalTitle, THEME.text)

    moduleUI.rootSurvivalEnabledCheck = Checkbox(
        rootPanel,
        "Enable Survival Helper module",
        450,
        -580,
        function(value)
            if BW.SetSurvivalModuleEnabled then
                BW:SetSurvivalModuleEnabled(value)
            end

            BW:RefreshSurvivalOptions()
        end
    )

    local survivalDesc = Label(
        rootPanel,
        "Suggests a personal defensive, Healthstone, or healing potion at configurable HP thresholds.",
        "GameFontHighlightSmall"
    )
    survivalDesc:SetPoint(
        "TOPLEFT",
        rootPanel,
        "TOPLEFT",
        450,
        -616
    )
    survivalDesc:SetWidth(360)
    survivalDesc:SetJustifyH("LEFT")
    SetFontColor(survivalDesc, THEME.subtext)

    local launcherCard = CreateFlatPanel(
        rootPanel,
        16,
        -660,
        820,
        92
    )

    local launcherTitle = Label(
        launcherCard,
        "Minimap Launcher",
        "GameFontNormalLarge"
    )
    launcherTitle:SetPoint(
        "TOPLEFT",
        launcherCard,
        "TOPLEFT",
        18,
        -16
    )
    SetFontColor(launcherTitle, THEME.text)

    moduleUI.minimapButtonCheck = Checkbox(
        launcherCard,
        "Show Kaylii Helper minimap button",
        14,
        -48,
        function(value)
            if BW.SetMinimapButtonShown then
                BW:SetMinimapButtonShown(value)
            end
        end
    )

    local resetMinimap = CreateFrame(
        "Button",
        nil,
        launcherCard,
        "UIPanelButtonTemplate"
    )
    resetMinimap:SetSize(150, 28)
    resetMinimap:SetPoint(
        "TOPRIGHT",
        launcherCard,
        "TOPRIGHT",
        -18,
        -42
    )
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

        BW:RefreshRaidFrameSpecOptions()
        BW:RefreshMinimapButtonOptions()
    end)
end

local function BuildPanelShell()
    panel = CreateFrame("Frame", nil, helperContent)
    panel:SetAllPoints(helperContent)

    local title = Label(
        panel,
        "Buff White List — Blizzard Target Frame",
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
        "Independent buff/debuff grids, filters, blacklist, priorities, and text controls.",
        "GameFontHighlight"
    )
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(760)
    desc:SetJustifyH("LEFT")
    SetFontColor(desc, THEME.subtext)

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
    --------------------------------------------------
    -- LAYOUT PAGE
    --------------------------------------------------

    layoutPage = CreateFrame("Frame", nil, panel)
    layoutPage:Hide()
    layoutPage:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        0,
        -132
    )
    layoutPage:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        0,
        0
    )

    focusCheck = Checkbox(
        layoutPage,
        "Also apply layout/filter to Blizzard Focus Frame",
        12,
        -4,
        function(value)
            BW.db.applyToFocus = value
            BW:SetupFocusFrame()
        end
    )

    previewCheck = Checkbox(
        layoutPage,
        "Show draggable preview (B1/B2… D1/D2…)",
        360,
        -4,
        function(value)
            BW.db.showLayoutPreview = value
            BW:RefreshLayoutPreview()
        end
    )

    iconSizeSlider = Slider(
        layoutPage,
        "Icon size",
        16,
        -54,
        170,
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

    local fineTuneHint = Label(
        layoutPage,
        "Move with the mouse: enable the numbered preview, then drag the Buff or Debuff grid directly. Sliders/boxes remain for fine tuning.",
        "GameFontDisableSmall"
    )
    fineTuneHint:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        16,
        -92
    )
    fineTuneHint:SetWidth(640)
    fineTuneHint:SetJustifyH("LEFT")

    local relationTitle = Label(
        layoutPage,
        "Debuff anchor mode:",
        "GameFontHighlight"
    )
    relationTitle:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        270,
        -47
    )

    detachedButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    detachedButton:SetSize(90, 23)
    detachedButton:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        270,
        -68
    )
    detachedButton:SetText("Detached")
    detachedButton:SetScript("OnClick", function()
        SetAnchorMode("detached")
    end)

    aboveButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    aboveButton:SetSize(108, 23)
    aboveButton:SetPoint(
        "LEFT",
        detachedButton,
        "RIGHT",
        5,
        0
    )
    aboveButton:SetText("Above buffs")
    aboveButton:SetScript("OnClick", function()
        SetAnchorMode("aboveBuffs")
    end)

    belowButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    belowButton:SetSize(108, 23)
    belowButton:SetPoint(
        "LEFT",
        aboveButton,
        "RIGHT",
        5,
        0
    )
    belowButton:SetText("Below buffs")
    belowButton:SetScript("OnClick", function()
        SetAnchorMode("belowBuffs")
    end)

    local relationHelp = Label(
        layoutPage,
        "When attached, Debuff X/Y become fine offsets from the buff grid.",
        "GameFontDisableSmall"
    )
    relationHelp:SetPoint(
        "TOPLEFT",
        relationTitle,
        "BOTTOMLEFT",
        0,
        -52
    )

    --------------------------------------------------
    -- BUFF GRID
    --------------------------------------------------

    local buffTitle = Label(
        layoutPage,
        "BUFF GRID",
        "GameFontNormalLarge"
    )
    buffTitle:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        16,
        -132
    )

    buffXSlider = Slider(
        layoutPage,
        "Buff X",
        16,
        -166,
        170,
        -300,
        400,
        1,
        function(value)
            return tostring(value)
        end,
        function(value)
            BW.db.buffOffsetX = value
            BW:RefreshPresentation()
        end
    )

    buffYSlider = Slider(
        layoutPage,
        "Buff Y",
        250,
        -166,
        170,
        -250,
        300,
        1,
        function(value)
            return tostring(value)
        end,
        function(value)
            BW.db.buffOffsetY = value
            BW:RefreshPresentation()
        end
    )

    buffColumnsBox = NumberBox(
        layoutPage,
        "Columns",
        16,
        -218,
        1,
        10,
        function(value)
            BW.db.buffColumns = value
            BW:RefreshAllContainers()
        end
    )

    buffRowsBox = NumberBox(
        layoutPage,
        "Rows",
        150,
        -218,
        1,
        10,
        function(value)
            BW.db.buffRows = value
            BW:RefreshAllContainers()
        end
    )

    local buffHorizontal = Label(
        layoutPage,
        "Horizontal:",
        "GameFontHighlight"
    )
    buffHorizontal:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        275,
        -213
    )

    buffGrowLeftButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    buffGrowLeftButton:SetSize(58, 22)
    buffGrowLeftButton:SetPoint(
        "LEFT",
        buffHorizontal,
        "RIGHT",
        8,
        0
    )
    buffGrowLeftButton:SetText("Left")
    buffGrowLeftButton:SetScript("OnClick", function()
        BW.db.buffGrowLeft = true
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    buffGrowRightButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    buffGrowRightButton:SetSize(58, 22)
    buffGrowRightButton:SetPoint(
        "LEFT",
        buffGrowLeftButton,
        "RIGHT",
        4,
        0
    )
    buffGrowRightButton:SetText("Right")
    buffGrowRightButton:SetScript("OnClick", function()
        BW.db.buffGrowLeft = false
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    local buffVertical = Label(
        layoutPage,
        "Vertical:",
        "GameFontHighlight"
    )
    buffVertical:SetPoint(
        "LEFT",
        buffGrowRightButton,
        "RIGHT",
        16,
        0
    )

    buffGrowUpButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    buffGrowUpButton:SetSize(52, 22)
    buffGrowUpButton:SetPoint(
        "LEFT",
        buffVertical,
        "RIGHT",
        8,
        0
    )
    buffGrowUpButton:SetText("Up")
    buffGrowUpButton:SetScript("OnClick", function()
        BW.db.buffGrowDown = false
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    buffGrowDownButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    buffGrowDownButton:SetSize(58, 22)
    buffGrowDownButton:SetPoint(
        "LEFT",
        buffGrowUpButton,
        "RIGHT",
        4,
        0
    )
    buffGrowDownButton:SetText("Down")
    buffGrowDownButton:SetScript("OnClick", function()
        BW.db.buffGrowDown = true
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    local buffCapacity = Label(
        layoutPage,
        "Capacity = Buff Rows × Columns (up to 40).",
        "GameFontDisableSmall"
    )
    buffCapacity:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        16,
        -252
    )

    --------------------------------------------------
    -- DEBUFF GRID
    --------------------------------------------------

    local debuffTitle = Label(
        layoutPage,
        "DEBUFF GRID",
        "GameFontNormalLarge"
    )
    debuffTitle:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        16,
        -291
    )

    debuffXSlider = Slider(
        layoutPage,
        "Debuff X",
        16,
        -325,
        170,
        -300,
        400,
        1,
        function(value)
            return tostring(value)
        end,
        function(value)
            BW.db.debuffOffsetX = value
            BW:RefreshPresentation()
        end
    )

    debuffYSlider = Slider(
        layoutPage,
        "Debuff Y",
        250,
        -325,
        170,
        -250,
        300,
        1,
        function(value)
            return tostring(value)
        end,
        function(value)
            BW.db.debuffOffsetY = value
            BW:RefreshPresentation()
        end
    )

    debuffColumnsBox = NumberBox(
        layoutPage,
        "Columns",
        16,
        -377,
        1,
        10,
        function(value)
            BW.db.debuffColumns = value
            BW:RefreshAllContainers()
        end
    )

    debuffRowsBox = NumberBox(
        layoutPage,
        "Rows",
        150,
        -377,
        1,
        10,
        function(value)
            BW.db.debuffRows = value
            BW:RefreshAllContainers()
        end
    )

    local debuffHorizontal = Label(
        layoutPage,
        "Horizontal:",
        "GameFontHighlight"
    )
    debuffHorizontal:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        275,
        -372
    )

    debuffGrowLeftButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    debuffGrowLeftButton:SetSize(58, 22)
    debuffGrowLeftButton:SetPoint(
        "LEFT",
        debuffHorizontal,
        "RIGHT",
        8,
        0
    )
    debuffGrowLeftButton:SetText("Left")
    debuffGrowLeftButton:SetScript("OnClick", function()
        BW.db.debuffGrowLeft = true
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    debuffGrowRightButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    debuffGrowRightButton:SetSize(58, 22)
    debuffGrowRightButton:SetPoint(
        "LEFT",
        debuffGrowLeftButton,
        "RIGHT",
        4,
        0
    )
    debuffGrowRightButton:SetText("Right")
    debuffGrowRightButton:SetScript("OnClick", function()
        BW.db.debuffGrowLeft = false
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    local debuffVertical = Label(
        layoutPage,
        "Vertical:",
        "GameFontHighlight"
    )
    debuffVertical:SetPoint(
        "LEFT",
        debuffGrowRightButton,
        "RIGHT",
        16,
        0
    )

    debuffGrowUpButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    debuffGrowUpButton:SetSize(52, 22)
    debuffGrowUpButton:SetPoint(
        "LEFT",
        debuffVertical,
        "RIGHT",
        8,
        0
    )
    debuffGrowUpButton:SetText("Up")
    debuffGrowUpButton:SetScript("OnClick", function()
        BW.db.debuffGrowDown = false
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    debuffGrowDownButton = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    debuffGrowDownButton:SetSize(58, 22)
    debuffGrowDownButton:SetPoint(
        "LEFT",
        debuffGrowUpButton,
        "RIGHT",
        4,
        0
    )
    debuffGrowDownButton:SetText("Down")
    debuffGrowDownButton:SetScript("OnClick", function()
        BW.db.debuffGrowDown = true
        UpdateDirectionButtons()
        BW:RefreshPresentation()
    end)

    local debuffCapacity = Label(
        layoutPage,
        "Capacity = Debuff Rows × Columns (up to 40). Detached mode uses its own absolute X/Y anchor.",
        "GameFontDisableSmall"
    )
    debuffCapacity:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        16,
        -411
    )
    debuffCapacity:SetWidth(650)
    debuffCapacity:SetJustifyH("LEFT")

    local resetLayout = CreateFrame(
        "Button",
        nil,
        layoutPage,
        "UIPanelButtonTemplate"
    )
    resetLayout:SetSize(120, 24)
    resetLayout:SetPoint(
        "TOPLEFT",
        layoutPage,
        "TOPLEFT",
        16,
        -455
    )
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
        { 0.045, 0.060, 0.085, 0.82 },
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

    lustPage = CreateFrame("Frame", nil, lustPanel)
    lustPage:SetPoint("TOPLEFT", lustPanel, "TOPLEFT", 0, -112)
    lustPage:SetPoint("BOTTOMRIGHT", lustPanel, "BOTTOMRIGHT", 0, 0)

    --------------------------------------------------
    -- TOP ROW
    --------------------------------------------------

    local visibilityCard = CreateSection(
        lustPage,
        14,
        -8,
        394,
        350,
        "Visibility & Alerts",
        "Dungeon/Raid filters apply to the indicator and automatic voice/chat alerts. Tracking continues in the background."
    )

    local indicatorCard = CreateSection(
        lustPage,
        424,
        -8,
        394,
        350,
        "Indicator",
        "Resize the icon or unlock it to drag anywhere on screen."
    )

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

    local manageDrums = CreateFrame(
        "Button",
        nil,
        indicatorCard,
        "UIPanelButtonTemplate"
    )
    manageDrums:SetSize(118, 26)
    manageDrums:SetPoint(
        "TOPRIGHT",
        indicatorCard,
        "TOPRIGHT",
        -18,
        -252
    )
    manageDrums:SetText("Manage drums")
    manageDrums:SetScript("OnClick", function()
        if moduleUI.lustDrumManager then
            moduleUI.lustDrumManager:Show()
            BW:RefreshLustUpOptions()
        end
    end)
    SkinButton(manageDrums)

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

    --------------------------------------------------
    -- LIVE STATUS
    --------------------------------------------------

    local statusCard = CreateSection(
        lustPage,
        14,
        -370,
        804,
        132,
        "Live Status",
        "Current lust readiness as seen by the tracker."
    )

    lustUpStatusText = Label(
        statusCard,
        "Status: checking...",
        "GameFontNormal"
    )
    lustUpStatusText:SetPoint(
        "TOPLEFT",
        statusCard,
        "TOPLEFT",
        18,
        -58
    )
    lustUpStatusText:SetWidth(760)
    lustUpStatusText:SetJustifyH("LEFT")
    SetFontColor(lustUpStatusText, THEME.accent)

    moduleUI.lustReadyAlphaSlider = Slider(
        statusCard,
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
        statusCard,
        "Locked alpha",
        412,
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

    --------------------------------------------------
    -- TRACKED LOCKOUTS
    --------------------------------------------------

    local trackingCard = CreateSection(
        lustPage,
        14,
        -514,
        804,
        224,
        "Tracked Lust Lockouts",
        "Built-in lust variants are already covered. Add a lockout debuff Spell ID only for a new or custom variant."
    )

    local builtInTitle = Label(
        trackingCard,
        "Built-in coverage",
        "GameFontNormal"
    )
    builtInTitle:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -56
    )
    SetFontColor(builtInTitle, THEME.text)

    local builtIn = Label(
        trackingCard,
        "Bloodlust / Heroism • Time Warp • Fury of the Aspects (Evoker) • Hunter lust • Drums\n"
        .. "Lockouts: Exhaustion 57723/390435, Sated 57724, Temporal Displacement 80354, Insanity 95809, Fatigued 160455/264689.",
        "GameFontHighlightSmall"
    )
    builtIn:SetPoint("TOPLEFT", builtInTitle, "BOTTOMLEFT", 0, -8)
    builtIn:SetWidth(750)
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
        -110
    )
    SetFontColor(customTitle, THEME.text)

    lustUpCustomBox = CreateVisibleValueBox(trackingCard, 164)
    lustUpCustomBox:SetMaxLetters(12)
    lustUpCustomBox:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -138
    )
    lustUpCustomBox:SetRenderedValue("")

    local addCustom = CreateFrame(
        "Button",
        nil,
        trackingCard,
        "UIPanelButtonTemplate"
    )
    addCustom:SetSize(100, 26)
    addCustom:SetPoint("LEFT", lustUpCustomBox, "RIGHT", 10, 0)
    addCustom:SetText("Add ID")
    addCustom:SetScript("OnClick", function()
        if BW.AddLustUpLockout
            and BW:AddLustUpLockout(lustUpCustomBox:GetText()) then

            lustUpCustomBox:SetRenderedValue("")
        end
    end)
    SkinButton(addCustom)

    local removeCustom = CreateFrame(
        "Button",
        nil,
        trackingCard,
        "UIPanelButtonTemplate"
    )
    removeCustom:SetSize(108, 26)
    removeCustom:SetPoint("LEFT", addCustom, "RIGHT", 8, 0)
    removeCustom:SetText("Remove ID")
    removeCustom:SetScript("OnClick", function()
        if BW.RemoveLustUpLockout
            and BW:RemoveLustUpLockout(lustUpCustomBox:GetText()) then

            lustUpCustomBox:SetRenderedValue("")
        end
    end)
    SkinButton(removeCustom)

    local customListTitle = Label(
        trackingCard,
        "Custom IDs currently tracked",
        "GameFontHighlight"
    )
    customListTitle:SetPoint(
        "TOPLEFT",
        trackingCard,
        "TOPLEFT",
        18,
        -184
    )
    SetFontColor(customListTitle, THEME.text)

    lustUpCustomListText = Label(
        trackingCard,
        "None added.",
        "GameFontHighlightSmall"
    )
    lustUpCustomListText:SetPoint(
        "TOPLEFT",
        customListTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    lustUpCustomListText:SetWidth(750)
    lustUpCustomListText:SetJustifyH("LEFT")
    SetFontColor(lustUpCustomListText, THEME.subtext)

    --------------------------------------------------
    -- LUST DRUM MANAGER
    --------------------------------------------------

    moduleUI.lustDrumManager = CreateFrame(
        "Frame",
        nil,
        lustPanel,
        "BackdropTemplate"
    )
    moduleUI.lustDrumManager:SetSize(590, 390)
    moduleUI.lustDrumManager:SetPoint(
        "CENTER",
        lustPanel,
        "CENTER",
        0,
        -10
    )
    moduleUI.lustDrumManager:SetFrameLevel(
        lustPanel:GetFrameLevel() + 40
    )
    moduleUI.lustDrumManager:EnableMouse(true)
    ApplyBackdrop(
        moduleUI.lustDrumManager,
        THEME.panel,
        THEME.borderAccent
    )
    moduleUI.lustDrumManager:Hide()

    local drumTitle = Label(
        moduleUI.lustDrumManager,
        "Lust Drums",
        "GameFontNormalHuge"
    )
    drumTitle:SetPoint(
        "TOPLEFT",
        moduleUI.lustDrumManager,
        "TOPLEFT",
        20,
        -18
    )
    SetFontColor(drumTitle, THEME.text)

    local drumDesc = Label(
        moduleUI.lustDrumManager,
        "Built-ins are maintained by Kaylii Helper. Add future drum Item IDs below without waiting for an addon update.",
        "GameFontHighlightSmall"
    )
    drumDesc:SetPoint(
        "TOPLEFT",
        drumTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    drumDesc:SetWidth(545)
    drumDesc:SetJustifyH("LEFT")
    SetFontColor(drumDesc, THEME.subtext)

    local builtInDrumsTitle = Label(
        moduleUI.lustDrumManager,
        "Built-in drums",
        "GameFontNormal"
    )
    builtInDrumsTitle:SetPoint(
        "TOPLEFT",
        moduleUI.lustDrumManager,
        "TOPLEFT",
        20,
        -92
    )
    SetFontColor(builtInDrumsTitle, THEME.text)

    moduleUI.lustBuiltInDrumListText = Label(
        moduleUI.lustDrumManager,
        "",
        "GameFontHighlightSmall"
    )
    moduleUI.lustBuiltInDrumListText:SetPoint(
        "TOPLEFT",
        builtInDrumsTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    moduleUI.lustBuiltInDrumListText:SetWidth(545)
    moduleUI.lustBuiltInDrumListText:SetJustifyH("LEFT")
    SetFontColor(
        moduleUI.lustBuiltInDrumListText,
        THEME.subtext
    )

    local customDrumTitle = Label(
        moduleUI.lustDrumManager,
        "Additional drum Item ID",
        "GameFontNormal"
    )
    customDrumTitle:SetPoint(
        "TOPLEFT",
        moduleUI.lustDrumManager,
        "TOPLEFT",
        20,
        -170
    )
    SetFontColor(customDrumTitle, THEME.text)

    moduleUI.lustCustomDrumBox =
        CreateVisibleValueBox(
            moduleUI.lustDrumManager,
            160
        )
    moduleUI.lustCustomDrumBox:SetMaxLetters(12)
    moduleUI.lustCustomDrumBox:SetPoint(
        "TOPLEFT",
        moduleUI.lustDrumManager,
        "TOPLEFT",
        20,
        -202
    )
    moduleUI.lustCustomDrumBox:SetRenderedValue("")

    local addDrum = CreateFrame(
        "Button",
        nil,
        moduleUI.lustDrumManager,
        "UIPanelButtonTemplate"
    )
    addDrum:SetSize(96, 26)
    addDrum:SetPoint(
        "LEFT",
        moduleUI.lustCustomDrumBox,
        "RIGHT",
        10,
        0
    )
    addDrum:SetText("Add ID")
    addDrum:SetScript("OnClick", function()
        if BW.AddLustUpDrumItem
            and BW:AddLustUpDrumItem(
                moduleUI.lustCustomDrumBox:GetText()
            ) then

            moduleUI.lustCustomDrumBox:SetRenderedValue("")
        end
    end)
    SkinButton(addDrum)

    local removeDrum = CreateFrame(
        "Button",
        nil,
        moduleUI.lustDrumManager,
        "UIPanelButtonTemplate"
    )
    removeDrum:SetSize(104, 26)
    removeDrum:SetPoint(
        "LEFT",
        addDrum,
        "RIGHT",
        8,
        0
    )
    removeDrum:SetText("Remove ID")
    removeDrum:SetScript("OnClick", function()
        if BW.RemoveLustUpDrumItem
            and BW:RemoveLustUpDrumItem(
                moduleUI.lustCustomDrumBox:GetText()
            ) then

            moduleUI.lustCustomDrumBox:SetRenderedValue("")
        end
    end)
    SkinButton(removeDrum)

    local customDrumListTitle = Label(
        moduleUI.lustDrumManager,
        "Custom drums",
        "GameFontNormal"
    )
    customDrumListTitle:SetPoint(
        "TOPLEFT",
        moduleUI.lustDrumManager,
        "TOPLEFT",
        20,
        -252
    )
    SetFontColor(customDrumListTitle, THEME.text)

    moduleUI.lustCustomDrumListText = Label(
        moduleUI.lustDrumManager,
        "None added.",
        "GameFontHighlightSmall"
    )
    moduleUI.lustCustomDrumListText:SetPoint(
        "TOPLEFT",
        customDrumListTitle,
        "BOTTOMLEFT",
        0,
        -8
    )
    moduleUI.lustCustomDrumListText:SetWidth(545)
    moduleUI.lustCustomDrumListText:SetJustifyH("LEFT")
    SetFontColor(
        moduleUI.lustCustomDrumListText,
        THEME.subtext
    )

    local closeDrums = CreateFrame(
        "Button",
        nil,
        moduleUI.lustDrumManager,
        "UIPanelButtonTemplate"
    )
    closeDrums:SetSize(96, 28)
    closeDrums:SetPoint(
        "BOTTOMRIGHT",
        moduleUI.lustDrumManager,
        "BOTTOMRIGHT",
        -18,
        16
    )
    closeDrums:SetText("Close")
    closeDrums:SetScript("OnClick", function()
        moduleUI.lustDrumManager:Hide()
    end)
    SkinButton(closeDrums)
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
    moduleStatus:SetPoint(
        "TOPRIGHT",
        moduleUI.statsPanel,
        "TOPRIGHT",
        -18,
        -22
    )
    moduleStatus:SetJustifyH("RIGHT")
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
        "Enable My Stats module",
        18,
        -68,
        function(value)
            if BW.SetStatsModuleEnabled then
                BW:SetStatsModuleEnabled(value)
            end
        end
    )

    moduleUI.statsPage = CreateFrame("Frame", nil, moduleUI.statsPanel)
    moduleUI.statsPage:SetPoint("TOPLEFT", moduleUI.statsPanel, "TOPLEFT", 0, -112)
    moduleUI.statsPage:SetPoint("BOTTOMRIGHT", moduleUI.statsPanel, "BOTTOMRIGHT", 0, 0)

    local displayCard = CreateSection(
        moduleUI.statsPage,
        14,
        -8,
        394,
        372,
        "Display",
        "Move, align, size, and control when the stat panel is visible."
    )

    moduleUI.statsFontSizeSlider = Slider(
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
            BW.db.statsFontSize = value
            BW:ApplyStatsSettings()
        end
    )

    moduleUI.statsOrientationButton = SortCycleButton(
        displayCard,
        "Orientation",
        18,
        -124,
        152,
        DISPLAY_ORIENTATION_ORDER,
        DISPLAY_ORIENTATION_LABELS,
        function(value)
            BW.db.statsOrientation = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsAlignButton = SortCycleButton(
        displayCard,
        "Text alignment",
        18,
        -160,
        152,
        {
            "left",
            "center",
            "right",
        },
        {
            left = "Left",
            center = "Center",
            right = "Right",
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

    moduleUI.statsUnlockCheck = Checkbox(
        displayCard,
        "Unlock display to drag",
        14,
        -198,
        function(value)
            BW:SetStatsUnlocked(value)
        end
    )

    moduleUI.statsOnlyInCombatCheck = Checkbox(
        displayCard,
        "Only show in combat",
        14,
        -232,
        function(value)
            BW.db.statsOnlyInCombat = value

            if value then
                BW.db.statsOnlyOutOfCombat = false
            end

            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsOnlyOutOfCombatCheck = Checkbox(
        displayCard,
        "Only show out of combat",
        194,
        -232,
        function(value)
            BW.db.statsOnlyOutOfCombat = value

            if value then
                BW.db.statsOnlyInCombat = false
            end

            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsOnlyInInstanceCheck = Checkbox(
        displayCard,
        "Only show in instances",
        14,
        -266,
        function(value)
            BW.db.statsOnlyInInstance = value
            BW:ApplyStatsSettings()
        end
    )

    moduleUI.statsShowBackgroundCheck = Checkbox(
        displayCard,
        "Show background",
        194,
        -266,
        function(value)
            BW.db.statsShowBackground = value
            BW:ApplyStatsSettings()
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
        -312
    )
    reset:SetText("Reset position")
    reset:SetScript("OnClick", function()
        BW:ResetStatsPosition()
    end)
    SkinButton(reset)

    local statsCard = CreateSection(
        moduleUI.statsPage,
        424,
        -8,
        394,
        372,
        "Stats",
        "Choose which secondary stats to show and set a separate color for each."
    )

    moduleUI.statsShowCritCheck = Checkbox(
        statsCard,
        "Critical Strike",
        14,
        -72,
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
        -108,
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
        -144,
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
        -180,
        function(value)
            BW.db.statsShowVersatility = value
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsCritColorButton = ColorButton(
        statsCard,
        "Color",
        214,
        -72,
        function(color)
            BW.db.statsCritColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsHasteColorButton = ColorButton(
        statsCard,
        "Color",
        214,
        -108,
        function(color)
            BW.db.statsHasteColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsMasteryColorButton = ColorButton(
        statsCard,
        "Color",
        214,
        -144,
        function(color)
            BW.db.statsMasteryColor = color
            BW:ApplyStatsSettings()
            BW:RefreshStatsOptions()
        end
    )

    moduleUI.statsVersatilityColorButton = ColorButton(
        statsCard,
        "Color",
        214,
        -180,
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
        214,
        -216
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

    local previewLabel = Label(
        statsCard,
        "Live preview",
        "GameFontHighlight"
    )
    previewLabel:SetPoint(
        "TOPLEFT",
        statsCard,
        "TOPLEFT",
        18,
        -258
    )
    SetFontColor(previewLabel, THEME.subtext)

    moduleUI.statsPreviewText = Label(
        statsCard,
        "",
        "GameFontNormal"
    )
    moduleUI.statsPreviewText:SetPoint(
        "TOPLEFT",
        previewLabel,
        "BOTTOMLEFT",
        0,
        -10
    )
    moduleUI.statsPreviewText:SetWidth(350)
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

    moduleUI.survivalPage = CreateFrame("Frame", nil, moduleUI.survivalPanel)
    moduleUI.survivalPage:SetPoint("TOPLEFT", moduleUI.survivalPanel, "TOPLEFT", 0, -112)
    moduleUI.survivalPage:SetPoint("BOTTOMRIGHT", moduleUI.survivalPanel, "BOTTOMRIGHT", 0, 0)

    local recommendationCard = CreateSection(
        moduleUI.survivalPage,
        14,
        -8,
        394,
        500,
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
    actionScroll:SetPoint("BOTTOMRIGHT", recommendationCard, "BOTTOMRIGHT", -34, 104)

    local actionScrollChild = CreateFrame("Frame", nil, actionScroll)
    actionScrollChild:SetSize(338, 1)
    actionScroll:SetScrollChild(actionScrollChild)
    moduleUI.survivalActionScrollChild = actionScrollChild

    local function EnsureActionRow(index)
        local row = moduleUI.survivalActionRows[index]
        if row then return row end

        row = CreateFrame("Frame", nil, actionScrollChild)
        row:SetSize(332, 58)
        row:SetPoint(
            "TOPLEFT",
            actionScrollChild,
            "TOPLEFT",
            0,
            -((index - 1) * 60)
        )

        local divider = row:CreateTexture(nil, "BACKGROUND")
        divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        divider:SetHeight(1)
        divider:SetColorTexture(
            THEME.border[1],
            THEME.border[2],
            THEME.border[3],
            0.55
        )

        row.enabled = Checkbox(
            row,
            "",
            0,
            -2,
            function(value)
                if row.actionKey and BW.SetSurvivalActionEnabled then
                    BW:SetSurvivalActionEnabled(row.actionKey, value)
                    BW:RefreshSurvivalOptions()
                end
            end
        )
        if row.enabled.Label then row.enabled.Label:Hide() end

        row.linkButton = CreateFrame("Button", nil, row)
        row.linkButton:SetSize(190, 22)
        row.linkButton:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -2)

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
        row.status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -7)
        row.status:SetWidth(102)
        row.status:SetJustifyH("RIGHT")

        row.up = CreateFrame(
            "Button",
            nil,
            row,
            "UIPanelButtonTemplate"
        )
        row.up:SetSize(48, 24)
        row.up:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 34, 5)
        row.up:SetText("Up")
        row.up:SetScript("OnClick", function()
            if row.actionKey and BW.MoveSurvivalAction then
                BW:MoveSurvivalAction(row.actionKey, "up")
                BW:RefreshSurvivalOptions()
            end
        end)
        SkinButton(row.up)

        row.down = CreateFrame(
            "Button",
            nil,
            row,
            "UIPanelButtonTemplate"
        )
        row.down:SetSize(48, 24)
        row.down:SetPoint("LEFT", row.up, "RIGHT", 5, 0)
        row.down:SetText("Down")
        row.down:SetScript("OnClick", function()
            if row.actionKey and BW.MoveSurvivalAction then
                BW:MoveSurvivalAction(row.actionKey, "down")
                BW:RefreshSurvivalOptions()
            end
        end)
        SkinButton(row.down)

        row.ttsLabel = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.ttsLabel:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 140, 10)
        row.ttsLabel:SetText("TTS")
        row.ttsLabel:SetTextColor(THEME.subtext[1], THEME.subtext[2], THEME.subtext[3], 1)

        row.ttsPhraseBox = CreateVisibleValueBox(row, 132)
        row.ttsPhraseBox:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 162, 5)
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
        row.remove:SetSize(30, 24)
        row.remove:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 5)
        row.remove:SetText("X")
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

    moduleUI.refreshSurvivalActionRows = function()
        local actions = BW.GetSurvivalActions and BW:GetSurvivalActions() or {}

        for index, action in ipairs(actions) do
            local row = EnsureActionRow(index)
            row.actionKey = action.key
            row.actionType = action.actionType
            row.actionID = action.id
            row.actionName = action.name or ""
            row.enabled:SetChecked(action.enabled and true or false)
            row.linkText:SetText(
                tostring(index) .. ". " .. (action.link or action.name or "Unknown action")
            )
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

        actionScrollChild:SetHeight(math.max(248, #actions * 60))
    end

    local addLabel = Label(
        recommendationCard,
        "Add future spell/item by ID or pasted link:",
        "GameFontHighlightSmall"
    )
    addLabel:SetPoint("BOTTOMLEFT", recommendationCard, "BOTTOMLEFT", 16, 70)
    SetFontColor(addLabel, THEME.subtext)

    moduleUI.survivalAddActionBox = CreateFrame(
        "EditBox",
        nil,
        recommendationCard,
        "InputBoxTemplate"
    )
    moduleUI.survivalAddActionBox:SetSize(112, 26)
    moduleUI.survivalAddActionBox:SetAutoFocus(false)
    moduleUI.survivalAddActionBox:SetPoint(
        "BOTTOMLEFT",
        recommendationCard,
        "BOTTOMLEFT",
        16,
        34
    )
    SkinEditBox(moduleUI.survivalAddActionBox)

    local function AddSurvivalAction(actionType)
        if not BW.AddSurvivalAction then return end

        local ok, message = BW:AddSurvivalAction(
            actionType,
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

    moduleUI.survivalAddSpellButton = CreateFrame(
        "Button",
        nil,
        recommendationCard,
        "UIPanelButtonTemplate"
    )
    moduleUI.survivalAddSpellButton:SetSize(96, 26)
    moduleUI.survivalAddSpellButton:SetPoint(
        "LEFT",
        moduleUI.survivalAddActionBox,
        "RIGHT",
        8,
        0
    )
    moduleUI.survivalAddSpellButton:SetText("Add Spell")
    moduleUI.survivalAddSpellButton:SetScript("OnClick", function()
        AddSurvivalAction("spell")
    end)
    SkinButton(moduleUI.survivalAddSpellButton)

    moduleUI.survivalAddItemButton = CreateFrame(
        "Button",
        nil,
        recommendationCard,
        "UIPanelButtonTemplate"
    )
    moduleUI.survivalAddItemButton:SetSize(96, 26)
    moduleUI.survivalAddItemButton:SetPoint(
        "LEFT",
        moduleUI.survivalAddSpellButton,
        "RIGHT",
        6,
        0
    )
    moduleUI.survivalAddItemButton:SetText("Add Item")
    moduleUI.survivalAddItemButton:SetScript("OnClick", function()
        AddSurvivalAction("item")
    end)
    SkinButton(moduleUI.survivalAddItemButton)

    moduleUI.survivalAddActionStatus = Label(
        recommendationCard,
        "",
        "GameFontDisableSmall"
    )
    moduleUI.survivalAddActionStatus:SetPoint(
        "BOTTOMLEFT",
        recommendationCard,
        "BOTTOMLEFT",
        16,
        12
    )
    moduleUI.survivalAddActionStatus:SetWidth(356)
    moduleUI.survivalAddActionStatus:SetJustifyH("LEFT")

    local displayCard = CreateSection(
        moduleUI.survivalPage,
        424,
        -8,
        394,
        540,
        "Trigger / Display",
        "One HP threshold. The first ready priority action is shown."
    )

    moduleUI.survivalTriggerSlider = Slider(
        displayCard,
        "Trigger at HP",
        18,
        -78,
        218,
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

    moduleUI.survivalAlertTypeCheck = Checkbox(
        displayCard,
        "Use sound alert (unchecked = TTS)",
        14,
        -130,
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
        14,
        -160,
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
        "Speak ready action name",
        218,
        -160,
        function(value)
            BW.db.survivalSpeakActionName = value and true or false
        end
    )

    local ttsLabel = Label(
        displayCard,
        "TTS phrase",
        "GameFontHighlightSmall"
    )
    ttsLabel:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -200)
    SetFontColor(ttsLabel, THEME.subtext)

    moduleUI.survivalTTSTextBox = CreateFrame(
        "EditBox",
        nil,
        displayCard,
        "InputBoxTemplate"
    )
    moduleUI.survivalTTSTextBox:SetSize(250, 28)
    moduleUI.survivalTTSTextBox:SetAutoFocus(false)
    moduleUI.survivalTTSTextBox:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -220)
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
    moduleUI.survivalTTSTestButton:SetPoint(
        "LEFT",
        moduleUI.survivalTTSTextBox,
        "RIGHT",
        8,
        0
    )
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
    moduleUI.survivalTTSStatus:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 18, -254)
    moduleUI.survivalTTSStatus:SetWidth(350)
    moduleUI.survivalTTSStatus:SetJustifyH("LEFT")

    local alertSoundLabel = Label(
        displayCard,
        "Alert sound",
        "GameFontHighlightSmall"
    )
    alertSoundLabel:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 218, -274)
    SetFontColor(alertSoundLabel, THEME.subtext)

    moduleUI.survivalAlertSoundDropdown = moduleUI.CreateChoiceDropdown(
        displayCard,
        218,
        -290,
        158,
        BW.GetSurvivalAlertSoundChoices and BW:GetSurvivalAlertSoundChoices() or {
            { key = "off", label = "Off" },
        },
        function(value)
            if BW.SetSurvivalAlertSound then BW:SetSurvivalAlertSound(value) end
        end
    )

    moduleUI.survivalAlertSoundTestButton = CreateFrame(
        "Button", nil, displayCard, "UIPanelButtonTemplate"
    )
    moduleUI.survivalAlertSoundTestButton:SetSize(158, 28)
    moduleUI.survivalAlertSoundTestButton:SetPoint(
        "TOPLEFT", displayCard, "TOPLEFT", 218, -322
    )
    moduleUI.survivalAlertSoundTestButton:SetText("Test alert sound")
    moduleUI.survivalAlertSoundTestButton:SetScript("OnClick", function()
        local worked = BW.TestSurvivalAlertSound and BW:TestSurvivalAlertSound()
        if moduleUI.survivalTTSStatus then
            moduleUI.survivalTTSStatus:SetText(worked and "Alert sound played" or "Sound unavailable or set to Off")
            SetFontColor(moduleUI.survivalTTSStatus, worked and THEME.accent or { 1.00, 0.42, 0.42, 1 })
        end
    end)
    SkinButton(moduleUI.survivalAlertSoundTestButton)

    moduleUI.survivalIconSizeSlider = Slider(
        displayCard,
        "Icon size",
        18,
        -290,
        130,
        32,
        100,
        1,
        function(value)
            return string.format("%d px", value)
        end,
        function(value)
            BW.db.survivalIconSize = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalUnlockCheck = Checkbox(
        displayCard,
        "Unlock display to drag",
        14,
        -344,
        function(value)
            if BW.SetSurvivalUnlocked then
                BW:SetSurvivalUnlocked(value)
            end
        end
    )

    moduleUI.survivalShowLabelCheck = Checkbox(
        displayCard,
        "Show action name",
        14,
        -374,
        function(value)
            BW.db.survivalShowLabel = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalShowAllReadyActionsCheck = Checkbox(
        displayCard,
        "Show all ready actions",
        14,
        -464,
        function(value)
            BW.db.survivalShowAllReadyActions = value and true or false
            if moduleUI.survivalReadyActionsGrowthDropdown then
                moduleUI.survivalReadyActionsGrowthDropdown:SetEnabledState(value)
            end
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalReadyActionsGrowthDropdown = moduleUI.CreateChoiceDropdown(
        displayCard,
        14,
        -494,
        158,
        {
            { key = "left", label = "Grow left" },
            { key = "right", label = "Grow right" },
            { key = "up", label = "Grow up" },
            { key = "down", label = "Grow down" },
        },
        function(value)
            BW.db.survivalReadyActionsGrowth = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalOnlyCombatCheck = Checkbox(
        displayCard,
        "Only show in combat",
        14,
        -404,
        function(value)
            BW.db.survivalOnlyInCombat = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalOnlyInstanceCheck = Checkbox(
        displayCard,
        "Only show in instances",
        14,
        -434,
        function(value)
            BW.db.survivalOnlyInInstance = value
            BW:ApplySurvivalSettings()
        end
    )

    moduleUI.survivalGlowCheck = Checkbox(
        displayCard,
        "Glow icon when active",
        218,
        -360,
        function(value)
            if BW.SetSurvivalGlowEnabled then
                BW:SetSurvivalGlowEnabled(value)
            else
                BW.db.survivalGlowEnabled = value and true or false
                BW:ApplySurvivalSettings()
            end
        end
    )

    moduleUI.survivalDeathSoundCard = CreateFrame(
        "Frame", nil, displayCard, "BackdropTemplate"
    )
    moduleUI.survivalDeathSoundCard:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 210, -402)
    moduleUI.survivalDeathSoundCard:SetSize(170, 130)
    ApplyBackdrop(moduleUI.survivalDeathSoundCard, THEME.panelAlt, THEME.border)

    local deathSoundTitle = Label(
        moduleUI.survivalDeathSoundCard,
        "Group Death Sound",
        "GameFontHighlightSmall"
    )
    deathSoundTitle:SetPoint("TOPLEFT", moduleUI.survivalDeathSoundCard, "TOPLEFT", 10, -8)
    SetFontColor(deathSoundTitle, THEME.subtext)

    moduleUI.survivalDeathSoundCheck = Checkbox(
        moduleUI.survivalDeathSoundCard,
        "Enabled",
        8,
        -31,
        function(value)
            if BW.SetSurvivalDeathSoundEnabled then
                BW:SetSurvivalDeathSoundEnabled(value)
            else
                BW.db.survivalDeathSoundEnabled = value and true or false
            end
        end
    )

    moduleUI.survivalDeathSoundDropdown = moduleUI.CreateChoiceDropdown(
        moduleUI.survivalDeathSoundCard,
        8,
        -52,
        154,
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
    moduleUI.survivalDeathSoundTestButton:SetSize(154, 28)
    moduleUI.survivalDeathSoundTestButton:SetPoint(
        "TOPLEFT",
        moduleUI.survivalDeathSoundCard,
        "TOPLEFT",
        8,
        -84
    )
    moduleUI.survivalDeathSoundTestButton:SetText("Test death sound")
    moduleUI.survivalDeathSoundTestButton:SetScript("OnClick", function()
        if BW.TestSurvivalDeathSound then
            BW:TestSurvivalDeathSound()
        end
    end)
    SkinButton(moduleUI.survivalDeathSoundTestButton)

    local reset = CreateFrame(
        "Button",
        nil,
        moduleUI.survivalPanel,
        "UIPanelButtonTemplate"
    )
    reset:SetSize(124, 28)
    reset:SetPoint("LEFT", moduleUI.survivalPageEnabledCheck, "LEFT", 340, 0)
    reset:SetText("Reset position")
    reset:SetScript("OnClick", function()
        if BW.ResetSurvivalPosition then
            BW:ResetSurvivalPosition()
        end
    end)
    SkinButton(reset)

    moduleUI.survivalStatusText = Label(
        moduleUI.survivalPage,
        "",
        "GameFontHighlightSmall"
    )
    moduleUI.survivalStatusText:SetPoint("TOPLEFT", moduleUI.survivalPage, "TOPLEFT", 20, -526)
    moduleUI.survivalStatusText:SetWidth(790)
    moduleUI.survivalStatusText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.survivalStatusText, THEME.accent)

    moduleUI.survivalDetectedText = Label(
        moduleUI.survivalPage,
        "",
        "GameFontHighlightSmall"
    )
    moduleUI.survivalDetectedText:SetPoint("TOPLEFT", moduleUI.survivalPage, "TOPLEFT", 20, -548)
    moduleUI.survivalDetectedText:SetWidth(790)
    moduleUI.survivalDetectedText:SetJustifyH("LEFT")
    SetFontColor(moduleUI.survivalDetectedText, THEME.subtext)

    local note = Label(
        moduleUI.survivalPage,
        "Example: if Desperate Prayer is first but on cooldown, Kaylii immediately checks the next row, then the next, until it finds something ready. If nothing is ready, no icon is shown.",
        "GameFontHighlightSmall"
    )
    note:SetPoint("TOPLEFT", moduleUI.survivalPage, "TOPLEFT", 20, -574)
    note:SetWidth(790)
    note:SetJustifyH("LEFT")
    SetFontColor(note, THEME.subtext)
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

    moduleUI.talentPage = CreateFrame("Frame", nil, moduleUI.talentPanel)
    moduleUI.talentPage:SetPoint("TOPLEFT", moduleUI.talentPanel, "TOPLEFT", 0, -112)
    moduleUI.talentPage:SetPoint("BOTTOMRIGHT", moduleUI.talentPanel, "BOTTOMRIGHT", 0, 0)

    local displayCard = CreateSection(
        moduleUI.talentPage,
        14,
        -8,
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
        "Save per-spec Raid and Party overrides while preserving Ellesmere defaults. Use the tabs below to edit one frame type at a time.",
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

    moduleUI.raidSpecPage = CreateFrame("Frame", nil, moduleUI.raidSpecPanel)
    moduleUI.raidSpecPage:SetPoint("TOPLEFT", moduleUI.raidSpecPanel, "TOPLEFT", 0, -112)
    moduleUI.raidSpecPage:SetPoint("BOTTOMRIGHT", moduleUI.raidSpecPanel, "BOTTOMRIGHT", 0, 0)

    local manageCard = CreateSection(
        moduleUI.raidSpecPage,
        14, -8, 804, 126,
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

local settingsLauncherSuppressAutoOpen = false

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
        settingsLauncherSuppressAutoOpen = true
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
                settingsLauncherSuppressAutoOpen = false
            end)
        end)
        return
    end

    -- Legacy/fallback name for older client UI layouts.
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        settingsLauncherSuppressAutoOpen = true

        if HideUIPanel then
            HideUIPanel(InterfaceOptionsFrame)
        else
            InterfaceOptionsFrame:Hide()
        end

        C_Timer.After(0, function()
            settingsLauncherSuppressAutoOpen = false
        end)
    end
end

local function OpenFromBlizzardSettings(view)
    if settingsLauncherSuppressAutoOpen then
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
        if settingsLauncherSuppressAutoOpen then
            return
        end

        C_Timer.After(0, function()
            if frame:IsShown()
                and not settingsLauncherSuppressAutoOpen then

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
            settingsLauncherSuppressAutoOpen = true

            C_Timer.After(0, function()
                settingsLauncherSuppressAutoOpen = false
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
