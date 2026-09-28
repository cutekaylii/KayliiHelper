local _, BW = ...

local window, body, scrollFrame, tabRow, currentTab
local tabs = { "Trigger", "Priority", "Ready alerts", "Death sound", "Appearance" }
local palette = {
    background = { 0.055, 0.075, 0.105, 0.98 },
    panel = { 0.075, 0.10, 0.14, 0.96 },
    border = { 0.22, 0.30, 0.40, 1 },
    blue = { 0.04, 0.40, 0.89, 1 },
    text = { 0.93, 0.96, 1, 1 },
    muted = { 0.67, 0.76, 0.86, 1 },
}

local function Panel(parent, width, height, color)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(color or palette.panel))
    frame:SetBackdropBorderColor(unpack(palette.border))
    return frame
end

local function Text(parent, value, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 13)
    label:SetTextColor(unpack(color or palette.text))
    label:SetJustifyH("LEFT")
    label:SetText(value)
    return label
end

local function Button(parent, label, width, click)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 90, 27)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.05, 0.31, 0.68, 1)
    button:SetBackdropBorderColor(0.16, 0.50, 0.92, 1)
    local text = Text(button, label, 12)
    text:SetPoint("CENTER")
    button:SetFontString(text)
    button:SetText(label)
    button:SetScript("OnClick", click)
    return button
end

local function Card(title, detail, y, height)
    local card = Panel(body, 512, height)
    card:SetPoint("TOPLEFT", body, "TOPLEFT", 0, y)
    local heading = Text(card, title, 15)
    heading:SetPoint("TOPLEFT", 15, -13)
    if detail then
        local subtitle = Text(card, detail, 12, palette.muted)
        subtitle:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -5)
        subtitle:SetWidth(476)
    end
    return card
end

local function Toggle(parent, y, label, key, setter)
    local text = Text(parent, label, 13)
    text:SetPoint("TOPLEFT", 16, y)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    box:SetPoint("LEFT", parent, "TOPLEFT", 446, y - 7)
    box:SetChecked(BW.db[key] == true)
    box:SetScript("OnClick", function(self)
        local value = self:GetChecked() and true or false
        if setter then BW[setter](BW, value) else
            BW.db[key] = value
            BW:ApplySurvivalSettings()
        end
    end)
end

local function Value(parent, y, title, initial, save, width)
    local label = Text(parent, title, 12, palette.muted)
    label:SetPoint("TOPLEFT", 16, y)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetSize(width or 192, 26)
    input:SetPoint("TOPLEFT", 280, y + 2)
    input:SetText(tostring(initial or ""))
    input:SetCursorPosition(0)
    input:SetScript("OnEnterPressed", function(self) save(self:GetText()); self:ClearFocus() end)
    input:SetScript("OnEditFocusLost", function(self) save(self:GetText()) end)
    return input
end

local function SoundPicker(parent, y, label, choices, selected, save)
    local text = Text(parent, label, 13)
    text:SetPoint("TOPLEFT", 16, y)
    local button = Button(parent, "", 195, function(self)
        if not MenuUtil or not MenuUtil.CreateContextMenu then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            for _, option in ipairs(choices) do
                root:CreateButton(option.label, function()
                    save(option.key)
                    self:SetText(option.label)
                end)
            end
        end)
    end)
    button:SetPoint("TOPLEFT", 275, y + 4)
    for _, option in ipairs(choices) do
        if option.key == selected then button:SetText(option.label); break end
    end
    return button
end

local function ClearBody()
    for _, child in ipairs({ body:GetChildren() }) do child:Hide(); child:SetParent(nil) end
    for _, region in ipairs({ body:GetRegions() }) do region:Hide() end
end

local function RenderTrigger()
    local card = Card("Health trigger", "Choose when to recommend a ready action.", 0, 191)
    Value(card, -73, "Health threshold (%)", BW.db.survivalTriggerThreshold,
        function(value) BW:SetSurvivalTriggerThreshold(tonumber(value) or 30) end)
    Toggle(card, -119, "Only in combat", "survivalOnlyInCombat")
    Toggle(card, -155, "Only in instances", "survivalOnlyInInstance")
    local second = Card("Ready actions", "Only usable actions for this character can appear.", -207, 139)
    Toggle(second, -76, "Show all ready actions", "survivalShowAllReadyActions")
    Toggle(second, -112, "Show action name", "survivalShowLabel")
end

local function RenderPriority()
    local actions = BW:GetSurvivalActions()
    local card = Card("Action priority", "Each action has its own character-specific TTS text.", 0,
        math.max(148, 88 + #actions * 65))
    for index, action in ipairs(actions) do
        local y = -70 - (index - 1) * 65
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("TOPLEFT", 16, y)
        icon:SetTexture(action.icon or 134400)
        local name = Text(card, tostring(index) .. "  " .. tostring(action.name or action.key), 13)
        name:SetPoint("TOPLEFT", 51, y - 2)
        name:SetWidth(218)
        Value(card, y - 30, "TTS text", BW:GetSurvivalTTSPhrase(
            action.key, "Use " .. tostring(action.name or "action")),
            function(text) BW:SetSurvivalTTSPhrase(action.key, text) end, 190)
        local up = Button(card, "↑", 29, function()
            BW:MoveSurvivalAction(action.key, "up"); BW:RefreshSurvivalOptions()
        end)
        up:SetPoint("TOPLEFT", 391, y)
        up:SetEnabled(index > 1)
        local down = Button(card, "↓", 29, function()
            BW:MoveSurvivalAction(action.key, "down"); BW:RefreshSurvivalOptions()
        end)
        down:SetPoint("LEFT", up, "RIGHT", 3, 0)
        down:SetEnabled(index < #actions)
        if action.custom then
            local remove = Button(card, "×", 29, function()
                BW:RemoveSurvivalAction(action.key); BW:RefreshSurvivalOptions()
            end)
            remove:SetPoint("LEFT", down, "RIGHT", 3, 0)
        end
    end
    local add = Card("Add an action", "Paste a spell or item link, or enter its ID.",
        -(math.max(148, 88 + #actions * 65) + 16), 125)
    local input = Value(add, -69, "Spell or item ID", "", function() end, 190)
    local spell = Button(add, "Add spell", 93, function()
        local ok, message = BW:AddSurvivalAction("spell", input:GetText())
        if not ok then print(message) end
        BW:RefreshSurvivalOptions()
    end)
    spell:SetPoint("TOPLEFT", 16, -91)
    local item = Button(add, "Add item", 88, function()
        local ok, message = BW:AddSurvivalAction("item", input:GetText())
        if not ok then print(message) end
        BW:RefreshSurvivalOptions()
    end)
    item:SetPoint("LEFT", spell, "RIGHT", 8, 0)
end

local function RenderAlerts()
    local card = Card("Ready action alert", "Choose speech or a separate alert sound.", 0, 176)
    local typeButton = Button(card,
        BW.db.survivalThresholdAlertType == "sound" and "Sound" or "Text to speech", 190,
        function(self)
            local nextType = BW.db.survivalThresholdAlertType == "sound" and "tts" or "sound"
            BW:SetSurvivalThresholdAlertType(nextType)
            self:SetText(nextType == "tts" and "Text to speech" or "Sound")
            BW:RefreshSurvivalOptions()
        end)
    typeButton:SetPoint("TOPLEFT", 275, -62)
    local label = Text(card, "Alert type", 13)
    label:SetPoint("TOPLEFT", 16, -68)
    if BW.db.survivalThresholdAlertType == "sound" then
        SoundPicker(card, -105, "Alert sound", BW:GetSurvivalAlertSoundChoices(),
            BW.db.survivalAlertSound, function(key) BW:SetSurvivalAlertSound(key) end)
        local test = Button(card, "Test alert", 100, function() BW:TestSurvivalAlertSound() end)
        test:SetPoint("TOPLEFT", 275, -140)
    else
        Toggle(card, -105, "Speak ready action", "survivalTTSEnabled", "SetSurvivalTTSEnabled")
        local test = Button(card, "Test speech", 110, function() BW:TestSurvivalTTS() end)
        test:SetPoint("TOPLEFT", 275, -140)
    end
end

local function RenderDeath()
    local card = Card("Death sound", "This is separate from your ready action alert.", 0, 156)
    Toggle(card, -72, "Play on death", "survivalDeathSoundEnabled", "SetSurvivalDeathSoundEnabled")
    SoundPicker(card, -108, "Death sound", BW:GetSurvivalDeathSoundChoices(),
        BW.db.survivalDeathSound, function(key) BW:SetSurvivalDeathSound(key) end)
    local test = Button(card, "Test death sound", 130, function() BW:TestSurvivalDeathSound() end)
    test:SetPoint("TOPLEFT", 275, -132)
end

local function RenderAppearance()
    local card = Card("Recommendation display", "Position, size and presentation.", 0, 198)
    Toggle(card, -70, "Show action name", "survivalShowLabel")
    Toggle(card, -107, "Show icon glow", "survivalGlowEnabled", "SetSurvivalGlowEnabled")
    Value(card, -150, "Icon size", BW.db.survivalIconSize, function(value)
        BW.db.survivalIconSize = math.max(32, math.min(100, tonumber(value) or 58))
        BW:ApplySurvivalSettings()
    end)
    local move = Button(card, "Move display", 112, function()
        BW:SetSurvivalUnlocked(not BW.db.survivalUnlocked)
    end)
    move:SetPoint("TOPLEFT", 275, -180)
end

local renderers = { RenderTrigger, RenderPriority, RenderAlerts, RenderDeath, RenderAppearance }
function BW:RefreshSurvivalOptions()
    if not window or not window:IsShown() or not body then return end
    ClearBody()
    body:SetHeight(currentTab == 2
        and math.max(700, 88 + #BW:GetSurvivalActions() * 65 + 180)
        or 700)
    renderers[currentTab or 1]()
end

function BW:OpenWindow()
    if not window then self:CreateOptions() end
    window:Show()
    self:RefreshSurvivalOptions()
end

function BW:CreateOptions()
    if window then return end
    window = Panel(UIParent, 590, 580, palette.background)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()

    local title = Text(window, "Kaylii Survival Helper", 21)
    title:SetPoint("TOPLEFT", 20, -18)
    local enabledLabel = Text(window, "Enabled", 12)
    enabledLabel:SetPoint("TOPLEFT", 384, -24)
    local enabled = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    enabled:SetPoint("TOPLEFT", 451, -14)
    enabled:SetChecked(BW.db.survivalModuleEnabled == true)
    enabled:SetScript("OnClick", function(self)
        BW:SetSurvivalModuleEnabled(self:GetChecked() and true or false)
    end)
    window:SetScript("OnShow", function()
        enabled:SetChecked(BW.db.survivalModuleEnabled == true)
    end)
    local close = Button(window, "×", 30, function() window:Hide() end)
    close:SetPoint("TOPRIGHT", -10, -13)
    local minimized = false
    local minimize = Button(window, "−", 30, function(self)
        minimized = not minimized
        window:SetHeight(minimized and 58 or 580)
        tabRow:SetShown(not minimized)
        scrollFrame:SetShown(not minimized)
        if not minimized then BW:RefreshSurvivalOptions() end
        self:SetText(minimized and "+" or "−")
    end)
    minimize:SetPoint("RIGHT", close, "LEFT", -4, 0)

    tabRow = CreateFrame("Frame", nil, window)
    tabRow:SetPoint("TOPLEFT", 15, -54)
    tabRow:SetSize(560, 32)
    scrollFrame = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -99)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 17)
    local child = CreateFrame("Frame", nil, scrollFrame)
    child:SetSize(512, 1100)
    scrollFrame:SetScrollChild(child)
    body = child

    local tabButtons = {}
    for index, name in ipairs(tabs) do
        local tab = Button(tabRow, name, index == 4 and 110 or 104, function()
            currentTab = index
            for number, item in ipairs(tabButtons) do
                if number == index then item:SetBackdropColor(0.05, 0.31, 0.68, 1)
                else item:SetBackdropColor(0.08, 0.13, 0.20, 1) end
            end
            BW:RefreshSurvivalOptions()
        end)
        tabButtons[index] = tab
        tab:SetPoint("TOPLEFT", (index - 1) * 110, 0)
        if index ~= currentTab then tab:SetBackdropColor(0.08, 0.13, 0.20, 1) end
    end
    currentTab = 1
    SLASH_KAYLIISURVIVAL1 = "/khsurvival"
    SLASH_KAYLIISURVIVAL2 = "/khsurv"
    SlashCmdList.KAYLIISURVIVAL = function() BW:OpenWindow() end
end
