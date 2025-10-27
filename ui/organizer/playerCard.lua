-- MARK: Module Definition
local _, NextKey222 = ...

local PlayerCard = {}
NextKey222.PlayerCard = PlayerCard
NextKey222.RegisterModule("PlayerCard", PlayerCard)

local Debug = NextKey222.Debug

-- MARK: Component Pool
PlayerCard.cardPool = {}

-- MARK: Region Pool Structure
-- Each card stores references to all created regions for proper cleanup
local function InitializeRegionPool(card)
    card.regions = {
        textures = {},  -- All texture regions
        fontStrings = {},  -- All font string regions
        activeCount = 0  -- Track how many regions are in use
    }
end

-- MARK: Region Cleanup
local function ClearCardRegions(card)
    if not card.regions then return end
    
    -- Hide and clear all textures
    for _, texture in ipairs(card.regions.textures) do
        texture:Hide()
        texture:ClearAllPoints()
    end
    
    -- Hide and clear all font strings
    for _, fontString in ipairs(card.regions.fontStrings) do
        fontString:Hide()
        fontString:SetText("")
        fontString:ClearAllPoints()
    end
    
    -- Reset active count
    card.regions.activeCount = 0
    
    Debug:Trace("organizer_ui", "Cleared all regions from card:", card.playerData and card.playerData.name or "Unknown")
end

-- MARK: Region Creation Helpers (with tracking)
local function CreateTrackedTexture(card, ...)
    local texture = card:CreateTexture(...)
    table.insert(card.regions.textures, texture)
    card.regions.activeCount = card.regions.activeCount + 1
    return texture
end

local function CreateTrackedFontString(card, ...)
    local fontString = card:CreateFontString(...)
    table.insert(card.regions.fontStrings, fontString)
    card.regions.activeCount = card.regions.activeCount + 1
    return fontString
end

-- MARK: Native Card Creation (NEW - Based on drag_test_simple.lua)
function PlayerCard:CreateNativeCard(playerData, parentFrame, location, displayMode)
    return NextKey222.SafeRun(function()
        if not playerData then
            Debug:Error("Cannot create player card: playerData is nil")
            return nil
        end
        
        -- Determine size based on mode
        local width, height
        if displayMode == "compact" then
            width, height = 180, 20
        elseif displayMode == "opt_out" then
            width, height = 90, 40  -- Square-ish for 2-line layout
        else
            width, height = 155, 90  -- Expanded
        end
        
        -- Create native button frame with backdrop
        local card = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
        card:SetSize(width, height)
        card:SetMovable(true)
        card:RegisterForDrag("LeftButton")
        card:SetClampedToScreen(false)  -- Allow dragging outside parent
        
        -- Backdrop setup
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        
        -- Apply class color
        local classColor = RAID_CLASS_COLORS[playerData.class] or {r=0.5, g=0.5, b=0.5}
        card:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.8)
        card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        
        -- Store metadata
        card.playerData = playerData
        card.location = location
        card.displayMode = displayMode
        card.isDragging = false
        card.classColor = classColor
        
        -- Initialize region pool for tracking
        InitializeRegionPool(card)
        
        -- Create visual content based on display mode
        self:UpdateCardContent(card, displayMode)
        
        -- Enable dragging
        self:EnableNativeDragging(card)
        
        card:Show()
        Debug:Dev("organizer_ui", "Created native", displayMode, "card for:", playerData.name)
        
        return card
        
    end, "PlayerCard:CreateNativeCard")
end

-- MARK: Dynamic Content Update (NEW - Region Pooling)
function PlayerCard:UpdateCardContent(card, newDisplayMode)
    -- Clear existing regions before creating new ones
    ClearCardRegions(card)
    
    -- Update display mode
    card.displayMode = newDisplayMode
    
    -- Create appropriate content based on mode
    if newDisplayMode == "compact" then
        self:CreateCompactContent(card, card.playerData)
    elseif newDisplayMode == "opt_out" then
        self:CreateOptOutContent(card, card.playerData)
    elseif newDisplayMode == "expanded" then
        self:CreateExpandedContent(card, card.playerData)
    end
    
    Debug:Dev("organizer_ui", "Updated card content to mode:", newDisplayMode, "- Active regions:", card.regions.activeCount)
end

-- MARK: Compact Card Content (Native Frame Version - Region Tracked)
function PlayerCard:CreateCompactContent(card, playerData)
    local xOffset = 5
    
    -- Role icons (max 2)
    if playerData.roles then
        -- PHASE 1: Diagnostic logging - track role icons for compact cards
        if Debug and (playerData.name:find("Ryuza") or playerData.class == "EVOKER") then
            Debug:Dev("organizer_ui", string.format("COMPACT CARD: Creating role icons for %s, roles array: [%s]",
                playerData.name, table.concat(playerData.roles, ", ")))
        end
        
        for i, role in ipairs(playerData.roles) do
            if i > 2 then break end
            
            local icon = CreateTrackedTexture(card, nil, "ARTWORK")
            icon:SetSize(16, 16)
            icon:SetPoint("LEFT", card, "LEFT", xOffset, 0)
            icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            
            local normalizedRole = role:upper()
            
            -- PHASE 1: Diagnostic logging - track which role icon is being set
            if Debug and (playerData.name:find("Ryuza") or playerData.class == "EVOKER") then
                Debug:Dev("organizer_ui", string.format("Setting role icon %d for %s: role=%s, normalized=%s",
                    i, playerData.name, role, normalizedRole))
            end
            
            if normalizedRole == "TANK" then
                icon:SetTexCoord(0, 19/64, 22/64, 41/64)
            elseif normalizedRole == "HEALER" then
                icon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
            else  -- DAMAGER/DPS
                icon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
            end
            
            xOffset = xOffset + 18
        end
    end
    
    -- Player name (truncated)
    local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    local truncatedName = playerData.name or "Unknown"
    if #truncatedName > 7 then
        truncatedName = truncatedName:sub(1, 7)
    end
    nameText:SetText(truncatedName)
    nameText:SetTextColor(1, 1, 1)
    xOffset = xOffset + 55
    
    -- Separator
    local sepText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    sepText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    sepText:SetText("|")
    sepText:SetTextColor(0.7, 0.7, 0.7)
    xOffset = xOffset + 10
    
    -- Keystone info (use alias for compact display)
    if playerData.keystone then
        local dungeonAbbrev = "???"
        -- Use centralized DungeonNameService for consistent lookups
        if NextKey222.DungeonNameService then
            dungeonAbbrev = NextKey222.DungeonNameService:GetAlias(playerData.keystone.dungeonID)
        end
        
        local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
        keyText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
        keyText:SetText(dungeonAbbrev .. " +" .. (playerData.keystone.level or 0))
        keyText:SetTextColor(1, 0.82, 0)
        xOffset = xOffset + 45
    end
    
    -- IO Score
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    ioText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    ioText:SetText("[" .. (playerData.overallScore or 0) .. "]")
    ioText:SetTextColor(0.8, 0.8, 1)
end

-- MARK: Opt-Out Card Content (2-Line Square Layout)
function PlayerCard:CreateOptOutContent(card, playerData)
    -- Line 1: Role icon + Name (truncated to 7 chars)
    local xOffset = 5
    
    -- Role icon (first role only)
    if playerData.roles and playerData.roles[1] then
        local icon = CreateTrackedTexture(card, nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -5)
        icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        
        local normalizedRole = playerData.roles[1]:upper()
        if normalizedRole == "TANK" then
            icon:SetTexCoord(0, 19/64, 22/64, 41/64)
        elseif normalizedRole == "HEALER" then
            icon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
        else  -- DAMAGER/DPS
            icon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
        end
        
        xOffset = xOffset + 18
    end
    
    -- Player name (truncated to 7 chars)
    local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -5)
    local truncatedName = playerData.name or "Unknown"
    if #truncatedName > 7 then
        truncatedName = truncatedName:sub(1, 7)
    end
    nameText:SetText(truncatedName)
    nameText:SetTextColor(1, 1, 1)
    
    -- Line 2: Dungeon abbreviation +level | IO Score
    local line2YOffset = -22
    xOffset = 5
    
    -- Keystone info (use alias for opt-out display)
    if playerData.keystone then
        local dungeonAbbrev = "???"
        -- Use centralized DungeonNameService for consistent lookups
        if NextKey222.DungeonNameService then
            dungeonAbbrev = NextKey222.DungeonNameService:GetAlias(playerData.keystone.dungeonID)
        end
        
        local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
        keyText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, line2YOffset)
        keyText:SetText(dungeonAbbrev .. " +" .. (playerData.keystone.level or 0))
        keyText:SetTextColor(1, 0.82, 0)
        xOffset = xOffset + 38
    end
    
    -- IO Score
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    ioText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, line2YOffset)
    ioText:SetText("[" .. (playerData.overallScore or 0) .. "]")
    ioText:SetTextColor(0.8, 0.8, 1)
end

-- MARK: Expanded Card Content (Native Frame Version)
function PlayerCard:CreateExpandedContent(card, playerData)
    local yOffset = 5
    
    -- Line 1: Class icon + Role icons
    local xOffset = 5
    
    -- Class icon
    if playerData.class then
        local classIcon = CreateTrackedTexture(card, nil, "ARTWORK")
        classIcon:SetSize(20, 20)
        classIcon:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        
        local coords = CLASS_ICON_TCOORDS[playerData.class]
        if coords then
            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
        xOffset = xOffset + 25
    end
    
    -- Role icons
    if playerData.roles then
        -- PHASE 1: Diagnostic logging - track role icons for expanded cards
        if Debug and (playerData.name:find("Ryuza") or playerData.class == "EVOKER") then
            Debug:Dev("organizer_ui", string.format("EXPANDED CARD: Creating role icons for %s, roles array: [%s]",
                playerData.name, table.concat(playerData.roles, ", ")))
        end
        
        for _, role in ipairs(playerData.roles) do
            local roleIcon = CreateTrackedTexture(card, nil, "ARTWORK")
            roleIcon:SetSize(16, 16)
            roleIcon:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
            roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            
            local normalizedRole = role:upper()
            
            -- PHASE 1: Diagnostic logging - track which role icon is being set
            if Debug and (playerData.name:find("Ryuza") or playerData.class == "EVOKER") then
                Debug:Dev("organizer_ui", string.format("Setting role icon for %s: role=%s, normalized=%s",
                    playerData.name, role, normalizedRole))
            end
            
            if normalizedRole == "TANK" then
                roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
            elseif normalizedRole == "HEALER" then
                roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
            else
                roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
            end
            
            xOffset = xOffset + 18
        end
    end
    
    yOffset = yOffset + 25
    
    -- Line 2: Player name
    local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
    nameText:SetText(playerData.name or "Unknown")
    nameText:SetTextColor(1, 1, 1)
    yOffset = yOffset + 18
    
    -- Line 2.5: Spec name (if available)
    if playerData.specName then
        local specText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
        specText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
        specText:SetText(playerData.specName)
        specText:SetTextColor(0.7, 0.9, 1.0)  -- Light blue color
        yOffset = yOffset + 14
    end
    
    -- Line 3: Keystone info
    if playerData.keystone then
        local dungeonName = "Unknown"
        -- Use centralized DungeonNameService for consistent lookups
        if NextKey222.DungeonNameService then
            dungeonName = NextKey222.DungeonNameService:GetFullName(playerData.keystone.dungeonID)
        end
        
        local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
        keyText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
        keyText:SetText(dungeonName .. " +" .. (playerData.keystone.level or 0))
        keyText:SetTextColor(1, 0.82, 0)
        yOffset = yOffset + 16
    end
    
    -- Line 4: IO Score
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    ioText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
    ioText:SetText("IO: " .. (playerData.overallScore or 0))
    ioText:SetTextColor(0.8, 0.8, 1)
end

-- MARK: Native Drag Handlers (Based on drag_test_simple.lua)
function PlayerCard:EnableNativeDragging(card)
    card:SetScript("OnDragStart", function(self)
        -- CRITICAL: Store ALL original frame properties
        self.originalParent = self:GetParent()
        self.originalX, self.originalY = self:GetCenter()
        self.originalFrameStrata = self:GetFrameStrata()
        self.originalFrameLevel = self:GetFrameLevel()
        
        -- CRITICAL: Reparent to UIParent to avoid clipping
        self:SetParent(UIParent)
        self:SetFrameStrata("TOOLTIP")
        
        -- Start moving
        self:StartMoving()
        self.isDragging = true
        
        -- Visual feedback
        self:SetBackdropColor(self.classColor.r, self.classColor.g, self.classColor.b, 0.5)
        self:SetBackdropBorderColor(1, 1, 0, 1)
        
        Debug:Dev("organizer_ui", "Started dragging:", self.playerData.name, "- Stored frame level:", self.originalFrameLevel)
    end)
    
    card:SetScript("OnDragStop", function(self)
        if not self.isDragging then return end
        
        self:StopMovingOrSizing()
        self.isDragging = false
        self:SetFrameStrata("MEDIUM")
        
        -- Detect drop target using IsMouseOver()
        local dropTarget = NextKey222.RosterBoard:DetectDropTarget()
        
        if dropTarget then
            Debug:Dev("organizer_ui", "Valid drop target detected:", dropTarget.type)
            NextKey222.RosterBoard:HandleCardDrop(self, dropTarget)
        else
            Debug:Dev("organizer_ui", "No valid drop target - rejecting")
            NextKey222.RosterBoard:AnimateRejection(self)
        end
    end)
    
    Debug:Dev("organizer_ui", "Enabled native dragging for:", card.playerData.name)
end

-- MARK: View Detection
function PlayerCard:IsOrganizerView()
    if NextKey222.RosterBoard then
        return NextKey222.RosterBoard:IsOrganizer()
    end
    return false
end

-- MARK: Initialization
function PlayerCard:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Initializing Player Card module (Native Frame Version)")
        self.cardPool = {}
        return true
    end, "PlayerCard:Initialize")
end
