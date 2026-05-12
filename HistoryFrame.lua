local ADDON_NAME, ns = ...

local HistoryFrame = CreateFrame('Frame', ADDON_NAME .. 'HistoryFrame', nil, ADDON_NAME .. 'HistoryFrameTemplate')

function HistoryFrame:Init()
    self:SetTitle(ADDON_NAME .. ' History')

    local titleWidth = nil
    local measureText = nil
    local needsHeightRefresh = false
    local COL_MAP_LEFT    = nil
    local COL_MAP_W       = 100
    local COL_POS_LEFT    = nil
    local COL_POS_W       = 90
    local COL_TIME_W      = 90

    local LINE_PAD = 6

    local initializer = function(line, quest)
        if not titleWidth then
            local totalW     = self.QuestList.ScrollBox:GetWidth()
            COL_TIME_W       = 110
            COL_POS_W        = 100
            COL_MAP_W        = 140
            COL_POS_LEFT     = totalW - COL_TIME_W - COL_POS_W
            COL_MAP_LEFT     = COL_POS_LEFT - COL_MAP_W
            titleWidth       = COL_MAP_LEFT - 70 - 5
            measureText = self.QuestList:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            measureText:SetWidth(titleWidth)
            measureText:SetWordWrap(true)
            measureText:Hide()
            needsHeightRefresh = true
        end
        if not line.Id then
            line.Id = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightRight')
            line.Id:SetPoint('LEFT', 5, 0)
            line.Id:SetWidth(55)

            line.Title = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            line.Title:SetPoint('LEFT', line, 'LEFT', 70, 0)
            line.Title:SetWidth(titleWidth)
            line.Title:SetWordWrap(true)

            line.Map = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            line.Map:SetPoint('LEFT', line, 'LEFT', COL_MAP_LEFT, 0)
            line.Map:SetWidth(COL_MAP_W)

            line.Position = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLeft')
            line.Position:SetPoint('LEFT', line, 'LEFT', COL_POS_LEFT, 0)
            line.Position:SetWidth(COL_POS_W)

            line.Time = line:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightRight')
            line.Time:SetPoint('RIGHT')
            line.Time:SetWidth(COL_TIME_W)
        end

        -- Color title based on tracking type:
        --   confident  = orange  (known tracking quest name)
        --   unsure     = yellow  (guessed tracking quest name)
        --   unknown    = red     (no name found anywhere)
        --   nil        = default (WoW provided the title)
        local trackingType = ns.DB.char.Quests[quest.id] and ns.DB.char.Quests[quest.id].trackingType
        local titleText = quest.title or UNKNOWN
        if trackingType == 'confident' then
            titleText = '|cFFFF8C00' .. titleText .. '|r'
        elseif trackingType == 'unsure' then
            titleText = '|cFFFFFF00' .. titleText .. '|r'
        elseif trackingType == 'unknown' then
            titleText = '|cFFFF4444' .. titleText .. '|r'
        end

        line.Title:SetText(titleText)
        line.Map:SetText(quest.map)
        line.Position:SetText(format('%.2f %.2f', quest.pos.x * 100 or 0, quest.pos.y * 100 or 0))
        line.Id:SetText(quest.id)
        line.Time:SetText(ns.DB.char.Quests[quest.id].time and date('%d.%m %H:%M:%S', quest.time) or UNKNOWN)

        -- After the first initializer run, measureText exists and heights can be
        -- properly calculated. Trigger one Refresh so the ExtentCalculator re-runs.
        if needsHeightRefresh then
            needsHeightRefresh = false
            C_Timer.After(0, function() self:Refresh() end)
        end
    end

    local dataProvider = CreateDataProvider(ns.QuestList())
    dataProvider:SetSortComparator(function(A, B) return A.time > B.time end)
    self.dataProvider = dataProvider

    local ScrollView = CreateScrollBoxListLinearView()
    ScrollView:SetElementExtent(20)  -- minimum / pool hint
    ScrollView:SetElementExtentCalculator(function(dataIndex, elementData)
        if not measureText then return 20 end
        -- Strip color codes before measuring so they don't affect line breaks
        local titleText = (elementData.title or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
        measureText:SetText(titleText)
        return math.max(20, measureText:GetStringHeight() + LINE_PAD)
    end)
    ScrollView:SetElementInitializer('Button', initializer)
    self.ScrollView = ScrollView

    ScrollUtil.InitScrollBoxListWithScrollBar(self.QuestList.ScrollBox, self.QuestList.ScrollBar, ScrollView)
    self.QuestList.ScrollBox:SetDataProvider(self.dataProvider)

    self.QuestList:Show()
end

function HistoryFrame:Refresh()
    if not self.dataProvider then return end
    self.dataProvider:Flush()
    self.dataProvider:InsertTable(ns.QuestList())
    self.dataProvider:Sort()
end

ns.HistoryFrame = HistoryFrame
