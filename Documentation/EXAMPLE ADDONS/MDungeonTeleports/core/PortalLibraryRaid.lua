-- Start Up
local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
MDungeonTeleports.customFont = GameFontNormal:GetFont()

-- Save Function
local function SavePortalLibraryRaidPosition()
   local DungeonFrame = PVEFrame
   if DungeonFrame then
       local frameScale = PortalLibraryRaid:GetEffectiveScale()
       local parentScale = DungeonFrame:GetEffectiveScale()

       local PortalLibraryRaidLeft = PortalLibraryRaid:GetLeft() * frameScale
       local PortalLibraryRaidRight = PortalLibraryRaid:GetRight() * frameScale
       local PortalLibraryRaidBottom = PortalLibraryRaid:GetBottom() * frameScale
       local dungeonLeft = DungeonFrame:GetLeft() * parentScale
       local dungeonRight = DungeonFrame:GetRight() * parentScale
       local dungeonBottom = DungeonFrame:GetBottom() * parentScale
       
       local anchorToRight = (PortalLibraryRaidLeft >= dungeonRight - 10)

       local offsetX, anchor
       if anchorToRight then
           offsetX = (PortalLibraryRaidRight - dungeonRight) / parentScale
           anchor = "BOTTOMRIGHT"
       else
           offsetX = (PortalLibraryRaidLeft - dungeonLeft) / parentScale
           anchor = "BOTTOMLEFT"
       end
       local offsetY = (PortalLibraryRaidBottom - dungeonBottom) / parentScale

       MDungeonTeleports.PortalLibraryRaidPos = {x = offsetX, y = offsetY, anchor = anchor}
   end
end

-- Load Function
local function LoadandReattatchPortalLibraryRaidPosition()
   local DungeonFrame = PVEFrame
   if DungeonFrame and MDungeonTeleports.PortalLibraryRaidPos then
       local pos = MDungeonTeleports.PortalLibraryRaidPos

       local frameScale = PortalLibraryRaid:GetEffectiveScale()
       local parentScale = DungeonFrame:GetEffectiveScale()

       local adjustedX = pos.x * parentScale / frameScale
       local adjustedY = pos.y * parentScale / frameScale

       PortalLibraryRaid:ClearAllPoints()
       local anchor = pos.anchor or "BOTTOMRIGHT"
       PortalLibraryRaid:SetPoint(anchor, DungeonFrame, anchor, adjustedX, adjustedY)
   end
end

-- MARK: Login Start Up
local function OnPlayerLogin()
    LoadandReattatchPortalLibraryRaidPosition()
    MDTUpdatePortalLibraryRaidColors()
    MDTUpdatePortalLibraryRaidBorder()
    MDTUpdateFontPLR()
    MDTCompactModePortalLibraryRaid()
    MDTShiftDragToggleRL()
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
function MDTPortalLibraryRaid_UpdateVisibility(show)
   local portalLibraryRaidFrame = _G["PortalLibraryRaid"]
   if portalLibraryRaidFrame then
       portalLibraryRaidFrame:SetShown(show)
   end
end

-- MARK: Portal Library Raid Frame
local PortalLibraryRaid = CreateFrame("Frame", "PortalLibraryRaid", PVEFrame)
PortalLibraryRaid:SetSize(124, 212)
PortalLibraryRaid:SetPoint("CENTER", PVEFrame, "CENTER", 860, -270)
PortalLibraryRaid:SetMovable(true)
PortalLibraryRaid:EnableMouse(true)
PortalLibraryRaid:RegisterForDrag("LeftButton")
PortalLibraryRaid:SetClampedToScreen(true)

PortalLibraryRaid.isBeingDragged = false

PortalLibraryRaid:SetScript(
   "OnDragStart",
   function(self)
       self.isBeingDragged = true
       self:StartMoving()
   end
)

PortalLibraryRaid:SetScript(
   "OnDragStop",
   function(self)
       if self.isBeingDragged then
           self:StopMovingOrSizing()
           SavePortalLibraryRaidPosition()
           self.isBeingDragged = false
           LoadandReattatchPortalLibraryRaidPosition()
       end
   end
)

-- Border thickness
local borderThickness = 2

-- PortalLibraryRaid Backdrop and Borders
local PortalLibraryRaidBackdrop = PortalLibraryRaid:CreateTexture(nil, "BACKGROUND")
PortalLibraryRaidBackdrop:SetAllPoints(PortalLibraryRaid)
PortalLibraryRaidBackdrop:SetColorTexture(
    MDungeonTeleports.backgroundColor.r,
    MDungeonTeleports.backgroundColor.g,
    MDungeonTeleports.backgroundColor.b,
    MDungeonTeleports.backgroundColor.a
)

local borderTop = PortalLibraryRaid:CreateTexture(nil, "OVERLAY")
borderTop:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderTop:SetPoint("TOPLEFT", PortalLibraryRaid, "TOPLEFT", borderThickness, 0)
borderTop:SetPoint("TOPRIGHT", PortalLibraryRaid, "TOPRIGHT", -borderThickness, 0)
borderTop:SetHeight(borderThickness)

local borderBottom = PortalLibraryRaid:CreateTexture(nil, "OVERLAY")
borderBottom:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderBottom:SetPoint("BOTTOMLEFT", PortalLibraryRaid, "BOTTOMLEFT", borderThickness, 0)
borderBottom:SetPoint("BOTTOMRIGHT", PortalLibraryRaid, "BOTTOMRIGHT", -borderThickness, 0)
borderBottom:SetHeight(borderThickness)

local borderLeft = PortalLibraryRaid:CreateTexture(nil, "OVERLAY")
borderLeft:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderLeft:SetPoint("TOPLEFT", PortalLibraryRaid, "TOPLEFT", 0, 0)
borderLeft:SetPoint("BOTTOMLEFT", PortalLibraryRaid, "BOTTOMLEFT", 0, 0)
borderLeft:SetWidth(borderThickness)

local borderRight = PortalLibraryRaid:CreateTexture(nil, "OVERLAY")
borderRight:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderRight:SetPoint("TOPRIGHT", PortalLibraryRaid, "TOPRIGHT", 0, 0)
borderRight:SetPoint("BOTTOMRIGHT", PortalLibraryRaid, "BOTTOMRIGHT", 0, 0)
borderRight:SetWidth(borderThickness)

-- Portal Library Raid Title
local PortalLibraryRaidTitle = PortalLibraryRaid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
PortalLibraryRaidTitle:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -10)
PortalLibraryRaidTitle:SetFont(MDungeonTeleports.customFont, 13, "OUTLINE")
PortalLibraryRaidTitle:SetText(L["RAID_LIBRARY"])

-- Shadowlands Title
local titleShadowlands = PortalLibraryRaid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleShadowlands:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -27)
local font, _, flags = titleShadowlands:GetFont()
titleShadowlands:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleShadowlands:SetTextColor(0.2, 0.8, 0.9)
titleShadowlands:SetText(L["EXP_SL"])

-- Dragonflight Title
local titleDragonflight = PortalLibraryRaid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleDragonflight:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -87)
local font, _, flags = titleDragonflight:GetFont()
titleDragonflight:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleDragonflight:SetTextColor(0.2, 0.8, 0.9)
titleDragonflight:SetText(L["EXP_DF"])

-- The War Within Title
local titleTheWarWithin = PortalLibraryRaid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleTheWarWithin:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -147)
local font, _, flags = titleTheWarWithin:GetFont()
titleTheWarWithin:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
titleTheWarWithin:SetTextColor(0.2, 0.8, 0.9)
titleTheWarWithin:SetText(L["EXP_TWW"])

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
local function CreateSpellButton(parent, data, rowOffset, horizontalOffset)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", (data.index - 1) * (buttonSize + buttonSpacing) + 10 + (horizontalOffset or 0), rowOffset)

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

function MDTUpdatePLRButtonTexture()
    for _, button in ipairs(spellButtons) do
        if button.UpdateButtonTexture then
            button:UpdateButtonTexture()
        end
    end
end

--MARK: Button Rows Setup
local rowOffset = -40
local row1HorizontalOffset = 0
local row2Offset = -100
local row2HorizontalOffset = 0
local row3Offset = -160
local row3HorizontalOffset = 0

-- MARK: Button Rows Setup
for i, data in ipairs(MDT_PLR_TWW) do
   data.index = i
   data.row = 1
   CreateSpellButton(PortalLibraryRaid, data, rowOffset, row1HorizontalOffset)
end

for i, data in ipairs(MDT_PLR_DF) do
   data.index = i
   data.row = 2
   CreateSpellButton(PortalLibraryRaid, data, row2Offset, row2HorizontalOffset)
end

for i, data in ipairs(MDT_PLR_SL) do
   data.index = i
   data.row = 3
   CreateSpellButton(PortalLibraryRaid, data, row3Offset, row3HorizontalOffset)
end

-- Compact Mode Start
function MDTCompactModePortalLibraryRaid()
   if MDungeonTeleports.CompactMode == true then
       CompactModePortalLibraryRaidOn()
   else
       CompactModePortalLibraryRaidOff()
   end
end

-- Compact Mode On
function CompactModePortalLibraryRaidOn()
    PortalLibraryRaid:SetSize(108, 156)
    PortalLibraryRaidTitle:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -4)
    PortalLibraryRaidTitle:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")

    titleTheWarWithin:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -15)
    titleDragonflight:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -61)
    titleShadowlands:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -107)

    titleTheWarWithin:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleDragonflight:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")
    titleShadowlands:SetFont(MDungeonTeleports.customFont, 10, "OUTLINE")

    local buttonSpacing = 2
    local rowOffsets = { -27, -73, -119 }

    for _, button in ipairs(spellButtons) do
        local data = button.data
        local rowOffsetValue = rowOffsets[data.row] or -27
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
function CompactModePortalLibraryRaidOff()
    PortalLibraryRaid:SetSize(124, 212)
    PortalLibraryRaidTitle:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -10)
    PortalLibraryRaidTitle:SetFont(MDungeonTeleports.customFont, 13, "OUTLINE")

    titleTheWarWithin:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -26)
    titleDragonflight:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -86)
    titleShadowlands:SetPoint("TOP", PortalLibraryRaid, "TOP", 0, -146)

    titleTheWarWithin:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleDragonflight:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")
    titleShadowlands:SetFont(MDungeonTeleports.customFont, 11, "OUTLINE")

    local buttonSpacing = 5
    local rowOffsets = { -40, -100, -160 }

    for _, button in ipairs(spellButtons) do
        local data = button.data
        local rowOffsetValue = rowOffsets[data.row] or -40
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
function MDTShiftDragToggleRL()
    if MDungeonTeleports.ShiftDragToggle == true then
        PortalLibraryRaid:SetScript("OnDragStart", function(self)
            if IsShiftKeyDown() then
                self.isBeingDragged = true
                self:StartMoving()
            end
        end)
    else
        PortalLibraryRaid:SetScript("OnDragStart", function(self)
            self.isBeingDragged = true
            self:StartMoving()
        end)
    end
end

-- MARK: Backdrop and Border Colour Update
function MDTUpdatePortalLibraryRaidColors()
    local bc = MDungeonTeleports.borderColor
    local bg = MDungeonTeleports.backgroundColor
    local bbc = MDungeonTeleports.buttonBorderColor or { r = 0.05, g = 0.05, b = 0.05, a = 0.8 }

    if PortalLibraryRaidBackdrop then
        PortalLibraryRaidBackdrop:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
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
function MDTUpdatePortalLibraryRaidBorder()
    local borderThickness = MDungeonTeleports.borderThickness

    if borderThickness == 0 then 
        borderTop:Hide() borderBottom:Hide() borderLeft:Hide() borderRight:Hide()
    else 
        borderTop:Show() borderBottom:Show() borderLeft:Show() borderRight:Show() 
    end

    borderTop:SetHeight(borderThickness)
    borderTop:ClearAllPoints()
    borderTop:SetPoint("TOPLEFT", PortalLibraryRaid, "TOPLEFT", borderThickness, 0)
    borderTop:SetPoint("TOPRIGHT", PortalLibraryRaid, "TOPRIGHT", -borderThickness, 0)

    borderBottom:SetHeight(borderThickness)
    borderBottom:ClearAllPoints()
    borderBottom:SetPoint("BOTTOMLEFT", PortalLibraryRaid, "BOTTOMLEFT", borderThickness, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", PortalLibraryRaid, "BOTTOMRIGHT", -borderThickness, 0)

    borderLeft:SetWidth(borderThickness)
    borderLeft:ClearAllPoints()
    borderLeft:SetPoint("TOPLEFT", PortalLibraryRaid, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", PortalLibraryRaid, "BOTTOMLEFT", 0, 0)

    borderRight:SetWidth(borderThickness)
    borderRight:ClearAllPoints()
    borderRight:SetPoint("TOPRIGHT", PortalLibraryRaid, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", PortalLibraryRaid, "BOTTOMRIGHT", 0, 0)
end

-- MARK: Font Update
function MDTUpdateFontPLR()
    local customFont = MDungeonTeleports.customFont
    PortalLibraryRaidTitle:SetFont(customFont, 11, "OUTLINE")

    titleShadowlands:SetFont(customFont, 11, "OUTLINE")
    titleDragonflight:SetFont(customFont, 11, "OUTLINE")
    titleTheWarWithin:SetFont(customFont, 11, "OUTLINE")

    local tx = MDungeonTeleports.expansionColor

    titleShadowlands:SetTextColor(tx.r, tx.g, tx.b)
    titleDragonflight:SetTextColor(tx.r, tx.g, tx.b)
    titleTheWarWithin:SetTextColor(tx.r, tx.g, tx.b)

    local tx2 = MDungeonTeleports.titleColor

    PortalLibraryRaidTitle:SetTextColor(tx2.r, tx2.g, tx2.b)

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
    MDTCompactModePortalLibraryRaid()
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