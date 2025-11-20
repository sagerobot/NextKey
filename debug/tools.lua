-- MARK: Debug Tools & Forms
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

-- Helper Functions
local function normalizeMapID(mapID)
    return tonumber(mapID) or 0
end

-- MARK: Add Form Functions
function NextKey:EnsureDebugAddForm()
    local dbg = self:EnsureDebug()
    dbg.addForm = dbg.addForm or { best = {} }
    dbg.addForm.best = dbg.addForm.best or {}
    return dbg.addForm
end

function NextKey:GetAddFormBest(mapID)
    local form = self:EnsureDebugAddForm()
    return form.best[normalizeMapID(mapID)]
end

function NextKey:SetAddFormBest(mapID, level, chests)
    local form = self:EnsureDebugAddForm()
    mapID = normalizeMapID(mapID)
    if not level or level <= 0 then
        form.best[mapID] = nil
        return
    end
    form.best[mapID] = {
        level = level,
        timed = (chests or 0) > 0,
        chests = chests or 0,
        fractionalTime = (chests or 0) > 0 and (NextKey222.IOCalculator and NextKey222.IOCalculator:ApproximateFractionalFromChests(chests) or 1.0) or nil,
    }
end

function NextKey:SetAddFormAllBest(level, timed)
    local form = self:EnsureDebugAddForm()
    if not level or level <= 0 then
        form.best = {}
        return
    end
    for _, mapID in ipairs(self:GetActiveSeasonDungeonIDs()) do
        form.best[mapID] = {
            level = level,
            timed = timed == true,
            chests = timed and 1 or 0,
            fractionalTime = timed and (NextKey222.IOCalculator and NextKey222.IOCalculator:ApproximateFractionalFromChests(1) or 0.9) or nil,
        }
    end
end

function NextKey:ClearAddFormBest()
    local form = self:EnsureDebugAddForm()
    form.best = {}
end

