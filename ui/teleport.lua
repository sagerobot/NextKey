-- MARK: Initialization
local addon = LibStub("AceAddon-3.0"):GetAddon("NextKey", true)
if not addon then return end

-- MARK: Constants
local HEARTH_ITEM_ID = 6948
local SEASON_PORTALS = {
    -- The War Within Season 3 dungeon teleports.
    [503] = { mapID = 503, spellID = 445417, name = "Ara-Kara, City of Echoes", alias = "Ara", destination = "Ara-Kara, City of Echoes" }, -- Real ID for Ara-Kara
    [524] = { mapID = 524, spellID = 445414, name = "The Dawnbreaker", alias = "Dawn", destination = "The Dawnbreaker" },
    [526] = { mapID = 526, spellID = 1237215, name = "Eco-Dome Al'dani", alias = "Eco", destination = "Eco-Dome Al'dani" },
    [377] = { mapID = 377, spellID = 354465, name = "Halls of Atonement", alias = "Halls", destination = "Halls of Atonement" },
    [525] = { mapID = 525, spellID = 1216786, name = "Operation: Floodgate", alias = "Flood", destination = "Operation: Floodgate" },
    [523] = { mapID = 523, spellID = 445444, name = "Priory of the Sacred Flame", alias = "Priory", destination = "Priory of the Sacred Flame" },
    [401] = { mapID = 401, spellID = 367416, name = "Tazavesh: Streets of Wonder", alias = "Streets", destination = "Tazavesh: Streets of Wonder" },
    [402] = { mapID = 402, spellID = 367416, name = "Tazavesh: So'leah's Gambit", alias = "Gambit", destination = "Tazavesh: So'leah's Gambit" },
}
local SPELL_BANK_PLAYER = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
local SPELL_BANK_PET = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1

local function safeGetItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemID)
    end
    if GetItemInfo then
        return GetItemInfo(itemID)
    end
end

local function getHearthName()
    local name = select(1, safeGetItemInfo(HEARTH_ITEM_ID))
    return name or "Hearthstone"
end

local function safeGetSpellInfo(spellID)
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID
        end
    end
    return nil, nil, nil
end

local function playerKnowsSpell(spellID)
    if not spellID then return false end
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
        if C_SpellBook.IsSpellInSpellBook(spellID, SPELL_BANK_PLAYER) then
            return true
        end
        if C_SpellBook.IsSpellInSpellBook(spellID, SPELL_BANK_PET) then
            return true
        end
    end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then return true end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    return false
end

local cachedPlayerFullName
local cachedPlayerShortName

local function getPlayerFullName()
    if cachedPlayerFullName then
        return cachedPlayerFullName
    end
    if UnitFullName then
        local name, realm = UnitFullName("player")
        if name and name ~= "" then
            if realm and realm ~= "" then
                cachedPlayerFullName = string.format("%s-%s", name, realm)
            else
                cachedPlayerFullName = name
            end
        end
    end
    if not cachedPlayerFullName then
        local name = UnitName and UnitName("player")
        cachedPlayerFullName = name or ""
    end
    cachedPlayerShortName = cachedPlayerFullName and cachedPlayerFullName:match("^[^%-]+") or cachedPlayerFullName
    return cachedPlayerFullName
end

local function isHearthstoneEnabled()
    if addon and addon.IsHearthstoneEnabled then
        return addon:IsHearthstoneEnabled()
    end
    local tele = addon and addon.db and addon.db.global and addon.db.global.teleport
    return tele and tele.showHearthstone == true
end

local function getKeystoneTeleportData()
    if not addon then
        return nil
    end
    local keyInfo
    if addon.GetTeleportTargetKey then
        keyInfo = addon:GetTeleportTargetKey()
    elseif addon.ScanPlayerKeystone then
        keyInfo = addon:ScanPlayerKeystone()
    end
    -- Handle case where keyInfo is just a dungeon ID
    if type(keyInfo) == "number" then
        keyInfo = {
            dungeonID = keyInfo,
            level = 2  -- Default to +2 if unknown
        }
    end
    if keyInfo and (not keyInfo.io or keyInfo.io <= 0) and addon.GetCurrentSeasonData then
        local seasonData = addon:GetCurrentSeasonData()
        if seasonData and seasonData.currentScore and seasonData.currentScore > 0 then
            keyInfo.io = seasonData.currentScore
        end
    end
    if not keyInfo or not keyInfo.dungeonID then
        return nil
    end
    local dungeonName = addon:GetDungeonName(keyInfo.dungeonID)
    if not dungeonName then return nil end
    local portal
    for _, data in pairs(SEASON_PORTALS) do
        if data.name == dungeonName then
            portal = data
            break
        end
    end
    -- If not found in SEASON_PORTALS, try to find it in NextKey_DungeonNames and then get the spell from NextKey_PortalDB
    if not portal and type(NextKey_DungeonNames) == "table" and type(NextKey_PortalDB) == "table" then
        local mapID
        for id, name in pairs(NextKey_DungeonNames) do
            if name == dungeonName then
                mapID = id
                break
            end
        end
        if mapID then
            local spellID = NextKey_PortalDB[mapID]
            if spellID then
                portal = {
                    mapID = mapID,
                    spellID = spellID,
                    name = dungeonName,
                    destination = dungeonName,
                    alias = NextKey_DungeonAliases and NextKey_DungeonAliases[mapID],
                }
            end
        end
    end
    if not portal then
        -- Could not find the dungeon in our databases
        return {
            mapID = keyInfo.dungeonID,
            level = keyInfo.level or 0,
            ownerName = keyInfo.ownerName,
            class = keyInfo.class,
            io = keyInfo.io,
            dungeonName = dungeonName,
            destination = dungeonName,
            alias = NextKey_DungeonAliases and NextKey_DungeonAliases[keyInfo.dungeonID],
        }
    end
    local spellID = portal.spellID
    local spellName, _, spellTexture = safeGetSpellInfo(spellID)
    return {
        mapID = portal.mapID, -- Use the ID from our DB
        level = keyInfo.level or 0,
        ownerName = keyInfo.ownerName,
        class = keyInfo.class,
        io = keyInfo.io,
        spellID = spellID,
        spellName = spellName or dungeonName,
        icon = spellTexture,
        dungeonName = dungeonName,
        destination = dungeonName,
        alias = portal.alias or (NextKey_DungeonAliases and NextKey_DungeonAliases[portal.mapID]),
    }
end

local function setButtonTexture(button, texture)
    local tex = texture or "Interface/Icons/INV_Misc_QuestionMark"
    button:SetNormalTexture(tex)
    local normal = button:GetNormalTexture()
    if normal then normal:SetAllPoints() end
    button:SetPushedTexture(tex)
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAllPoints()
        pushed:SetVertexColor(0.9, 0.9, 0.9)
    end
    button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetAllPoints()
        highlight:SetBlendMode("ADD")
    end
end

local function createTeleportButton(parent, texture, tooltipFunc)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(48, 48)
    -- Allow actions to fire regardless of ActionButtonUseKeyDown
    button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    setButtonTexture(button, texture)
    if tooltipFunc then
        button:SetScript("OnEnter", tooltipFunc)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return button
end

local function updateTeleportLayout(window)
    if not window or not window.frame then
        return
    end
    local frame = window.frame
    local closeButton = window.closeButton
    local titleLabel = window.titleLabel
    local hearthButton = window.hearthButton
    local keystoneButton = window.keystoneButton
    local aliasLabel = window.keystoneAliasLabel
    local levelLabel = window.keystoneLevelLabel
    local noteLabel = window.keystoneOwnerNoteLabel
    local showHearth = isHearthstoneEnabled()

    local leftPadding = 14
    local rightPadding = 14
    local betweenPadding = 12
    local topPadding = 12
    local titleHeight = (titleLabel and titleLabel:GetStringHeight()) or 14
    local contentTop = topPadding + titleHeight + 6

    if hearthButton then
        hearthButton:ClearAllPoints()
        if showHearth then
            hearthButton:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPadding, -contentTop)
            hearthButton:Show()
            local hearthTexture = select(10, safeGetItemInfo(HEARTH_ITEM_ID)) or "Interface/Icons/INV_Misc_Rune_01"
            setButtonTexture(hearthButton, hearthTexture)
            hearthButton:SetAttribute("type", "item")
            hearthButton:SetAttribute("item", getHearthName())
            contentTop = contentTop + 48 + 6
        else
            hearthButton:Hide()
            hearthButton:SetAttribute("type", nil)
            hearthButton:SetAttribute("item", nil)
        end
    end

    if keystoneButton then
        keystoneButton:ClearAllPoints()
        keystoneButton:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPadding, -contentTop)
    end

    local aliasWidth = aliasLabel and aliasLabel:GetStringWidth() or 0
    local aliasHeight = 0
    if aliasLabel then
        aliasLabel:ClearAllPoints()
        aliasLabel:SetPoint("TOP", keystoneButton, "BOTTOM", 0, -4)
        aliasLabel:SetJustifyH("CENTER")
        if aliasLabel:IsShown() and aliasLabel:GetText() ~= "" then
            aliasHeight = aliasLabel:GetStringHeight() or 0
            local aliasFont = aliasLabel:GetFontObject()
            if aliasFont and aliasFont.GetLineHeight then
                local lh = aliasFont:GetLineHeight()
                if lh and lh > 0 then
                    aliasHeight = math.max(aliasHeight, lh)
                end
            end
        else
            aliasHeight = 0
            aliasWidth = 0
            aliasLabel:Hide()
        end
    end

    local levelWidth = levelLabel and levelLabel:GetStringWidth() or 0
    local noteHeight = 0
    local noteColumnWidth = levelWidth
    if noteLabel and levelLabel then
        noteLabel:ClearAllPoints()
        noteLabel:SetPoint("TOP", levelLabel, "BOTTOM", 0, -4)
        noteLabel:SetJustifyH("CENTER")
        if noteLabel:IsShown() and noteLabel:GetText() ~= "" then
            local preferredWidth = 72
            noteLabel:SetWidth(preferredWidth)
            noteColumnWidth = math.max(levelWidth, preferredWidth)
            noteHeight = noteLabel:GetStringHeight() or 0
            local noteFont = noteLabel:GetFontObject()
            if noteFont and noteFont.GetLineHeight then
                local lh = noteFont:GetLineHeight()
                if lh and lh > 0 then
                    noteHeight = math.max(noteHeight, lh)
                end
            end
        else
            noteLabel:Hide()
            noteColumnWidth = levelWidth
            noteHeight = 0
        end
    elseif noteLabel then
        noteLabel:Hide()
    end

    local iconColumnWidth = math.max(48, aliasWidth)
    if aliasLabel then
        aliasLabel:SetWidth(iconColumnWidth)
        if aliasHeight <= 0 then
            aliasLabel:Hide()
        else
            aliasLabel:Show()
        end
    end

    local levelColumnWidth = math.max(levelWidth, noteColumnWidth)
    if noteLabel then
        noteLabel:SetWidth(levelColumnWidth)
        if noteHeight <= 0 then
            noteLabel:Hide()
        end
    end

    local contentWidth = leftPadding + iconColumnWidth + betweenPadding + levelColumnWidth + rightPadding
    local frameWidth = math.max(160, math.ceil(contentWidth))

    local aliasExtra = aliasHeight > 0 and (aliasHeight + 6) or 0
    local noteExtra = noteHeight > 0 and (noteHeight + 6) or 0
    local extraHeight = math.max(aliasExtra, noteExtra)
    local baseHeight = contentTop + 48 + extraHeight + 12

    frame:SetSize(frameWidth, math.ceil(baseHeight))

    if closeButton then
        closeButton:ClearAllPoints()
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
        closeButton:SetFrameStrata(frame:GetFrameStrata())
        closeButton:EnableMouse(true)
        closeButton:SetHitRectInsets(0, 0, 0, 0)
        closeButton:Raise()
    end
end

local function updateKeystoneButton(window)
    if not window or not window.keystoneButton then
        return
    end
    local button = window.keystoneButton
    local aliasLabel = window.keystoneAliasLabel
    local levelLabel = window.keystoneLevelLabel
    local noteLabel = window.keystoneOwnerNoteLabel
    local data = getKeystoneTeleportData()
    button.keystoneData = data
    setButtonTexture(button, data and data.icon)

    local isPlayersKey = false
    if data and data.ownerName and data.ownerName ~= "" then
        local ownerName = data.ownerName
        if strtrim then
            ownerName = strtrim(ownerName)
        end
        if ownerName and ownerName ~= "" then
            local ownerLower = string.lower(ownerName)
            local full = getPlayerFullName()
            if full and full ~= "" then
                local playerLower = string.lower(full)
                if ownerLower == playerLower then
                    isPlayersKey = true
                else
                    local short = cachedPlayerShortName or full:match("^[^%-]+") or full
                    if short and short ~= "" and ownerLower == string.lower(short) then
                        isPlayersKey = true
                    end
                end
            end
        end
    end

    if aliasLabel then
        if data and (data.alias or data.dungeonName or data.destination) then
            aliasLabel:SetText(data.alias or data.dungeonName or data.destination)
            aliasLabel:Show()
        else
            aliasLabel:SetText("No keystone selected.")
            aliasLabel:Show()
        end
    end

    if noteLabel then
        local lines = {}
        if isPlayersKey then
            lines[#lines + 1] = "*YOUR KEY*"
            noteLabel:SetTextColor(0.1, 1, 0.4)
        else
            noteLabel:SetTextColor(0.85, 0.85, 0.85)
        end
        local ioScore = data and tonumber(data.io)
        if ioScore and ioScore > 0 then
            lines[#lines + 1] = string.format("IO: %d", ioScore)
        end
        if #lines > 0 then
            noteLabel:SetText(table.concat(lines, "\n"))
            noteLabel:Show()
        else
            noteLabel:SetText("")
            noteLabel:Hide()
        end
    end

    if data and data.spellID and playerKnowsSpell(data.spellID) then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", data.spellID)
        button:Enable()
        local tex = button:GetNormalTexture()
        if tex then tex:SetDesaturated(false) end
        if levelLabel then
            if data.level and data.level > 0 then
                levelLabel:SetFormattedText("+%d", data.level)
                levelLabel:SetTextColor(1, 0.82, 0)
            else
                levelLabel:SetText("")
            end
        end
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
        button:Disable()
        local tex = button:GetNormalTexture()
        if tex then tex:SetDesaturated(true) end
        if levelLabel then
            if data and data.level and data.level > 0 then
                levelLabel:SetFormattedText("+%d", data.level)
                levelLabel:SetTextColor(0.7, 0.7, 0.7)
            else
                levelLabel:SetText("")
            end
        end
    end
end

local function showKeystoneTooltip(button)
    if not button then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local data = button.keystoneData or getKeystoneTeleportData()
    local ioScore = data and tonumber(data.io)
    if data and data.spellID then
        GameTooltip:SetSpellByID(data.spellID)
        if data.destination then
            GameTooltip:AddLine(string.format("Destination: %s", data.destination), 0.8, 0.8, 0.8)
        end
        if data.ownerName and data.ownerName ~= "" then
            GameTooltip:AddLine(string.format("Selected key: %s", data.ownerName), 0.9, 0.9, 0.9)
        end
        if data.level and data.level > 0 then
            GameTooltip:AddLine(string.format("Keystone +%d", data.level), 1, 0.82, 0)
        end
        local mapID = data.dungeonID or data.mapID
        if mapID and addon.GetSeasonBestEntry then
            local bestEntry = addon:GetSeasonBestEntry(mapID)
            if bestEntry and bestEntry.level and bestEntry.level > 0 then
                local timed = bestEntry.timed == true or (bestEntry.chests or 0) > 0
                local status = timed and "timed" or "depleted"
                GameTooltip:AddLine(string.format("Your best: +%d (%s)", bestEntry.level, status), 0.6, 0.9, 1)
            end
        end
        if ioScore and ioScore > 0 then
            GameTooltip:AddLine(string.format("IO Score: %d", ioScore), 0.8, 0.8, 1)
        end
        if not playerKnowsSpell(data.spellID) then
            GameTooltip:AddLine("You have not learned this teleport yet.", 1, 0.2, 0.2)
        end
    elseif data then
        GameTooltip:SetText(data.destination or data.dungeonName or "No keystone teleport available")
        if data.ownerName and data.ownerName ~= "" then
            GameTooltip:AddLine(string.format("Selected key: %s", data.ownerName), 0.9, 0.9, 0.9)
        end
        local mapID = data.dungeonID or data.mapID
        if mapID and addon.GetSeasonBestEntry then
            local bestEntry = addon:GetSeasonBestEntry(mapID)
            if bestEntry and bestEntry.level and bestEntry.level > 0 then
                local timed = bestEntry.timed == true or (bestEntry.chests or 0) > 0
                local status = timed and "timed" or "depleted"
                GameTooltip:AddLine(string.format("Your best: +%d (%s)", bestEntry.level, status), 0.6, 0.9, 1)
            end
        end
        if ioScore and ioScore > 0 then
            GameTooltip:AddLine(string.format("IO Score: %d", ioScore), 0.8, 0.8, 1)
        end
        GameTooltip:AddLine("No teleport is configured for this dungeon.", 1, 0.82, 0)
    else
        GameTooltip:SetText("No keystone teleport available")
    end
    GameTooltip:Show()
end

function addon:EnsureTeleportWindow()
    if self.teleportWindow and self.teleportWindow.frame then
        return self.teleportWindow
    end
    local frame = CreateFrame("Frame", "NextKeyTeleportWindow", UIParent, "BackdropTemplate")
    frame:SetSize(200, 140)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(600)
    frame:SetToplevel(true)
    frame:Hide()
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    close:SetFrameLevel(frame:GetFrameLevel() + 10)
    close:SetFrameStrata(frame:GetFrameStrata())
    close:EnableMouse(true)
    close:SetHitRectInsets(0, 0, 0, 0)
    close:Raise()
    close:SetScript("OnClick", function() frame:Hide() end)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
    title:SetText("NextKey")
    local hearthTexture = select(10, safeGetItemInfo(HEARTH_ITEM_ID)) or "Interface/Icons/INV_Misc_Rune_01"
    local hearthButton = createTeleportButton(frame, hearthTexture, function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(HEARTH_ITEM_ID)
        GameTooltip:Show()
    end)
    hearthButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
    hearthButton:SetScript("PostClick", function(_, mouseButton)
        addon:Print("Debug: Hearth button PostClick (" .. tostring(mouseButton) .. ")")
    end)
    local keystoneData = getKeystoneTeleportData()
    local keystoneTexture = (keystoneData and keystoneData.icon) or "Interface/Icons/INV_Misc_QuestionMark"
    local keystoneButton = createTeleportButton(frame, keystoneTexture, showKeystoneTooltip)
    keystoneButton:SetPoint("TOPLEFT", hearthButton, "BOTTOMLEFT", 0, -18)
    keystoneButton:SetScript("PostClick", function(_, mouseButton)
        addon:Print("Debug: Keystone button PostClick (" .. tostring(mouseButton) .. ")")
    end)
    local keystoneAlias = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    keystoneAlias:SetJustifyH("CENTER")
    keystoneAlias:SetText("")
    keystoneAlias:SetTextColor(0.85, 0.85, 0.85)
    local keystoneLevel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    keystoneLevel:SetPoint("LEFT", keystoneButton, "RIGHT", 12, 0)
    keystoneLevel:SetJustifyH("LEFT")
    keystoneLevel:SetText("")
    keystoneLevel:SetTextColor(1, 0.82, 0)
    local keystoneNote = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    keystoneNote:SetJustifyH("CENTER")
    keystoneNote:SetText("")
    keystoneNote:SetTextColor(0.1, 1, 0.4)
    keystoneNote:Hide()
    local noteFont, noteSize, noteFlags = keystoneNote:GetFont()
    if noteFont and noteSize then
        local targetSize = math.min(noteSize + 2, 18)
        keystoneNote:SetFont(noteFont, targetSize, noteFlags)
    end
    self.teleportWindow = {
        frame = frame,
        closeButton = close,
        titleLabel = title,
        hearthButton = hearthButton,
        keystoneButton = keystoneButton,
        keystoneAliasLabel = keystoneAlias,
        keystoneLevelLabel = keystoneLevel,
        keystoneOwnerNoteLabel = keystoneNote,
    }

    updateKeystoneButton(self.teleportWindow)
    updateTeleportLayout(self.teleportWindow)
    return self.teleportWindow
end

function addon:ToggleTeleportWindow()
    local window = self:EnsureTeleportWindow()
    if not window then return end
    if window.frame:IsShown() then
        window.frame:Hide()
        return
    end

    updateKeystoneButton(window)
    updateTeleportLayout(window)

    window.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    window.frame:SetFrameLevel(600)
    window.frame:SetToplevel(true)
    window.frame:Show()
    window.frame:Raise()
end

function addon:RefreshTeleportWindow()
    if not self.teleportWindow then
        return
    end
    updateKeystoneButton(self.teleportWindow)
    updateTeleportLayout(self.teleportWindow)
end

















