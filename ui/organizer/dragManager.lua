local _, NextKey222 = ...
local AceGUI = LibStub("AceGUI-3.0")
local Debug = NextKey222.Debug

-- MARK: Module Definition
local DragManager = {}
NextKey222.DragManager = DragManager
NextKey222.RegisterModule("DragManager", DragManager)

-- MARK: State Management
DragManager.state = {
    isDragging = false,
    draggedWidget = nil,
    draggedFrame = nil,
    draggedPlayer = nil,
    dragCursor = nil,
    originalLocation = nil,
    validDropTargets = {},
    currentDropTarget = nil
}

-- MARK: Initialization
function DragManager:Initialize()
    Debug:Dev("dragmanager", "DragManager initialized")
    return true
end

-- MARK: Drag Lifecycle

--- Starts a drag operation
-- @param playerCard frame The player card being dragged
-- @param playerData table The player's data
function DragManager:StartDrag(cardWidget, playerData)
    if self.state.isDragging then
        Debug:Dev("dragmanager", "Already dragging, ignoring new drag")
        return false
    end

    local dragFrame = cardWidget and cardWidget.frame or cardWidget
    local dragData = playerData or (cardWidget and cardWidget.playerData)

    if not dragFrame or not dragData then
        Debug:Dev("dragmanager", "Missing drag frame or player data, cannot start drag")
        return false
    end

    Debug:Dev("dragmanager", "Starting drag for player:", dragData.name)

    self.state.isDragging = true
    self.state.draggedWidget = cardWidget
    self.state.draggedFrame = dragFrame
    self.state.draggedPlayer = dragData

    if cardWidget and cardWidget.location then
        if type(cardWidget.location) == "table" then
            if CopyTable then
                self.state.originalLocation = CopyTable(cardWidget.location)
            else
                local clone = {}
                for k, v in pairs(cardWidget.location) do
                    clone[k] = v
                end
                self.state.originalLocation = clone
            end
        else
            self.state.originalLocation = cardWidget.location
        end
    else
        self.state.originalLocation = nil
    end

    self:CreateDragCursor(dragFrame, dragData)
    self:HighlightValidDropTargets(dragData)

    dragFrame:SetAlpha(0.4)

    return true
end

--- Creates a visual cursor that follows the mouse during drag
-- @param originalCard frame The card being dragged
-- @param playerData table The player's data
function DragManager:CreateDragCursor(sourceFrame, playerData)
    local width = (sourceFrame and sourceFrame:GetWidth()) or 160
    local height = (sourceFrame and sourceFrame:GetHeight()) or 24

    local cursor = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    cursor:SetSize(width, height)
    cursor:SetFrameStrata("TOOLTIP")
    cursor:SetClampedToScreen(true)

    local classColor = (playerData and playerData.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerData.class]) or nil
    local r = classColor and classColor.r or 0.2
    local g = classColor and classColor.g or 0.2
    local b = classColor and classColor.b or 0.2

    cursor:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1
    })
    cursor:SetBackdropColor(r, g, b, 0.85)
    cursor:SetBackdropBorderColor(0, 0, 0, 0.9)

    local nameText = cursor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("CENTER")
    nameText:SetText(playerData and (playerData.shortName or playerData.name) or "Unknown")

    cursor:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        DragManager:UpdateDropTargetDetection()
    end)

    cursor:Show()
    self.state.dragCursor = cursor
end

--- Highlights all valid drop targets for the dragged player
-- @param playerData table The player's data
function DragManager:HighlightValidDropTargets(playerData)
    if not NextKey222.RosterBoard then
        return
    end

    self.state.validDropTargets = {}

    local slots = NextKey222.RosterBoard:GetAllRoleSlots()
    for _, slot in ipairs(slots) do
        if self:CanPlayerFillSlot(playerData, slot) then
            NextKey222.RosterBoard:SetDropTargetHighlight(slot, "valid")
            table.insert(self.state.validDropTargets, {
                widget = slot,
                frame = slot.frame,
                info = {
                    widget = slot,
                    type = "role_slot",
                    groupIndex = slot.groupIndex,
                    slotIndex = slot.slotIndex,
                    role = slot.role,
                    roleLabel = slot.roleLabel,
                    occupiedBy = slot.playerCard and slot.playerCard.playerData or nil
                }
            })
        end
    end

    local benchColumn = NextKey222.RosterBoard:GetBenchColumn()
    if benchColumn and benchColumn.frame then
        NextKey222.RosterBoard:SetDropTargetHighlight(benchColumn, "valid")
        table.insert(self.state.validDropTargets, {
            widget = benchColumn,
            frame = benchColumn.frame,
            info = {
                widget = benchColumn,
                type = "bench"
            }
        })
    end

    local optOutSection = NextKey222.RosterBoard:GetOptOutSection()
    if optOutSection and optOutSection.frame then
        NextKey222.RosterBoard:SetDropTargetHighlight(optOutSection, "valid")
        table.insert(self.state.validDropTargets, {
            widget = optOutSection,
            frame = optOutSection.frame,
            info = {
                widget = optOutSection,
                type = "opt_out"
            }
        })
    end
end

--- Checks if a player can fill a specific role slot
-- @param playerData table The player's data
-- @param slot table The role slot
-- @return boolean true if player can fill the slot
function DragManager:CanPlayerFillSlot(playerData, slot)
    if not playerData or not slot then
        return false
    end

    local roles = playerData.roles or playerData.availableRoles
    if not roles then
        return false
    end

    if NextKey222.RosterBoard and NextKey222.RosterBoard.CanPlayerFillRole then
        return NextKey222.RosterBoard:CanPlayerFillRole(roles, slot.role)
    end

    for _, role in ipairs(roles) do
        if role == slot.role or (role == "DAMAGER" and slot.role == "DPS") or (role == "DPS" and slot.role == "DAMAGER") then
            return true
        end
    end

    return false
end

--- Updates drop target detection based on cursor position
function DragManager:UpdateDropTargetDetection()
    if not self.state.isDragging then
        return
    end

    local mouseX, mouseY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    mouseX = mouseX / scale
    mouseY = mouseY / scale

    local newTarget = nil
    for _, target in ipairs(self.state.validDropTargets) do
        if target.frame and target.frame:IsShown() and self:IsMouseOverFrame(target.frame, mouseX, mouseY) then
            newTarget = target
            break
        end
    end

    if newTarget ~= self.state.currentDropTarget then
        if self.state.currentDropTarget and NextKey222.RosterBoard then
            NextKey222.RosterBoard:SetDropTargetHighlight(self.state.currentDropTarget.widget, "valid")
        end

        if newTarget and NextKey222.RosterBoard then
            NextKey222.RosterBoard:SetDropTargetHighlight(newTarget.widget, "hover")
        end

        self.state.currentDropTarget = newTarget
    end
end

--- Checks if mouse is over a frame
-- @param frame frame The frame to check
-- @param mouseX number Mouse X position
-- @param mouseY number Mouse Y position
-- @return boolean true if mouse is over frame
function DragManager:IsMouseOverFrame(frame, mouseX, mouseY)
    if not frame or not frame:IsVisible() then
        return false
    end
    
    local left = frame:GetLeft() or 0
    local right = frame:GetRight() or 0
    local top = frame:GetTop() or 0
    local bottom = frame:GetBottom() or 0
    
    return mouseX >= left and mouseX <= right and 
           mouseY >= bottom and mouseY <= top
end

--- Ends the drag operation with a drop
-- @param dropTarget table The target where the card was dropped (optional)
function DragManager:EndDrag(dropTarget)
    if not self.state.isDragging then
        return
    end
    
    Debug:Dev("dragmanager", "Ending drag, drop target:", dropTarget and "valid" or "none")
    
    -- Process drop if valid target
    if dropTarget or self.state.currentDropTarget then
        self:ProcessDrop(dropTarget or self.state.currentDropTarget)
    else
        -- No valid drop - spring back to original location
        self:CancelDrag()
        return
    end
    
    -- Cleanup
    self:CleanupDrag()
end

--- Processes a successful drop
-- @param dropTarget table The target where the card was dropped
function DragManager:ProcessDrop(dropTarget)
    local playerData = self.state.draggedPlayer
    local cardWidget = self.state.draggedWidget
    local dropInfo = dropTarget and (dropTarget.info or dropTarget) or nil

    if not playerData or not cardWidget or not dropInfo then
        Debug:Dev("dragmanager", "Missing drag state or drop info; aborting drop processing")
        return
    end

    Debug:Dev("dragmanager", "Processing drop for player:", playerData.name, "target type:", dropInfo.type)

    if NextKey222.RosterBoard and NextKey222.RosterBoard.HandleCardDrop then
        NextKey222.RosterBoard:HandleCardDrop(cardWidget, dropInfo)
    else
        Debug:Dev("dragmanager", "RosterBoard unavailable, unable to handle drop target")
    end
end

--- Places a player in a role slot
-- @param playerData table The player's data
-- @param slot table The target slot
function DragManager:PlacePlayerInSlot(playerData, slot)
    Debug:Dev("dragmanager", "Placing player in slot:", playerData.name, slot.role)
    
    -- TODO: Implement slot placement logic
    -- This will be called from RosterBoard module
    if NextKey222.RosterBoard then
        NextKey222.RosterBoard:PlacePlayerInSlot(playerData, slot)
    end
end

--- Swaps two players between locations
-- @param player1 table First player's data
-- @param player2 table Second player's data
-- @param targetSlot table The slot where player1 is being dropped
function DragManager:SwapPlayers(player1, player2, targetSlot)
    Debug:Dev("dragmanager", "Swapping players:", player1.name, player2.name)
    
    -- TODO: Implement swap logic
    -- This will be called from RosterBoard module
    if NextKey222.RosterBoard then
        NextKey222.RosterBoard:SwapPlayers(player1, player2, targetSlot)
    end
end

--- Moves a player to the bench
-- @param playerData table The player's data
function DragManager:MovePlayerToBench(playerData)
    Debug:Dev("dragmanager", "Moving player to bench:", playerData.name)
    
    -- TODO: Implement bench move logic
    if NextKey222.RosterBoard then
        NextKey222.RosterBoard:MovePlayerToBench(playerData)
    end
end

--- Moves a player to opt-out section
-- @param playerData table The player's data
function DragManager:MovePlayerToOptOut(playerData)
    Debug:Dev("dragmanager", "Moving player to opt-out:", playerData.name)
    
    -- TODO: Implement opt-out move logic
    if NextKey222.RosterBoard then
        NextKey222.RosterBoard:MovePlayerToOptOut(playerData)
    end
end

--- Cancels the drag and returns card to original location
function DragManager:CancelDrag()
    if not self.state.isDragging then
        return
    end
    
    Debug:Dev("dragmanager", "Canceling drag, spring-back to original location")
    
    -- TODO: Implement spring-back animation
    -- For now, just restore alpha
    if self.state.draggedFrame and self.state.draggedFrame.SetAlpha then
        self.state.draggedFrame:SetAlpha(1.0)
    end
    
    self:CleanupDrag()
end

--- Cleans up drag state and visuals
function DragManager:CleanupDrag()
    -- Remove drag cursor
    if self.state.dragCursor then
        self.state.dragCursor:Hide()
        self.state.dragCursor = nil
    end
    
    -- Restore card alpha
    if self.state.draggedFrame and self.state.draggedFrame.SetAlpha then
        self.state.draggedFrame:SetAlpha(1.0)
    end
    
    -- Remove highlights from drop targets
    if NextKey222.RosterBoard and NextKey222.RosterBoard.SetDropTargetHighlight then
        for _, target in ipairs(self.state.validDropTargets) do
            NextKey222.RosterBoard:SetDropTargetHighlight(target.widget, "off")
        end
    end
    
    -- Reset state
    self.state.isDragging = false
    self.state.draggedWidget = nil
    self.state.draggedFrame = nil
    self.state.draggedPlayer = nil
    self.state.originalLocation = nil
    self.state.validDropTargets = {}
    self.state.currentDropTarget = nil
    
    Debug:Dev("dragmanager", "Drag cleanup complete")
end

return DragManager
