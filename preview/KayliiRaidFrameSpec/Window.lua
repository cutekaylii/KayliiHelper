local _, module = ...

local window, body, tabs, active = nil, nil, nil, 1
local function Color(label, size, shade)
    local text = label:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size or 13)
    text:SetTextColor(unpack(shade or { 0.94, 0.96, 1 }))
    text:SetJustifyH("LEFT")
    return text
end

local function Panel(parent, width, height, shade)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(shade or { 0.068, 0.093, 0.136, 0.98 }))
    frame:SetBackdropBorderColor(0.24, 0.36, 0.49, 1)
    return frame
end

local function Button(parent, caption, width, click)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 130, 29)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.035, 0.28, 0.58, 1)
    button:SetBackdropBorderColor(0.22, 0.51, 0.78, 1)
    local title = Color(button, 12)
    title:SetPoint("CENTER")
    button:SetFontString(title)
    button:SetText(caption)
    button:SetScript("OnClick", click)
    return button
end

local function Updated(row, value)
    local method = module[row[4]]
    if row[4] == "SetBuffWhitelistModuleEnabled" then
        method(module, value)
        return
    end
    if row[4] == "SetStatsModuleEnabled" or row[4] == "SetTalentLoadoutEnabled"
        or row[4] == "SetLustUpUnlocked" or row[4] == "SetLustUpIndicatorClickable"
        or row[4] == "SetStatsUnlocked" or row[4] == "SetTalentLoadoutUnlocked"
        or row[4] == "SetRaidFrameSpecEnabled" then
        if method then method(module, value) end
        return
    end
    module.db[row[2]] = value
    if method then method(module) end
end

local function Entry(parent, row, y)
    local title = Color(parent, 14)
    title:SetText(row[1])
    title:SetPoint("TOPLEFT", 19, y)
    if row[3] == "toggle" then
        local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        box:SetPoint("TOPRIGHT", -26, y + 6)
        box:SetChecked(module.db[row[2]] == true)
        box:SetScript("OnClick", function(self) Updated(row, self:GetChecked() and true or false) end)
    elseif row[3] == "action" then
        local action = Button(parent, "Apply", 120, function()
            if module[row[2]] then module[row[2]](module) end
        end)
        action:SetPoint("TOPRIGHT", -22, y + 5)
    elseif row[3] == "text" or row[3] == "number" then
        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetSize(254, 27)
        input:SetAutoFocus(false)
        input:SetPoint("TOPRIGHT", -23, y + 5)
        input:SetText(tostring(module.db[row[2]] or ""))
        input:SetCursorPosition(0)
        local function Save(self)
            local value = self:GetText()
            if row[3] == "number" then
                value = tonumber(value)
                if not value then return end
            end
            Updated(row, value)
        end
        input:SetScript("OnEnterPressed", function(self) Save(self); self:ClearFocus() end)
        input:SetScript("OnEditFocusLost", Save)
    elseif row[3] == "spells" or row[3] == "blacklist" then
        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetSize(190, 27)
        input:SetAutoFocus(false)
        input:SetPoint("TOPLEFT", 19, y - 35)
        input:SetText("")
        local add = Button(parent, "Add spell", 102, function()
            if row[3] == "spells" then module:AddSpell(row[4], input:GetText())
            else module:AddBlacklistSpell(row[4], input:GetText()) end
            module:RefreshWindow()
        end)
        add:SetPoint("LEFT", input, "RIGHT", 14, 0)
        local data = module.db[row[2]] or {}
        local ids = {}
        for id, enabled in pairs(data) do if enabled then ids[#ids + 1] = tonumber(id) end end
        table.sort(ids)
        for index, spellID in ipairs(ids) do
            if index > 8 then break end
            local entry = Color(parent, 12, { 0.72, 0.82, 0.91 })
            entry:SetPoint("TOPLEFT", 28, y - 74 - (index - 1) * 28)
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            entry:SetText((info and info.name or "Spell") .. "  ·  " .. tostring(spellID))
            local remove = Button(parent, "Remove", 82, function()
                if row[3] == "spells" then module:RemoveSpell(row[4], spellID)
                else module:RemoveBlacklistSpell(row[4], spellID) end
                module:RefreshWindow()
            end)
            remove:SetPoint("TOPRIGHT", -22, y - 70 - (index - 1) * 28)
        end
    end
end

function module:RefreshWindow()
    if not body then return end
    if body.page then body.page:Hide(); body.page:SetParent(nil) end
    local page = CreateFrame("Frame", nil, body)
    page:SetSize(607, 650)
    body.page = page
    local config = self.pages[active]
    local heading = Color(page, 21, { 0.97, 0.85, 0.58 })
    heading:SetPoint("TOPLEFT", 17, -17)
    heading:SetText(config.title)
    local subtitle = Color(page, 12, { 0.66, 0.76, 0.87 })
    subtitle:SetPoint("TOPLEFT", 18, -48)
    subtitle:SetText("Settings for this module are saved separately from Kaylii Helper 1.x.")
    local y = -79
    for _, row in ipairs(config.rows) do
        local height = row[3] == "spells" or row[3] == "blacklist" and 330 or 53
        if row[3] == "spells" or row[3] == "blacklist" then height = 330 end
        local card = Panel(page, 565, height - 8)
        card:SetPoint("TOPLEFT", 17, y)
        Entry(card, row, -14)
        y = y - height
    end
    page:SetHeight(math.max(600, -y + 20))
    body:SetScrollChild(page)
    for index, button in ipairs(tabs) do
        button:SetBackdropColor(index == active and 0.03 or 0.07,
            index == active and 0.39 or 0.17, index == active and 0.78 or 0.28, 1)
    end
end

function module:OpenWindow()
    if not window then
        window = Panel(UIParent, 675, 625, { 0.045, 0.06, 0.09, 0.98 })
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:EnableMouse(true)
        window:SetMovable(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        local heading = Color(window, 24, { 0.96, 0.85, 0.61 })
        heading:SetText(self.title)
        heading:SetPoint("TOPLEFT", 20, -16)
        local close = Button(window, "×", 31, function() window:Hide() end)
        close:SetPoint("TOPRIGHT", -13, -12)
        local minimized = false
        local minimize = Button(window, "−", 31, function(self)
            minimized = not minimized
            body:SetShown(not minimized)
            for _, tab in ipairs(tabs) do tab:SetShown(not minimized) end
            window:SetHeight(minimized and 56 or 625)
            self:SetText(minimized and "+" or "−")
        end)
        minimize:SetPoint("RIGHT", close, "LEFT", -5, 0)
        tabs = {}
        for index, config in ipairs(self.pages) do
            local button = Button(window, config.title, 202, function()
                active = index
                self:RefreshWindow()
            end)
            button:SetPoint("TOPLEFT", 19 + ((index - 1) % 3) * 212,
                -62 - math.floor((index - 1) / 3) * 37)
            tabs[index] = button
        end
        local offset = -62 - math.ceil(#self.pages / 3) * 37 - 8
        body = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        body:SetPoint("TOPLEFT", 18, offset)
        body:SetSize(624, 625 + offset - 18)
    end
    window:Show()
    self:RefreshWindow()
end
