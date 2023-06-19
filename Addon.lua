local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', "AceTimer-3.0")

function Addon:OnInitialize()
    local db = LibStub("AceDB-3.0"):New("QuestTrackerDB", {char = {Quests = {}}})
    ns.QuestDB = db.char.Quests
    ns.HistoryFrame:Init()
end

function Addon:OnEnable()
    if next(ns.QuestDB) == nil then
        self:Print("QuestDB is empty, getting completed quests")
        for id, c in pairs(self.GetCompletedQuests()) do ns.QuestDB[id] = {completed = c} end
    end
    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
end

function Addon:QUEST_LOG_UPDATE() self:Refresh() end

function Addon:Refresh()
    local changedQuests = ns.QuestHistory:GetChangedQuests()
    if changedQuests.count > 0 then
        self:Print(changedQuests.count, "Quests Changed:")
        ns.QuestHistory:UpdateQuestDB(changedQuests)
        ns.QuestHistory:Refresh()
    end
end

Addon:RegisterChatCommand("QT", function() if ns.HistoryFrame then ns.HistoryFrame:Show() end end)

function ns.Print(...) Addon:Print(...) end
