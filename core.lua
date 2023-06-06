local ADDON_NAME, ns = ...

local Addon = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceConsole-3.0',
                                               'AceEvent-3.0', "AceTimer-3.0")
local defaults = {char = {Quests = {}}}

function Addon:OnInitialize()
    local db = LibStub("AceDB-3.0"):New("QuestTrackerDB", defaults)
    self.QuestDB = db.char.Quests
end

function Addon:OnEnable() -- Called when the addon is enabled
    if next(self.QuestDB) == nil then
        self:Print("QuestDB is empty, getting completed quests")
        for id, c in pairs(self.GetCompletedQuests()) do
            self.QuestDB[id] = {completed = c}
            print(id, self.QuestDB[id].completed)
        end
    end

    self:RegisterEvent('QUEST_LOG_UPDATE')
end

function Addon:OnDisable() -- Called when the addon is disabled
    self:UnregisterAllBuckets()
end

function Addon:QUEST_LOG_UPDATE()
    self:Print("QUEST_LOG_UPDATE")
    self:Refresh()
end

function Addon:Refresh()
    local changedQuests = self:GetChangedQuests()
    if changedQuests.count > 0 then
        self:Print(changedQuests.count, "Quests Changed:")
        Addon:UpdateQuestDB(changedQuests)
    end
end

function Addon:UpdateQuestDB(changedQuests)
    local Quests = {}
    local counter = 0

    for id, changeTo in pairs(changedQuests) do
        counter = counter + 1
        if counter > 20 then
            self:Print(">20 Quests Changed, please wait.")
            C_Timer.After(0.5, function()
                self:UpdateQuestDB(changedQuests)
            end)
            break
        else
            if id ~= 'count' then
                if not self.QuestDB[id] then
                    self.QuestDB[id] = {completed = changeTo}
                else
                    self.QuestDB[id].completed = changeTo
                end
                if self.QuestDB[id] and not self.QuestDB[id].title then
                    self.QuestDB[id].title =
                        C_QuestLog.GetTitleForQuestID(id) or
                            'Hidden/Tracking Quest'
                end

                self:Print("[" .. id .. "]", self.QuestDB[id].title,
                           "changed from", not self.QuestDB[id].completed, "to",
                           self.QuestDB[id].completed)
            end
        end
    end
end

function Addon:GetCompletedQuests()
    local Q = {}
    for _, id in pairs(C_QuestLog.GetAllCompletedQuestIDs()) do Q[id] = true end
    return Q
end

function Addon:GetChangedQuests()
    local completedQuests = self:GetCompletedQuests()
    local qDB = self.QuestDB

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
        if completedQuests[id] == true and not quest.completed then
            changed[id] = true
            changed.count = changed.count + 1
        end
        if completedQuests[id] == false and quest.completed then
            changed[id] = false
            changed.count = changed.count + 1
        end
    end

    return changed
end
