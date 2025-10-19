local addon, ns = ...
local version = 0.71
local newVersion = false

local players = {}

local partyList = {}
local addonPrefix = "PORTAPARTY"
C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix)

local myRealm = GetNormalizedRealmName()
local myName = UnitName("player")
local myKeystoneID = C_MythicPlus.GetOwnedKeystoneMapID()

local mapInfo = C_MythicPlus.RequestMapInfo()

local seasonID = 0
local dungeonFrames = {}
local overall = 0
local equipped = 0

PortaParty_UIFrame = CreateFrame("Frame", "PortaParty", UIParent, "BasicFrameTemplateWithInset")
PortaParty_UIFrame:Hide()
PortaParty_UIFrame:SetMovable(true)
PortaParty_UIFrame:EnableMouse(true)
PortaParty_UIFrame:RegisterForDrag("LeftButton")
PortaParty_UIFrame:SetScript("OnDragStart", PortaParty_UIFrame.StartMoving)
PortaParty_UIFrame:SetScript("OnDragStop", PortaParty_UIFrame.StopMovingOrSizing)

local icon = LibStub("LibDBIcon-1.0")


local LibOpenRaidKeystonePrefix = "K"
local function onReceiveComm(self, event, prefix, text, channel, sender)
    --check if the data belong to us
    if (prefix == "LRS") then
        sender = Ambiguate(sender, "none")

        --don't receive comms from the player itself
        local playerName = UnitName("player")
        if (playerName == sender) then
            return
        end

        local data = text
        local LibDeflate = LibStub:GetLibrary("LibDeflate")
        local dataCompressed = LibDeflate:DecodeForWoWAddonChannel(data)
        data = LibDeflate:DecompressDeflate(dataCompressed)

        --some users are reporting errors where 'data is nil'. Making some sanitization
        if (not data) then
            return
        elseif (type(data) ~= "string") then
            return
        end
        local dataTypePrefix = data:match("^.")
        if dataTypePrefix ~= LibOpenRaidKeystonePrefix then
            return
        end


        --convert to table
        local dataAsTable = { strsplit(",", data) }
        if dataAsTable[1] == LibOpenRaidKeystonePrefix then
            if players[sender] == nil then
                players[sender] = {
                    mapID = 0,
                    level = 0,
                    rating = 0,
                    version = 0,
                    overall = 0,
                    equipped = 0,
                    timestamp = date(),
                }
            end
            if players[sender].version == 0 then
                players[sender] = {
                    mapID = tonumber(dataAsTable[3]),
                    level = tonumber(dataAsTable[2]),
                    rating = tonumber(dataAsTable[6]),
                    version = 0,
                    overall = 0,
                    equipped = 0,
                    timestamp = date(),
                }
            end
        end

        --remove the first index (prefix)



        --trigger callbacks
    end
end


local function secToStr(a) -- Time in seconds
    if a > 3600 then
        return floor((mod(a, 86400) / 3600) + 0.5) .. "h"
    elseif a > 60 then
        return floor((mod(a, 3600) / 60) + 0.5) .. "m"
    end
    return floor(mod(a, 60)) .. "s"
end





-- get the player's info
local function getPlayerInfo()
    --print("PortaParty calling getPlayerInfo()")
    myKeystoneID = C_MythicPlus.GetOwnedKeystoneMapID()
    if myKeystoneID ~= nil then
        return {
            mapID = myKeystoneID,
            level = C_MythicPlus.GetOwnedKeystoneLevel(),
            isKnown = IsSpellKnown(ns.lookups[myKeystoneID].spellID, false),
            isUsable = IsUsableSpell(ns.lookups[myKeystoneID].spellID),
            --realm = myRealm,
            timestamp = date(),
            overall = overall,
            equipped = equipped
        }
    end
    myKeystoneID = 0
    return {
        mapID = 0,
        level = 0,
        isKnown = false,
        isUsable = false,
        --realm = myRealm,
        timestamp = date(),
        overall = overall,
        equipped = equipped
    }
end

local function updatePartyKeys(sender, text)
    if IsInGroup() then
        local senderName = sender
        if text ~= nil then
            local responses = {}
            for r in (text .. ","):gmatch("([^,]*),") do
                table.insert(responses, r)
            end
            local senderFull = {}
            for r in (sender .. "-"):gmatch("([^-]*)-") do
                table.insert(senderFull, r)
            end

            if senderFull[2] == GetNormalizedRealmName() then
                senderName = senderFull[1]
            end
            if responses[1] == "S" then
                -- list of unknown spells
                players[senderName].spells = {}
                for i = 2, #responses do
                    table.insert(players[senderName].spells, responses[i])
                end
            end
            if responses[1] == "K" then
                -- key info

                -- fill in missing data

                -- rating
                if responses[4] == nil then
                    responses[4] = 0
                end

                -- version
                if responses[5] == nil then
                    responses[5] = version
                end

                -- overall item level
                if responses[6] == nil then
                    responses[6] = 0
                end

                -- equipped item level
                if responses[7] == nil then
                    responses[7] = 0
                end

                players[senderName] = {
                    mapID = tonumber(responses[2]),
                    level = tonumber(responses[3]),
                    rating = responses[4],
                    version = responses[5],
                    overall = responses[6],
                    equipped = responses[7],
                    timestamp = date(),
                }
                if tonumber(players[senderName].version) > version and newVersion == false then
                    print("A new version of |cff00ffffPortaParty|r is available.")
                    newVersion = true
                end
            end
        end
    end
end

local function generateUpdateMessage()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    local overall, equipped = GetAverageItemLevel()
    local message = ""
    if mapID == nil then
        mapID = 0
        keystoneLevel = 0
    end
    message = mapID .. ","
        .. keystoneLevel .. ","
        .. C_ChallengeMode.GetOverallDungeonScore() .. ","
        .. version .. ","
        .. overall .. ","
        .. equipped
    return "K," .. message
end

local function generateUnknownPortals()
    local message = "S"
    local spellList = {}
    for i = 1, #ns.seasons[seasonID] do
        local spellID = ns.lookups[ns.seasons[seasonID][i]].spellID
        if IsSpellKnown(tonumber(spellID), false) == false then
            message = message .. "," .. spellID
        end
    end
    return message
end


local function OnEvent(self, event, ...)
    local prefix, message, channel, sender = ...
    if event == "CHAT_MSG_ADDON" then
        if prefix == "LRS" then
            onReceiveComm(self, nil, "LRS", message, nil, sender)
        end
    end
    if IsInGroup() then
        if event == "CHAT_MSG_ADDON" then
            if prefix == addonPrefix then
                if message == "query" then
                    C_ChatInfo.SendAddonMessage(addonPrefix, generateUpdateMessage(), "PARTY")
                    C_ChatInfo.SendAddonMessage(addonPrefix, generateUnknownPortals(), "PARTY")
                end
                if channel == "PARTY" and prefix == addonPrefix then
                    updatePartyKeys(sender, message)
                end
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            local isLogin, isReload = ...
            if isLogin or isReload then
                C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix)
            end
            mapInfo = C_MythicPlus.RequestMapInfo()
        elseif event == "GROUP_ROSTER_UPDATE" then
            partyList = GetHomePartyInfo(partyList)
            local result = C_ChatInfo.SendAddonMessage(addonPrefix, generateUpdateMessage(), "PARTY")
            C_ChatInfo.SendAddonMessage(addonPrefix, generateUnknownPortals(), "PARTY")
        end
    end
end

local function RequestQuery()
    C_ChatInfo.SendAddonMessage(addonPrefix, "query", "PARTY")
end

local UnitFrames = {}

local function createPlayerFrame(player, role, keystoneMapID, keystoneLevel, parentFrame, xCoordinate, score, overall,
                                 equipped, version)
    local function CreateBorder(self, red, blue, green)
        if not self.borders then
            self.borders = {}
            for i = 1, 4 do
                self.borders[i] = self:CreateLine(nil, "BACKGROUND", nil, 0)
                local l = self.borders[i]
                l:SetThickness(2)
                l:SetColorTexture(red, blue, green, 1)

                if i == 1 then
                    l:SetStartPoint("TOPLEFT")
                    l:SetEndPoint("TOPRIGHT")
                elseif i == 2 then
                    l:SetStartPoint("TOPRIGHT")
                    l:SetEndPoint("BOTTOMRIGHT")
                elseif i == 3 then
                    l:SetStartPoint("BOTTOMRIGHT")
                    l:SetEndPoint("BOTTOMLEFT")
                else
                    l:SetStartPoint("BOTTOMLEFT")
                    l:SetEndPoint("TOPLEFT")
                end
            end
        end
    end


    if UnitExists(player) then
        local fp = CreateFrame("Button", "PortaPartyPlayerPortrait", parentFrame, "SecureUnitButtonTemplate")
        fp:SetSize(24, 24)
        fp:SetPoint("TOPLEFT", xCoordinate, -20)
        fp:SetAttribute("unit", player)
        RegisterUnitWatch(fp)

        fp:SetAttribute("toggleForVehicle", true)
        fp:RegisterForClicks("AnyUp")
        fp:SetAttribute("*type1", "target")
        fp:SetAttribute("*type2", "togglemenu")
        fp:SetAttribute("*type3", "assist")
        fp.Texture = fp:CreateTexture("$parent_Texture", "BACKGROUND")
        fp.Texture:SetAllPoints()
        SetPortraitTexture(fp.Texture, "player")
        fp.Border = fp:CreateTexture("$parent_Border", "BORDER")
        fp.Border:SetPoint("TOPLEFT", -6, 4)
        fp.Border:SetPoint("BOTTOMRIGHT", 6, -10)
        fp.Border:SetTexture("Interface/AddOns/PortaParty/PortaParty-player-ring")
        --fp.Border:SetTexture("Interface/PLAYERFRAME/UI-PlayerFrame-Deathknight-Ring")
        local className, normalizedClassName = UnitClass(player)
        local classColor = C_ClassColor.GetClassColor(normalizedClassName)
        local classR, classG, classB = classColor:GetRGB()
        fp.Border:SetVertexColor(classR, classG, classB, 1)
        if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
            local roleIcon = CreateFrame("Frame", nil, fp)
            local roleTexture = roleIcon:CreateTexture(nil, "BACKGROUND")
            roleIcon:SetSize(16, 16)
            --roleTexture:SetAllPoints(roleIcon)
            roleIcon:SetPoint("CENTER", 10, 10)
            roleTexture:SetPoint("CENTER", roleIcon, 0, 0)

            local size = roleIcon:GetHeight()
            roleTexture:SetTexture("Interface/LFGFrame/UI-LFG-ICON-PORTRAITROLES")
            --roleTexture:SetTexCoord(0,1,0,1)
            roleTexture:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
            roleTexture:Show()
            roleIcon:Show()
            roleTexture:SetSize(size, size);
        end

        if UnitIsGroupLeader(player) then
            local leaderIcon = CreateFrame("Frame", nil, fp)
            local leaderTexture = leaderIcon:CreateTexture(nil, "BACKGROUND")
            leaderIcon:SetSize(16, 16)
            --roleTexture:SetAllPoints(roleIcon)
            leaderIcon:SetPoint("CENTER", -12, 12)
            leaderTexture:SetPoint("CENTER", leaderIcon, 0, 0)

            local size = leaderIcon:GetHeight()
            leaderTexture:SetTexture("Interface/GROUPFRAME/UI-Group-LeaderIcon")
            --roleTexture:SetTexCoord(0,1,0,1)
            leaderTexture:Show()
            leaderIcon:Show()
            leaderTexture:SetSize(size, size);
        end

        --CreateBorder(fp,ns.classColors[UnitClass(player)].red,ns.classColors[UnitClass(player)].blue,ns.classColors[UnitClass(player)].green)

        local playerKey = CreateFrame("Frame", nil, fp)
        local texture = playerKey:CreateTexture(nil, "BACKGROUND")
        playerKey:SetSize(5, 5)
        playerKey:SetPoint("CENTER", 0, -18)
        playerKey.Text = playerKey:CreateFontString("Bazooka")
        playerKey.Text:SetPoint("CENTER")
        playerKey.Text:SetFontObject("GameFontHighlight")

        playerKey.Text:SetText(keystoneLevel)

        SetPortraitTexture(fp.Texture, player)
        local function ShowTooltip(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR");

            GameTooltip:SetText(GetUnitName(player, true), 1.0, 1.0, 1.0);
            local guildName = GetGuildInfo(player)
            if player ~= nil then
                GameTooltip:AddLine(guildName, .8, .8, .8)
            end

            GameTooltip:AddLine(className, classR, classG, classB)
            if tonumber(score) ~= nil then
			   local scoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(tonumber(score))
			   if scoreColor ~= nil then
			       local scoreR, scoreG, scoreB = scoreColor:GetRGB()
                   GameTooltip:AddDoubleLine("Mythic+ Score", score, 1, 1, 1, scoreR, scoreG, scoreB)
			   else
				   GameTooltip:AddDoubleLine("Mythic+ Score", score, 1, 1, 1, 1,1,1)
			   end
            end
            
            if tonumber(overall) > 0 and tonumber(equipped) > 0 then
                if overall ~= equipped then
                    GameTooltip:AddLine("Item Level: " ..
                        string.format("%.2f", overall) .. " (" .. string.format("%.2f", equipped) .. " equipped)")
                else
                    GameTooltip:AddLine("Item Level: " .. string.format("%.2f", overall))
                end
            end
            if tonumber(version) == 0 then
                GameTooltip:AddLine("Data retrieved from LibOpenRaid")
            end

            GameTooltip:Show();
        end

        -- Hide the buttons tooltip
        local function HideTooltip(self)
            GameTooltip:Hide();
        end


        fp:SetNormalTexture("");
        fp:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", add);
        fp:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress");

        fp:SetScript("OnEnter", ShowTooltip);
        fp:SetScript("OnLeave", HideTooltip);




        return fp
    end
end



local function createDungeonFrame(keystoneMapID, yCoordinate, parentFrame, frameNumber, frameName)
    local keystoneMap = ns.lookups[keystoneMapID].dungeonName
    local keystoneZoneID = ns.lookups[keystoneMapID].zoneID
    local keystoneZoneName = ns.lookups[keystoneMapID].zone
    local dungeonName = CreateFrame("Frame", frameName, parentFrame)
    local texture = dungeonName:CreateTexture(nil, "BACKGROUND")
    dungeonName:SetSize(5, 5)
    dungeonName:SetPoint("TOPLEFT", 20, -40 - yCoordinate)
    dungeonName.Text = dungeonName:CreateFontString("Bazooka")
    dungeonName.Text:SetPoint("TOPLEFT")
    dungeonName.Text:SetFontObject("GameFontHighlight")


    dungeonName.Text:SetText(keystoneMap)


    --local zoneName = CreateFrame("Button", nil, dungeonName, "UIPanelButtonTemplate")
    local zoneName = CreateFrame("Button", nil, dungeonName)
    local zoneTexture = zoneName:CreateTexture(nil, "BACKGROUND")
    zoneName:SetSize(5, 5)
    zoneName:SetPoint("RIGHT", dungeonName.Text, 10, 0)
    zoneName.Text = zoneName:CreateFontString("Bazooka")
    zoneName.Text:SetPoint("LEFT")
    zoneName.Text:SetFontObject("GameFontDisableSmall")
    --zoneName.Text:SetSize(250,25)
    zoneName:SetSize(zoneName.Text:GetSize())
    local x, y = zoneName.Text:GetSize()

    --zoneName:SetHyperlinksEnabled(true)


    zoneName.Text:SetText(keystoneZoneName)

    --zoneName:RegisterForClicks("AnyDown")

    local zoneMap = CreateFrame("Button", nil, zoneName)
    zoneMap:SetNormalTexture("")
    zoneMap:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square");
    zoneMap:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress");
    -- local w,h = zoneName.Text:GetSize()
    -- zoneMap:SetSize(w+10,h+10)
    zoneMap:SetSize(zoneName.Text:GetSize())
    zoneMap:SetPoint("LEFT")





    zoneMap:SetScript("OnClick", function()
        if not WorldMapFrame:IsVisible() then
            ToggleWorldMap()
        end
        WorldMapFrame:SetMapID(keystoneZoneID)
    end
    )



    local btn = CreateFrame("Button", "PortalButton", dungeonName, "SecureActionButtonTemplate")
    btn:SetSize(40, 40)
    btn:SetPoint("TOPRIGHT", 300, -16)

    -- btn:RegisterForClicks("AnyUp")
    local spellID = ns.lookups[keystoneMapID].spellID
    -- btn:SetNormalTexture("Achievement/Dungeon/Ataldazar")
    btn:SetNormalTexture(GetSpellTexture(spellID))
    --btn:SetNormalTexture("Interface/Buttons/Button-Backpack-Up")
    btn:RegisterForClicks("AnyDown", "AnyUp")
    
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellID)

    local known = IsSpellKnown(spellID, false)
    local usable = IsUsableSpell(spellID)

    -- Show a tooltip for the button
    local function ShowTooltip(self)
        --local Available                                        = (GetSpellInfo(spellID) ~= nil);
        local name, rank, icon, castTime                       = GetSpellInfo(spellID);

        local TimeNow                                          = GetTime();
        local CooldownStart, CooldownDuration, CooldownEnabled = GetSpellCooldown(spellID);
        local CooldownCounter                                  = 0;

        local spell                                            = Spell:CreateFromSpellID(spellID)
        local desc                                             = spell:GetSpellDescription()

        if (CooldownEnabled) then CooldownCounter = CooldownDuration - (TimeNow - CooldownStart); end
        CooldownCounter = math.floor(CooldownCounter);
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
        GameTooltip:SetText(name, 1.0, 1.0, 1.0);

        GameTooltip:AddDoubleLine(string.format("%.1f", castTime / 1000) .. " sec cast", "8 hour cooldown", 1, 1, 1, 1.0,
            1.0, 1.0)
        GameTooltip:AddLine(desc, 1, 1, 0, true)

        if (not known or not usable) then
            GameTooltip:AddLine("You have not yet unlocked this portal.", 1.0, 1.0, 1.0);
        end
        -- elseif ( CooldownDuration == 0 ) then
        --     GameTooltip:AddLine(_L["AVAILABLE"], 1.0,1.0,1.0);
        -- elseif ( CooldownEnabled and CooldownDuration ~= 0) then
        --     GameTooltip:AddLine(_L["ON_COOLDOWN"], 1.0,1.0,1.0);
        -- end
        if partyList ~= nil then
            local playersMissingPortal = ""
            for i = 1, #partyList do
                if players[partyList[i]] ~= nil then
                    if players[partyList[i]].spells ~= nil then
                        for j = 1, #players[partyList[i]].spells do
                            if tonumber(players[partyList[i]].spells[j]) == spellID then
                                if playersMissingPortal ~= "" then
                                    playersMissingPortal = playersMissingPortal .. ", " .. partyList[i]
                                else
                                    playersMissingPortal = partyList[i]
                                end
                            end
                        end
                    end
                end
            end
            if playersMissingPortal ~= "" then
                GameTooltip:AddLine("Summon " .. playersMissingPortal,0.7,0.7,0.7)
            end
        end


        GameTooltip:Show();
        return dungeonName
    end

    -- Hide the buttons tooltip
    local function HideTooltip(self)
        GameTooltip:Hide();
    end

    -- Update the cooldown counter
    local function UpdateCooldown(self)
        local TimeNow = GetTime();
        local CooldownStart, CooldownDuration, CooldownEnabled = GetSpellCooldown(spellID);
        if (not CooldownEnabled) then return; end
        if (CooldownDuration == 0) then return; end
        local DiffTime = TimeNow - CooldownStart;
        local CooldownCounter = CooldownDuration - DiffTime;
        CooldownCounter = math.floor(CooldownCounter);
        if (CooldownCounter > 0) then
            self.Text:SetText(secToStr(CooldownCounter));
        else
            self.Text:SetText("");
        end
    end

    if (not known or not usable) then
        -- fade button
        btn:SetAlpha(0.4)
    end


    btn:SetScript("OnEnter", ShowTooltip);
    btn:SetScript("OnLeave", HideTooltip);
    -- Create the Cooldown frame to display the Cooldown Counter
    btn.Cooldown = CreateFrame("Frame", "Cooldown", btn);
    btn.Cooldown:SetAllPoints(btn);
    btn.Cooldown.Text = btn.Cooldown:CreateFontString("Cooldown_Text", 'ARTWORK', "GameFontNormal");
    local Path, Size, Flags = btn.Cooldown.Text:GetFont()
    btn.Cooldown.Text:SetAllPoints(btn.Cooldown);
    btn.Cooldown.Text:SetJustifyH("CENTER");
    btn.Cooldown.Text:SetJustifyV("MIDDLE");
    btn.Cooldown.Text:SetTextColor(1, 1, 0, 1);
    btn.Cooldown.Text:SetText("");
    btn.Cooldown:SetScript("OnUpdate", UpdateCooldown);










    local playerXCoordinate = 5
    local playerXSpacing = 40
    local me = getPlayerInfo()
    if myKeystoneID == keystoneMapID then
        createPlayerFrame("player", UnitGroupRolesAssigned("player"), keystoneMapID, me.level, dungeonName,
            playerXCoordinate, C_ChallengeMode.GetOverallDungeonScore(), overall, equipped, version)
        playerXCoordinate = playerXCoordinate + playerXSpacing
    end



    if partyList ~= nil then
        for i = 1, #partyList do
            if players[partyList[i]] ~= nil then
                if players[partyList[i]].mapID ~= nil then
                    if players[partyList[i]].mapID == keystoneMapID then
                        local role = UnitGroupRolesAssigned("party" .. i)
                        createPlayerFrame(partyList[i], role, keystoneMapID, players[partyList[i]].level, dungeonName,
                            playerXCoordinate, players[partyList[i]].rating, players[partyList[i]].overall,
                            players[partyList[i]].equipped, players[partyList[i]].version)
                        playerXCoordinate = playerXCoordinate + playerXSpacing
                    end
                end
            end
        end
    end
    return dungeonName
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", OnEvent)

PortaParty_UIFrame:SetSize(350, 400)
PortaParty_UIFrame:SetPoint("CENTER", UIParent, "CENTER")
PortaParty_UIFrame.title = PortaParty_UIFrame:CreateFontString(nil, "OVERLAY")
PortaParty_UIFrame.title:SetFontObject("GameFontHighlight")
PortaParty_UIFrame.title:SetPoint("LEFT", PortaParty_UIFrame.TitleBg, "LEFT", 5, 0)
PortaParty_UIFrame.title:SetText("PortaParty")
players["player"] = getPlayerInfo()


local function UpdateFrame()
    if mapInfo == nil then
        mapInfo = C_MythicPlus.RequestMapInfo()
    end
    partyList = GetHomePartyInfo(partyList)
    overall, equipped = GetAverageItemLevel()



    local dungeons = {}
    dungeons[0] = {}
    dungeons[0].count = 0
    dungeons[0].order = 99

    seasonID = C_MythicPlus.GetCurrentSeason()
    -- if seasonID < 1 then
    --     seasonID = C_MythicPlus.GetCurrentSeason()
    --     -- if seasonID < 1 then
    --     --     print("No Mythic+ season found!")
    --     --     return
    --     -- end
    -- end
    -- add current season dungeons to table with a count of 0

    for i = 1, #ns.seasons[seasonID] do
        dungeons[ns.seasons[seasonID][i]] = {}
        dungeons[ns.seasons[seasonID][i]].count = 0
        dungeons[ns.seasons[seasonID][i]].order = 0
    end

    if myKeystoneID ~= nil then
        if myKeystoneID ~= 0 then
            dungeons[myKeystoneID].count = 1
        end
    end


    local unit = "player"
    local name = ""
    local realm = GetRealmName()
    local party = {}

    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        --print("Is In Group")
        party = GetHomePartyInfo()
        for i = 1, #party do
            unit = "party" .. i
            name = UnitName(unit)
            if players[name] ~= nil then
                if players[name].mapID ~= nil then
                    dungeons[players[name].mapID].count = dungeons[players[name].mapID].count + 1
                end
            end
        end
    end

    -- DUPLICATED FROM ABOVE
    -- if partyList ~= nil then
    --     for i = 1, #partyList do
    --         --print(players[partyList[i]].mapID)
    --         for j = 1, #ns.seasons[seasonID] do
    --             if players[partyList[i]] ~= nil then
    --                 if players[partyList[i]].mapID ~= nil then
    --                     print(players[partyList[i]].mapID)
    --                     if players[partyList[i]].mapID == ns.seasons[seasonID][j] then
    --                         dungeons[ns.seasons[seasonID][j]].count = dungeons[ns.seasons[seasonID][j]].count + 1
    --                         print (tostring(ns.seasons[seasonID][j]) .. ": " .. tostring(dungeons[ns.seasons[seasonID][j]].count))
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end

    for i = 1, #ns.seasons[seasonID] do
        if ns.seasons[seasonID][i] == C_MythicPlus.GetOwnedKeystoneMapID() then
            dungeons[ns.seasons[seasonID][i]].order = 1
            dungeons[ns.seasons[seasonID][i]].count = dungeons[ns.seasons[seasonID][i]].count + 1
        end
    end

    local dungeonCounter = 2
    for i = 1, #ns.seasons[seasonID] do
        if dungeons[ns.seasons[seasonID][i]].count == 4 and dungeons[ns.seasons[seasonID][i]].order == 0 then
            dungeons[ns.seasons[seasonID][i]].order = dungeonCounter
            dungeonCounter = dungeonCounter + 1
        end
        if dungeons[ns.seasons[seasonID][i]].count == 3 and dungeons[ns.seasons[seasonID][i]].order == 0 then
            dungeons[ns.seasons[seasonID][i]].order = dungeonCounter
            dungeonCounter = dungeonCounter + 1
        end
        if dungeons[ns.seasons[seasonID][i]].count == 2 and dungeons[ns.seasons[seasonID][i]].order == 0 then
            dungeons[ns.seasons[seasonID][i]].order = dungeonCounter
            dungeonCounter = dungeonCounter + 1
        end
        if dungeons[ns.seasons[seasonID][i]].count == 1 and dungeons[ns.seasons[seasonID][i]].order == 0 then
            dungeons[ns.seasons[seasonID][i]].order = dungeonCounter
            dungeonCounter = dungeonCounter + 1
        end
    end
    local dungeonYCoordinate = 0

    for i = 1, #dungeonFrames do
        dungeonFrames[i]:Hide()
    end
    for currentDungeonOrder = 1, 5 do
        for i = 1, #ns.seasons[seasonID] do
            if dungeons[ns.seasons[seasonID][i]].count > 0 and dungeons[ns.seasons[seasonID][i]].order == currentDungeonOrder then
                local newFrame = createDungeonFrame(ns.seasons[seasonID][i], dungeonYCoordinate, PortaParty_UIFrame,
                    currentDungeonOrder)
                PortaParty_UIFrame:SetSize(350, dungeonYCoordinate + 150)
                table.insert(dungeonFrames, newFrame)
                newFrame:Show()
                dungeonYCoordinate = dungeonYCoordinate + 70
            end
        end
    end
    -- TODO: Code to have PP automatically appear when ChallengeFrame is loaded.
--[[     PortaParty_UIFrame:SetParent(ChallengesFrame)
    PortaParty_UIFrame:SetAllPoints(ChallengesFrame)
    PortaParty_UIFrame:SetPoint("RIGHT",ChallengesFrame,700,0)
    PortaParty_UIFrame:Show() ]]
end


local versionNumber = CreateFrame("Frame", nil, PortaParty_UIFrame)
local vnTexture = versionNumber:CreateTexture(nil, "BACKGROUND")
versionNumber:SetSize(5, 5)
versionNumber:SetPoint("BOTTOMLEFT", 10, 12)
versionNumber.Text = versionNumber:CreateFontString("Bazooka")
versionNumber.Text:SetPoint("TOPLEFT")
versionNumber.Text:SetFontObject("GameFontDarkGraySmall")
versionNumber.Text:SetText("v" .. tostring(version))


local refreshButton = CreateFrame("Button", "MyButton", PortaParty_UIFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(60, 15)
refreshButton:SetText("Refresh")
refreshButton:SetPoint("BOTTOMRIGHT", -8, 8)
refreshButton:SetScript("OnClick", function()
    C_ChatInfo.SendAddonMessage(addonPrefix, "query", "PARTY")
    PortaParty_UIFrame:Hide()
    if InCombatLockdown() == false then
        UpdateFrame()
        PortaParty_UIFrame:Show()
    end
end)

-- Main UI Frame
local frame = CreateFrame("FRAME", "PortaPartyFrame")
local texture = frame:CreateTexture(nil, "BACKGROUND")
local fontString = frame:CreateFontString(nil, "BACKGROUND")
frame:RegisterEvent("PLAYER_ENTERING_WORLD");

local function PortaParty(msg)
    if msg == nil  or msg == "" then
        mapInfo = C_MythicPlus.RequestMapInfo()
        if InCombatLockdown() == false then
            UpdateFrame()
            PortaParty_UIFrame:Show()
        end
    elseif string.lower(msg) == "hideminimap" then
        -- hide minimap button
        icon:Hide("PortaParty")
        --print (self.db.profile.minimap.hide)
    elseif string.lower(msg) == "showminimap" then
        -- show minimap button
        icon:Show("PortaParty")
    end
end

SLASH_PORTAPARTY1 = "/pp"
SLASH_PORTAPARTY2 = "/portaparty"
SlashCmdList.PORTAPARTY = PortaParty
print("|cff00ffffPortaParty|r " .. version .. " by |cffC41E3AMystikos|r loaded. |cff00ffff/pp|r to use.")


tinsert(UISpecialFrames, PortaParty_UIFrame:GetName())

local function refreshKeys()
    players = {}
    players["player"] = getPlayerInfo()
    sendRefreshRequest()
end

local addon = LibStub("AceAddon-3.0"):NewAddon("PortaParty")
PortaPartyLDB = LibStub("LibDataBroker-1.1"):NewDataObject("PortaParty", {
    type = "data source",
    text = "PortaParty",
    icon = "Interface\\AddOns\\PortaParty\\icons\\logo",
    OnClick = function()
        if PortaParty_UIFrame:IsShown() then
            PortaParty_UIFrame:Hide()
        else
            C_ChatInfo.SendAddonMessage(addonPrefix, "query", "PARTY")
            if InCombatLockdown() == false then
                UpdateFrame()

                PortaParty_UIFrame:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end

        tooltip:AddLine("|cff00ffffPortaParty|r " .. version)
        tooltip:AddLine("Click to toggle or type |cff00ffff/pp|r.", 1, 1, 1)
    end,
})



function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("PortaPartyDB", {
        profile = {
            minimap = {
                hide = false,
            },
        },
    })
    icon:Register("PortaParty", PortaPartyLDB, self.db.profile.minimap)
end

function PortaParty_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
    if PortaParty_UIFrame:IsShown() then
        PortaParty_UIFrame:Hide()
    else
        C_ChatInfo.SendAddonMessage(addonPrefix, "query", "PARTY")
        if InCombatLockdown() == false then
            UpdateFrame()
            PortaParty_UIFrame:Show()
        end
    end
end

function PortaParty_OnAddonCompartmentEnter(addonName, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_CURSOR");
    GameTooltip:AddLine("|cff00ffffPortaParty|r " .. version)
    GameTooltip:AddLine("Click to toggle or type |cff00ffff/pp|r.", 1, 1, 1)
end

function PortaParty_OnAddonCompartmentLeave(addonName, menuButtonFrame)
    GameTooltip:Hide();
end

AddonCompartmentFrame:RegisterAddon({
    text = "|cff00ffffPortaParty|r " .. version,
    icon = "Interface\\AddOns\\PortaParty\\icons\\logo",
    notCheckable = true,
    func = function()
        if PortaParty_UIFrame:IsShown() then
            PortaParty_UIFrame:Hide()
        else
            C_ChatInfo.SendAddonMessage(addonPrefix, "query", "PARTY")
            if InCombatLockdown() == false then
                UpdateFrame()

                PortaParty_UIFrame:Show()
            end
        end
    end,
})



-- JESUS IS LORD
-- FIN
