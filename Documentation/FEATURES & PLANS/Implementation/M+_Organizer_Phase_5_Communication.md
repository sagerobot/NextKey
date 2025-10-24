# M+ Group Organizer - Phase 5: Communication

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0-4  
**Estimated Complexity:** Low  
**Implementation Priority:** MEDIUM - Final feature polish

---

## Overview

This phase implements the announcement system that allows the Organizer to broadcast finalized group compositions to various chat channels. This is the final user-facing feature that completes the Organizer workflow.

**Key Deliverables:**
1. "Announce Groups" button handler
2. Chat channel selection system
3. Message formatting engine
4. Preview system
5. Confirmation dialogs

---

## 1. Announcement System

### 1.1 Button Handler

**File:** `core/organizer/announcer.lua` (NEW)

```lua
-- MARK: Module Definition
local Announcer = {}
NextKey222.Announcer = Announcer
NextKey222.RegisterModule("Announcer", Announcer)

function Announcer:AnnounceGroups(groups, channels)
    return NextKey222.SafeRun(function()
        -- Validate groups
        if not groups or #groups == 0 then
            Debug:User("No groups to announce")
            return
        end
        
        -- Validate at least one channel selected
        if not channels.raid and not channels.guild then
            Debug:User("Please select at least one chat channel")
            return
        end
        
        -- Format messages
        local messages = self:FormatGroupMessages(groups)
        
        -- Show preview dialog
        self:ShowPreviewDialog(messages, channels)
        
    end, "Announcer:AnnounceGroups")
end

function Announcer:FormatGroupMessages(groups)
    local messages = {}
    
    -- Header
    table.insert(messages, "=== M+ Groups ===")
    
    for groupIndex, group in ipairs(groups) do
        -- Group header with keystone
        local keystoneText = "No key designated"
        if group.chosenKeystone then
            local dungeon = NextKey222.Utils:GetDungeonName(group.chosenKeystone.dungeonID)
            keystoneText = dungeon .. " +" .. group.chosenKeystone.level
        end
        
        table.insert(messages, "")
        table.insert(messages, "Group " .. groupIndex .. ": " .. keystoneText)
        
        -- Players by role
        local roleOrder = {"Tank", "Healer", "DPS"}
        local playersByRole = {Tank = {}, Healer = {}, DPS = {}}
        
        for _, player in ipairs(group.players) do
            -- Determine primary role in this group
            local assignedRole = self:GetPlayerAssignedRole(player, group)
            table.insert(playersByRole[assignedRole], player)
        end
        
        for _, role in ipairs(roleOrder) do
            for _, player in ipairs(playersByRole[role]) do
                local classColor = RAID_CLASS_COLORS[player.class]
                local colorCode = string.format("|cFF%02x%02x%02x", 
                    classColor.r * 255, classColor.g * 255, classColor.b * 255)
                
                table.insert(messages, "  " .. role .. ": " .. colorCode .. player.name .. "|r")
            end
        end
    end
    
    -- Footer
    table.insert(messages, "")
    table.insert(messages, "Organized with NextKey")
    
    return messages
end

function Announcer:GetPlayerAssignedRole(player, group)
    -- Determine which role this player was assigned in the group
    -- (Based on slot position in Roster Board)
    return player.assignedRole or player.roles[1] or "DPS"
end

function Announcer:ShowPreviewDialog(messages, channels)
    local dialog = AceGUI:Create("Frame")
    dialog:SetTitle("Announce Groups - Preview")
    dialog:SetWidth(500)
    dialog:SetHeight(600)
    dialog:SetLayout("Fill")
    
    -- Preview scroll area
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    dialog:AddChild(scrollFrame)
    
    -- Display messages
    for _, line in ipairs(messages) do
        local label = AceGUI:Create("Label")
        label:SetText(line)
        label:SetFullWidth(true)
        scrollFrame:AddChild(label)
    end
    
    -- Buttons
    local buttonGroup = AceGUI:Create("SimpleGroup")
    buttonGroup:SetLayout("Flow")
    buttonGroup:SetFullWidth(true)
    
    local confirmButton = AceGUI:Create("Button")
    confirmButton:SetText("Send to Chat")
    confirmButton:SetWidth(150)
    confirmButton:SetCallback("OnClick", function()
        self:SendToChannels(messages, channels)
        dialog:Hide()
    end)
    buttonGroup:AddChild(confirmButton)
    
    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(100)
    cancelButton:SetCallback("OnClick", function()
        dialog:Hide()
    end)
    buttonGroup:AddChild(cancelButton)
    
    dialog:AddChild(buttonGroup)
end

function Announcer:SendToChannels(messages, channels)
    local fullMessage = table.concat(messages, "\n")
    
    if channels.raid then
        if IsInRaid() then
            SendChatMessage(fullMessage, "RAID")
            Debug:Dev("announcer", "Sent to RAID chat")
        elseif IsInGroup() then
            SendChatMessage(fullMessage, "PARTY")
            Debug:Dev("announcer", "Sent to PARTY chat")
        end
    end
    
    if channels.guild then
        if IsInGuild() then
            SendChatMessage(fullMessage, "GUILD")
            Debug:Dev("announcer", "Sent to GUILD chat")
        end
    end
    
    Debug:User("Groups announced successfully")
end
```

---

## 2. Implementation Checklist

- [ ] Create `core/organizer/announcer.lua` module
- [ ] Implement message formatting system
- [ ] Build preview dialog
- [ ] Add channel selection logic
- [ ] Handle chat API limitations
- [ ] Add error handling for chat restrictions
- [ ] Write test suite
- [ ] Test with various group sizes
- [ ] Test channel selection combinations
- [ ] Update `NextKey.toc`

---

**Document Status:** Complete  
**Ready for Implementation:** Yes  
**Blockers:** Phase 0-4 must complete first  
**Next Document:** State Management