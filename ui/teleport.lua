-- MARK: Initialization
local _, NextKey222 = ...
local addon = NextKey222.Addon
if not addon then return end

-- MARK: Constants
local HEARTH_ITEM_ID = 6948
local SEASON_PORTALS = {
    -- The War Within Season 3 dungeon teleports.
    [503] = { mapID = 503, spellID = 445417, name = "Ara-Kara, City of Echoes", alias = "Ara", destination = "Ara-Kara, City of Echoes" }, -- Real ID for Ara-Kara
    [524] = { mapID = 524, spellID = 445414, name = "The Dawnbreaker", alias = "Dawn", destination = "The Dawnbreaker" },
    [526] = { mapID = 526, spellID = 1237215, name = "Eco-Dome Al'dani", alias = "Eco", destination = "Eco-Dome Al'dani" },
    [377] = { mapID = 377, spellID = 354465, name = "Halls of Atonement", alias = "Halls", destination = "Halls of Atonement" },
    [525] = { mapID = 525, spellID = 1216786, name = "Operation: Floodgate", alias = "Flood", destination = "Operation: Floodgate" },
    [523] = { mapID = 523, spellID = 445444, name = "Priory of the Sacred Flame", alias = "Priory", destination = "Priory of the Sacred Flame" },
    [401] = { mapID = 401, spellID = 367416, name = "Tazavesh: Streets of Wonder", alias = "Streets", destination = "Tazavesh: Streets of Wonder" },
    [402] = { mapID = 402, spellID = 367416, name = "Tazavesh: So'leah's Gambit", alias = "Gambit", destination = "Tazavesh: So'leah's Gambit" },
}
local SPELL_BANK_PLAYER = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
local SPELL_BANK_PET = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1

local function safeGetItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemID)
    end
    if GetItemInfo then
        return GetItemInfo(itemID)
    end
end

local function getHearthName()
    local name = select(1, safeGetItemInfo(HEARTH_ITEM_ID))
    return name or "Hearthstone"
end

local function safeGetSpellInfo(spellID)
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID
        end
    end
    return nil, nil, nil
end

local function playerKnowsSpell(spellID)
    if not spellID then return false end
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
        if C_SpellBook.IsSpellInSpellBook(spellID, SPELL_BANK_PLAYER) then
            return true
        end
        if C_SpellBook.IsSpellInSpellBook(spellID, SPELL_BANK_PET) then
            return true
        end
    end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then return true end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    return false
end

local cachedPlayerFullName
local cachedPlayerShortName

local function getPlayerFullName()
    if cachedPlayerFullName then
        return cachedPlayerFullName
    end
    if UnitFullName then
        local name, realm = UnitFullName("player")
        if name and name ~= "" then
            if realm and realm ~= "" then
                cachedPlayerFullName = string.format("%s-%s", name, realm)
            else
                cachedPlayerFullName = name
            end
        end
    end
    if not cachedPlayerFullName then
        local name = UnitName and UnitName("player")
        cachedPlayerFullName = name or ""
    end
    cachedPlayerShortName = cachedPlayerFullName and cachedPlayerFullName:match("^[^%-]+") or cachedPlayerFullName
    return cachedPlayerFullName
end

local function isHearthstoneEnabled()
    if addon and addon.IsHearthstoneEnabled then
        return addon:IsHearthstoneEnabled()
    end
    local tele = addon and addon.db and addon.db.global and addon.db.global.teleport
    return tele and tele.showHearthstone == true
end

local function getKeystoneTeleportData()
    if not addon then
        return nil
    end
    local keyInfo
    if addon.GetTeleportTargetKey then
        keyInfo = addon:GetTeleportTargetKey()
    elseif addon.ScanPlayerKeystone then
        keyInfo = addon:ScanPlayerKeystone()
    end
    -- Handle case where keyInfo is just a dungeon ID
    if type(keyInfo) == "number" then
        keyInfo = {
            dungeonID = keyInfo,
            level = 2  -- Default to +2 if unknown
        }
    end
    if keyInfo and (not keyInfo.io or keyInfo.io <= 0) and addon.GetCurrentSeasonData then
        local seasonData = addon:GetCurrentSeasonData()
        if seasonData and seasonData.currentScore and seasonData.currentScore > 0 then
            keyInfo.io = seasonData.currentScore
        end
    end
    if not keyInfo or not keyInfo.dungeonID then
        return nil
    end
    local dungeonName = addon:GetDungeonName(keyInfo.dungeonID)
    NextKey222.Debug:Dev("teleport", "getKeystoneTeleportData - dungeonID:", keyInfo.dungeonID, "dungeonName:", dungeonName or "nil")
    if not dungeonName then return nil end
    local portal
    -- First try to match by dungeonID directly (more reliable)
    if SEASON_PORTALS[keyInfo.dungeonID] then
        portal = SEASON_PORTALS[keyInfo.dungeonID]
        NextKey222.Debug:Dev("teleport", "Found portal by dungeonID:", keyInfo.dungeonID, "spellID:", portal.spellID)
    else
        -- Fallback to name matching
        for _, data in pairs(SEASON_PORTALS) do
            NextKey222.Debug:Dev("teleport", "Checking SEASON_PORTALS entry:", data.name, "vs dungeonName:", dungeonName)
            if data.name == dungeonName then
                portal = data
                NextKey222.Debug:Dev("teleport", "Found matching portal for:", dungeonName, "spellID:", data.spellID)
                break
            end
        end
        if not portal then
            NextKey222.Debug:Dev("teleport", "No portal found for dungeonName:", dungeonName, "or dungeonID:", keyInfo.dungeonID, "in SEASON_PORTALS")
        end
    end
    -- If not found in SEASON_PORTALS, try to find it in NextKey_DungeonNames and then get the spell from NextKey_PortalDB
    if not portal and type(NextKey_DungeonNames) == "table" and type(NextKey_PortalDB) == "table" then
        local mapID
        for id, name in pairs(NextKey_DungeonNames) do
            if name == dungeonName then
                mapID = id
                break
            end
        end
        if mapID then
            local spellID = NextKey_PortalDB[mapID]
            if spellID then
                portal = {
                    mapID = mapID,
                    spellID = spellID,
                    name = dungeonName,
                    destination = dungeonName,
                    alias = NextKey_DungeonAliases and NextKey_DungeonAliases[mapID],
                }
            end
        end
    end
    if not portal then
        -- Could not find the dungeon in our databases
        return {
            mapID = keyInfo.dungeonID,
            level = keyInfo.level or 0,
            ownerName = keyInfo.ownerName,
            class = keyInfo.class,
            io = keyInfo.io,
            dungeonName = dungeonName,
            destination = dungeonName,
            alias = NextKey_DungeonAliases and NextKey_DungeonAliases[keyInfo.dungeonID],
        }
    end
    local spellID = portal.spellID
    local spellName, _, spellTexture = safeGetSpellInfo(spellID)
    return {
        mapID = portal.mapID, -- Use the ID from our DB
        level = keyInfo.level or 0,
        ownerName = keyInfo.ownerName,
        class = keyInfo.class,
        io = keyInfo.io,
        spellID = spellID,
        spellName = spellName or dungeonName,
        icon = spellTexture,
        dungeonName = dungeonName,
        destination = portal.destination or portal.name or dungeonName,  -- Use portal destination first
        alias = portal.alias or (NextKey_DungeonAliases and NextKey_DungeonAliases[portal.mapID]),
    }
end

local function setButtonTexture(button, texture)
    local tex = texture or "Interface/Icons/INV_Misc_QuestionMark"
    button:SetNormalTexture(tex)
    local normal = button:GetNormalTexture()
    if normal then normal:SetAllPoints() end
    button:SetPushedTexture(tex)
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAllPoints()
        pushed:SetVertexColor(0.9, 0.9, 0.9)
    end
    button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetAllPoints()
        highlight:SetBlendMode("ADD")
    end
end

local function createTeleportButton(parent, texture, tooltipFunc)
    -- Hybrid approach: Keep native SecureActionButtonTemplate but style with Components
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(48, 48)
    -- Allow actions to fire regardless of ActionButtonUseKeyDown
    button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    setButtonTexture(button, texture)
    
    -- Apply Components styling to the native button
    NextKey222.UIComponents:ConfigureBackdrop(button, "compact", {
        colorScheme = "transparent"
    })
    
    if tooltipFunc then
        button:SetScript("OnEnter", tooltipFunc)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return button
end

local function updateTeleportLayout(window)
    if not window or not window.frame then
        return
    end
    local frame = window.frame
    local mainContainer = window.mainContainer
    local closeButton = window.closeButton
    local titleLabel = window.titleLabel
    local hearthButton = window.hearthButton
    local keystoneButton = window.keystoneButton
    local aliasLabel = window.keystoneAliasLabel
    local levelLabel = window.keystoneLevelLabel
    local noteLabel = window.keystoneOwnerNoteLabel
    local showHearth = isHearthstoneEnabled()
    
    -- Get teleport data to determine window sizing
    local data = getKeystoneTeleportData()
    local isDungeonPortal = data and data.source == "dungeon_portal"
    
    -- Use configuration values for dynamic sizing
    local config = isDungeonPortal and NextKey222.UIConfig.TELEPORT_WINDOW.COMPACT or NextKey222.UIConfig.TELEPORT_WINDOW.STANDARD
    local leftPadding = config.LEFT_PADDING
    local rightPadding = config.RIGHT_PADDING
    local betweenPadding = config.BETWEEN_PADDING
    local topPadding = 12
    local titleHeight = (titleLabel and titleLabel:GetStringHeight()) or 14
    local contentTop = topPadding + titleHeight + 6

    if hearthButton then
        hearthButton:ClearAllPoints()
        if showHearth then
            hearthButton:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPadding, -contentTop)
            hearthButton:Show()
            local hearthTexture = select(10, safeGetItemInfo(HEARTH_ITEM_ID)) or "Interface/Icons/INV_Misc_Rune_01"
            setButtonTexture(hearthButton, hearthTexture)
            hearthButton:SetAttribute("type", "item")
            hearthButton:SetAttribute("item", getHearthName())
            contentTop = contentTop + 48 + 6
        else
            hearthButton:Hide()
            hearthButton:SetAttribute("type", nil)
            hearthButton:SetAttribute("item", nil)
        end
    end

    if keystoneButton then
        keystoneButton:ClearAllPoints()
        keystoneButton:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPadding, -contentTop)
    end

    local aliasWidth = aliasLabel and aliasLabel.frame and aliasLabel.frame:GetWidth() or 0
    local aliasHeight = 0
    if aliasLabel then
        local aliasFrame = aliasLabel.frame
        aliasFrame:ClearAllPoints()
        aliasFrame:SetPoint("TOP", keystoneButton, "BOTTOM", 0, -4)
        if aliasFrame:IsShown() and aliasLabel:GetText() ~= "" then
            aliasHeight = aliasFrame:GetHeight() or 0
        else
            aliasHeight = 0
            aliasWidth = 0
            aliasFrame:Hide()
        end
    end

    local levelWidth = levelLabel and levelLabel.frame and levelLabel.frame:GetWidth() or 0
    local noteHeight = 0
    local noteColumnWidth = levelWidth
    if noteLabel and levelLabel then
        local noteFrame = noteLabel.frame
        local levelFrame = levelLabel.frame
        noteFrame:ClearAllPoints()
        noteFrame:SetPoint("TOP", levelFrame, "BOTTOM", 0, -4)
        if noteFrame:IsShown() and noteLabel:GetText() ~= "" then
            local preferredWidth = 72
            noteLabel:SetWidth(preferredWidth)
            noteColumnWidth = math.max(levelWidth, preferredWidth)
            noteHeight = noteFrame:GetHeight() or 0
        else
            noteFrame:Hide()
            noteColumnWidth = levelWidth
            noteHeight = 0
        end
    elseif noteLabel then
        noteLabel.frame:Hide()
    end

    local iconColumnWidth = math.max(48, aliasWidth)
    if aliasLabel then
        aliasLabel:SetWidth(iconColumnWidth)
        if aliasHeight <= 0 then
            aliasLabel.frame:Hide()
        else
            aliasLabel.frame:Show()
        end
    end

    local levelColumnWidth = math.max(levelWidth, noteColumnWidth)
    if noteLabel then
        noteLabel:SetWidth(levelColumnWidth)
        if noteHeight <= 0 then
            noteLabel.frame:Hide()
        end
    end

    -- Dynamic sizing using configuration values
    local contentWidth = leftPadding + iconColumnWidth + betweenPadding + levelColumnWidth + rightPadding
    local frameWidth = math.max(config.MIN_WIDTH, math.ceil(contentWidth))
    
    local aliasExtra = aliasHeight > 0 and (aliasHeight + config.ELEMENT_SPACING) or 0
    local noteExtra = noteHeight > 0 and (noteHeight + config.ELEMENT_SPACING) or 0
    local extraHeight = math.max(aliasExtra, noteExtra)
    
    local baseHeight = contentTop + 48 + extraHeight + config.BOTTOM_PADDING
    
    -- Update both the native frame and the AceGUI container
    frame:SetSize(frameWidth, math.ceil(baseHeight))
    if mainContainer then
        mainContainer:SetWidth(frameWidth)
        mainContainer:SetHeight(math.ceil(baseHeight))
    end

    if closeButton then
        closeButton:ClearAllPoints()
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
        closeButton:SetFrameStrata(frame:GetFrameStrata())
        closeButton:EnableMouse(true)
        closeButton:SetHitRectInsets(0, 0, 0, 0)
        closeButton:Raise()
    end
end

local function updateKeystoneButton(window)
    if not window or not window.keystoneButton then
        return
    end
    local button = window.keystoneButton
    local aliasLabel = window.keystoneAliasLabel
    local levelLabel = window.keystoneLevelLabel
    local noteLabel = window.keystoneOwnerNoteLabel
    local data = getKeystoneTeleportData()
    button.keystoneData = data
    setButtonTexture(button, data and data.icon)

    local isPlayersKey = false
    -- Don't treat dungeon portals as player keys, even if they have the player's name
    if data and data.source ~= "dungeon_portal" and data.ownerName and data.ownerName ~= "" then
        local ownerName = data.ownerName
        if strtrim then
            ownerName = strtrim(ownerName)
        end
        if ownerName and ownerName ~= "" then
            local ownerLower = string.lower(ownerName)
            local full = getPlayerFullName()
            if full and full ~= "" then
                local playerLower = string.lower(full)
                if ownerLower == playerLower then
                    isPlayersKey = true
                else
                    local short = cachedPlayerShortName or full:match("^[^%-]+") or full
                    if short and short ~= "" and ownerLower == string.lower(short) then
                        isPlayersKey = true
                    end
                end
            end
        end
    end

    if aliasLabel then
        if data and (data.alias or data.dungeonName or data.destination) then
            aliasLabel:SetText(data.alias or data.dungeonName or data.destination)
            aliasLabel.frame:Show()
        elseif data and data.source == "dungeon_portal" then
            aliasLabel:SetText("Dungeon Portal")
            aliasLabel.frame:Show()
        else
            aliasLabel:SetText("No keystone selected.")
            aliasLabel.frame:Show()
        end
    end

    if noteLabel then
        local lines = {}
        if isPlayersKey then
            lines[#lines + 1] = "*YOUR KEY*"
            noteLabel:SetColor(0.1, 1, 0.4)
        elseif data and data.source == "dungeon_portal" then
            lines[#lines + 1] = "Direct Portal Access"
            noteLabel:SetColor(0.85, 0.85, 0.85)
        else
            noteLabel:SetColor(0.85, 0.85, 0.85)
        end
        
        if #lines > 0 then
            noteLabel:SetText(table.concat(lines, "\n"))
            noteLabel.frame:Show()
        else
            noteLabel:SetText("")
            noteLabel.frame:Hide()
        end
    end

    if data and data.spellID and playerKnowsSpell(data.spellID) then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", data.spellID)
        button:Enable()
        local tex = button:GetNormalTexture()
        if tex then tex:SetDesaturated(false) end
        if levelLabel then
            if data and data.source == "dungeon_portal" then
                levelLabel:SetText("Portal")
                levelLabel:SetColor(0.4, 1, 0.9)  -- Cyan color for portals
            elseif data.level and data.level > 0 then
                levelLabel:SetText(string.format("+%d", data.level))
                levelLabel:SetColor(1, 0.82, 0)
            else
                levelLabel:SetText("")
            end
        end
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button:Disable()
        local tex = button:GetNormalTexture()
        if tex then tex:SetDesaturated(true) end
        if levelLabel then
            if data and data.source == "dungeon_portal" then
                levelLabel:SetText("Portal")
                levelLabel:SetColor(0.3, 0.7, 0.6)  -- Dimmed cyan for disabled portals
            elseif data and data.level and data.level > 0 then
                levelLabel:SetText(string.format("+%d", data.level))
                levelLabel:SetColor(0.7, 0.7, 0.7)
            else
                levelLabel:SetText("")
            end
        end
    end
end

local function showKeystoneTooltip(button)
    print("NextKey TELEPORT DEBUG: showKeystoneTooltip called")
    if not button then
        print("NextKey TELEPORT DEBUG: No button provided")
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local data = button.keystoneData or getKeystoneTeleportData()
    print("NextKey TELEPORT DEBUG: Got tooltip data:", data and "yes" or "nil")
    local ioScore = data and tonumber(data.io)
    if data and data.spellID then
        GameTooltip:SetSpellByID(data.spellID)
        if data.destination then
            GameTooltip:AddLine(string.format("Destination: %s", data.destination), 0.8, 0.8, 0.8)
        end
        if data.ownerName and data.ownerName ~= "" then
            GameTooltip:AddLine(string.format("Source: %s", data.ownerName), 0.9, 0.9, 0.9)
        end
        
        -- Calculate and display Gainable IO range using existing methods
        local ioRange = nil
        if NextKey222.IOCalculator and data then
            -- Create keystone data structure for IO calculation
            local keystoneData = {
                dungeonID = data.dungeonID or data.mapID,
                level = data.level or 0
            }
            
            -- Get player profiles (simplified for single player calculation)
            local currentPlayer = UnitName("player")
            local playerProfiles = {}
            if NextKey222.IOCalculator.GetPlayerProfile then
                playerProfiles[currentPlayer] = NextKey222.IOCalculator:GetPlayerProfile(currentPlayer)
            end
            
            -- Calculate group IO range (which includes individual player calculation)
            if keystoneData.dungeonID and keystoneData.level > 0 then
                ioRange = NextKey222.IOCalculator:CalculateGroupIORange(keystoneData, playerProfiles)
            end
        end
        
        -- Display Gainable IO range, but skip if min is 0 to avoid showing "0-X" ranges
        if ioRange and ioRange.expected and ioRange.expected > 0 and ioRange.max and ioRange.max > ioRange.min then
            GameTooltip:AddLine(string.format("Gainable IO: %d-%d", math.floor(ioRange.min), math.floor(ioRange.max)), 0.8, 0.8, 1)
        elseif ioRange and ioRange.expected and ioRange.expected > 0 then
            GameTooltip:AddLine(string.format("Gainable IO: %d", math.floor(ioRange.expected)), 0.8, 0.8, 1)
        end
        if not playerKnowsSpell(data.spellID) then
            GameTooltip:AddLine("You have not learned this teleport yet.", 1, 0.2, 0.2)
        end
    elseif data then
        GameTooltip:SetText(data.destination or data.dungeonName or "No keystone teleport available")
        if data.ownerName and data.ownerName ~= "" then
            GameTooltip:AddLine(string.format("Source: %s", data.ownerName), 0.9, 0.9, 0.9)
        end
    else
        GameTooltip:SetText("No keystone teleport available")
    end
    GameTooltip:Show()
end

function addon:EnsureTeleportWindow()
    if self.teleportWindow and self.teleportWindow.frame then
        return self.teleportWindow
    end
    
    -- Create main window using AceGUI Frame with Components styling
    local mainContainer = NextKey222.UIComponents:CreateFrame("window", nil, {
        width = 200,
        height = 140,
        colorScheme = "dark"
    })
    
    local frame = mainContainer.frame
    _G["NextKeyTeleportWindow"] = frame
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(600)
    frame:SetToplevel(true)
    frame:Hide()
    -- Create close button using AceGUI with Components styling
    local close = NextKey222.UIComponents:CreateButton("small", frame, {
        text = "×",
        onClick = function()
            frame:Hide()
            addon:ClearTeleportWindowContext()
        end
    })
    
    -- Position the close button
    local closeFrame = close.frame
    closeFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeFrame:SetFrameStrata(frame:GetFrameStrata())
    closeFrame:EnableMouse(true)
    closeFrame:SetHitRectInsets(0, 0, 0, 0)
    closeFrame:Raise()
    
    -- Add the close button to the main container for proper cleanup
    mainContainer:AddChild(close)
    
    -- Add cleanup function for proper AceGUI container management
    function addon:CleanupTeleportWindow()
        if self.teleportWindow then
            if self.teleportWindow.mainContainer then
                self.teleportWindow.mainContainer:ReleaseChildren()
                self.teleportWindow.mainContainer:Release()
                self.teleportWindow.mainContainer = nil
            end
            self.teleportWindow = nil
        end
    end
    -- Create title using AceGUI Label with Components styling
    local title = NextKey222.UIComponents:CreateText("header", frame, {
        text = "NextKey",
        width = 100,
        justifyH = "LEFT"
    })
    
    -- Position the title label
    local titleFrame = title.frame
    titleFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)

   -- Summon button (for PUG mode)
   local summonButton = createTeleportButton(frame, "Interface/Icons/Spell_Nature_SummonTreant", function(btn)
       GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
       GameTooltip:SetText("Request Summon")
       GameTooltip:AddLine("Asks your party for a summon.", 0.8, 0.8, 0.8, true)
       GameTooltip:Show()
   end)
   summonButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -100)
   summonButton:SetAttribute("type", "macro")
   summonButton:SetAttribute("macrotext", "/p Summon please!")
   summonButton:Hide() -- Initially hidden

    local hearthTexture = select(10, safeGetItemInfo(HEARTH_ITEM_ID)) or "Interface/Icons/INV_Misc_Rune_01"
    local hearthButton = createTeleportButton(frame, hearthTexture, function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(HEARTH_ITEM_ID)
        GameTooltip:Show()
    end)
    hearthButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
    hearthButton:SetScript("PostClick", function(_, mouseButton)
        addon:Print("Debug: Hearth button PostClick (" .. tostring(mouseButton) .. ")")
    end)
    local keystoneData = getKeystoneTeleportData()
    local keystoneTexture = (keystoneData and keystoneData.icon) or "Interface/Icons/INV_Misc_QuestionMark"
    local keystoneButton = createTeleportButton(frame, keystoneTexture, showKeystoneTooltip)
    keystoneButton:SetPoint("TOPLEFT", hearthButton, "BOTTOMLEFT", 0, -18)
    keystoneButton:SetScript("PostClick", function(_, mouseButton)
        addon:Print("Debug: Keystone button PostClick (" .. tostring(mouseButton) .. ")")
    end)
    -- Create keystone alias label using AceGUI Label with Components styling
    local keystoneAlias = NextKey222.UIComponents:CreateText("label", frame, {
        text = "",
        justifyH = "CENTER",
        color = {0.85, 0.85, 0.85}
    })
    
    -- Create keystone level label using AceGUI Label with Components styling
    local keystoneLevel = NextKey222.UIComponents:CreateText("large", frame, {
        text = "",
        justifyH = "LEFT",
        color = {1, 0.82, 0}
    })
    
    -- Position the level label relative to keystone button
    local keystoneLevelFrame = keystoneLevel.frame
    keystoneLevelFrame:SetPoint("LEFT", keystoneButton, "RIGHT", 12, 0)
    
    -- Create keystone note label using AceGUI Label with Components styling
    local keystoneNote = NextKey222.UIComponents:CreateText("label", frame, {
        text = "",
        justifyH = "CENTER",
        color = {0.1, 1, 0.4}
    })
    
    -- Initially hide the note label
    keystoneNote.frame:Hide()
    -- Add all AceGUI widgets to main container for proper cleanup
    mainContainer:AddChild(title)
    mainContainer:AddChild(keystoneAlias)
    mainContainer:AddChild(keystoneLevel)
    mainContainer:AddChild(keystoneNote)
    
    self.teleportWindow = {
        frame = frame,
        mainContainer = mainContainer,  -- Store AceGUI container for proper cleanup
        closeButton = close,
        titleLabel = title,
        hearthButton = hearthButton,
        keystoneButton = keystoneButton,
        keystoneAliasLabel = keystoneAlias,
        keystoneLevelLabel = keystoneLevel,
        keystoneOwnerNoteLabel = keystoneNote,
        summonButton = summonButton,
    }

    updateKeystoneButton(self.teleportWindow)
    updateTeleportLayout(self.teleportWindow)
    return self.teleportWindow
end

function addon:ToggleTeleportWindow()
    local window = self:EnsureTeleportWindow()
    if not window then return end
    
    NextKey222.Debug:User("Teleport Window: Toggle called")
    
    if window.frame:IsShown() then
        NextKey222.Debug:User("Teleport Window: Hiding window")
        window.frame:Hide()
        addon:ClearTeleportWindowContext()
        return
    end

    local context = addon:GetTeleportWindowContext()
    NextKey222.Debug:User("Teleport Window: Context: " .. (context and ("mode=" .. (context.mode or "nil")) or "nil"))
    
    if context and context.mode == "PUG" then
       NextKey222.Debug:User("Teleport Window: Setting PUG mode - showing summon button")
       window.titleLabel:SetText("NextKey - PUG Travel")
       window.summonButton:Show()
    else
       NextKey222.Debug:User("Teleport Window: Setting normal mode - hiding summon button")
       window.titleLabel:SetText("NextKey")
       window.summonButton:Hide()
    end

    updateKeystoneButton(window)
    updateTeleportLayout(window)

    window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    window.frame:SetFrameLevel(600)
    window.frame:SetToplevel(true)
    window.frame:Show()
    window.frame:Raise()
    
    NextKey222.Debug:User("Teleport Window: Window shown and raised")
end

function addon:RefreshTeleportWindow()
    if not self.teleportWindow then
        return
    end
    updateKeystoneButton(self.teleportWindow)
    updateTeleportLayout(self.teleportWindow)
end

















