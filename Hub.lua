local ADDON_NAME, BW = ...

-- Retain the complete 1.x tables for each standalone module's migration.
_G.KayliiHelper2 = BW
BW.modules = {}

local definitions = {
    { id = "buff", title = "Buff White List", addon = "KayliiTargetAuras", description = "Target and focus aura filters and layout." },
    { id = "lust", title = "Lust Up", addon = "KayliiLustUp", description = "Lust readiness and voice alerts." },
    { id = "stats", title = "My Stats", addon = "KayliiStatsDisplay", description = "Movable live secondary stats." },
    { id = "talent", title = "Talent Loadout", addon = "KayliiTalentLoadout", description = "Saved build and Hero Talent display." },
    { id = "raidspec", title = "Raid Frame Spec", addon = "KayliiRaidFrameSpec", description = "Per-spec Ellesmere Raid and Party frame layout." },
    { id = "survival", title = "Survival Helper", addon = "KayliiSurvivalHelper", description = "Ready actions and character-specific alerts." },
}

local window, content, contentPage, active = nil, nil, nil, "home"
local font = "Fonts\\FRIZQT__.TTF"

local function Label(parent, text, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(font, size or 14)
    label:SetTextColor(unpack(color or { 0.94, 0.97, 1 }))
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function Frame(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.06, 0.085, 0.12, 0.98)
    frame:SetBackdropBorderColor(0.23, 0.32, 0.43, 1)
    return frame
end

local function Button(parent, text, width, height, click)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 31)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.09, 0.17, 0.29, 1)
    button:SetBackdropBorderColor(0.27, 0.43, 0.64, 1)
    local label = Label(button, text, 13)
    label:SetPoint("CENTER")
    button:SetFontString(label)
    button:SetText(text)
    button:SetScript("OnClick", click)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.06, 0.38, 0.78, 1)
    end)
    button:SetScript("OnLeave", function(self)
        if self.selected then self:SetBackdropColor(0.025, 0.36, 0.84, 1)
        else self:SetBackdropColor(0.09, 0.17, 0.29, 1) end
    end)
    return button
end

function BW:RegisterModule(id, api)
    if type(id) ~= "string" or type(api) ~= "table"
        or type(api.open) ~= "function" then return end
    self.modules[id] = api
    if window and window:IsShown() then self:RefreshHub() end
end

local function Loaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    end
    return type(IsAddOnLoaded) == "function" and IsAddOnLoaded(name)
end

function BW:RefreshHub()
    if not content then return end
    if contentPage then contentPage:Hide(); contentPage:SetParent(nil) end
    contentPage = CreateFrame("Frame", nil, content)
    contentPage:SetAllPoints(content)
    local page = contentPage

    local selected
    for _, definition in ipairs(definitions) do
        if definition.id == active then selected = definition; break end
    end
    local title = Label(page, selected and selected.title or "Kaylii Helper", 23)
    title:SetPoint("TOPLEFT", 22, -21)
    local description = Label(page,
        selected and selected.description or "Choose a module to open its settings.",
        13, { 0.70, 0.78, 0.88 })
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -9)

    if selected then
        local card = Frame(page, 570, 155)
        card:SetPoint("TOPLEFT", 22, -105)
        local installed = Loaded(selected.addon)
        local status = Label(card, installed and "Installed" or "Not installed", 17,
            installed and { 0.53, 0.85, 0.59 } or { 0.70, 0.78, 0.88 })
        status:SetPoint("TOPLEFT", 18, -21)
        local info = Label(card, selected.description, 13, { 0.70, 0.78, 0.88 })
        info:SetPoint("TOPLEFT", 18, -57)
        local open = Button(card, "Open settings", 140, 32, function()
            local api = BW.modules[selected.id]
            if api then api.open() end
        end)
        open:SetPoint("BOTTOMLEFT", 18, 19)
        open:SetEnabled(BW.modules[selected.id] ~= nil)
        return
    end

    for index, definition in ipairs(definitions) do
        local row = Frame(page, 570, 65)
        row:SetPoint("TOPLEFT", 22, -97 - (index - 1) * 73)
        local name = Label(row, definition.title, 16)
        name:SetPoint("TOPLEFT", 16, -12)
        local detail = Label(row, definition.description, 12, { 0.70, 0.78, 0.88 })
        detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
        local installed = Loaded(definition.addon)
        local state = Label(row, installed and "Installed" or "Not installed", 12,
            installed and { 0.53, 0.85, 0.59 } or { 0.65, 0.72, 0.82 })
        state:SetPoint("RIGHT", row, "RIGHT", -18, 0)
    end
end

local function BuildWindow()
    if window then return end
    window = Frame(UIParent, 860, 610)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()

    local heading = Label(window, "Kaylii Helper", 25)
    heading:SetPoint("TOPLEFT", 20, -17)
    local close = Button(window, "×", 30, 28, function() window:Hide() end)
    close:SetPoint("TOPRIGHT", -9, -11)

    local sidebar = Frame(window, 220, 528)
    sidebar:SetPoint("TOPLEFT", 12, -65)
    local main = Frame(window, 610, 528)
    main:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    content = main

    local minimized = false
    local minimize = Button(window, "−", 30, 28, function(self)
        minimized = not minimized
        sidebar:SetShown(not minimized)
        main:SetShown(not minimized)
        window:SetHeight(minimized and 58 or 610)
        self:SetText(minimized and "+" or "−")
    end)
    minimize:SetPoint("RIGHT", close, "LEFT", -4, 0)

    local navButtons = {}
    local function Nav(text, id, index)
        local button = Button(sidebar, text, 200, 43, function()
            active = id
            for name, navButton in pairs(navButtons) do
                navButton.selected = name == id
                if name == id then navButton:SetBackdropColor(0.025, 0.36, 0.84, 1)
                else navButton:SetBackdropColor(0.09, 0.17, 0.29, 1) end
            end
            BW:RefreshHub()
        end)
        navButtons[id] = button
        button.selected = active == id
        button:SetPoint("TOPLEFT", 10, -12 - (index - 1) * 50)
        if active == id then button:SetBackdropColor(0.025, 0.36, 0.84, 1) end
    end
    Nav("Home", "home", 1)
    for index, definition in ipairs(definitions) do
        Nav(definition.title, definition.id, index + 1)
    end
end

function BW:OpenHelperWindow(view)
    BuildWindow()
    active = view or "home"
    window:Show()
    self:RefreshHub()
end

function BW:ToggleHelperWindow(view)
    BuildWindow()
    if window:IsShown() then window:Hide()
    else self:OpenHelperWindow(view) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == ADDON_NAME then
        KayliiHelperDB = KayliiHelperDB or BuffWhitelistDB or {}
        BuffWhitelistDB = KayliiHelperDB
        KayliiHelperCharacterDB = KayliiHelperCharacterDB or {}
        BW.db = KayliiHelperDB
        BW.characterDB = KayliiHelperCharacterDB
        if BW.db.minimapButtonShown == nil then BW.db.minimapButtonShown = true end
    elseif event == "PLAYER_LOGIN" then
        if BW.InitializeMinimapButton then BW:InitializeMinimapButton() end
    end
end)

SLASH_KAYLIIHELPER1 = "/kh"
SLASH_KAYLIIHELPER2 = "/kaylii"
SLASH_KAYLIIHELPER3 = "/kayliihelper"
SlashCmdList.KAYLIIHELPER = function() BW:OpenHelperWindow("home") end
