local addonName, NS = ...

-- Initialize namespace
NS.COMM_PREFIX = "NKEY1"
NS.Addon = nil -- Will be set once addon is created

-- Create the addon
local NextKey = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0")
NS.Addon = NextKey

-- Function to update player's keystone
function NextKey:UpdatePlayerKeystone(mapID, level)
    -- Update local cache
    self.playerKeystone = {
        mapID = mapID,
        level = level
    }
    
    -- Notify group if in one
    if IsInGroup() then
        self:SendKeystoneData()
    end
end

-- Core library dependencies
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

-- MARK: Addon Lifecycle
function NextKey:OnInitialize()
    self.db = AceDB:New("NextKeyDB", NS.DEFAULTS, true)

    self.playerFullName = NS.Utils.safeGetName("player")
    self.playerShortName = self.playerFullName:match("^[^%-]+") or self.playerFullName
    self.playerClass = NS.Utils.safeGetClass("player") or ""

    self.cachedKeys = {}
    self.receivedKeys = {}
    self.teleportTargetKey = nil
    self.lastGroupSize = nil

    self:EnsureSeasonData()

    if type(self.RegisterEventHandlers) == "function" then
        self:RegisterEventHandlers()
    else
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
        self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
        self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnEvent")
    end

    if type(self.SetupOptions) == "function" then
        self:SetupOptions()
    end

    self:RegisterComm(NS.COMM_PREFIX, "OnCommReceived")
    self:RegisterChatCommand("nextkey", "SlashHandler")
    self:RegisterChatCommand("nk", "SlashHandler")
    self:RegisterChatCommand("keys", "SlashHandler")

    if type(self.EnsureTeleportWindow) == "function" then
        local window = self:EnsureTeleportWindow()
        if window and window.frame then
            window.frame:Hide()
        end
    end

    self:Print("NextKey initialized. Type /nk or /nk config.")
end

-- MARK: Slash Commands
function NextKey:GetArgs(input, num)
    if not input or input == "" then
        return
    end
    local args = {}
    for arg in input:gmatch("%S+") do
        table.insert(args, arg)
        if num and #args >= num then
            break
        end
    end
    return unpack(args, 1, num or #args)
end

function NextKey:SlashHandler(input)
    local command = self:GetArgs(input)
    if not command or command == "" then
        if type(self.ToggleMainFrame) == "function" then
            self:ToggleMainFrame()
        else
            self:Print("Main frame not available.")
        end
        return
    end

    command = command:lower()
    if command == "config" then
        if AceConfigDialog then
            AceConfigDialog:Open("NextKey")
        end
    elseif command == "teleport" then
        if type(self.ToggleTeleportWindow) == "function" then
            self:ToggleTeleportWindow()
        end
    elseif command == "sync" then
        self:SendSync()
    else
        if type(self.ToggleMainFrame) == "function" then
            self:ToggleMainFrame()
        else
            self:Print("Main frame not available.")
        end
    end
end

return NextKey