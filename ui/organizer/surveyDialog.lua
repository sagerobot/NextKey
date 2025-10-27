-- MARK: Module Definition
-- Progressive Poll Window for M+ Group Organizer
-- Three-phase UI: Participation → Character Selection → Spec Selection

local _, NextKey222 = ...

local SurveyDialog = {}
NextKey222.SurveyDialog = SurveyDialog
NextKey222.RegisterModule("SurveyDialog", SurveyDialog)

local Debug = NextKey222.Debug
local UIConfig = NextKey222.UIConfig

-- MARK: Module State
SurveyDialog.activeDialog = nil
SurveyDialog.currentPhase = nil
SurveyDialog.pollData = nil
SurveyDialog.responseData = {
    phase1 = nil,  -- { participation = "yes" | "yes_alt" | "no" }
    phase2 = nil,  -- { selectedCharacterID, characterData }
    phase3 = nil   -- { specPreferences = { [specID] = "none" | "play" | "fill" } }
}

-- MARK: Initialization
function SurveyDialog:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Initializing Progressive Survey Dialog module")
        return true
    end, "SurveyDialog:Initialize")
end

-- MARK: Main Entry Point
function SurveyDialog:Show(pollData)
    return NextKey222.SafeRun(function()
        self.pollData = pollData
        self.responseData = { phase1 = nil, phase2 = nil, phase3 = nil }
        
        -- Start with Phase 1
        self:ShowPhase1()
    end, "SurveyDialog:Show")
end

-- MARK: Phase 1 - Participation Question
function SurveyDialog:ShowPhase1()
    return NextKey222.SafeRun(function()
        -- Close existing dialog if open
        self:CloseDialog()
        
        local cfg = UIConfig.POLL_WINDOW
        
        -- Create main frame
        local frame = CreateFrame("Frame", "NextKeySurveyDialog", UIParent, "BackdropTemplate")
        frame:SetSize(cfg.PHASE1_WIDTH, cfg.PHASE1_HEIGHT)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetFrameLevel(100)
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        
        -- Backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        -- Drag functionality
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -15)
        title:SetText("M+ Group Organizer - Poll")
        title:SetTextColor(1, 0.82, 0)
        
        -- Header text
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOP", frame, "TOP", 0, -45)
        header:SetWidth(cfg.PHASE1_WIDTH - 40)
        header:SetJustifyH("CENTER")
        header:SetText(string.format("%s is organizing M+ groups.\nDo you want to play M+ tonight?", 
            self.pollData.organizerName or "The raid leader"))
        header:SetTextColor(1, 1, 1)
        
        -- Create three participation cards
        local yOffset = -100
        
        -- Card 1: Yes
        local yesCard = self:CreateParticipationCard(frame, "yes", yOffset)
        
        -- Card 2: Yes on Alt
        local altCard = self:CreateParticipationCard(frame, "yes_alt", yOffset - cfg.PARTICIPATION_CARD_HEIGHT_YES - cfg.PARTICIPATION_CARD_SPACING)
        
        -- Card 3: No
        local noCard = self:CreateParticipationCard(frame, "no", yOffset - (cfg.PARTICIPATION_CARD_HEIGHT_YES + cfg.PARTICIPATION_CARD_SPACING) * 2)
        
        frame:Show()
        self.activeDialog = frame
        self.currentPhase = 1
        
        Debug:Dev("organizer", "Showed Phase 1: Participation cards")
    end, "SurveyDialog:ShowPhase1")
end

-- MARK: Create Participation Card
function SurveyDialog:CreateParticipationCard(parent, cardType, yOffset)
    local cfg = UIConfig.POLL_WINDOW
    
    -- Determine card height based on type
    local cardHeight = (cardType == "no") and cfg.PARTICIPATION_CARD_HEIGHT_NO or cfg.PARTICIPATION_CARD_HEIGHT_YES
    
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(cfg.PHASE1_WIDTH - 40, cardHeight)
    card:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Backdrop
    card:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    -- Card configuration based on type
    local config = {
        yes = {
            icon = "Interface\\Buttons\\UI-CheckBox-Check",
            iconColor = {0.2, 0.9, 0.2},
            borderColor = cfg.COLOR_GREEN_BORDER,
            primaryText = "Yes",
            secondaryText = "Play on current character"
        },
        yes_alt = {
            icon = "Interface\\Icons\\Ability_Warrior_StrengthOfArms",
            iconColor = {0.2, 0.9, 0.2},
            borderColor = cfg.COLOR_GREEN_BORDER,
            primaryText = "Yes on an Alt",
            secondaryText = "Choose a different character"
        },
        no = {
            icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
            iconColor = {0.9, 0.2, 0.2},
            borderColor = cfg.COLOR_RED_BORDER,
            primaryText = "No",
            secondaryText = "Not playing tonight"
        }
    }
    
    local cardConfig = config[cardType]
    
    -- Set initial colors
    card:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    card:SetBackdropBorderColor(cardConfig.borderColor[1], cardConfig.borderColor[2], cardConfig.borderColor[3], cardConfig.borderColor[4])
    
    -- Icon
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(cfg.ICON_SIZE, cfg.ICON_SIZE)
    icon:SetPoint("LEFT", card, "LEFT", 12, 0)
    icon:SetTexture(cardConfig.icon)
    icon:SetVertexColor(cardConfig.iconColor[1], cardConfig.iconColor[2], cardConfig.iconColor[3])
    
    -- Primary text
    local primaryText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    primaryText:SetPoint("LEFT", icon, "RIGHT", 12, 12)
    primaryText:SetText(cardConfig.primaryText)
    primaryText:SetTextColor(1, 1, 1)
    
    -- Secondary text
    local secondaryText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    secondaryText:SetPoint("LEFT", icon, "RIGHT", 12, -8)
    secondaryText:SetText(cardConfig.secondaryText)
    secondaryText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Hover effects
    card:SetScript("OnEnter", function()
        card:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
        card:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)
    
    card:SetScript("OnLeave", function()
        card:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        card:SetBackdropBorderColor(cardConfig.borderColor[1], cardConfig.borderColor[2], cardConfig.borderColor[3], cardConfig.borderColor[4])
    end)
    
    -- Click handler
    card:SetScript("OnClick", function()
        self:OnPhase1CardClick(cardType)
    end)
    
    return card
end

-- MARK: Phase 1 Click Handler
function SurveyDialog:OnPhase1CardClick(participation)
    return NextKey222.SafeRun(function()
        self.responseData.phase1 = { participation = participation, timestamp = GetTime() }
        
        if participation == "no" then
            -- Opt-out flow: Submit immediately and close
            self:SubmitFinalResponse(false)
            self:CloseDialog()
        elseif participation == "yes" then
            -- Go directly to Phase 3 (spec selection) for current character
            local currentChar = UnitName("player") .. "-" .. GetRealmName()
            self.responseData.phase2 = { selectedCharacterID = currentChar }
            self:ShowPhase3(currentChar)
        else -- yes_alt
            -- Go to Phase 2 (character selection)
            self:ShowPhase2()
        end
        
        Debug:Dev("organizer", "Phase 1 response:", participation)
    end, "SurveyDialog:OnPhase1CardClick")
end

-- MARK: Phase 2 - Alt Character Selection
function SurveyDialog:ShowPhase2()
    return NextKey222.SafeRun(function()
        -- Close existing dialog
        self:CloseDialog()
        
        local cfg = UIConfig.POLL_WINDOW
        
        -- Get character list (includes current character at end with "Current" marker)
        local charList = NextKey222.CharacterStorage:GetMaxLevelCharactersSortedByIO(false)
        
        if not charList or #charList == 0 then
            Debug:User("No characters found in storage")
            return
        end
        
        -- Calculate window height based on character count
        local windowHeight = cfg.PHASE2_BASE_HEIGHT + (#charList * (cfg.PHASE2_CARD_HEIGHT + 8))
        windowHeight = math.min(windowHeight, cfg.PHASE2_MAX_HEIGHT)
        
        -- Create main frame
        local frame = CreateFrame("Frame", "NextKeySurveyDialog", UIParent, "BackdropTemplate")
        frame:SetSize(cfg.PHASE2_WIDTH, windowHeight)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetFrameLevel(100)
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        
        -- Backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        -- Drag functionality
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        
        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -15)
        title:SetText("M+ Group Organizer - Choose Character")
        title:SetTextColor(1, 0.82, 0)
        
        -- Header text
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOP", frame, "TOP", 0, -45)
        header:SetText("Select which character you want to play:")
        header:SetTextColor(1, 1, 1)
        
        -- Scroll frame for characters
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -75)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 50)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(cfg.PHASE2_WIDTH - 50, #charList * (cfg.PHASE2_CARD_HEIGHT + 8))
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Create character cards
        local yOffset = 0
        for i, charEntry in ipairs(charList) do
            local card = self:CreateCharacterCard(scrollChild, charEntry, yOffset)
            yOffset = yOffset - (cfg.PHASE2_CARD_HEIGHT + 8)
        end
        
        -- Back button
        local backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        backButton:SetSize(80, 24)
        backButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
        backButton:SetText("← Back")
        backButton:SetScript("OnClick", function()
            self:ShowPhase1()
        end)
        
        frame:Show()
        self.activeDialog = frame
        self.currentPhase = 2
        
        Debug:Dev("organizer", "Showed Phase 2: Character selection -", #charList, "characters")
    end, "SurveyDialog:ShowPhase2")
end

-- MARK: Create Character Card
function SurveyDialog:CreateCharacterCard(parent, charEntry, yOffset)
    local cfg = UIConfig.POLL_WINDOW
    local charData = charEntry.data
    
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(cfg.PHASE2_WIDTH - 60, cfg.PHASE2_CARD_HEIGHT)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    
    -- Backdrop
    card:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    card:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8)
    
    -- Class icon
    local classIcon = card:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(cfg.ICON_SIZE, cfg.ICON_SIZE)
    classIcon:SetPoint("LEFT", card, "LEFT", 8, 0)
    
    -- Set class icon texture
    local classFile = charData.class or "WARRIOR"
    local coords = CLASS_ICON_TCOORDS[classFile]
    if coords then
        classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end
    
    -- Get class color
    local classColor = RAID_CLASS_COLORS[classFile] or {r=1, g=1, b=1}
    
    -- Character name (line 1)
    local nameLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameLabel:SetPoint("LEFT", classIcon, "RIGHT", 10, 20)
    nameLabel:SetText(charData.name or "Unknown")
    nameLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
    
    -- Current character indicator
    if charEntry.isCurrent then
        local currentLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        currentLabel:SetPoint("LEFT", nameLabel, "RIGHT", 5, 0)
        currentLabel:SetText("(Current)")
        currentLabel:SetTextColor(0.8, 0.8, 0.8)
    end
    
    -- Class info (line 2)
    local classInfo = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classInfo:SetPoint("LEFT", classIcon, "RIGHT", 10, 4)
    local className = charData.class or "Unknown"
    local specName = charData.specName or "Unknown Spec"
    classInfo:SetText(string.format("%s - %s", className, specName))
    classInfo:SetTextColor(1, 1, 1)
    
    -- Scores (line 3)
    local scoresLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scoresLabel:SetPoint("LEFT", classIcon, "RIGHT", 10, -12)
    scoresLabel:SetText(string.format("IO: %d | iLvl: %d",
        charEntry.io or 0,
        charEntry.itemLevel or 0))
    scoresLabel:SetTextColor(0.8, 0.8, 1)
    
    -- Keystone (line 4)
    local keystoneLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keystoneLabel:SetPoint("LEFT", classIcon, "RIGHT", 10, -28)
    
    if charData.currentKeystone and charData.currentKeystone.dungeonID then
        local dungeonName = NextKey222.DungeonNameService and
            NextKey222.DungeonNameService:GetAlias(charData.currentKeystone.dungeonID) or "???"
        keystoneLabel:SetText(string.format("Key: %s +%d",
            dungeonName,
            charData.currentKeystone.level or 0))
    else
        keystoneLabel:SetText("Key: None")
    end
    keystoneLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Hover effects
    card:SetScript("OnEnter", function()
        card:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
        card:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end)
    
    card:SetScript("OnLeave", function()
        card:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        card:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8)
    end)
    
    -- Click handler
    card:SetScript("OnClick", function()
        self:OnPhase2CardClick(charEntry)
    end)
    
    return card
end

-- MARK: Phase 2 Click Handler
function SurveyDialog:OnPhase2CardClick(charEntry)
    return NextKey222.SafeRun(function()
        self.responseData.phase2 = {
            selectedCharacterID = charEntry.id,
            characterData = {
                name = charEntry.data.name,
                class = charEntry.data.class,
                io = charEntry.io,
                itemLevel = charEntry.itemLevel,
                keystone = charEntry.data.currentKeystone
            }
        }
        
        -- Proceed to Phase 3 (spec selection)
        self:ShowPhase3(charEntry.id)
        
        Debug:Dev("organizer", "Phase 2 response: Selected", charEntry.id)
    end, "SurveyDialog:OnPhase2CardClick")
end

-- MARK: Phase 3 - Spec Selection (TODO: Next implementation)
function SurveyDialog:ShowPhase3(characterID)
    return NextKey222.SafeRun(function()
        Debug:User("Phase 3 (Spec Selection) - Not yet implemented. Character:", characterID)
        -- TODO: Implement spec selection cards
    end, "SurveyDialog:ShowPhase3")
end

-- MARK: Submit Final Response
function SurveyDialog:SubmitFinalResponse(optedIn)
    return NextKey222.SafeRun(function()
        local response = {
            pollID = self.pollData.pollID,
            optedIn = optedIn,
            timestamp = GetTime()
        }
        
        if optedIn and self.responseData.phase2 and self.responseData.phase3 then
            response.selectedCharacter = self.responseData.phase2.selectedCharacterID
            response.characterData = self.responseData.phase2.characterData
            response.specPreferences = self.responseData.phase3.specPreferences
        end
        
        -- Check if we're the organizer
        local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
        if currentPlayer == self.pollData.organizerName then
            -- Process our own response directly
            if NextKey222.ParticipantSurvey then
                NextKey222.ParticipantSurvey:ProcessResponse(currentPlayer, response)
            end
            
            -- Update poll progress
            if NextKey222.RosterBoard and NextKey222.RosterBoard.activePoll then
                table.insert(NextKey222.RosterBoard.activePoll.responses, {
                    sender = currentPlayer,
                    response = response,
                    timestamp = GetTime()
                })
                if NextKey222.RosterBoard.UpdatePollProgress then
                    NextKey222.RosterBoard:UpdatePollProgress()
                end
            end
        else
            -- Send response to organizer
            if NextKey222.ParticipantSurvey then
                NextKey222.ParticipantSurvey:SendPollResponse(response, self.pollData.organizerName)
            end
        end
        
        Debug:Dev("organizer", "Submitted final response - opted in:", optedIn)
    end, "SurveyDialog:SubmitFinalResponse")
end

-- MARK: Utility Functions
function SurveyDialog:CloseDialog()
    if self.activeDialog then
        self.activeDialog:Hide()
        self.activeDialog:SetParent(nil)
        self.activeDialog = nil
    end
    self.currentPhase = nil
end

return SurveyDialog