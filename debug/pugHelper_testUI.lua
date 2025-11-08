--[[
NextKey PUG Helper Test UI
Interactive testing interface for PUG Helper workflows
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGHelperTestUI = {}
NextKey222.PUGHelperTestUI = PUGHelperTestUI

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Private Variables
local testFrame = nil
local selectedDungeonID = 499 -- Default: Priory of the Sacred Flame
local simulatedGroupType = nil -- nil = use real detection, or "PUG"/"GUILD"/"PREMADE"/"SOLO"

-- TWW Season 3 Dungeons
local TEST_DUNGEONS = {
    { id = 499, name = "Priory of the Sacred Flame", activityID = 1281 },
    { id = 505, name = "The Dawnbreaker", activityID = 1285 },
    { id = 542, name = "Eco-Dome Aldani", activityID = 1694 },
    { id = 391, name = "Tazavesh: Streets", activityID = 1016 },
    { id = 503, name = "Ara-Kara, City of Echoes", activityID = 1284 },
    { id = 392, name = "Tazavesh: Gambit", activityID = 1017 },
    { id = 525, name = "Operation: Floodgate", activityID = 1550 },
    { id = 378, name = "Halls of Atonement", activityID = 699 },
}

-- MARK: Module Registration
NextKey222.RegisterModule("PUGHelperTestUI", PUGHelperTestUI)

-- MARK: Public Interface

function PUGHelperTestUI:Initialize()
    Debug:Dev("pughelper", "PUGHelperTestUI:Initialize() called")
    return true
end

function PUGHelperTestUI:Show()
    if not testFrame then
        self:CreateFrame()
    end
    
    if testFrame then
        testFrame:Show()
        Debug:Dev("pughelper", "PUG Helper Test UI shown")
    end
end

function PUGHelperTestUI:Hide()
    if testFrame then
        testFrame:Hide()
    end
end

function PUGHelperTestUI:Toggle()
    if testFrame and testFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- MARK: Private Implementation

function PUGHelperTestUI:CreateFrame()
    local UIComponents = NextKey222.UIComponents
    if not UIComponents then
        Debug:Error("PUGHelperTestUI:CreateFrame() - UIComponents not available")
        return
    end
    
    -- Main frame
    local main = CreateFrame("Frame", "NextKey_PUGHelperTestUI", UIParent, "BackdropTemplate")
    main:SetSize(340, 540)
    main:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
    main:SetFrameStrata("DIALOG")
    main:SetFrameLevel(100)
    main:SetMovable(true)
    main:EnableMouse(true)
    main:RegisterForDrag("LeftButton")
    main:SetScript("OnDragStart", function(self) self:StartMoving() end)
    main:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Backdrop
    if UIComponents.ConfigureBackdrop then
        UIComponents:ConfigureBackdrop(main, "dialog", { colorScheme = "dark" })
    else
        main:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
    end
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, main, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", main, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() self:Hide() end)
    
    -- Title
    local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", main, "TOP", 0, -18)
    title:SetText("PUG Helper Test UI")
    
    local y = -50
    
    -- Dungeon dropdown
    local dungeonLabel = main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dungeonLabel:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    dungeonLabel:SetText("Select Dungeon:")
    
    y = y - 25
    local dungeonDropdown = CreateFrame("Frame", "NextKey_PUGTestDungeonDropdown", main, "UIDropDownMenuTemplate")
    dungeonDropdown:SetPoint("TOPLEFT", main, "TOPLEFT", 10, y)
    
    UIDropDownMenu_SetWidth(dungeonDropdown, 280)
    UIDropDownMenu_SetText(dungeonDropdown, TEST_DUNGEONS[1].name)
    
    UIDropDownMenu_Initialize(dungeonDropdown, function(self, level)
        for i, dungeon in ipairs(TEST_DUNGEONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = dungeon.name
            info.value = dungeon.id
            info.func = function()
                selectedDungeonID = dungeon.id
                UIDropDownMenu_SetText(dungeonDropdown, dungeon.name)
                Debug:Dev("pughelper", "Selected dungeon: " .. dungeon.name .. " (ID: " .. dungeon.id .. ")")
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    y = y - 40
    
    -- Section: Event Simulation
    local eventSection = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    eventSection:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    eventSection:SetText("Event Simulation")
    
    y = y - 30
    
    -- Button: Simulate Accept
    local acceptButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    acceptButton:SetSize(300, 30)
    acceptButton:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    acceptButton:SetText("Simulate: Get Accepted to Group")
    acceptButton:SetScript("OnClick", function()
        self:SimulateGroupAccept()
    end)
    
    y = y - 40
    
    -- Button: Simulate Dungeon Complete
    local completeButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    completeButton:SetSize(300, 30)
    completeButton:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    completeButton:SetText("Simulate: Dungeon Complete")
    completeButton:SetScript("OnClick", function()
        self:SimulateDungeonComplete()
    end)
    
    y = y - 50
    
    -- Section: UI Testing
    local uiSection = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    uiSection:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    uiSection:SetText("UI Testing")
    
    y = y - 30
    
    -- Button: Show Teleport (PUG)
    local teleportPUGButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    teleportPUGButton:SetSize(300, 30)
    teleportPUGButton:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    teleportPUGButton:SetText("Show Teleport Window (PUG Mode)")
    teleportPUGButton:SetScript("OnClick", function()
        self:ShowTeleportWindow("PUG")
    end)
    
    y = y - 40
    
    -- Button: Show Teleport (Guild)
    local teleportGuildButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    teleportGuildButton:SetSize(300, 30)
    teleportGuildButton:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    teleportGuildButton:SetText("Show Teleport Window (Guild Mode)")
    teleportGuildButton:SetScript("OnClick", function()
        self:ShowTeleportWindow("GUILD")
    end)
    
    y = y - 40
    
    -- Button: Show Teleport with Leave Group (dungeon complete simulation)
    local leaveGroupButton = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    leaveGroupButton:SetSize(300, 30)
    leaveGroupButton:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    leaveGroupButton:SetText("Show Teleport + Leave Group (PUG)")
    leaveGroupButton:SetScript("OnClick", function()
        self:ShowTeleportWindow("PUG", true)  -- true = dungeonComplete
    end)
    
    y = y - 50
    
    -- Section: Detection Info
    local detectionSection = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    detectionSection:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    detectionSection:SetText("Group Detection")
    
    y = y - 25
    
    -- Detection info text
    local detectionInfo = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detectionInfo:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    detectionInfo:SetWidth(300)
    detectionInfo:SetJustifyH("LEFT")
    detectionInfo:SetText("PUG: Active LFG entry or tracked\nGuild: Majority guild members\nPremade: Manual invites/friends")
    
    y = y - 50
    
    -- Current group type display
    local currentGroupLabel = main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentGroupLabel:SetPoint("TOPLEFT", main, "TOPLEFT", 20, y)
    currentGroupLabel:SetText("Current Group:")
    
    y = y - 20
    local currentGroupText = main:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    currentGroupText:SetPoint("TOPLEFT", main, "TOPLEFT", 30, y)
    currentGroupText:SetWidth(280)
    currentGroupText:SetJustifyH("LEFT")
    currentGroupText:SetText("Not in a group")
    
    -- Update function
    local function UpdateGroupTypeDisplay()
        if NextKey222.PUGHelper and NextKey222.PUGHelper.GetGroupTypeInfo then
            local groupInfo = NextKey222.PUGHelper:GetGroupTypeInfo()
            local color = groupInfo.color
            currentGroupText:SetTextColor(color.r, color.g, color.b)
            currentGroupText:SetText(groupInfo.displayText)
        end
    end
    
    -- Update on show
    main:SetScript("OnShow", function()
        UpdateGroupTypeDisplay()
    end)
    
    -- Periodic update
    C_Timer.NewTicker(2, function()
        if main:IsShown() then
            UpdateGroupTypeDisplay()
        end
    end)
    
    testFrame = main
    testFrame:Hide()
    
    Debug:Dev("pughelper", "PUG Helper Test UI created")
end

-- MARK: Simulation Methods

function PUGHelperTestUI:SimulateGroupAccept()
    local dungeon = self:GetSelectedDungeon()
    if not dungeon then
        Debug:Error("No dungeon selected")
        return
    end
    
    Debug:User("Simulating group acceptance for: " .. dungeon.name)
    
    -- Create fake application data
    local fakeAppData = {
        id = "999",
        name = dungeon.name,
        leader = "TestLeader-TestRealm",
        dungeonID = dungeon.id,
        activityID = dungeon.activityID,
        keyLevel = 10,
        appliedAt = time(),
        status = "invited"
    }
    
    -- Call OnMPlusAccepted
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnMPlusAccepted then
        NextKey222.PUGHelper:OnMPlusAccepted(fakeAppData)
    else
        Debug:Error("PUGHelper:OnMPlusAccepted not available")
    end
end

function PUGHelperTestUI:SimulateDungeonComplete()
    local dungeon = self:GetSelectedDungeon()
    if not dungeon then
        Debug:Error("No dungeon selected")
        return
    end
    
    Debug:User("Simulating dungeon completion for: " .. dungeon.name)
    
    -- Call OnChallengeModeCompleted
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnChallengeModeCompleted then
        NextKey222.PUGHelper:OnChallengeModeCompleted(dungeon.id, 10)
    else
        Debug:Error("PUGHelper:OnChallengeModeCompleted not available")
    end
end

function PUGHelperTestUI:ShowTeleportWindow(mode, dungeonComplete)
    local dungeon = self:GetSelectedDungeon()
    if not dungeon then
        Debug:Error("No dungeon selected")
        return
    end
    
    local contextDesc = mode .. " mode" .. (dungeonComplete and ", dungeon complete" or "")
    Debug:User("Showing teleport window (" .. contextDesc .. ") for: " .. dungeon.name)
    
    local NextKey = NextKey222.Addon
    if not NextKey then
        Debug:Error("NextKey addon not available")
        return
    end
    
    local fakeKeyInfo = {
        dungeonID = dungeon.id,
        level = 10,
        ownerName = mode == "PUG" and "PUG-Leader-Realm" or "Guildmate-Realm",
    }
    
    NextKey:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
    NextKey:SetTeleportWindowContext({
        mode = mode,
        dungeonComplete = dungeonComplete or false
    })
    
    if NextKey.ToggleTeleportWindow then
        NextKey:ToggleTeleportWindow()
    end
end

-- MARK: Helper Methods

function PUGHelperTestUI:GetSelectedDungeon()
    for _, dungeon in ipairs(TEST_DUNGEONS) do
        if dungeon.id == selectedDungeonID then
            return dungeon
        end
    end
    return nil
end

function PUGHelperTestUI:GetSimulatedGroupType()
    return simulatedGroupType
end

-- MARK: Slash Command
SLASH_NKPUGTEST1 = "/nkpugtest"
SlashCmdList["NKPUGTEST"] = function()
    PUGHelperTestUI:Toggle()
end