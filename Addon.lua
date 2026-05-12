local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

function Addon:OnInitialize() ns.DB = LibStub('AceDB-3.0'):New('QuestTrackerDB', {char = {Quests = {}}}) end

function Addon:OnEnable()
    self:InitQDB()
    ns.HistoryFrame:HookScript('OnShow', function(self)
        if not self.initialized then
            self:Init()
            self.initialized = true
        end
    end)
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('QUEST_DATA_LOAD_RESULT')
end

function Addon:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent('PLAYER_ENTERING_WORLD')
    self:MigrateQDB()
end

function Addon:InitQDB()
    local quests = C_QuestLog.GetAllCompletedQuestIDs()
    for _, id in pairs(quests) do if not ns.DB.char.Quests[id] then ns.DB.char.Quests[id] = {completed = true} end end
end

-- Resolves a quest title: WoW API → Grail → PrintQuests → unknown
-- Returns: title (string), trackingType ('confident'|'unsure'|'unknown'|nil)
-- trackingType nil means WoW provided the title directly (normal quest).
local function ResolveTitle(id)
    local title = C_QuestLog.GetTitleForQuestID(id)
    if title then return title, nil end

    if Grail and Grail.QuestName then
        local grailName = Grail:QuestName(id)
        if grailName then return grailName, 'confident' end
    end

    if PrintQuests then
        if PrintQuests.ConfidentlyNamedTrackingQuests and PrintQuests.ConfidentlyNamedTrackingQuests[id] then
            return PrintQuests.ConfidentlyNamedTrackingQuests[id], 'confident'
        elseif PrintQuests.UnsurelyNamedTrackingQuests and PrintQuests.UnsurelyNamedTrackingQuests[id] then
            return PrintQuests.UnsurelyNamedTrackingQuests[id], 'unsure'
        end
    end

    return 'Hidden/Tracking Quest', 'unknown'
end

-- Migrates old DB entries that predate the trackingType field.
-- 'Pending ...' entries not found in Grail/PrintQuests are re-requested from WoW.
-- 'unknown' entries are re-checked every login in case Grail/PrintQuests now has a name.
local migrationPending = {}

local function resolveFromGrailOrPrintQuests(id, quest)
    if Grail and Grail.QuestName then
        local grailName = Grail:QuestName(id)
        if grailName then
            quest.title = grailName
            quest.trackingType = 'confident'
            return true
        end
    end
    if PrintQuests and PrintQuests.ConfidentlyNamedTrackingQuests and PrintQuests.ConfidentlyNamedTrackingQuests[id] then
        quest.title = PrintQuests.ConfidentlyNamedTrackingQuests[id]
        quest.trackingType = 'confident'
        return true
    elseif PrintQuests and PrintQuests.UnsurelyNamedTrackingQuests and PrintQuests.UnsurelyNamedTrackingQuests[id] then
        quest.title = PrintQuests.UnsurelyNamedTrackingQuests[id]
        quest.trackingType = 'unsure'
        return true
    end
    return false
end

function Addon:MigrateQDB()
    for id, quest in pairs(ns.DB.char.Quests) do
        if quest.trackingType == 'unknown' then
            -- Re-check each login: Grail or PrintQuests might now have a name
            resolveFromGrailOrPrintQuests(id, quest)
            -- else: still unknown, leave as is

        elseif quest.trackingType ~= nil then
            -- confident/unsure: already evaluated, skip

        elseif quest.title == nil or quest.title == 'Hidden/Tracking Quest' or quest.title == 'Pending ...' then
            if not resolveFromGrailOrPrintQuests(id, quest) then
                if quest.title == 'Pending ...' then
                    -- Not in Grail or PrintQuests – re-request from WoW, handled in QUEST_DATA_LOAD_RESULT
                    migrationPending[id] = true
                    C_QuestLog.RequestLoadQuestByID(id)
                else
                    quest.trackingType = 'unknown'
                end
            end
        end
    end
end

-------------------------------------------------------------------------------

local processedQuests = {}

function Addon:QUEST_LOG_UPDATE()
    processedQuests = {}
    ns.changedQuests = ns.QuestHistory:GetChangedQuests() or {quests = {}, counter = 0}
    if ns.changedQuests.counter > 0 then
        ns.QuestHistory:UpdateQuestDB(true)
        ns.HistoryFrame:Refresh()
    end
end

function Addon:QUEST_DATA_LOAD_RESULT(e, id, success)
    local isMigration = migrationPending[id]
    local isChanged = ns.changedQuests and ns.changedQuests.quests and ns.changedQuests.quests[id]

    if not isMigration and not isChanged then return end
    if processedQuests[id] then return end
    processedQuests[id] = true

    if ns.DB.char.Quests[id] and ns.DB.char.Quests[id].completed ~= nil then
        local title, trackingType = ResolveTitle(id)
        ns.DB.char.Quests[id].title = title
        ns.DB.char.Quests[id].trackingType = trackingType

        migrationPending[id] = nil
        ns.HistoryFrame:Refresh()

        -- Only print chat message for newly changed quests, not migrations
        if isChanged then
            local tru, fls = '|cFF00FF00TRUE|r', '|cFFFF0000FALSE|r'
            local change = ns.DB.char.Quests[id].completed and tru or fls
            ns.Print(format('Quest [%d] (%s) changed to %s', id, title, change))
        end
    end
end

-------------------------------------------------------------------------------

function ns.Print(...) Addon:Print(...) end

-------------------------------------------------------------------------------
-------------------------------- CHAT COMMANDS --------------------------------
-------------------------------------------------------------------------------

Addon:RegisterChatCommand('QT', function() if ns.HistoryFrame then ns.HistoryFrame:Show() end end)

-- Debug
Addon:RegisterChatCommand('QTflush', function()
    ns.DB.char.Quests = {}
    Addon:InitQDB()
    ns.HistoryFrame:Refresh()
end)
Addon:RegisterChatCommand('QTupdate', function() ns.QuestHistory:UpdateQuestDB() end)
Addon:RegisterChatCommand('QTprint', function()
    ns.printQDB()
    ns.Print(next(ns.DB.char.Quests))
end)
ns.printQDB = function()
    for k, v in pairs(ns.DB.char.Quests) do
        ns.Print(k, v)
        if type(v) == 'table' then for x, y in pairs(v) do ns.Print("--", x, y) end end
    end
end
Addon:RegisterChatCommand('QTmissing', function()
    local list = {}
    for id, quest in pairs(ns.DB.char.Quests) do
        if not quest.title or quest.title == 'Pending ...' or quest.title == 'Hidden/Tracking Quest' then
            table.insert(list, {
                id           = id,
                title        = quest.title,
                trackingType = quest.trackingType,
                time         = quest.time or 0,
            })
        end
    end
    table.sort(list, function(a, b) return a.time > b.time end)

    -- Persist to SavedVars
    ns.DB.char.MissingQuestsLog = {
        scannedAt = time(),
        quests    = list,
    }

    -- Print sorted
    for _, q in ipairs(list) do
        ns.Print(format('[%s] Quest [%d] trackingType=%s title=%s',
            q.time > 0 and date('%d.%m %H:%M', q.time) or '??',
            q.id,
            tostring(q.trackingType),
            tostring(q.title)
        ))
    end
    ns.Print(format('Total missing: %d  (gespeichert in MissingQuestsLog)', #list))
end)

-------------------------------------------------------------------------------

ns.Addon = Addon
