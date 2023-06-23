local ADDON_NAME, ns = ...

---------- Helper Function to generate the QuestList from ns.QuestDB ----------
function ns.QuestList()
    local QuestList = {}
    local TIME = time()
    for id, quest in pairs(ns.QuestDB) do
        if quest.title then
            table.insert(QuestList, {
                id = id,
                title = quest.title,
                time = quest.time or -1, -- defaults to -1 for sorting
                map = quest.mapName,
                pos = {x = quest.x or 0, y = quest.y or 0}
            })
        end
    end
    return QuestList
end
-------------------------------------------------------------------------------

local QuestHistory = {}

function QuestHistory:UpdateQuestDB(changedQuests, slow)
    local mapID = C_Map.GetBestMapForUnit('player')
    local mapName = C_Map.GetMapInfo(mapID).name
    local x, y = C_Map.GetPlayerMapPosition(mapID, 'player'):GetXY()
    local TIME = time()
    local qDB = ns.QuestDB

    local counter = 0
    for id, changedTo in pairs(changedQuests) do
        counter = counter + 1
        if counter > 20 then
            if not slow then Addon:Print('>20 Quests Changed, please wait.') end
            C_Timer.After(0.5, function() self:UpdateQuestDB(changedQuests, true) end)
            break
        elseif id ~= 'count' then
            if not qDB[id] then
                qDB[id] = {id = id, completed = changedTo}
            else
                qDB[id].completed = changedTo
            end

            if not qDB[id].title then
                qDB[id].title = C_QuestLog.GetTitleForQuestID(id) or 'Hidden/Tracking Quest'
            end

            qDB[id].mapId = mapID
            qDB[id].mapName = mapName or UNKNOWN
            qDB[id].x = x or 0
            qDB[id].y = y or 0
            qDB[id].time = TIME

            local tru, fls = '|cFF00FF00TRUE|r', '|cFFFF0000FALSE|r'
            local change = qDB[id].completed and (fls .. " > " .. tru) or (tru .. " > " .. fls)
            ns.Print(format('Quest [%d] (%s) changed from %s', id, qDB[id].title, change))
        end
    end
end

function QuestHistory:GetCompletedQuests()
    local Q = {}
    for _, id in pairs(C_QuestLog.GetAllCompletedQuestIDs()) do Q[id] = true end
    return Q
end

function QuestHistory:Refresh()
    ns.HistoryFrame.dataProvider:Flush()
    ns.HistoryFrame.dataProvider:InsertTable(ns.QuestList())
    ns.HistoryFrame.dataProvider:Sort()
    ns.HistoryFrame.ScrollView:SetDataProvider(ns.HistoryFrame.dataProvider)
end

function QuestHistory:GetChangedQuests()
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

ns.QuestHistory = QuestHistory
