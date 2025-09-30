-- MARK: Initialization
local addon = LibStub("AceAddon-3.0"):GetAddon("NextKey", true)
if not addon then return end

local AceGUI = LibStub("AceGUI-3.0")

-- MARK: UI Utilities

local function trackAuxFrame(self, frame)
    if not frame then return end
    self._auxFrames = self._auxFrames or {}
    table.insert(self._auxFrames, frame)
end

local function darkenContent(frame)
    if not frame or frame._nkDarkened then return end
    local bg = frame.content:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.55)
    bg:SetAllPoints(frame.content)
    frame._nkDarkened = true
end

-- MARK: UI Components

function addon:CreateMainFrame()
    if self.mainFrame then return end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("NextKey")
    frame:SetStatusText("UI skeleton - M0.6")
    frame:SetLayout("Flow")
    frame:SetWidth(420)
    frame:SetHeight(640)
    frame:EnableResize(true)

    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        self.mainFrame = nil
        self.resultsFrame = nil
        self:ClearAuxFrames()
    end)

    darkenContent(frame)

    local header = AceGUI:Create("Label")
    header:SetText("Choose a sort mode; results area below.")
    header:SetFullWidth(true)
    frame:AddChild(header)

    local controls = AceGUI:Create("SimpleGroup")
    controls:SetFullWidth(true)
    controls:SetLayout("Flow")
    frame:AddChild(controls)

    local sortDrop = AceGUI:Create("Dropdown")
    sortDrop:SetLabel("Sort Mode")
    sortDrop:SetList({ HighestKeyLevel = "Highest Key Level", LowestKeyLevel = "Lowest Key Level" })
    sortDrop:SetValue(self:GetCurrentSortMode())
    sortDrop:SetCallback("OnValueChanged", function(_, _, key)
        self:SetSortMode(key)
        self:RenderResults()
    end)
    controls:AddChild(sortDrop)

    local refreshBtn = AceGUI:Create("Button")
    refreshBtn:SetText("Refresh")
    refreshBtn:SetAutoWidth(true)
    refreshBtn:SetCallback("OnClick", function()
        self:RenderResults()
    end)
    controls:AddChild(refreshBtn)

    local syncBtn = AceGUI:Create("Button")
    syncBtn:SetText("Sync")
    syncBtn:SetAutoWidth(true)
    syncBtn:SetCallback("OnClick", function()
        self:SendSync()
    end)
    controls:AddChild(syncBtn)

    local teleportWindowBtn = AceGUI:Create("Button")
    teleportWindowBtn:SetText("Open Teleport")
    teleportWindowBtn:SetAutoWidth(true)
    teleportWindowBtn:SetCallback("OnClick", function()
        self:ToggleTeleportWindow()
    end)
    controls:AddChild(teleportWindowBtn)

    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    frame:AddChild(spacer)

    local results = AceGUI:Create("ScrollFrame")
    results:SetFullWidth(true)
    results:SetFullHeight(true)
    results:SetLayout("List")
    frame:AddChild(results)

    self.resultsFrame = results
    self.mainFrame = frame

    self:RenderResults()
end

function addon:ToggleMainFrame()
    if self.mainFrame then
        self.mainFrame:Hide()
        AceGUI:Release(self.mainFrame)
        self.mainFrame = nil
        self.resultsFrame = nil
        self:ClearAuxFrames()
    else
        self:CreateMainFrame()
    end
end

function addon:SortKeys(keys, mode)
    local sorted = {}
    for _, key in ipairs(keys) do
        table.insert(sorted, { key = key })
    end

    if mode == "HighestKeyLevel" then
        table.sort(sorted, function(a, b)
            return (a.key.level or 0) > (b.key.level or 0)
        end)
    elseif mode == "LowestKeyLevel" then
        table.sort(sorted, function(a, b)
            return (a.key.level or 0) < (b.key.level or 0)
        end)
    end

    return sorted
end

function addon:RenderResults()
    if not self.resultsFrame then 
        if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
            self:Print("Debug: No results frame found")
        end
        return 
    end

    -- Clear existing content
    self:ClearAuxFrames()
    self.resultsFrame:ReleaseChildren()

    -- Get available keys
    local keys = self:GetAvailableKeys()
    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
        self:Print("Debug: GetAvailableKeys returned", keys and #keys or 0, "keys")
    end

    -- Update status text
    local mode = self:GetCurrentSortMode()
    if self.mainFrame and self.mainFrame.SetStatusText then
        local count = keys and #keys or 0
        self.mainFrame:SetStatusText(string.format("Mode: %s | Keys: %d | M0.6", tostring(mode), count))
    end

    if not keys or #keys == 0 then
        local none = AceGUI:Create("Label")
        none:SetText("No keys detected. Enable Debug in options or acquire a keystone.")
        none:SetFullWidth(true)
        self.resultsFrame:AddChild(none)
        return
    end

    local items = self:SortKeys(keys, mode)
    for _, it in ipairs(items) do
        self:AddKeyRow(it)
    end
end

function addon:AddKeyRow(entry)
    local keyInfo = entry.key
    local dungeonName = self:GetDungeonName(keyInfo.dungeonID)
    local ownerName = keyInfo.ownerName or "Unknown"
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Get player score
    local score = 0
    if keyInfo.ownerName and self:IsPlayerOwner(keyInfo.ownerName) then
        score = self:GetPlayerCalculatedScore()
        if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
            self:Print(string.format("Debug: Using player score %d for %s", score, keyInfo.ownerName))
        end
    else
        score = keyInfo.io or 0
        if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
            self:Print(string.format("Debug: Using key score %d for %s", score, keyInfo.ownerName or "Unknown"))
        end
    end
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local ownerColor = classColor and classColor.colorStr or "ffffffff"

    local container = AceGUI:Create("SimpleGroup")
    container:SetFullWidth(true)
    container:SetLayout("Fill")
    container:SetAutoAdjustHeight(false)
    container:SetHeight(88)
    self.resultsFrame:AddChild(container)

    local frame = CreateFrame("Frame", nil, container.frame, "BackdropTemplate")
    frame:SetAllPoints(container.frame)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.55)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    trackAuxFrame(self, frame)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 12, 0)
    icon:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if coords then
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end

    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    
    -- Get the appropriate score based on whether it's the player or not
    local score = 0
    if self.IsPlayerOwner and self:IsPlayerOwner(ownerName) then
        score = self:GetPlayerCalculatedScore()
    else
        score = keyInfo.io and tonumber(keyInfo.io) or 0
    end
    
    local nameDisplay = string.format("|c%s%s|r", ownerColor, ownerName)
    if score > 0 then
        nameDisplay = string.format("%s |cffFFD700(%d)|r", nameDisplay, score)
    end
    nameText:SetText(nameDisplay)
    nameText:SetJustifyH("LEFT")

    local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 2)
    levelText:SetText(string.format("Keystone: %s |cff4aa3ff+%d|r", dungeonName, keyInfo.level or 0))
    levelText:SetJustifyH("LEFT")

    local bestLevel = self.GetSeasonBestLevel and self:GetSeasonBestLevel(keyInfo.dungeonID)
    if bestLevel and bestLevel > 0 then
        local bestText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bestText:SetPoint("TOPLEFT", levelText, "BOTTOMLEFT", 0, -4)
        bestText:SetText(string.format("Your best: |cff4aa3ff+%d|r", bestLevel))
        bestText:SetJustifyH("LEFT")
    end

    local selectBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectBtn:SetSize(80, 22)
    selectBtn:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    selectBtn:SetText("Select")
    selectBtn:SetMotionScriptsWhileDisabled(true)
    trackAuxFrame(self, selectBtn)

    local isLeader = self:IsLeaderOrSolo()
    local isSelected = self.IsKeySelected and self:IsKeySelected(keyInfo)

    if isSelected then
        selectBtn:SetText("Selected")
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnClick", nil)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetAlpha(1)
        selectBtn:SetScript("OnClick", function()
            self:SetTeleportTargetKey(keyInfo, { broadcast = true })
        end)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set this keystone as the teleport target.")
            GameTooltip:AddLine("Shares the selection with party members running NextKey.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
    else
        selectBtn:Disable()
        selectBtn:SetAlpha(0.4)
        selectBtn:SetScript("OnClick", nil)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)


end

function addon:ClearAuxFrames()
    if not self._auxFrames then return end
    for _, frame in ipairs(self._auxFrames) do
        if frame and frame.Hide then
            frame:Hide()
            frame:SetParent(nil)
        end
    end
    wipe(self._auxFrames)
end

