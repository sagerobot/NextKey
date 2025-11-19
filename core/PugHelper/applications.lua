local _, NextKey222 = ...
local PUGHelper = NextKey222.PUGHelper
local Debug = NextKey222.Debug

if not PUGHelper then
    Debug:Error("PUG Helper module not found, cannot add application management.")
    return
end

PUGHelper.trackedApplications = {}

-- MARK: Search Cache
-- Maps searchResultID -> dungeon info (from LFG_LIST_SEARCH_RESULTS_UPDATED)
-- This cache is rebuilt every time search results update
local SearchResultCache = {}

-- MARK: Cache Function
-- Called when LFG_LIST_SEARCH_RESULTS_UPDATED fires
-- Caches dungeon names for all visible search results
function PUGHelper:CacheSearchResults()
    -- Wipe old cache
    wipe(SearchResultCache)
    
    -- Get current search results
    local searchResults = C_LFGList.GetSearchResults()
    if not searchResults then
        Debug:Dev("pughelper", "No search results available for caching")
        return
    end
    
    Debug:Dev("pughelper", "Caching search results: " .. #searchResults .. " entries")
    
    for i = 1, #searchResults do
        local resultID = searchResults[i]
        local resultInfo = C_LFGList.GetSearchResultInfo(resultID)
        
        if resultInfo and resultInfo.activityIDs and type(resultInfo.activityIDs) == "table" then
            local firstActivityID = resultInfo.activityIDs[1]
            
            if firstActivityID then
                -- Try to get dungeon name from activity info
                local activityInfo = C_LFGList.GetActivityInfoTable(firstActivityID)
                if activityInfo and activityInfo.fullName then
                    SearchResultCache[resultID] = {
                        dungeonName = activityInfo.fullName,
                        activityID = firstActivityID,
                        groupName = resultInfo.name
                    }
                    Debug:Dev("pughelper", "  Cached [" .. resultID .. "] = " .. activityInfo.fullName .. " (activityID: " .. firstActivityID .. ")")
                end
            end
        end
    end
    
    local count = 0
    for _ in pairs(SearchResultCache) do count = count + 1 end
    Debug:Dev("pughelper", "Search result cache updated: " .. count .. " dungeons cached")
end

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

-- MARK: LFG Processing
-- Prevents excessive processing during rapid LFG updates

-- Performance throttling variables
local lastLFGUpdate = 0
local LFG_UPDATE_THROTTLE = 0.5 -- 500ms minimum between updates
local pendingLFGUpdate = false
local cachedApplications = {}

function PUGHelper:OnApplicationListUpdated()
    local now = GetTime()

    -- PERFORMANCE: Throttle processing; avoid log spam here
    if now - lastLFGUpdate < LFG_UPDATE_THROTTLE then
        if not pendingLFGUpdate then
            pendingLFGUpdate = true
            C_Timer.NewTimer(LFG_UPDATE_THROTTLE, function()
                self:ProcessLFGUpdate("throttled")
                pendingLFGUpdate = false
            end)
        end
        return
    end

    self:ProcessLFGUpdate("immediate")
    lastLFGUpdate = now
end

function PUGHelper:ProcessLFGUpdate(source)
    -- Keep this very light; only a single optional trace
    if source == "immediate" then
        Debug:Dev("pughelper", "ProcessLFGUpdate (immediate)")
    end

    if not self:IsEnabled() then
        return
    end
    
    -- Stop processing LFG updates if already in a group
    if self:GetState() == PUGHelper.STATE.IN_GROUP then
        return
    end

    local currentResults = C_LFGList.GetApplications() or {}

    -- PERFORMANCE FIX: Compare with cache to avoid unnecessary processing
    local currentResults = C_LFGList.GetApplications() or {}
    local resultsHash = ""
    if #currentResults > 0 then
        resultsHash = table.concat(currentResults, ",")
    end
    
    if resultsHash == cachedApplications.hash then
        return
    end

    self.trackedApplications = {}

    for i = 1, #currentResults do
        local resultID = currentResults[i]
        
        -- C_LFGList.GetSearchResultInfo works with both search result IDs AND application IDs
        -- Just use it directly - no need for GetApplicationInfo
        local info = C_LFGList.GetSearchResultInfo(resultID)
        
        if info then
            -- Try to get dungeon info from search result cache FIRST (reliable!)
            local cachedInfo = SearchResultCache[resultID]
            local dungeonName = nil
            local firstActivityID = nil
            
            if cachedInfo then
                -- We have cached data from when the user browsed the LFG list!
                dungeonName = cachedInfo.dungeonName
                firstActivityID = cachedInfo.activityID
                Debug:Dev("pughelper", "Using cached dungeon info for " .. resultID .. ": " .. dungeonName)
            else
                -- Fallback: try to extract from activityIDs table (may not work reliably)
                Debug:Dev("pughelper", "No cached data for " .. resultID .. ", attempting fallback")
                if info.activityIDs and type(info.activityIDs) == "table" then
                    firstActivityID = info.activityIDs[1]
                    if firstActivityID then
                        local activityInfo = C_LFGList.GetActivityInfoTable(firstActivityID)
                        if activityInfo then
                            dungeonName = activityInfo.fullName
                        end
                    end
                end
                
                -- Last resort: use group name
                if not dungeonName then
                    dungeonName = info.name
                end
            end
            
            Debug:Dev("pughelper", "Processing application " .. resultID .. ": dungeonName=" .. tostring(dungeonName) .. ", activityID=" .. tostring(firstActivityID))
            
            local appData = {
                id = tostring(resultID),
                name = dungeonName or info.name, -- Use cached dungeon name if available
                leader = info.leaderName,
                dungeonID = firstActivityID,
                keyLevel = 0,
                activityID = firstActivityID,
                comment = info.comment or "",
                voiceChat = info.voiceChat,
                iLevel = info.requiredItemLevel,
                honorLevel = info.requiredHonorLevel,
                appliedAt = time(),
                status = "pending",
                statusHistory = {
                    { status = "pending", timestamp = time() }
                }
            }

            -- Parse key level from group name (e.g., "Mists +10" or "NW 10")
            local keyLevel = appData.name and string.match(appData.name, "%+?(%d+)")
            if keyLevel then
                appData.keyLevel = tonumber(keyLevel)
                Debug:Dev("pughelper", "  Parsed key level: " .. appData.keyLevel)
            end
            
            Debug:Dev("pughelper", "  Stored application: activityID=" .. tostring(appData.activityID) .. ", dungeonID=" .. tostring(appData.dungeonID) .. ", keyLevel=" .. tostring(appData.keyLevel))

            self.trackedApplications[appData.id] = appData
        else
            Debug:Dev("pughelper", "  No search result info for application " .. resultID)
        end
    end

    -- Update cache
    cachedApplications = {
        hash = resultsHash,
        timestamp = GetTime()
    }
 
    local appCount = 0
    for _ in pairs(self.trackedApplications) do
        appCount = appCount + 1
    end
    Debug:Dev("pughelper", "Total applications tracked: " .. appCount)
 
    -- State transitions
    if appCount > 0 and self:GetState() == PUGHelper.STATE.IDLE then
        Debug:Dev("pughelper", "Transition IDLE -> TRACKING (applications_detected)")
        self:TransitionToState(PUGHelper.STATE.TRACKING, "applications_detected")
    elseif appCount == 0 and self:GetState() == PUGHelper.STATE.TRACKING then
        Debug:Dev("pughelper", "Transition TRACKING -> IDLE (no_applications)")
        self:TransitionToState(PUGHelper.STATE.IDLE, "no_applications")
    end
 
    -- Notify debug-only tracker with current applications
    if NextKey222.PUGApplicationTracker and NextKey222.PUGApplicationTracker.OnApplicationsUpdated then
        NextKey222.SafeRun(function()
            local apps = self:GetApplicationsAsArray()
            Debug:Dev("pughelper", "Calling PUGApplicationTracker:OnApplicationsUpdated with " .. #apps .. " apps")
            NextKey222.PUGApplicationTracker:OnApplicationsUpdated(apps)
        end, "PUGApplicationTracker:OnApplicationsUpdated")
    end
end

function PUGHelper:OnApplicationStatusChanged(resultID, newStatus, oldStatus)
    if not self:IsEnabled() then
        return
    end
    
    -- Stop processing if already in a group
    if self:GetState() == PUGHelper.STATE.IN_GROUP then
        return
    end

    -- Single concise dev trace per status event
    Debug:Dev("pughelper", "Application " .. tostring(resultID) .. " status: " .. (oldStatus or "nil") .. " -> " .. (newStatus or "nil"))

    local appID = tostring(resultID)
    local appData = self.trackedApplications[appID]

    if appData then
        appData.status = newStatus

        table.insert(appData.statusHistory, {
            status = newStatus,
            timestamp = time()
        })

        -- Check if application was accepted (invited status)
        if newStatus == "invited" then
            -- First-accepted-wins:
            -- If no primary invite yet, lock this one and drive teleport.
            -- If a primary already exists, ignore this as a secondary (no retarget).
            if not self.primaryInvite and not self.activeInviteID then
                self:SetPrimaryInvite(appData)
                Debug:Dev("pughelper", "Application invited and locked as primary: " .. (appData.name or "Unknown"))
                self:TransitionToState(PUGHelper.STATE.INVITE_RECEIVED, "first_invite_locked")
                self:OnMPlusAccepted(appData)
            else
                Debug:Dev("pughelper", "Secondary invited application ignored (primary locked): " .. (appData.name or "Unknown"))
            end
        end
        
        -- Transition to IN_GROUP when invite is accepted
        if newStatus == "inviteaccepted" then
            Debug:Dev("pughelper", "Invite accepted - transitioning to IN_GROUP state")

            -- CRITICAL FIX: Set primary invite if not already set
            -- This handles cases where status skips "invited" and goes straight to "inviteaccepted"
            if not self.primaryInvite and not self.activeInviteID then
                self:SetPrimaryInvite(appData)
                Debug:Dev("pughelper", "Primary invite set on inviteaccepted (missed invited status): " .. (appData.name or "Unknown"))
                self:OnMPlusAccepted(appData)
            end

            -- Only treat as our tracked PUG if it matches the primary invite (or if no primary set)
            if (self.activeInviteID and appID == self.activeInviteID) or not self.activeInviteID then
                if self.MarkGroupAsPUG then
                    self:MarkGroupAsPUG()
                end
                self:TransitionToState(PUGHelper.STATE.IN_GROUP, "invite_accepted")
                self:ClearPrimaryInvite("inviteaccepted")
            else
                Debug:Dev("pughelper", "Inviteaccepted for non-primary application - ignoring for PUGHelper state")
            end
        end

        -- PERFORMANCE FIX + primary invite unlock handling
        local shouldUpdateUI = false
        local is_terminal_failure = (
            newStatus == "declined"
            or newStatus == "cancelled"
            or newStatus == "failed"
            or newStatus == "declined_full"
            or newStatus == "invitedeclined"
        )

        if is_terminal_failure then
            -- If this was the primary invite, unlock and immediately allow another invited app to become primary.
            if self.activeInviteID and appID == self.activeInviteID then
                self:ClearPrimaryInvite("primary_terminal_status_" .. tostring(newStatus))

                -- Promote the earliest remaining invited application (if any) to new primary.
                local nextPrimary = nil
                for _, candidate in pairs(self.trackedApplications) do
                    if candidate.status == "invited" then
                        if not nextPrimary or (candidate.appliedAt or 0) < (nextPrimary.appliedAt or 0) then
                            nextPrimary = candidate
                        end
                    end
                end

                if nextPrimary then
                    self:SetPrimaryInvite(nextPrimary)
                    Debug:Dev("pughelper", "Promoting secondary invited application to new primary after decline: " .. (nextPrimary.name or "Unknown"))
                    -- Drive teleport for the new primary immediately.
                    self:OnMPlusAccepted(nextPrimary)
                    -- Ensure state reflects that we have an active invite again.
                    if self:GetState() ~= PUGHelper.STATE.INVITE_RECEIVED then
                        self:TransitionToState(PUGHelper.STATE.INVITE_RECEIVED, "secondary_invite_promoted")
                    end
                end
            end

            self.trackedApplications[appID] = nil
            Debug:Dev("pughelper", "Removed application: " .. (appData.name or ("AppID " .. appID)))
            shouldUpdateUI = true

            if not next(self.trackedApplications) and self:GetState() == PUGHelper.STATE.TRACKING then
                self:TransitionToState(PUGHelper.STATE.IDLE, "all_applications_failed")
            end
        else
            shouldUpdateUI = true
        end

        -- PERFORMANCE FIX: Throttle debug UI updates
        if shouldUpdateUI and NextKey222.PUGApplicationTracker and NextKey222.PUGApplicationTracker.OnApplicationsUpdated then
            C_Timer.After(0.1, function()
                NextKey222.SafeRun(function()
                    NextKey222.PUGApplicationTracker:OnApplicationsUpdated(self:GetApplicationsAsArray())
                end, "PUGApplicationTracker:OnApplicationsUpdated(throttled)")
            end)
        end
    end
end

-- Called when an application transitions into a successful M+ state.
-- Uses tracked application data to drive teleport behavior.
function PUGHelper:OnMPlusAccepted(appData)
    if not appData then
        Debug:Dev("pughelper", "OnMPlusAccepted: No appData provided")
        return
    end
 
    Debug:Dev("pughelper", "OnMPlusAccepted called for: " .. (appData.name or "Unknown"))

    -- Respect primary invite lock:
    -- Only the current primary (if any) may drive teleport targeting.
    if self.primaryInvite and self.activeInviteID and appData.id ~= self.activeInviteID then
        Debug:Dev("pughelper", "OnMPlusAccepted: app is not primary (" .. tostring(appData.id) ..
            " != " .. tostring(self.activeInviteID) .. "), ignoring teleport update")
        return
    end
    
    local NextKey = NextKey222.Addon
    if not NextKey or not NextKey.SetTeleportWindowContext or not NextKey.ToggleTeleportWindow then
        Debug:Dev("pughelper", "OnMPlusAccepted: NextKey teleport APIs not available")
        return
    end
 
    -- Try to get challenge map ID from the activity ID first (most reliable!)
    local dungeonID = nil
    if appData.activityID and NextKey222.ActivityToDungeonMap then
        dungeonID = NextKey222.ActivityToDungeonMap:GetMapIDFromActivityID(appData.activityID)
        Debug:Dev("pughelper", "ActivityToDungeonMap lookup for activityID " .. tostring(appData.activityID) .. ": " .. tostring(dungeonID))
    end
    
    -- Fallback: Try to extract dungeon ID from the group name using DungeonNameMatcher
    if not dungeonID and appData.name and NextKey222.DungeonNameMatcher then
        dungeonID = NextKey222.DungeonNameMatcher:ParseGroupName(appData.name)
        Debug:Dev("pughelper", "DungeonNameMatcher lookup for '" .. appData.name .. "': " .. tostring(dungeonID))
    end
    
    if dungeonID then
        -- We found a dungeon ID! Set it as the teleport target
        Debug:Dev("pughelper", "OnMPlusAccepted: Found dungeonID=" .. dungeonID .. " from name '" .. appData.name .. "'")
        
        local fakeKeyInfo = {
            dungeonID = dungeonID,
            level = appData.keyLevel or 0,
            ownerName = appData.leader or "PUG Group",
        }
        
        -- Set teleport target with the matched dungeon
        NextKey:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
        NextKey:SetTeleportWindowContext({ mode = "PUG" })
    else
        -- Couldn't determine dungeon - show all portals
        Debug:Dev("pughelper", "OnMPlusAccepted: Could not determine dungeonID from '" .. (appData.name or "nil") .. "' - showing all portals")
        
        NextKey:SetTeleportWindowContext({
            mode = "PUG",
            groupName = appData.name,
            leader = appData.leader,
            keyLevel = appData.keyLevel
        })
    end
 
    -- Show teleport window shortly after acceptance if not already visible
    C_Timer.After(0.7, function()
        NextKey222.SafeRun(function()
            if not NextKey.teleportWindow or not NextKey.teleportWindow.frame or not NextKey.teleportWindow.frame:IsShown() then
                Debug:Dev("pughelper", "OnMPlusAccepted: showing teleport window")
                NextKey:ToggleTeleportWindow()
            else
                Debug:Dev("pughelper", "OnMPlusAccepted: teleport window already visible")
            end
        end, "PUGHelper:ShowTeleportOnMPlusAccepted")
    end)
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