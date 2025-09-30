-- MARK: Start Up
local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
MDungeonTeleports.customFont = GameFontNormal:GetFont()

-- Save Function
local function SaveSeason3Position()
    local DungeonFrame = PVEFrame
    if DungeonFrame then
        local frameScale = Season3:GetEffectiveScale()
        local parentScale = DungeonFrame:GetEffectiveScale()

        local season3Left = Season3:GetLeft() * frameScale
        local season3Right = Season3:GetRight() * frameScale
        local season3Bottom = Season3:GetBottom() * frameScale
        local dungeonLeft = DungeonFrame:GetLeft() * parentScale
        local dungeonRight = DungeonFrame:GetRight() * parentScale
        local dungeonBottom = DungeonFrame:GetBottom() * parentScale

        local anchorToRight = (season3Left >= dungeonRight - 10)

        local offsetX, anchor
        if anchorToRight then
            offsetX = (season3Right - dungeonRight) / parentScale
            anchor = "BOTTOMRIGHT"
        else
            offsetX = (season3Left - dungeonLeft) / parentScale
            anchor = "BOTTOMLEFT"
        end
        local offsetY = (season3Bottom - dungeonBottom) / parentScale

        MDungeonTeleports.Season3Pos = {x = offsetX, y = offsetY, anchor = anchor}
    end
end

-- Load Function
local function LoadandReattachSeason3Position()
    local DungeonFrame = PVEFrame
    if DungeonFrame and MDungeonTeleports.Season3Pos then
        local pos = MDungeonTeleports.Season3Pos

        local frameScale = Season3:GetEffectiveScale()
        local parentScale = DungeonFrame:GetEffectiveScale()

        local adjustedX = pos.x * parentScale / frameScale
        local adjustedY = pos.y * parentScale / frameScale

        Season3:ClearAllPoints()
        local anchor = pos.anchor or "BOTTOMRIGHT"
        Season3:SetPoint(anchor, DungeonFrame, anchor, adjustedX, adjustedY)
    end
end

-- MARK: Login Start Up
local function OnPlayerLogin()
    LoadandReattachSeason3Position()
    MDTUpdateSeason3Colors()
    MDTUpdateSeason3Border()
    MDTUpdateFontS3()
    MDTCompactModeSeason3()
    MDTShiftDragToggleS3()
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript(
    "OnEvent",
    function(self, event)
        if event == "PLAYER_LOGIN" then
            OnPlayerLogin()
        end
    end
)

-- MARK: Visibility Toggle
function MDTSeason3_UpdateVisibility(show)
    local seasonFrame = _G["Season3"]
    if seasonFrame then
        seasonFrame:SetShown(show)
    end
end

-- MARK: Season 3 Frame
local Season3 = CreateFrame("Frame", "Season3", PVEFrame)
Season3:SetSize(164, 130)
Season3:SetMovable(true)
Season3:EnableMouse(true)
Season3:RegisterForDrag("LeftButton")
Season3:SetClampedToScreen(true)

Season3.isBeingDragged = false

Season3:SetScript(
    "OnDragStart",
    function(self)
        self.isBeingDragged = true
        self:StartMoving()
    end
)

Season3:SetScript(
    "OnDragStop",
    function(self)
        if self.isBeingDragged then
            self:StopMovingOrSizing()
            SaveSeason3Position()
            self.isBeingDragged = false
            LoadandReattachSeason3Position()
        end
    end
)

-- Border color
local borderThickness = 2

-- Season3 Backdrop and Borders
local Season3Backdrop = Season3:CreateTexture(nil, "BACKGROUND")
Season3Backdrop:SetAllPoints(Season3)
Season3Backdrop:SetColorTexture(
    MDungeonTeleports.backgroundColor.r,
    MDungeonTeleports.backgroundColor.g,
    MDungeonTeleports.backgroundColor.b,
    MDungeonTeleports.backgroundColor.a
)

local borderTop = Season3:CreateTexture(nil, "OVERLAY")
borderTop:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderTop:SetPoint("TOPLEFT", Season3, "TOPLEFT", borderThickness, 0)
borderTop:SetPoint("TOPRIGHT", Season3, "TOPRIGHT", -borderThickness, 0)
borderTop:SetHeight(borderThickness)

local borderBottom = Season3:CreateTexture(nil, "OVERLAY")
borderBottom:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderBottom:SetPoint("BOTTOMLEFT", Season3, "BOTTOMLEFT", borderThickness, 0)
borderBottom:SetPoint("BOTTOMRIGHT", Season3, "BOTTOMRIGHT", -borderThickness, 0)
borderBottom:SetHeight(borderThickness)

local borderLeft = Season3:CreateTexture(nil, "OVERLAY")
borderLeft:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderLeft:SetPoint("TOPLEFT", Season3, "TOPLEFT", 0, 0)
borderLeft:SetPoint("BOTTOMLEFT", Season3, "BOTTOMLEFT", 0, 0)
borderLeft:SetWidth(borderThickness)

local borderRight = Season3:CreateTexture(nil, "OVERLAY")
borderRight:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderRight:SetPoint("TOPRIGHT", Season3, "TOPRIGHT", 0, 0)
borderRight:SetPoint("BOTTOMRIGHT", Season3, "BOTTOMRIGHT", 0, 0)
borderRight:SetWidth(borderThickness)

-- Season 3 Title
local Season3Title = Season3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
Season3Title:SetPoint("TOP", Season3, "TOP", 0, -10)
Season3Title:SetFont(MDungeonTeleports.customFont, 13, "OUTLINE")
Season3Title:SetText(L["TITLE_S3"])

-- MARK: Time Formatting
local function FormatCooldownTime(seconds)
    if seconds >= 3600 then
        local hours = math.floor(seconds / 3600)
        return string.format("%dh", hours)
    elseif seconds >= 60 then
        local minutes = math.floor(seconds / 60)
        return string.format("%dm", minutes)
    else
        return string.format("%ds", math.floor(seconds))
    end
end

-- -MARK: Cooldown Text Function
local function UpdateCooldownText(button, spellID)
    if InCombatLockdown() then return end

    local cooldownFrame = button.cooldownText
    local cooldownOverlay = button.cooldownOverlay
    local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)

    if spellCooldownInfo then
        local startTime = spellCooldownInfo.startTime
        local duration = spellCooldownInfo.duration
        local isEnabled = spellCooldownInfo.isEnabled

        if startTime > 0 and duration > 0 and isEnabled then
            local remaining = max(0, (startTime + duration) - GetTime())

            if remaining > 5 then
                cooldownFrame:SetText(FormatCooldownTime(remaining))
                cooldownOverlay:Show()
                return
            end
        end
    end

    cooldownFrame:SetText("")
    cooldownOverlay:Hide()
end

-- MARK: Button Settings
local buttonSize = 32
local buttonSpacing = 5

local spellButtons = {}

-- MARK: Button Creation
local function CreateSpellButton(parent, data, rowOffset)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", (data.index - 1) * (buttonSize + buttonSpacing) + 10, rowOffset)

    button.data = data

    local buttonTexture = button:CreateTexture(nil, "BACKGROUND")
    buttonTexture:SetAllPoints(button)
    buttonTexture:SetTexture(data.icon)
    button.buttonTexture = buttonTexture

    local cooldownOverlay = button:CreateTexture(nil, "ARTWORK")
    cooldownOverlay:SetAllPoints(button)
    cooldownOverlay:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    cooldownOverlay:SetVertexColor(0, 0, 0, 0.6)
    cooldownOverlay:Hide()
    button.cooldownOverlay = cooldownOverlay

    local hoverOverlay = button:CreateTexture(nil, "ARTWORK")
    hoverOverlay:SetAllPoints(button)
    hoverOverlay:SetColorTexture(0, 0, 0, 0.6)
    hoverOverlay:SetDrawLayer("ARTWORK", 1)
    hoverOverlay:Hide()
    button.hoverOverlay = hoverOverlay

    local buttonBorderThickness = 2

    local borderTop = button:CreateTexture(nil, "OVERLAY")
    borderTop:SetColorTexture(MDungeonTeleports.borderColor.r, MDungeonTeleports.borderColor.g, MDungeonTeleports.borderColor.b, 1)
    borderTop:SetPoint("TOPLEFT", button, "TOPLEFT", buttonBorderThickness, 0)
    borderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", -buttonBorderThickness, 0)
    borderTop:SetHeight(buttonBorderThickness)
    button.borderTop = borderTop

    local borderBottom = button:CreateTexture(nil, "OVERLAY")
    borderBottom:SetColorTexture(MDungeonTeleports.borderColor.r, MDungeonTeleports.borderColor.g, MDungeonTeleports.borderColor.b, 1)
    borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", buttonBorderThickness, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -buttonBorderThickness, 0)
    borderBottom:SetHeight(buttonBorderThickness)
    button.borderBottom = borderBottom

    local borderLeft = button:CreateTexture(nil, "OVERLAY")
    borderLeft:SetColorTexture(MDungeonTeleports.borderColor.r, MDungeonTeleports.borderColor.g, MDungeonTeleports.borderColor.b, 1)
    borderLeft:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(buttonBorderThickness)
    button.borderLeft = borderLeft

    local borderRight = button:CreateTexture(nil, "OVERLAY")
    borderRight:SetColorTexture(MDungeonTeleports.borderColor.r, MDungeonTeleports.borderColor.g, MDungeonTeleports.borderColor.b, 1)
    borderRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(buttonBorderThickness)
    button.borderRight = borderRight

    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("TOP", button, "BOTTOM", 1, -2)
    buttonText:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    buttonText:SetTextColor(1, 1, 1)
    buttonText:SetText(data.name)
    button.buttonText = buttonText

    local cooldownText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownText:SetPoint("CENTER", button, "CENTER", 1, 0)
    cooldownText:SetTextColor(1, 1, 1)
    cooldownText:SetFont(MDungeonTeleports.customFont, 14, "OUTLINE")
    button.cooldownText = cooldownText

    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", data.spellID)

    table.insert(spellButtons, button)

        local function UpdateButtonTexture()
            if IsSpellKnown(data.spellID) then
                buttonTexture:SetTexture(data.icon)
                buttonTexture:SetDesaturated(false)
            else
                for _, lock in ipairs(AltLocks) do
                    if lock.spellID == data.spellID then
                        if MDungeonTeleports.LockIcons then
                            buttonTexture:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\lock.blp")
                        else
                            buttonTexture:SetTexture(lock.icon)
                        end
                        buttonTexture:SetDesaturated(true)
                        return
                    end
                end
                buttonTexture:SetTexture(data.icon)
                buttonTexture:SetDesaturated(true)
            end
        end

    button.UpdateButtonTexture = UpdateButtonTexture
    UpdateButtonTexture()

    local function OnEvent(self, event)
        if event == "SPELLS_CHANGED" then
            UpdateButtonTexture()
            UpdateCooldownText(self, data.spellID)
        elseif event == "PLAYER_ENTERING_WORLD" then
            UpdateButtonTexture()
            UpdateCooldownText(self, data.spellID)
        elseif event == "CHALLENGE_MODE_COMPLETED" then
            C_Timer.After(2, function()
                UpdateButtonTexture()
                UpdateCooldownText(self, data.spellID)
            end)
        end
    end

    button:SetScript("OnEnter", function(self)
        if MDungeonTeleports.showTooltips then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(data.spellID)
            GameTooltip:Show()
        end
        hoverOverlay:Show()
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        hoverOverlay:Hide()
    end)

    button:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:RegisterEvent("SPELLS_CHANGED")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetScript("OnEvent", OnEvent)

    return button
end

function MDTUpdateS3ButtonTexture()
    for _, button in ipairs(spellButtons) do
        if button.UpdateButtonTexture then
            button:UpdateButtonTexture()
        end
    end
end

-- MARK: Button Rows Setup
local rowOffset = -30
local row2Offset = -79

for i, data in ipairs(MDT_Season3Row1) do
    data.index = i
    data.row = 1
    CreateSpellButton(Season3, data, rowOffset)
end

for i, data in ipairs(MDT_Season3Row2) do
    data.index = i
    data.row = 2
    CreateSpellButton(Season3, data, row2Offset)
end

-- Compact Mode Start
function MDTCompactModeSeason3()
    if MDungeonTeleports.CompactMode == true then
        CompactModeSeason3On()
    else
        CompactModeSeason3Off()
    end
end

-- MARK: Compact Mode On
function CompactModeSeason3On()
    Season3:SetSize(142, 94)
    Season3Title:SetPoint("TOP", Season3, "TOP", 0, -4)
    Season3Title:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")

    local buttonSpacing = 2
    local compactRowOffset = -18
    local compactRow2Offset = -57

    local numColumns = #MDT_Season3Row1

    for _, button in ipairs(spellButtons) do
        local data = button.data
        local isRow2 = (data.row == 2)
        local rowOffset = isRow2 and compactRow2Offset or compactRowOffset
        local colOffset = (data.index - 1) * (buttonSize + buttonSpacing) + 4

        button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", colOffset, rowOffset)

        local buttonText = button.buttonText
        if buttonText then
            buttonText:ClearAllPoints()
            buttonText:SetPoint("TOP", button, "BOTTOM", 1, 12)
            buttonText:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
        end
        local cooldownText = button.cooldownText
        if cooldownText then
            cooldownText:ClearAllPoints()
            cooldownText:SetPoint("CENTER", button, "CENTER", 0, 4)
            cooldownText:SetFont(MDungeonTeleports.customFont, 12, "OUTLINE")
        end
    end
end

-- MARK: Compact Mode Off
function CompactModeSeason3Off()
    Season3:SetSize(164, 130)
    Season3Title:SetPoint("TOP", Season3, "TOP", 0, -10)
    Season3Title:SetFont(MDungeonTeleports.customFont, 13, "OUTLINE")

    local buttonSpacing = 5
    local rowOffset = -30
    local row2Offset = -79

    local numColumns = #MDT_Season3Row1

    for _, button in ipairs(spellButtons) do
        local data = button.data
        local isRow2 = (data.row == 2)
        local rowOffset = isRow2 and row2Offset or rowOffset
        local colOffset = (data.index - 1) * (buttonSize + buttonSpacing) + 10

        button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", colOffset, rowOffset)

        local buttonText = button.buttonText
        if buttonText then
            buttonText:ClearAllPoints()
            buttonText:SetPoint("TOP", button, "BOTTOM", 1, -2)
            buttonText:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
        end
        local cooldownText = button.cooldownText
        if cooldownText then
            cooldownText:ClearAllPoints()
            cooldownText:SetPoint("CENTER", button, "CENTER", 1, 0)
            cooldownText:SetFont(MDungeonTeleports.customFont, 14, "OUTLINE")
        end
    end
end

-- MARK: Shift Drag Toggle
function MDTShiftDragToggleS3()
    if MDungeonTeleports.ShiftDragToggle == true then
        Season3:SetScript("OnDragStart", function(self)
            if IsShiftKeyDown() then
                self.isBeingDragged = true
                self:StartMoving()
            end
        end)
    else
        Season3:SetScript("OnDragStart", function(self)
            self.isBeingDragged = true
            self:StartMoving()
        end)
    end
end

-- MARK: Backdrop and Border Colour Update
function MDTUpdateSeason3Colors()
    local bc = MDungeonTeleports.borderColor
    local bg = MDungeonTeleports.backgroundColor
    local bbc = MDungeonTeleports.buttonBorderColor or { r = 0.05, g = 0.05, b = 0.05, a = 0.8 }

    if Season3Backdrop then
        Season3Backdrop:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
    end

    if borderTop then borderTop:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end
    if borderBottom then borderBottom:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end
    if borderLeft then borderLeft:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end
    if borderRight then borderRight:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end

    for _, button in ipairs(spellButtons) do
        if button.borderTop then
            button.borderTop:SetColorTexture(bbc.r, bbc.g, bbc.b, 1)
        end
        if button.borderBottom then
            button.borderBottom:SetColorTexture(bbc.r, bbc.g, bbc.b, 1)
        end
        if button.borderLeft then
            button.borderLeft:SetColorTexture(bbc.r, bbc.g, bbc.b, 1)
        end
        if button.borderRight then
            button.borderRight:SetColorTexture(bbc.r, bbc.g, bbc.b, 1)
        end
    end
end

-- MARK: Border Thickness Update
function MDTUpdateSeason3Border()
    local borderThickness = MDungeonTeleports.borderThickness

    if borderThickness == 0 then 
        borderTop:Hide() borderBottom:Hide() borderLeft:Hide() borderRight:Hide()
    else 
        borderTop:Show() borderBottom:Show() borderLeft:Show() borderRight:Show() 
    end

    borderTop:SetHeight(borderThickness)
    borderTop:ClearAllPoints()
    borderTop:SetPoint("TOPLEFT", Season3, "TOPLEFT", borderThickness, 0)
    borderTop:SetPoint("TOPRIGHT", Season3, "TOPRIGHT", -borderThickness, 0)

    borderBottom:SetHeight(borderThickness)
    borderBottom:ClearAllPoints()
    borderBottom:SetPoint("BOTTOMLEFT", Season3, "BOTTOMLEFT", borderThickness, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", Season3, "BOTTOMRIGHT", -borderThickness, 0)

    borderLeft:SetWidth(borderThickness)
    borderLeft:ClearAllPoints()
    borderLeft:SetPoint("TOPLEFT", Season3, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", Season3, "BOTTOMLEFT", 0, 0)

    borderRight:SetWidth(borderThickness)
    borderRight:ClearAllPoints()
    borderRight:SetPoint("TOPRIGHT", Season3, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", Season3, "BOTTOMRIGHT", 0, 0)
end

-- MARK: Font Update
function MDTUpdateFontS3()
    local customFont = MDungeonTeleports.customFont
    Season3Title:SetFont(customFont, 11, "OUTLINE")

    local tx2 = MDungeonTeleports.titleColor

    Season3Title:SetTextColor(tx2.r, tx2.g, tx2.b)

    local tx3 = MDungeonTeleports.buttonTextColor

    for _, button in ipairs(spellButtons) do
        local buttonText = button.buttonText
        if buttonText then
            buttonText:SetFont(customFont, 11, "OUTLINE")
            local spellID = button.data and button.data.spellID
            if spellID and not IsSpellKnown(spellID) and MDungeonTeleports.DarkenText then
                buttonText:SetTextColor(0.5, 0.5, 0.5)
            else
                buttonText:SetTextColor(tx3.r, tx3.g, tx3.b)
            end
        end
        local cooldownText = button.cooldownText
        if cooldownText then
            cooldownText:SetFont(customFont, 14, "OUTLINE")
        end
    end
    MDTCompactModeSeason3()
end

local function SetButtonEventsEnabled(enabled)
    if spellButtons then
        for _, button in ipairs(spellButtons) do
            if enabled then
                button:RegisterEvent("SPELLS_CHANGED")
            else
                button:UnregisterEvent("SPELLS_CHANGED")
            end
        end
    end
end

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        SetButtonEventsEnabled(false)
    elseif event == "PLAYER_REGEN_ENABLED" then
        SetButtonEventsEnabled(true)
    end
end)