-- MARK: Debug Profile Adapter
-- Adapter for converting fake/debug player data into standard PlayerProfile format
-- Uses FakePlayerService exclusively (legacy paths removed)

local _, NextKey222 = ...

local DebugAdapter = {}

-- MARK: Profile Building
function DebugAdapter:GetProfile(playerName)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        return nil
    end
    
    local profile = NextKey222.FakePlayerService:GetProfile(playerName)
    if profile then
        NextKey222.Debug:Dev("debug", "Got profile from FakePlayerService for:", playerName)
    end
    
    return profile
end

-- MARK: Player Detection
function DebugAdapter:IsDebugPlayer(playerName)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        return false
    end
    
    return NextKey222.FakePlayerService:IsFakePlayer(playerName)
end

-- MARK: Player Management
function DebugAdapter:GetAllDebugPlayers()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        return {}
    end
    
    return NextKey222.FakePlayerService:GetAllPlayerNames()
end

-- MARK: Export
NextKey222.DebugAdapter = DebugAdapter