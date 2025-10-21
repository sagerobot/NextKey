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

function PUGHelper:OnApplicationListUpdated()
    print("NextKey PUG: Application refresh detected via hook.")

    if not self:IsEnabled() then
        print("NextKey PUG: PUG Helper is disabled - ignoring applications.")
        Debug:Dev("pughelper", "Application refresh detected but PUG Helper is disabled.")
        return
    end

    print("NextKey PUG: Processing LFG applications...")
    Debug:Dev("pughelper", "LFG application list updated")

    self.trackedApplications = {}

    local results = C_LFGList.GetApplications()
    print("NextKey PUG: Found " .. #results .. " LFG applications via C_LFGList.GetApplications()")
    Debug:User("PUG Helper: Found " .. #results .. " LFG applications")

    for i = 1, #results do
        local resultID = results[i]
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

            print("NextKey PUG: Application #" .. i .. " - Leader: " .. (appData.leader or "Unknown") ..
                  ", Dungeon: " .. (appData.name or "Unknown") ..
                  ", Key Level: +" .. (appData.keyLevel or "?"))

            Debug:User("PUG Helper: Tracking application: " .. appData.name .. " (ID: " .. appData.id .. ")")
        else
            print("NextKey PUG: ERROR - Could not get search result info for resultID: " .. tostring(resultID))
        end
    end

    local appCount = 0
    for _ in pairs(self.trackedApplications) do appCount = appCount + 1 end
    print("NextKey PUG: Total applications tracked: " .. appCount)

    if next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.IDLE then
        print("NextKey PUG: Transitioning from IDLE to TRACKING - found applications")
        Debug:User("PUG Helper: Transitioning from IDLE to TRACKING - found applications")
        self:TransitionToState(PUGHelper.STATE.TRACKING, "applications_detected")

        if NextKey222.PUGApplicationTracker then
            print("NextKey PUG: Calling AutoShowIfNeeded on application tracker")
            Debug:User("PUG Helper: Calling AutoShowIfNeeded on application tracker")
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        else
            print("NextKey PUG: ERROR - PUGApplicationTracker not available!")
            Debug:Error("PUG Helper: PUGApplicationTracker not available!")
        end
    elseif not next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.TRACKING then
        print("NextKey PUG: Transitioning from TRACKING to IDLE - no applications")
        Debug:User("PUG Helper: Transitioning from TRACKING to IDLE - no applications")
        self:TransitionToState(PUGHelper.STATE.IDLE, "no_applications")

        if NextKey222.PUGApplicationTracker then
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        end
    else
        print("NextKey PUG: No state change needed - Current state: " .. self:GetState() .. ", Applications: " .. appCount)
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

        if NextKey222.PUGApplicationTracker then
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        end

        if newStatus == "declined" or newStatus == "cancelled" or newStatus == "failed" then
            self.trackedApplications[appID] = nil
            Debug:Dev("pughelper", "Removed application: " .. appData.name)

            if NextKey222.PUGApplicationTracker then
                NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
            end

            if not next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.TRACKING then
                self:TransitionToState(PUGHelper.STATE.IDLE, "all_applications_failed")
            end
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