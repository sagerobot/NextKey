-- Test script to explore LFG API capabilities
-- Use /testlfgapis to run

local function TestLFGAPIs()
    print("=== Testing LFG APIs ===")
    
    local applications = C_LFGList.GetApplications()
    if not applications or #applications == 0 then
        print("No active applications found. Apply to some M+ groups first!")
        return
    end
    
    print("Found " .. #applications .. " applications")
    print("")
    
    for i, resultID in ipairs(applications) do
        print("--- Application " .. i .. " (ID: " .. resultID .. ") ---")
        
        -- Try GetSearchResultInfo (what we're currently using)
        local searchInfo = C_LFGList.GetSearchResultInfo(resultID)
        if searchInfo then
            print("GetSearchResultInfo:")
            for k, v in pairs(searchInfo) do
                print("  " .. tostring(k) .. " = " .. tostring(v))
            end
        end
        
        -- Try GetApplicationInfo
        local appInfo = C_LFGList.GetApplicationInfo(resultID)
        if appInfo then
            print("GetApplicationInfo:")
            for k, v in pairs(appInfo) do
                print("  " .. tostring(k) .. " = " .. tostring(v))
            end
        end
        
        -- Try GetActivityInfoTable if we have activityIDs
        if searchInfo and searchInfo.activityIDs and type(searchInfo.activityIDs) == "table" then
            print("activityIDs table contains " .. #searchInfo.activityIDs .. " entries:")
            for i, activityID in ipairs(searchInfo.activityIDs) do
                print("  [" .. i .. "] = " .. tostring(activityID))
                
                -- Try to get activity info for this ID
                local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
                if activityInfo then
                    print("    GetActivityInfoTable(" .. activityID .. "):")
                    for k, v in pairs(activityInfo) do
                        print("      " .. tostring(k) .. " = " .. tostring(v))
                    end
                end
                
                -- Try GetActivityFullName
                local fullName = C_LFGList.GetActivityFullName(activityID)
                if fullName then
                    print("    GetActivityFullName: " .. tostring(fullName))
                end
                
                -- Try GetActivityGroupInfo
                local groupInfo = C_LFGList.GetActivityGroupInfo(activityID)
                if groupInfo then
                    print("    GetActivityGroupInfo: " .. tostring(groupInfo))
                end
            end
        end
        
        print("")
    end
    
    print("=== Test Complete ===")
end

SLASH_TESTLFGAPIS1 = "/testlfgapis"
SlashCmdList["TESTLFGAPIS"] = TestLFGAPIs

print("LFG API test loaded. Use /testlfgapis to test (apply to some M+ groups first).")