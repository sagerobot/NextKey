-- Information about guild keystone sharing requirements

print("=== Guild Keystone Sharing Requirements ===")
print("")
print("For guild keystone sharing to work, OTHER guild members need:")
print("")
print("📋 COMPATIBLE ADDONS (one of these):")
print("   • RaiderIO - Most common, includes LibOpenRaid")
print("   • Details! - Popular damage meter with LibOpenRaid")
print("   • OmniCD - Cooldown tracker with LibOpenRaid")
print("   • Method Raid Tools (MRT) - Raid planning addon")
print("   • Any other addon that includes LibOpenRaid-1.0")
print("")
print("🔧 WHAT TO ASK YOUR GUILD MEMBERS TO DO:")
print("   1. Install RaiderIO (easiest option)")
print("   2. Type '/reload' to ensure LibOpenRaid loads")
print("   3. Make sure they have keystones in their bags")
print("   4. Be online when you request guild keystones")
print("")
print("💡 ALTERNATIVE METHODS:")
print("   • Ask guild members to link keystones in chat manually")
print("   • Use guild discord/website to coordinate keystones")
print("   • Form a party with members who have keystones")
print("")
print("🔍 TO TEST IF IT'S WORKING:")
print("   1. Click 'Guild Keys' button in NextKey")
print("   2. Look for message: 'Requesting guild keystones...'")
print("   3. Wait 3-5 seconds for responses")
print("   4. Check if other players' keystones appear")
print("")
print("Current guild members online who might have compatible addons:")

if IsInGuild() then
    C_GuildInfo.GuildRoster() -- Refresh roster
    local numMembers = GetNumGuildMembers()
    local onlineCount = 0
    
    for i = 1, numMembers do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            onlineCount = onlineCount + 1
            local shortName = name:match("^([^%-]+)") or name
            print("   • " .. shortName)
        end
    end
    
    print("")
    print("Total online guild members: " .. onlineCount)
    print("")
    
    if onlineCount < 2 then
        print("ℹ️ Only you are online - guild keystone sharing needs other online members")
    else
        print("✓ Multiple members online - ask them to install RaiderIO for keystone sharing")
    end
else
    print("❌ You are not in a guild")
end

print("")
print("=== END GUILD KEYSTONE INFO ===")
print("Run this again anytime: /run loadfile('Interface/AddOns/NextKey/guild_info.lua')()")