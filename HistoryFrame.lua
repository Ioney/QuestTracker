local ADDON_NAME, ns = ...

local QuestHistory = {}

local function QuestList()
    local QuestList = {}
    local TIME = time()
    for id, quest in pairs(ns.QuestDB) do
        if quest.title then
            table.insert(QuestList, {
                id = id,
                title = quest.title,
                time = quest.time and TIME - quest.time or TIME, -- defaults to current time for sorting
                map = quest.map and quest.map.name or UNKNOWN,
                pos = {x = quest.x, y = quest.y}
            })
        end
    end
    return QuestList
end

function QuestHistory:Refresh()
    local dataProvider = CreateDataProvider(QuestList())
    dataProvider:SetSortComparator(function(A, B) return A.time < B.time end)
    self.Frame.QuestListContainer.ScrollView:SetDataProvider(dataProvider)
end

function QuestHistory:Init()
    self.Frame = CreateFrame("Frame", ADDON_NAME .. "HistoryFrame", nil, ADDON_NAME .. "HistoryFrameTemplate")
    self.Frame:SetTitle(ADDON_NAME)
    self.Frame:Hide()

    local initializer = function(line, quest)
        line:SetHighlightAtlas("auctionhouse-ui-row-highlight")

        line.Id = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightRight")
        line.Id:SetPoint("LEFT", 10, 0)
        line.Id:SetText(quest.id)

        line.Title = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
        line.Title:SetPoint("LEFT", 100, 0)
        line.Title:SetText(quest.title)

        line.Map = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
        line.Map:SetPoint("RIGHT", -200, 0)
        line.Map:SetText(quest.map and quest.map.name or UNKNOWN)

        line.Position = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
        line.Position:SetPoint("RIGHT", -100, 0)
        line.Position:SetText(format("%.2f %.2f", quest.pos.x * 100, quest.pos.y * 100))

        line.Time = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightRight")
        line.Time:SetPoint("RIGHT")
        line.Time:SetText(ns.QuestDB[quest.id].time and SecondsToTime(quest.time, true) or UNKNOWN)
    end

    local dataProvider = CreateDataProvider(QuestList())

    dataProvider:SetSortComparator(function(A, B) return A.time < B.time end)

    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(dataProvider)
    ScrollView:SetElementExtent(20)
    ScrollView:SetElementInitializer("Button", initializer)
    self.Frame.QuestListContainer.ScrollView = ScrollView

    ScrollUtil.InitScrollBoxWithScrollBar(self.Frame.QuestListContainer.ScrollBox,
                                          self.Frame.QuestListContainer.ScrollBar, ScrollView)

    self.Frame.QuestListContainer:Show()
end

ns.QuestHistory = QuestHistory
