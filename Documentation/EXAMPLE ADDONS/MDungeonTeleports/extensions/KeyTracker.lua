-- Start Up
local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0", true)

-- Save Function
local function SaveKeyTrackerPos()
    local DungeonFrame = PVEFrame
    if DungeonFrame then
        local frameScale = KeyTrackerFrame:GetEffectiveScale()
        local parentScale = DungeonFrame:GetEffectiveScale()

        local keyLeft = KeyTrackerFrame:GetLeft() * frameScale
        local keyTop = KeyTrackerFrame:GetTop() * frameScale
        local dungeonLeft = DungeonFrame:GetLeft() * parentScale
        local dungeonTop = DungeonFrame:GetTop() * parentScale

        local offsetX = (keyLeft - dungeonLeft) / parentScale
        local offsetY = (keyTop - dungeonTop) / parentScale
        local anchor = "TOPLEFT"

        MDungeonTeleports.KeyTrackerPos = {x = offsetX, y = offsetY, anchor = anchor}
    end
end

-- Load Function
local function LoadandReattachKeyTrackerPos()
    local DungeonFrame = PVEFrame
    if DungeonFrame and MDungeonTeleports.KeyTrackerPos then
        local pos = MDungeonTeleports.KeyTrackerPos

        local frameScale = KeyTrackerFrame:GetEffectiveScale()
        local parentScale = DungeonFrame:GetEffectiveScale()

        local adjustedX = pos.x * parentScale / frameScale
        local adjustedY = pos.y * parentScale / frameScale

        KeyTrackerFrame:ClearAllPoints()
        local anchor = "TOPLEFT"
        KeyTrackerFrame:SetPoint(anchor, DungeonFrame, anchor, adjustedX, adjustedY)
    end
end

local LocaleNoKey = L["NO_KEY"]

local function GetDungeonInfo(mapID)
    for _, dungeon in ipairs(KeyTrackerIcons) do
        if dungeon.mapID == mapID then
            return dungeon.icon, dungeon.short, dungeon.spellID
        end
    end
    return nil, LocaleNoKey, nil
end

-- MARK: Visibility Toggle
function MDTKeyFrame_UpdateVisibility(show)
    local KeyF = _G["KeyTrackerFrame"]
    if KeyF then
        KeyF:SetShown(show)
    end
end

-- MARK: Save Function on Close
local function OnPVEFrameClose()
    SaveKeyTrackerPos()
end

-- MARK: Login Start Up
local function OnPlayerLogin()
    LoadandReattachKeyTrackerPos()
    MDTShiftDragToggleKT()
    MDTUpdateFontKT()
    MDTUpdateKeyTrackerBorder()
    MDTUpdateKeyTrackerColors()
    MDTUpdateScoreNameKT()
    MDTKTSetWidth()
    MDTKTToggleDragHandle()
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        OnPlayerLogin()
    end
end)

local defaultFont = GameFontNormal:GetFont()


-- MARK: Key Tracker Main
local KeyTrackerFrame = CreateFrame("Frame", "KeyTrackerFrame", PVEFrame, "BackdropTemplate")
KeyTrackerFrame:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", 0, -1)
KeyTrackerFrame:SetSize(160, 34)
KeyTrackerFrame:EnableMouse(true)
KeyTrackerFrame:SetMovable(true)
KeyTrackerFrame:RegisterForDrag("LeftButton")
KeyTrackerFrame:SetClampedToScreen(true)
KeyTrackerFrame:Show()

KeyTrackerFrame.isBeingDragged = false

KeyTrackerFrame:SetScript("OnDragStart", function(self)
    self.isBeingDragged = true
    self:StartMoving()
end)

KeyTrackerFrame:SetScript("OnDragStop", function(self)
    if self.isBeingDragged then
        self:StopMovingOrSizing()
        SaveKeyTrackerPos()
        self.isBeingDragged = false
        LoadandReattachKeyTrackerPos()
    end
end)

-- Border thickness
local borderThickness = 2

-- KeyTracker Backdrop and Borders
local KeyTrackerFrameBackdrop = KeyTrackerFrame:CreateTexture(nil, "BACKGROUND")
KeyTrackerFrameBackdrop:SetAllPoints(KeyTrackerFrame)
KeyTrackerFrameBackdrop:SetColorTexture(
    MDungeonTeleports.backgroundColor.r,
    MDungeonTeleports.backgroundColor.g,
    MDungeonTeleports.backgroundColor.b,
    MDungeonTeleports.backgroundColor.a
)

local borderTop = KeyTrackerFrame:CreateTexture(nil, "OVERLAY")
borderTop:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderTop:SetPoint("TOPLEFT", KeyTrackerFrame, "TOPLEFT", borderThickness, 0)
borderTop:SetPoint("TOPRIGHT", KeyTrackerFrame, "TOPRIGHT", -borderThickness, 0)
borderTop:SetHeight(borderThickness)

local borderBottom = KeyTrackerFrame:CreateTexture(nil, "OVERLAY")
borderBottom:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderBottom:SetPoint("BOTTOMLEFT", KeyTrackerFrame, "BOTTOMLEFT", borderThickness, 0)
borderBottom:SetPoint("BOTTOMRIGHT", KeyTrackerFrame, "BOTTOMRIGHT", -borderThickness, 0)
borderBottom:SetHeight(borderThickness)

local borderLeft = KeyTrackerFrame:CreateTexture(nil, "OVERLAY")
borderLeft:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderLeft:SetPoint("TOPLEFT", KeyTrackerFrame, "TOPLEFT", 0, 0)
borderLeft:SetPoint("BOTTOMLEFT", KeyTrackerFrame, "BOTTOMLEFT", 0, 0)
borderLeft:SetWidth(borderThickness)

local borderRight = KeyTrackerFrame:CreateTexture(nil, "OVERLAY")
borderRight:SetColorTexture(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderRight:SetPoint("TOPRIGHT", KeyTrackerFrame, "TOPRIGHT", 0, 0)
borderRight:SetPoint("BOTTOMRIGHT", KeyTrackerFrame, "BOTTOMRIGHT", 0, 0)
borderRight:SetWidth(borderThickness)

-- Constants for sizing and spacing
local BUTTON_SIZE = 30
local ENTRY_PADDING_X = 3 -- padding from left/right
local ENTRY_PADDING_Y = 3 -- padding from top/bottom
local ENTRY_SPACING = 4   -- space between entries
local HEADER_HEIGHT = BUTTON_SIZE + (ENTRY_PADDING_Y * 2)
local ENTRY_HEIGHT = BUTTON_SIZE + ENTRY_SPACING

-- Border thickness for buttons
local buttonBorderThickness = 2

-- MARK: Main Button Creation
local function CreateKeystoneButton(parent)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:RegisterForClicks("AnyDown", "AnyUp")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)

    button.cooldownOverlay = button:CreateTexture(nil, "ARTWORK", nil, 1)
    button.cooldownOverlay:SetAllPoints(button)
    button.cooldownOverlay:SetColorTexture(0, 0, 0, 0.7)
    button.cooldownOverlay:Hide()

    button.highlight = button:CreateTexture(nil, "ARTWORK", nil, 2)
    button.highlight:SetAllPoints(button)
    button.highlight:SetColorTexture(0, 0, 0, 0.6)
    button.highlight:Hide()

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

    button.crownIcon = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.crownIcon:SetSize(10, 10)
    button.crownIcon:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.crownIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    button.crownIcon:Hide()

    button.keystoneLevel = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.keystoneLevel:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.keystoneLevel:SetFont(defaultFont, 14, "OUTLINE")

    button.dungeonName = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.dungeonName:SetPoint("LEFT", button, "RIGHT", 4, 6)
    button.dungeonName:SetFont(defaultFont, 11, "OUTLINE")
    button.dungeonName:SetJustifyH("LEFT")

    button.dungeonFullName = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.dungeonFullName:SetPoint("LEFT", button, "RIGHT", 4, 6)
    button.dungeonFullName:SetFont(defaultFont, 11, "OUTLINE")
    button.dungeonFullName:SetJustifyH("LEFT")

    button.playerName = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.playerName:SetPoint("TOPLEFT", button.dungeonName, "BOTTOMLEFT", 0, -1)
    button.playerName:SetFont(defaultFont, 9, "OUTLINE")
    button.playerName:SetJustifyH("LEFT")

    button.playerNameRealm = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.playerNameRealm:SetPoint("TOPLEFT", button.dungeonName, "BOTTOMLEFT", 0, -1)
    button.playerNameRealm:SetFont(defaultFont, 9, "OUTLINE")
    button.playerNameRealm:SetJustifyH("LEFT")
    button.playerNameRealm:Hide()

    button.playerScore = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.playerScore:SetPoint("LEFT", button, "RIGHT", (KeyTrackerFrame:GetWidth() - button:GetWidth() - 40), 0)
    button.playerScore:SetFont(defaultFont, 9, "OUTLINE")
    button.playerScore:SetJustifyH("RIGHT")

    button:SetScript("OnEnter", function(self)
        self.highlight:Show()
    end)

    button:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)

    return button
end

-- MARK: My Keystone
local MyCurrentKeystone = {}
MyCurrentKeystone.button = CreateKeystoneButton(KeyTrackerFrame)
MyCurrentKeystone.button:SetPoint("TOPLEFT", KeyTrackerFrame, "TOPLEFT", ENTRY_PADDING_X, -ENTRY_PADDING_Y)

local keystoneEntries = {}

local function CreateKeystoneEntry(index)
    local yOffset = -HEADER_HEIGHT - ((index - 1) * ENTRY_HEIGHT)
    local button = CreateKeystoneButton(KeyTrackerFrame)
    button:SetPoint("TOPLEFT", KeyTrackerFrame, "TOPLEFT", ENTRY_PADDING_X, yOffset)
    keystoneEntries[index] = button
end

-- MARK: Entries
for i = 1, 5 do
    CreateKeystoneEntry(i)
end

-- Add this near the top with other constants
local ROLE_ICONS = {
    dps = {
        full = "|TInterface\\AddOns\\MDungeonTeleports\\media\\ui\\dps_full:14:14:0:0:16:16:0:16:0:16|t",
        partial = "|TInterface\\AddOns\\MDungeonTeleports\\media\\ui\\dps_partial:14:14:0:0:16:16:0:16:0:16|t"
    },
    healer = {
        full = "|TInterface\\AddOns\\MDungeonTeleports\\media\\ui\\heal_full:14:14:0:0:16:16:0:16:0:16|t", 
        partial = "|TInterface\\AddOns\\MDungeonTeleports\\media\\ui\\heal_partial:14:14:0:0:16:16:0:16:0:16|t"
    },
    tank = {
        full = "|TInterface\\AddOns\\MDungeonTeleports\\media\\ui\\tank_full:14:14:0:0:16:16:0:16:0:16|t",
        partial = "|TInterface\\AddOns\\MDungeonTeleports\\media\\ui\\tank_partial:14:14:0:0:16:16:0:16:0:16|t"
    }
}

-- Get Score and Colour with fallback
local function GetPlayerMythicPlusScoreAndColor(unit)
    local score, color, roleIcons = 0, { r = 1, g = 1, b = 1 }, ""

    if RaiderIO and RaiderIO.GetProfile then
        local profile = RaiderIO.GetProfile(unit)
        if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.currentScore then
            score = math.floor(profile.mythicKeystoneProfile.currentScore)

            -- Get role icons from RaiderIO profile
            if profile.mythicKeystoneProfile.mplusCurrent and profile.mythicKeystoneProfile.mplusCurrent.roles then
                local icons = {}
                for i = 1, #profile.mythicKeystoneProfile.mplusCurrent.roles do
                    local role = profile.mythicKeystoneProfile.mplusCurrent.roles[i]
                    local roleName, roleType = role[1], role[2]  -- e.g., "tank", "full"
                    if ROLE_ICONS[roleName] and ROLE_ICONS[roleName][roleType] then
                        icons[i] = ROLE_ICONS[roleName][roleType]
                    end
                end
                roleIcons = table.concat(icons, "")
            end

            if RaiderIO.GetScoreColor then
                local r, g, b = RaiderIO.GetScoreColor(score)
                color = { r = r, g = g, b = b }
            end
            return score, color, roleIcons
        end
    end

    local ratingInfo = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
    if ratingInfo and ratingInfo.currentSeasonScore and ratingInfo.currentSeasonScore > 0 then
        score = math.floor(ratingInfo.currentSeasonScore)

        if C_ChallengeMode.GetDungeonScoreRarityColor then
            local rarityColor = C_ChallengeMode.GetDungeonScoreRarityColor(score)
            if rarityColor then
                color = { r = rarityColor.r, g = rarityColor.g, b = rarityColor.b }
            end
        end
    end
    return score, color, roleIcons
end

-- Update the SetButtonPlayerScore function to include role icons
local function SetButtonPlayerScore(button, unit)
    local score, color, roleIcons = GetPlayerMythicPlusScoreAndColor(unit)
    if score > 0 then
        local scoreText = ('|cff%02x%02x%02x%d|r'):format(color.r*255, color.g*255, color.b*255, score)
        -- Combine role icons with score
        local displayText = roleIcons ~= "" and (roleIcons .. "" .. scoreText) or scoreText
        button.playerScore:SetText(displayText)
    else
        button.playerScore:SetText("")
    end
end

-- MARK: Cooldown Update Function
local function UpdateButtonCooldown(button)
    if InCombatLockdown() then return end
    if button.spellID then
        local cooldownInfo = C_Spell.GetSpellCooldown(button.spellID)
        local isOnCooldown = false
        
        if cooldownInfo then
            local start = cooldownInfo.startTime
            local duration = cooldownInfo.duration
            local isEnabled = cooldownInfo.isEnabled
            if start > 0 and duration > 5 and isEnabled then
                isOnCooldown = true
            end
        end
        
        if isOnCooldown then
            button.cooldownOverlay:Show()
        else
            button.cooldownOverlay:Hide()
        end
    else
        button.cooldownOverlay:Hide()
    end
end

-- Function to update all button cooldowns
local function UpdateAllCooldowns()
    UpdateButtonCooldown(MyCurrentKeystone.button)
    for _, btn in ipairs(keystoneEntries) do
        UpdateButtonCooldown(btn)
    end
end

-- Update My Keystone
local function UpdateMyKeystone()
    if InCombatLockdown() then return end
    local myKeystoneInfo = openRaidLib.GetKeystoneInfo("player")
    local btn = MyCurrentKeystone.button
    local _, class = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or "FFFFFFFF"
    local playerName = UnitName("player")
    local playerNameRealm = playerName .. "-" .. (GetNormalizedRealmName() or "")
    
    local isLeader = UnitIsGroupLeader("player")
    if isLeader and not IsInRaid() then
        btn.crownIcon:Show()
    else
        btn.crownIcon:Hide()
    end

    if myKeystoneInfo then
        local dungeonName = C_ChallengeMode.GetMapUIInfo(myKeystoneInfo.challengeMapID) or LocaleNoKey
        local dungeonIconID, dungeonShortName, spellID = GetDungeonInfo(myKeystoneInfo.challengeMapID)
        local keystoneLevelFull = myKeystoneInfo.level > 0 and "+" .. myKeystoneInfo.level or ""

        btn.icon:SetTexture(dungeonIconID or "Interface\\Icons\\misc_rnrredxbutton")
        btn.keystoneLevel:SetText(keystoneLevelFull)
        btn.dungeonName:SetText(dungeonShortName)
        btn.dungeonFullName:SetText(dungeonName)
        btn.dungeonFullName:Hide() -- Hide by default
        btn.playerName:SetText("|c" .. classColor .. playerName .. "|r")
        btn.playerNameRealm:SetText("|c" .. classColor .. playerNameRealm .. "|r")
        SetButtonPlayerScore(btn, "player")

        if spellID then
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("spell", spellID)
            btn.spellID = spellID
        else
            btn:SetAttribute("type", nil)
            btn:SetAttribute("spell", nil)
            btn.spellID = nil
        end
        btn:Show()
        UpdateButtonCooldown(btn)
    else
        btn.icon:SetTexture("Interface\\Icons\\misc_rnrredxbutton")
        btn.keystoneLevel:SetText("")
        btn.dungeonName:SetText(LocaleNoKey)
        btn.dungeonFullName:SetText("")
        btn.dungeonFullName:Hide()
        btn.playerName:SetText("|c" .. classColor .. playerName .. "|r")
        btn.playerNameRealm:SetText("|c" .. classColor .. playerNameRealm .. "|r")
        btn.playerScore:SetText("")
        btn:SetAttribute("type", nil)
        btn:SetAttribute("spell", nil)
        btn.spellID = nil
        btn:Show()
        UpdateButtonCooldown(btn)
    end
end

-- Update Party Keystones
local function UpdatePartyKeystones()
    if InCombatLockdown() then return end
    if IsInRaid() then
        for i = 1, #keystoneEntries do
            local btn = keystoneEntries[i]
            btn:Hide()
        end

        KeyTrackerFrame:SetHeight(HEADER_HEIGHT)
        return
    end

    local allKeystoneInfo = openRaidLib.GetAllKeystonesInfo()
    local index = 1

    -- Populate new data
    for i = 1, GetNumGroupMembers() - 1 do
        local unitId = "party" .. i
        local unitName, realm = UnitName(unitId)
        local btn = keystoneEntries[index]
        if unitName and btn then
            if realm and realm ~= "" then
                unitName = unitName .. "-" .. realm
            end
            local playerNameWithoutRealm = unitName:match("([^%-]+)") or unitName
            local keystoneInfo = allKeystoneInfo[unitName]
            local _, class = UnitClass(unitId)
            local classColor = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or "FFFFFFFF"
            
            local isLeader = UnitIsGroupLeader(unitId)
            if isLeader and not IsInRaid() then
                btn.crownIcon:Show()
            else
                btn.crownIcon:Hide()
            end

            if keystoneInfo then
                local dungeonName = C_ChallengeMode.GetMapUIInfo(keystoneInfo.challengeMapID) or LocaleNoKey
                local dungeonIconID, dungeonShortName, spellID = GetDungeonInfo(keystoneInfo.challengeMapID)
                local keystoneLevelFullParty = keystoneInfo.level > 0 and "+" .. keystoneInfo.level or ""

                btn.icon:SetTexture(dungeonIconID or "Interface\\Icons\\misc_rnrredxbutton")
                btn.keystoneLevel:SetText(keystoneLevelFullParty)
                btn.dungeonName:SetText(dungeonShortName)
                btn.dungeonFullName:SetText(dungeonName)
                btn.dungeonFullName:Hide() -- Hide by default
                btn.playerName:SetText("|c" .. classColor .. playerNameWithoutRealm .. "|r")
                btn.playerNameRealm:SetText("|c" .. classColor .. playerNameWithoutRealm .. "-" .. (realm or GetNormalizedRealmName()) .. "|r")
                SetButtonPlayerScore(btn, unitId)

                if spellID then
                    btn:SetAttribute("type", "spell")
                    btn:SetAttribute("spell", spellID)
                    btn.spellID = spellID
                else
                    btn:SetAttribute("type", nil)
                    btn:SetAttribute("spell", nil)
                    btn.spellID = nil
                end
            else
                btn.icon:SetTexture("Interface\\Icons\\misc_rnrredxbutton")
                btn.keystoneLevel:SetText("")
                btn.dungeonName:SetText(LocaleNoKey)
                btn.dungeonFullName:SetText("")
                btn.dungeonFullName:Hide()
                btn.playerName:SetText("|c" .. classColor .. playerNameWithoutRealm .. "|r")
                btn.playerNameRealm:SetText("|c" .. classColor .. playerNameWithoutRealm .. "-" .. (realm or GetNormalizedRealmName()) .. "|r")
                btn.playerScore:SetText("")
                btn:SetAttribute("type", nil)
                btn:SetAttribute("spell", nil)
                btn.spellID = nil
            end

            btn:Show()
            UpdateButtonCooldown(btn)
            index = index + 1
        else
            if btn then
                btn.icon:SetTexture(nil)
                btn.keystoneLevel:SetText("")
                btn.dungeonName:SetText("")
                btn.dungeonFullName:SetText("")
                btn.dungeonFullName:Hide()
                btn.playerName:SetText("")
                btn.playerNameRealm:SetText("")
                btn.playerScore:SetText("")
                btn.crownIcon:Hide()
                btn:SetAttribute("type", nil)
                btn:SetAttribute("spell", nil)
                btn.spellID = nil
                btn:Hide()
                UpdateButtonCooldown(btn)
            end
            index = index + 1
        end
    end

    for i = index, #keystoneEntries do
        local btn = keystoneEntries[i]
        btn.icon:SetTexture(nil)
        btn.keystoneLevel:SetText("")
        btn.dungeonName:SetText("")
        btn.dungeonFullName:SetText("")
        btn.dungeonFullName:Hide()
        btn.playerName:SetText("")
        btn.playerNameRealm:SetText("")
        btn.playerScore:SetText("")
        btn.crownIcon:Hide()
        btn:SetAttribute("type", nil)
        btn:SetAttribute("spell", nil)
        btn.spellID = nil
        btn:Hide()
        UpdateButtonCooldown(btn)
    end

    -- Frame Resizing
    local totalKeys = index - 1
    local minHeight = HEADER_HEIGHT
    KeyTrackerFrame:SetHeight(minHeight + (totalKeys * ENTRY_HEIGHT))
end

-- MARK: Request Functions
local function RequestPartyKeystones()
    openRaidLib.RequestKeystoneDataFromParty()
    if not RequestKeystoneTimer then
        RequestKeystoneTimer = C_Timer.NewTimer(2, function()
            UpdatePartyKeystones()
            RequestKeystoneTimer = nil
        end)
    end
end

local function RequestPersonalKeystone()
    openRaidLib.RequestKeystoneDataFromParty()
    if not RequestMyKeystoneTimer then
        RequestMyKeystoneTimer = C_Timer.NewTimer(2, function()
            UpdateMyKeystone()
            RequestMyKeystoneTimer = nil
        end)
    end
end

-- MARK: Sync Keys Addon Send/Receive
local addonPrefix = "MDT_PEEPO"
C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix)

local storedMapID = nil
local storedLevel = nil

local function StoreCurrentKeystone()
    storedMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    storedLevel = C_MythicPlus.GetOwnedKeystoneLevel()
end

local function SyncKeys()
    local currentMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local currentLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    
    if currentMapID and currentLevel then
        if currentMapID ~= storedMapID or currentLevel ~= storedLevel then
            C_ChatInfo.SendAddonMessage(addonPrefix, "SyncKeys", "PARTY")
            storedMapID = currentMapID
            storedLevel = currentLevel
        end
    end
end

local addonMessageFrame = CreateFrame("Frame")
addonMessageFrame:RegisterEvent("CHAT_MSG_ADDON")
addonMessageFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix == addonPrefix and message == "SyncKeys" then
        RequestPartyKeystones()
        RequestPersonalKeystone()
    end
end)

-- MARK: Keystone Update Events
local eventFrame = CreateFrame("Frame")
local previousGroupSize = GetNumGroupMembers()

eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("GOSSIP_CLOSED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(5, function()
            if not InCombatLockdown() then
                local currentGroupSize = GetNumGroupMembers()
                if currentGroupSize ~= previousGroupSize then
                    RequestPartyKeystones()
                    previousGroupSize = currentGroupSize
                end
            end
        end)
    elseif event == "GROUP_LEFT" or event == "GROUP_JOINED" then
        C_Timer.After(1, function()
            if not InCombatLockdown() then
                RequestPersonalKeystone()
                RequestPartyKeystones()
            end
        end)
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        C_Timer.After(3, function()
            RequestPartyKeystones()
            RequestPersonalKeystone()
            UpdateAllCooldowns()
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function()
            if not InCombatLockdown() then
                RequestPersonalKeystone()
                StoreCurrentKeystone()
                UpdateAllCooldowns()
            end
        end)
    elseif event == "GOSSIP_CLOSED" then
        C_Timer.After(3, function()
            RequestPersonalKeystone()
            SyncKeys()
        end)
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        UpdateAllCooldowns()
    end
end)

if openRaidLib then
    openRaidLib.RegisterCallback(NS, "KeystoneUpdate", "OnKeystoneUpdate")
    function NS:OnKeystoneUpdate(unit, keystoneInfo, allKeystones)
        C_Timer.After(2, function()
            RequestPersonalKeystone()
            RequestPartyKeystones()
        end)
    end
end

if PVEFrame then
    PVEFrame:HookScript("OnShow", function()
        C_Timer.After(1, function()
            if not InCombatLockdown() then
                RequestPersonalKeystone()
                RequestPartyKeystones()
            end
        end)
    end)
end

RequestPersonalKeystone()
RequestPartyKeystones()
StoreCurrentKeystone()

KeyTrackerFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        C_Timer.After(2, function()
            RequestPersonalKeystone()
            RequestPartyKeystones()
            print(L['KEYS_REFRESHED'])
        end)
    end
end)

-- MARK: Look for Keystone in Bags
local function FindKeystone()
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID == 180653 then
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemInfo and itemInfo.hyperlink then
                    return itemInfo.hyperlink
                end
            end
        end
    end
    return nil
end

-- MARK: Respond to Keys
local function OnEvent(self, event, text, sender, ...)
    if MDungeonTeleports.isRespondChecked then
        if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
            if text:lower() == "!keys" then
                local keystoneItemLink = FindKeystone()
                local message = "[M+DT]: " .. (keystoneItemLink or LocaleNoKey)
                SendChatMessage(message, "PARTY")
            end
        end
    end
end

local chatResponseFrame = CreateFrame("Frame")
chatResponseFrame:RegisterEvent("CHAT_MSG_PARTY")
chatResponseFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
chatResponseFrame:SetScript("OnEvent", OnEvent)

-- MARK: Shift Drag Toggle
function MDTShiftDragToggleKT()
    if MDungeonTeleports.ShiftDragToggle == true then
        KeyTrackerFrame:SetScript("OnDragStart", function(self)
            if IsShiftKeyDown() then
                self.isBeingDragged = true
                self:StartMoving()
            end
        end)
    else
        KeyTrackerFrame:SetScript("OnDragStart", function(self)
            self.isBeingDragged = true
            self:StartMoving()
        end)
    end
end

-- MARK: Backdrop and Border Colour Update for KeyTracker
function MDTUpdateKeyTrackerColors()
    local bc = MDungeonTeleports.borderColor
    local bg = MDungeonTeleports.backgroundColor
    local bbc = MDungeonTeleports.buttonBorderColor or { r = 0.05, g = 0.05, b = 0.05, a = 0.8 }

    if KeyTrackerFrameBackdrop then
        KeyTrackerFrameBackdrop:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
    end

    if borderTop then borderTop:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end
    if borderBottom then borderBottom:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end
    if borderLeft then borderLeft:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end
    if borderRight then borderRight:SetColorTexture(bc.r, bc.g, bc.b, bc.a) end

    -- Update button borders
    local allButtons = {MyCurrentKeystone.button}
    for _, btn in ipairs(keystoneEntries) do table.insert(allButtons, btn) end
    for _, button in ipairs(allButtons) do
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

-- MARK: Border Thickness Update for KeyTracker
function MDTUpdateKeyTrackerBorder()
    local borderThickness = MDungeonTeleports.borderThickness

    if borderThickness == 0 then 
        borderTop:Hide() borderBottom:Hide() borderLeft:Hide() borderRight:Hide()
    else 
        borderTop:Show() borderBottom:Show() borderLeft:Show() borderRight:Show() 
    end

    borderTop:SetHeight(borderThickness)
    borderTop:ClearAllPoints()
    borderTop:SetPoint("TOPLEFT", KeyTrackerFrame, "TOPLEFT", borderThickness, 0)
    borderTop:SetPoint("TOPRIGHT", KeyTrackerFrame, "TOPRIGHT", -borderThickness, 0)

    borderBottom:SetHeight(borderThickness)
    borderBottom:ClearAllPoints()
    borderBottom:SetPoint("BOTTOMLEFT", KeyTrackerFrame, "BOTTOMLEFT", borderThickness, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", KeyTrackerFrame, "BOTTOMRIGHT", -borderThickness, 0)

    borderLeft:SetWidth(borderThickness)
    borderLeft:ClearAllPoints()
    borderLeft:SetPoint("TOPLEFT", KeyTrackerFrame, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", KeyTrackerFrame, "BOTTOMLEFT", 0, 0)

    borderRight:SetWidth(borderThickness)
    borderRight:ClearAllPoints()
    borderRight:SetPoint("TOPRIGHT", KeyTrackerFrame, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", KeyTrackerFrame, "BOTTOMRIGHT", 0, 0)
end

-- MARK: Font Update for KeyTracker
function MDTUpdateFontKT()
    local customFont = MDungeonTeleports.customFont
    local tx3 = MDungeonTeleports.buttonTextColor

    local allButtons = {MyCurrentKeystone.button}
    for _, btn in ipairs(keystoneEntries) do table.insert(allButtons, btn) end

    for _, button in ipairs(allButtons) do
        if button.keystoneLevel then
            button.keystoneLevel:SetFont(customFont, 14, "OUTLINE")
        end
        if button.dungeonName then
            button.dungeonName:SetFont(customFont, 11, "OUTLINE")
            button.dungeonName:SetTextColor(tx3.r, tx3.g, tx3.b)
        end
        if button.dungeonFullName then
            button.dungeonFullName:SetFont(customFont, 11, "OUTLINE")
            button.dungeonFullName:SetTextColor(tx3.r, tx3.g, tx3.b)
        end
        if button.playerName then
            button.playerName:SetFont(customFont, 9, "OUTLINE")
        end
        if button.playerScore then
            button.playerScore:SetFont(customFont, 9, "OUTLINE")
        end
    end
end

-- MARK: Show/Hide Score and Realm Name for KeyTracker
function MDTUpdateScoreNameKT()
    local allButtons = {MyCurrentKeystone.button}
    for _, btn in ipairs(keystoneEntries) do table.insert(allButtons, btn) end

    for _, button in ipairs(allButtons) do
        if MDungeonTeleports.rioScore == false then
            button.playerScore:Hide()
        else
            button.playerScore:Show()
        end

        if MDungeonTeleports.realmName == true then
            button.playerName:Hide()
            button.playerNameRealm:Show()
        else
            button.playerName:Show()
            button.playerNameRealm:Hide()
        end
    end
end

-- MARK: Update Player Score Positions based on Width
local function UpdatePlayerScorePositions()
    local rightPadding = 10
    local allButtons = {MyCurrentKeystone.button}
    for _, btn in ipairs(keystoneEntries) do
        table.insert(allButtons, btn)
    end
    for _, button in ipairs(allButtons) do
        button.playerScore:ClearAllPoints()
        button.playerScore:SetPoint("RIGHT", button, "RIGHT", (KeyTrackerFrame:GetWidth() - button:GetWidth() - rightPadding), 0)
    end
end

-- MARK: Drag Handle for Resizing Width
local dragHandle = CreateFrame("Frame", nil, KeyTrackerFrame)
dragHandle:SetSize(12, 34)
dragHandle:SetPoint("LEFT", KeyTrackerFrame, "RIGHT", 1, 0)
dragHandle:EnableMouse(true)
dragHandle:SetFrameStrata("TOOLTIP")

dragHandle.texture = dragHandle:CreateTexture(nil, "OVERLAY")
dragHandle.texture:SetAllPoints()
dragHandle.texture:SetColorTexture(1, 1, 1, 0.6)
dragHandle.texture:Hide()

dragHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self.isResizing = true
        self.startX = GetCursorPosition()
        self.startWidth = KeyTrackerFrame:GetWidth()
        self:SetScript("OnUpdate", function()
            local currentX = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            local delta = (currentX - self.startX) / scale
            local minWidth = 140
            local maxWidth = 240
            local newWidth = math.max(minWidth, math.min(self.startWidth + delta, maxWidth))
            KeyTrackerFrame:SetWidth(newWidth)
            MDungeonTeleports.KeyTrackerWidth = newWidth
            UpdatePlayerScorePositions()
        end)
    end
end)

dragHandle:SetScript("OnEnter", function(self)
    self.texture:Show()
end)

dragHandle:SetScript("OnLeave", function(self)
    self.texture:Hide()
end)

dragHandle:SetScript("OnMouseUp", function(self, button)
    if self.isResizing then
        self.isResizing = false
        self:SetScript("OnUpdate", nil)
        SaveKeyTrackerPos()
    end
end)

-- MARK: Set Width and Score Positions on Updates
function MDTKTSetWidth()
    local ktwidth = MDungeonTeleports.KeyTrackerWidth or 160
    KeyTrackerFrame:SetWidth(ktwidth)
    UpdatePlayerScorePositions() 
end

-- MARK: Toggle Drag Handle Visibility
function MDTKTToggleDragHandle()
    if MDungeonTeleports.dragHandle then
        dragHandle:Show()
    else
        dragHandle:Hide() 
    end
end