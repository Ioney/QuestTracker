local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

function Addon:OnInitialize()
    ns.DB = LibStub('AceDB-3.0'):New(ADDON_NAME .. 'DB', {char = {Quests = {}}})
    ns.QuestDB = ns.DB.char.Quests

    ns.HistoryFrame:Init()
end

function Addon:OnEnable()
    ns.QuestHistory:UpdateQuestDB(ns.QuestHistory:GetChangedQuests(), nil, true)
    self:RegisterEvent('QUEST_LOG_UPDATE')
end

function Addon:QUEST_LOG_UPDATE() self:Refresh() end

function Addon:Refresh()
    local changedQuests = ns.QuestHistory:GetChangedQuests()
    if changedQuests.count > 0 then
        self:Print(changedQuests.count, 'Quests Changed:')
        ns.QuestHistory:UpdateQuestDB(changedQuests)
        ns.QuestHistory:Refresh()
    end
end

-------------------------------------------------------------------------------

function ns.Print(...) Addon:Print(...) end

-------------------------------------------------------------------------------
-------------------------------- CHAT COMMANDS --------------------------------
-------------------------------------------------------------------------------

Addon:RegisterChatCommand('QT', function() if ns.HistoryFrame then ns.HistoryFrame:Show() end end)

-------------------------------------------------------------------------------

ns.Addon = Addon
