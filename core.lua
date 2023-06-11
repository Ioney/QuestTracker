local ADDON_NAME, ns = ...

ns.Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', "AceTimer-3.0")
local defaults = {char = {Quests = {}}}

function ns.Addon:OnInitialize()
    local db = LibStub("AceDB-3.0"):New("QuestTrackerDB", defaults)
    ns.QuestDB = db.char.Quests
    ns.QuestHistory:Init()
end

function ns.Addon:OnEnable()
    if next(ns.QuestDB) == nil then
        self:Print("QuestDB is empty, getting completed quests")
        for id, c in pairs(self.GetCompletedQuests()) do ns.QuestDB[id] = {completed = c} end
    end
    self:RegisterEvent('QUEST_LOG_UPDATE')
end

function ns.Addon:QUEST_LOG_UPDATE() self:Refresh() end

function ns.Addon:Refresh()
    local changedQuests = self:GetChangedQuests()
    if changedQuests.count > 0 then
        self:Print(changedQuests.count, "Quests Changed:")
        self:UpdateQuestDB(changedQuests)
        ns.QuestHistory:Refresh()
    end
end

function ns.Addon:UpdateQuestDB(changedQuests, slow)
    local mapID = C_Map.GetBestMapForUnit('player')
    local mapName = C_Map.GetMapInfo(mapID).name
    local x, y = C_Map.GetPlayerMapPosition(mapID, 'player'):GetXY()
    local TIME = time()

    local counter = 0
    for id, changedTo in pairs(changedQuests) do
        counter = counter + 1
        if counter > 20 then
            if not slow then self:Print(">20 Quests Changed, please wait.") end
            C_Timer.After(0.5, function() self:UpdateQuestDB(changedQuests, true) end)
            break
        elseif id ~= 'count' then
            if not ns.QuestDB[id] then
                ns.QuestDB[id] = {id = id, completed = changedTo}
            else
                ns.QuestDB[id].completed = changedTo
            end

            if not ns.QuestDB[id].title then
                ns.QuestDB[id].title = C_QuestLog.GetTitleForQuestID(id) or 'Hidden/Tracking Quest'
            end

            ns.QuestDB[id].map = {id = mapID or UNKNOWN, name = mapName or UNKNOWN}
            ns.QuestDB[id].x = x or 0
            ns.QuestDB[id].y = y or 0
            ns.QuestDB[id].time = TIME

            print(ns.QuestDB[id].map, ns.QuestDB[id].x, ns.QuestDB[id].y, ns.QuestDB[id].time)

            self:Print("[" .. id .. "]", ns.QuestDB[id].title, "changed from", not ns.QuestDB[id].completed, "to",
                       ns.QuestDB[id].completed)
        end
    end
end

function ns.Addon:GetCompletedQuests()
    local Q = {}
    for _, id in pairs(C_QuestLog.GetAllCompletedQuestIDs()) do Q[id] = true end
    return Q
end

function ns.Addon:GetChangedQuests()
    local completedQuests = self:GetCompletedQuests()
    local qDB = ns.QuestDB

    local changed = {count = 0}
    for id, completed in pairs(completedQuests) do
        -- Quest was completed before and is now not completed
        if qDB[id] and qDB[id].completed == true and not completed then
            changed[id] = false
            changed.count = changed.count + 1
        end
        -- Quest was not completed before and is now completed
        if qDB[id] and qDB[id].completed == false and completed then
            changed[id] = true
            changed.count = changed.count + 1
        end
        -- Quest did not exist in QuestDB and is now completed
        if not qDB[id] and completed then
            changed[id] = true
            changed.count = changed.count + 1
        end
    end
    for id, quest in pairs(qDB) do
        -- Quest was completed before and is now not completed
        if completedQuests[id] == true and not quest.completed then
            changed[id] = true
            changed.count = changed.count + 1
        end
        -- Quest was not completed before and is now completed
        if completedQuests[id] == false and quest.completed then
            changed[id] = false
            changed.count = changed.count + 1
        end
    end

    return changed
end

ns.Addon:RegisterChatCommand("QT", function() if ns.QuestHistory.Frame then ns.QuestHistory.Frame:Show() end end)
