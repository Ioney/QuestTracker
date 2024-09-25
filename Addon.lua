local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

function Addon:OnInitialize() ns.DB = LibStub('AceDB-3.0'):New('QuestTrackerDB', {char = {Quests = {}}}) end

function Addon:OnEnable()
    local quests = C_QuestLog.GetAllCompletedQuestIDs()
    for _, id in pairs(quests) do if not ns.DB.char.Quests[id] then ns.DB.char.Quests[id] = {completed = true} end end
    ns.HistoryFrame:Init()
    self:RegisterEvent('QUEST_LOG_UPDATE')
end

function Addon:QUEST_LOG_UPDATE()
    local changedQuests = ns.QuestHistory:GetChangedQuests()
    if changedQuests.counter > 0 then
        self:Print(changedQuests.counter, 'Quests Changed:')
        ns.QuestHistory:UpdateQuestDB(true)
        ns.HistoryFrame:Refresh()
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
