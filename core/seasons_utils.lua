local _, NextKey222 = ...
local NextKey = NextKey222.Addon

-- MARK: RaiderIO Integration
function NextKey:TryLoadRaiderIO(opts)
    opts = opts or {}
    if not RaiderIO or not RaiderIO.GetProfile then
        if not opts.silent then
            self:Print("RaiderIO addon not available.")
        end
        return false
    end
    local profile = RaiderIO.GetProfile("player")
    if profile and profile.mythicKeystoneProfile then
        return self:ApplyRaiderIOProfile(profile.mythicKeystoneProfile, opts)
    end
    if not opts.silent then
        self:Print("RaiderIO profile not ready.")
    end
    return false
end

-- MARK: Data Management
function NextKey:ClearMythicPlusData()
    local seasonData = self:EnsureSeasonData()
    if not seasonData then
        return
    end
    seasonData.currentScore = 0
    seasonData.bestLevels = {}
    seasonData.lastSyncTime = nil
    seasonData.lastSyncSource = nil
    if NextKey222.UI and NextKey222.UI.RenderResults and NextKey222.UI.mainFrame then
        NextKey222.UI:RenderResults()
    end
    self:Print("Cleared all Mythic+ score data.")
end