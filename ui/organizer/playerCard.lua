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
    
    -- CRITICAL FIX: Properly destroy all textures
    for _, texture in ipairs(card.regions.textures) do
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetTexture(nil)  -- Release texture memory
    end
    
    -- CRITICAL FIX: Properly destroy all font strings
    for _, fontString in ipairs(card.regions.fontStrings) do
        fontString:Hide()
        fontString:SetText("")
        fontString:ClearAllPoints()
    end
    
    -- CRITICAL FIX: Properly destroy role icon buttons (created with CreateFrame)
    if card.roleButtons then
        for _, button in ipairs(card.roleButtons) do
            if button then
                -- MEMORY LEAK FIX: Nil all script handlers to break circular references
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
                button:SetScript("OnClick", nil)
                
                -- Clear all child textures
                for _, region in ipairs({button:GetRegions()}) do
                    if region:GetObjectType() == "Texture" then
                        region:SetTexture(nil)
                    end
                end
                
                button:Hide()
                button:SetParent(nil)
                button:ClearAllPoints()
            end
        end
        card.roleButtons = {}
    end
    
    -- Reset active count
    card.regions.activeCount = 0
    
    Debug:Trace("organizer_ui", "Cleared all regions from card with proper cleanup:", card.playerData and card.playerData.name or "Unknown")
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
    
    -- SIMPLIFIED FIX: Just show the player's current spec from profile
    -- This is the same data shown in expanded cards (line 701-702)
    if playerData.specName then
        -- Show current spec with preference color
        if roleInfo.preference == "play" then
            GameTooltip:AddLine(playerData.specName .. ": Want to Play", 0.2, 0.9, 0.2)
        elseif roleInfo.preference == "fill" then
            GameTooltip:AddLine(playerData.specName .. ": Will Fill", 0.9, 0.8, 0.2)
        else
            GameTooltip:AddLine(playerData.specName, 1, 1, 1)
        end
    else
        -- Fallback if no spec name available
        if roleInfo.preference == "play" then
            GameTooltip:AddLine("Want to Play", 0.2, 0.9, 0.2)
        elseif roleInfo.preference == "fill" then
            GameTooltip:AddLine("Will Fill", 0.9, 0.8, 0.2)
        end
    end
    
    GameTooltip:Show()
end

-- MARK: Shared Rendering Helpers

-- Helper: Render multi-role icons with preference colors
-- NOTE: For compact cards, pass yOffset=nil or 0 to use CENTER anchoring
local function RenderRoleIcons(card, playerData, xOffset, yOffset, maxRoles)
    if not playerData.roles then
        Debug:Dev("organizer_ui", "RenderRoleIcons: playerData.roles is nil for", playerData.name)
        -- Always reserve space for maxRoles even if no roles to render
        return xOffset + (maxRoles * 20)
    end
    
    if #playerData.roles == 0 then
        Debug:Dev("organizer_ui", "RenderRoleIcons: playerData.roles is empty array for", playerData.name)
        -- Always reserve space for maxRoles even if no roles to render
        return xOffset + (maxRoles * 20)
    end
    
    -- BUG FIX: Initialize roleButtons array if not present
    if not card.roleButtons then
        card.roleButtons = {}
    end
    
    local rolesToShow = {}
    
    -- Collect roles with preferences (up to maxRoles)
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
        
        -- BUG FIX: If specPreferences exists but ALL are "none", fall back to roles array
        if #rolesToShow == 0 and playerData.roles then
            Debug:Dev("organizer_ui", "All specPreferences are 'none' - using roles array fallback for", playerData.name)
            for i, role in ipairs(playerData.roles) do
                table.insert(rolesToShow, {
                    role = role,
                    preference = "play"  -- Default to "want to play"
                })
            end
        end
    else
        -- Fallback: show current roles without preference data
        for i, role in ipairs(playerData.roles) do
            table.insert(rolesToShow, {
                role = role,
                preference = "play"  -- Default to "want to play"
            })
        end
    end
    
    Debug:Dev("organizer_ui", "RenderRoleIcons: rolesToShow count =", #rolesToShow, "for", playerData.name)
    
    -- Limit to specified max roles
    local roleCount = math.min(#rolesToShow, maxRoles)
    
    -- Detect if this is compact mode (yOffset == 0 or nil for compact)
    local isCompact = (yOffset == nil or yOffset == 0)
    
    -- Store starting offset for space reservation
    local startOffset = xOffset
    
    for i = 1, roleCount do
        local roleInfo = rolesToShow[i]
        
        -- Create invisible button frame for tooltip support
        local roleButton = CreateFrame("Button", nil, card)
        roleButton:SetSize(18, 18)
        
        if isCompact then
            -- Compact mode: use LEFT anchor for vertical centering (y=0)
            roleButton:SetPoint("LEFT", card, "LEFT", xOffset, 0)
        else
            -- Expanded mode: use TOPLEFT anchor with yOffset
            roleButton:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
        end
        
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
        
        -- Add tooltip on hover with spec-level details
        roleButton:SetScript("OnEnter", function(self)
            ShowRoleTooltip(self, roleInfo, playerData)
        end)
        
        roleButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        xOffset = xOffset + 20
    end
    
    -- Always return offset as if we rendered maxRoles icons (reserve space)
    return startOffset + (maxRoles * 20)
end

-- Helper: Render keystone information
-- NOTE: yOffset parameter is now unused for compact cards (uses vertical CENTER)
local function RenderKeystoneInfo(card, playerData, xOffset, yOffset, useAlias)
    if not playerData.keystone then return xOffset end
    
    local dungeonText
    if useAlias then
        -- Use abbreviation for compact display
        dungeonText = "???"
        if NextKey222.DungeonNameService then
            dungeonText = NextKey222.DungeonNameService:GetAlias(playerData.keystone.dungeonID)
        end
    else
        -- Use full name for expanded display
        dungeonText = "Unknown"
        if NextKey222.DungeonNameService then
            dungeonText = NextKey222.DungeonNameService:GetFullName(playerData.keystone.dungeonID)
        end
    end
    
    local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    if useAlias then
        -- Compact mode: use LEFT anchor for vertical centering (y=0)
        keyText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    else
        -- Expanded mode: use TOPLEFT with yOffset
        keyText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
    end
    keyText:SetText(dungeonText .. " +" .. (playerData.keystone.level or 0))
    keyText:SetTextColor(1, 0.82, 0)
    
    -- Add width constraint and word wrap for expanded cards to prevent overflow
    if not useAlias then
        keyText:SetWidth(130)  -- Max width for 155px card
        keyText:SetWordWrap(true)
        keyText:SetJustifyH("LEFT")
    end
    
    -- Return updated offset (approximate text width)
    if useAlias then
        return xOffset + 45
    else
        return xOffset
    end
end

-- Helper: Render player name
-- NOTE: yOffset parameter is now unused for compact cards (uses vertical CENTER)
local function RenderPlayerName(card, playerData, xOffset, yOffset, truncateLength)
    local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    
    -- Check if this is compact mode (yOffset ignored for compact, used for expanded/opt-out)
    if truncateLength then
        -- Compact mode: use LEFT anchor for vertical centering (y=0)
        nameText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    else
        -- Expanded/opt-out mode: use TOPLEFT with yOffset
        nameText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
    end
    
    local displayName = playerData.name or "Unknown"
    if truncateLength and #displayName > truncateLength then
        displayName = displayName:sub(1, truncateLength)
    end
    
    nameText:SetText(displayName)
    nameText:SetTextColor(1, 1, 1)
    
    return xOffset + 55  -- Approximate text width
end

-- Helper: Render IO score
-- NOTE: yOffset parameter is now unused for compact cards (uses vertical CENTER)
local function RenderIOScore(card, playerData, xOffset, yOffset, isCompact)
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    
    if isCompact then
        -- Compact mode: use RIGHT anchor for vertical centering (y=0)
        ioText:SetPoint("RIGHT", card, "RIGHT", -5, 0)
    else
        -- Expanded/opt-out mode: use TOPRIGHT with yOffset
        ioText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -yOffset)
    end
    
    ioText:SetText("[" .. (playerData.overallScore or 0) .. "]")
    
    -- Use universal IO score color system
    local r, g, b = NextKey222.Utils:GetIOScoreColor(playerData.overallScore or 0)
    ioText:SetTextColor(r, g, b)
end


-- MARK: Native Card Creation (STATE-DRIVEN - Session 3 Refactor)
function PlayerCard:CreateNativeCard(playerData, parentFrame, location, displayMode)
    return NextKey222.SafeRun(function()
        if not playerData then
            Debug:Error("Cannot create player card: playerData is nil")
            return nil
        end
        
        -- Determine size based on mode
        local width, height
        if displayMode == "compact" then
            -- Use UIConfig for dynamic height (robust to config changes)
            local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
            local benchCardHeight = config.BENCH_CARD_HEIGHT or 25
            width, height = 200, benchCardHeight
        elseif displayMode == "opt_out" then
            -- Use UIConfig for opt-out card dimensions
            local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
            width = config.OPT_OUT_CARD_WIDTH or 90
            height = config.OPT_OUT_CARD_HEIGHT or 40
        else
            width, height = 170, 105  -- Expanded (increased width to 170 to prevent dungeon name overflow)
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
        
        -- Store metadata (SESSION 3: Only store playerID, not full data)
        card.playerID = playerData.id  -- CRITICAL: Lightweight reference only
        card.playerData = playerData   -- Keep for backward compatibility during migration
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
        
        -- Enable right-click for manual preference setting (organizer only)
        self:EnableRightClickPreferences(card)
        
        card:Show()
        Debug:Dev("organizer_ui", "Created native", displayMode, "card for:", playerData.name, "- playerID:", card.playerID)
        
        return card
        
    end, "PlayerCard:CreateNativeCard")
end

-- MARK: Dynamic Content Update (STATE-DRIVEN - Session 3 Refactor)
function PlayerCard:UpdateCardContent(card, newDisplayMode)
    -- CRITICAL: Fetch fresh data from OrganizerState on every render
    if card.playerID and NextKey222.OrganizerState then
        local freshData = NextKey222.OrganizerState:GetPlayer(card.playerID)
        if freshData then
            card.playerData = freshData  -- Update with latest state
            Debug:Dev("organizer_ui", "Refreshed card data from state:", card.playerID)
        else
            Debug:Error("Card references player not in state:", card.playerID)
        end
    end
    
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
    -- Check if awaiting poll response (has addon, poll active, no response yet)
    local isAwaitingPollResponse = false
    if NextKey222.RosterBoard and NextKey222.RosterBoard.activePoll then
        -- Check if this player is in addon users list
        local addonUsers = NextKey222.RosterBoard.activePoll.addonUsers or {}
        local isAddonUser = false
        for _, playerID in ipairs(addonUsers) do
            if playerID == playerData.id then
                isAddonUser = true
                break
            end
        end
        
        -- Check if they've responded
        local hasResponded = false
        if isAddonUser then
            for _, response in ipairs(NextKey222.RosterBoard.activePoll.responses) do
                if response.sender == playerData.id then
                    hasResponded = true
                    break
                end
            end
            
            isAwaitingPollResponse = not hasResponded
        end
    end
    
    -- Apply greyed-out visual state if awaiting response
    if isAwaitingPollResponse then
        -- Dim the card
        card:SetAlpha(0.6)
        
        -- Show "Polling..." text centered
        local pollingText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
        pollingText:SetPoint("CENTER", card, "CENTER", 0, 0)
        pollingText:SetText("Polling...")
        pollingText:SetTextColor(1, 1, 0.5)  -- Yellow
        
        return  -- Skip normal content rendering
    else
        -- Ensure full opacity for normal state
        card:SetAlpha(1.0)
    end
    
    -- Read configurable left padding from UIConfig
    local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
    local xOffset = config.BENCH_CARD_LEFT_PADDING or 5
    
    -- COMPACT CARD VERTICAL CENTERING FIX:
    -- Use CENTER-based anchoring (y=0) for all elements instead of TOPLEFT
    -- This ensures text centers through the middle of letters, not on the baseline
    
    Debug:Dev("organizer_ui", "Compact card using CENTER-based vertical anchoring (all elements y=0)")
    
    -- Player name (truncated to 7 chars) - FIRST - uses LEFT anchor with y=0
    xOffset = RenderPlayerName(card, playerData, xOffset, 0, 7)
    
    -- Multi-role icons with preference colors (max 3) - SECOND - uses LEFT anchor with y=0
    xOffset = RenderRoleIcons(card, playerData, xOffset, 0, 3)
    
    -- Separator - uses LEFT anchor with y=0 (already correct)
    local sepText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    sepText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    sepText:SetText("|")
    sepText:SetTextColor(0.7, 0.7, 0.7)
    xOffset = xOffset + 10
    
    -- Keystone info (use alias for compact display) - uses LEFT anchor with y=0
    xOffset = RenderKeystoneInfo(card, playerData, xOffset, 0, true)
    
    -- IO Score - uses RIGHT anchor with y=0
    RenderIOScore(card, playerData, xOffset, 0, true)
end

-- MARK: Opt-Out Card Content (Two-Line Layout - No IO)
function PlayerCard:CreateOptOutContent(card, playerData)
    -- Get configuration
    local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
    local padding = config.OPT_OUT_PADDING or 5
    
    local xOffset = padding
    
    -- Role icon (first role only) - vertically centered on left side
    if playerData.roles and playerData.roles[1] then
        local icon = CreateTrackedTexture(card, nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", card, "LEFT", xOffset, 0)
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
    
    -- Line 1: Player name (truncated to 7 chars) - top line
    local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -padding)
    
    local displayName = playerData.name or "Unknown"
    if #displayName > 7 then
        displayName = displayName:sub(1, 7)
    end
    nameText:SetText(displayName)
    nameText:SetTextColor(1, 1, 1)
    
    -- Line 2: Keystone info (short name) - bottom line
    if playerData.keystone then
        local dungeonText = "???"
        if NextKey222.DungeonNameService then
            dungeonText = NextKey222.DungeonNameService:GetAlias(playerData.keystone.dungeonID)
        end
        
        local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
        keyText:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", xOffset, padding)
        keyText:SetText(dungeonText .. " +" .. (playerData.keystone.level or 0))
        keyText:SetTextColor(1, 0.82, 0)
    end
end

-- MARK: Expanded Card Content (Native Frame Version)
function PlayerCard:CreateExpandedContent(card, playerData)
    local yOffset = 5
    local xOffset = 5
    
    -- Line 1: Class icon + Multi-role icons (left) | IO Score (right)
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
    
    -- CRITICAL FIX: When in a slot, override roles to show slot role instead of current spec
    local displayPlayerData = playerData
    if card.location and type(card.location) == "table" and card.location.type == "role_slot" then
        -- Create a copy with the slot's role for display purposes
        displayPlayerData = {}
        for k, v in pairs(playerData) do
            displayPlayerData[k] = v
        end
        -- Override roles to show the slot's role
        displayPlayerData.roles = {card.location.role}
        Debug:Dev("organizer_ui", "Expanded card showing slot role:", card.location.role, "for", playerData.name)
    end
    
    -- Multi-role icons with preference colors (up to 3) - use display data
    RenderRoleIcons(card, displayPlayerData, xOffset, yOffset, 3)
    
    -- IO Score (right-aligned on line 1, no separator)
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
    ioText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -yOffset)
    ioText:SetText(playerData.overallScore or 0)
    
    -- Use universal IO score color system
    local r, g, b = NextKey222.Utils:GetIOScoreColor(playerData.overallScore or 0)
    ioText:SetTextColor(r, g, b)
    
    yOffset = yOffset + 25
    
    -- Line 2: Player name - Current Spec (truncated if needed)
    local nameSpecText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
    nameSpecText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
    
    -- Build name-spec string
    local displayText = playerData.name or "Unknown"
    if playerData.specName then
        displayText = displayText .. " - " .. playerData.specName
    end
    
    -- Smart truncation with max width
    nameSpecText:SetWidth(160)  -- Increased for wider card
    nameSpecText:SetWordWrap(false)
    nameSpecText:SetJustifyH("LEFT")
    nameSpecText:SetText(displayText)
    
    -- Truncate with ellipsis if too long
    local actualWidth = nameSpecText:GetStringWidth()
    if actualWidth > 160 then
        local truncated = displayText
        while nameSpecText:GetStringWidth() > 150 and #truncated > 3 do
            truncated = truncated:sub(1, -2)
            nameSpecText:SetText(truncated .. "...")
        end
    end
    nameSpecText:SetTextColor(1, 1, 1)
    
    yOffset = yOffset + 18
    
    -- Lines 3-4: Keystone info (full name with wrapping)
    if playerData.keystone then
        local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
        keyText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
        
        local dungeonText = "Unknown"
        if NextKey222.DungeonNameService then
            dungeonText = NextKey222.DungeonNameService:GetFullName(playerData.keystone.dungeonID)
        end
        
        keyText:SetText(dungeonText .. " +" .. (playerData.keystone.level or 0))
        keyText:SetTextColor(1, 0.82, 0)
        keyText:SetWidth(135)  -- Reduced from 160 to wrap earlier and prevent last few characters from sticking out
        keyText:SetWordWrap(true)
        keyText:SetJustifyH("LEFT")
    end
    
    -- Keystone designation button (bottom-right corner)
    if playerData.keystone then
        local keystoneButton = self:CreateKeystoneButton(card, playerData)
        if keystoneButton then
            card.keystoneButton = keystoneButton
            table.insert(card.roleButtons, keystoneButton)  -- Track for cleanup
        end
    end
end

-- MARK: Keystone Designation Button
function PlayerCard:CreateKeystoneButton(card, playerData)
    -- Only create if card is in a group slot
    if not card.location or
       type(card.location) ~= "table" or
       card.location.type ~= "role_slot" then
        return nil
    end
    
    -- Create button frame in BOTTOM-RIGHT corner
    local keystoneButton = CreateFrame("Button", nil, card, "BackdropTemplate")
    keystoneButton:SetSize(20, 20)
    keystoneButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -3, 3)
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

-- MARK: Right-Click Preference Setting
function PlayerCard:EnableRightClickPreferences(card)
    -- Only enable for organizers
    if not self:IsOrganizerView() then
        return
    end
    
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Store the original OnClick handler if it exists
    local originalOnClick = card:GetScript("OnClick")
    
    card:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Check if card is currently polling (awaiting response)
            local isAwaitingPollResponse = false
            if NextKey222.RosterBoard and NextKey222.RosterBoard.activePoll then
                -- Check if this player is in addon users list
                local addonUsers = NextKey222.RosterBoard.activePoll.addonUsers or {}
                local isAddonUser = false
                for _, playerID in ipairs(addonUsers) do
                    if playerID == card.playerData.id then
                        isAddonUser = true
                        break
                    end
                end
                
                -- Check if they've responded
                local hasResponded = false
                if isAddonUser then
                    for _, response in ipairs(NextKey222.RosterBoard.activePoll.responses) do
                        if response.sender == card.playerData.id then
                            hasResponded = true
                            break
                        end
                    end
                    
                    isAwaitingPollResponse = not hasResponded
                end
            end
            
            -- Only allow manual preference setting if NOT currently polling
            if isAwaitingPollResponse then
                Debug:User("Cannot set preferences while player is responding to poll")
                return
            end
            
            -- Show manual preference dialog for this player
            NextKey222.PlayerCard:ShowManualPreferenceDialog(card.playerData)
        elseif originalOnClick then
            -- Call original click handler for left clicks
            originalOnClick(self, button)
        end
    end)
    
    Debug:Dev("organizer_ui", "Enabled right-click preferences for:", card.playerData.name)
end

-- MARK: Manual Preference Dialog
function PlayerCard:ShowManualPreferenceDialog(playerData)
    return NextKey222.SafeRun(function()
        if not playerData then
            Debug:Error("Cannot show manual preference dialog: playerData is nil")
            return
        end
        
        Debug:Dev("organizer_ui", "Showing manual preference dialog for:", playerData.name)
        
        -- Create a fake poll message for the survey dialog
        local pollMessage = {
            pollID = "manual-" .. tostring(GetTime()),
            organizerName = UnitName("player") .. "-" .. GetRealmName(),
            timeout = 300,  -- Longer timeout for manual entry
            isManualEntry = true,  -- Flag to identify manual entries
            targetPlayerID = playerData.id,
            targetPlayerName = playerData.name
        }
        
        -- Show the survey dialog for this specific player
        if NextKey222.SurveyDialog and NextKey222.SurveyDialog.ShowManualEntry then
            NextKey222.SurveyDialog:ShowManualEntry(pollMessage, playerData)
        else
            Debug:Error("SurveyDialog.ShowManualEntry not available")
        end
        
    end, "PlayerCard:ShowManualPreferenceDialog")
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
