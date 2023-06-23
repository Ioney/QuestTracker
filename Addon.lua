local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

function Addon:OnInitialize()
    ns.DB = LibStub('AceDB-3.0'):New(ADDON_NAME .. 'DB', {char = {Quests = {}}})
    ns.QuestDB = ns.DB.char.Quests

    ns.HistoryFrame:Init()
    ns.Options:Init()
end

function Addon:OnEnable()
    if next(ns.QuestDB) == nil then -- Generate QuestDB at first Login.
        for id, c in pairs(ns.QuestHistory.GetCompletedQuests()) do ns.QuestDB[id] = {completed = c} end
    end
    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('CURRENCY_DISPLAY_UPDATE')
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

function Addon:CURRENCY_DISPLAY_UPDATE(_, id, qty, change, gain, lost)
    local SPAM = {
        [2155] = true,
        [2156] = true,
        [2157] = true,
        [2158] = true,
        [2160] = true,
        [2162] = true,
        [2159] = true
    }
    if id and not SPAM[id] then
        local Currency = C_CurrencyInfo.GetCurrencyInfo(id)
        local str = 'Currency [%d] (%s) changed from %d to %d.'
        self:Print(format(str, id, Currency.name, Currency.quantity - change, Currency.quantity))
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
