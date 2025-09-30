local ADDON_NAME, NS = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
local AceGUI = LibStub("AceGUI-3.0")

local addonName = "MDungeonTeleports"
local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Unknown"

-- Version Check
function VersionCheck()
   local currentVersion = 50100
    if not MDungeonTeleports then
        MDungeonTeleports = {}
    end

    if MDungeonTeleports.Version == nil or MDungeonTeleports.Version > currentVersion then
        MDungeonTeleports.Version = currentVersion
        LaunchFeatureWindow()
        return
    end

    if MDungeonTeleports.Version < currentVersion then
        MDungeonTeleports.Version = currentVersion
        LaunchFeatureWindow()
        return
    end
end

-- font set
local defaultFont = "Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf"

local function FontSet()
    if GetLocale() == "zhCN" or GetLocale() == "koKR" then
        defaultFont = GameFontNormal:GetFont()
    else
        defaultFont = "Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf"
    end
end

FontSet()

-- MARK: First Launch Frame
local FeatureWindow = CreateFrame("Frame", "FeatureWindow", UIParent)
FeatureWindow:SetSize(410, 210)
FeatureWindow:SetPoint("CENTER")
FeatureWindow:SetMovable(true)
FeatureWindow:EnableMouse(true)
FeatureWindow:RegisterForDrag("LeftButton")
FeatureWindow:SetScript("OnDragStart", FeatureWindow.StartMoving)
FeatureWindow:SetScript("OnDragStop", FeatureWindow.StopMovingOrSizing)
FeatureWindow:SetFrameStrata("DIALOG")
FeatureWindow:Hide()
FeatureWindow:EnableKeyboard(true)
FeatureWindow:SetClampedToScreen(true)
FeatureWindow:SetScale(1.3)

-- Feature Window Visuals
local FeatureWindowBackdrop = FeatureWindow:CreateTexture(nil, "BACKGROUND")
FeatureWindowBackdrop:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\feature.blp")
FeatureWindowBackdrop:SetTexCoord(0, 0.800781, 0, 0.820312)
FeatureWindowBackdrop:SetAllPoints(FeatureWindow)

local borderColor = {0, 0, 0, 0.6}
local borderThickness = 3

local borderTop = FeatureWindow:CreateTexture(nil, "OVERLAY")
borderTop:SetColorTexture(unpack(borderColor))
borderTop:SetPoint("TOPLEFT", FeatureWindow, "TOPLEFT", 0, 0)
borderTop:SetPoint("TOPRIGHT", FeatureWindow, "TOPRIGHT", 0, 0)
borderTop:SetHeight(borderThickness)

local borderBottom = FeatureWindow:CreateTexture(nil, "OVERLAY")
borderBottom:SetColorTexture(unpack(borderColor))
borderBottom:SetPoint("BOTTOMLEFT", FeatureWindow, "BOTTOMLEFT", 0, 0)
borderBottom:SetPoint("BOTTOMRIGHT", FeatureWindow, "BOTTOMRIGHT", 0, 0)
borderBottom:SetHeight(borderThickness)

local borderLeft = FeatureWindow:CreateTexture(nil, "OVERLAY")
borderLeft:SetColorTexture(unpack(borderColor))
borderLeft:SetPoint("TOPLEFT", FeatureWindow, "TOPLEFT", 0, 0)
borderLeft:SetPoint("BOTTOMLEFT", FeatureWindow, "BOTTOMLEFT", 0, 0)
borderLeft:SetWidth(borderThickness)

local borderRight = FeatureWindow:CreateTexture(nil, "OVERLAY")
borderRight:SetColorTexture(unpack(borderColor))
borderRight:SetPoint("TOPRIGHT", FeatureWindow, "TOPRIGHT", 0, 0)
borderRight:SetPoint("BOTTOMRIGHT", FeatureWindow, "BOTTOMRIGHT", 0, 0)
borderRight:SetWidth(borderThickness)
--------------------------------------------
-- MARK: Titles
local FeatureTitle = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle:SetPoint("TOP", FeatureWindow, "TOP", -108, -10)
FeatureTitle:SetFont(defaultFont, 15, nil)
FeatureTitle:SetTextColor(1, 1, 1)
FeatureTitle:SetText(L["FEATURE_TITLE"])

local FeatureTitle2 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle2:SetPoint("TOP", FeatureWindow, "TOP", -108, -24)
FeatureTitle2:SetFont(defaultFont, 8, nil)
FeatureTitle2:SetTextColor(1, 1, 1)
FeatureTitle2:SetText(L["VER_TITLE"] ..version.."?")

local FeatureTitle3 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle3:SetPoint("TOP", FeatureWindow, "TOP", -104, -48)
FeatureTitle3:SetFont(defaultFont, 14, nil)
FeatureTitle3:SetJustifyH("LEFT")
FeatureTitle3:SetTextColor(1, 1, 1)
FeatureTitle3:SetText(L["FEATURE_1"])

local FeatureTitle4 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle4:SetPoint("TOP", FeatureWindow, "TOP", -90, -62)
FeatureTitle4:SetFont(defaultFont, 8, nil)
FeatureTitle4:SetJustifyH("LEFT")
FeatureTitle4:SetTextColor(1, 1, 1)
FeatureTitle4:SetText(L["FEATURE_DESC_1"])

local FeatureTitle5 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle5:SetPoint("TOP", FeatureWindow, "TOP", -91, -100)
FeatureTitle5:SetFont(defaultFont, 14, nil)
FeatureTitle5:SetJustifyH("LEFT")
FeatureTitle5:SetTextColor(1, 1, 1)
FeatureTitle5:SetText(L["FEATURE_2"])

local FeatureTitle6 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle6:SetPoint("TOP", FeatureWindow, "TOP", -95, -114)
FeatureTitle6:SetFont(defaultFont, 8, nil)
FeatureTitle6:SetJustifyH("LEFT")
FeatureTitle6:SetTextColor(1, 1, 1)
FeatureTitle6:SetText(L["FEATURE_DESC_2"])

local FeatureTitle7 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle7:SetPoint("TOP", FeatureWindow, "TOP", -91, -150)
FeatureTitle7:SetFont(defaultFont, 14, nil)
FeatureTitle7:SetJustifyH("LEFT")
FeatureTitle7:SetTextColor(1, 1, 1)
FeatureTitle7:SetText(L["FEATURE_3"])

local FeatureTitle8 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle8:SetPoint("TOP", FeatureWindow, "TOP", -92, -164)
FeatureTitle8:SetFont(defaultFont, 8, nil)
FeatureTitle8:SetJustifyH("LEFT")
FeatureTitle8:SetTextColor(1, 1, 1)
FeatureTitle8:SetText(L["FEATURE_DESC_3"])

local FeatureTitle9 = FeatureWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
FeatureTitle9:SetPoint("TOP", FeatureWindow, "TOP", -105, -195)
FeatureTitle9:SetFont(defaultFont, 8, nil)
FeatureTitle9:SetTextColor(1, 1, 1)
FeatureTitle9:SetText(L["MORE_UPDATES"])
--------------------------------------------
-- MARK: FeatureWindow Close Button
local closeButtonContainer = AceGUI:Create("SimpleGroup")
closeButtonContainer:SetLayout("Flow")
closeButtonContainer:SetWidth(70)
closeButtonContainer:SetHeight(32)
closeButtonContainer.frame:SetParent(FeatureWindow)
closeButtonContainer.frame:SetPoint("BOTTOMRIGHT", FeatureWindow, "BOTTOMRIGHT", -7, -5)
closeButtonContainer.frame:Show()

local aceCloseButton = AceGUI:Create("Button")
aceCloseButton:SetText("Close")
aceCloseButton:SetWidth(90)
aceCloseButton.frame:SetScale(0.6)
aceCloseButton:SetCallback("OnClick", function()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

    if KeyTrackerFrame then
        KeyTrackerFrame:ClearAllPoints()
        KeyTrackerFrame:SetPoint("TOPRIGHT", PVEFrame, "TOPLEFT", 971, -429)
        KeyTrackerFrame:Show()
    end

    MDungeonTeleports.KeyTrackerPos = {x = 971, y = -429}
    MDungeonTeleports.isKeyFrameShown = true

    FeatureWindow:Hide()
end)

closeButtonContainer:AddChild(aceCloseButton)
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
        FeatureWindow:Show()
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
    local button = CreateFrame("Button", name, FeatureWindow)
    button:SetSize(24, 24)
    button:SetPoint("BOTTOMRIGHT", FeatureWindow, "BOTTOMRIGHT", x, y)
    button:SetFrameStrata("DIALOG")
    button:SetScale(0.7)

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
    button:SetScript("OnClick", function() FeatureWindow:Hide() ShowPopup(linkURL, name) end)

    return button
end

local xOffset = {-24, -50, -76}
local i = 1
for name, url in pairs(links) do
    local texPath = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_"..name:lower()..".blp"
    local highlightPath = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\button_"..name:lower().."_highlight.blp"
    CreateButton(name, texPath, highlightPath, url, xOffset[i], 32)
    i = i + 1
end
--------------------------------------------
-- MARK: Launch Feature Window
function LaunchFeatureWindow()
   FeatureWindow:Show()
end

local launchFrame = CreateFrame("Frame")
launchFrame:RegisterEvent("ADDON_LOADED")
launchFrame:RegisterEvent("PLAYER_LOGIN")
launchFrame:SetScript(
   "OnEvent",
   function(self, event, arg1)
      if event == "ADDON_LOADED" then
         if arg1 == "MDungeonTeleports" then
            C_Timer.After(2, function() 
               VersionCheck() 
            end)
         end
      elseif event == "PLAYER_LOGIN" then
         C_Timer.After(2, function() 
            VersionCheck() 
         end)
      end
   end
)

