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
    
    -- CRITICAL: Clear role icon buttons (created with CreateFrame)
    if card.roleButtons then
        for _, button in ipairs(card.roleButtons) do
            if button then
                button:Hide()
                button:SetParent(nil)
                button:ClearAllPoints()
            end
        end
        card.roleButtons = {}
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

-- MARK: Shared Tooltip Handler
local function ShowRoleTooltip(roleButton, roleInfo, playerData)
    GameTooltip:SetOwner(roleButton, "ANCHOR_RIGHT")
    
    -- Normalize role display: DAMAGER → DPS for consistency
    local displayRole = roleInfo.role
    if displayRole:upper() == "DAMAGER" then
        displayRole = "DPS"
    end
    
    GameTooltip:SetText(displayRole, 1, 1, 1)
    
    -- Show spec-level breakdown if available (CRITICAL: normalize role key to uppercase)
    local normalizedRole = roleInfo.role:upper()
    
    -- DEBUG: Log what we're checking (using normalized key)
    Debug:Dev("organizer_ui", "Tooltip hover - Role:", roleInfo.role, "-> Normalized:", normalizedRole)
    Debug:Dev("organizer_ui", "  - playerData.specDetails exists:", playerData.specDetails ~= nil)
    if playerData.specDetails then
        -- Build key list for debugging
        local keys = {}
        for k in pairs(playerData.specDetails) do
            table.insert(keys, k)
        end
        Debug:Dev("organizer_ui", "  - specDetails keys:", table.concat(keys, ", "))
        Debug:Dev("organizer_ui", "  - specDetails[" .. normalizedRole .. "] exists:", playerData.specDetails[normalizedRole] ~= nil)
        if playerData.specDetails[normalizedRole] then
            Debug:Dev("organizer_ui", "  - Number of specs:", #playerData.specDetails[normalizedRole])
        end
    end
    
    -- ONLY show tooltip if we have spec details - otherwise show fallback
    if playerData.specDetails and playerData.specDetails[normalizedRole] then
    	for _, specInfo in ipairs(playerData.specDetails[normalizedRole]) do
    		-- CRITICAL: Only show "play" and "fill" preferences, hide "none"
    		if specInfo.preference == "play" then
    			GameTooltip:AddLine(specInfo.specName .. ": Want to Play", 0.2, 0.9, 0.2)
    		elseif specInfo.preference == "fill" then
    			GameTooltip:AddLine(specInfo.specName .. ": Will Fill", 0.9, 0.8, 0.2)
    		end
    		-- NOTE: "none" preferences are NOT displayed (per user request)
    	end
    else
        -- Fallback to simple display
        Debug:Dev("organizer_ui", "  - Using fallback tooltip (no specDetails)")
        if roleInfo.preference == "play" then
            GameTooltip:AddLine("Want to Play", 0.2, 0.9, 0.2)
        elseif roleInfo.preference == "fill" then
            GameTooltip:AddLine("Will Fill", 0.9, 0.8, 0.2)
        end
    end
    
    GameTooltip:Show()
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
        
        -- CRITICAL: Initialize role buttons array for proper cleanup
        card.roleButtons = {}
        
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
    -- Store keystone button state if it exists
    local wasDesignated = false
    if card.keystoneButton and card.location and
       type(card.location) == "table" and
       card.location.type == "role_slot" then
        
        wasDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
            card.location.groupIndex,
            card.playerData.id
        )
    end
    
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
    
    -- Restore keystone button highlight if needed
    if wasDesignated and card.keystoneButton then
        NextKey222.RosterBoard:HighlightKeystoneButton(card.playerData.id)
    end
    
    Debug:Dev("organizer_ui", "Updated card content to mode:", newDisplayMode, "- Active regions:", card.regions.activeCount)
    
    -- DEBUG: Log what data we're working with AFTER recreation
    Debug:Dev("organizer_ui", "Card content updated for:", card.playerData.name)
    Debug:Dev("organizer_ui", "  - has specPreferences:", card.playerData.specPreferences ~= nil)
    if card.playerData.specPreferences then
        local prefCount = 0
        for role, pref in pairs(card.playerData.specPreferences) do
            prefCount = prefCount + 1
            Debug:Dev("organizer_ui", "    -", role, ":", pref)
        end
        Debug:Dev("organizer_ui", "  - Total prefs:", prefCount)
    end
end

-- MARK: Compact Card Content (Native Frame Version - Region Tracked)
function PlayerCard:CreateCompactContent(card, playerData)
    local xOffset = 5
    
    -- Multi-role icons with preference colors (max 3)
    if playerData.roles then
        local rolesToShow = {}
        
        -- DEBUG: Log what we're working with
        Debug:Dev("organizer_ui", "CreateCompactContent for", playerData.name)
        Debug:Dev("organizer_ui", "  - has specPreferences:", playerData.specPreferences ~= nil)
        Debug:Dev("organizer_ui", "  - has roles:", playerData.roles ~= nil, "count:", playerData.roles and #playerData.roles or 0)
        
        -- Collect roles with preferences (up to 3)
        if playerData.specPreferences then
            -- DEBUG: Show what's in specPreferences
            local prefCount = 0
            for role, preference in pairs(playerData.specPreferences) do
                prefCount = prefCount + 1
                Debug:Dev("organizer_ui", "    - specPreferences[" .. role .. "] =", preference)
            end
            Debug:Dev("organizer_ui", "  - Total spec preferences:", prefCount)
            
            -- If we have poll data, show roles based on preference order
            for role, preference in pairs(playerData.specPreferences) do
                if preference ~= "none" then
                    table.insert(rolesToShow, {
                        role = role,
                        preference = preference
                    })
                end
            end
            
            Debug:Dev("organizer_ui", "  - Roles to show (after filtering 'none'):", #rolesToShow)
        else
            -- Fallback: show current roles without preference data
            Debug:Dev("organizer_ui", "  - Using fallback (roles array)")
            for i, role in ipairs(playerData.roles) do
                table.insert(rolesToShow, {
                    role = role,
                    preference = "play"  -- Default to "want to play"
                })
            end
        end
        
        -- Limit to 3 roles
        local maxRoles = math.min(#rolesToShow, 3)
        
        for i = 1, maxRoles do
            local roleInfo = rolesToShow[i]
            
            -- Create invisible button frame for tooltip support
            local roleButton = CreateFrame("Button", nil, card)
            roleButton:SetSize(18, 18)
            roleButton:SetPoint("LEFT", card, "LEFT", xOffset, 0)
            roleButton:EnableMouse(true)
            
            -- CRITICAL: Track role button for cleanup
            table.insert(card.roleButtons, roleButton)
            
            -- Create colored circle background
            local bgCircle = roleButton:CreateTexture(nil, "BACKGROUND")
            bgCircle:SetAllPoints(roleButton)
            
            -- Set color based on preference
            if roleInfo.preference == "play" then
                bgCircle:SetColorTexture(0.2, 0.9, 0.2, 0.7)  -- Green
            elseif roleInfo.preference == "fill" then
                bgCircle:SetColorTexture(0.9, 0.8, 0.2, 0.7)  -- Yellow
            else
                bgCircle:SetColorTexture(0.5, 0.5, 0.5, 0.5)  -- Grey (shouldn't happen)
            end
            
            -- Create role icon on top of circle
            local icon = roleButton:CreateTexture(nil, "ARTWORK")
            icon:SetSize(14, 14)
            icon:SetPoint("CENTER", roleButton, "CENTER", 0, 0)
            icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            
            local normalizedRole = roleInfo.role:upper()
            
            if normalizedRole == "TANK" then
                icon:SetTexCoord(0, 19/64, 22/64, 41/64)
            elseif normalizedRole == "HEALER" then
                icon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
            else  -- DAMAGER/DPS
                icon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
            end
            
            -- Add tooltip on hover with spec-level details (SHARED FUNCTION)
            roleButton:SetScript("OnEnter", function(self)
                ShowRoleTooltip(self, roleInfo, playerData)
            end)
            
            roleButton:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            xOffset = xOffset + 20
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
    
    -- Line 1: Class icon + Multi-role icons with preference colors
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
    
    -- Multi-role icons with preference colors (up to 3)
    if playerData.roles then
        local rolesToShow = {}
        
        -- DEBUG: Log what we're rendering
        Debug:Dev("organizer_ui", "CreateExpandedContent for", playerData.name, "- has specPreferences:", playerData.specPreferences ~= nil)
        if playerData.specPreferences then
            Debug:Dev("organizer_ui", "Spec preferences:")
            for role, preference in pairs(playerData.specPreferences) do
                Debug:Dev("organizer_ui", "  -", role, ":", preference)
            end
        end
        
        -- Collect roles with preferences (up to 3)
        if playerData.specPreferences then
            -- If we have poll data, show roles based on preference order
            for role, preference in pairs(playerData.specPreferences) do
                if preference ~= "none" then
                    table.insert(rolesToShow, {
                        role = role,
                        preference = preference
                    })
                end
            end
            Debug:Dev("organizer_ui", "Found", #rolesToShow, "roles to show (excluding 'none')")
        else
            -- Fallback: show current roles without preference data
            for i, role in ipairs(playerData.roles) do
                table.insert(rolesToShow, {
                    role = role,
                    preference = "play"  -- Default to "want to play"
                })
            end
        end
        
        -- Limit to 3 roles
        local maxRoles = math.min(#rolesToShow, 3)
        
        for i = 1, maxRoles do
            local roleInfo = rolesToShow[i]
            
            -- Create invisible button frame for tooltip support
            local roleButton = CreateFrame("Button", nil, card)
            roleButton:SetSize(18, 18)
            roleButton:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
            roleButton:EnableMouse(true)
            
            -- CRITICAL: Track role button for cleanup
            table.insert(card.roleButtons, roleButton)
            
            -- Create colored circle background
            local bgCircle = roleButton:CreateTexture(nil, "BACKGROUND")
            bgCircle:SetAllPoints(roleButton)
            
            -- Set color based on preference
            if roleInfo.preference == "play" then
                bgCircle:SetColorTexture(0.2, 0.9, 0.2, 0.7)  -- Green
            elseif roleInfo.preference == "fill" then
                bgCircle:SetColorTexture(0.9, 0.8, 0.2, 0.7)  -- Yellow
            else
                bgCircle:SetColorTexture(0.5, 0.5, 0.5, 0.5)  -- Grey
            end
            
            -- Create role icon on top of circle
            local roleIcon = roleButton:CreateTexture(nil, "ARTWORK")
            roleIcon:SetSize(14, 14)
            roleIcon:SetPoint("CENTER", roleButton, "CENTER", 0, 0)
            roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            
            local normalizedRole = roleInfo.role:upper()
            
            if normalizedRole == "TANK" then
                roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
            elseif normalizedRole == "HEALER" then
                roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
            else  -- DAMAGER/DPS
                roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
            end
            
            -- Add tooltip on hover with spec-level details (SHARED FUNCTION)
            roleButton:SetScript("OnEnter", function(self)
                ShowRoleTooltip(self, roleInfo, playerData)
            end)
            
            roleButton:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            xOffset = xOffset + 20
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
    
    -- NEW: Add keystone designation button in top-right corner (only in group slots and if has keystone)
    if playerData.keystone then
        local keystoneButton = self:CreateKeystoneButton(card, playerData)
        if keystoneButton then
            card.keystoneButton = keystoneButton
            table.insert(card.roleButtons, keystoneButton)  -- Track for cleanup
        end
    end
    
    -- Line 4: IO Score
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    ioText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
    ioText:SetText("IO: " .. (playerData.overallScore or 0))
    ioText:SetTextColor(0.8, 0.8, 1)
end

-- MARK: Keystone Designation Button
function PlayerCard:CreateKeystoneButton(card, playerData)
    -- Only create if card is in a group slot
    if not card.location or
       type(card.location) ~= "table" or
       card.location.type ~= "role_slot" then
        return nil
    end
    
    -- Create button frame in top-right corner
    local keystoneButton = CreateFrame("Button", nil, card, "BackdropTemplate")
    keystoneButton:SetSize(20, 20)
    keystoneButton:SetPoint("TOPRIGHT", card, "TOPRIGHT", -3, -3)
    keystoneButton:EnableMouse(true)
    
    -- Backdrop for visual feedback (circular background)
    keystoneButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    keystoneButton:SetBackdropColor(0, 0, 0, 0.7)
    keystoneButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    
    -- Star icon (using achievement star texture - much better!)
    local icon = keystoneButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
    icon:SetTexCoord(0, 0.5625, 0, 0.5625)  -- Get just the star part
    icon:SetVertexColor(0.8, 0.8, 0.8)  -- Gray by default
    
    -- Click handler
    keystoneButton:SetScript("OnClick", function()
        NextKey222.RosterBoard:DesignateGroupKeystone(
            card.location.groupIndex,
            playerData.keystone,
            playerData.id
        )
    end)
    
    -- Hover effect with tooltip
    keystoneButton:SetScript("OnEnter", function(self)
        -- Brighten icon on hover
        local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
            card.location.groupIndex,
            playerData.id
        )
        
        if not isDesignated then
            icon:SetVertexColor(1.0, 1.0, 1.0)  -- Brighten to white
        end
        
        -- Show tooltip
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        if isDesignated then
            GameTooltip:SetText("Group Keystone", 1, 1, 1)
            GameTooltip:AddLine("Click to undesignate", 0.7, 0.7, 0.7)
        else
            GameTooltip:SetText("Click to Set as Group Keystone", 1, 1, 1)
        end
        
        GameTooltip:Show()
    end)
    
    keystoneButton:SetScript("OnLeave", function()
        -- Reset hover brightness
        local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
            card.location.groupIndex,
            playerData.id
        )
        
        if not isDesignated then
            icon:SetVertexColor(0.8, 0.8, 0.8)  -- Reset to gray
        end
        
        GameTooltip:Hide()
    end)
    
    -- Store icon reference for easy color changes
    keystoneButton.icon = icon
    
    Debug:Dev("organizer_ui", "Created keystone button for:", playerData.name)
    
    return keystoneButton
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
