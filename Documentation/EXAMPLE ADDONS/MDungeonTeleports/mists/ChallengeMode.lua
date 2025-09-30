-- MARK: Start Up
if not MDungeonTeleports then
    MDungeonTeleports = {}
end

if not MDungeonTeleports.Challenge then
    MDungeonTeleports.Challenge = {x = 1005, y = -19}
end

if MDungeonTeleports.showTooltips == nil then
    MDungeonTeleports.showTooltips = false
end

if MDungeonTeleports.ShiftDragToggle == nil then
    MDungeonTeleports.ShiftDragToggle = false
end

-- Save Function
local function SaveChallengeFramePos()
    local DungeonFrame = PVEFrame
    if DungeonFrame then
        local frameScale = ChallengeFrame:GetScale()
        local parentScale = DungeonFrame:GetScale()

        local season1Left = ChallengeFrame:GetLeft() * frameScale
        local season1Top = ChallengeFrame:GetTop() * frameScale
        local dungeonLeft = DungeonFrame:GetLeft() * parentScale
        local dungeonTop = DungeonFrame:GetTop() * parentScale

        local offsetX = (season1Left - dungeonLeft) / parentScale
        local offsetY = (season1Top - dungeonTop) / parentScale

        MDungeonTeleports.Challenge = {x = offsetX, y = offsetY}
    end
end

-- Load Function
local function LoadChallengeFramePos()
    local VarVersionS1 = 1
    if MDungeonTeleports.VarVersionS1 == nil or MDungeonTeleports.VarVersionS1 < VarVersionS1 then
        MDungeonTeleports.VarVersionS1 = VarVersionS1
        MDungeonTeleports.Challenge = {x = 1005, y = -19}
    end
    local DungeonFrame = PVEFrame
    if DungeonFrame and MDungeonTeleports.Challenge then
        local pos = MDungeonTeleports.Challenge

        local frameScale = ChallengeFrame:GetScale()
        local parentScale = DungeonFrame:GetScale()

        local adjustedX = pos.x * parentScale / frameScale
        local adjustedY = pos.y * parentScale / frameScale

        ChallengeFrame:ClearAllPoints()
        ChallengeFrame:SetPoint("TOPLEFT", DungeonFrame, "TOPLEFT", adjustedX, adjustedY)
    end
end

-- Reattach Function
local function ReattatchChallengeFrame()
    local DungeonFrame = PVEFrame
    if DungeonFrame and MDungeonTeleports.Challenge then
        local pos = MDungeonTeleports.Challenge

        local frameScale = ChallengeFrame:GetScale()
        local parentScale = DungeonFrame:GetScale()

        local adjustedX = pos.x * parentScale / frameScale
        local adjustedY = pos.y * parentScale / frameScale

        ChallengeFrame:ClearAllPoints()
        ChallengeFrame:SetPoint("TOPLEFT", DungeonFrame, "TOPLEFT", adjustedX, adjustedY)
    end
end

-- MARK: Save Function on Close
local function OnPVEFrameClose()
    SaveChallengeFramePos()
end

-- MARK: Login Start Up
local function OnPlayerLogin()
    LoadChallengeFramePos()
    UpdateChallengeFrameUI()
    ShiftDragToggleChallengeFrame()
    showTooltips = MDungeonTeleports.showTooltips
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

-- MARK: Tooltip Toggle
function ToggleTooltips()
    MDungeonTeleports.showTooltips = not MDungeonTeleports.showTooltips
end

-- MARK: Visibility Toggle
function ChallengeFrame_UpdateVisibility(show)
    local seasonFrame = _G["ChallengeFrame"]
    if seasonFrame then
        seasonFrame:SetShown(show)
    end
end

-- MARK: Season 1 Frame
local ChallengeFrame = CreateFrame("Frame", "ChallengeFrame", PVEFrame)
ChallengeFrame:SetSize(126, 180)
ChallengeFrame:SetMovable(true)
ChallengeFrame:EnableMouse(true)
ChallengeFrame:RegisterForDrag("LeftButton")
ChallengeFrame:SetClampedToScreen(true)

ChallengeFrame.isBeingDragged = false

ChallengeFrame:SetScript(
    "OnDragStart",
    function(self)
        self.isBeingDragged = true
        self:StartMoving()
    end
)

ChallengeFrame:SetScript(
    "OnDragStop",
    function(self)
        if self.isBeingDragged then
            self:StopMovingOrSizing()
            SaveChallengeFramePos()
            self.isBeingDragged = false
            ReattatchChallengeFrame()
        end
    end
)

-- Season 1 Background
local backgroundSeason1 = ChallengeFrame:CreateTexture(nil, "BACKGROUND")
backgroundSeason1:SetAllPoints(ChallengeFrame)
backgroundSeason1:SetTexture("Interface/AddOns/MDungeonTeleports/mists/default_frames_mists.blp")
backgroundSeason1:SetTexCoord(0, 0.123046, 0, 0.175781)
backgroundSeason1:SetVertexColor(1, 1, 1, 1)

-- Season 1 Title
local Season1Title = ChallengeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
Season1Title:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 12, flags)
Season1Title:SetPoint("TOP", ChallengeFrame, "TOP", 0, -8)
Season1Title:SetText("Mists of Pandaria")

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
            else
                cooldownFrame:SetText("")
                cooldownOverlay:Hide()
            end
        else
            cooldownFrame:SetText("")
            cooldownOverlay:Hide()
        end
    else
        cooldownFrame:SetText("")
        cooldownOverlay:Hide()
    end
end

-- MARK: Button Settings
local buttonSize = 32
local buttonSpacing = 5
local topRowSpacing = 5 -- spacing for the top row
local bottomRowSpacing = 5 -- spacing for the bottom row
local middleRowSpacing = 5

local spellButtons = {}

-- MARK: Update UI Function
function UpdateChallengeFrameUI()
    for _, btn in ipairs(spellButtons) do
        if btn.UpdateButtonTexture then
            btn.UpdateButtonTexture()
        end
    end
end

-- MARK: Button Creation
local function CreateSpellButton(parent, data, rowOffset, customSpacing)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(buttonSize, buttonSize)
    local spacing = customSpacing or buttonSpacing
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", (data.index - 1) * (buttonSize + spacing) + 10, rowOffset)

    button.data = data

    -- Texture for the button
    local buttonTexture = button:CreateTexture(nil, "ARTWORK")
    buttonTexture:SetAllPoints(button)
    buttonTexture:SetTexture(data.icon)

    -- Border texture
    local borderTexture = button:CreateTexture(nil, "OVERLAY")
    borderTexture:SetAllPoints(button)
    borderTexture:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_border.blp")
    borderTexture:SetDrawLayer("OVERLAY", 2)
    button.borderTexture = borderTexture

    -- Cooldown texture
    local cooldownOverlay = button:CreateTexture(nil, "OVERLAY")
    cooldownOverlay:SetAllPoints(button)
    cooldownOverlay:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    cooldownOverlay:SetVertexColor(0, 0, 0, 0.6)
    cooldownOverlay:Hide()
    button.cooldownOverlay = cooldownOverlay

    -- Button text
    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("TOP", button, "BOTTOM", 1, -2)
    local font, _, flags = buttonText:GetFont()
    buttonText:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 9, "OUTLINE")
    buttonText:SetTextColor(1, 1, 1)
    buttonText:SetText(data.name)
    button.buttonText = buttonText

    -- Cooldown text
    local cooldownText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownText:SetPoint("CENTER", button, "CENTER", 1, 0)
    cooldownText:SetTextColor(1, 1, 1)
    cooldownText:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 14, "OUTLINE")
    button.cooldownText = cooldownText

    -- Spell ID
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", data.spellID)

    -- Hover overlay
    local hoverOverlay = button:CreateTexture(nil, "HIGHLIGHT")
    hoverOverlay:SetAllPoints(button)
    hoverOverlay:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_highlight.blp")
    hoverOverlay:Hide()
    button.hoverOverlay = hoverOverlay

    table.insert(spellButtons, button)

    -- Button texture update function
    local function UpdateButtonTexture()
        local UIPack

        if MDungeonTeleports.CompactMode then
            UIPack = "Interface/Addons/MDungeonTeleports/media/ui/ui_default/"
        else
            UIPack = MDungeonTeleports.selectedUIPack or "Interface/Addons/MDungeonTeleports/media/ui/ui_default/"
        end

        if IsSpellKnown(data.spellID) then
            buttonTexture:SetTexture(data.icon)
        elseif MDungeonTeleports.AltLocks then
            if type(MistsAltLocks) == "table" then
                for _, lock in ipairs(MistsAltLocks) do
                    if lock.spellID == data.spellID then
                        buttonTexture:SetTexture(lock.icon)
                        buttonTexture:SetAlpha(0.6)
                        buttonTexture:SetDesaturated(true)
                        return
                    end
                end
            end
            buttonTexture:SetTexture(UIPack .. "lock.blp")
            buttonTexture:SetAlpha(1)
            buttonTexture:SetDesaturated(false)
        else
            buttonTexture:SetTexture(UIPack .. "lock.blp")
            buttonTexture:SetAlpha(1)
            buttonTexture:SetDesaturated(false)
        end
    end

    button.UpdateButtonTexture = UpdateButtonTexture

    UpdateButtonTexture()

    -- Event handler
    local function OnEvent(self, event)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELLS_CHANGED" then
            UpdateButtonTexture()
            UpdateCooldownText(self, data.spellID)
        end
    end

    -- Tooltips and hover
    button:SetScript(
        "OnEnter",
        function(self)
            if MDungeonTeleports.showTooltips then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(data.spellID)
                GameTooltip:Show()
            end
            hoverOverlay:Show()
        end
    )

    button:SetScript(
        "OnLeave",
        function(self)
            GameTooltip:Hide()
            hoverOverlay:Hide()
        end
    )

    -- Register events
    button:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    button:RegisterEvent("SPELLS_CHANGED")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetScript("OnEvent", OnEvent)

    return button
end

-- MARK: Button Rows Setup
local rowOffset = -30
local row2Offset = -79
local row3Offset = -128

for i, data in ipairs(MDT_MOP_1) do
    data.index = i
    data.row = 1
    CreateSpellButton(ChallengeFrame, data, rowOffset, topRowSpacing)
end

for i, data in ipairs(MDT_MOP_2) do
    data.index = i
    data.row = 2
    CreateSpellButton(ChallengeFrame, data, row2Offset, middleRowSpacing)
end

for i, data in ipairs(MDT_MOP_3) do
    data.index = i
    data.row = 3
    CreateSpellButton(ChallengeFrame, data, row3Offset, bottomRowSpacing)
end

-- MARK: Shift Drag Toggle
function ShiftDragToggleChallengeFrame()
    if MDungeonTeleports.ShiftDragToggle == true then
        ChallengeFrame:SetScript("OnDragStart", function(self)
            if IsShiftKeyDown() then
                self.isBeingDragged = true
                self:StartMoving()
            end
        end)
    else
        ChallengeFrame:SetScript("OnDragStart", function(self)
            self.isBeingDragged = true
            self:StartMoving()
        end)
    end
end

UpdateChallengeFrameUI()