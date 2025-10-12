-- UI Components - Shared rendering components for NextKey
-- Provides reusable card, button, and backdrop factory functions
-- Following Ace3 best practices and DRY principles

local _, NextKey222 = ...
local AceGUI = LibStub("AceGUI-3.0")

local Components = {}
NextKey222.UIComponents = Components

-- Register with module system
NextKey222.RegisterModule("UIComponents", Components)

-- MARK: Spec to Role Mapping
-- Definitive mapping of all specialization IDs to their roles
-- This is more reliable than WoW API calls and ensures correct role display
local SPEC_TO_ROLE = {
    -- Death Knight
    [250] = "TANK",     -- Blood
    [251] = "DAMAGER",  -- Frost
    [252] = "DAMAGER",  -- Unholy
    
    -- Demon Hunter
    [577] = "DAMAGER",  -- Havoc
    [581] = "TANK",     -- Vengeance
    
    -- Druid
    [102] = "DAMAGER",  -- Balance
    [103] = "DAMAGER",  -- Feral
    [104] = "TANK",     -- Guardian
    [105] = "HEALER",   -- Restoration
    
    -- Evoker
    [1467] = "DAMAGER", -- Devastation
    [1468] = "HEALER",  -- Preservation
    [1473] = "DAMAGER", -- Augmentation
    
    -- Hunter
    [253] = "DAMAGER",  -- Beast Mastery
    [254] = "DAMAGER",  -- Marksmanship
    [255] = "DAMAGER",  -- Survival
    
    -- Mage
    [62] = "DAMAGER",   -- Arcane
    [63] = "DAMAGER",   -- Fire
    [64] = "DAMAGER",   -- Frost
    
    -- Monk
    [268] = "TANK",     -- Brewmaster
    [270] = "HEALER",   -- Mistweaver
    [269] = "DAMAGER",  -- Windwalker
    
    -- Paladin
    [65] = "HEALER",    -- Holy
    [66] = "TANK",      -- Protection
    [70] = "DAMAGER",   -- Retribution
    
    -- Priest
    [256] = "HEALER",   -- Discipline
    [257] = "HEALER",   -- Holy
    [258] = "DAMAGER",  -- Shadow
    
    -- Rogue
    [259] = "DAMAGER",  -- Assassination
    [260] = "DAMAGER",  -- Outlaw
    [261] = "DAMAGER",  -- Subtlety
    
    -- Shaman
    [262] = "DAMAGER",  -- Elemental
    [263] = "DAMAGER",  -- Enhancement
    [264] = "HEALER",   -- Restoration
    
    -- Warlock
    [265] = "DAMAGER",  -- Affliction
    [266] = "DAMAGER",  -- Demonology
    [267] = "DAMAGER",  -- Destruction
    
    -- Warrior
    [71] = "DAMAGER",   -- Arms
    [72] = "DAMAGER",   -- Fury
    [73] = "TANK",      -- Protection
}

-- MARK: Role Detection Helper
-- Shared function for reliable role detection from specID

--- Gets the role for a given specID using the definitive mapping table
-- @param specID number The specialization ID
-- @param fallbackRole string Optional fallback role if specID not found (default: "DAMAGER")
-- @return string The role: "TANK", "HEALER", or "DAMAGER"
function Components:GetRoleFromSpecID(specID, fallbackRole)
    if specID and SPEC_TO_ROLE[specID] then
        return SPEC_TO_ROLE[specID]
    end
    return fallbackRole or "DAMAGER"
end

-- MARK: Backdrop Factory
-- Creates standardized backdrop configurations for different card types

local BACKDROP_CONFIGS = {
    keystone = {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        bgColor = { 0, 0, 0, 0.55 },
        borderColor = { 0.35, 0.35, 0.35, 1 }
    },
    
    keystone_compact = {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
        bgColor = { 0, 0, 0, 0.45 },
        borderColor = { 0.35, 0.35, 0.35, 1 }
    },
    
    dungeon = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
        bgColor = { 0, 0, 0, 0.8 },
        borderColor = { 0.5, 0.5, 0.5, 1 }
    }
}

--- Creates a backdrop frame with standard configuration
-- @param parent Frame The parent frame
-- @param type string The backdrop type: "keystone", "keystone_compact", "dungeon"
-- @return Frame The created backdrop frame
function Components:CreateBackdrop(parent, type)
    local config = BACKDROP_CONFIGS[type]
    if not config then
        NextKey222.Debug:Dev("components", "Unknown backdrop type:", type)
        config = BACKDROP_CONFIGS.keystone
    end
    
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    frame:SetBackdrop({
        bgFile = config.bgFile,
        edgeFile = config.edgeFile,
        tile = config.tile,
        tileSize = config.tileSize,
        edgeSize = config.edgeSize,
        insets = config.insets
    })
    frame:SetBackdropColor(unpack(config.bgColor))
    frame:SetBackdropBorderColor(unpack(config.borderColor))
    
    return frame
end

-- MARK: Score Retrieval System
-- Centralized player score retrieval with fallback logic

--- Gets player's total IO score from multiple sources
-- @param playerInfo table Player info containing ownerName, rating, rioScore, etc.
-- @return number The player's IO score (0 if not found)
function Components:GetPlayerScore(playerInfo)
    if not playerInfo then return 0 end
    
    local score = 0
    
    -- Try multiple score sources (LibOpenRaid uses 'rating' field)
    score = playerInfo.rating or playerInfo.rioScore or playerInfo.io or playerInfo.score or 0
    
    -- For the actual player, try getting current live score
    local ownerName = playerInfo.ownerName or "Unknown"
    if NextKey222.Addon.IsPlayerOwner and NextKey222.Addon:IsPlayerOwner(ownerName) then
        if NextKey222.Addon and NextKey222.Addon.GetRaiderIOTotalScore then
            local playerScore = NextKey222.Addon:GetRaiderIOTotalScore()
            if playerScore and playerScore > score then
                score = playerScore
            end
        end
    end
    
    -- Check RaiderIO API for additional data
    if RaiderIO and RaiderIO.GetProfile then
        local profile = RaiderIO.GetProfile(ownerName)
        if profile and profile.mythicKeystoneProfile then
            local rioScore = profile.mythicKeystoneProfile.currentScore
            if rioScore and rioScore > score then
                score = rioScore
            end
        end
    end
    
    return score
end

--- Normalizes player name with realm information
-- @param rawName string The raw player name
-- @return string Normalized name with realm
function Components:NormalizePlayerName(rawName)
    if not rawName or rawName == "Unknown" then 
        return rawName or "Unknown"
    end
    
    -- Add current realm if no realm specified
    if not string.find(rawName, "-") then
        local currentRealm = GetRealmName()
        if currentRealm and currentRealm ~= "" then
            return rawName .. "-" .. currentRealm
        end
    end
    
    return rawName
end

-- MARK: Button Factory System
-- Standardized button creation with consistent styling

local BUTTON_CONFIGS = {
    select = {
        size = { 80, 22 },
        text = "Select",
        template = "UIPanelButtonTemplate"
    },
    
    select_compact = {
        size = { 50, 18 },
        text = "Select", 
        template = "UIPanelButtonTemplate"
    },
    
    teleport = {
        size = { 70, 24 },
        text = "Teleport",
        template = "UIPanelButtonTemplate"
    },
    
    loot = {
        size = { 50, 24 },
        text = "Loot",
        template = "UIPanelButtonTemplate"
    },
    
    preference = {
        size = { 25, 24 },
        text = "+",
        template = "UIPanelButtonTemplate"
    }
}

--- Creates a standardized button
-- @param parent Frame The parent frame
-- @param type string Button type: "select", "select_compact", "teleport", "loot", "preference"
-- @param onClick function Click callback function
-- @param onEnter function Optional enter callback for tooltips
-- @return Button The created button frame
function Components:CreateButton(parent, type, onClick, onEnter)
    local config = BUTTON_CONFIGS[type]
    if not config then
        NextKey222.Debug:Dev("components", "Unknown button type:", type)
        config = BUTTON_CONFIGS.select
    end
    
    local button = CreateFrame("Button", nil, parent, config.template)
    button:SetSize(unpack(config.size))
    button:SetText(config.text)
    button:SetMotionScriptsWhileDisabled(true)
    
    if onClick then
        button:SetScript("OnClick", onClick)
    end
    
    if onEnter then
        button:SetScript("OnEnter", onEnter)
        button:SetScript("OnLeave", GameTooltip_Hide)
    end
    
    return button
end

-- MARK: Icon Creation System
-- Standardized class icon, role icon, and dungeon icon creation

--- Creates a class icon texture
-- @param parent Frame The parent frame
-- @param classToken string The class token (e.g., "WARRIOR")
-- @param size number Icon size (default 32)
-- @param playerData table Optional player data for tooltip (ownerName, classToken, specName, role)
-- @return Texture The created icon texture
function Components:CreateClassIcon(parent, classToken, size, playerData)
    size = size or 32
    
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size)
    icon:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
    
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken or "WARRIOR"]
    if coords then
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
    
    -- Attach player tooltip if player data is provided
    if playerData then
        self:AttachPlayerTooltip(icon, playerData)
    end
    
    return icon
end

--- Creates a role icon texture using Blizzard's standard role icons
-- @param parent Frame The parent frame
-- @param role string The role ("TANK", "HEALER", "DAMAGER")
-- @param size number Icon size (default 16, smaller than class icon)
-- @return FontString The created role indicator (using colored text as reliable fallback)
function Components:CreateRoleIcon(parent, role, size)
    size = size or 16
    
    -- Normalize role to uppercase and provide fallback
    local normalizedRole = role and string.upper(role) or "DAMAGER"
    
    -- Create a FontString with colored role abbreviations
    local roleText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    
    -- Set role indicator with appropriate color and letter
    local roleDisplay = ""
    local r, g, b = 1, 1, 1
    
    if normalizedRole == "TANK" then
        roleDisplay = "T"
        r, g, b = 0.31, 0.45, 0.63  -- Blue for tank (matches WoW tank color)
    elseif normalizedRole == "HEALER" then
        roleDisplay = "H"
        r, g, b = 0.25, 0.78, 0.25  -- Green for healer (matches WoW healer color)
    else -- DAMAGER or DPS
        roleDisplay = "D"
        r, g, b = 0.77, 0.12, 0.23  -- Red for DPS (matches WoW DPS color)
    end
    
    roleText:SetText(roleDisplay)
    roleText:SetTextColor(r, g, b, 1)
    roleText:SetFont("Fonts\\FRIZQT__.TTF", size + 2, "OUTLINE, THICK")
    roleText:SetJustifyH("CENTER")
    
    -- Add debug info
    if NextKey222.Debug then
        NextKey222.Debug:Dev("components", string.format("Creating role indicator: role=%s, display=%s, color=rgb(%.2f,%.2f,%.2f)",
            normalizedRole, roleDisplay, r, g, b))
    end
    
    return roleText
end

--- Creates a dungeon icon using AceGUI
-- @param dungeonID number The NextKey dungeon ID
-- @param dungeonData table Dungeon data containing mapArtID
-- @param size number Icon size (default 32)
-- @return AceGUI-Icon The created icon widget
function Components:CreateDungeonIcon(dungeonID, dungeonData, size)
    size = size or 32
    
    local iconWidget = AceGUI:Create("Icon")
    
    if dungeonData and dungeonData.mapArtID then
        -- Convert NextKey dungeon ID to proper Challenge Mode map ID for icon lookup
        local challengeModeMapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
        local iconTexture = select(4, C_ChallengeMode.GetMapUIInfo(challengeModeMapID)) or "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider"
        iconWidget:SetImage(iconTexture)
    else
        iconWidget:SetImage("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider") -- Default dungeon icon
    end
    
    iconWidget:SetImageSize(size, size)
    iconWidget:SetWidth(size + 8) -- Add some padding
    
    return iconWidget
end

-- MARK: Text Formatting Utilities
-- Consistent text formatting and coloring

--- Formats player name with class colors and score
-- @param playerName string The player name
-- @param classToken string The class token
-- @param score number The player's IO score (optional)
-- @return string Formatted colored text
function Components:FormatPlayerNameWithScore(playerName, classToken, score)
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken or "WARRIOR"]
    local ownerColor = classColor and classColor.colorStr or "ffffffff"
    
    local nameDisplay = string.format("|c%s%s|r", ownerColor, playerName or "Unknown")
    if score and score > 0 then
        nameDisplay = string.format("%s |cffFFD700(%d)|r", nameDisplay, score)
    end
    
    return nameDisplay
end

--- Formats dungeon and keystone level with colors
-- @param dungeonName string The dungeon name
-- @param level number The keystone level
-- @return string Formatted colored text
function Components:FormatKeystoneDisplay(dungeonName, level)
    return string.format("Keystone: %s |cff4aa3ff+%d|r", dungeonName or "Unknown", level or 0)
end

-- MARK: Container Factory
-- Standardized AceGUI container creation

--- Creates a card container with consistent settings
-- @param height number Container height
-- @param compact boolean Whether to use compact layout
-- @return AceGUI-SimpleGroup The created container
function Components:CreateCardContainer(height, compact)
    local container = AceGUI:Create("SimpleGroup")
    container:SetFullWidth(true)
    container:SetLayout("Fill")
    container:SetAutoAdjustHeight(false)
    container:SetHeight(height or (compact and 28 or 88))
    
    return container
end

-- MARK: Tooltip System
-- Standardized tooltip creation and management

--- Creates a tooltip for player class icon with detailed information
-- @param icon Texture The class icon texture to attach tooltip to
-- @param playerData table Player information containing ownerName, classToken (for display fallback)
function Components:AttachPlayerTooltip(icon, playerData)
    if not icon or not playerData then return end
    
    icon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
        
        -- Extract player name and server
        local fullName = playerData.ownerName or "Unknown"
        local playerName = fullName:match("^([^%-]+)") or fullName
        local serverName = fullName:match("-(.+)") or GetRealmName()
        
        -- Fetch FRESH profile data when tooltip is shown (ensures live updates)
        local liveProfile = nil
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            liveProfile = NextKey222.ProfilesService:GetProfile(fullName)
            if NextKey222.Debug then
                NextKey222.Debug:Dev("components", string.format("Tooltip GetProfile for %s: profile=%s, specID=%s, role=%s",
                    fullName,
                    liveProfile and "exists" or "nil",
                    liveProfile and liveProfile.specID or "nil",
                    liveProfile and liveProfile.role or "nil"))
            end
        end
        
        -- Format class name from token (use live data if available)
        local className = (liveProfile and liveProfile.class) or playerData.classToken or "Unknown"
        local classMapping = {
            WARRIOR = "Warrior",
            PALADIN = "Paladin",
            HUNTER = "Hunter",
            ROGUE = "Rogue",
            PRIEST = "Priest",
            DEATHKNIGHT = "Death Knight",
            SHAMAN = "Shaman",
            MAGE = "Mage",
            WARLOCK = "Warlock",
            MONK = "Monk",
            DRUID = "Druid",
            DEMONHUNTER = "Demon Hunter",
            EVOKER = "Evoker"
        }
        className = classMapping[className] or className
        
        -- Get LIVE role using spec-to-role mapping (most reliable)
        local role = "DAMAGER"
        local specName = nil
        local usedSpecID = nil
        
        -- Determine best specID source (live profile first, then playerData fallback)
        if liveProfile and liveProfile.specID then
            usedSpecID = liveProfile.specID
            specName = liveProfile.specName
        elseif playerData and playerData.specID then
            usedSpecID = playerData.specID
            specName = playerData.specName
            if NextKey222.Debug then
                NextKey222.Debug:Dev("components", string.format("Using playerData specID fallback: %d", usedSpecID))
            end
        end
        
        -- Primary: Use spec-to-role mapping table (most reliable method)
        if usedSpecID and SPEC_TO_ROLE[usedSpecID] then
            role = SPEC_TO_ROLE[usedSpecID]
            if NextKey222.Debug then
                NextKey222.Debug:Dev("components", string.format("✓ Spec-to-role mapping SUCCESS: player=%s, specID=%d, specName=%s, role=%s",
                    playerName, usedSpecID, specName or "nil", role))
            end
        -- Fallback 1: Try WoW API if mapping not found
        elseif usedSpecID and GetSpecializationInfoByID then
            local _, apiSpecName, _, _, _, specRole = GetSpecializationInfoByID(usedSpecID)
            if specRole and specRole ~= "" then
                role = specRole
                specName = apiSpecName or specName
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("components", string.format("WoW API role: player=%s, specID=%d, role=%s",
                        playerName, usedSpecID, specRole))
                end
            end
        -- Fallback 2: Use profile role directly
        elseif liveProfile and liveProfile.role then
            role = liveProfile.role
            specName = liveProfile.specName or specName
            if NextKey222.Debug then
                NextKey222.Debug:Dev("components", string.format("Using profile role: player=%s, role=%s",
                    playerName, role))
            end
        end
        
        -- Final check: Detect and fix role corruption (when role equals class name)
        local classTokenUpper = string.upper(playerData.classToken or "")
        if role == classTokenUpper or role == className then
            if NextKey222.Debug then
                NextKey222.Debug:Dev("components", string.format("! Role corruption still present: role='%s' equals class, forcing DAMAGER",
                    role))
            end
            role = "DAMAGER" -- Safe fallback when role data is corrupted
        end
        
        -- Debug logging for tooltip data
        if fullName and (fullName:find("Ryuza") or fullName:find("Petalz")) then
            local debugMsg = string.format("Tooltip Debug (LIVE): ownerName=%s, role=%s, classToken=%s, specName=%s, specID=%s",
                fullName or "nil",
                role or "nil",
                className or "nil",
                specName or "nil",
                liveProfile and liveProfile.specID or "nil")
            if NextKey222.Debug then
                NextKey222.Debug:Dev("components", debugMsg)
            end
        end
        
        local roleColor = {1, 1, 1} -- Default white
        if role == "TANK" then
            roleColor = {0.31, 0.45, 0.63}  -- Blue
        elseif role == "HEALER" then
            roleColor = {0.25, 0.78, 0.25}  -- Green
        elseif role == "DAMAGER" then
            roleColor = {0.77, 0.12, 0.23}  -- Red
        end
        
        -- Line 1: Name and Server
        local nameLine = string.format("%s - %s", playerName, serverName)
        GameTooltip:SetText(nameLine, 1, 1, 1, true)
        
        -- Line 2: Class and Specialization (use live data)
        local classSpecLine = className
        if specName and specName ~= "" then
            classSpecLine = string.format("%s (%s)", className, specName)
        end
        GameTooltip:AddLine(classSpecLine, 1, 1, 1)
        
        -- Line 3: Role (with color) - now shows live role data
        GameTooltip:AddLine(string.format("Role: %s", role), roleColor[1], roleColor[2], roleColor[3])
        
        -- Line 4: Heroism/Battle Res capabilities (use live profile data)
        local capabilities = {}
        local hasHeroism = false
        local hasBattleRes = false
        
        if liveProfile and liveProfile.capabilities then
            hasHeroism = liveProfile.capabilities.heroism or false
            hasBattleRes = liveProfile.capabilities.battleRes or false
        elseif playerData then
            -- Fallback to playerData if no live profile
            hasHeroism = playerData.hasHeroism or false
            hasBattleRes = playerData.hasBattleRes or false
        end
        
        if hasHeroism then
            table.insert(capabilities, "|cff0070ddHeroism|r")
        end
        if hasBattleRes then
            table.insert(capabilities, "|cffa335eeBattle Res|r")
        end
        
        if #capabilities > 0 then
            local capabilityText = table.concat(capabilities, " / ")
            GameTooltip:AddLine("Utilities: " .. capabilityText, 1, 1, 1)
        end
        
        GameTooltip:Show()
    end)
    
    icon:SetScript("OnLeave", GameTooltip_Hide)
end

--- Creates a tooltip for IO gain display
-- @param button Frame The button to attach tooltip to
-- @param keyInfo table Keystone information
-- @param ioRange table IO gain range data
-- @param uiRef table Reference to UI instance for method calls
function Components:AttachIOGainTooltip(button, keyInfo, ioRange, uiRef)
    if not button or not keyInfo or not ioRange or not uiRef then return end
    
    button:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        
        -- Get dungeon name and owner info for header
        local dungeonName = "Unknown Dungeon"
        local ownerName = keyInfo.ownerName or "Unknown"
        if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
            dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID) or ("Dungeon " .. keyInfo.dungeonID)
        end
        
        -- Enhanced header with dungeon, level, and owner information
        local keystoneLevel = keyInfo.level or 0
        local headerText = string.format("%s (+%d) - %s's Key", dungeonName, keystoneLevel, ownerName:match("^([^%-]+)") or ownerName)
        GameTooltip:SetText(headerText, 1, 1, 1, 1, true)
        GameTooltip:AddLine("Group IO Gain Potential", 0.9, 0.9, 1)
        
        -- Add breakpoint information if available
        if keystoneLevel > 0 and NextKey222.IOCalculator and ioRange.playerBreakdown then
            local breakpointRanges = uiRef:CalculateBreakpointRanges(keyInfo, ioRange.playerBreakdown)
            
            if breakpointRanges then
                GameTooltip:AddLine(string.format("Untimed: +%d Group IO (+%d Avg)", 
                    math.floor(breakpointRanges.untimed.total), 
                    math.floor(breakpointRanges.untimed.average)), 0.8, 0.4, 0.4)
                GameTooltip:AddLine(string.format("Timed: +%d Group IO (+%d Avg)", 
                    math.floor(breakpointRanges.timed.total), 
                    math.floor(breakpointRanges.timed.average)), 1, 1, 0.4)
                GameTooltip:AddLine(string.format("+2: +%d Group IO (+%d Avg)", 
                    math.floor(breakpointRanges.plus2.total), 
                    math.floor(breakpointRanges.plus2.average)), 0.4, 1, 0.4)
                GameTooltip:AddLine(string.format("+3: +%d Group IO (+%d Avg)", 
                    math.floor(breakpointRanges.plus3.total), 
                    math.floor(breakpointRanges.plus3.average)), 0.2, 1, 0.2)
            else
                -- Fallback display
                GameTooltip:AddLine(string.format("+%d Group IO", math.floor(ioRange.expected)), 0, 1, 0)
                GameTooltip:AddLine(string.format("Range: +%d to +%d Group IO", math.floor(ioRange.min), math.floor(ioRange.max)), 1, 1, 1)
            end
        end
        
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

-- MARK: Initialization
function Components:Initialize()
    NextKey222.Debug:Dev("components", "UI Components system initialized")
    return true
end

return Components