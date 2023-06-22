local ADDON_NAME, ns = ...

_G['HandyNotes_ZarPluginsDevelopment'] = true

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

function Addon:OnInitialize()
    local db = LibStub('AceDB-3.0'):New('ZarPlugins_DevDB', {char = {Quests = {}}})
    ns.QuestDB = db.char.Quests
    ns.HistoryFrame:Init()
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

function ns.Print(...) Addon:Print(...) end

-------------------------------------------------------------------------------
-------------------------------- CHAT COMMANDS --------------------------------
-------------------------------------------------------------------------------

Addon:RegisterChatCommand('QT', function() if ns.HistoryFrame then ns.HistoryFrame:Show() end end)

Addon:RegisterChatCommand('PetID', function(name)
    if #name == 0 then return print('Usage: /petid NAME') end
    local petid = C_PetJournal.FindPetIDByName(name)
    if petid then
        Addon:Print(name .. ': ' .. petid)
    else
        Addon:Print('NO MATCH FOR: /petid ' .. name)
    end
end)

Addon:RegisterChatCommand('MountID', function(name)
    if #name == 0 then return print('Usage: /mountid NAME') end
    for i, m in ipairs(C_MountJournal.GetMountIDs()) do
        if (C_MountJournal.GetMountInfoByID(m) == name) then
            Addon:Print(name .. ': ' .. m)
            return
        end
    end
    Addon:Print('NO MATCH FOR: /mountid ' .. name)
end)

Addon:RegisterChatCommand('ScanQuestObjectives', function(_start_end_)
    local _start_, _end_ = strsplit(' ', _start_end_)

    local function attemptObjectiveInfo(quest, index)
        local text, objectiveType, finished, fulfilled = GetQuestObjectiveInfo(quest, index, true)
        if text or objectiveType or finished or fulfilled then
            ns.Print(quest, index, text, objectiveType, finished, fulfilled)
        end
    end

    for i = _start_, _end_, 1 do for j = 0, 10, 1 do attemptObjectiveInfo(i, j) end end
end)
