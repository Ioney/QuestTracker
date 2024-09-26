local ADDON_NAME, ns = ...

---------- Helper Function to generate the QuestList from ns.DB.char.Quests ----------
function ns.QuestList()
    local QuestList = {}
    local TIME = time()
    for id, quest in pairs(ns.DB.char.Quests) do
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

function QuestHistory:UpdateQuestDB()
    local mapID = C_Map.GetBestMapForUnit('player')
    local mapName = C_Map.GetMapInfo(mapID).name
    local mapPos = C_Map.GetPlayerMapPosition(mapID, 'player')
    local x, y = 0, 0
    if mapPos then x, y = mapPos:GetXY() end
    local TIME = time()

    local counter = 0
    for id, changedTo in pairs(self:GetChangedQuests().quests) do
        counter = counter + 1
        if counter > 20 then
            ns.Print('>20 Quests Changed, please wait.')
            C_Timer.After(1, function() self:UpdateQuestDB() end)
            break
        else
            if not ns.DB.char.Quests[id] then
                ns.DB.char.Quests[id] = {id = id, completed = changedTo}
            else
                ns.DB.char.Quests[id].completed = changedTo
            end

            if not ns.DB.char.Quests[id].title then
                ns.DB.char.Quests[id].title = 'Pending ...'
                C_QuestLog.RequestLoadQuestByID(id)
            end

            ns.DB.char.Quests[id].mapId = mapID
            ns.DB.char.Quests[id].mapName = mapName or UNKNOWN
            ns.DB.char.Quests[id].x = x or 0
            ns.DB.char.Quests[id].y = y or 0
            ns.DB.char.Quests[id].time = TIME

            ns.HistoryFrame:Refresh()
        end
    end
end

function QuestHistory:GetCompletedQuests()
    local Q = {}
    for _, id in pairs(C_QuestLog.GetAllCompletedQuestIDs()) do Q[id] = true end
    return Q
end

function QuestHistory:GetChangedQuests()
    local completedQuests = self:GetCompletedQuests()

    local counter = 0
    local quests = {}
    for id, completed in pairs(completedQuests) do
        -- Quest was completed before and is now not completed
        if ns.DB.char.Quests[id] and ns.DB.char.Quests[id].completed == true and not completed then
            quests[id] = false
            counter = counter + 1
        end
        -- Quest was not completed before and is now completed
        if ns.DB.char.Quests[id] and ns.DB.char.Quests[id].completed == false and completed then
            quests[id] = true
            counter = counter + 1
        end
        -- Quest did not exist in QuestDB and is now completed
        if not ns.DB.char.Quests[id] and completed then
            quests[id] = true
            counter = counter + 1
        end
    end
    for id, quest in pairs(ns.DB.char.Quests) do
        -- Quest was completed before and is now not completed
        if completedQuests[id] == true and not quest.completed then
            quests[id] = true
            counter = counter + 1
        end
        -- Quest was not completed before and is now completed
        if completedQuests[id] == false and quest.completed then
            quests[id] = false
            counter = counter + 1
        end
    end

    return {quests = quests, counter = counter}
end

ns.QuestHistory = QuestHistory
