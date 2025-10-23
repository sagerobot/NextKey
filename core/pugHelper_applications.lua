local _, NextKey222 = ...
local PUGHelper = NextKey222.PUGHelper
local Debug = NextKey222.Debug

if not PUGHelper then
    Debug:Error("PUG Helper module not found, cannot add application management.")
    return
end

PUGHelper.trackedApplications = {}

function PUGHelper:GetApplicationsAsArray()
    local applications = {}

    for _, appData in pairs(self.trackedApplications) do
        table.insert(applications, appData)
    end

    table.sort(applications, function(a, b)
        return (a.appliedAt or 0) > (b.appliedAt or 0)
    end)

    return applications
end

-- MARK: Performance-Optimized LFG Application Processing
-- Prevents excessive processing during rapid LFG updates

-- Performance throttling variables
local lastLFGUpdate = 0
local LFG_UPDATE_THROTTLE = 0.5 -- 500ms minimum between updates
local pendingLFGUpdate = false
local cachedApplications = {}

function PUGHelper:OnApplicationListUpdated()
    local now = GetTime()
    
    -- PERFORMANCE FIX: Immediate throttling to prevent excessive processing
    if now - lastLFGUpdate < LFG_UPDATE_THROTTLE then
        if not pendingLFGUpdate then
            pendingLFGUpdate = true
            Debug:Dev("pughelper", "LFG application update throttled - scheduling delayed processing")
            
            C_Timer.NewTimer(LFG_UPDATE_THROTTLE, function()
                self:ProcessLFGUpdate()
                pendingLFGUpdate = false
            end)
        else
            Debug:Dev("pughelper", "LFG application update throttled - already pending")
        end
        return
    end
    
    self:ProcessLFGUpdate()
    lastLFGUpdate = now
end

function PUGHelper:ProcessLFGUpdate()
    Debug:User("PUG Helper: Application refresh detected via hook.")

    if not self:IsEnabled() then
        Debug:User("PUG Helper: PUG Helper is disabled - ignoring applications.")
        return
    end

    Debug:User("PUG Helper: Processing LFG applications...")

    -- PERFORMANCE FIX: Compare with cache to avoid unnecessary processing
    local currentResults = C_LFGList.GetApplications()
    local resultsHash = table.concat(currentResults, ",")
    
    if resultsHash == cachedApplications.hash then
        Debug:Dev("pughelper", "LFG applications unchanged - skipping processing")
        return
    end

    self.trackedApplications = {}

    Debug:User("PUG Helper: Found " .. #currentResults .. " LFG applications")

    for i = 1, #currentResults do
        local resultID = currentResults[i]
        local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)

        if searchResultInfo then
            local appData = {
                id = tostring(resultID),
                name = searchResultInfo.name,
                leader = searchResultInfo.leaderName,
                dungeonID = searchResultInfo.activityID,
                keyLevel = 0,
                activityID = searchResultInfo.activityID,
                comment = searchResultInfo.comment or "",
                voiceChat = searchResultInfo.voiceChat,
                iLevel = searchResultInfo.requiredItemLevel,
                honorLevel = searchResultInfo.requiredHonorLevel,
                appliedAt = time(),
                status = "pending",
                statusHistory = {
                    {status = "pending", timestamp = time()}
                }
            }

            local keyLevel = string.match(appData.name, "(%d+)")
            if keyLevel then
                appData.keyLevel = tonumber(keyLevel)
            end

            self.trackedApplications[appData.id] = appData

            Debug:Dev("pughelper", "Application #" .. i .. " - Leader: " .. (appData.leader or "Unknown") ..
                  ", Dungeon: " .. (appData.name or "Unknown") ..
                  ", Key Level: +" .. (appData.keyLevel or "?"))

            Debug:User("PUG Helper: Tracking application: " .. appData.name .. " (ID: " .. appData.id .. ")")
        else
            Debug:Error("PUG Helper: Could not get search result info for resultID: " .. tostring(resultID))
        end
    end

    -- Update cache
    cachedApplications = {
        hash = resultsHash,
        timestamp = GetTime()
    }

    local appCount = 0
    for _ in pairs(self.trackedApplications) do appCount = appCount + 1 end
    Debug:User("PUG Helper: Total applications tracked: " .. appCount)

    if next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.TRACKING then
        Debug:User("PUG Helper: No state change needed - already tracking applications")
    elseif next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.IDLE then
        Debug:User("PUG Helper: Transitioning from IDLE to TRACKING - found applications")
        self:TransitionToState(PUGHelper.STATE.TRACKING, "applications_detected")

        if NextKey222.PUGApplicationTracker then
            Debug:User("PUG Helper: Calling AutoShowIfNeeded on application tracker")
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        else
            Debug:Error("PUG Helper: PUGApplicationTracker not available!")
        end
    elseif not next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.TRACKING then
        Debug:User("PUG Helper: Transitioning from TRACKING to IDLE - no applications")
        self:TransitionToState(PUGHelper.STATE.IDLE, "no_applications")

        if NextKey222.PUGApplicationTracker then
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        end
    else
        Debug:Dev("pughelper", "No state change needed - Current state: " .. self:GetState() .. ", Applications: " .. appCount)
    end
end

function PUGHelper:OnApplicationStatusChanged(resultID, newStatus, oldStatus)
    if not self:IsEnabled() then
        return
    end

    Debug:Dev("pughelper", "Application status changed: " .. resultID .. " from " .. (oldStatus or "nil") .. " to " .. (newStatus or "nil"))

    local appID = tostring(resultID)
    local appData = self.trackedApplications[appID]

    if appData then
        appData.status = newStatus

        table.insert(appData.statusHistory, {
            status = newStatus,
            timestamp = time()
        })

        -- PERFORMANCE FIX: Batch UI updates to prevent excessive refreshes
        local shouldUpdateUI = false
        if newStatus == "declined" or newStatus == "cancelled" or newStatus == "failed" then
            self.trackedApplications[appID] = nil
            Debug:Dev("pughelper", "Removed application: " .. appData.name)
            shouldUpdateUI = true

            if not next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.TRACKING then
                self:TransitionToState(PUGHelper.STATE.IDLE, "all_applications_failed")
            end
        else
            shouldUpdateUI = true
        end

        -- PERFORMANCE FIX: Throttle UI updates
        if shouldUpdateUI and NextKey222.PUGApplicationTracker then
            C_Timer.After(0.1, function()
                NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
            end)
        end
    end
end

function PUGHelper:MatchInviteToApplication(inviteName)
    Debug:Dev("pughelper", "Matching invite to applications: " .. inviteName)

    for appID, appData in pairs(self.trackedApplications) do
        if appData.leader == inviteName then
            Debug:Dev("pughelper", "Found matching application: " .. appData.name)
            return appData
        end
    end

    for appID, appData in pairs(self.trackedApplications) do
        if string.find(inviteName, appData.leader, 1, true) or
           string.find(appData.name, string.gsub(inviteName, "-.*", ""), 1, true) then
            Debug:Dev("pughelper", "Found partial match: " .. appData.name)
            return appData
        end
    end

    Debug:Dev("pughelper", "No matching application found for: " .. inviteName)
    return nil
end