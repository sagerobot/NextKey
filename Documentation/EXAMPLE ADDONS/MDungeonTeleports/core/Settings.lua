local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local ldb = LibStub("LibDataBroker-1.1", true)
local icon = LibStub("LibDBIcon-1.0", true)
-------------------------------------------------
local addonName = "MDungeonTeleports"
local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Unknown"
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
-------------------------------------------------
-- Font RegisterEvent
LSM:Register("font", "Expressway", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\expressway.ttf")
LSM:Register("font", "Sarasa", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\sarasa.ttf")
LSM:Register("font", "Wanted", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\wanted.ttf")
LSM:Register("font", "Lato", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\lato.ttf")
LSM:Register("font", "Montserrat", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\montserrat.ttf")
LSM:Register("font", "Avalon", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\avalon.ttf")
LSM:Register("font", "Geo Sans Light", "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\geosans.ttf")
-------------------------------------------------
-- MARK: Set Defaults
local defaultSettings = {
    Season1Pos = {x = 570, y = 280},
    Season2Pos = {x = 570, y = 144},
    Season3Pos = {x = 570, y = 6},
    PortalLibraryPos = {x = 960, y = -99},
    PortalLibraryRaidPos = {x = 1092, y = 198},
    KeyTrackerPos = {x = 971, y = -429},
    showTooltips = false,
    CompactMode = false,
    ShiftDragToggle = false,
    isRespondChecked = true,
    isSeason1PortalsShown = true,
    isSeason2PortalsShown = true,
    isSeason3PortalsShown = true,
    isPortalLibraryShown = true,
    isPortalLibraryRaidShown = true,
    isKeyFrameShown = true,
    loginMessage = true,
    frameScale = 1,
    KeyTrackerFrameScale = 1,
    borderColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.8 },
    backgroundColor = { r = 0, g = 0, b = 0, a = 0.6 },
    expansionColor = { r = 0, g = 1, b = 0.6 },
    titleColor = { r = 1, g = 1, b = 1 },
    buttonTextColor = { r = 1, g = 1, b = 1 },
    borderThickness = 2,
    customFontName = nil,
    customFont = nil,
    settingsScale = 1,
    announcePort = false,
    LockIcons = false,
    DarkenText = false,
    rioScore = true,
    realmName = false,
    dragHandle = true,
    selectedPreset = 1,
    buttonBorderColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.8 },
    KeyTrackerWidth = 160,
    lastVersionCheck = nil,
    WhisperResonse = true,
}

if MDungeonTeleports == nil then MDungeonTeleports = {} end

MDungeonTeleports.Season1Pos = MDungeonTeleports.Season1Pos or defaultSettings.Season1Pos
MDungeonTeleports.Season2Pos = MDungeonTeleports.Season2Pos or defaultSettings.Season2Pos
MDungeonTeleports.Season3Pos = MDungeonTeleports.Season3Pos or defaultSettings.Season3Pos
MDungeonTeleports.PortalLibraryPos = MDungeonTeleports.PortalLibraryPos or defaultSettings.PortalLibraryPos
MDungeonTeleports.PortalLibraryRaidPos = MDungeonTeleports.PortalLibraryRaidPos or defaultSettings.PortalLibraryRaidPos
MDungeonTeleports.KeyTrackerPos = MDungeonTeleports.KeyTrackerPos or defaultSettings.KeyTrackerPos
MDungeonTeleports.showTooltips = MDungeonTeleports.showTooltips or defaultSettings.showTooltips
MDungeonTeleports.CompactMode = MDungeonTeleports.CompactMode or defaultSettings.CompactMode
MDungeonTeleports.ShiftDragToggle = MDungeonTeleports.ShiftDragToggle or defaultSettings.ShiftDragToggle
MDungeonTeleports.isRespondChecked = MDungeonTeleports.isRespondChecked or defaultSettings.isRespondChecked
MDungeonTeleports.isSeason1PortalsShown = MDungeonTeleports.isSeason1PortalsShown or defaultSettings.isSeason1PortalsShown
MDungeonTeleports.isSeason2PortalsShown = MDungeonTeleports.isSeason2PortalsShown or defaultSettings.isSeason2PortalsShown
MDungeonTeleports.isSeason3PortalsShown = MDungeonTeleports.isSeason3PortalsShown or defaultSettings.isSeason3PortalsShown
MDungeonTeleports.isPortalLibraryShown = MDungeonTeleports.isPortalLibraryShown or defaultSettings.isPortalLibraryShown
MDungeonTeleports.isPortalLibraryRaidShown = MDungeonTeleports.isPortalLibraryRaidShown or defaultSettings.isPortalLibraryRaidShown
MDungeonTeleports.isKeyFrameShown = MDungeonTeleports.isKeyFrameShown or defaultSettings.isKeyFrameShown
MDungeonTeleports.loginMessage = MDungeonTeleports.loginMessage or defaultSettings.loginMessage
MDungeonTeleports.frameScale = MDungeonTeleports.frameScale or defaultSettings.frameScale
MDungeonTeleports.KeyTrackerFrameScale = MDungeonTeleports.KeyTrackerFrameScale or defaultSettings.KeyTrackerFrameScale
MDungeonTeleports.borderColor = MDungeonTeleports.borderColor or defaultSettings.borderColor
MDungeonTeleports.backgroundColor = MDungeonTeleports.backgroundColor or defaultSettings.backgroundColor
MDungeonTeleports.expansionColor = MDungeonTeleports.expansionColor or defaultSettings.expansionColor
MDungeonTeleports.titleColor = MDungeonTeleports.titleColor or defaultSettings.titleColor
MDungeonTeleports.buttonTextColor = MDungeonTeleports.buttonTextColor or defaultSettings.buttonTextColor
MDungeonTeleports.borderThickness = MDungeonTeleports.borderThickness or defaultSettings.borderThickness
MDungeonTeleports.customFontName = MDungeonTeleports.customFontName or defaultSettings.customFontName
MDungeonTeleports.customFont = MDungeonTeleports.customFont or defaultSettings.customFont
MDungeonTeleports.settingsScale = MDungeonTeleports.settingsScale or defaultSettings.settingsScale
MDungeonTeleports.announcePort = MDungeonTeleports.announcePort or defaultSettings.announcePort
MDungeonTeleports.LockIcons = MDungeonTeleports.LockIcons or defaultSettings.LockIcons
MDungeonTeleports.DarkenText = MDungeonTeleports.DarkenText or defaultSettings.DarkenText
MDungeonTeleports.rioScore = MDungeonTeleports.rioScore or defaultSettings.rioScore
MDungeonTeleports.realmName = MDungeonTeleports.realmName or defaultSettings.realmName
MDungeonTeleports.dragHandle = MDungeonTeleports.dragHandle or defaultSettings.dragHandle
MDungeonTeleports.selectedPreset = MDungeonTeleports.selectedPreset or defaultSettings.selectedPreset
MDungeonTeleports.buttonBorderColor = MDungeonTeleports.buttonBorderColor or defaultSettings.buttonBorderColor
MDungeonTeleports.KeyTrackerWidth = MDungeonTeleports.KeyTrackerWidth or defaultSettings.KeyTrackerWidth
MDungeonTeleports.lastVersionCheck = MDungeonTeleports.lastVersionCheck or defaultSettings.lastVersionCheck

if MDungeonTeleports.customFont == nil or MDungeonTeleports.customFontName == nil then
    local locale = GetLocale and GetLocale() or "enUS"
    if locale == "zhCN" then
        MDungeonTeleports.customFont = "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\sarasa.ttf"
        MDungeonTeleports.customFontName = "Sarasa"
    elseif locale == "koKR" then
        MDungeonTeleports.customFont = "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\wanted.ttf"
        MDungeonTeleports.customFontName = "Wanted"
    else
        MDungeonTeleports.customFont = "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\expressway.ttf"
        MDungeonTeleports.customFontName = "Expressway"
    end
end
-------------------------------------------------
-- MARK: Settings Frame
local Settings = CreateFrame("Frame", "Settings", UIParent)
Settings:SetSize(500, 450)
Settings:SetPoint("CENTER")
Settings:SetMovable(true)
Settings:EnableMouse(true)
Settings:RegisterForDrag("LeftButton")
Settings:SetScript("OnDragStart", Settings.StartMoving)
Settings:SetScript("OnDragStop", Settings.StopMovingOrSizing)
Settings:Hide()
Settings:SetFrameStrata("DIALOG")
Settings:EnableKeyboard(true)
Settings:SetClampedToScreen(true)
Settings:SetScript(
    "OnKeyDown",
    function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end
)
-------------------------------------------------
-- Settings Background
local SettingsBackdrop = Settings:CreateTexture(nil, "BACKGROUND")
SettingsBackdrop:SetAllPoints(Settings)
SettingsBackdrop:SetColorTexture(0, 0, 0, 0.75)

local borderColor = {0, 0, 0, 0.6}
local borderThickness = 3

local borderTop = Settings:CreateTexture(nil, "OVERLAY")
borderTop:SetColorTexture(unpack(borderColor))
borderTop:SetPoint("TOPLEFT", Settings, "TOPLEFT", 0, 0)
borderTop:SetPoint("TOPRIGHT", Settings, "TOPRIGHT", 0, 0)
borderTop:SetHeight(borderThickness)

local borderBottom = Settings:CreateTexture(nil, "OVERLAY")
borderBottom:SetColorTexture(unpack(borderColor))
borderBottom:SetPoint("BOTTOMLEFT", Settings, "BOTTOMLEFT", 0, 0)
borderBottom:SetPoint("BOTTOMRIGHT", Settings, "BOTTOMRIGHT", 0, 0)
borderBottom:SetHeight(borderThickness)

local borderLeft = Settings:CreateTexture(nil, "OVERLAY")
borderLeft:SetColorTexture(unpack(borderColor))
borderLeft:SetPoint("TOPLEFT", Settings, "TOPLEFT", 0, 0)
borderLeft:SetPoint("BOTTOMLEFT", Settings, "BOTTOMLEFT", 0, 0)
borderLeft:SetWidth(borderThickness)

local borderRight = Settings:CreateTexture(nil, "OVERLAY")
borderRight:SetColorTexture(unpack(borderColor))
borderRight:SetPoint("TOPRIGHT", Settings, "TOPRIGHT", 0, 0)
borderRight:SetPoint("BOTTOMRIGHT", Settings, "BOTTOMRIGHT", 0, 0)
borderRight:SetWidth(borderThickness)
-------------------------------------------------
-- MARK: Visibility Toggles
local function Season1Vis(show)
    if MDTSeason1_UpdateVisibility then MDTSeason1_UpdateVisibility(show) end
end
local function Season2Vis(show)
    if MDTSeason2_UpdateVisibility then MDTSeason2_UpdateVisibility(show) end
end
local function Season3Vis(show)
    if MDTSeason3_UpdateVisibility then MDTSeason3_UpdateVisibility(show) end
end
local function DungeonVis(show)
    if MDTPortalLibrary_UpdateVisibility then MDTPortalLibrary_UpdateVisibility(show) end
end
local function RaidVis(show)
    if MDTPortalLibraryRaid_UpdateVisibility then MDTPortalLibraryRaid_UpdateVisibility(show) end
end
local function KeyTVis(show)
    if MDTKeyFrame_UpdateVisibility then MDTKeyFrame_UpdateVisibility(show) end
end
-------------------------------------------------
-- MARK: Frames Scale Update
function UpdateFrameScale(scale)
    scale = scale or 1
    if Season1 then Season1:SetScale(scale) end
    if Season2 then Season2:SetScale(scale) end
    if Season3 then Season3:SetScale(scale) end
    if PortalLibrary then PortalLibrary:SetScale(scale) end
    if PortalLibraryRaid then PortalLibraryRaid:SetScale(scale) end
    MDungeonTeleports.frameScale = scale
end
-------------------------------------------------
-- MARK: Key Tracker Frame Scale
function UpdateKeyTrackerFrameScale(keyscalescale)
    keyscalescale = keyscalescale or 1
    if KeyTrackerFrame then KeyTrackerFrame:SetScale(keyscalescale) end
    MDungeonTeleports.KeyTrackerFrameScale = keyscalescale
end
-------------------------------------------------
-- MARK: Settings Frame Scale
local function UpdateSettingsFrameScale(scalesettings)
    if Settings then Settings:SetScale(scalesettings) end
    MDungeonTeleports.settingsScale = scalesettings
end
-------------------------------------------------
-- MARK: Titles
local defaultFont = GameFontNormal:GetFont()

local SettingsTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SettingsTitle:SetPoint("TOP", Settings, "TOP", 0, -7)
SettingsTitle:SetFont(defaultFont, 12, flags)
SettingsTitle:SetText(L["SETTINGS"])

local SeasonTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SeasonTitle:SetPoint("TOP", Settings, "TOP", -160, -30)
SeasonTitle:SetFont(defaultFont, 11, flags)
SeasonTitle:SetTextColor(0.2, 0.8, 0.9)
SeasonTitle:SetText(L["SEASONS"])

local LibrariesTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LibrariesTitle:SetPoint("TOP", Settings, "TOP", -160, -125)
LibrariesTitle:SetFont(defaultFont, 11, flags)
LibrariesTitle:SetTextColor(0.2, 0.8, 0.9)
LibrariesTitle:SetText(L["LIBRARIES"])

local KeyTrackerTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
KeyTrackerTitle:SetPoint("TOP", Settings, "TOP", -160, -195)
KeyTrackerTitle:SetFont(defaultFont, 11, flags)
KeyTrackerTitle:SetTextColor(0.2, 0.8, 0.9)
KeyTrackerTitle:SetText(L["KEYTRACKER"])

local CustomizationsTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
CustomizationsTitle:SetPoint("TOP", Settings, "TOP", 0, -90)
CustomizationsTitle:SetFont(defaultFont, 11, flags)
CustomizationsTitle:SetTextColor(0.2, 0.8, 0.9)
CustomizationsTitle:SetText(L["CUSTOMIZATIONS"])

local PresetsTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
PresetsTitle:SetPoint("TOP", Settings, "TOP", 0, -30)
PresetsTitle:SetFont(defaultFont, 11, flags)
PresetsTitle:SetTextColor(0.2, 0.8, 0.9)
PresetsTitle:SetText(L["FRAME_PRESETS"])

local UtilityTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
UtilityTitle:SetPoint("TOP", Settings, "TOP", 160, -30)
UtilityTitle:SetFont(defaultFont, 11, flags)
UtilityTitle:SetTextColor(0.2, 0.8, 0.9)
UtilityTitle:SetText(L["UTILITIES"])

local ExtrasTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ExtrasTitle:SetPoint("TOP", Settings, "TOP", 160, -150)
ExtrasTitle:SetFont(defaultFont, 11, flags)
ExtrasTitle:SetTextColor(0.2, 0.8, 0.9)
ExtrasTitle:SetText(L["EXTRA_CUSTOMIZATIONS"])

local KeyTrackerExtrasTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
KeyTrackerExtrasTitle:SetPoint("TOP", Settings, "TOP", 160, -270)
KeyTrackerExtrasTitle:SetFont(defaultFont, 11, flags)
KeyTrackerExtrasTitle:SetTextColor(0.2, 0.8, 0.9)
KeyTrackerExtrasTitle:SetText(L["KEYTRACKER_EXTRAS"])

local AddonInfo = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
AddonInfo:SetPoint("BOTTOM", Settings, "BOTTOM", 0, 13)
AddonInfo:SetFont(defaultFont, 8, flags)
AddonInfo:SetText("M+ Dungeon Teleports by peepoStudy // " .. version .. "")
AddonInfo:SetTextColor(0.5, 0.5, 0.5)
-------------------------------------------------
-- MARK: Containers
local ContainSettings = AceGUI:Create("SimpleGroup")
ContainSettings:SetWidth(50)
ContainSettings:SetHeight(300)
ContainSettings.frame:SetParent(Settings)
ContainSettings.frame:SetPoint("TOP", SettingsTitle, "TOP", 193, 15)
ContainSettings.frame:Show()
-- Container Seasons
local ContainSeasons = AceGUI:Create("SimpleGroup")
ContainSeasons:SetWidth(150)
ContainSeasons:SetHeight(300)
ContainSeasons.frame:SetParent(Settings)
ContainSeasons.frame:SetPoint("TOP", SeasonTitle, "TOP", 0, -12)
ContainSeasons.frame:Show()
-- Container Libraries
local ContainLibraries = AceGUI:Create("SimpleGroup")
ContainLibraries:SetWidth(150)
ContainLibraries:SetHeight(200)
ContainLibraries.frame:SetParent(Settings)
ContainLibraries.frame:SetPoint("TOP", LibrariesTitle, "TOP", 0, -12)
ContainLibraries.frame:Show()
-- Container Key Tracker
local ContainKeyTracker = AceGUI:Create("SimpleGroup")
ContainKeyTracker:SetWidth(150)
ContainKeyTracker:SetHeight(200)
ContainKeyTracker.frame:SetParent(Settings)
ContainKeyTracker.frame:SetPoint("TOP", KeyTrackerTitle, "TOP", 0, -12)
ContainKeyTracker.frame:Show()
-- Container Customizations
local ContainCustomization = AceGUI:Create("SimpleGroup")
ContainCustomization:SetWidth(150)
ContainCustomization:SetHeight(600)
ContainCustomization.frame:SetParent(Settings)
ContainCustomization.frame:SetPoint("TOP", CustomizationsTitle, "TOP", 0, -12)
ContainCustomization.frame:Show()
-- Container Presets
local ContainPresets = AceGUI:Create("SimpleGroup")
ContainPresets:SetWidth(150)
ContainPresets:SetHeight(400)
ContainPresets.frame:SetParent(Settings)
ContainPresets.frame:SetPoint("TOP", PresetsTitle, "TOP", 0, -12)
ContainPresets.frame:Show()
-- Container Extras
local ContainExtras = AceGUI:Create("SimpleGroup")
ContainExtras:SetWidth(150)
ContainExtras:SetHeight(400)
ContainExtras.frame:SetParent(Settings)
ContainExtras.frame:SetPoint("TOP", ExtrasTitle, "TOP", 0, -12)
ContainExtras.frame:Show()
-- Container Utility
local ContainUtility = AceGUI:Create("SimpleGroup")
ContainUtility:SetWidth(150)
ContainUtility:SetHeight(400)
ContainUtility.frame:SetParent(Settings)
ContainUtility.frame:SetPoint("TOP", UtilityTitle, "TOP", 0, -12)
ContainUtility.frame:Show()
-- Container Key Tracker
local ContainKeyTrackerExtras = AceGUI:Create("SimpleGroup")
ContainKeyTrackerExtras:SetWidth(150)
ContainKeyTrackerExtras:SetHeight(400)
ContainKeyTrackerExtras.frame:SetParent(Settings)
ContainKeyTrackerExtras.frame:SetPoint("TOP", KeyTrackerExtrasTitle, "TOP", 0, -12)
ContainKeyTrackerExtras.frame:Show()
-------------------------------------------------
-- MARK: Season 1
local Season1CheckBox = AceGUI:Create("CheckBox")
Season1CheckBox:SetLabel(L["SEASON_1"])
Season1CheckBox:SetWidth(150) 
Season1CheckBox:SetValue(MDungeonTeleports.isSeason1PortalsShown)
Season1CheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isSeason1PortalsShown = val
    Season1Vis(val)
end)
ContainSeasons:AddChild(Season1CheckBox)
-------------------------------------------------
-- MARK: Season 2
local Season2CheckBox = AceGUI:Create("CheckBox")
Season2CheckBox:SetLabel(L["SEASON_2"])
Season2CheckBox:SetWidth(150) 
Season2CheckBox:SetValue(MDungeonTeleports.isSeason2PortalsShown)
Season2CheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isSeason2PortalsShown = val
    Season2Vis(val)
end)
ContainSeasons:AddChild(Season2CheckBox)
-------------------------------------------------
-- MARK: Season 3
local Season3CheckBox = AceGUI:Create("CheckBox")
Season3CheckBox:SetLabel(L["SEASON_3"])
Season3CheckBox:SetWidth(150) 
Season3CheckBox:SetValue(MDungeonTeleports.isSeason3PortalsShown)
Season3CheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isSeason3PortalsShown = val
    Season3Vis(val)
end)
ContainSeasons:AddChild(Season3CheckBox)
-------------------------------------------------
-- MARK: Dungeon Library
local PortalLibraryCheckBox = AceGUI:Create("CheckBox")
PortalLibraryCheckBox:SetLabel(L["DUNGEON_LIBRARY"])
PortalLibraryCheckBox:SetWidth(150) 
PortalLibraryCheckBox:SetValue(MDungeonTeleports.isPortalLibraryShown)
PortalLibraryCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isPortalLibraryShown = val
    DungeonVis(val)
end)
ContainLibraries:AddChild(PortalLibraryCheckBox)
-------------------------------------------------
-- MARK: Raid Library
local PortalLibraryRaidCheckBox = AceGUI:Create("CheckBox")
PortalLibraryRaidCheckBox:SetLabel(L["RAID_LIBRARY"])
PortalLibraryRaidCheckBox:SetWidth(150)
PortalLibraryRaidCheckBox:SetValue(MDungeonTeleports.isPortalLibraryRaidShown)
PortalLibraryRaidCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isPortalLibraryRaidShown = val
    RaidVis(val)
end)
ContainLibraries:AddChild(PortalLibraryRaidCheckBox)
-------------------------------------------------
-- MARK: Key Tracker
local ToggleKeyFrameCheckBox = AceGUI:Create("CheckBox")
ToggleKeyFrameCheckBox:SetLabel(L["KEY_TRACKER"])
ToggleKeyFrameCheckBox:SetWidth(150)
ToggleKeyFrameCheckBox:SetValue(MDungeonTeleports.isKeyFrameShown)
ToggleKeyFrameCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isKeyFrameShown = val
    KeyTVis(val)
end)
ContainKeyTracker:AddChild(ToggleKeyFrameCheckBox)
-------------------------------------------------
-- MARK: Show Tooltips
local ToggleTooltipsCheckBox = AceGUI:Create("CheckBox")
ToggleTooltipsCheckBox:SetLabel(L["TOOLTIPS"])
ToggleTooltipsCheckBox:SetWidth(150)
ToggleTooltipsCheckBox:SetValue(MDungeonTeleports.showTooltips)
ToggleTooltipsCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.showTooltips = val
end)
ContainExtras:AddChild(ToggleTooltipsCheckBox)
-------------------------------------------------
-- MARK: Compact Mode
local CompactModeCheckBox = AceGUI:Create("CheckBox")
CompactModeCheckBox:SetLabel(L["COMPACT_MODE"])
CompactModeCheckBox:SetWidth(150)
CompactModeCheckBox:SetValue(MDungeonTeleports.CompactMode)
CompactModeCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.CompactMode = val
    if MDTCompactModeSeason1 then MDTCompactModeSeason1() end
    if MDTCompactModeSeason2 then MDTCompactModeSeason2() end
    if MDTCompactModeSeason3 then MDTCompactModeSeason3() end
    if MDTCompactModePortalLibrary then MDTCompactModePortalLibrary() end
    if MDTCompactModePortalLibraryRaid then MDTCompactModePortalLibraryRaid() end
end)
ContainExtras:AddChild(CompactModeCheckBox)
-------------------------------------------------
-- MARK: Shift Drag Frames
local ShiftMoveCheckBox = AceGUI:Create("CheckBox")
ShiftMoveCheckBox:SetLabel(L["LOCK_FRAMES"])
ShiftMoveCheckBox:SetWidth(150)
ShiftMoveCheckBox:SetValue(MDungeonTeleports.ShiftDragToggle)
ShiftMoveCheckBox.frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText(L["TOOLTIP_SHIFT"], 1, 1, 1)
    GameTooltip:AddLine(L["TOOLTIP_SHIFT_SUB"], nil, nil, nil, true)
    GameTooltip:Show()
end)
ShiftMoveCheckBox.frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
ShiftMoveCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.ShiftDragToggle = val
    if MDTShiftDragToggleS1 then MDTShiftDragToggleS1() end
    if MDTShiftDragToggleS2 then MDTShiftDragToggleS2() end
    if MDTShiftDragToggleS3 then MDTShiftDragToggleS3() end
    if MDTShiftDragToggleDL then MDTShiftDragToggleDL() end
    if MDTShiftDragToggleRL then MDTShiftDragToggleRL() end
    if MDTShiftDragToggleKT then MDTShiftDragToggleKT() end
end)
ContainUtility:AddChild(ShiftMoveCheckBox)
-------------------------------------------------
-- MARK: Locked Icons
local LockIconsCheckBox = AceGUI:Create("CheckBox")
LockIconsCheckBox:SetLabel(L["LOCK_ICONS"])
LockIconsCheckBox:SetWidth(150)
LockIconsCheckBox:SetValue(MDungeonTeleports.LockIcons)
LockIconsCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.LockIcons = val
    if MDTUpdateS1ButtonTexture then MDTUpdateS1ButtonTexture() end
    if MDTUpdateS2ButtonTexture then MDTUpdateS2ButtonTexture() end
    if MDTUpdateS3ButtonTexture then MDTUpdateS3ButtonTexture() end 
    if MDTUpdatePLButtonTexture then MDTUpdatePLButtonTexture() end
    if MDTUpdatePLRButtonTexture then MDTUpdatePLRButtonTexture() end
end)
ContainExtras:AddChild(LockIconsCheckBox)
-------------------------------------------------
-- MARK: Greyed out Text
local DarkenCheckBox = AceGUI:Create("CheckBox")
DarkenCheckBox:SetLabel(L["DARKEN_TEXT"])
DarkenCheckBox:SetWidth(150)
DarkenCheckBox:SetValue(MDungeonTeleports.DarkenIcons)
DarkenCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.DarkenText = val
    if MDTUpdateFontS1 then MDTUpdateFontS1() end
    if MDTUpdateFontS2 then MDTUpdateFontS2() end
    if MDTUpdateFontS3 then MDTUpdateFontS3() end
    if MDTUpdateFontPL then MDTUpdateFontPL() end
    if MDTUpdateFontPLR then MDTUpdateFontPLR() end
end)
ContainExtras:AddChild(DarkenCheckBox)
-------------------------------------------------
-- MARK: Respond to Keys
local RespondKeysCheckBox = AceGUI:Create("CheckBox")
RespondKeysCheckBox:SetLabel(L["RESPOND_TO_KEYS"])
RespondKeysCheckBox:SetValue(MDungeonTeleports.isRespondChecked)
RespondKeysCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.isRespondChecked = val
end)
ContainUtility:AddChild(RespondKeysCheckBox)
-------------------------------------------------
-- MARK: Announce Teleport Location
local AnnounceTeleportCheckBox = AceGUI:Create("CheckBox")
AnnounceTeleportCheckBox:SetLabel(L["TELEPORT_LOCATION"])
AnnounceTeleportCheckBox:SetWidth(150)
AnnounceTeleportCheckBox:SetValue(MDungeonTeleports.announcePort)
AnnounceTeleportCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.announcePort = val
end)
ContainUtility:AddChild(AnnounceTeleportCheckBox)
-------------------------------------------------
-- MARK: Daily Login Message
local DailyLoginMessageCheckBox = AceGUI:Create("CheckBox")
DailyLoginMessageCheckBox:SetLabel(L["LOGIN_MESSAGE"])
DailyLoginMessageCheckBox:SetWidth(150)
DailyLoginMessageCheckBox:SetValue(MDungeonTeleports.loginMessage)
DailyLoginMessageCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.loginMessage = val
end)
ContainUtility:AddChild(DailyLoginMessageCheckBox)
-------------------------------------------------
-- MARK: Button Border Colour
local ButtonBorderColorPicker = AceGUI:Create("ColorPicker")
ButtonBorderColorPicker:SetLabel(L["BUTTON_BORDER_COLOR"])
ButtonBorderColorPicker:SetWidth(150)
ButtonBorderColorPicker:SetHasAlpha(true)
ButtonBorderColorPicker:SetColor(
    MDungeonTeleports.buttonBorderColor.r,
    MDungeonTeleports.buttonBorderColor.g,
    MDungeonTeleports.buttonBorderColor.b,
    MDungeonTeleports.buttonBorderColor.a
)
ButtonBorderColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
    if r == 0 and g == 0 and b == 0 then
        r, g, b = 0.05, 0.05, 0.05
    end
    MDungeonTeleports.buttonBorderColor = { r = r, g = g, b = b, a = a }
    if MDTUpdateSeason1Colors then MDTUpdateSeason1Colors() end
    if MDTUpdateSeason2Colors then MDTUpdateSeason2Colors() end
    if MDTUpdateSeason3Colors then MDTUpdateSeason3Colors() end
    if MDTUpdatePortalLibraryColors then MDTUpdatePortalLibraryColors() end
    if MDTUpdatePortalLibraryRaidColors then MDTUpdatePortalLibraryRaidColors() end
    if MDTUpdateKeyTrackerColors then MDTUpdateKeyTrackerColors() end
end)
ContainCustomization:AddChild(ButtonBorderColorPicker)

-------------------------------------------------
-- MARK: Border Colour
local borderColorPicker = AceGUI:Create("ColorPicker")
borderColorPicker:SetLabel(L["BORDER_COLOR"])
borderColorPicker:SetWidth(150)
borderColorPicker:SetHasAlpha(true)
borderColorPicker:SetColor(
    MDungeonTeleports.borderColor.r,
    MDungeonTeleports.borderColor.g,
    MDungeonTeleports.borderColor.b,
    MDungeonTeleports.borderColor.a
)
borderColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
    if r == 0 and g == 0 and b == 0 then
        r, g, b = 0.05, 0.05, 0.05
    end
    MDungeonTeleports.borderColor = { r = r, g = g, b = b, a = a }
    if MDTUpdateSeason1Colors then MDTUpdateSeason1Colors() end
    if MDTUpdateSeason2Colors then MDTUpdateSeason2Colors() end
    if MDTUpdateSeason3Colors then MDTUpdateSeason3Colors() end
    if MDTUpdatePortalLibraryColors then MDTUpdatePortalLibraryColors() end
    if MDTUpdatePortalLibraryRaidColors then MDTUpdatePortalLibraryRaidColors() end
    if MDTUpdateKeyTrackerColors then MDTUpdateKeyTrackerColors() end
end)
ContainCustomization:AddChild(borderColorPicker)
-------------------------------------------------
-- MARK: Background Colour
local backgroundColorPicker = AceGUI:Create("ColorPicker")
backgroundColorPicker:SetLabel(L["BACKGROUND_COLOR"])
backgroundColorPicker:SetWidth(150)
backgroundColorPicker:SetHasAlpha(true)
backgroundColorPicker:SetColor(
    MDungeonTeleports.backgroundColor.r,
    MDungeonTeleports.backgroundColor.g,
    MDungeonTeleports.backgroundColor.b,
    MDungeonTeleports.backgroundColor.a
)
backgroundColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
    MDungeonTeleports.backgroundColor = { r = r, g = g, b = b, a = a }
    if MDTUpdateSeason1Colors then MDTUpdateSeason1Colors() end
    if MDTUpdateSeason2Colors then MDTUpdateSeason2Colors() end
    if MDTUpdateSeason3Colors then MDTUpdateSeason3Colors() end
    if MDTUpdatePortalLibraryColors then MDTUpdatePortalLibraryColors() end
    if MDTUpdatePortalLibraryRaidColors then MDTUpdatePortalLibraryRaidColors() end
    if MDTUpdateKeyTrackerColors then MDTUpdateKeyTrackerColors() end
end)
ContainCustomization:AddChild(backgroundColorPicker)
-------------------------------------------------
-- MARK: Font Dropdown
local fontDropdown = AceGUI:Create("Dropdown")
fontDropdown:SetLabel(L["SELECT_FONT"])
local fontList = {}
for _, font in ipairs(LSM:List("font")) do
    fontList[font] = font
end
fontDropdown:SetList(fontList)
fontDropdown:SetWidth(150)
fontDropdown:SetCallback("OnOpened", function()
    local pullout = fontDropdown.pullout
    if pullout and pullout.frame then
        pullout.frame:SetHeight(300)
    end
end)
if MDungeonTeleports.customFontName then
    fontDropdown:SetValue(MDungeonTeleports.customFontName)
    MDungeonTeleports.customFont = LSM:Fetch("font", MDungeonTeleports.customFontName)
end
fontDropdown:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.customFontName = val
    local fontPath = LSM:Fetch("font", val)
    if fontPath then
        MDungeonTeleports.customFont = fontPath
    end
    if MDTUpdateFontS1 then MDTUpdateFontS1() end
    if MDTUpdateFontS2 then MDTUpdateFontS2() end
    if MDTUpdateFontS3 then MDTUpdateFontS3() end
    if MDTUpdateFontPL then MDTUpdateFontPL() end
    if MDTUpdateFontPLR then MDTUpdateFontPLR() end
    if MDTUpdateFontKT then MDTUpdateFontKT() end
end)
ContainCustomization:AddChild(fontDropdown)
-------------------------------------------------
-- MARK: Expansion Title Colour Picker
local expansionColorPicker = AceGUI:Create("ColorPicker")
expansionColorPicker:SetLabel(L["EXPANSION_COLOR"])
expansionColorPicker:SetWidth(150)
expansionColorPicker:SetHasAlpha(false)
expansionColorPicker:SetColor(
    MDungeonTeleports.expansionColor.r,
    MDungeonTeleports.expansionColor.g,
    MDungeonTeleports.expansionColor.b
)
expansionColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b)
    MDungeonTeleports.expansionColor = { r = r, g = g, b = b }
    if MDTUpdateFontPL then MDTUpdateFontPL() end
    if MDTUpdateFontPLR then MDTUpdateFontPLR() end
end)
ContainCustomization:AddChild(expansionColorPicker)
-------------------------------------------------
-- MARK: Title Text Colour Picker
local titleColorPicker = AceGUI:Create("ColorPicker")
titleColorPicker:SetLabel(L["TITLE_COLOR"])
titleColorPicker:SetWidth(150)
titleColorPicker:SetHasAlpha(false)
titleColorPicker:SetColor(
    MDungeonTeleports.titleColor.r,
    MDungeonTeleports.titleColor.g,
    MDungeonTeleports.titleColor.b
)
titleColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b)
    MDungeonTeleports.titleColor = { r = r, g = g, b = b }
    if MDTUpdateFontS1 then MDTUpdateFontS1() end
    if MDTUpdateFontS2 then MDTUpdateFontS2() end
    if MDTUpdateFontS3 then MDTUpdateFontS3() end
    if MDTUpdateFontPL then MDTUpdateFontPL() end
    if MDTUpdateFontPLR then MDTUpdateFontPLR() end
    if MDTUpdateFontKT then MDTUpdateFontKT() end
end)
ContainCustomization:AddChild(titleColorPicker)
-------------------------------------------------
-- MARK: Button Text Colour Picker  
local buttonTextColorPicker = AceGUI:Create("ColorPicker")
buttonTextColorPicker:SetLabel(L["PORTAL_COLOR"])
buttonTextColorPicker:SetWidth(150)
buttonTextColorPicker:SetHasAlpha(false)
buttonTextColorPicker:SetColor(
    MDungeonTeleports.buttonTextColor.r,
    MDungeonTeleports.buttonTextColor.g,
    MDungeonTeleports.buttonTextColor.b
)
buttonTextColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b)
    MDungeonTeleports.buttonTextColor = { r = r, g = g, b = b }
    if MDTUpdateFontS1 then MDTUpdateFontS1() end
    if MDTUpdateFontS2 then MDTUpdateFontS2() end
    if MDTUpdateFontS3 then MDTUpdateFontS3() end
    if MDTUpdateFontPL then MDTUpdateFontPL() end
    if MDTUpdateFontPLR then MDTUpdateFontPLR() end
    if MDTUpdateFontKT then MDTUpdateFontKT() end
end)
ContainCustomization:AddChild(buttonTextColorPicker)
-------------------------------------------------
-- MARK: Frame Presets Dropdown
local presetDropdown = AceGUI:Create("Dropdown")
presetDropdown:SetLabel(L["SELECT_PRESET"])
presetDropdown:SetWidth(150)

local presetList = {}
for _, preset in ipairs(MDT_ColourPresets) do
    presetList[preset.text] = preset.text
end
presetDropdown:SetList(presetList)
presetDropdown:SetValue(MDT_ColourPresets[1].text)
MDungeonTeleports.selectedPreset = 1
presetDropdown:SetCallback("OnValueChanged", function(_, _, val)
    collectgarbage("collect")
    local selectedPreset
    for i, preset in ipairs(MDT_ColourPresets) do
        if preset.text == val then
            selectedPreset = preset
            MDungeonTeleports.selectedPreset = i
            break
        end
    end
    if selectedPreset then
        local back = selectedPreset.back
        if back then
            MDungeonTeleports.backgroundColor = { r = back.r, g = back.g, b = back.b, a = back.a }
        end
        local border = selectedPreset.border
        if border then
            MDungeonTeleports.borderColor = { r = border.r, g = border.g, b = border.b, a = border.a }
        end
        local title = selectedPreset.title
        if title then
            MDungeonTeleports.titleColor = { r = title.r, g = title.g, b = title.b }
        end
        local expansion = selectedPreset.expansion
        if expansion then
            MDungeonTeleports.expansionColor = { r = expansion.r, g = expansion.g, b = expansion.b }
        end
        local buttonX = selectedPreset.button
        if buttonX then
            MDungeonTeleports.buttonTextColor = { r = buttonX.r, g = buttonX.g, b = buttonX.b }
        end
        local buttonborderx = selectedPreset.buttonborder
        if buttonborderx then
            MDungeonTeleports.buttonBorderColor = { r = buttonborderx.r, g = buttonborderx.g, b = buttonborderx.b, a = buttonborderx.a }
        end

        if MDTUpdateFontS1 then MDTUpdateFontS1() end
        if MDTUpdateFontS2 then MDTUpdateFontS2() end
        if MDTUpdateFontS3 then MDTUpdateFontS3() end
        if MDTUpdateFontPL then MDTUpdateFontPL() end
        if MDTUpdateFontPLR then MDTUpdateFontPLR() end
        if MDTUpdateFontKT then MDTUpdateFontKT() end
        
        if MDTUpdateSeason1Border then MDTUpdateSeason1Border() end
        if MDTUpdateSeason2Border then MDTUpdateSeason2Border() end
        if MDTUpdateSeason3Border then MDTUpdateSeason3Border() end
        if MDTUpdatePortalLibraryBorder then MDTUpdatePortalLibraryBorder() end
        if MDTUpdatePortalLibraryRaidBorder then MDTUpdatePortalLibraryRaidBorder() end
        if MDTUpdateKeyTrackerBorder then MDTUpdateKeyTrackerBorder() end

        if MDTUpdateSeason1Colors then MDTUpdateSeason1Colors() end
        if MDTUpdateSeason2Colors then MDTUpdateSeason2Colors() end
        if MDTUpdateSeason3Colors then MDTUpdateSeason3Colors() end
        if MDTUpdatePortalLibraryColors then MDTUpdatePortalLibraryColors() end
        if MDTUpdatePortalLibraryRaidColors then MDTUpdatePortalLibraryRaidColors() end
        if MDTUpdateKeyTrackerColors then MDTUpdateKeyTrackerColors() end

        borderColorPicker:SetColor(MDungeonTeleports.borderColor.r, MDungeonTeleports.borderColor.g, MDungeonTeleports.borderColor.b, MDungeonTeleports.borderColor.a)
        backgroundColorPicker:SetColor(MDungeonTeleports.backgroundColor.r, MDungeonTeleports.backgroundColor.g, MDungeonTeleports.backgroundColor.b, MDungeonTeleports.backgroundColor.a)
        expansionColorPicker:SetColor(MDungeonTeleports.expansionColor.r, MDungeonTeleports.expansionColor.g, MDungeonTeleports.expansionColor.b)
        titleColorPicker:SetColor(MDungeonTeleports.titleColor.r, MDungeonTeleports.titleColor.g, MDungeonTeleports.titleColor.b)
        buttonTextColorPicker:SetColor(MDungeonTeleports.buttonTextColor.r, MDungeonTeleports.buttonTextColor.g, MDungeonTeleports.buttonTextColor.b)   
        ButtonBorderColorPicker:SetColor(MDungeonTeleports.buttonBorderColor.r, MDungeonTeleports.buttonBorderColor.g, MDungeonTeleports.buttonBorderColor.b, MDungeonTeleports.buttonBorderColor.a)
    end
end)
ContainPresets:AddChild(presetDropdown)
-------------------------------------------------
-- -- MARK: Frame Size Slider
local UIScaleSlider = AceGUI:Create("Slider")
UIScaleSlider:SetLabel(L["SCALE_SLIDER"])
UIScaleSlider:SetWidth(150)
UIScaleSlider:SetSliderValues(0.75, 1.25, 0.01)
UIScaleSlider:SetValue(MDungeonTeleports.frameScale or 1)
UIScaleSlider:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.frameScale = val
    UpdateFrameScale(val)
end)
ContainCustomization:AddChild(UIScaleSlider)
--------------------------------------------------
-- MARK: Border Thickness Slider
local BorderSlider = AceGUI:Create("Slider")
BorderSlider:SetLabel(L["SCALE_SLIDER_BORDER"])
BorderSlider:SetWidth(150)
BorderSlider:SetSliderValues(0, 5, 1)
BorderSlider:SetValue(1)
BorderSlider:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.borderThickness = val
    if MDTUpdateSeason1Border then MDTUpdateSeason1Border() end
    if MDTUpdateSeason2Border then MDTUpdateSeason2Border() end
    if MDTUpdateSeason3Border then MDTUpdateSeason3Border() end
    if MDTUpdatePortalLibraryBorder then MDTUpdatePortalLibraryBorder() end
    if MDTUpdatePortalLibraryRaidBorder then MDTUpdatePortalLibraryRaidBorder() end
    if MDTUpdateKeyTrackerBorder then MDTUpdateKeyTrackerBorder() end
end)
ContainCustomization:AddChild(BorderSlider)
-------------------------------------------------
-- MARK: Key TrackerFrame Size Slider
local KeyTrackerUIScaleSlider = AceGUI:Create("Slider")
KeyTrackerUIScaleSlider:SetLabel(L["KEY_SCALE_SLIDER"])
KeyTrackerUIScaleSlider:SetWidth(150)
KeyTrackerUIScaleSlider:SetSliderValues(0.75, 1.25, 0.01)
KeyTrackerUIScaleSlider:SetValue(MDungeonTeleports.KeyTrackerFrameScale or 1)
KeyTrackerUIScaleSlider:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.KeyTrackerFrameScale = val
    UpdateKeyTrackerFrameScale(val)
end)
ContainCustomization:AddChild(KeyTrackerUIScaleSlider)
-------------------------------------------------
-- MARK: Rio Score
local RioScoreCheckBox = AceGUI:Create("CheckBox")
RioScoreCheckBox:SetLabel(L["RIO_SCORE"])
RioScoreCheckBox:SetWidth(150)
RioScoreCheckBox:SetValue(MDungeonTeleports.rioScore)
RioScoreCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.rioScore = val
    MDTUpdateScoreNameKT()
end)
ContainKeyTrackerExtras:AddChild(RioScoreCheckBox)
-------------------------------------------------
-- MARK: Realm Name
local RealmNameCheckBox = AceGUI:Create("CheckBox")
RealmNameCheckBox:SetLabel(L["REALM_NAME"])
RealmNameCheckBox:SetWidth(150)
RealmNameCheckBox:SetValue(MDungeonTeleports.realmName)
RealmNameCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.realmName = val
    MDTUpdateScoreNameKT()
end)
ContainKeyTrackerExtras:AddChild(RealmNameCheckBox)
-------------------------------------------------
-- MARK: Drag Handle
local DragHandleCheckBox = AceGUI:Create("CheckBox")
DragHandleCheckBox:SetLabel(L["DRAG_HANDLE"])
DragHandleCheckBox:SetWidth(150)
DragHandleCheckBox:SetValue(MDungeonTeleports.dragHandle)
DragHandleCheckBox:SetCallback("OnValueChanged", function(_, _, val)
    MDungeonTeleports.dragHandle = val
    MDTKTToggleDragHandle()
end)
ContainKeyTrackerExtras:AddChild(DragHandleCheckBox)
-------------------------------------------------
-- MARK: Settings Size Slider
local UISettingsScaleSlider = AceGUI:Create("Slider")
UISettingsScaleSlider:SetLabel("")
UISettingsScaleSlider:SetWidth(50)
UISettingsScaleSlider:SetSliderValues(0.7, 1.3, 0.01)
UISettingsScaleSlider:SetValue(MDungeonTeleports.settingsScale or 1)
UISettingsScaleSlider.lowtext:SetText("")
UISettingsScaleSlider.lowtext:Hide()
UISettingsScaleSlider.hightext:SetText("")
UISettingsScaleSlider.hightext:Hide()
UISettingsScaleSlider.editbox:Hide()
UISettingsScaleSlider:SetCallback("OnValueChanged", function(_, _, val)
    UISettingsScaleSlider._pendingValue = val
end)
UISettingsScaleSlider.slider:HookScript("OnMouseUp", function()
    if UISettingsScaleSlider._pendingValue then
        MDungeonTeleports.settingsScale = UISettingsScaleSlider._pendingValue
        UpdateSettingsFrameScale(UISettingsScaleSlider._pendingValue)
    end
end)
UISettingsScaleSlider.slider:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L["TOOLTIP_SCALE"], 1, 1, 1)
    GameTooltip:AddLine(L["TOOLTIP_SCALE_SUB"], nil, nil, nil, true)
    GameTooltip:Show()
end)
UISettingsScaleSlider.slider:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
ContainSettings:AddChild(UISettingsScaleSlider)
-------------------------------------------------
-- MARK: Settings Exit Button
local settingsExitButton = CreateFrame("Button", "SettingsOpenButton", Settings)
settingsExitButton:SetSize(11, 11)
settingsExitButton:SetPoint("TOPRIGHT", Settings, "TOPRIGHT", -7, -7)
settingsExitButton:SetFrameStrata("DIALOG")

local settingExitButtonTexture = settingsExitButton:CreateTexture(nil, "BACKGROUND")
settingExitButtonTexture:SetAllPoints(settingsExitButton)
settingExitButtonTexture:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_close.blp")

local settingsExitButtonHighlight = settingsExitButton:CreateTexture(nil, "HIGHLIGHT")
settingsExitButtonHighlight:SetAllPoints(settingsExitButton)
settingsExitButtonHighlight:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_close_highlight.blp")
settingsExitButtonHighlight:Hide()

settingsExitButton.settingsExitButtonHighlight = settingsExitButtonHighlight
settingsExitButton.settingExitButtonTexture = settingExitButtonTexture
settingsExitButton:SetScript("OnEnter", function(self)
        self.settingsExitButtonHighlight:Show()
        self.settingExitButtonTexture:Hide()
    end
)
settingsExitButton:SetScript("OnLeave", function(self)
        self.settingsExitButtonHighlight:Hide()
        self.settingExitButtonTexture:Show()
    end
)
settingsExitButton:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
        Settings:Hide()
    end
)
-------------------------------------------------
-- MARK: Update UI
local function UpdateUI()
    --- Checkbox Value Set ---
    if Season1CheckBox then Season1CheckBox:SetValue(MDungeonTeleports.isSeason1PortalsShown) end
    if Season2CheckBox then Season2CheckBox:SetValue(MDungeonTeleports.isSeason2PortalsShown) end
    if Season3CheckBox then Season3CheckBox:SetValue(MDungeonTeleports.isSeason3PortalsShown) end
    if PortalLibraryCheckBox then PortalLibraryCheckBox:SetValue(MDungeonTeleports.isPortalLibraryShown) end
    if PortalLibraryRaidCheckBox then PortalLibraryRaidCheckBox:SetValue(MDungeonTeleports.isPortalLibraryRaidShown) end
    if ToggleKeyFrameCheckBox then ToggleKeyFrameCheckBox:SetValue(MDungeonTeleports.isKeyFrameShown) end
    if ToggleTooltipsCheckBox then ToggleTooltipsCheckBox:SetValue(MDungeonTeleports.showTooltips) end
    if CompactModeCheckBox then CompactModeCheckBox:SetValue(MDungeonTeleports.CompactMode) end
    if ShiftMoveCheckBox then ShiftMoveCheckBox:SetValue(MDungeonTeleports.ShiftDragToggle) end
    if RespondKeysCheckBox then RespondKeysCheckBox:SetValue(MDungeonTeleports.isRespondChecked) end
    if DailyLoginMessageCheckBox then DailyLoginMessageCheckBox:SetValue(MDungeonTeleports.loginMessage) end
    if AnnounceTeleportCheckBox then AnnounceTeleportCheckBox:SetValue(MDungeonTeleports.announcePort) end
    if LockIconsCheckBox then LockIconsCheckBox:SetValue(MDungeonTeleports.LockIcons) end
    if DarkenCheckBox then DarkenCheckBox:SetValue(MDungeonTeleports.DarkenText) end
    if RioScoreCheckBox then RioScoreCheckBox:SetValue(MDungeonTeleports.rioScore) end
    if RealmNameCheckBox then RealmNameCheckBox:SetValue(MDungeonTeleports.realmName) end
    if DragHandleCheckBox then DragHandleCheckBox:SetValue(MDungeonTeleports.dragHandle) end
    --- Login Visibility Variable Check and Set ---
    Season1Vis(MDungeonTeleports.isSeason1PortalsShown)
    Season2Vis(MDungeonTeleports.isSeason2PortalsShown)
    Season3Vis(MDungeonTeleports.isSeason3PortalsShown)
    DungeonVis(MDungeonTeleports.isPortalLibraryShown)
    RaidVis(MDungeonTeleports.isPortalLibraryRaidShown)
    KeyTVis(MDungeonTeleports.isKeyFrameShown)
    --- UI Scale Value Set ---
    if UIScaleSlider then UIScaleSlider:SetValue(MDungeonTeleports.frameScale or 1) end
    if KeyTrackerUIScaleSlider then KeyTrackerUIScaleSlider:SetValue(MDungeonTeleports.KeyTrackerFrameScale or 1) end
    --- UI Border Scale Set ---
    if BorderSlider then BorderSlider:SetValue(MDungeonTeleports.borderThickness or 1) end
    --- UI Settings Scale Set --- 
    if UISettingsScaleSlider then UISettingsScaleSlider:SetValue(MDungeonTeleports.settingsScale or 1) end
    --- UI Scale Set ---
    local scale = MDungeonTeleports.frameScale
    local keyscale = MDungeonTeleports.KeyTrackerFrameScale
    UpdateFrameScale(scale)
    UpdateKeyTrackerFrameScale(keyscale)
    local scalesettings = MDungeonTeleports.settingsScale
    UpdateSettingsFrameScale(scalesettings)
    --- Font Dropdown Value Set ---
    if fontDropdown then fontDropdown:SetValue(MDungeonTeleports.customFontName) end
    if presetDropdown and MDT_ColourPresets and MDungeonTeleports.selectedPreset and MDT_ColourPresets[MDungeonTeleports.selectedPreset] then 
        presetDropdown:SetValue(MDT_ColourPresets[MDungeonTeleports.selectedPreset].text) 
    end
    --- Color Picker Value Set ---
    if borderColorPicker then borderColorPicker:SetColor(MDungeonTeleports.borderColor.r, MDungeonTeleports.borderColor.g, MDungeonTeleports.borderColor.b, MDungeonTeleports.borderColor.a) end
    if backgroundColorPicker then backgroundColorPicker:SetColor(MDungeonTeleports.backgroundColor.r, MDungeonTeleports.backgroundColor.g, MDungeonTeleports.backgroundColor.b, MDungeonTeleports.backgroundColor.a) end
    if expansionColorPicker then expansionColorPicker:SetColor(MDungeonTeleports.expansionColor.r, MDungeonTeleports.expansionColor.g, MDungeonTeleports.expansionColor.b) end
    if titleColorPicker then titleColorPicker:SetColor(MDungeonTeleports.titleColor.r, MDungeonTeleports.titleColor.g, MDungeonTeleports.titleColor.b) end
    if buttonTextColorPicker then buttonTextColorPicker:SetColor(MDungeonTeleports.buttonTextColor.r, MDungeonTeleports.buttonTextColor.g, MDungeonTeleports.buttonTextColor.b) end
    local bbcolor = MDungeonTeleports.buttonBorderColor or { r = 0.05, g = 0.05, b = 0.05, a = 0.8 }
    if ButtonBorderColorPicker then ButtonBorderColorPicker:SetColor(bbcolor.r, bbcolor.g, bbcolor.b, bbcolor.a) end
end
-------------------------------------------------
-- MARK: AddOn Load Event
local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MDungeonTeleports" then
        UpdateUI()
    end
end
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
-------------------------------------------------
-- MARK: Slash Command
SLASH_DP1 = "/dp"
SlashCmdList["DP"] = function()
    if Settings:IsShown() then
        Settings:Hide()
    else
        Settings:Show()
    end
end
-------------------------------------------------
-- MARK: Group Finder Settings Button
local settingsOpenButton = CreateFrame("Button", "SettingsOpenButton", PVEFrame)

local isElvUILoaded = IsAddOnLoaded("ElvUI")

if isElvUILoaded then
    settingsOpenButton:SetSize(14, 14)
    settingsOpenButton:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", -22, -5)
else
    settingsOpenButton:SetSize(21, 21)
    settingsOpenButton:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", -22, -1)
end

settingsOpenButton:SetFrameStrata("DIALOG")

local defaultTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\settings_buttons.blp"
local elvuiTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_settings.blp"

local defaultNormalCoords = {0.054687, 0.304687, 0.046875, 0.296875}
local defaultHighlightCoords = {0.351562, 0.601562, 0.046875, 0.296875}
local defaultPressedCoords = {0.054687, 0.304687, 0.3828125, 0.632812}

local elvuiHighlightTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_settings_highlight.blp"
local elvuiPressedTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_settings_pressed.blp"

local settingsOpenButtonTexture = settingsOpenButton:CreateTexture(nil, "BACKGROUND")
settingsOpenButtonTexture:SetAllPoints(settingsOpenButton)
settingsOpenButtonTexture:SetTexture(isElvUILoaded and elvuiTexture or defaultTexture)

if not isElvUILoaded then
    settingsOpenButtonTexture:SetTexCoord(unpack(defaultNormalCoords))
end

local settingsButtonHoverOverlay = settingsOpenButton:CreateTexture(nil, "HIGHLIGHT")
settingsButtonHoverOverlay:SetAllPoints(settingsOpenButton)
settingsButtonHoverOverlay:SetTexture(isElvUILoaded and elvuiHighlightTexture or defaultTexture)
settingsButtonHoverOverlay:Hide()

if not isElvUILoaded then
    settingsButtonHoverOverlay:SetTexCoord(unpack(defaultHighlightCoords))
end

local settingsButtonPressedOverlay = settingsOpenButton:CreateTexture(nil, "BACKGROUND")
settingsButtonPressedOverlay:SetAllPoints(settingsOpenButton)
settingsButtonPressedOverlay:SetTexture(isElvUILoaded and elvuiPressedTexture or defaultTexture)
settingsButtonPressedOverlay:Hide()

if not isElvUILoaded then
    settingsButtonPressedOverlay:SetTexCoord(unpack(defaultPressedCoords))
end

settingsOpenButton.settingsOpenButtonTexture = settingsOpenButtonTexture
settingsOpenButton.settingsButtonHoverOverlay = settingsButtonHoverOverlay
settingsOpenButton.settingsButtonPressedOverlay = settingsButtonPressedOverlay

settingsOpenButton:SetScript(
    "OnEnter",
    function(self)
        self.settingsButtonHoverOverlay:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["MDT_FULL"], 1, 1, 1)
        GameTooltip:AddLine(L["OPEN_SETTINGS"], nil, nil, nil, true)
        if InCombatLockdown() then
            GameTooltip:AddLine("|cFFFF0000" .. L["COMBAT_WARNING"] .. "|r", nil, nil, nil, true)
        end
        GameTooltip:Show()
    end
)

settingsOpenButton:SetScript(
    "OnLeave",
    function(self)
        self.settingsButtonHoverOverlay:Hide()
        self.settingsButtonPressedOverlay:Hide()
        self.settingsOpenButtonTexture:Show()
        GameTooltip:Hide()
    end
)
settingsOpenButton:SetScript(
    "OnMouseDown",
    function(self)
        self.settingsButtonPressedOverlay:Show()
        self.settingsOpenButtonTexture:Hide()
    end
)

settingsOpenButton:SetScript(
    "OnMouseUp",
    function(self)
        self.settingsButtonPressedOverlay:Hide()
        self.settingsOpenButtonTexture:Show()
    end
)

settingsOpenButton:SetScript(
    "OnClick",
    function(self)
        if InCombatLockdown() then
            return
        end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        if Settings:IsShown() then
            Settings:Hide()
        else
            Settings:Show()
        end
    end
)

local function UpdateButtonStatus()
    if InCombatLockdown() then
        settingsOpenButton:Disable()
    else
        settingsOpenButton:Enable()
    end
end

settingsOpenButton:RegisterEvent("PLAYER_REGEN_ENABLED")
settingsOpenButton:RegisterEvent("PLAYER_REGEN_DISABLED")
settingsOpenButton:SetScript("OnEvent", UpdateButtonStatus)

UpdateButtonStatus()
-------------------------------------------------
-- MARK: Reset Button
local resetButton = CreateFrame("Button", "ResetButton", Settings)
resetButton:SetSize(24, 24)
resetButton:SetPoint("BOTTOMLEFT", Settings, "BOTTOMLEFT", 4, 4)
resetButton:SetFrameStrata("DIALOG")

local resetButtonTexture = resetButton:CreateTexture(nil, "BACKGROUND")
resetButtonTexture:SetAllPoints(resetButton)
resetButtonTexture:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_reset.blp")

local resetButtonHighlight = resetButton:CreateTexture(nil, "HIGHLIGHT")
resetButtonHighlight:SetAllPoints(resetButton)
resetButtonHighlight:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_reset_highlight.blp")
resetButtonHighlight:Hide()

resetButton.resetButtonHighlight = resetButtonHighlight
resetButton.resetButtonTexture = resetButtonTexture
resetButton:SetScript(
    "OnEnter",
    function(self)
        self.resetButtonHighlight:Show()
        self.resetButtonTexture:Hide()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["RESET_ADDON"], 1, 1, 1)
        GameTooltip:AddLine(L["RESET_ADDON_TIP"], nil, nil, nil, true)
        GameTooltip:Show()
    end
)
resetButton:SetScript(
    "OnLeave",
    function(self)
        self.resetButtonHighlight:Hide()
        self.resetButtonTexture:Show()
        GameTooltip:Hide()
    end
)
resetButton:SetScript(
    "OnClick",
    function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        MDungeonTeleports.Season1Pos = defaultSettings.Season1Pos
        MDungeonTeleports.Season2Pos = defaultSettings.Season2Pos
        MDungeonTeleports.Season3Pos = defaultSettings.Season3Pos
        MDungeonTeleports.PortalLibraryPos = defaultSettings.PortalLibraryPos
        MDungeonTeleports.PortalLibraryRaidPos = defaultSettings.PortalLibraryRaidPos
        MDungeonTeleports.KeyTrackerPos = defaultSettings.KeyTrackerPos
        MDungeonTeleports.isSeason1PortalsShown = defaultSettings.isSeason1PortalsShown
        MDungeonTeleports.isSeason2PortalsShown = defaultSettings.isSeason2PortalsShown
        MDungeonTeleports.isSeason3PortalsShown = defaultSettings.isSeason3PortalsShown
        MDungeonTeleports.isPortalLibraryShown = defaultSettings.isPortalLibraryShown
        MDungeonTeleports.isPortalLibraryRaidShown = defaultSettings.isPortalLibraryRaidShown
        MDungeonTeleports.isKeyFrameShown = defaultSettings.isKeyFrameShown
        MDungeonTeleports.showTooltips = defaultSettings.showTooltips
        MDungeonTeleports.CompactMode = defaultSettings.CompactMode
        MDungeonTeleports.ShiftDragToggle = defaultSettings.ShiftDragToggle
        MDungeonTeleports.isRespondChecked = defaultSettings.isRespondChecked
        MDungeonTeleports.loginMessage = defaultSettings.loginMessage
        MDungeonTeleports.announcePort = defaultSettings.announcePort
        MDungeonTeleports.LockIcons = defaultSettings.LockIcons
        MDungeonTeleports.DarkenText = defaultSettings.DarkenText
        MDungeonTeleports.borderColor = defaultSettings.borderColor
        MDungeonTeleports.backgroundColor = defaultSettings.backgroundColor
        MDungeonTeleports.expansionColor = defaultSettings.expansionColor
        MDungeonTeleports.titleColor = defaultSettings.titleColor
        MDungeonTeleports.buttonTextColor = defaultSettings.buttonTextColor
        MDungeonTeleports.buttonBorderColor = defaultSettings.buttonBorderColor
        MDungeonTeleports.customFont = defaultSettings.customFont
        MDungeonTeleports.customFontName = defaultSettings.customFontName
        MDungeonTeleports.frameScale = defaultSettings.frameScale
        MDungeonTeleports.KeyTrackerFrameScale = defaultSettings.KeyTrackerFrameScale
        MDungeonTeleports.settingsScale = defaultSettings.settingsScale
        MDungeonTeleports.borderThickness = defaultSettings.borderThickness
        MDungeonTeleports.selectedPreset = 1
        MDungeonTeleports.rioScore = defaultSettings.rioScore
        MDungeonTeleports.realmName = defaultSettings.realmName
        MDungeonTeleports.dragHandle = defaultSettings.dragHandle
        MDungeonTeleports.lastVersionCheck = defaultSettings.lastVersionCheck

        local locale = GetLocale and GetLocale() or "enUS"
        if locale == "zhCN" then
            MDungeonTeleports.customFont = "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\sarasa.ttf"
            MDungeonTeleports.customFontName = "Sarasa"
        elseif locale == "koKR" then
            MDungeonTeleports.customFont = "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\wanted.ttf"
            MDungeonTeleports.customFontName = "Wanted"
        else
            MDungeonTeleports.customFont = "Interface\\AddOns\\MDungeonTeleports\\media\\fonts\\expressway.ttf"
            MDungeonTeleports.customFontName = "Expressway"
        end
        ReloadUI()
    end
)
--------------------------------------------------
-- MARK: External Links Frames
local links = {
    Discord = "https://discord.gg/5AtcdZ9t7Q",
    CurseForge = "https://www.curseforge.com/wow/addons/dungeonports",
    Wago = "https://addons.wago.io/addons/dungeonports"
}

local CopyFrame

local function CreateCloseButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(14, 14)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -5)
    btn:SetFrameStrata("DIALOG")

    local tex = btn:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(btn)
    tex:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_close.blp")

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(btn)
    highlight:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_close_highlight.blp")
    highlight:Hide()

    btn:SetScript("OnEnter", function(self)
        highlight:Show()
        tex:Hide()
    end)
    btn:SetScript("OnLeave", function(self)
        highlight:Hide()
        tex:Show()
    end)
    btn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
        parent:Hide()
        Settings:Show()
    end)

    return btn
end

local function ShowPopup(linkURL, linkName)
    if not CopyFrame then
        CopyFrame = CreateFrame("Frame", "CopyFrame", UIParent, "BackdropTemplate")
        CopyFrame:SetSize(350, 80)
        CopyFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
        CopyFrame:SetPoint("CENTER")
        CopyFrame:EnableMouse(true)
        CopyFrame:SetMovable(true)
        CopyFrame:RegisterForDrag("LeftButton")
        CopyFrame:SetScript("OnDragStart", CopyFrame.StartMoving)
        CopyFrame:SetScript("OnDragStop", CopyFrame.StopMovingOrSizing)
        CopyFrame:EnableKeyboard(true)
        CopyFrame:SetClampedToScreen(true)
        CopyFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then self:Hide() else self:SetPropagateKeyboardInput(true) end
        end)

        CopyFrame.title = CopyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        CopyFrame.title:SetPoint("TOP", CopyFrame, "TOP", 0, -10)
        CopyFrame.title:SetFont(defaultFont, 12, flags)
        CopyFrame.title:SetTextColor(0.2, 0.8, 0.9)

        CopyFrame.editBox = CreateFrame("EditBox", nil, CopyFrame, "InputBoxTemplate")
        CopyFrame.editBox:SetSize(310, 20)
        CopyFrame.editBox:SetPoint("TOP", CopyFrame, "TOP", 0, -40)
        CopyFrame.editBox:SetAutoFocus(false)
        CopyFrame.editBox:SetScript("OnEscapePressed", function() CopyFrame:Hide() end)
        CopyFrame.editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        CopyFrame.editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

        CreateCloseButton(CopyFrame)
    end

    CopyFrame.title:SetText(linkName)
    CopyFrame.editBox:SetText(linkURL)
    CopyFrame.editBox:HighlightText()
    CopyFrame:Show()
end

-- Button setup
local function CreateButton(name, texturePath, highlightTexturePath, linkURL, x, y)
    local button = CreateFrame("Button", name, Settings)
    button:SetSize(24, 24)
    button:SetPoint("BOTTOMRIGHT", Settings, "BOTTOMRIGHT", x, y)
    button:SetFrameStrata("DIALOG")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(button)
    icon:SetTexture(texturePath)

    local iconHighlight = button:CreateTexture(nil, "HIGHLIGHT")
    iconHighlight:SetAllPoints(button)
    iconHighlight:SetTexture(highlightTexturePath)
    iconHighlight:Hide()

    button:SetScript("OnEnter", function(self)
        iconHighlight:Show()
        icon:Hide()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(name, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        iconHighlight:Hide()
        icon:Show()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function() Settings:Hide() ShowPopup(linkURL, name) end)

    return button
end

local xOffset = {-6, -32, -58}
local i = 1
for name, url in pairs(links) do
    local texPath = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_"..name:lower()..".blp"
    local highlightPath = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_"..name:lower().."_highlight.blp"
    CreateButton(name, texPath, highlightPath, url, xOffset[i], 4)
    i = i + 1
end
-------------------------------------------------
-- MARK: Login Message
local loginmessage = CreateFrame("Frame")
loginmessage:RegisterEvent("PLAYER_LOGIN")
loginmessage:RegisterEvent("PLAYER_ENTERING_WORLD")
loginmessage:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if MDungeonTeleports.loginMessage then
            local today = date("%Y-%m-%d")
            if MDungeonTeleports.lastLogin ~= today then
                DEFAULT_CHAT_FRAME:AddMessage(L["LOGIN_MESSAGE_CHAT"], 0.8, 0.6, 1)
                MDungeonTeleports.lastLogin = today
            end
        end
    end
end)
-------------------------------------------------
-- MARK: Announce Teleport Spell Cast
local MDT_All = {}
local dungeonLists = {MDT_PL_TWW, MDT_PL_DF, MDT_PL_SL, MDT_PL_BFA, MDT_PL_Legion, MDT_PL_WOD, MDT_PL_MOP, MDT_PL_CATA, MDT_PLR_SL, MDT_PLR_DF, MDT_PLR_TWW}

for _, t in ipairs(dungeonLists) do
    for _, spell in ipairs(t) do
        MDT_All[spell.spellID] = spell.fullname
    end
end

local function AnnounceSpellCast(spellID)
    local spellName = MDT_All[spellID]
    if spellName and MDungeonTeleports.announcePort then
        SendChatMessage(L["TELEPORT_LOCATION_CHAT"] .. spellName .. "!", "PARTY")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if unit == "player" then
        AnnounceSpellCast(spellID)
    end
end)


-- verison check function (testing elvui like feature) maybe works through guild message on login checks if guild members have a newer version, if they do issue a out of date message.. hmm
local addonPrefix = "MDT_PEEPO"
C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix)

local addonMessageFrame = CreateFrame("Frame")
addonMessageFrame:RegisterEvent("CHAT_MSG_ADDON")
addonMessageFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix == addonPrefix and message == "VersionCheck" then
        local version = C_AddOns.GetAddOnMetadata("MDungeonTeleports", "Version")
        if channel == "GUILD" then
            C_ChatInfo.SendAddonMessage(addonPrefix, "VersionResponse:" .. version, "GUILD")
        else
            C_ChatInfo.SendAddonMessage(addonPrefix, "VersionResponse:" .. version, "PARTY")
        end
    end
end)

-------------------------------------------------
-- MARK: Version Check
local function SendVersionRequest()
    C_ChatInfo.SendAddonMessage("MDT_PEEPO", version, "GUILD")
end

local ignoredPlayers = {
    "Salora-Hellfire",
    "Malore-Hellfire",
    "Leliane-Hellfire",
    "Talanah-Hellfire"
}

local function ShouldIgnorePlayer(playerName)
    for _, ignoredPlayer in ipairs(ignoredPlayers) do
        if playerName == ignoredPlayer then
            return true
        end
    end
    return false
end

local function HandleVersionMessage(prefix, msg, channel, sender)
    if prefix == "MDT_PEEPO" then
        local theirVersion = msg
        local playerName = sender
        
        if not string.find(playerName, "-") then
            local realmName = GetRealmName()
            playerName = playerName .. "-" .. realmName
        end
        
        if ShouldIgnorePlayer(playerName) then
            return
        end
        
        if sender ~= UnitName("player") then
            local function parseVersion(ver)
                local major, minor, patch = string.match(ver, "(%d+)%.(%d+)%.(%d+)")
                return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
            end
            local myMajor, myMinor, myPatch = parseVersion(version)
            local theirMajor, theirMinor, theirPatch = parseVersion(theirVersion)
            if (theirMajor > myMajor) or
               (theirMajor == myMajor and theirMinor > myMinor) or
               (theirMajor == myMajor and theirMinor == myMinor and theirPatch > myPatch) then
                   local today = date("%Y-%m-%d")
                   if MDungeonTeleports.lastVersionCheck ~= today then
                       DEFAULT_CHAT_FRAME:AddMessage("|cFFB19CD9" .. L["MDT_UPDATE_MESSAGE"] .. theirVersion .. "|r")
                       MDungeonTeleports.lastVersionCheck = today
                   end
               end
           end
       end
   end
local versionCommFrame = CreateFrame("Frame")
versionCommFrame:RegisterEvent("PLAYER_LOGIN")
versionCommFrame:SetScript("OnEvent", function()
    SendVersionRequest()
end)

C_ChatInfo.RegisterAddonMessagePrefix("MDT_PEEPO")
versionCommFrame:RegisterEvent("CHAT_MSG_ADDON")
versionCommFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        SendVersionRequest()
    elseif event == "CHAT_MSG_ADDON" then
        HandleVersionMessage(...)
    end
end)