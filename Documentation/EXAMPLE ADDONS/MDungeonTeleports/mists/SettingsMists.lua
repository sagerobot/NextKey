-- MARK: Default Settings
local defaultSettings = {
    isChallengeFramePortalsShown = true,
}

-- Load Variables
if MDungeonTeleports == nil then
    MDungeonTeleports = {}
end

-- Assign Defaults
MDungeonTeleports.isChallengeFramePortalsShown =
    MDungeonTeleports.isChallengeFramePortalsShown ~= nil and MDungeonTeleports.isChallengeFramePortalsShown or
    defaultSettings.isChallengeFramePortalsShown

local function SaveSettings()
    if
        ChallengeFrameCheckBox
    then
        MDungeonTeleports.isChallengeFramePortalsShown = ChallengeFrameCheckBox:GetChecked()
        MDungeonTeleports.frameScale = uiScaleSlider:GetValue()
    end
end

-- MARK: Visibility Toggles
local function ToggleChallengeFramePortals(show)
    if ChallengeFrame_UpdateVisibility then
        ChallengeFrame_UpdateVisibility(show)
    end
    SaveSettings()
end

-- MARK: Scale Update
function UpdateFrameScale(scale)
    if ChallengeFrame then
        ChallengeFrame:SetScale(scale)
    end
    MDungeonTeleports.frameScale = scale
end

-- MARK: Settings Frame
local Settings = CreateFrame("Frame", "Settings", UIParent)
Settings:SetSize(420, 400)
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

-- backgroundSettings
local backgroundSettings = Settings:CreateTexture(nil, "BACKGROUND")
backgroundSettings:SetAllPoints(Settings)
backgroundSettings:SetTexture("Interface/AddOns/MDungeonTeleports/mists/ui_frames_mists.blp")
backgroundSettings:SetTexCoord(0.589843, 1, 0, 0.78125)

-- title
local SettingsTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SettingsTitle:SetPoint("TOP", Settings, "TOP", 0, -7)
SettingsTitle:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 12, flags)
SettingsTitle:SetText("Settings")

-- MARK: Section Titles
local SeasonTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
SeasonTitle:SetPoint("CENTER", Settings, "TOPLEFT", 92, -35)
SeasonTitle:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
SeasonTitle:SetTextColor(0.2, 0.8, 0.9)
SeasonTitle:SetText("Portal Window")

local UIScaleTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
UIScaleTitle:SetPoint("CENTER", Settings, "TOPLEFT", 92, -85)
UIScaleTitle:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
UIScaleTitle:SetTextColor(0.2, 0.8, 0.9)
UIScaleTitle:SetText("Window Sizing")

local ExtraTitle = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ExtraTitle:SetPoint("CENTER", Settings, "TOPLEFT", 92, -155)
ExtraTitle:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
ExtraTitle:SetTextColor(0.2, 0.8, 0.9)
ExtraTitle:SetText("Extra Features")

-- addon data and information
local AddonInfo = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
AddonInfo:SetPoint("BOTTOM", Settings, "BOTTOM", 0, 13)
AddonInfo:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 8, flags)
AddonInfo:SetText("M+ Dungeon Teleports - Challenge Mode by peepoStudy")
AddonInfo:SetTextColor(0.5, 0.5, 0.5)

-- MARK: Addon Usage
local AddonUsage1 = Settings:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
AddonUsage1:SetPoint("CENTER", Settings, "CENTER", 0, -154)
AddonUsage1:SetJustifyH("CENTER")
AddonUsage1:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
AddonUsage1:SetText(
    "• Customize your Challenge Mode frame with the Scale Slider, Toolips Toggle, Alternative|n Lock Icons for locked portals and stop them from moving around with the lock toggle."
)

-- MARK: Checkboxes
local textureCheckNormal = "Interface/AddOns/MDungeonTeleports/media/ui/ui_elements/checkbox.blp"
local textureCheckPushed = "Interface/AddOns/MDungeonTeleports/media/ui/ui_elements/checkbox_pushed.blp"
local textureCheckHighlight = "Interface/AddOns/MDungeonTeleports/media/ui/ui_elements/checkbox_highlight.blp"
local textureCheckChecked = "Interface/AddOns/MDungeonTeleports/media/ui/ui_elements/checkbox_checked.blp"

local function CreateCheckboxes()
    ChallengeFrameCheckBox = CreateFrame("CheckButton", nil, Settings, "ChatConfigCheckButtonTemplate")
    ChallengeFrameCheckBox:SetPoint("CENTER", Settings, "TOPLEFT", 29, -60)
    local font, _, flags = ChallengeFrameCheckBox.Text:GetFont()
    ChallengeFrameCheckBox.Text:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
    ChallengeFrameCheckBox.Text:SetPoint("LEFT", ChallengeFrameCheckBox, "RIGHT", 0, 0)
    ChallengeFrameCheckBox.Text:SetText("Show MoP Portals")
    ChallengeFrameCheckBox:SetChecked(MDungeonTeleports.isChallengeFramePortalsShown)
    ChallengeFrameCheckBox:SetScript(
        "OnClick",
        function(self)
            ToggleChallengeFramePortals(self:GetChecked())
        end
    )

    ChallengeFrameCheckBox:SetNormalTexture(textureCheckNormal)
    ChallengeFrameCheckBox:SetPushedTexture(textureCheckPushed)
    ChallengeFrameCheckBox:SetHighlightTexture(textureCheckHighlight)
    ChallengeFrameCheckBox:SetCheckedTexture(textureCheckChecked)

    -- tooltips
    ToggleTooltips = CreateFrame("CheckButton", nil, Settings, "ChatConfigCheckButtonTemplate")
    ToggleTooltips:SetPoint("CENTER", Settings, "TOPLEFT", 29, -180)
    local font, _, flags = ToggleTooltips.Text:GetFont()
    ToggleTooltips.Text:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
    ToggleTooltips.Text:SetPoint("LEFT", ToggleTooltips, "RIGHT", 0, 0)
    ToggleTooltips.Text:SetText("Tooltips")
    ToggleTooltips:SetChecked(MDungeonTeleports.showTooltips)
    ToggleTooltips:SetScript(
        "OnClick",
        function(self)
            MDungeonTeleports.showTooltips = self:GetChecked()
        end
    )

    ToggleTooltips:SetNormalTexture(textureCheckNormal)
    ToggleTooltips:SetPushedTexture(textureCheckPushed)
    ToggleTooltips:SetHighlightTexture(textureCheckHighlight)
    ToggleTooltips:SetCheckedTexture(textureCheckChecked)

    -- altlockbox
    AltLocksBox = CreateFrame("CheckButton", nil, Settings, "ChatConfigCheckButtonTemplate")
    AltLocksBox:SetPoint("CENTER", Settings, "TOPLEFT", 29, -200)
    local font, _, flags = AltLocksBox.Text:GetFont()
    AltLocksBox.Text:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
    AltLocksBox.Text:SetPoint("LEFT", AltLocksBox, "RIGHT", 0, 0)
    AltLocksBox.Text:SetText("Alternative Lock Icons")
    AltLocksBox:SetChecked(MDungeonTeleports.AltLocks)
    AltLocksBox:SetScript(
        "OnClick",
        function(self)
            MDungeonTeleports.AltLocks = self:GetChecked()
            if UpdateChallengeFrameUI then
                UpdateChallengeFrameUI()
            end
        end
    )

    AltLocksBox:SetNormalTexture(textureCheckNormal)
    AltLocksBox:SetPushedTexture(textureCheckPushed)
    AltLocksBox:SetHighlightTexture(textureCheckHighlight)
    AltLocksBox:SetCheckedTexture(textureCheckChecked)

    -- Shift Movement Toggle
    ShiftMoveCheckBox = CreateFrame("CheckButton", nil, Settings, "ChatConfigCheckButtonTemplate")
    ShiftMoveCheckBox:SetPoint("CENTER", Settings, "TOPLEFT", 29, -220)
    local font, _, flags = ShiftMoveCheckBox.Text:GetFont()
    ShiftMoveCheckBox.Text:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
    ShiftMoveCheckBox.Text:SetPoint("LEFT", ShiftMoveCheckBox, "RIGHT", 0, 0)
    ShiftMoveCheckBox.Text:SetText("Shift Lock Frames")
    ShiftMoveCheckBox:SetChecked(MDungeonTeleports.ShiftDragToggle)
    ShiftMoveCheckBox:SetScript(
        "OnClick",
        function(self)
            MDungeonTeleports.ShiftDragToggle = self:GetChecked()
            if ShiftMoveCheckBox then
                if ShiftDragToggleChallengeFrame then
                    ShiftDragToggleChallengeFrame()
                end
            end
        end
    )

    ShiftMoveCheckBox:SetNormalTexture(textureCheckNormal)
    ShiftMoveCheckBox:SetPushedTexture(textureCheckPushed)
    ShiftMoveCheckBox:SetHighlightTexture(textureCheckHighlight)
    ShiftMoveCheckBox:SetCheckedTexture(textureCheckChecked)
end

CreateCheckboxes()

-- MARK: UI Slider
local uiScaleSlider = CreateFrame("Slider", "uiScaleSlider", Settings, "OptionsSliderTemplate")
uiScaleSlider:SetPoint("CENTER", Settings, "TOPLEFT", 92, -123)
uiScaleSlider:SetMinMaxValues(0.8, 1.2)
uiScaleSlider:SetValue(MDungeonTeleports.scaleSliderValue or 50)
uiScaleSlider:SetValueStep(0.1)
uiScaleSlider:SetWidth(135)

-- minimum label
local minLabel = _G[uiScaleSlider:GetName() .. "Low"]
minLabel:SetText("-20%")
minLabel:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
-- maximum label
local maxLabel = _G[uiScaleSlider:GetName() .. "High"]
maxLabel:SetText("+20%")
maxLabel:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
-- text label for the slider
local textLabel = _G[uiScaleSlider:GetName() .. "Text"]
textLabel:SetText("Scale Slider")
textLabel:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 10, flags)
-- OnValueChanged handler for the slider
uiScaleSlider:SetScript(
    "OnValueChanged",
    function(self, value)
        -- Round to one decimal place
        local scale = math.floor(value * 10 + 0.5) / 10
        -- Update the scale globally
        UpdateFrameScale(scale)
    end
)

uiScaleSlider:SetValue(MDungeonTeleports.frameScale or 1.0)

-- Update the UI with the current settings
local function UpdateUI()
    if
        ChallengeFrameCheckBox
     then
        ChallengeFrameCheckBox:SetChecked(MDungeonTeleports.isChallengeFramePortalsShown)
        ToggleChallengeFramePortals(MDungeonTeleports.isChallengeFramePortalsShown)
    end
    if ToggleTooltips then
        ToggleTooltips:SetChecked(MDungeonTeleports.showTooltips)
    end
    if AltLocksBox then
        AltLocksBox:SetChecked(MDungeonTeleports.AltLocks)
    end
    if ShiftMoveCheckBox then 
        ShiftMoveCheckBox:SetChecked(MDungeonTeleports.ShiftDragToggle)
    end
end

-- MARK: Reset Button
local resetButton = CreateFrame("Button", "ResetButton", Settings)
resetButton:SetSize(24, 24)
resetButton:SetPoint("BOTTOMLEFT", Settings, "BOTTOMLEFT", 4, 4)
resetButton:SetFrameStrata("DIALOG")

local resetButtonTexture = resetButton:CreateTexture(nil, "BACKGROUND")
resetButtonTexture:SetAllPoints(resetButton)
resetButtonTexture:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_reset.blp")

local resetButtonHighlight = resetButton:CreateTexture(nil, "HIGHLIGHT")
resetButtonHighlight:SetAllPoints(resetButton)
resetButtonHighlight:SetTexture(
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_reset_highlight.blp"
)
resetButtonHighlight:Hide()

resetButton.resetButtonHighlight = resetButtonHighlight
resetButton.resetButtonTexture = resetButtonTexture

resetButton:SetScript(
    "OnEnter",
    function(self)
        self.resetButtonHighlight:Show()
        self.resetButtonTexture:Hide()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reset Addon UI", 1, 1, 1)
        GameTooltip:AddLine("Reset your AddOn.", nil, nil, nil, true)
        GameTooltip:AddLine("This will reload your UI", nil, nil, nil, true)
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

-- MARK: Reset Script

resetButton:SetScript(
    "OnClick",
    function(self)
        MDungeonTeleports.ChallengeFramePos = {x = 1005, y = -19}
        MDungeonTeleports.frameScale = 1
        MDungeonTeleports.isChallengeFramePortalsShown = true
        MDungeonTeleports.showTooltips = false
        MDungeonTeleports.AltLocks = false
        MDungeonTeleports.ShiftDragToggle = false
        ReloadUI()
    end
)

-- MARK: Settings Exit Button
local settingsExitButton = CreateFrame("Button", "SettingsOpenButton", Settings)
settingsExitButton:SetSize(14, 14)
settingsExitButton:SetPoint("TOPRIGHT", Settings, "TOPRIGHT", -5, -5)
settingsExitButton:SetFrameStrata("DIALOG")

local settingExitButtonTexture = settingsExitButton:CreateTexture(nil, "BACKGROUND")
settingExitButtonTexture:SetAllPoints(settingsExitButton)
settingExitButtonTexture:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_close.blp")

local settingsExitButtonHighlight = settingsExitButton:CreateTexture(nil, "HIGHLIGHT")
settingsExitButtonHighlight:SetAllPoints(settingsExitButton)
settingsExitButtonHighlight:SetTexture(
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_close_highlight.blp"
)
settingsExitButtonHighlight:Hide()

settingsExitButton.settingsExitButtonHighlight = settingsExitButtonHighlight
settingsExitButton.settingExitButtonTexture = settingExitButtonTexture

settingsExitButton:SetScript(
    "OnEnter",
    function(self)
        self.settingsExitButtonHighlight:Show()
        self.settingExitButtonTexture:Hide()
    end
)

settingsExitButton:SetScript(
    "OnLeave",
    function(self)
        self.settingsExitButtonHighlight:Hide()
        self.settingExitButtonTexture:Show()
    end
)

settingsExitButton:SetScript(
    "OnClick",
    function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
        Settings:Hide()
    end
)

-- Ensure compatibility with both the new and old API versions
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

-- MARK: PVE Settings Button
local settingsOpenButton = CreateFrame("Button", "SettingsOpenButton", PVEFrame)

-- Check if ElvUI is loaded
local isElvUILoaded = IsAddOnLoaded("ElvUI")

-- Set button size based on whether ElvUI is loaded
if isElvUILoaded then
    settingsOpenButton:SetSize(14, 14) -- Size for ElvUI
    settingsOpenButton:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", -22, -5)
else
    settingsOpenButton:SetSize(21, 21) -- Default size if ElvUI is not loaded
    settingsOpenButton:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", -22, -1)
end

settingsOpenButton:SetFrameStrata("DIALOG")

-- Define textures
local defaultTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_elements\\settings_buttons.blp"
local elvuiTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_settings.blp"

-- Non-ElvUI texture coordinates provided
local defaultNormalCoords = {0.054687, 0.304687, 0.046875, 0.296875} -- Normal state
local defaultHighlightCoords = {0.351562, 0.601562, 0.046875, 0.296875} -- Highlight state
local defaultPressedCoords = {0.054687, 0.304687, 0.3828125, 0.632812} -- Pressed state

-- ElvUI texture paths (these will use the full texture for each state)
local elvuiHighlightTexture =
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_settings_highlight.blp"
local elvuiPressedTexture = "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_settings_pressed.blp"

-- Set main texture
local settingsOpenButtonTexture = settingsOpenButton:CreateTexture(nil, "BACKGROUND")
settingsOpenButtonTexture:SetAllPoints(settingsOpenButton)
settingsOpenButtonTexture:SetTexture(isElvUILoaded and elvuiTexture or defaultTexture)

-- Apply texture coordinates based on ElvUI status
if not isElvUILoaded then
    settingsOpenButtonTexture:SetTexCoord(unpack(defaultNormalCoords))
end

-- Set up highlight texture
local settingsButtonHoverOverlay = settingsOpenButton:CreateTexture(nil, "HIGHLIGHT")
settingsButtonHoverOverlay:SetAllPoints(settingsOpenButton)
settingsButtonHoverOverlay:SetTexture(isElvUILoaded and elvuiHighlightTexture or defaultTexture)
settingsButtonHoverOverlay:Hide()

if not isElvUILoaded then
    settingsButtonHoverOverlay:SetTexCoord(unpack(defaultHighlightCoords))
end

-- Define the pressed texture
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

-- Tooltip and interaction scripts
settingsOpenButton:SetScript(
    "OnEnter",
    function(self)
        self.settingsButtonHoverOverlay:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("M+ Dungeon Teleports", 1, 1, 1)
        GameTooltip:AddLine("Open the Settings.", nil, nil, nil, true)
        if InCombatLockdown() then
            GameTooltip:AddLine("|cFFFF0000Unavailable during combat!|r", nil, nil, nil, true)
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
            print("|cFFFF0000Settings cannot be opened during combat!|r")
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

-- Disable the button during combat
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

--------------

function ToggleSettingsPanel()
    if InCombatLockdown() then
        print("|cFFFF0000Settings cannot be opened during combat!|r")
        return
    end

    if Settings:IsShown() then
        Settings:Hide()
    else
        Settings:Show()
    end
end

-- MARK: Slash Command '/dp'
SLASH_DPTOGGLE1 = "/dp"
SlashCmdList["DPTOGGLE"] = function()
    ToggleSettingsPanel()
end

local discordURL = "https://discord.gg/5AtcdZ9t7Q"
local curseforgeURL = "https://www.curseforge.com/wow/addons/dungeonports"
local wagoURL = "https://addons.wago.io/addons/dungeonports"

local CopyFrame

local function ShowPopup(linkURL, linkName)
    if CopyFrame then
        CopyFrame:Hide()
    end

    if Settings and Settings:IsShown() then
        Settings:Hide()
    end

    -- Create new frame
    CopyFrame = CreateFrame("Frame", "CopyFrame", UIParent, "BackdropTemplate")
    CopyFrame:SetSize(350, 80)
    CopyFrame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
    CopyFrame:SetPoint("CENTER")
    CopyFrame:EnableMouse(true)
    CopyFrame:SetMovable(true)
    CopyFrame:RegisterForDrag("LeftButton")
    CopyFrame:SetScript(
        "OnDragStart",
        function(self)
            self:StartMoving()
        end
    )
    CopyFrame:SetScript(
        "OnDragStop",
        function(self)
            self:StopMovingOrSizing()
        end
    )
    CopyFrame:EnableKeyboard(true)
    CopyFrame:SetClampedToScreen(true)
    CopyFrame:SetScript(
        "OnKeyDown",
        function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end
    )

    local poptitle = CopyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    poptitle:SetPoint("TOP", CopyFrame, "TOP", 0, -10)
    poptitle:SetFont("Interface/AddOns/MDungeonTeleports/media/fonts/expressway.ttf", 12, flags)
    poptitle:SetTextColor(0.2, 0.8, 0.9)
    poptitle:SetText(linkName)

    local editBox = CreateFrame("EditBox", nil, CopyFrame, "InputBoxTemplate")
    editBox:SetSize(310, 20)
    editBox:SetPoint("TOP", CopyFrame, "TOP", 0, -40)
    editBox:SetAutoFocus(false)
    editBox:SetText(linkURL)
    editBox:HighlightText()

    editBox:SetScript(
        "OnEscapePressed",
        function()
            CopyFrame:Hide()
        end
    )
    editBox:SetScript(
        "OnEnterPressed",
        function()
            editBox:ClearFocus()
        end
    )
    editBox:SetScript(
        "OnEditFocusGained",
        function(self)
            self:HighlightText()
        end
    )

    -- MARK: CopyFrame Exit Button
    local copyframeexitbutton = CreateFrame("Button", "SettingsOpenButton", CopyFrame)
    copyframeexitbutton:SetSize(14, 14)
    copyframeexitbutton:SetPoint("TOPRIGHT", CopyFrame, "TOPRIGHT", -5, -5)
    copyframeexitbutton:SetFrameStrata("DIALOG")

    local copyframeexit = copyframeexitbutton:CreateTexture(nil, "BACKGROUND")
    copyframeexit:SetAllPoints(copyframeexitbutton)
    copyframeexit:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_close.blp")

    local copyframeexithighlight = copyframeexitbutton:CreateTexture(nil, "HIGHLIGHT")
    copyframeexithighlight:SetAllPoints(copyframeexitbutton)
    copyframeexithighlight:SetTexture("Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_default\\button_close_highlight.blp")
    copyframeexithighlight:Hide()

    copyframeexitbutton.copyframeexithighlight = copyframeexithighlight
    copyframeexitbutton.copyframeexit = copyframeexit

    copyframeexitbutton:SetScript(
        "OnEnter",
        function(self)
            self.copyframeexithighlight:Show()
            self.copyframeexit:Hide()
        end
    )

    copyframeexitbutton:SetScript(
        "OnLeave",
        function(self)
            self.copyframeexithighlight:Hide()
            self.copyframeexit:Show()
        end
    )

    copyframeexitbutton:SetScript(
        "OnClick",
        function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
            CopyFrame:Hide()
        end
    )

    CopyFrame:Show()
end

-- Setup Button
local function CreateButton(name, texturePath, highlightTexturePath, linkURL, x, y)
    local button = CreateFrame("Button", name, Settings)
    button:SetSize(24, 24)
    button:SetPoint("BOTTOMRIGHT", Settings, "BOTTOMRIGHT", x, y)
    button:SetFrameStrata("DIALOG")

    local buttonIcon = button:CreateTexture(nil, "BACKGROUND")
    buttonIcon:SetAllPoints(button)
    buttonIcon:SetTexture(texturePath)

    local buttonIconHighlight = button:CreateTexture(nil, "HIGHLIGHT")
    buttonIconHighlight:SetAllPoints(button)
    buttonIconHighlight:SetTexture(highlightTexturePath)
    buttonIconHighlight:Hide()

    button:SetScript(
        "OnEnter",
        function(self)
            buttonIconHighlight:Show()
            buttonIcon:Hide()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(name, 1, 1, 1)
            GameTooltip:Show()
        end
    )

    button:SetScript(
        "OnLeave",
        function(self)
            buttonIconHighlight:Hide()
            buttonIcon:Show()
            GameTooltip:Hide()
        end
    )

    button:SetScript(
        "OnClick",
        function()
            ShowPopup(linkURL, name)
        end
    )

    return button
end

-- Create Buttons
local DiscordButton =
    CreateButton(
    "Discord",
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_external\\button_discord.blp",
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_external\\button_discord_highlight.blp",
    discordURL,
    -4,
    4
)
local CurseForgeButton =
    CreateButton(
    "CurseForge",
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_external\\button_curseforge.blp",
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_external\\button_curseforge_highlight.blp",
    curseforgeURL,
    -30,
    4
)
local WagoButton =
    CreateButton(
    "Wago",
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_external\\button_wago.blp",
    "Interface\\AddOns\\MDungeonTeleports\\media\\ui\\ui_external\\button_wago_highlight.blp",
    wagoURL,
    -56,
    4
)

-- MARK: End of Settings.

--//////////////////////////////////////////////////////////////////////--

-- MARK: AddOn Load Event
local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MDungeonTeleports" then
        local VarVersionScale = 1
        if MDungeonTeleports.VarVersionScale == nil or MDungeonTeleports.VarVersionScale < VarVersionScale then
            MDungeonTeleports.VarVersionScale = VarVersionScale
            MDungeonTeleports.frameScale = 1
        end
        local savedScale = MDungeonTeleports.frameScale or 1.0
        uiScaleSlider:SetValue(savedScale)
        UpdateFrameScale(savedScale)
        UpdateUI()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)