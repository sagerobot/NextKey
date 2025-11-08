local _, NextKey222 = ...
local PUGHelper = NextKey222.PUGHelper
local Debug = NextKey222.Debug

if not PUGHelper then
    Debug:Error("PUG Helper module not found, cannot add state management.")
    return
end

PUGHelper.STATE = {
    IDLE = "idle",
    TRACKING = "tracking",
    INVITE_RECEIVED = "invite",
    IN_GROUP = "in_group",
    RUN_COMPLETE = "run_complete"
}

PUGHelper.VALID_TRANSITIONS = {
    [PUGHelper.STATE.IDLE] = {
        [PUGHelper.STATE.TRACKING] = true,
        [PUGHelper.STATE.RUN_COMPLETE] = true  -- Allow manual join completion
    },
    [PUGHelper.STATE.TRACKING] = {
        [PUGHelper.STATE.IDLE] = true,
        [PUGHelper.STATE.INVITE_RECEIVED] = true,
        [PUGHelper.STATE.RUN_COMPLETE] = true  -- Allow manual join completion
    },
    [PUGHelper.STATE.INVITE_RECEIVED] = {
        [PUGHelper.STATE.TRACKING] = true,
        [PUGHelper.STATE.IN_GROUP] = true
    },
    [PUGHelper.STATE.IN_GROUP] = {
        [PUGHelper.STATE.IDLE] = true,
        [PUGHelper.STATE.RUN_COMPLETE] = true
    },
    [PUGHelper.STATE.RUN_COMPLETE] = {
        [PUGHelper.STATE.IDLE] = true
    }
}

local currentState = PUGHelper.STATE.IDLE

-- Primary invite lock for first-accepted-wins behavior
PUGHelper.primaryInvite = nil        -- table: locked primary application data
PUGHelper.activeInviteID = nil      -- string: appData.id of primary invite

function PUGHelper:GetState()
    return currentState
end

function PUGHelper:ValidateStateTransition(fromState, toState)
    if not fromState or not toState then
        Debug:Dev("pughelper", "Invalid state transition: missing states")
        return false
    end

    if fromState == toState then
        Debug:Dev("pughelper", "State transition to same state: " .. toState)
        return true
    end

    local validTransitions = PUGHelper.VALID_TRANSITIONS[fromState]
    if not validTransitions then
        Debug:Dev("pughelper", "No valid transitions defined from state: " .. fromState)
        return false
    end

    local isValid = validTransitions[toState] or false
    if not isValid then
        Debug:Dev("pughelper", "Invalid state transition: " .. fromState .. " -> " .. toState)
    else
        Debug:Dev("pughelper", "Valid state transition: " .. fromState .. " -> " .. toState)
    end

    return isValid
end

function PUGHelper:TransitionToState(newState, context)
    context = context or "unknown"

    if not self:ValidateStateTransition(currentState, newState) then
        Debug:Error("PUG Helper: Invalid state transition attempted: " .. currentState .. " -> " .. newState .. " (context: " .. context .. ")")
        return false
    end

    local oldState = currentState
    currentState = newState

    Debug:Dev("pughelper", "PUG Helper state transition: " .. oldState .. " -> " .. newState .. " (context: " .. context .. ")")

    self:OnStateChanged(oldState, newState, context)

    return true
end

function PUGHelper:OnStateChanged(oldState, newState, context)
    if oldState == PUGHelper.STATE.INVITE_RECEIVED then
        if self.inviteTimer then
            self.inviteTimer:Cancel()
            self.inviteTimer = nil
        end
    elseif oldState == PUGHelper.STATE.RUN_COMPLETE then
        if self.getawayTimer then
            self.getawayTimer:Cancel()
            self.getawayTimer = nil
        end
    end

    if newState == PUGHelper.STATE.IDLE then
        self.trackedApplications = {}
        self.currentInvite = nil
        self.currentGroupInfo = nil
        self.primaryInvite = nil
        self.activeInviteID = nil
        Debug:Dev("pughelper", "PUG Helper state -> IDLE (state cleared)")
    end
end

function PUGHelper:ResetState()
    Debug:Dev("pughelper", "Resetting PUG Helper state from: " .. currentState)

    if self.inviteTimer then
        self.inviteTimer:Cancel()
        self.inviteTimer = nil
    end

    if self.getawayTimer then
        self.getawayTimer:Cancel()
        self.getawayTimer = nil
    end

    self.trackedApplications = {}
    self.currentInvite = nil
    self.currentGroupInfo = nil
    self.primaryInvite = nil
    self.activeInviteID = nil

    currentState = PUGHelper.STATE.IDLE

    Debug:Dev("pughelper", "PUG Helper state reset to IDLE (including primary invite)")
end

-- MARK: Primary Invite Lock Helpers

function PUGHelper:SetPrimaryInvite(app_data)
    if not app_data or not app_data.id then
        return
    end

    -- First-accepted-wins: if already locked, do nothing
    if self.primaryInvite and self.activeInviteID then
        Debug:Dev("pughelper", "SetPrimaryInvite called but primary already locked to: " .. tostring(self.activeInviteID))
        return
    end

    self.primaryInvite = app_data
    self.activeInviteID = app_data.id

    Debug:Dev("pughelper", "primary_invite_locked id=" .. tostring(app_data.id) .. " name=" .. tostring(app_data.name))
end

function PUGHelper:ClearPrimaryInvite(reason)
    if self.primaryInvite or self.activeInviteID then
        Debug:Dev("pughelper", "primary_invite_cleared reason=" .. tostring(reason or "unknown") ..
            " id=" .. tostring(self.activeInviteID or (self.primaryInvite and self.primaryInvite.id)))
    end

    self.primaryInvite = nil
    self.activeInviteID = nil
end

function PUGHelper:GetPrimaryInvite()
    return self.primaryInvite
end