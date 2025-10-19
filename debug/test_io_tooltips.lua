-- IO Tooltip Test Script
-- Tests the centralized tooltip system for IO gain tooltips
-- Usage: /script TestIOTooltips()

local _, NextKey222 = ...

function TestIOTooltips()
    if not NextKey222.UI then
        print("|cFFFF0000ERROR: UI module not loaded|r")
        return
    end
    
    if not NextKey222.Tooltip then
        print("|cFFFF0000ERROR: Tooltip module not loaded|r")
        return
    end
    
    -- Enable debug output for tooltip category
    if NextKey222.Debug and NextKey222.Debug.SetLevel then
        NextKey222.Debug:SetLevel(3) -- DEV level
        print("|cffFFFF00Enabled debug mode for tooltip testing|r")
    end
    
    print("|cFF00FF00Testing IO Tooltip System...|r")
    
    -- Test 1: Check if centralized tooltip system is available
    if NextKey222.Tooltip and NextKey222.Tooltip.Create then
        print("|cff00ff00✓|r Centralized tooltip system available")
    else
        print("|cFFFF0000✗|r Centralized tooltip system not available")
        return
    end
    
    -- Test 2: Check if UI module has the new centralized function
    if NextKey222.UI.ShowIOGainTooltipCentralized then
        print("|cff00ff00✓|r ShowIOGainTooltipCentralized function available")
    else
        print("|cFFFF0000✗|r ShowIOGainTooltipCentralized function missing")
        return
    end
    
    -- Test 3: Test tooltip data building functions
    if NextKey222.UI.BuildIOTooltipTitle then
        print("|cff00ff00✓|r BuildIOTooltipTitle function available")
    else
        print("|cFFFF0000✗|r BuildIOTooltipTitle function missing")
    end
    
    if NextKey222.UI.BuildIOTooltipBreakdown then
        print("|cff00ff00✓|r BuildIOTooltipBreakdown function available")
    else
        print("|cFFFF0000✗|r BuildIOTooltipBreakdown function missing")
    end
    
    if NextKey222.UI.BuildIOTooltipTotals then
        print("|cff00ff00✓|r BuildIOTooltipTotals function available")
    else
        print("|cFFFF0000✗|r BuildIOTooltipTotals function missing")
    end
    
    -- Test 4: Create test data and try to build tooltip
    print("|cffFFFF00Testing tooltip creation with test data...|r")
    
    local testKeyInfo = {
        dungeonID = 503, -- Ara-Kara
        level = 15,
        ownerName = "TestPlayer-Realm"
    }
    
    local testIORange = {
        min = 120,
        max = 180,
        expected = 150,
        playerBreakdown = {
            ["TestPlayer-Realm"] = {
                min = 30,
                max = 45,
                current = 200
            },
            ["Player2-Realm"] = {
                min = 25,
                max = 40,
                current = 150
            }
        }
    }
    
    -- Test title building
    if NextKey222.UI.BuildIOTooltipTitle then
        local title = NextKey222.UI:BuildIOTooltipTitle(testKeyInfo, testIORange)
        if title and title ~= "" then
            print("|cff00ff00✓|r Title building works: " .. title)
        else
            print("|cFFFF0000✗|r Title building failed")
        end
    end
    
    -- Test breakdown building
    if NextKey222.UI.BuildIOTooltipBreakdown then
        local breakdown = NextKey222.UI:BuildIOTooltipBreakdown(testKeyInfo, testIORange)
        if breakdown and #breakdown > 0 then
            print("|cff00ff00✓|r Breakdown building works: " .. #breakdown .. " players")
        else
            print("|cFFFF0000✗|r Breakdown building failed")
        end
    end
    
    -- Test centralized tooltip creation
    if NextKey222.Tooltip.Create then
        -- Create a test frame to attach tooltip to
        local testFrame = CreateFrame("Frame", nil, UIParent)
        testFrame:SetSize(100, 20)
        testFrame:SetPoint("CENTER")
        testFrame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        testFrame:SetBackdropColor(0, 0, 0, 0.8)
        testFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        local tooltipData = {
            frame = testFrame,
            title = "Test IO Tooltip",
            subtitle = "Test Subtitle",
            breakdown = {
                {
                    name = "TestPlayer-Realm",
                    shortName = "TestPlayer",
                    minGain = 30,
                    maxGain = 45,
                    currentIO = 200,
                    hasNextKey = true
                }
            },
            totals = {
                timed = { total = 150, average = 75 },
                untimed = { total = 120, average = 60 }
            }
        }
        
        local success = pcall(function()
            NextKey222.Tooltip:Create(NextKey222.Tooltip.TYPE_IO_GAIN, tooltipData)
        end)
        
        if success then
            print("|cff00ff00✓|r Centralized tooltip creation works")
            print("|cffFFFF00Test frame created at center of screen. Hover over it to test tooltip.|r")
            
            -- Add hover scripts to test frame
            testFrame:SetScript("OnEnter", function()
                NextKey222.Tooltip:Create(NextKey222.Tooltip.TYPE_IO_GAIN, tooltipData)
            end)
            
            testFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            -- Auto-hide test frame after 30 seconds
            C_Timer.After(30, function()
                testFrame:Hide()
            end)
        else
            print("|cFFFF0000✗|r Centralized tooltip creation failed")
        end
    end
    
    print("|cFF00FF00IO Tooltip Test Complete!|r")
    print("|cffFFFF00To test in-game:|r")
    print("1. Get some fake players: /nk test preset mixed_skill")
    print("2. Set sort mode to 'IO Gain Potential'")
    print("3. Hover over the green IO gain text")
    print("4. Tooltip should appear with detailed breakdown")
    print("5. Check debug output for tooltip events")
end

-- Create slash command for easy testing
SLASH_TESTIOTOOLTIPS1 = "/testiotooltips"
SlashCmdList["TESTIOTOOLTIPS"] = function(msg)
    TestIOTooltips()
end

print("|cffFFFF00IO Tooltip Test Script loaded. Use /testiotooltips to test.|r")