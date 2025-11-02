-- MARK: Spec Change Detection Test
-- Test that spec changes are detected for group members

local _, NextKey222 = ...

function TestSpecChangeDetection()
    if not NextKey222.Debug then
        print("Debug system not available")
        return
    end
    
    local Debug = NextKey222.Debug
    Debug:User("===== SPEC CHANGE DETECTION TEST =====")
    
    -- Get all group members
    local members = {}
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = IsInRaid() and "raid" .. i or "party" .. i
            local name, realm = UnitName(unit)
            if name then
                local fullName = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
                table.insert(members, {
                    name = fullName,
                    unit = unit
                })
            end
        end
    end
    
    -- Add current player
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    table.insert(members, {
        name = playerName .. "-" .. realmName,
        unit = "player"
    })
    
    Debug:User("Found " .. #members .. " group members")
    Debug:User("")
    
    -- Test each member
    for _, member in ipairs(members) do
        Debug:User("=== " .. member.name .. " ===")
        
        -- Get Blizzard adapter data
        local blizzProfile = NextKey222.BlizzardAdapter and NextKey222.BlizzardAdapter:GetProfile(member.name)
        if blizzProfile then
            Debug:User("  Blizzard Adapter:")
            Debug:User("    specID: " .. tostring(blizzProfile.specID))
            Debug:User("    role: " .. tostring(blizzProfile.role))
            Debug:User("    specName: " .. tostring(blizzProfile.specName))
        else
            Debug:User("  Blizzard Adapter: NO DATA")
        end
        
        -- Get RaiderIO adapter data
        local rioProfile = NextKey222.RaiderIOAdapter and NextKey222.RaiderIOAdapter:GetProfile(member.name)
        if rioProfile then
            Debug:User("  RaiderIO Adapter:")
            Debug:User("    specID: " .. tostring(rioProfile.specID))
            Debug:User("    (RaiderIO doesn't provide role/specName)")
        else
            Debug:User("  RaiderIO Adapter: NO DATA")
        end
        
        -- Get final merged profile
        local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(member.name)
        if profile then
            Debug:User("  Final Profile:")
            Debug:User("    specID: " .. tostring(profile.specID))
            Debug:User("    role: " .. tostring(profile.role))
            Debug:User("    specName: " .. tostring(profile.specName))
            Debug:User("    dataSource: " .. tostring(profile.dataSource))
        else
            Debug:User("  Final Profile: NO DATA")
        end
        
        Debug:User("")
    end
    
    Debug:User("===== TEST COMPLETE =====")
    Debug:User("Instructions: Have a group member change spec, then run this test again.")
    Debug:User("The 'role' should update to match their new spec (TANK/HEALER/DAMAGER)")
end

-- Register slash command
SLASH_TESTSPECCHANGE1 = "/testspec"
SlashCmdList["TESTSPECCHANGE"] = function()
    TestSpecChangeDetection()
end

print("Spec change test loaded. Type /testspec to run.")