-- MARK: Core Initialization
local _, NS = ...
local NextKey = NS.Addon

-- Library Dependencies
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Utility Dependencies
local Utils = NS.Utils
NextKey.Utils = Utils

-- MARK: Addon Lifecycle
function NextKey:OnInitialize()
    -- Initialize core settings
    self.COMM_PREFIX = NS.COMM_PREFIX

    -- Initialize database with defaults
    self.db = AceDB:New("NextKeyDB", NS.DEFAULTS, true)

    -- Set up player info
    self.playerFullName = Utils.safeGetName("player")
    self.playerShortName = self.playerFullName:match("^[^%-]+") or self.playerFullName
    self.playerClass = Utils.safeGetClass("player") or ""

    -- Initialize caches
    self.cachedKeys = {}
    self.receivedKeys = {}
    self.teleportTargetKey = nil
    self.lastGroupSize = nil
    
    -- Initialize scores
    self.currentSeasonScore = C_ChallengeMode.GetOverallDungeonScore() or 0
    self.previousSeasonScore = 0
    
    -- Try to get RaiderIO score if available
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local profile = _G.RaiderIO.GetProfile("player")
        if profile then
            self.currentSeasonScore = profile.mythicKeystoneScore or self.currentSeasonScore
            self.previousSeasonScore = profile.previousScore or 0
        end
    end
    
    -- Initialize debug module
    if not self.db.global.debug then
        self.db.global.debug = {
            enabled = false,
            players = {},
            addForm = { best = {} }
        }
    end
    
    -- Ensure debug state is consistent
    local dbg = self:EnsureDebug()
    if dbg then
        dbg.players = dbg.players or {}
        dbg.addForm = dbg.addForm or { best = {} }
    end

    -- Ensure season data is set up
    self:EnsureSeasonData()
    
    -- Set up score functions
    function self:GetPlayerCalculatedScore()
        return self.currentSeasonScore or 0
    end
    
    function self:IsPlayerOwner(name)
        if not name then return false end
        return name == self.playerFullName or name == self.playerShortName
    end
    
    -- Register events
    if type(self.RegisterEventHandlers) == "function" then
        self:RegisterEventHandlers()
    else
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    end

    -- Set up addon options
    if type(self.SetupOptions) == "function" then
        self:SetupOptions()
    end

    -- Register communication
    self:RegisterComm(self.COMM_PREFIX, "OnCommReceived")
    
    -- Register slash commands
    self:RegisterChatCommand("nextkey", "SlashHandler")
    self:RegisterChatCommand("nk", "SlashHandler")
    self:RegisterChatCommand("keys", "SlashHandler")

    -- Initialize teleport window if available
    if type(self.EnsureTeleportWindow) == "function" then
        local window = self:EnsureTeleportWindow()
        if window and window.frame then
            window.frame:Hide()
        end
    end

    self:Print("NextKey initialized. Type /nk or /nk config.")
end

-- MARK: Command Handling
-- Parses command arguments from input string
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

-- Handle slash commands
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