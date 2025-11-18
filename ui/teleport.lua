-- MARK: Initialization
local _, NextKey222 = ...
local addon = NextKey222.Addon
if not addon then return end
local UI = NextKey222.UIComponents

-- MARK: Constants
-- Hearthstone functionality - now uses dynamic selection from config
local function getSelectedHearthstone()
    if not addon or not addon.db or not addon.db.global or not addon.db.global.teleport then
        return {id = 6948, type = "item"} -- Fallback to standard Hearthstone
    end
    
    local selectedID = addon.db.global.teleport.selectedHearthstoneID or 6948
    
    -- Try to get hearthstone data from our database
    if NextKey222 and NextKey222.HearthstoneData then
        local hearthstone = NextKey222.HearthstoneData.GetHearthstoneByID(selectedID)
        if hearthstone then
            return hearthstone
        end
    end
    
    -- Fallback to standard Hearthstone
    return {id = 6948, type = "item"}
end

local function isHearthstoneAvailable()
    local hearthstone = getSelectedHearthstone()
    if NextKey222 and NextKey222.HearthstoneData then
        return NextKey222.HearthstoneData.HasHearthstone(hearthstone.id, hearthstone.type)
    end
    
    -- Fallback check for standard Hearthstone
    return GetItemCount(6948) > 0
end
-- Use centralized UI configuration
local UIConfig = NextKey222.UIConfig
local CARD_ICON_SIZE = UIConfig.TELEPORT_CARD.CARD_ICON_SIZE
local CARD_HEIGHT = UIConfig.TELEPORT_CARD.CARD_HEIGHT
local CARD_PADDING = UIConfig.TELEPORT_CARD.CARD_PADDING
local WINDOW_WIDTH = UIConfig.TELEPORT_CARD.WINDOW_WIDTH
local CARD_SPACING = UIConfig.TELEPORT_CARD.CARD_SPACING
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
local SPELL_BANK_PLAYER = UIConfig.SPELL.BANK_PLAYER
local SPELL_BANK_PET = UIConfig.SPELL.BANK_PET

local function safeGetItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemID)
    end
    if GetItemInfo then
        return GetItemInfo(itemID)
    end
end

local function getHearthName()
    local name = select(1, safeGetItemInfo(UIConfig.ITEM.HEARTHSTONE_ID))
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

local function isHearthstoneEnabled()
    if addon and addon.IsHearthstoneEnabled then
        return addon:IsHearthstoneEnabled()
    end
    local tele = addon and addon.db and addon.db.global and addon.db.global.teleport
    return tele and tele.showHearthstone == true and isHearthstoneAvailable()
end

local function isCompactModeEnabled()
    local tele = addon and addon.db and addon.db.global and addon.db.global.teleport
    return tele and tele.compactMode == true
end

local function configureSpellButton(button, spellID)
    if not button then return end
    -- PortaParty approach: Use spellID directly in the attribute
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", spellID)
    button:Enable()
end

local function configureItemButton(button, itemID)
    if not button then return end
    button:SetAttribute("type", "item")
    button:SetAttribute("*type*", "item")
    button:SetAttribute("type1", "item")
    button:SetAttribute("item", "item:" .. itemID)
    button:SetAttribute("spell", nil)
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("unit", "player")
    button:Enable()
end

local function disableSecureButton(button)
    if not button then return end
    button:SetAttribute("type", nil)
    button:SetAttribute("*type*", nil)
    button:SetAttribute("type1", nil)
    button:SetAttribute("spell", nil)
    button:SetAttribute("item", nil)
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("unit", nil)
    button:Disable()
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
    -- Use passed dungeonName if available (from dungeon cards), otherwise look it up
    local dungeonName = keyInfo.dungeonName or addon:GetDungeonName(keyInfo.dungeonID)
    NextKey222.Debug:Dev("teleport", "getKeystoneTeleportData - dungeonID:", keyInfo.dungeonID, "dungeonName:", dungeonName or "nil", "source:", keyInfo.dungeonName and "passed" or "lookup")
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
        spellName = spellName or portal.name or dungeonName,
        icon = spellTexture,
        dungeonName = portal.name or dungeonName,  -- Use portal name first (more reliable)
        destination = portal.destination or portal.name or dungeonName,  -- Use portal destination first
        alias = portal.alias or (NextKey_DungeonAliases and NextKey_DungeonAliases[portal.mapID]),
    }
end


local function showKeystoneTooltip(button)
    NextKey222.Debug:Dev("teleport", "showKeystoneTooltip called")
    if not button then
        NextKey222.Debug:Dev("teleport", "No button provided")
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local data = button.keystoneData or getKeystoneTeleportData()
    NextKey222.Debug:Dev("teleport", "Got tooltip data:", data and "yes" or "nil")
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

-- MARK: Card Builder Functions
-- =====================================================
-- Card-based layout functions for teleport window

--- Builds a teleport card for keystone or hearthstone
-- @param entryData table Data for the card (dungeon, level, owner, etc.)
-- @param isHearthstone boolean Whether this is a hearthstone card
-- @return AceGUI-Container The configured card container
--- Builds a compact icon-only teleport button (no text, just icon)
-- @param entryData table Data for the button
-- @return table The configured button
local function BuildCompactTeleportButton(entryData)
    local COMPACT_ICON_SIZE = UIConfig.TELEPORT_CARD.COMPACT_ICON_SIZE
    
    -- Create a simple button with icon only
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    button:SetSize(COMPACT_ICON_SIZE, COMPACT_ICON_SIZE)
    button:RegisterForClicks("AnyDown", "AnyUp")
    
    -- Set the icon texture
    button:SetNormalTexture(entryData.icon or "Interface/Icons/INV_Misc_QuestionMark")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    
    -- Store icon texture reference
    local iconTexture = button:GetNormalTexture()
    button.iconTexture = iconTexture
    
    -- Wrap in a table for compatibility
    local card = {
        frame = button,
        iconButton = button,  -- The button IS both frame and button
        entryData = entryData,
        type = "CompactTeleportButton"
    }
    
    return card
end

--- Builds a full-size teleport card with text and icon
-- @param entryData table Data for the card
-- @return table The configured card
local function BuildTeleportCard(entryData)
    -- Make the ENTIRE card a SecureActionButtonTemplate so clicking anywhere works
    local cardFrame = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,BackdropTemplate")
    cardFrame:SetSize(WINDOW_WIDTH - 20, CARD_HEIGHT)
    cardFrame:RegisterForClicks("AnyDown", "AnyUp")
    
    -- Apply more visible backdrop with minimal insets for tight padding
    cardFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }  -- Reduced from 11-12 to 4
    })
    cardFrame:SetBackdropColor(0, 0, 0, 0.85)
    cardFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Create icon texture directly on the card frame with minimal padding
    local iconTexture = cardFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(CARD_ICON_SIZE, CARD_ICON_SIZE)
    iconTexture:SetPoint("LEFT", cardFrame, "LEFT", 8, 0)  -- Reduced from 16 to 8
    iconTexture:SetTexture(entryData.icon or "Interface/Icons/INV_Misc_QuestionMark")
    
    -- Add highlight texture for the icon area
    local iconHighlight = cardFrame:CreateTexture(nil, "HIGHLIGHT")
    iconHighlight:SetSize(CARD_ICON_SIZE, CARD_ICON_SIZE)
    iconHighlight:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
    iconHighlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    iconHighlight:SetBlendMode("ADD")

    -- Create text labels directly on the card frame with minimal spacing and proper width constraints
    local nameLabel = cardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameLabel:SetPoint("LEFT", iconTexture, "RIGHT", 8, 8)  -- Reduced spacing from 12,10 to 8,8
    nameLabel:SetPoint("RIGHT", cardFrame, "RIGHT", -8, 8)  -- Constrain to card width with padding
    nameLabel:SetText(entryData.displayName or entryData.titleText or "Unknown")
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetTextColor(1, 0.82, 0)  -- Gold color for titles
    nameLabel:SetWordWrap(false)  -- Don't wrap, truncate instead
    nameLabel:SetMaxLines(1)  -- Single line only
    
    local detailLabel = cardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -4)
    detailLabel:SetPoint("RIGHT", cardFrame, "RIGHT", -8, 0)  -- Constrain width
    detailLabel:SetText(entryData.detailText or "")
    detailLabel:SetTextColor(0.82, 0.82, 0.82)
    detailLabel:SetJustifyH("LEFT")
    detailLabel:SetWordWrap(false)
    detailLabel:SetMaxLines(1)
    
    if entryData.subText and entryData.subText ~= "" then
        local subLabel = cardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        subLabel:SetPoint("TOPLEFT", detailLabel, "BOTTOMLEFT", 0, -2)
        subLabel:SetText(entryData.subText)
        subLabel:SetTextColor(0.7, 0.7, 0.7)
        subLabel:SetJustifyH("LEFT")
    end
    
    -- Store texture reference for alpha changes if needed
    cardFrame.iconTexture = iconTexture

    local function highlightOn()
        cardFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        cardFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end

    local function highlightOff()
        cardFrame:SetBackdropColor(0, 0, 0, 0.85)
        cardFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end

    cardFrame:SetScript("OnEnter", highlightOn)
    cardFrame:SetScript("OnLeave", highlightOff)
    cardFrame:SetScript("OnHide", highlightOff)

    -- Wrap in a table for compatibility (cardFrame IS the button now)
    local card = {
        frame = cardFrame,
        iconButton = cardFrame,  -- The card frame IS the button
        entryData = entryData,
        highlightOn = highlightOn,
        highlightOff = highlightOff,
        type = "TeleportCard"
    }

    return card
end

--- Updates the teleport window with current data
-- @param window table The teleport window structure
local function UpdateTeleportWindowContent(window)
    if not window or not window.mainContainer then
        return
    end

    local widget = window.widget or window.mainContainer
    local titleText = window.titleText or "NextKey"
    if widget and widget.SetTitle then
        widget:SetTitle(titleText)
    end
    window.mainContainer:SetLayout("List")
    window.mainContainer:SetAutoAdjustHeight(true)
    window.mainContainer:ReleaseChildren()

    local cardsGroup = UI:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "List"
    })
    cardsGroup:SetAutoAdjustHeight(true)

    local entries = {}
    local keystoneData = getKeystoneTeleportData()

    if keystoneData then
        local iconTexture = keystoneData.icon
        if not iconTexture and keystoneData.spellID then
            local _, _, spellTexture = safeGetSpellInfo(keystoneData.spellID)
            iconTexture = spellTexture
        end

        local ownerName = keystoneData.ownerName or ""
        local detailLine
        if ownerName ~= "" then
            detailLine = string.format("+%d - %s", keystoneData.level or 0, ownerName)
        else
            detailLine = string.format("+%d", keystoneData.level or 0)
        end

        local subLine
        if keystoneData.destination and keystoneData.destination ~= keystoneData.dungeonName then
            subLine = keystoneData.destination
        end

        table.insert(entries, {
            kind = "keystone",
            icon = iconTexture,
            displayName = keystoneData.dungeonName or "Unknown Dungeon",
            detailText = detailLine,
            subText = subLine,
            data = keystoneData
        })
    end

    if isHearthstoneEnabled() then
        local hearthstone = getSelectedHearthstone()
        local hearthTexture
        local hearthName
        
        -- Get texture and name based on hearthstone type
        if NextKey222 and NextKey222.HearthstoneData then
            hearthTexture = NextKey222.HearthstoneData.GetHearthstoneTexture(hearthstone.id, hearthstone.type)
            hearthName = NextKey222.HearthstoneData.GetHearthstoneName(hearthstone.id, hearthstone.type)
        end
        
        -- Fallback for standard Hearthstone
        if not hearthTexture or not hearthName then
            hearthTexture = select(10, safeGetItemInfo(hearthstone.id)) or "Interface/Icons/INV_Misc_Rune_01"
            hearthName = safeGetItemInfo(hearthstone.id) or "Hearthstone"
        end
        
        table.insert(entries, {
            kind = "hearth",
            icon = hearthTexture,
            displayName = hearthName,
            detailText = "Return to your home inn",
            subText = "",
            itemID = hearthstone.id,
            itemType = hearthstone.type
        })
    end
    
    -- Add Leave Group option if teleport window is in PUG mode AND dungeon is complete
    local context = addon:GetTeleportWindowContext()
    if context and context.mode == "PUG" and context.dungeonComplete then
        NextKey222.Debug:Dev("teleport", "Adding Leave Group option (dungeon complete)")
        table.insert(entries, {
            kind = "leavegroup",
            icon = "Interface\\Icons\\Ability_Rogue_FeignDeath",
            displayName = "Leave Group",
            detailText = "Exit the PUG group",
            subText = ""
        })
    end

    -- Clear any existing cards
    if window.cards then
        for _, card in ipairs(window.cards) do
            if card.frame then
                card.frame:Hide()
                card.frame:SetParent(nil)
            end
        end
    end
    window.cards = {}
    
    if #entries == 0 then
        local emptyLabel = window.mainContainer.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("CENTER", window.mainContainer.frame, "CENTER", 0, 0)
        emptyLabel:SetText("No teleports are available right now.")
        emptyLabel:SetTextColor(0.75, 0.75, 0.75)
        table.insert(window.cards, { frame = emptyLabel, type = "label" })
    else
        -- Use compact or full cards based on setting
        local isCompact = isCompactModeEnabled()
        local yOffset = 0  -- Start much closer to top (reduced from -60)
        local xOffset = 10   -- For compact mode horizontal layout
        
        if isCompact then
            -- Compact mode: horizontal layout with just icons and minimal spacing
            local COMPACT_ICON_SIZE = UIConfig.TELEPORT_CARD.COMPACT_ICON_SIZE
            local COMPACT_SPACING = UIConfig.TELEPORT_CARD.COMPACT_SPACING
            -- Calculate starting X position to center the icons
            local totalIconWidth = #entries * COMPACT_ICON_SIZE + (#entries - 1) * COMPACT_SPACING
            xOffset = -totalIconWidth / 2 + COMPACT_ICON_SIZE / 2
            yOffset = -8  -- Minimal padding from top
        end
        
        for i, entry in ipairs(entries) do
            local card
            if isCompact then
                card = BuildCompactTeleportButton(entry)
                -- Parent to the content area of the AceGUI container (not the frame)
                local parentFrame = window.mainContainer.content or window.mainContainer.frame
                card.frame:SetParent(parentFrame)
                card.frame:ClearAllPoints()
                card.frame:SetPoint("TOP", parentFrame, "TOP", xOffset, yOffset)
                xOffset = xOffset + 48 + 8  -- Move to next icon position
            else
                card = BuildTeleportCard(entry)
                -- Parent to the content area of the AceGUI container
                local parentFrame = window.mainContainer.content or window.mainContainer.frame
                card.frame:SetParent(parentFrame)
                card.frame:ClearAllPoints()
                card.frame:SetPoint("TOP", parentFrame, "TOP", 0, yOffset)
                yOffset = yOffset - (CARD_HEIGHT + CARD_SPACING)
            end
            
            card.frame:Show()
            table.insert(window.cards, card)
            
            -- Configure the entire card as a clickable button
            if card.frame then
                if entry.kind == "hearth" then
                    -- Configure based on hearthstone type
                    if entry.itemType == "toy" then
                        card.frame:SetAttribute("type", "toy")
                        card.frame:SetAttribute("toy", entry.itemID)
                    elseif entry.itemType == "spell" then
                        configureSpellButton(card.frame, entry.itemID)
                    else -- item
                        configureItemButton(card.frame, entry.itemID)
                    end
                    
                    card.frame:SetScript("OnEnter", function()
                        if card.highlightOn then card.highlightOn() end
                        GameTooltip:SetOwner(card.frame, "ANCHOR_RIGHT")
                        
                        -- Show appropriate tooltip based on type
                        if entry.itemType == "toy" then
                            GameTooltip:SetToyByItemID(entry.itemID)
                        elseif entry.itemType == "spell" then
                            GameTooltip:SetSpellByID(entry.itemID)
                        else -- item
                            GameTooltip:SetItemByID(entry.itemID)
                        end
                        GameTooltip:Show()
                    end)
                    card.frame:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                        if card.highlightOff then card.highlightOff() end
                    end)
                elseif entry.kind == "keystone" then
                    card.frame.keystoneData = entry.data
                    if entry.data and entry.data.spellID and playerKnowsSpell(entry.data.spellID) then
                        configureSpellButton(card.frame, entry.data.spellID)
                    else
                        disableSecureButton(card.frame)
                        -- Fade out the icon for locked spells
                        if card.frame.iconTexture then
                            card.frame.iconTexture:SetAlpha(0.4)
                        elseif card.frame.GetNormalTexture then
                            local tex = card.frame:GetNormalTexture()
                            if tex then tex:SetAlpha(0.4) end
                        end
                    end
                    card.frame:SetScript("OnEnter", function()
                        if card.highlightOn then card.highlightOn() end
                        showKeystoneTooltip(card.frame)
                    end)
                    card.frame:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                        if card.highlightOff then card.highlightOff() end
                    end)
                elseif entry.kind == "leavegroup" then
                    -- Leave Group button - non-secure, just a regular click
                    card.frame:SetAttribute("type", nil)  -- Clear secure attributes
                    card.frame:SetScript("OnClick", function()
                        NextKey222.Debug:User("Leave Group button clicked")
                        if IsInGroup() then
                            LeaveParty()
                            NextKey222.Debug:User("Left the group")
                        else
                            NextKey222.Debug:User("Not in a group")
                        end
                    end)
                    card.frame:SetScript("OnEnter", function()
                        if card.highlightOn then card.highlightOn() end
                        GameTooltip:SetOwner(card.frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("Leave Group")
                        GameTooltip:AddLine("Click to exit the PUG group", 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    card.frame:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                        if card.highlightOff then card.highlightOff() end
                    end)
                end
            end
            
        end
        
        -- Adjust window height/width based on mode with minimal padding
        if isCompact then
            -- Compact mode: ultra-compact with minimal chrome
            local COMPACT_ICON_SIZE = UIConfig.TELEPORT_CARD.COMPACT_ICON_SIZE
            local COMPACT_SPACING = UIConfig.TELEPORT_CARD.COMPACT_SPACING
            local totalIconWidth = #entries * COMPACT_ICON_SIZE + (#entries - 1) * COMPACT_SPACING
            local totalWidth = math.max(200, totalIconWidth + 30)  -- Minimal padding (reduced from 60)
            window.mainContainer.frame:SetWidth(totalWidth)
            window.mainContainer.frame:SetHeight(120)  -- Minimal height (reduced from 160)
        else
            -- Full mode: calculate height with minimal spacing
            local totalHeight = 70 + (#entries * (CARD_HEIGHT + CARD_SPACING))  -- Minimal base height
            window.mainContainer.frame:SetHeight(totalHeight)
            window.mainContainer.frame:SetWidth(WINDOW_WIDTH)
        end
    end

    -- Set status text using centralized UIConfig system
    local UIConfig = NextKey222 and NextKey222.UIConfig
    if widget and widget.SetStatusText then
        if UIConfig and UIConfig.GetStatusMessage then
            widget:SetStatusText(UIConfig:GetStatusMessage("TELEPORT_WINDOW"))
        else
            -- Fallback if UIConfig not available
            local version = "v0.5.32"
            if NextKey and NextKey.version_full then
                version = NextKey.version_full
            elseif NextKey and NextKey.version then
                version = "v" .. NextKey.version
            end
            widget:SetStatusText(version)
        end
    end
end

function addon:EnsureTeleportWindow()
    if self.teleportWindow and self.teleportWindow.frame then
        return self.teleportWindow
    end
    
    -- Create main window using AceGUI Frame with Components styling
    local mainContainer = UI:CreateFrame("window", nil, {
        width = WINDOW_WIDTH,
        height = 220,
        colorScheme = "dark"
    })
    mainContainer:SetLayout("List")
    if mainContainer.SetAutoAdjustHeight then
        mainContainer:SetAutoAdjustHeight(true)
    end
    
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
    
    -- Make window non-resizable using AceGUI's EnableResize method
    if mainContainer.EnableResize then
        mainContainer:EnableResize(false)
    end
    if mainContainer.SetTitle then
        mainContainer:SetTitle("NextKey")
    end
    
    -- Set status text using centralized UIConfig system
    local UIConfig = NextKey222 and NextKey222.UIConfig
    if mainContainer.SetStatusText then
        if UIConfig and UIConfig.GetStatusMessage then
            mainContainer:SetStatusText(UIConfig:GetStatusMessage("TELEPORT_WINDOW"))
        else
            -- Fallback if UIConfig not available
            local version = "v0.5.32"
            if NextKey and NextKey.version_full then
                version = NextKey.version_full
            elseif NextKey and NextKey.version then
                version = "v" .. NextKey.version
            end
            mainContainer:SetStatusText(version)
        end
    elseif frame.SetStatusText then
        if UIConfig and UIConfig.GetStatusMessage then
            frame:SetStatusText(UIConfig:GetStatusMessage("TELEPORT_WINDOW"))
        else
            -- Fallback if UIConfig not available
            local version = "v0.5.32"
            if NextKey and NextKey.version_full then
                version = NextKey.version_full
            elseif NextKey and NextKey.version then
                version = "v" .. NextKey.version
            end
            frame:SetStatusText(version)
        end
    end
    frame:SetWidth(WINDOW_WIDTH)
    frame:Hide()
    
    -- Add cleanup function for proper AceGUI container management
    function addon:CleanupTeleportWindow()
        if self.teleportWindow then
            local container = self.teleportWindow.mainContainer
            if container then
                container:ReleaseChildren()
                container:Release()
            end
            self.teleportWindow.widget = nil
            self.teleportWindow.mainContainer = nil
            self.teleportWindow = nil
        end
    end
    
    self.teleportWindow = {
        widget = mainContainer,
        frame = frame,
        mainContainer = mainContainer,
        titleText = "NextKey"
    }
    
    UpdateTeleportWindowContent(self.teleportWindow)
    return self.teleportWindow
end

function addon:ToggleTeleportWindow()
    local window = self:EnsureTeleportWindow()
    if not window then return end
    
    NextKey222.Debug:User("Teleport Window: Toggle called")
    
    if window.frame:IsShown() then
        -- Check if we're switching to a different dungeon
        local currentKeyData = getKeystoneTeleportData()
        local previousTarget = self:GetTeleportTargetKey()
        
        -- Compare current target with previous target to detect dungeon changes
        local isDifferentDungeon = false
        if currentKeyData and previousTarget then
            isDifferentDungeon = (currentKeyData.dungeonID ~= previousTarget.dungeonID)
        elseif currentKeyData and not previousTarget then
            isDifferentDungeon = true -- New target when none was set
        end
        
        if isDifferentDungeon then
            NextKey222.Debug:User("Teleport Window: Updating content for different dungeon")
            
            local context = addon:GetTeleportWindowContext()
            NextKey222.Debug:User("Teleport Window: Context: " .. (context and ("mode=" .. (context.mode or "nil")) or "nil"))
            
            if context and context.mode == "PUG" then
               NextKey222.Debug:User("Teleport Window: Setting PUG mode")
               window.titleText = "NextKey - PUG Travel"
            else
               NextKey222.Debug:User("Teleport Window: Setting normal mode")
               window.titleText = "NextKey"
            end

            -- Update window content with current data
            UpdateTeleportWindowContent(window)
            
            -- Ensure window stays on top
            window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
            window.frame:SetFrameLevel(600)
            window.frame:SetToplevel(true)
            window.frame:Raise()
            
            NextKey222.Debug:User("Teleport Window: Content updated for new dungeon")
            return
        else
            -- Same dungeon or no change detected, hide the window
            NextKey222.Debug:User("Teleport Window: Hiding window (same dungeon or no change)")
            window.frame:Hide()
            addon:ClearTeleportWindowContext()
            return
        end
    end

    -- Window is not shown, show it with current content
    local context = addon:GetTeleportWindowContext()
    NextKey222.Debug:User("Teleport Window: Context: " .. (context and ("mode=" .. (context.mode or "nil")) or "nil"))
    
    if context and context.mode == "PUG" then
       NextKey222.Debug:User("Teleport Window: Setting PUG mode")
       window.titleText = "NextKey - PUG Travel"
    else
       NextKey222.Debug:User("Teleport Window: Setting normal mode")
       window.titleText = "NextKey"
    end

    -- Update window content with current data
    UpdateTeleportWindowContent(window)

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
    UpdateTeleportWindowContent(self.teleportWindow)
end

-- MARK: Keystone Event Listeners

--- Registers event listeners for keystone events affecting teleport window
function addon:RegisterTeleportEventListeners()
    return NextKey222.SafeRun(function()
        if not self or not self.RegisterMessage then
            if NextKey222.Debug then
                NextKey222.Debug:Error("TeleportWindow: Cannot register event listeners - RegisterMessage not available")
            end
            return
        end

        -- Listen for teleport selection changes
        self:RegisterMessage(NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_SELECTED, function(event, payload)
            addon:OnTeleportSelectedEvent(payload)
        end)

        -- Listen for teleport cleared
        self:RegisterMessage(NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_CLEARED, function(event, payload)
            addon:OnTeleportClearedEvent(payload)
        end)

        if NextKey222.Debug then
            NextKey222.Debug:Dev("teleport", "Registered 2 keystone event listeners for teleport window")
        end
    end, "RegisterTeleportEventListeners")
end

--- Event handler: Teleport target selected
function addon:OnTeleportSelectedEvent(payload)
    if not payload then return end

    if NextKey222.Debug then
        NextKey222.Debug:Dev("teleport", string.format(
            "TeleportWindow received TELEPORT_SELECTED event: dungeonID=%s, level=%s, source=%s",
            tostring(payload.dungeonID),
            tostring(payload.level),
            payload.source or "unknown"
        ))
    end

    -- Refresh teleport window if it's open
    if self.teleportWindow and self.teleportWindow.frame and self.teleportWindow.frame:IsShown() then
        self:RefreshTeleportWindow()
        if NextKey222.Debug then
            NextKey222.Debug:Dev("teleport", "Teleport window refreshed after TELEPORT_SELECTED event")
        end
    end
end

--- Event handler: Teleport target cleared
function addon:OnTeleportClearedEvent(payload)
    if not payload then return end

    if NextKey222.Debug then
        NextKey222.Debug:Dev("teleport", "TeleportWindow received TELEPORT_CLEARED event")
    end

    -- Close teleport window if it's open
    if self.teleportWindow and self.teleportWindow.frame and self.teleportWindow.frame:IsShown() then
        self.teleportWindow.frame:Hide()
        self:ClearTeleportWindowContext()
        if NextKey222.Debug then
            NextKey222.Debug:Dev("teleport", "Teleport window hidden after TELEPORT_CLEARED event")
        end
    end
end

-- MARK: Testing Functions
-- =====================================================
-- Test functions for verifying the teleport window polish

-- Test command to verify the teleport window works correctly
-- Usage: /script NextKey222.Addon:TestTeleportWindow()
function addon:TestTeleportWindow()
    NextKey222.Debug:User("=== Testing Teleport Window Polish ===")

    NextKey222.Debug:User("1. Testing window creation...")
    local window = self:EnsureTeleportWindow()
    if not window then
        NextKey222.Debug:Error("Failed to create teleport window")
        return
    end
    NextKey222.Debug:User("[OK] Window created successfully")

    NextKey222.Debug:User("2. Testing keystone data retrieval...")
    local keystoneData = getKeystoneTeleportData()
    if keystoneData then
        NextKey222.Debug:User(string.format("[OK] Keystone data: %s +%d", keystoneData.dungeonName or "?", keystoneData.level or 0))
    else
        NextKey222.Debug:User("[WARN] No keystone data available (expected if no keystone)")
    end

    NextKey222.Debug:User("3. Testing content update...")
    UpdateTeleportWindowContent(window)
    NextKey222.Debug:User("[OK] Content updated successfully")

    if window.mainContainer and window.mainContainer.children then
        NextKey222.Debug:User(string.format("4. Content widget count: %d", #window.mainContainer.children))
    end

    NextKey222.Debug:User("5. Testing window toggle...")
    self:ToggleTeleportWindow()
    if window.frame:IsShown() then
        NextKey222.Debug:User("[OK] Window shown successfully")
        window.frame:Hide()
    else
        NextKey222.Debug:Error("Failed to show window")
    end

    NextKey222.Debug:User("6. Testing hearthstone setting...")
    NextKey222.Debug:User(string.format("[INFO] Hearthstone enabled: %s", tostring(isHearthstoneEnabled())))

    NextKey222.Debug:User("=== Teleport Window Test Complete ===")
    NextKey222.Debug:User("Open the teleport window with /nk teleport to visually verify the changes")
end