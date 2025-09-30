-- Start Up
local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
MDungeonTeleports.customFont = GameFontNormal:GetFont()

-- Save Function
local function SavePortalLibraryPosition()
    local DungeonFrame = PVEFrame
    if DungeonFrame then
        local frameScale = PortalLibrary:GetEffectiveScale()
        local parentScale = DungeonFrame:GetEffectiveScale()

        local PortalLibraryLeft = PortalLibrary:GetLeft() * frameScale
        local PortalLibraryRight = PortalLibrary:GetRight() * frameScale
        local PortalLibraryBottom = PortalLibrary:GetBottom() * frameScale
        local dungeonLeft = DungeonFrame:GetLeft() * parentScale
        local dungeonRight = DungeonFrame:GetRight() * parentScale
        local dungeonBottom = DungeonFrame:GetBottom() * parentScale

        local anchorToRight = (PortalLibraryLeft >= dungeonRight - 10)

        local offsetX, anchor
        if anchorToRight then
            offsetX = (PortalLibraryRight - dungeonRight) / parentScale
            anchor = "BOTTOMRIGHT"
        else
            offsetX = (PortalLibraryLeft - dungeonLeft) / parentScale
            anchor = "BOTTOMLEFT"
        end
        local offsetY = (PortalLibraryBottom - dungeonBottom) / parentScale

        MDungeonTeleports.PortalLibraryPos = {x = offsetX, y = offsetY, anchor = anchor}
    end
end

-- Load Function
local function LoadandReattatchPortalLibraryPosition()
    local DungeonFrame = PVEFrame
    if DungeonFrame and MDungeonTeleports.PortalLibraryPos then
        local pos = MDungeonTeleports.PortalLibraryPos

        local frameScale = PortalLibrary:GetEffectiveScale()
        local parentScale = DungeonFrame:GetEffectiveScale()

        local adjustedX = pos.x * parentScale / frameScale
        local adjustedY = pos.y * parentScale / frameScale

        PortalLibrary:ClearAllPoints()
        local anchor = pos.anchor or "BOTTOMRIGHT"
        PortalLibrary:SetPoint(anchor, DungeonFrame, anchor, adjustedX, adjustedY)
    end
end

-- MARK: Login Start Up
local function OnPlayerLogin()
    LoadandReattatchPortalLibraryPosition()
    MDTUpdatePortalLibraryColors()
    MDTUpdatePortalLibraryBorder()
    MDTUpdateFontPL()
    MDTCompactModePortalLibrary()
    MDTShiftDragToggleDL()
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
function MDTPortalLibrary_UpdateVisibility(show)
    local portalLibraryFrame = _G["PortalLibrary"]
    if portalLibraryFrame then
        portalLibraryFrame:SetShown(show)
    end
end

-- MARK: Portal Library Frame
local PortalLibrary = CreateFrame("Frame", "PortalLibrary", PVEFrame)
PortalLibrary:SetSize(384, 510)
PortalLibrary:SetPoint("CENTER", PVEFrame, "CENTER", 900, 0)
PortalLibrary:SetMovable(true)
PortalLibrary:EnableMouse(true)
PortalLibrary:RegisterForDrag("LeftButton")
PortalLibrary:SetClampedToScreen(true)

PortalLibrary:SetScript(
    "OnDragStart",
    function(self)
        self.isBeingDragged = true
        self:StartMoving()
    end
)

PortalLibrary:SetScript(
    "OnDragStop",
    function(self)
        if self.isBeingDragged then
            self:StopMovingOrSizing()
            SavePortalLibraryPosition()
            self.isBeingDragged = false
            LoadandReattatchPortalLibraryPosition()
        end
    end
)

-- Border thickness
local borderThickness = 2

-- Portal Library Backdrop and Borders
local PortalLibraryBackdrop = PortalLibrary:CreateTexture(nil, "BACKGROUND")
PortalLibraryBackdrop:SetAllPoints(PortalLibrary)
PortalLibraryBackdrop:SetColorTexture(
    MDungeonTeleports.backgroundColor.r,
    MDungeonTeleports.backgroundColor.g,
    MDungeonTeleports.backgroundColor.b,
    MDungeonTeleports.backgroundColor.a
)

local borderTop = PortalLibrary:CreateTexture(nil, "OVERLAY")
borderTop:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderTop:SetPoint("TOPLEFT", PortalLibrary, "TOPLEFT", borderThickness, 0)
borderTop:SetPoint("TOPRIGHT", PortalLibrary, "TOPRIGHT", -borderThickness, 0)
borderTop:SetHeight(borderThickness)

local borderBottom = PortalLibrary:CreateTexture(nil, "OVERLAY")
borderBottom:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderBottom:SetPoint("BOTTOMLEFT", PortalLibrary, "BOTTOMLEFT", borderThickness, 0)
borderBottom:SetPoint("BOTTOMRIGHT", PortalLibrary, "BOTTOMRIGHT", -borderThickness, 0)
borderBottom:SetHeight(borderThickness)

local borderLeft = PortalLibrary:CreateTexture(nil, "OVERLAY")
borderLeft:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderLeft:SetPoint("TOPLEFT", PortalLibrary, "TOPLEFT", 0, 0)
borderLeft:SetPoint("BOTTOMLEFT", PortalLibrary, "BOTTOMLEFT", 0, 0)
borderLeft:SetWidth(borderThickness)

local borderRight = PortalLibrary:CreateTexture(nil, "OVERLAY")
borderRight:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderRight:SetPoint("TOPRIGHT", PortalLibrary, "TOPRIGHT", 0, 0)
borderRight:SetPoint("BOTTOMRIGHT", PortalLibrary, "BOTTOMRIGHT", 0, 0)
borderRight:SetWidth(borderThickness)

-- Portal Library Title
local PortalLibraryTitle = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
PortalLibraryTitle:SetPoint("TOP", PortalLibrary, "TOP", 0, -10)
PortalLibraryTitle:SetFont(MDungeonTeleports.customFont, 13, "OUTLINE")
PortalLibraryTitle:SetTextColor(1, 1, 1)
PortalLibraryTitle:SetText(L["DUNGEON_LIBRARY"])

-- MARK: Expansion Titles Setup
local titleTWW = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleTWW:SetPoint("TOP", PortalLibrary, "TOP", 0, -26)
local font, _, flags = titleTWW:GetFont()
titleTWW:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleTWW:SetTextColor(0.2, 0.8, 0.9)
titleTWW:SetText(L["EXP_TWW"])

local titleDF = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleDF:SetPoint("TOP", PortalLibrary, "TOP", 0, -86)
local font, _, flags = titleDF:GetFont()
titleDF:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleDF:SetTextColor(0.2, 0.8, 0.9)
titleDF:SetText(L["EXP_DF"])

local titleSL = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleSL:SetPoint("TOP", PortalLibrary, "TOP", 0, -146)
local font, _, flags = titleSL:GetFont()
titleSL:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleSL:SetTextColor(0.2, 0.8, 0.9)
titleSL:SetText(L["EXP_SL"])

local titleBFA = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleBFA:SetPoint("TOP", PortalLibrary, "TOP", 0, -206)
local font, _, flags = titleBFA:GetFont()
titleBFA:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleBFA:SetTextColor(0.2, 0.8, 0.9)
titleBFA:SetText(L["EXP_BFA"])

local titleLeg = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleLeg:SetPoint("TOP", PortalLibrary, "TOP", 0, -266)
local font, _, flags = titleLeg:GetFont()
titleLeg:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleLeg:SetTextColor(0.2, 0.8, 0.9)
titleLeg:SetText(L["EXP_LEG"])

local titleWOD = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleWOD:SetPoint("TOP", PortalLibrary, "TOP", 0, -326)
local font, _, flags = titleWOD:GetFont()
titleWOD:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleWOD:SetTextColor(0.2, 0.8, 0.9)
titleWOD:SetText(L["EXP_WOD"])

local titleMOP = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleMOP:SetPoint("TOP", PortalLibrary, "TOP", 0, -386)
local font, _, flags = titleMOP:GetFont()
titleMOP:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleMOP:SetTextColor(0.2, 0.8, 0.9)
titleMOP:SetText(L["EXP_MOP"] )

local titleCATA = PortalLibrary:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleCATA:SetPoint("TOP", PortalLibrary, "TOP", 0, -446)
local font, _, flags = titleSL:GetFont()
titleCATA:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleCATA:SetTextColor(0.2, 0.8, 0.9)
titleCATA:SetText(L["EXP_CATA"])

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

function MDTUpdatePLButtonTexture()
    for _, button in ipairs(spellButtons) do
        if button.UpdateButtonTexture then
            button:UpdateButtonTexture()
        end
    end
end

--MARK: Button Rows Setup
local rowOffset = -40
local row2Offset = -99
local row3Offset = -159
local row4Offset = -219
local row5Offset = -279
local row6Offset = -339
local row7Offset = -399
local row8Offset = -459

-- MARK: Button Rows Setup
for i, data in ipairs(MDT_PL_TWW) do
    data.index = i
    data.row = 1
    CreateSpellButton(PortalLibrary, data, rowOffset)
end

for i, data in ipairs(MDT_PL_DF) do
    data.index = i
    data.row = 2
    CreateSpellButton(PortalLibrary, data, row2Offset)
end

for i, data in ipairs(MDT_PL_SL) do
    data.index = i
    data.row = 3
    CreateSpellButton(PortalLibrary, data, row3Offset)
end

for i, data in ipairs(MDT_PL_BFA) do
    data.index = i
    data.row = 4
    CreateSpellButton(PortalLibrary, data, row4Offset)
end

for i, data in ipairs(MDT_PL_Legion) do
    data.index = i
    data.row = 5
    CreateSpellButton(PortalLibrary, data, row5Offset)
end

for i, data in ipairs(MDT_PL_WOD) do
    data.index = i
    data.row = 6
    CreateSpellButton(PortalLibrary, data, row6Offset)
end

for i, data in ipairs(MDT_PL_MOP) do
    data.index = i
    data.row = 7
    CreateSpellButton(PortalLibrary, data, row7Offset)
end

for i, data in ipairs(MDT_PL_CATA) do
    data.index = i
    data.row = 8
    CreateSpellButton(PortalLibrary, data, row8Offset)
end

-- Compact Mode Start
function MDTCompactModePortalLibrary()
    if MDungeonTeleports.CompactMode == true then
        CompactModePortalLibraryOn()
    else
        CompactModePortalLibraryOff()
    end
end

-- Compact Mode On
function CompactModePortalLibraryOn()
    PortalLibrary:SetSize(348, 386)
    PortalLibraryTitle:SetPoint("TOP", PortalLibrary, "TOP", 0, -4)
    PortalLibraryTitle:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")

    titleTWW:SetPoint("TOP", PortalLibrary, "TOP", 0, -15)
    titleDF:SetPoint("TOP", PortalLibrary, "TOP", 0, -61)
    titleSL:SetPoint("TOP", PortalLibrary, "TOP", 0, -107)
    titleBFA:SetPoint("TOP", PortalLibrary, "TOP", 0, -153)
    titleLeg:SetPoint("TOP", PortalLibrary, "TOP", 0, -199)
    titleWOD:SetPoint("TOP", PortalLibrary, "TOP", 0, -245)
    titleMOP:SetPoint("TOP", PortalLibrary, "TOP", 0, -291)
    titleCATA:SetPoint("TOP", PortalLibrary, "TOP", 0, -337)

    titleTWW:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleDF:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleSL:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleBFA:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleLeg:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleWOD:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleMOP:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleCATA:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")

    local buttonSpacing = 2
    local rowOffset = -27
    local row2Offset = -73
    local row3Offset = -119
    local row4Offset = -165
    local row5Offset = -211
    local row6Offset = -257
    local row7Offset = -303
    local row8Offset = -349
    local row9Offset = -395
    local row10Offset = -441

    local numColumns = #MDT_PL_TWW

    for _, button in ipairs(spellButtons) do
        local data = button.data
        local rowOffsets = {
            [1] = rowOffset,
            [2] = row2Offset,
            [3] = row3Offset,
            [4] = row4Offset,
            [5] = row5Offset,
            [6] = row6Offset,
            [7] = row7Offset,
            [8] = row8Offset,
            [9] = row9Offset,
            [10] = row10Offset
        }

        local rowOffsetValue = rowOffsets[data.row] or rowOffset
        local colOffset = (data.index - 1) * (buttonSize + buttonSpacing) + 4

        button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", colOffset, rowOffsetValue)

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

-- Compact Mode Off
function CompactModePortalLibraryOff()
    PortalLibrary:SetSize(384, 510)
    PortalLibraryTitle:SetPoint("TOP", PortalLibrary, "TOP", 0, -10)
    PortalLibraryTitle:SetFont(MDungeonTeleports.customFont, 13, "OUTLINE")

    titleTWW:SetPoint("TOP", PortalLibrary, "TOP", 0, -26)
    titleDF:SetPoint("TOP", PortalLibrary, "TOP", 0, -86)
    titleSL:SetPoint("TOP", PortalLibrary, "TOP", 0, -146)
    titleBFA:SetPoint("TOP", PortalLibrary, "TOP", 0, -206)
    titleLeg:SetPoint("TOP", PortalLibrary, "TOP", 0, -266)
    titleWOD:SetPoint("TOP", PortalLibrary, "TOP", 0, -326)
    titleMOP:SetPoint("TOP", PortalLibrary, "TOP", 0, -386)
    titleCATA:SetPoint("TOP", PortalLibrary, "TOP", 0, -446)

    titleTWW:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleDF:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleSL:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleBFA:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleLeg:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleWOD:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleMOP:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleCATA:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")

    local buttonSpacing = 5
    local rowOffset = -40
    local row2Offset = -99
    local row3Offset = -159
    local row4Offset = -219
    local row5Offset = -279
    local row6Offset = -339
    local row7Offset = -399
    local row8Offset = -459
    local row9Offset = -519
    local row10Offset = -579

    local numColumns = #MDT_PL_TWW

    for _, button in ipairs(spellButtons) do
        local data = button.data
        local rowOffsets = {
            [1] = rowOffset,
            [2] = row2Offset,
            [3] = row3Offset,
            [4] = row4Offset,
            [5] = row5Offset,
            [6] = row6Offset,
            [7] = row7Offset,
            [8] = row8Offset,
            [9] = row9Offset,
            [10] = row10Offset
        }

        local rowOffsetValue = rowOffsets[data.row] or rowOffset
        local colOffset = (data.index - 1) * (buttonSize + buttonSpacing) + 10

        button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", colOffset, rowOffsetValue)

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
function MDTShiftDragToggleDL()
    if MDungeonTeleports.ShiftDragToggle == true then
        PortalLibrary:SetScript("OnDragStart", function(self)
            if IsShiftKeyDown() then
                self.isBeingDragged = true
                self:StartMoving()
            end
        end)
    else
        PortalLibrary:SetScript("OnDragStart", function(self)
            self.isBeingDragged = true
            self:StartMoving()
        end)
    end
end

-- MARK: Backdrop and Border Colour Update
function MDTUpdatePortalLibraryColors()
    local bc = MDungeonTeleports.borderColor
    local bg = MDungeonTeleports.backgroundColor
    local bbc = MDungeonTeleports.buttonBorderColor or { r = 0.05, g = 0.05, b = 0.05, a = 0.8 }

    if PortalLibraryBackdrop then
        PortalLibraryBackdrop:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
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
function MDTUpdatePortalLibraryBorder()
    local borderThickness = MDungeonTeleports.borderThickness

    if borderThickness == 0 then 
        borderTop:Hide() borderBottom:Hide() borderLeft:Hide() borderRight:Hide()
    else 
        borderTop:Show() borderBottom:Show() borderLeft:Show() borderRight:Show() 
    end

    borderTop:SetHeight(borderThickness)
    borderTop:ClearAllPoints()
    borderTop:SetPoint("TOPLEFT", PortalLibrary, "TOPLEFT", borderThickness, 0)
    borderTop:SetPoint("TOPRIGHT", PortalLibrary, "TOPRIGHT", -borderThickness, 0)

    borderBottom:SetHeight(borderThickness)
    borderBottom:ClearAllPoints()
    borderBottom:SetPoint("BOTTOMLEFT", PortalLibrary, "BOTTOMLEFT", borderThickness, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", PortalLibrary, "BOTTOMRIGHT", -borderThickness, 0)

    borderLeft:SetWidth(borderThickness)
    borderLeft:ClearAllPoints()
    borderLeft:SetPoint("TOPLEFT", PortalLibrary, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", PortalLibrary, "BOTTOMLEFT", 0, 0)

    borderRight:SetWidth(borderThickness)
    borderRight:ClearAllPoints()
    borderRight:SetPoint("TOPRIGHT", PortalLibrary, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", PortalLibrary, "BOTTOMRIGHT", 0, 0)
end

-- MARK: Font Update
function MDTUpdateFontPL()
    local customFont = MDungeonTeleports.customFont
    PortalLibraryTitle:SetFont(customFont, 11, "OUTLINE")

    titleTWW:SetFont(customFont, 11, "OUTLINE")
    titleDF:SetFont(customFont, 11, "OUTLINE")
    titleSL:SetFont(customFont, 11, "OUTLINE")
    titleBFA:SetFont(customFont, 11, "OUTLINE")
    titleLeg:SetFont(customFont, 11, "OUTLINE")
    titleWOD:SetFont(customFont, 11, "OUTLINE")
    titleMOP:SetFont(customFont, 11, "OUTLINE")
    titleCATA:SetFont(customFont, 11, "OUTLINE")

    local tx = MDungeonTeleports.expansionColor

    titleTWW:SetTextColor(tx.r, tx.g, tx.b) 
    titleDF:SetTextColor(tx.r, tx.g, tx.b)
    titleSL:SetTextColor(tx.r, tx.g, tx.b)
    titleBFA:SetTextColor(tx.r, tx.g, tx.b)
    titleLeg:SetTextColor(tx.r, tx.g, tx.b)
    titleWOD:SetTextColor(tx.r, tx.g, tx.b)
    titleMOP:SetTextColor(tx.r, tx.g, tx.b)
    titleCATA:SetTextColor(tx.r, tx.g, tx.b)

    local tx2 = MDungeonTeleports.titleColor

    PortalLibraryTitle:SetTextColor(tx2.r, tx2.g, tx2.b)

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
    MDTCompactModePortalLibrary()
end

local function SetButtonEventsEnabled(enabled)
    if spellButtons then
        for _, button in ipairs(spellButtons) do
            if enabled then
                button:RegisterEvent("SPELL_UPDATE_COOLDOWN")
                button:RegisterEvent("SPELLS_CHANGED")
            else
                button:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
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