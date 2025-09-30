local addonName, NS = ...

-- Wait for addon to be created if it's not ready yet
local NextKey
if NS.Addon then
    NextKey = NS.Addon
else
    NextKey = LibStub("AceAddon-3.0"):GetAddon(addonName)
end

function NextKey:RegisterEventHandlers()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end

function NextKey:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        self:Print("Addon loaded")
    end
end