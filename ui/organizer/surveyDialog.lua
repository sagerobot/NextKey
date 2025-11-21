-- MARK: Module Definition
-- Progressive Poll Window for M+ Group Organizer
-- Three-phase UI: Participation -> Character Selection -> Spec Selection

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

-- MARK: Manual Entry
-- Right-Click on Cards
function SurveyDialog:ShowManualEntry(pollData, playerData)
    return NextKey222.SafeRun(function()
        self.pollData = pollData
        self.responseData = { phase1 = nil, phase2 = nil, phase3 = nil }
        self.isManualEntry = true
        self.targetPlayerData = playerData
        
        -- For manual entry, skip directly to Phase 3 (spec selection)
        -- Use the target player's character ID
        Debug:Dev("organizer", "Manual entry for player:", playerData.name)
        
        -- Set up response data to skip phases 1 and 2
        self.responseData.phase1 = { participation = "yes", timestamp = GetTime() }
        self.responseData.phase2 = {
            selectedCharacterID = playerData.id,
            characterData = playerData
        }
        
        -- Show Phase 3 with the player's character
        self:ShowPhase3(playerData.id)
    end, "SurveyDialog:ShowManualEntry")
end

-- MARK: Participation UI
-- First survey step
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
        frame:SetFrameLevel(9999)  -- Very high level to ensure it's on top
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:Raise()  -- Explicitly raise to front
        
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

-- MARK: Participation Card
function SurveyDialog:CreateParticipationCard(parent, cardType, yOffset)
    local cfg = UIConfig.POLL_WINDOW
    
    -- Determine card height based on type
    local cardHeight = (cardType == "no") and cfg.PARTICIPATION_CARD_HEIGHT_NO or cfg.PARTICIPATION_CARD_HEIGHT_YES
    
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(cfg.PHASE1_WIDTH - 40, cardHeight)
    card:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Backdrop (border only - no bgFile for solid colors)
    card:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    -- Create background texture with thematic colors (green for yes/yes_alt, red for no)
    local bgTexture = card:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(card)
    
    -- Set thematic color based on card type
    if cardType == "yes" or cardType == "yes_alt" then
        bgTexture:SetColorTexture(0.05, 0.25, 0.05, 0.85)  -- Dark green
        card.baseColor = {0.05, 0.25, 0.05, 0.85}
        card.hoverColor = {0.08, 0.28, 0.08, 0.85}  -- Slightly lighter
    else  -- "no"
        bgTexture:SetColorTexture(0.25, 0.05, 0.05, 0.85)  -- Dark red
        card.baseColor = {0.25, 0.05, 0.05, 0.85}
        card.hoverColor = {0.28, 0.08, 0.08, 0.85}  -- Slightly lighter
    end
    card.bgTexture = bgTexture
    
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
    
    -- Set initial border color
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
    
    -- Hover effects (use pre-calculated hover color)
    card:SetScript("OnEnter", function()
        -- Use pre-calculated hover color
        local hover = card.hoverColor
        card.bgTexture:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
        
        -- Brighten border
        local currentBorderColor = {card:GetBackdropBorderColor()}
        card:SetBackdropBorderColor(
            math.min(currentBorderColor[1] * 1.5, 1),
            math.min(currentBorderColor[2] * 1.5, 1),
            math.min(currentBorderColor[3] * 1.5, 1),
            1.0
        )
    end)
    
    card:SetScript("OnLeave", function()
        -- Restore original background
        local base = card.baseColor
        card.bgTexture:SetColorTexture(base[1], base[2], base[3], base[4])
        -- Restore original border
        card:SetBackdropBorderColor(cardConfig.borderColor[1], cardConfig.borderColor[2], cardConfig.borderColor[3], cardConfig.borderColor[4])
    end)
    
    -- Click handler
    card:SetScript("OnClick", function()
        self:OnPhase1CardClick(cardType)
    end)
    
    return card
end

-- MARK: Participation Click
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

-- MARK: Character Select UI
-- Alt selection step
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
        frame:SetFrameLevel(9999)  -- Very high level to ensure it's on top
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:Raise()  -- Explicitly raise to front
        
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
        
        -- Calculate available space for content using UIConfig constants
        local availableHeight = windowHeight - cfg.PHASE2_SCROLL_TOP_OFFSET - cfg.PHASE2_SCROLL_BOTTOM_OFFSET
        local contentHeight = #charList * (cfg.PHASE2_CARD_HEIGHT + 8)
        local needsScroll = contentHeight > availableHeight
        
        local contentParent
        
        if needsScroll then
            -- Create scroll frame when content doesn't fit (using UIConfig constants)
            local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -cfg.PHASE2_SCROLL_TOP_OFFSET)
            scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, cfg.PHASE2_SCROLL_BOTTOM_OFFSET)
            
            local scrollChild = CreateFrame("Frame", nil, scrollFrame)
            scrollChild:SetSize(cfg.PHASE2_WIDTH - 50, contentHeight)
            scrollFrame:SetScrollChild(scrollChild)
            contentParent = scrollChild
        else
            -- No scroll needed - use frame directly (using UIConfig constants)
            contentParent = CreateFrame("Frame", nil, frame)
            contentParent:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -cfg.PHASE2_SCROLL_TOP_OFFSET)
            contentParent:SetSize(cfg.PHASE2_WIDTH - 50, contentHeight)
        end
        
        -- Create character cards (pass hasScrollbar flag to adjust card width)
        local yOffset = 0
        for i, charEntry in ipairs(charList) do
            local card = self:CreateCharacterCard(contentParent, charEntry, yOffset, needsScroll)
            yOffset = yOffset - (cfg.PHASE2_CARD_HEIGHT + 8)
        end
        
        -- Back button
        local backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        backButton:SetSize(80, 24)
        backButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
        backButton:SetText("< Back")
        backButton:SetScript("OnClick", function()
            self:ShowPhase1()
        end)
        
        frame:Show()
        self.activeDialog = frame
        self.currentPhase = 2
        
        Debug:Dev("organizer", "Showed Phase 2: Character selection -", #charList, "characters")
    end, "SurveyDialog:ShowPhase2")
end

-- MARK: Character Card
function SurveyDialog:CreateCharacterCard(parent, charEntry, yOffset, hasScrollbar)
    local cfg = UIConfig.POLL_WINDOW
    local charData = charEntry.data
    
    -- Adjust card width based on whether scrollbar is visible
    -- When no scrollbar: use more horizontal space (subtract less from PHASE2_WIDTH)
    -- When scrollbar: use less horizontal space (subtract more for scrollbar)
    local cardWidth = hasScrollbar and (cfg.PHASE2_WIDTH - 60) or (cfg.PHASE2_WIDTH - 40)
    
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(cardWidth, cfg.PHASE2_CARD_HEIGHT)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    
    -- Backdrop (border only - no bgFile for solid colors)
    card:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    -- Get class color and darken it for background
    local classFile = charData.class or "WARRIOR"
    local classColor = RAID_CLASS_COLORS[classFile] or {r=1, g=1, b=1}
    
    -- Darken the class color (multiply by 0.35 for brighter base, was 0.25)
    local darkR = classColor.r * 0.35
    local darkG = classColor.g * 0.35
    local darkB = classColor.b * 0.35
    
    -- Create background texture with darkened class color
    local bgTexture = card:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(card)
    bgTexture:SetColorTexture(darkR, darkG, darkB, 0.85)
    card.bgTexture = bgTexture
    
    -- Store original colors for hover restoration
    card.originalBgColor = {darkR, darkG, darkB, 0.85}
    
    -- Set border to VERY bright class color (1.5x to make it more vivid)
    card:SetBackdropBorderColor(
        math.min(classColor.r * 1.5, 1),
        math.min(classColor.g * 1.5, 1),
        math.min(classColor.b * 1.5, 1),
        1.0
    )
    
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
    
    -- Hover effects (subtle brightening by adding small amount)
    card:SetScript("OnEnter", function()
        -- Add 0.02 to each channel to brighten class color slightly
        local orig = card.originalBgColor
        card.bgTexture:SetColorTexture(
            math.min(orig[1] + 0.02, 1),
            math.min(orig[2] + 0.02, 1),
            math.min(orig[3] + 0.02, 1),
            orig[4]
        )
        
        -- Brighten border even more on hover (1.8x for maximum vividness)
        card:SetBackdropBorderColor(
            math.min(classColor.r * 1.8, 1),
            math.min(classColor.g * 1.8, 1),
            math.min(classColor.b * 1.8, 1),
            1.0
        )
    end)
    
    card:SetScript("OnLeave", function()
        -- Restore original class-colored background
        local orig = card.originalBgColor
        card.bgTexture:SetColorTexture(orig[1], orig[2], orig[3], orig[4])
        -- Restore very bright class color border (1.5x)
        card:SetBackdropBorderColor(
            math.min(classColor.r * 1.5, 1),
            math.min(classColor.g * 1.5, 1),
            math.min(classColor.b * 1.5, 1),
            1.0
        )
    end)
    
    -- Click handler
    card:SetScript("OnClick", function()
        self:OnPhase2CardClick(charEntry)
    end)
    
    return card
end

-- MARK: Character Click
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

-- MARK: Spec Select UI
-- Final survey step
function SurveyDialog:ShowPhase3(characterID)
    return NextKey222.SafeRun(function()
        -- Close existing dialog
        self:CloseDialog()
        
        local cfg = UIConfig.POLL_WINDOW
        
        -- Get character data and available specs based on entry mode
        local charData = nil
        local availableSpecs = {}
        
        if self.isManualEntry then
            -- Manual entry: Generate specs from player's class (no CharacterStorage lookup)
            local playerData = self.targetPlayerData
            if not playerData or not playerData.class then
                Debug:Error("Phase 3 - No class data for manual entry:", characterID)
                return
            end
            
            Debug:Dev("organizer", "Manual entry for player:", characterID, "class:", playerData.class)
            
            -- Get class ID from class token
            local classID = nil
            local numClasses = GetNumClasses()
            for i = 1, numClasses do
                local className, classToken = GetClassInfo(i)
                Debug:Dev("organizer", "Checking class", i, ":", classToken, "against", playerData.class)
                if classToken == playerData.class then
                    classID = i
                    Debug:Dev("organizer", "Found matching classID:", classID, "for class:", playerData.class)
                    break
                end
            end
            
            if not classID then
                Debug:Error("Phase 3 - Could not find classID for class:", playerData.class)
                return
            end
            
            -- Query ALL specializations for this class
            -- CRITICAL: Must use GetSpecializationInfoForClassID to get target player's class specs
            -- DO NOT use GetSpecializationInfo() as it returns the CURRENT PLAYER's specs, not the target player's
            
            -- Use global WoW API functions (available in all versions)
            local GetNumSpecsFunc = _G.GetNumSpecializationsForClassID
            local GetSpecInfoFunc = _G.GetSpecializationInfoForClassID
            
            if not GetNumSpecsFunc or not GetSpecInfoFunc then
                Debug:Error("Phase 3 - GetSpecializationInfoForClassID API not available in _G")
                return
            end
            
            local numSpecs = GetNumSpecsFunc(classID)
            Debug:Dev("organizer", "Found", numSpecs, "specializations for classID:", classID, "class:", playerData.class)
            
            for i = 1, numSpecs do
                local specID, specName, _, iconTexture, role = GetSpecInfoFunc(classID, i)
                if specID then
                    Debug:Dev("organizer", "  Spec", i, ":", specName, "role:", role, "specID:", specID)
                    table.insert(availableSpecs, {
                        specID = specID,
                        specName = specName,
                        role = role,
                        iconTexture = iconTexture
                    })
                else
                    Debug:Dev("organizer", "  Spec", i, "returned nil - skipping")
                end
            end
        else
            -- Normal poll: Use CharacterStorage
            charData = NextKey222.CharacterStorage:GetCharacter(characterID)
            if not charData then
                Debug:Error("Phase 3 - Character data not found:", characterID)
                return
            end
            availableSpecs = NextKey222.CharacterStorage:GetAvailableSpecializations(characterID)
        end
        
        Debug:Dev("organizer", "Character has", #availableSpecs, "available specializations")
        
        -- Calculate window height based on number of specs
        local windowHeight = cfg.PHASE3_BASE_HEIGHT + (#availableSpecs * (cfg.PHASE3_SPEC_HEIGHT + 8))
        windowHeight = math.min(windowHeight, 500)
        
        -- Create main frame
        local frame = CreateFrame("Frame", "NextKeySurveyDialog", UIParent, "BackdropTemplate")
        frame:SetSize(cfg.PHASE3_WIDTH, windowHeight)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetFrameLevel(9999)  -- Very high level to ensure it's on top
        frame:SetToplevel(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:Raise()  -- Explicitly raise to front
        
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
        title:SetText("M+ Group Organizer - Spec Preferences")
        title:SetTextColor(1, 0.82, 0)
        
        -- Header text
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOP", frame, "TOP", 0, -45)
        header:SetWidth(cfg.PHASE3_WIDTH - 40)
        header:SetJustifyH("CENTER")
        header:SetText("Select which specs you're willing to play:")
        header:SetTextColor(1, 1, 1)
        
        -- Store spec preferences
        frame.specPreferences = {}
        
        -- Determine current player's active spec for default state
        local currentChar = UnitName("player") .. "-" .. GetRealmName()
        local isCurrentChar = (characterID == currentChar)
        local currentSpecID = nil
        
        if isCurrentChar and GetSpecialization then
            currentSpecID = select(1, GetSpecializationInfo(GetSpecialization()))
        end
        
        -- Create spec preference cards for each specialization
        local yOffset = -75
        for i, specInfo in ipairs(availableSpecs) do
            -- Default state logic:
            -- - Manual entry: Load from existing specPreferences if available
            -- - Current character + current spec: "play" (green)
            -- - Current character + other specs: "none" (grey)
            -- - Alt character + last played spec: "play" (green)
            -- - Alt character + other specs: "none" (grey)
            local defaultState = "none"
            
            if self.isManualEntry then
                -- Manual entry: Pre-populate from existing player preferences
                local playerData = self.targetPlayerData
                if playerData and playerData.specPreferences then
                    -- Get the preference for this spec's role
                    local normalizedRole = specInfo.role:upper()
                    local rolePreference = playerData.specPreferences[normalizedRole]
                    if rolePreference and rolePreference ~= "none" then
                        defaultState = rolePreference  -- "play" or "fill"
                        Debug:Dev("organizer", "Pre-populated spec", specInfo.specName, "with existing preference:", defaultState)
                    end
                end
            elseif not self.isManualEntry then
                if isCurrentChar then
                    -- Current character: green for active spec only
                    if specInfo.specID == currentSpecID then
                        defaultState = "play"
                    end
                elseif charData and charData.specName then
                    -- Alt character: green for last played spec
                    if specInfo.specName == charData.specName then
                        defaultState = "play"
                    end
                end
            end
            
            local specCard = self:CreateSpecCard(frame, specInfo, yOffset, defaultState)
            yOffset = yOffset - (cfg.PHASE3_SPEC_HEIGHT + 8)
            
            -- Store reference for data collection (keyed by specID to support multi-spec roles like Evoker)
            frame.specPreferences[specInfo.specID] = specCard
        end
        
        -- Button container at bottom
        local buttonY = yOffset - 20
        
        -- Back button (only for normal polls, not manual entry)
        if not self.isManualEntry then
            local backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            backButton:SetSize(80, 24)
            backButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
            backButton:SetText("< Back")
            backButton:SetScript("OnClick", function()
                -- Go back to Phase 2 (alt selection) or Phase 1 if current character
                local currentChar = UnitName("player") .. "-" .. GetRealmName()
                if characterID == currentChar then
                    self:ShowPhase1()
                else
                    self:ShowPhase2()
                end
            end)
        end
        
        -- Submit button
        local submitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        submitButton:SetSize(100, 24)
        submitButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
        submitButton:SetText("Submit")
        submitButton:SetScript("OnClick", function()
            self:OnPhase3SubmitClicked(frame, characterID)
        end)
        
        -- Update title if this is a manual entry
        if self.isManualEntry and self.targetPlayerData then
            title:SetText("Set Preferences for " .. self.targetPlayerData.name)
        end
        
        frame:Show()
        self.activeDialog = frame
        self.currentPhase = 3
        
        Debug:Dev("organizer", "Showed Phase 3: Spec selection -", #availableSpecs, "specs for", characterID)
    end, "SurveyDialog:ShowPhase3")
end

-- MARK: Create Spec Card
function SurveyDialog:CreateSpecCard(parent, specInfo, yOffset, defaultState)
    local cfg = UIConfig.POLL_WINDOW
    
    -- Make card clickable (Button instead of Frame)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(cfg.PHASE3_WIDTH - 40, cfg.PHASE3_SPEC_HEIGHT)
    card:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Backdrop (border only - no bgFile so we can use solid colors)
    card:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    -- Create background texture for solid color control
    local bgTexture = card:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(card)
    card.bgTexture = bgTexture
    
    -- Initialize state (none/play/fill)
    card.state = defaultState or "none"
    
    -- Spec icon (left side, standard positioning)
    local specIcon = card:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(40, 40)
    specIcon:SetPoint("LEFT", card, "LEFT", 10, 0)  -- Left side with small padding
    
    -- Use spec icon if available, otherwise fallback to role color
    if specInfo.iconTexture and specInfo.iconTexture ~= "" then
        specIcon:SetTexture(specInfo.iconTexture)
        Debug:Dev("organizer", "Set spec icon texture:", specInfo.iconTexture, "for", specInfo.specName)
    elseif specInfo.specID then
        -- Try to get icon from specID using WoW API
        local _, _, _, iconTexture = GetSpecializationInfoByID(specInfo.specID)
        if iconTexture then
            specIcon:SetTexture(iconTexture)
            Debug:Dev("organizer", "Set spec icon from API for specID:", specInfo.specID)
        else
            -- Fallback to colored circle
            local roleColors = {
                Tank = {0.2, 0.5, 1.0},
                Healer = {0.1, 0.9, 0.1},
                DPS = {0.9, 0.1, 0.1}
            }
            local color = roleColors[specInfo.role] or {1, 1, 1}
            specIcon:SetColorTexture(color[1], color[2], color[3], 0.6)
            Debug:Dev("organizer", "Using fallback color for spec:", specInfo.specName)
        end
    else
        -- Legacy fallback: use role color
        local roleColors = {
            Tank = {0.2, 0.5, 1.0},
            Healer = {0.1, 0.9, 0.1},
            DPS = {0.9, 0.1, 0.1}
        }
        local color = roleColors[specInfo.role] or {1, 1, 1}
        specIcon:SetColorTexture(color[1], color[2], color[3], 0.6)
    end
    
    -- Role icon (directly to the right of spec icon)
    local roleIcon = card:CreateTexture(nil, "ARTWORK")
    roleIcon:SetSize(20, 20)
    roleIcon:SetPoint("LEFT", specIcon, "RIGHT", 8, 0)  -- 8px to the right of spec icon
    
    -- Set role icon texture
    local roleIconPath = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
    roleIcon:SetTexture(roleIconPath)
    
    -- CRITICAL FIX: Normalize role to uppercase for proper icon selection
    local normalizedRole = specInfo.role:upper()
    
    if normalizedRole == "TANK" then
        roleIcon:SetTexCoord(0, 19/64, 22/64, 41/64)
    elseif normalizedRole == "HEALER" then
        roleIcon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
    else  -- DAMAGER/DPS
        roleIcon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
    end
    
    -- Spec name label (centered, to the right of role icon)
    local specLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    specLabel:SetPoint("LEFT", roleIcon, "RIGHT", 6, 0)  -- 6px to the right of role icon
    specLabel:SetText(specInfo.specName or specInfo.role)
    
    -- Spec name color based on role
    local roleColors = {
        Tank = {0.2, 0.5, 1.0},
        Healer = {0.1, 0.9, 0.1},
        DPS = {0.9, 0.1, 0.1}
    }
    local color = roleColors[specInfo.role] or {1, 1, 1}
    specLabel:SetTextColor(color[1], color[2], color[3])
    
    -- State indicator label (right side)
    local stateLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stateLabel:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    card.stateLabel = stateLabel
    
    -- Function to update card visuals based on state
    local function UpdateCardState()
        local stateConfig = {
            none = {
                text = "Not Playing",
                bgColor = {0.15, 0.15, 0.15, 0.85},  -- Slightly lighter dark grey instead of pure black
                borderColor = {0.3, 0.3, 0.3, 0.6},
                textColor = {0.5, 0.5, 0.5}
            },
            play = {
                text = "Want to Play",
                bgColor = cfg.COLOR_GREEN_BG,          -- Use dark green background from UIConfig
                borderColor = {0.2, 0.9, 0.2, 1.0},
                textColor = {0.2, 0.9, 0.2}
            },
            fill = {
                text = "Will Fill",
                bgColor = cfg.COLOR_YELLOW_BG,         -- Use dark yellow background from UIConfig
                borderColor = {0.9, 0.8, 0.2, 1.0},
                textColor = {0.9, 0.8, 0.2}
            }
        }
        
        local config = stateConfig[card.state] or stateConfig.none
        
        -- Set solid background color using texture
        card.bgTexture:SetColorTexture(config.bgColor[1], config.bgColor[2], config.bgColor[3], config.bgColor[4])
        
        -- Set border color
        card:SetBackdropBorderColor(config.borderColor[1], config.borderColor[2], config.borderColor[3], config.borderColor[4])
        
        -- Set label text and color
        stateLabel:SetText(config.text)
        stateLabel:SetTextColor(config.textColor[1], config.textColor[2], config.textColor[3])
    end
    
    -- Click handler to cycle states: none -> play -> fill -> none
    card:SetScript("OnClick", function()
        local oldState = card.state
        if card.state == "none" then
            card.state = "play"
        elseif card.state == "play" then
            card.state = "fill"
        else
            card.state = "none"
        end
        UpdateCardState()
        Debug:Dev("organizer", "Spec card clicked:", specInfo.specName, "- State changed from", oldState, "to", card.state)
    end)
    
    -- Hover effects (store original state colors for hover)
    card.hoverColors = {
        none = {0.18, 0.18, 0.18, 0.85},  -- Slightly lighter grey
        play = {0.08, 0.33, 0.08, 0.9},    -- Slightly lighter dark green
        fill = {0.38, 0.33, 0.08, 0.9}     -- Slightly lighter dark yellow
    }
    
    card:SetScript("OnEnter", function()
        -- Use pre-calculated hover color for current state
        local hoverColor = card.hoverColors[card.state] or card.hoverColors.none
        card.bgTexture:SetColorTexture(hoverColor[1], hoverColor[2], hoverColor[3], hoverColor[4])
        
        -- Brighten border
        local currentBorderColor = {card:GetBackdropBorderColor()}
        card:SetBackdropBorderColor(
            math.min(currentBorderColor[1] * 1.5, 1),
            math.min(currentBorderColor[2] * 1.5, 1),
            math.min(currentBorderColor[3] * 1.5, 1),
            1.0  -- Full opacity
        )
        
        -- Show tooltip
        GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
        GameTooltip:SetText(specInfo.specName or specInfo.role, 1, 1, 1)
        GameTooltip:AddLine("Click to cycle preference", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cff808080Not Playing|r -> |cff33ff33Want to Play|r -> |cffffff33Will Fill|r", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    card:SetScript("OnLeave", function()
        UpdateCardState()  -- Restore original colors
        GameTooltip:Hide()
    end)
    
    -- Initialize visuals
    UpdateCardState()
    
    -- Store references
    card.role = specInfo.role
    card.specID = specInfo.specID
    card.specName = specInfo.specName
    
    return card
end

-- MARK: Spec Submit
function SurveyDialog:OnPhase3SubmitClicked(frame, characterID)
    return NextKey222.SafeRun(function()
        -- Collect spec preferences from card states
        local specPreferences = {}
        local hasAnyPreference = false
        
        Debug:Dev("organizer", "Collecting spec preferences from Phase 3 cards:")
        
        -- Priority: play > fill > none
        local priorityMap = { play = 3, fill = 2, none = 1 }
        
        -- Track spec-level data for tooltip
        local specDetails = {}
        
        for specID, specCard in pairs(frame.specPreferences) do
            local cardState = specCard.state or "none"
            
            Debug:Dev("organizer", "  - specID", specID, "(", specCard.specName, ") card state:", cardState)
            
            -- Track individual spec preferences for tooltip
            -- CRITICAL: Normalize role to uppercase for consistent keying
            local normalizedRole = specCard.role:upper()
            
            if not specDetails[normalizedRole] then
                specDetails[normalizedRole] = {}
            end
            table.insert(specDetails[normalizedRole], {
                specName = specCard.specName,
                preference = cardState
            })
            
            -- Store by role with priority (highest priority wins)
            if cardState and cardState ~= "none" then
                local currentPriority = priorityMap[specPreferences[normalizedRole]] or 0
                local newPriority = priorityMap[cardState] or 0
                
                if newPriority > currentPriority then
                    specPreferences[normalizedRole] = cardState
                    Debug:Dev("organizer", "    -> Setting", normalizedRole, "to", cardState, "(higher priority)")
                end
            end
            
            if specCard.state and specCard.state ~= "none" then
                hasAnyPreference = true
            end
        end
        
        -- Store spec details for tooltip rendering
        frame.specDetails = specDetails
        
        Debug:Dev("organizer", "Final spec preferences being sent:", specPreferences)
        
        -- Check if all specs are set to "none" (no preferences selected)
        if not hasAnyPreference then
            -- Show confirmation dialog before moving to opt-out
            self:ShowAllNoneConfirmation(frame, characterID, specPreferences, specDetails)
            return
        end
        
        -- Store Phase 3 data (include specDetails for tooltip rendering)
        self.responseData.phase3 = {
            specPreferences = specPreferences,
            specDetails = specDetails,  -- CRITICAL: Include spec-level breakdown for tooltips
            timestamp = GetTime()
        }
        
        -- Submit final response
        if self.isManualEntry then
            -- Manual entry: process directly without sending over network
            self:SubmitManualResponse(true)
        else
            -- Normal poll: send response
            self:SubmitFinalResponse(true)
        end
        
        -- Close dialog
        self:CloseDialog()
        
        Debug:Dev("organizer", "Phase 3 submitted with preferences:", specPreferences)
        
    end, "SurveyDialog:OnPhase3SubmitClicked")
end

-- MARK: All None Confirmation
function SurveyDialog:ShowAllNoneConfirmation(parentFrame, characterID, specPreferences, specDetails)
    return NextKey222.SafeRun(function()
        local cfg = UIConfig.POLL_WINDOW
        
        -- Hide parent frame while showing confirmation dialog
        if parentFrame then
            parentFrame:Hide()
        end
        
        -- Create frame matching poll window style
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame:SetSize(400, 220)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Same strata as poll windows
        frame:SetFrameLevel(10000)  -- Higher level than poll windows (9999)
        frame:SetToplevel(true)  -- CRITICAL: This ensures frame rises above others in same strata
        frame:SetMovable(false)  -- Not draggable - it's a modal confirmation dialog
        frame:EnableMouse(false)  -- Don't capture mouse - let buttons handle it
        frame:Raise()  -- Explicitly raise to front
        
        -- Backdrop matching poll windows
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        frame:SetBackdropBorderColor(0.8, 0.4, 0, 1)  -- Warning orange
        
        -- Warning Icon (large, centered at top)
        local warningIcon = frame:CreateTexture(nil, "ARTWORK")
        warningIcon:SetSize(48, 48)
        warningIcon:SetPoint("TOP", 0, -20)
        warningIcon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
        
        -- Title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -75)
        title:SetText("No Specs Selected")
        title:SetTextColor(1, 0.82, 0)
        
        -- Message
        local message = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        message:SetPoint("TOP", 0, -110)
        message:SetWidth(360)
        message:SetJustifyH("CENTER")
        message:SetText("You haven't selected any specs to play.\n\nThis will place you in the \"Not Playing\" section.\n\nAre you sure?")
        message:SetTextColor(1, 1, 1)
        
        -- CRITICAL: Create buttons BEFORE frame:Show()
        local backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        backButton:SetSize(100, 24)
        backButton:SetPoint("BOTTOMLEFT", 20, 15)
        backButton:SetText("Go Back")
        backButton:SetScript("OnClick", function()
            frame:Hide()
            -- Restore parent frame visibility
            if parentFrame then
                parentFrame:Show()
            end
        end)
        
        local optOutButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        optOutButton:SetSize(160, 24)
        optOutButton:SetPoint("BOTTOMRIGHT", -20, 15)
        optOutButton:SetText("Opt Out (Not Playing)")
        optOutButton:SetScript("OnClick", function()
            frame:Hide()
            
            -- Store Phase 3 data with empty preferences
            self.responseData.phase3 = {
                specPreferences = {},
                specDetails = specDetails,
                timestamp = GetTime()
            }
            
            -- Submit as opt-out
            if self.isManualEntry then
                self:SubmitManualResponse(false)
            else
                self:SubmitFinalResponse(false)
            end
            
            -- Close survey dialog
            self:CloseDialog()
            
            Debug:Dev("organizer", "Player confirmed opt-out (no specs selected)")
        end)
        
        -- Show frame AFTER all elements are created
        frame:Show()
        
    end, "SurveyDialog:ShowAllNoneConfirmation")
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
            response.specDetails = self.responseData.phase3.specDetails  -- CRITICAL: Include for tooltip rendering
        end
        
        -- Check if we're the organizer
        local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
        if currentPlayer == self.pollData.organizerName then
            -- Process our own response directly
            if NextKey222.ParticipantSurvey then
                NextKey222.ParticipantSurvey:ProcessResponse(currentPlayer, response)
            end
            
            -- If opted out (no specs selected), move to opt-out section
            if not optedIn and NextKey222.OrganizerState then
                NextKey222.OrganizerState:MoveToOptOut(currentPlayer)
                Debug:Dev("organizer", "Moved player to opt-out (no specs selected):", currentPlayer)
            end
            
            -- SESSION 3: Sync UI to state immediately (same as other responses)
            if NextKey222.RosterBoard and NextKey222.RosterBoard.SyncUIToState then
                NextKey222.RosterBoard:SyncUIToState()
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

-- MARK: Manual Response
-- Right-Click Entry
function SurveyDialog:SubmitManualResponse(optedIn)
    return NextKey222.SafeRun(function()
        local response = {
            pollID = self.pollData.pollID,
            optedIn = optedIn,
            timestamp = GetTime(),
            isManualEntry = true  -- Flag to identify manual entries
        }
        
        if optedIn and self.responseData.phase2 and self.responseData.phase3 then
            response.selectedCharacter = self.responseData.phase2.selectedCharacterID
            response.characterData = self.responseData.phase2.characterData
            response.specPreferences = self.responseData.phase3.specPreferences
            response.specDetails = self.responseData.phase3.specDetails
        end
        
        -- Get the target player ID (the player we're setting preferences for)
        local targetPlayerID = self.targetPlayerData and self.targetPlayerData.id or response.selectedCharacter
        
        -- Process manually entered response directly (as organizer)
        if NextKey222.ParticipantSurvey then
            NextKey222.ParticipantSurvey:ProcessResponse(targetPlayerID, response)
        end
        
        -- Update OrganizerState directly
        if NextKey222.OrganizerState then
            NextKey222.OrganizerState:UpdatePlayerFromPollResponse(targetPlayerID, response)
            
            -- If opted out (no specs selected), move to opt-out section
            if not optedIn then
                NextKey222.OrganizerState:MoveToOptOut(targetPlayerID)
                Debug:Dev("organizer", "Moved player to opt-out (no specs selected):", targetPlayerID)
            end
        end
        
        -- Sync UI to show changes
        if NextKey222.RosterBoard and NextKey222.RosterBoard.SyncUIToState then
            NextKey222.RosterBoard:SyncUIToState()
        end
        
        -- Save state (with database check)
        if NextKey222.OrganizerState and NextKey222.OrganizerState.SaveToPersistence then
            local success = NextKey222.OrganizerState:SaveToPersistence()
            if not success then
                Debug:Dev("organizer", "State save failed but data is in memory - will persist on reload")
            end
        end
        
        if not optedIn then
            Debug:User("Set " .. (self.targetPlayerData and self.targetPlayerData.name or "player") .. " to Not Playing (no specs selected)")
        else
            Debug:User("Manually set preferences for " .. (self.targetPlayerData and self.targetPlayerData.name or "player"))
        end
        Debug:Dev("organizer", "Submitted manual response for:", targetPlayerID, "opted in:", optedIn)
        
        -- Clear manual entry flags
        self.isManualEntry = false
        self.targetPlayerData = nil
        
    end, "SurveyDialog:SubmitManualResponse")
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