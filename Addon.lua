local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

function Addon:OnInitialize() ns.DB = LibStub('AceDB-3.0'):New('QuestTrackerDB', {char = {Quests = {}}}) end

function Addon:OnEnable()
    self:InitQDB()
    ns.HistoryFrame:Init()
    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('QUEST_DATA_LOAD_RESULT')
end

function Addon:InitQDB()
    local quests = C_QuestLog.GetAllCompletedQuestIDs()
    for _, id in pairs(quests) do if not ns.DB.char.Quests[id] then ns.DB.char.Quests[id] = {completed = true} end end
end

function Addon:QUEST_LOG_UPDATE()
    ns.changedQuests = ns.QuestHistory:GetChangedQuests() or {quests = {}, counter = 0}
    if ns.changedQuests.counter > 0 then
        self:Print(ns.changedQuests.counter, 'Quests Changed:')
        ns.QuestHistory:UpdateQuestDB(true)
        ns.HistoryFrame:Refresh()
    end
end

function Addon:QUEST_DATA_LOAD_RESULT(e, id, success)    
    if not ns.changedQuests or not ns.changedQuests.quests or not ns.changedQuests.quests[id] then
        return
    end

    if ns.DB.char.Quests[id] and ns.DB.char.Quests[id].completed ~= nil then
        ns.DB.char.Quests[id].title = C_QuestLog.GetTitleForQuestID(id) or 'Hidden/Tracking Quest'
        ns.HistoryFrame:Refresh()

        local tru, fls = '|cFF00FF00TRUE|r', '|cFFFF0000FALSE|r'
        local change = ns.DB.char.Quests[id].completed and tru or fls
        ns.Print(format('Quest [%d] (%s) changed to %s', id, ns.DB.char.Quests[id].title, change))
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

-------------------------------------------------------------------------------

ns.Addon = Addon
