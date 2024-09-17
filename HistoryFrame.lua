local ADDON_NAME, ns = ...

local HistoryFrame = CreateFrame('Frame', ADDON_NAME .. 'HistoryFrame', nil, ADDON_NAME .. 'HistoryFrameTemplate')

function HistoryFrame:Init()
    self:SetTitle(ADDON_NAME .. ' History')

    local initializer = function(line, quest)
        line:SetHighlightAtlas('auctionhouse-ui-row-highlight')
        if not line.Id then
            line.Id = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightRight')
            line.Id:SetPoint('LEFT', 10, 0)

            line.Title = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            line.Title:SetPoint('LEFT', 70, 0)

            line.Map = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            line.Map:SetPoint('RIGHT', -220, 0)

            line.Position = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            line.Position:SetPoint('RIGHT', -120, 0)

            line.Time = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightRight')
            line.Time:SetPoint('RIGHT')
        end

        line.Title:SetText(quest.title)
        line.Map:SetText(quest.map)
        line.Position:SetText(format('%.2f %.2f', quest.pos.x * 100 or 0, quest.pos.y * 100 or 0))
        line.Id:SetText(quest.id)
        line.Time:SetText(ns.DB.char.Quests[quest.id].time and date('%d.%m %H:%M:%S', quest.time) or UNKNOWN)
    end

    local dataProvider = CreateDataProvider(ns.QuestList())
    dataProvider:SetSortComparator(function(A, B) return A.time > B.time end)
    self.dataProvider = dataProvider

    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetDataProvider(self.dataProvider)
    ScrollView:SetElementExtent(20)
    ScrollView:SetElementInitializer('Button', initializer)
    self.ScrollView = ScrollView

    ScrollUtil.InitScrollBoxWithScrollBar(self.QuestList.ScrollBox, self.QuestList.ScrollBar, ScrollView)

    self.QuestList:Show()
end

function HistoryFrame:Refresh()
    self.dataProvider:Flush()
    self.dataProvider:InsertTable(ns.QuestList())
    self.dataProvider:Sort()
    self.ScrollView:SetDataProvider(self.dataProvider)
end

ns.HistoryFrame = HistoryFrame
