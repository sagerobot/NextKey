-- MARK: Module Definition
local _, NextKey222 = ...

local KeystoneManager = {}
NextKey222.KeystoneManager = KeystoneManager
NextKey222.RegisterModule("KeystoneManager", KeystoneManager)

local Debug = NextKey222.Debug

-- MARK: Initialization
function KeystoneManager:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "KeystoneManager module initialized")
        return true
    end, "KeystoneManager:Initialize")
end

-- MARK: Designation
--- Designate a keystone for a group
-- @param rosterBoard RosterBoard instance
-- @param groupIndex Group number
-- @param keystone Keystone data
-- @param playerID Player identifier
function KeystoneManager:designate_group_keystone(rosterBoard, groupIndex, keystone, playerID)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "DesignateGroupKeystone called:", groupIndex, playerID)
        
        -- Validate group exists
        if not rosterBoard.groupKeystones[groupIndex] then
            Debug:Error("Invalid group index:", groupIndex)
            return
        end
        
        -- Check if clicking the same keystone (toggle off)
        if rosterBoard.groupKeystones[groupIndex].playerID == playerID then
            Debug:Dev("organizer", "Undesignating keystone")
            self:clear_group_keystone(rosterBoard, groupIndex)
            return
        end
        
        -- Clear previous designation if different player
        if rosterBoard.groupKeystones[groupIndex].playerID then
            self:unhighlight_keystone_button(
                rosterBoard,
                rosterBoard.groupKeystones[groupIndex].playerID
            )
        end
        
        -- Set new designation
        rosterBoard.groupKeystones[groupIndex] = {
            keystone = keystone,
            playerID = playerID
        }
        
        -- Update group header
        self:update_group_header(rosterBoard, groupIndex, keystone)
        
        -- Highlight new keystone button
        self:highlight_keystone_button(rosterBoard, playerID)
        
        -- Sync to participants
        rosterBoard:BroadcastRosterUpdate({
            action = "KEYSTONE_DESIGNATED",
            groupIndex = groupIndex,
            keystoneOwner = playerID,
            keystone = keystone
        })
        
        Debug:Dev("organizer", "Designated keystone for group", groupIndex)
        
    end, "KeystoneManager:designate_group_keystone")
end

--- Clear a group's designated keystone
-- @param rosterBoard RosterBoard instance
-- @param groupIndex Group number
function KeystoneManager:clear_group_keystone(rosterBoard, groupIndex)
    if not rosterBoard.groupKeystones[groupIndex] then return end
    
    -- Unhighlight button
    if rosterBoard.groupKeystones[groupIndex].playerID then
        self:unhighlight_keystone_button(
            rosterBoard,
            rosterBoard.groupKeystones[groupIndex].playerID
        )
    end
    
    -- Clear data
    rosterBoard.groupKeystones[groupIndex] = {
        keystone = nil,
        playerID = nil
    }
    
    -- Reset group header
    if rosterBoard.groupTitles[groupIndex] then
        rosterBoard.groupTitles[groupIndex]:SetText("M+ Grp. " .. groupIndex)
        rosterBoard.groupTitles[groupIndex]:SetTextColor(1, 1, 1)
    end
    
    -- Sync to participants
    rosterBoard:BroadcastRosterUpdate({
        action = "KEYSTONE_CLEARED",
        groupIndex = groupIndex
    })
    
    Debug:Dev("organizer", "Cleared keystone for group", groupIndex)
end

--- Check if a keystone is designated for a group
-- @param rosterBoard RosterBoard instance
-- @param groupIndex Group number
-- @param playerID Player identifier
-- @return boolean True if designated
function KeystoneManager:is_keystone_designated(rosterBoard, groupIndex, playerID)
    if not rosterBoard.groupKeystones[groupIndex] then return false end
    return rosterBoard.groupKeystones[groupIndex].playerID == playerID
end

-- MARK: Visual Updates
--- Update group header with keystone information
-- @param rosterBoard RosterBoard instance
-- @param groupIndex Group number
-- @param keystone Keystone data (or nil to reset)
function KeystoneManager:update_group_header(rosterBoard, groupIndex, keystone)
    if not rosterBoard.groupTitles[groupIndex] then
        Debug:Error("Group title not found for index:", groupIndex)
        return
    end
    
    if keystone then
        -- Get dungeon abbreviation using centralized service
        local dungeonAbbrev = "???"
        if NextKey222.DungeonNameService then
            dungeonAbbrev = NextKey222.DungeonNameService:GetAlias(keystone.dungeonID)
        end
        
        local headerText = dungeonAbbrev .. " +" .. keystone.level
        rosterBoard.groupTitles[groupIndex]:SetText(headerText)
        
        -- Color code by key level
        if keystone.level >= 15 then
            rosterBoard.groupTitles[groupIndex]:SetTextColor(1, 0.5, 0)  -- Orange
        elseif keystone.level >= 10 then
            rosterBoard.groupTitles[groupIndex]:SetTextColor(0.8, 0.8, 1)  -- Light blue
        else
            rosterBoard.groupTitles[groupIndex]:SetTextColor(1, 1, 1)  -- White
        end
        
        Debug:Dev("organizer", "Updated group", groupIndex, "header:", headerText)
    else
        -- Reset to default
        rosterBoard.groupTitles[groupIndex]:SetText("M+ Grp. " .. groupIndex)
        rosterBoard.groupTitles[groupIndex]:SetTextColor(1, 1, 1)  -- White
    end
end

--- Highlight keystone button (gold border)
-- @param rosterBoard RosterBoard instance
-- @param playerID Player identifier
function KeystoneManager:highlight_keystone_button(rosterBoard, playerID)
    local card = self:find_card_by_player_id(rosterBoard, playerID)
    if not card or not card.keystoneButton then return end
    
    -- Gold border and bright gold icon
    card.keystoneButton:SetBackdropBorderColor(1, 0.84, 0, 1.0)
    if card.keystoneButton.icon then
        card.keystoneButton.icon:SetVertexColor(1.0, 0.84, 0)  -- Bright gold
    end
    Debug:Dev("organizer", "Highlighted keystone button for:", playerID)
end

--- Unhighlight keystone button (gray border)
-- @param rosterBoard RosterBoard instance
-- @param playerID Player identifier
function KeystoneManager:unhighlight_keystone_button(rosterBoard, playerID)
    local card = self:find_card_by_player_id(rosterBoard, playerID)
    if not card or not card.keystoneButton then return end
    
    -- Gray border and gray icon
    card.keystoneButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    if card.keystoneButton.icon then
        card.keystoneButton.icon:SetVertexColor(0.8, 0.8, 0.8)  -- Gray
    end
    Debug:Dev("organizer", "Unhighlighted keystone button for:", playerID)
end

-- MARK: Helper Functions
--- Find a card by player ID across all locations
-- @param rosterBoard RosterBoard instance
-- @param playerID Player identifier
-- @return card The player card frame, or nil if not found
function KeystoneManager:find_card_by_player_id(rosterBoard, playerID)
    -- Search bench
    if rosterBoard.benchCards then
        for _, card in ipairs(rosterBoard.benchCards) do
            if card.playerID and card.playerID == playerID then
                return card
            end
        end
    end
    
    -- Search slots
    if rosterBoard.groupSlots then
        for _, slots in pairs(rosterBoard.groupSlots) do
            for _, slot in pairs(slots) do
                if slot.playerCard and slot.playerCard.playerID and
                   slot.playerCard.playerID == playerID then
                    return slot.playerCard
                end
            end
        end
    end
    
    -- Search opt-out cards
    if rosterBoard.optOutSection and rosterBoard.optOutSection.playerCards then
        for _, card in ipairs(rosterBoard.optOutSection.playerCards) do
            if card.playerID and card.playerID == playerID then
                return card
            end
        end
    end
    
    return nil
end