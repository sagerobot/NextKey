-- MARK: Module Definition
local _, NextKey222 = ...

local CardView = {}
NextKey222.CardView = CardView
NextKey222.RegisterModule("CardView", CardView)

local Debug = NextKey222.Debug

-- MARK: Region Pool Structure
-- Each card stores references to all created regions for proper cleanup
local function InitializeRegionPool(card)
    card.regions = {
        textures = {},      -- All texture regions
        fontStrings = {},   -- All font string regions
        activeCount = 0     -- Track how many regions are in use
    }
end

-- MARK: Region Cleanup
local function ClearCardRegions(card)
    if not card.regions then return end
    
    -- Properly destroy all textures
    for _, texture in ipairs(card.regions.textures) do
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetTexture(nil)  -- Release texture memory
    end
    
    -- Properly destroy all font strings
    for _, fontString in ipairs(card.regions.fontStrings) do
        fontString:Hide()
        fontString:SetText("")
        fontString:ClearAllPoints()
    end
    
    -- Properly destroy role icon buttons (created with CreateFrame)
    if card.roleButtons then
        for _, button in ipairs(card.roleButtons) do
            if button then
                -- MEMORY LEAK FIX: Nil all script handlers
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
    
    Debug:Trace("card_view", "Cleared all regions from card:", card.playerID)
end

-- MARK: Region Helpers
-- Region creation with tracking
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

-- MARK: Tooltip Handler
local function ShowRoleTooltip(roleButton, roleInfo, playerData)
    GameTooltip:SetOwner(roleButton, "ANCHOR_RIGHT")
    
    -- Normalize role display: DAMAGER → DPS for consistency
    local displayRole = roleInfo.role
    if displayRole:upper() == "DAMAGER" then
        displayRole = "DPS"
    end
    
    GameTooltip:SetText(displayRole, 1, 1, 1)
    
    -- Show current spec with preference color
    if playerData.specName then
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

-- MARK: Render Helpers

-- Helper: Render multi-role icons with preference colors
local function RenderRoleIcons(card, playerData, xOffset, yOffset, maxRoles)
    if not playerData.roles then
        Debug:Dev("card_view", "RenderRoleIcons: playerData.roles is nil for", playerData.name)
        return xOffset + (maxRoles * 20)
    end
    
    if #playerData.roles == 0 then
        Debug:Dev("card_view", "RenderRoleIcons: playerData.roles is empty array for", playerData.name)
        return xOffset + (maxRoles * 20)
    end
    
    if not card.roleButtons then
        card.roleButtons = {}
    end
    
    local rolesToShow = {}
    
    -- Collect roles with preferences (up to maxRoles)
    if playerData.specPreferences then
        Debug:Dev("card_view", "Player", playerData.name, "has specPreferences - checking for non-none roles")
        for role, preference in pairs(playerData.specPreferences) do
            Debug:Dev("card_view", "  Role:", role, "Preference:", preference)
            if preference ~= "none" then
                table.insert(rolesToShow, {
                    role = role,
                    preference = preference
                })
                Debug:Dev("card_view", "    Added to rolesToShow")
            end
        end
        
        -- Fallback if all specPreferences are "none"
        if #rolesToShow == 0 and playerData.roles then
            Debug:Dev("card_view", "All specPreferences are 'none' - using roles array fallback for", playerData.name)
            for i, role in ipairs(playerData.roles) do
                table.insert(rolesToShow, {
                    role = role,
                    preference = "play"
                })
            end
        end
    else
        Debug:Dev("card_view", "Player", playerData.name, "has NO specPreferences - using roles array")
        if playerData.roles then
            for i, role in ipairs(playerData.roles) do
                Debug:Dev("card_view", "  Adding role from roles array:", role)
                table.insert(rolesToShow, {
                    role = role,
                    preference = "play"
                })
            end
        else
            Debug:Dev("card_view", "Player", playerData.name, "has NO roles array either!")
        end
    end
    
    Debug:Dev("card_view", "RenderRoleIcons: rolesToShow count =", #rolesToShow, "for", playerData.name)
    
    local roleCount = math.min(#rolesToShow, maxRoles)
    local isCompact = (yOffset == nil or yOffset == 0)
    local startOffset = xOffset
    
    for i = 1, roleCount do
        local roleInfo = rolesToShow[i]
        
        Debug:Dev("card_view", string.format("Creating role button %d/%d for %s - role: %s preference: %s",
            i, roleCount, playerData.name, roleInfo.role, roleInfo.preference))
        
        -- Create invisible button frame for tooltip support
        local roleButton = CreateFrame("Button", nil, card)
        roleButton:SetSize(18, 18)
        
        if isCompact then
            roleButton:SetPoint("LEFT", card, "LEFT", xOffset, 0)
            Debug:Dev("card_view", string.format("  Positioned at xOffset=%d (compact mode)", xOffset))
        else
            roleButton:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
            Debug:Dev("card_view", string.format("  Positioned at xOffset=%d yOffset=%d (expanded mode)", xOffset, yOffset))
        end
        
        roleButton:EnableMouse(true)
        roleButton:Show()
        
        table.insert(card.roleButtons, roleButton)
        
        Debug:Dev("card_view", string.format("  Button created and shown - total roleButtons: %d", #card.roleButtons))
        
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
local function RenderKeystoneInfo(card, playerData, xOffset, yOffset, useAlias)
    if not playerData.keystone then return xOffset end
    
    local dungeonText
    if useAlias then
        dungeonText = "???"
        if NextKey222.DungeonNameService then
            dungeonText = NextKey222.DungeonNameService:GetAlias(playerData.keystone.dungeonID)
        end
    else
        dungeonText = "Unknown"
        if NextKey222.DungeonNameService then
            dungeonText = NextKey222.DungeonNameService:GetFullName(playerData.keystone.dungeonID)
        end
    end
    
    local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    if useAlias then
        keyText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    else
        keyText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
    end
    keyText:SetText(dungeonText .. " +" .. (playerData.keystone.level or 0))
    keyText:SetTextColor(1, 0.82, 0)
    
    -- Add width constraint and word wrap for expanded cards
    if not useAlias then
        keyText:SetWidth(130)
        keyText:SetWordWrap(true)
        keyText:SetJustifyH("LEFT")
    end
    
    if useAlias then
        return xOffset + 45
    else
        return xOffset
    end
end

-- Helper: Render player name
local function RenderPlayerName(card, playerData, xOffset, yOffset, truncateLength)
    local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    
    if truncateLength then
        nameText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
    else
        nameText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
    end
    
    local displayName = playerData.name or "Unknown"
    if truncateLength and #displayName > truncateLength then
        displayName = displayName:sub(1, truncateLength)
    end
    
    nameText:SetText(displayName)
    nameText:SetTextColor(1, 1, 1)
    
    return xOffset + 55
end

-- Helper: Render IO score
local function RenderIOScore(card, playerData, xOffset, yOffset, isCompact)
    local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
    
    if isCompact then
        ioText:SetPoint("RIGHT", card, "RIGHT", -5, 0)
    else
        ioText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -yOffset)
    end
    
    ioText:SetText("[" .. (playerData.overallScore or 0) .. "]")
    
    -- Use universal IO score color system
    local r, g, b = NextKey222.ScoringUtils:GetIOScoreColor(playerData.overallScore or 0)
    ioText:SetTextColor(r, g, b)
end

-- MARK: Helper Functions

--- Get display mode based on location
-- @param location string|table - Player location
-- @return string - Display mode: "compact", "expanded", or "opt_out"
local function GetDisplayMode(location)
	if not location then
		return "compact"  -- Default to compact if no location
	end
	
	if location == "bench" then
		return "compact"
	elseif location == "opt_out" then
		return "opt_out"
	elseif type(location) == "table" and location.zone == "slot" then
		return "expanded"
	end
	
	return "compact"  -- Safe default
end

-- MARK: Card Creation

--- Create a new card view
-- @param playerID string - Player identifier
-- @param parentFrame Frame - Parent frame for the card
-- @param zone string - Zone identifier ("bench", "slots", "opt_out")
-- @return Frame - The created card frame
function CardView:Create(playerID, parentFrame, zone)
	return NextKey222.SafeRun(function()
		if not playerID then
			Debug:Error("CardView:Create called with nil playerID")
			return nil
		end
		
		-- Create frame with BackdropTemplate
		local card = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
		
		-- Store ONLY playerID and zone (no playerData, no location, no displayMode)
		card.playerID = playerID
		card.zone = zone
		
		-- Set initial size (will be adjusted by display mode)
		card:SetSize(200, 40)
		
		-- Set backdrop
		card:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
		})
		card:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
		card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
		
		-- CRITICAL: Enable mouse for drag handlers
		card:EnableMouse(true)
		
		-- Initialize region pool for tracking
		InitializeRegionPool(card)
		
		-- Initialize role buttons array for proper cleanup
		card.roleButtons = {}
		
		-- Store class color reference (will be set during first Update)
		card.classColor = {r = 0.5, g = 0.5, b = 0.5}
		
		-- Enable drag via DragController
		if NextKey222.DragController then
			NextKey222.DragController:EnableDrag(card)
		end
		
		Debug:Dev("card_view", "Created card for playerID:", playerID, "zone:", zone)
		
		return card
	end, "CardView:Create")
end

-- MARK: Card Rendering

--- Update card content from state
-- @param card Frame - The card frame to update
function CardView:Update(card)
	return NextKey222.SafeRun(function()
				end
			end
			
		elseif displayMode == "opt_out" then
			-- Use UIConfig for opt-out card dimensions
			local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
			local width = config.OPT_OUT_CARD_WIDTH or 90
			local height = config.OPT_OUT_CARD_HEIGHT or 40
			local padding = config.OPT_OUT_PADDING or 5
			
			card:SetSize(width, height)
			
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
			
			-- Gray out the card
			card:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
			card:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
		end
		
		Debug:Dev("card_view", "Rendered card content for", playerData.id, "mode:", displayMode)
	end, "CardView:RenderContent")
	end
	
	-- MARK: Keystone Button
	
	--- Create keystone designation button for expanded slot cards
	-- @param card Frame - The card frame
	-- @param playerData table - Player data
	-- @param location table - Slot location {zone="slot", group=N, slot=N}
	-- @return Frame - The button frame
	function CardView:CreateKeystoneButton(card, playerData, location)
		return NextKey222.SafeRun(function()
			-- Create button frame in BOTTOM-RIGHT corner
			local keystoneButton = CreateFrame("Button", nil, card, "BackdropTemplate")
			keystoneButton:SetSize(20, 20)
			keystoneButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -3, 3)
			keystoneButton:EnableMouse(true)
			
			-- Backdrop for visual feedback
			keystoneButton:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Buttons\\WHITE8X8",
				tile = false, edgeSize = 2,
				insets = {left = 2, right = 2, top = 2, bottom = 2}
			})
			keystoneButton:SetBackdropColor(0, 0, 0, 0.7)
			keystoneButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
			
			-- Star icon
			local icon = keystoneButton:CreateTexture(nil, "ARTWORK")
			icon:SetSize(16, 16)
			icon:SetPoint("CENTER")
			icon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
			icon:SetTexCoord(0, 0.5625, 0, 0.5625)
			icon:SetVertexColor(0.8, 0.8, 0.8)  -- Gray by default
			
			-- Click handler
			keystoneButton:SetScript("OnClick", function()
				NextKey222.RosterBoard:DesignateGroupKeystone(
					location.group,
					playerData.keystone,
					playerData.id
				)
			end)
			
			-- Hover effect with tooltip
			keystoneButton:SetScript("OnEnter", function(self)
				local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
					location.group,
					playerData.id
				)
				
				if not isDesignated then
					icon:SetVertexColor(1.0, 1.0, 1.0)  -- Brighten
				end
				
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
				local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
					location.group,
					playerData.id
				)
				
				if not isDesignated then
					icon:SetVertexColor(0.8, 0.8, 0.8)  -- Reset
				end
				
				GameTooltip:Hide()
			end)
			
			keystoneButton.icon = icon
			
			Debug:Dev("card_view", "Created keystone button for:", playerData.name)
			
			return keystoneButton
			
		end, "CardView:CreateKeystoneButton")
	end
	
	-- MARK: Cleanup

--- Destroy card and clean up resources
-- @param card Frame - The card frame to destroy
function CardView:Destroy(card)
	return NextKey222.SafeRun(function()
		if not card then return end
		
		-- Hide and clear parent
		card:Hide()
		card:SetParent(nil)
		
		-- Clear all points
		card:ClearAllPoints()
		
		Debug:Dev("card_view", "Destroyed card for", card.playerID)
	end, "CardView:Destroy")
end